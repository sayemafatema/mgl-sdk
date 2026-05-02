import Flutter
import UIKit

#if canImport(MGLFleetSDK)
import MGLFleetSDK
#endif

public class MglFleetNativeSdkPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "mgl_fleet_native_sdk", binaryMessenger: registrar.messenger())
    let instance = MglFleetNativeSdkPlugin()
    channel.setMethodCallHandler(instance.handle(_:result:))
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initialize":
      #if canImport(MGLFleetSDK)
      guard let args = call.arguments as? [String: Any],
            let apiBaseUrl = args["apiBaseUrl"] as? String else {
        result(FlutterError(code: "BAD_ARGS", message: "apiBaseUrl required", details: nil))
        return
      }
      let useMock = args["useMock"] as? Bool ?? true
      let authToken = args["authToken"] as? String
      FleetSdk.shared.initialize(options: FleetSdkOptions(apiBaseUrl: apiBaseUrl, authToken: authToken, useMock: useMock))
      result(nil)
      #else
      result(
        FlutterError(
          code: "NO_NATIVE_SDK",
          message: "Add native-ios/MGLFleetSDK as an SPM dependency to the Runner target — see docs/README.NATIVE-SDK.md",
          details: nil,
        ),
      )
      #endif

    case "presentFleetFlow":
      #if canImport(MGLFleetSDK)
      guard let presenter = Self.presentingViewController() else {
        result(FlutterError(code: "NO_ACTIVITY", message: "No root view controller", details: nil))
        return
      }
      let args = call.arguments as? [String: Any] ?? [:]
      let correlationId = args["correlationId"] as? String
      let session = correlationId.map { FleetSessionOptions(correlationId: $0) }

      do {
        try FleetSdk.shared.presentFleetFlow(from: presenter, session: session) { sdkResult in
          DispatchQueue.main.async {
            switch sdkResult {
            case let .success(event, payload):
              result(["event": event, "payload": payload])
            case let .failure(err):
              result(FlutterError(code: String(err.code.rawValue), message: err.message, details: nil))
            }
          }
        }
      } catch let err as FleetSdkError {
        result(FlutterError(code: String(err.code.rawValue), message: err.message, details: nil))
      } catch {
        result(FlutterError(code: "INTERNAL", message: error.localizedDescription, details: nil))
      }
      #else
      result(
        FlutterError(
          code: "NO_NATIVE_SDK",
          message: "Add native-ios/MGLFleetSDK as an SPM dependency to the Runner target — see docs/README.NATIVE-SDK.md",
          details: nil,
        ),
      )
      #endif

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private static func presentingViewController() -> UIViewController? {
    guard let root = rootViewController() else { return nil }
    return topPresented(from: root)
  }

  private static func rootViewController() -> UIViewController? {
    guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return nil }
    let window = scene.windows.first { $0.isKeyWindow } ?? scene.windows.first
    return window?.rootViewController
  }

  private static func topPresented(from root: UIViewController) -> UIViewController {
    var top = root
    while let presented = top.presentedViewController {
      top = presented
    }
    return top
  }
}
