#!/usr/bin/env bash
# iPhone/iPad-only preparation and optional unsigned IPA build.
set -euo pipefail
cd "$(dirname "$0")/.."

mode="${1:-prepare}"
case "$mode" in prepare|ipa) ;; *) echo "Usage: $0 [prepare|ipa]" >&2; exit 2 ;; esac
if [ "$(uname -s)" != Darwin ]; then
    echo "This build requires macOS and full Xcode." >&2
    exit 1
fi
for tool in xcodebuild xcrun xcodegen rustup cargo curl unzip; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Missing $tool. See START-HERE.md for prerequisites." >&2
        exit 1
    fi
done
xcrun --sdk iphoneos --show-sdk-path >/dev/null
xcrun --sdk iphonesimulator --show-sdk-path >/dev/null

# Fetch the upstream, checksum-verified runtime, streaming server, and fonts.
./scripts/fetch-server-deps.sh
rustup toolchain install nightly --profile minimal
rustup +nightly target add aarch64-apple-ios aarch64-apple-ios-sim
(
    cd core
    SDKROOT="$(xcrun --sdk iphoneos --show-sdk-path)" \
        cargo +nightly build --target aarch64-apple-ios --release
    SDKROOT="$(xcrun --sdk iphonesimulator --show-sdk-path)" \
        cargo +nightly build --target aarch64-apple-ios-sim --release
)
framework="app/Vendor/StremioXCore.xcframework"
rm -rf "$framework"
xcodebuild -create-xcframework \
    -library core/target/aarch64-apple-ios/release/libstremiox_core.a -headers core/include \
    -library core/target/aarch64-apple-ios-sim/release/libstremiox_core.a -headers core/include \
    -output "$framework"
(cd app && xcodegen generate --spec project-ios.yml)

if [ "$mode" = prepare ]; then
    echo "Open app/StremioPersonal.xcodeproj; select your team and iPhone, then Run."
    exit 0
fi
xcodebuild -project app/StremioPersonal.xcodeproj -scheme StremioPersonal \
    -sdk iphoneos -destination 'generic/platform=iOS' -configuration Release \
    -derivedDataPath app/build/personal-ios CODE_SIGNING_ALLOWED=NO build

staging="$(mktemp -d)"
trap 'rm -rf "$staging"' EXIT
mkdir -p "$staging/Payload" build/personal-ios
cp -R app/build/personal-ios/Build/Products/Release-iphoneos/StremioPersonal.app "$staging/Payload/"
output="$PWD/build/personal-ios/StremioPersonal-unsigned.ipa"
rm -f "$output"
(cd "$staging" && zip -qry "$output" Payload)
shasum -a 256 "$output" > build/personal-ios/SHA256SUMS.txt
echo "Unsigned IPA: $output (sign before installing)"
