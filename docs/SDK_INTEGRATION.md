# SDK integration (overview)

**New mobile work** should follow **[README.NATIVE-SDK.md](./README.NATIVE-SDK.md)** — Kotlin/Android + Swift/iOS cores with Capacitor / Flutter / React Native bridges (`initialize`, `presentFleetFlow`).

| Platform | Preferred path | Legacy / transitional |
|----------|----------------|------------------------|
| **Angular + Capacitor** | `@mgl/capacitor-fleet-sdk` + published `fleet-android` + linked `MGLFleetSDK` | `initFleetNativeSdk` + embedded `angular-sdk` routes |
| **Flutter** | `mgl_fleet_native_sdk` plugin | Pure-Dart `flutter-sdk` package |
| **React Native** | `@mgl/react-native-fleet-sdk` | N/A |
| **Headless TS** | `new FleetSDK(config)` (`@mgl/fleet-core-sdk`) | — |

REST contract: **[openapi/fleet-api.yaml](./openapi/fleet-api.yaml)**.

---

## TypeScript core (`@mgl/fleet-core-sdk`)

Used by Angular **`FleetService`** and optional non-Angular hosts.

1. Build: **`cd core-sdk && npm install && npm run build`**.
2. Install in the host app (**`file:`** path or private registry).

```typescript
import { FleetSDK } from '@mgl/fleet-core-sdk';

const sdk = new FleetSDK({
  apiBaseUrl: 'https://your-api.example',
  authToken: sessionToken,
  useMock: false,
});

sdk.on('DRIVER_UPDATED', (payload) => console.log(payload));
await sdk.getDrivers();
```

---

## Native-first bridges

See **[README.NATIVE-SDK.md](./README.NATIVE-SDK.md)**, **[RELEASE_NATIVE_SDK.md](./RELEASE_NATIVE_SDK.md)**, and **[README.MIGRATION-NATIVE-FLEET.md](./README.MIGRATION-NATIVE-FLEET.md)**.

---

## Angular + Capacitor (legacy embedded shell)

See **[README.ANGULAR-CAPACITOR.md](./README.ANGULAR-CAPACITOR.md)**.

---

## Flutter (legacy Dart UI)

See **[FLUTTER_SDK_INTEGRATION_GUIDE.md](./FLUTTER_SDK_INTEGRATION_GUIDE.md)** — manual HTTP appendix: **[flutter-integration/README.md](../flutter-integration/README.md)**.

---

## Versioning

1. Bump **`version`** in **`core-sdk/package.json`** when the public API or OpenAPI changes.
2. Regenerate or update Kotlin/Swift clients after spec edits.
3. Keep native + wrapper semver aligned per **[RELEASE_NATIVE_SDK.md](./RELEASE_NATIVE_SDK.md)**.
