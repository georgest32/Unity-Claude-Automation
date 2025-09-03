//
//  EnhancedWebSocketClient.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Enhanced WebSocket client with data stream processing and performance monitoring
//

import Foundation
import ComposableArchitecture

// MARK: - Enhanced WebSocket Client Protocol

protocol EnhancedWebSocketClientProtocol: WebSocketClientProtocol {
    func processedMessages() -> AsyncThrowingStream<ProcessedMessage, Error>
    func batchProcessedMessages() -> AsyncThrowingStream<BatchProcessingResult, Error>
    func getStreamingMetrics() -> StreamingMetrics
    func configureBatchProcessing(enabled: Bool, batchSize: Int, batchInterval: TimeInterval)
}

// MARK: - Enhanced WebSocket Client Implementation

final class EnhancedWebSocketClient: WebSocketClientProtocol, EnhancedWebSocketClientProtocol {
    
    // Core WebSocket functionality
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession
    private var url: URL
    private var isTaskConnected = false
    
    // Enhanced processing components
    private let dataStreamProcessor: DataStreamProcessorProtocol
    private let messageBatcher: MessageBatcher
    private var streamingMetrics = StreamingMetrics()
    
    // Configuration
    private var batchProcessingEnabled: Bool = true
    private var batchSize: Int = 10
    private var batchInterval: TimeInterval = 1.0
    
    // Message continuations
    private var messageContinuation: AsyncThrowingStream<WebSocketMessage, Error>.Continuation?
    private var processedMessageContinuation: AsyncThrowingStream<ProcessedMessage, Error>.Continuation?
    private var batchContinuation: AsyncThrowingStream<BatchProcessingResult, Error>.Continuation?
    
    init(url: URL,
         session: URLSession = .shared,
         dataStreamProcessor: DataStreamProcessorProtocol? = nil) {
        self.url = url
        self.session = session
        self.dataStreamProcessor = dataStreamProcessor ?? DataStreamProcessor()
        self.messageBatcher = MessageBatcher(batchSize: batchSize, interval: batchInterval)
        
        print("[EnhancedWebSocketClient] Initialized with URL: \(url)")
    }
    
    // MARK: - WebSocketClientProtocol Implementation
    
    var isConnected: Bool {
        get async {
            return isTaskConnected
        }
    }
    
    func connect() async throws {
        print("[EnhancedWebSocketClient] Attempting to connect to \(url)")
        
        await disconnect()
        
        webSocketTask = session.webSocketTask(with: url)
        
        guard let task = webSocketTask else {
            throw WebSocketError.connectionFailed("Failed to create WebSocket task")
        }
        
        task.resume()
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        isTaskConnected = true
        streamingMetrics.recordConnection()
        
        print("[EnhancedWebSocketClient] Connected successfully")
    }
    
    func disconnect() async {
        print("[EnhancedWebSocketClient] Disconnecting...")
        
        if let task = webSocketTask {
            task.cancel(with: .goingAway, reason: nil)
        }
        
        isTaskConnected = false
        webSocketTask = nil
        messageContinuation?.finish()
        messageContinuation = nil
        processedMessageContinuation?.finish()
        processedMessageContinuation = nil
        batchContinuation?.finish()
        batchContinuation = nil
        
        streamingMetrics.recordDisconnection()
        
        print("[EnhancedWebSocketClient] Disconnected")
    }
    
    func send(_ message: WebSocketMessage) async throws {
        guard let task = webSocketTask, isTaskConnected else {
            throw WebSocketError.notConnected
        }
        
        print("[EnhancedWebSocketClient] Sending message: \(message.type.rawValue)")
        
        do {
            let data = try JSONEncoder().encode(message)
            let urlMessage = URLSessionWebSocketTask.Message.data(data)
            try await task.send(urlMessage)
            
            streamingMetrics.recordSentMessage()
            print("[EnhancedWebSocketClient] Message sent successfully")
        } catch {
            streamingMetrics.recordSendError()
            print("[EnhancedWebSocketClient] Failed to send message: \(error)")
            throw WebSocketError.sendFailed(error)
        }
    }
    
    func messages() -> AsyncThrowingStream<WebSocketMessage, Error> {
        return AsyncThrowingStream<WebSocketMessage, Error> { continuation in
            self.messageContinuation = continuation
            
            continuation.onTermination = { @Sendable _ in
                print("[EnhancedWebSocketClient] Raw message stream terminated")
            }
            
            Task {
                await self.startListening(continuation: continuation)
            }
        }
    }
    
    // MARK: - Enhanced Processing Methods
    
