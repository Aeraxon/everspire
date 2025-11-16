# Linux

Linux System-Setup, Tools und Konfigurationen.

## Anleitungen

### [python/](python/)
Python environment management (venv, conda/miniconda) and setup guides.

### git-setup-guide.md
Git-Konfiguration und Repository-Setup für GitHub und GitLab.

Inhalt:
- Git initial konfigurieren (user, email, default branch)
- SSL-Zertifikate für Self-Hosted GitLab
- Repository initialisieren und pushen
- Access Tokens erstellen
- SSH-Setup (optional)

### cuda-bashrc-setup.sh
Automated CUDA Toolkit bashrc configuration helper.

Interaktive Auswahl der CUDA-Version (11.8-12.8), erstellt Backup und fügt CUDA Pfade automatisch zur `~/.bashrc` hinzu. Optional: Symlink `/usr/local/cuda` erstellen.

```bash
./cuda-bashrc-setup.sh
```

Siehe auch: **cuda-bashrc-setup.md** für manuelle Konfiguration.

Pattern:
```bash
export PATH=/usr/local/cuda-X.Y/bin${PATH:+:${PATH}}
export LD_LIBRARY_PATH=/usr/local/cuda-X.Y/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
```

### ubuntu-filesystem-resize.md
Ubuntu Filesystem auf volle Festplattengröße erweitern (LVM und Non-LVM).

Typisch nach VM-Installation wenn nur 100GB genutzt werden trotz größerer virtueller Disk.

```bash
sudo lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
sudo resize2fs /dev/ubuntu-vg/ubuntu-lv
```

### scp-file-transfer.md
Sichere Dateiübertragung zwischen Systemen via SSH.

```bash
# Datei
scp /pfad/datei.txt username@host:/ziel/

# Ordner
scp -r /pfad/ordner username@host:/ziel/

# Mit Optionen (Port, Key, Kompression)
scp -rP 2222 -i ~/.ssh/key -C /ordner username@host:/ziel/
```
