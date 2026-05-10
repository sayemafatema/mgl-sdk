# Fleet cross-platform SDK

This repository contains:

| Package | Role |
|---------|------|
| [native-android/](native-android/) | **Kotlin/Android library** (`fleet-android`) — `FleetSdk.initialize`, `FleetSdk.presentFleetFlow`. |
| [native-ios/MGLFleetSDK](native-ios/MGLFleetSDK/) | **Swift/iOS package** (`MGLFleetSDK`) — same lifecycle surface as Android. |
| [plugins/capacitor-fleet/](plugins/capacitor-fleet/) | **Capacitor** npm bridge (`@mgl/capacitor-fleet-sdk`). |
| [plugins/flutter-fleet/mgl_fleet_native_sdk/](plugins/flutter-fleet/mgl_fleet_native_sdk/) | **Flutter** plugin (Maven-backed Android `.aar`). |
| [plugins/react-native-fleet/](plugins/react-native-fleet/) | **React Native** npm bridge (`@mgl/react-native-fleet-sdk`). |
| [core-sdk](./core-sdk/) | Headless **TypeScript** `FleetSDK`. |
| [angular-sdk](./angular-sdk/) | Legacy Angular UI shell — prefer Capacitor bridge + native cores for new apps. |
| [flutter-sdk](./flutter-sdk/) | Legacy pure-Dart UI — prefer `mgl_fleet_native_sdk` for native-backed flows. |
| [docs/openapi/fleet-api.yaml](./openapi/fleet-api.yaml) | Shared HTTP contract for **all** stacks. |

## Native-first integration (recommended)

**[README.NATIVE-SDK.md](./README.NATIVE-SDK.md)** — Maven Central **`fleet-android`**, SPM **`MGLFleetSDK`**, npm/pub bridges (**`initialize` / `presentFleetFlow`**).

- Maintainer publishing: **[PUBLISH_FOR_EXTERNAL_CONSUMERS.md](./PUBLISH_FOR_EXTERNAL_CONSUMERS.md)** · pinned versions **[VERSIONS.md](./VERSIONS.md)**
- Build smoke script: **`scripts/smoke-native-matrix.sh`** · matrix **[native/HOST_E2E.md](./native/HOST_E2E.md)** · wrapper surface **[native/SMOKE_WRAPPERS.md](./native/SMOKE_WRAPPERS.md)**
- Migration from legacy shells: **[README.MIGRATION-NATIVE-FLEET.md](./README.MIGRATION-NATIVE-FLEET.md)**
- Release playbook: **[RELEASE_NATIVE_SDK.md](./RELEASE_NATIVE_SDK.md)**

## Build core SDK

```bash
cd core-sdk && npm install && npm run build
```

Consumers import **`FleetSDK`** from **`@mgl/fleet-core-sdk`** when using the headless TS layer only.

## Events (core)

Core emits string events suitable for logging or bridging:

- `DRIVER_UPDATED`
- `DRIVERS_REFRESHED`
- `SESSION_READY` (after `setAuthToken`)
- `ERROR`

## Legacy Angular / Flutter hosts

The core SDK uses **fetch** only — safe inside Capacitor’s Angular bundle.

- **Angular:** **`initFleetNativeSdk`** + **`provideRouter`** → [README.ANGULAR-CAPACITOR.md](./README.ANGULAR-CAPACITOR.md)
- **Flutter:** **`FleetNativeSdk`** → [README.FLUTTER.md](./README.FLUTTER.md)

## Integration guides

- **[README.NATIVE-SDK.md](./README.NATIVE-SDK.md)** — native cores + bridges (**preferred**).
- **[Angular + Capacitor](./README.ANGULAR-CAPACITOR.md)** — embedded Angular shell route pattern.
- **[Flutter](./README.FLUTTER.md)** — pure-Dart SDK package pattern.

## Further reading

- [native/HOST_E2E.md](./native/HOST_E2E.md) — host/device smoke matrix · `scripts/smoke-native-matrix.sh`
- [native/SMOKE_WRAPPERS.md](./native/SMOKE_WRAPPERS.md) — unchanged `initialize` / `presentFleetFlow` surface
- [openapi/DRIVER_APP_OPENAPI_GAP.md](./openapi/DRIVER_APP_OPENAPI_GAP.md) — driver-app vs fleet OpenAPI scope
