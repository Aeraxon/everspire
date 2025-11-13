#!/bin/bash

# Universal Docker Installation Script
# Installiert Docker nach offizieller Methode mit optionalem GPU-Support und Portainer
# Script sollte mit normalen User-Rechten ausgeführt werden (nicht als root)

set -e  # Bei Fehler abbrechen

echo "========================================"
echo "Docker Installation Script"
echo "========================================"
echo ""

# ============================================================================
# Abfragen am Anfang
# ============================================================================

read -p "GPU-Support installieren? (j/n): " GPU_CHOICE
read -p "Portainer installieren? (0=Nein, 1=CE Standalone, 2=Agent): " PORTAINER_CHOICE

echo ""
echo "Zusammenfassung:"
echo "  - GPU-Support: $GPU_CHOICE"
echo "  - Portainer: $PORTAINER_CHOICE"
echo ""
read -p "Installation starten? (j/n): " CONFIRM

if [ "$CONFIRM" != "j" ] && [ "$CONFIRM" != "J" ]; then
    echo "Installation abgebrochen."
    exit 0
fi

echo ""

# ============================================================================
# Phase 1: Docker Installation
# ============================================================================

echo "[Phase 1] Docker Installation"
echo "------------------------------"
echo ""

echo "→ Entferne alte Docker-Pakete..."
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    sudo apt-get remove -y $pkg 2>/dev/null || true
done

echo "→ System aktualisieren und Abhängigkeiten installieren..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl

echo "→ Docker GPG-Key hinzufügen..."
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "→ Docker Repository hinzufügen..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "→ APT-Index aktualisieren..."
sudo apt-get update

echo "→ Docker-Pakete installieren..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "→ Benutzer '$USER' zur docker-Gruppe hinzufügen..."
sudo usermod -aG docker $USER

echo ""
echo "✓ Docker Installation abgeschlossen!"
echo ""

# ============================================================================
# Phase 2: NVIDIA GPU-Support (optional)
# ============================================================================

if [ "$GPU_CHOICE" == "j" ] || [ "$GPU_CHOICE" == "J" ]; then
    echo "[Phase 2] NVIDIA Container Toolkit Installation"
    echo "------------------------------------------------"
    echo ""

    echo "→ NVIDIA Container Toolkit Repository hinzufügen..."
    sudo curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
      sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

    sudo curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
      sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
      sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

    echo "→ NVIDIA Container Toolkit installieren..."
    sudo apt-get update
    sudo apt-get install -y nvidia-container-toolkit

    echo "→ Docker Runtime für NVIDIA konfigurieren..."
    sudo nvidia-ctk runtime configure --runtime=docker

    echo ""
    echo "✓ NVIDIA Container Toolkit installiert!"
    echo ""
    echo "HINWEIS: Falls dies ein unprivileged LXC Container ist, muss noch"
    echo "         'no-cgroups' aktiviert werden mit:"
    echo "         sudo nvidia-ctk config --set nvidia-container-cli.no-cgroups=true --in-place"
    echo ""
else
    echo "[Phase 2] GPU-Support übersprungen"
    echo ""
fi

# ============================================================================
# Phase 3: Portainer Installation (optional)
# ============================================================================

if [ "$PORTAINER_CHOICE" == "1" ]; then
    echo "[Phase 3] Portainer CE Installation"
    echo "------------------------------------"
    echo ""

    echo "→ Erstelle Portainer-Verzeichnisstruktur..."
    mkdir -p $HOME/docker/portainer/volumes/portainer/data

    echo "→ Erstelle docker-compose.yml..."
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

    echo "→ Starte Portainer..."
    cd $HOME/docker/portainer
    docker compose up -d

    echo ""
    echo "✓ Portainer CE installiert und gestartet!"
    echo "  - WebUI (HTTPS): https://$(hostname -I | awk '{print $1}'):9443"
    echo "  - Edge Port:     Port 8000"
    echo ""

elif [ "$PORTAINER_CHOICE" == "2" ]; then
    echo "[Phase 3] Portainer Agent Installation"
    echo "---------------------------------------"
    echo ""

    echo "→ Starte Portainer-Agent..."
    docker run -d \
      -p 9001:9001 \
      --name portainer_agent \
      --restart=always \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v /var/lib/docker/volumes:/var/lib/docker/volumes \
      -v /:/host \
      portainer/agent:latest

    echo ""
    echo "✓ Portainer-Agent installiert und gestartet!"
    echo "  - Agent Port: 9001"
    echo "  - Verbinde von deinem Portainer-Server aus mit: $(hostname -I | awk '{print $1}'):9001"
    echo ""
else
    echo "[Phase 3] Portainer-Installation übersprungen"
    echo ""
fi

# ============================================================================
# Abschluss
# ============================================================================

echo "========================================"
echo "Installation erfolgreich abgeschlossen!"
echo "========================================"
echo ""
echo "Installierte Komponenten:"
echo "  - Docker: $(docker --version)"

if [ "$GPU_CHOICE" == "j" ] || [ "$GPU_CHOICE" == "J" ]; then
    echo "  - NVIDIA Container Toolkit: $(nvidia-ctk --version | head -n1)"
fi

if [ "$PORTAINER_CHOICE" == "1" ]; then
    echo "  - Portainer CE"
elif [ "$PORTAINER_CHOICE" == "2" ]; then
    echo "  - Portainer Agent"
fi

echo ""
echo "WICHTIG:"
echo "  - Die Docker-Gruppe wird erst nach einem Reboot oder Re-Login aktiv"
echo "  - Du kannst dich neu einloggen mit: newgrp docker"
echo "  - Oder das System neu starten"
echo ""

if [ "$GPU_CHOICE" == "j" ] || [ "$GPU_CHOICE" == "J" ]; then
    echo "GPU-Test nach dem Reboot:"
    echo "  docker run --rm --gpus all nvidia/cuda:12.6.0-base-ubuntu22.04 nvidia-smi"
    echo ""
fi

read -p "System jetzt neu starten? (j/n): " REBOOT_CHOICE
if [ "$REBOOT_CHOICE" == "j" ] || [ "$REBOOT_CHOICE" == "J" ]; then
    echo "System wird neu gestartet..."
    sudo reboot
else
    echo "Bitte später manuell neu starten oder 'newgrp docker' ausführen."
fi
