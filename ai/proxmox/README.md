# Proxmox

GPU-accelerated AI infrastructure on Proxmox VE.

## Complete Setup Guide

*(Coming soon)* End-to-end guide for deploying GPU-accelerated AI workloads on Proxmox, similar to the [Incus guide](../incus/).

**Will include:**
- LXC containers with GPU support for AI workloads
- VM-based GPU deployments
- Docker-in-LXC with GPU support
- Template-based workflow
- Cluster configuration

---

## GPU Configuration Guides

### kernel-pinning.md
Pin kernel version to prevent automatic kernel updates that might break GPU drivers.

```bash
proxmox-boot-tool kernel list
proxmox-boot-tool kernel pin <kernel-version>
```

**Why:** NVIDIA drivers are compiled for specific kernel versions. Kernel updates can cause driver issues.

### gpu-driver-blacklist.md
Blacklist GPU drivers on host for GPU passthrough to VMs.

```bash
echo "blacklist nouveau" >> /etc/modprobe.d/blacklist.conf
echo "blacklist nvidia" >> /etc/modprobe.d/blacklist.conf
update-initramfs -u -k all
reboot
```

**Use case:** When GPU is passed through to VM, host must not load drivers.

### pcie-passthrough-setup.md
Complete PCIe/GPU passthrough setup for VMs.

**Steps:**
1. Enable IOMMU (Legacy/EFI, Intel/AMD)
2. Load VFIO modules
3. Blacklist GPU drivers on host
4. Configure device IDs
5. Assign to VM

**Perfect for:** Windows VMs with GPU, gaming VMs, dedicated AI VMs.

### nvidia-gpu-in-lxc.md
Enable NVIDIA GPU in unprivileged LXC containers with shared host kernel.

**Steps:**
1. Update Proxmox + pin kernel
2. Install PVE headers + NVIDIA driver on host (with --dkms)
3. Identify device numbers
4. Adjust container config (cgroup2.devices.allow + mount.entry)
5. Install driver in container (with --no-kernel-module)

**Advantage:** GPU can be used by multiple containers simultaneously.

### nvidia-gpu-lxc-init.md
Auto-initialize NVIDIA GPU on boot for LXC containers.

**Problem:** Containers can't see GPU after reboot until `nvidia-smi` runs on host.

**Solution:** Systemd service that initializes GPU on boot.

```bash
systemctl enable nvidia-init.service
```

---

## Related Documentation

For general Proxmox guides (monitoring, backup, etc.), see [../../virtualization/proxmox/](../../virtualization/proxmox/).
