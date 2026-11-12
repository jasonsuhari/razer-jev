#!/bin/sh
# macOS ties Input Monitoring and Screen Recording grants to the app's signature.
# A fixed local certificate keeps those grants across rebuilds; ad-hoc signing loses them.
set -e
cd "$(dirname "$0")"
KEYCHAIN="$PWD/razer-jev.keychain-db"
openssl req -x509 -newkey rsa:2048 -nodes -keyout key.pem -out cert.pem -days 3650 -config cert.cnf 2>/dev/null
openssl rand -hex 16 > keychain-password
chmod 600 key.pem keychain-password
PASSWORD=$(cat keychain-password)
openssl pkcs12 -export -legacy -inkey key.pem -in cert.pem -out identity.p12 -passout "pass:$PASSWORD"
security create-keychain -p "$PASSWORD" "$KEYCHAIN"
security set-keychain-settings "$KEYCHAIN"
security unlock-keychain -p "$PASSWORD" "$KEYCHAIN"
security import identity.p12 -k "$KEYCHAIN" -P "$PASSWORD" -T /usr/bin/codesign >/dev/null
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$PASSWORD" "$KEYCHAIN" >/dev/null
rm identity.p12
security list-keychains -d user -s $(security list-keychains -d user | tr -d '"') "$KEYCHAIN"
