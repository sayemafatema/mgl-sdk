# MGLFleetSDK (Swift)

Native iOS Fleet shell + API client consumed by **`@mgl/capacitor-fleet-sdk`**, **`mgl_fleet_native_sdk`**, and **`@mgl/react-native-fleet-sdk`** after **`MGLFleetSDK`** is linked to the host app target.

## Consumers

**Swift Package Manager — monorepo URL**

Root **[`Package.swift`](../../Package.swift)** exposes product **`MGLFleetSDK`**:

```swift
.package(url: "https://github.com/YOUR_ORG/mgl-sdk.git", from: "0.1.0")
```

**Local development**

Open **File → Add Local Packages…** in Xcode → select this **`MGLFleetSDK`** folder **or** the repo root.

**CocoaPods**

See **[`MGLFleetSDK.podspec`](./MGLFleetSDK.podspec)** and **[`docs/PUBLISH_FOR_EXTERNAL_CONSUMERS.md`](../../docs/PUBLISH_FOR_EXTERNAL_CONSUMERS.md)**.

## Maintainer publish

Replace **`YOUR_ORG`** placeholders in **`MGLFleetSDK.podspec`**, tag Git (**`X.Y.Z`**), then follow **`docs/PUBLISH_FOR_EXTERNAL_CONSUMERS.md`**.
