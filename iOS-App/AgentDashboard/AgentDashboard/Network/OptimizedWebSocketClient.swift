//
//  OptimizedWebSocketClient.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Optimized WebSocket client with traffic reduction and performance enhancements
//

import Foundation
import Network
import ComposableArchitecture

// MARK: - Optimized WebSocket Client Protocol

protocol OptimizedWebSocketClientProtocol {
    /// Connect with optimized settings
    func connectOptimized() async throws
    
    /// Send message with compression
    func sendCompressed(_ message: WebSocketMessage) async throws
    
    /// Send batch of messages efficiently
    func sendBatch(_ messages: [WebSocketMessage]) async throws
    
    /// Configure traffic optimization
    func configureOptimization(_ config: WebSocketOptimizationConfig)
    
    /// Get performance metrics
    func getPerformanceMetrics() -> WebSocketPerformanceMetrics
    
    /// Enable/disable message compression
    func setCompressionEnabled(_ enabled: Bool)
}

// MARK: - WebSocket Optimization Models

struct WebSocketOptimizationConfig {
    var compressionEnabled: Bool = true
    var batchingEnabled: Bool = true
    var maxBatchSize: Int = 10
    var batchTimeout: TimeInterval = 1.0
    var heartbeatInterval: TimeInterval = 30.0
    var reconnectDelay: TimeInterval = 5.0
    var maxReconnectAttempts: Int = 5
    var trafficLoggingEnabled: Bool = false
    
    static let `default` = WebSocketOptimizationConfig()
    
    static let highPerformance = WebSocketOptimizationConfig(
        compressionEnabled: true,
        batchingEnabled: true,
        maxBatchSize: 20,
        batchTimeout: 0.5,
        heartbeatInterval: 15.0,
        reconnectDelay: 2.0,
        maxReconnectAttempts: 10,
        trafficLoggingEnabled: false
    )
    
    static let lowBandwidth = WebSocketOptimizationConfig(
        compressionEnabled: true,
        batchingEnabled: true,
        maxBatchSize: 50,
        batchTimeout: 2.0,
        heartbeatInterval: 60.0,
        reconnectDelay: 10.0,
        maxReconnectAttempts: 3,
        trafficLoggingEnabled: false
    )
}

struct WebSocketPerformanceMetrics {
    var totalMessagesSent: Int = 0
    var totalMessagesReceived: Int = 0
    var totalBytesSent: Int = 0
    var totalBytesReceived: Int = 0
    var compressionRatio: Double = 0.0
    var averageLatency: TimeInterval = 0.0
    var connectionUptime: TimeInterval = 0.0
    var reconnectionCount: Int = 0
    var lastConnectionTime: Date?
    var trafficSavings: Double = 0.0
    
    var messagesPerSecond: Double {
        guard connectionUptime > 0 else { return 0 }
        return Double(totalMessagesReceived) / connectionUptime
    }
    
    var bytesPerSecond: Double {
        guard connectionUptime > 0 else { return 0 }
        return Double(totalBytesReceived) / connectionUptime
    }
    
    var compressionSavings: String {
        String(format: "%.1f%%", (1.0 - compressionRatio) * 100)
    }
}

// MARK: - Message Batching System

final class MessageBatcher {
    private var pendingMessages: [WebSocketMessage] = []
    private var batchTimer: Timer?
    private let maxBatchSize: Int
    private let batchInterval: TimeInterval
    private let logger = Logger(subsystem: "AgentDashboard", category: "MessageBatcher")
    
    var onBatchReady: (([WebSocketMessage]) -> Void)?
    
    init(maxBatchSize: Int = 10, batchInterval: TimeInterval = 1.0) {
        self.maxBatchSize = maxBatchSize
        self.batchInterval = batchInterval
        logger.debug("MessageBatcher initialized - MaxSize: \(maxBatchSize), Interval: \(batchInterval)s")
    }
    
    func addMessage(_ message: WebSocketMessage) {
        pendingMessages.append(message)
        logger.debug("Message added to batch - Pending: \(pendingMessages.count)/\(maxBatchSize)")
        
        // Send batch if we've reached the size limit
        if pendingMessages.count >= maxBatchSize {
            sendBatch()
        } else if batchTimer == nil {
            // Start timer for timeout-based sending
            startBatchTimer()
        }
    }
    
