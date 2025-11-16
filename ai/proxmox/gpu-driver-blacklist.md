# GPU-Treiber Blacklisten

Verhindert dass der Host GPU-Treiber lädt. Notwendig für GPU-Passthrough an VMs.

## Nouveau (Open-Source NVIDIA Treiber) blacklisten

```bash
echo "blacklist nouveau" >> /etc/modprobe.d/blacklist.conf
```

## Proprietary NVIDIA Treiber blacklisten

```bash
echo "blacklist nvidia" >> /etc/modprobe.d/blacklist.conf
```

## AMD GPU Treiber blacklisten

```bash
echo "blacklist amdgpu" >> /etc/modprobe.d/blacklist.conf
echo "blacklist radeon" >> /etc/modprobe.d/blacklist.conf
```

## Initramfs neu generieren

Nach Änderungen Initramfs aktualisieren:

```bash
update-initramfs -u -k all
```

## Reboot

Blacklist wird erst nach Neustart aktiv:

```bash
reboot
```

## Prüfen ob Treiber geladen ist

```bash
lsmod | grep nouveau
lsmod | grep nvidia
lsmod | grep amdgpu
```

Keine Ausgabe = Treiber nicht geladen (gut für Passthrough).

## Blacklist entfernen

```bash
nano /etc/modprobe.d/blacklist.conf
```

Zeile löschen, dann:

```bash
update-initramfs -u -k all
reboot
```

## Typischer Workflow für GPU-Passthrough

1. GPU-Treiber blacklisten
2. VFIO-Module laden (für Passthrough)
3. Initramfs neu generieren
4. Reboot
5. GPU an VM durchreichen

Siehe auch: IOMMU-Konfiguration und VFIO-Setup für vollständiges GPU-Passthrough.

## Wann blacklisten?

- **GPU-Passthrough** - Host darf GPU nicht nutzen
- **Troubleshooting** - Probleme mit bestimmten Treibern
- **Multi-GPU-Setup** - Nur bestimmte GPUs für Host reservieren
