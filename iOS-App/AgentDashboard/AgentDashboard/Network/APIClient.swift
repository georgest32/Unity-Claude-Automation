//
//  APIClient.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  REST API client for Unity-Claude-Automation backend
//

import Foundation
import Dependencies

// MARK: - API Client Protocol

protocol APIClientProtocol {
    func fetchSystemStatus() async throws -> SystemStatus
    func fetchAgents() async throws -> [Agent]
    func fetchModules() async throws -> [Module]
    func executeCommand(_ command: String) async throws -> CommandResult
    func authenticate(username: String, password: String) async throws -> AuthToken
    
    // Agent control operations
    func startAgent(_ id: UUID) async throws -> AgentActionResult
    func stopAgent(_ id: UUID) async throws -> AgentActionResult
    func pauseAgent(_ id: UUID) async throws -> AgentActionResult
    func resumeAgent(_ id: UUID) async throws -> AgentActionResult
    func restartAgent(_ id: UUID) async throws -> AgentActionResult
    func getAgentConfiguration(_ id: UUID) async throws -> [String: Any]
    func updateAgentConfiguration(_ id: UUID, configuration: [String: Any]) async throws -> AgentActionResult
}

// MARK: - API Models

struct CommandResult: Codable {
    let id: UUID
    let command: String
    let output: String?
    let error: String?
    let exitCode: Int
    let executionTime: TimeInterval
    let timestamp: Date
}

struct AuthToken: Codable {
    let token: String
    let refreshToken: String
    let expiresAt: Date
    let user: User
}

struct AgentActionResult: Codable {
    let success: Bool
    let message: String
    let agentId: UUID
    let action: String
    let timestamp: Date
    let executionTime: TimeInterval?
    
    init(success: Bool, message: String, agentId: UUID, action: String, executionTime: TimeInterval? = nil) {
        self.success = success
        self.message = message
        self.agentId = agentId
        self.action = action
        self.timestamp = Date()
        self.executionTime = executionTime
    }
}

// MARK: - API Client Implementation

