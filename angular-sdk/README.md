# @mgl/fleet-angular-sdk

Angular bindings for `@mgl/fleet-core-sdk`. Templates only — **no WebView**.

## Seamless integration (entire flow)

**`FleetModule.forRoot`** + **one lazy-loaded `FleetShellModule`** route is enough: **`FleetFlowHostComponent`** hosts **every** bundled step (login/signup → OTP/PIN → main shell). You do **not** register separate routes or components per SDK screen.

Import **`FleetModule.forRoot`** once, lazy-load **`FleetShellModule`**. Users land on **mobile login / signup**, then OTP / PIN, then the **driver shell** (tabs, overlays, scan demo).

```typescript
// AppModule (or standalone bootstrap providers)
imports: [
  FleetModule.forRoot({
    apiBaseUrl: environment.fleetApiUrl,
    useMock: true,
  }),
],

// app.routes.ts — route path is yours
{
  path: 'fleet',
  loadChildren: () =>
    import('@mgl/fleet-angular-sdk').then((m) => m.FleetShellModule),
},
```

Navigate to `/fleet`. Optional dev shortcut: **`skipToMainApp`** is exposed from the core engine for QA.

Inject **`FleetService`** for **`FleetSDK`** (`raw()`, RxJS helpers).

Full **integration steps**, **mock-mode E2E test checklist**, Capacitor notes, **another developer's machine** (clone / zip / registry), and **whether GitHub is required**: **[docs/README.ANGULAR-CAPACITOR.md](../docs/README.ANGULAR-CAPACITOR.md)**.

## Setup

1. `cd ../core-sdk && npm install && npm run build`
2. Copy **`angular-sdk/src/lib/**`** into your Angular library or depend on this package with **`file:`**.
3. Peer deps: **`@angular/common`**, **`@angular/core`**, **`rxjs`**.
