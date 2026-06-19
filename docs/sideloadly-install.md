# Sideloadly Install

Windows cannot compile a native iOS IPA. Build the app on a Mac with Xcode, then use this PC with Sideloadly if desired.

1. Install Sideloadly on this computer.
2. Connect the iPhone by USB.
3. Trust the computer on the iPhone.
4. Open Sideloadly.
5. Select the Rivet `.ipa`.
6. Enter the Apple ID when Sideloadly prompts.
7. Start install.
8. On iPhone, trust the developer profile if iOS requires it.
9. Launch Rivet.
10. Pair with `autopersonal` using `rivet-admin pairing-code create --ttl 10m`.
11. Grant notification permission.
12. Confirm Settings shows backend sync status.

Free Apple account installs may expire after 7 days and require reinstalling or re-signing. Backend data is canonical, so reinstalling the app should not delete history after re-pairing.

No APNs or remote push path is used. Rivet schedules local notifications on device after pulling backend records.
