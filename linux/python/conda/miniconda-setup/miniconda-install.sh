#!/usr/bin/env bash
set -euo pipefail

# Installationsverzeichnis anlegen
mkdir -p "$HOME/miniconda3"

# Miniconda-Installer herunterladen
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
     -O "$HOME/miniconda3/miniconda.sh"

# Installer im Batch-Modus ohne Rückfrage ausführen und Zielpfad setzen
bash "$HOME/miniconda3/miniconda.sh" -b -u -p "$HOME/miniconda3"

# Installer-Skript entfernen
rm "$HOME/miniconda3/miniconda.sh"

echo "Miniconda wurde erfolgreich in ~/miniconda3 installiert. Rebooting now."

sudo reboot
