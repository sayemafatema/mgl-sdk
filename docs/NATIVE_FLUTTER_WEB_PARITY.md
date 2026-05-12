# Web vs native vs Flutter parity (source: `app/page.tsx`)

Web reference is **React/Next** (`app/page.tsx`). There is **no Angular** tree in this repo; any “Angular app” parity means **mirroring the same behaviour as this file** from an external app via SDK/plugins.

## Parity implementation notes (ongoing)

- **Banner helpers**: Android `ReactParityBanner.kt`, iOS `ReactParityBanner.swift`, Flutter `react_parity_strings.dart` mirror `bannerFromThrownError` / OTP / PIN / generic fallbacks from `app/page.tsx`.
- **iOS onboarding** uses React step IDs `set_pin` / `confirm_pin` (replacing `*_first`).
- **Flutter live auth**: `FleetAppEngine(config: FleetConfig(useMock: false, apiBaseUrl: …))` uses `driver_app_http.dart` for login / invite / multi-FO (`select_fo`, `fo_pin_login`). OTP resend uses **60s** countdown (live) / **30s** (mock), matching `page.tsx` intervals.

- **UI tokens**: Flutter `fleet_react_theme.dart`; Android demo `FleetReactTokens.kt`. Auth shell uses **SafeArea** on Flutter.

