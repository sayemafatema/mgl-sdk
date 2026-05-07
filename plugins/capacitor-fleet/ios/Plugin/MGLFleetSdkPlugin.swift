import Capacitor
import Foundation
#if canImport(MGLFleetSDK)
import MGLFleetSDK
#endif

@objc(MGLFleetSdkPlugin)
public class MGLFleetSdkPlugin: CAPPlugin {

    @objc func initialize(_ call: CAPPluginCall) {
        #if canImport(MGLFleetSDK)
        guard let apiBaseUrlRaw = call.getString("apiBaseUrl"),
              !apiBaseUrlRaw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            call.reject("apiBaseUrl is required and must not be blank")
            return
        }
        let apiBaseUrl = apiBaseUrlRaw.trimmingCharacters(in: .whitespacesAndNewlines)
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
        guard FleetSdk.shared.isInitialized() else {
            call.reject(
                "Fleet SDK is not initialized. Use openFleetNativeFlow() / openMglFleetNativeFlow() or await initialize() before presentFleetFlow().",
                "NOT_INITIALIZED",
                nil,
            )
            return
        }
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
                        call.reject(err.message, String(err.code.rawValue), err)
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

    /// Single bridge call: initialize then present (matches Android / TS `openFleetNativeFlow`).
    @objc func openFleetNativeFlow(_ call: CAPPluginCall) {
        #if canImport(MGLFleetSDK)
        guard let initBlock = call.options["initialize"] as? JSObject else {
            call.reject("initialize object is required")
            return
        }
        guard let apiBaseUrlRaw = initBlock["apiBaseUrl"] as? String else {
            call.reject("apiBaseUrl is required")
            return
        }
        let apiBaseUrl = apiBaseUrlRaw.trimmingCharacters(in: .whitespacesAndNewlines)
        if apiBaseUrl.isEmpty {
            call.reject("apiBaseUrl must not be blank")
            return
        }
        let useMock = initBlock["useMock"] as? Bool ?? true
        let authToken = initBlock["authToken"] as? String

        FleetSdk.shared.initialize(
            options: FleetSdkOptions(apiBaseUrl: apiBaseUrl, authToken: authToken, useMock: useMock),
        )

        guard let vc = bridge?.viewController else {
            call.reject("No Capacitor bridge view controller")
            return
        }
        call.keepAlive = true

        let present = call.options["present"] as? JSObject
        let correlationId = present?["correlationId"] as? String
        let session = correlationId.map { FleetSessionOptions(correlationId: $0) }

        do {
            try FleetSdk.shared.presentFleetFlow(from: vc, session: session) { result in
                DispatchQueue.main.async {
                    switch result {
                    case let .success(event, payload):
                        call.resolve(["event": event, "payload": payload])
                    case let .failure(err):
                        call.reject(err.message, String(err.code.rawValue), err)
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
