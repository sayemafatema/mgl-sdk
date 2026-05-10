# Schema → native model mapping

Two contracts feed the repos’ native stacks:

| Contract | Canonical file | Kotlin | Swift |
|----------|----------------|--------|-------|
| **Fleet REST (OpenAPI)** | [`fleet-api.yaml`](../openapi/fleet-api.yaml) | [`FleetApiClient.kt`](../../native-android/fleet-sdk/src/main/java/com/mgl/fleet/sdk/FleetApiClient.kt) · `api/` DTOs | [`FleetApiClient.swift`](../../native-ios/MGLFleetSDK/Sources/MGLFleetSDK/FleetApiClient.swift) |
| **Driver app REST** | [`driver-api.ts`](../../components/mgl/driver-api.ts) | [`DriverAppApiClient.kt`](../../native-android/fleet-sdk/src/main/java/com/mgl/fleet/sdk/internal/DriverAppApiClient.kt) + internal parsers | [`DriverAppApiClient.swift`](../../native-ios/MGLFleetSDK/Sources/MGLFleetSDK/DriverAppApiClient.swift) + [`DriverFleetJson.swift`](../../native-ios/MGLFleetSDK/Sources/MGLFleetSDK/DriverFleetJson.swift) |

Driver-app paths are **not** in OpenAPI yet; see **[DRIVER_APP_OPENAPI_GAP.md](../openapi/DRIVER_APP_OPENAPI_GAP.md)**.

---

## A. OpenAPI fleet API (`fleet-api.yaml`)

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

---

## B. Driver app API (`driver-api.ts` ↔ native)

Types in TS align to Kotlin/Swift parser structs (envelopes peeled the same order as TS `unwrapDriverBodyData`).

| TS type (`driver-api.ts`) | Kotlin | Swift |
|---------------------------|--------|-------|
| `CheckMobileStatus` | `CheckMobileStatus` | `CheckMobileStatusKind` |
| `FoListEntry` | `FoListEntry` | `FoListEntryParsed` |
| `InviteValidateResult` | `InviteValidateResult` | `InviteValidateParsed` |
| `DriverHome` | `DriverHomeJson` | `DriverHomeParsed` |
| `DriverAssignment` | `DriverAssignmentJson` | `DriverAssignmentParsed` |
| `DriverProfile` | `DriverProfileJson` | `DriverProfileParsed` |
| `QrPayResult` | `QrPayResultJson` | `QrPayResultParsed` |
| `DriverTxnRow` | `DriverTxnRowParse` | `DriverTxnRowParsed` |
| `DriverTransactionsResult` | `TxnsPageParsed` | `TxnsPageParsedIOS` |

### Paths → native methods (`DriverAppApiClient`)

| Purpose | HTTP | Kotlin / Swift |
|---------|------|----------------|
| Check mobile | `POST /api/v0/driver-app/auth/check-mobile` | `driverCheckMobile` |
| Send login OTP | `GET /api/v0/otp/login?username=` | `driverSendLoginOtp` |
| Invite send OTP | `POST /api/v0/driver-app/auth/mobile/send-otp` | `driverInviteMobileSendOtp` |
| Invite verify OTP | `POST /api/v0/driver-app/auth/mobile/verify-otp` | `driverInviteMobileVerifyOtp` |
| Invite validate | `POST /api/v0/driver-app/auth/invite/validate` | `driverInviteValidate` |
| Invite set PIN | `POST /api/v0/driver-app/auth/invite/set-pin` | `driverInviteSetPin` |
| OAuth OTP grant | `POST /oauth/token` (form body) | `driverOauthOtpGrant` |
| FO list | `GET /api/v0/driver-app/auth/fo-list` | `driverFoList` |
| FO select + fleet token | `POST /api/v0/driver-app/auth/fo-select` | `driverFoSelect` |
| Home | `GET /api/v0/driver-app/home` | `driverGetHome` |
| Profile | `GET /api/v0/driver-app/profile` | `driverGetProfile` |
| Assignments | `GET /api/v0/driver-app/assignments` | `driverGetAssignments` |
| Accept pairing | `POST /api/v0/driver-app/vehicle/accept-pairing` | `driverAcceptPairing` |
| QR pay | `POST /api/v0/driver-app/qr/pay` | `driverQrPay` |
| Vehicle transactions | `GET /api/v0/driver-app/vehicles/{id}/transactions` | `driverGetTransactions` |

_TS also calls **`GET …/balance`** (`fetchDriverBalanceLive`); Android/iOS parity UIs refresh balance via **home** + assignments mapping — add a dedicated client method only if product requires `/balance` on device._

Fleetpay QR helpers: **`parseFleetpayPayUri`** / **`FleetpayQrPayload`** ↔ **`DriverFleetQr`** / **`FleetpayQrPayloadIOS`** (Android `DriverFleetQr.kt`).
