//
//  Models.swift
//  AgentDashboard
//
//  Created on 2025-08-31
//  Core data models for the application
//

import Foundation
import SwiftUI

// MARK: - Connection Models

enum ConnectionStatus: Equatable {
    case disconnected
    case connecting
    case connected
    case disconnecting
    case error(String)
    
    var color: Color {
        switch self {
        case .disconnected: return .gray
        case .connecting, .disconnecting: return .orange
        case .connected: return .green
        case .error: return .red
        }
    }
    
    var description: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting..."
        case .connected: return "Connected"
        case .disconnecting: return "Disconnecting..."
        case let .error(message): return "Error: \(message)"
        }
    }
}

// MARK: - User Models

struct User: Equatable, Codable, Identifiable {
    let id: UUID
    let username: String
    let email: String
    let role: UserRole
    let createdAt: Date
}

enum UserRole: String, Codable {
    case admin
    case systemOperator = "operator"
    case viewer
}

// MARK: - System Models

struct SystemStatus: Equatable, Codable {
    let timestamp: Date
    let isHealthy: Bool
    let cpuUsage: Double
    let memoryUsage: Double
    let diskUsage: Double
    let activeAgents: Int
    let totalModules: Int
    let uptime: TimeInterval
    
    // Debug logging
    var debugDescription: String {
        return """
        [SystemStatus] Timestamp: \(timestamp)
        [SystemStatus] Healthy: \(isHealthy)
        [SystemStatus] CPU: \(String(format: "%.1f%%", cpuUsage))
        [SystemStatus] Memory: \(String(format: "%.1f%%", memoryUsage))
        [SystemStatus] Disk: \(String(format: "%.1f%%", diskUsage))
        [SystemStatus] Active Agents: \(activeAgents)
        [SystemStatus] Total Modules: \(totalModules)
        """
    }
}

// MARK: - Agent Models
// Note: Agent struct is defined in Models/Agent.swift to avoid duplication

enum AgentType: String, Codable, CaseIterable {
    case orchestrator = "CLI Orchestrator"
    case monitor = "System Monitor"
    case analyzer = "Code Analyzer"
    case builder = "Build Agent"
    case tester = "Test Runner"
    case reporter = "Report Generator"
    
    var icon: String {
        switch self {
        case .orchestrator: return "cpu"
        case .monitor: return "eye"
        case .analyzer: return "magnifyingglass"
        case .builder: return "hammer"
        case .tester: return "checkmark.circle"
        case .reporter: return "doc.text"
        }
    }
}

enum AgentStatus: String, Codable {
    case idle
    case running
    case paused
    case stopped
    case error
    
    var color: Color {
        switch self {
        case .idle: return .gray
        case .running: return .green
        case .paused: return .orange
        case .stopped: return .red
        case .error: return .red
        }
    }
}

struct ResourceUsage: Equatable, Codable {
    let cpu: Double
    let memory: Double
    let threads: Int
    let handles: Int
}

// MARK: - Module Models
// Note: Module struct is defined in Models/SystemStatus.swift to avoid duplication

// MARK: - Command Models

struct Command: Equatable, Codable, Identifiable {
    let id: UUID
    let text: String
    let timestamp: Date
    let source: CommandSource
    let status: CommandStatus
    var output: String?
    var error: String?
    
    // Debug logging
    func logExecution() {
        print("[Command] ID: \(id)")
        print("[Command] Text: \(text)")
        print("[Command] Source: \(source.rawValue)")
        print("[Command] Status: \(status.rawValue)")
        if let output = output {
            print("[Command] Output: \(output.prefix(100))...")
        }
        if let error = error {
            print("[Command] Error: \(error)")
        }
    }
}

enum CommandSource: String, Codable {
    case user
    case system
    case agent
    case scheduled
}

enum CommandStatus: String, Codable {
    case pending
    case executing
    case completed
    case failed
    case cancelled
}

// MARK: - Analytics Models

