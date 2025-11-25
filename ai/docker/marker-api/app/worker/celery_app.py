"""
Celery application configuration.
"""

import os
from celery import Celery

# Redis configuration from environment
REDIS_HOST = os.environ.get("REDIS_HOST", "redis")
REDIS_PORT = os.environ.get("REDIS_PORT", "6379")
REDIS_DB = os.environ.get("REDIS_DB", "0")

REDIS_URL = f"redis://{REDIS_HOST}:{REDIS_PORT}/{REDIS_DB}"

# Create Celery app
celery_app = Celery(
    "marker_worker",
    broker=REDIS_URL,
    backend=REDIS_URL,
    include=["app.worker.tasks"]
)

# Celery configuration
celery_app.conf.update(
    # Task settings
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="UTC",
    enable_utc=True,

    # Result backend settings
    result_expires=3600,  # Results expire after 1 hour
    result_extended=True,  # Store task args and kwargs in result

    # Worker settings
    worker_prefetch_multiplier=1,  # Only fetch one task at a time (important for GPU)
    worker_concurrency=1,  # One task at a time per worker

    # Task execution settings
    task_acks_late=True,  # Acknowledge after task completion
    task_reject_on_worker_lost=True,  # Requeue if worker dies

    # Timeouts
    task_soft_time_limit=600,  # 10 minutes soft limit
    task_time_limit=900,  # 15 minutes hard limit

    # Progress tracking
    task_track_started=True,

    # Memory management - restart worker after N tasks to prevent memory leaks
    worker_max_tasks_per_child=50,
)


@celery_app.task(name="celery.ping")
def ping():
    """Simple ping task for health checks."""
    return "pong"
