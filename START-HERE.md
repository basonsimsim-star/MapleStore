# Get your IPA

MapleStore is a source-code Git repository. This download does **not** contain a compiled IPA yet.

1. Create an empty GitHub repository named `MapleStore`.
2. Push this local repository to it (commands are in [BUILDING.md](BUILDING.md)).
3. Open **Actions → Build MapleStore IPA**. The push starts a build, or choose **Run workflow**.
4. When the run succeeds, download the `MapleStore-unsigned-…` artifact.
5. Unzip it to get **MapleStore-unsigned.ipa**.
6. Sign and install that IPA using your preferred sideloading tool.

In MapleStore, add your Apple Account, search for an app, and use its **Version History** to select a downloadable release.

The app requires iOS 17 or later. Compatibility with your exact device and current iOS release needs physical-device testing.

Apple decides which apps and versions your account can download. Paid apps require a purchase. Free apps may require obtaining a free license first. Versions Apple no longer serves cannot be recovered by this app. An unsigned MapleStore IPA needs signing; downloaded App Store IPAs can retain FairPlay protection and account restrictions.
