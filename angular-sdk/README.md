# @mgl/fleet-angular-sdk

Angular UI for the MGL Fleet driver flow (**templates only — no WebView**). One lazy route loads the **entire** journey: login / signup → OTP / PIN → driver shell (tabs, overlays, scan demo).

---

## What you add (two things)

| # | In your app | Purpose |
|---|-------------|---------|
| 1 | **`FleetModule.forRoot({ … })`** once at bootstrap | Config + **`FleetService`** (wraps **`FleetSDK`**) |
| 2 | **One lazy route** → **`FleetShellModule`** | Mounts **`FleetFlowHostComponent`** for every bundled screen |

You **do not** register separate routes per SDK screen.

---

## Prerequisites

- **Node.js 20+** (build tooling for core SDK).
- **Angular 17+** (same majors as peer deps).
- **npm** (or yarn/pnpm — keep **one** lockfile at your app root; remove stray **`pnpm-lock.yaml`** if you use npm-only).

---

## Integration (copy in order)

### 1 — Build the TypeScript core SDK

From your clone of **`mgl-sdk`**:

```bash
cd core-sdk
npm install
npm run build
```

You should see **`core-sdk/dist/`** after this step. Your Angular app talks to **`@mgl/fleet-core-sdk`** from that build.

---

### 2 — Wire **`@mgl/fleet-core-sdk`** into your Angular app

In your host app **`package.json`**:

```json
{
  "dependencies": {
    "@mgl/fleet-core-sdk": "file:../mgl-sdk/core-sdk"
  }
}
```

Adjust **`file:`** so it resolves from **your** app folder (examples):

| Your app lives at | Typical `file:` value |
|-------------------|------------------------|
| Next to **`mgl-sdk`** | **`file:../mgl-sdk/core-sdk`** |
| Inside **`vendor/`** beside **`mgl-sdk`** | **`file:../../mgl-sdk/core-sdk`** |

Then:

```bash
npm install
```

---

### 3 — Add the Angular SDK sources

Copy **`angular-sdk/src/lib/`** from **`mgl-sdk`** into your project (pick one layout):

| Layout | Copy into |
|--------|-----------|
| Feature folder | **`src/app/fleet/`** (you’ll import `./fleet/fleet.module`, etc.) |
| Nx / workspace lib | **`libs/fleet-sdk/src/lib/`** (match your **`tsconfig`** paths) |

Keep the **`src/lib`** file structure so imports between SDK files stay valid.

Imports inside those files use **`@mgl/fleet-core-sdk`** — already correct once step **2** works.

---

### 4 — Register **`FleetModule.forRoot`** (once)

**NgModule app:**

```typescript
import { FleetModule } from './fleet/fleet.module'; // path = where you copied step 3

@NgModule({
  imports: [
    FleetModule.forRoot({
      apiBaseUrl: environment.fleetApiUrl,
      authToken: undefined,
      useMock: true, // false when your backend is ready
    }),
    // …your other imports
  ],
})
export class AppModule {}
```

**Standalone bootstrap** (`app.config.ts` / `main.ts`): use **`importProvidersFrom`**:

```typescript
import { importProvidersFrom } from '@angular/core';
import { FleetModule } from './fleet/fleet.module';

export const appConfig = {
  providers: [
    importProvidersFrom(
      FleetModule.forRoot({
        apiBaseUrl: environment.fleetApiUrl,
        useMock: true,
      }),
    ),
    // …
  ],
};
```

**Config shape** (`FleetSDKConfig`):

| Field | Meaning |
|-------|---------|
| **`apiBaseUrl`** | Base URL for fleet REST API |
| **`authToken`** | Optional Bearer token (**set after login** when **`useMock: false`**) |
| **`useMock`** | **`true`** = bundled demo data, no backend |

---

### 5 — Lazy-load **`FleetShellModule`** (one route)

```typescript
{
  path: 'fleet',
  loadChildren: () =>
    import('./fleet/fleet-shell.module').then((m) => m.FleetShellModule),
},
```

Change **`./fleet/…`** to match your copy location from step **3**.

Navigate once:

```typescript
this.router.navigate(['/fleet']);
```

Default shell child route **`''`** renders **`FleetFlowHostComponent`** — the full flow.

---

### 6 — Production auth (**`useMock: false`**)

After your host (or SDK flow) obtains a token:

```typescript
constructor(private fleet: FleetService) {}

someLoginHandler(token: string) {
  this.fleet.setAuthToken(token);
}
```

Inject **`FleetService`** from **`./fleet/fleet.service`** (or your copy path). Use **`FleetService.raw()`** if you need direct **`FleetSDK`** access.

---

## Quick checklist before `ng serve`

- [ ] **`core-sdk`** built (**`dist/`** exists).
- [ ] **`@mgl/fleet-core-sdk`** resolves (**`npm install`** succeeds).
- [ ] **`FleetModule.forRoot`** is registered at root.
- [ ] Lazy route loads **`FleetShellModule`** (path matches copied folder).
- [ ] **`useMock: true`** for local demo without API.

---

## Mock-mode smoke test

1. Run **`ng serve`** (or Capacitor dev build).
2. Open **`/fleet`** (or whatever path you chose).
3. Login: any **10-digit** mobile → OTP **`123456`** → PIN **`123456`** → driver shell tabs appear.
4. Optional invite path: invite **`ABC123`** / **`XYZ789`** (see full checklist in docs).

---

## Capacitor / device notes

- Use a **reachable HTTPS** **`apiBaseUrl`** on real devices (not only **`localhost`** unless proxied).
- Configure **CORS** for WebView origins (**`capacitor://localhost`**, etc.).
- After web build: **`npx cap sync`**.

---

## Exports (when importing from copied **`src/lib`**)

From **`public-api`** equivalents:

- **`FleetModule`**, **`FleetShellModule`**, **`FLEET_SHELL_ROUTES`**
- **`FleetFlowHostComponent`**, **`FleetService`**, **`FLEET_SDK_CONFIG`**

---

## More detail

- Long-form guide (E2E checklist, teammate setup, **`file:`** vs zip vs registry): **[`docs/README.ANGULAR-CAPACITOR.md`](../docs/README.ANGULAR-CAPACITOR.md)**
- REST contract: **[`docs/openapi/fleet-api.yaml`](../docs/openapi/fleet-api.yaml)**
