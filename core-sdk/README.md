# @mgl/fleet-core-sdk

Headless fleet/domain SDK:

- **Transport**: `fetch` only (browser + Capacitor safe).
- **State**: vanilla observable store (`subscribe` / `getState`), demo-seeded from the legacy React mocks.
- **Events**: string-based pub/sub (`DRIVER_UPDATED`, `DRIVERS_REFRESHED`, `SESSION_READY`, `ERROR`).

```bash
npm install && npm run build
```

Default constructor opts into mock drivers (`useMock: true`). Set `useMock: false` and a real `apiBaseUrl` to hit REST endpoints described in `docs/openapi/fleet-api.yaml`.
