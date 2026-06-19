# Deployment Status Before IPA Build

Checked on June 19, 2026.

## Backend URL

`https://rivetapp.duckdns.org`

## VM Service State

- `rivet-backend.service`: active
- `caddy`: active
- Uvicorn: listening on `127.0.0.1:8721`
- Caddy: listening on public `80` and `443`
- Public `https://rivetapp.duckdns.org:8721/healthz`: blocked/no response
- Local `http://127.0.0.1:8721/healthz`: `{"status":"ok"}`

## UFW

Configured rules:

```text
Default: deny incoming, allow outgoing
22/tcp allow from 69.181.86.59
443/tcp allow from anywhere
80/tcp allow from anywhere
8721/tcp deny from anywhere
```

OCI ingress still needs to match this posture:

- TCP 443 from `0.0.0.0/0`
- TCP 80 from `0.0.0.0/0` only for Caddy certificate/redirect
- TCP 22 only from the trusted IP/range
- No public ingress to TCP 8721

## Secrets

`MISTRAL_API_KEY` is set in `/etc/rivet/backend.env` on `autopersonal`. It is not stored in this repository.

Model id in deployed env: `MISTRAL_MODEL_ID=mistral-large-2512`.

## TLS Pin

Current active SPKI SHA-256 pin:

```text
WZohl+Vx3/1i/HHPVo3P+w8l3tuxzxQijsfhupf798k=
```

Before a Release iOS build enables pinning, generate and configure a backup pin from a second key controlled by the user.

## Backup Verification

Online SQLite backup to `/var/backups/rivet` was tested and `PRAGMA integrity_check;` returned `ok`.

The directory remains owned by `root:rivet`; an ACL grants the `rivet` service user write access for the documented backup command.

## Pairing Command

Generate the real install-time code only when the app is ready to pair:

```bash
sudo bash -lc 'set -a; . /etc/rivet/backend.env; set +a; cd /opt/rivet/backend; sudo -u rivet env DATABASE_URL="$DATABASE_URL" PUBLIC_BASE_URL="$PUBLIC_BASE_URL" TIMEZONE="$TIMEZONE" MISTRAL_MODEL_ID="${MISTRAL_MODEL_ID:-}" .venv/bin/python -m app.admin pairing-code create --ttl 10m'
```

A one-minute probe code was generated successfully and discarded.

## IPA Boundary

The next blocked step is a native iOS archive/IPA build. This must run on macOS with Xcode; this Windows PC cannot compile a SwiftUI iOS app or produce the IPA directly.
