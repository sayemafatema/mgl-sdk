# Integrating with Angular + Capacitor

This guide explains **how your Angular app connects to the fleet SDK** and how to integrate **the whole fleet UI flow in one shot** (mobile login / invite signup → OTP / PIN → driver shell with tabs, overlays, and scan demo).

---

## Seamless integration (entire flow, one initialization)

Two registrations cover the UI flow—nothing else is required for the bundled screens:

1. **`FleetModule.forRoot({ apiBaseUrl, useMock, … })`** once in your root **`NgModule`** (or equivalent standalone providers).
2. **One lazy route** that loads **`FleetShellModule`**, whose default child is **`FleetFlowHostComponent`**.

After that, navigate to your fleet URL (for example **`/mgl-fleet`**). **Do not** declare or lazy-load separate SDK routes per auth step or tab—the host component owns the full journey.

For production APIs, keep **`useMock: false`** and set **`FleetService.setAuthToken`** when your host finishes real authentication.

---

## How the connection works

| Layer | What runs where | Role |
|--------|-----------------|------|
| **Fleet UI shell** | Same Angular bundle as your app (`FleetShellModule`) | **`FleetFlowHostComponent`** covers auth + main app — **you do not wire each screen manually**. |
| **`@mgl/fleet-core-sdk`** | Same JS bundle | Headless logic: `fetch`, mocks, store, events — **no React**. |
| **`FleetModule.forRoot`** | Root injector | Registers config token + `FleetService` wrapping `FleetSDK`. |
| **Your HTTP API** | Server | REST contract in [`openapi/fleet-api.yaml`](openapi/fleet-api.yaml). |

Capacitor runs **one** WebView for your Angular app; the SDK is **TypeScript + templates** using **`fetch`** only.

```mermaid
flowchart LR
  subgraph cap [Capacitor WebView]
    Shell[FleetShellModule → FleetFlowHost]
    Svc[FleetService]
    SDK[FleetSDK]
    Shell --> Svc --> SDK
  end
  SDK -->|HTTPS when useMock false| API[Your Fleet API]
```

---

## Prerequisites

- Node.js **18+** recommended (building core SDK).
- Angular **17+** + Capacitor.
- `core-sdk` built (`dist/` present).

---

## Integrate this SDK (follow in order)

| Step | What to do |
|------|------------|
| **1** | Build **`core-sdk`** (`npm install && npm run build` in [`core-sdk/`](../core-sdk/)). |
| **2** | Add **`@mgl/fleet-core-sdk`** to your Angular app (`file:` / `link:` path to built **`core-sdk`**, or a registry URL after you publish). |
| **3** | Copy **[`angular-sdk/src/lib/`](../angular-sdk/src/lib/)** into your project (or consume as an Angular library), matching import paths (e.g. `./fleet/…`). |
| **4** | Import **`FleetModule.forRoot({ apiBaseUrl, useMock: true, … })`** in your root **`NgModule`** (or equivalent **`importProvidersFrom`** for standalone bootstrap). |
| **5** | Register **one** lazy route whose **`loadChildren`** resolves **`FleetShellModule`** (snippets under **Step 4 — Mount the entire flow with lazy routing**). |
| **6** | Run **`ng serve`** (or **`ionic serve`** / **`ng build && npx cap run`**). Navigate to your fleet path (e.g. **`/mgl-fleet`**). |

Skipping **`FleetModule.forRoot`** or loading **`FleetShellModule`** without the core **`FleetService`** provider will break **`FleetFlowHostComponent`** at runtime.

Detailed snippets: **Steps 1–6** in the sections below (build core → dependencies → **`forRoot`** → lazy shell → auth token → Capacitor).

---

## Step 1 — Build the core SDK

```bash
cd core-sdk
npm install
npm run build
```

---

## Step 2 — Dependencies

In your Angular app `package.json`:

```json
{
  "dependencies": {
    "@mgl/fleet-core-sdk": "file:../../path/to/mgl-sdk/core-sdk"
  }
}
```

```bash
npm install
```

Copy or symlink **[`angular-sdk/src/lib/`](../angular-sdk/src/lib/)** into your workspace (library or `src/app/fleet/`), keeping imports consistent.

---

## Step 3 — Register SDK config (root)

**Once** in `AppModule` (or bootstrap):

```typescript
import { FleetModule } from './fleet/fleet.module';

@NgModule({
  imports: [
    FleetModule.forRoot({
      apiBaseUrl: environment.fleetApiUrl,
      authToken: undefined,
      useMock: true,
    }),
  ],
})
export class AppModule {}
```

This exposes `FleetService` / `FleetSDK` config app-wide.

---

## Step 4 — Mount the **entire flow** with lazy routing

Add **one** lazy route pointing at **`FleetShellModule`**:

```typescript
// app.routes.ts (or AppRoutingModule)
{
  path: 'mgl-fleet',
  loadChildren: () =>
    import('./fleet/fleet-shell.module').then((m) => m.FleetShellModule),
},
```

If you copied sources into `./fleet/`, adjust the import path.

### Flow inside the shell

| Route segment | Screen |
|---------------|--------|
| `/mgl-fleet` (lazy route path `''`) | **`FleetFlowHostComponent`** — mobile login/signup → OTP/PIN → driver shell (tabs + overlays). |

