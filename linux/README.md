# Linux

Linux System-Setup, Tools und Konfigurationen.

## Anleitungen

### python-venv-setup.md
Installation und Aktivierung von Python Virtual Environments für verschiedene Python-Versionen (3.9, 3.10, 3.11, 3.12, etc.).

Pattern:
```bash
sudo apt install python3.XX python3.XX-venv python3.XX-dev build-essential
python3.XX -m venv venv
source venv/bin/activate
```

### git-setup-guide.md
Git-Konfiguration und Repository-Setup für GitHub und GitLab.

Inhalt:
- Git initial konfigurieren (user, email, default branch)
- SSL-Zertifikate für Self-Hosted GitLab
- Repository initialisieren und pushen
- Access Tokens erstellen
- SSH-Setup (optional)

### cuda-bashrc-setup.md
CUDA Toolkit PATH und LD_LIBRARY_PATH Konfiguration für verschiedene CUDA-Versionen.

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
