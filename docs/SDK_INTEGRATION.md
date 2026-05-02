# SDK integration (Angular + Capacitor + Flutter)

## 1. TypeScript core (`@mgl/fleet-core-sdk`)

1. Build: `cd core-sdk && npm install && npm run build`.
2. Install in the host app (`file:./core-sdk` or private registry).
3. Instantiate where needed (or use Angular `FleetService`):

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

## 2. Angular

1. Import `FleetModule.forRoot(config)` in `AppModule` (or a feature module).
2. Declare templates with `<mgl-driver-list />` and `<mgl-driver-detail [driverId]="id" />`.
3. Inject `FleetService` for `getDrivers()`, `getDriverDetails(id)`, `updateDriver()`, or `raw()` for `FleetSDK` store subscriptions.

## 3. Capacitor

- Capacitor hosts the Angular bundle; enable `server`/`https` as usual.
- Ensure CORS and TLS for `apiBaseUrl` on device.
- Do not rely on Node built-ins in app code — the core SDK already avoids them.

## 4. Flutter

- Treat [openapi/fleet-api.yaml](./openapi/fleet-api.yaml) as the contract.
- Implement `FleetApiService` (see [flutter-integration/README.md](../flutter-integration/README.md)).
- Map JSON to Dart models; drive `ListView` / `Navigator` with native widgets only.

## 5. Versioning

1. Bump `version` in `core-sdk/package.json` when the public API or OpenAPI changes.
2. Regenerate Flutter code (if using OpenAPI generator) after spec updates.
3. Keep Angular peer dependency ranges aligned with your workspace.
