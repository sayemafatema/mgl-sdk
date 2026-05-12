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
        let m = (e as LocalizedError).errorDescription ?? (e as NSError).localizedDescription
        let t = m.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? String(describing: type(of: e)) : t
    }

    private static func isLikelyNetworkFailure(_ msg: String) -> Bool {
        let l = msg.lowercased()
        return l.range(of: "network|fetch|failed to fetch|timeout|502|503|504|econn|aborted", options: .regularExpression) != nil
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
        fromThrown(e, transportFallback: "Could not verify OTP. Check your connection and try again.")
    }

    static func forPinFailure(_ e: Error?) -> String {
        fromThrown(e, transportFallback: "Could not verify PIN. Check your connection and try again.")
    }

    static func forGenericFailure(_ e: Error?) -> String {
        fromThrown(e, transportFallback: "Something went wrong. Check your connection and try again.")
    }
}
