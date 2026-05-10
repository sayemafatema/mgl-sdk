# Native Fleet SDK release playbook

## Contract-first

1. Update [`openapi/fleet-api.yaml`](openapi/fleet-api.yaml) if **fleet-management** REST payloads change.
2. For **driver-app** HTTP, sync [`components/mgl/driver-api.ts`](../components/mgl/driver-api.ts) ↔ native `DriverAppApiClient` ([MODEL_MAPPING.md](native/MODEL_MAPPING.md) §B). OpenAPI gap: [DRIVER_APP_OPENAPI_GAP.md](openapi/DRIVER_APP_OPENAPI_GAP.md).
3. Update parity checklist rows ([PARITY_CHECKLIST.md](native/PARITY_CHECKLIST.md)).
4. Run [`scripts/smoke-native-matrix.sh`](../scripts/smoke-native-matrix.sh).

## Versioning matrix

Keep wrapper releases aligned with native cores:

| Native Android (`fleet-android`) | Native iOS (`MGLFleetSDK`) | Capacitor `@mgl/capacitor-fleet-sdk` | Flutter `mgl_fleet_native_sdk` | RN `@mgl/react-native-fleet-sdk` |
|----------------------------------|---------------------------|--------------------------------------|-------------------------------|----------------------------------|
| `fleet-android` on Maven (`com.mgl.sdk:fleet-android`) | `MGLFleetSDK` SPM tag **0.2.x** | `@mgl/capacitor-fleet-sdk` **0.2.x** | `mgl_fleet_native_sdk` **0.2.x** | `@mgl/react-native-fleet-sdk` **0.2.x** |

Document incompatible bumps in **`CHANGELOG.md`** per package.

## Publish steps

Operator checklist (Maven Central signing, npm OTP, CocoaPods trunk, pub.dev): **[`PUBLISH_FOR_EXTERNAL_CONSUMERS.md`](PUBLISH_FOR_EXTERNAL_CONSUMERS.md)**.

Short summary:

1. Ship **`fleet-android`** (`com.mgl.sdk:fleet-android`) — Gradle **`publishReleasePublicationToMavenLocalRepository`** / OSSRH / Central Portal bundle under **`fleet-sdk/build/staging-deploy/`**.
2. Tag the Git repo (**e.g.** **`0.2.0`**) so SPM consumers resolve root **`Package.swift`**; align CocoaPods **`MGLFleetSDK.podspec`** `:tag` if publishing to trunk.
3. **`npm publish`** **`@mgl/capacitor-fleet-sdk`** + **`@mgl/react-native-fleet-sdk`** after **`npm run build`**.
4. **`dart pub publish`** **`mgl_fleet_native_sdk`** when **`publish_to`** allows.

## QA gates

- Run **`native-android/sample-host`** smoke (`presentFleetFlow`).
- Xcode workspace importing SPM **`MGLFleetSDK`** smoke (`presentFleetFlow`).
- Bridge smoke tests per stack (`initialize` → `presentFleetFlow`).
