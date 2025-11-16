# AI / Machine Learning

AI tools, model deployment, and ML frameworks.

## Platform Deployment Guides

### [incus/](incus/)
Complete setup guide for GPU-accelerated AI infrastructure on Incus.

### [proxmox/](proxmox/)
GPU-accelerated AI infrastructure on Proxmox VE *(guide coming soon)*.

## Docker Deployments

### [docker/vllm/](docker/vllm/)
Deploy LLMs with vLLM using Docker Compose - high-throughput OpenAI-compatible API server.

Quick Start:
```bash
cd docker/vllm
cp .env.example .env  # Optional, for gated models
docker compose up -d
```

Features:
- OpenAI-compatible API
- FP8/INT8 quantization support
- Multi-GPU tensor parallelism
- Efficient KV cache management
- Wide model compatibility (Llama, Mistral, Gemma, Qwen, etc.)

### [docker/ollama/](docker/ollama/)
Deploy LLMs with Ollama using Docker Compose - simple model management with automatic optimization.

Quick Start:
```bash
cd docker/ollama
docker compose up -d
docker exec ollama-gemma3-12b ollama pull gemma3:12b
```

Features:
- One-command model downloads
- Automatic quantization
- Interactive chat mode
- Easy model switching
- OpenAI-compatible API

## Native Installations

### ollama-network-access.md
Configure Ollama for network access (localhost only by default).

Update-safe method using systemd override:
```bash
sudo systemctl edit ollama
# Add: Environment="OLLAMA_HOST=0.0.0.0"
sudo systemctl restart ollama
```

Note: Service file gets overwritten after Ollama updates - override persists.

### nvidia-nim-deployment.md
Deploy NVIDIA NIMs (Neural Inference Microservices) with Docker.

Quick Start:
```bash
export NGC_API_KEY="..."  # WITHOUT nvapi- prefix!
docker login nvcr.io  # Username: $oauthtoken
export LOCAL_NIM_CACHE=~/.cache/nim && mkdir -p "$LOCAL_NIM_CACHE"
docker run -d --runtime=nvidia --gpus all -e NGC_API_KEY=$NGC_API_KEY \
  -v "$LOCAL_NIM_CACHE:/opt/nim/.cache" -p 8000:8000 -p 8001:8001 \
  nvcr.io/nim/nvidia/maxine-bnr:latest
```

Important: First start takes time (model download).

## Comparison

| Feature | vLLM | Ollama |
|---------|------|--------|
| Setup Complexity | Medium | Easy |
| Performance | Highest | Good |
| Quantization | Manual (FP8/INT8) | Automatic |
| Multi-GPU | Yes (tensor parallel) | Limited |
| Model Management | Manual download | Built-in (`ollama pull`) |
| Best For | Production, high throughput | Development, quick testing |
