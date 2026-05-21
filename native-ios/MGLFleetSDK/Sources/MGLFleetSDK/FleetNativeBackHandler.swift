import SwiftUI
import UIKit

/// Registers Android `BackHandler` parity on `FleetSdkViewController` (edge-swipe + Escape).
struct FleetNativeBackHandlerRegistration: UIViewControllerRepresentable {
    let onBack: () -> Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(onBack: onBack)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        vc.view.isHidden = true
        vc.view.isUserInteractionEnabled = false
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        let handler = context.coordinator.onBack
        DispatchQueue.main.async {
            if let fleet = findFleetSdkViewController(from: uiViewController) {
                fleet.registerNativeBackHandler(handler)
            }
        }
    }

    private func findFleetSdkViewController(from vc: UIViewController) -> FleetSdkViewController? {
        var current: UIViewController? = vc
        while let c = current {
            if let fleet = c as? FleetSdkViewController { return fleet }
            current = c.parent
        }
        return nil
    }

    final class Coordinator {
        let onBack: () -> Bool
        init(onBack: @escaping () -> Bool) { self.onBack = onBack }
    }
}