struct MetricPoint: Equatable, Codable {
    let timestamp: Date
    let value: Double
    let label: String?
}

struct ChartData: Equatable, Identifiable {
    let id = UUID()
    let title: String
    let points: [MetricPoint]
    let type: ChartType
    
    enum ChartType: String, Codable {
        case line
        case bar
        case area
        case scatter
    }
}

// MARK: - WebSocket Models

struct WebSocketMessage: Equatable, Codable {
    let id: UUID
    let type: MessageType
    let payload: Data
    let timestamp: Date
    
    enum MessageType: String, Codable {
        case agentStatus
        case systemMetrics
        case terminalOutput
        case commandResult
        case alert
        case heartbeat
    }
    
    // Debug logging
    func logReceived() {
        print("[WebSocket] Message ID: \(id)")
        print("[WebSocket] Type: \(type.rawValue)")
        print("[WebSocket] Payload size: \(payload.count) bytes")
        print("[WebSocket] Timestamp: \(timestamp)")
    }
}

// MARK: - Alert Models

struct Alert: Equatable, Codable, Identifiable {
    let id: UUID
    let title: String
    let message: String
    let severity: Severity
    let timestamp: Date
    let source: String
    
    enum Severity: String, Codable {
        case info
        case warning
        case error
        case critical
        
        var color: Color {
            switch self {
            case .info: return .blue
            case .warning: return .orange
            case .error: return .red
            case .critical: return .purple
            }
        }
        
        var icon: String {
            switch self {
            case .info: return "info.circle"
            case .warning: return "exclamationmark.triangle"
            case .error: return "xmark.circle"
            case .critical: return "exclamationmark.octagon"
            }
        }
    }
    
    // Debug logging
    func logAlert() {
        print("[Alert] [\(severity.rawValue.uppercased())] \(title)")
        print("[Alert] Message: \(message)")
        print("[Alert] Source: \(source)")
        print("[Alert] Time: \(timestamp)")
    }
}

// MARK: - Command Queue Models

struct QueuedCommand: Equatable, Codable, Identifiable {
    let id: UUID
    let request: CommandRequest
    var priority: CommandPriority
    let enqueuedAt: Date
    var status: CommandExecutionStatus
    var progress: Double
    var startedAt: Date?
    var completedAt: Date?
    var result: CommandResult?
    var error: String?
    let estimatedDuration: TimeInterval
    var executionProgress: ExecutionProgress?
    var detailedProgress: DetailedExecutionProgress?
    
    var executionDuration: TimeInterval? {
        guard let startedAt = startedAt, let completedAt = completedAt else { return nil }
        return completedAt.timeIntervalSince(startedAt)
    }
    
    var isActive: Bool {
        status == .executing
    }
    
    var canBeCancelled: Bool {
        status == .queued || status == .executing
    }
}

struct CommandRequest: Equatable, Codable, Identifiable {
    let id: UUID
    let prompt: String
    let targetSystem: AISystem
    let mode: AIMode
    let enhancementOptions: PromptEnhancementOptions
    let estimatedDuration: TimeInterval?
    let createdAt: Date
    
    enum AISystem: String, Codable, CaseIterable {
        case claudeCode = "Claude Code CLI"
        case autoGen = "AutoGen"
        case langGraph = "LangGraph" 
        case custom = "Custom System"
    }
    
    enum AIMode: String, Codable, CaseIterable {
        case normal = "Normal"
        case headless = "Headless"
    }
}

struct PromptEnhancementOptions: Equatable, Codable {
    let includeSystemContext: Bool
    let includeErrorLogs: Bool
    let includeTimestamp: Bool
    let responseFormat: ResponseFormat
    
    enum ResponseFormat: String, Codable, CaseIterable {
        case markdown = "Markdown"
        case plainText = "Plain Text"
        case json = "JSON"
        case structured = "Structured"
    }
}

