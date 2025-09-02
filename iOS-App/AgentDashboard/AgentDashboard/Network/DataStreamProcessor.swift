//
//  DataStreamProcessor.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Enhanced data stream processing with validation, transformation, and performance monitoring
//

import Foundation
import ComposableArchitecture

// MARK: - Stream Processing Protocol

protocol DataStreamProcessorProtocol {
    func processMessage(_ message: WebSocketMessage) async -> ProcessingResult
    func processMessageBatch(_ messages: [WebSocketMessage]) async -> BatchProcessingResult
    func getProcessingMetrics() -> StreamProcessingMetrics
    func resetMetrics()
}

// MARK: - Processing Results

enum ProcessingResult {
    case success(ProcessedMessage)
    case failed(ProcessingError)
    case filtered(FilterReason)
    
    var isSuccess: Bool {
        switch self {
        case .success: return true
        case .failed, .filtered: return false
        }
    }
    
    var processedMessage: ProcessedMessage? {
        switch self {
        case .success(let message): return message
        case .failed, .filtered: return nil
        }
    }
    
    var error: ProcessingError? {
        switch self {
        case .failed(let error): return error
        case .success, .filtered: return nil
        }
    }
}

struct BatchProcessingResult {
    let processed: [ProcessedMessage]
    let failed: [ProcessingError]
    let filtered: Int
    let totalProcessingTime: TimeInterval
    
    var successCount: Int { processed.count }
    var failureCount: Int { failed.count }
    var totalCount: Int { successCount + failureCount + filtered }
    var successRate: Double { 
        return totalCount > 0 ? Double(successCount) / Double(totalCount) : 0
    }
}

struct ProcessedMessage {
    let originalMessage: WebSocketMessage
    let validatedPayload: Any?
    let transformedData: Any?
    let processingTime: TimeInterval
    let priority: MessagePriority
    let metadata: [String: Any]
    
    enum MessagePriority: Int, Comparable {
        case low = 0
        case normal = 1
        case high = 2
        case critical = 3
        
        static func < (lhs: MessagePriority, rhs: MessagePriority) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    }
}

enum FilterReason {
    case duplicateMessage
    case rateLimited
    case priorityFiltered
    case payloadTooOld
    case invalidSchema
}

enum ProcessingError: Error, LocalizedError {
    case validationFailed(ValidationError)
    case transformationFailed(Error)
    case processingTimeout
    case memoryLimitExceeded
    case unknownMessageType
    
    var errorDescription: String? {
        switch self {
        case .validationFailed(let error):
            return "Validation failed: \(error.localizedDescription ?? "Unknown validation error")"
        case .transformationFailed(let error):
            return "Transformation failed: \(error.localizedDescription)"
        case .processingTimeout:
            return "Processing timeout exceeded"
        case .memoryLimitExceeded:
            return "Memory limit exceeded during processing"
        case .unknownMessageType:
            return "Unknown message type"
        }
    }
}

// MARK: - Data Stream Processor Implementation

final class DataStreamProcessor: DataStreamProcessorProtocol {
    
    // Dependencies
    private let validator: MessageValidatorProtocol
    private let transformer: MessageTransformerProtocol
    
    // Configuration
    private let processingTimeout: TimeInterval
    private let maxMemoryUsage: Int // bytes
    private let enableBatchProcessing: Bool
    private let batchSize: Int
    
    // State
    private var processingMetrics = StreamProcessingMetrics()
    private var messageCache: Set<UUID> = []
    private var rateLimiter: RateLimiter
    private var currentMemoryUsage: Int = 0
    
    // Queue for batch processing
    private var pendingMessages: [WebSocketMessage] = []
    private let processingQueue = DispatchQueue(label: "com.agentdashboard.datastream", qos: .userInitiated)
    
    init(validator: MessageValidatorProtocol = MessageValidator(),
         transformer: MessageTransformerProtocol = MessageTransformer(),
         processingTimeout: TimeInterval = 5.0,
         maxMemoryUsage: Int = 50 * 1024 * 1024, // 50MB
         enableBatchProcessing: Bool = true,
         batchSize: Int = 10) {
        self.validator = validator
        self.transformer = transformer
        self.processingTimeout = processingTimeout
        self.maxMemoryUsage = maxMemoryUsage
        self.enableBatchProcessing = enableBatchProcessing
        self.batchSize = batchSize
        self.rateLimiter = RateLimiter(maxRequestsPerSecond: 100)
        
        print("[DataStreamProcessor] Initialized with timeout: \(processingTimeout)s, max memory: \(maxMemoryUsage) bytes")
    }
    
