# Rivet

Private daily accountability app and backend.

Backend:

- FastAPI
- SQLite WAL
- Ed25519 signed device requests
- Pull-based sync
- Mistral Large 3 via backend-only environment secret

iOS:

- SwiftUI, iOS 17+
- Local notifications only
- No APNs, Firebase Cloud Messaging, or backend push
- Sideloadly-oriented unsigned IPA build flow

The implementation contract is preserved in `Rivet_Planning_Package/` and copied into `docs/specs/`.

Build status artifacts and pre-IPA deployment notes are in `docs/deployment-status.md`.