enum CommandPriority: Int, Codable, CaseIterable {
    case low = 0
    case normal = 1
    case high = 2
    case urgent = 3
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High"
        case .urgent: return "Urgent"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .gray
        case .normal: return .blue
        case .high: return .orange
        case .urgent: return .red
        }
    }
}

enum CommandExecutionStatus: String, Codable {
    case queued
    case executing
    case completed
    case failed
    case cancelled
    
    var color: Color {
        switch self {
        case .queued: return .gray
        case .executing: return .blue
        case .completed: return .green
        case .failed: return .red
        case .cancelled: return .orange
        }
    }
    
    var icon: String {
        switch self {
        case .queued: return "clock"
        case .executing: return "play.circle"
        case .completed: return "checkmark.circle"
        case .failed: return "xmark.circle"
        case .cancelled: return "stop.circle"
        }
    }
}

struct CommandResult: Equatable, Codable {
    let id: UUID
    let success: Bool
    let output: String?
    let error: String?
    let executionTime: TimeInterval
    let timestamp: Date
    
    var displayOutput: String {
        if success {
            return output ?? "Command completed successfully"
        } else {
            return error ?? "Unknown error occurred"
        }
    }
}

struct ExecutionProgress: Equatable, Codable {
    let currentStep: String
    let stepNumber: Int
    let totalSteps: Int
    let completionRatio: Double
    let estimatedTimeRemaining: TimeInterval?
    
    var progressDescription: String {
        "Step \(stepNumber)/\(totalSteps): \(currentStep)"
    }
}

struct SystemResourceUsage: Equatable, Codable {
    let cpuUsage: Double
    let memoryUsage: Double
    let availableMemory: Double
    let batteryLevel: Double?
    let thermalState: ThermalState
    let timestamp: Date
    
    enum ThermalState: String, Codable {
        case nominal
        case fair
        case serious
        case critical
    }
    
    static func current() -> SystemResourceUsage {
        SystemResourceUsage(
            cpuUsage: 0.3,
            memoryUsage: 0.6,
            availableMemory: 2048,
            batteryLevel: 0.8,
            thermalState: .nominal,
            timestamp: Date()
        )
    }
}

struct QueueStatistics: Equatable, Codable {
    var totalEnqueued: Int = 0
    var totalStarted: Int = 0
    var totalCompleted: Int = 0
    var totalFailed: Int = 0
    var totalCancelled: Int = 0
    var currentQueueDepth: Int = 0
    var currentExecutingCount: Int = 0
    var averageExecutionTime: TimeInterval = 0.0
    var lastUpdated: Date = Date()
    
    var completionRate: Double {
        let total = totalStarted
        guard total > 0 else { return 0.0 }
        return Double(totalCompleted) / Double(total)
    }
    
    var failureRate: Double {
        let total = totalStarted
        guard total > 0 else { return 0.0 }
        return Double(totalFailed) / Double(total)
    }
}

enum QueueHealth: String, CaseIterable {
    case idle
    case active
    case busy
    case overloaded
    
    var color: Color {
        switch self {
        case .idle: return .gray
        case .active: return .green
        case .busy: return .orange
        case .overloaded: return .red
        }
    }
    
    var description: String {
        switch self {
        case .idle: return "Queue is idle"
        case .active: return "Queue is processing commands"
        case .busy: return "Queue is busy"
        case .overloaded: return "Queue is overloaded"
        }
    }
}

// MARK: - Enhanced Cancellation Models (Hour 7)

struct ConfirmationDialogState: Equatable {
    let title: String
    let message: String
    let confirmButtonTitle: String
    let isDestructive: Bool
    let action: ConfirmationAction
    
    enum ConfirmationAction: Equatable {
        case cancelSelectedCommands
        case cancelAllQueued
        case cancelAllExecuting
    }
}

struct UndoableOperation: Equatable, Identifiable {
    let id = UUID()
    let type: OperationType
    let affectedCommands: Set<QueuedCommand.ID>
    let timestamp: Date
    
