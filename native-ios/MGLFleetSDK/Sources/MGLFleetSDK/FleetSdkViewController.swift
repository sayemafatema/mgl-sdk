import UIKit

final class FleetSdkViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let titleLabel = UILabel()
        titleLabel.text = "MGL Fleet SDK"
        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let subtitle = UILabel()
        subtitle.text = "Native shell (parity UI replaces this placeholder)."
        subtitle.font = .preferredFont(forTextStyle: .body)
        subtitle.numberOfLines = 0
        subtitle.translatesAutoresizingMaskIntoConstraints = false

        let complete = UIButton(type: .system)
        complete.setTitle("Complete flow", for: .normal)
        complete.backgroundColor = UIColor(red: 4 / 255, green: 120 / 255, blue: 87 / 255, alpha: 1)
        complete.setTitleColor(.white, for: .normal)
        complete.layer.cornerRadius = 8
        complete.translatesAutoresizingMaskIntoConstraints = false
        complete.addTarget(self, action: #selector(onComplete), for: .touchUpInside)

        let cancel = UIButton(type: .system)
        cancel.setTitle("Cancel", for: .normal)
        cancel.translatesAutoresizingMaskIntoConstraints = false
        cancel.addTarget(self, action: #selector(onCancel), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitle, complete, cancel])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            stack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            complete.heightAnchor.constraint(equalToConstant: 48),
        ])

        FleetPresentationBridge.emit(
            name: "FLOW_STARTED",
            payload: FleetPresentationBridge.pendingSession?.correlationId.map { ["correlationId": $0] },
        )
    }

    @objc private func onComplete() {
        guard let opts = FleetSdk.shared.snapshotOptions() else {
            finish(with: .failure(FleetSdkError(code: .notInitialized, message: "FleetSdk.initialize required.")))
            return
        }
        let client = FleetApiClient(options: opts)
        client.listDrivers { result in
            DispatchQueue.main.async {
                switch result {
                case let .success(drivers):
                    let id = drivers.first?.id ?? "unknown"
                    self.finish(
                        with: .success(
                            event: "FLEET_FLOW_COMPLETED",
                            payload: ["driverId": id, "driverCount": drivers.count],
                        ),
                    )
                case let .failure(err):
                    let fleetErr = FleetSdkError(code: .networkError, message: err.localizedDescription)
                    self.finish(with: .failure(fleetErr))
                }
            }
        }
    }

    @objc private func onCancel() {
        finish(
            with: .failure(FleetSdkError(code: .userCancelled, message: "User cancelled.")),
        )
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
