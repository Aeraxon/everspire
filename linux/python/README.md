# Python

Python environment management tools and setup guides.

## Contents

### python-install.sh
Automated Python version installer for Ubuntu 24.04 using deadsnakes PPA.

Installs specific Python versions (3.8-3.13) with venv and dev packages via interactive menu.

```bash
./python-install.sh
```

### [venv-setup.md](venv-setup.md)
Installation and activation of Python Virtual Environments for different Python versions (3.9, 3.10, 3.11, 3.12, etc.).

Pattern:
```bash
sudo apt install python3.XX python3.XX-venv python3.XX-dev build-essential
python3.XX -m venv venv
source venv/bin/activate
```

### [conda/](conda/)
Miniconda installation and conda environment management for various shells.
