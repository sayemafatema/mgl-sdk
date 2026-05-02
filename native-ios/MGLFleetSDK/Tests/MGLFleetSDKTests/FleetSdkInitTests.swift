import XCTest
@testable import MGLFleetSDK

final class FleetSdkInitTests: XCTestCase {
    func testInitializeStoresOptions() {
        FleetSdk.shared.initialize(options: FleetSdkOptions(apiBaseUrl: "https://api.example.com", useMock: true))
        XCTAssertNotNil(FleetSdk.shared.snapshotOptions())
    }
}