    enum OperationType: String {
        case cancelCommands = "Cancel Commands"
        case reprioritizeCommands = "Reprioritize Commands"
        case reorderQueue = "Reorder Queue"
    }
}

// MARK: - Enhanced Progress Models (Hour 8)

struct DetailedExecutionProgress: Equatable, Codable {
    let currentStep: String
    let stepNumber: Int
    let totalSteps: Int
    let completionRatio: Double
    let estimatedTimeRemaining: TimeInterval?
    let executionPhase: ExecutionPhase
    let stepStartTime: Date
    let subSteps: [ExecutionSubStep]
    
    enum ExecutionPhase: String, Codable, CaseIterable {
        case initialization = "Initialization"
        case validation = "Validation"
        case execution = "Execution"
        case postProcessing = "Post-Processing"
        case completion = "Completion"
        
        var color: Color {
            switch self {
            case .initialization: return .blue
            case .validation: return .orange
            case .execution: return .green
            case .postProcessing: return .purple
            case .completion: return .mint
            }
        }
        
        var icon: String {
            switch self {
            case .initialization: return "gear"
            case .validation: return "checkmark.shield"
            case .execution: return "play.circle"
            case .postProcessing: return "wand.and.rays"
            case .completion: return "checkmark.circle"
            }
        }
    }
    
    var progressDescription: String {
        "Step \(stepNumber)/\(totalSteps): \(currentStep)"
    }
    
    var etaDescription: String {
        guard let eta = estimatedTimeRemaining else { return "Calculating..." }
        if eta < 60 {
            return "\(Int(eta))s remaining"
        } else {
            let minutes = Int(eta / 60)
            return "\(minutes)m remaining"
        }
    }
}

struct ExecutionSubStep: Equatable, Codable, Identifiable {
    let id = UUID()
    let name: String
    let isCompleted: Bool
    let duration: TimeInterval?
    let startTime: Date?
    let endTime: Date?
}

struct QueueAnalytics: Equatable, Codable {
    let totalProcessed: Int
    let averageQueueTime: TimeInterval
    let averageExecutionTime: TimeInterval
    let peakQueueDepth: Int
    let successRate: Double
    let throughputPerHour: Double
    let resourceUtilization: ResourceUtilization
    let trendData: [TrendDataPoint]
    let lastUpdated: Date
    
    var efficiencyScore: Double {
        let timeScore = min(1.0, 300.0 / averageExecutionTime) // 5 minutes as ideal
        let successScore = successRate
        let utilizationScore = min(1.0, resourceUtilization.cpuEfficiency)
        return (timeScore + successScore + utilizationScore) / 3.0
    }
}

struct ResourceUtilization: Equatable, Codable {
    let cpuUsage: Double
    let memoryUsage: Double
    let networkUsage: Double
    let cpuEfficiency: Double // CPU usage vs queue depth ratio
    let memoryEfficiency: Double
    let timestamp: Date
    
    var overallHealth: Double {
        let cpuHealth = 1.0 - min(1.0, cpuUsage)
        let memoryHealth = 1.0 - min(1.0, memoryUsage)
        let networkHealth = 1.0 - min(1.0, networkUsage)
        return (cpuHealth + memoryHealth + networkHealth) / 3.0
    }
}

struct TrendDataPoint: Equatable, Codable, Identifiable {
    let id = UUID()
    let timestamp: Date
    let queueDepth: Int
    let executingCount: Int
    let completionRate: Double
    let averageWaitTime: TimeInterval
    let resourceUsage: Double
}

struct ExecutionMetrics: Equatable, Codable {
    let commandID: QueuedCommand.ID
    let startTime: Date
    let endTime: Date?
    let totalDuration: TimeInterval?
    let phaseTimings: [DetailedExecutionProgress.ExecutionPhase: TimeInterval]
    let resourcePeak: ResourceUtilization
    let stepCount: Int
    let stepDurations: [TimeInterval]
    let errorCount: Int
    let retryCount: Int
    
