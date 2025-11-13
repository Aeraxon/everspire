# Proxmox

Proxmox VE Setup, LXC Container und VM-Management.

## Anleitungen

### kernel-pinning.md
Kernel-Version pinnen um automatische Kernel-Updates zu verhindern.

```bash
proxmox-boot-tool kernel list
proxmox-boot-tool kernel pin <kernel-version>
```

### cpu-c-states.md
CPU C-States auslesen und verwalten für Power-Management und Performance-Tuning.

```bash
apt install linux-cpupower
cpupower idle-info
```

### gpu-driver-blacklist.md
GPU-Treiber blacklisten für GPU-Passthrough an VMs.

```bash
echo "blacklist nouveau" >> /etc/modprobe.d/blacklist.conf
echo "blacklist nvidia" >> /etc/modprobe.d/blacklist.conf
update-initramfs -u -k all
reboot
```

### pcie-passthrough-setup.md
Komplettes Setup für PCIe/GPU Passthrough an VMs.

Schritte:
1. IOMMU aktivieren (Legacy/EFI, Intel/AMD)
2. VFIO Module laden
3. GPU-Treiber blacklisten
4. Device IDs konfigurieren
5. An VM zuweisen

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

### nvidia-gpu-in-lxc.md
NVIDIA GPU in LXC Container nutzen mit geteiltem Host-Kernel.

Schritte:
1. Proxmox Update + Kernel Pin
2. PVE-Headers + NVIDIA Treiber auf Host (mit --dkms)
3. Device-Nummern ermitteln
4. Container-Config anpassen (cgroup2.devices.allow + mount.entry)
5. Treiber im Container (mit --no-kernel-module)

GPU kann von mehreren Containern gleichzeitig genutzt werden.

### nvidia-gpu-lxc-init.md
NVIDIA GPU automatisch beim Boot initialisieren für LXC Container.

Löst Problem: Container sehen GPU nach Reboot nicht, bis auf Host `nvidia-smi` ausgeführt wurde.

```bash
# Systemd Service installieren
systemctl enable nvidia-init.service
```
