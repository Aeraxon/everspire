"""
Async job endpoints for large file processing.
"""

import os
import base64
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from celery.result import AsyncResult

from app.config import settings
from app.models import (
    JobStatus,
    JobCreateResponse,
    JobStatusResponse,
    JobResultResponse,
    JobDeleteResponse,
    ConvertResponse,
)
from app.worker.celery_app import celery_app
from app.worker.tasks import convert_pdf_task

router = APIRouter(prefix="/jobs", tags=["Jobs"])


def celery_state_to_job_status(state: str) -> JobStatus:
    """Convert Celery task state to JobStatus."""
    mapping = {
        "PENDING": JobStatus.PENDING,
        "STARTED": JobStatus.PROCESSING,
        "PROCESSING": JobStatus.PROCESSING,
        "SUCCESS": JobStatus.COMPLETED,
        "FAILURE": JobStatus.FAILED,
        "REVOKED": JobStatus.FAILED,
    }
    return mapping.get(state, JobStatus.PENDING)


@router.post("", response_model=JobCreateResponse)
async def create_job(
    file: UploadFile = File(..., description="PDF file to convert"),
    use_llm: bool = Form(default=False, description="Use LLM for better accuracy"),
    force_ocr: bool = Form(default=False, description="Force OCR on all pages"),
    output_format: str = Form(default="markdown", description="Output format: markdown, json, html"),
    extract_images: bool = Form(default=True, description="Extract images as base64"),
) -> JobCreateResponse:
    """
    Create an async conversion job.

    Use this endpoint for large files that might timeout with /convert.
    Returns a job_id that can be used to check status and retrieve results.

    Workflow:
    1. POST /jobs with file -> get job_id
    2. GET /jobs/{job_id} -> check status (poll until completed)
    3. GET /jobs/{job_id}/result -> get conversion result
    """
    # Validate file
    if not file.filename:
        raise HTTPException(status_code=400, detail="No filename provided")

    allowed_extensions = {".pdf", ".png", ".jpg", ".jpeg", ".tiff", ".bmp", ".webp"}
    file_ext = os.path.splitext(file.filename)[1].lower()
    if file_ext not in allowed_extensions:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported file type: {file_ext}. Allowed: {allowed_extensions}"
        )

    # Read and check file size
    content = await file.read()
    file_size_mb = len(content) / (1024 * 1024)
    if file_size_mb > settings.max_file_size_mb:
        raise HTTPException(
            status_code=413,
            detail=f"File too large: {file_size_mb:.1f}MB. Max: {settings.max_file_size_mb}MB"
        )

    # Encode file content as base64 for Celery serialization
    content_b64 = base64.b64encode(content).decode("utf-8")

    # Submit task to Celery
    task = convert_pdf_task.delay(
        file_content_b64=content_b64,
        filename=file.filename,
        use_llm=use_llm,
        force_ocr=force_ocr,
        output_format=output_format,
        extract_images=extract_images,
    )

    return JobCreateResponse(
        job_id=task.id,
        status=JobStatus.PENDING,
        message=f"Job created. File: {file.filename} ({file_size_mb:.1f}MB)",
        created_at=datetime.utcnow(),
    )


@router.get("/{job_id}", response_model=JobStatusResponse)
async def get_job_status(job_id: str) -> JobStatusResponse:
    """
    Get the status of a conversion job.

    Poll this endpoint to check if a job is completed.
    """
    task = AsyncResult(job_id, app=celery_app)

    response = JobStatusResponse(
        job_id=job_id,
        status=celery_state_to_job_status(task.state),
    )

    # Add progress info if available
    if task.state == "PROCESSING" and task.info:
        response.progress = task.info.get("progress", 0)
        response.current_page = task.info.get("current_page")
        response.total_pages = task.info.get("total_pages")
        response.message = task.info.get("message")

    elif task.state == "SUCCESS":
        response.progress = 100
        response.message = "Conversion completed"
        if task.result:
            response.completed_at = datetime.fromisoformat(
                task.result.get("completed_at", datetime.utcnow().isoformat())
            )

    elif task.state == "FAILURE":
        response.message = str(task.result) if task.result else "Task failed"
        response.error = str(task.result)

    return response


@router.get("/{job_id}/result", response_model=JobResultResponse)
async def get_job_result(job_id: str) -> JobResultResponse:
    """
    Get the result of a completed conversion job.

    Only returns results for completed jobs. Check status first.
    """
    task = AsyncResult(job_id, app=celery_app)

    if task.state == "PENDING":
        raise HTTPException(
            status_code=202,
            detail="Job is still pending. Please wait and check status."
        )

    if task.state in ("STARTED", "PROCESSING"):
        raise HTTPException(
            status_code=202,
            detail="Job is still processing. Please wait and check status."
        )

    if task.state == "FAILURE":
        return JobResultResponse(
            job_id=job_id,
            status=JobStatus.FAILED,
            error=str(task.result) if task.result else "Unknown error",
        )

    if task.state == "SUCCESS":
        result = task.result

        if not result.get("success"):
            return JobResultResponse(
                job_id=job_id,
                status=JobStatus.FAILED,
                error=result.get("error", "Conversion failed"),
            )

        # Build ConvertResponse from task result
        output_format = result.get("output_format", "markdown")
        convert_response = ConvertResponse(
            success=True,
            images=result.get("images", {}),
            metadata=result.get("metadata", {}),
            pages=result.get("pages", 0),
            processing_time=result.get("processing_time", 0),
        )

        # Set content based on format
        content = result.get("content", "")
        if output_format == "markdown":
            convert_response.markdown = content
        elif output_format == "html":
            convert_response.html = content
        elif output_format == "json":
            convert_response.json_content = {"content": content}

        return JobResultResponse(
            job_id=job_id,
            status=JobStatus.COMPLETED,
            result=convert_response,
        )

    # Unknown state
    raise HTTPException(
        status_code=500,
        detail=f"Unknown task state: {task.state}"
    )


@router.delete("/{job_id}", response_model=JobDeleteResponse)
async def delete_job(job_id: str) -> JobDeleteResponse:
    """
    Delete/cancel a job.

    If the job is still running, it will be revoked.
    """
    task = AsyncResult(job_id, app=celery_app)

    if task.state in ("PENDING", "STARTED", "PROCESSING"):
        # Revoke running task
        task.revoke(terminate=True)
        return JobDeleteResponse(
            job_id=job_id,
            deleted=True,
            message="Job cancelled",
        )

    # For completed/failed tasks, just forget the result
    task.forget()

    return JobDeleteResponse(
        job_id=job_id,
        deleted=True,
        message="Job result deleted",
    )
