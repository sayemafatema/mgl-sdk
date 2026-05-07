# Changelog

## Unreleased

- **Android:** Depend on **`project(':capacitor-android')`** instead of Maven **`com.capacitorjs:capacitor-android`** so host apps resolve Capacitor core from **`node_modules`** (standard Capacitor plugin pattern).
- **JS:** **`openMglFleetNativeFlow()`** exported so host apps always call **`initialize`** before **`presentFleetFlow`** (fixes “button does nothing” when only **`presentFleetFlow`** was used).

## 0.1.0

- Initial npm publish train (`MGLFleetSdk` Capacitor plugin; TypeScript facade).