- **Scan session OTP:** Android Compose + Flutter demo now use a **60s resend cooldown** for the scan-flow OTP step (`otp_entry`), matching `page.tsx` `scanSessionOtpCountdown` / invite OTP timers. iOS still shows OTP inputs; add a `Timer`/`onReceive` countdown there to match if you need identical copy.
- **Flutter theme:** `FleetReactTheme` uses Tailwind **`green-700` (#15803d)**, **`#43a047`** for primary CTA (login Send OTP), and shared text/blue panel tokens; `FleetFlowScreen` uses `SafeArea` and shared radii/spacing.
- **Flutter engine:** `FleetAppSnapshot.sessionOtp` + flow **idle → confirmation → pin_confirm → otp_entry → authorized → complete** with `ReactParityStrings.bannerFromThrown` / failure helpers for live API errors.
- **Packages:** **`@mgl/capacitor-fleet-sdk`**, **`mgl_fleet_native_sdk`**, and **`mgl_fleet_sdk`** (flutter-sdk) are bumped to **0.5.0** — republish and **`npx cap sync`** / **`flutter pub get`** in host apps.

Full pixel-perfect motion (every `transition` / `animate-*` in `page.tsx`) and iOS scan OTP timer are optional follow-ups; run the live checklist in this file after integrating.

| Tier | Meaning |
|------|---------|
| **Strong** | Main shell + scan/session shape aligned with the wired React flows (tabs, overlays, scan phases, FO login chain). |
| **Proof-level 1:1** | Every branch, banner text, retry, animation, and web-only affordance matched — requires **live** screen matrix + API trace (below). |

---

## 1. Screen / state matrix

### 1.1 Onboarding (`onboardingStep` vs native / Flutter)

| React `onboardingStep` | Android `FleetDriverComposeApp` (`onboardingStep`) | iOS `FleetDriverNativeView` | Flutter `FleetAppEngine.authStep` |
|------------------------|------------------------------------------------------|-------------------------------|-----------------------------------|
| `login` | `login` | `login` | `login` |
| `login_otp` | `login_otp` | `login_otp` | `login_otp` |
| `select_fo` | `select_fo` | `select_fo` | **Not in demo engine** (multi-FO is live/native-focused). |
| `fo_pin_login` | `fo_pin_login` | `fo_pin_login` | `fo_pin_login` |
| `set_pin` | `set_pin` | `set_pin` | `set_pin` |
| `confirm_pin` | `confirm_pin` | `confirm_pin` | `confirm_pin` |
| `registered` | `registered` | `registered` | `registered` |
| `forgot_pin` | `forgot_pin` | `forgot_pin` | `forgot_pin` |
| `complete` | `complete` | `complete` | `complete` |
| `1b` … `1f` invite ladder | `1b`–`1f` | `1b`–`1f` | `1b`–`1f` |

**Gap (explicit):** Flutter has no **`select_fo`** auth step until multi-FO UX is added to `FleetAppEngine`.

### 1.2 Session / scan (`sessionState` vs `sessionPhase` / `sessionState`)

| React `sessionState` | Android `sessionPhase` | iOS `sessionPhase` | Flutter `sessionState` |
|----------------------|------------------------|--------------------|------------------------|
| `idle` | `idle` | `idle` | `idle` |
| `scanning` | **Often co-located with idle in UI** — confirm scanner active state | same | **not a distinct engine value** in `fleet_app_engine.dart` |
| `confirmation` | `confirmation` | `confirmation` | `confirmation` |
| `pin_confirm` | `pin_confirm` | `pin_confirm` | `pin_confirm` |
| `otp_entry` | `otp_entry` | `otp_entry` | **Not fully modeled** (mock flow skips to authorized in React demo paths). |
| `authorized` | `authorized` | `authorized` | `authorized` (brief UI then auto-advances) |
| `complete` | `complete` | `complete` | `complete` (Done → idle) |

**Gap:** Flutter demo does not yet mirror **live** `driverQrPay` / scan OTP resend timers; use native for full API parity tests.

### 1.3 Main shell / overlay

| React | Android | iOS | Flutter |
|-------|---------|-----|---------|
| `activeTab`: `card` \| `scan` \| `assignments` \| `transactions` \| `profile` | `mainTab` string + transactions route | `activeTab` / indices + txn | `activeTab` |
| `currentMainScreen`: `assignment_notification`, `pairing_code`, `assignment_accepted`, … | `mainOverlay`: `none`, `assignment_notification`, `pairing_code`, `assignment_accepted` | `overlay` | `mainOverlay` — **values may differ** (`home` vs `none`) |

### 1.4 Web-only (no native clone expected unless product asks)

- DOM `.session-otp-digit` focus chain, `fuelReceiptCaptureRef` / html2canvas-style receipt capture, browser share APIs, keyboard tab order.

---

## 2. API trace (wired React → `DriverAppApiClient` Kotlin)

These mirror `components/mgl/driver-api` helpers used by `page.tsx`:

| React helper (`driver-api`) | Kotlin `DriverAppApiClient` |
|------------------------------|-----------------------------|
| `driverCheckMobile` | ✅ `driverCheckMobile` |
| `driverSendLoginOtp` | ✅ `driverSendLoginOtp` |
| `driverOauthOtpGrant` | ✅ `driverOauthOtpGrant` |
| `driverFoList` | ✅ `driverFoList` |
| `driverFoSelect` | ✅ `driverFoSelect` |
| `driverInviteMobileSendOtp` | ✅ `driverInviteMobileSendOtp` |
| `driverInviteMobileVerifyOtp` | ✅ `driverInviteMobileVerifyOtp` |
| `driverInviteValidate` | ✅ `driverInviteValidate` |
| `driverInviteSetPin` | ✅ `driverInviteSetPin` |
| `driverGetHome` / `driverGetProfile` / `driverGetAssignments` | ✅ |
| `driverGetTransactions` | ✅ |
| `driverAcceptPairing` | ✅ |
| `driverQrPay` | ✅ |

**Error / banner parity:** React uses `setApiBanner(message)` from peeled errors. Native demos must map `DriverApiException` / OAuth peel strings to the **same user-visible text** where intended; **diff `page.tsx` error branches vs Kotlin `performOnboarding*` / Swift handlers** for proof-level claims.

**Retries:** React has resend timers (`otpCountdown`, `scanSessionOtpCountdown`). Native must expose the same cooldown behaviour where live OTP resend exists.

---

## 3. Plugins (lag check)

| Surface | Role | Parity note |
|---------|------|-------------|
| `plugins/capacitor-fleet` | `FleetSdk.initialize` + `openFleetNativeFlow` / `presentFleetFlow` | Thin bridge; **behaviour = packaged `fleet-sdk` AAR** — bump / sync when demo changes |
| Flutter plugin package | Embeds or links to `flutter-sdk` | Same rule: **release** when `flutter-sdk` parity milestone closes |

---

## 4. Live verification checklist (claim “wired flows match”)

For each row: run React app + native demo + Flutter demo against the **same `apiBaseUrl`**, same mobile/invite fixtures.

1. Login → OTP → FO list (0/1/n) → optional FO PIN → home refresh (`driverGetHome`/`Profile`/`Assignments`/`FoList`).
2. Invite `1b`→`1f` (or Flutter equivalent) → set PIN → registered → complete.
3. Forgot PIN path → back to login.
4. Card tab: empty / paired / pending badge behaviour vs `apiHome` + bindings.
5. Assignment notification → accept/decline → pairing overlay → `driverAcceptPairing` → assignments refresh.
6. Scan: idle/scan → confirmation → PIN → (OTP if wired) → authorized/complete → `driverQrPay` + balance/txn refresh.
7. Transactions: filter all / success / failed vs `driverGetTransactions` payload `status`.
8. Profile: display fields vs `driverGetProfile`.

**Evidence:** HAR or OkHttp/URLSession log **path + status + peeled error body** per step; screenshot matrix optional.

---

## 5. Next assistant: recommended order

1. Flutter: add engine/UI for **`otp_entry`**, **`authorized`**, full **`complete`** receipt flow to match React `sessionState` (Android/iOS already use `authorized`).
2. Align Flutter `authStep` strings with React **or** ship a single `AUTH_STEP_MAP` in Dart (include **multi-FO** `select_fo` if live product needs it).
3. Diff `page.tsx` `apiBanner` strings vs Android/iOS handlers for each onboarding + scan failure branch.
4. Capacitor / Flutter plugin releases when `fleet-sdk` / `flutter-sdk` demo parity moves.
