# TrueNAS Festplatten-Temperatur Monitoring

Festplatten-Temperaturen mit smartctl auslesen.

## Einmalige Abfrage

### Alle SAS/SATA Devices

```bash
for disk in /dev/sd?; do
  smartctl -A "$disk" 2>/dev/null | awk -v dev="$disk" '/Current Drive Temperature/ {print dev ": " $4 "°C"}';
done
```

Beispiel-Ausgabe:
```
/dev/sda: 35°C
/dev/sdb: 37°C
/dev/sdc: 34°C
```

### Mehrstellige Device-Namen (sda, sdb, ..., sdaa, sdab)

```bash
for disk in /dev/sd*; do
  smartctl -A "$disk" 2>/dev/null | awk -v dev="$disk" '/Current Drive Temperature/ {print dev ": " $4 "°C"}';
done
```

### Einzelne Festplatte

```bash
smartctl -A /dev/sda | grep Temperature
```

## Automatische Aktualisierung

### Alle 10 Sekunden

```bash
watch -n 10 'for disk in /dev/sd?; do smartctl -A "$disk" 2>/dev/null | awk -v dev="$disk" "/Current Drive Temperature/ {print dev \": \" \$4 \"°C\"}"; done'
```

### Alle 30 Sekunden (schonender für Disks)

```bash
watch -n 30 'for disk in /dev/sd?; do smartctl -A "$disk" 2>/dev/null | awk -v dev="$disk" "/Current Drive Temperature/ {print dev \": \" \$4 \"°C\"}"; done'
```

## Nach Temperatur sortiert

```bash
for disk in /dev/sd?; do
  temp=$(smartctl -A "$disk" 2>/dev/null | awk '/Current Drive Temperature/ {print $4}');
  [ -n "$temp" ] && echo "$temp $disk";
done | sort -n | awk '{print $2 ": " $1 "°C"}'
```

Zeigt Disks von kalt nach warm sortiert.

## NVMe SSDs

```bash
for disk in /dev/nvme?n1; do
  smartctl -A "$disk" 2>/dev/null | awk -v dev="$disk" '/Temperature:/ {print dev ": " $2 "°C"}';
done
```

## Detaillierte SMART-Informationen

```bash
smartctl -a /dev/sda
```

Zeigt alle SMART-Attribute inklusive:
- Temperatur
- Power-On Hours
- Reallocated Sectors
- Pending Sectors
- Health Status

## Script für übersichtlichere Ausgabe

```bash
#!/bin/bash
echo "Disk Temperatures:"
echo "=================="
for disk in /dev/sd?; do
  if smartctl -i "$disk" 2>/dev/null | grep -q "Device Model"; then
    model=$(smartctl -i "$disk" 2>/dev/null | grep "Device Model" | awk '{print $3, $4}')
    temp=$(smartctl -A "$disk" 2>/dev/null | awk '/Current Drive Temperature/ {print $4}')
    if [ -n "$temp" ]; then
      printf "%-10s %-20s %s°C\n" "$disk" "$model" "$temp"
    fi
  fi
done
```

Speichern als `/root/disk-temps.sh`, ausführbar machen:
```bash
chmod +x /root/disk-temps.sh
./disk-temps.sh
```

## Temperatur-Warnung

Script das warnt wenn Festplatten zu heiß werden:

```bash
#!/bin/bash
TEMP_WARN=45
TEMP_CRIT=50

for disk in /dev/sd?; do
  temp=$(smartctl -A "$disk" 2>/dev/null | awk '/Current Drive Temperature/ {print $4}')
  if [ -n "$temp" ]; then
    if [ "$temp" -ge "$TEMP_CRIT" ]; then
      echo "CRITICAL: $disk is $temp°C (>=$TEMP_CRIT°C)"
    elif [ "$temp" -ge "$TEMP_WARN" ]; then
      echo "WARNING: $disk is $temp°C (>=$TEMP_WARN°C)"
    fi
  fi
done
```

## Integration in TrueNAS

### Via WebUI

TrueNAS Scale zeigt Disk-Temperaturen automatisch:
- Storage → Disks
- Spalte "Temperature" aktivieren

### Via CLI (SSH)

```bash
# Als root auf TrueNAS einloggen
ssh root@truenas-ip

# Temperatures abfragen
midclt call disk.temperatures
```

TrueNAS eigener Befehl (zeigt JSON):
```bash
midclt call disk.query | jq '.[] | {name: .name, temperature: .temperature}'
```

## Cron-Job für Logging

Temperaturen stündlich loggen:

```bash
crontab -e
```

Füge hinzu:
```cron
0 * * * * /root/disk-temps.sh >> /var/log/disk-temps.log
```

## Wichtige Hinweise

- **Nicht zu oft abfragen** - smartctl-Abfragen belasten die Disks leicht
- **Normale Temperaturen** - 30-45°C sind normal, >50°C kritisch
- **SAS vs SATA** - Beide nutzen gleiche SMART-Befehle
- **TrueNAS Updates** - Nach Updates eventuell smartmontools neu installieren falls CLI-Tools fehlen

## Troubleshooting

### smartctl nicht gefunden

```bash
apt update && apt install smartmontools
```

### Keine Temperatur angezeigt

Nicht alle Disks/Controller unterstützen Temperatur-Reporting. Prüfen:
```bash
smartctl -a /dev/sda | grep -i temp
```

Falls leer: Disk oder Controller unterstützt keine Temperatur-Ausgabe via SMART.

### Permission denied

Als root ausführen:
```bash
sudo smartctl -A /dev/sda
```
