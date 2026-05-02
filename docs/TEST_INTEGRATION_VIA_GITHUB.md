# End-to-end SDK integration test via GitHub (no npm / Maven Central required)

Use this when a **reviewer’s machine** should run **`initialize` → `presentFleetFlow`** without publishing to Maven Central, npm, CocoaPods trunk, or pub.dev.

---

## A. Maintainer (you)

1. Push **`mgl-sdk`** to GitHub (**private** repo is fine).
2. Invite the tester (**Settings → Collaborators**) or give them read access via team/org.
3. Tell them which branch/tag to use (e.g. **`main`**).

Optional: tag a release candidate (**`v0.1.0-rc1`**) so SPM pins easily—still **Git only**, no registry.

---

## B. Tester (their machine)

### Prerequisites

| Stack | Needs |
|-------|--------|
| Android | JDK **17**, Android SDK, Android Studio or CLI tools |
| iOS | macOS + **Xcode** |
| JS bridges | **Node.js** **≥ 14.17** (20 LTS recommended) |
| Flutter | **Flutter SDK** **≥ 3.16** if testing Flutter |

---

### 1. Clone

```bash
git clone git@github.com:YOUR_ORG/mgl-sdk.git
cd mgl-sdk
git checkout main   # or the branch you were given
```

---

### 2. Publish Android library to Maven Local (required for bridges)

Gradle wrapper: if **`native-android/gradlew`** is missing, generate once (see **`docs/PUBLISH_FOR_EXTERNAL_CONSUMERS.md`** bootstrap snippet) or open **`native-android`** in Android Studio and sync.

```bash
cd native-android
chmod +x gradlew 2>/dev/null || true
./gradlew :fleet-sdk:publishReleasePublicationToMavenLocalRepository
```

This installs **`com.mgl.sdk:fleet-android`** at the version in **`native-android/gradle.properties`** (**`fleetAndroid.version`**).

---

### 3. Pick one host path

#### Option 1 — Angular + Capacitor (existing host app)

From **their Capacitor app root** (not inside `mgl-sdk`):

```bash
npm install /absolute/path/to/mgl-sdk/plugins/capacitor-fleet
# or: npm install file:../../mgl-sdk/plugins/capacitor-fleet
cd node_modules/@mgl/capacitor-fleet-sdk && npm ci && npm run build && cd -
```

Ensure **`android/`** Gradle repos include **`mavenLocal()`** until **`fleet-android`** is on Maven Central (the plugin **already lists it**; add at **project root** if Gradle still fails to resolve).

```bash
npx cap sync
```

**iOS:** Xcode → **App** target → **Package Dependencies** → **Add Local…** → choose **`mgl-sdk/native-ios/MGLFleetSDK`**,  
**or** add **`https://github.com/YOUR_ORG/mgl-sdk.git`** with rule **branch / tag** (uses root **`Package.swift`**).

Then follow **`docs/README.INTEGRATION-ANGULAR-CAPACITOR-NATIVE.md`** (**`initialize`** once, **`presentFleetFlow`** from UI).

#### Option 2 — Flutter host app

In **`pubspec.yaml`**:

```yaml
dependencies:
  mgl_fleet_native_sdk:
    path: /absolute/path/to/mgl-sdk/plugins/flutter-fleet/mgl_fleet_native_sdk
```

Run **`flutter pub get`**. Android uses **`mavenLocal()`** same as §2.  
**iOS:** link **`MGLFleetSDK`** via local folder or Git URL as in Option 1.

Call **`MglFleetNativeSdk.initialize`** then **`presentFleetFlow`** per **`docs/README.NATIVE-SDK.md`**.

#### Option 3 — React Native host app

```bash
npm install /absolute/path/to/mgl-sdk/plugins/react-native-fleet
cd node_modules/@mgl/react-native-fleet-sdk && npm ci && npm run build && cd -
```

Register **`MglFleetSdkPackage`** in **`MainApplication`** (Android).  
**iOS:** SPM link **`MGLFleetSDK`** like Option 1.

---

### 4. Run on device/emulator

**Android**

```bash
npx cap run android          # Capacitor
# or flutter run / npx react-native run-android
```

**iOS**

```bash
npx cap run ios              # Capacitor
# or flutter run / npx react-native run-ios
```

---

### 5. Success criteria

- **`initialize`** completes without native errors.
- **`presentFleetFlow`** opens the fullscreen Fleet UI and returns **`event` / `payload`** or a documented error code (see **`docs/README.NATIVE-SDK.md`** §6).

---

## Troubleshooting

| Issue | Action |
|-------|--------|
| Cannot resolve **`fleet-android`** | Re-run §2; confirm **`mavenLocal()`** on consuming Gradle; version matches **`gradle.properties`**. |
| iOS **`NO_NATIVE_SDK`** / **`canImport`** | **`MGLFleetSDK`** not linked to **App** / **Runner** target—repeat SPM steps. |
| Capacitor TS errors | **`npm run build`** inside **`plugins/capacitor-fleet`** so **`dist/`** exists. |

---

## Related

- **[README.NATIVE-SDK.md](README.NATIVE-SDK.md)** — full integration surface.
- **[README.INTEGRATION-ANGULAR-CAPACITOR-NATIVE.md](README.INTEGRATION-ANGULAR-CAPACITOR-NATIVE.md)** — Angular + Capacitor detail.
