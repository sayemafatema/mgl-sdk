import UIKit

public final class FleetSdk {
    public static let shared = FleetSdk()

    private var options: FleetSdkOptions?
    private let lock = NSLock()

    private init() {}

    /// Snapshot for internal callers (tests).
    func snapshotOptions() -> FleetSdkOptions? {
        lock.lock()
        defer { lock.unlock() }
        return options
    }

    public func initialize(options: FleetSdkOptions) {
        lock.lock()
        defer { lock.unlock() }
        self.options = options
    }

    /// Present fullscreen Fleet flow modally from `viewController`.
    public func presentFleetFlow(
        from viewController: UIViewController,
        session: FleetSessionOptions? = nil,
        completion: @escaping FleetSdkCompletionHandler,
    ) throws {
        lock.lock()
        let opts = options
        lock.unlock()

        guard opts != nil else {
            throw FleetSdkError(code: .notInitialized, message: "FleetSdk.initialize required.")
        }

        FleetPresentationBridge.pendingSession = session
        FleetPresentationBridge.pendingCompletion = completion

        let vc = FleetSdkViewController()
        vc.modalPresentationStyle = .fullScreen
        viewController.present(vc, animated: true)
    }

    public func addListener(tag: String, listener: FleetSdkEventListener) {
        FleetPresentationBridge.listeners.append((tag, listener))
    }

    public func removeListener(tag: String) {
        FleetPresentationBridge.listeners.removeAll { $0.0 == tag }
    }
}
