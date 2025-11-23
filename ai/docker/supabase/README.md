# Supabase Self-Hosted (Official Setup)

## Why this setup?

The official Supabase deployment guide is powerful but **tedious to follow** - lots of manual steps, file downloads, and configuration scattered across documentation. This setup stays **as close as possible to the official deployment** (almost identical), but makes it **directly implementable and reproducible**. No fiddling around - just run the scripts and start.

**What we provide:**
- Automated download of all official config files
- Automatic secret generation
- Clear, linear setup process
- Ready-to-use configuration for experimentation and development

## Quick Start

1. **Download config files**:
   ```bash
   ./setup.sh
   ```

2. **Generate secrets**:
   ```bash
   ./generate-secrets.sh
   ```

3. **Generate JWT tokens**:
   - Go to: https://supabase.com/docs/guides/self-hosting/docker
   - Scroll to "Generate API Keys"
   - Enter the `JWT_SECRET` from the script output
   - Generate both `ANON_KEY` and `SERVICE_ROLE_KEY`

4. **Edit .env**:
   ```bash
   nano .env
   # Add the generated ANON_KEY and SERVICE_ROLE_KEY
   ```

5. **Start Supabase**:
   ```bash
   docker compose up -d
   ```

6. **Access Studio**: http://localhost:8000

## Important Notes

**Self-hosted = 1 project per deployment**. For multiple projects, use schemas (see below).

**RLS is enabled by default** on tables created in Studio. If queries return empty results, either disable RLS or use `SERVICE_ROLE_KEY`.

## Custom Schemas

```sql
-- In Studio SQL Editor
CREATE SCHEMA myapp;
GRANT USAGE ON SCHEMA myapp TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA myapp TO anon, authenticated, service_role;
```

```bash
# In .env
PGRST_DB_SCHEMAS=public,storage,graphql_public,myapp

# Restart
docker compose restart rest
```

## n8n Integration

Configure the Supabase node in n8n:
- **Host**: `http://YOUR_HOST_IP:8000` (replace with your server IP or hostname)
- **Service Role Secret**: Use `SERVICE_ROLE_KEY` from `.env`
- **Custom Schema** (optional): Enable and enter schema name (e.g., `myapp`)

If using custom schemas, add them to `PGRST_DB_SCHEMAS` in `.env` and restart:
```bash
docker compose restart rest
```

## Commands

```bash
# Logs
docker compose logs -f [service]

# Status
docker compose ps

# Stop
docker compose down

# Stop + remove data
docker compose down -v

# Restart service
docker compose restart [service]

# Backup
docker exec supabase-db pg_dump -U postgres postgres > backup.sql

# Restore
cat backup.sql | docker exec -i supabase-db psql -U postgres postgres
```

## Configuration

Essential `.env` variables:
- `POSTGRES_PASSWORD` - Database password
- `JWT_SECRET` - Signs all JWTs (32+ chars)
- `ANON_KEY` / `SERVICE_ROLE_KEY` - API keys (must be JWTs signed with JWT_SECRET)
- `PGRST_DB_SCHEMAS` - Exposed schemas (e.g., `public,storage,graphql_public,myapp`)
- `SITE_URL` - Your frontend URL for auth redirects
- `KONG_HTTP_PORT` - Studio access port (default: 8000)

## Troubleshooting

**Port 8000 already in use**:
```bash
# Change KONG_HTTP_PORT in .env
KONG_HTTP_PORT=8001
docker compose down && docker compose up -d
```

**Cannot access Studio**:
- Check `DASHBOARD_USERNAME` and `DASHBOARD_PASSWORD` in `.env`
- Verify container is running: `docker compose ps`
- Check logs: `docker compose logs kong studio`

**401 Unauthorized errors**:
- Verify `ANON_KEY` and `SERVICE_ROLE_KEY` are valid JWTs signed with your `JWT_SECRET`
- Regenerate keys using the official generator
- Ensure no extra whitespace in `.env` values

**Configuration changes not applied**:
```bash
docker compose down
docker compose up -d
```

**Service won't start**:
```bash
# Check specific service logs
docker compose logs [service]

# Common issues:
# - db: Check volumes/db/ directory permissions
# - kong: Verify kong.yml exists in volumes/api/
# - auth: Database not ready (wait a few seconds)
```

**Empty query results**:
- RLS (Row Level Security) is enabled by default on tables created in Studio
- Use `SERVICE_ROLE_KEY` to bypass RLS
- Or disable RLS: `ALTER TABLE your_table DISABLE ROW LEVEL SECURITY;`

**Custom schema not accessible**:
- Add schema to `PGRST_DB_SCHEMAS` in `.env`
- Grant permissions in SQL Editor
- Restart PostgREST: `docker compose restart rest`
