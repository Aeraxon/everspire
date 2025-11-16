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

### docker-lxc-apparmor-fix.md
Fix AppArmor conflicts when running Docker in unprivileged Proxmox LXC containers.

**Problem:** Docker fails with "permission denied: open sysctl net.ipv4.ip_unprivileged_port_start file"

**Quick fix:**
```bash
# Add to /etc/pve/lxc/100.conf:
lxc.apparmor.profile: unconfined
lxc.mount.entry: /dev/null sys/module/apparmor/parameters/enabled none bind 0 0
```

Required for containerd.io 1.7.28+ in nested containers. Container remains unprivileged.

---

## GPU & AI Workloads

GPU-bezogene Proxmox Guides wurden nach **[ai/proxmox/](ai/proxmox/)** verschoben:
- GPU-Passthrough für VMs
- NVIDIA GPU in LXC Containern
- Kernel-Pinning für GPU-Stabilität
- GPU-Treiber Blacklisting
- GPU-Initialisierung für Container