final class APIClient: APIClientProtocol {
    private let session: URLSession
    private let baseURL: URL
    private var authToken: String?
    
    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        print("[APIClient] Initialized with base URL: \(baseURL)")
    }
    
    func fetchSystemStatus() async throws -> SystemStatus {
        print("[APIClient] Fetching system status...")
        
        let url = baseURL.appendingPathComponent("/api/system/status")
        let request = try createRequest(for: url, method: "GET")
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        let systemStatus = try JSONDecoder().decode(SystemStatus.self, from: data)
        print("[APIClient] System status fetched successfully")
        systemStatus.debugDescription
        
        return systemStatus
    }
    
    func fetchAgents() async throws -> [Agent] {
        print("[APIClient] Fetching agents...")
        
        let url = baseURL.appendingPathComponent("/api/agents")
        let request = try createRequest(for: url, method: "GET")
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        let agents = try JSONDecoder().decode([Agent].self, from: data)
        print("[APIClient] Fetched \(agents.count) agents")
        
        return agents
    }
    
    func fetchModules() async throws -> [Module] {
        print("[APIClient] Fetching modules...")
        
        let url = baseURL.appendingPathComponent("/api/modules")
        let request = try createRequest(for: url, method: "GET")
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        let modules = try JSONDecoder().decode([Module].self, from: data)
        print("[APIClient] Fetched \(modules.count) modules")
        
        return modules
    }
    
    func executeCommand(_ command: String) async throws -> CommandResult {
        print("[APIClient] Executing command: \(command)")
        
        let url = baseURL.appendingPathComponent("/api/commands/execute")
        var request = try createRequest(for: url, method: "POST")
        
        let commandRequest = ["command": command]
        request.httpBody = try JSONEncoder().encode(commandRequest)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        let result = try JSONDecoder().decode(CommandResult.self, from: data)
        print("[APIClient] Command executed with exit code: \(result.exitCode)")
        
        return result
    }
    
    func authenticate(username: String, password: String) async throws -> AuthToken {
        print("[APIClient] Authenticating user: \(username)")
        
        let url = baseURL.appendingPathComponent("/api/auth/login")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let credentials = ["username": username, "password": password]
        request.httpBody = try JSONEncoder().encode(credentials)
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        let authToken = try JSONDecoder().decode(AuthToken.self, from: data)
        self.authToken = authToken.token
        
        print("[APIClient] Authentication successful for user: \(authToken.user.username)")
        return authToken
    }
    
    // MARK: - Agent Control Operations
    
    func startAgent(_ id: UUID) async throws -> AgentActionResult {
        print("[APIClient] Starting agent: \(id)")
        
        let url = baseURL.appendingPathComponent("/api/agents/\(id.uuidString)/start")
        let request = try createRequest(for: url, method: "POST")
        
        let startTime = Date()
        let (data, response) = try await session.data(for: request)
        let executionTime = Date().timeIntervalSince(startTime)
        
        try validateResponse(response)
        
        let result = try JSONDecoder().decode(AgentActionResult.self, from: data)
        print("[APIClient] Agent start result: \(result.success ? "SUCCESS" : "FAILED") - \(result.message)")
        
        return result
    }
    
    func stopAgent(_ id: UUID) async throws -> AgentActionResult {
        print("[APIClient] Stopping agent: \(id)")
        
        let url = baseURL.appendingPathComponent("/api/agents/\(id.uuidString)/stop")
        let request = try createRequest(for: url, method: "POST")
        
        let startTime = Date()
        let (data, response) = try await session.data(for: request)
        let executionTime = Date().timeIntervalSince(startTime)
        
        try validateResponse(response)
        
        let result = try JSONDecoder().decode(AgentActionResult.self, from: data)
        print("[APIClient] Agent stop result: \(result.success ? "SUCCESS" : "FAILED") - \(result.message)")
        
        return result
    }
    
    func pauseAgent(_ id: UUID) async throws -> AgentActionResult {
        print("[APIClient] Pausing agent: \(id)")
        
        let url = baseURL.appendingPathComponent("/api/agents/\(id.uuidString)/pause")
        let request = try createRequest(for: url, method: "POST")
        
        let startTime = Date()
        let (data, response) = try await session.data(for: request)
        let executionTime = Date().timeIntervalSince(startTime)
        
        try validateResponse(response)
        
        let result = try JSONDecoder().decode(AgentActionResult.self, from: data)
        print("[APIClient] Agent pause result: \(result.success ? "SUCCESS" : "FAILED") - \(result.message)")
        
        return result
    }
    
    func resumeAgent(_ id: UUID) async throws -> AgentActionResult {
        print("[APIClient] Resuming agent: \(id)")
        
        let url = baseURL.appendingPathComponent("/api/agents/\(id.uuidString)/resume")
        let request = try createRequest(for: url, method: "POST")
        
        let startTime = Date()
        let (data, response) = try await session.data(for: request)
        let executionTime = Date().timeIntervalSince(startTime)
        
        try validateResponse(response)
        
        let result = try JSONDecoder().decode(AgentActionResult.self, from: data)
        print("[APIClient] Agent resume result: \(result.success ? "SUCCESS" : "FAILED") - \(result.message)")
        
        return result
    }
    
    func restartAgent(_ id: UUID) async throws -> AgentActionResult {
        print("[APIClient] Restarting agent: \(id)")
        
        let url = baseURL.appendingPathComponent("/api/agents/\(id.uuidString)/restart")
        let request = try createRequest(for: url, method: "POST")
        
        let startTime = Date()
        let (data, response) = try await session.data(for: request)
        let executionTime = Date().timeIntervalSince(startTime)
        
        try validateResponse(response)
        
        let result = try JSONDecoder().decode(AgentActionResult.self, from: data)
        print("[APIClient] Agent restart result: \(result.success ? "SUCCESS" : "FAILED") - \(result.message)")
        
        return result
    }
    
    func getAgentConfiguration(_ id: UUID) async throws -> [String: Any] {
        print("[APIClient] Getting agent configuration: \(id)")
        
        let url = baseURL.appendingPathComponent("/api/agents/\(id.uuidString)/config")
        let request = try createRequest(for: url, method: "GET")
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        guard let configuration = json as? [String: Any] else {
            throw APIError.invalidResponse
        }
        
        print("[APIClient] Retrieved configuration with \(configuration.keys.count) keys")
        return configuration
    }
    
    func updateAgentConfiguration(_ id: UUID, configuration: [String: Any]) async throws -> AgentActionResult {
        print("[APIClient] Updating agent configuration: \(id)")
        
        let url = baseURL.appendingPathComponent("/api/agents/\(id.uuidString)/config")
        var request = try createRequest(for: url, method: "PUT")
        
        request.httpBody = try JSONSerialization.data(withJSONObject: configuration, options: [])
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let startTime = Date()
        let (data, response) = try await session.data(for: request)
        let executionTime = Date().timeIntervalSince(startTime)
        
        try validateResponse(response)
        
        let result = try JSONDecoder().decode(AgentActionResult.self, from: data)
        print("[APIClient] Agent configuration update result: \(result.success ? "SUCCESS" : "FAILED") - \(result.message)")
        
        return result
    }
    
    // MARK: - Helper Methods
    
    private func createRequest(for url: URL, method: String) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        // Add authentication header if available
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add default headers
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("AgentDashboard/1.0", forHTTPHeaderField: "User-Agent")
        
        return request
    }
    
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("[APIClient] Response status code: \(httpResponse.statusCode)")
        
        switch httpResponse.statusCode {
        case 200...299:
            return // Success
        case 401:
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        case 404:
            throw APIError.notFound
        case 429:
            throw APIError.rateLimited
        case 500...599:
            throw APIError.serverError(httpResponse.statusCode)
        default:
            throw APIError.httpError(httpResponse.statusCode)
        }
    }
}

