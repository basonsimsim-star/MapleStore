#!/bin/zsh

set -euo pipefail

usage() {
    cat <<'EOF'
Generate GitHub Actions signing inputs for:
  .github/workflows/upstream-signed-ios.yml

Required inputs:
  --p12              Path to Apple signing certificate (.p12)
  --p12-password     Password used when exporting .p12
  --mobileprovision  Path to provisioning profile (.mobileprovision)

Optional:
  --output-dir       Output directory (default: /tmp/asspp-gha-inputs-<timestamp>)
  --ota-base-url     Custom OTA base URL for IOS_OTA_BASE_URL (example: https://app.example.com)
  --bundle-id        Override bundle id for IOS_BUNDLE_ID
  --export-method    Override IOS_EXPORT_METHOD (ad-hoc|development|enterprise|app-store)
  --keychain-password Override IOS_KEYCHAIN_PASSWORD (otherwise auto-generated)
  -h, --help         Show this help

Example file names:
  ./Certificates/apple_distribution.p12
  ./Certificates/Asspp_AdHoc.mobileprovision

Example:
  ./Resources/Scripts/generate.github.action.inputs.sh \
    --p12 ./Certificates/apple_distribution.p12 \
    --p12-password 'your-p12-password' \
    --mobileprovision ./Certificates/Asspp_AdHoc.mobileprovision \
    --ota-base-url https://app.example.com
EOF
}

error() {
    echo "Error: $1" >&2
    exit 1
}

require_file() {
    local path="$1"
    [ -f "$path" ] || error "File not found: $path"
}

to_lower() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

P12_FILE=""
P12_PASSWORD=""
PROFILE_FILE=""
OUTPUT_DIR="/tmp/asspp-gha-inputs-$(date +%Y%m%d-%H%M%S)"
OTA_BASE_URL=""
BUNDLE_ID_OVERRIDE=""
EXPORT_METHOD_OVERRIDE=""
KEYCHAIN_PASSWORD_OVERRIDE=""

while [ $# -gt 0 ]; do
    case "$1" in
        --p12)
            [ $# -ge 2 ] || error "--p12 requires a value"
            P12_FILE="$2"
            shift 2
            ;;
        --p12-password)
            [ $# -ge 2 ] || error "--p12-password requires a value"
            P12_PASSWORD="$2"
            shift 2
            ;;
        --mobileprovision)
            [ $# -ge 2 ] || error "--mobileprovision requires a value"
            PROFILE_FILE="$2"
            shift 2
            ;;
        --output-dir)
            [ $# -ge 2 ] || error "--output-dir requires a value"
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --ota-base-url)
            [ $# -ge 2 ] || error "--ota-base-url requires a value"
            OTA_BASE_URL="$2"
            shift 2
            ;;
        --bundle-id)
            [ $# -ge 2 ] || error "--bundle-id requires a value"
            BUNDLE_ID_OVERRIDE="$2"
            shift 2
            ;;
        --export-method)
            [ $# -ge 2 ] || error "--export-method requires a value"
            EXPORT_METHOD_OVERRIDE="$2"
            shift 2
            ;;
        --keychain-password)
            [ $# -ge 2 ] || error "--keychain-password requires a value"
            KEYCHAIN_PASSWORD_OVERRIDE="$2"
            shift 2
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            error "Unknown argument: $1"
            ;;
    esac
done

[ -n "$P12_FILE" ] || error "Missing --p12"
[ -n "$P12_PASSWORD" ] || error "Missing --p12-password (workflow requires IOS_CERT_PASSWORD)"
[ -n "$PROFILE_FILE" ] || error "Missing --mobileprovision"

command -v security >/dev/null 2>&1 || error "security command not found (run on macOS)"
command -v openssl >/dev/null 2>&1 || error "openssl command not found"
[ -x /usr/libexec/PlistBuddy ] || error "/usr/libexec/PlistBuddy not found"

require_file "$P12_FILE"
require_file "$PROFILE_FILE"

P12_VERIFY_ERR_FILE=$(mktemp)

if ! openssl pkcs12 -in "$P12_FILE" -passin "pass:${P12_PASSWORD}" -nokeys >/dev/null 2>"$P12_VERIFY_ERR_FILE"; then
    # OpenSSL 3 may reject old PKCS#12 algorithms unless -legacy is enabled.
    if ! openssl pkcs12 -legacy -in "$P12_FILE" -passin "pass:${P12_PASSWORD}" -nokeys >/dev/null 2>"$P12_VERIFY_ERR_FILE"; then
        P12_ERR_MSG=$(tr '\n' ' ' <"$P12_VERIFY_ERR_FILE" | sed 's/[[:space:]]\+/ /g')
        if echo "$P12_ERR_MSG" | grep -Eiq "unsupported|legacy|unknown pbe|unknown cipher|mac verify error|invalid password"; then
            error "Unable to read .p12. Password may be wrong, or file uses legacy encryption unsupported by default OpenSSL 3. Re-export .p12 from Keychain Access and retry. openssl: $P12_ERR_MSG"
        fi
        error "Unreadable .p12 file. openssl: $P12_ERR_MSG"
    fi
fi

TMP_DIR=$(mktemp -d)
PROFILE_PLIST="$TMP_DIR/profile.plist"
cleanup() {
    if [ -n "${TMP_DIR:-}" ]; then
        rm -rf "$TMP_DIR"
    fi
    rm -f "$P12_VERIFY_ERR_FILE"
}
trap cleanup EXIT

security cms -D -i "$PROFILE_FILE" >"$PROFILE_PLIST"

PROFILE_NAME=$(/usr/libexec/PlistBuddy -c "Print Name" "$PROFILE_PLIST")
PROFILE_UUID=$(/usr/libexec/PlistBuddy -c "Print UUID" "$PROFILE_PLIST")
TEAM_ID=$(/usr/libexec/PlistBuddy -c "Print TeamIdentifier:0" "$PROFILE_PLIST")
APP_IDENTIFIER=$(/usr/libexec/PlistBuddy -c "Print Entitlements:application-identifier" "$PROFILE_PLIST")

BUNDLE_ID="${APP_IDENTIFIER#*.}"
if [ -n "$BUNDLE_ID_OVERRIDE" ]; then
    BUNDLE_ID="$BUNDLE_ID_OVERRIDE"
fi

HAS_PROVISIONED_DEVICES="false"
if /usr/libexec/PlistBuddy -c "Print ProvisionedDevices:0" "$PROFILE_PLIST" >/dev/null 2>&1; then
    HAS_PROVISIONED_DEVICES="true"
fi

PROVISIONS_ALL_DEVICES="false"
if /usr/libexec/PlistBuddy -c "Print ProvisionsAllDevices" "$PROFILE_PLIST" >/dev/null 2>&1; then
    PROVISIONS_ALL_DEVICES=$(/usr/libexec/PlistBuddy -c "Print ProvisionsAllDevices" "$PROFILE_PLIST")
fi

GET_TASK_ALLOW="false"
if /usr/libexec/PlistBuddy -c "Print Entitlements:get-task-allow" "$PROFILE_PLIST" >/dev/null 2>&1; then
    GET_TASK_ALLOW=$(/usr/libexec/PlistBuddy -c "Print Entitlements:get-task-allow" "$PROFILE_PLIST")
fi

if [ -n "$EXPORT_METHOD_OVERRIDE" ]; then
    EXPORT_METHOD="$EXPORT_METHOD_OVERRIDE"
else
    if [ "$(to_lower "$PROVISIONS_ALL_DEVICES")" = "true" ]; then
        EXPORT_METHOD="enterprise"
    elif [ "$HAS_PROVISIONED_DEVICES" = "true" ]; then
        if [ "$(to_lower "$GET_TASK_ALLOW")" = "true" ]; then
            EXPORT_METHOD="development"
        else
            EXPORT_METHOD="ad-hoc"
        fi
    else
        EXPORT_METHOD="app-store"
    fi
fi

case "$EXPORT_METHOD" in
    development)
        SIGNING_IDENTITY="Apple Development"
        ;;
    ad-hoc | enterprise | app-store)
        SIGNING_IDENTITY="Apple Distribution"
        ;;
    *)
        error "Invalid export method: $EXPORT_METHOD"
        ;;
