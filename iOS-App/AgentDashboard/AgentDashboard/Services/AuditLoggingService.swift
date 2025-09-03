//
//  AuditLoggingService.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Comprehensive audit logging service for security and compliance
//

import Foundation
import SwiftUI
import ComposableArchitecture

// MARK: - Audit Logging Service Protocol

protocol AuditLoggingServiceProtocol {
    /// Log security event
    func logSecurityEvent(_ event: SecurityEvent)
    
    /// Log authentication event
    func logAuthenticationEvent(_ event: AuthenticationEvent)
    
    /// Log API access event
    func logAPIAccessEvent(_ event: APIAccessEvent)
    
    /// Log agent control event
    func logAgentControlEvent(_ event: AgentControlEvent)
    
    /// Log user action event
    func logUserActionEvent(_ event: UserActionEvent)
    
    /// Get audit logs with filtering
    func getAuditLogs(filter: AuditLogFilter?) async -> [AuditLogEntry]
    
    /// Export audit logs
    func exportAuditLogs(format: ExportFormat, dateRange: DateInterval?) async -> Data?
    
    /// Clear old audit logs
    func clearOldLogs(olderThan: Date) async -> Int
}

// MARK: - Audit Event Models

struct SecurityEvent {
    let type: SecurityEventType
    let description: String
    let severity: EventSeverity
    let context: [String: String]
    let timestamp: Date
    
    init(type: SecurityEventType, description: String, severity: EventSeverity = .medium, context: [String: String] = [:]) {
        self.type = type
        self.description = description
        self.severity = severity
        self.context = context
        self.timestamp = Date()
    }
}

enum SecurityEventType: String, CaseIterable {
    case certificateValidation = "certificate_validation"
    case certificatePinningFailure = "certificate_pinning_failure"
    case unauthorizedAccess = "unauthorized_access"
    case tokenExpiration = "token_expiration"
    case tokenRefresh = "token_refresh"
    case secureStorageAccess = "secure_storage_access"
    case biometricFailure = "biometric_failure"
    case suspiciousActivity = "suspicious_activity"
    
    var displayName: String {
        switch self {
        case .certificateValidation:
            return "Certificate Validation"
        case .certificatePinningFailure:
            return "Certificate Pinning Failure"
        case .unauthorizedAccess:
            return "Unauthorized Access"
        case .tokenExpiration:
            return "Token Expiration"
        case .tokenRefresh:
            return "Token Refresh"
        case .secureStorageAccess:
            return "Secure Storage Access"
        case .biometricFailure:
            return "Biometric Failure"
        case .suspiciousActivity:
            return "Suspicious Activity"
        }
    }
}

struct AuthenticationEvent {
    let type: AuthenticationType
    let result: AuthenticationResult
    let username: String?
    let method: String
    let duration: TimeInterval
    let context: [String: String]
    let timestamp: Date
    
    init(type: AuthenticationType, result: AuthenticationResult, username: String? = nil, method: String, duration: TimeInterval, context: [String: String] = [:]) {
        self.type = type
        self.result = result
        self.username = username
        self.method = method
        self.duration = duration
        self.context = context
        self.timestamp = Date()
    }
}

enum AuthenticationType: String, CaseIterable {
    case login = "login"
    case logout = "logout"
    case tokenRefresh = "token_refresh"
    case biometric = "biometric"
    case passcode = "passcode"
    case sessionExpiry = "session_expiry"
}

enum AuthenticationResult: String, CaseIterable {
    case success = "success"
    case failure = "failure"
    case cancelled = "cancelled"
    case timeout = "timeout"
    case lockout = "lockout"
}

struct APIAccessEvent {
    let endpoint: String
    let method: String
    let statusCode: Int?
    let responseTime: TimeInterval
    let userId: String?
    let userAgent: String?
    let context: [String: String]
    let timestamp: Date
    
