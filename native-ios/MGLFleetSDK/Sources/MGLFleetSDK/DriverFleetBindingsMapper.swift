import Foundation

enum DriverFleetBindingsMapper {
    static func mapAssignmentsToDemoBindings(
        home: DriverHomeParsed?,
        rows: [DriverAssignmentParsed],
    ) -> [DemoBinding] {
        let homeVrn = home?.vehicleRegNo.map { DriverFleetQr.normVrnPublic($0) } ?? ""
        let hasHomeVrn = !homeVrn.isEmpty

        func parseShiftDays(_ csv: String?) -> [String]? {
            guard let csv, !csv.isEmpty else { return nil }
            return csv.split(separator: ",").map { d in
                let t = String(d).trimmingCharacters(in: .whitespaces)
                guard t.count >= 2 else { return t }
                let take = min(3, t.count)
                let idx = t.index(t.startIndex, offsetBy: take)
                let suffix = String(t[t.index(after: t.startIndex) ..< idx]).lowercased(with: Locale(identifier: "en_US"))
                return String(t.prefix(1)) + suffix
            }
        }

        func authMode(for t: String) -> DemoAuthMode {
            switch t.uppercased() {
            case "WHOLE_TIME": return .vehicleLinked
            case "SHIFT": return .shiftBased
            default: return .tripLinked
            }
        }

        return rows.map { a in
            let matchesHome = home?.hasActiveVehicle == true && hasHomeVrn &&
                DriverFleetQr.normVrnPublic(a.vehicleRegNo) == homeVrn
            let activeEligible = a.status == "ACTIVE" && !a.requiresPairing
            let homeEligible =
                home?.isCurrentlyEligible == true
                || home?.currentlyEligible == true
                || (home?.isCurrentlyEligible == nil && home?.currentlyEligible == nil && activeEligible)
            let eligible = matchesHome ? homeEligible : activeEligible

            let scanPay: String = {
                if a.status == "PENDING_ACCEPTANCE" && a.requiresPairing { return "locked_unpaired" }
                if !eligible { return "out_window" }
                switch a.assignmentType.uppercased() {
                case "WHOLE_TIME": return "always_available"
                case "SHIFT": return "in_window"
                default: return "trip_window"
                }
            }()

            let balance: Int =
                matchesHome ? Int((home?.totalBalanceINR ?? 0).rounded()) : 0
            let foFromHome: String = {
                guard matchesHome, let n = home?.foName?.trimmingCharacters(in: .whitespaces), !n.isEmpty else { return "" }
                return n
            }()

            let state: DemoBindingState = a.status == "PENDING_ACCEPTANCE" ? .pendingAcceptance : .active
            let paired = !(a.status == "PENDING_ACCEPTANCE" && a.requiresPairing)

            return DemoBinding(
                id: String(a.vehicleDriverId),
                vrn: a.vehicleRegNo,
                fo: foFromHome,
                vehicleId: a.vehicleId,
                authMode: authMode(for: a.assignmentType),
                state: state,
                paired: paired,
                scanPayStatus: scanPay,
                balance: balance,
                cardBalance: balance,
                incentiveBalance: 0,
                spendLimit: 2000,
                shiftDays: parseShiftDays(a.shiftDaysOfWeek) ?? [],
                shiftStart: a.shiftStartTime ?? "",
                shiftEnd: a.shiftEndTime ?? "",
                tripStart: a.tripStartTime ?? "",
                tripEnd: a.tripEndTime ?? "",
                tripDate: a.tripDate ?? "",
                origin: a.tripStartLocation ?? "",
                destination: "",
                assignedBy: nil,
                validPairingCode: nil,
                repairReason: nil,
            )
        }
    }
}
