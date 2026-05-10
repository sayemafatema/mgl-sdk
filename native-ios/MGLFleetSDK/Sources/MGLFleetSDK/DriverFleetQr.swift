import Foundation

struct FleetpayQrPayloadIOS: Equatable {
    var txnId: String
    var mid: String
    var terminalId: String
    var amountPaise: Int64
    var expiryEpoch: Int64
    var sign: String
    var merchantName: String?
    var currency: String?
}

enum DriverFleetQr {
    static let simulatedUri =
        "fleetpay://pay?txn=SIMTXN01&mid=DEMOMID&tid=DEMOTID&am=67200&exp=9999999999&sign=demosign&mn=Demo%20CNG%20Station"

    static func parseFleetpayPayUri(_ raw: String) -> FleetpayQrPayloadIOS? {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard s.lowercased().hasPrefix("fleetpay://") else { return nil }
        guard let u = URLComponents(string: s), let host = u.host?.lowercased() else { return nil }
        let pathNorm = u.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")).lowercased()
        let payPathOk = pathNorm.isEmpty || pathNorm.hasSuffix("pay") || pathNorm.hasSuffix("/pay")
        let payHostOk = host == "pay"
        if !payHostOk && !payPathOk { return nil }

        func qp(_ name: String) -> String? {
            u.queryItems?.first { $0.name == name }?.value?.removingPercentEncoding
                ?? u.queryItems?.first { $0.name == name }?.value
        }

        guard let txnId = qp("txn"), !txnId.isEmpty,
              let mid = qp("mid"), !mid.isEmpty,
              let terminalId = qp("tid"), !terminalId.isEmpty,
              let am = qp("am"), let amountPaise = Double(am).flatMap({ Int64($0) }),
              let exp = qp("exp"), let expiryEpoch = Double(exp).flatMap({ Int64($0) }),
              let sign = qp("sign"), !sign.isEmpty else { return nil }

        return FleetpayQrPayloadIOS(
            txnId: txnId,
            mid: mid,
            terminalId: terminalId,
            amountPaise: amountPaise,
            expiryEpoch: expiryEpoch,
            sign: sign,
            merchantName: qp("mn"),
            currency: qp("cu"),
        )
    }

    static func paiseToInrDisplay(_ amountPaise: Int64) -> String {
        let inr = Double(amountPaise) / 100.0
        let f = NumberFormatter()
        f.locale = Locale(identifier: "en_IN")
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: inr)) ?? String(format: "%.2f", inr)
    }

    static func validIndianMobile10(_ digitsOnly: String) -> Bool {
        let d = String(digitsOnly.filter(\.isNumber).suffix(10))
        guard d.count == 10, let first = d.first, let fv = Int(String(first)) else { return false }
        return (6 ... 9).contains(fv)
    }

    static func normVrnPublic(_ v: String) -> String {
        v.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
            .uppercased(with: Locale(identifier: "en_US"))
    }

    static func normVrnForQrPay(_ v: String) -> String {
        normVrnPublic(v).replacingOccurrences(of: " ", with: "")
    }
}
