# mgl_fleet_native_sdk

Flutter plugin bridging to **MGL Fleet** native cores (**`fleet-android`** + **`MGLFleetSDK`**).

## Integration

See **[`docs/README.NATIVE-SDK.md`](../../docs/README.NATIVE-SDK.md)**.

## Maintainer publish

1. Align Android dependency version with **[`docs/VERSIONS.md`](../../docs/VERSIONS.md)** (`android/build.gradle` → **`com.mgl.sdk:fleet-android`**).
2. When ready for pub.dev, remove **`publish_to: none`** in **`pubspec.yaml`**, replace **`YOUR_ORG`** placeholders, run **`flutter pub publish`**.

Operator checklist: **[`docs/PUBLISH_FOR_EXTERNAL_CONSUMERS.md`](../../docs/PUBLISH_FOR_EXTERNAL_CONSUMERS.md)**.
