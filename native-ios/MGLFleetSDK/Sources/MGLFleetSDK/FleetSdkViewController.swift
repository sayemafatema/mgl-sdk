import SwiftUI
import UIKit

final class FleetSdkViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        FleetPresentationBridge.emit(
            name: "FLOW_STARTED",
            payload: FleetPresentationBridge.pendingSession?.correlationId.map { ["correlationId": $0] },
        )

        let root = FleetDriverNativeView { [weak self] result in
            self?.finish(with: result)
        }

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

    private func finish(with result: FleetSdkResult) {
        let completion = FleetPresentationBridge.pendingCompletion
        FleetPresentationBridge.pendingCompletion = nil
        FleetPresentationBridge.pendingSession = nil
        dismiss(animated: true) {
            completion?(result)
        }
    }
}
