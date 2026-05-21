# `mgl_fleet_sdk`

Pure **Flutter** driver SDK — one call (`FleetNativeSdk.root` / `present`) mounts the full login → shell → scan flow.

**Integration guide:** [`docs/FLUTTER_SDK_INTEGRATION_GUIDE.md`](../docs/FLUTTER_SDK_INTEGRATION_GUIDE.md)

## Quick start

```yaml
dependencies:
  mgl_fleet_sdk:
    path: ../mgl-sdk/flutter-sdk
```

```dart
import 'package:flutter/material.dart';
import 'package:mgl_fleet_sdk/mgl_fleet_sdk.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    FleetNativeSdk.root(
      const FleetConfig(
        apiBaseUrl: 'https://api-fleet-uat.enkash.in',
        useMock: true,
      ),
    ),
  );
}
```

## Example

```bash
cd flutter-sdk/example
flutter pub get
flutter run
```

Mock OTP/PIN: `123456`. Pairing demo: `123456`, `789012`. Invite: `ABC123`, `XYZ789`.

Optional native Compose/SwiftUI bridge: [`plugins/flutter-fleet/mgl_fleet_native_sdk`](../plugins/flutter-fleet/mgl_fleet_native_sdk/) (not required for this package).
