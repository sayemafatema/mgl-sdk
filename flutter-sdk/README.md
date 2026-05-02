# `mgl_fleet_sdk`

**Native Fleet SDK for Flutter** — Material UI only; same REST contract as **[OpenAPI](../docs/openapi/fleet-api.yaml)**.

Integration is **initialization-only**: wrap **`FleetNativeSdk.root(config)`** or call **`FleetNativeSdk.present(...)`**.

---

## Initialization

### 1 — Dependency

```yaml
dependencies:
  mgl_fleet_sdk:
    path: ../mgl-sdk/flutter-sdk  # adjust relative to your app
```

```bash
flutter pub get
```

### 2 — Start the SDK

**Full screen** (typical demo / fleet-only build):

```dart
import 'package:flutter/material.dart';
import 'package:mgl_fleet_sdk/mgl_fleet_sdk.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    FleetNativeSdk.root(
      FleetConfig(
        apiBaseUrl: 'https://your-api.example',
        useMock: true,
      ),
    ),
  );
}
```

**From your existing app**:

```dart
await FleetNativeSdk.present(
  context,
  FleetConfig(apiBaseUrl: baseUrl, useMock: false),
);
```

That’s it — no manual composition of login / OTP / shell screens.

---

## **`FleetConfig`**

| Field | Meaning |
|-------|---------|
| **`apiBaseUrl`** | Fleet REST base URL |
| **`useMock`** | **`true`** = in-memory demo (**no backend**) |
| **`authToken`** | Optional Bearer when **`useMock: false`** |

---

## Equivalence

| API | Role |
|-----|------|
| **`FleetNativeSdk.root`** | Preferred native SDK entry |
| **`FleetSdkApp`** | Same widget; kept for backwards compatibility |

---

## Example app (this repo)

From **`mgl-sdk`** root:

```bash
cd flutter-sdk/example
flutter pub get
flutter run
```

---

## Requirements

- Flutter **3.x**, **`environment.sdk: '>=3.0.0 <4.0.0'`** in this package.

---

## More detail

- **[`docs/README.FLUTTER.md`](../docs/README.FLUTTER.md)** — E2E checklist, devices, publishing.
- **[`flutter-integration/README.md`](../flutter-integration/README.md)** — REST-only / custom UI appendix.
