# Ollama Tools

Tools and guides for working with Ollama.

## Tools

### [ollama-fleet-manager](./ollama-fleet-manager/)

Declarative model fleet management for Ollama. Define your desired models in a `models.txt` file and sync with one command.

```bash
cd ollama-fleet-manager
./ollama_sync.sh
```

**Use cases**:
- Team consistency (commit model lists to git)
- Automated deployments
- CI/CD pipelines
- Multi-environment fleet management

## Guides

### [ollama-network-access.md](./ollama-network-access.md)

Guide for configuring network access to Ollama instances.

## Related

- [Ollama Docker Setup](../docker/ollama/) - Docker Compose setup for running Ollama
