// APIClient.swift
@preconcurrency import Foundation
import Dependencies

// MARK: - Errors

public struct APIError: Error, Sendable, LocalizedError, Equatable {
  public let code: Int?
  public let message: String
  public let underlying: String?

  public init(code: Int?, message: String, underlying: String? = nil) {
    self.code = code
    self.message = message
    self.underlying = underlying
  }

  public var errorDescription: String? { message }

  public static func http(_ status: Int, body: Data?) -> APIError {
    let bodyString = body.flatMap { String(data: $0, encoding: .utf8) }?
      .trimmingCharacters(in: .whitespacesAndNewlines)
    return APIError(code: status, message: "HTTP \(status)", underlying: bodyString)
  }
}

// MARK: - Actor that owns URLSession

actor HTTPSession {
  private let session: URLSession

  init(configuration: URLSessionConfiguration = .ephemeral) {
    self.session = URLSession(configuration: configuration)
  }

  func data(for request: URLRequest) async throws -> (Data, URLResponse) {
    try await session.data(for: request)
  }
}

// MARK: - Client

public struct APIClient: Sendable {
  public var data: @Sendable (_ request: URLRequest) async throws -> (Data, URLResponse)
  public var json: @Sendable <T: Decodable>(_ request: URLRequest,
                                            _ configureDecoder: @Sendable ((inout JSONDecoder) -> Void)?)
    async throws -> T

  public init(
    data: @escaping @Sendable (_: URLRequest) async throws -> (Data, URLResponse),
    json: @escaping @Sendable <T: Decodable>(_: URLRequest,
                                             _: @Sendable ((inout JSONDecoder) -> Void)?)
      async throws -> T
  ) {
    self.data = data
    self.json = json
  }

  // Convenience
  @inlinable
  public func json<T: Decodable>(_ request: URLRequest) async throws -> T {
    try await self.json(request, nil)
  }
}

// MARK: - Live implementation

extension APIClient {
  public static let live: APIClient = {
    let http = HTTPSession() // actor is Sendable-safe to capture

    return APIClient(
      data: { request in
        try await http.data(for: request)
      },
      json: { (request: URLRequest, configureDecoder) in
        let (data, response) = try await http.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
          throw APIError(code: nil, message: "Non-HTTP response")
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
          throw APIError.http(httpResponse.statusCode, body: data)
        }

        var decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        if let configureDecoder { configureDecoder(&decoder) }

        do {
          return try decoder.decode(T.self, from: data)
        } catch {
          let sample = String(data: data.prefix(512), encoding: .utf8)
          throw APIError(code: httpResponse.statusCode,
                         message: "Decoding error: \(T.self)",
                         underlying: sample)
        }
      }
    )
  }()
}

// MARK: - Dependencies wiring (Point-Free)

extension APIClient: DependencyKey {
  public static let liveValue: APIClient = .live

  public static let testValue: APIClient = APIClient(
    data: { _ in
      struct Unimplemented: Error {}
      throw Unimplemented()
    },
    json: { _, _ in
      struct Unimplemented: Error {}
      throw Unimplemented()
    }
  )
}

public extension DependencyValues {
  var apiClient: APIClient {
    get { self[APIClient.self] }
    set { self[APIClient.self] = newValue }
  }
}