    var efficiency: Double {
        guard let totalDuration = totalDuration, totalDuration > 0 else { return 0.0 }
        let idealTime = TimeInterval(stepCount) * 2.0 // 2 seconds per step ideal
        return min(1.0, idealTime / totalDuration)
    }
}

// MARK: - Response Models (Hour 9)

@Model
class Response {
    @Attribute(.unique) var id: UUID
    var content: String
    var formattedContent: String?
    var sourceCommandID: UUID
    var aiSystem: String
    var aiMode: String
    var createdAt: Date
    var receivedAt: Date
    var lastViewedAt: Date?
    var isFavorite: Bool
    var tags: [String]
    var category: String
    var responseType: String
    var wordCount: Int
    var readingTimeMinutes: Double
    var qualityScore: Double?
    var isArchived: Bool
    
    // Relationships
    var sourceCommand: CommandRequest?
    var responseMetadata: ResponseMetadata?
    
    init(content: String, sourceCommandID: UUID, aiSystem: String, aiMode: String = "normal") {
        self.id = UUID()
        self.content = content
        self.sourceCommandID = sourceCommandID
        self.aiSystem = aiSystem
        self.aiMode = aiMode
        self.createdAt = Date()
        self.receivedAt = Date()
        self.isFavorite = false
        self.tags = []
        self.category = "General"
        self.responseType = detectResponseType(content)
        self.wordCount = content.split(separator: " ").count
        self.readingTimeMinutes = Double(wordCount) / 200.0 // 200 WPM average
        self.isArchived = false
    }
    
    var displayTitle: String {
        let preview = content.prefix(50)
        return preview + (content.count > 50 ? "..." : "")
    }
    
    var formattedCreatedAt: String {
        createdAt.formatted(date: .abbreviated, time: .shortened)
    }
}

@Model 
class ResponseMetadata {
    @Attribute(.unique) var id: UUID
    var responseID: UUID
    var executionTime: TimeInterval
    var promptLength: Int
    var responseLength: Int
    var hasCodeBlocks: Bool
    var hasLinks: Bool
    var hasImages: Bool
    var complexity: ResponseComplexity
    var sentiment: ResponseSentiment
    var topics: [String]
    var keyPhrases: [String]
    var relatedResponseIDs: [UUID]
    
    init(responseID: UUID, executionTime: TimeInterval, promptLength: Int, content: String) {
        self.id = UUID()
        self.responseID = responseID
        self.executionTime = executionTime
        self.promptLength = promptLength
        self.responseLength = content.count
        self.hasCodeBlocks = content.contains("```")
        self.hasLinks = content.contains("http")
        self.hasImages = content.contains("![")
        self.complexity = analyzeComplexity(content)
        self.sentiment = analyzeSentiment(content)
        self.topics = extractTopics(content)
        self.keyPhrases = extractKeyPhrases(content)
        self.relatedResponseIDs = []
    }
}

enum ResponseComplexity: String, Codable, CaseIterable {
    case simple = "Simple"
    case moderate = "Moderate"  
    case complex = "Complex"
    case expert = "Expert"
    
    var color: Color {
        switch self {
        case .simple: return .green
        case .moderate: return .blue
        case .complex: return .orange
        case .expert: return .red
        }
    }
}

enum ResponseSentiment: String, Codable, CaseIterable {
    case positive = "Positive"
    case neutral = "Neutral"
    case negative = "Negative"
    case mixed = "Mixed"
    
    var color: Color {
        switch self {
        case .positive: return .green
        case .neutral: return .gray
        case .negative: return .red
        case .mixed: return .orange
        }
    }
}

struct ResponseSearchQuery: Equatable, Codable {
    var searchText: String = ""
    var aiSystemFilter: String? = nil
    var categoryFilter: String? = nil
    var dateRange: DateRange? = nil
    var complexityFilter: ResponseComplexity? = nil
    var tagsFilter: [String] = []
    var isFavoriteOnly: Bool = false
    var includeArchived: Bool = false
    
