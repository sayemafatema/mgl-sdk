# MGL Fleet native-first SDK

Cross-framework integration centers on **Kotlin/Android** and **Swift/iOS** libraries; Angular (Capacitor), Flutter, and React Native consume **thin bridges** with the same logical API:

| Step | JS / Dart API | Native behaviour |
|------|----------------|------------------|
| 1 | `initialize({ apiBaseUrl, authToken?, useMock? })` | Stores config + validates prerequisites |
| 2 | `presentFleetFlow({ correlationId? })` | Full-screen native shell (`FleetSdkActivity` / `FleetSdkViewController`) |

Public HTTP contract (DTO parity): [`openapi/fleet-api.yaml`](openapi/fleet-api.yaml).  
Screen parity checklist: [`native/PARITY_CHECKLIST.md`](native/PARITY_CHECKLIST.md).  
DTO mapping notes: [`native/MODEL_MAPPING.md`](native/MODEL_MAPPING.md).

---

## 1. Android artifact (`fleet-android`)

**Published coordinate:** **`com.mgl.sdk:fleet-android`** — version **[`VERSIONS.md`](VERSIONS.md)**.

Integrators resolve **Maven Central** (after you publish — **[`PUBLISH_FOR_EXTERNAL_CONSUMERS.md`](PUBLISH_FOR_EXTERNAL_CONSUMERS.md)**):

```gradle
repositories {
    google()
    mavenCentral()
}

dependencies {
    implementation 'com.mgl.sdk:fleet-android:0.3.0'
}
```

While iterating privately, publish to **Maven Local** (`./gradlew :fleet-sdk:publishToMavenLocal`) and add **`mavenLocal()`** to repositories — see [`native-android/README.md`](../native-android/README.md).

Sample host [`sample-host`](../native-android/sample-host) uses **`project(":fleet-sdk")`** instead of Maven coordinates.

---

## 2. iOS Swift package (`MGLFleetSDK`)

Sources live under [`native-ios/MGLFleetSDK/`](../native-ios/MGLFleetSDK/).

**Swift Package Manager:** This repo includes a root **[`Package.swift`](../Package.swift)** so consumers can depend on **your Git URL** (replace **`YOUR_ORG`** after publishing):

```swift
.package(url: "https://github.com/YOUR_ORG/mgl-sdk.git", from: "0.3.0")
```

Link library product **`MGLFleetSDK`** to the host **App** target.  
For local dev you can still use **File → Add Local Packages…** → **`native-ios/MGLFleetSDK`**.

**CocoaPods:** [`MGLFleetSDK.podspec`](../native-ios/MGLFleetSDK/MGLFleetSDK.podspec) — `source_files` and `LICENSE` are relative to the **`native-ios/MGLFleetSDK`** directory (matches `pod …, :path => '…/MGLFleetSDK'` or the same path inside a git checkout). See **[`PUBLISH_FOR_EXTERNAL_CONSUMERS.md`](PUBLISH_FOR_EXTERNAL_CONSUMERS.md)**.

```bash
swift build              # from repo root (uses root Package.swift)
# or
swift build --package-path native-ios/MGLFleetSDK
```

Capacitor / Flutter hosts must link **`MGLFleetSDK`** before `#if canImport(MGLFleetSDK)` in bridge Swift activates.

Flutter iOS [`MglFleetNativeSdkPlugin.swift`](../plugins/flutter-fleet/mgl_fleet_native_sdk/ios/Classes/MglFleetNativeSdkPlugin.swift) mirrors Capacitor: after **`MGLFleetSDK`** is linked to **`Runner`**, **`initialize`** / **`presentFleetFlow`** route into **`FleetSdk.shared`**; otherwise **`NO_NATIVE_SDK`**.

---

## 3. Angular + Capacitor (`@mgl/capacitor-fleet-sdk`)

**Step-by-step Angular + Capacitor host setup:** [`README.INTEGRATION-ANGULAR-CAPACITOR-NATIVE.md`](README.INTEGRATION-ANGULAR-CAPACITOR-NATIVE.md) (`initialize` vs `presentFleetFlow`, Maven / SPM, `cap sync`).

Package path: [`plugins/capacitor-fleet/`](../plugins/capacitor-fleet/).

```bash
cd plugins/capacitor-fleet
npm install
npm run build        # emits dist/*.js TypeScript facade
```

Wire plugin via **`npm install @mgl/capacitor-fleet-sdk`** (after publish) or **`npm install ../path/to/capacitor-fleet`**, then **`npx cap sync`**.

```typescript
import { MGLFleetSdk } from '@mgl/capacitor-fleet-sdk';

await MGLFleetSdk.initialize({ apiBaseUrl: 'https://api.example.com', useMock: true });
const result = await MGLFleetSdk.presentFleetFlow({ correlationId: 'checkout-42' });
console.log(result.event, result.payload);
```

Android must resolve **`com.mgl.sdk:fleet-android`** from **Maven Central** (published build). During SDK development only, use **Maven Local** (§1).

---

## 4. Flutter (`mgl_fleet_native_sdk`)

