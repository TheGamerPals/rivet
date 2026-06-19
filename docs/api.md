# Rivet API

Base URL: `https://rivetapp.duckdns.org`

All authenticated endpoints require:

- `Authorization: Bearer <device_token>`
- `X-Rivet-Device-Id`
- `X-Rivet-Timestamp`
- `X-Rivet-Nonce`
- `X-Rivet-Body-SHA256`
- `X-Rivet-Signature`

Canonical signature string:

```text
METHOD
PATH
CANONICAL_QUERY
DEVICE_ID
TIMESTAMP
NONCE
BODY_SHA256
```

Endpoints:

- `POST /v1/pair/claim`: unsigned pairing claim with code, display name, and Ed25519 public key.
- `GET /v1/sync?cursor=<integer>`: cursor-based pull sync.
- `POST /v1/progress`: idempotent progress submission with `client_request_id`.
- `PUT /v1/settings`: versioned settings update; stale `base_version` returns `409`.
- `GET /v1/day/{YYYY-MM-DD}`: signed daily timeline fetch.
- `GET /v1/diagnostics`: signed backend status.
- `GET /healthz`: localhost/service health only; Caddy config hides this publicly.