    private func sendBatch() {
        guard !pendingMessages.isEmpty else { return }
        
        let batch = pendingMessages
        pendingMessages.removeAll()
        batchTimer?.invalidate()
        batchTimer = nil
        
        logger.info("Sending message batch - Count: \(batch.count)")
        onBatchReady?(batch)
    }
    
    private func startBatchTimer() {
        batchTimer = Timer.scheduledTimer(withTimeInterval: batchInterval, repeats: false) { _ in
            self.sendBatch()
        }
    }
    
    func flush() {
        logger.debug("Flushing pending messages - Count: \(pendingMessages.count)")
        sendBatch()
    }
}

// MARK: - Message Compression System

final class MessageCompressor {
    private let logger = Logger(subsystem: "AgentDashboard", category: "MessageCompressor")
    
    func compress(_ data: Data) throws -> Data {
        logger.debug("Compressing message - Original size: \(data.count) bytes")
        
        let compressedData = try (data as NSData).compressed(using: .zlib) as Data
        let compressionRatio = Double(compressedData.count) / Double(data.count)
        
        logger.debug("Message compressed - New size: \(compressedData.count) bytes, Ratio: \(String(format: "%.2f", compressionRatio))")
        
        return compressedData
    }
    
    func decompress(_ data: Data) throws -> Data {
        logger.debug("Decompressing message - Compressed size: \(data.count) bytes")
        
        let decompressedData = try (data as NSData).decompressed(using: .zlib) as Data
        
        logger.debug("Message decompressed - Original size: \(decompressedData.count) bytes")
        
        return decompressedData
    }
}

// MARK: - Optimized WebSocket Client Implementation

final class OptimizedWebSocketClient: OptimizedWebSocketClientProtocol {
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession
    private let url: URL
    private let logger = Logger(subsystem: "AgentDashboard", category: "OptimizedWebSocket")
    
    // Optimization components
    private let messageBatcher: MessageBatcher
    private let messageCompressor: MessageCompressor
    private var optimizationConfig: WebSocketOptimizationConfig
    private var performanceMetrics = WebSocketPerformanceMetrics()
    
    // Connection management
    private var isConnected: Bool = false
    private var connectionStartTime: Date?
    private var heartbeatTimer: Timer?
    private var reconnectAttempts: Int = 0
    
    init(url: URL, optimizationConfig: WebSocketOptimizationConfig = .default) {
        self.url = url
        self.optimizationConfig = optimizationConfig
        self.messageBatcher = MessageBatcher(
            maxBatchSize: optimizationConfig.maxBatchSize,
            batchInterval: optimizationConfig.batchTimeout
        )
        self.messageCompressor = MessageCompressor()
        
        // Configure URLSession for optimal performance
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30.0
        configuration.timeoutIntervalForResource = 300.0
        configuration.waitsForConnectivity = true
        
        self.session = URLSession(configuration: configuration)
        
        logger.info("OptimizedWebSocketClient initialized - URL: \(url), Config: \(optimizationConfig)")
        
        setupMessageBatcher()
    }
    
    private func setupMessageBatcher() {
        messageBatcher.onBatchReady = { [weak self] batch in
            Task {
                await self?.sendMessageBatch(batch)
            }
        }
    }
    
    func connectOptimized() async throws {
        logger.info("Connecting optimized WebSocket to: \(url)")
        
        webSocketTask = session.webSocketTask(with: url)
        connectionStartTime = Date()
        performanceMetrics.lastConnectionTime = Date()
        
        webSocketTask?.resume()
        isConnected = true
        
        logger.info("Optimized WebSocket connected successfully")
        
        // Start heartbeat if configured
        if optimizationConfig.heartbeatInterval > 0 {
            startHeartbeat()
        }
        
        // Start receiving messages
        await startReceivingMessages()
    }
    
