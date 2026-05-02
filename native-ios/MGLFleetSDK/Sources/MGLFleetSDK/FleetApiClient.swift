import Foundation

/// Minimal REST client aligned with `docs/openapi/fleet-api.yaml`.
public final class FleetApiClient {
    private let options: FleetSdkOptions
    private let session: URLSession

    public init(options: FleetSdkOptions, session: URLSession = .shared) {
        self.options = options
        self.session = session
    }

    public static func `default`(resolvedOptions: FleetSdkOptions?) throws -> FleetApiClient {
        guard let o = resolvedOptions else {
            throw FleetSdkError(code: .notInitialized, message: "FleetSdk.initialize required.")
        }
        return FleetApiClient(options: o)
    }

    public func listDrivers(completion: @escaping (Result<[Driver], Error>) -> Void) {
        if options.useMock {
            completion(.success([
                Driver(
                    id: "DRV001",
                    name: "Demo Driver",
                    vrn: "MH 02 AB 1234",
                    status: "Active",
                    cardBalancePaise: 1_250_000,
                ),
            ]))
            return
        }

        var base = options.apiBaseUrl
        while base.hasSuffix("/") {
            base.removeLast()
        }
        guard let url = URL(string: base + "/fleet/drivers") else {
            completion(.failure(FleetSdkError(code: .invalidInput, message: "Bad apiBaseUrl")))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = options.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        session.dataTask(with: request) { data, _, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard let data else {
                completion(.failure(FleetSdkError(code: .networkError, message: "Empty response")))
                return
            }
            do {
                let decoded = try JSONDecoder().decode(DriversResponse.self, from: data)
                completion(.success(decoded.drivers))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    private struct DriversResponse: Codable {
        let drivers: [Driver]
    }
}