    init(endpoint: String, method: String, statusCode: Int? = nil, responseTime: TimeInterval, userId: String? = nil, userAgent: String? = nil, context: [String: String] = [:]) {
        self.endpoint = endpoint
        self.method = method
        self.statusCode = statusCode
        self.responseTime = responseTime
        self.userId = userId
        self.userAgent = userAgent
        self.context = context
        self.timestamp = Date()
    }
}

struct AgentControlEvent {
    let agentId: String
    let agentName: String
    let operation: String
    let result: OperationResult
    let userId: String?
    let context: [String: String]
    let timestamp: Date
    
    init(agentId: String, agentName: String, operation: String, result: OperationResult, userId: String? = nil, context: [String: String] = [:]) {
        self.agentId = agentId
        self.agentName = agentName
        self.operation = operation
        self.result = result
        self.userId = userId
        self.context = context
        self.timestamp = Date()
    }
}

enum OperationResult: String, CaseIterable {
    case success = "success"
    case failure = "failure"
    case timeout = "timeout"
    case unauthorized = "unauthorized"
    case invalid = "invalid"
}

struct UserActionEvent {
    let action: String
    let screen: String
    let userId: String?
    let context: [String: String]
    let timestamp: Date
    
    init(action: String, screen: String, userId: String? = nil, context: [String: String] = [:]) {
        self.action = action
        self.screen = screen
        self.userId = userId
        self.context = context
        self.timestamp = Date()
    }
}

enum EventSeverity: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var color: Color {
        switch self {
        case .low:
            return .gray
        case .medium:
            return .blue
        case .high:
            return .orange
        case .critical:
            return .red
        }
    }
    
    var priority: Int {
        switch self {
        case .low:
            return 1
        case .medium:
            return 2
        case .high:
            return 3
        case .critical:
            return 4
        }
    }
}

// MARK: - Audit Log Models

struct AuditLogEntry: Identifiable, Codable {
    let id: UUID
    let eventType: String
    let category: String
    let description: String
    let severity: String
    let userId: String?
    let context: [String: String]
    let timestamp: Date
    let sessionId: String?
    
    init(eventType: String, category: String, description: String, severity: EventSeverity, userId: String? = nil, context: [String: String] = [:], sessionId: String? = nil) {
        self.id = UUID()
        self.eventType = eventType
        self.category = category
        self.description = description
        self.severity = severity.rawValue
        self.userId = userId
        self.context = context
        self.timestamp = Date()
        self.sessionId = sessionId
    }
    
    var severityLevel: EventSeverity {
        EventSeverity(rawValue: severity) ?? .medium
    }
    
    var displayTimestamp: String {
        timestamp.formatted(date: .abbreviated, time: .shortened)
    }
}

struct AuditLogFilter {
    var eventTypes: Set<String>?
    var severities: Set<EventSeverity>?
    var userIds: Set<String>?
    var dateRange: DateInterval?
    var searchText: String?
    
    func matches(_ entry: AuditLogEntry) -> Bool {
        if let eventTypes = eventTypes, !eventTypes.contains(entry.eventType) {
            return false
        }
        
        if let severities = severities, !severities.contains(entry.severityLevel) {
            return false
        }
        
        if let userIds = userIds, let userId = entry.userId, !userIds.contains(userId) {
            return false
        }
        
        if let dateRange = dateRange, !dateRange.contains(entry.timestamp) {
            return false
        }
        
        if let searchText = searchText, !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            let matchesDescription = entry.description.lowercased().contains(searchLower)
            let matchesContext = entry.context.values.contains { $0.lowercased().contains(searchLower) }
            
            if !matchesDescription && !matchesContext {
                return false
            }
        }
        
        return true
    }
}

enum ExportFormat: String, CaseIterable {
    case json = "json"
    case csv = "csv"
    case txt = "txt"
    
    var fileExtension: String {
        return rawValue
    }
    
    var mimeType: String {
        switch self {
        case .json:
            return "application/json"
        case .csv:
            return "text/csv"
        case .txt:
            return "text/plain"
        }
    }
}

// MARK: - Production Audit Logging Service

