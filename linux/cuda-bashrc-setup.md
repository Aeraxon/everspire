# CUDA Bashrc Konfiguration

## Pattern für ~/.bashrc

Ersetze `X.Y` mit deiner CUDA-Version (z.B. 12.1, 12.4, 11.8):

```bash
# CUDA X.Y
export PATH=/usr/local/cuda-X.Y/bin${PATH:+:${PATH}}
export LD_LIBRARY_PATH=/usr/local/cuda-X.Y/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
```

Die Syntax `${PATH:+:${PATH}}` fügt nur einen Doppelpunkt und den existierenden PATH hinzu, wenn PATH bereits gesetzt ist.

## Beispiele

### CUDA 12.1
```bash
export PATH=/usr/local/cuda-12.1/bin${PATH:+:${PATH}}
export LD_LIBRARY_PATH=/usr/local/cuda-12.1/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
```

### CUDA 11.8
```bash
export PATH=/usr/local/cuda-11.8/bin${PATH:+:${PATH}}
export LD_LIBRARY_PATH=/usr/local/cuda-11.8/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
```

## Installation

```bash
# 1. Bashrc öffnen
nano ~/.bashrc

# 2. Zeilen am Ende einfügen
# Speichern: Ctrl+O → Enter → Ctrl+X

# 3. Neu laden
source ~/.bashrc

# 4. Prüfen
nvcc --version
```

Erwartete Ausgabe:
```
nvcc: NVIDIA (R) Cuda compiler driver
Cuda compilation tools, release X.Y, VX.Y.XXX
```

## CUDA-Treiber

CUDA-Toolkit ≠ NVIDIA-Treiber! Ohne passenden Treiber funktioniert CUDA nicht.

### Treiber-Version prüfen
```bash
nvidia-smi
```

Zeigt oben rechts die Treiber-Version und unterstützte CUDA-Version an.

### Treiber nachinstallieren (falls nötig)
```bash
sudo ./cuda_X.Y.Z_linux.run --silent --driver
```

## Alternative: System-weite Library-Konfiguration

Statt `LD_LIBRARY_PATH` in bashrc (nur für deinen User):

```bash
# System-weit für alle User
sudo sh -c 'echo "/usr/local/cuda-X.Y/lib64" > /etc/ld.so.conf.d/cuda-X-Y.conf'
sudo ldconfig
```

PATH muss trotzdem in bashrc gesetzt werden.

## Mehrere CUDA-Versionen parallel

Falls mehrere Versionen installiert sind, nutze Symlink:

```bash
# /usr/local/cuda zeigt standardmäßig auf neueste Version
export PATH=/usr/local/cuda/bin${PATH:+:${PATH}}
export LD_LIBRARY_PATH=/usr/local/cuda/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

# Oder manuell umstellen
sudo rm /usr/local/cuda
sudo ln -s /usr/local/cuda-12.1 /usr/local/cuda
```
