#!/usr/bin/env bash
# Build-only smoke: native cores + JS/RN plugin compile. Run from repo root.
# Optional: set SKIP_FLUTTER=1 if Flutter SDK is not installed.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "== Android :fleet-sdk:compileDebugKotlin =="
cd native-android
./gradlew :fleet-sdk:compileDebugKotlin --no-daemon -q

echo "== iOS MGLFleetSDK (Simulator) =="
cd "$ROOT/native-ios/MGLFleetSDK"
xcodebuild -scheme MGLFleetSDK -destination 'generic/platform=iOS Simulator' -quiet build

echo "== Capacitor plugin build =="
cd "$ROOT/plugins/capacitor-fleet"
npm run build

echo "== React Native plugin build =="
cd "$ROOT/plugins/react-native-fleet"
npm run build

if [[ "${SKIP_FLUTTER:-}" != "1" ]] && command -v flutter >/dev/null 2>&1; then
  echo "== Flutter plugin analyze =="
  cd "$ROOT/plugins/flutter-fleet/mgl_fleet_native_sdk"
  flutter pub get
  flutter analyze
else
  echo "== Flutter (skipped: set SKIP_FLUTTER=1 or install flutter) =="
fi

echo "OK smoke-native-matrix"
