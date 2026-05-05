import Foundation
import React
import UIKit

#if canImport(MGLFleetSDK)
import MGLFleetSDK
#endif

@objc(MglFleetSdk)
class MglFleetSdk: NSObject {

    @objc static func requiresMainQueueSetup() -> Bool {
        true
    }

    @objc func initialize(_ opts: NSDictionary, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        #if canImport(MGLFleetSDK)
        guard let apiBaseUrl = opts["apiBaseUrl"] as? String else {
            reject("BAD_ARGS", "apiBaseUrl required", nil)
            return
        }
        let useMock = opts["useMock"] as? Bool ?? true
        let authToken = opts["authToken"] as? String
        FleetSdk.shared.initialize(options: FleetSdkOptions(apiBaseUrl: apiBaseUrl, authToken: authToken, useMock: useMock))
        resolve(nil)
        #else
        reject(
            "NO_NATIVE_SDK",
            "Add native-ios/MGLFleetSDK via SPM to the app target — see docs/README.NATIVE-SDK.md",
            nil,
        )
        #endif
    }

    @objc func presentFleetFlow(_ opts: NSDictionary?, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        #if canImport(MGLFleetSDK)
        DispatchQueue.main.async {
            guard let presenter = Self.presentingViewController() else {
                reject("NO_ACTIVITY", "No root view controller", nil)
                return
            }
            let correlationId = opts?["correlationId"] as? String
            let session = correlationId.map { FleetSessionOptions(correlationId: $0) }
            do {
                try FleetSdk.shared.presentFleetFlow(from: presenter, session: session) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case let .success(event, payload):
                            resolve(["event": event, "payload": payload])
                        case let .failure(err):
                            reject(String(err.code.rawValue), err.message, nil)
                        }
                    }
                }
            } catch let err as FleetSdkError {
                reject(String(err.code.rawValue), err.message, nil)
            } catch {
                reject("INTERNAL", error.localizedDescription, nil)
            }
        }
        #else
        reject(
            "NO_NATIVE_SDK",
            "Add native-ios/MGLFleetSDK via SPM to the app target — see docs/README.NATIVE-SDK.md",
            nil,
        )
        #endif
    }

    private static func presentingViewController() -> UIViewController? {
        guard let root = rootViewController() else { return nil }
        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }

    private static func rootViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return nil }
        let window = scene.windows.first { $0.isKeyWindow } ?? scene.windows.first
        return window?.rootViewController
    }
}
