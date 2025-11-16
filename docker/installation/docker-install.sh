#!/bin/bash

# Universal Docker Installation Script
# Installs Docker using official method with optional GPU support and Portainer
# Script should be run with normal user privileges (not as root)

set -e  # Exit on error

echo "========================================"
echo "Docker Installation Script"
echo "========================================"
echo ""

# ============================================================================
# Initial questions
# ============================================================================

read -p "Install GPU support? (y/n): " GPU_CHOICE
read -p "Install Portainer? (0=No, 1=CE Standalone, 2=Agent): " PORTAINER_CHOICE

echo ""
echo "Summary:"
echo "  - GPU Support: $GPU_CHOICE"
echo "  - Portainer: $PORTAINER_CHOICE"
echo ""
read -p "Start installation? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "Installation cancelled."
    exit 0
fi

echo ""

# ============================================================================
# Phase 1: Docker Installation
# ============================================================================

echo "[Phase 1] Docker Installation"
echo "------------------------------"
echo ""

echo "→ Removing old Docker packages..."
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    sudo apt-get remove -y $pkg 2>/dev/null || true
done

echo "→ Updating system and installing dependencies..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl

echo "→ Adding Docker GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "→ Adding Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "→ Updating APT index..."
sudo apt-get update

echo "→ Installing Docker packages..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "→ Adding user '$USER' to docker group..."
sudo usermod -aG docker $USER

echo ""
echo "✓ Docker installation completed!"
echo ""

# ============================================================================
# Phase 2: NVIDIA GPU-Support (optional)
# ============================================================================

if [ "$GPU_CHOICE" == "y" ] || [ "$GPU_CHOICE" == "Y" ]; then
    echo "[Phase 2] NVIDIA Container Toolkit Installation"
    echo "------------------------------------------------"
    echo ""

    echo "→ Adding NVIDIA Container Toolkit repository..."
    sudo curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
      sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

    sudo curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
      sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
      sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

    echo "→ Installing NVIDIA Container Toolkit..."
    sudo apt-get update
    sudo apt-get install -y nvidia-container-toolkit

    echo "→ Configuring Docker runtime for NVIDIA..."
    sudo nvidia-ctk runtime configure --runtime=docker

    echo ""
    echo "✓ NVIDIA Container Toolkit installed!"
    echo ""
    echo "NOTE: If this is an unprivileged LXC container, you need to enable"
    echo "      'no-cgroups' with:"
    echo "      sudo nvidia-ctk config --set nvidia-container-cli.no-cgroups=true --in-place"
    echo ""
else
    echo "[Phase 2] GPU support skipped"
    echo ""
fi

# ============================================================================
# Phase 3: Portainer Installation (optional)
# ============================================================================

if [ "$PORTAINER_CHOICE" == "1" ]; then
    echo "[Phase 3] Portainer CE Installation"
    echo "------------------------------------"
    echo ""

    echo "→ Creating Portainer directory structure..."
    mkdir -p $HOME/docker/portainer/volumes/portainer/data

    echo "→ Creating docker-compose.yml..."
    cat <<'EOF' > $HOME/docker/portainer/docker-compose.yml
services:
  portainer:
    container_name: portainer
    image: portainer/portainer-ce:latest
    ports:
      - "8000:8000/tcp"
      - "9443:9443/tcp"
    volumes:
      - "./volumes/portainer/data:/data"
      - "/var/run/docker.sock:/var/run/docker.sock"
    restart: always
EOF

    echo "→ Starting Portainer..."
    cd $HOME/docker/portainer
    docker compose up -d

    echo ""
    echo "✓ Portainer CE installed and started!"
    echo "  - WebUI (HTTPS): https://$(hostname -I | awk '{print $1}'):9443"
    echo "  - Edge Port:     Port 8000"
    echo ""

elif [ "$PORTAINER_CHOICE" == "2" ]; then
    echo "[Phase 3] Portainer Agent Installation"
    echo "---------------------------------------"
    echo ""

    echo "→ Starting Portainer Agent..."
    docker run -d \
      -p 9001:9001 \
      --name portainer_agent \
      --restart=always \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v /var/lib/docker/volumes:/var/lib/docker/volumes \
      -v /:/host \
      portainer/agent:latest

    echo ""
    echo "✓ Portainer Agent installed and started!"
    echo "  - Agent Port: 9001"
    echo "  - Connect from your Portainer server to: $(hostname -I | awk '{print $1}'):9001"
    echo ""
else
    echo "[Phase 3] Portainer installation skipped"
    echo ""
fi

# ============================================================================
# Completion
# ============================================================================

echo "========================================"
echo "Installation completed successfully!"
echo "========================================"
echo ""
echo "Installed components:"
echo "  - Docker: $(docker --version)"

if [ "$GPU_CHOICE" == "y" ] || [ "$GPU_CHOICE" == "Y" ]; then
    echo "  - NVIDIA Container Toolkit: $(nvidia-ctk --version | head -n1)"
fi

if [ "$PORTAINER_CHOICE" == "1" ]; then
    echo "  - Portainer CE"
elif [ "$PORTAINER_CHOICE" == "2" ]; then
    echo "  - Portainer Agent"
fi

echo ""
echo "IMPORTANT:"
echo "  - Docker group will be active only after reboot or re-login"
echo "  - You can re-login with: newgrp docker"
echo "  - Or restart the system"
echo ""

if [ "$GPU_CHOICE" == "y" ] || [ "$GPU_CHOICE" == "Y" ]; then
    echo "GPU test after reboot:"
    echo "  docker run --rm --gpus all nvidia/cuda:12.6.0-base-ubuntu22.04 nvidia-smi"
    echo ""
fi

read -p "Restart system now? (y/n): " REBOOT_CHOICE
if [ "$REBOOT_CHOICE" == "y" ] || [ "$REBOOT_CHOICE" == "Y" ]; then
    echo "System is restarting..."
    sudo reboot
else
    echo "Please restart manually later or run 'newgrp docker'."
fi
