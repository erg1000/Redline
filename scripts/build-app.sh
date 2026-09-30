#!/bin/zsh
# Builds "Redline.app" into build/. Pass --install to copy it to /Applications and launch it.
set -euo pipefail
cd "$(dirname "$0")/.."

APP="build/Redline.app"
swift build -c release --arch arm64 --arch x86_64
BIN="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)/Redline"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Redline"
cp Resources/Info.plist "$APP/Contents/Info.plist"
[[ -f Resources/AppIcon.icns ]] && cp Resources/AppIcon.icns "$APP/Contents/Resources/"
codesign --force --sign - --entitlements Resources/Redline.entitlements --options runtime "$APP"
echo "Built $APP"

if [[ "${1:-}" == "--install" ]]; then
    pkill -x Redline || true
    rm -rf "/Applications/Redline.app"
    cp -R "$APP" /Applications/
    open "/Applications/Redline.app"
    echo "Installed to /Applications"
fi
