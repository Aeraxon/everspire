#!/bin/bash
#
# Python Version Installer for Ubuntu 24.04
# Installs specific Python version with pip and venv
#

set -e

echo "==================================="
echo "  Python Version Installer"
echo "==================================="
echo ""
echo "Which Python version would you like to install?"
echo ""
echo "  1) Python 3.8"
echo "  2) Python 3.9"
echo "  3) Python 3.10"
echo "  4) Python 3.11"
echo "  5) Python 3.12"
echo "  6) Python 3.13"
echo ""
read -p "Choose an option (1-6): " choice

case $choice in
    1)
        VERSION="3.8"
        ;;
    2)
        VERSION="3.9"
        ;;
    3)
        VERSION="3.10"
        ;;
    4)
        VERSION="3.11"
        ;;
    5)
        VERSION="3.12"
        ;;
    6)
        VERSION="3.13"
        ;;
    *)
        echo "Invalid selection!"
        exit 1
        ;;
esac

echo ""
echo "Installing Python ${VERSION}..."
echo ""

# Update package lists
sudo apt update

# Install software-properties-common for add-apt-repository
sudo apt install -y software-properties-common

# Add deadsnakes PPA (for Python versions not in Ubuntu repos)
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt update

# Install Python, venv, and dev headers
sudo apt install -y \
    python${VERSION} \
    python${VERSION}-venv \
    python${VERSION}-dev

echo ""
echo "✅ Python ${VERSION} successfully installed!"
echo ""
echo "Available commands:"
echo "  python${VERSION} --version"
echo "  python${VERSION} -m venv myenv"
echo ""
echo "⚠️  IMPORTANT: System Python (python3) was NOT changed!"
echo "   Use Python ${VERSION} via venvs:"
echo ""
echo "   python${VERSION} -m venv myenv"
echo "   source myenv/bin/activate"
echo "   pip install ..."
echo ""

echo ""
echo "Done! 🎉"

