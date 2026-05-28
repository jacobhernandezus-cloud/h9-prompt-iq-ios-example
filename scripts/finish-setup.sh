#!/usr/bin/env bash
# Post-Xcode-install bootstrap. Run once, after Xcode finishes downloading from
# the App Store. Bundles every step that needs sudo into a single password entry
# (sudo caches the timestamp for 5 minutes by default).
#
# Usage:
#   bash scripts/finish-setup.sh

set -euo pipefail

XCODE_APP="/Applications/Xcode.app"

if [[ ! -d "$XCODE_APP" ]]; then
  echo "Xcode.app not found at $XCODE_APP" >&2
  echo "Open the App Store and install Xcode (App ID 497799835), then re-run." >&2
  exit 1
fi

echo "→ Pointing xcode-select at the real Xcode (sudo)…"
sudo xcode-select -s "$XCODE_APP/Contents/Developer"

echo "→ Accepting the Xcode license (sudo, no re-prompt expected)…"
sudo xcodebuild -license accept

echo "→ Running Xcode first-launch tasks (installs simulator runtimes; sudo)…"
sudo xcodebuild -runFirstLaunch

echo "→ Booting the iPhone 17 simulator (no sudo needed beyond this point)…"
# Pick the newest iPhone simulator that's available, fall back to whatever exists.
DEVICE_ID=$(
  xcrun simctl list devices available --json \
    | python3 -c '
import json, sys
data = json.load(sys.stdin)
ios = next((k for k in data["devices"] if "iOS" in k and data["devices"][k]), None)
if not ios:
    sys.exit("no iOS simulators available")
devs = data["devices"][ios]
# Prefer newest iPhone, fall back to first
phones = [d for d in devs if "iPhone" in d["name"]]
chosen = sorted(phones, key=lambda d: d["name"])[-1] if phones else devs[0]
print(chosen["udid"])
'
)
echo "  using simulator: $DEVICE_ID"
xcrun simctl boot "$DEVICE_ID" || true  # boot is idempotent
open -a Simulator

echo "→ Regenerating the Xcode project from project.yml…"
( cd "$(dirname "$0")/.." && xcodegen generate )

echo ""
echo "✓ Setup complete. To build and install the app:"
echo ""
echo "  cd $(cd "$(dirname "$0")/.." && pwd)"
echo "  xcodebuild -project PromptIQExample.xcodeproj \\"
echo "    -scheme PromptIQExample \\"
echo "    -destination 'id=$DEVICE_ID' \\"
echo "    -configuration Debug \\"
echo "    -derivedDataPath build \\"
echo "    build"
echo ""
echo "  xcrun simctl install $DEVICE_ID \\"
echo "    build/Build/Products/Debug-iphonesimulator/PromptIQExample.app"
echo "  xcrun simctl launch $DEVICE_ID com.h9.PromptIQExample"