    func sendCompressed(_ message: WebSocketMessage) async throws {
        logger.debug("Sending compressed message - Type: \(message.type.rawValue)")
        
        guard isConnected, let webSocketTask = webSocketTask else {
            throw WebSocketError.notConnected
        }
        
        do {
            var messageData = message.payload
            
            // Apply compression if enabled
            if optimizationConfig.compressionEnabled {
                messageData = try messageCompressor.compress(messageData)
                performanceMetrics.compressionRatio = Double(messageData.count) / Double(message.payload.count)
            }
            
            // Create optimized message
            let optimizedMessage = URLSessionWebSocketTask.Message.data(messageData)
            
            // Send message
            try await webSocketTask.send(optimizedMessage)
            
            // Update metrics
            performanceMetrics.totalMessagesSent += 1
            performanceMetrics.totalBytesSent += messageData.count
            
            logger.debug("Compressed message sent - Original: \(message.payload.count) bytes, Compressed: \(messageData.count) bytes")
            
        } catch {
            logger.error("Failed to send compressed message: \(error.localizedDescription)")
            throw error
        }
    }
    
    func sendBatch(_ messages: [WebSocketMessage]) async throws {
        logger.info("Sending message batch - Count: \(messages.count)")
        
        guard !messages.isEmpty else { return }
        
        if optimizationConfig.batchingEnabled && messages.count > 1 {
            // Send as single batch message
            let batchMessage = createBatchMessage(messages)
            try await sendCompressed(batchMessage)
            logger.debug("Batch sent as single message")
        } else {
            // Send individually
            for message in messages {
                try await sendCompressed(message)
            }
            logger.debug("Batch sent as individual messages")
        }
    }
    
    func configureOptimization(_ config: WebSocketOptimizationConfig) {
        logger.info("Updating WebSocket optimization configuration")
        
        self.optimizationConfig = config
        
        // Update message batcher
        messageBatcher.maxBatchSize = config.maxBatchSize
        messageBatcher.batchInterval = config.batchTimeout
        
        // Restart heartbeat with new interval
        if isConnected {
            stopHeartbeat()
            if config.heartbeatInterval > 0 {
                startHeartbeat()
            }
        }
        
        logger.debug("Optimization configuration updated")
    }
    
    func getPerformanceMetrics() -> WebSocketPerformanceMetrics {
        // Update uptime
        if let connectionTime = connectionStartTime {
            performanceMetrics.connectionUptime = Date().timeIntervalSince(connectionTime)
        }
        
        return performanceMetrics
    }
    
    func setCompressionEnabled(_ enabled: Bool) {
        logger.info("Setting compression enabled: \(enabled)")
        optimizationConfig.compressionEnabled = enabled
    }
    
    // MARK: - Private Helper Methods
    
    private func startReceivingMessages() async {
        while isConnected {
            do {
                guard let webSocketTask = webSocketTask else { break }
                
                let message = try await webSocketTask.receive()
                await processReceivedMessage(message)
                
            } catch {
                logger.error("Error receiving WebSocket message: \(error.localizedDescription)")
                
                if isConnected {
                    await attemptReconnection()
                }
                break
            }
        }
    }
    
    private func processReceivedMessage(_ message: URLSessionWebSocketTask.Message) async {
        let startTime = Date()
        
        do {
            var messageData: Data
            
            switch message {
            case .data(let data):
                messageData = data
            case .string(let string):
                messageData = string.data(using: .utf8) ?? Data()
            @unknown default:
                logger.warning("Unknown WebSocket message type received")
                return
            }
            
            // Decompress if needed
            if optimizationConfig.compressionEnabled {
                messageData = try messageCompressor.decompress(messageData)
            }
            
            // Update metrics
            performanceMetrics.totalMessagesReceived += 1
            performanceMetrics.totalBytesReceived += messageData.count
            
            let processingTime = Date().timeIntervalSince(startTime)
            performanceMetrics.averageLatency = (performanceMetrics.averageLatency + processingTime) / 2.0
            
            logger.debug("Message processed - Size: \(messageData.count) bytes, Time: \(String(format: "%.3f", processingTime))s")
            
        } catch {
            logger.error("Failed to process received message: \(error.localizedDescription)")
        }
    }
    
