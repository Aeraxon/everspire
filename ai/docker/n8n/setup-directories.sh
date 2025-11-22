#!/bin/bash
# Create required directories for n8n stack

set -e

echo "Creating n8n directories..."

mkdir -p n8n/backup
mkdir -p shared
mkdir -p consume
mkdir -p output

echo "Done! Directories created with your user permissions."
echo "You can now run: ./generate-env.sh"
echo ""
echo "Cleaning up setup script..."
rm -- "$0"
