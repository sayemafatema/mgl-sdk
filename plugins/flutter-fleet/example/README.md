# mgl_fleet_native_sdk example

```bash
cd plugins/flutter-fleet/example
flutter create . --platforms=android,ios   # first time only — generates android/ios if missing
flutter pub get
flutter run
```

**Android:** `settings.gradle.kts` includes `:fleet-sdk` from `native-android/fleet-sdk`.  
**iOS:** Run `pod install` in `ios/` after `flutter create`; MGLFleetSDK links via plugin podspec path.

Use **Open Fleet (native)** — mock OTP `123456`, PIN `234567`.
