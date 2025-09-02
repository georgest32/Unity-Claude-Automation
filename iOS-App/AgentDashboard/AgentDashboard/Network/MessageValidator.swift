//
//  MessageValidator.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Message validation and schema enforcement for real-time data streaming
//

import Foundation

// MARK: - Message Validation Protocol

protocol MessageValidatorProtocol {
    func validate(_ message: WebSocketMessage) -> ValidationResult
    func validatePayload<T: Codable>(_ type: T.Type, data: Data) -> PayloadValidationResult<T>
}

// MARK: - Validation Results

enum ValidationResult {
    case valid
    case invalid(ValidationError)
    
    var isValid: Bool {
        switch self {
        case .valid: return true
        case .invalid: return false
        }
    }
    
    var error: ValidationError? {
        switch self {
        case .valid: return nil
        case .invalid(let error): return error
        }
    }
}

enum PayloadValidationResult<T> {
    case valid(T)
    case invalid(ValidationError)
    
    var isValid: Bool {
        switch self {
        case .valid: return true
        case .invalid: return false
        }
    }
    
    var value: T? {
        switch self {
        case .valid(let value): return value
        case .invalid: return nil
        }
    }
    
    var error: ValidationError? {
        switch self {
        case .valid: return nil
        case .invalid(let error): return error
        }
    }
}

// MARK: - Validation Errors

enum ValidationError: Error, LocalizedError {
    case invalidMessageType
    case invalidMessageId
    case payloadTooLarge(Int, maxSize: Int)
    case payloadEmpty
    case invalidTimestamp
    case schemaValidationFailed(String)
    case serializationFailed(Error)
    case missingRequiredFields([String])
    case invalidFieldValues([String: String])
    
    var errorDescription: String? {
        switch self {
        case .invalidMessageType:
            return "Invalid message type"
        case .invalidMessageId:
            return "Invalid message ID format"
        case .payloadTooLarge(let size, let maxSize):
            return "Payload too large: \(size) bytes (max: \(maxSize))"
        case .payloadEmpty:
            return "Payload is empty"
        case .invalidTimestamp:
            return "Invalid timestamp format"
        case .schemaValidationFailed(let reason):
            return "Schema validation failed: \(reason)"
        case .serializationFailed(let error):
            return "Serialization failed: \(error.localizedDescription)"
        case .missingRequiredFields(let fields):
            return "Missing required fields: \(fields.joined(separator: ", "))"
        case .invalidFieldValues(let fields):
            return "Invalid field values: \(fields.map { "\($0.key): \($0.value)" }.joined(separator: ", "))"
        }
    }
}

// MARK: - Message Validator Implementation

final class MessageValidator: MessageValidatorProtocol {
    
    // Configuration
    private let maxPayloadSize: Int
    private let requireValidTimestamp: Bool
    private let enableSchemaValidation: Bool
    
    // Metrics
    private var validationMetrics = ValidationMetrics()
    
    init(maxPayloadSize: Int = 1024 * 1024, // 1MB default
         requireValidTimestamp: Bool = true,
         enableSchemaValidation: Bool = true) {
        self.maxPayloadSize = maxPayloadSize
        self.requireValidTimestamp = requireValidTimestamp
        self.enableSchemaValidation = enableSchemaValidation
        
        print("[MessageValidator] Initialized with max payload: \(maxPayloadSize) bytes")
    }
    
