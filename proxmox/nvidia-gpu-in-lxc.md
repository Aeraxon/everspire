# NVIDIA GPU in LXC Container nutzen

GPU-Zugriff für LXC Container ermöglichen. GPU wird vom Host geteilt, mehrere Container können gleichzeitig zugreifen.

## Voraussetzungen

- Proxmox VE Host
- NVIDIA GPU im System
- GPU darf nicht an VM durchgereicht sein (kein GPU Passthrough)
- GPU darf nicht auf Kernel-Blacklist stehen

## 1. Proxmox Host vorbereiten

### System aktualisieren

```bash
apt update && apt upgrade -y
reboot
```

Nach Reboot weiter.

### Kernel pinnen (empfohlen)

Verhindert automatische Kernel-Updates die Treiber brechen können.

```bash
# Aktuelle Kernel anzeigen
proxmox-boot-tool kernel list

# Aktuellen Kernel pinnen
proxmox-boot-tool kernel pin $(uname -r)
```

Siehe: `kernel-pinning.md`

### PVE-Headers installieren

**Vor** Treiber-Installation:

```bash
apt install pve-headers-$(uname -r)
```

## 2. NVIDIA Treiber auf Host installieren

### Treiber herunterladen

Von https://www.nvidia.com/Download/index.aspx

Oder direkt:
```bash
wget https://download.nvidia.com/XFree86/Linux-x86_64/<VERSION>/NVIDIA-Linux-x86_64-<VERSION>.run
```

Beispiel für Treiber 550.127.05:
```bash
wget https://download.nvidia.com/XFree86/Linux-x86_64/550.127.05/NVIDIA-Linux-x86_64-550.127.05.run
chmod +x NVIDIA-Linux-x86_64-550.127.05.run
```

### Treiber installieren

```bash
./NVIDIA-Linux-x86_64-<VERSION>.run --dkms
```

**Wichtig:**
- `--dkms` für automatische Kernel-Modul-Updates
- **Keine** xorg/GUI-Komponenten installieren (wenn headless)
- Bei Fehlern: PVE-Headers prüfen

### Reboot und Test

```bash
reboot
```

Nach Reboot:
```bash
nvidia-smi
```

Sollte GPU(s) anzeigen:
```
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 550.127.05             Driver Version: 550.127.05     CUDA Version: 12.4     |
|-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|=========================================+========================+======================|
|   0  NVIDIA GeForce RTX 3090      Off   | 00000000:01:00.0  Off |                  N/A |
| 30%   45C    P0              69W / 350W |       0MiB / 24576MiB |      0%      Default |
+-----------------------------------------+------------------------+----------------------+
```

## 3. Device-Nummern ermitteln

```bash
ls -al /dev/nvidia*
```

Beispiel-Ausgabe:
```
crw-rw-rw- 1 root root 195,   0 Dec 30 10:00 /dev/nvidia0
crw-rw-rw- 1 root root 195, 255 Dec 30 10:00 /dev/nvidiactl
crw-rw-rw- 1 root root 195, 254 Dec 30 10:00 /dev/nvidia-modeset
crw-rw-rw- 1 root root 507,   0 Dec 30 10:00 /dev/nvidia-uvm
crw-rw-rw- 1 root root 507,   1 Dec 30 10:00 /dev/nvidia-uvm-tools
```

**Wichtig:** Major-Nummern notieren (hier: **195** und **507**)

## 4. LXC Container konfigurieren

### Container-Config bearbeiten

```bash
nano /etc/pve/lxc/<VMID>.conf
```

Ersetze `<VMID>` mit deiner Container-ID (z.B. 250).

### GPU-Devices hinzufügen

Am Ende der Datei hinzufügen:

