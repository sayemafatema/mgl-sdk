import Capacitor
import Foundation
#if canImport(MGLFleetSDK)
import MGLFleetSDK
#endif

@objc(MGLFleetSdkPlugin)
public class MGLFleetSdkPlugin: CAPPlugin {

    @objc func initialize(_ call: CAPPluginCall) {
        #if canImport(MGLFleetSDK)
        guard let apiBaseUrl = call.getString("apiBaseUrl") else {
            call.reject("apiBaseUrl is required")
            return
        }
        let useMock = call.getBool("useMock") ?? true
        let authToken = call.getString("authToken")
        FleetSdk.shared.initialize(options: FleetSdkOptions(apiBaseUrl: apiBaseUrl, authToken: authToken, useMock: useMock))
        call.resolve()
        #else
        call.reject("Add local Swift package ../../../native-ios/MGLFleetSDK to the iOS app target — see docs/README.NATIVE-SDK.md")
        #endif
    }

    @objc func presentFleetFlow(_ call: CAPPluginCall) {
        #if canImport(MGLFleetSDK)
        guard let vc = bridge?.viewController else {
            call.reject("No Capacitor bridge view controller")
            return
        }
        call.keepAlive = true
        let correlationId = call.getString("correlationId")
        let session = correlationId.map { FleetSessionOptions(correlationId: $0) }

        do {
            try FleetSdk.shared.presentFleetFlow(from: vc, session: session) { result in
                DispatchQueue.main.async {
                    switch result {
                    case let .success(event, payload):
                        call.resolve(["event": event, "payload": payload])
                    case let .failure(err):
                        call.reject(err.message, nil, String(err.code.rawValue))
                    }
                }
            }
        } catch {
            call.reject(error.localizedDescription)
        }
        #else
        call.reject("Add local Swift package ../../../native-ios/MGLFleetSDK — see docs/README.NATIVE-SDK.md")
        #endif
    }
}
