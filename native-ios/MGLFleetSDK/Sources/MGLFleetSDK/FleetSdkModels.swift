import Foundation

public struct FleetSdkOptions {
    public var apiBaseUrl: String
    public var authToken: String?
    public var useMock: Bool
    /// When opening the flow already FO-authenticated (`authToken`), pass FO id so Profile → Change PIN can call `pin/reset`.
    public var foCompanyId: Int64?

    public init(apiBaseUrl: String, authToken: String? = nil, useMock: Bool = true, foCompanyId: Int64? = nil) {
        self.apiBaseUrl = apiBaseUrl
        self.authToken = authToken
        self.useMock = useMock
        self.foCompanyId = foCompanyId
    }
}

public struct FleetSessionOptions {
    public var correlationId: String?

    public init(correlationId: String? = nil) {
        self.correlationId = correlationId
    }
}

public enum FleetSdkResult {
    case success(event: String, payload: [String: Any])
    case failure(FleetSdkError)
}

public typealias FleetSdkCompletionHandler = (FleetSdkResult) -> Void

public protocol FleetSdkEventListener: AnyObject {
    func onEvent(name: String, payload: [String: Any]?)
}
