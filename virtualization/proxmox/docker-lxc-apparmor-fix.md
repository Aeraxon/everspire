# Docker in Proxmox LXC - AppArmor Fix

## The Problem

Docker fails in unprivileged Proxmox LXC containers with:

```
permission denied: open sysctl net.ipv4.ip_unprivileged_port_start file
```

**Root cause**: containerd.io 1.7.28+ conflicts with AppArmor in nested containers.

---

## Quick Fix (Existing Container)

```bash
# On Proxmox host
pct stop 100

nano /etc/pve/lxc/100.conf
```

**Add these two lines at the end:**

```
lxc.apparmor.profile: unconfined
lxc.mount.entry: /dev/null sys/module/apparmor/parameters/enabled none bind 0 0
```

```bash
pct start 100
pct enter 100

# Test
docker run hello-world  # Should work now
```

**That's it.**

---

## For New Containers

**Option 1 - Web UI + Manual Config:**

1. Create container via Web UI with **Nesting enabled** (don't start yet)
2. Edit config: `nano /etc/pve/lxc/100.conf`
3. Add the two AppArmor lines above
4. Start container: `pct start 100`

**Option 2 - CLI:**

```bash
# Create container
pct create 100 local:vztmpl/ubuntu-24.04-standard_24.04-1_amd64.tar.zst \
  --hostname docker-host \
  --memory 4096 \
  --cores 2 \
  --rootfs local-lvm:25 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp \
  --features nesting=1 \
  --unprivileged 1

# Add AppArmor fix
cat >> /etc/pve/lxc/100.conf <<EOF
lxc.apparmor.profile: unconfined
lxc.mount.entry: /dev/null sys/module/apparmor/parameters/enabled none bind 0 0
EOF

# Start
pct start 100
```

---

## What This Does

| Config Line | Purpose |
|-------------|---------|
| `lxc.apparmor.profile: unconfined` | Relaxes AppArmor restrictions for this container |
| `lxc.mount.entry: /dev/null...` | Makes Docker think AppArmor is disabled |

**Important:**
- Container remains **unprivileged** (secure!)
- Only affects AppArmor for **this specific container**
- Host and other containers stay protected

---

## Security Note

**Trade-off:**
- ✅ Unprivileged container = Base isolation intact
- ⚠️ Relaxed AppArmor = Less additional isolation layer
- 🎯 Acceptable for dedicated Docker host containers
- ❌ Avoid for containers with direct internet exposure

**Best Practice:** Use dedicated containers for Docker, keep them updated, run critical services in separate containers without this fix.

---

## Quick Reference

```bash
# View container config
cat /etc/pve/lxc/100.conf

# Edit config
nano /etc/pve/lxc/100.conf

# List all containers
pct list

# Stop/Start
pct stop 100
pct start 100
```
