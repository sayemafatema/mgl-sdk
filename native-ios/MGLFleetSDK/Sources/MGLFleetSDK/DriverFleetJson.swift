import Foundation

enum DriverApiError: Error, LocalizedError {
    case message(String)
    var errorDescription: String? {
        switch self {
        case .message(let s): return s
        }
    }
}

enum CheckMobileStatusKind: String {
    case newUser = "NEW_USER"
    case returningUser = "RETURNING_USER"
}

struct FoListEntryParsed: Equatable {
    var foCompanyId: Int64
    var foName: String
    var foStatus: String
}

struct InviteValidateParsed: Equatable {
    var sessionToken: String
    var driverName: String
    var foName: String
    var foCompanyId: Int64
}

struct DriverHomeParsed: Equatable {
    var hasActiveVehicle: Bool
    var foName: String?
    var vehicleRegNo: String?
    var vehicleId: String?
    var assignmentType: String?
    var isCurrentlyEligible: Bool?
    var currentlyEligible: Bool?
    var totalBalanceINR: Double?
    var shiftDaysOfWeek: String?
    var shiftStartTime: String?
    var shiftEndTime: String?
    var tripDate: String?
    var tripStartTime: String?
    var tripEndTime: String?
    var tripStartLocation: String?
}

struct DriverAssignmentParsed: Equatable {
    var vehicleDriverId: Int64
    var vehicleId: String
    var vehicleRegNo: String
    var assignmentType: String
    var status: String
    var requiresPairing: Bool
    var shiftDaysOfWeek: String?
    var shiftStartTime: String?
    var shiftEndTime: String?
    var tripDate: String?
    var tripStartTime: String?
    var tripEndTime: String?
    var tripStartLocation: String?
    var assignedAt: String?
}

struct DriverProfileParsed: Equatable {
    var driverId: String
    var name: String
    var maskedMobile: String?
    var dlNumber: String?
    var foStatus: String?
}

struct QrPayResultParsed: Equatable {
    var serverTxnId: String?
    var vehicleRegNo: String?
    var amountINR: Double?
    var newBalanceINR: Double?
    var authCode: String?
    var txnTime: String?
    var status: String?
    var quantityKg: Double?
}

struct DriverTxnRowParsed: Equatable {
    var serverTxnId: String
    var vehicleRegNo: String
    var amountINR: Double
    var status: String
    var driverName: String
    var createdOn: String
}

struct TxnsPageParsedIOS: Equatable {
    var rows: [DriverTxnRowParsed]
    var page: Int
    var limit: Int
    var totalElements: Int
    var totalPages: Int
}

