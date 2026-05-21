import SwiftUI
import UIKit

private enum FleetSdkResourceBundle {
    static var bundle: Bundle {
        #if SWIFT_PACKAGE
        return .module
        #else
        if let url = Bundle(for: FleetSdk.self).url(forResource: "MGLFleetSDK", withExtension: "bundle"),
           let b = Bundle(url: url) {
            return b
        }
        return Bundle(for: FleetSdk.self)
        #endif
    }
}

// MARK: - Formatters (Android FleetDriverScreens parity)

func formatPayApiTxnDate(_ iso: String?) -> String {
    let t = iso?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    if t.isEmpty { return "—" }
    let isoFmt = ISO8601DateFormatter()
    isoFmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    var date = isoFmt.date(from: t)
    if date == nil {
        isoFmt.formatOptions = [.withInternetDateTime]
        date = isoFmt.date(from: t)
    }
    if let date {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_IN")
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }
    return t
}

func formatPrettyVrn(_ vrn: String?) -> String {
    let raw = (vrn ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
    if raw.isEmpty { return "—" }
    let upper = raw.uppercased()
    let pattern = #"^([A-Z]{2})(\d{2})([A-Z]{1,3})(\d{1,4})$"#
    if let re = try? NSRegularExpression(pattern: pattern),
       let m = re.firstMatch(in: upper, range: NSRange(upper.startIndex..., in: upper)),
       m.numberOfRanges == 5,
       let r1 = Range(m.range(at: 1), in: upper),
       let r2 = Range(m.range(at: 2), in: upper),
       let r3 = Range(m.range(at: 3), in: upper),
       let r4 = Range(m.range(at: 4), in: upper) {
        return "\(upper[r1]) \(upper[r2]) \(upper[r3]) \(upper[r4])"
    }
    return vrn?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        ? (vrn?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "—")
        : "—"
}

private func formatReceiptAmountDisplay(amountInr: Double) -> String {
    guard amountInr.isFinite else { return "—" }
    let f = NumberFormatter()
    f.locale = Locale(identifier: "en_IN")
    f.minimumFractionDigits = 0
    f.maximumFractionDigits = 2
    let n = f.string(from: NSNumber(value: amountInr)) ?? String(format: "%.2f", amountInr)
    return "₹\(n)"
}

// MARK: - Receipt row

struct ReceiptKvRow: View {
    let label: String
    let value: String
    var valueColor: Color = FleetParityColors.textPrimary

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color(red: 107 / 255, green: 114 / 255, blue: 128 / 255))
            Spacer(minLength: 8)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Mock authorized phase (Android ScanTab "authorized")

struct ScanAuthorizedParityView: View {
    let parsedQr: FleetpayQrPayloadIOS?
    let liveMode: Bool
    let lastPay: QrPayResultParsed?
    let onFuelingComplete: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(red: 209 / 255, green: 250 / 255, blue: 229 / 255))
                    .frame(width: 64, height: 64)
                Image(systemName: "checkmark")
                    .font(.title2.bold())
                    .foregroundStyle(FleetParityColors.green700)
            }
            Text("Fueling authorized")
                .font(.title2.bold())
            Text("Dispenser is now unlocked")
                .font(.subheadline)
                .foregroundStyle(FleetParityColors.textMuted)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 4) {
                let merchantName = (parsedQr?.merchantName ?? "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let station = merchantName.isEmpty ? (liveMode ? "—" : "Station") : merchantName
                Text(station)
                    .font(.caption)
                    .foregroundStyle(FleetParityColors.textMuted)
                let preAuth =
                    parsedQr.map { "₹\(DriverFleetQr.paiseToInrDisplay($0.amountPaise))" }
                        ?? (liveMode ? "—" : "1,200.00")
                Text("Pre-authorized: \(preAuth)")
                    .font(.subheadline.weight(.semibold))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(red: 229 / 255, green: 231 / 255, blue: 235 / 255)))

            Text("⚠ Do not leave the pump until fueling is complete")
                .font(.caption)
                .foregroundStyle(Color(red: 120 / 255, green: 53 / 255, blue: 15 / 255))
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(red: 255 / 255, green: 247 / 255, blue: 237 / 255))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(red: 251 / 255, green: 191 / 255, blue: 36 / 255)))

            VStack(spacing: 8) {
                Text("Dispensing")
                    .font(.caption)
                    .foregroundStyle(FleetParityColors.textMuted)
                if !liveMode {
                    Text("2.4 kg")
                        .font(.title.bold())
                    Text("₹384")
                        .font(.subheadline)
                        .foregroundStyle(FleetParityColors.textMuted)
                } else {
                    let qkg = lastPay?.quantityKg
                    Text(
                        qkg != nil && qkg!.isFinite
                            ? String(format: "%.1f kg", qkg!)
                            : "—",
                    )
                    .font(.title.bold())
                    if let pq = parsedQr {
                        let inr = Double(pq.amountPaise) / 100.0
                        let cur = NumberFormatter()
                        cur.locale = Locale(identifier: "en_IN")
                        cur.numberStyle = .currency
                        cur.currencyCode = "INR"
                        Text(inr.isFinite ? (cur.string(from: NSNumber(value: inr)) ?? "—") : "—")
                            .font(.subheadline)
                            .foregroundStyle(FleetParityColors.textMuted)
                    } else {
                        Text("—")
                            .font(.subheadline)
                            .foregroundStyle(FleetParityColors.textMuted)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(Color(red: 249 / 255, green: 250 / 255, blue: 251 / 255))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Button("Fueling Complete", action: onFuelingComplete)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .buttonStyle(.borderedProminent)
                .tint(FleetParityColors.green700)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Complete receipt (Android ScanTab "complete")

struct ScanCompleteReceiptParityView: View {
    let activeBinding: DemoBinding
    let parsedQr: FleetpayQrPayloadIOS?
    let lastPay: QrPayResultParsed?
    let liveMode: Bool
    let receiptDriverName: String?
    let onSessionDone: () -> Void

    private var payFailed: Bool {
        liveMode && lastPay?.status?.uppercased() == "FAILED"
    }

    private var amountInr: Double {
        if let p = lastPay?.amountINR, p.isFinite { return p }
        if let pq = parsedQr { return Double(pq.amountPaise) / 100.0 }
        return .nan
    }

    var body: some View {
        let amountDisplay = formatReceiptAmountDisplay(amountInr: amountInr)
        let stationName =
            parsedQr?.merchantName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                ? (parsedQr?.merchantName ?? "—")
                : "—"
        let vrnPretty = formatPrettyVrn(lastPay?.vehicleRegNo ?? activeBinding.vrn)
        let txnIdDisp = lastPay?.serverTxnId?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? (lastPay?.serverTxnId ?? "—")
            : "—"
        let txnDateDisp = formatPayApiTxnDate(lastPay?.txnTime)
        let newBalRaw = lastPay?.newBalanceINR
        let newBalDisp: String? =
            if !payFailed, let b = newBalRaw, b.isFinite {
                formatReceiptAmountDisplay(amountInr: b)
            } else {
                nil
            }
        let authLine = lastPay?.authCode?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        VStack(spacing: 12) {
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    if payFailed {
                        ZStack {
                            Circle()
                                .fill(Color(red: 220 / 255, green: 38 / 255, blue: 38 / 255))
                                .frame(width: 64, height: 64)
                            Image(systemName: "xmark")
                                .font(.title.bold())
                                .foregroundStyle(.white)
                        }
                        Text("Transaction Failed")
                            .font(.title3.bold())
                            .foregroundStyle(Color(red: 185 / 255, green: 28 / 255, blue: 28 / 255))
                    } else {
                        ZStack {
                            Circle()
                                .fill(Color(red: 46 / 255, green: 125 / 255, blue: 50 / 255))
                                .frame(width: 64, height: 64)
                            Image(systemName: "checkmark")
                                .font(.title.bold())
                                .foregroundStyle(.white)
                        }
                        Text("Fueling Complete")
                            .font(.title3.bold())
                            .foregroundStyle(Color(red: 46 / 255, green: 125 / 255, blue: 50 / 255))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)

                VStack(spacing: 8) {
                    FleetReceiptLogoBadge()
                    Text("Official Receipt")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color(red: 6 / 255, green: 78 / 255, blue: 59 / 255))

                VStack(spacing: 0) {
                    ReceiptKvRow(label: "Station", value: stationName)
                    Divider().background(Color(red: 243 / 255, green: 244 / 255, blue: 246 / 255))
                    ReceiptKvRow(label: "Vehicle", value: vrnPretty)
                    if let name = receiptDriverName?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
                        Divider().background(Color(red: 243 / 255, green: 244 / 255, blue: 246 / 255))
                        ReceiptKvRow(label: "Driver", value: name)
                    }
                    if payFailed {
                        Divider().background(Color(red: 243 / 255, green: 244 / 255, blue: 246 / 255))
                        ReceiptKvRow(label: "Status", value: "FAILED", valueColor: Color(red: 220 / 255, green: 38 / 255, blue: 38 / 255))
                    }
                    Divider().background(Color(red: 243 / 255, green: 244 / 255, blue: 246 / 255))
                    ReceiptKvRow(
                        label: "Amount",
                        value: amountDisplay,
                        valueColor: payFailed
                            ? Color(red: 220 / 255, green: 38 / 255, blue: 38 / 255)
                            : Color(red: 46 / 255, green: 125 / 255, blue: 50 / 255),
                    )
                    if !payFailed, let bal = newBalDisp {
                        Divider().background(Color(red: 243 / 255, green: 244 / 255, blue: 246 / 255))
                        ReceiptKvRow(label: "New balance", value: bal, valueColor: Color(red: 46 / 255, green: 125 / 255, blue: 50 / 255))
                    }
                    if !authLine.isEmpty {
                        Divider().background(Color(red: 243 / 255, green: 244 / 255, blue: 246 / 255))
                        ReceiptKvRow(label: "Auth code", value: authLine)
                    }
                    Divider().padding(.vertical, 8)
                    Text(txnIdDisp == "—" ? "TXN ID: —" : "TXN ID: \(txnIdDisp)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color(red: 107 / 255, green: 114 / 255, blue: 128 / 255))
                        .frame(maxWidth: .infinity)
                    Text(txnDateDisp)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color(red: 107 / 255, green: 114 / 255, blue: 128 / 255))
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 16)
                }
                .padding(.horizontal, 16)
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(FleetParityColors.cardBorder))

            Button("Done", action: onSessionDone)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .buttonStyle(.borderedProminent)
                .tint(payFailed ? Color(red: 55 / 255, green: 65 / 255, blue: 81 / 255) : Color(red: 46 / 255, green: 125 / 255, blue: 50 / 255))

            Button {
                FleetFuelingReceiptShare.share(
                    payFailed: payFailed,
                    station: stationName,
                    vehicle: vrnPretty,
                    driverName: receiptDriverName?.trimmingCharacters(in: .whitespacesAndNewlines),
                    amountDisplay: amountDisplay,
                    newBalance: newBalDisp,
                    authCode: authLine.isEmpty ? nil : authLine,
                    txnId: txnIdDisp,
                    txnDate: txnDateDisp,
                )
            } label: {
                Text("Share receipt")
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.bordered)
            .tint(Color(red: 17 / 255, green: 24 / 255, blue: 39 / 255))
        }
    }
}

