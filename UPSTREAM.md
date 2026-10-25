# Source and attribution

MapleStore 1.0.0 is an independent fork of [Lakr233/Asspp](https://github.com/Lakr233/Asspp), not an official PancakeStore, WaffleStore, or DLiPA release.

- Snapshot date: October 25, 2026.
- Upstream main commit: `6682eb8f831a7b5c62dc14ea97088769c6adba48`.
- Upstream commit date: October 20, 2026.
- Upstream version configuration: 4.2.2.
- App Store protocol library: [ApplePackage](https://github.com/Lakr233/ApplePackage), pinned by upstream to 2.0.3, revision `773583a29c6b1f1b0d0783d0a15d3ddafcd85eec`.
- License: MIT, copyright 2025 Lakr Aream. The original [LICENSE](LICENSE) and source notices are retained. Dependencies retain their respective licenses.

Changes in MapleStore:

- Separate display name, bundle identifier, and Keychain service names.
- Source version configuration consistently uses MapleStore 1.0.0.
- IPA workflow supports push, pull request, manual build, and tagged release.
- Build selects the latest stable Xcode available on its runner and records the actual SDK.
- Packaging script preserves local changes and signing configuration.
- IPA archive validation, packaging regression checks, and checksums.
- Setup instructions and explicit build/device validation status.

Search, account authentication, version history, downloads, IPA export, existing artwork, and the optional local OTA installer are inherited from Asspp. App Store credentials are entered in the app and stored using upstream's Keychain integration, never in GitHub Actions. No ownership-check bypass or FairPlay decryption has been added.