    func processMessage(_ message: WebSocketMessage) async -> ProcessingResult {
        let startTime = Date()
        
        print("[DataStreamProcessor] Processing message ID: \(message.id), type: \(message.type.rawValue)")
        
        // Check rate limiting
        if !rateLimiter.allowRequest() {
            print("[DataStreamProcessor] Message rate limited")
            processingMetrics.recordFiltered(.rateLimited)
            return .filtered(.rateLimited)
        }
        
        // Check for duplicate messages
        if messageCache.contains(message.id) {
            print("[DataStreamProcessor] Duplicate message filtered: \(message.id)")
            processingMetrics.recordFiltered(.duplicateMessage)
            return .filtered(.duplicateMessage)
        }
        
        // Add to cache (with size limit)
        messageCache.insert(message.id)
        if messageCache.count > 1000 { // Prevent memory growth
            messageCache.removeFirst()
        }
        
        // Check memory usage
        let estimatedMessageSize = message.payload.count + 200 // Estimated overhead
        if currentMemoryUsage + estimatedMessageSize > maxMemoryUsage {
            print("[DataStreamProcessor] Memory limit exceeded")
            processingMetrics.recordError(.memoryLimitExceeded)
            return .failed(.memoryLimitExceeded)
        }
        currentMemoryUsage += estimatedMessageSize
        defer { currentMemoryUsage -= estimatedMessageSize }
        
        // Process with timeout
        do {
            let result = try await withTimeout(processingTimeout) {
                await self.processMessageInternal(message, startTime: startTime)
            }
            
            let processingTime = Date().timeIntervalSince(startTime)
            processingMetrics.recordProcessing(duration: processingTime, success: result.isSuccess)
            
            return result
        } catch {
            print("[DataStreamProcessor] Processing timeout: \(error)")
            processingMetrics.recordError(.processingTimeout)
            return .failed(.processingTimeout)
        }
    }
    
    func processMessageBatch(_ messages: [WebSocketMessage]) async -> BatchProcessingResult {
        let startTime = Date()
        
        print("[DataStreamProcessor] Processing batch of \(messages.count) messages")
        
        var processed: [ProcessedMessage] = []
        var failed: [ProcessingError] = []
        var filtered = 0
        
        // Process messages concurrently but respect memory limits
        for message in messages {
            let result = await processMessage(message)
            
            switch result {
            case .success(let processedMessage):
                processed.append(processedMessage)
            case .failed(let error):
                failed.append(error)
            case .filtered:
                filtered += 1
            }
        }
        
        let totalTime = Date().timeIntervalSince(startTime)
        processingMetrics.recordBatchProcessing(
            messageCount: messages.count,
            duration: totalTime,
            successCount: processed.count
        )
        
        return BatchProcessingResult(
            processed: processed,
            failed: failed,
            filtered: filtered,
            totalProcessingTime: totalTime
        )
    }
    
    // MARK: - Internal Processing
    
    private func processMessageInternal(_ message: WebSocketMessage, startTime: Date) async -> ProcessingResult {
        // Step 1: Validate message
        let validationResult = validator.validate(message)
        if !validationResult.isValid {
            print("[DataStreamProcessor] Message validation failed: \(validationResult.error?.localizedDescription ?? "Unknown error")")
            processingMetrics.recordError(.validationFailed(validationResult.error!))
            return .failed(.validationFailed(validationResult.error!))
        }
        
        // Step 2: Transform payload based on message type
        let transformedData: Any?
        do {
            transformedData = try await transformer.transform(message)
            print("[DataStreamProcessor] Message transformed successfully")
        } catch {
            print("[DataStreamProcessor] Transformation failed: \(error)")
            processingMetrics.recordError(.transformationFailed(error))
            return .failed(.transformationFailed(error))
        }
        
        // Step 3: Determine priority
        let priority = determinePriority(for: message)
        
        // Step 4: Extract metadata
        let metadata = extractMetadata(from: message)
        
        // Step 5: Create processed message
        let processingTime = Date().timeIntervalSince(startTime)
        let processedMessage = ProcessedMessage(
            originalMessage: message,
            validatedPayload: transformedData,
            transformedData: transformedData,
            processingTime: processingTime,
            priority: priority,
            metadata: metadata
        )
        
        print("[DataStreamProcessor] Message processed successfully in \(String(format: "%.3fms", processingTime * 1000))")
        return .success(processedMessage)
    }
    
    private func determinePriority(for message: WebSocketMessage) -> ProcessedMessage.MessagePriority {
        switch message.type {
        case .alert:
            // Check alert severity in payload if possible
            if let alertData = try? JSONDecoder.apiDecoder.decode(Alert.self, from: message.payload) {
                switch alertData.severity {
                case .critical: return .critical
                case .error: return .high
                case .warning: return .normal
                case .info: return .low
                }
            }
            return .high
        case .systemMetrics:
            return .normal
        case .agentStatus:
            return .normal
        case .terminalOutput:
            return .low
        case .commandResult:
            return .high
        case .heartbeat:
            return .low
        }
    }
    
