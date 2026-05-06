import Foundation

enum DemoAuthMode: Equatable {
    case vehicleLinked
    case shiftBased
    case tripLinked
}

enum DemoBindingState: Equatable {
    case active
    case pendingAcceptance
}

struct DemoDriver: Equatable {
    let id: String
    let name: String
    let initials: String
    let mobile: String
    let pin: String
}

struct DemoBinding: Identifiable, Equatable {
    let id: String
    var vrn: String
    var fo: String
    let authMode: DemoAuthMode
    let state: DemoBindingState
    var paired: Bool
    var scanPayStatus: String
    var balance: Int
    var cardBalance: Int
    var incentiveBalance: Int
    var spendLimit: Int
    var shiftDays: [String]
    var shiftStart: String
    var shiftEnd: String
    var tripStart: String
    var tripEnd: String
    var origin: String
    var destination: String
    var assignedBy: String?
    var validPairingCode: String?
}

struct DemoTxn: Identifiable, Equatable {
    let id: String
    let station: String
    let vrn: String
    let amount: Int
    let date: String
    let type: String
    let status: String
}

enum FleetReactMockIOS {
    static let driver = DemoDriver(
        id: "DRV001",
        name: "Ravi Sharma",
        initials: "RS",
        mobile: "9876501234",
        pin: "123456",
    )

    static let bindings: [DemoBinding] = [
        DemoBinding(
            id: "BND001",
            vrn: "MH 02 AB 1234",
            fo: "ABC Logistics Pvt. Ltd.",
            authMode: .vehicleLinked,
            state: .active,
            paired: true,
            scanPayStatus: "always_available",
            balance: 14600,
            cardBalance: 12500,
            incentiveBalance: 2100,
            spendLimit: 2000,
            shiftDays: [],
            shiftStart: "",
            shiftEnd: "",
            tripStart: "",
            tripEnd: "",
            origin: "",
            destination: "",
            assignedBy: nil,
            validPairingCode: nil,
        ),
        DemoBinding(
            id: "BND002",
            vrn: "MH 02 CD 5678",
            fo: "ABC Logistics Pvt. Ltd.",
            authMode: .shiftBased,
            state: .active,
            paired: true,
            scanPayStatus: "in_window",
            balance: 8200,
            cardBalance: 8200,
            incentiveBalance: 0,
            spendLimit: 1500,
            shiftDays: ["Mon", "Tue", "Wed", "Thu", "Fri"],
            shiftStart: "06:00",
            shiftEnd: "14:00",
            tripStart: "",
            tripEnd: "",
            origin: "",
            destination: "",
            assignedBy: nil,
            validPairingCode: nil,
        ),
        DemoBinding(
            id: "BND004",
            vrn: "MH 06 EF 3456",
            fo: "ABC Logistics Pvt. Ltd.",
            authMode: .vehicleLinked,
            state: .pendingAcceptance,
            paired: false,
            scanPayStatus: "locked_unpaired",
            balance: 0,
            cardBalance: 0,
            incentiveBalance: 0,
            spendLimit: 2000,
            shiftDays: [],
            shiftStart: "",
            shiftEnd: "",
            tripStart: "",
            tripEnd: "",
            origin: "",
            destination: "",
            assignedBy: "Ramesh Shah",
            validPairingCode: "234567",
        ),
    ]

    static let transactions: [DemoTxn] = [
        DemoTxn(id: "TXN001", station: "MGL Hind CNG Filling", vrn: "MH 02 AB 1234", amount: 672, date: "Mar 23", type: "Fueling", status: "Success"),
    ]

    static var assignmentForPairing: DemoBinding { bindings[2] }

    static let inviteCodes = ["ABC123": "ABC Logistics Pvt. Ltd."]
}
