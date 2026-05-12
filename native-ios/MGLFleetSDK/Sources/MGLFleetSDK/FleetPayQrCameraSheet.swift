import SwiftUI
import AVFoundation
import AudioToolbox

/// Camera QR capture for Fleetpay URIs (`fleetpay://...`). Host app must declare `NSCameraUsageDescription` in `Info.plist`.
struct FleetPayQrCameraSheet: View {
    let onDecoded: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            FleetPayQrCameraRepresentable(onDecode: { payload in
                onDecoded(payload)
                dismiss()
            })
                .ignoresSafeArea()
                .navigationTitle("Scan QR")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
                    }
                }
        }
    }
}

struct FleetPayQrCameraRepresentable: UIViewControllerRepresentable {
    let onDecode: (String) -> Void

    func makeUIViewController(context: Context) -> QrScannerViewController {
        let vc = QrScannerViewController()
        vc.onString = onDecode
        return vc
    }

    func updateUIViewController(_ uiViewController: QrScannerViewController, context: Context) {}
}

final class QrScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onString: ((String) -> Void)?
    private let session = AVCaptureSession()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        AVCaptureDevice.requestAccess(for: .video) { [weak self] ok in
            DispatchQueue.main.async {
                guard let self else { return }
                if ok { self.configureSession() }
            }
        }
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .high

        guard
            let device = AVCaptureDevice.default(for: .video),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            session.commitConfiguration()
            return
        }
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else {
            session.commitConfiguration()
            return
        }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        output.metadataObjectTypes = [.qr]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.frame = view.bounds
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)

        session.commitConfiguration()
        session.startRunning()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.layer.sublayers?.compactMap { $0 as? AVCaptureVideoPreviewLayer }.forEach { $0.frame = view.bounds }
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection,
    ) {
        guard
            let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
            obj.type == .qr,
            let s = obj.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines),
            !s.isEmpty
        else {
            return
        }
        if session.isRunning { session.stopRunning() }
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        onString?(s)
    }

    deinit {
        if session.isRunning { session.stopRunning() }
    }
}
