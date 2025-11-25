"""
Celery tasks for PDF conversion.
"""

import os
import time
import base64
import tempfile
from io import BytesIO
from typing import Optional, Dict, Any
from datetime import datetime

from celery import current_task
from celery.signals import worker_process_init
from PIL import Image

from app.worker.celery_app import celery_app
from app.config import settings

# Global model cache (loaded once per worker)
model_dict = None


@worker_process_init.connect
def initialize_models(**kwargs):
    """
    Initialize marker models when worker starts.
    This ensures models are loaded only once per worker process.
    """
    global model_dict
    if model_dict is None:
        print("=" * 60)
        print("Loading Marker models...")
        print("=" * 60)

        from marker.models import create_model_dict
        model_dict = create_model_dict()

        print(f"Models loaded successfully: {list(model_dict.keys())}")
        print("=" * 60)


def get_models():
    """Get the cached model dictionary."""
    global model_dict
    if model_dict is None:
        from marker.models import create_model_dict
        model_dict = create_model_dict()
    return model_dict


def get_llm_service_string():
    """Get the LLM service class path string based on configuration."""
    if not settings.use_llm:
        return None

    if settings.llm_provider == "ollama":
        return "marker.services.ollama.OllamaService"
    elif settings.llm_provider == "gemini" and settings.google_api_key:
        os.environ["GOOGLE_API_KEY"] = settings.google_api_key
        return "marker.services.gemini.GoogleGeminiService"
    elif settings.llm_provider == "openai" and settings.openai_api_key:
        return "marker.services.openai.OpenAIService"
    elif settings.llm_provider == "anthropic" and settings.anthropic_api_key:
        return "marker.services.claude.ClaudeService"

    return None


def image_to_base64(img: Image.Image) -> str:
    """Convert PIL Image to base64 string."""
    buffered = BytesIO()
    img.save(buffered, format="PNG")
    return base64.b64encode(buffered.getvalue()).decode("utf-8")


def update_progress(current: int, total: int, message: str = ""):
    """Update task progress for status polling."""
    if current_task:
        progress = int((current / total) * 100) if total > 0 else 0
        current_task.update_state(
            state="PROCESSING",
            meta={
                "progress": progress,
                "current_page": current,
                "total_pages": total,
                "message": message,
            }
        )


@celery_app.task(
    bind=True,
    name="convert_pdf",
    max_retries=3,
    default_retry_delay=10,
)
def convert_pdf_task(
    self,
    file_content_b64: str,
    filename: str,
    use_llm: bool = False,
    force_ocr: bool = False,
    output_format: str = "markdown",
    extract_images: bool = True,
) -> Dict[str, Any]:
    """
    Async task to convert PDF to markdown.

    Args:
        file_content_b64: Base64 encoded file content
        filename: Original filename
        use_llm: Use LLM for improved accuracy
        force_ocr: Force OCR on all pages
        output_format: Output format (markdown, json, html)
        extract_images: Extract images as base64

    Returns:
        Dict with conversion result
    """
    start_time = time.time()
    tmp_path = None

    try:
        # Update status
        self.update_state(
            state="PROCESSING",
            meta={"progress": 0, "message": "Starting conversion..."}
        )

        # Decode file content
        file_content = base64.b64decode(file_content_b64)

        # Get file extension
        file_ext = os.path.splitext(filename)[1].lower() or ".pdf"

        # Save to temp file
        with tempfile.NamedTemporaryFile(delete=False, suffix=file_ext) as tmp:
            tmp.write(file_content)
            tmp_path = tmp.name

        self.update_state(
            state="PROCESSING",
            meta={"progress": 10, "message": "File saved, loading models..."}
        )

        # Import marker components
        from marker.converters.pdf import PdfConverter
        from marker.output import text_from_rendered

        # Build converter config
        config = {
            "output_format": output_format,
        }

        if use_llm and settings.use_llm:
            config["use_llm"] = True
            # Add Ollama-specific config
            if settings.llm_provider == "ollama":
                config["ollama_base_url"] = settings.ollama_base_url
                config["ollama_model"] = settings.ollama_model

        if force_ocr:
            config["force_ocr"] = True

        self.update_state(
            state="PROCESSING",
            meta={"progress": 20, "message": "Converting PDF..."}
        )

        # Get cached models
        models = get_models()

        # Get LLM service class path string if enabled
        llm_service = get_llm_service_string() if (use_llm and settings.use_llm) else None

        # Create converter and process
        converter = PdfConverter(
            artifact_dict=models,
            config=config,
            llm_service=llm_service
        )

        rendered = converter(tmp_path)

        self.update_state(
            state="PROCESSING",
            meta={"progress": 80, "message": "Extracting content..."}
        )

        # Extract text based on format
        text_content = text_from_rendered(rendered)

        # Extract images as base64
        images_base64 = {}
        if extract_images and hasattr(rendered, 'images') and rendered.images:
            for img_name, img in rendered.images.items():
                if isinstance(img, Image.Image):
                    images_base64[img_name] = image_to_base64(img)

        # Build metadata
        num_pages = len(rendered.children) if hasattr(rendered, 'children') else 0
        metadata = {
            "pages": num_pages,
            "filename": filename,
        }
        if hasattr(rendered, 'metadata'):
            metadata.update(rendered.metadata)

        processing_time = time.time() - start_time

        self.update_state(
            state="PROCESSING",
            meta={"progress": 100, "message": "Completed!"}
        )

        # Build result
        result = {
            "success": True,
            "content": text_content,
            "images": images_base64,
            "metadata": metadata,
            "pages": num_pages,
            "processing_time": processing_time,
            "output_format": output_format,
            "completed_at": datetime.utcnow().isoformat(),
        }

        return result

    except Exception as e:
        processing_time = time.time() - start_time
        error_msg = str(e)

        # Retry on certain errors
        if "CUDA out of memory" in error_msg:
            raise self.retry(exc=e, countdown=30)

        return {
            "success": False,
            "error": error_msg,
            "processing_time": processing_time,
            "completed_at": datetime.utcnow().isoformat(),
        }

    finally:
        # Cleanup temp file
        if tmp_path and os.path.exists(tmp_path):
            try:
                os.unlink(tmp_path)
            except Exception:
                pass
