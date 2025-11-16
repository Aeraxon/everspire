# Proxmox Backup Server auf TrueNAS Scale

Installation von PBS in einem LXC Container auf TrueNAS Scale mit Dataset-Integration für Snapshots und Replikation.

## Voraussetzungen

- TrueNAS Scale 25.04 oder neuer
- Konfigurierte Storage Pools
- Admin-Zugang zur TrueNAS Web-GUI

## 1. Dataset-Struktur vorbereiten

**Ziel:** `pool1/data/containers/pbs/backup`

### Container-Dataset

**TrueNAS Web-GUI:**
1. **Storage** → **Datasets** → `pool1/data` auswählen
2. **Add Dataset**
3. **Name:** `containers`
4. **Dataset Preset:** `Generic`
5. **Save**

### PBS-Dataset

1. **`pool1/data/containers`** auswählen
2. **Add Dataset**
3. **Name:** `pbs`
4. **Dataset Preset:** `Generic`
5. **Save**

### Backup-Dataset

1. **`pool1/data/containers/pbs`** auswählen
2. **Add Dataset**
3. **Name:** `backup`
4. **Dataset Preset:** `Generic`
5. **Save**

## 2. Pool für Instances konfigurieren

**TrueNAS Web-GUI:**
1. **Apps** → **Instances**
2. Falls "Select Pool" angezeigt: **Select Pool** klicken
3. **Pool:** `pool1` auswählen
4. **Apply**

## 3. LXC Container erstellen

**TrueNAS Web-GUI:**
1. **Apps** → **Instances** → **Create New Instance**
2. **Instance Configuration:**
   - **Name:** `<container-name>` (anpassen)
   - **Type:** `Container`
   - **Image:** `Debian bookworm amd64 (default)`
3. **CPU & Memory:** Nach Bedarf
4. **Network:** Standard
5. **Create**

**Container starten:** Grünen Play-Button klicken

## 4. SSH-Zugang einrichten

**Container Shell (via TrueNAS Web-GUI):**
```bash
# SSH Server installieren
apt update
apt install openssh-server -y

# SSH aktivieren
systemctl start ssh
systemctl enable ssh

# Root-Passwort setzen
passwd root
```

## 5. Proxmox Backup Server installieren

### Debian Version prüfen

```bash
cat /etc/debian_version
lsb_release -a
```

### PBS Installation

**Debian 12 Bookworm (Standard bei TrueNAS Scale 25.04):**

```bash
# PBS Repository hinzufügen
echo "deb http://download.proxmox.com/debian/pbs bookworm pbs-no-subscription" | sudo tee -a /etc/apt/sources.list

# GPG Key installieren
apt install wget -y
wget https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg

# System aktualisieren
apt update && apt upgrade -y

# Dependencies installieren
apt install -y whiptail apt-utils coreutils bash proxmox-widget-toolkit nano nfs-common cron

# PBS installieren
apt update && apt install proxmox-backup-server -y

# Web-UI URL anzeigen
echo "https://$(ip -4 addr show $(ip route | grep default | awk '{print $5}') | grep inet | awk '{print $2}' | cut -d/ -f1):8007"

# Root-Passwort setzen
passwd root
```

**Debian 13 Trixie:**

Ersetze `bookworm` durch `trixie` und verwende `proxmox-release-trixie.gpg`.

### PBS Post-Install Script (empfohlen)

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/post-pbs-install.sh)"
```

Konfiguriert:
- Debian Repository Sources
- No-Subscription Repository
- Entfernt Subscription-Nag
- System-Update

## 6. Storage-Mounting

### Backup-Dataset in Container mounten

**TrueNAS Shell:**

```bash
# Dataset mounten mit shift=true für UID-Mapping
incus config device add <container-name> mydataset disk source=/mnt/pool1/data/containers/pbs/backup path=/backup shift=true
```

**Pattern:**
```bash
incus config device add <container-name> <device-name> disk source=<host-path> path=<container-path> shift=true
```

### Mount verifizieren

**Container Shell:**

```bash
# Mount prüfen
df -h | grep backup

# Schreibtest
mkdir -p /backup/test
echo "PBS Storage Test" > /backup/test/test.txt
cat /backup/test/test.txt
```

## 7. PBS Datastore konfigurieren

### Web-Interface öffnen

URL: `https://<CONTAINER-IP>:8007`

Login:
- **Username:** `root`
- **Password:** Bei Installation gesetztes Passwort

### Datastore erstellen

1. **Administration** → **Storage/Disks** → **Directory**
2. **Create: Directory**
3. **Datastore Configuration:**
   - **Name:** `truenas-backup`
   - **Backing Path:** `/backup`
   - **GC Schedule:** `daily`
   - **Prune Schedule:** `daily`
4. **Create**

## 8. Disaster Recovery

### Vollständiger Neuaufbau

Bei Verlust des Containers:

1. Neuen Container erstellen (Schritt 3)
2. PBS installieren (Schritt 5)
3. Storage mounten:
   ```bash
   incus config device add <new-container> mydataset disk source=/mnt/pool1/data/containers/pbs/backup path=/backup shift=true
   ```
