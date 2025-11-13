# SCP File Transfer

Sichere Dateiübertragung zwischen Systemen via SSH.

## Basis-Syntax

```bash
scp [optionen] quelle ziel
```

## Einzelne Datei kopieren

### Lokal → Remote

```bash
scp /pfad/zur/datei.txt username@remote-ip:/ziel/pfad/
```

Windows → Linux:
```bash
scp C:\Ordner\datei.txt username@192.168.1.100:/home/username/
```

### Remote → Lokal

```bash
scp username@remote-ip:/pfad/zur/datei.txt /lokaler/pfad/
```

### Remote → Remote (von lokalem System aus)

```bash
scp username1@host1:/pfad/datei.txt username2@host2:/pfad/
```

## Ordner rekursiv kopieren

### Mit -r Flag

```bash
scp -r /lokaler/ordner username@remote-ip:/ziel/pfad/
```

Windows:
```bash
scp -r C:\Ordner username@192.168.1.100:/home/username/
```

**Wichtig:** `-r` kopiert alle Unterordner und Dateien rekursiv.

## Wichtige Optionen

### -r (recursive)
Ordner mit allen Inhalten kopieren
```bash
scp -r /pfad/zum/ordner username@host:/ziel/
```

### -P (Port)
Anderen SSH-Port nutzen (Standard: 22)
```bash
scp -P 2222 datei.txt username@host:/pfad/
```

**Achtung:** Großes `-P` bei scp (klein `-p` bei ssh!)

### -p (preserve)
Timestamps und Berechtigungen beibehalten
```bash
scp -p datei.txt username@host:/pfad/
```

### -i (identity file)
SSH-Key verwenden
```bash
scp -i ~/.ssh/id_rsa datei.txt username@host:/pfad/
```

### -v (verbose)
Debug-Ausgabe für Troubleshooting
```bash
scp -v datei.txt username@host:/pfad/
```

### -C (compress)
Komprimierung aktivieren (schneller bei langsamer Verbindung)
```bash
scp -C grosse-datei.zip username@host:/pfad/
```

### -l (limit)
Bandbreite limitieren (in Kbit/s)
```bash
scp -l 1024 datei.txt username@host:/pfad/  # Max 1 Mbit/s
```

## Optionen kombinieren

```bash
# Ordner rekursiv, Port 2222, mit Key
scp -r -P 2222 -i ~/.ssh/mykey /ordner username@host:/pfad/

# Oder kurz:
scp -rP 2222 -i ~/.ssh/mykey /ordner username@host:/pfad/
```

## Spezielle Use-Cases

### Docker Volume befüllen

```bash
# Einzelne Datei
scp datei.txt username@host:/var/lib/docker/volumes/my-volume/_data/

# Ganzer Ordner
scp -r /lokaler/ordner username@host:/var/lib/docker/volumes/my-volume/_data/
```

### Backup herunterladen

```bash
scp -r username@host:/var/backups/wichtig /lokale/backups/
```

### Mehrere Dateien

```bash
# Mit Wildcard
scp username@host:/pfad/*.log /lokaler/pfad/

# Explizit mehrere
scp datei1.txt datei2.txt username@host:/pfad/
```

### Ganzes Verzeichnis mit Timestamp

```bash
scp -rp /wichtiger/ordner username@host:/backup/  # -p behält Timestamps
```

## Windows-Pfade

Windows-Pfade in Git Bash / WSL:
```bash
# Mit Leerzeichen
scp "C:\Pfad mit Leerzeichen\datei.txt" username@host:/pfad/

# Backslash escapen (bash)
scp C:\\Users\\Name\\datei.txt username@host:/pfad/

# Oder Forward Slash (funktioniert oft)
scp C:/Users/Name/datei.txt username@host:/pfad/
```

PowerShell (native):
```powershell
scp C:\Ordner\datei.txt username@192.168.1.100:/home/username/
```

## Progress anzeigen

