// APIClient.swift - Swift 6 Safe Implementation
@preconcurrency import Foundation   // lets us use Foundation types without extra Sendable warnings
import Dependencies

public struct APIError: Error, Sendable, LocalizedError {
  public let code: Int?
  public let message: String

  public var errorDescription: String? { message }

  public static func http(_ status: Int, body: Data?) -> APIError {
    APIError(code: status, message: "HTTP \(status)" + (body.flatMap { " – " + (String(data:$0, encoding:.utf8) ?? "") } ?? ""))
  }
}

public struct APIClient: Sendable {
  public var data: @Sendable (_ request: URLRequest) async throws -> (Data, URLResponse)
  public var json: @Sendable <T: Decodable>(_ request: URLRequest, _ configureDecoder: @Sendable ((inout JSONDecoder) -> Void)? ) async throws -> T

  public init(
    data: @escaping @Sendable (_ request: URLRequest) async throws -> (Data, URLResponse),
    json: @escaping @Sendable <T: Decodable>(_ request: URLRequest, _ configureDecoder: @Sendable ((inout JSONDecoder) -> Void)? ) async throws -> T
  ) {
    self.data = data
    self.json = json
  }
}

extension APIClient {
  public static let live: APIClient = {
    APIClient(
      data: { request in
        // Create a fresh URLSession configuration each call to avoid capturing non-Sendable state
        let session = URLSession(configuration: .ephemeral)
        return try await session.data(for: request)
      },
      json: { (request: URLRequest, configureDecoder) in
        let session = URLSession(configuration: .ephemeral)
        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
          throw APIError(code: nil, message: "Non-HTTP response")
        }
        guard (200..<300).contains(http.statusCode) else {
          throw APIError.http(http.statusCode, body: data)
        }

        var decoder = JSONDecoder()
        // sensible defaults; adjust if you need custom strategies
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        if let configure = configureDecoder { configure(&decoder) }

        return try decoder.decode(T.self, from: data)
      }
    )
  }()

  // A convenient helper when you just want JSON with defaults
  @inlinable
  public func json<T: Decodable>(_ request: URLRequest) async throws -> T {
    try await self.json(request, nil)
  }
}

// MARK: - Dependencies wiring (Point-Free)

extension APIClient: DependencyKey {
  public static let liveValue: APIClient = .live

  // A failing default for tests; replace with your own fixtures
  public static let testValue: APIClient = APIClient(
    data: { _ in
      fatalError("APIClient.data not implemented in tests")
    },
    json: { _, _ in
      fatalError("APIClient.json not implemented in tests")
    }
  )
}

public extension DependencyValues {
  var apiClient: APIClient {
    get { self[APIClient.self] }
    set { self[APIClient.self] = newValue }
  }
}

// MARK: - Mock Data for Development

extension APIClient {
  public static let mock = APIClient(
    data: { _ in
      let mockData = Data("{}".utf8)
      let response = HTTPURLResponse(url: URL(string: "https://api.mock")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
      return (mockData, response)
    },
    json: { _, _ in
      // Mock Agent data for development
      return [
        Agent(
          id: UUID().uuidString,
          name: "CLI Orchestrator",
          type: "CLI Orchestrator",
          status: .running
        )
      ] as! T
    }
  )
}