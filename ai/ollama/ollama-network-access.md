# Ollama Netzwerk-Zugriff konfigurieren

Ollama hört standardmäßig nur auf localhost. Für Netzwerk-Zugriff muss `OLLAMA_HOST` konfiguriert werden.

## Problem

- Ollama nach Installation: Nur über `localhost:11434` erreichbar
- Von anderen Maschinen/Containern nicht erreichbar
- Nach Ollama-Update wird Konfiguration überschrieben

## Lösung: OLLAMA_HOST konfigurieren

### Methode 1: Systemd Service (empfohlen)

**Persistent, überdauert Neustart:**

```bash
# Service-Datei editieren
sudo nano /etc/systemd/system/ollama.service
```

In der `[Service]` Sektion hinzufügen:
```ini
[Service]
Environment="OLLAMA_HOST=0.0.0.0"
```

Vollständiges Beispiel:
```ini
[Unit]
Description=Ollama Service
After=network.target

[Service]
Type=simple
User=ollama
Group=ollama
ExecStart=/usr/local/bin/ollama serve
Environment="OLLAMA_HOST=0.0.0.0"
Restart=always

[Install]
WantedBy=multi-user.target
```

```bash
# Änderungen übernehmen
sudo systemctl daemon-reload

# Service neustarten
sudo systemctl restart ollama

# Status prüfen
sudo systemctl status ollama
```

### Methode 2: Environment File (Update-sicher)

**Besser als direkte Service-Bearbeitung, da updates den Service überschreiben:**

```bash
# Systemd Override erstellen
sudo systemctl edit ollama
```

Editor öffnet sich. Einfügen:
```ini
[Service]
Environment="OLLAMA_HOST=0.0.0.0"
```

Speichern und schließen (Ctrl+O, Enter, Ctrl+X in nano).

```bash
# Service neustarten
sudo systemctl restart ollama
```

**Vorteil:** Override-Datei liegt in `/etc/systemd/system/ollama.service.d/override.conf` und wird bei Updates nicht überschrieben.

### Methode 3: Command Line (temporär)

**Nur für Testing, nicht persistent:**

```bash
# Ollama Service stoppen
sudo systemctl stop ollama

# Manuell mit Network Binding starten
OLLAMA_HOST=0.0.0.0 ollama serve
```

Läuft nur bis Beenden (Ctrl+C) oder Reboot.

### Methode 4: Docker Compose

Für Ollama in Docker Container:

```yaml
services:
  ollama:
    image: ollama/ollama:latest
    ports:
      - "11434:11434"
    environment:
      - OLLAMA_HOST=0.0.0.0
    extra_hosts:
      - "host.docker.internal:host-gateway"
    volumes:
      - ollama-data:/root/.ollama
    restart: unless-stopped

volumes:
  ollama-data:
```

## Zugriff testen

### Von Host

```bash
# Localhost
curl http://localhost:11434/api/version

# Netzwerk-Interface
curl http://$(hostname -I | awk '{print $1}'):11434/api/version
```

### Von anderem Computer

```bash
curl http://<server-ip>:11434/api/version
```

Sollte Ollama-Version zurückgeben:
```json
{"version":"0.1.32"}
```

### Aus Docker Container

```bash
curl http://host.docker.internal:11434/api/version
```

## Spezifische IP statt 0.0.0.0

Falls nur bestimmtes Interface:

```ini
[Service]
Environment="OLLAMA_HOST=192.168.1.100:11434"
```

Oder nur localhost + custom Port:
```ini
[Service]
Environment="OLLAMA_HOST=127.0.0.1:8080"
```

## Nach Ollama Update

### Wenn systemd edit verwendet (empfohlen)

Override bleibt erhalten, nichts zu tun.

### Wenn Service-Datei direkt editiert

```bash
# Prüfen ob Environment-Variable noch da ist
grep OLLAMA_HOST /etc/systemd/system/ollama.service

# Falls fehlt, erneut hinzufügen (siehe Methode 1)
sudo nano /etc/systemd/system/ollama.service
sudo systemctl daemon-reload
sudo systemctl restart ollama
```

### Besser: Auf Override umstellen

```bash
# Alte Änderung aus Service entfernen
sudo nano /etc/systemd/system/ollama.service
# Environment="OLLAMA_HOST=0.0.0.0" löschen

# Override erstellen
sudo systemctl edit ollama
# Environment="OLLAMA_HOST=0.0.0.0" hinzufügen

# Neustarten
sudo systemctl daemon-reload
sudo systemctl restart ollama
```

