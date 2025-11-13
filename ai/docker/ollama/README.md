# Ollama Deployment with Docker Compose

Ollama provides a simple way to run large language models locally with automatic quantization and optimization.

## Prerequisites

- Docker and Docker Compose installed
- NVIDIA GPU with Docker GPU support (nvidia-container-toolkit)

## Quick Start

1. **Start the container**:
   ```bash
   docker compose up -d
   ```

2. **Pull a model** (required on first run):
   ```bash
   docker exec ollama-gemma3-12b ollama pull gemma3:12b
   ```

3. **View logs**:
   ```bash
   docker compose logs -f
   ```

4. **Stop the service**:
   ```bash
   docker compose down
   ```

## API Access

- **Base URL**: `http://localhost:8002`
- **OpenAI-compatible endpoint**: `http://localhost:8002/v1`

## Example Request

```bash
curl http://localhost:8002/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemma3:12b",
    "messages": [
      {"role": "user", "content": "Hello, how are you?"}
    ]
  }'
```

## Configuration

### Current Setup

- **Model**: gemma3:12b (Ollama default quantization)
- **Size**: ~8-9 GB (automatically quantized)
- **Parameters**: 12B
- **GPU**: GPU #1 (48GB VRAM)
- **Port**: 8002 (avoids conflicts with vLLM:8000 and other services)

### Customization Options

**Change port**:
```yaml
environment:
  - OLLAMA_HOST=0.0.0.0:8003  # Use port 8003
```

**Use different GPU**:
```yaml
environment:
  - CUDA_VISIBLE_DEVICES=0  # Use GPU 0
  - NVIDIA_VISIBLE_DEVICES=0
deploy:
  resources:
    reservations:
      devices:
        - driver: nvidia
          device_ids: ['0']  # Update here too
```

**Change container name**:
```yaml
container_name: ollama-mistral-7b  # Use descriptive name for your model
```

**Network mode** (alternative to host mode):
```yaml
network_mode: bridge
ports:
  - "8002:11434"  # Ollama default port is 11434
environment:
  - OLLAMA_HOST=0.0.0.0:11434
```

## Model Management

### Pull Models

```bash
# Pull default quantized version
docker exec ollama-gemma3-12b ollama pull gemma3:12b

# Pull specific quantization
docker exec ollama-gemma3-12b ollama pull gemma3:12b-q4_0
docker exec ollama-gemma3-12b ollama pull gemma3:12b-q8_0
```

### List Models

```bash
docker exec ollama-gemma3-12b ollama list
```

### Remove Models

```bash
docker exec ollama-gemma3-12b ollama rm gemma3:12b
```

### Run Interactive Chat

```bash
docker exec -it ollama-gemma3-12b ollama run gemma3:12b
```

## Popular Models

Ollama supports many models with automatic optimization:

```bash
# Meta Llama
docker exec ollama-gemma3-12b ollama pull llama3.1:8b
docker exec ollama-gemma3-12b ollama pull llama3.1:70b

# Mistral
docker exec ollama-gemma3-12b ollama pull mistral:7b
docker exec ollama-gemma3-12b ollama pull mixtral:8x7b

# Google Gemma
docker exec ollama-gemma3-12b ollama pull gemma2:9b
docker exec ollama-gemma3-12b ollama pull gemma3:12b

# Qwen
docker exec ollama-gemma3-12b ollama pull qwen2:7b

# Phi
docker exec ollama-gemma3-12b ollama pull phi3:14b

# DeepSeek Coder
docker exec ollama-gemma3-12b ollama pull deepseek-coder:6.7b
```

Check [Ollama Library](https://ollama.com/library) for the full list.

## Quantization Options

Ollama supports various quantization levels (smaller = faster, but lower quality):

- `q4_0` - 4-bit quantization (smallest, fastest)
- `q4_1` - 4-bit quantization (alternative)
- `q5_0` - 5-bit quantization (balanced)
- `q5_1` - 5-bit quantization (alternative)
- `q8_0` - 8-bit quantization (higher quality)
- `f16` - 16-bit float (original quality)

Example:
```bash
docker exec ollama-gemma3-12b ollama pull llama3.1:8b-q4_0  # Smaller, faster
docker exec ollama-gemma3-12b ollama pull llama3.1:8b-q8_0  # Better quality
```

## Volume Management

Models are stored in the `ollama-data` volume.

**View volume**:
```bash
docker volume ls | grep ollama-data
```

**Backup models**:
```bash
docker run --rm -v ollama-data:/data -v $(pwd):/backup ubuntu tar czf /backup/ollama-backup.tar.gz /data
```

**Restore models**:
```bash
docker run --rm -v ollama-data:/data -v $(pwd):/backup ubuntu tar xzf /backup/ollama-backup.tar.gz -C /
```

**Remove volume** (deletes all models):
```bash
docker compose down
docker volume rm ollama-data
```

## Performance Tips

1. **Choose appropriate quantization**: Q4/Q5 for speed, Q8/F16 for quality
2. **GPU selection**: Ollama automatically uses available VRAM efficiently
3. **Context length**: Ollama auto-adjusts based on available memory
4. **Parallel requests**: Ollama handles multiple requests well with proper VRAM

## Troubleshooting

**Container exits immediately**:
- Check logs: `docker compose logs`
- Verify NVIDIA GPU support: `docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi`

**Model pull fails**:
- Check internet connection
- Verify disk space: `df -h`
- Check volume: `docker volume inspect ollama-data`

**Out of memory**:
- Use smaller quantization (q4_0, q5_0)
- Use a smaller model
- Check GPU memory: `nvidia-smi`

**Connection refused**:
- Verify container is running: `docker ps | grep ollama`
- Check port binding: `docker port ollama-gemma3-12b`
- Test locally: `curl http://localhost:8002/api/tags`

**Slow inference**:
- Use lower quantization (q4_0 is fastest)
- Reduce concurrent requests
- Check GPU utilization: `nvidia-smi`

## OpenAI API Compatibility

Ollama provides an OpenAI-compatible API at `/v1` endpoint:

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:8002/v1",
    api_key="ollama",  # Not used, but required by OpenAI SDK
)

response = client.chat.completions.create(
    model="gemma3:12b",
    messages=[
        {"role": "user", "content": "Hello!"}
    ]
)

print(response.choices[0].message.content)
```

## Additional Resources

- [Ollama Documentation](https://github.com/ollama/ollama/blob/main/docs/api.md)
- [Ollama Model Library](https://ollama.com/library)
- [Ollama Docker Hub](https://hub.docker.com/r/ollama/ollama)
- [OpenAI API Reference](https://platform.openai.com/docs/api-reference)
