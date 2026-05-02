import Foundation

public struct Driver: Codable {
    public let id: String
    public let name: String
    public let vrn: String
    public let status: String
    public let cardBalancePaise: Int64
}
