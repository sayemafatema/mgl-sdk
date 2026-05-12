# Changelog — MGL Fleet SDK (monorepo)

All notable changes are tracked here by release train. Per-package npm/pub releases may duplicate entries.

## [0.3.0] — native parity program (state map, QR camera, API)

### Added

- [`docs/native/REACT_PARITY_STATE_MAP.md`](docs/native/REACT_PARITY_STATE_MAP.md): React `page.tsx` state + driver-app endpoint matrix for Kotlin/Swift parity.
- Android **`driverGetBalance`** in [`DriverAppApiClient.kt`](native-android/fleet-sdk/src/main/java/com/mgl/fleet/sdk/internal/DriverAppApiClient.kt); iOS equivalent in **`DriverAppApiClient.swift`**.
- **`FleetBarcodeScannerOverlay`**: CameraX + ML Kit QR → Fleetpay URI; Scan tab **`Scan QR with camera`** ([`FleetBarcodeScannerOverlay.kt`](native-android/fleet-sdk/src/main/java/com/mgl/fleet/sdk/demo/ui/FleetBarcodeScannerOverlay.kt)); manifest **`CAMERA`** permission — host docs should mention usage rationale.
- iOS **`FleetPayQrCameraSheet`** + Transactions tab (`mainTab`) + **`Scan QR with camera`** in [`FleetDriverNativeView.swift`](native-ios/MGLFleetSDK/Sources/MGLFleetSDK/FleetDriverNativeView.swift); embedder **`Info.plist`**: **`NSCameraUsageDescription`**.

### Changed

- Modularized Compose shells: **`FleetDriverScreens.kt`** + slim [`FleetDriverComposeApp.kt`](native-android/fleet-sdk/src/main/java/com/mgl/fleet/sdk/demo/ui/FleetDriverComposeApp.kt); Bottom nav exposes **Transactions** like React `activeTab`.
- Smoke matrix: **`angular-sdk`** `tsc --noEmit`; artifact train **0.3.0** ([`VERSIONS.md`](docs/VERSIONS.md)).

[0.3.0]: https://github.com/YOUR_ORG/mgl-sdk/releases/tag/v0.3.0

## [0.2.0] — publish train aligned with `fleet-android` / native bridges

### Changed

- Monorepo npm packages and Flutter `mgl_fleet_sdk` example package versions aligned to **0.2.0** with Capacitor / React Native / Android / iOS artifacts.

[0.2.0]: https://github.com/YOUR_ORG/mgl-sdk/releases/tag/v0.2.0

## [0.1.0] — initial publish train

### Added

- **`fleet-android`** (`com.mgl.sdk:fleet-android`) library with `FleetSdk.initialize` / `presentFleetFlow`.
- **`MGLFleetSDK`** Swift package + CocoaPods podspec.
- Bridges: **`@mgl/capacitor-fleet-sdk`**, **`@mgl/react-native-fleet-sdk`**, **`mgl_fleet_native_sdk`** Flutter plugin.
- Maintainer docs: **`docs/PUBLISH_FOR_EXTERNAL_CONSUMERS.md`**, **`docs/VERSIONS.md`**.

[0.1.0]: https://github.com/YOUR_ORG/mgl-sdk/releases/tag/v0.1.0