    struct DateRange: Equatable, Codable {
        let startDate: Date
        let endDate: Date
    }
}

// MARK: - Helper Functions

private func detectResponseType(_ content: String) -> String {
    if content.contains("```") {
        return "Code"
    } else if content.contains("# ") || content.contains("## ") {
        return "Documentation"
    } else if content.contains("Error") || content.contains("Exception") {
        return "Error Analysis"
    } else if content.count > 1000 {
        return "Detailed Analysis"
    } else {
        return "General"
    }
}

private func analyzeComplexity(_ content: String) -> ResponseComplexity {
    let wordCount = content.split(separator: " ").count
    let codeBlocks = content.components(separatedBy: "```").count - 1
    let technicalTerms = ["algorithm", "optimization", "performance", "architecture", "implementation"].filter { content.localizedCaseInsensitiveContains($0) }.count
    
    let complexityScore = wordCount / 100 + codeBlocks * 2 + technicalTerms
    
    switch complexityScore {
    case 0...5: return .simple
    case 6...15: return .moderate
    case 16...30: return .complex
    default: return .expert
    }
}

private func analyzeSentiment(_ content: String) -> ResponseSentiment {
    let positiveWords = ["success", "excellent", "good", "working", "complete", "solved"]
    let negativeWords = ["error", "failed", "broken", "issue", "problem", "warning"]
    
    let positiveCount = positiveWords.filter { content.localizedCaseInsensitiveContains($0) }.count
    let negativeCount = negativeWords.filter { content.localizedCaseInsensitiveContains($0) }.count
    
    if positiveCount > negativeCount + 1 {
        return .positive
    } else if negativeCount > positiveCount + 1 {
        return .negative
    } else if positiveCount > 0 && negativeCount > 0 {
        return .mixed
    } else {
        return .neutral
    }
}

private func extractTopics(_ content: String) -> [String] {
    let topics = ["iOS", "Swift", "SwiftUI", "TCA", "API", "Database", "UI", "Performance", "Security", "Testing"]
    return topics.filter { content.localizedCaseInsensitiveContains($0) }
}

private func extractKeyPhrases(_ content: String) -> [String] {
    // Simple key phrase extraction - in production would use NLP
    let sentences = content.components(separatedBy: ". ")
    return sentences.prefix(3).map { sentence in
        String(sentence.prefix(50))
    }
}

// MARK: - Enhanced Template Models (Hour 9.3)

@Model
class EnhancedPromptTemplate {
    @Attribute(.unique) var id: UUID
    var name: String
    var content: String
    var category: String
    var subcategory: String?
    var description: String
    var variables: [TemplateVariable]
    var tags: [String]
    var aiSystemCompatibility: [String]
    var createdAt: Date
    var lastModified: Date
    var lastUsed: Date?
    var usageCount: Int
    var isBuiltIn: Bool
    var isFavorite: Bool
    var version: String
    var author: String?
    
    init(name: String, content: String, category: String, description: String) {
        self.id = UUID()
        self.name = name
        self.content = content
        self.category = category
        self.description = description
        self.variables = extractVariables(from: content)
        self.tags = []
        self.aiSystemCompatibility = ["Claude Code CLI", "AutoGen", "LangGraph", "Custom System"]
        self.createdAt = Date()
        self.lastModified = Date()
        self.usageCount = 0
        self.isBuiltIn = false
        self.isFavorite = false
        self.version = "1.0"
    }
    
    var displayName: String {
        name.isEmpty ? "Untitled Template" : name
    }
    
    var previewContent: String {
        let preview = content.prefix(100)
        return preview + (content.count > 100 ? "..." : "")
    }
    
    var variableCount: Int {
        variables.count
    }
    
