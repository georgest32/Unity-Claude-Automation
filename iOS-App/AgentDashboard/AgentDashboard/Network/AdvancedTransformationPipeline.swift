//
//  AdvancedTransformationPipeline.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Advanced data transformation pipeline with filtering, routing, and performance optimization
//

import Foundation

// MARK: - Advanced Transformation Pipeline

final class AdvancedTransformationPipeline {
    
    // Core components
    private let messageTransformer: MessageTransformerProtocol
    private let filterEngine: MessageFilterEngine
    private let compressionEngine: CompressionEngine
    
    // Configuration
    private let enableCompression: Bool
    private let enableBatchOptimization: Bool
    private let performanceThreshold: TimeInterval
    
    // Metrics
    private var pipelineMetrics = TransformationPipelineMetrics()
    
    init(messageTransformer: MessageTransformerProtocol = MessageTransformer(),
         enableCompression: Bool = true,
         enableBatchOptimization: Bool = true,
         performanceThreshold: TimeInterval = 0.1) {
        
        self.messageTransformer = messageTransformer
        self.filterEngine = MessageFilterEngine()
        self.compressionEngine = CompressionEngine()
        self.enableCompression = enableCompression
        self.enableBatchOptimization = enableBatchOptimization
        self.performanceThreshold = performanceThreshold
        
        print("[AdvancedTransformationPipeline] Initialized with compression: \(enableCompression), batch optimization: \(enableBatchOptimization)")
    }
    
    func processMessage(_ message: WebSocketMessage) async throws -> TransformationResult {
        let startTime = Date()
        
        print("[AdvancedTransformationPipeline] Processing message: \(message.type.rawValue)")
        
        // Step 1: Apply filters
        let filterResult = await filterEngine.shouldProcess(message)
        guard filterResult.shouldProcess else {
            pipelineMetrics.recordFiltered(reason: filterResult.reason)
            return .filtered(filterResult.reason)
        }
        
        // Step 2: Transform message
        let transformedData = try await messageTransformer.transform(message)
        
        // Step 3: Apply compression if enabled
        let finalData: Any?
        if enableCompression && message.payload.count > 1024 { // Only compress large payloads
            finalData = try await compressionEngine.compress(transformedData)
        } else {
            finalData = transformedData
        }
        
        let processingTime = Date().timeIntervalSince(startTime)
        pipelineMetrics.recordProcessing(duration: processingTime)
        
        print("[AdvancedTransformationPipeline] Message processed in \(String(format: "%.3fms", processingTime * 1000))")
        
        return .success(TransformedMessage(
            originalMessage: message,
            transformedData: finalData,
            processingTime: processingTime,
            compressionApplied: enableCompression && message.payload.count > 1024,
            metadata: [
                "originalSize": message.payload.count,
                "processingTime": processingTime,
                "filtersPassed": true
            ]
        ))
    }
}

// MARK: - Transformation Result

enum TransformationResult {
    case success(TransformedMessage)
    case filtered(FilterReason)
    case failed(TransformationError)
    
    var isSuccess: Bool {
        switch self {
        case .success: return true
        case .filtered, .failed: return false
        }
    }
}

struct TransformedMessage {
    let originalMessage: WebSocketMessage
    let transformedData: Any?
    let processingTime: TimeInterval
    let compressionApplied: Bool
    let metadata: [String: Any]
}

// MARK: - Message Filter Engine

final class MessageFilterEngine {
    
    private var filters: [MessageFilter] = []
    
    init() {
        setupDefaultFilters()
    }
    
    func shouldProcess(_ message: WebSocketMessage) async -> FilterResult {
        for filter in filters {
            let result = await filter.evaluate(message)
            if !result.shouldProcess {
                return result
            }
        }
        
        return FilterResult(shouldProcess: true, reason: .none)
    }
    
    private func setupDefaultFilters() {
        filters = [
            DuplicateMessageFilter(),
            MessageAgeFilter(maxAge: 300), // 5 minutes
            PayloadSizeFilter(maxSize: 5 * 1024 * 1024), // 5MB
            RateLimitFilter(maxMessagesPerSecond: 50)
        ]
    }
}

struct FilterResult {
    let shouldProcess: Bool
    let reason: FilterReason
}

enum FilterReason {
    case none
    case duplicate
    case tooOld
    case tooLarge
    case rateLimited
    case invalidFormat
    case blacklisted
}

// MARK: - Message Filters

protocol MessageFilter {
    func evaluate(_ message: WebSocketMessage) async -> FilterResult
}

final class DuplicateMessageFilter: MessageFilter {
    private var seenMessages: Set<UUID> = []
    private let maxCacheSize = 1000
    
    func evaluate(_ message: WebSocketMessage) async -> FilterResult {
        if seenMessages.contains(message.id) {
            return FilterResult(shouldProcess: false, reason: .duplicate)
        }
        
        seenMessages.insert(message.id)
        
        // Limit cache size
        if seenMessages.count > maxCacheSize {
            seenMessages.removeFirst()
        }
        
        return FilterResult(shouldProcess: true, reason: .none)
    }
}

final class MessageAgeFilter: MessageFilter {
    private let maxAge: TimeInterval
    
    init(maxAge: TimeInterval) {
        self.maxAge = maxAge
    }
    
    func evaluate(_ message: WebSocketMessage) async -> FilterResult {
        let age = Date().timeIntervalSince(message.timestamp)
        
        if age > maxAge {
            return FilterResult(shouldProcess: false, reason: .tooOld)
        }
        
        return FilterResult(shouldProcess: true, reason: .none)
    }
}

final class PayloadSizeFilter: MessageFilter {
    private let maxSize: Int
    
    init(maxSize: Int) {
        self.maxSize = maxSize
    }
    
    func evaluate(_ message: WebSocketMessage) async -> FilterResult {
        if message.payload.count > maxSize {
            return FilterResult(shouldProcess: false, reason: .tooLarge)
        }
        
        return FilterResult(shouldProcess: true, reason: .none)
    }
}

final class RateLimitFilter: MessageFilter {
    private let maxMessagesPerSecond: Int
    private var messageTimes: [Date] = []
    
    init(maxMessagesPerSecond: Int) {
        self.maxMessagesPerSecond = maxMessagesPerSecond
    }
    
    func evaluate(_ message: WebSocketMessage) async -> FilterResult {
        let now = Date()
        let oneSecondAgo = now.addingTimeInterval(-1.0)
        
        // Remove old messages
        messageTimes = messageTimes.filter { $0 > oneSecondAgo }
        
        if messageTimes.count >= maxMessagesPerSecond {
            return FilterResult(shouldProcess: false, reason: .rateLimited)
        }
        
        messageTimes.append(now)
        return FilterResult(shouldProcess: true, reason: .none)
    }
}

// MARK: - Compression Engine

final class CompressionEngine {
    
    func compress(_ data: Any?) async throws -> Any? {
        // Simple compression simulation for now
        print("[CompressionEngine] Applying compression to data")
        return data
    }
}

// MARK: - Pipeline Metrics

struct TransformationPipelineMetrics {
    private(set) var messagesProcessed: Int = 0
    private(set) var messagesFiltered: [FilterReason: Int] = [:]
    private(set) var averageProcessingTime: TimeInterval = 0
    
    private var totalProcessingTime: TimeInterval = 0
    
    mutating func recordProcessing(duration: TimeInterval) {
        messagesProcessed += 1
        totalProcessingTime += duration
        averageProcessingTime = totalProcessingTime / Double(messagesProcessed)
    }
    
    mutating func recordFiltered(reason: FilterReason) {
        messagesFiltered[reason, default: 0] += 1
    }
}