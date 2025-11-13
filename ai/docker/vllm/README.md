# vLLM Deployment with Docker Compose

vLLM is a high-throughput and memory-efficient inference engine for Large Language Models (LLMs). This setup provides an OpenAI-compatible API server using Docker Compose.

## Prerequisites

- Docker and Docker Compose installed
- NVIDIA GPU with Docker GPU support (nvidia-container-toolkit)
- (Optional) Hugging Face account and API token for gated models

## Quick Start

1. **Copy environment file** (optional, only needed for gated models):
   ```bash
   cp .env.example .env
   # Edit .env and add your HUGGING_FACE_HUB_TOKEN if needed
   ```

2. **Start the service**:
   ```bash
   docker compose up -d
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

- **Base URL**: `http://localhost:8000`
- **OpenAI-compatible endpoint**: `http://localhost:8000/v1`
- **API documentation**: `http://localhost:8000/docs`

## Example Request

```bash
curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "RedHatAI/gemma-3-12b-it-FP8-dynamic",
    "messages": [
      {"role": "user", "content": "Hello, how are you?"}
    ]
  }'
```

## Configuration

### Current Model Configuration

- **Model**: RedHatAI/gemma-3-12b-it-FP8-dynamic
- **Size**: ~8-9 GB (FP8 quantized)
- **Parameters**: 12B
- **Quantization**: FP8-dynamic (model + KV cache)
- **Context Length**: 16K tokens (16384)
- **GPU**: GPU #1 (48GB VRAM, ~18GB used at 0.45 utilization)
- **KV Cache**: FP8 quantized (~50% VRAM savings)

### Customization Options

Edit `docker-compose.yml` to customize:

**Change the model**:
```yaml
command:
  - --model
  - your-model/name-here  # Replace with any HuggingFace model
```

**Adjust GPU selection**:
```yaml
device_ids: ['0']  # Use GPU 0 instead of GPU 1
# or
device_ids: ['0', '1']  # Use multiple GPUs
```

**Change port**:
```yaml
- --port
- "8001"  # Use a different port
```

**Adjust GPU memory**:
```yaml
- --gpu-memory-utilization
- "0.9"  # Use up to 90% of GPU memory (default: 0.9)
```

**Change context length**:
```yaml
- --max-model-len
- "32768"  # Increase context window (requires more VRAM)
```

**Enable tensor parallelism** (for multi-GPU):
```yaml
- --tensor-parallel-size
- "2"  # Split model across 2 GPUs
```

### Advanced Options

**Enable FP8 KV Cache** (uncomment in docker-compose.yml):
```yaml
- --kv-cache-dtype
- fp8
```

**Adjust shared memory**:
```yaml
shm_size: '4gb'  # Increase if needed for larger batches
```

## Volume Management

Model weights are cached in the `vllm-cache` volume to avoid re-downloading.

**View volume**:
```bash
docker volume ls | grep vllm-cache
```

**Remove cache** (will re-download model on next start):
```bash
docker compose down
docker volume rm vllm-cache
```

## Security Notes

- **Never commit `.env` file** - it's already in `.gitignore`
- Hugging Face tokens have read access to your private models
- Consider using `network_mode: bridge` and expose specific ports instead of `host` mode for better isolation
- For production, implement authentication and use HTTPS

## Performance Tips

1. **GPU Memory Utilization**: Start with 0.45-0.6 and increase if you have headroom
2. **Batch Size**: Increase `--max-num-batched-tokens` for higher throughput
3. **Quantization**: Use FP8 or INT8 quantized models for better VRAM efficiency
4. **KV Cache**: Enable `fp8` KV cache dtype for ~50% memory savings

## Troubleshooting

**Container exits immediately**:
- Check logs: `docker compose logs`
- Verify NVIDIA GPU support: `docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi`

**Out of memory errors**:
- Reduce `--gpu-memory-utilization`
- Reduce `--max-model-len`
- Use a smaller or quantized model
- Enable FP8 KV cache

**Model download fails**:
- Check internet connection
- For gated models, ensure `HUGGING_FACE_HUB_TOKEN` is set correctly
- Verify token has access to the model

**Slow inference**:
- Check GPU utilization: `nvidia-smi`
- Increase `--gpu-memory-utilization` if GPU memory is underutilized
- Consider using a quantized model for faster inference

## Supported Models

vLLM supports most HuggingFace Transformers models. Popular choices:

- **Meta Llama**: `meta-llama/Meta-Llama-3-8B-Instruct`
- **Mistral**: `mistralai/Mistral-7B-Instruct-v0.2`
- **Gemma**: `google/gemma-7b-it`
- **Phi**: `microsoft/phi-2`
- **Qwen**: `Qwen/Qwen2-7B-Instruct`

Check the [vLLM documentation](https://docs.vllm.ai/en/latest/models/supported_models.html) for the full list.

## Additional Resources

- [vLLM GitHub](https://github.com/vllm-project/vllm)
- [vLLM Documentation](https://docs.vllm.ai/)
- [OpenAI API Reference](https://platform.openai.com/docs/api-reference)