    func processedContent(with values: [String: String]) -> String {
        var processed = content
        
        // Replace built-in variables
        processed = processed.replacingOccurrences(of: "{{timestamp}}", with: Date().formatted())
        processed = processed.replacingOccurrences(of: "{{date}}", with: Date().formatted(date: .abbreviated, time: .omitted))
        processed = processed.replacingOccurrences(of: "{{time}}", with: Date().formatted(date: .omitted, time: .shortened))
        
        // Replace custom variables
        for variable in variables {
            if let value = values[variable.name] {
                processed = processed.replacingOccurrences(of: "{{\(variable.name)}}", with: value)
            } else if let defaultValue = variable.defaultValue {
                processed = processed.replacingOccurrences(of: "{{\(variable.name)}}", with: defaultValue)
            }
        }
        
        return processed
    }
}

@Model
class TemplateVariable {
    @Attribute(.unique) var id: UUID
    var name: String
    var type: VariableType
    var description: String
    var defaultValue: String?
    var isRequired: Bool
    var validation: String? // Regex for validation
    var placeholder: String
    var options: [String]? // For dropdown variables
    
    init(name: String, type: VariableType, description: String, isRequired: Bool = false) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.description = description
        self.isRequired = isRequired
        self.placeholder = "Enter \(name.lowercased())"
    }
    
    enum VariableType: String, Codable, CaseIterable {
        case text = "Text"
        case number = "Number"
        case date = "Date"
        case dropdown = "Dropdown"
        case boolean = "Boolean"
        case multiline = "Multiline Text"
        
        var icon: String {
            switch self {
            case .text: return "textformat"
            case .number: return "number"
            case .date: return "calendar"
            case .dropdown: return "list.bullet"
            case .boolean: return "checkmark.square"
            case .multiline: return "text.alignleft"
            }
        }
        
        var color: Color {
            switch self {
            case .text: return .blue
            case .number: return .green
            case .date: return .orange
            case .dropdown: return .purple
            case .boolean: return .red
            case .multiline: return .cyan
            }
        }
    }
}

@Model
class TemplateCategory {
    @Attribute(.unique) var id: UUID
    var name: String
    var description: String
    var icon: String
    var color: String
    var parentCategoryID: UUID?
    var sortOrder: Int
    var isBuiltIn: Bool
    var templateCount: Int
    
    init(name: String, description: String, icon: String = "folder", color: String = "blue") {
        self.id = UUID()
        self.name = name
        self.description = description
        self.icon = icon
        self.color = color
        self.sortOrder = 0
        self.isBuiltIn = false
        self.templateCount = 0
    }
    
    var displayColor: Color {
        switch color {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "purple": return .purple
        default: return .gray
        }
    }
}

struct TemplateSearchQuery: Equatable {
    var searchText: String = ""
    var categoryFilter: String? = nil
    var tagsFilter: [String] = []
    var aiSystemFilter: String? = nil
    var showFavoritesOnly: Bool = false
    var showBuiltInOnly: Bool = false
    var sortBy: SortOption = .lastModified
    
    enum SortOption: String, CaseIterable {
        case name = "Name"
        case lastModified = "Last Modified"
        case lastUsed = "Last Used"
        case usageCount = "Usage Count"
        case category = "Category"
    }
}

// MARK: - Template Helper Functions

private func extractVariables(from content: String) -> [TemplateVariable] {
    let pattern = "\\{\\{([^}]+)\\}\\}"
    let regex = try! NSRegularExpression(pattern: pattern, options: [])
    let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: content.count))
    
    var variables: [TemplateVariable] = []
    let builtInVariables = ["timestamp", "date", "time", "user", "system"]
    
    for match in matches {
        if let range = Range(match.range(at: 1), in: content) {
            let variableName = String(content[range])
            
            // Skip built-in variables
            if builtInVariables.contains(variableName.lowercased()) {
                continue
            }
            
            // Avoid duplicates
            if !variables.contains(where: { $0.name == variableName }) {
                let variable = TemplateVariable(
                    name: variableName,
                    type: inferVariableType(variableName),
                    description: "Variable: \(variableName)"
                )
                variables.append(variable)
            }
        }
    }
    
    return variables
}

