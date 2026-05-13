import Foundation

/// User-visible banners aligned with `app/page.tsx` (`bannerFromThrownError`, `bannerForOtpFailure`, …).
enum ReactParityBanner {
    static let validMobileError = "Please enter a valid mobile number"

    static let invalidFleetpayQr = "Invalid Fleetpay QR. Point at the station QR (must include tid)."
    static let selectVehicleFirst = "Select a vehicle first."
    static let noActiveFleet = "No active fleet — use your invite code."
    static let newUserContinueInvite = "New user — continue with invite code."
    static let inviteVerifyMobileFirst = "Invite flow incomplete — verify mobile first."
    static let useSendOtpOnLogin = "Use “Send OTP” on the login screen."
    static let completeMobileOtpFirst = "Complete mobile OTP verification first."
    static let sessionMissingInvite = "Session missing — go back to invite step."
    static let pinsDontMatch1f = "PINs don't match. Try again."
    static let pinsDidntMatchConfirm = "PINs didn't match. Try again."

    private static let bannerMsgMax = 280

    private static func errTxt(_ e: Error) -> String {
        var collected: [String] = []
        var current: Error? = e
        var depth = 0
        while let err = current, depth < 8 {
            depth += 1
            let localized = (err as? LocalizedError)?.errorDescription?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let fromNs = (err as NSError).localizedDescription
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let piece: String
            if let l = localized, !l.isEmpty {
                piece = l
            } else if !fromNs.isEmpty {
                piece = fromNs
            } else {
                piece = ""
            }
            if !piece.isEmpty {
                collected.append(piece)
            }
            current = (err as NSError).userInfo[NSUnderlyingErrorKey] as? Error
        }
        if let last = collected.last { return last }
        return String(describing: type(of: e))
    }

    private static func isLikelyNetworkFailure(_ msg: String) -> Bool {
        let l = msg.lowercased()
        return l.range(of: "network|fetch|failed to fetch|timeout|502|503|504|econn|aborted", options: .regularExpression) != nil
    }

    private static let otpVerifyBannerFallback = "Could not verify OTP. Check your connection and try again."
    private static let pinVerifyBannerFallback = "Could not verify PIN. Check your connection and try again."

    private static let otpAuthNoisePattern =
        "unauthori[sz]ed|invalid[_\\s-]?grant|invalid[_\\s-]?token|\\b401\\b|bad\\s*credentials|access\\s*denied|^oauth\\s+failed|^http\\s*401|authentication\\s*failed|full\\s*authentication"

    private static let pinAuthNoisePattern =
        "unauthori[sz]ed|invalid[_\\s-]?grant|\\b401\\b|bad\\s*credentials|access\\s*denied|^oauth\\s+failed|^http\\s*401|wrong\\s*pin|incorrect\\s*pin|invalid\\s*pin|authentication\\s*failed"

    private static func humanizeOtpVerifyBanner(_ base: String, transportFallback: String) -> String {
        if base == transportFallback { return base }
        let t = base.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty || t == "Request failed." { return "Incorrect OTP. Try again." }
        if t.range(of: otpAuthNoisePattern, options: [.regularExpression, .caseInsensitive]) != nil {
            return "Incorrect OTP. Try again."
        }
        return base
    }

    private static func humanizePinVerifyBanner(_ base: String, transportFallback: String) -> String {
        if base == transportFallback { return base }
        let t = base.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty || t == "Request failed." { return "Incorrect PIN. Try again." }
        if t.range(of: pinAuthNoisePattern, options: [.regularExpression, .caseInsensitive]) != nil {
            return "Incorrect PIN. Try again."
        }
        return base
    }

    static func fromThrown(_ e: Error?, transportFallback: String) -> String {
        guard let e else { return transportFallback }
        let m = errTxt(e)
        if isLikelyNetworkFailure(m) { return transportFallback }
        let t = m.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return "Request failed." }
        if t.count <= bannerMsgMax { return t }
        let idx = t.index(t.startIndex, offsetBy: bannerMsgMax - 1)
        return String(t[..<idx]) + "…"
    }

    static func forOtpFailure(_ e: Error?) -> String {
        humanizeOtpVerifyBanner(
            fromThrown(e, transportFallback: otpVerifyBannerFallback),
            transportFallback: otpVerifyBannerFallback,
        )
    }

    static func forPinFailure(_ e: Error?) -> String {
        humanizePinVerifyBanner(
            fromThrown(e, transportFallback: pinVerifyBannerFallback),
            transportFallback: pinVerifyBannerFallback,
        )
    }

    static func forGenericFailure(_ e: Error?) -> String {
        fromThrown(e, transportFallback: "Something went wrong. Check your connection and try again.")
    }
}
