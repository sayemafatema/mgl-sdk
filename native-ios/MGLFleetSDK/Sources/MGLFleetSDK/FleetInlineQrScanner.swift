import AVFoundation
import AudioToolbox
import SwiftUI

/// Inline QR preview in Scan & Pay card (Android `FleetInlineQrScanner` parity).
struct FleetInlineQrScanner: View {
    let active: Bool
    let scanResetKey: String
    let onBarcodeRaw: (String) -> Void

    @State private var permissionGranted = false
    @State private var permissionChecked = false

    var body: some View {
        ZStack {
            Color.black
            if active, permissionGranted {
                FleetInlineQrRepresentable(scanResetKey: scanResetKey, onDecode: onBarcodeRaw)
                    .id(scanResetKey)
            } else if active, permissionChecked, !permissionGranted {
                Text("Camera permission is required to scan the POS QR code.")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(16)
            } else {
                Image(systemName: "qrcode")
                    .font(.system(size: 48))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear { refreshPermission() }
        .onChange(of: active) { _, isActive in
            if isActive { refreshPermission() }
        }
    }

    private func refreshPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
            permissionChecked = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { ok in
                DispatchQueue.main.async {
                    permissionGranted = ok
                    permissionChecked = true
                }
            }
        default:
            permissionGranted = false
            permissionChecked = true
        }
    }
}

private struct FleetInlineQrRepresentable: UIViewControllerRepresentable {
    let scanResetKey: String
    let onDecode: (String) -> Void

    func makeUIViewController(context: Context) -> InlineQrScannerViewController {
        let vc = InlineQrScannerViewController()
        vc.onString = onDecode
        return vc
    }

    func updateUIViewController(_ uiViewController: InlineQrScannerViewController, context: Context) {
        uiViewController.resetDecodeLatch()
        if !uiViewController.session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                uiViewController.session.startRunning()
            }
        }
    }
}

/// Reuses capture pipeline; decode latch resets when [scanResetKey] changes.
final class InlineQrScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onString: ((String) -> Void)?
    let session = AVCaptureSession()
    private var decodedOnce = false

    func resetDecodeLatch() {
        decodedOnce = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configureSession()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.layer.sublayers?
            .compactMap { $0 as? AVCaptureVideoPreviewLayer }
            .forEach { $0.frame = view.bounds }
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
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.frame = view.bounds
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)
        session.commitConfiguration()
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection,
    ) {
        guard !decodedOnce else { return }
        guard
            let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
            obj.type == .qr,
            let s = obj.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines),
            !s.isEmpty
        else { return }
        decodedOnce = true
        if session.isRunning { session.stopRunning() }
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        onString?(s)
    }

    deinit {
        if session.isRunning { session.stopRunning() }
    }
}