// MARK: - API Errors

enum APIError: Error, LocalizedError {
    case invalidResponse
    case unauthorized
    case forbidden
    case notFound
    case rateLimited
    case serverError(Int)
    case httpError(Int)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Unauthorized - please check your credentials"
        case .forbidden:
            return "Access forbidden"
        case .notFound:
            return "Resource not found"
        case .rateLimited:
            return "Rate limit exceeded - please try again later"
        case .serverError(let code):
            return "Server error (\(code))"
        case .httpError(let code):
            return "HTTP error (\(code))"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - API Dependency Key

private enum APIClientKey: DependencyKey {
    static let liveValue: APIClientProtocol = {
        // Default to localhost for development
        let url = URL(string: "http://localhost:8080")!
        return APIClient(baseURL: url)
    }()
    
    static let testValue: APIClientProtocol = MockAPIClient()
    
    static let previewValue: APIClientProtocol = MockAPIClient()
}

// MARK: - Dependency Registration

extension DependencyValues {
    var apiClient: APIClientProtocol {
        get { self[APIClientKey.self] }
        set { self[APIClientKey.self] = newValue }
    }
}

// MARK: - Mock API Client for Testing

final class MockAPIClient: APIClientProtocol {
    func fetchSystemStatus() async throws -> SystemStatus {
        print("[MockAPIClient] Fetching mock system status...")
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        return SystemStatus(
            timestamp: Date(),
            isHealthy: true,
            cpuUsage: Double.random(in: 20...80),
            memoryUsage: Double.random(in: 30...70),
            diskUsage: Double.random(in: 40...80),
            activeAgents: Int.random(in: 3...7),
            totalModules: 12,
            uptime: TimeInterval(Int.random(in: 3600...86400))
        )
    }
    
    func fetchAgents() async throws -> [Agent] {
        print("[MockAPIClient] Fetching mock agents...")
        
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        return [
            Agent(
                id: UUID(),
                name: "CLI Orchestrator",
                type: .orchestrator,
                status: .running,
                description: "Main orchestration agent",
                startTime: Date().addingTimeInterval(-3600),
                lastActivity: Date(),
                resourceUsage: ResourceUsage(cpu: 15.5, memory: 45.2, threads: 4, handles: 32),
                configuration: ["mode": "auto", "priority": "high"]
            ),
            Agent(
                id: UUID(),
                name: "System Monitor",
                type: .monitor,
                status: .running,
                description: "System health monitoring",
                startTime: Date().addingTimeInterval(-7200),
                lastActivity: Date().addingTimeInterval(-60),
                resourceUsage: ResourceUsage(cpu: 8.3, memory: 25.1, threads: 2, handles: 18),
                configuration: ["interval": "30s", "alerts": "enabled"]
            )
        ]
    }
    
    func fetchModules() async throws -> [Module] {
        print("[MockAPIClient] Fetching mock modules...")
        
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        return [
            Module(
                id: UUID(),
                name: "Unity-Claude-Core",
                version: "1.2.1",
                isLoaded: true,
                dependencies: ["PowerShell.Core"],
                lastModified: Date().addingTimeInterval(-86400)
            ),
            Module(
                id: UUID(),
                name: "Unity-Claude-SystemStatus",
                version: "1.1.0",
                isLoaded: true,
                dependencies: ["Unity-Claude-Core"],
                lastModified: Date().addingTimeInterval(-172800)
            )
        ]
    }
    
    func executeCommand(_ command: String) async throws -> CommandResult {
        print("[MockAPIClient] Executing mock command: \(command)")
        
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        return CommandResult(
            id: UUID(),
            command: command,
            output: "Mock output for command: \(command)",
            error: nil,
            exitCode: 0,
            executionTime: 0.5,
            timestamp: Date()
        )
    }
    
