# Changelog

## Unreleased

- **Android:** Depend on **`project(':capacitor-android')`** instead of Maven **`com.capacitorjs:capacitor-android`** so host apps resolve Capacitor core from **`node_modules`** (standard Capacitor plugin pattern).
- **JS:** **`openMglFleetNativeFlow()`** validates **`apiBaseUrl`** (fills mock placeholder when empty + **`useMock`**), **`try/catch`** + **`console.error`** on failures; **`initialize`** rejects blank **`apiBaseUrl`** on Android/iOS.

## 0.1.0

- Initial npm publish train (`MGLFleetSdk` Capacitor plugin; TypeScript facade).
