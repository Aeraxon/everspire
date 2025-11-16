# Proxmox Kernel Pinning

Kernel Pinning verhindert automatische Kernel-Updates beim Upgrade. Nützlich wenn ein neuer Kernel Probleme verursacht.

## Verfügbare Kernel anzeigen

```bash
proxmox-boot-tool kernel list
```

Ausgabe zeigt installierte Kernel-Versionen, z.B.:
```
Manually selected kernels:
None.

Automatically selected kernels:
6.8.12-1-pve
6.5.13-5-pve
6.2.16-20-pve
```

## Kernel pinnen

```bash
proxmox-boot-tool kernel pin <kernel-version>
```

Beispiel:
```bash
proxmox-boot-tool kernel pin 6.5.13-5-pve
```

**Wichtig:** Kernel-Version muss exakt aus der Liste kopiert werden.

## Pin prüfen

```bash
proxmox-boot-tool kernel list
```

Gepinnter Kernel erscheint unter "Manually selected kernels".

## Pin entfernen

```bash
proxmox-boot-tool kernel unpin
```

System nutzt dann wieder automatisch den neuesten Kernel.

## Reboot

Kernel-Änderungen werden erst nach Neustart aktiv:

```bash
reboot
```

## Wann Kernel pinnen?

- Neuer Kernel verursacht Hardware-Probleme (z.B. GPU Passthrough)
- Neuer Kernel inkompatibel mit bestimmten Treibern
- Stabilen Kernel für Production-System sichern

Nach Pin werden Sicherheitsupdates für diesen Kernel weiter installiert, nur kein automatischer Wechsel zu neuerem Kernel.