```bash
# NVIDIA GPU Passthrough
lxc.cgroup2.devices.allow: c 195:* rwm
lxc.cgroup2.devices.allow: c 507:* rwm
lxc.mount.entry: /dev/nvidia0 dev/nvidia0 none bind,optional,create=file
lxc.mount.entry: /dev/nvidiactl dev/nvidiactl none bind,optional,create=file
lxc.mount.entry: /dev/nvidia-modeset dev/nvidia-modeset none bind,optional,create=file
lxc.mount.entry: /dev/nvidia-uvm dev/nvidia-uvm none bind,optional,create=file
lxc.mount.entry: /dev/nvidia-uvm-tools dev/nvidia-uvm-tools none bind,optional,create=file
```

**Anpassen:** Major-Nummern mit deinen Werten aus Schritt 3 ersetzen.

### Mehrere GPUs

Für zweite GPU (`/dev/nvidia1`):
```bash
lxc.mount.entry: /dev/nvidia1 dev/nvidia1 none bind,optional,create=file
```

### Beispiel vollständige Config

```bash
arch: amd64
cores: 8
memory: 16384
swap: 8192
hostname: ml-container
net0: name=eth0,bridge=vmbr0,ip=dhcp,type=veth
ostype: ubuntu
rootfs: local-lvm:vm-250-disk-0,size=100G
unprivileged: 1
features: nesting=1

# NVIDIA GPU
lxc.cgroup2.devices.allow: c 195:* rwm
lxc.cgroup2.devices.allow: c 507:* rwm
lxc.mount.entry: /dev/nvidia0 dev/nvidia0 none bind,optional,create=file
lxc.mount.entry: /dev/nvidiactl dev/nvidiactl none bind,optional,create=file
lxc.mount.entry: /dev/nvidia-modeset dev/nvidia-modeset none bind,optional,create=file
lxc.mount.entry: /dev/nvidia-uvm dev/nvidia-uvm none bind,optional,create=file
lxc.mount.entry: /dev/nvidia-uvm-tools dev/nvidia-uvm-tools none bind,optional,create=file
```

### Container neu starten

```bash
pct stop <VMID>
pct start <VMID>
```

## 5. NVIDIA Treiber im Container installieren

**Wichtig:** Gleiche Treiber-Version wie auf Host!

### Container Shell öffnen

```bash
pct enter <VMID>
```

### Treiber herunterladen

Im Container:
```bash
apt update
apt install wget -y
wget https://download.nvidia.com/XFree86/Linux-x86_64/<VERSION>/NVIDIA-Linux-x86_64-<VERSION>.run
chmod +x NVIDIA-Linux-x86_64-<VERSION>.run
```

**Oder:** Mit scp vom Host kopieren (von anderem Terminal):
```bash
scp NVIDIA-Linux-x86_64-<VERSION>.run root@<container-ip>:/root/
```

### Treiber installieren (ohne Kernel-Module)

```bash
./NVIDIA-Linux-x86_64-<VERSION>.run --no-kernel-module
```

**Wichtig:**
- `--no-kernel-module` - Container nutzt Host-Kernel
- **Keine** Kernel-Module kompilieren
- **Keine** xorg-Komponenten (wenn headless)

### Test im Container

```bash
nvidia-smi
```

Sollte gleiche GPU(s) wie auf Host zeigen.

## 6. CUDA-Unterstützung testen

### CUDA Toolkit installieren (optional)

Nur wenn CUDA-Apps verwendet werden (z.B. PyTorch, TensorFlow):

```bash
# Im Container
apt install nvidia-cuda-toolkit -y
```

Oder spezifische Version von https://developer.nvidia.com/cuda-downloads

### Test mit nvidia-smi

```bash
nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv
```

## Troubleshooting

### Container sieht GPU nicht nach Reboot

Siehe: `nvidia-gpu-lxc-init.md` - Systemd Service für automatische GPU-Initialisierung.

Kurz:
```bash
# Auf Host einmal ausführen
nvidia-smi

# Container neu starten
pct restart <VMID>
```

### Permission Denied

```bash
# Auf Host: Permissions prüfen
ls -al /dev/nvidia*

# Sollten rw-rw-rw sein
chmod 666 /dev/nvidia*
```

### Major-Nummern falsch

