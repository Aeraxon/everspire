# Ubuntu Filesystem erweitern

Nach VM-Installation nutzt Ubuntu oft nicht die ganze virtuelle Festplatte. Diese Anleitung zeigt wie man das Filesystem erweitert.

## 1. Aktuellen Status prüfen

```bash
# Partitionen anzeigen
lsblk

# Speichernutzung anzeigen
df -h
```

Typisches Problem:
- Virtuelle Disk: 500GB
- Ubuntu nutzt: 100GB
- Lösung: Filesystem erweitern

## 2. LVM vs. Non-LVM prüfen

```bash
sudo vgdisplay
```

- **Ausgabe vorhanden** → LVM (häufiger Fall)
- **Keine Ausgabe** → Non-LVM (siehe unten)

## LVM Filesystem erweitern (Standard Ubuntu)

### Schritt 1: Freien Speicherplatz prüfen

```bash
sudo vgdisplay ubuntu-vg
```

Wichtig: Zeile **VG Free** - das ist der verfügbare Speicher in der Volume Group.

Falls `VG Free = 0`:
- Problem liegt eine Ebene höher (Partition nicht erweitert)
- Siehe "Partition vorher erweitern" unten

### Schritt 2: Logisches Volume erweitern

```bash
sudo lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
```

**Pattern für andere Namen:**
```bash
sudo lvextend -l +100%FREE /dev/<vg-name>/<lv-name>
```

VG/LV Namen mit `sudo vgdisplay` und `sudo lvdisplay` herausfinden.

### Schritt 3: Dateisystem vergrößern

Für **ext4** (Standard):
```bash
sudo resize2fs /dev/ubuntu-vg/ubuntu-lv
```

Für **xfs**:
```bash
sudo xfs_growfs /
```

Filesystem-Typ prüfen:
```bash
df -T
```

### Schritt 4: Erfolgreich?

```bash
df -h
```

Zeile mit `/` sollte jetzt die volle Größe zeigen.

## Partition vorher erweitern (falls VG Free = 0)

Wenn die LVM Volume Group keinen freien Speicher hat, muss erst die Partition erweitert werden.

### Schritt 1: Partition identifizieren

```bash
lsblk
```

Beispiel-Ausgabe:
```
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                         8:0    0  500G  0 disk
├─sda1                      8:1    0    1M  0 part
├─sda2                      8:2    0    2G  0 part /boot
└─sda3                      8:3    0   98G  0 part
  ├─ubuntu--vg-ubuntu--lv 253:0    0   50G  0 lvm  /
  └─ubuntu--vg-ubuntu--swap 253:1  0    4G  0 lvm  [SWAP]
```

Problem: `sda` hat 500G, aber `sda3` (LVM Partition) nur 98G.

### Schritt 2: Partition erweitern mit growpart

```bash
# growpart installieren falls nicht vorhanden
sudo apt install cloud-guest-utils

# Partition erweitern (Achtung: Leerzeichen zwischen Device und Nummer!)
sudo growpart /dev/sda 3
```

**Pattern:**
```bash
sudo growpart /dev/<device> <partition-nummer>
```

### Schritt 3: Physical Volume erweitern

```bash
sudo pvresize /dev/sda3
```

**Pattern:**
```bash
sudo pvresize /dev/<partition>
```

### Schritt 4: Freien Platz prüfen

```bash
sudo vgdisplay ubuntu-vg
```

`VG Free` sollte jetzt den zusätzlichen Speicher zeigen.

Jetzt weiter mit "LVM Filesystem erweitern" oben.

## Non-LVM Filesystem erweitern (selten)

Falls Ubuntu ohne LVM installiert wurde:

### Schritt 1: Partition erweitern

```bash
sudo growpart /dev/sda 2  # Haupt-Partition (meist sda2)
```

### Schritt 2: Dateisystem erweitern

```bash
sudo resize2fs /dev/sda2
```

### Schritt 3: Prüfen

```bash
df -h
```

## Troubleshooting

### growpart: device busy

```bash
# Reboot und dann erneut versuchen
sudo reboot
```

### resize2fs funktioniert nicht

Filesystem-Typ prüfen:
```bash
df -T
```

Für xfs:
```bash
sudo xfs_growfs /
```

### VG Free zeigt Speicher, aber lvextend schlägt fehl

```bash
# Alle VGs anzeigen
sudo vgdisplay

# Alle LVs anzeigen
sudo lvdisplay

# Korrekten Namen verwenden
sudo lvextend -l +100%FREE /dev/<korrekte-vg>/<korrekte-lv>
```

### Keine Änderung nach resize2fs

```bash
# Filesystem-Check erzwingen (nur bei ext4)
sudo e2fsck -f /dev/ubuntu-vg/ubuntu-lv
sudo resize2fs /dev/ubuntu-vg/ubuntu-lv
```

## Vollständiges Beispiel (häufigster Fall)

```bash
# 1. Status prüfen
df -h
lsblk

# 2. LVM freien Speicher prüfen
sudo vgdisplay ubuntu-vg

# 3. Falls VG Free = 0, Partition erst erweitern
sudo apt install cloud-guest-utils
sudo growpart /dev/sda 3
sudo pvresize /dev/sda3

# 4. LV erweitern
sudo lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv

# 5. Filesystem erweitern
sudo resize2fs /dev/ubuntu-vg/ubuntu-lv

# 6. Prüfen
df -h
```

## Wichtige Hinweise

- **Backup erstellen** vor Partition-Operationen
- Bei VMs: VM-Snapshot erstellen falls möglich
- **Keine Daten verloren** - Operationen sind nicht-destruktiv
- Funktioniert **online** - kein Reboot nötig (außer bei growpart-Problemen)
- Typisch nach **Vergrößern der virtuellen Disk** in VMware/Proxmox/VirtualBox

## Wann nötig?

- Nach Ubuntu Installation in VM (nur 100G trotz größerer Disk)
- Nach Vergrößern der virtuellen Festplatte
- Nach Migration auf größere Disk
- Initial zu kleine Partition während Installation
