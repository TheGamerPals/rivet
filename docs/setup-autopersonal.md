# Autopersonal Setup

Target paths:

- App: `/opt/rivet/backend`
- Venv: `/opt/rivet/backend/.venv`
- Env: `/etc/rivet/backend.env`
- Database: `/var/lib/rivet/rivet.sqlite3`
- Backups: `/var/backups/rivet`
- Service: `/etc/systemd/system/rivet-backend.service`
- Caddy: `/etc/caddy/Caddyfile`

Install packages:

```bash
sudo apt update
sudo apt install -y python3.12 python3.12-venv python3.12-dev build-essential sqlite3 git curl ca-certificates ufw caddy
```

Create user and directories:

```bash
sudo useradd --system --home /var/lib/rivet --shell /usr/sbin/nologin rivet
sudo mkdir -p /opt/rivet/backend /etc/rivet /var/lib/rivet /var/backups/rivet
sudo chown root:rivet /opt/rivet /opt/rivet/backend /etc/rivet /var/backups/rivet
sudo chown rivet:rivet /var/lib/rivet
sudo chmod 0750 /opt/rivet /opt/rivet/backend /etc/rivet /var/lib/rivet /var/backups/rivet
```

`/etc/rivet/backend.env`:

```bash
MISTRAL_API_KEY=...
DATABASE_URL=sqlite:////var/lib/rivet/rivet.sqlite3
PUBLIC_BASE_URL=https://rivetapp.duckdns.org
TIMEZONE=America/Los_Angeles
LOG_LEVEL=INFO
RIVET_BIND_HOST=127.0.0.1
RIVET_BIND_PORT=8721
RIVET_MODEL_ID=mistral-large-2512
```

Set permissions:

```bash
sudo chown root:rivet /etc/rivet/backend.env
sudo chmod 0640 /etc/rivet/backend.env
```

Systemd service:

```ini
[Unit]
Description=Rivet backend
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=rivet
Group=rivet
WorkingDirectory=/opt/rivet/backend
EnvironmentFile=/etc/rivet/backend.env
ExecStart=/opt/rivet/backend/.venv/bin/uvicorn app.main:app --host 127.0.0.1 --port 8721 --proxy-headers
Restart=on-failure
RestartSec=5
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/lib/rivet /var/backups/rivet
ReadOnlyPaths=/opt/rivet/backend /etc/rivet

[Install]
WantedBy=multi-user.target
```

Caddyfile:

```caddy
rivetapp.duckdns.org {
    encode zstd gzip
    handle /healthz {
        respond 404
    }
    handle {
        reverse_proxy 127.0.0.1:8721
    }
    header {
        Strict-Transport-Security "max-age=31536000; includeSubDomains"
        X-Content-Type-Options "nosniff"
        Referrer-Policy "no-referrer"
    }
}
```

UFW:

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 443/tcp
sudo ufw allow 80/tcp
sudo ufw deny 8721/tcp
sudo ufw enable
```

OCI ingress must allow TCP 443 publicly, TCP 80 only if needed for certificate issuance, TCP 22 only from your trusted IP, and no public 8721.

Backup:

```bash
sudo -u rivet sqlite3 /var/lib/rivet/rivet.sqlite3 ".backup '/var/backups/rivet/rivet-YYYYMMDD-HHMMSS.sqlite3'"
sqlite3 /var/backups/rivet/rivet-YYYYMMDD-HHMMSS.sqlite3 "PRAGMA integrity_check;"
```

SPKI pin extraction:

```bash
openssl s_client -connect rivetapp.duckdns.org:443 -servername rivetapp.duckdns.org </dev/null 2>/dev/null \
  | openssl x509 -pubkey -noout \
  | openssl pkey -pubin -outform der \
  | openssl dgst -sha256 -binary \
  | openssl base64
```

At-rest encryption is not implemented in v1 unless the VM disk is encrypted separately.
