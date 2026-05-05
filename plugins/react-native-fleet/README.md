# @mgl/react-native-fleet-sdk

React Native bridge for **MGL Fleet** (**`fleet-android`** + **`MGLFleetSDK`** on iOS).

## Host integration

See **[`docs/README.NATIVE-SDK.md`](../../docs/README.NATIVE-SDK.md)**.

### Android

Register **`MglFleetSdkPackage`** in **`MainApplication`** if autolinking does not pick it up (see React Native docs).

### iOS

1. **`pod install`** after **`npm install`** (autolinking installs **`MglFleetSdk`** from **`MglFleetSdk.podspec`**).
2. Xcode → **App** target → **Package Dependencies** → add **`native-ios/MGLFleetSDK`** or monorepo Git URL (**root [`Package.swift`](../../Package.swift)**), product **`MGLFleetSDK`** — same as Capacitor/Flutter (**`#if canImport(MGLFleetSDK)`** must succeed).

## Maintainer publish

```bash
npm ci && npm run build
npm publish --access public
```

Replace **`YOUR_ORG`** in **`package.json`** / **`MglFleetSdk.podspec`** before tagging. **[`docs/PUBLISH_FOR_EXTERNAL_CONSUMERS.md`](../../docs/PUBLISH_FOR_EXTERNAL_CONSUMERS.md)**.
