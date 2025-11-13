# Python Virtual Environments Setup

## Installation & Aktivierung

```bash
# Pattern: Ersetze 3.XX mit gewünschter Version (3.9, 3.10, 3.11, 3.12, etc.)
sudo apt install python3.XX python3.XX-venv python3.XX-dev build-essential

# venv erstellen
python3.XX -m venv venv

# Aktivieren
source venv/bin/activate

# Deaktivieren
deactivate
```

## Beispiele

### Python 3.9
```bash
sudo apt install python3.9 python3.9-venv python3.9-dev build-essential
python3.9 -m venv venv
source venv/bin/activate
```

### Python 3.11
```bash
sudo apt install python3.11 python3.11-venv python3.11-dev build-essential
python3.11 -m venv venv
source venv/bin/activate
```

### Python 3.12
```bash
sudo apt install python3.12 python3.12-venv python3.12-dev build-essential
python3.12 -m venv venv
source venv/bin/activate
```

## Pakete

- `python3.XX` - Python Interpreter
- `python3.XX-venv` - venv Modul
- `python3.XX-dev` - Header-Dateien für C-Extensions
- `build-essential` - Compiler für pip packages mit C-Code

## Hinweise

- venv-Name kann angepasst werden: `python3.XX -m venv mein_projekt_env`
- Verschiedene venvs für verschiedene Projekte nutzen
- Nicht ins Git committen (zu `.gitignore` hinzufügen)