private func inferVariableType(_ name: String) -> TemplateVariable.VariableType {
    let lowercased = name.lowercased()
    
    if lowercased.contains("count") || lowercased.contains("number") || lowercased.contains("amount") {
        return .number
    } else if lowercased.contains("date") || lowercased.contains("time") {
        return .date
    } else if lowercased.contains("description") || lowercased.contains("content") {
        return .multiline
    } else if lowercased.contains("enable") || lowercased.contains("include") || lowercased.contains("show") {
        return .boolean
    } else {
        return .text
    }
}

private func generateDefaultTemplateCategories() -> [TemplateCategory] {
    return [
        TemplateCategory(name: "System Analysis", description: "Templates for system monitoring and analysis", icon: "cpu", color: "blue"),
        TemplateCategory(name: "Debugging", description: "Error investigation and troubleshooting templates", icon: "bug", color: "red"),
        TemplateCategory(name: "Performance", description: "Performance optimization and monitoring templates", icon: "speedometer", color: "green"),
        TemplateCategory(name: "Code Review", description: "Code analysis and review templates", icon: "doc.text.magnifyingglass", color: "purple"),
        TemplateCategory(name: "Documentation", description: "Documentation generation and maintenance templates", icon: "doc.richtext", color: "orange"),
        TemplateCategory(name: "Testing", description: "Testing and validation templates", icon: "checkmark.shield", color: "mint")
    ]
}

private func generateAdvancedDefaultTemplates() -> [EnhancedPromptTemplate] {
    let systemAnalysis = EnhancedPromptTemplate(
        name: "System Performance Analysis",
        content: """
        Please analyze the current system performance focusing on {{focus_area}}.
        
        **Analysis Parameters:**
        - Time window: {{time_window}}
        - Include metrics: {{include_metrics}}
        - Priority level: {{priority}}
        
        **Context:**
        - Current date: {{date}}
        - System load: {{system_load}}
        
        Please provide:
        1. Current status assessment
        2. Performance trends
        3. Optimization recommendations
        4. Risk analysis
        
        **Output format:** {{output_format}}
        """,
        category: "System Analysis",
        description: "Comprehensive system performance analysis with customizable parameters"
    )
    
    let errorInvestigation = EnhancedPromptTemplate(
        name: "Error Investigation Template",
        content: """
        Investigate the following error and provide solution recommendations:
        
        **Error Details:**
        - Error type: {{error_type}}
        - Error message: {{error_message}}
        - Occurrence time: {{timestamp}}
        - Affected component: {{component}}
        
        **System Context:**
        - Environment: {{environment}}
        - Version: {{version}}
        - Related processes: {{related_processes}}
        
        Please analyze:
        1. Root cause analysis
        2. Impact assessment
        3. Immediate fixes
        4. Long-term prevention
        
        **Urgency level:** {{urgency}}
        """,
        category: "Debugging",
        description: "Structured error investigation with context and solution framework"
    )
    
    let codeReview = EnhancedPromptTemplate(
        name: "Code Review Checklist",
        content: """
        Please review the following code focusing on {{review_focus}}:
        
        **Review Criteria:**
        - Code quality: {{quality_level}}
        - Security review: {{include_security}}
        - Performance analysis: {{include_performance}}
        - Style compliance: {{style_guide}}
        
        **Code Context:**
        - Language: {{language}}
        - Framework: {{framework}}
        - Module: {{module_name}}
        
        **Review Areas:**
        1. Logic correctness
        2. Error handling
        3. Performance implications
        4. Security considerations
        5. Maintainability
        
        **Reviewer:** {{reviewer}}
        **Review date:** {{date}}
        """,
        category: "Code Review",
        description: "Comprehensive code review template with customizable focus areas"
    )
    
    return [systemAnalysis, errorInvestigation, codeReview]
}