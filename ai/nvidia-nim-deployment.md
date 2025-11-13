# NVIDIA NIM Deployment

Deployment von NVIDIA NIMs (Neural Inference Microservices) in Docker mit GPU-Zugriff.

## Voraussetzungen

- Docker mit GPU-Support installiert
- NVIDIA GPU im System
- Test erfolgreich:
  ```bash
  docker run --rm --gpus all nvidia/cuda:12.6.0-base-ubuntu22.04 nvidia-smi
  ```

## 1. NGC API Key besorgen

1. https://org.ngc.nvidia.com/setup/api-key
2. Login mit NVIDIA Account
3. **Generate Personal Key**
4. **NGC Catalog** auswählen
5. Key kopieren (ca. 40-50 Zeichen)

**Wichtig:** Key hat **KEIN** `nvapi-` Präfix!

## 2. NGC API Key konfigurieren

### Temporär (aktuelle Session)

```bash
export NGC_API_KEY="ZjhjYzYt..."  # Ohne nvapi- Präfix!
```

### Permanent

```bash
echo 'export NGC_API_KEY="ZjhjYzYt..."' >> ~/.bashrc
source ~/.bashrc
```

### Verifizieren

```bash
echo $NGC_API_KEY
```

Sollte kompletten Key zeigen (40-50 Zeichen).

## 3. Bei NVIDIA Container Registry einloggen

### Interaktiv

```bash
docker login nvcr.io
```

Eingeben:
- **Username:** `$oauthtoken` (exakt mit $-Zeichen!)
- **Password:** Dein NGC_API_KEY

### Automatisch

```bash
echo "$NGC_API_KEY" | docker login nvcr.io --username '$oauthtoken' --password-stdin
```

Erfolg:
```
Login Succeeded
```

Warnung über unverschlüsselte Credentials ist normal.

## 4. NIM deployen

### Cache-Verzeichnis erstellen

**Wichtig:** Vor `docker run` ausführen!

```bash
export LOCAL_NIM_CACHE=~/.cache/nim
mkdir -p "$LOCAL_NIM_CACHE"
```

### Maxine BNR NIM

Background Noise Removal:

```bash
docker run -d \
  --name maxine-bnr \
  --runtime=nvidia \
  --gpus all \
  --shm-size=8GB \
  -e NGC_API_KEY=$NGC_API_KEY \
  -e MAXINE_MAX_CONCURRENCY_PER_GPU=1 \
  -e FILE_SIZE_LIMIT=36700160 \
  -p 8000:8000 \
  -p 8001:8001 \
  -v "$LOCAL_NIM_CACHE:/opt/nim/.cache" \
  --restart unless-stopped \
  nvcr.io/nim/nvidia/maxine-bnr:latest
```

### Llama 3.1 8B Instruct

```bash
export NIM_CACHE=~/.cache/nim/llama31
mkdir -p "$NIM_CACHE"

docker run -d \
  --name llama31-8b \
  --runtime=nvidia \
  --gpus all \
  --shm-size=16GB \
  -e NGC_API_KEY=$NGC_API_KEY \
  -v "$NIM_CACHE:/opt/nim/.cache" \
  -p 8002:8000 \
  --restart unless-stopped \
  nvcr.io/nim/meta/llama-3.1-8b-instruct:latest
```

## 5. Deployment prüfen

### Logs verfolgen

```bash
docker logs -f maxine-bnr
```

Warten auf:
```
Started GRPCInferenceService at 127.0.0.1:9001
Started HTTPService at 127.0.0.1:9000
Started Metrics Service at 127.0.0.1:9002
Maxine GRPC Service: Listening to 0.0.0.0:8001
```

**Erster Start:** Lange (Model Download mehrere GB)
**Weitere Starts:** Schnell (Cache)

### Health Check

```bash
curl http://localhost:8000/health
```

## 6. NIMs testen

### Maxine BNR Python Client

```bash
# Repo klonen
git clone https://github.com/NVIDIA-Maxine/nim-clients
cd nim-clients/bnr

# venv erstellen
python3 -m venv venv
source venv/bin/activate

# Dependencies
pip install -r requirements.txt

# Test (transactional)
python bnr.py --target localhost:8001 --input input.wav --output output.wav

# Test (streaming)
python bnr.py --target localhost:8001 --input input.wav --output output.wav --streaming

# venv deaktivieren
deactivate
```

