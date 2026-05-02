# @mgl/fleet-angular-sdk

**Native Fleet SDK for Angular** — native templates + TS core (**no WebView**). Integrate with **one initialization**: register SDK providers and merge SDK routes into your router.

---

## Initialization (recommended — standalone Angular)

Build **`core-sdk`** once (`npm install && npm run build` in **`core-sdk/`**). Install **`@mgl/fleet-core-sdk`** via **`file:`** as today. Copy **`angular-sdk/src/lib/`** into your app **or** consume this package from disk/registry.

Then:

```typescript
import { ApplicationConfig } from '@angular/core';
import { provideRouter } from '@angular/router';
import {
  initFleetNativeSdk,
} from './fleet/fleet-native-sdk'; // or '@mgl/fleet-angular-sdk' when packaged

const fleet = initFleetNativeSdk(
  {
    apiBaseUrl: environment.fleetApiUrl,
    useMock: true,
    authToken: undefined,
  },
  { path: 'fleet' }, // navigate to /fleet
);

export const appConfig: ApplicationConfig = {
  providers: [
    fleet.providers,
    provideRouter([
      ...fleet.routes,
      // …your other routes
    ]),
  ],
};
```

That single **`initFleetNativeSdk`** call supplies:

| Returned field | Where it goes |
|----------------|----------------|
| **`fleet.providers`** | App **`providers`** (`bootstrapApplication` / **`ApplicationConfig`**) |
| **`fleet.routes`** | Inside **`provideRouter([...])`** (spread first or last — your choice) |

After **`ng serve`**, open **`/fleet`** (or your chosen **`path`**). No per-screen wiring — **`FleetFlowHostComponent`** owns login → OTP/PIN → driver shell.

---

## Lower-level exports (same behaviour)

```typescript
import {
  provideFleetNativeSdk,
  fleetNativeSdkRoutes,
} from './fleet/fleet-native-sdk';

providers: [
  provideFleetNativeSdk(config),
  provideRouter([...fleetNativeSdkRoutes({ path: 'mgl-fleet' }), ...routes]),
],
```

---

## Legacy **`NgModule`**

```typescript
imports: [
  FleetModule.forRoot({
    apiBaseUrl: environment.fleetApiUrl,
    useMock: true,
  }),
],
```

You still merge **`fleetNativeSdkRoutes()`** (or **`initFleetNativeSdk(...).routes`**) into **`RouterModule.forRoot`** — **`FleetModule`** only registers providers (shell stays lazy).

---

## Production (**`useMock: false`**)

After login, set the bearer token:

```typescript
constructor(private fleet: FleetService) {}
this.fleet.setAuthToken(token);
```

---

## **`FleetSDKConfig`**

| Field | Meaning |
|-------|---------|
| **`apiBaseUrl`** | Fleet REST base URL |
| **`authToken`** | Optional Bearer token |
| **`useMock`** | **`true`** = bundled demo |

---

## Mock smoke test

Navigate to your fleet path → any **10-digit** mobile → OTP **`123456`** → PIN **`123456`** → tabs appear.

---

## Requirements

- **Node.js 20+**, **Angular 17+**, **`core-sdk`** built (**`dist/`**).

---

## Full guides

- **[`docs/README.ANGULAR-CAPACITOR.md`](../docs/README.ANGULAR-CAPACITOR.md)** — Capacitor, E2E checklist, **`file:`** paths.
- **[`docs/openapi/fleet-api.yaml`](../docs/openapi/fleet-api.yaml)** — REST contract.
