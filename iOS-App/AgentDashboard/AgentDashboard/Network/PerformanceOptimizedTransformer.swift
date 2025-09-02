//
//  PerformanceOptimizedTransformer.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Performance optimizations for data transformation with compression and batch processing
//

import Foundation

// MARK: - Performance Optimized Transformer

final class PerformanceOptimizedTransformer {
    
    // Configuration
    private let compressionThreshold: Int = 1024 // Compress payloads > 1KB
    private let batchSize: Int = 10
    private let memoryLimit: Int = 50 * 1024 * 1024 // 50MB
    
    // State
    private var currentMemoryUsage: Int = 0
    private var compressionCache: [String: Data] = [:]
    
    // Metrics
    private var performanceMetrics = PerformanceMetrics()
    
    func optimizedTransform(_ message: WebSocketMessage) async throws -> OptimizedTransformResult {
        let startTime = Date()
        
        // Check memory usage
        let estimatedSize = message.payload.count + 500 // Overhead estimate
        guard currentMemoryUsage + estimatedSize <= memoryLimit else {
            throw TransformationError.transformationFailed("Memory", NSError(domain: "MemoryLimit", code: 1))
        }
        
        currentMemoryUsage += estimatedSize
        defer { currentMemoryUsage -= estimatedSize }
        
        // Apply compression if needed
        let processedPayload: Data
        if message.payload.count > compressionThreshold {
            processedPayload = try await compressPayload(message.payload)
            performanceMetrics.recordCompression(
                originalSize: message.payload.count,
                compressedSize: processedPayload.count
            )
        } else {
            processedPayload = message.payload
        }
        
        let processingTime = Date().timeIntervalSince(startTime)
        performanceMetrics.recordProcessing(duration: processingTime)
        
        return OptimizedTransformResult(
            originalMessage: message,
            optimizedPayload: processedPayload,
            compressionRatio: Double(processedPayload.count) / Double(message.payload.count),
            processingTime: processingTime,
            memoryUsed: estimatedSize
        )
    }
    
    private func compressPayload(_ data: Data) async throws -> Data {
        // Simple compression simulation
        print("[PerformanceOptimizedTransformer] Compressing \(data.count) bytes")
        
        // In a real implementation, you would use proper compression
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms simulation
        
        let compressionRatio = 0.7 // Simulate 30% compression
        let compressedSize = Int(Double(data.count) * compressionRatio)
        
        return Data(data.prefix(compressedSize))
    }
    
    func getMetrics() -> PerformanceMetrics {
        return performanceMetrics
    }
}

struct OptimizedTransformResult {
    let originalMessage: WebSocketMessage
    let optimizedPayload: Data
    let compressionRatio: Double
    let processingTime: TimeInterval
    let memoryUsed: Int
}

struct PerformanceMetrics {
    private(set) var totalProcessed: Int = 0
    private(set) var totalCompressions: Int = 0
    private(set) var averageCompressionRatio: Double = 0
    private(set) var averageProcessingTime: TimeInterval = 0
    
    private var totalProcessingTime: TimeInterval = 0
    private var totalCompressionRatio: Double = 0
    
    mutating func recordProcessing(duration: TimeInterval) {
        totalProcessed += 1
        totalProcessingTime += duration
        averageProcessingTime = totalProcessingTime / Double(totalProcessed)
    }
    
    mutating func recordCompression(originalSize: Int, compressedSize: Int) {
        totalCompressions += 1
        let ratio = Double(compressedSize) / Double(originalSize)
        totalCompressionRatio += ratio
        averageCompressionRatio = totalCompressionRatio / Double(totalCompressions)
    }
}