Navigate users once:

```typescript
this.router.navigate(['/mgl-fleet']);
```

Optional default redirect:

```typescript
{ path: '', redirectTo: 'mgl-fleet', pathMatch: 'full' },
```

---

## Step 5 — Auth token (production)

After login:

```typescript
constructor(private fleet: FleetService) {}
this.fleet.setAuthToken(token);
```

Used when `useMock: false` (`Authorization: Bearer …`).

---

## Step 6 — Capacitor-specific configuration

1. **API URL on device** — Use a reachable HTTPS origin (not `localhost` on physical devices unless proxied).
2. **CORS** — Allow Capacitor WebView origins (`capacitor://localhost`, etc.).
3. **Sync** — `ng build && npx cap sync`.

---

## Test end-to-end (mock mode)

No backend is required when **`useMock: true`** (as in Step 3).

1. Start your app (**`ng serve`**, or your usual Capacitor dev workflow).
2. Open the fleet route (for example **`http://localhost:4200/mgl-fleet`** — adjust host/port/path).
3. **Login path:** enter any **10-digit** mobile → **Send OTP** → OTP **`123456`** → PIN **`123456`**. You should land on the driver shell (tabs visible).
4. **Dev shortcut:** **Skip to main (dev)** jumps straight to the shell (QA only).
5. **Invite path (optional):** **New user? I have an invite code** → **`ABC123`** or **`XYZ789`** → mobile → OTP **`123456`** → set PIN twice → shell.
6. In the shell: use tabs (**Card / Scan / Assign / Txns / Profile**). Try **Demo: assignment push** and **Demo: pairing** (pairing codes **`123456`**, **`789012`**).
7. **Scan:** pick an eligible vehicle → **Simulate scan** → authorize PIN **`123456`** → **Authorize**.
8. **Profile** → **Log out** returns to login.

---

## Do I need to push this code to GitHub?

**No.** Keep **`mgl-sdk`** locally and point **`package.json`** at **`core-sdk`** with **`file:…`**; copy **`angular-sdk/src/lib`** into your app. GitHub is optional—for backups, teams, or CI.

For installs without a disk path, publish **`@mgl/fleet-core-sdk`** / your Angular library to npm or a private registry, or consume from git using your organization’s standard (**`npm install git+…`** patterns vary).

---

## Integrate on someone else's machine

Another developer needs **the SDK sources** (or **published packages**) available **on their disk** or **from a registry**. You do **not** special-case “their machine”—only **how they obtain `mgl-sdk`** and **what paths they put in `package.json`**.

| How they get the code | Typical setup |
|----------------------|----------------|
| **`git clone`** your repo | They clone to e.g. **`~/code/mgl-sdk`**, run **`core-sdk`** **`npm install && npm run build`**, then point **`file:`** at **`…/mgl-sdk/core-sdk`** and copy/use **`angular-sdk/src/lib`** as in Steps **2–5**. Same repo path for teammates—everyone rebuilds **`core-sdk`** after **`git pull`**. |
| **Zip / shared drive** | Send a zip of **`mgl-sdk`** (or minimal **`core-sdk`** + **`angular-sdk`**). They unzip anywhere and use **`file:`** paths **relative to their host app**, e.g. **`file:../vendor/mgl-sdk/core-sdk`**. |
| **npm / private registry** | Publish **`@mgl/fleet-core-sdk`** (and optionally wrap **`angular-sdk`** as its own library). They **`npm install`** by package name—**no local clone**. You still ship **`angular-sdk`** sources or a published Angular library. |
| **Git dependency** | Possible for **`core-sdk`** if you expose it as installable from git (**`npm install git+https://…`**)—exact **`package.json`** shape depends on repo layout; **monorepo subfolders** often push teams toward **clone + `file:`** or **publish**. |

**Checklist for your teammate**

1. Node **18+**, Angular **17+**, **`core-sdk`** built (**`dist/`** exists).
2. **`package.json`** **`file:`** (or registry) **`@mgl/fleet-core-sdk`** resolves on **their** filesystem.
3. **`FleetModule.forRoot`** + lazy **`FleetShellModule`** wired as in this doc.
4. Optional: pin the same **Git tag/commit** as you so **`core-sdk`** behaviour matches.

---

## Optional — Embed individual widgets only

If you **don’t** want the full shell, import **`FleetModule.forRoot`** only and build your own routes while driving **`FleetService.raw().appFlow`** (same **`FleetAppEngine`** as the host component).

---

## Troubleshooting

| Symptom | Check |
|---------|--------|
| Blank lazy route | `FleetModule.forRoot` imported in `AppModule`; path matches copied module location. |
| `FleetSDK` import fails | Rebuild `core-sdk`; verify `package.json` paths. |
| Network errors | URL, HTTPS, CORS, auth token when `useMock: false`. |

---

## Related files

- Shell routes: [`angular-sdk/src/lib/fleet-shell.routes.ts`](../angular-sdk/src/lib/fleet-shell.routes.ts)
- Core: [`core-sdk/fleet-sdk.ts`](../core-sdk/fleet-sdk.ts)
- OpenAPI: [`openapi/fleet-api.yaml`](openapi/fleet-api.yaml)
