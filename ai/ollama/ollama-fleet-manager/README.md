# ollama-fleet-manager

Declarative model fleet management for Ollama. Define your models in a file, sync with one command.

## Quick Start

```bash
# 1. Create your model fleet definition
cat > models.txt << EOF
llama3.2:latest
qwen2.5-coder:7b
bge-m3:latest
EOF

# 2. Sync your fleet
./ollama_sync.sh
```

## Features

- **Declarative fleet definition**: Define desired state in `models.txt`
- **Automatic cleanup**: Removes models not in your fleet
- **Automatic provisioning**: Pulls missing models
- **Comment support**: Lines starting with `#` are ignored
- **Tag normalization**: Handles both `model` and `model:latest` syntax
- **Team consistency**: Commit `models.txt` to git for synchronized fleet

## Usage

### Fleet Sync

```bash
./ollama_sync.sh
```

### Fleet Definition Format

```txt
# models.txt - define your model fleet

# Large models
llama3.2:70b
mixtral:8x7b

# Code models
qwen2.5-coder:7b
deepseek-coder:6.7b

# Embedding models
bge-m3:latest
nomic-embed-text:latest
```

### Output

```
Ollama Model Sync
=================

Gewünschte Modelle: llama3.2 qwen2.5-coder:7b bge-m3:latest
Installierte Modelle: llama3.2 old-model:latest

Prüfe auf zu löschende Modelle...
❌ Lösche: old-model:latest
   ✓ Erfolgreich gelöscht

Prüfe auf fehlende Modelle...
⬇️  Pulling: qwen2.5-coder:7b
   ✓ Erfolgreich installiert
⬇️  Pulling: bge-m3:latest
   ✓ Erfolgreich installiert

=================
Sync abgeschlossen!
Gelöscht: 1 Modell(e)
Installiert: 2 Modell(e)
```

## Automation

### Cron Job

```bash
# Daily fleet sync at 3 AM
0 3 * * * cd /path/to/ollama-fleet-manager && ./ollama_sync.sh >> sync.log 2>&1
```

### Git Integration

```bash
# Sync fleet on git pull
git pull && ./ollama_sync.sh
```

### CI/CD Pipeline

```yaml
# .github/workflows/sync-models.yml
name: Sync Ollama Model Fleet
on:
  push:
    paths:
      - 'ai/ollama/ollama-fleet-manager/models.txt'
jobs:
  sync:
    runs-on: self-hosted
    steps:
      - uses: actions/checkout@v4
      - name: Sync model fleet
        run: |
          cd ai/ollama/ollama-fleet-manager
          ./ollama_sync.sh
```

## Use Cases

- **Development teams**: Share consistent model fleet via git
- **Server management**: Declarative model fleet provisioning
- **CI/CD**: Automated model deployment
- **Fleet cleanup**: Automatically remove unused models
- **Multi-environment**: Different fleets for dev/staging/prod

## Requirements

- Bash
- Ollama CLI installed and accessible via `ollama` command

## Docker Integration

Works seamlessly with Docker-based Ollama:

```bash
# Modify script to use docker exec
docker exec ollama-container ollama list
docker exec ollama-container ollama pull model:tag
docker exec ollama-container ollama rm model:tag
```

## Fleet Patterns

### Development Fleet

```txt
# Small, fast models for development
llama3.2:3b
qwen2.5-coder:7b
```

### Production Fleet

```txt
# Larger, higher quality models
llama3.2:70b
qwen2.5-coder:32b
mistral:8x7b
```

### Embedding Fleet

```txt
# Specialized embedding models
bge-m3:latest
nomic-embed-text:latest
mxbai-embed-large:latest
```

## Tips

- Start with small models for testing
- Use specific tags (`:7b`, `:latest`) for reproducibility
- Comment out models temporarily instead of deleting
- Keep `models.txt` in version control for team consistency
- Different fleets for different environments (dev/prod)
- Use `.txt` extension for better git diffs

## Troubleshooting

**Script can't find Ollama**:
- Ensure `ollama` is in PATH
- Or modify script to use full path: `/usr/local/bin/ollama`

**Permission denied**:
```bash
chmod +x ollama_sync.sh
```

**Models not syncing**:
- Check Ollama is running: `ollama list`
- Verify network connectivity
- Check disk space
