#!/usr/bin/env bash
set -euo pipefail

# Miniconda aktivieren
source "$HOME/miniconda3/bin/activate"

# conda für alle Shells initialisieren
conda init --all

echo "Conda wurde initiiert – starte am besten eine neue Shell, damit die Änderungen aktiv werden."
