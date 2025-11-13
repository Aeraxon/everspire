# Git Setup Guide

## Initiale Git-Konfiguration

```bash
# Benutzer konfigurieren
git config --global user.name "Dein Name"
git config --global user.email "deine@email.com"

# Default Branch auf "main" setzen
git config --global init.defaultBranch main

# Credential Helper (speichert Zugangsdaten)
git config --global credential.helper store
```

## SSL-Zertifikate (für Self-Hosted GitLab)

```bash
# Global alle SSL-Zertifikate akzeptieren (unsicher!)
git config --global http.sslVerify false

# Nur für spezifischen Server (empfohlen)
git config --global http."https://gitlab.your-domain.com/".sslVerify false
```

## Neues Repository erstellen

### Lokales Projekt initialisieren

```bash
cd /pfad/zu/deinem/projekt

# Git initialisieren
git init

# Remote hinzufügen
git remote add origin <REPOSITORY_URL>

# Branch prüfen/umbenennen
git branch  # zeigt aktuellen Branch
git branch -M main  # umbenennen auf "main" falls nötig

# Erste Dateien committen
git add .
git commit -m "Initial commit"

# Zum Remote pushen
git push -u origin main
```

### Repository URLs

**GitHub:**
```
https://github.com/username/repo-name.git
git@github.com:username/repo-name.git  # SSH
```

**GitLab (Self-Hosted):**
```
https://gitlab.your-domain.com/username/repo-name.git
git@gitlab.your-domain.com:username/repo-name.git  # SSH
```

## Access Token erstellen

### GitHub
1. Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token
3. Scopes: `repo` (für private repos)
4. Token als Passwort beim Push verwenden

### GitLab
1. User Settings → Access Tokens
2. Name + Expiration + Scopes (`write_repository`, `read_repository`)
3. Create token
4. Token als Passwort beim Push verwenden

## Authentifizierung

Beim ersten `git push`:
```
Username: dein_username
Password: dein_access_token  # NICHT dein Account-Passwort!
```

Mit `credential.helper store` werden die Daten nach erstem Eingeben gespeichert.

## SSH statt HTTPS (optional)

```bash
# SSH-Key generieren
ssh-keygen -t ed25519 -C "deine@email.com"

# Public Key anzeigen
cat ~/.ssh/id_ed25519.pub

# Key zu GitHub/GitLab hinzufügen (in den Settings)

# Remote auf SSH umstellen
git remote set-url origin git@github.com:username/repo-name.git
```

## Nützliche Befehle

```bash
# Remote prüfen
git remote -v

# Status checken
git status

# Änderungen pushen
git add .
git commit -m "Beschreibung"
git push

# Änderungen pullen
git pull

# Branch wechseln/erstellen
git checkout -b neuer-branch
git push -u origin neuer-branch
```
