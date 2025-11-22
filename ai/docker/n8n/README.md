# n8n Workflow Automation Stack

n8n is a workflow automation platform with PostgreSQL database and Qdrant vector database for AI capabilities.

## Download

Download the required files:

```bash
wget https://raw.githubusercontent.com/Aeraxon/everspire/main/ai/docker/n8n/docker-compose.yml
wget https://raw.githubusercontent.com/Aeraxon/everspire/main/ai/docker/n8n/.env.example
wget https://raw.githubusercontent.com/Aeraxon/everspire/main/ai/docker/n8n/setup-directories.sh
wget https://raw.githubusercontent.com/Aeraxon/everspire/main/ai/docker/n8n/generate-env.sh
chmod +x setup-directories.sh generate-env.sh
```

## Privacy Warning

**IMPORTANT**: n8n phones home and sends telemetry data to the developers. At minimum, your email address is transmitted when you register/sign up - this has been confirmed by receiving an email from n8n after registration.

The current configuration has diagnostics and personalization disabled:
```yaml
- N8N_DIAGNOSTICS_ENABLED=false
- N8N_PERSONALIZATION_ENABLED=false
```

However, this may not prevent all data transmission. If privacy is a concern, consider monitoring network traffic or using firewall rules to block outbound connections.

## Version Note

This setup uses n8n version **1.118.2** instead of the latest version due to a known bug in version 1.120.4 that causes the frontend to crash with the error: "Cannot read properties of undefined (reading 'ldap')". Version 1.118.2 is stable and tested.

## Quick Start

1. **Create required directories**:
   ```bash
   ./setup-directories.sh
   ```
   This creates directories with your user permissions (if Docker creates them, they'll be owned by root).

2. **Edit docker-compose.yml**:
   - Replace `my-host-name` with your actual hostname or domain
   - Adjust `GENERIC_TIMEZONE` if needed (default: UTC)

3. **Generate .env file with random secrets**:
   ```bash
   ./generate-env.sh
   ```

4. **Start the stack**:
   ```bash
   docker compose up -d
   ```

5. **Access n8n**: `http://localhost:5678`