    func authenticate(username: String, password: String) async throws -> AuthToken {
        print("[MockAPIClient] Mock authentication for: \(username)")
        
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        let user = User(
            id: UUID(),
            username: username,
            email: "\(username)@example.com",
            role: .admin,
            createdAt: Date().addingTimeInterval(-86400)
        )
        
        return AuthToken(
            token: "mock_jwt_token_\(UUID().uuidString)",
            refreshToken: "mock_refresh_token_\(UUID().uuidString)",
            expiresAt: Date().addingTimeInterval(3600), // 1 hour
            user: user
        )
    }
    
    // MARK: - Mock Agent Control Operations
    
    func startAgent(_ id: UUID) async throws -> AgentActionResult {
        print("[MockAPIClient] Mock starting agent: \(id)")
        
        try await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds to simulate PowerShell execution
        
        // Simulate success most of the time, occasional failures for testing
        let success = Bool.random() ? true : (Int.random(in: 1...10) > 2) // 80% success rate
        let message = success ? "Agent started successfully" : "Failed to start agent: Mock error condition"
        
        return AgentActionResult(
            success: success,
            message: message,
            agentId: id,
            action: "start",
            executionTime: 0.8
        )
    }
    
    func stopAgent(_ id: UUID) async throws -> AgentActionResult {
        print("[MockAPIClient] Mock stopping agent: \(id)")
        
        try await Task.sleep(nanoseconds: 600_000_000) // 0.6 seconds
        
        let success = Bool.random() ? true : (Int.random(in: 1...10) > 1) // 90% success rate
        let message = success ? "Agent stopped successfully" : "Failed to stop agent: Mock timeout"
        
        return AgentActionResult(
            success: success,
            message: message,
            agentId: id,
            action: "stop",
            executionTime: 0.6
        )
    }
    
    func pauseAgent(_ id: UUID) async throws -> AgentActionResult {
        print("[MockAPIClient] Mock pausing agent: \(id)")
        
        try await Task.sleep(nanoseconds: 400_000_000) // 0.4 seconds
        
        let success = Bool.random() ? true : (Int.random(in: 1...10) > 1) // 90% success rate
        let message = success ? "Agent paused successfully" : "Failed to pause agent: Not running"
        
        return AgentActionResult(
            success: success,
            message: message,
            agentId: id,
            action: "pause",
            executionTime: 0.4
        )
    }
    
    func resumeAgent(_ id: UUID) async throws -> AgentActionResult {
        print("[MockAPIClient] Mock resuming agent: \(id)")
        
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        let success = Bool.random() ? true : (Int.random(in: 1...10) > 1) // 90% success rate
        let message = success ? "Agent resumed successfully" : "Failed to resume agent: Not paused"
        
        return AgentActionResult(
            success: success,
            message: message,
            agentId: id,
            action: "resume",
            executionTime: 0.5
        )
    }
    
    func restartAgent(_ id: UUID) async throws -> AgentActionResult {
        print("[MockAPIClient] Mock restarting agent: \(id)")
        
        try await Task.sleep(nanoseconds: 1_200_000_000) // 1.2 seconds for stop + start sequence
        
        let success = Bool.random() ? true : (Int.random(in: 1...10) > 2) // 80% success rate
        let message = success ? "Agent restarted successfully" : "Failed to restart agent: Mock dependency error"
        
        return AgentActionResult(
            success: success,
            message: message,
            agentId: id,
            action: "restart",
            executionTime: 1.2
        )
    }
    
    func getAgentConfiguration(_ id: UUID) async throws -> [String: Any] {
        print("[MockAPIClient] Mock getting agent configuration: \(id)")
        
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        return [
            "mode": "auto",
            "priority": "high",
            "logLevel": "info",
            "maxRetries": 3,
            "timeout": 30,
            "enabled": true,
            "tags": ["production", "critical"],
            "lastConfigUpdate": Date().addingTimeInterval(-3600).timeIntervalSince1970
        ]
    }
    
    func updateAgentConfiguration(_ id: UUID, configuration: [String: Any]) async throws -> AgentActionResult {
        print("[MockAPIClient] Mock updating agent configuration: \(id)")
        print("[MockAPIClient] Configuration keys: \(configuration.keys.joined(separator: ", "))")
        
        try await Task.sleep(nanoseconds: 400_000_000) // 0.4 seconds
        
        let success = Bool.random() ? true : (Int.random(in: 1...10) > 1) // 90% success rate
        let message = success ? "Agent configuration updated successfully" : "Failed to update configuration: Invalid values"
        
        return AgentActionResult(
            success: success,
            message: message,
            agentId: id,
            action: "configure",
            executionTime: 0.4
        )
    }
}