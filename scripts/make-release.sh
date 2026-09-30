#!/bin/zsh
# Builds a universal "Redline.app" and packages it as build/Redline-<version>.dmg.
#
# The app is ad-hoc signed (no Developer ID), so it isn't notarized: on first launch,
# macOS asks the user to allow it in System Settings → Privacy & Security.

set -euo pipefail
cd "$(dirname "$0")/.."

./scripts/build-app.sh
APP="build/Redline.app"
codesign --verify --strict "$APP"

VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$APP/Contents/Info.plist")
DMG="build/Redline-$VERSION.dmg"

echo "Packaging $DMG…"
STAGING="build/dmg"
rm -rf "$STAGING"
mkdir -p "$STAGING"
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"
hdiutil create -volname "Redline" -srcfolder "$STAGING" -fs HFS+ -format UDZO -ov "$DMG" -quiet
rm -rf "$STAGING"

echo "Done: $DMG"