Package path: [`plugins/flutter-fleet/mgl_fleet_native_sdk/`](../plugins/flutter-fleet/mgl_fleet_native_sdk/).  
Full guide: [`plugins/flutter-fleet/mgl_fleet_native_sdk/README.md`](../plugins/flutter-fleet/mgl_fleet_native_sdk/README.md).

```yaml
dependencies:
  mgl_fleet_native_sdk:
    path: ../mgl-sdk/plugins/flutter-fleet/mgl_fleet_native_sdk
```

```dart
import 'package:mgl_fleet_native_sdk/mgl_fleet_native_sdk.dart';

// Recommended: init + present in one native bridge call
final result = await MglFleetNativeSdk.openMglFleetNativeFlow(
  initialize: FleetSdkInitializeOptions(
    apiBaseUrl: 'https://api.example.com',
    useMock: true,
    authToken: bearer,       // optional
    foCompanyId: 12345,      // Profile → Change PIN when bearer-only
  ),
  present: FleetSdkPresentOptions(correlationId: 'job-9'),
);
```

**Android:** `MainActivity` must extend **`FlutterFragmentActivity`**. For latest native UI from this repo, include `:fleet-sdk` in host `settings.gradle` (see plugin README). Otherwise **`com.mgl.sdk:fleet-android`** from Maven Central / Local (§1).  
**iOS:** **`MGLFleetSDK`** on Runner (SPM or CocoaPods); monorepo path dependency auto-links via plugin podspec. Add **`NSCameraUsageDescription`** for scan QR.

All driver flows (OTP, forgot/change PIN, invite, scan, receipt share) run in **native UI** — same as Capacitor §3.

---

## 5. React Native (`@mgl/react-native-fleet-sdk`)

Package path: [`plugins/react-native-fleet/`](../plugins/react-native-fleet/).

```bash
cd plugins/react-native-fleet
npm install && npm run build   # emits lib/
```

Install from **`npm`** / path in your RN app; register **`MglFleetSdkPackage`** on Android (**`MainApplication`**) when autolinking doesn’t; **`pod install`** on iOS. Android resolves **`fleet-android`** from **Maven Central** (§1), or **`mavenLocal()`** during SDK development.  
**iOS:** link **`MGLFleetSDK`** SPM to the host app ([**`plugins/react-native-fleet/ios`**](../plugins/react-native-fleet/ios) + **`MglFleetSdk.podspec`**) — see [**`plugins/react-native-fleet/README.md`**](../plugins/react-native-fleet/README.md).

```typescript
import {
  fleetSdkInitialize,
  fleetSdkPresentFleetFlow,
} from '@mgl/react-native-fleet-sdk';

await fleetSdkInitialize({ apiBaseUrl: 'https://api.example.com', useMock: true });
const result = await fleetSdkPresentFleetFlow({ correlationId: 'trip-77' });
```

---

## 6. Completion semantics & built-in error codes

Successful **`presentFleetFlow`** resolves with **`{ event: string; payload: Record<string, unknown> }`** (aligned across bridges).

Native **`FleetSdkError`** codes surfaced as rejection / **`FlutterError`** / **`PlatformException`** **`code`**:

| Code | Meaning |
|------|---------|
| 1001 | Invalid input |
| 1002 | SDK not initialized |
| 1003 | User cancelled flow |
| 1004 | Internal SDK error |
| 1005 | Permission denied |
| 1007 | Network / HTTP failure |

---

## 7. Events (native emission)

Both cores emit **`FLOW_STARTED`** when UI attaches; extend [`FleetPresentationBridge`](../native-android/fleet-sdk/src/main/java/com/mgl/fleet/sdk/internal/FleetPresentationBridge.kt) / Swift counterpart as parity grows.

---

## 8. Distribution checklist

| Artifact | Channel |
|----------|---------|
| `fleet-android` | Maven Central / private Maven (`com.mgl.sdk:fleet-android`) |
| `MGLFleetSDK` | CocoaPods spec / SPM Git tag |
| `@mgl/capacitor-fleet-sdk` | npm |
| `mgl_fleet_native_sdk` | pub.dev (publish federated plugin + pin native artifact versions) |
| `@mgl/react-native-fleet-sdk` | npm |

Keep wrapper semver aligned — see [`RELEASE_NATIVE_SDK.md`](RELEASE_NATIVE_SDK.md). Maintainer checklist: **[`PUBLISH_FOR_EXTERNAL_CONSUMERS.md`](PUBLISH_FOR_EXTERNAL_CONSUMERS.md)** · pinned rows: **[`VERSIONS.md`](VERSIONS.md)**.

---

## 9. Further reading

- [Test integration on another machine via GitHub (no registries)](TEST_INTEGRATION_VIA_GITHUB.md)
- [Publishing for external consumers](PUBLISH_FOR_EXTERNAL_CONSUMERS.md)
- [Angular + Capacitor integration (step-by-step)](README.INTEGRATION-ANGULAR-CAPACITOR-NATIVE.md)
- [Migration from Dart/Angular-only SDKs](README.MIGRATION-NATIVE-FLEET.md)
- [Release playbook](RELEASE_NATIVE_SDK.md)
