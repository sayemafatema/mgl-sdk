# Capacitor Fleet demo (local testing)

Minimal host to exercise **`openMglFleetNativeFlow`** the same way a real Capacitor app does.

## Requirements

- **Node.js 18+** (Capacitor 6 CLI refuses older runtimes.)
- **Android:** Android SDK — set **`ANDROID_HOME`** or create **`native-android/local.properties`** with `sdk.dir=…`
- **iOS:** Xcode, and add local Swift package **`native-ios/MGLFleetSDK`** to the **App** target after sync (see main integration doc).

## 1 — Publish `fleet-android` to Maven Local

```bash
cd native-android
./gradlew :fleet-sdk:publishToMavenLocal --no-daemon
```

## 2 — Build web bundle & sync Capacitor

First time only (Node 18+):

```bash
cd examples/capacitor-fleet-demo
npm install
npx cap add android
npx cap add ios   # macOS only
```

Every change to JS or the plugin:

```bash
npm run build              # bundles TS → dist/main.js
npm run cap:sync           # or: npm run build && npx cap sync
```

If **`fleet-android`** is not in Maven Local, Android Gradle will fail until step 1 completes.

### Android: `mavenLocal()` for plugins

If **`com.mgl.sdk:fleet-android`** still does not resolve, add **`mavenLocal()`** to the **root** **`android`** `dependencyResolutionManagement { repositories { … } }` block (Capacitor 8-style templates), then sync again.

## 3 — Run on device or emulator

```bash
npm run cap:android
# or
npm run cap:ios
```

Tap **Open Fleet (native)**. In Logcat / Safari Web Inspector you should see **`[MGL Fleet]`** log lines before the fullscreen UI appears.

---

**Pure native Android (no Capacitor, no Node 18 for CLI):** open **`native-android`** in Android Studio and run the **`sample-host`** app (`com.mgl.fleet.samplehost`).
