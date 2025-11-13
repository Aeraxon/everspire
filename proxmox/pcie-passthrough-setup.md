# PCIe Passthrough Setup

Komplettes Setup für GPU/PCIe-Device Passthrough an VMs.

## 1. IOMMU Support aktivieren

### Legacy BIOS Boot

```bash
nano /etc/default/grub
```

Intel CPU:
```bash
GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on"
```

AMD CPU:
```bash
GRUB_CMDLINE_LINUX_DEFAULT="quiet amd_iommu=on"
```

Grub aktualisieren:
```bash
update-grub
```

### EFI Boot

```bash
nano /etc/kernel/cmdline
```

Intel CPU:
```
intel_iommu=on
```

AMD CPU:
```
amd_iommu=on
```

Bootloader aktualisieren:
```bash
proxmox-boot-tool refresh
```

## 2. VFIO Module laden

```bash
nano /etc/modules
```

Füge hinzu:
```
vfio
vfio_iommu_type1
vfio_pci
vfio_virqfd
```

## 3. VFIO und KVM konfigurieren

```bash
echo "options vfio_iommu_type1 allow_unsafe_interrupts=1" > /etc/modprobe.d/iommu_unsafe_interrupts.conf
echo "options kvm ignore_msrs=1" > /etc/modprobe.d/kvm.conf
```

## 4. GPU-Treiber blacklisten (optional)

**Nur wenn Host die GPU nicht nutzen soll:**

```bash
echo "blacklist nouveau" >> /etc/modprobe.d/blacklist.conf
echo "blacklist nvidia" >> /etc/modprobe.d/blacklist.conf
```

AMD GPU:
```bash
echo "blacklist amdgpu" >> /etc/modprobe.d/blacklist.conf
echo "blacklist radeon" >> /etc/modprobe.d/blacklist.conf
```

## 5. GPU für Passthrough konfigurieren

### GPU finden

```bash
lspci | grep -i vga
lspci | grep -i nvidia
```

Beispiel-Ausgabe:
```
82:00.0 VGA compatible controller: NVIDIA Corporation ...
82:00.1 Audio device: NVIDIA Corporation ...
```

**Wichtig:** Notiere die PCI-Adresse (hier: `82:00`)

### Device IDs auslesen

```bash
lspci -n -s 82:00 -v
```

Ersetze `82:00` mit deiner PCI-Adresse.

Beispiel-Ausgabe:
```
82:00.0 0300: 10de:2204 (rev a1)
82:00.1 0403: 10de:1aef (rev a1)
```

Wichtig: Die Hex-Werte nach dem Leerzeichen (z.B. `10de:2204`, `10de:1aef`)

### VFIO konfigurieren

```bash
echo "options vfio-pci ids=10de:2204,10de:1aef disable_vga=1" > /etc/modprobe.d/vfio.conf
```

Ersetze die IDs mit deinen Device IDs (Komma-separiert, GPU + Audio).

**Pattern:**
```bash
echo "options vfio-pci ids=XXXX:YYYY,XXXX:ZZZZ disable_vga=1" > /etc/modprobe.d/vfio.conf
```

## 6. Änderungen anwenden

```bash
update-initramfs -u -k all
```

## 7. Reboot

```bash
reboot
```

## 8. Passthrough prüfen

Nach Reboot prüfen ob VFIO die GPU übernommen hat:

```bash
lspci -k | grep -A 3 -i vga
```

Bei erfolgreicher Konfiguration sollte `Kernel driver in use: vfio-pci` angezeigt werden.

IOMMU-Gruppen anzeigen:
```bash
find /sys/kernel/iommu_groups/ -type l
```

## 9. GPU an VM zuweisen

In Proxmox Web UI:
1. VM auswählen → Hardware → Add → PCI Device
2. GPU auswählen (die mit vfio-pci)
3. Haken bei "All Functions" (für GPU + Audio)
4. Optional: "Primary GPU" aktivieren
5. Optional: "PCI-Express" aktivieren
6. VM starten

## Troubleshooting

### IOMMU nicht aktiv
```bash
dmesg | grep -i iommu
```

Sollte IOMMU-Meldungen zeigen. Falls nicht, BIOS-Einstellungen prüfen (VT-d/AMD-Vi aktivieren).

### GPU wird nicht von vfio-pci verwendet
```bash
lspci -k -s 82:00.0  # Ersetze mit deiner PCI-Adresse
```

Prüfe "Kernel driver in use". Falls anderer Treiber: Blacklist prüfen, Initramfs neu generieren.

### VM bootet nicht / schwarzer Bildschirm
- UEFI BIOS für VM verwenden (nicht SeaBIOS)
- "Primary GPU" deaktivieren wenn Host auch eine GPU hat
- OVMF BIOS mit SecureBoot deaktiviert

## Vollständiges Beispiel (NVIDIA GPU, EFI Boot, Intel)

```bash
# 1. IOMMU aktivieren
echo "intel_iommu=on" >> /etc/kernel/cmdline
proxmox-boot-tool refresh

# 2. VFIO Module
cat <<EOF >> /etc/modules
vfio
vfio_iommu_type1
vfio_pci
vfio_virqfd
EOF

# 3. VFIO/KVM Config
echo "options vfio_iommu_type1 allow_unsafe_interrupts=1" > /etc/modprobe.d/iommu_unsafe_interrupts.conf
echo "options kvm ignore_msrs=1" > /etc/modprobe.d/kvm.conf

# 4. Treiber blacklisten
echo "blacklist nouveau" >> /etc/modprobe.d/blacklist.conf
echo "blacklist nvidia" >> /etc/modprobe.d/blacklist.conf

# 5. GPU Device IDs auslesen und VFIO konfigurieren
lspci | grep -i nvidia
lspci -n -s 82:00 -v  # Deine PCI-Adresse
echo "options vfio-pci ids=10de:2204,10de:1aef disable_vga=1" > /etc/modprobe.d/vfio.conf

# 6. Anwenden
update-initramfs -u -k all

# 7. Reboot
reboot

# 8. Nach Reboot prüfen
lspci -k | grep -A 3 -i vga
```
