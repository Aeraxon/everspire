#!/bin/bash

# Supabase Setup Script
# This script downloads all required configuration files from the official Supabase repository

set -e

echo "========================================="
echo "Supabase Self-Hosted Setup"
echo "========================================="
echo ""

# Check if .env exists
if [ -f .env ]; then
    read -p ".env file already exists. Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Keeping existing .env file..."
    else
        echo "Copying .env.example to .env..."
        cp .env.example .env
        echo "✓ Created .env file"
        echo ""
        echo "⚠️  IMPORTANT: Edit the .env file and change all secrets before starting!"
    fi
else
    echo "Creating .env file from template..."
    cp .env.example .env
    echo "✓ Created .env file"
    echo ""
    echo "⚠️  IMPORTANT: Edit the .env file and change all secrets before starting!"
fi

echo ""
echo "Creating volume directories..."

# Create volume directories
mkdir -p volumes/db
mkdir -p volumes/api
mkdir -p volumes/logs
mkdir -p volumes/pooler
mkdir -p volumes/functions/main

echo "✓ Created volume directories"
echo ""

echo "Downloading Supabase configuration files from official repository..."

# Download Kong configuration
curl -L https://raw.githubusercontent.com/supabase/supabase/master/docker/volumes/api/kong.yml \
  -o volumes/api/kong.yml

# Download database initialization scripts
curl -L https://raw.githubusercontent.com/supabase/supabase/master/docker/volumes/db/_supabase.sql \
  -o volumes/db/_supabase.sql

curl -L https://raw.githubusercontent.com/supabase/supabase/master/docker/volumes/db/roles.sql \
  -o volumes/db/roles.sql

curl -L https://raw.githubusercontent.com/supabase/supabase/master/docker/volumes/db/jwt.sql \
  -o volumes/db/jwt.sql

curl -L https://raw.githubusercontent.com/supabase/supabase/master/docker/volumes/db/realtime.sql \
  -o volumes/db/realtime.sql

curl -L https://raw.githubusercontent.com/supabase/supabase/master/docker/volumes/db/webhooks.sql \
  -o volumes/db/webhooks.sql

curl -L https://raw.githubusercontent.com/supabase/supabase/master/docker/volumes/db/logs.sql \
  -o volumes/db/logs.sql

curl -L https://raw.githubusercontent.com/supabase/supabase/master/docker/volumes/db/pooler.sql \
  -o volumes/db/pooler.sql 2>/dev/null || echo "Note: pooler.sql not found (optional)"

# Download pooler configuration
curl -L https://raw.githubusercontent.com/supabase/supabase/master/docker/volumes/pooler/pooler.exs \
  -o volumes/pooler/pooler.exs

# Download Vector logging configuration
curl -L https://raw.githubusercontent.com/supabase/supabase/master/docker/volumes/logs/vector.yml \
  -o volumes/logs/vector.yml

# Download main edge function
curl -L https://raw.githubusercontent.com/supabase/supabase/master/docker/volumes/functions/main/index.ts \
  -o volumes/functions/main/index.ts

echo "✓ Downloaded all configuration files"
echo ""

echo "========================================="
echo "Setup Complete!"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Edit the .env file and update all secrets (marked with CHANGE THIS)"
echo "2. Generate proper JWT tokens using: https://supabase.com/docs/guides/self-hosting/docker#generate-api-keys"
echo "3. Review the configuration in docker-compose.yml"
echo "4. Start Supabase: docker compose up -d"
echo "5. Access Studio at: http://localhost:8000"
echo ""
echo "For detailed instructions, see README.md"
echo ""
