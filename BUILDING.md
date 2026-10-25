# Build MapleStore

## GitHub Actions (works from Windows)

Create an empty repository on GitHub, without an initial README. From this directory:

```powershell
git remote add origin https://github.com/YOUR-USERNAME/MapleStore.git
git push -u origin main
```

If you downloaded `MapleStore-repository.bundle`, restore its full Git history first instead:

```powershell
git clone .\MapleStore-repository.bundle MapleStore
cd MapleStore
git remote set-url origin https://github.com/YOUR-USERNAME/MapleStore.git
git push -u origin main
```

The source ZIP contains the files without Git history. If using that ZIP instead of the bundle, extract it and run `git init -b main`, `git add .`, and `git commit -m "Initial MapleStore source"` before adding the GitHub remote. Git may ask you to configure your commit name and email.

Replace `YOUR-USERNAME` with your GitHub username. Git will ask you to authenticate to GitHub. Apple Account credentials are **not** needed for CI: the build only compiles source.

Open **Actions → Build MapleStore IPA**. Download the successful run's artifact and extract `MapleStore-unsigned.ipa`. Actions must be enabled for the repository. Private-repository macOS jobs may consume paid Actions minutes depending on your plan.

The workflow selects the newest stable Xcode **installed on the macOS 26 runner**. This can lag Apple's newest release. The build information file records the actual Xcode and SDK versions. Source dependencies stay pinned to the checked-in `Package.resolved` for repeatability.

Push a version tag to build and publish a GitHub Release in your own repository:

```powershell
git tag v1.0.0
git push origin v1.0.0
```

Tagged releases contain the unsigned IPA, SHA-256 checksum, and build information. Normal branch builds are available as Actions artifacts for 30 days.

## Local macOS build

Install Xcode and its iOS platform support, select Xcode's developer directory, and accept its license. Install `xcbeautify` if needed:

```bash
brew install xcbeautify
bash Resources/Scripts/build.maplestore.sh
```

Output: `build/MapleStore-unsigned.ipa`. Open `Asspp.xcworkspace` for interactive development; the workspace and target retain their upstream names. For a signed Xcode build, copy `Configuration/Developer.xcconfig.template` to `Configuration/Developer.xcconfig`, set your development team, and use a bundle identifier you control. The unsigned build script creates a temporary configuration only when none exists and does not overwrite your configuration or reset Git changes.

Check the checksum on macOS with `shasum -a 256 -c MapleStore-unsigned.ipa.sha256`, or compare `Get-FileHash .\MapleStore-unsigned.ipa -Algorithm SHA256` on Windows.

## Updating

This fork records the latest Asspp main commit retrieved on October 25, 2026. It does not automatically merge upstream changes. Fetch and review updates from the `upstream` remote, merge them, and resolve any conflicts with MapleStore's configuration and workflow. Update Swift packages through Xcode and commit the resolved versions after a successful build. Dependabot opens weekly GitHub Actions update PRs after the repository is hosted on GitHub.

## Validation status

The delivery environment is Windows, without Xcode. Packaging regression checks and shell syntax checks can run here; the SwiftUI app, App Store authentication, and physical-device installation have not been tested here. A successful GitHub Actions run is required to confirm compilation. No particular iOS 27 release is certified by this fork.

The build script validates the IPA's ZIP integrity, application metadata, device platform, executable presence, and absence of personal build paths or provisioning files. These checks do not prove the app will authenticate or install on a device.