    private func createBatchMessage(_ messages: [WebSocketMessage]) -> WebSocketMessage {
        let batchData = try? JSONEncoder().encode(messages)
        
        return WebSocketMessage(
            id: UUID(),
            type: .batch,
            payload: batchData ?? Data(),
            timestamp: Date()
        )
    }
    
    private func startHeartbeat() {
        logger.debug("Starting heartbeat with interval: \(optimizationConfig.heartbeatInterval)s")
        
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: optimizationConfig.heartbeatInterval, repeats: true) { _ in
            Task {
                await self.sendHeartbeat()
            }
        }
    }
    
    private func stopHeartbeat() {
        logger.debug("Stopping heartbeat")
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }
    
    private func sendHeartbeat() async {
        let heartbeatMessage = WebSocketMessage(
            id: UUID(),
            type: .heartbeat,
            payload: Data(),
            timestamp: Date()
        )
        
        do {
            try await sendCompressed(heartbeatMessage)
            logger.debug("Heartbeat sent")
        } catch {
            logger.warning("Failed to send heartbeat: \(error.localizedDescription)")
        }
    }
    
    private func attemptReconnection() async {
        guard reconnectAttempts < optimizationConfig.maxReconnectAttempts else {
            logger.error("Max reconnection attempts reached")
            isConnected = false
            return
        }
        
        reconnectAttempts += 1
        performanceMetrics.reconnectionCount += 1
        
        logger.info("Attempting reconnection \(reconnectAttempts)/\(optimizationConfig.maxReconnectAttempts)")
        
        try? await Task.sleep(nanoseconds: UInt64(optimizationConfig.reconnectDelay * 1_000_000_000))
        
        do {
            try await connectOptimized()
            reconnectAttempts = 0 // Reset on successful connection
            logger.info("Reconnection successful")
        } catch {
            logger.error("Reconnection failed: \(error.localizedDescription)")
        }
    }
    
    private func sendMessageBatch(_ batch: [WebSocketMessage]) async {
        do {
            try await sendBatch(batch)
            logger.debug("Message batch sent successfully - Count: \(batch.count)")
        } catch {
            logger.error("Failed to send message batch: \(error.localizedDescription)")
        }
    }
    
    func disconnect() async {
        logger.info("Disconnecting optimized WebSocket")
        
        isConnected = false
        stopHeartbeat()
        
        webSocketTask?.cancel(with: .goingAway, reason: "Client disconnect".data(using: .utf8))
        webSocketTask = nil
        
        logger.info("Optimized WebSocket disconnected")
    }
}

// MARK: - WebSocket Message Extensions

extension WebSocketMessage {
    enum MessageType: String, Codable {
        case agentStatus
        case systemMetrics
        case terminalOutput
        case commandResult
        case alert
        case heartbeat
        case batch
        case compressed
    }
}

// MARK: - WebSocket Error Types

enum WebSocketError: Error, LocalizedError {
    case notConnected
    case compressionFailed
    case decompressionFailed
    case batchingFailed
    case configurationError
    
    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "WebSocket not connected"
        case .compressionFailed:
            return "Message compression failed"
        case .decompressionFailed:
            return "Message decompression failed"
        case .batchingFailed:
            return "Message batching failed"
        case .configurationError:
            return "WebSocket configuration error"
        }
    }
}

// MARK: - Performance Monitoring Service

final class WebSocketPerformanceMonitor {
    private let logger = Logger(subsystem: "AgentDashboard", category: "WebSocketPerformance")
    private var metrics = WebSocketPerformanceMetrics()
    private var latencyMeasurements: [TimeInterval] = []
    private let maxLatencyMeasurements = 100
    
    func recordLatency(_ latency: TimeInterval) {
        latencyMeasurements.append(latency)
        
        // Keep only recent measurements
        if latencyMeasurements.count > maxLatencyMeasurements {
            latencyMeasurements.removeFirst()
        }
        
        // Update average latency
        metrics.averageLatency = latencyMeasurements.reduce(0, +) / Double(latencyMeasurements.count)
        
        logger.debug("Latency recorded: \(String(format: "%.3f", latency))s, Average: \(String(format: "%.3f", metrics.averageLatency))s")
    }
    
