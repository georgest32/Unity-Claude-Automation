//
//  ModelSerialization.swift
//  AgentDashboard
//
//  Created on 2025-08-31
//  Model serialization/deserialization for API communication
//

import Foundation

// MARK: - API Response Models

struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let error: String?
    let timestamp: Date
}

struct PaginatedResponse<T: Codable>: Codable {
    let items: [T]
    let page: Int
    let pageSize: Int
    let totalPages: Int
    let totalItems: Int
}

// MARK: - API Request Models

struct CreateAgentRequest: Codable {
    let name: String
    let type: String
    let configuration: [String: String]
}

struct UpdateAgentRequest: Codable {
    let name: String?
    let configuration: [String: String]?
}

struct ExecuteCommandRequest: Codable {
    let command: String
    let parameters: [String: String]?
    let runAsJob: Bool
}

struct AuthenticationRequest: Codable {
    let username: String
    let password: String
    let deviceId: String
}

struct AuthenticationResponse: Codable {
    let token: String
    let refreshToken: String
    let expiresAt: Date
    let user: User
}

// MARK: - DTO Models (Data Transfer Objects)

struct AgentDTO: Codable {
    let id: String
    let name: String
    let status: String
    let type: String
    let startTime: String?
    let lastActivity: String?
    let metrics: [String: Double]?
    let errorMessage: String?
    
    func toAgent() -> Agent {
        let dateFormatter = ISO8601DateFormatter()
        
        return Agent(
            id: UUID(uuidString: id) ?? UUID(),
            name: name,
            type: AgentType(rawValue: type) ?? .orchestrator,
            status: AgentStatus(rawValue: status.lowercased()) ?? .idle,
            description: "",
            startTime: startTime.flatMap { dateFormatter.date(from: $0) },
            lastActivity: lastActivity.flatMap { dateFormatter.date(from: $0) },
            resourceUsage: metrics.map { ResourceUsage(
                cpu: $0["cpu"] ?? 0,
                memory: $0["memory"] ?? 0,
                threads: Int($0["threads"] ?? 0),
                handles: Int($0["handles"] ?? 0)
            )},
            configuration: [:]
        )
    }
}

struct ModuleDTO: Codable {
    let id: String
    let name: String
    let version: String
    let status: String
    let loadTime: String?
    let dependencies: [String]
    
    func toModule() -> Module {
        let dateFormatter = ISO8601DateFormatter()
        
        return Module(
            id: UUID(uuidString: id) ?? UUID(),
            name: name,
            version: version,
            isLoaded: status.lowercased() == "active",
            dependencies: dependencies,
            lastModified: loadTime.flatMap { dateFormatter.date(from: $0) } ?? Date()
        )
    }
}

struct SystemStatusDTO: Codable {
    let id: String
    let isOnline: Bool
    let uptime: String
    let lastHeartbeat: String
    let version: String
    let environment: String
    
    func toSystemStatus(with metrics: SystemMetricsDTO?) -> SystemStatus {
        return SystemStatus(
            timestamp: Date(),
            isHealthy: isOnline,
            cpuUsage: metrics?.cpuUsage ?? 0,
            memoryUsage: metrics?.memoryUsage ?? 0,
            diskUsage: metrics?.diskUsageBytes ?? 0,
            activeAgents: metrics?.processCount ?? 0,
            totalModules: 0,
            uptime: parseUptime(uptime)
        )
    }
    
    private func parseUptime(_ uptimeString: String) -> TimeInterval {
        // Parse uptime string like "2d 14h 32m" to TimeInterval
        var totalSeconds: TimeInterval = 0
        
        let components = uptimeString.components(separatedBy: " ")
        for component in components {
            if component.hasSuffix("d") {
                let days = Double(component.dropLast()) ?? 0
                totalSeconds += days * 86400
            } else if component.hasSuffix("h") {
                let hours = Double(component.dropLast()) ?? 0
                totalSeconds += hours * 3600
            } else if component.hasSuffix("m") {
                let minutes = Double(component.dropLast()) ?? 0
                totalSeconds += minutes * 60
            } else if component.hasSuffix("s") {
                let seconds = Double(component.dropLast()) ?? 0
                totalSeconds += seconds
            }
        }
        
        return totalSeconds
    }
}

struct SystemMetricsDTO: Codable {
    let cpuUsage: Double
    let memoryUsage: Double
    let processCount: Int
    let threadCount: Int
    let diskUsageBytes: Double
    let customMetrics: [String: Double]?
}

struct CommandResultDTO: Codable {
    let success: Bool
    let output: String?
    let errorMessage: String?
    let jobId: String?
    let executionTime: TimeInterval?
}

struct WebSocketMessageDTO: Codable {
    let id: String
    let type: String
    let action: String
    let payload: Data?
    let timestamp: String
    let correlationId: String?
    let source: String?
    let target: String?
    
    func toWebSocketMessage() -> WebSocketMessage {
        let dateFormatter = ISO8601DateFormatter()
        
        return WebSocketMessage(
            id: UUID(uuidString: id) ?? UUID(),
            type: WebSocketMessage.MessageType(rawValue: type) ?? .heartbeat,
            payload: payload ?? Data(),
            timestamp: dateFormatter.date(from: timestamp) ?? Date()
        )
    }
}

// MARK: - JSON Encoder/Decoder Extensions

extension JSONEncoder {
    static let apiEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()
}

extension JSONDecoder {
    static let apiDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

// MARK: - Serialization Helpers

struct ModelSerializer {
    static func serialize<T: Encodable>(_ model: T) throws -> Data {
        return try JSONEncoder.apiEncoder.encode(model)
    }
    
    static func deserialize<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        return try JSONDecoder.apiDecoder.decode(type, from: data)
    }
    
    static func serializeToString<T: Encodable>(_ model: T) throws -> String {
        let data = try serialize(model)
        guard let string = String(data: data, encoding: .utf8) else {
            throw SerializationError.encodingFailed
        }
        return string
    }
    
    static func deserializeFromString<T: Decodable>(_ type: T.Type, from string: String) throws -> T {
        guard let data = string.data(using: .utf8) else {
            throw SerializationError.decodingFailed
        }
        return try deserialize(type, from: data)
    }
}

enum SerializationError: LocalizedError {
    case encodingFailed
    case decodingFailed
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode model to JSON"
        case .decodingFailed:
            return "Failed to decode JSON to model"
        case .invalidData:
            return "Invalid data format"
        }
    }
}