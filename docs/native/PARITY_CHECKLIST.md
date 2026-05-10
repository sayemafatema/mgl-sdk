# Fleet SDK — UI parity checklist (native cores vs reference hosts)

Reference implementations for behaviour and copy:

| Area | Flutter reference | Angular reference |
|------|-------------------|-------------------|
| Flow shell | [`flutter-sdk/lib/src/fleet_flow_screen.dart`](../../flutter-sdk/lib/src/fleet_flow_screen.dart) | [`angular-sdk/src/lib/fleet-flow-host.component.ts`](../../angular-sdk/src/lib/fleet-flow-host.component.ts) |

Contract for HTTP payloads:

| Artifact | Path |
|----------|------|
| OpenAPI 3.1 | [`docs/openapi/fleet-api.yaml`](../openapi/fleet-api.yaml) |

## Screen / state parity (implement on Kotlin + Swift)

Mark **Done** per platform when UX matches acceptance criteria (copy may vary slightly).

| Step | ID | Acceptance |
|------|-----|------------|
| Mobile login | `auth_mobile` | 10-digit validation; navigate to OTP |
| OTP verify | `auth_otp` | Demo OTP `123456` in mock mode |
| PIN entry | `auth_pin` | Demo PIN `123456`; lockout messaging if applicable |
| Invite signup | `auth_invite` | Optional branch; demo codes `ABC123` / `XYZ789` |
| Driver shell tabs | `shell_tabs` | Primary tabs visible (Card / Scan / Assign / Txns / Profile — mirror reference) |
| Scan flow | `shell_scan` | Vehicle selection → authorize simulation |
| Profile / logout | `shell_profile` | Log out returns to login |

## Mock vs live API

| Mode | Behaviour |
|------|-----------|
| `useMock: true` | No driver-app network; fixtures from [`FleetReactMock`](../../native-android/fleet-sdk/src/main/java/com/mgl/fleet/sdk/demo/FleetDemoModels.kt) (same demo OTP/PIN/invite behaviour as before). |
| `useMock: false` | **`apiBaseUrl`** must point at the driver fleet host (same base as `NEXT_PUBLIC_DRIVER_API_BASE` / [`components/mgl/driver-api.ts`](../../components/mgl/driver-api.ts)). Android native client: [`DriverAppApiClient.kt`](../../native-android/fleet-sdk/src/main/java/com/mgl/fleet/sdk/internal/DriverAppApiClient.kt) — auth (`/api/v0/driver-app/auth/*`, `/oauth/token`), home, assignments, profile, transactions, QR pay, accept-pairing. Optional `authToken` on init skips login when non-blank. |

| Platform | Live E2E (`useMock: false`) |
|----------|----------------------------|
| **Android** (`fleet-android`) | Implemented in [`FleetDriverComposeApp.kt`](../../native-android/fleet-sdk/src/main/java/com/mgl/fleet/sdk/demo/ui/FleetDriverComposeApp.kt) (FO select, invite flow, scan pay, pairing). |
| **iOS** (`MGLFleetSDK`) | Implemented in [`FleetDriverNativeView.swift`](../../native-ios/MGLFleetSDK/Sources/MGLFleetSDK/FleetDriverNativeView.swift) + [`DriverAppApiClient.swift`](../../native-ios/MGLFleetSDK/Sources/MGLFleetSDK/DriverAppApiClient.swift) (FO select, invite flow, scan pay, pairing; mirror Android). |

## Maintainer smoke

Automated subset: `./scripts/smoke-native-matrix.sh`. Full checklist: **[`native/HOST_E2E.md`](native/HOST_E2E.md)** · wrapper contract **[`native/SMOKE_WRAPPERS.md`](native/SMOKE_WRAPPERS.md)**.

## Versioning note

Bump native artifact semver together when parity checklist rows change completion status for shipped flows.
