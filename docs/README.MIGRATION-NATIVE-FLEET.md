# Migrating from Dart-only / Angular-only Fleet SDKs

The repositories under **`flutter-sdk/`** and **`angular-sdk/`** remain useful references for UX parity and OpenAPI-aligned behaviour, but **new mobile integrations should prefer**:

| Host | Preferred integration |
|------|------------------------|
| Angular + Capacitor | `@mgl/capacitor-fleet-sdk` calling Kotlin/Swift cores ([README.NATIVE-SDK.md](./README.NATIVE-SDK.md)) |
| Flutter | `mgl_fleet_native_sdk` plugin ([README.NATIVE-SDK.md](./README.NATIVE-SDK.md)) |
| React Native | `@mgl/react-native-fleet-sdk` ([README.NATIVE-SDK.md](./README.NATIVE-SDK.md)) |

**Publishing / versions (maintainers):** [PUBLISH_FOR_EXTERNAL_CONSUMERS.md](./PUBLISH_FOR_EXTERNAL_CONSUMERS.md) · [VERSIONS.md](./VERSIONS.md)

## Why migrate?

- Installable artifacts (Maven / npm / pub) instead of copying `src/lib` trees.
- Full-screen **`presentFleetFlow`** semantics align with industry SDK patterns (Digitap-class lifecycle).
- Shared REST contract remains [`openapi/fleet-api.yaml`](openapi/fleet-api.yaml); native cores duplicate networking + UI per OS.

## Web-only hosts

If you ship **browser-only Angular** without Capacitor, you may continue embedding **`angular-sdk`** until a hosted WebView shell lands inside native wrappers—document team preference separately.
