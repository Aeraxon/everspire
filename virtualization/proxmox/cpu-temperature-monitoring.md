# CPU Temperatur Monitoring

Systemtemperaturen (CPU, GPU, Mainboard) auslesen mit lm-sensors.

## Installation

```bash
apt update && apt install lm-sensors
```

## Sensoren erkennen

```bash
sensors-detect
```

Bei allen Fragen mit `ENTER` (default: YES) bestätigen. Schreibt Konfiguration automatisch.

## Alle Sensoren anzeigen

```bash
sensors
```

Zeigt alle erkannten Temperaturen, Lüfter-Geschwindigkeiten und Spannungen.

Beispiel-Ausgabe:
```
k10temp-pci-00c3
Adapter: PCI adapter
Tctl:         +45.0°C

coretemp-isa-0000
Adapter: ISA adapter
Package id 0:  +42.0°C
Core 0:        +38.0°C
Core 1:        +40.0°C
```

## Spezifische Sensoren filtern

### AMD CPU Temperatur

```bash
sensors | grep -E 'k10temp|Tctl'
```

### Intel CPU Temperatur

```bash
sensors | grep -E 'coretemp|Package'
```

### AMD GPU (integriert)

```bash
sensors | grep -E 'amdgpu|edge'
```

### NVIDIA GPU

```bash
nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader
```

## Auto-Refresh mit watch

### Alle Sensoren (Update alle 1 Sekunde)

```bash
watch -n 1 sensors
```

### Nur CPU (AMD)

```bash
watch -n 1 "sensors | grep -E 'k10temp|Tctl'"
```

### Nur CPU (Intel)

```bash
watch -n 1 "sensors | grep -E 'coretemp|Package'"
```

### CPU + GPU (AMD Server Beispiel)

```bash
watch -n 1 "sensors | grep -E 'k10temp-pci-00c3|amdgpu-pci-0d00|Tctl|edge'"
```

**Pattern anpassen:** Ersetze PCI-IDs mit deinen Werten aus `sensors` Ausgabe.

## Eigene PCI-IDs finden

```bash
sensors
```

Suche nach deinen CPU/GPU Adapter-Namen (z.B. `k10temp-pci-00c3`, `coretemp-isa-0000`).

Beispiel für eigenen Filter:
```bash
# Deine Adapter aus sensors Ausgabe kopieren
sensors | grep -E 'dein-adapter|dein-wert'
```

## Alarmwerte konfigurieren (optional)

```bash
sensors -A  # Zeigt Alarm-Limits
```

Custom Limits in `/etc/sensors.d/` konfigurieren.

## In Proxmox Web UI anzeigen

Proxmox zeigt CPU-Temperatur automatisch wenn lm-sensors installiert ist:
- Node auswählen → Summary
- Temperatur erscheint unter "CPU(s)" Bereich

Eventuell Seite neu laden nach Installation.

## Nützliche Varianten

### Minimal - nur Temperatur-Werte

```bash
sensors | grep '°C'
```

### Mit Timestamp loggen

```bash
while true; do echo "$(date '+%Y-%m-%d %H:%M:%S') - $(sensors | grep Tctl)"; sleep 60; done >> /var/log/cpu-temp.log
```

### Höchste Temperatur highlighten (bash)

```bash
sensors | grep '°C' | sort -t+ -k2 -n
```

## Troubleshooting

### Keine Sensoren gefunden

```bash
# Module manuell laden (Beispiel für k10temp)
modprobe k10temp

# Verfügbare Sensor-Module
ls /lib/modules/$(uname -r)/kernel/drivers/hwmon/
```

### sensors-detect hat nichts erkannt

Manche Server/Mainboards benötigen spezielle Module. BIOS-Update kann helfen.

### Temperatur zeigt unrealistische Werte

AMD Tctl kann Offset haben. Nutze Tdie (Die Temperature) falls verfügbar:
```bash
sensors | grep Tdie
```

## Beispiel: Multi-CPU AMD Server

```bash
# Alle CPUs
sensors | grep -E 'k10temp|Tctl'

# Mit watch
watch -n 2 "sensors | grep -E 'k10temp|Tctl'"
```

## Beispiel: Intel Workstation

```bash
# CPU Temperatur
sensors | grep -E 'Package|Core'

# Mit watch
watch -n 2 "sensors | grep -E 'Package|Core'"
```
