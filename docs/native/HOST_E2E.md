# Host E2E smoke matrix (native + bridges)

Manual or CI runs: confirm **build** parity after native or bridge changes. **Live** (`useMock: false`) needs a reachable driver-app host and credentials; **mock** only needs successful compile / present flow.

| Host / artifact | Mock smoke | Live E2E |
|-----------------|------------|----------|
| Android `fleet-sdk` | `./gradlew :fleet-sdk:assembleDebug` · present flow with `useMock: true` | Set `apiBaseUrl` to driver-app base, `useMock: false` · login / invite / pairing / QR pay as environment allows |
| iOS `MGLFleetSDK` | `xcodebuild -scheme MGLFleetSDK -destination 'generic/platform=iOS Simulator' build` · present with mock | Same options as Android |
| Capacitor `@mgl/capacitor-fleet-sdk` | Plugin `npm run build`; host app `Fleet.initialize` + `presentFleetFlow` with mock | Wire `apiBaseUrl`; exercise on device/simulator |
| Flutter `mgl_fleet_native_sdk` | `flutter analyze` / run example with mock | Same `FleetSdkOptions` as native |
| React Native `@mgl/react-native-fleet-sdk` | `npm run build` in plugin | Native module calls with live base |
| Angular **`initFleetNativeSdk`** (core UI) | **`core-sdk` build** + `ng serve`; route `/fleet` — **TS core + templates**, not Maven/SPM | N/A unless embedded in Capacitor with native |

Automated subset (no device): run **`scripts/smoke-native-matrix.sh`** from repo root (requires Xcode, Android Gradle, Node; optional Flutter).

See also: **[SMOKE_WRAPPERS.md](./SMOKE_WRAPPERS.md)** (unchanged public surface).
