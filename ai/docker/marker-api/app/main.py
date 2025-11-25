"""
Marker API - FastAPI Application

High-quality PDF to Markdown conversion service with async job support.
"""

import os
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.config import settings
from app.routes import health, convert, jobs


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan handler."""
    # Startup
    print("=" * 60)
    print("Marker API Starting...")
    print(f"  Debug: {settings.debug}")
    print(f"  Redis: {settings.redis_host}:{settings.redis_port}")
    print(f"  Use LLM: {settings.use_llm}")
    print(f"  Max File Size: {settings.max_file_size_mb}MB")
    print("=" * 60)

    # Create directories
    os.makedirs(settings.upload_dir, exist_ok=True)
    os.makedirs(settings.results_dir, exist_ok=True)
    os.makedirs(settings.temp_dir, exist_ok=True)

    yield

    # Shutdown
    print("Marker API Shutting down...")


# Create FastAPI app
app = FastAPI(
    title="Marker API",
    description="""
# Marker API

High-quality PDF to Markdown conversion service powered by [marker-pdf](https://github.com/datalab-to/marker).

## Features

- **GPU Accelerated**: Fast conversion using NVIDIA CUDA
- **High Quality**: Uses Surya models for superior layout detection
- **LLM Enhanced**: Optional LLM integration for complex layouts
- **Async Jobs**: Handle large files without timeouts

## Endpoints

### Synchronous Conversion
- `POST /convert` - Convert small files directly (< 20 pages recommended)

### Async Jobs (for large files)
- `POST /jobs` - Create conversion job
- `GET /jobs/{job_id}` - Check job status
- `GET /jobs/{job_id}/result` - Get job result
- `DELETE /jobs/{job_id}` - Cancel/delete job

### Health
- `GET /health` - Service health check
- `GET /health/gpu` - GPU information
""",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Global exception handler
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Handle uncaught exceptions."""
    return JSONResponse(
        status_code=500,
        content={
            "error": "Internal server error",
            "detail": str(exc) if settings.debug else "An unexpected error occurred",
        }
    )


# Include routers
app.include_router(health.router)
app.include_router(convert.router)
app.include_router(jobs.router)


# Root endpoint
@app.get("/", tags=["Root"])
async def root():
    """API root - returns basic info."""
    return {
        "name": "Marker API",
        "version": "1.0.0",
        "docs": "/docs",
        "health": "/health",
    }
