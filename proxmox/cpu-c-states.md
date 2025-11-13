# CPU C-States auslesen

C-States sind CPU-Stromspar-Modi. Wichtig für Power-Management und Performance-Troubleshooting.

## Installation

```bash
apt update && apt install linux-cpupower
```

## C-States anzeigen

```bash
cpupower idle-info
```

Beispiel-Ausgabe:
```
CPUidle driver: intel_idle
CPUidle governor: menu
analyzing CPU 0:

Number of idle states: 4
Available idle states: POLL C1 C1E C6
POLL:
Flags/Description: CPUIDLE CORE POLL IDLE
Latency: 0
Usage: 12345
Duration: 1000000
C1:
Flags/Description: MWAIT 0x00
Latency: 2
Usage: 67890
Duration: 5000000
...
```

## Wichtige Felder

- **Driver** - z.B. `intel_idle` oder `acpi_idle`
- **Governor** - Strategie (meist `menu`)
- **Number of idle states** - Anzahl verfügbarer C-States
- **Latency** - Aufwachzeit in Mikrosekunden
- **Usage** - Wie oft wurde der State genutzt
- **Duration** - Gesamtzeit in diesem State

## C-States deaktivieren (falls nötig)

Für maximale Performance oder bei Latenzen-Problemen:

### Dauerhaft via Kernel-Parameter

```bash
nano /etc/default/grub
```

Füge zu `GRUB_CMDLINE_LINUX_DEFAULT` hinzu:
```
intel_idle.max_cstate=0 processor.max_cstate=1
```

Grub aktualisieren:
```bash
update-grub
reboot
```

### Temporär (bis Reboot)

```bash
cpupower idle-set -d 2  # Deaktiviert C-States ab Level 2
```

## Weitere nützliche Befehle

```bash
# CPU-Frequenz anzeigen
cpupower frequency-info

# CPU-Governor anzeigen
cpupower frequency-info | grep "current policy"

# Alle CPU-Infos
lscpu
```

## Wann relevant?

- Performance-Tuning (niedrige Latenzen)
- Strom-Verbrauch optimieren
- Troubleshooting bei CPU-Performance-Problemen
- PCIe-Passthrough oder GPU-Workloads
