# NVIDIA GPU Initialisierung für LXC Container

Nach Reboot sehen LXC Container die GPU nicht, bis auf dem Host einmal `nvidia-smi` ausgeführt wurde. Systemd Service löst das Problem automatisch.

## Problem

Nach Proxmox Reboot:
- LXC Container starten
- Container sehen GPU nicht (`nvidia-smi` schlägt fehl)
- Workaround: Auf Host `nvidia-smi` ausführen, Container neustarten
- Erst danach funktioniert GPU in Containern

**Grund:** NVIDIA Kernel-Module werden erst bei erster Nutzung vollständig initialisiert.

## Lösung: Systemd Service

Service initialisiert GPU automatisch beim Boot, bevor LXC Container starten.

## Installation

### Automatisches Script

```bash
#!/bin/bash

# Systemd Service erstellen
cat > /etc/systemd/system/nvidia-init.service << 'EOF'
[Unit]
Description=Initialize NVIDIA GPU for LXC containers
After=multi-user.target
Before=pve-container@.service

[Service]
Type=oneshot
ExecStart=/usr/bin/nvidia-smi
ExecStart=/bin/sleep 2
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Service aktivieren und starten
systemctl daemon-reload
systemctl enable nvidia-init.service
systemctl start nvidia-init.service

# Status prüfen
systemctl status nvidia-init.service
```

Speichern als `/root/install-nvidia-init.sh`, ausführbar machen:
```bash
chmod +x /root/install-nvidia-init.sh
./root/install-nvidia-init.sh
```

### Manuelle Installation

```bash
# 1. Service-Datei erstellen
nano /etc/systemd/system/nvidia-init.service
```

Inhalt:
```ini
[Unit]
Description=Initialize NVIDIA GPU for LXC containers
After=multi-user.target
Before=pve-container@.service

[Service]
Type=oneshot
ExecStart=/usr/bin/nvidia-smi
ExecStart=/bin/sleep 2
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

```bash
# 2. Service aktivieren
systemctl daemon-reload
systemctl enable nvidia-init.service

# 3. Service testen
systemctl start nvidia-init.service
systemctl status nvidia-init.service
```

## Service-Erklärung

### [Unit] Sektion

- **Description:** Beschreibung des Services
- **After=multi-user.target:** Startet nach Basis-System
- **Before=pve-container@.service:** Startet VOR LXC Containern

### [Service] Sektion

- **Type=oneshot:** Einmaliger Aufruf, kein dauerhafter Prozess
- **ExecStart=/usr/bin/nvidia-smi:** GPU initialisieren
- **ExecStart=/bin/sleep 2:** 2 Sekunden warten (Initialisierung abschließen)
- **RemainAfterExit=yes:** Service gilt als aktiv nach Ausführung
- **StandardOutput/Error=journal:** Logs in systemd journal

### [Install] Sektion

- **WantedBy=multi-user.target:** Automatischer Start beim Boot

## Prüfen ob Service funktioniert

### Status checken

```bash
systemctl status nvidia-init.service
```

Sollte zeigen: `active (exited)`

### Logs anzeigen

```bash
journalctl -u nvidia-init.service
```

Sollte nvidia-smi Output zeigen.

### Nach Reboot testen

```bash
# Reboot
reboot

# Nach Reboot prüfen
systemctl status nvidia-init.service

# GPU-Status
nvidia-smi

# Container GPU-Zugriff testen
pct enter <container-id>
nvidia-smi
```

## Troubleshooting

### Service startet nicht

```bash
# Logs prüfen
journalctl -u nvidia-init.service -b

# Service manuell starten
systemctl start nvidia-init.service
```

### nvidia-smi nicht gefunden

```bash
# NVIDIA Treiber installiert?
which nvidia-smi

# Falls nicht installiert:
apt update && apt install nvidia-driver -y
```

### Service läuft, Container sehen GPU trotzdem nicht

```bash
# Container GPU-Konfiguration prüfen
pct config <container-id> | grep -i gpu

# NVIDIA Container Toolkit im Container installiert?
pct enter <container-id>
nvidia-smi
```

Siehe: `../../docker/installation/docker-install.sh` mit GPU-Support Option für NVIDIA Container Toolkit Installation.

### Container startet vor Service

Service-Datei anpassen:
```ini
[Unit]
Before=pve-container@.service lxc.service
```

Dann:
```bash
systemctl daemon-reload
systemctl restart nvidia-init.service
```

## Service deaktivieren/entfernen

```bash
# Deaktivieren
systemctl disable nvidia-init.service
systemctl stop nvidia-init.service

# Entfernen
rm /etc/systemd/system/nvidia-init.service
systemctl daemon-reload
```

## Alternative Lösungen

### Cronjob @reboot

```bash
# Cronjob erstellen
crontab -e
```

Hinzufügen:
```cron
@reboot /usr/bin/nvidia-smi && sleep 2
```

**Nachteil:** Kein Dependency-Management (startet eventuell nach Containern).

### rc.local Script

```bash
# rc.local erstellen/bearbeiten
nano /etc/rc.local
```

Hinzufügen:
```bash
#!/bin/bash
/usr/bin/nvidia-smi
sleep 2
exit 0
```

```bash
# Ausführbar machen
chmod +x /etc/rc.local
```

**Nachteil:** Legacy-Methode, systemd ist moderner und zuverlässiger.

## Best Practices

- **Systemd Service bevorzugen** - sauberste Lösung mit Dependency-Management
- **Nach Reboot testen** - sicherstellen dass Container GPU direkt nutzen können
- **Logs überwachen** - bei Problemen `journalctl` nutzen
- **GPU Passthrough prüfen** - sicherstellen dass GPU korrekt konfiguriert ist (siehe `pcie-passthrough-setup.md`)

## Verwandte Themen

- **GPU Passthrough:** `pcie-passthrough-setup.md`
- **GPU Treiber Blacklisting:** `gpu-driver-blacklist.md`
- **Docker GPU Support:** `../../docker/installation/docker-install.sh` mit GPU-Option

## Erweiterte Konfiguration

### GPU-Status vor Container-Start loggen

Service erweitern:
```ini
[Service]
Type=oneshot
ExecStart=/usr/bin/nvidia-smi
ExecStart=/bin/sleep 2
ExecStartPost=/usr/bin/logger "NVIDIA GPU initialized for LXC containers"
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal
```

### Mehrere GPUs

Bei mehreren GPUs alle initialisieren:
```ini
[Service]
Type=oneshot
ExecStart=/usr/bin/nvidia-smi -L
ExecStart=/usr/bin/nvidia-smi
ExecStart=/bin/sleep 2
RemainAfterExit=yes
```

### Timeout anpassen

Falls GPU langsam initialisiert:
```ini
[Service]
Type=oneshot
TimeoutStartSec=30
ExecStart=/usr/bin/nvidia-smi
ExecStart=/bin/sleep 5
RemainAfterExit=yes
```

---

**Löst das Problem mit NVIDIA GPU-Erkennung in LXC Containern nach Proxmox Reboot.**
