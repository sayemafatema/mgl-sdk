import Foundation

public enum FleetSdkErrorCodes: Int {
    case invalidInput = 1001
    case notInitialized = 1002
    case userCancelled = 1003
    case internalSdkError = 1004
    case permissionDenied = 1005
    case networkError = 1007
}

public struct FleetSdkError: Error {
    public let code: FleetSdkErrorCodes
    public let message: String

    public init(code: FleetSdkErrorCodes, message: String) {
        self.code = code
        self.message = message
    }
}
