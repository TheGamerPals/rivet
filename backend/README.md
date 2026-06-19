# Rivet Backend

FastAPI backend for Rivet. It stores canonical history on `autopersonal`, signs every paired-device request with Ed25519, and loads the Mistral API key only from backend environment.

## Local Development

```bash
cd backend
python3.12 -m venv .venv
. .venv/bin/activate
pip install -e ".[dev]"
export DATABASE_URL=sqlite:///./rivet.sqlite3
export PUBLIC_BASE_URL=https://rivetapp.duckdns.org
export RIVET_MODEL_ID=mistral-large-2512
uvicorn app.main:app --host 127.0.0.1 --port 8721
```

## Pairing Code

Pairing codes are SSH-only admin operations:

```bash
rivet-admin pairing-code create --ttl 10m
```

The command prints the code once and stores only a SHA-256 hash.

## Secrets

`MISTRAL_API_KEY` belongs only in `/etc/rivet/backend.env` on `autopersonal`. Do not put it in iOS source, `.env.example`, docs examples, or git history.

## Model

The default model id is `mistral-large-2512`, verified against Mistral docs for Mistral Large 3 on June 19, 2026. Override with `RIVET_MODEL_ID`.

## Validation

```bash
python -m ruff format backend
python -m ruff check backend
python -m mypy backend/app
python -m pytest backend/tests
```