## Firewall konfigurieren

Falls Ollama nicht erreichbar:

### UFW (Ubuntu)

```bash
# Port öffnen
sudo ufw allow 11434/tcp

# Status prüfen
sudo ufw status
```

### firewalld (RHEL/CentOS)

```bash
sudo firewall-cmd --permanent --add-port=11434/tcp
sudo firewall-cmd --reload
```

### iptables

```bash
sudo iptables -A INPUT -p tcp --dport 11434 -j ACCEPT
sudo iptables-save > /etc/iptables/rules.v4
```

## Reverse Proxy (optional)

Für HTTPS und Domain-Namen:

### Nginx

```nginx
server {
    listen 443 ssl;
    server_name ollama.example.com;

    ssl_certificate /etc/ssl/certs/ollama.crt;
    ssl_certificate_key /etc/ssl/private/ollama.key;

    location / {
        proxy_pass http://localhost:11434;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Caddy

```
ollama.example.com {
    reverse_proxy localhost:11434
}
```

## Troubleshooting

### Service startet nicht

```bash
# Logs prüfen
sudo journalctl -u ollama -f

# Service Status
sudo systemctl status ollama
```

### Zugriff verweigert

```bash
# Listening Ports prüfen
sudo ss -tlnp | grep 11434

# Sollte zeigen: 0.0.0.0:11434 (nicht 127.0.0.1:11434)
```

### Port bereits belegt

```bash
# Prüfen wer Port nutzt
sudo lsof -i :11434

# Anderen Port verwenden
Environment="OLLAMA_HOST=0.0.0.0:11435"
```

### Permission Denied

```bash
# Ollama-User hat keine Berechtigung für niedrige Ports (<1024)
# Verwende Port >1024 oder setze Capabilities:
sudo setcap 'cap_net_bind_service=+ep' /usr/local/bin/ollama
```

## API Endpoints testen

### Modelle auflisten

```bash
curl http://localhost:11434/api/tags
```

### Chat Request

```bash
curl http://localhost:11434/api/generate -d '{
  "model": "llama2",
  "prompt": "Why is the sky blue?",
  "stream": false
}'
```

### Embeddings

```bash
curl http://localhost:11434/api/embeddings -d '{
  "model": "llama2",
  "prompt": "Here is an article about llamas..."
}'
```

## Sicherheitshinweise

- **0.0.0.0 exponiert Ollama ins Netzwerk** - nur in vertrauenswürdigen Netzen nutzen
- **Keine Authentifizierung** - Ollama hat keine eingebaute Auth
- **Reverse Proxy empfohlen** für Production mit Auth und HTTPS
- **Firewall konfigurieren** - Port nur für benötigte IPs/Netze öffnen
- **VPN nutzen** für Zugriff von extern

## Best Practices

- **systemctl edit** statt direkte Service-Bearbeitung (update-sicher)
- **Reverse Proxy** mit Authentication für Production
- **Monitoring** - Ollama-Verfügbarkeit überwachen
- **Backup** - Ollama Models und Konfiguration regelmäßig sichern
- **Updates** - Ollama regelmäßig aktualisieren, dann Config prüfen

## Update-Workflow

```bash
# 1. Ollama updaten
curl -fsSL https://ollama.com/install.sh | sh

# 2. Config prüfen (bei systemctl edit: automatisch OK)
sudo systemctl status ollama

# 3. Falls OLLAMA_HOST fehlt
sudo systemctl edit ollama
# Environment="OLLAMA_HOST=0.0.0.0" hinzufügen

# 4. Service neustarten
sudo systemctl restart ollama

# 5. Testen
curl http://localhost:11434/api/version
```

## Integration mit anderen Tools

### Open WebUI

```yaml
services:
  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    ports:
      - "3000:8080"
    environment:
      - OLLAMA_BASE_URL=http://host.docker.internal:11434
    extra_hosts:
      - "host.docker.internal:host-gateway"
```

### Python Client

```python
import ollama

client = ollama.Client(host='http://192.168.1.100:11434')
response = client.chat(model='llama2', messages=[
  {'role': 'user', 'content': 'Why is the sky blue?'}
])
print(response['message']['content'])
```

### JavaScript/TypeScript

```javascript
const response = await fetch('http://192.168.1.100:11434/api/generate', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    model: 'llama2',
    prompt: 'Why is the sky blue?',
    stream: false
  })
});
const data = await response.json();
console.log(data.response);
```

---

**Update-sichere Konfiguration für Ollama Netzwerk-Zugriff.**
