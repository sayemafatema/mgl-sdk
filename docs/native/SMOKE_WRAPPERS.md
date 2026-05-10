# Wrapper smoke — frozen public surface

Bridges must keep these entrypoints **additive-only** (same names and option shapes) unless a major semver is planned.

## Android (`com.mgl.fleet.sdk`)

| API | Notes |
|-----|--------|
| `FleetSdk.initialize(options: FleetSdkOptions)` | `apiBaseUrl`, `authToken`, `useMock` |
| `FleetSdk.presentFleetFlow(activity, session?, callback)` | Modal fullscreen flow |
| `FleetSdk.isInitialized()` | — |

## iOS (`MGLFleetSDK`)

| API | Notes |
|-----|--------|
| `FleetSdk.shared.initialize(options:)` | Same fields as Android |
| `FleetSdk.shared.presentFleetFlow(from:session:completion:)` | — |
| `FleetSdk.shared.isInitialized()` | — |

## Capacitor (`@mgl/capacitor-fleet-sdk`)

Thin JS → native: same initialize + present semantics as native; see plugin `README.md`.

## Flutter (`mgl_fleet_native_sdk`)

Plugin method channel mirrors native options; **do not** rename platform method names without coordinated major bump.

## React Native (`@mgl/react-native-fleet-sdk`)

Same contract as Capacitor-style bridge; verify after native AAR / framework updates.

## Smoke checklist (per release)

1. Bump **[VERSIONS.md](../VERSIONS.md)** and aligned Gradle / podspec / npm / pub versions together.
2. Run **`scripts/smoke-native-matrix.sh`** (build-only).
3. One manual **mock** present on Android + iOS (or Capacitor host).
