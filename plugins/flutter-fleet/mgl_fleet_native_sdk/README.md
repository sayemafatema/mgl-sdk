# mgl_fleet_native_sdk

Flutter plugin for **MGL Fleet native driver SDK** — same end-to-end flows as `native-android` / `native-ios` (login OTP, forgot PIN, change PIN, invite, scan & pay, receipt share). **No Dart UI**; fullscreen native Compose / SwiftUI runs inside your app.

## Quick start (any Flutter app)

### 1. `pubspec.yaml`

```yaml
dependencies:
  mgl_fleet_native_sdk:
    path: ../mgl-sdk/plugins/flutter-fleet/mgl_fleet_native_sdk   # adjust path
```

```bash
flutter pub get
```

### 2. Dart (recommended — one call)

```dart
import 'package:mgl_fleet_native_sdk/mgl_fleet_native_sdk.dart';

final result = await MglFleetNativeSdk.openMglFleetNativeFlow(
  initialize: FleetSdkInitializeOptions(
    apiBaseUrl: 'https://your-api.example.com',
    useMock: true, // false for live driver-app APIs
    // authToken: bearer,           // optional: skip onboarding when set
    // foCompanyId: 12345,          // required for Profile → Change PIN with bearer-only
  ),
  present: FleetSdkPresentOptions(correlationId: 'job-42'),
);
print(result.event); // e.g. FLEET_FLOW_COMPLETED
```

Or split init + present:

```dart
await MglFleetNativeSdk.initialize(
  apiBaseUrl: 'https://your-api.example.com',
  useMock: true,
  foCompanyId: 12345,
);
if (await MglFleetNativeSdk.isInitialized()) {
  final result = await MglFleetNativeSdk.presentFleetFlow();
}
```

### 3. Android host setup

**MainActivity must extend `FlutterFragmentActivity`** (not `FlutterActivity`):

```kotlin
// android/app/src/main/kotlin/.../MainActivity.kt
package com.example.your_app

import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity()
```

**Use latest native SDK from monorepo** — in `android/settings.gradle.kts` (or `.gradle`):

```kotlin
// After includeBuild / plugin includes, add:
include(":fleet-sdk")
project(":fleet-sdk").projectDir =
    file("../../mgl-sdk/native-android/fleet-sdk")  // path to native-android/fleet-sdk
```

Then `flutter run` resolves `implementation project(':fleet-sdk')` from the plugin.

**Without monorepo:** publish `fleet-android` to Maven Local or Maven Central (`com.mgl.sdk:fleet-android:0.3.0`) and ensure `mavenCentral()` (+ `mavenLocal()` if needed) in `android/build.gradle`.

### 4. iOS host setup

From monorepo, CocoaPods auto-links **`MGLFleetSDK`** when the plugin podspec finds `native-ios/MGLFleetSDK`.

Otherwise add SPM to **Runner**:

- File → Add Package Dependencies → `native-ios/MGLFleetSDK` (local path or git URL)

**Camera** (scan QR): add to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera is used to scan the fuel station QR code.</string>
```

### 5. Run

```bash
flutter run
```

Mock login OTP: `123456`. Mock fleet PIN: `234567` (see native SDK / `app/page.tsx` parity).

---

## API surface (Capacitor parity)

| Method | Description |
|--------|-------------|
| `initialize` / `initializeOptions` | `apiBaseUrl`, `authToken?`, `useMock`, **`foCompanyId?`** |
| `isInitialized` | Process-level init guard |
| `presentFleetFlow` | Fullscreen native flow (requires init) |
| `openFleetNativeFlow` / `openMglFleetNativeFlow` | Init + present in one call |

## Native features (inside `presentFleetFlow`)

All UI and API calls run in native SDK — no extra Flutter code:

- Login / OTP resend / FO select / FO PIN unlock  
- **Forgot PIN** (`driverPinReset` on FO login)  
- **Profile → Change PIN** (`foCompanyId` when bearer-only)  
- Invite flow (`1c` → `1d` → `1b` → PIN setup)  
- Scan & Pay (inline QR, PIN, mock OTP, receipt + **share**)  
- Back navigation (Android back / iOS edge-swipe + Escape)

## Errors

`PlatformException.code`: `NOT_INITIALIZED`, `1003` (user cancelled), `NO_ACTIVITY`, `NO_NATIVE_SDK` (iOS — link MGLFleetSDK).

## Example app

See [`example/`](../example/) in this folder.

## Docs

- [`docs/README.NATIVE-SDK.md`](../../../docs/README.NATIVE-SDK.md)  
- [`docs/README.INTEGRATION-ANGULAR-CAPACITOR-NATIVE.md`](../../../docs/README.INTEGRATION-ANGULAR-CAPACITOR-NATIVE.md) (same init options)

## Pure-Dart legacy package

[`flutter-sdk/`](../../../flutter-sdk/) (`mgl_fleet_sdk`) is a separate Flutter-only UI. For **native parity**, use **`mgl_fleet_native_sdk`** only.