    func validate(_ message: WebSocketMessage) -> ValidationResult {
        let startTime = Date()
        defer {
            validationMetrics.recordValidation(duration: Date().timeIntervalSince(startTime))
        }
        
        print("[MessageValidator] Validating message ID: \(message.id), type: \(message.type.rawValue)")
        
        // Validate message ID
        if message.id.uuidString.isEmpty {
            let error = ValidationError.invalidMessageId
            print("[MessageValidator] Validation failed: \(error.localizedDescription ?? "Invalid message ID")")
            validationMetrics.recordFailure()
            return .invalid(error)
        }
        
        // Validate payload size
        if message.payload.count > maxPayloadSize {
            let error = ValidationError.payloadTooLarge(message.payload.count, maxSize: maxPayloadSize)
            print("[MessageValidator] Validation failed: \(error.localizedDescription ?? "Payload too large")")
            validationMetrics.recordFailure()
            return .invalid(error)
        }
        
        // Validate timestamp if required
        if requireValidTimestamp {
            let timeDifference = abs(message.timestamp.timeIntervalSinceNow)
            if timeDifference > 300 { // 5 minutes tolerance
                let error = ValidationError.invalidTimestamp
                print("[MessageValidator] Validation failed: \(error.localizedDescription ?? "Invalid timestamp")")
                validationMetrics.recordFailure()
                return .invalid(error)
            }
        }
        
        // Validate payload is not empty for data messages
        if message.type != .heartbeat && message.payload.isEmpty {
            let error = ValidationError.payloadEmpty
            print("[MessageValidator] Validation failed: \(error.localizedDescription ?? "Empty payload")")
            validationMetrics.recordFailure()
            return .invalid(error)
        }
        
        // Schema validation based on message type
        if enableSchemaValidation {
            let schemaResult = validateMessageSchema(message)
            if !schemaResult.isValid {
                validationMetrics.recordFailure()
                return schemaResult
            }
        }
        
        print("[MessageValidator] Message validation successful")
        validationMetrics.recordSuccess()
        return .valid
    }
    
    func validatePayload<T: Codable>(_ type: T.Type, data: Data) -> PayloadValidationResult<T> {
        let startTime = Date()
        defer {
            validationMetrics.recordPayloadValidation(duration: Date().timeIntervalSince(startTime))
        }
        
        print("[MessageValidator] Validating payload for type: \(String(describing: type))")
        
        // Check data size
        if data.count > maxPayloadSize {
            let error = ValidationError.payloadTooLarge(data.count, maxSize: maxPayloadSize)
            print("[MessageValidator] Payload validation failed: \(error.localizedDescription ?? "Payload too large")")
            return .invalid(error)
        }
        
        // Attempt deserialization
        do {
            let decoder = JSONDecoder.apiDecoder
            let object = try decoder.decode(type, from: data)
            
            // Additional validation based on type
            let typeValidationResult = validateObjectSchema(object)
            if !typeValidationResult.isValid {
                return .invalid(typeValidationResult.error!)
            }
            
            print("[MessageValidator] Payload validation successful")
            return .valid(object)
        } catch {
            let validationError = ValidationError.serializationFailed(error)
            print("[MessageValidator] Payload validation failed: \(validationError.localizedDescription ?? "Serialization failed")")
            return .invalid(validationError)
        }
    }
    
    // MARK: - Schema Validation
    
    private func validateMessageSchema(_ message: WebSocketMessage) -> ValidationResult {
        switch message.type {
        case .agentStatus:
            return validateAgentStatusPayload(message.payload)
        case .systemMetrics:
            return validateSystemMetricsPayload(message.payload)
        case .terminalOutput:
            return validateTerminalOutputPayload(message.payload)
        case .commandResult:
            return validateCommandResultPayload(message.payload)
        case .alert:
            return validateAlertPayload(message.payload)
        case .heartbeat:
            return .valid // Heartbeat can be empty
        }
    }
    
    private func validateAgentStatusPayload(_ data: Data) -> ValidationResult {
        let result = validatePayload(Agent.self, data: data)
        return result.isValid ? .valid : .invalid(result.error!)
    }
    
    private func validateSystemMetricsPayload(_ data: Data) -> ValidationResult {
        let result = validatePayload(SystemStatus.self, data: data)
        return result.isValid ? .valid : .invalid(result.error!)
    }
    
    private func validateTerminalOutputPayload(_ data: Data) -> ValidationResult {
        // Terminal output should be valid UTF-8 string
        guard String(data: data, encoding: .utf8) != nil else {
            return .invalid(.schemaValidationFailed("Terminal output must be valid UTF-8"))
        }
        return .valid
    }
    
    private func validateCommandResultPayload(_ data: Data) -> ValidationResult {
        let result = validatePayload(CommandResult.self, data: data)
        return result.isValid ? .valid : .invalid(result.error!)
    }
    
    private func validateAlertPayload(_ data: Data) -> ValidationResult {
        let result = validatePayload(Alert.self, data: data)
        return result.isValid ? .valid : .invalid(result.error!)
    }
    