    func processedMessages() -> AsyncThrowingStream<ProcessedMessage, Error> {
        return AsyncThrowingStream<ProcessedMessage, Error> { continuation in
            self.processedMessageContinuation = continuation
            
            continuation.onTermination = { @Sendable _ in
                print("[EnhancedWebSocketClient] Processed message stream terminated")
            }
            
            Task {
                await self.startProcessedMessageStream(continuation: continuation)
            }
        }
    }
    
    func batchProcessedMessages() -> AsyncThrowingStream<BatchProcessingResult, Error> {
        return AsyncThrowingStream<BatchProcessingResult, Error> { continuation in
            self.batchContinuation = continuation
            
            continuation.onTermination = { @Sendable _ in
                print("[EnhancedWebSocketClient] Batch message stream terminated")
            }
            
            Task {
                await self.startBatchProcessedMessageStream(continuation: continuation)
            }
        }
    }
    
    func configureBatchProcessing(enabled: Bool, batchSize: Int, batchInterval: TimeInterval) {
        print("[EnhancedWebSocketClient] Configuring batch processing: enabled=\(enabled), size=\(batchSize), interval=\(batchInterval)s")
        
        self.batchProcessingEnabled = enabled
        self.batchSize = batchSize
        self.batchInterval = batchInterval
        
        messageBatcher.configure(batchSize: batchSize, interval: batchInterval)
    }
    
    func getStreamingMetrics() -> StreamingMetrics {
        var metrics = streamingMetrics
        metrics.dataStreamProcessorMetrics = dataStreamProcessor.getProcessingMetrics()
        return metrics
    }
    
    // MARK: - Private Message Processing
    
    private func startListening(continuation: AsyncThrowingStream<WebSocketMessage, Error>.Continuation) async {
        print("[EnhancedWebSocketClient] Starting enhanced message listening...")
        
        while isTaskConnected, let task = webSocketTask {
            do {
                let urlMessage = try await task.receive()
                
                switch urlMessage {
                case .data(let data):
                    do {
                        let message = try JSONDecoder().decode(WebSocketMessage.self, from: data)
                        message.logReceived()
                        
                        streamingMetrics.recordReceivedMessage(size: data.count)
                        continuation.yield(message)
                        
                    } catch {
                        print("[EnhancedWebSocketClient] Failed to decode message: \(error)")
                        streamingMetrics.recordReceiveError()
                        continuation.yield(with: .failure(WebSocketError.decodingFailed(error)))
                    }
                    
                case .string(let text):
                    print("[EnhancedWebSocketClient] Received text message: \(text)")
                    if let data = text.data(using: .utf8) {
                        do {
                            let message = try JSONDecoder().decode(WebSocketMessage.self, from: data)
                            message.logReceived()
                            
                            streamingMetrics.recordReceivedMessage(size: data.count)
                            continuation.yield(message)
                            
                        } catch {
                            print("[EnhancedWebSocketClient] Failed to decode text message: \(error)")
                            streamingMetrics.recordReceiveError()
                            continuation.yield(with: .failure(WebSocketError.decodingFailed(error)))
                        }
                    }
                    
                @unknown default:
                    print("[EnhancedWebSocketClient] Unknown message type received")
                }
                
            } catch {
                print("[EnhancedWebSocketClient] Error receiving message: \(error)")
                streamingMetrics.recordReceiveError()
                
                if (error as NSError).code == NSURLErrorCancelled {
                    print("[EnhancedWebSocketClient] Connection was cancelled")
                } else {
                    continuation.yield(with: .failure(WebSocketError.receiveFailed(error)))
                }
                break
            }
        }
        
        print("[EnhancedWebSocketClient] Enhanced message listening stopped")
    }
    
    private func startProcessedMessageStream(continuation: AsyncThrowingStream<ProcessedMessage, Error>.Continuation) async {
        print("[EnhancedWebSocketClient] Starting processed message stream...")
        
        for await message in messages() {
            do {
                let result = await dataStreamProcessor.processMessage(message)
                
                if let processedMessage = result.processedMessage {
                    continuation.yield(processedMessage)
                } else if let error = result.error {
                    print("[EnhancedWebSocketClient] Message processing failed: \(error)")
                    // Don't terminate stream for processing errors, just log them
                }
                
            } catch {
                print("[EnhancedWebSocketClient] Error in processed message stream: \(error)")
                continuation.yield(with: .failure(error))
                break
            }
        }
    }
    
    private func startBatchProcessedMessageStream(continuation: AsyncThrowingStream<BatchProcessingResult, Error>.Continuation) async {
        guard batchProcessingEnabled else {
            print("[EnhancedWebSocketClient] Batch processing disabled")
            return
        }
        
        print("[EnhancedWebSocketClient] Starting batch processed message stream...")
        
        for await batch in messageBatcher.batches() {
            do {
                let batchResult = await dataStreamProcessor.processMessageBatch(batch)
                continuation.yield(batchResult)
                
                streamingMetrics.recordBatchProcessing(
                    messageCount: batch.count,
                    successCount: batchResult.successCount
                )
                
            } catch {
                print("[EnhancedWebSocketClient] Error in batch processing: \(error)")
                continuation.yield(with: .failure(error))
                break
            }
        }
    }
}

