# Fleet native SDK — released artifact versions

Bump **all rows together** per release train (see **[PUBLISH_FOR_EXTERNAL_CONSUMERS.md](PUBLISH_FOR_EXTERNAL_CONSUMERS.md)**).

| Artifact | Coordinate / package | Current |
|----------|----------------------|---------|
| Android native | Maven **`com.mgl.sdk:fleet-android`** | **0.1.0** (`native-android/gradle.properties` → `fleetAndroid.version`) |
| iOS native | SPM tag / CocoaPods **`MGLFleetSDK`** | **0.1.0** (`native-ios/MGLFleetSDK/MGLFleetSDK.podspec`) |
| Capacitor bridge | npm **`@mgl/capacitor-fleet-sdk`** | **0.1.0** |
| Flutter bridge | pub **`mgl_fleet_native_sdk`** | **0.1.0** (`pubspec.yaml`) |
| React Native bridge | npm **`@mgl/react-native-fleet-sdk`** | **0.1.0** |

Consumer Gradle dependency:

```gradle
implementation 'com.mgl.sdk:fleet-android:0.1.0'
```
