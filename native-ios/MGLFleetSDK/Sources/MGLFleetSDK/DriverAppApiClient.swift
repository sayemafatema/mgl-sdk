import Foundation

/// Live driver-app HTTP; mirrors `driver-api.ts` / Android `DriverAppApiClient`. Use when `!FleetSdkOptions.useMock`.
final class DriverAppApiClient {
    private let options: FleetSdkOptions
    private let session: URLSession

    private static let userAgent = "mgl-fleet-ios-sdk/1.0"

    init(options: FleetSdkOptions, session: URLSession = .shared) {
        self.options = options
        self.session = session
    }

    private var baseTrimmed: String {
        options.apiBaseUrl.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    private func unwrapBody(from text: String) throws -> Any? {
        let parsed = try DriverFleetJSON.parseFlexible(text)
        return try DriverFleetJSON.unwrapDriverBody(parsed)
    }

    private func getRaw(path: String, bearer: String?) async throws -> String {
        guard let url = URL(string: baseTrimmed + path) else { throw DriverApiError.message("Bad URL") }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        if let b = bearer?.trimmingCharacters(in: .whitespaces), !b.isEmpty {
            req.setValue("Bearer \(b)", forHTTPHeaderField: "Authorization")
        }
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw DriverApiError.message("No HTTP response") }
        let text = String(data: data, encoding: .utf8) ?? ""
        if !(200 ..< 300).contains(http.statusCode) {
            let msg =
                (
                    try? DriverFleetJSON.extractFleetApiErrorMessage(try DriverFleetJSON.parseFlexible(text)))
                ?? nil
            throw DriverApiError.message(msg ?? "HTTP \(http.statusCode)")
        }
        return text
    }

