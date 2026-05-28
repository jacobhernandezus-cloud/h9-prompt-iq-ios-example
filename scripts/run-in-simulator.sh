#!/usr/bin/env bash
# Build the app, install it on the booted iPhone simulator, launch it, and
# capture a few screenshots. Idempotent and sudo-free.
#
# Usage:
#   bash scripts/run-in-simulator.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! xcrun --find xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild not found. Run scripts/finish-setup.sh first." >&2
  exit 1
fi

# Make sure the xcodeproj is up to date with project.yml.
if [[ ! -d "PromptIQExample.xcodeproj" ]] || [[ "project.yml" -nt "PromptIQExample.xcodeproj/project.pbxproj" ]]; then
  echo "→ Regenerating PromptIQExample.xcodeproj from project.yml…"
  xcodegen generate
fi

# Pick the booted iPhone simulator (or boot the newest available).
DEVICE_ID=$(xcrun simctl list devices booted --json \
  | python3 -c '
import json, sys
d = json.load(sys.stdin)["devices"]
for runtime, devs in d.items():
    if "iOS" not in runtime: continue
    for dev in devs:
        if "iPhone" in dev["name"] and dev["state"] == "Booted":
            print(dev["udid"]); sys.exit(0)
' || true)

if [[ -z "${DEVICE_ID:-}" ]]; then
  echo "→ No booted iPhone simulator; picking the newest available…"
  DEVICE_ID=$(xcrun simctl list devices available --json | python3 -c '
import json, sys
data = json.load(sys.stdin)
ios = sorted([k for k in data["devices"] if "iOS" in k and data["devices"][k]])
if not ios: sys.exit("no iOS simulators installed")
devs = data["devices"][ios[-1]]
phones = [x for x in devs if "iPhone" in x["name"]]
chosen = sorted(phones, key=lambda d: d["name"])[-1] if phones else devs[0]
print(chosen["udid"])
')
  xcrun simctl boot "$DEVICE_ID"
fi
echo "  simulator: $DEVICE_ID"
open -a Simulator

echo "→ Building PromptIQExample (Debug, iphonesimulator)…"
xcodebuild \
  -project PromptIQExample.xcodeproj \
  -scheme PromptIQExample \
  -destination "id=$DEVICE_ID" \
  -configuration Debug \
  -derivedDataPath build \
  -quiet \
  build

APP_PATH="build/Build/Products/Debug-iphonesimulator/PromptIQExample.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "Build succeeded but $APP_PATH is missing." >&2
  exit 1
fi

echo "→ Installing app on simulator…"
xcrun simctl install "$DEVICE_ID" "$APP_PATH"

echo "→ Launching com.h9.PromptIQExample…"
xcrun simctl launch "$DEVICE_ID" com.h9.PromptIQExample
sleep 4  # let the list view fetch customs + render

mkdir -p screenshots
TS=$(date +%Y-%m-%d_%H%M%S)
xcrun simctl io "$DEVICE_ID" screenshot "screenshots/01-list_${TS}.png"
echo "  saved screenshots/01-list_${TS}.png"

echo ""
echo "✓ App is running in the simulator. Open Simulator.app to interact."
echo "  Tap a prompt → detail view; tap + → new-prompt form."
echo "  Re-run this script after code changes; it rebuilds idempotently."
