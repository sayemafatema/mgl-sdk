# Changelog

## Unreleased

- **Bridge:** **`openFleetNativeFlow`** (native) + **`openMglFleetNativeFlow`** (TS) now use **one Capacitor invoke** for **initialize + present** — avoids ordering/race issues when the host stacks two separate native calls (Angular `Zone.js`, slow devices, or bridge batching). **`presentFleetFlow`** alone now rejects with **`NOT_INITIALIZED`** if **`initialize`** never ran (clearer than a generic native error).
- **Android `FleetSdk.isInitialized()`:** Public check used by the Capacitor plugin guard.
- **iOS `FleetSdk.isInitialized()`:** Same; fixes **`presentFleetFlow`** failure **`reject`** arguments (code vs `Error`).
- **Android:** Depend on **`project(':capacitor-android')`** instead of Maven **`com.capacitorjs:capacitor-android`** so host apps resolve Capacitor core from **`node_modules`** (standard Capacitor plugin pattern).
- **JS:** **`openMglFleetNativeFlow`** now **throws** (with a clear message) when **`!Capacitor.isNativePlatform()`** instead of resolving **`null`**, so Angular **`catch`/snackbars** fire when the SPA is opened in Chrome or **`ng serve` only**. Return type is **`Promise<FleetSdkSuccessPayload>`** (no **`null`**). Logs extra guidance when the native bridge reports **UNIMPLEMENTED** / missing plugin (**`npx cap sync`** + rebuild).
- **Native `FleetSdk`:** Run **`startActivity` (Android)** / **`present` (iOS)** on the **main thread** — Capacitor often calls plugins off the UI thread, which could previously result in no Fleet UI.
- **Capacitor `android`:** **`consumer-rules.pro`** + **`consumerProguardFiles`** so R8 does not drop **`FleetSdkPlugin`** in release builds.

## 0.1.0

- Initial npm publish train (`MGLFleetSdk` Capacitor plugin; TypeScript facade).
