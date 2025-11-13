# AI / Machine Learning

AI-Tools, Model-Setup und ML-Frameworks.

## Anleitungen

### ollama-network-access.md
Ollama für Netzwerk-Zugriff konfigurieren (standardmäßig nur localhost).

Update-sichere Methode mit systemd override:
```bash
sudo systemctl edit ollama
# Environment="OLLAMA_HOST=0.0.0.0" hinzufügen
sudo systemctl restart ollama
```

Problem: Nach Ollama-Updates wird Service-Datei überschrieben - Override bleibt erhalten.

### nvidia-nim-deployment.md
NVIDIA NIMs (Neural Inference Microservices) in Docker deployen.

Quick Start:
```bash
export NGC_API_KEY="..."  # OHNE nvapi- Präfix!
docker login nvcr.io  # Username: $oauthtoken
export LOCAL_NIM_CACHE=~/.cache/nim && mkdir -p "$LOCAL_NIM_CACHE"
docker run -d --runtime=nvidia --gpus all -e NGC_API_KEY=$NGC_API_KEY \
  -v "$LOCAL_NIM_CACHE:/opt/nim/.cache" -p 8000:8000 -p 8001:8001 \
  nvcr.io/nim/nvidia/maxine-bnr:latest
```

Wichtig: Erster Start dauert lange (Model Download).