final class AuditLoggingService: AuditLoggingServiceProtocol {
    private let logger = Logger(subsystem: "AgentDashboard", category: "AuditLogging")
    private let fileManager = FileManager.default
    private let auditLogDirectory: URL
    private let maxLogFileSize: Int = 10_000_000 // 10MB
    private let maxLogFiles: Int = 10
    private var currentSessionId: String = UUID().uuidString
    
    init() {
        // Create audit log directory in app's documents directory
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        auditLogDirectory = documentsPath.appendingPathComponent("AuditLogs", isDirectory: true)
        
        createAuditDirectoryIfNeeded()
        logger.info("AuditLoggingService initialized - Session: \(currentSessionId)")
        
        // Log service initialization
        logSecurityEvent(SecurityEvent(
            type: .secureStorageAccess,
            description: "Audit logging service initialized",
            severity: .low,
            context: ["session_id": currentSessionId]
        ))
    }
    
    private func createAuditDirectoryIfNeeded() {
        do {
            try fileManager.createDirectory(at: auditLogDirectory, withIntermediateDirectories: true)
            logger.debug("Audit log directory created/verified: \(auditLogDirectory.path)")
        } catch {
            logger.error("Failed to create audit log directory: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Event Logging Methods
    
    func logSecurityEvent(_ event: SecurityEvent) {
        let entry = AuditLogEntry(
            eventType: event.type.rawValue,
            category: "security",
            description: event.description,
            severity: event.severity,
            context: event.context,
            sessionId: currentSessionId
        )
        
        writeAuditEntry(entry)
        logger.info("Security event logged: \(event.type.displayName) - \(event.severity.rawValue)")
    }
    
    func logAuthenticationEvent(_ event: AuthenticationEvent) {
        let entry = AuditLogEntry(
            eventType: event.type.rawValue,
            category: "authentication",
            description: "Authentication \(event.type.rawValue): \(event.result.rawValue) via \(event.method)",
            severity: determineSeverity(for: event),
            userId: event.username,
            context: event.context.merging([
                "method": event.method,
                "duration": String(format: "%.3f", event.duration),
                "result": event.result.rawValue
            ]) { _, new in new },
            sessionId: currentSessionId
        )
        
        writeAuditEntry(entry)
        logger.info("Authentication event logged: \(event.type.rawValue) - \(event.result.rawValue)")
    }
    
    func logAPIAccessEvent(_ event: APIAccessEvent) {
        let entry = AuditLogEntry(
            eventType: "api_access",
            category: "api",
            description: "\(event.method) \(event.endpoint) - \(event.statusCode ?? 0)",
            severity: determineSeverity(for: event),
            userId: event.userId,
            context: event.context.merging([
                "endpoint": event.endpoint,
                "method": event.method,
                "status_code": String(event.statusCode ?? 0),
                "response_time": String(format: "%.3f", event.responseTime),
                "user_agent": event.userAgent ?? "unknown"
            ]) { _, new in new },
            sessionId: currentSessionId
        )
        
        writeAuditEntry(entry)
        logger.debug("API access logged: \(event.method) \(event.endpoint)")
    }
    
    func logAgentControlEvent(_ event: AgentControlEvent) {
        let entry = AuditLogEntry(
            eventType: "agent_control",
            category: "operations",
            description: "Agent \(event.agentName) (\(event.agentId)): \(event.operation) - \(event.result.rawValue)",
            severity: determineSeverity(for: event),
            userId: event.userId,
            context: event.context.merging([
                "agent_id": event.agentId,
                "agent_name": event.agentName,
                "operation": event.operation,
                "result": event.result.rawValue
            ]) { _, new in new },
            sessionId: currentSessionId
        )
        
        writeAuditEntry(entry)
        logger.info("Agent control logged: \(event.agentName) - \(event.operation)")
    }
    
    func logUserActionEvent(_ event: UserActionEvent) {
        let entry = AuditLogEntry(
            eventType: "user_action",
            category: "user_interface",
            description: "User action: \(event.action) on \(event.screen)",
            severity: .low,
            userId: event.userId,
            context: event.context.merging([
                "action": event.action,
                "screen": event.screen
            ]) { _, new in new },
            sessionId: currentSessionId
        )
        
        writeAuditEntry(entry)
        logger.debug("User action logged: \(event.action)")
    }
    
    // MARK: - Audit Log Retrieval
    
    func getAuditLogs(filter: AuditLogFilter? = nil) async -> [AuditLogEntry] {
        logger.debug("Retrieving audit logs with filter")
        
        do {
            let logFiles = try fileManager.contentsOfDirectory(at: auditLogDirectory, includingPropertiesForKeys: [.creationDateKey])
                .filter { $0.pathExtension == "json" }
                .sorted { url1, url2 in
                    let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                    let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                    return date1 > date2
                }
            
            var allEntries: [AuditLogEntry] = []
            
            for logFile in logFiles {
                do {
                    let data = try Data(contentsOf: logFile)
                    let entries = try JSONDecoder().decode([AuditLogEntry].self, from: data)
                    allEntries.append(contentsOf: entries)
                } catch {
                    logger.error("Failed to read audit log file \(logFile.lastPathComponent): \(error.localizedDescription)")
                }
            }
            
            // Apply filter if provided
            if let filter = filter {
                allEntries = allEntries.filter { filter.matches($0) }
            }
            
            // Sort by timestamp (newest first)
            allEntries.sort { $0.timestamp > $1.timestamp }
            
            logger.info("Retrieved \(allEntries.count) audit log entries")
            return allEntries
            
        } catch {
            logger.error("Failed to retrieve audit logs: \(error.localizedDescription)")
            return []
        }
    }
    
    func exportAuditLogs(format: ExportFormat, dateRange: DateInterval? = nil) async -> Data? {
        logger.info("Exporting audit logs in \(format.rawValue) format")
        
        let filter = AuditLogFilter(dateRange: dateRange)
        let logs = await getAuditLogs(filter: filter)
        
        switch format {
        case .json:
            return exportAsJSON(logs)
        case .csv:
            return exportAsCSV(logs)
        case .txt:
            return exportAsText(logs)
        }
    }
    
    func clearOldLogs(olderThan: Date) async -> Int {
        logger.info("Clearing audit logs older than: \(olderThan)")
        
        do {
            let logFiles = try fileManager.contentsOfDirectory(at: auditLogDirectory, includingPropertiesForKeys: [.creationDateKey])
                .filter { $0.pathExtension == "json" }
            
            var deletedCount = 0
            
            for logFile in logFiles {
                if let creationDate = (try? logFile.resourceValues(forKeys: [.creationDateKey]))?.creationDate,
                   creationDate < olderThan {
                    do {
                        try fileManager.removeItem(at: logFile)
                        deletedCount += 1
                        logger.debug("Deleted old audit log: \(logFile.lastPathComponent)")
                    } catch {
                        logger.error("Failed to delete audit log \(logFile.lastPathComponent): \(error.localizedDescription)")
                    }
                }
            }
            
            logger.info("Cleared \(deletedCount) old audit log files")
            return deletedCount
            
        } catch {
            logger.error("Failed to clear old audit logs: \(error.localizedDescription)")
            return 0
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func writeAuditEntry(_ entry: AuditLogEntry) {
        Task {
            do {
                let fileName = "audit-\(dateFormatter.string(from: entry.timestamp)).json"
                let fileURL = auditLogDirectory.appendingPathComponent(fileName)
                
                var entries: [AuditLogEntry] = []
                
                // Load existing entries for the day
                if fileManager.fileExists(atPath: fileURL.path) {
                    let existingData = try Data(contentsOf: fileURL)
                    entries = try JSONDecoder().decode([AuditLogEntry].self, from: existingData)
                }
                
                // Add new entry
                entries.append(entry)
                
                // Write back to file
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                encoder.outputFormatting = .prettyPrinted
                
                let data = try encoder.encode(entries)
                try data.write(to: fileURL)
                
                logger.debug("Audit entry written to file: \(fileName)")
                
                // Check file size and rotate if necessary
                await rotateLogsIfNeeded()
                
            } catch {
                logger.error("Failed to write audit entry: \(error.localizedDescription)")
            }
        }
    }
    
    private func rotateLogsIfNeeded() async {
        do {
            let logFiles = try fileManager.contentsOfDirectory(at: auditLogDirectory, includingPropertiesForKeys: [.fileSizeKey, .creationDateKey])
                .filter { $0.pathExtension == "json" }
                .sorted { url1, url2 in
                    let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                    let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                    return date1 > date2
                }
            
            // Remove excess files (keep only maxLogFiles)
            if logFiles.count > maxLogFiles {
                let filesToRemove = logFiles.dropFirst(maxLogFiles)
                for file in filesToRemove {
                    try fileManager.removeItem(at: file)
                    logger.debug("Rotated old audit log: \(file.lastPathComponent)")
                }
            }
            
        } catch {
            logger.error("Failed to rotate audit logs: \(error.localizedDescription)")
        }
    }
    
    private func determineSeverity(for event: AuthenticationEvent) -> EventSeverity {
        switch event.result {
        case .success:
            return .low
        case .failure:
            return .medium
        case .cancelled:
            return .low
        case .timeout:
            return .medium
        case .lockout:
            return .high
        }
    }
    
    private func determineSeverity(for event: APIAccessEvent) -> EventSeverity {
        guard let statusCode = event.statusCode else { return .medium }
        
        switch statusCode {
        case 200...299:
            return .low
        case 400...499:
            return .medium
        case 500...599:
            return .high
        default:
            return .medium
        }
    }
    
    private func determineSeverity(for event: AgentControlEvent) -> EventSeverity {
        switch event.result {
        case .success:
            return .low
        case .failure:
            return .medium
        case .timeout:
            return .medium
        case .unauthorized:
            return .high
        case .invalid:
            return .medium
        }
    }
    
    // MARK: - Export Helper Methods
    
    private func exportAsJSON(_ logs: [AuditLogEntry]) -> Data? {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            return try encoder.encode(logs)
        } catch {
            logger.error("Failed to export logs as JSON: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func exportAsCSV(_ logs: [AuditLogEntry]) -> Data? {
        var csvString = "ID,Event Type,Category,Description,Severity,User ID,Timestamp,Session ID\n"
        
        for log in logs {
            let row = [
                log.id.uuidString,
                log.eventType,
                log.category,
                "\"" + log.description.replacingOccurrences(of: "\"", with: "\"\"") + "\"",
                log.severity,
                log.userId ?? "",
                log.timestamp.ISO8601Format(),
                log.sessionId ?? ""
            ].joined(separator: ",")
            
            csvString += row + "\n"
        }
        
        return csvString.data(using: .utf8)
    }
    
    private func exportAsText(_ logs: [AuditLogEntry]) -> Data? {
        var textString = "Unity-Claude Agent Dashboard - Audit Log Export\n"
        textString += "Generated: \(Date().formatted())\n"
        textString += "Total Entries: \(logs.count)\n\n"
        
        for log in logs {
            textString += "[\(log.displayTimestamp)] [\(log.severity.uppercased())] [\(log.category.uppercased())]\n"
            textString += "Event: \(log.eventType)\n"
            textString += "Description: \(log.description)\n"
            if let userId = log.userId {
                textString += "User: \(userId)\n"
            }
            if !log.context.isEmpty {
                textString += "Context: \(log.context)\n"
            }
            textString += "\n"
        }
        
        return textString.data(using: .utf8)
    }
    
    private var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

// MARK: - Mock Audit Logging Service

final class MockAuditLoggingService: AuditLoggingServiceProtocol {
    private var logs: [AuditLogEntry] = []
    private let logger = Logger(subsystem: "AgentDashboard", category: "MockAuditLogging")
    
    init() {
        logger.info("MockAuditLoggingService initialized")
        generateMockLogs()
    }
    
    private func generateMockLogs() {
        // Generate some mock audit logs for testing
        logs = [
            AuditLogEntry(
                eventType: "authentication",
                category: "security",
                description: "User login successful via Face ID",
                severity: .low,
                userId: "admin",
                context: ["method": "face_id", "duration": "0.8"]
            ),
            AuditLogEntry(
                eventType: "agent_control",
                category: "operations",
                description: "Agent restart operation completed",
                severity: .medium,
                userId: "admin",
                context: ["agent_name": "CLI Orchestrator", "operation": "restart"]
            )
        ]
    }
    
    func logSecurityEvent(_ event: SecurityEvent) {
        logger.debug("Mock logging security event: \(event.type.displayName)")
        let entry = AuditLogEntry(
            eventType: event.type.rawValue,
            category: "security",
            description: event.description,
            severity: event.severity,
            context: event.context
        )
        logs.append(entry)
    }
    
    func logAuthenticationEvent(_ event: AuthenticationEvent) {
        logger.debug("Mock logging authentication event: \(event.type.rawValue)")
        let entry = AuditLogEntry(
            eventType: event.type.rawValue,
            category: "authentication",
            description: "\(event.type.rawValue): \(event.result.rawValue)",
            severity: .low,
            userId: event.username,
            context: event.context
        )
        logs.append(entry)
    }
    
    func logAPIAccessEvent(_ event: APIAccessEvent) {
        logger.debug("Mock logging API access: \(event.endpoint)")
        let entry = AuditLogEntry(
            eventType: "api_access",
            category: "api",
            description: "\(event.method) \(event.endpoint)",
            severity: .low,
            userId: event.userId,
            context: event.context
        )
        logs.append(entry)
    }
    
    func logAgentControlEvent(_ event: AgentControlEvent) {
        logger.debug("Mock logging agent control: \(event.operation)")
        let entry = AuditLogEntry(
            eventType: "agent_control",
            category: "operations",
            description: "\(event.operation) on \(event.agentName)",
            severity: .low,
            userId: event.userId,
            context: event.context
        )
        logs.append(entry)
    }
    
    func logUserActionEvent(_ event: UserActionEvent) {
        logger.debug("Mock logging user action: \(event.action)")
        let entry = AuditLogEntry(
            eventType: "user_action",
            category: "user_interface",
            description: event.action,
            severity: .low,
            userId: event.userId,
            context: event.context
        )
        logs.append(entry)
    }
    
    func getAuditLogs(filter: AuditLogFilter? = nil) async -> [AuditLogEntry] {
        logger.debug("Mock retrieving audit logs")
        
        if let filter = filter {
            return logs.filter { filter.matches($0) }
        }
        
        return logs.sorted { $0.timestamp > $1.timestamp }
    }
    
    func exportAuditLogs(format: ExportFormat, dateRange: DateInterval? = nil) async -> Data? {
        logger.debug("Mock exporting audit logs as \(format.rawValue)")
        
        let filter = AuditLogFilter(dateRange: dateRange)
        let filteredLogs = await getAuditLogs(filter: filter)
        
        switch format {
        case .json:
            return try? JSONEncoder().encode(filteredLogs)
        case .csv:
            return "Mock CSV Export".data(using: .utf8)
        case .txt:
            return "Mock Text Export".data(using: .utf8)
        }
    }
    
    func clearOldLogs(olderThan: Date) async -> Int {
        logger.debug("Mock clearing old logs")
        let initialCount = logs.count
        logs.removeAll { $0.timestamp < olderThan }
        return initialCount - logs.count
    }
}

// MARK: - Dependency Registration

private enum AuditLoggingKey: DependencyKey {
    static let liveValue: AuditLoggingServiceProtocol = AuditLoggingService()
    static let testValue: AuditLoggingServiceProtocol = MockAuditLoggingService()
    static let previewValue: AuditLoggingServiceProtocol = MockAuditLoggingService()
}

extension DependencyValues {
    var auditLogging: AuditLoggingServiceProtocol {
        get { self[AuditLoggingKey.self] }
        set { self[AuditLoggingKey.self] = newValue }
    }
}