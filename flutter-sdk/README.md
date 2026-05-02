# `mgl_fleet_sdk`

Flutter implementation of the MGL Fleet driver flow: **native Material UI**, same REST contract as the TypeScript **`DriversApi`** / **[OpenAPI](../docs/openapi/fleet-api.yaml)**.

**Single entry:** **`FleetSdkApp`** + **`FleetConfig`** → full flow (login / invite signup → OTP / PIN → driver shell). You **do not** compose individual SDK screens for the default path.

---

## What you add (two things)

| # | In your app | Purpose |
|---|-------------|---------|
| 1 | **`mgl_fleet_sdk`** dependency (**`path:`** or published/git package) | SDK widgets + **`FleetRepository`** HTTP |
| 2 | **`FleetSdkApp(config: FleetConfig(...))`** — **`runApp`** or **`Navigator.push`** | Starts **`FleetFlowScreen`** driven by **`FleetAppEngine`** |

---

## Prerequisites

- **Flutter SDK 3.x** (**`flutter`** / **`dart`** on **`PATH`**).
- **`flutter doctor`** without blocking issues for your target device/emulator.

---

## Integration (copy in order)

### 1 — Depend on this package

In your host app **`pubspec.yaml`**:

```yaml
dependencies:
  flutter:
    sdk: flutter
  mgl_fleet_sdk:
    path: ../mgl-sdk/flutter-sdk
```

Adjust **`path:`** relative to **your app’s `pubspec.yaml`**:

| Your Flutter app lives at | Example `path:` |
|---------------------------|-----------------|
| **`projects/my_app/`** next to **`mgl-sdk/`** | **`../mgl-sdk/flutter-sdk`** |
| **`projects/mobile/`** and **`mgl-sdk`** is sibling of **`projects/`** | **`../../mgl-sdk/flutter-sdk`** |

If **`flutter pub get`** fails, verify **`path:`** targets the **`flutter-sdk`** folder that contains this **`pubspec.yaml`** (package name **`mgl_fleet_sdk`**).

---

### 2 — Fetch packages

From **your host app** directory (where **`pubspec.yaml`** is):

```bash
flutter pub get
```

If resolution fails: fix **`path:`**, ensure **`flutter-sdk/pubspec.yaml`** exists on disk.

---

### 3 — Launch the fleet UI

**Option A — entire window is fleet (simplest demo)**

```dart
import 'package:flutter/material.dart';
import 'package:mgl_fleet_sdk/mgl_fleet_sdk.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    FleetSdkApp(
      config: FleetConfig(
        apiBaseUrl: 'https://your-api.example',
        useMock: true,
      ),
    ),
  );
}
```

**Option B — push from your existing `MaterialApp`**

```dart
import 'package:mgl_fleet_sdk/mgl_fleet_sdk.dart';

void openFleet(BuildContext context) {
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => FleetSdkApp(
        config: FleetConfig(
          apiBaseUrl: 'https://your-api.example',
          useMock: true,
        ),
      ),
    ),
  );
}
```

**Option C — nested route (e.g. `go_router`)**

Return **`FleetSdkApp`** from a route **`builder`** / **`pageBuilder`** with the same **`FleetConfig`**.

---

### 4 — Configure **`FleetConfig`**

| Field | Meaning |
|-------|---------|
| **`apiBaseUrl`** | Base URL for fleet REST (**required** for real API). |
| **`useMock`** | **`true`** = in-memory demo (**no backend**). **`false`** = **`FleetRepository`** calls your server. |
| **`authToken`** | Optional Bearer token when **`useMock: false`** (set via **`FleetConfig.copyWith`** when your host obtains a token). |

Production-style example:

```dart
FleetSdkApp(
  config: FleetConfig(
    apiBaseUrl: 'https://api.yourcompany.com',
    useMock: false,
    authToken: tokenFromYourAuthLayer,
  ),
)
```

Implement endpoints per **[`docs/openapi/fleet-api.yaml`](../docs/openapi/fleet-api.yaml)**.

---

## Quick checklist before **`flutter run`**

- [ ] **`pubspec.yaml`** **`path:`** points at **`flutter-sdk`** folder that contains **`pubspec.yaml`**.
- [ ] **`flutter pub get`** completed with **Exit code 0**.
- [ ] Import URI is **`package:mgl_fleet_sdk/mgl_fleet_sdk.dart`** (underscore in package name).
- [ ] **`useMock: true`** to try UI without API first.

---

## Run the bundled example app (this repo)

Useful to verify Flutter tooling before integrating into your host.

From **`mgl-sdk`** repository root:

```bash
cd flutter-sdk/example
flutter pub get
flutter run
```

If you are already inside **`flutter-sdk/`**, use **`cd example`** instead.

Demo credentials match the Angular guide (**OTP / PIN `123456`**, invite codes **`ABC123`** / **`XYZ789`**).

---

## Mock-mode smoke test (your host app)

1. **`flutter run`** on simulator or device.
2. Login: any **10-digit** mobile → **Send OTP** → **`123456`** → PIN **`123456`** → tabs (**Card / Scan / Assign / …**) appear.
3. Optional: **Invite** flow with **`ABC123`** / **`XYZ789`**.
4. **Profile → Log out** returns to login.

---

## Networking (devices)

| Topic | Tip |
|-------|-----|
| Emulator vs phone | **`localhost`** / **`127.0.0.1`** differ — use machine LAN IP or deployed **`apiBaseUrl`**. |
| HTTPS | Prefer HTTPS; Android cleartext / iOS ATS only for controlled dev. |

---

## Advanced / partial integration

- **`FleetFlowScreen`** + **`FleetScope`** / **`FleetRepository`** — see exported **`lib/src/`** if you build a custom shell (not needed for **`FleetSdkApp`**).
- REST-only custom UI: **[`flutter-integration/README.md`](../flutter-integration/README.md)**.

---

## More detail

- Long-form guide (teammates, git zip, publishing): **[`docs/README.FLUTTER.md`](../docs/README.FLUTTER.md)**
- OpenAPI: **[`docs/openapi/fleet-api.yaml`](../docs/openapi/fleet-api.yaml)**
