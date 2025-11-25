"""
Pydantic models for API request/response schemas.
"""

from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List
from enum import Enum
from datetime import datetime


class JobStatus(str, Enum):
    """Job status enumeration."""
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"


class OutputFormat(str, Enum):
    """Supported output formats."""
    MARKDOWN = "markdown"
    JSON = "json"
    HTML = "html"


# ============ Request Models ============

class ConvertOptions(BaseModel):
    """Options for PDF conversion."""
    use_llm: bool = Field(default=False, description="Use LLM for improved accuracy")
    force_ocr: bool = Field(default=False, description="Force OCR on all pages")
    output_format: OutputFormat = Field(default=OutputFormat.MARKDOWN, description="Output format")
    extract_images: bool = Field(default=True, description="Extract and include images")
    page_range: Optional[str] = Field(default=None, description="Page range, e.g. '1-10' or '1,3,5'")


# ============ Response Models ============

class HealthResponse(BaseModel):
    """Health check response."""
    status: str = "ok"
    gpu_available: bool = False
    models_loaded: bool = False
    redis_connected: bool = False
    version: str = "1.0.0"


class ConvertResponse(BaseModel):
    """Synchronous conversion response."""
    success: bool
    markdown: Optional[str] = None
    html: Optional[str] = None
    json_content: Optional[Dict[str, Any]] = None
    images: Dict[str, str] = Field(default_factory=dict, description="Image name -> base64 data")
    metadata: Dict[str, Any] = Field(default_factory=dict)
    pages: int = 0
    processing_time: float = 0.0
    error: Optional[str] = None


class JobCreateResponse(BaseModel):
    """Response when creating an async job."""
    job_id: str
    status: JobStatus = JobStatus.PENDING
    message: str = "Job created successfully"
    created_at: datetime = Field(default_factory=datetime.utcnow)


class JobStatusResponse(BaseModel):
    """Response for job status check."""
    job_id: str
    status: JobStatus
    progress: int = Field(default=0, ge=0, le=100, description="Progress percentage")
    current_page: Optional[int] = None
    total_pages: Optional[int] = None
    message: Optional[str] = None
    created_at: Optional[datetime] = None
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    error: Optional[str] = None


class JobResultResponse(BaseModel):
    """Response containing job result."""
    job_id: str
    status: JobStatus
    result: Optional[ConvertResponse] = None
    error: Optional[str] = None


class JobDeleteResponse(BaseModel):
    """Response for job deletion."""
    job_id: str
    deleted: bool
    message: str


class JobListResponse(BaseModel):
    """Response for listing jobs."""
    jobs: List[JobStatusResponse]
    total: int


class ErrorResponse(BaseModel):
    """Error response."""
    error: str
    detail: Optional[str] = None
    status_code: int = 500