4. PBS konfigurieren: Datastore auf `/backup` erstellen
5. **Backups automatisch verfügbar** (auf TrueNAS Dataset gespeichert)

### Container-Konfiguration sichern

**TrueNAS Shell:**
```bash
# Config exportieren
incus config show <container-name> > /mnt/pool1/data/containers/pbs/container-config.yaml

# Bei Neuaufbau importieren
incus config edit <new-container> < /mnt/pool1/data/containers/pbs/container-config.yaml
```

## 9. TrueNAS Backup-Integration

### Snapshot-Integration

Dataset `pool1/data/containers/pbs/backup` wird automatisch in Snapshot-Tasks einbezogen wenn auf `pool1/data` oder höher konfiguriert.

### Replikation

PBS-Backup-Daten werden automatisch mit `pool1/data` Dataset repliziert.

## 10. Wartung und Updates

### PBS Updates

**Container Shell:**
```bash
apt update && apt upgrade -y
systemctl restart proxmox-backup
```

### Container-Neustart

**TrueNAS Web-GUI:**
1. **Apps** → **Instances** → Container auswählen
2. **Stop** → **Start**

## 11. Troubleshooting

### Permission-Probleme

Falls `/backup` nicht beschreibbar:

**TrueNAS Shell:**
```bash
# Container-UID ermitteln
incus exec <container-name> -- id backup

# Host-Permissions setzen (Beispiel)
chown -R 2147000035:2147000035 /mnt/pool1/data/containers/pbs/backup
```

### Mount-Probleme

**Container remounten:**
```bash
# TrueNAS Shell
incus config device remove <container-name> mydataset
incus config device add <container-name> mydataset disk source=/mnt/pool1/data/containers/pbs/backup path=/backup shift=true
```

### Logs prüfen

**Container Shell:**
```bash
# PBS Service Logs
journalctl -u proxmox-backup -f

# System Logs
journalctl -f
```

### Netzwerk-Probleme

```bash
# Container IP prüfen
ip addr show

# DNS-Test
ping -c 3 google.com

# Port-Test von Host
curl -k https://<container-ip>:8007
```

## 12. Sicherheit

- **Firewall:** Port 8007 nur für vertrauenswürdige Netzwerke
- **Backups:** Regelmäßige Snapshots des `containers/pbs` Datasets
- **Updates:** PBS und Container regelmäßig aktualisieren
- **Monitoring:** PBS-Status und verfügbaren Speicherplatz überwachen
- **SSL:** Gültige Zertifikate für Production-Umgebungen
- **Passwörter:** Starke Passwörter verwenden

## 13. Erweiterte Konfiguration

### SSL-Zertifikat

PBS nutzt selbstsignierte Zertifikate. Für Production gültige SSL-Zertifikate verwenden:

**Container Shell:**
```bash
# Zertifikat kopieren
cp /pfad/zum/cert.pem /etc/proxmox-backup/proxy.pem
cp /pfad/zum/key.pem /etc/proxmox-backup/proxy.key

# Service neustarten
systemctl restart proxmox-backup-proxy
```

### Benutzer und Berechtigungen

In PBS Web-GUI können zusätzliche Benutzer und granulare Berechtigungen konfiguriert werden:
- **Configuration** → **Access Control** → **User Management**

### Pruning und Garbage Collection

Automatische Aufräum-Tasks anpassen:
- **Administration** → **Prune & GC Jobs**

### Email-Benachrichtigungen

**Container Shell:**
```bash
# Postfix installieren
apt install postfix -y

# In PBS Web-GUI konfigurieren:
# Configuration → Notifications → Email
```

## 14. Nützliche Befehle

### PBS CLI

```bash
# Datastore-Status
proxmox-backup-manager datastore list

# Garbage Collection manuell starten
proxmox-backup-manager garbage-collection start truenas-backup

# Backup-Gruppen anzeigen
proxmox-backup-manager backup-group list truenas-backup

# Service-Status
systemctl status proxmox-backup
```

### Container-Management (TrueNAS Shell)

```bash
# Container Info
incus info <container-name>

# Container-Logs
incus console <container-name>

# Container-Shell
incus exec <container-name> bash

# Container stoppen/starten
incus stop <container-name>
incus start <container-name>

# Devices auflisten
incus config device show <container-name>
```

## 15. Performance-Tuning

### PBS Worker Threads

**Container Shell:**
```bash
nano /etc/proxmox-backup/datastore.cfg
```

Hinzufügen:
```
datastore: truenas-backup
    path /backup
    max-prune-jobs 2
    max-verify-jobs 2
```

### ZFS Tuning (TrueNAS)

Für bessere PBS-Performance:
- **Recordsize:** 1M für Backup-Dataset
- **Compression:** lz4 oder zstd
- **Snapshots:** Nicht zu häufig (täglich reicht)

**TrueNAS Shell:**
```bash
zfs set recordsize=1M pool1/data/containers/pbs/backup
zfs set compression=lz4 pool1/data/containers/pbs/backup
```

---

**Produktionstaugliche PBS-Installation mit ordentlicher TrueNAS Storage-Integration.**
