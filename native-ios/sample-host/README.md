# iOS sample host (manual)

[`MGLFleetSDK`](../MGLFleetSDK/) ships as a Swift Package without an Xcode application target checked into this repo.

1. Create **iOS App** project in Xcode.
2. **File → Add Package Dependencies… → Add Local…** → select `native-ios/MGLFleetSDK`.
3. Link **`MGLFleetSDK`** product to the app target.
4. In `SceneDelegate` / `UIViewController`:

```swift
import MGLFleetSDK

FleetSdk.shared.initialize(options: FleetSdkOptions(apiBaseUrl: "https://api.example.com", useMock: true))

try FleetSdk.shared.presentFleetFlow(from: self, session: FleetSessionOptions(correlationId: "demo")) { result in
    switch result {
    case let .success(event, payload):
        print(event, payload)
    case let .failure(err):
        print(err.code.rawValue, err.message)
    }
}
```

Running SwiftPM tests:

```bash
swift test --package-path native-ios/MGLFleetSDK
```
