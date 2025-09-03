import Foundation
import Dependencies

// MARK: - Errors
public enum APIError: Error, Sendable {
  case http(Int, body: Data?)
  case decoding(String)
  case other(String)
  case message(String)

  var code: Int? {
    if case let .http(code, _) = self { return code }
    return nil
  }
}

// MARK: - API Client
public struct APIClient: Sendable {
  // Non-generic transport
  public var data: @Sendable (URLRequest) async throws -> (Data, URLResponse)

  public init(
    data: @escaping @Sendable (URLRequest) async throws -> (Data, URLResponse)
  ) {
    self.data = data
  }

  // Generic decode as a METHOD (allowed)
  public func decode<T: Decodable>(
    _ type: T.Type,
    from request: URLRequest,
    configureDecoder: ((inout JSONDecoder) -> Void)? = nil
  ) async throws -> T {
    let (bytes, response) = try await data(request)

    guard let http = response as? HTTPURLResponse else {
      throw APIError.message("Non-HTTP response")
    }
    guard (200..<300).contains(http.statusCode) else {
      throw APIError.http(http.statusCode, body: bytes)
    }

    var decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    if let configureDecoder {
      var d = decoder
      configureDecoder(&d)
      return try d.decode(T.self, from: bytes)
    } else {
      return try decoder.decode(T.self, from: bytes)
    }
  }

  // Convenience matching older call sites
  public func json<T: Decodable>(
    _ request: URLRequest,
    _ configureDecoder: ((inout JSONDecoder) -> Void)? = nil
  ) async throws -> T {
    try await decode(T.self, from: request, configureDecoder: configureDecoder)
  }

  // Optional endpoint helper (if you use APIEndpoint)
  public func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
    let baseURL = URL(string: "http://localhost:5000")!
    let url = baseURL.appendingPathComponent(endpoint.path)
    var req = URLRequest(url: url)
    req.httpMethod = endpoint.method.rawValue
    if let headers = endpoint.headers {
      headers.forEach { req.addValue($1, forHTTPHeaderField: $0) }
    }
    if let body = endpoint.body {
      req.httpBody = try JSONEncoder().encode(AnyEncodable(body))
      req.addValue("application/json", forHTTPHeaderField: "Content-Type")
    }
    return try await json(req)
  }
}

// MARK: - Live/Test
extension APIClient: DependencyKey {
  public static var liveValue: APIClient {
    let cfg = URLSessionConfiguration.ephemeral
    cfg.timeoutIntervalForRequest = 30
    cfg.timeoutIntervalForResource = 60
    let session = URLSession(configuration: cfg)
    return APIClient { req in try await session.data(for: req) }
  }

  public static var testValue: APIClient {
    APIClient { _ in
      struct Unimplemented: Error {}
      throw Unimplemented()
    }
  }
}

public extension DependencyValues {
  var apiClient: APIClient {
    get { self[APIClient.self] }
    set { self[APIClient.self] = newValue }
  }
}

// MARK: - Agent helpers used by AgentsFeature
public extension APIClient {
  func fetchAgents() async throws -> [Agent] {
    try await json(URLRequest(url: URL(string: "http://localhost:5000/api/agents")!))
  }
  func startAgent(_ id: String) async throws -> String {
    var r = URLRequest(url: URL(string: "http://localhost:5000/api/agents/\(id)/start")!)
    r.httpMethod = "POST"
    return try await json(r)
  }
  func stopAgent(_ id: String) async throws -> String {
    var r = URLRequest(url: URL(string: "http://localhost:5000/api/agents/\(id)/stop")!)
    r.httpMethod = "POST"
    return try await json(r)
  }
  func pauseAgent(_ id: String) async throws -> String {
    var r = URLRequest(url: URL(string: "http://localhost:5000/api/agents/\(id)/pause")!)
    r.httpMethod = "POST"
    return try await json(r)
  }
  func resumeAgent(_ id: String) async throws -> String {
    var r = URLRequest(url: URL(string: "http://localhost:5000/api/agents/\(id)/resume")!)
    r.httpMethod = "POST"
    return try await json(r)
  }
}

// MARK: - Types
public struct APIEndpoint: Sendable {
  public enum Method: String { case get = "GET", post = "POST", put = "PUT", patch = "PATCH", delete = "DELETE" }
  public var path: String
  public var method: Method
  public var headers: [String:String]?
  public var body: (any Encodable)?
  public init(path: String, method: Method = .get, headers: [String:String]? = nil, body: (any Encodable)? = nil) {
    self.path = path; self.method = method; self.headers = headers; self.body = body
  }
}

private struct AnyEncodable: Encodable {
  private let encodeFunc: (Encoder) throws -> Void
  init(_ value: any Encodable) { self.encodeFunc = value.encode }
  func encode(to encoder: Encoder) throws { try encodeFunc(encoder) }
}