Falls `python3-venv` fehlt:
```bash
apt install python3-venv
```

### Llama API Test

```bash
curl -X POST http://localhost:8002/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "meta/llama-3.1-8b-instruct",
    "prompt": "Hello, how are you?",
    "max_tokens": 50
  }'
```

## Parameter-Übersicht

| Parameter | Beschreibung |
|-----------|--------------|
| `NGC_API_KEY` | NGC API Key - **Pflicht** für Model Download |
| `NIM_MODEL_PROFILE` | Optimiertes Model für GPU (auto-detect) |
| `MAXINE_MAX_CONCURRENCY_PER_GPU` | Gleichzeitige Requests (Standard: 1) |
| `FILE_SIZE_LIMIT` | Max. Dateigröße Bytes (36700160 = ~35MB) |
| `-p 8000:8000` | HTTP API Port |
| `-p 8001:8001` | gRPC Service Port |
| `--shm-size` | Shared Memory für GPU Operations |
| `-v LOCAL_NIM_CACHE:/opt/nim/.cache` | Model Cache (wichtig!) |

## Docker Compose Setup

### docker-compose.yml

```yaml
services:
  maxine-bnr:
    image: nvcr.io/nim/nvidia/maxine-bnr:latest
    container_name: maxine-bnr
    runtime: nvidia
    environment:
      - NGC_API_KEY=${NGC_API_KEY}
      - MAXINE_MAX_CONCURRENCY_PER_GPU=1
      - FILE_SIZE_LIMIT=36700160
    ports:
      - "8000:8000"
      - "8001:8001"
    volumes:
      - nim-cache:/opt/nim/.cache
    shm_size: '8gb'
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
    restart: unless-stopped

  llama31-8b:
    image: nvcr.io/nim/meta/llama-3.1-8b-instruct:latest
    container_name: llama31-8b
    runtime: nvidia
    environment:
      - NGC_API_KEY=${NGC_API_KEY}
    ports:
      - "8002:8000"
    volumes:
      - llama-cache:/opt/nim/.cache
    shm_size: '16gb'
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
    restart: unless-stopped

volumes:
  nim-cache:
  llama-cache:
```

### .env Datei

```bash
cat > .env << 'EOF'
NGC_API_KEY=ZjhjYzYt...
EOF
```

**Wichtig:** Key OHNE `nvapi-` Präfix!

### Starten

```bash
docker compose up -d
docker compose logs -f
```

## Troubleshooting

### "unauthorized: authentication required"

Nicht eingeloggt oder falscher Key.

```bash
# Erneut einloggen
echo "$NGC_API_KEY" | docker login nvcr.io --username '$oauthtoken' --password-stdin
```

### "empty section between colons"

`$LOCAL_NIM_CACHE` nicht gesetzt.

```bash
export LOCAL_NIM_CACHE=~/.cache/nim
mkdir -p "$LOCAL_NIM_CACHE"
# Dann docker run
```

### "Permission error" / "failed to download model"

**Ursachen:**
1. `NGC_API_KEY` nicht gesetzt
2. Falsches Präfix verwendet (`nvapi-` entfernen!)

```bash
# Key prüfen
echo $NGC_API_KEY  # Sollte ~40-50 Zeichen zeigen

# Richtig exportieren (OHNE nvapi-)
export NGC_API_KEY="ZjhjYzYt..."

# Container neu starten
docker stop maxine-bnr && docker rm maxine-bnr
# Dann erneut docker run
```

### "GPU not found" im Container

GPU-Zugriff funktioniert nicht.

```bash
# Prüfen
docker run --rm --gpus all nvidia/cuda:12.6.0-base-ubuntu22.04 nvidia-smi

# Falls LXC: no-cgroups prüfen
grep "no-cgroups" /etc/nvidia-container-runtime/config.toml
```

Siehe: `nvidia-gpu-in-lxc.md`

### NIM hängt beim Start

Model Download dauert beim ersten Start (mehrere GB).

```bash
# Logs verfolgen
docker logs -f maxine-bnr

# Netzwerk-Bandbreite prüfen
```

