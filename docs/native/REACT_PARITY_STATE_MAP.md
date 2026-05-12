# React reference state map (`app/page.tsx`)

Machine-readable parity reference for **Android Compose** [`FleetDriverComposeApp.kt`](../../native-android/fleet-sdk/src/main/java/com/mgl/fleet/sdk/demo/ui/FleetDriverComposeApp.kt) and **iOS SwiftUI** [`FleetDriverNativeView.swift`](../../native-ios/MGLFleetSDK/Sources/MGLFleetSDK/FleetDriverNativeView.swift).

Reference file: [`app/page.tsx`](../../app/page.tsx).

## `onboardingStep` (exclusive phases before main shell)

TypeScript union (initial `'login'`):

| Step | Purpose |
|------|---------|
| `login` | Mobile entry; invite path → `1b`/`1c` |
| `login_otp` | OTP verify login |
| `set_pin` / `confirm_pin` / `registered` | New-device PIN onboarding |
| `select_fo` | Multi-FO picker after OTP grant |
| `fo_pin_login` | FO PIN + selective `driverFoSelect` |
| `1b` | Invite: mobile-first branch |
| `1c` | Invite: code entry / validate |
| `1d` | Invite OTP send/verify branch |
| `1e` / `1f` | Invite PIN create/confirm (`driverInviteSetPin`) |
| `forgot_pin` | PIN recovery intro |
| `complete` | Main app shell (requires `foScopedToken`) |

Native bridges must preserve **the same string ids** (`setOnboardingStep` targets) unless a deliberate versioned migration ships.

## Main shell (`onboardingStep === 'complete'`)

| State | TS type | Notes |
|-------|---------|--------|
| `activeTab` | `'card'\|'scan'\|'assignments'\|'transactions'\|'profile'` | Bottom navigation |
| `txnFilter` | `'all'\|'successful'\|'failed'` | Transactions tab |
| `currentMainScreen` | `'home_empty'\|'home_active'\|'assignment_notification'\|'pairing_code'\|'assignment_accepted'` | Card-area sub-state |
| `sessionState` (scan session) | `'idle'\|'scanning'\|'confirmation'\|'pin_confirm'\|'otp_entry'\|'authorized'\|'complete'` | Scan & Pay flow |

## Driver API surface used by `page.tsx`

Functions called from TS (mirror in [`driver-api.ts`](../../components/mgl/driver-api.ts) → Kotlin [`DriverAppApiClient.kt`](../../native-android/fleet-sdk/src/main/java/com/mgl/fleet/sdk/internal/DriverAppApiClient.kt) → Swift [`DriverAppApiClient.swift`](../../native-ios/MGLFleetSDK/Sources/MGLFleetSDK/DriverAppApiClient.swift)):

| Function | Endpoint / pattern |
|---------|---------------------|
| `driverCheckMobile` | POST `/api/v0/driver-app/auth/check-mobile` |
| `driverSendLoginOtp` | GET `/api/v0/otp/login?username=` |
| `driverOauthOtpGrant` | POST `/oauth/token` (form otp grant) |
| `driverFoList` | GET `/api/v0/driver-app/auth/fo-list` |
| `driverFoSelect` | POST `/api/v0/driver-app/auth/fo-select` |
| `driverInviteMobileSendOtp` | POST `/api/v0/driver-app/auth/mobile/send-otp` |
| `driverInviteMobileVerifyOtp` | POST `/api/v0/driver-app/auth/mobile/verify-otp` |
| `driverInviteValidate` | POST `/api/v0/driver-app/auth/invite/validate` |
| `driverInviteSetPin` | POST `/api/v0/driver-app/auth/invite/set-pin` |
| `driverGetHome` | GET `/api/v0/driver-app/home` |
| `driverGetProfile` | GET `/api/v0/driver-app/profile` |
| `driverGetAssignments` | GET `/api/v0/driver-app/assignments` |
| `driverGetTransactions` | GET `/api/v0/driver-app/vehicles/{vehicleId}/transactions` |
| `driverAcceptPairing` | POST `/api/v0/driver-app/vehicle/accept-pairing` |
| `driverQrPay` | POST `/api/v0/driver-app/qr/pay` |
| `driverGetBalance` | GET `/api/v0/driver-app/balance` (optional UI; parity with TS client) |

`mapAssignmentsToUiBindings`: TS [`driver-api.ts`](../../components/mgl/driver-api.ts); Kotlin [`mapAssignmentsToDemoBindings`](../../native-android/fleet-sdk/src/main/java/com/mgl/fleet/sdk/internal/).

## QR helpers

[`fleetpay-qr`](../../components/mgl/fleetpay-qr): `parseFleetpayPayUri`, `paiseToInrDisplay` — native equivalents in `Internal` parsers (Android/iOS).

## Out of SDK scope from Next shell

[`app/layout.tsx`](../../app/layout.tsx): fonts, metadata, Analytics — recreate only as native theme tokens where needed.
