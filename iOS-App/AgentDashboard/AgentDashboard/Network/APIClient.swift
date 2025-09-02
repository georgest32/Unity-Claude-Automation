// APIClient.swift
import Foundation
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

  public var errorDescription: String? {
    if let code { return "[\(code)] \(message)" }
    return message
  }

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
  public var json: @Sendable <T: Decodable>(
    _ request: URLRequest,
    _ configureDecoder: @Sendable ((inout JSONDecoder) -> Void)?
  ) async throws -> T

  public init(
    data: @escaping @Sendable (_ request: URLRequest) async throws -> (Data, URLResponse),
    json: @escaping @Sendable <T: Decodable>(
      _ request: URLRequest,
      _ configureDecoder: @Sendable ((inout JSONDecoder) -> Void)?
    ) async throws -> T
  ) {
    self.data = data
    self.json = json
  }

  @inlinable
  public func json<T: Decodable>(_ request: URLRequest) async throws -> T {
    try await self.json(request, nil)
  }
}

// MARK: - Live implementation

extension APIClient: DependencyKey {
  public static var liveValue: APIClient {
    let config = URLSessionConfiguration.ephemeral
    config.timeoutIntervalForRequest = 30
    config.timeoutIntervalForResource = 60

    let http = HTTPSession(configuration: config)

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
        decoder.dateDecodingStrategy = .iso8601
        if let configureDecoder {
          var d = decoder
          configureDecoder(&d)
          return try d.decode(T.self, from: data)
        } else {
          return try decoder.decode(T.self, from: data)
        }
      }
    )
  }

  public static var testValue: APIClient {
    APIClient(
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

  public static var previewValue: APIClient { .testValue }
}

// MARK: - Dependency Accessor

public extension DependencyValues {
  var apiClient: APIClient {
    get { self[APIClient.self] }
    set { self[APIClient.self] = newValue }
  }
}

// MARK: - Convenience builders

public enum RequestBuilder {
  public static func get(url: URL, headers: [String: String] = [:]) -> URLRequest {
    var req = URLRequest(url: url)
    req.httpMethod = "GET"
    headers.forEach { req.addValue($1, forHTTPHeaderField: $0) }
    return req
  }

  public static func postJSON<Body: Encodable>(
    url: URL,
    body: Body,
    headers: [String: String] = [:]
  ) throws -> URLRequest {
    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.addValue("application/json", forHTTPHeaderField: "Content-Type")
    headers.forEach { req.addValue($1, forHTTPHeaderField: $0) }
    req.httpBody = try JSONEncoder().encode(body)
    return req
  }
}