private struct FleetReceiptLogoBadge: View {
    var body: some View {
        Group {
            if let ui = UIImage(named: "mgl_logo", in: FleetSdkResourceBundle.bundle, compatibleWith: nil) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 120, maxHeight: 36)
            } else {
                Text("MGL")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(red: 63 / 255, green: 63 / 255, blue: 70 / 255))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.8), lineWidth: 1),
        )
    }
}

// MARK: - Share receipt image (Android FuelingReceiptShare parity)

enum FleetFuelingReceiptShare {
    static func share(
        payFailed: Bool,
        station: String,
        vehicle: String,
        driverName: String?,
        amountDisplay: String,
        newBalance: String?,
        authCode: String?,
        txnId: String,
        txnDate: String,
    ) {
        guard let presenter = topViewController() else { return }
        let image = renderReceiptBitmap(
            payFailed: payFailed,
            station: station,
            vehicle: vehicle,
            driverName: driverName,
            amountDisplay: amountDisplay,
            newBalance: newBalance,
            authCode: authCode,
            txnId: txnId,
            txnDate: txnDate,
        )
        let title = payFailed ? "MGL — Transaction failed" : "MGL — Fueling complete"
        var text =
            (payFailed ? "Transaction failed" : "Fueling complete")
            + "\nStation: \(station)"
            + "\nVehicle: \(vehicle)"
        if let d = driverName, !d.isEmpty { text += "\nDriver: \(d)" }
        text += "\nAmount: \(amountDisplay)"
        if !payFailed, let bal = newBalance, !bal.isEmpty { text += "\nNew balance: \(bal)" }
        if let auth = authCode, !auth.isEmpty { text += "\nAuth code: \(auth)" }
        text += "\nTXN ID: \(txnId)"
        text += "\nTransaction date: \(txnDate)"
        if payFailed { text += "\nStatus: FAILED" }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("mgl-fueling-receipt.png")
        if let data = image.pngData() {
            try? data.write(to: url)
        }
        let av = UIActivityViewController(activityItems: [url, text], applicationActivities: nil)
        av.setValue(title, forKey: "subject")
        presenter.present(av, animated: true)
    }

