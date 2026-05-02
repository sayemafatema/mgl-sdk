# Fleet cross-platform SDK

This repository contains:

| Package | Role |
|---------|------|
| [core-sdk](./core-sdk/) | Headless **TypeScript** `FleetSDK`: HTTP + mock fleet data, observable store, events. **No React.** |
| [angular-sdk](./angular-sdk/) | **`FleetShellModule`** — lazy-loaded **full UI flow** (welcome → tabs → drivers/detail); optional granular components. |
| [flutter-sdk](./flutter-sdk/) | **`FleetSdkApp`** — single widget starts the **full native flow** (welcome → tabs → detail). |
| [docs/openapi/fleet-api.yaml](./docs/openapi/fleet-api.yaml) | Shared HTTP contract for TS + **Capacitor** + **Flutter**. |
| [flutter-integration/README.md](./flutter-integration/README.md) | Manual Dart snippets — prefer **`flutter-sdk`** package first. |

## Build core SDK

```bash
cd core-sdk && npm install && npm run build
```

Consumers import `FleetSDK` from `@mgl/fleet-core-sdk` (path or published package).

## Events (core)

Core emits string events suitable for logging or bridging:

- `DRIVER_UPDATED`
- `DRIVERS_REFRESHED`
- `SESSION_READY` (after `setAuthToken`)
- `ERROR`

## Capacitor & Flutter entry points

The core SDK uses **fetch** only — safe inside Capacitor’s Angular bundle.

- **Angular:** `FleetModule.forRoot` + lazy **`FleetShellModule`** → see [README.ANGULAR-CAPACITOR.md](./README.ANGULAR-CAPACITOR.md).
- **Flutter:** **`FleetSdkApp`** (native widgets; same REST contract) → see [README.FLUTTER.md](./README.FLUTTER.md).

## Integration guides

- **[Angular + Capacitor](./README.ANGULAR-CAPACITOR.md)** — one lazy route mounts the entire fleet shell.
- **[Flutter](./README.FLUTTER.md)** — path dependency + `FleetSdkApp`; optional manual HTTP appendix.

## Further reading

- [SDK_INTEGRATION.md](./SDK_INTEGRATION.md)
- [UI_SCREEN_MAPPING.md](./UI_SCREEN_MAPPING.md)
