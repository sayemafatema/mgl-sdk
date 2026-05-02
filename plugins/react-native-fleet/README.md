# @mgl/react-native-fleet-sdk

React Native bridge for **MGL Fleet** (**`fleet-android`** + **`MGLFleetSDK`** on iOS).

## Host integration

See **[`docs/README.NATIVE-SDK.md`](../../docs/README.NATIVE-SDK.md)**.

Android: register **`MglFleetSdkPackage`** in **`MainApplication`** per React Native docs.

## Maintainer publish

```bash
npm ci && npm run build
npm publish --access public
```

Replace **`YOUR_ORG`** in **`package.json`** **`repository`** / **`homepage`** before tagging. Operator checklist: **[`docs/PUBLISH_FOR_EXTERNAL_CONSUMERS.md`](../../docs/PUBLISH_FOR_EXTERNAL_CONSUMERS.md)**.
