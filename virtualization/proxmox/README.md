# Proxmox

Proxmox VE Setup, Monitoring und VM-Management.

## Anleitungen

### cpu-c-states.md
CPU C-States auslesen und verwalten für Power-Management und Performance-Tuning.

```bash
apt install linux-cpupower
cpupower idle-info
```

### cpu-temperature-monitoring.md
CPU/GPU Temperaturen auslesen mit lm-sensors.

```bash
apt install lm-sensors
sensors-detect
sensors
watch -n 1 "sensors | grep -E 'k10temp|Tctl'"  # AMD
```

### pbs-on-truenas-scale.md
Proxmox Backup Server Installation in LXC Container auf TrueNAS Scale.

Schritte:
1. Dataset-Struktur vorbereiten
2. LXC Container erstellen
3. PBS installieren
4. Storage mounten mit incus
5. Datastore konfigurieren
6. Integration in TrueNAS Snapshots/Replikation

---

## GPU & AI Workloads

GPU-bezogene Proxmox Guides wurden nach **[ai/proxmox/](ai/proxmox/)** verschoben:
- GPU-Passthrough für VMs
- NVIDIA GPU in LXC Containern
- Kernel-Pinning für GPU-Stabilität
- GPU-Treiber Blacklisting
- GPU-Initialisierung für Container
