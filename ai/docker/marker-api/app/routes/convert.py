"""
Synchronous conversion endpoint for small files.
"""

import os
import time
import base64
import tempfile
from io import BytesIO
from typing import Optional

from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from PIL import Image

from app.config import settings
from app.models import ConvertResponse, ConvertOptions, OutputFormat

router = APIRouter(tags=["Convert"])

# Global model cache
_model_dict = None


def get_models():
    """Get or initialize marker models (cached)."""
    global _model_dict
    if _model_dict is None:
        from marker.models import create_model_dict
        _model_dict = create_model_dict()
    return _model_dict


def image_to_base64(img: Image.Image) -> str:
    """Convert PIL Image to base64 string."""
    buffered = BytesIO()
    img.save(buffered, format="PNG")
    return base64.b64encode(buffered.getvalue()).decode("utf-8")


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


def convert_pdf_to_markdown(
    file_path: str,
    use_llm: bool = False,
    force_ocr: bool = False,
    output_format: str = "markdown",
    extract_images: bool = True,
) -> dict:
    """
    Convert a PDF file to markdown using marker.

    Returns dict with: markdown, images, metadata, pages
    """
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

    # Get cached models
    model_dict = get_models()

    # Get LLM service class path string if enabled
    llm_service = get_llm_service_string() if (use_llm and settings.use_llm) else None

    # Create converter and process
    converter = PdfConverter(
        artifact_dict=model_dict,
        config=config,
        llm_service=llm_service
    )

    rendered = converter(file_path)

    # Extract text based on format
    text_content = text_from_rendered(rendered)

    # Extract images as base64
    images_base64 = {}
    if extract_images and hasattr(rendered, 'images') and rendered.images:
        for img_name, img in rendered.images.items():
            if isinstance(img, Image.Image):
                images_base64[img_name] = image_to_base64(img)

    # Build metadata
    metadata = {
        "pages": len(rendered.children) if hasattr(rendered, 'children') else 0,
    }
    if hasattr(rendered, 'metadata'):
        metadata.update(rendered.metadata)

    return {
        "content": text_content,
        "images": images_base64,
        "metadata": metadata,
        "pages": metadata.get("pages", 0),
    }


@router.post("/convert", response_model=ConvertResponse)
async def convert_sync(
    file: UploadFile = File(..., description="PDF file to convert"),
    use_llm: bool = Form(default=False, description="Use LLM for better accuracy"),
    force_ocr: bool = Form(default=False, description="Force OCR on all pages"),
    output_format: str = Form(default="markdown", description="Output format: markdown, json, html"),
    extract_images: bool = Form(default=True, description="Extract images as base64"),
) -> ConvertResponse:
    """
    Synchronous PDF conversion.

    Best for small files (<20 pages). For larger files, use the async /jobs endpoint.

    **Warning**: This endpoint may timeout for large files. Use /jobs for files >20 pages.
    """
    start_time = time.time()

    # Validate file type
    if not file.filename:
        raise HTTPException(status_code=400, detail="No filename provided")

    allowed_extensions = {".pdf", ".png", ".jpg", ".jpeg", ".tiff", ".bmp", ".webp"}
    file_ext = os.path.splitext(file.filename)[1].lower()
    if file_ext not in allowed_extensions:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported file type: {file_ext}. Allowed: {allowed_extensions}"
        )

    # Check file size
    content = await file.read()
    file_size_mb = len(content) / (1024 * 1024)
    if file_size_mb > settings.max_file_size_mb:
        raise HTTPException(
            status_code=413,
            detail=f"File too large: {file_size_mb:.1f}MB. Max: {settings.max_file_size_mb}MB"
        )

    # Save to temp file
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=file_ext) as tmp:
            tmp.write(content)
            tmp_path = tmp.name

        # Convert
        result = convert_pdf_to_markdown(
            file_path=tmp_path,
            use_llm=use_llm,
            force_ocr=force_ocr,
            output_format=output_format,
            extract_images=extract_images,
        )

        processing_time = time.time() - start_time

        # Build response based on format
        response = ConvertResponse(
            success=True,
            images=result["images"],
            metadata=result["metadata"],
            pages=result["pages"],
            processing_time=processing_time,
        )

        if output_format == "markdown":
            response.markdown = result["content"]
        elif output_format == "html":
            response.html = result["content"]
        elif output_format == "json":
            response.json_content = {"content": result["content"]}

        return response

    except Exception as e:
        processing_time = time.time() - start_time
        return ConvertResponse(
            success=False,
            error=str(e),
            processing_time=processing_time,
        )

    finally:
        # Cleanup temp file
        if 'tmp_path' in locals() and os.path.exists(tmp_path):
            os.unlink(tmp_path)