    private static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let window = scenes.flatMap(\.windows).first { $0.isKeyWindow }
        var vc = window?.rootViewController
        while let presented = vc?.presentedViewController { vc = presented }
        return vc
    }

    private static func renderReceiptBitmap(
        payFailed: Bool,
        station: String,
        vehicle: String,
        driverName: String?,
        amountDisplay: String,
        newBalance: String?,
        authCode: String?,
        txnId: String,
        txnDate: String,
    ) -> UIImage {
        let w: CGFloat = 1080
        let pad: CGFloat = 48
        let lineGap: CGFloat = 72
        let headline = payFailed ? "Transaction Failed" : "Fueling Complete"
        var rowCount = 5
        if driverName?.isEmpty == false { rowCount += 1 }
        if payFailed { rowCount += 1 }
        if newBalance?.isEmpty == false { rowCount += 1 }
        if authCode?.isEmpty == false { rowCount += 1 }
        let h = pad * 2 + 56 + 200 + lineGap * CGFloat(rowCount) + 120

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: w, height: h))
        return renderer.image { ctx in
            let c = ctx.cgContext
            UIColor.white.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))

            let titleColor = payFailed
                ? UIColor(red: 185 / 255, green: 28 / 255, blue: 28 / 255, alpha: 1)
                : UIColor(red: 46 / 255, green: 125 / 255, blue: 50 / 255, alpha: 1)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 56),
                .foregroundColor: titleColor,
            ]
            (headline as NSString).draw(at: CGPoint(x: pad, y: pad), withAttributes: attrs)

            var y = pad + 56 + 48
            let hdrH: CGFloat = 200
            UIColor(red: 6 / 255, green: 78 / 255, blue: 59 / 255, alpha: 1).setFill()
            ctx.fill(CGRect(x: 0, y: y, width: w, height: hdrH))
            if let logo = UIImage(named: "mgl_logo", in: FleetSdkResourceBundle.bundle, compatibleWith: nil) {
                let targetH: CGFloat = 100
                let lw = min(280, max(80, logo.size.width * (targetH / logo.size.height)))
                let lh = min(130, logo.size.height * (lw / logo.size.width))
                logo.draw(in: CGRect(x: (w - lw) / 2, y: y + (hdrH - lh) / 2 - 16, width: lw, height: lh))
            }
            let officialAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 32),
                .foregroundColor: UIColor.white.withAlphaComponent(0.9),
            ]
            let official = "Official Receipt" as NSString
            let os = official.size(withAttributes: officialAttrs)
            official.draw(
                at: CGPoint(x: (w - os.width) / 2, y: y + hdrH - 32 - os.height),
                withAttributes: officialAttrs,
            )
            y = y + hdrH + pad

            func row(_ label: String, _ value: String, valUIColor: UIColor = UIColor(red: 17 / 255, green: 24 / 255, blue: 39 / 255, alpha: 1)) {
                let labelAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 36),
                    .foregroundColor: UIColor(red: 107 / 255, green: 114 / 255, blue: 128 / 255, alpha: 1),
                ]
                let valueAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 40),
                    .foregroundColor: valUIColor,
                ]
                (label as NSString).draw(at: CGPoint(x: pad, y: y), withAttributes: labelAttrs)
                let vs = (value as NSString).size(withAttributes: valueAttrs)
                (value as NSString).draw(at: CGPoint(x: w - pad - vs.width, y: y), withAttributes: valueAttrs)
                y += lineGap
                UIColor(red: 243 / 255, green: 244 / 255, blue: 246 / 255, alpha: 1).setStroke()
                c.setLineWidth(2)
                c.move(to: CGPoint(x: pad, y: y - 16))
                c.addLine(to: CGPoint(x: w - pad, y: y - 16))
                c.strokePath()
            }

            row("Station", station)
            row("Vehicle", vehicle)
            if let d = driverName, !d.isEmpty { row("Driver", d) }
            if payFailed {
                row("Status", "FAILED", valUIColor: UIColor(red: 220 / 255, green: 38 / 255, blue: 38 / 255, alpha: 1))
            }
            row(
                "Amount",
                amountDisplay,
                valUIColor: payFailed
                    ? UIColor(red: 220 / 255, green: 38 / 255, blue: 38 / 255, alpha: 1)
                    : UIColor(red: 46 / 255, green: 125 / 255, blue: 50 / 255, alpha: 1),
            )
            if !payFailed, let bal = newBalance, !bal.isEmpty {
                row("New balance", bal, valUIColor: UIColor(red: 46 / 255, green: 125 / 255, blue: 50 / 255, alpha: 1))
            }
            if let auth = authCode, !auth.isEmpty { row("Auth code", auth) }

            y += 32
            let footAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 30, weight: .regular),
                .foregroundColor: UIColor(red: 107 / 255, green: 114 / 255, blue: 128 / 255, alpha: 1),
            ]
            let tid = (txnId == "—" ? "TXN ID: —" : "TXN ID: \(txnId)") as NSString
            let ts = tid.size(withAttributes: footAttrs)
            tid.draw(at: CGPoint(x: (w - ts.width) / 2, y: y), withAttributes: footAttrs)
            y += ts.height + 24
            let td = txnDate as NSString
            let tds = td.size(withAttributes: footAttrs)
            td.draw(at: CGPoint(x: (w - tds.width) / 2, y: y), withAttributes: footAttrs)
        }
    }
}
