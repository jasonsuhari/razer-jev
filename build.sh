#!/bin/sh
set -e
cd "$(dirname "$0")"
APP="$HOME/Applications/Razer Jev.app"
KEYCHAIN="$PWD/signing/razer-jev.keychain-db"

swift build -c release
mkdir -p "$APP/Contents/MacOS"
cp .build/release/RazerJev "$APP/Contents/MacOS/RazerJev"
cp Info.plist "$APP/Contents/Info.plist"
rm -rf "$APP/Contents/Resources/modes" && mkdir -p "$APP/Contents/Resources" && cp -R modes "$APP/Contents/Resources/modes"

[ -f "$KEYCHAIN" ] || signing/make-identity.sh
security unlock-keychain -p "$(cat signing/keychain-password)" "$KEYCHAIN"
codesign --force --keychain "$KEYCHAIN" -s "Razer Jev Local Signing" -i local.razer-jev "$APP"
echo "$APP"