esac

KEYCHAIN_PASSWORD="$KEYCHAIN_PASSWORD_OVERRIDE"
if [ -z "$KEYCHAIN_PASSWORD" ]; then
    KEYCHAIN_PASSWORD=$(openssl rand -hex 24)
fi

CERT_B64=$(openssl base64 -A -in "$P12_FILE")
PROFILE_B64=$(openssl base64 -A -in "$PROFILE_FILE")

mkdir -p "$OUTPUT_DIR/secrets" "$OUTPUT_DIR/variables"

printf '%s' "$CERT_B64" >"$OUTPUT_DIR/secrets/IOS_CERT_P12_BASE64.txt"
printf '%s' "$P12_PASSWORD" >"$OUTPUT_DIR/secrets/IOS_CERT_PASSWORD.txt"
printf '%s' "$PROFILE_B64" >"$OUTPUT_DIR/secrets/IOS_PROVISIONING_PROFILE_BASE64.txt"
printf '%s' "$KEYCHAIN_PASSWORD" >"$OUTPUT_DIR/secrets/IOS_KEYCHAIN_PASSWORD.txt"
printf '%s' "$TEAM_ID" >"$OUTPUT_DIR/secrets/IOS_TEAM_ID.txt"

printf '%s' "$EXPORT_METHOD" >"$OUTPUT_DIR/variables/IOS_EXPORT_METHOD.txt"
printf '%s' "$SIGNING_IDENTITY" >"$OUTPUT_DIR/variables/IOS_SIGNING_IDENTITY.txt"
printf '%s' "$BUNDLE_ID" >"$OUTPUT_DIR/variables/IOS_BUNDLE_ID.txt"
if [ -n "$OTA_BASE_URL" ]; then
    printf '%s' "${OTA_BASE_URL%/}" >"$OUTPUT_DIR/variables/IOS_OTA_BASE_URL.txt"
