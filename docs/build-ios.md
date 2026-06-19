# iOS Build

This workspace is on Windows, so it cannot run Xcode or produce a native iOS IPA.

On macOS:

```bash
cd ios/Rivet
open Package.swift
```

Create an iOS app target named `Rivet`, add `Sources/RivetApp` to the target, set deployment target to iOS 17.0, add the generated app icon set, and archive in Release. The backend URL is `https://rivetapp.duckdns.org`; release SPKI pins must be filled after Caddy is deployed and the active/backup public keys are generated.

Do not put `MISTRAL_API_KEY` in the iOS project. The app only stores per-device token and signing key in Keychain.
