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
      handleInitialize(call, result: result)
    case "isInitialized":
      #if canImport(MGLFleetSDK)
      result(FleetSdk.shared.isInitialized())
      #else
      result(FlutterError(code: "NO_NATIVE_SDK", message: Self.noSdkMessage, details: nil))
      #endif
    case "presentFleetFlow":
      handlePresent(call, result: result)
    case "openFleetNativeFlow":
      handleOpenFleetNativeFlow(call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  #if canImport(MGLFleetSDK)
  private func handleInitialize(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let apiBaseUrl = (args["apiBaseUrl"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
          !apiBaseUrl.isEmpty else {
      result(FlutterError(code: "BAD_ARGS", message: "apiBaseUrl required", details: nil))
      return
    }
    let useMock = args["useMock"] as? Bool ?? true
    let authToken = args["authToken"] as? String
    let foCompanyId = Self.readFoCompanyId(fromAny: args["foCompanyId"])
    FleetSdk.shared.initialize(
      options: FleetSdkOptions(
        apiBaseUrl: apiBaseUrl,
        authToken: authToken,
        useMock: useMock,
        foCompanyId: foCompanyId,
      ),
    )
    result(nil)
  }

  private func handleOpenFleetNativeFlow(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let root = call.arguments as? [String: Any],
          let initBlock = root["initialize"] as? [String: Any],
          let apiBaseUrl = (initBlock["apiBaseUrl"] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
          !apiBaseUrl.isEmpty else {
      result(FlutterError(code: "BAD_ARGS", message: "initialize.apiBaseUrl required", details: nil))
      return
    }
    let useMock = initBlock["useMock"] as? Bool ?? true
    let authToken = initBlock["authToken"] as? String
    let foCompanyId = Self.readFoCompanyId(fromAny: initBlock["foCompanyId"])
    FleetSdk.shared.initialize(
      options: FleetSdkOptions(
        apiBaseUrl: apiBaseUrl,
        authToken: authToken,
        useMock: useMock,
        foCompanyId: foCompanyId,
      ),
    )
    let present = root["present"] as? [String: Any]
    executePresent(presentArgs: present, result: result)
  }

  private func handlePresent(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard FleetSdk.shared.isInitialized() else {
      result(
        FlutterError(
          code: "NOT_INITIALIZED",
          message:
            "Fleet SDK is not initialized. Use openFleetNativeFlow() or await initialize() before presentFleetFlow().",
          details: nil,
        ),
      )
      return
    }
    let args = call.arguments as? [String: Any]
    executePresent(presentArgs: args, result: result)
  }

  private func executePresent(presentArgs: [String: Any]?, result: @escaping FlutterResult) {
    guard let presenter = Self.presentingViewController() else {
      result(FlutterError(code: "NO_ACTIVITY", message: "No root view controller", details: nil))
      return
    }
    let correlationId = presentArgs?["correlationId"] as? String
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
      result(FlutterError(code: "1004", message: error.localizedDescription, details: nil))
    }
  }
  #endif

  #if !canImport(MGLFleetSDK)
  private func handleInitialize(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result(FlutterError(code: "NO_NATIVE_SDK", message: Self.noSdkMessage, details: nil))
  }

  private func handleOpenFleetNativeFlow(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result(FlutterError(code: "NO_NATIVE_SDK", message: Self.noSdkMessage, details: nil))
  }

  private func handlePresent(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result(FlutterError(code: "NO_NATIVE_SDK", message: Self.noSdkMessage, details: nil))
  }
  #endif

  private static let noSdkMessage =
    "Link MGLFleetSDK to the iOS Runner target (SPM or CocoaPods). See plugins/flutter-fleet/mgl_fleet_native_sdk/README.md"

  private static func readFoCompanyId(fromAny raw: Any?) -> Int64? {
    guard let raw else { return nil }
    if let i = raw as? Int64 { return i }
    if let i = raw as? Int { return Int64(i) }
    if let n = raw as? NSNumber { return n.int64Value }
    if let d = raw as? Double { return Int64(d) }
    if let s = raw as? String { return Int64(s.trimmingCharacters(in: .whitespacesAndNewlines)) }
    return nil
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
