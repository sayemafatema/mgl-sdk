# Changelog

## Unreleased

- **Android:** Depend on **`project(':capacitor-android')`** instead of Maven **`com.capacitorjs:capacitor-android`** so host apps resolve Capacitor core from **`node_modules`** (standard Capacitor plugin pattern).
- **JS:** **`@capacitor/core`** is a runtime **`dependency`** so bundlers resolve **`require('@capacitor/core')`** from **`dist/`**; run **`npm install`** in **`plugins/capacitor-fleet`** after clone.

## 0.1.0

- Initial npm publish train (`MGLFleetSdk` Capacitor plugin; TypeScript facade).
