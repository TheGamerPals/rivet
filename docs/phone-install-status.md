# Phone Install Status

Checked on June 19, 2026.

## IPA

`C:\Users\Tolerance\Downloads\app setup\artifacts\Rivet-unsigned-ipa\Rivet-unsigned.ipa`

## Sideloadly

Installed executable:

`C:\Users\Tolerance\AppData\Local\Sideloadly\sideloadly.exe`

Sideloadly was launched with the Rivet unsigned IPA.

## iPhone Detection

Windows did not enumerate an Apple/iPhone USB device during the check. If Sideloadly shows no device:

1. Unlock the iPhone.
2. Keep it connected by USB.
3. Tap **Trust This Computer** on the iPhone if prompted.
4. Reopen Apple Devices or iTunes once if Windows still does not attach the driver.
5. Relaunch Sideloadly if needed.

## Backend

Backend URL:

`https://rivetapp.duckdns.org`

Backend service and Caddy were verified active before IPA install.

## Pairing Code

A 10-minute pairing code was generated:

`ITvaYBKCrDFkXWRRLlh0xg`

If it expires, generate a fresh one:

```bash
sudo bash -lc 'set -a; . /etc/rivet/backend.env; set +a; cd /opt/rivet/backend; sudo -u rivet env DATABASE_URL="$DATABASE_URL" PUBLIC_BASE_URL="$PUBLIC_BASE_URL" TIMEZONE="$TIMEZONE" MISTRAL_MODEL_ID="${MISTRAL_MODEL_ID:-}" .venv/bin/python - <<'"'"'PY'"'"'
from app.admin import create_pairing_code
create_pairing_code(10)
PY'
```

Run that over:

```bash
ssh autopersonal
```

## Sideloadly Steps Remaining

1. Select the IPA above if it is not already selected.
2. Select the connected iPhone.
3. Enter Apple ID when Sideloadly prompts.
4. Start install.
5. On iPhone, trust the developer profile if iOS requires it.
6. Open Rivet.
7. Enter the pairing code.
8. Grant notification permission.
9. Open Settings in Rivet and confirm backend sync status.