enum DriverFleetJSON {
    static func parseFlexible(_ text: String) throws -> Any {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return [String: Any]() }
        guard let d = t.data(using: .utf8) else { throw DriverApiError.message("Bad encoding") }
        return try JSONSerialization.jsonObject(with: d, options: [])
    }

    static func extractFleetApiErrorMessage(_ body: Any?) -> String? {
        guard let o = body as? [String: Any] else { return nil }
        if let er = o["errorResponse"] as? [String: Any] {
            for k in ["errorMessage", "message", "error", "detail"] {
                if let s = er[k] as? String, !s.trimmingCharacters(in: .whitespaces).isEmpty { return s.trimmingCharacters(in: .whitespaces) }
            }
        }
        for k in ["errorMessage", "message", "error", "detail"] {
            if let s = o[k] as? String, !s.trimmingCharacters(in: .whitespaces).isEmpty { return s.trimmingCharacters(in: .whitespaces) }
        }
        if let p = o["payload"] as? String, !p.isEmpty, (o["response_message"] as? String) == "FAILURE" { return p.trimmingCharacters(in: .whitespaces) }
        return nil
    }

    static func peelFleetEnvelope(_ raw: Any) throws -> Any? {
        guard let o = raw as? [String: Any], o["payload"] != nil, o["response_message"] != nil else { return raw }
        let msg = (o["response_message"] as? String) ?? ""
        let code = o["response_code"]
        let errDetail = extractFleetApiErrorMessage(o)
        let errorResponseBad = o["errorResponse"] != nil && !(o["errorResponse"] is NSNull)
        var codeNum = 0
        if let n = code as? Int { codeNum = n }
        else if let n = code as? NSNumber { codeNum = n.intValue }
        let isError = errorResponseBad || msg == "FAILURE" || codeNum >= 400
        if isError {
            let m = errDetail?.isEmpty == false ? errDetail! : (msg != "FAILURE" && !msg.isEmpty ? msg : (codeNum != 0 ? "Error \(codeNum)" : "Request failed"))
            throw DriverApiError.message(m)
        }
        return o["payload"]
    }

    static func unwrapIfWrapped(_ raw: Any?) throws -> Any? {
        let peeled = try peelFleetEnvelope(raw ?? NSNull())
        guard let o = peeled as? [String: Any], o["status"] != nil, o["data"] != nil else { return peeled }
        let st = (o["status"] as? String) ?? ""
        if st == "FAILURE" {
            let d = (o["errorMessage"] as? String)?.trimmingCharacters(in: .whitespaces).nilIfEmpty
                ?? (o["message"] as? String)?.trimmingCharacters(in: .whitespaces).nilIfEmpty
            throw DriverApiError.message(d ?? "Request failed")
        }
        return o["data"]
    }

    static func unwrapDriverBody(_ raw: Any?) throws -> Any? {
        let step = try unwrapIfWrapped(raw)
        if let o = step as? [String: Any], o.count == 1, o["data"] != nil { return o["data"] }
        return step
    }

    static func unwrapDriverBodyString(_ text: String) throws -> Any? {
        try unwrapDriverBody(parseFlexible(text))
    }

    static func oauthAccessToken(_ any: Any?) -> String? {
        guard let o = any as? [String: Any] else { return nil }
        if let t = o["accessToken"] as? String, !t.isEmpty { return t }
        if let t = o["access_token"] as? String, !t.isEmpty { return t }
        return nil
    }

    static func parseCheckMobile(_ data: Any?) throws -> CheckMobileStatusKind {
        guard let o = data as? [String: Any], let s = o["status"] as? String else {
            throw DriverApiError.message("Unexpected check-mobile response")
        }
        switch s.trimmingCharacters(in: .whitespaces) {
        case "NEW_USER": return .newUser
        case "RETURNING_USER": return .returningUser
        default: throw DriverApiError.message("Unexpected check-mobile response")
        }
    }

    static func peelOAuthError(_ body: Any?) -> String {
        if let m = extractFleetApiErrorMessage(body) { return m }
        guard let o = body as? [String: Any] else { return "OAuth failed" }
        if let d = o["error_description"] as? String, !d.trimmingCharacters(in: .whitespaces).isEmpty { return d.trimmingCharacters(in: .whitespaces) }
        if let e = o["error"] as? String, !e.isEmpty { return e }
        return "OAuth failed"
    }

    static func unwrapInviteSendOtpInner(_ rawParsed: Any?) throws -> String {
        if let inner = try? unwrapDriverBody(rawParsed), let s = inner as? String, !s.isEmpty { return s }
        if let u = try? unwrapIfWrapped(rawParsed), let s = u as? String, !s.isEmpty { return s }
        if let p = try? peelFleetEnvelope(rawParsed), let s = p as? String, !s.isEmpty { return s }
        throw DriverApiError.message("Unexpected send-otp response")
    }

    static func requireJSONObject(_ any: Any?) throws -> [String: Any] {
        guard let o = any as? [String: Any] else { throw DriverApiError.message("Expected JSON object") }
        return o
    }

    static func parseHome(_ o: [String: Any]) -> DriverHomeParsed {
        DriverHomeParsed(
            hasActiveVehicle: o["hasActiveVehicle"] as? Bool ?? (o["hasActiveVehicle"] as? NSNumber)?.boolValue ?? false,
            foName: stringOrNil(o["foName"]),
            vehicleRegNo: stringOrNil(o["vehicleRegNo"]),
            vehicleId: stringOrNil(o["vehicleId"]),
            assignmentType: stringOrNil(o["assignmentType"]),
            isCurrentlyEligible: boolOrNil(o["isCurrentlyEligible"]),
            currentlyEligible: boolOrNil(o["currentlyEligible"]),
            totalBalanceINR: doubleOrNil(o["totalBalanceINR"]),
            shiftDaysOfWeek: stringOrNil(o["shiftDaysOfWeek"]),
            shiftStartTime: stringOrNil(o["shiftStartTime"]),
            shiftEndTime: stringOrNil(o["shiftEndTime"]),
            tripDate: stringOrNil(o["tripDate"]),
            tripStartTime: stringOrNil(o["tripStartTime"]),
            tripEndTime: stringOrNil(o["tripEndTime"]),
            tripStartLocation: stringOrNil(o["tripStartLocation"]),
        )
    }

    static func parseProfile(_ o: [String: Any]) -> DriverProfileParsed {
        let dl =
            stringOrNil(o["dlNumber"])
            ?? stringOrNil(o["dl_number"])
            ?? stringOrNil(o["licenceNumber"])
            ?? stringOrNil(o["licenseNumber"])
        return DriverProfileParsed(
            driverId: (o["driverId"] as? String) ?? "",
            name: (o["name"] as? String) ?? "",
            maskedMobile: stringOrNil(o["maskedMobile"]),
            dlNumber: dl,
            foStatus: stringOrNil(o["foStatus"]),
        )
    }

    static func parseAssignments(_ data: Any?) -> [DriverAssignmentParsed] {
        guard let arr = data as? [Any] else { return [] }
        return arr.compactMap { row -> DriverAssignmentParsed? in
            guard let a = row as? [String: Any] else { return nil }
            let vd = a["vehicleDriverId"]
            let vid: Int64 =
                (vd as? Int64)
                ?? (vd as? NSNumber)?.int64Value
                ?? Int64((vd as? Int) ?? 0)
            return DriverAssignmentParsed(
                vehicleDriverId: vid,
                vehicleId: (a["vehicleId"] as? String) ?? "",
                vehicleRegNo: (a["vehicleRegNo"] as? String) ?? "",
                assignmentType: (a["assignmentType"] as? String) ?? "",
                status: (a["status"] as? String) ?? "",
                requiresPairing: (a["requiresPairing"] as? Bool) ?? ((a["requiresPairing"] as? NSNumber)?.boolValue ?? false),
                shiftDaysOfWeek: stringOrNil(a["shiftDaysOfWeek"]),
                shiftStartTime: stringOrNil(a["shiftStartTime"]),
                shiftEndTime: stringOrNil(a["shiftEndTime"]),
                tripDate: stringOrNil(a["tripDate"]),
                tripStartTime: stringOrNil(a["tripStartTime"]),
                tripEndTime: stringOrNil(a["tripEndTime"]),
                tripStartLocation: stringOrNil(a["tripStartLocation"]),
                assignedAt: stringOrNil(a["assignedAt"]),
            )
        }
    }

    static func parseFoList(_ data: Any?) -> [FoListEntryParsed] {
        guard let arr = data as? [Any] else { return [] }
        return arr.compactMap { row -> FoListEntryParsed? in
            guard let fo = row as? [String: Any] else { return nil }
            let cid = fo["foCompanyId"]
            let id: Int64 = (cid as? Int64) ?? (cid as? NSNumber)?.int64Value ?? Int64((cid as? Int) ?? 0)
            return FoListEntryParsed(
                foCompanyId: id,
                foName: (fo["foName"] as? String) ?? "",
                foStatus: (fo["foStatus"] as? String) ?? "",
            )
        }
    }

    static func parseInviteValidate(_ o: [String: Any]) throws -> InviteValidateParsed {
        guard let st = o["sessionToken"] as? String, !st.isEmpty else { throw DriverApiError.message("invite validate: missing sessionToken") }
        let foId = o["foCompanyId"]
        let id: Int64 = (foId as? Int64) ?? (foId as? NSNumber)?.int64Value ?? 0
        return InviteValidateParsed(
            sessionToken: st,
            driverName: (o["driverName"] as? String) ?? "",
            foName: (o["foName"] as? String) ?? "",
            foCompanyId: id,
        )
    }

    static func parseQrPayResult(_ o: [String: Any]) -> QrPayResultParsed {
        let stRaw = ((o["status"] as? String) ?? "").trimmingCharacters(in: .whitespaces)
        let st = stRaw.isEmpty ? nil : stRaw.uppercased(with: Locale(identifier: "en_US"))
        return QrPayResultParsed(
            serverTxnId: stringOrNil(o["serverTxnId"]),
            vehicleRegNo: stringOrNil(o["vehicleRegNo"]),
            amountINR: doubleOrNil(o["amountINR"]),
            newBalanceINR: doubleOrNil(o["newBalanceINR"]),
            authCode: stringOrNil(o["authCode"]),
            txnTime: stringOrNil(o["txnTime"]),
            status: (st == "FAILED") ? "FAILED" : "SUCCESS",
            quantityKg: doubleOrNil(o["quantityKg"]),
        )
    }

    static func normalizeDriverTransactionsPayload(_ data: Any?) -> TxnsPageParsedIOS {
        if let arr = data as? [Any] {
            let rows = txnRowsFromArray(arr)
            return TxnsPageParsedIOS(rows: rows, page: 0, limit: rows.count, totalElements: rows.count, totalPages: rows.isEmpty ? 0 : 1)
        }
        guard let o = data as? [String: Any] else {
            return TxnsPageParsedIOS(rows: [], page: 0, limit: 0, totalElements: 0, totalPages: 0)
        }
        let content = o["content"] as? [Any] ?? []
        let rows = txnRowsFromArray(content)
        let page = intOrZero(o["page"])
        let limit = intOrZero(o["limit"])
        let totalE = intOrZero(o["totalElements"])
        let totalP = intOrZero(o["totalPages"])
        return TxnsPageParsedIOS(
            rows: rows,
            page: page,
            limit: limit == 0 && !rows.isEmpty ? rows.count : limit,
            totalElements: totalE == 0 && !rows.isEmpty ? rows.count : totalE,
            totalPages: totalP,
        )
    }

    private static func txnRowsFromArray(_ arr: [Any]) -> [DriverTxnRowParsed] {
        arr.compactMap { row -> DriverTxnRowParsed? in
            guard let o = row as? [String: Any] else { return nil }
            return DriverTxnRowParsed(
                serverTxnId: (o["serverTxnId"] as? String) ?? "",
                vehicleRegNo: (o["vehicleRegNo"] as? String) ?? "",
                amountINR: doubleOrNil(o["amountINR"]) ?? 0,
                status: (o["status"] as? String) ?? "",
                driverName: (o["driverName"] as? String) ?? "",
                createdOn: (o["createdOn"] as? String) ?? "",
            )
        }
    }

    private static func stringOrNil(_ v: Any?) -> String? {
        guard let s = v as? String else { return nil }
        let t = s.trimmingCharacters(in: .whitespaces)
        return t.isEmpty ? nil : t
    }

    private static func boolOrNil(_ v: Any?) -> Bool? {
        if let b = v as? Bool { return b }
        if let n = v as? NSNumber { return n.boolValue }
        return nil
    }

    private static func doubleOrNil(_ v: Any?) -> Double? {
        if let d = v as? Double { return d.isNaN ? nil : d }
        if let i = v as? Int { return Double(i) }
        if let n = v as? NSNumber { let d = n.doubleValue; return d.isNaN ? nil : d }
        return nil
    }

    private static func intOrZero(_ v: Any?) -> Int {
        if let i = v as? Int { return i }
        if let n = v as? NSNumber { return n.intValue }
        return 0
    }
}

private extension String {
    fileprivate var nilIfEmpty: String? { isEmpty ? nil : self }
}
