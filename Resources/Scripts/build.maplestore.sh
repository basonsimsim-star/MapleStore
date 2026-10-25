#!/usr/bin/env bash
# Build an unsigned device IPA without resetting or cleaning the checkout.
set -euo pipefail

if [[ "$(uname -s)" != Darwin ]]; then
    echo 'Build requires macOS and Xcode. On Windows, use the GitHub Actions workflow.' >&2
    exit 1
fi
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
for command in xcodebuild xcbeautify python3 ditto shasum; do
    command -v "$command" >/dev/null || { echo "Missing tool: $command" >&2; exit 1; }
done
mkdir -p build

# Never overwrite a developer's signing configuration.
GENERATED_CONFIG=0
STAGING=""
cleanup() {
    if [[ "$GENERATED_CONFIG" == 1 ]]; then
        rm -f "$ROOT/Configuration/Developer.xcconfig"
    fi
    if [[ -n "$STAGING" ]]; then rm -rf "$STAGING"; fi
}
trap cleanup EXIT
if [[ ! -f Configuration/Developer.xcconfig ]]; then
    GENERATED_CONFIG=1
    cat > Configuration/Developer.xcconfig <<'CONFIG'
// Temporary configuration for unsigned IPA builds.
DEVELOPMENT_TEAM =
CODE_SIGN_STYLE = Manual
CODE_SIGN_IDENTITY =
CODE_SIGNING_REQUIRED = NO
CODE_SIGNING_ALLOWED = NO
CONFIG
fi

{
    echo 'MapleStore unsigned device build'
    echo "Commit: $(git rev-parse HEAD)"
    echo "Built (UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    xcodebuild -version
    xcodebuild -showsdks
} > build/build-info.txt

xcodebuild -workspace Asspp.xcworkspace -scheme Asspp \
    -configuration Release -destination 'generic/platform=iOS' \
    -derivedDataPath "$ROOT/build/DerivedDataMapleStore" \
    -clonedSourcePackagesDirPath "$ROOT/build/SourcePackages" \
    -onlyUsePackageVersionsFromResolvedFile \
    build \
    PRODUCT_BUNDLE_IDENTIFIER=app.maplestore.client \
    INFOPLIST_KEY_CFBundleDisplayName=MapleStore \
    DEVELOPMENT_TEAM='' CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY='' \
    CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO CODE_SIGN_ENTITLEMENTS='' \
    | tee build/xcodebuild.log | xcbeautify

APP="$ROOT/build/DerivedDataMapleStore/Build/Products/Release-iphoneos/Asspp.app"
[[ -d "$APP" ]] || { echo "Missing build product: $APP" >&2; exit 1; }
STAGING="$(mktemp -d "$ROOT/build/package.XXXXXX")"
mkdir "$STAGING/Payload"
ditto "$APP" "$STAGING/Payload/Asspp.app"
ditto -c -k --norsrc --keepParent "$STAGING/Payload" "$STAGING/MapleStore-unsigned.ipa"
python3 Resources/Scripts/check.maplestore.ipa.py "$STAGING/MapleStore-unsigned.ipa"
mv -f "$STAGING/MapleStore-unsigned.ipa" build/MapleStore-unsigned.ipa
(cd build && shasum -a 256 MapleStore-unsigned.ipa > MapleStore-unsigned.ipa.sha256)
echo 'Created build/MapleStore-unsigned.ipa. Sign it before installing.'
