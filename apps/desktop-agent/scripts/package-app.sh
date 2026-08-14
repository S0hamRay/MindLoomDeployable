#!/usr/bin/env bash
# Build MindLoomAgent, wrap it in a .app bundle, and publish a downloadable zip
# to the web app (apps/web/public/downloads/LoomCapture-macos.zip).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

WEB_BASE="${LOOM_WEB_BASE:-${FRONTEND_URL:-http://localhost:5500}}"
WEB_BASE="${WEB_BASE%/}"
if [[ -n "${LOOM_API_BASE:-}" ]]; then
  API_BASE="${LOOM_API_BASE}"
elif [[ "$WEB_BASE" == *localhost* || "$WEB_BASE" == *127.0.0.1* ]]; then
  API_BASE="http://localhost:8000"
else
  # Same-origin nginx proxy used by Compose / typical Railway frontend images.
  API_BASE="/api"
fi
API_BASE="${API_BASE%/}"

echo "Packaging Loom Capture"
echo "  webBase: $WEB_BASE"
echo "  apiBase: $API_BASE"
if [[ "$WEB_BASE" == *localhost* || "$WEB_BASE" == *127.0.0.1* ]]; then
  echo "  warning: webBase is localhost. People who download this build from a" >&2
  echo "  deployed site will not be able to sign in. Re-run with:" >&2
  echo "    LOOM_WEB_BASE=https://your-web-host ./scripts/package-app.sh" >&2
fi

build_arch() {
  local arch="$1"
  swift build -c release --arch "$arch" >&2
  local candidate="$ROOT/.build/${arch}-apple-macosx/release/MindLoomAgent"
  if [[ -x "$candidate" ]]; then
    printf '%s' "$candidate"
    return 0
  fi
  return 1
}

ARM_BIN=""
X86_BIN=""
ARM_BIN="$(build_arch arm64 || true)"
X86_BIN="$(build_arch x86_64 || true)"

BIN=""
if [[ -n "$ARM_BIN" && -n "$X86_BIN" ]]; then
  BIN="$ROOT/.build/MindLoomAgent-universal"
  lipo -create -output "$BIN" "$ARM_BIN" "$X86_BIN"
  echo "  binary: universal (arm64 + x86_64)"
elif [[ -n "$ARM_BIN" ]]; then
  BIN="$ARM_BIN"
  echo "  binary: arm64"
elif [[ -n "$X86_BIN" ]]; then
  BIN="$X86_BIN"
  echo "  binary: x86_64"
else
  # Host-arch fallback (older SwiftPM layouts).
  swift build -c release
  if [[ -x "$ROOT/.build/arm64-apple-macosx/release/MindLoomAgent" ]]; then
    BIN="$ROOT/.build/arm64-apple-macosx/release/MindLoomAgent"
  elif [[ -x "$ROOT/.build/release/MindLoomAgent" ]]; then
    BIN="$ROOT/.build/release/MindLoomAgent"
  else
    echo "error: could not find the MindLoomAgent release binary" >&2
    exit 1
  fi
  echo "  binary: $(basename "$(dirname "$(dirname "$BIN")")")"
fi

APP="$ROOT/dist/Loom Capture.app"
CONTENTS="$APP/Contents"
MACOS="$CONTENTS/MacOS"
IDENTIFIER="com.mindloom.capture-agent"

rm -rf "$ROOT/dist"
mkdir -p "$MACOS"

cat > "$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>Loom Capture</string>
  <key>CFBundleDisplayName</key>
  <string>Loom Capture</string>
  <key>CFBundleIdentifier</key>
  <string>${IDENTIFIER}</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleExecutable</key>
  <string>MindLoomAgent</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSAccessibilityUsageDescription</key>
  <string>Loom Capture uses Accessibility to record allowlisted app interaction metadata (not keystroke content) for workflow skill files.</string>
  <key>LoomWebBase</key>
  <string>${WEB_BASE}</string>
  <key>LoomAPIBase</key>
  <string>${API_BASE}</string>
</dict>
</plist>
PLIST

cp "$BIN" "$MACOS/MindLoomAgent"
chmod +x "$MACOS/MindLoomAgent"

# Ad-hoc sign the *bundle* so TCC ties permission to this app id (not a naked binary).
# Re-run this script after every rebuild; then toggle Accessibility off/on once and relaunch.
codesign --force --deep --sign - --identifier "$IDENTIFIER" "$APP"
xattr -cr "$APP" 2>/dev/null || true
codesign --verify --verbose=2 "$APP"

ZIP="$ROOT/dist/LoomCapture-macos.zip"
# ditto preserves macOS metadata that a plain zip can strip.
ditto -c -k --keepParent "$APP" "$ZIP"

WEB_DOWNLOADS="$ROOT/../web/public/downloads"
mkdir -p "$WEB_DOWNLOADS"
cp "$ZIP" "$WEB_DOWNLOADS/LoomCapture-macos.zip"

echo
echo "Packaged: $APP"
echo "Zip:      $ZIP"
echo "Web:      $WEB_DOWNLOADS/LoomCapture-macos.zip"
echo
echo "Launch locally: open \"$APP\""
echo "Then: System Settings → Privacy & Security → Accessibility → enable “Loom Capture”, quit, reopen."
echo
echo "People can download it from the website after you rebuild/redeploy the frontend image"
echo "so public/downloads/LoomCapture-macos.zip is included."
echo "  Web UI:  /download"
echo "  Direct:  /downloads/LoomCapture-macos.zip"