```bash
# Auf Host prüfen
ls -al /dev/nvidia* | awk '{print $5, $6}'

# In Container-Config anpassen
nano /etc/pve/lxc/<VMID>.conf
```

### Treiber-Version Mismatch

Host und Container müssen **exakt gleiche** Treiber-Version haben.

```bash
# Host
nvidia-smi | grep "Driver Version"

# Container
nvidia-smi | grep "Driver Version"
```

Bei Unterschied: Treiber im Container neu installieren.

### Kernel-Update bricht Treiber

```bash
# Auf Host
apt install pve-headers-$(uname -r)
./NVIDIA-Linux-x86_64-<VERSION>.run --dkms
reboot
```

**Oder:** Kernel pinnen (siehe Schritt 1).

## Mehrere Container

Dieselbe GPU kann von mehreren Containern gleichzeitig genutzt werden.

**Für jeden Container wiederholen:**
1. Container-Config editieren (Schritt 4)
2. Container neu starten
3. Treiber im Container installieren (Schritt 5)

**Limitierung:** Consumer-GPUs haben Limit für Video Encoder/Decoder Streams (meist 3-5).

## GPU-Auslastung überwachen

### Auf Host

```bash
# Einfach
watch -n 1 nvidia-smi

# Mit Prozessen
nvidia-smi pmon -c 1
```

### In Container

```bash
nvidia-smi dmon -c 1
```

## Updates

### Treiber-Update

```bash
# 1. Auf Host
apt install pve-headers-$(uname -r)
./NVIDIA-Linux-x86_64-<NEW-VERSION>.run --dkms
reboot

# 2. In jedem Container
pct enter <VMID>
./NVIDIA-Linux-x86_64-<NEW-VERSION>.run --no-kernel-module
```

### Proxmox-Update

Nach Proxmox-Update:
1. PVE-Headers prüfen: `apt install pve-headers-$(uname -r)`
2. Falls Kernel geändert: Treiber neu installieren
3. Container neu starten

## Nützliche Befehle

```bash
# Container mit GPU auflisten
grep -l "nvidia" /etc/pve/lxc/*.conf

# GPU-Nutzung aller Container
for ct in $(pct list | awk 'NR>1 {print $1}'); do
  echo "Container $ct:"
  pct exec $ct -- nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader 2>/dev/null
done

# Devices in Container prüfen
pct enter <VMID>
ls -al /dev/nvidia*
```

## Alternative: Docker mit GPU in LXC

Falls Docker im LXC Container:

```bash
# Im Container: NVIDIA Container Toolkit
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

apt update
apt install nvidia-container-toolkit -y
nvidia-ctk runtime configure --runtime=docker
systemctl restart docker

# Test
docker run --rm --gpus all nvidia/cuda:12.4.0-base-ubuntu22.04 nvidia-smi
```

Siehe: `docker/installation/install-docker.sh` mit GPU-Option.

## Best Practices

- **Kernel pinnen** - verhindert Treiber-Probleme bei Updates
- **Gleiche Treiber-Version** - Host und Container synchron halten
- **GPU-Init Service** - für automatische Initialisierung nach Reboot
- **Monitoring** - GPU-Auslastung überwachen
- **Backups** - Container-Configs regelmäßig sichern
- **Dokumentation** - Treiber-Version und Config dokumentieren

## Verwandte Themen

- **GPU Passthrough:** `pcie-passthrough-setup.md` (für VMs)
- **GPU Init Service:** `nvidia-gpu-lxc-init.md` (Container sehen GPU nach Reboot)
- **GPU Treiber Blacklist:** `gpu-driver-blacklist.md` (falls GPU an VM)
- **Docker GPU:** `../docker/installation/install-docker.sh` (GPU in Docker)

---

**Ermöglicht GPU-Zugriff für LXC Container mit geteiltem Host-Kernel.**

## Credits

Basiert auf Erkenntnissen von Yomi's Blog:
https://yomis.blog/nvidia-gpu-in-proxmox-lxc/