    private func extractMetadata(from message: WebSocketMessage) -> [String: Any] {
        var metadata: [String: Any] = [:]
        
        metadata["messageId"] = message.id.uuidString
        metadata["messageType"] = message.type.rawValue
        metadata["payloadSize"] = message.payload.count
        metadata["timestamp"] = message.timestamp
        metadata["processingTime"] = Date()
        
        // Extract additional metadata based on message type
        switch message.type {
        case .systemMetrics:
            if let systemStatus = try? JSONDecoder.apiDecoder.decode(SystemStatus.self, from: message.payload) {
                metadata["cpuUsage"] = systemStatus.cpuUsage
                metadata["memoryUsage"] = systemStatus.memoryUsage
                metadata["isHealthy"] = systemStatus.isHealthy
            }
            
        case .agentStatus:
            if let agent = try? JSONDecoder.apiDecoder.decode(Agent.self, from: message.payload) {
                metadata["agentName"] = agent.name
                metadata["agentType"] = agent.type.rawValue
                metadata["agentStatus"] = agent.status.rawValue
            }
            
        case .alert:
            if let alert = try? JSONDecoder.apiDecoder.decode(Alert.self, from: message.payload) {
                metadata["alertSeverity"] = alert.severity.rawValue
                metadata["alertSource"] = alert.source
            }
            
        default:
            break
        }
        
        return metadata
    }
    
    // MARK: - Metrics Access
    
    func getProcessingMetrics() -> StreamProcessingMetrics {
        return processingMetrics
    }
    
    func resetMetrics() {
        processingMetrics = StreamProcessingMetrics()
        print("[DataStreamProcessor] Metrics reset")
    }
}

// MARK: - Stream Processing Metrics

struct StreamProcessingMetrics {
    private(set) var totalMessages: Int = 0
    private(set) var successfulMessages: Int = 0
    private(set) var failedMessages: Int = 0
    private(set) var filteredMessages: [FilterReason: Int] = [:]
    private(set) var errorCounts: [String: Int] = [:]
    private(set) var averageProcessingTime: TimeInterval = 0
    private(set) var batchProcessingCount: Int = 0
    private(set) var averageBatchSize: Double = 0
    private(set) var peakMemoryUsage: Int = 0
    
    private var totalProcessingTime: TimeInterval = 0
    private var totalBatchSize: Int = 0
    
    var successRate: Double {
        return totalMessages > 0 ? Double(successfulMessages) / Double(totalMessages) : 0
    }
    
    var messagesPerSecond: Double {
        return averageProcessingTime > 0 ? 1.0 / averageProcessingTime : 0
    }
    
    mutating func recordProcessing(duration: TimeInterval, success: Bool) {
        totalMessages += 1
        totalProcessingTime += duration
        averageProcessingTime = totalProcessingTime / Double(totalMessages)
        
        if success {
            successfulMessages += 1
        } else {
            failedMessages += 1
        }
    }
    
    mutating func recordFiltered(_ reason: FilterReason) {
        filteredMessages[reason, default: 0] += 1
    }
    
    mutating func recordError(_ error: ProcessingError) {
        let errorKey = String(describing: error)
        errorCounts[errorKey, default: 0] += 1
    }
    
    mutating func recordBatchProcessing(messageCount: Int, duration: TimeInterval, successCount: Int) {
        batchProcessingCount += 1
        totalBatchSize += messageCount
        averageBatchSize = Double(totalBatchSize) / Double(batchProcessingCount)
    }
    
    mutating func updateMemoryUsage(_ usage: Int) {
        peakMemoryUsage = max(peakMemoryUsage, usage)
    }
    
    func debugDescription() -> String {
        return """
        [StreamProcessingMetrics]
        Total Messages: \(totalMessages)
        Successful: \(successfulMessages) (\(String(format: "%.1f%%", successRate * 100)))
        Failed: \(failedMessages)
        Filtered: \(filteredMessages.values.reduce(0, +))
        Avg Processing Time: \(String(format: "%.3fms", averageProcessingTime * 1000))
        Messages/Second: \(String(format: "%.1f", messagesPerSecond))
        Batch Count: \(batchProcessingCount)
        Avg Batch Size: \(String(format: "%.1f", averageBatchSize))
        Peak Memory: \(peakMemoryUsage) bytes
        """
    }
}

// MARK: - Rate Limiter

private class RateLimiter {
    private let maxRequestsPerSecond: Int
    private var requestTimes: [Date] = []
    private let queue = DispatchQueue(label: "com.agentdashboard.ratelimiter")
    
    init(maxRequestsPerSecond: Int) {
        self.maxRequestsPerSecond = maxRequestsPerSecond
    }
    
    func allowRequest() -> Bool {
        return queue.sync {
            let now = Date()
            let oneSecondAgo = now.addingTimeInterval(-1.0)
            
            // Remove old requests
            requestTimes = requestTimes.filter { $0 > oneSecondAgo }
            
            // Check if we can allow this request
            if requestTimes.count < maxRequestsPerSecond {
                requestTimes.append(now)
                return true
            }
            
            return false
        }
    }
}

// MARK: - Timeout Utility

private func withTimeout<T>(_ timeout: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
    return try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            return try await operation()
        }
        
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            throw ProcessingError.processingTimeout
        }
        
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}