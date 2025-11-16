#!/bin/bash
#
# CUDA Toolkit bashrc Configuration Helper
# Adds CUDA paths to ~/.bashrc
#

set -e

echo "==================================="
echo "  CUDA Toolkit bashrc Helper"
echo "==================================="
echo ""
echo "Which CUDA Toolkit version did you install?"
echo ""
echo "Download: https://developer.nvidia.com/cuda-toolkit-archive"
echo ""
echo "Available versions:"
echo "  1) CUDA 11.8"
echo "  2) CUDA 12.0"
echo "  3) CUDA 12.1"
echo "  4) CUDA 12.2"
echo "  5) CUDA 12.3"
echo "  6) CUDA 12.4"
echo "  7) CUDA 12.5"
echo "  8) CUDA 12.6"
echo "  9) CUDA 12.7"
echo " 10) CUDA 12.8"
echo " 11) CUDA 12.9"
echo " 12) CUDA 13.0"
echo " 13) CUDA 13.1"
echo " 14) CUDA 13.2"
echo " 15) Other version (manual input)"
echo ""
read -p "Choose an option (1-15): " choice

case $choice in
    1)
        VERSION="11.8"
        ;;
    2)
        VERSION="12.0"
        ;;
    3)
        VERSION="12.1"
        ;;
    4)
        VERSION="12.2"
        ;;
    5)
        VERSION="12.3"
        ;;
    6)
        VERSION="12.4"
        ;;
    7)
        VERSION="12.5"
        ;;
    8)
        VERSION="12.6"
        ;;
    9)
        VERSION="12.7"
        ;;
    10)
        VERSION="12.8"
        ;;
    11)
        VERSION="12.9"
        ;;
    12)
        VERSION="13.0"
        ;;
    13)
        VERSION="13.1"
        ;;
    14)
        VERSION="13.2"
        ;;
    15)
        read -p "Enter the CUDA version (e.g. 12.1): " VERSION
        ;;
    *)
        echo "Invalid selection!"
        exit 1
        ;;
esac

CUDA_PATH="/usr/local/cuda-${VERSION}"

# Check if CUDA Toolkit is actually installed
if [ ! -d "$CUDA_PATH" ]; then
    echo ""
    echo "⚠️  Warning: CUDA ${VERSION} not found at $CUDA_PATH"
    echo ""
    echo "Please install the CUDA Toolkit first:"
    echo "https://developer.nvidia.com/cuda-toolkit-archive"
    echo ""
    read -p "Continue anyway? (y/n): " continue
    if [[ $continue != "y" && $continue != "Y" ]]; then
        exit 1
    fi
fi

echo ""
echo "Adding CUDA ${VERSION} paths to ~/.bashrc..."
echo ""

# Create backup
cp ~/.bashrc ~/.bashrc.backup.$(date +%Y%m%d_%H%M%S)

# Add CUDA configuration
cat >> ~/.bashrc << EOF

# CUDA ${VERSION}
export PATH=${CUDA_PATH}/bin\${PATH:+:\${PATH}}
export LD_LIBRARY_PATH=${CUDA_PATH}/lib64\${LD_LIBRARY_PATH:+:\${LD_LIBRARY_PATH}}
EOF

echo "✅ CUDA ${VERSION} paths added to ~/.bashrc!"
echo ""
echo "Added lines:"
echo "  export PATH=${CUDA_PATH}/bin\${PATH:+:\${PATH}}"
echo "  export LD_LIBRARY_PATH=${CUDA_PATH}/lib64\${LD_LIBRARY_PATH:+:\${LD_LIBRARY_PATH}}"
echo ""
echo "Activate the changes with:"
echo "  source ~/.bashrc"
echo ""
echo "Or log in again."
echo ""

# Optional: Create symlink
if [ -d "$CUDA_PATH" ]; then
    read -p "Create symlink /usr/local/cuda -> $CUDA_PATH? (y/n): " create_symlink
    if [[ $create_symlink == "y" || $create_symlink == "Y" ]]; then
        sudo ln -sf $CUDA_PATH /usr/local/cuda
        echo "✅ Symlink created: /usr/local/cuda -> $CUDA_PATH"
    fi
fi

echo ""
echo "Done! 🎉"
echo ""
echo "Test the installation with:"
echo "  nvcc --version"