    private func validateObjectSchema<T>(_ object: T) -> ValidationResult {
        // Type-specific validation rules
        if let agent = object as? Agent {
            return validateAgent(agent)
        } else if let systemStatus = object as? SystemStatus {
            return validateSystemStatus(systemStatus)
        } else if let alert = object as? Alert {
            return validateAlert(alert)
        }
        
        return .valid
    }
    
    private func validateAgent(_ agent: Agent) -> ValidationResult {
        var missingFields: [String] = []
        var invalidValues: [String: String] = [:]
        
        if agent.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missingFields.append("name")
        }
        
        if agent.resourceUsage?.cpu ?? 0 < 0 || agent.resourceUsage?.cpu ?? 0 > 100 {
            invalidValues["cpu"] = "must be between 0-100"
        }
        
        if agent.resourceUsage?.memory ?? 0 < 0 || agent.resourceUsage?.memory ?? 0 > 100 {
            invalidValues["memory"] = "must be between 0-100"
        }
        
        if !missingFields.isEmpty {
            return .invalid(.missingRequiredFields(missingFields))
        }
        
        if !invalidValues.isEmpty {
            return .invalid(.invalidFieldValues(invalidValues))
        }
        
        return .valid
    }
    
    private func validateSystemStatus(_ status: SystemStatus) -> ValidationResult {
        var invalidValues: [String: String] = [:]
        
        if status.cpuUsage < 0 || status.cpuUsage > 100 {
            invalidValues["cpuUsage"] = "must be between 0-100"
        }
        
        if status.memoryUsage < 0 || status.memoryUsage > 100 {
            invalidValues["memoryUsage"] = "must be between 0-100"
        }
        
        if status.activeAgents < 0 {
            invalidValues["activeAgents"] = "must be non-negative"
        }
        
        if !invalidValues.isEmpty {
            return .invalid(.invalidFieldValues(invalidValues))
        }
        
        return .valid
    }
    
    private func validateAlert(_ alert: Alert) -> ValidationResult {
        var missingFields: [String] = []
        
        if alert.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missingFields.append("title")
        }
        
        if alert.message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missingFields.append("message")
        }
        
        if !missingFields.isEmpty {
            return .invalid(.missingRequiredFields(missingFields))
        }
        
        return .valid
    }
    
    // MARK: - Metrics Access
    
    func getValidationMetrics() -> ValidationMetrics {
        return validationMetrics
    }
    
    func resetMetrics() {
        validationMetrics = ValidationMetrics()
        print("[MessageValidator] Metrics reset")
    }
}

// MARK: - Validation Metrics

struct ValidationMetrics {
    private(set) var totalValidations: Int = 0
    private(set) var successfulValidations: Int = 0
    private(set) var failedValidations: Int = 0
    private(set) var totalPayloadValidations: Int = 0
    private(set) var averageValidationTime: TimeInterval = 0
    private(set) var averagePayloadValidationTime: TimeInterval = 0
    
    private var totalValidationTime: TimeInterval = 0
    private var totalPayloadValidationTime: TimeInterval = 0
    
    var successRate: Double {
        return totalValidations > 0 ? Double(successfulValidations) / Double(totalValidations) : 0
    }
    
    mutating func recordValidation(duration: TimeInterval) {
        totalValidations += 1
        totalValidationTime += duration
        averageValidationTime = totalValidationTime / Double(totalValidations)
    }
    
    mutating func recordSuccess() {
        successfulValidations += 1
    }
    
    mutating func recordFailure() {
        failedValidations += 1
    }
    
    mutating func recordPayloadValidation(duration: TimeInterval) {
        totalPayloadValidations += 1
        totalPayloadValidationTime += duration
        averagePayloadValidationTime = totalPayloadValidationTime / Double(totalPayloadValidations)
    }
    
    func debugDescription() -> String {
        return """
        [ValidationMetrics]
        Total Validations: \(totalValidations)
        Successful: \(successfulValidations)
        Failed: \(failedValidations)
        Success Rate: \(String(format: "%.2f%%", successRate * 100))
        Avg Validation Time: \(String(format: "%.3fms", averageValidationTime * 1000))
        Payload Validations: \(totalPayloadValidations)
        Avg Payload Time: \(String(format: "%.3fms", averagePayloadValidationTime * 1000))
        """
    }
}