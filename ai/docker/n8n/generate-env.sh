#!/bin/bash
# Generate .env file with random secrets

set -e

if [ -f .env ]; then
    read -p ".env file already exists. Overwrite? (y/n): " OVERWRITE
    if [ "$OVERWRITE" != "y" ] && [ "$OVERWRITE" != "Y" ]; then
        echo "Aborted."
        exit 0
    fi
fi

echo "Generating .env file with random secrets..."

# Generate random secrets
N8N_ENCRYPTION_KEY=$(openssl rand -base64 32)
N8N_JWT_SECRET=$(openssl rand -base64 32)
QDRANT_API_KEY=$(openssl rand -base64 32)
POSTGRES_PASSWORD=$(openssl rand -base64 32)

# Create .env file
cat > .env <<EOF
POSTGRES_USER=n8n
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
POSTGRES_DB=n8n

QDRANT_API_KEY=${QDRANT_API_KEY}

N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}
N8N_USER_MANAGEMENT_JWT_SECRET=${N8N_JWT_SECRET}
EOF

echo "✓ .env file created with secure random secrets!"
echo ""
echo "IMPORTANT: Keep this file secure and never commit it to git."
echo "You can now run: docker compose up -d"
echo ""
echo "Cleaning up setup script..."
rm -- "$0"
