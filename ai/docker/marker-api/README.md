# Marker API

PDF to Markdown REST API powered by [marker-pdf](https://github.com/datalab-to/marker).

## Requirements

- Docker with NVIDIA GPU support
- ~10 GB VRAM (Surya models + optional LLM)

## Quick Start

```bash
cp .env.example .env
# Edit .env (set OLLAMA_BASE_URL if using local Ollama)
docker-compose up -d
```

First start downloads ~3 GB models. Check progress: `docker-compose logs -f api`

## API

### Sync (small files)

```bash
curl -X POST http://localhost:8000/convert \
  -F "file=@document.pdf" \
  -F "use_llm=true"
```

### Async (large files)

```bash
# Start job
curl -X POST http://localhost:8000/jobs -F "file=@large.pdf"
# {"job_id": "abc123", "status": "pending"}

# Poll status
curl http://localhost:8000/jobs/abc123
# {"status": "processing", "progress": 45}

# Get result
curl http://localhost:8000/jobs/abc123/result
```

### Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/convert` | POST | Sync conversion |
| `/jobs` | POST | Create async job |
| `/jobs/{id}` | GET | Job status |
| `/jobs/{id}/result` | GET | Job result |
| `/jobs/{id}` | DELETE | Cancel job |
| `/health` | GET | Health check |
| `/docs` | GET | Swagger UI |

## Configuration

Edit `.env`:

| Variable | Default | Description |
|----------|---------|-------------|
| `USE_LLM` | `true` | LLM post-processing |
| `LLM_PROVIDER` | `ollama` | ollama/gemini/openai/anthropic |
| `OLLAMA_BASE_URL` | `localhost:11434` | Ollama server |
| `OLLAMA_MODEL` | `qwen3:4b` | Model (~2.5 GB VRAM) |
| `MAX_FILE_SIZE_MB` | `100` | Upload limit |

## Monitoring

- Swagger: http://localhost:8000/docs
- Flower: http://localhost:5555

## License

**This wrapper code**: [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/) (non-commercial use)

**marker-pdf**: [GPL v3](https://github.com/datalab-to/marker/blob/master/LICENSE)

### How it works

This repository contains only the API wrapper code (FastAPI, Celery config, Docker setup). When you run `docker-compose build`, marker-pdf is downloaded separately via pip and is subject to its own GPL v3 license.

```
You clone this repo     → CC BY-NC 4.0 (this code)
docker-compose build    → Downloads marker-pdf (GPL v3)
Container runs          → Combined, marker's GPL v3 applies to the binary
```

This project does not distribute marker-pdf, only instructions to install it.
