# Proxmox Persistent Network Interface Names

## The Problem

Network interface names change randomly after:
- Adding/removing GPUs or PCIe cards
- Kernel updates
- Sometimes even just rebooting

Your interface jumps between `enp4s0`, `enp5s0`, `eno1`, etc. and Proxmox loses network connectivity.

**Root cause**: "Predictable" interface names are based on PCI slot positions, which shift when hardware changes.

---

## Quick Fix

### 1. Find Your MAC Address

```bash
ip link show
```

Look for your network interface (the one with `state UP` or connected to your bridge):

```
2: enp5s0: <BROADCAST,MULTICAST,UP,LOWER_UP> ...
    link/ether 52:54:00:12:34:56 brd ff:ff:ff:ff:ff:ff
```

Note the MAC: `52:54:00:12:34:56`

### 2. Create systemd .link File

```bash
nano /etc/systemd/network/10-eth0.link
```

**Content:**

```ini
[Match]
MACAddress=52:54:00:12:34:56

[Link]
Name=eth0
```

Replace the MAC address with yours.

### 3. Update Network Config

```bash
nano /etc/network/interfaces
```

Change your interface name to `eth0`:

```
iface eth0 inet manual

auto vmbr0
iface vmbr0 inet static
        address 192.168.1.100/24
        gateway 192.168.1.1
        bridge-ports eth0
        bridge-stp off
        bridge-fd 0
```

### 4. Apply and Reboot

```bash
update-initramfs -u
reboot
```

**That's it.** Your interface will now always be `eth0`.

---

## Emergency Recovery

Lost network after reboot? Connect via console (keyboard/monitor or IPMI):

```bash
# Check current interface name
ip link show | grep enp

# Temporarily fix network (replace enp5s0 with actual name)
ip link set enp5s0 master vmbr0
ip link set enp5s0 up
```

Now you have network access to fix the config properly.

---

## What This Does

| Component | Purpose |
|-----------|---------|
| `/etc/systemd/network/10-eth0.link` | Tells systemd to name the interface by MAC address |
| `10-` prefix | Ensures it runs before `99-default.link` |
| `update-initramfs -u` | Bakes the config into early boot |

**Why systemd .link instead of udev rules?**

Modern Debian/Proxmox (8.x+) uses systemd-networkd for interface naming. The old `/etc/udev/rules.d/70-persistent-net.rules` method is deprecated and often ignored.

---

## Multiple Interfaces

For multiple NICs, create separate .link files:

```bash
# First NIC
cat > /etc/systemd/network/10-eth0.link <<EOF
[Match]
MACAddress=52:54:00:12:34:56

[Link]
Name=eth0
EOF

# Second NIC
cat > /etc/systemd/network/11-eth1.link <<EOF
[Match]
MACAddress=52:54:00:ab:cd:ef

[Link]
Name=eth1
EOF

update-initramfs -u
```

---

## Verify Setup

After reboot:

```bash
# Check interface name
ip link show

# Should show eth0 instead of enp*s*
# 2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> ...

# Verify which .link file is applied
udevadm info /sys/class/net/eth0 | grep LINK_FILE
# ID_NET_LINK_FILE=/etc/systemd/network/10-eth0.link
```

---

## Quick Reference

```bash
# Find MAC addresses
ip link show

# List systemd network configs
ls -la /etc/systemd/network/

# Check default naming policy
cat /usr/lib/systemd/network/99-default.link

# Test .link file without reboot
udevadm test-builtin net_setup_link /sys/class/net/eth0

# Rebuild initramfs
update-initramfs -u

# View current network config
cat /etc/network/interfaces
```

---

## Tested On

- Proxmox VE 8.x / 9.x
- Debian 12 (Bookworm)
- Kernel 6.x

Works with any hardware that changes PCI topology (GPU swaps, NVMe additions, etc.).