    private func postJsonRaw(path: String, body: [String: Any], bearer: String?) async throws -> String {
        guard let url = URL(string: baseTrimmed + path) else { throw DriverApiError.message("Bad URL") }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        req.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        if let b = bearer?.trimmingCharacters(in: .whitespaces), !b.isEmpty {
            req.setValue("Bearer \(b)", forHTTPHeaderField: "Authorization")
        }
        req.httpBody =
            try JSONSerialization.data(withJSONObject: body)
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw DriverApiError.message("No HTTP response") }
        let text = String(data: data, encoding: .utf8) ?? ""
        if !(200 ..< 300).contains(http.statusCode) {
            let msg =
                (
                    try? DriverFleetJSON.extractFleetApiErrorMessage(try DriverFleetJSON.parseFlexible(text)))
                ?? nil
            throw DriverApiError.message(msg ?? "HTTP \(http.statusCode)")
        }
        return text
    }

    func driverCheckMobile(_ mobile: String) async -> Result<CheckMobileStatusKind, Error> {
        await runCatching {
            let txt = try await postJsonRaw(path: "/api/v0/driver-app/auth/check-mobile", body: ["mobile": mobile], bearer: nil)
            let unwrapped = try unwrapBody(from: txt)
            return try DriverFleetJSON.parseCheckMobile(unwrapped)
        }
    }

    func driverSendLoginOtp(_ mobile: String) async -> Result<Void, Error> {
        await runCatching {
            let enc = mobile.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? mobile
            _ = try await getRaw(path: "/api/v0/otp/login?username=\(enc)", bearer: nil)
        }
    }

    func driverInviteMobileSendOtp(_ mobile: String) async -> Result<String, Error> {
        await runCatching {
            let txt = try await postJsonRaw(path: "/api/v0/driver-app/auth/mobile/send-otp", body: ["mobile": mobile], bearer: nil)
            let parsed = try DriverFleetJSON.parseFlexible(txt)
            return try DriverFleetJSON.unwrapInviteSendOtpInner(parsed)
        }
    }

    func driverInviteMobileVerifyOtp(mobile: String, otpRefNumber: String, otp: String) async -> Result<String, Error> {
        await runCatching {
            let txt =
                try await postJsonRaw(
                    path: "/api/v0/driver-app/auth/mobile/verify-otp",
                    body: [
                        "mobile": mobile,
                        "otpRefNumber": otpRefNumber,
                        "otp": otp,
                    ],
                    bearer: nil,
                )
            let parsed = try DriverFleetJSON.parseFlexible(txt)
            let unwrappedAny = try DriverFleetJSON.unwrapDriverBody(parsed)
            let jo = try DriverFleetJSON.requireJSONObject(unwrappedAny)
            guard let tok = jo["mobileVerificationToken"] as? String, !tok.trimmingCharacters(in: .whitespaces).isEmpty else {
                throw DriverApiError.message("Unexpected verify-otp response")
            }
            return tok
        }
    }

    func driverInviteValidate(mobile: String, inviteCode: String, mobileVerificationToken: String) async -> Result<InviteValidateParsed, Error> {
        await runCatching {
            let txt =
                try await postJsonRaw(
                    path: "/api/v0/driver-app/auth/invite/validate",
                    body: [
                        "mobile": mobile,
                        "inviteCode": inviteCode,
                        "mobileVerificationToken": mobileVerificationToken,
                    ],
                    bearer: nil,
                )
            let unwrapped = try unwrapBody(from: txt)
            let jo = try DriverFleetJSON.requireJSONObject(unwrappedAny(unwrapped))
            return try DriverFleetJSON.parseInviteValidate(jo)
        }
    }

    /// After JSON decode, unwrap string-wrapped payloads for OAuth bodies.
    private func unwrappedAny(_ any: Any?) -> Any? {
        if let s = any as? String, let d = s.data(using: .utf8),
           let o = try? JSONSerialization.jsonObject(with: d) {
            return o
        }
        return any
    }

    func driverInviteSetPin(sessionToken: String, pin: String) async -> Result<String, Error> {
        await runCatching {
            let txt =
                try await postJsonRaw(
                    path: "/api/v0/driver-app/auth/invite/set-pin",
                    body: ["sessionToken": sessionToken, "pin": pin],
                    bearer: nil,
                )
            let parsed = try DriverFleetJSON.parseFlexible(txt)
            guard let uw = try DriverFleetJSON.unwrapDriverBody(parsed) else { throw DriverApiError.message("invite set-pin: empty body") }
            if let tok = DriverFleetJSON.oauthAccessToken(unwrappedAny(uw)) { return tok }
            if let inner = uw as? [String: Any], let nested = DriverFleetJSON.oauthAccessToken(inner) { return nested }
            throw DriverApiError.message("Missing access token")
        }
    }

    func driverOauthOtpGrant(mobile: String, otp: String) async -> Result<String, Error> {
        await runCatching {
            guard let url = URL(string: baseTrimmed + "/oauth/token") else { throw DriverApiError.message("Bad oauth URL") }
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Accept")
            req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            req.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
            let pairs: [(String, String)] = [
                ("grant_type", "otp"),
                ("username", mobile.trimmingCharacters(in: .whitespaces)),
                ("otp", otp.trimmingCharacters(in: .whitespaces)),
                ("client_id", "mgl-driver-app-client"),
                ("client_secret", "driver-app-secret"),
            ]
            let body =
                pairs
                    .map { kv in
                        let k = kv.0.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? kv.0
                        let v = kv.1.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? kv.1
                        return "\(k)=\(v)"
                    }
                    .joined(separator: "&")
            req.httpBody = body.data(using: .utf8)

            let (data, resp) = try await session.data(for: req)
            guard let http = resp as? HTTPURLResponse else { throw DriverApiError.message("No HTTP response") }
            let text = String(data: data, encoding: .utf8) ?? ""
            if !(200 ..< 300).contains(http.statusCode) {
                let parsed = try? DriverFleetJSON.parseFlexible(text)
                throw DriverApiError.message(DriverFleetJSON.peelOAuthError(parsed))
            }
            let any = try DriverFleetJSON.parseFlexible(text)
            guard let jo = any as? [String: Any],
                  let t = jo["access_token"] as? String ?? jo["accessToken"] as? String,
                  !t.isEmpty else { throw DriverApiError.message("OAuth: no token") }
            return t
        }
    }

    func driverFoList(_ bearerPartial: String) async -> Result<[FoListEntryParsed], Error> {
        await runCatching {
            let txt = try await getRaw(path: "/api/v0/driver-app/auth/fo-list", bearer: bearerPartial)
            let uw = try unwrapBody(from: txt)
            return DriverFleetJSON.parseFoList(uw)
        }
    }

    func driverFoSelect(bearerPartial: String, foCompanyId: Int64, pin: String) async -> Result<String, Error> {
        await runCatching {
            let txt =
                try await postJsonRaw(
                    path: "/api/v0/driver-app/auth/fo-select",
                    body: ["foCompanyId": NSNumber(value: foCompanyId), "pin": pin],
                    bearer: bearerPartial,
                )
            let parsed = try DriverFleetJSON.parseFlexible(txt)
            guard let uw = try DriverFleetJSON.unwrapDriverBody(parsed) else { throw DriverApiError.message("fo-select empty") }
            if let tok = DriverFleetJSON.oauthAccessToken(unwrappedAny(uw)) { return tok }
            if let inner = uw as? [String: Any], let nested = DriverFleetJSON.oauthAccessToken(inner) { return nested }
            throw DriverApiError.message("Missing fleet token")
        }
    }

    func driverGetHome(_ token: String) async -> Result<DriverHomeParsed, Error> {
        await runCatching {
            let txt = try await getRaw(path: "/api/v0/driver-app/home", bearer: token)
            let uw = try unwrapBody(from: txt)
            let jo = try DriverFleetJSON.requireJSONObject(uw)
            return DriverFleetJSON.parseHome(jo)
        }
    }

    func driverGetProfile(_ token: String) async -> Result<DriverProfileParsed, Error> {
        await runCatching {
            let txt = try await getRaw(path: "/api/v0/driver-app/profile", bearer: token)
            let uw = try unwrapBody(from: txt)
            let jo = try DriverFleetJSON.requireJSONObject(uw)
            return DriverFleetJSON.parseProfile(jo)
        }
    }

    func driverGetAssignments(_ token: String) async -> Result<[DriverAssignmentParsed], Error> {
        await runCatching {
            let txt = try await getRaw(path: "/api/v0/driver-app/assignments", bearer: token)
            let uw = try unwrapBody(from: txt)
            return DriverFleetJSON.parseAssignments(uw)
        }
    }

    func driverAcceptPairing(_ token: String, pairingCode: String) async -> Result<(vrn: String, status: String), Error> {
        await runCatching {
            let txt =
                try await postJsonRaw(
                    path: "/api/v0/driver-app/vehicle/accept-pairing",
                    body: ["pairingCode": pairingCode],
                    bearer: token,
                )
            let uw = try unwrapBody(from: txt)
            let jo = try DriverFleetJSON.requireJSONObject(uw)
            let vrn = ((jo["vehicleRegNo"] as? String) ?? "").trimmingCharacters(in: .whitespaces)
            let status = ((jo["status"] as? String) ?? "").trimmingCharacters(in: .whitespaces)
            return (vrn, status)
        }
    }

    func driverQrPay(
        _ token: String,
        txnId: String,
        vehicleRegNoNorm: String,
        pin: String,
        mid: String,
        terminalId: String,
        amountPaise: Int64,
        expiryEpoch: Int64,
        sign: String,
    ) async -> Result<QrPayResultParsed, Error> {
        await runCatching {
            let txt =
                try await postJsonRaw(
                    path: "/api/v0/driver-app/qr/pay",
                    body: [
                        "txnId": txnId,
                        "vehicleRegNo": vehicleRegNoNorm,
                        "pin": pin,
                        "mid": mid,
                        "terminalId": terminalId,
                        "amountPaise": NSNumber(value: amountPaise),
                        "expiryEpoch": NSNumber(value: expiryEpoch),
                        "sign": sign,
                    ],
                    bearer: token,
                )
            let uw = try unwrapBody(from: txt)
            let jo = try DriverFleetJSON.requireJSONObject(uw)
            return DriverFleetJSON.parseQrPayResult(jo)
        }
    }

    func driverGetTransactions(_ token: String, vehicleId: String, page: Int = 0) async -> Result<TxnsPageParsedIOS, Error> {
        await runCatching {
            let vid = vehicleId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? vehicleId
            let q = page > 0 ? "?page=\(page)" : ""
            let txt = try await getRaw(path: "/api/v0/driver-app/vehicles/\(vid)/transactions\(q)", bearer: token)
            let uw = try unwrapBody(from: txt)
            return DriverFleetJSON.normalizeDriverTransactionsPayload(uw)
        }
    }

    private func runCatching<T>(_ body: () async throws -> T) async -> Result<T, Error> {
        do {
            return .success(try await body())
        } catch let e as DriverApiError {
            return .failure(e)
        } catch {
            return .failure(error)
        }
    }
}