### Falsches Model Profil

```bash
# Verfügbare Profile auflisten
docker run -it --rm \
  --runtime=nvidia \
  --gpus all \
  -e NGC_API_KEY=$NGC_API_KEY \
  nvcr.io/nim/nvidia/maxine-bnr:latest \
  list-model-profiles

# Dann korrektes Profil verwenden
```

## API Integration

### Python

```python
import requests

response = requests.post(
    'http://localhost:8002/v1/completions',
    headers={'Content-Type': 'application/json'},
    json={
        'model': 'meta/llama-3.1-8b-instruct',
        'prompt': 'Why is the sky blue?',
        'max_tokens': 100
    }
)
print(response.json()['choices'][0]['text'])
```

### cURL

```bash
curl -X POST http://localhost:8002/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "meta/llama-3.1-8b-instruct",
    "messages": [
      {"role": "user", "content": "Explain quantum computing"}
    ],
    "max_tokens": 150
  }'
```

### JavaScript/TypeScript

```javascript
const response = await fetch('http://localhost:8002/v1/completions', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    model: 'meta/llama-3.1-8b-instruct',
    prompt: 'Why is the sky blue?',
    max_tokens: 100
  })
});
const data = await response.json();
console.log(data.choices[0].text);
```

## Verfügbare NIMs

Weitere NIMs auf: https://catalog.ngc.nvidia.com/

**Beliebte NIMs:**
- `nvcr.io/nim/nvidia/maxine-bnr` - Background Noise Removal
- `nvcr.io/nim/meta/llama-3.1-8b-instruct` - Llama 3.1 8B
- `nvcr.io/nim/meta/llama-3.1-70b-instruct` - Llama 3.1 70B
- `nvcr.io/nim/nvidia/nemo-retriever-embedding-microservice` - Embeddings
- `nvcr.io/nim/nvidia/nemo-retriever-reranking-microservice` - Reranking

Pattern gleich wie oben, nur Image-Name anpassen.

## Nützliche Befehle

```bash
# Alle NIMs auflisten
docker ps --filter "ancestor=nvcr.io/nim/*"

# Logs aller NIMs
docker logs maxine-bnr
docker logs llama31-8b

# GPU-Nutzung überwachen
nvidia-smi dmon -s u

# Container neu starten
docker restart maxine-bnr

# Alle NIMs stoppen
docker stop $(docker ps -q --filter "ancestor=nvcr.io/nim/*")

# Cache-Größe prüfen
du -sh ~/.cache/nim/*
```

## Best Practices

- **Cache nutzen** - verhindert wiederholte Downloads
- **Model Profile** - NIM wählt automatisch passendes für GPU
- **Shared Memory** - ausreichend groß für Model (8-16GB)
- **Restart Policy** - `unless-stopped` für Production
- **Monitoring** - GPU-Auslastung überwachen
- **Updates** - NIMs regelmäßig aktualisieren (neue Features)
- **Logs** - regelmäßig prüfen auf Errors

## Sicherheit

- **NGC_API_KEY** nicht in Scripts hardcoden
- **Environment Files** (.env) nicht committen (.gitignore)
- **API Ports** nur intern exponieren oder mit Auth sichern
- **Reverse Proxy** für Production mit HTTPS und Auth
- **Resource Limits** setzen in Docker Compose

## Quick Reference

**Deployment-Workflow:**
1. NGC API Key holen
2. Key exportieren: `export NGC_API_KEY="..."`
3. Docker login: `docker login nvcr.io`
4. Cache erstellen: `export LOCAL_NIM_CACHE=~/.cache/nim && mkdir -p "$LOCAL_NIM_CACHE"`
5. NIM starten mit `docker run`
6. Logs prüfen: `docker logs -f <container>`
7. Health check: `curl http://localhost:8000/health`

**Wichtig:**
- ❌ Kein `nvapi-` Präfix beim NGC_API_KEY
- ✅ Cache-Variable VOR `docker run` setzen
- ✅ Erster Start dauert lange (Model Download)
- ✅ Username bei Docker Login: `$oauthtoken`

---

**NVIDIA NIMs bieten optimierte Inference für Production mit automatischem Model-Profil-Selection.**
