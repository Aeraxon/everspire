# TrueNAS Scale

TrueNAS Scale Konfiguration, Monitoring und Management.

## Anleitungen

### disk-temperature-monitoring.md
Festplatten-Temperaturen mit smartctl auslesen.

```bash
for disk in /dev/sd?; do
  smartctl -A "$disk" 2>/dev/null | awk -v dev="$disk" '/Current Drive Temperature/ {print dev ": " $4 "°C"}';
done
```
