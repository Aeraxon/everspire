#!/bin/bash

set -e

echo "========================================="
echo "Supabase Secrets Generator"
echo "========================================="
echo ""

# Check if .env already exists
if [ -f .env ]; then
    read -p ".env already exists. Overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

# Copy template
echo "Creating .env from .env.example..."
cp .env.example .env

# Generate secrets
echo "Generating secrets..."
# Use URL-safe base64 for POSTGRES_PASSWORD (replace + with -, / with _)
POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d '=\n' | tr '+/' '-_')
JWT_SECRET=$(openssl rand -base64 32 | tr -d '=\n')
SECRET_KEY_BASE=$(openssl rand -base64 48 | tr -d '=\n')
PG_META_CRYPTO_KEY=$(openssl rand -base64 32 | tr -d '=\n')
VAULT_ENC_KEY=$(openssl rand -hex 16)
LOGFLARE_PUBLIC_ACCESS_TOKEN=$(openssl rand -base64 32 | tr -d '=\n')
LOGFLARE_PRIVATE_ACCESS_TOKEN=$(openssl rand -base64 32 | tr -d '=\n')
DASHBOARD_PASSWORD=$(openssl rand -base64 24 | tr -d '=\n')
POOLER_TENANT_ID=$(openssl rand -hex 8)

# Replace in .env
echo "Writing secrets to .env..."
sed -i "s|POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=${POSTGRES_PASSWORD}|" .env
sed -i "s|JWT_SECRET=.*|JWT_SECRET=${JWT_SECRET}|" .env
sed -i "s|SECRET_KEY_BASE=.*|SECRET_KEY_BASE=${SECRET_KEY_BASE}|" .env
sed -i "s|PG_META_CRYPTO_KEY=.*|PG_META_CRYPTO_KEY=${PG_META_CRYPTO_KEY}|" .env
sed -i "s|VAULT_ENC_KEY=.*|VAULT_ENC_KEY=${VAULT_ENC_KEY}|" .env
sed -i "s|LOGFLARE_PUBLIC_ACCESS_TOKEN=.*|LOGFLARE_PUBLIC_ACCESS_TOKEN=${LOGFLARE_PUBLIC_ACCESS_TOKEN}|" .env
sed -i "s|LOGFLARE_PRIVATE_ACCESS_TOKEN=.*|LOGFLARE_PRIVATE_ACCESS_TOKEN=${LOGFLARE_PRIVATE_ACCESS_TOKEN}|" .env
sed -i "s|DASHBOARD_PASSWORD=.*|DASHBOARD_PASSWORD=${DASHBOARD_PASSWORD}|" .env
sed -i "s|POOLER_TENANT_ID=.*|POOLER_TENANT_ID=${POOLER_TENANT_ID}|" .env

echo "✓ Generated and saved secrets to .env"
echo ""
echo "========================================="
echo "Next Steps:"
echo "========================================="
echo ""
echo "1. Generate JWT tokens:"
echo "   Go to: https://supabase.com/docs/guides/self-hosting/docker"
echo "   Scroll to 'Generate API Keys' section"
echo ""
echo "   Use this JWT_SECRET: ${JWT_SECRET}"
echo ""
echo "   Generate both ANON_KEY and SERVICE_ROLE_KEY"
echo ""
echo "2. Edit .env and add the generated JWT tokens:"
echo "   - ANON_KEY=..."
echo "   - SERVICE_ROLE_KEY=..."
echo ""
echo "3. Optional: Update DASHBOARD_USERNAME and SITE_URL in .env"
echo ""
echo "4. Start Supabase: docker compose up -d"
echo ""