fi

cat >"$OUTPUT_DIR/profile.summary.txt" <<EOF
profile_name=$PROFILE_NAME
profile_uuid=$PROFILE_UUID
team_id=$TEAM_ID
application_identifier=$APP_IDENTIFIER
bundle_id=$BUNDLE_ID
export_method=$EXPORT_METHOD
signing_identity=$SIGNING_IDENTITY
EOF

cat >"$OUTPUT_DIR/apply-with-gh.sh" <<EOF
#!/bin/zsh
set -euo pipefail

: "\${GITHUB_REPOSITORY:?Please set GITHUB_REPOSITORY=owner/repo}"

BASE_DIR="$OUTPUT_DIR"

gh secret set IOS_CERT_P12_BASE64 --repo "\${GITHUB_REPOSITORY}" < "\$BASE_DIR/secrets/IOS_CERT_P12_BASE64.txt"
gh secret set IOS_CERT_PASSWORD --repo "\${GITHUB_REPOSITORY}" < "\$BASE_DIR/secrets/IOS_CERT_PASSWORD.txt"
gh secret set IOS_PROVISIONING_PROFILE_BASE64 --repo "\${GITHUB_REPOSITORY}" < "\$BASE_DIR/secrets/IOS_PROVISIONING_PROFILE_BASE64.txt"
gh secret set IOS_KEYCHAIN_PASSWORD --repo "\${GITHUB_REPOSITORY}" < "\$BASE_DIR/secrets/IOS_KEYCHAIN_PASSWORD.txt"
gh secret set IOS_TEAM_ID --repo "\${GITHUB_REPOSITORY}" < "\$BASE_DIR/secrets/IOS_TEAM_ID.txt"

gh variable set IOS_EXPORT_METHOD --repo "\${GITHUB_REPOSITORY}" --body "\$(cat "\$BASE_DIR/variables/IOS_EXPORT_METHOD.txt")"
gh variable set IOS_SIGNING_IDENTITY --repo "\${GITHUB_REPOSITORY}" --body "\$(cat "\$BASE_DIR/variables/IOS_SIGNING_IDENTITY.txt")"
gh variable set IOS_BUNDLE_ID --repo "\${GITHUB_REPOSITORY}" --body "\$(cat "\$BASE_DIR/variables/IOS_BUNDLE_ID.txt")"
if [ -f "\$BASE_DIR/variables/IOS_OTA_BASE_URL.txt" ]; then
    gh variable set IOS_OTA_BASE_URL --repo "\${GITHUB_REPOSITORY}" --body "\$(cat "\$BASE_DIR/variables/IOS_OTA_BASE_URL.txt")"
fi

echo "Done. Secrets/variables uploaded to \${GITHUB_REPOSITORY}"
EOF

chmod +x "$OUTPUT_DIR/apply-with-gh.sh"

cat <<EOF
Generated GitHub Actions inputs successfully.

Output directory:
  $OUTPUT_DIR

Parsed profile:
  Name: $PROFILE_NAME
  UUID: $PROFILE_UUID
  Team ID: $TEAM_ID
  Bundle ID: $BUNDLE_ID
  Export Method: $EXPORT_METHOD
  Signing Identity: $SIGNING_IDENTITY

Next steps:
  1) export GITHUB_REPOSITORY="<owner>/<repo>"
  2) $OUTPUT_DIR/apply-with-gh.sh

Files generated:
  - secrets/*.txt
  - variables/*.txt
  - profile.summary.txt
  - apply-with-gh.sh
EOF
