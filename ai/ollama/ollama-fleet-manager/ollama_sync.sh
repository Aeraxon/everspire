#!/bin/bash

# Konfiguration
MODELS_FILE="models.txt"

# Prüfe ob models.txt existiert
if [ ! -f "$MODELS_FILE" ]; then
    echo "Fehler: $MODELS_FILE nicht gefunden!"
    echo "Erstelle eine $MODELS_FILE Datei mit einem Modellnamen pro Zeile."
    exit 1
fi

echo "Ollama Model Sync"
echo "================="
echo ""

# Lese gewünschte Modelle aus models.txt (ignoriere Leerzeilen und Kommentare)
echo "Lese gewünschte Modelle aus $MODELS_FILE..."
DESIRED_MODELS=()
while IFS= read -r line || [ -n "$line" ]; do
    # Entferne Whitespace
    line=$(echo "$line" | xargs)
    # Ignoriere leere Zeilen und Kommentare
    if [ -n "$line" ] && [[ ! "$line" =~ ^# ]]; then
        DESIRED_MODELS+=("$line")
    fi
done < "$MODELS_FILE"

echo "Gewünschte Modelle: ${DESIRED_MODELS[*]}"
echo ""

# Hole installierte Modelle (überspringe Header-Zeile)
echo "Prüfe installierte Modelle..."
INSTALLED_MODELS=()
while IFS= read -r line; do
    # Extrahiere ersten Spalte (Modellname)
    model=$(echo "$line" | awk '{print $1}')
    if [ -n "$model" ] && [ "$model" != "NAME" ]; then
        INSTALLED_MODELS+=("$model")
    fi
done < <(ollama list)

echo "Installierte Modelle: ${INSTALLED_MODELS[*]}"
echo ""

# Funktion: Prüfe ob Modell in Array existiert
model_in_array() {
    local model="$1"
    shift
    local arr=("$@")

    for item in "${arr[@]}"; do
        # Berücksichtige sowohl "model" als auch "model:latest"
        if [ "$item" = "$model" ] || [ "$item" = "$model:latest" ] || [ "$item:latest" = "$model" ]; then
            return 0
        fi
    done
    return 1
}

# Lösche Modelle, die nicht mehr gewünscht sind
echo "Prüfe auf zu löschende Modelle..."
echo "--------------------------------"
DELETED=0
for installed in "${INSTALLED_MODELS[@]}"; do
    if ! model_in_array "$installed" "${DESIRED_MODELS[@]}"; then
        echo "❌ Lösche: $installed"
        ollama rm "$installed"
        if [ $? -eq 0 ]; then
            echo "   ✓ Erfolgreich gelöscht"
            ((DELETED++))
        else
            echo "   ✗ Fehler beim Löschen"
        fi
    fi
done

if [ $DELETED -eq 0 ]; then
    echo "Keine Modelle zu löschen."
fi
echo ""

# Installiere fehlende Modelle
echo "Prüfe auf fehlende Modelle..."
echo "--------------------------------"
PULLED=0
for desired in "${DESIRED_MODELS[@]}"; do
    if ! model_in_array "$desired" "${INSTALLED_MODELS[@]}"; then
        echo "⬇️  Pulling: $desired"
        ollama pull "$desired"
        if [ $? -eq 0 ]; then
            echo "   ✓ Erfolgreich installiert"
            ((PULLED++))
        else
            echo "   ✗ Fehler beim Installieren"
        fi
        echo ""
    fi
done

if [ $PULLED -eq 0 ]; then
    echo "Keine neuen Modelle zu installieren."
fi
echo ""

# Zusammenfassung
echo "================="
echo "Sync abgeschlossen!"
echo "Gelöscht: $DELETED Modell(e)"
echo "Installiert: $PULLED Modell(e)"
echo ""

# Zeige finale Liste
echo "Aktuelle Modelle:"
ollama list