Neuere scp-Versionen zeigen automatisch Fortschritt:
```
datei.txt                 100% 1024KB   2.0MB/s   00:00
```

Falls nicht, mit `-v`:
```bash
scp -v datei.txt username@host:/pfad/
```

## Authentifizierung

### Mit Passwort
Fragt beim Ausführen nach Passwort:
```bash
scp datei.txt username@host:/pfad/
```

### Mit SSH-Key
```bash
scp -i ~/.ssh/id_ed25519 datei.txt username@host:/pfad/
```

### SSH-Config nutzen

Wenn in `~/.ssh/config` konfiguriert:
```
Host myserver
    HostName 192.168.1.100
    User username
    Port 2222
    IdentityFile ~/.ssh/mykey
```

Dann einfach:
```bash
scp datei.txt myserver:/pfad/
```

## Troubleshooting

### Permission denied (publickey)

```bash
# Key explizit angeben
scp -i ~/.ssh/id_rsa datei.txt username@host:/pfad/

# Key-Permissions prüfen
chmod 600 ~/.ssh/id_rsa
```

### Connection refused

```bash
# Port prüfen
scp -P 2222 datei.txt username@host:/pfad/

# SSH-Verbindung testen
ssh -p 2222 username@host
```

### Langsame Übertragung

```bash
# Komprimierung aktivieren
scp -C datei.txt username@host:/pfad/

# Oder rsync verwenden (effizienter für große Datenmengen)
rsync -avz --progress /ordner username@host:/pfad/
```

### Host key verification failed

```bash
# Host Key aus known_hosts entfernen (bei neuem Server)
ssh-keygen -R hostname

# Oder: -o StrictHostKeyChecking=no (unsicher!)
scp -o StrictHostKeyChecking=no datei.txt username@host:/pfad/
```

## Alternativen zu SCP

### rsync (empfohlen für große Datenmengen)

```bash
# Effizienter, zeigt Progress, resumed bei Abbruch
rsync -avz --progress /ordner username@host:/pfad/
```

Vorteile:
- Nur geänderte Dateien
- Resume bei Abbruch
- Bessere Progress-Anzeige
- Erhalt von Permissions/Timestamps

### sftp (interaktiv)

```bash
sftp username@host
sftp> put lokale-datei.txt /remote/pfad/
sftp> get /remote/datei.txt
sftp> exit
```

## Vollständige Beispiele

### Backup von Server holen (mit Kompression, Zeitstempel erhalten)

```bash
scp -rCp username@192.168.1.100:/var/backups/wichtig /lokale/backups/$(date +%Y%m%d)
```

### Zu Docker Volume hochladen (custom Port, SSH-Key)

```bash
scp -P 2222 -i ~/.ssh/deploy_key -r /lokaler/ordner username@192.168.1.100:/var/lib/docker/volumes/app-data/_data/
```

### Von Windows zu Linux Server (mehrere Dateien)

```bash
scp C:\Projekt\*.conf username@192.168.1.100:/etc/app/config/
```

### Mit Progress und Bandbreiten-Limit

```bash
scp -Cv -l 5000 grosse-datei.iso username@host:/pfad/  # Max 5 Mbit/s
```

## Best Practices

- **rsync statt scp** für große Datenmengen oder wiederholte Transfers
- **SSH-Key** statt Passwort für Automatisierung
- **SSH-Config** nutzen für häufig verwendete Hosts
- **Backups testen** nach Transfer (md5sum, sha256sum)
- **-p Flag** nutzen um Timestamps zu erhalten
- **-C Flag** bei langsamen Verbindungen

## Sicherheitshinweise

- Niemals mit root-User direkt arbeiten wenn vermeidbar
- SSH-Keys mit Passphrase schützen
- Key-Permissions: `chmod 600 ~/.ssh/id_rsa`
- StrictHostKeyChecking nicht global deaktivieren
- Firewall-Regeln beachten (Port 22/custom)
