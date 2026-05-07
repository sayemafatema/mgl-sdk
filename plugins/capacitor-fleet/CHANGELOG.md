# Changelog

## Unreleased

- **Bridge:** **`openFleetNativeFlow`** (native) + **`openMglFleetNativeFlow`** (TS) now use **one Capacitor invoke** for **initialize + present** — avoids ordering/race issues when the host stacks two separate native calls (Angular `Zone.js`, slow devices, or bridge batching). **`presentFleetFlow`** alone now rejects with **`NOT_INITIALIZED`** if **`initialize`** never ran (clearer than a generic native error).
- **Android `FleetSdk.isInitialized()`:** Public check used by the Capacitor plugin guard.
- **iOS `FleetSdk.isInitialized()`:** Same; fixes **`presentFleetFlow`** failure **`reject`** arguments (code vs `Error`).
- **Android:** Depend on **`project(':capacitor-android')`** instead of Maven **`com.capacitorjs:capacitor-android`** so host apps resolve Capacitor core from **`node_modules`** (standard Capacitor plugin pattern).
- **Android `FleetSdkPlugin`:** Coerce nested **`initialize` / `present`** options when the bridge delivers **`Map`** instead of **`JSONObject`** (fixes **`getObject("initialize")` == null** and no-op / stuck flows). **`Log.i` / `Log.e`** for **`MGLFleetSdk`** tag. **`openFleetNativeFlow`** wrapped in **`try/catch`** with reject on unexpected throw.
- **JS:** If **`openFleetNativeFlow`** is **UNIMPLEMENTED** on native (stale APK / no sync), **fallback** to **`initialize` + `presentFleetFlow`** so Fleet still opens until the app is rebuilt.
- **Native `FleetSdk`:** Run **`startActivity` (Android)** / **`present` (iOS)** on the **main thread** — Capacitor often calls plugins off the UI thread, which could previously result in no Fleet UI.
- **Capacitor `android`:** **`consumer-rules.pro`** + **`consumerProguardFiles`** so R8 does not drop **`FleetSdkPlugin`** in release builds.

## 0.1.0

- Initial npm publish train (`MGLFleetSdk` Capacitor plugin; TypeScript facade).
