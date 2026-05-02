import Foundation

enum FleetPresentationBridge {
    static var pendingSession: FleetSessionOptions?
    static var pendingCompletion: FleetSdkCompletionHandler?
    static var listeners: [(String, FleetSdkEventListener)] = []

    static func emit(name: String, payload: [String: Any]? = nil) {
        listeners.forEach { _, listener in
            listener.onEvent(name: name, payload: payload)
        }
    }
}
