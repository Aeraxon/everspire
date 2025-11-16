# Incus Installation & Configuration Guide

## GPU-Enabled Bare Metal Host with Template-based Workflow

**Last Updated:** November 2025  
**Goal:** Complete setup of an Incus host with GPU support, DHCP networking, and template-based workflows

**Perfect for:** AI workloads, machine learning, GPU-accelerated applications  
**Special focus:** Docker-in-Incus with GPU support for container-based AI deployments

---

## Table of Contents

1. [OS Selection & Bare Metal Installation](#1-os-selection--bare-metal-installation)
2. [NVIDIA GPU Driver Installation](#2-nvidia-gpu-driver-installation)
3. [Incus Installation](#3-incus-installation)
   * 3a. [Set up Incus Web UI](#3a-set-up-incus-web-ui-optional-but-recommended-)
4. [Incus Initialization & Networking](#4-incus-initialization--networking)
5. [Configure External Bridge for Direct LAN Access](#5-configure-external-bridge-for-direct-lan-access)
6. [Configure GPU Support](#6-configure-gpu-support)
7. [Create Templates](#7-create-templates)
8. [Container Deployment Workflow](#8-container-deployment-workflow)
9. [Docker with GPU Support](#docker-with-gpu-support-in-containers) ⚠️ Important for AI workloads!

---

## 1. OS Selection & Bare Metal Installation

### Recommended OS: **Ubuntu 24.04 LTS Server**

**Why Ubuntu 24.04 LTS?**

* Native Incus packages in repository (as of 24.04)
* LTS = Long Term Support (5 years)
* Best NVIDIA driver support
* Large community for GPU/container workloads

**Alternative:** Debian 13 (Trixie) - works identically

### Bare Metal Installation

1. **Download Ubuntu Server 24.04 LTS ISO**
   ```
   https://ubuntu.com/download/server
   ```

2. **Create Installation USB**
   * Linux: `sudo dd if=ubuntu-24.04-live-server-amd64.iso of=/dev/sdX bs=4M status=progress`
   * Windows: Rufus or Balena Etcher

3. **Boot from USB & Run Installation**
   * Language: English or your preference
   * Network: Configure static IP or DHCP (depending on setup)
   * Storage:
     * **Recommendation:** Full disk for BTRFS or ext4
     * For GPU-intensive workloads: Prefer fast NVMe SSD
   * Create user account
   * Install OpenSSH Server ✓

4. **After Installation:**
   ```bash
   # Update system
   sudo apt update && sudo apt upgrade -y
   
   # Reboot if kernel was updated
   sudo reboot
   ```

5. **Configure SSH Keep-Alive (Recommended):**
   
   Prevents SSH connections from dropping after a few minutes of inactivity.
   
   ```bash
   # Enable SSH Keep-Alive
   sudo bash -c 'cat >> /etc/ssh/sshd_config << EOF

# Keep SSH connections alive
ClientAliveInterval 60
ClientAliveCountMax 120
EOF'
   
   # Restart SSH
   sudo systemctl restart ssh.service
   ```
   
   **What this does:**
   - Server sends keep-alive signal every 60 seconds
   - After 120 failed attempts (2 hours), connection is terminated
   - SSH sessions stay open practically indefinitely

---

## 2. NVIDIA GPU Driver Installation

### ℹ️ Important Info: Ubuntu 24.04 has CURRENT Drivers!

**Myth:** "Ubuntu apt only has old NVIDIA drivers"  
**Reality:** Ubuntu 24.04 LTS has drivers 550, 560, 565, 570, 575 - these are the **same** as on nvidia.com! Including the modern **open drivers** for new GPUs.

You have **two equivalent options:**

---

### **Option A: APT Installation (Recommended)** ⭐

**Why recommended:**

* ✅ Drivers are **current** (not outdated!)
* ✅ Automatic updates & DKMS
* ✅ Simple & stable
* ✅ Secure Boot compatible

**NVIDIA Open vs. Proprietary:**
* **Open drivers** (`-open` suffix): Recommended for **newer GPUs** (RTX 20-series and newer, Data Center GPUs)
* **Proprietary drivers** (no suffix): For older GPUs or special requirements

```bash
# Show available drivers
ubuntu-drivers list

# Output shows e.g.:
# nvidia-driver-550
# nvidia-driver-560
# nvidia-driver-565
# nvidia-driver-570-open  (recommended for new GPUs)
# nvidia-driver-570
# nvidia-driver-575

# Automatically install recommended driver
sudo ubuntu-drivers install

# OR manually specify version (recommended):
# For newer GPUs (RTX 20xx+, A-series, H-series):
sudo apt install nvidia-driver-570-open

# For older GPUs:
sudo apt install nvidia-driver-570

# Reboot required
sudo reboot
```

**For absolutely latest drivers (including beta):**

```bash
# Graphics Drivers PPA (optional - for beta versions)
sudo add-apt-repository ppa:graphics-drivers/ppa
sudo apt update

# Latest open drivers (for new GPUs):
sudo apt install nvidia-driver-570-open

# Or latest available version:
sudo apt install nvidia-driver-575
sudo reboot
```

---

### **Option B: .run File from NVIDIA Website**

**When to use:**

* You want **latest beta drivers** (e.g., 580.XX)
* Brand new GPU model not yet in apt
* Personal preference

**Disadvantages:**

* ⚠️ More complex setup
* ⚠️ No automatic apt updates
* ⚠️ Must manually recompile on kernel updates

```bash
# 1. Preparations
sudo apt update
sudo apt install build-essential dkms linux-headers-$(uname -r)

# 2. Blacklist Nouveau driver
sudo bash -c "echo 'blacklist nouveau' > /etc/modprobe.d/blacklist-nvidia-nouveau.conf"
sudo bash -c "echo 'options nouveau modeset=0' >> /etc/modprobe.d/blacklist-nvidia-nouveau.conf"
sudo update-initramfs -u
sudo reboot

# 3. After reboot: Stop display manager
# Login via TTY (Ctrl+Alt+F3)
sudo systemctl stop gdm3  # or lightdm/sddm if installed

# 4. Download .run file from NVIDIA website
# Visit: https://www.nvidia.com/download/index.aspx
# Select your GPU → Linux 64-bit → .run (local)

cd ~/Downloads
wget https://us.download.nvidia.com/XFree86/Linux-x86_64/565.XX.XX/NVIDIA-Linux-x86_64-565.XX.XX.run

# 5. Make executable and install
chmod +x NVIDIA-Linux-x86_64-565.XX.XX.run
sudo ./NVIDIA-Linux-x86_64-565.XX.XX.run --dkms

# Follow the installer:
# - "Install NVIDIA's 32-bit compatibility libraries?" → Yes (if needed)
# - "Would you like to run nvidia-xconfig?" → No (Server without desktop)
# - DKMS will be used automatically for kernel modules

sudo reboot
```

**On Kernel Updates (only .run file method):**

```bash
# DKMS should rebuild automatically, if not:
sudo dkms install -m nvidia -v 565.XX.XX
```

### Verify Driver

```bash
# Check GPU status
nvidia-smi

# Should output:
# +-----------------------------------------------------------------------------------------+
# | NVIDIA-SMI 565.XX.XX              Driver Version: 565.XX.XX      CUDA Version: 12.X     |
# |-------------------------------+----------------------+---------------------------+
# | GPU  Name                 ...  | 
# ...
```

---

### Install NVIDIA Container Toolkit

**⚠️ IMPORTANT:** The Container Toolkit is **ONLY** available via NVIDIA's repository - **NOT** in Ubuntu apt!  
Regardless of whether you installed drivers via apt or .run, the toolkit **always** comes directly from NVIDIA.

**Current Version:** 1.18.0 (Nov 2025) - actively maintained!

```bash
# 1. Add NVIDIA Container Toolkit repository
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
  sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt update

# 2. Install toolkit
sudo apt install nvidia-container-toolkit

# 3. Generate Container Device Interface (CDI)
# This is CRITICAL for Incus GPU support!
sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml

# 4. Verify CDI file
cat /etc/cdi/nvidia.yaml
# Should list your GPU(s)

# 5. Check toolkit version
nvidia-ctk --version
# Should be v1.18.0 or newer
```

**Why CDI is important:**  
CDI (Container Device Interface) is the modern standard for GPU access in containers. Incus uses CDI automatically when `nvidia.runtime=true` is set.

---

### 📊 Summary: Which Method to Choose?

| Criterion | APT (Option A) | .run File (Option B) |
|-----------|----------------|----------------------|
| **Driver Currency** | ✅ 570-open/575 available | ✅ Latest + Beta |
| **Installation** | ✅ Simple | ⚠️ Complex |
| **Updates** | ✅ `apt upgrade` | ❌ Manual |
| **Kernel Updates** | ✅ Automatic | ⚠️ Recompile |
| **Secure Boot** | ✅ Works | ⚠️ Manual signing |
| **Uninstallation** | ✅ `apt remove` | ⚠️ Manual |
| **Container Toolkit** | ✅ Same | ✅ Same |

**🎯 Recommendation for Incus Host:**  
**Option A (APT)** with **nvidia-driver-570-open** for modern GPUs - Unless you really need beta drivers 580.XX+

**Important:** The NVIDIA Container Toolkit is **identical** for **both** options and **always** comes from the NVIDIA repository!

---

### ⚠️ Important: Driver Updates and Container Compatibility

**The Golden Rule:** Host driver ≥ Container CUDA requirement

**Example:**
- Host: NVIDIA Driver 565 (supports CUDA 12.7)
- Container: Needs CUDA 12.1
- ✅ Works! (565 ≥ 12.1)

**If containers complain about CUDA version:**
```bash
# Check host driver
nvidia-smi

# If host driver is older than needed: Upgrade!
sudo apt update && sudo apt upgrade

# Or install newer version:
sudo apt install nvidia-driver-575
sudo reboot
```

**Container best practice:**
- Don't install nvidia-driver in containers
- Let host provide driver via container toolkit
- Only install CUDA Toolkit in container if needed for development

---

## 3. Incus Installation

### Install Incus from Zabbly Repository

**Why Zabbly?**

* ✅ Includes official Incus Web UI
* ✅ More up-to-date than Ubuntu's native packages
* ✅ Commercial support available
* ✅ Tested as complete integrated solution
* ✅ Proper `incus-admin` group management
* ✅ Choice between LTS (stable) and latest features (stable branch)

---

### Installation Steps

```bash
# 1. Verify and install GPG key
curl -fsSL https://pkgs.zabbly.com/key.asc | gpg --show-keys --fingerprint

# Should display:
# 4EFC 5906 96CB 15B8 7C73 A3AD 82CC 8797 C838 DCFD

# Install key
sudo mkdir -p /etc/apt/keyrings/
sudo curl -fsSL https://pkgs.zabbly.com/key.asc -o /etc/apt/keyrings/zabbly.asc
```

**Choose your repository:**

**Option A: LTS 6.0 (Recommended for production)**
```bash
# Add repository (6.0 LTS - stable)
sudo sh -c 'cat <<EOF > /etc/apt/sources.list.d/zabbly-incus-lts-6.0.sources
Enabled: yes
Types: deb
URIs: https://pkgs.zabbly.com/incus/lts-6.0
Suites: $(. /etc/os-release && echo ${VERSION_CODENAME})
Components: main
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/zabbly.asc
EOF'
```

**Option B: Stable (Latest features)**
```bash
# OR for latest features (stable branch):
sudo sh -c 'cat <<EOF > /etc/apt/sources.list.d/zabbly-incus-stable.sources
Enabled: yes
Types: deb
URIs: https://pkgs.zabbly.com/incus/stable
Suites: $(. /etc/os-release && echo ${VERSION_CODENAME})
Components: main
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/zabbly.asc
EOF'
```

**Complete installation:**
```bash
# Install Incus with Web UI
sudo apt update
sudo apt install incus incus-ui-canonical -y
```

**Configure user access:**

After installation, add your user to the `incus-admin` group:

```bash
# Add your user to incus-admin group
sudo usermod -aG incus-admin $USER

# Activate group membership (or logout and login again)
newgrp incus-admin

# Verify Incus version
incus version
# LTS: Should show 6.0.x
# Stable: Should show 6.7 or newer (as of Nov 2025)
```

**What gets installed:**
- `incus` - Core system container and VM manager
- `incus-ui-canonical` - Official web interface

---

### 3a. Set up Incus Web UI (Optional but Recommended) 🌐

**Why use the Web UI?**
- ✅ Easy container management
- ✅ Visual overview of all containers
- ✅ One-click start/stop/console
- ✅ GPU device management
- ✅ No CLI needed for basic tasks

#### Step 1: Enable Web UI

```bash
# Enable Web UI on port 8443
sudo incus config set core.https_address :8443
```

#### Step 2: Generate Trust Token

```bash
# Generate trust token for browser access
# Replace "my-browser" with any name you prefer
incus config trust add my-browser
```

**Output will show:**
```
Client my-browser certificate add token:
eyJjbGllbnRfbmFtZSI6Im15LWJyb3dzZXIi...
```

**Copy this entire token!** You'll need it in the next step.

#### Step 3: Access Web UI

1. **Open browser:** `https://<server-ip>:8443`

2. **Accept self-signed certificate warning:**
   - Click "Advanced" → "Proceed to <server-ip> (unsafe)"
   - This is normal for self-signed certificates

3. **You'll see the Incus UI welcome page**

4. **Click "Login with TLS"**

5. **On the left sidebar, click the second option** (token-based authentication)

6. **In Step 2, paste your token directly into the field**
   - The token you copied from `incus config trust add my-browser`
   - Should start with `eyJjbGllbnRfbmFtZSI...`

7. **Click "Submit" or "Authenticate"**

**You're in!** 🎉

**Web UI Features:**
- **Dashboard:** Overview of all instances
- **Instances:** Create/manage containers
- **Images:** Local templates
- **Storage:** Manage storage pools
- **Networks:** Network configuration
- **Settings:** Server configuration

**Security Note:** The self-signed certificate warning is normal. For production, consider using a proper certificate (Let's Encrypt, etc.).

---

## 4. Incus Initialization & Networking

### Initialize Incus

```bash
# Run initialization wizard
sudo incus admin init
```

**Wizard Questions & Recommended Answers:**

```
Would you like to use clustering? (yes/no) [default=no]:
→ no

Do you want to configure a new storage pool? (yes/no) [default=yes]:
→ yes

Name of the new storage pool [default=default]:
→ default (just press Enter)

Name of the storage backend to use (btrfs, dir, lvm, lvmcluster) [default=btrfs]:
→ btrfs
   (Why btrfs? Fast snapshots, copy-on-write, good for containers)

Create a new BTRFS pool? (yes/no) [default=yes]:
→ yes

Would you like to use an existing empty block device (e.g. a disk or partition)? (yes/no) [default=no]:
→ no

Size in GiB of the new loop device (1GiB minimum) [default=30GiB]:
→ 100GiB (or more, adjust to your needs - e.g., 400GiB)

Would you like to create a new local network bridge? (yes/no) [default=yes]:
→ no
   (We'll configure external bridge later for LAN access)

Would you like to use an existing bridge or host interface? (yes/no) [default=no]:
→ no
   (We'll set this up manually in the next section)

Would you like the server to be available over the network? (yes/no) [default=no]:
→ no
   (This is for Incus Remote API - NOT needed for Web UI!)
   (Web UI access is already configured in section 3a on port 8443)

Would you like stale cached images to be updated automatically? (yes/no) [default=yes]:
→ yes

Would you like a YAML "init" preseed to be printed? (yes/no) [default=no]:
→ no
```

**Done!** Incus is now initialized.

---

## 5. Configure External Bridge for Direct LAN Access

**Goal:** Containers get IP addresses directly from your router's DHCP server and are accessible from anywhere in your LAN - no port forwarding needed!

**What we're creating:**
```
Before:                          After:
Router                          Router
  ↓                              ↓
Physical NIC (enp1s0)           Bridge (br0)
  ↓                              ↓ ↓ ↓
Host                            Host + Container1 + Container2
192.168.1.100                   192.168.1.100 / .101 / .102
                                All get IPs from router!
```

---

### Prerequisites

```bash
# Install bridge-utils (if not already installed)
sudo apt install bridge-utils -y

# Find your network interface name
ip addr show

# Look for your main network interface, typically:
# - enp1s0, enp2s0, ens18 (physical NICs)
# - eth0 (virtual machines)
# - NOT 'lo' (loopback)
```

**Take note of your interface name!** Example: `enp1s0`

---

### Step 1: Back up Current Netplan Config

```bash
# Backup current network config
sudo cp /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.backup
```

---

### Step 2: Create Bridge Configuration

**Replace `enp1s0` with YOUR interface name!**

```bash
# Create new netplan config with bridge
sudo tee /etc/netplan/01-netcfg.yaml > /dev/null << 'EOF'
network:
  version: 2
  renderer: networkd
  
  ethernets:
    enp1s0:           # ← REPLACE with YOUR interface!
      dhcp4: false
      dhcp6: false
  
  bridges:
    br0:
      interfaces:
        - enp1s0       # ← REPLACE with YOUR interface!
      dhcp4: true
      dhcp6: false
      parameters:
        stp: false
        forward-delay: 0
EOF

# Disable cloud-init networking (prevents conflicts)
sudo tee /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg > /dev/null << 'EOF'
network: {config: disabled}
EOF
```

**Verify the config:**
```bash
cat /etc/netplan/01-netcfg.yaml
# Make sure your interface name is correct!
```

---

### Step 3: Apply Configuration (SSH will disconnect!)

**⚠️ WARNING: Your SSH connection WILL disconnect here!**

**Important:**
- Your SSH connection **will drop** when you apply the config
- Server gets new IP from DHCP
- Check your router's DHCP leases to find new IP
- Reconnect via new IP

**You have two options:**

**Option A: Test first (safer - auto-reverts after 120 seconds)**
```bash
sudo netplan try
# SSH will disconnect immediately
# If the new network config works:
#   1. Find new IP in your router's DHCP leases
#   2. SSH to new IP within 120 seconds
#   3. Press ENTER to confirm and make it permanent
# If you don't confirm within 120 seconds:
#   - Config auto-reverts to old settings
#   - Reconnect with old IP and fix the config
```

**Option B: Apply directly (if you're confident)**
```bash
sudo netplan apply
# SSH will disconnect immediately
# Find new IP and reconnect
# No auto-revert - config is permanent
```

**Your SSH connection will drop here!**

---

### Step 4: Find New IP and Verify

```bash
# If SSH disconnected: Reconnect
# IP might have changed - check your router!

# After login: Check bridge status
ip addr show br0

# Should show:
# br0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500
#     inet 192.168.1.x/24 brd 192.168.1.255 scope global dynamic br0
```

---

### Step 5: Configure Incus Default Profile to Use br0

```bash
# Add eth0 device to default profile (uses br0)
incus profile device add default eth0 nic nictype=bridged parent=br0

# Verify
incus profile show default

# Should show:
# devices:
#   eth0:
#     nictype: bridged
#     parent: br0
#     type: nic
#   root:
#     path: /
#     pool: default
#     type: disk
```

---

### Step 6: Start Test Container

```bash
# Create test container
incus launch images:ubuntu/24.04 test

# Wait briefly for DHCP (10 seconds)
sleep 10

# Show container IP
incus list test

# Should show:
# | test | RUNNING | 192.168.1.xxx (eth0) | ... | CONTAINER | 0 |
#                   ↑ IP from router DHCP!
```

**Success!** Container got IP directly from router (e.g., `192.168.1.150`)!

---

### Step 7: Test from LAN

```bash
# From another PC in your network:
ping 192.168.1.xxx  # The IP from incus list
```

**Containers are now directly accessible in LAN - no port forwards needed!**

---

### Step 8: Cleanup (Optional)

```bash
# Delete test container
incus delete test --force
```

**Done!** Your containers now use the external bridge and are directly accessible in LAN.

---

### Step 9: Set Default Profile Resource Limits

**Why set limits?**
- Without limits: Containers can slow down entire host
- With limits: Predictable performance and protection from resource hogs

**Recommended default values:**

```bash
# Limit root disk to 25GB
incus profile device set default root size=25GiB

# CPU limit: 4 cores
incus profile set default limits.cpu=4

# Memory limit: 4GB
incus profile set default limits.memory=4GiB

# Security settings for Docker in containers (stays unprivileged!)
incus profile set default security.nesting=true
incus profile set default security.syscalls.intercept.mknod=true
incus profile set default security.syscalls.intercept.setxattr=true

# AppArmor configuration for Docker (important!)
incus profile set default raw.lxc "lxc.apparmor.profile=unconfined
lxc.mount.entry=/dev/null sys/module/apparmor/parameters/enabled none bind 0 0"
```

**What do the security settings do?**
- `security.nesting=true`: Allows Docker/Podman in containers
- `syscalls.intercept.*`: Enables container-in-container without privileged mode
- `raw.lxc`: Disables AppArmor restrictions for Docker compatibility
  - `lxc.apparmor.profile=unconfined`: Sets container to unconfined (needed for Docker)
  - `lxc.mount.entry=...`: Pretends AppArmor is disabled (Docker compatibility)
- **Important:** Containers remain **unprivileged** (secure!)

**Verify:**

```bash
incus profile show default
```

**Expected output:**
```yaml
config:
  limits.cpu: "4"
  limits.memory: 4GiB
  raw.lxc: |-
    lxc.apparmor.profile=unconfined
    lxc.mount.entry=/dev/null sys/module/apparmor/parameters/enabled none bind 0 0
  security.nesting: "true"
  security.syscalls.intercept.mknod: "true"
  security.syscalls.intercept.setxattr: "true"
devices:
  eth0:
    nictype: bridged
    parent: br0
    type: nic
  root:
    path: /
    pool: default
    size: 25GiB
    type: disk
name: default
```

---

---

## 6. Configure GPU Support

### Create GPU Profile

**We create a separate `gpu` profile that includes everything from `default` plus GPU access.**

**⚠️ IMPORTANT: First determine your GPU ID!**

Run this command to see your available GPUs:
```bash
incus info --resources | grep -A 50 "GPUs"
```

Look for your NVIDIA GPU and note its ID number (usually 0 for bare metal, 1 for VMs).

**Create the profile:**

```bash
# Copy default profile to gpu profile
incus profile copy default gpu

# GPU-specific resource settings
incus profile device set gpu root size=75GiB
incus profile set gpu limits.cpu=4
incus profile set gpu limits.memory=16GiB

# Add GPU device
incus profile device add gpu gpu0 gpu id=0  # <-- Replace 0 with YOUR GPU ID!
incus profile set gpu nvidia.runtime=true

# Verify gpu profile
incus profile show gpu
```

**Expected output:**
```yaml
config:
  limits.cpu: "4"
  limits.memory: 16GiB
  nvidia.runtime: "true"    ← CRITICAL! Must be present!
  raw.lxc: |-
    lxc.apparmor.profile=unconfined
    lxc.mount.entry=/dev/null sys/module/apparmor/parameters/enabled none bind 0 0
  security.nesting: "true"
  security.syscalls.intercept.mknod: "true"
  security.syscalls.intercept.setxattr: "true"
devices:
  eth0:
    nictype: bridged
    parent: br0
    type: nic
  gpu0:
    id: "0"     ← Your GPU ID (check with incus info --resources)
    type: gpu
  root:
    path: /
    pool: default
    size: 75GiB
    type: disk
description: Default Incus profile
name: gpu
```

---

### Test GPU Access

```bash
# Start test container with GPU
incus launch images:ubuntu/24.04 gpu-test --profile gpu

# Wait briefly for container to start
sleep 5

# Test GPU in container
incus exec gpu-test -- nvidia-smi
```

**Expected output:**
```
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 570.XX.XX              Driver Version: 570.XX.XX      CUDA Version: 12.X     |
|-------------------------------+----------------------+---------------------------+
| GPU  Name                     | Bus-Id        | GPU-Util  Memory-Usage          |
|===============================|===============|=========|=========================|
|   0  NVIDIA A40               | 0000:00:10.0  |    0%   |      0MiB / 49140MiB    |
+-----------------------------------------------------------------------------------------+
```

**Should display your host GPU!**

**If `nvidia-smi` command not found:**
- Check that `nvidia.runtime=true` is set in the profile
- Verify CDI is generated: `sudo nvidia-ctk cdi list` (on host)
- Restart the container: `incus restart gpu-test`

---

### Cleanup

```bash
# Delete test container
incus delete gpu-test --force
```

**Done!** Your GPU profile is ready to use. Containers launched with `--profile gpu` will have GPU access.

---

## 7. Create Templates

Now we create pre-configured templates for fast container deployment.

We'll create **two templates**:
1. **Base Template** - Without GPU, for normal containers
2. **GPU Template** - With GPU access, for AI/ML workloads

### ℹ️ Important: Create Admin User

**Best Practice:** Create an admin user in each template and avoid running everything as `root`!

**Standard username in this guide:** `user`  
**⚠️ Recommendation:** Choose your own username and secure password!

**Why a separate user?**
- ✅ Better security (don't work as root)
- ✅ Clean separation of system and user files
- ✅ Prevents accidental system changes
- ✅ Standard in production environments

The user is automatically added to the `sudo` group and has admin rights in the container.

**SSH Security:**
- ✅ Root login via SSH is disabled (`PermitRootLogin no`)
- ✅ User login with password stays active (`PasswordAuthentication yes`)
- ℹ️ For higher security you can switch to SSH keys later

---

### Template 1: Base Template (without GPU)

#### Create and Prepare Container

```bash
# Start base container
incus launch images:ubuntu/24.04 base-template

# Enter container
incus exec base-template -- bash
```

#### In Container: Prepare System

```bash
# Update system
apt update && apt upgrade -y

# Install basic tools
apt install -y \
  curl \
  wget \
  git \
  nano \
  htop \
  btop \
  nmon \
  tree \
  jq \
  ca-certificates \
  software-properties-common \
  build-essential

# Install SSH server (for remote access)
apt install -y openssh-server

# Create admin user (don't run everything as root!)
# Note: Replace "user" with your desired username
adduser user

# Add user to sudo group (admin rights)
usermod -aG sudo user

# Optional: Enable passwordless sudo commands (for better automation)
# echo "user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/user
# chmod 440 /etc/sudoers.d/user

# Configure SSH (security)
# Disable root login, allow user login with password
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Restart SSH
systemctl restart ssh

# Exit container
exit
```

#### Optional: Prepare Docker Script (don't install)

**Universal script for Docker installation (works with and without GPU):**

```bash
# Download Docker installation script to /home/user/
curl -fsSL https://raw.githubusercontent.com/Aeraxon/everspire/main/docker/installation/docker-install.sh \
  -o /home/user/docker-install.sh

# Make executable
chmod +x /home/user/docker-install.sh

# Set owner to user
chown user:user /home/user/docker-install.sh
```

#### Publish Template

**ℹ️ Important:** `incus publish` creates a **local** image only on this server - nothing is uploaded to the internet!

**In container - Overview of prepared scripts:**
```bash
# Available scripts in /home/user/
ls -la /home/user/
# - docker-install.sh    → Install Docker

# Exit container
exit
```

**On host - Publish template:**
```bash
# Stop container
incus stop base-template

# Publish as local image (stays only on this server!)
incus publish base-template --alias ubuntu-2404-base \
  description="Ubuntu 24.04 Base Template - Standard LXC without GPU"

# Optional: Delete template container
incus delete base-template

# Check local templates
incus image list
```

---

### Template 2: GPU Template (with GPU)

#### Create and Prepare Container

```bash
# Start GPU container (uses GPU profile!)
incus launch images:ubuntu/24.04 gpu-template --profile gpu

# Enter container
incus exec gpu-template -- bash
```

#### In Container: Prepare System

```bash
# Update system
apt update && apt upgrade -y

# Install basic tools
apt install -y \
  curl \
  wget \
  git \
  nano \
  htop \
  btop \
  nmon \
  nvtop \
  tree \
  jq \
  ca-certificates \
  software-properties-common \
  build-essential

# Install SSH server (for remote access)
apt install -y openssh-server

# GPU test - nvidia-smi is already available from host!
nvidia-smi

# Create admin user (don't run everything as root!)
# Note: Replace "user" with your desired username
adduser user

# Add user to sudo group (admin rights)
usermod -aG sudo user

# Optional: Enable passwordless sudo commands (for better automation)
# echo "user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/user
# chmod 440 /etc/sudoers.d/user

# Configure SSH (security)
# Disable root login, allow user login with password
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Restart SSH
systemctl restart ssh
```

#### Optional: Prepare Docker Script (don't install)

**Universal script for Docker installation (works with and without GPU):**

```bash
# Download Docker installation script to /home/user/
curl -fsSL https://raw.githubusercontent.com/Aeraxon/everspire/main/docker/installation/docker-install.sh \
  -o /home/user/docker-install.sh

# Make executable
chmod +x /home/user/docker-install.sh

# Set owner to user
chown user:user /home/user/docker-install.sh
```

#### Optional: Prepare Python Installer Script (don't install)

```bash
# Download Python installer script
curl -fsSL https://raw.githubusercontent.com/Aeraxon/everspire/main/linux/python/python-install.sh \
  -o /home/user/python-install.sh

# Make executable
chmod +x /home/user/python-install.sh

# Set owner to user
chown user:user /home/user/python-install.sh
```

#### Optional: Prepare CUDA Setup Script (don't install)

```bash
# Download CUDA bashrc helper script
curl -fsSL https://raw.githubusercontent.com/Aeraxon/everspire/main/linux/cuda-bashrc-setup.sh \
  -o /home/user/cuda-bashrc-setup.sh

# Make executable
chmod +x /home/user/cuda-bashrc-setup.sh

# Set owner to user
chown user:user /home/user/cuda-bashrc-setup.sh
```

#### Exit Container and Publish Template

**ℹ️ Important:** `incus publish` creates a **local** image only on this server - nothing is uploaded to the internet!

**In container - Overview of prepared scripts:**
```bash
# Available scripts in /home/user/
ls -la /home/user/
# - docker-install.sh        → Install Docker (with or without GPU)
# - python-install.sh        → Install Python version
# - cuda-bashrc-setup.sh     → Configure CUDA paths

# Exit container
exit
```

**On host - Publish template:**
```bash
# Stop container
incus stop gpu-template

# Publish as local image (stays only on this server!)
incus publish gpu-template --alias ubuntu-2404-gpu \
  description="Ubuntu 24.04 GPU Template - LXC with GPU support"

# Optional: Delete template container
incus delete gpu-template

# Check local templates
incus image list
```

**⚠️ Important:** If you want to run **Docker containers with GPU** inside your Incus containers, see the [Docker with GPU Support](#docker-with-gpu-support-in-containers) section for additional configuration!

---

## 8. Container Deployment Workflow

### Use Templates (CLI)

**Normal container (without GPU):**
```bash
incus launch ubuntu-2404-base webserver
incus launch ubuntu-2404-base database
incus launch ubuntu-2404-base api-backend
```

**GPU containers:**
```bash
incus launch ubuntu-2404-gpu ollama --profile gpu
incus launch ubuntu-2404-gpu stable-diffusion --profile gpu
incus launch ubuntu-2404-gpu whisper --profile gpu
```

**Check IPs:**
```bash
incus list

# All containers have 192.168.1.x IPs from router!
```

---

### Use Templates via Web UI

**Access:** `https://<server-ip>:8443`

**Create container from template:**

1. **Instances** → **Create instance**
2. **Use image from local server**
3. **Select image:** `ubuntu-2404-base` or `ubuntu-2404-gpu`
4. **Instance name:** e.g., `ollama`
5. **Profiles:** 
   - Base Template: `default` (standard)
   - GPU Template: select `gpu` ✓
6. Click **Create**

**Done!** Container starts automatically with:
- ✅ DHCP IP from router
- ✅ Pre-installed scripts in `/home/user/`
- ✅ SSH access as `user` possible
- ✅ GPU access (for GPU template)

**Container management via UI:**
- **Start/Stop:** Click on container → Power button
- **Console:** Terminal icon → Direct access to container
- **Details:** All info (IP, CPU, RAM, GPU)

---

### Use Pre-installed Scripts

**All containers from templates already have installation scripts in `/home/user/`!**

#### Base Template Container

```bash
# SSH into container
ssh user@<container-ip>

# Show available scripts
ls -la /home/user/

# Install Docker (without GPU)
sudo /home/user/docker-install.sh
# The script asks interactively:
# - Install GPU support? (y/n) → enter n
# - Install Portainer? (0/1/2) → Choose as needed
```

#### GPU Template Container

```bash
# SSH into container
ssh user@<container-ip>

# Show available scripts
ls -la /home/user/

# 1. Install Docker with GPU support
sudo /home/user/docker-install.sh
# The script asks interactively:
# - Install GPU support? (y/n) → enter y
# - Install Portainer? (0/1/2) → Choose as needed

# 2. Install Python version
sudo /home/user/python-install.sh
# The script asks interactively:
# - Which Python version? (1-6) → Choose desired version
# Available versions: 3.8, 3.9, 3.10, 3.11, 3.12, 3.13
# System Python (python3) stays unchanged!
```

#### CUDA Toolkit (Optional)

**Step 1: Download and install CUDA Toolkit**

Visit the NVIDIA CUDA Toolkit Archive page:

```
https://developer.nvidia.com/cuda-toolkit-archive
```

There:
- Select your desired CUDA version (e.g., CUDA 12.1)
- Select: **Operating System:** Linux
- Select: **Architecture:** x86_64  
- Select: **Distribution:** Ubuntu
- Select: **Version:** 24.04
- Select: **Installer Type:** runfile (local)

Follow the installation instructions on the NVIDIA page.

**⚠️ IMPORTANT during installer:**
- **DESELECT "Driver"** - Driver comes from host, don't install!
- **SELECT "CUDA Toolkit"** - Only install toolkit

**Step 2: Add CUDA paths to bashrc (optional)**

After successful installation you can use the pre-installed helper script:

```bash
./cuda-bashrc-setup.sh
```

The script:
- Asks interactively for installed CUDA version
- Automatically adds PATH and LD_LIBRARY_PATH to `~/.bashrc`
- Activate with: `source ~/.bashrc`
- Test with: `nvcc --version`

**⚠️ Note:** 
- Scripts are ready but NOT automatically executed
- You decide when and if to use them
- All scripts are interactive and ask for your preferences

**🐳 Important for Docker:**
- Containers from templates (following this guide) are already pre-configured for Docker
- If Docker still throws errors (e.g., `permission denied`), restart container:
  ```bash
  # On the host
  incus restart containername
  ```
- If you created containers BEFORE AppArmor configuration:
  ```bash
  # On the host - for existing containers
  incus config set containername raw.lxc "lxc.apparmor.profile=unconfined
  lxc.mount.entry=/dev/null sys/module/apparmor/parameters/enabled none bind 0 0"
  incus restart containername
  ```

---

### Advanced Container Configuration

**Container with specific resource limits:**

```bash
# GPU container with more RAM (instead of standard 16GiB)
incus launch ubuntu-2404-gpu big-ai \
  --profile gpu \
  --config limits.memory=32GiB

# GPU container with more CPUs
incus launch ubuntu-2404-gpu multi-core \
  --profile gpu \
  --config limits.cpu=8

# With larger root disk
incus launch ubuntu-2404-gpu big-storage \
  --profile gpu \
  --config limits.disk=100GiB

# Normal container (without GPU) with custom limits
incus launch ubuntu-2404-base database \
  --config limits.cpu=2 \
  --config limits.memory=2GiB
```

### Template Updates

```bash
# Update GPU template
incus launch ubuntu-2404-gpu gpu-template-v2 --profile gpu

incus exec gpu-template-v2 -- bash
# ... Perform updates ...
exit

incus stop gpu-template-v2

# Publish new image (with version/date)
incus publish gpu-template-v2 \
  --alias ubuntu-2404-gpu-v2 \
  description="Updated GPU template $(date +%Y-%m-%d)"

# Optionally delete old image
incus image delete ubuntu-2404-gpu

# Rename alias (v2 becomes new standard)
incus image alias rename ubuntu-2404-gpu-v2 ubuntu-2404-gpu
```

### Copy-on-Write Clones (Snapshots)

```bash
# Fast snapshots for experiments
incus snapshot ollama clean-state

# ... Experiment ...

# Return to snapshot
incus restore ollama clean-state

# Delete snapshot
incus delete ollama/clean-state
```

---

## Docker with GPU Support in Containers

**Important for AI workloads:** If you want to run Docker containers **inside** your Incus containers with GPU access, additional configuration is required.

### Why Special Configuration?

Incus containers are **unprivileged** by default (for security). Unprivileged containers cannot modify cgroups, which Docker's default GPU passthrough tries to do. This causes errors like:

```
nvidia-container-cli: mount error: bpf_prog_query(BPF_CGROUP_DEVICE) failed: operation not permitted
```

### Solution: Use the Docker Installation Script

The GPU template includes a `docker-install.sh` script that handles everything automatically.

**Inside your GPU container:**

```bash
# Run the Docker installation script
./docker-install.sh

# When prompted:
# - Install GPU support? → y
# - Running in unprivileged LXC container? → y  (IMPORTANT!)
# - Install Portainer? → 0, 1, or 2 (your choice)
```

**The script automatically:**
- ✅ Installs Docker and NVIDIA Container Toolkit
- ✅ Sets `no-cgroups=true` for unprivileged containers
- ✅ Configures Docker for CDI mode
- ✅ Restarts Docker with correct settings

After installation, **reboot the container** or run `newgrp docker`.

---

### Docker Compose Syntax for GPU Access

**Use `runtime: nvidia` syntax instead of `deploy.resources`:**

```yaml
services:
  my-gpu-app:
    image: my-image
    runtime: nvidia  # <-- Use this!
    environment:
      - NVIDIA_VISIBLE_DEVICES=0  # GPU ID (always 0 in container)
    # ... rest of config
```

**Don't use (causes legacy mode errors):**
```yaml
deploy:
  resources:
    reservations:
      devices:
        - driver: nvidia  # <-- Don't use this in unprivileged containers!
```

---

### Test GPU Access

```bash
# Test GPU access in Docker
docker run --rm --runtime=nvidia nvidia/cuda:12.6.0-base-ubuntu22.04 nvidia-smi
```

**Expected:** You should see your GPU information.

---

### Manual Configuration (if needed)

If you installed Docker manually without the script, you need to configure it:

```bash
# Install NVIDIA Container Toolkit
sudo apt update
sudo apt install -y nvidia-container-toolkit

# Set no-cgroups mode (critical for unprivileged containers!)
sudo nvidia-ctk config --set nvidia-container-cli.no-cgroups=true --in-place

# Configure Docker for CDI
sudo nvidia-ctk runtime configure --runtime=docker --config=/etc/docker/daemon.json --set-as-default

# Restart Docker
sudo systemctl restart docker
```

---

### Common Issues

**Error: "operation not permitted"**
- Cause: `no-cgroups=true` not set
- Solution: Run `./docker-install.sh` again and answer "y" to LXC container question

**Error: "stat failed: /proc/driver/nvidia/gpus"**
- Cause: Using `deploy.resources` in docker-compose.yml
- Solution: Use `runtime: nvidia` instead

**GPU not visible in Docker container**
- Check: `nvidia-smi` works in the Incus container (outside Docker)
- Check: Docker was installed with GPU support enabled
- Restart: Container or run `sudo systemctl restart docker`

---

### Summary

For Docker-in-Incus with GPU:
1. ✅ Use `./docker-install.sh` script from GPU template
2. ✅ Answer "y" to both GPU support AND LXC container questions
3. ✅ Use `runtime: nvidia` in docker-compose.yml (not `deploy.resources`)
4. ✅ Set `NVIDIA_VISIBLE_DEVICES=0` in environment
5. ✅ Reboot container after installation

This configuration allows Docker containers to access the GPU while keeping Incus containers unprivileged and secure.

---

## Useful Commands - Cheat Sheet

```bash
# === Web UI ===
incus config set core.https_address :8443     # Enable Web UI
incus config trust add                        # Add certificate
incus config trust list                       # Trusted certificates
# Browser: https://<server-ip>:8443

# === Images & Templates ===
incus image list                          # Local images
incus image list images:                  # Remote images (ubuntu, debian, etc.)
incus publish container --alias name      # Container to image
incus image delete name                   # Delete image

# === Container Management ===
incus launch image-name container-name    # New container
incus start/stop/restart container-name   # Lifecycle
incus list                                # All containers
incus exec container-name -- bash         # Shell in container
incus delete container-name               # Delete container
incus delete container-name --force       # Delete running container

# === GPU ===
incus info --resources                    # GPU hardware info
incus config device add c1 gpu0 gpu       # Add GPU to container
incus exec container-name -- nvidia-smi   # GPU status in container

# === Networking ===
incus network list                        # Networks
incus network show br0                    # Bridge details
incus list --columns ns4                  # Containers with IPs

# === Snapshots ===
incus snapshot c1 snap1                   # Create snapshot
incus restore c1 snap1                    # Restore snapshot
incus info c1                             # Show snapshots

# === Profiles ===
incus profile list                        # All profiles
incus profile show default                # Profile details
incus profile edit profilename            # Edit profile

# === Storage ===
incus storage list                        # Storage pools
incus storage info default                # Pool details

# === Copy Files ===
incus file push /local/file c1/remote/    # Host → Container
incus file pull c1/remote/file /local/    # Container → Host
```

---

## Best Practices

### Security

* ✅ Use unprivileged containers (default in Incus)
* ✅ Keep host & containers updated
* ✅ Use `security.nesting=true` only when Docker is needed
* ⚠️ `lxc.apparmor.profile=unconfined` only for Docker host containers

### Performance

* ✅ BTRFS as storage backend for snapshots & clone performance
* ✅ NVMe SSDs for container storage
* ✅ GPU-intensive apps should release VRAM after use

### Workflow

* ✅ Create versioned templates (`ubuntu-2404-gpu-v1`, `-v2`, etc.)
* ✅ Use snapshots before major changes
* ✅ Document template contents in `description` field

---

## Further Links

* **Incus Documentation:** https://linuxcontainers.org/incus/docs/main/
* **Incus GitHub:** https://github.com/lxc/incus
* **NVIDIA Container Toolkit:** https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/
* **Community Forum:** https://discuss.linuxcontainers.org/
* **Zabbly Support:** https://zabbly.com/incus

---

**Good luck with your Incus GPU setup! 🚀**
