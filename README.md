# MapleStore

An independent iPhone and iPad App Store manager based on the current [Asspp](https://github.com/Lakr233/Asspp) source. Browse App Store apps, select available older versions, download IPAs, and export them from a native SwiftUI app.

**[Start here to get your IPA](START-HERE.md)** · [Build instructions](BUILDING.md) · [Source and credits](UPSTREAM.md) · [MIT License](LICENSE)

## Included

- App Store search across supported regions.
- Apple Account sign-in and verification, with Keychain storage.
- Version history and downloads of releases Apple still serves to your account.
- Download queue, progress, and IPA export.
- Existing upstream local OTA installation support.
- A GitHub Actions workflow that builds an **unsigned IPA** and publishes tagged releases.

## Get an IPA

Push this repository to your GitHub account. Open **Actions → Build MapleStore IPA** and download the successful run's artifact. Extract `MapleStore-unsigned.ipa`, then sign and install it with your preferred sideloading tool. See [BUILDING.md](BUILDING.md) for the commands.

No Apple credentials or signing secrets are required to build the unsigned IPA. Windows cannot compile iOS applications locally; GitHub Actions uses a macOS runner.

## App and version access

Apple controls download eligibility. Paid apps require purchase; free apps may require obtaining their free license. Version history only includes versions Apple exposes, and a listed version may no longer be downloadable. The app cannot download every app or every historical version, bypass ownership checks, or decrypt FairPlay-protected IPAs. Replacing an installed app with an older version can also be limited by iOS and data compatibility; back up the target app's data first.

## Current source and compatibility

MapleStore **1.0.0** uses Asspp's latest main commit retrieved October 25, 2026 (`6682eb8`, October 20, upstream version 4.2.2). It requires **iOS 17 or later** and retains upstream's newer-iOS interface paths. The build workflow picks the newest stable Xcode installed on its runner. This is a snapshot, with reviewed updates required to stay current.

**Compilation and physical-device operation have not been verified in this Windows delivery environment.** Run the included workflow to confirm the IPA build, then test sign-in and installation on your device. Packaging checks alone do not certify compatibility with the newest iOS release.

## Credits

The application and artwork are derived from Lakr Aream's MIT-licensed Asspp, with its ApplePackage dependency and existing source notices retained. MapleStore is not an official release of DLiPA, PancakeStore, WaffleStore, or Asspp. See [UPSTREAM.md](UPSTREAM.md) for the exact snapshot and changes.