// MARK: - Message Batcher

private class MessageBatcher {
    private var batchSize: Int
    private var batchInterval: TimeInterval
    private var currentBatch: [WebSocketMessage] = []
    private var batchTimer: Task<Void, Never>?
    private var continuation: AsyncThrowingStream<[WebSocketMessage], Error>.Continuation?
    
    init(batchSize: Int, interval: TimeInterval) {
        self.batchSize = batchSize
        self.batchInterval = interval
    }
    
    func configure(batchSize: Int, interval: TimeInterval) {
        self.batchSize = batchSize
        self.batchInterval = interval
        
        // Restart timer if configuration changes
        batchTimer?.cancel()
        startBatchTimer()
    }
    
    func batches() -> AsyncThrowingStream<[WebSocketMessage], Error> {
        return AsyncThrowingStream<[WebSocketMessage], Error> { continuation in
            self.continuation = continuation
            
            continuation.onTermination = { @Sendable _ in
                print("[MessageBatcher] Batch stream terminated")
            }
            
            startBatchTimer()
        }
    }
    
    func addMessage(_ message: WebSocketMessage) {
        currentBatch.append(message)
        
        if currentBatch.count >= batchSize {
            flushBatch()
        }
    }
    
    private func startBatchTimer() {
        batchTimer = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(batchInterval * 1_000_000_000))
                
                if !currentBatch.isEmpty {
                    flushBatch()
                }
            }
        }
    }
    
    private func flushBatch() {
        guard !currentBatch.isEmpty else { return }
        
        let batch = currentBatch
        currentBatch.removeAll()
        
        continuation?.yield(batch)
    }
}

// MARK: - Streaming Metrics

struct StreamingMetrics {
    private(set) var connectionCount: Int = 0
    private(set) var disconnectionCount: Int = 0
    private(set) var messagesReceived: Int = 0
    private(set) var messagesSent: Int = 0
    private(set) var bytesReceived: Int = 0
    private(set) var bytesSent: Int = 0
    private(set) var receiveErrors: Int = 0
    private(set) var sendErrors: Int = 0
    private(set) var batchesProcessed: Int = 0
    private(set) var totalBatchMessages: Int = 0
    private(set) var connectionUptime: TimeInterval = 0
    
    var dataStreamProcessorMetrics: StreamProcessingMetrics?
    
    private var lastConnectionTime: Date?
    
    var averageBatchSize: Double {
        return batchesProcessed > 0 ? Double(totalBatchMessages) / Double(batchesProcessed) : 0
    }
    
    var messageReceiveRate: Double {
        return connectionUptime > 0 ? Double(messagesReceived) / connectionUptime : 0
    }
    
    var errorRate: Double {
        let totalMessages = messagesReceived + messagesSent
        let totalErrors = receiveErrors + sendErrors
        return totalMessages > 0 ? Double(totalErrors) / Double(totalMessages) : 0
    }
    
    mutating func recordConnection() {
        connectionCount += 1
        lastConnectionTime = Date()
    }
    
    mutating func recordDisconnection() {
        disconnectionCount += 1
        if let lastConnection = lastConnectionTime {
            connectionUptime += Date().timeIntervalSince(lastConnection)
        }
        lastConnectionTime = nil
    }
    
    mutating func recordReceivedMessage(size: Int) {
        messagesReceived += 1
        bytesReceived += size
    }
    
    mutating func recordSentMessage() {
        messagesSent += 1
    }
    
    mutating func recordReceiveError() {
        receiveErrors += 1
    }
    
    mutating func recordSendError() {
        sendErrors += 1
    }
    
    mutating func recordBatchProcessing(messageCount: Int, successCount: Int) {
        batchesProcessed += 1
        totalBatchMessages += messageCount
    }
    
    func debugDescription() -> String {
        return """
        [StreamingMetrics]
        Connections: \(connectionCount) (Disconnections: \(disconnectionCount))
        Messages: Received \(messagesReceived), Sent \(messagesSent)
        Data: \(bytesReceived) bytes received, \(bytesSent) bytes sent
        Errors: \(receiveErrors) receive, \(sendErrors) send (Rate: \(String(format: "%.2f%%", errorRate * 100)))
        Batches: \(batchesProcessed) processed, avg size: \(String(format: "%.1f", averageBatchSize))
        Performance: \(String(format: "%.1f", messageReceiveRate)) messages/sec
        Uptime: \(String(format: "%.1f", connectionUptime))s
        """
    }
}