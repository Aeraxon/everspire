"""
Application configuration via environment variables.
"""

from pydantic_settings import BaseSettings
from typing import Optional


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    # Server
    app_name: str = "Marker API"
    debug: bool = False

    # Redis
    redis_host: str = "redis"
    redis_port: int = 6379
    redis_db: int = 0

    @property
    def redis_url(self) -> str:
        return f"redis://{self.redis_host}:{self.redis_port}/{self.redis_db}"

    # File handling
    max_file_size_mb: int = 100
    upload_dir: str = "/app/uploads"
    results_dir: str = "/app/results"
    temp_dir: str = "/app/temp"

    # Worker
    worker_concurrency: int = 1

    # LLM Integration
    use_llm: bool = False
    llm_provider: str = "gemini"  # gemini, openai, anthropic, ollama

    # API Keys (optional, only needed if use_llm=True)
    google_api_key: Optional[str] = None
    openai_api_key: Optional[str] = None
    anthropic_api_key: Optional[str] = None
    ollama_base_url: Optional[str] = "http://localhost:11434"
    ollama_model: str = "qwen3:4b"

    # Marker options
    force_ocr: bool = False
    output_format: str = "markdown"  # markdown, json, html

    # Job settings
    job_result_ttl: int = 3600  # Keep results for 1 hour
    job_max_retries: int = 3

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = False


# Global settings instance
settings = Settings()
