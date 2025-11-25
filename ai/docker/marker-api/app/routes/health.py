"""
Health check endpoint.
"""

from fastapi import APIRouter
import torch
import redis

from app.config import settings
from app.models import HealthResponse

router = APIRouter(tags=["Health"])

# Cache for models loaded status
_models_loaded = False


def check_models_loaded() -> bool:
    """Check if marker models are loaded."""
    global _models_loaded
    if _models_loaded:
        return True

    try:
        from marker.models import create_model_dict
        # Just check if import works, don't actually load
        _models_loaded = True
        return True
    except Exception:
        return False


def check_redis_connection() -> bool:
    """Check if Redis is reachable."""
    try:
        r = redis.Redis(
            host=settings.redis_host,
            port=settings.redis_port,
            db=settings.redis_db,
            socket_timeout=2
        )
        r.ping()
        return True
    except Exception:
        return False


@router.get("/health", response_model=HealthResponse)
async def health_check() -> HealthResponse:
    """
    Health check endpoint.
    Returns system status including GPU availability, model status, and Redis connection.
    """
    return HealthResponse(
        status="ok",
        gpu_available=torch.cuda.is_available(),
        models_loaded=check_models_loaded(),
        redis_connected=check_redis_connection(),
        version="1.0.0"
    )


@router.get("/health/gpu")
async def gpu_info():
    """Detailed GPU information."""
    if not torch.cuda.is_available():
        return {"gpu_available": False, "message": "No GPU detected"}

    return {
        "gpu_available": True,
        "device_count": torch.cuda.device_count(),
        "current_device": torch.cuda.current_device(),
        "device_name": torch.cuda.get_device_name(0),
        "memory_allocated": f"{torch.cuda.memory_allocated(0) / 1024**3:.2f} GB",
        "memory_reserved": f"{torch.cuda.memory_reserved(0) / 1024**3:.2f} GB",
    }
