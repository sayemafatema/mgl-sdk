# Android native fleet SDK (required for Scan & FO PIN)

After `flutter create . --platforms=android`, ensure:

1. **`settings.gradle.kts`** includes `:fleet-sdk` (this folder may already contain it).
2. **`MainActivity`** extends **`FlutterFragmentActivity`** (see `app/src/main/kotlin/.../MainActivity.kt`).

Without `:fleet-sdk`, the plugin uses Maven `com.mgl.sdk:fleet-android:0.3.0`.
