import SwiftUI
import UIKit

final class FleetSdkViewController: UIViewController {
    private var nativeBackHandler: (() -> Bool)?
    private var edgeBackGesture: UIScreenEdgePanGestureRecognizer?
    private var completionHandled = false

    func registerNativeBackHandler(_ handler: @escaping () -> Bool) {
        nativeBackHandler = handler
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let edge = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleNativeBackGesture))
        edge.edges = .left
        view.addGestureRecognizer(edge)
        edgeBackGesture = edge

        FleetPresentationBridge.emit(
            name: "FLOW_STARTED",
            payload: FleetPresentationBridge.pendingSession?.correlationId.map { ["correlationId": $0] },
        )

        let options =
            FleetSdk.shared.snapshotOptions()
            ?? FleetSdkOptions(apiBaseUrl: "http://localhost", useMock: true)

        let root = FleetDriverNativeView(onFinish: { [weak self] result in
            self?.finish(with: result)
        }, options: options)

        let host = UIHostingController(rootView: root)
        embed(host)
    }

    private func embed(_ child: UIViewController) {
        addChild(child)
        child.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(child.view)
        NSLayoutConstraint.activate([
            child.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            child.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            child.view.topAnchor.constraint(equalTo: view.topAnchor),
            child.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        child.didMove(toParent: self)
    }

    @objc private func handleNativeBackGesture() {
        _ = nativeBackHandler?()
    }

    override var keyCommands: [UIKeyCommand]? {
        [
            UIKeyCommand(
                input: UIKeyCommand.inputEscape,
                modifierFlags: [],
                action: #selector(handleNativeBackGesture),
            ),
        ]
    }

    override var canBecomeFirstResponder: Bool { true }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }

    private func finish(with result: FleetSdkResult) {
        guard !completionHandled else { return }
        completionHandled = true
        let completion = FleetPresentationBridge.pendingCompletion
        FleetPresentationBridge.pendingCompletion = nil
        FleetPresentationBridge.pendingSession = nil
        dismiss(animated: true) {
            completion?(result)
        }
    }
}
