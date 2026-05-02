# OpenAPI schema → native model mapping

Source: [`fleet-api.yaml`](../openapi/fleet-api.yaml).

Naming convention:

- **Kotlin**: `data class` in package `com.mgl.fleet.sdk.api`, PascalCase types, camelCase JSON via `@SerializedName` if using Gson/Moshi; this repo uses manual parsing with defaults aligned to YAML `required` arrays.
- **Swift**: `struct` with `Codable` in module `MGLFleetSDK`, matching property names to JSON keys (snake_case converted only where YAML uses snake — current YAML uses camelCase except enums).

## Components/schemas

| Schema | Kotlin type | Swift type |
|--------|-------------|------------|
| `Driver` | `Driver` | `Driver` |
| `DriverPatch` | `DriverPatch` | `DriverPatch` |
| `FleetBinding` | `FleetBinding` | `FleetBinding` |
| `FleetTransaction` | `FleetTransaction` | `FleetTransaction` |

### Driver

| Field | Type | Kotlin | Swift |
|-------|------|--------|-------|
| id | string | `String` | `String` |
| name | string | `String` | `String` |
| vrn | string | `String` | `String` |
| status | enum Active/Inactive | `String` sealed/check | `String` |
| cardBalancePaise | int64 | `Long` | `Int64` |

### FleetBinding / FleetTransaction

Mirror YAML properties 1:1; optional fields nullable (`?` / optional Swift lets).

## Paths → client methods

| OperationId | Method | Path | Kotlin | Swift |
|---------------|--------|------|--------|-------|
| listDrivers | GET | `/fleet/drivers` | `FleetApiClient.listDrivers()` | `FleetApiClient.listDrivers()` |
| getDriver | GET | `/fleet/drivers/{driverId}` | `getDriver(id)` | `getDriver(id)` |
| patchDriver | PATCH | `/fleet/drivers/{driverId}` | `patchDriver(id, patch)` | `patchDriver(id, patch)` |
| listBindings | GET | `/fleet/bindings` | `listBindings()` | `listBindings()` |
| listTransactions | GET | `/fleet/transactions` | `listTransactions()` | `listTransactions()` |

## Auth header

| Scheme | Header |
|--------|--------|
| bearerAuth | `Authorization: Bearer <token>` |

Codegen option: OpenAPI Generator `kotlin` + `swift5` clients can replace hand-written clients when CI is wired.
