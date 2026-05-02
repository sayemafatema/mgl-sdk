# `mgl_fleet_sdk` (Flutter)

## Seamless integration

**`FleetSdkApp`** is the single surface area for the bundled experience: initialize it once with **`FleetConfig`**, and you get the **full flow**—mobile login / invite signup → OTP / PIN → driver shell (tabs, assignment & pairing overlays, scan authorize)—without importing or composing individual SDK screens.

Internal **`FleetFlowScreen`** + **`FleetAppEngine`** mirror the Angular **`FleetFlowHost`** behaviour (Dart engine port). **`FleetScope`** still exposes **`FleetRepository`** for HTTP when **`useMock: false`**.

## Wire into your host app

### Full-screen fleet flow

```dart
import 'package:mgl_fleet_sdk/mgl_fleet_sdk.dart';
import 'package:flutter/material.dart';

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

### Push from existing app

```dart
Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => FleetSdkApp(
      config: FleetConfig(useMock: false, apiBaseUrl: 'https://your-api.example'),
    ),
  ),
);
```

## Path dependency

From your Flutter app **`pubspec.yaml`**:

```yaml
dependencies:
  mgl_fleet_sdk:
    path: ../mgl-sdk/flutter-sdk
```

Then **`flutter pub get`**.

## Backend alignment

Same REST paths as [`docs/openapi/fleet-api.yaml`](../docs/openapi/fleet-api.yaml) and TS **`DriversApi`**. Set **`useMock: false`** and implement the API server.

**Integration checklist**, **`flutter run`** E2E smoke steps (demo OTP/PIN **`123456`**), **integrating on someone else's machine**, and **GitHub / publishing**: **[docs/README.FLUTTER.md](../docs/README.FLUTTER.md)**.
