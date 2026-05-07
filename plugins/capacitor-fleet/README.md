# @mgl/capacitor-fleet-sdk

Capacitor bridge for **MGL Fleet** native cores (**`fleet-android`** + **`MGLFleetSDK`**).

## Host integration

See **[`docs/README.NATIVE-SDK.md`](../../docs/README.NATIVE-SDK.md)** and **[`docs/README.INTEGRATION-ANGULAR-CAPACITOR-NATIVE.md`](../../docs/README.INTEGRATION-ANGULAR-CAPACITOR-NATIVE.md)**.

From the host app import **`openMglFleetNativeFlow`** (not only **`presentFleetFlow`**) so **`initialize`** runs before the native fullscreen flow.

## Maintainer publish

```bash
npm ci && npm run build
npm publish --access public
```

Replace **`YOUR_ORG`** in **`package.json`** **`repository`** / **`homepage`** before tagging. Operator checklist: **[`docs/PUBLISH_FOR_EXTERNAL_CONSUMERS.md`](../../docs/PUBLISH_FOR_EXTERNAL_CONSUMERS.md)**.