    func recordTrafficSavings(_ originalSize: Int, _ optimizedSize: Int) {
        let savings = 1.0 - (Double(optimizedSize) / Double(originalSize))
        metrics.trafficSavings = (metrics.trafficSavings + savings) / 2.0 // Running average
        
        logger.debug("Traffic savings recorded - Original: \(originalSize) bytes, Optimized: \(optimizedSize) bytes, Savings: \(String(format: "%.1f", savings * 100))%")
    }
    
    func getMetrics() -> WebSocketPerformanceMetrics {
        return metrics
    }
    
    func reset() {
        logger.info("Resetting performance metrics")
        metrics = WebSocketPerformanceMetrics()
        latencyMeasurements.removeAll()
    }
}

// MARK: - Mock Optimized WebSocket Client

final class MockOptimizedWebSocketClient: OptimizedWebSocketClientProtocol {
    private let logger = Logger(subsystem: "AgentDashboard", category: "MockOptimizedWebSocket")
    private var mockMetrics = WebSocketPerformanceMetrics()
    private var isCompressionEnabled = true
    
    init() {
        logger.info("MockOptimizedWebSocketClient initialized")
        
        // Generate realistic mock metrics
        mockMetrics.totalMessagesSent = 150
        mockMetrics.totalMessagesReceived = 200
        mockMetrics.totalBytesSent = 45000
        mockMetrics.totalBytesReceived = 67000
        mockMetrics.compressionRatio = 0.65 // 35% compression savings
        mockMetrics.averageLatency = 0.120 // 120ms average
        mockMetrics.connectionUptime = 3600 // 1 hour
        mockMetrics.reconnectionCount = 2
        mockMetrics.trafficSavings = 0.35
    }
    
    func connectOptimized() async throws {
        logger.info("Mock optimized WebSocket connection")
        
        // Simulate connection delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        mockMetrics.lastConnectionTime = Date()
        logger.info("Mock optimized WebSocket connected")
    }
    
    func sendCompressed(_ message: WebSocketMessage) async throws {
        logger.debug("Mock sending compressed message - Type: \(message.type.rawValue)")
        
        // Simulate compression and network delay
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        
        mockMetrics.totalMessagesSent += 1
        let originalSize = message.payload.count
        let compressedSize = isCompressionEnabled ? Int(Double(originalSize) * 0.65) : originalSize
        mockMetrics.totalBytesSent += compressedSize
        
        logger.debug("Mock compressed message sent - Original: \(originalSize) bytes, Compressed: \(compressedSize) bytes")
    }
    
    func sendBatch(_ messages: [WebSocketMessage]) async throws {
        logger.info("Mock sending message batch - Count: \(messages.count)")
        
        for message in messages {
            try await sendCompressed(message)
        }
        
        logger.debug("Mock message batch sent successfully")
    }
    
    func configureOptimization(_ config: WebSocketOptimizationConfig) {
        logger.info("Mock updating optimization configuration")
        // Configuration would be applied in real implementation
    }
    
    func getPerformanceMetrics() -> WebSocketPerformanceMetrics {
        // Update uptime
        if let connectionTime = mockMetrics.lastConnectionTime {
            mockMetrics.connectionUptime = Date().timeIntervalSince(connectionTime)
        }
        
        return mockMetrics
    }
    
    func setCompressionEnabled(_ enabled: Bool) {
        logger.info("Mock setting compression enabled: \(enabled)")
        isCompressionEnabled = enabled
    }
}

// MARK: - Dependency Registration

private enum OptimizedWebSocketKey: DependencyKey {
    static let liveValue: OptimizedWebSocketClientProtocol = {
        let url = URL(string: "ws://localhost:8080/systemhub")!
        return OptimizedWebSocketClient(url: url, optimizationConfig: .highPerformance)
    }()
    static let testValue: OptimizedWebSocketClientProtocol = MockOptimizedWebSocketClient()
    static let previewValue: OptimizedWebSocketClientProtocol = MockOptimizedWebSocketClient()
}

extension DependencyValues {
    var optimizedWebSocket: OptimizedWebSocketClientProtocol {
        get { self[OptimizedWebSocketKey.self] }
        set { self[OptimizedWebSocketKey.self] = newValue }
    }
}