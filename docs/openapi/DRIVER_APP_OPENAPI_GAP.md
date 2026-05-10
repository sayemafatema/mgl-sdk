# Driver App API vs `fleet-api.yaml`

**`docs/openapi/fleet-api.yaml`** describes the **fleet-management** REST surface (e.g. `/fleet/drivers`, `/fleet/bindings`, `/fleet/transactions`).

The **driver mobile app** uses a **separate** backend contract: same base URL as `NEXT_PUBLIC_DRIVER_API_BASE` in the reference app, implemented in TypeScript as [`components/mgl/driver-api.ts`](../../components/mgl/driver-api.ts).

That contract is **not** yet represented as OpenAPI paths in this repo.

| Layer | Canonical reference | Native implementation |
|-------|---------------------|------------------------|
| Fleet REST (OpenAPI) | `fleet-api.yaml` | `FleetApiClient` (Kotlin) / `FleetApiClient` (Swift) |
| Driver app REST | `driver-api.ts` (+ JSON peel helpers) | `DriverAppApiClient` (Kotlin, `internal`) · `DriverAppApiClient` (Swift) |

When the driver-app API is stable for external consumers, paths and schemas should be **merged or split** into OpenAPI (or a second `driver-app.yaml`) and codegen considered; until then, **`MODEL_MAPPING.md`** lists field-level alignment for both contracts.
