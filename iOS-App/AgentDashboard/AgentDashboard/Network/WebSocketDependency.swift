//
//  WebSocketDependency.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  TCA dependency registration for WebSocket client
//

import Foundation
import Dependencies

// MARK: - WebSocket Dependency Key

private enum WebSocketClientKey: DependencyKey {
    static let liveValue: WebSocketClientProtocol = {
        // Default to localhost for development
        // This should be configurable in production
        let url = URL(string: "ws://localhost:8080/ws")!
        return EnhancedWebSocketClient(url: url)
    }()
    
    static let testValue: WebSocketClientProtocol = MockEnhancedWebSocketClient()
    
    static let previewValue: WebSocketClientProtocol = MockEnhancedWebSocketClient()
}

// MARK: - Enhanced WebSocket Dependency Key

private enum EnhancedWebSocketClientKey: DependencyKey {
    static let liveValue: EnhancedWebSocketClientProtocol = {
        let url = URL(string: "ws://localhost:8080/ws")!
        return EnhancedWebSocketClient(url: url)
    }()
    
    static let testValue: EnhancedWebSocketClientProtocol = MockEnhancedWebSocketClient()
    
    static let previewValue: EnhancedWebSocketClientProtocol = MockEnhancedWebSocketClient()
}

// MARK: - Dependency Registration

extension DependencyValues {
    var webSocketClient: WebSocketClientProtocol {
        get { self[WebSocketClientKey.self] }
        set { self[WebSocketClientKey.self] = newValue }
    }
    
    var enhancedWebSocketClient: EnhancedWebSocketClientProtocol {
        get { self[EnhancedWebSocketClientKey.self] }
        set { self[EnhancedWebSocketClientKey.self] = newValue }
    }
}

// MARK: - Mock WebSocket Client for Testing

final class MockWebSocketClient: WebSocketClientProtocol {
    private var _isConnected = false
    private var messageStream: AsyncThrowingStream<WebSocketMessage, Error>?
    private var messageContinuation: AsyncThrowingStream<WebSocketMessage, Error>.Continuation?
    
    var isConnected: Bool {
        get async { _isConnected }
    }
    
    func connect() async throws {
        print("[MockWebSocketClient] Connecting...")
        _isConnected = true
        
        // Simulate connection delay
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        print("[MockWebSocketClient] Connected")
    }
    
    func disconnect() async {
        print("[MockWebSocketClient] Disconnecting...")
        _isConnected = false
        messageContinuation?.finish()
        messageContinuation = nil
        print("[MockWebSocketClient] Disconnected")
    }
    
    func send(_ message: WebSocketMessage) async throws {
        guard _isConnected else {
            throw WebSocketError.notConnected
        }
        
        print("[MockWebSocketClient] Sending message: \(message.type.rawValue)")
        
        // Simulate send delay
        try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
    }
    
    func messages() -> AsyncThrowingStream<WebSocketMessage, Error> {
        return AsyncThrowingStream<WebSocketMessage, Error> { continuation in
            self.messageContinuation = continuation
            
            continuation.onTermination = { @Sendable _ in
                print("[MockWebSocketClient] Message stream terminated")
            }
            
            // Start sending mock messages
            Task {
                await self.sendMockMessages(continuation: continuation)
            }
        }
    }
    
    private func sendMockMessages(continuation: AsyncThrowingStream<WebSocketMessage, Error>.Continuation) async {
        print("[MockWebSocketClient] Starting mock message stream...")
        
        var counter = 0
        
        while _isConnected && counter < 100 { // Limit mock messages
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            if !_isConnected {
                break
            }
            
            counter += 1
            
            // Send different types of mock messages
            switch counter % 4 {
            case 0:
                // System status update
                let systemStatus = SystemStatus(
                    timestamp: Date(),
                    isHealthy: true,
                    cpuUsage: Double.random(in: 10...80),
                    memoryUsage: Double.random(in: 30...70),
                    diskUsage: Double.random(in: 20...60),
                    activeAgents: Int.random(in: 3...8),
                    totalModules: 12,
                    uptime: Double(counter * 30)
                )
                
                if let data = try? JSONEncoder().encode(systemStatus) {
                    let message = WebSocketMessage(
                        id: UUID(),
                        type: .systemMetrics,
                        payload: data,
                        timestamp: Date()
                    )
                    continuation.yield(message)
                }
                
            case 1:
                // Agent status update
                let agent = Agent(
                    id: UUID(),
                    name: "Mock Agent \(counter)",
                    type: .orchestrator,
                    status: [AgentStatus.idle, .running, .paused].randomElement()!,
                    description: "Mock agent for testing",
                    startTime: Date().addingTimeInterval(-Double(counter * 60)),
                    lastActivity: Date(),
                    resourceUsage: ResourceUsage(cpu: Double.random(in: 5...25), memory: Double.random(in: 10...50), threads: Int.random(in: 1...8), handles: Int.random(in: 10...100)),
                    configuration: ["key": "value"]
                )
                
                if let data = try? JSONEncoder().encode(agent) {
                    let message = WebSocketMessage(
                        id: UUID(),
                        type: .agentStatus,
                        payload: data,
                        timestamp: Date()
                    )
                    continuation.yield(message)
                }
                
            case 2:
                // Terminal output
                let output = "Mock terminal output line \(counter)"
                if let data = output.data(using: .utf8) {
                    let message = WebSocketMessage(
                        id: UUID(),
                        type: .terminalOutput,
                        payload: data,
                        timestamp: Date()
                    )
                    continuation.yield(message)
                }
                
            default:
                // Heartbeat
                let heartbeat = ["status": "alive", "timestamp": "\(Date())"]
                if let data = try? JSONEncoder().encode(heartbeat) {
                    let message = WebSocketMessage(
                        id: UUID(),
                        type: .heartbeat,
                        payload: data,
                        timestamp: Date()
                    )
                    continuation.yield(message)
                }
            }
        }
        
        print("[MockWebSocketClient] Mock message stream ended")
    }
}

// MARK: - Mock Enhanced WebSocket Client for Testing

final class MockEnhancedWebSocketClient: WebSocketClientProtocol, EnhancedWebSocketClientProtocol {
    private var _isConnected = false
    private var messageContinuation: AsyncThrowingStream<WebSocketMessage, Error>.Continuation?
    private var processedMessageContinuation: AsyncThrowingStream<ProcessedMessage, Error>.Continuation?
    private var batchContinuation: AsyncThrowingStream<BatchProcessingResult, Error>.Continuation?
    private var mockMetrics = StreamingMetrics()
    
    var isConnected: Bool {
        get async { _isConnected }
    }
    
    func connect() async throws {
        print("[MockEnhancedWebSocketClient] Connecting...")
        _isConnected = true
        mockMetrics.recordConnection()
        try await Task.sleep(nanoseconds: 100_000_000)
        print("[MockEnhancedWebSocketClient] Connected")
    }
    
    func disconnect() async {
        print("[MockEnhancedWebSocketClient] Disconnecting...")
        _isConnected = false
        mockMetrics.recordDisconnection()
        messageContinuation?.finish()
        processedMessageContinuation?.finish()
        batchContinuation?.finish()
        messageContinuation = nil
        processedMessageContinuation = nil
        batchContinuation = nil
        print("[MockEnhancedWebSocketClient] Disconnected")
    }
    
    func send(_ message: WebSocketMessage) async throws {
        guard _isConnected else {
            throw WebSocketError.notConnected
        }
        
        print("[MockEnhancedWebSocketClient] Sending message: \(message.type.rawValue)")
        mockMetrics.recordSentMessage()
        try await Task.sleep(nanoseconds: 50_000_000)
    }
    
    func messages() -> AsyncThrowingStream<WebSocketMessage, Error> {
        return AsyncThrowingStream<WebSocketMessage, Error> { continuation in
            self.messageContinuation = continuation
            
            continuation.onTermination = { @Sendable _ in
                print("[MockEnhancedWebSocketClient] Message stream terminated")
            }
            
            Task {
                await self.sendMockMessages(continuation: continuation)
            }
        }
    }
    
    func processedMessages() -> AsyncThrowingStream<ProcessedMessage, Error> {
        return AsyncThrowingStream<ProcessedMessage, Error> { continuation in
            self.processedMessageContinuation = continuation
            
            continuation.onTermination = { @Sendable _ in
                print("[MockEnhancedWebSocketClient] Processed message stream terminated")
            }
            
            Task {
                await self.sendMockProcessedMessages(continuation: continuation)
            }
        }
    }
    
    func batchProcessedMessages() -> AsyncThrowingStream<BatchProcessingResult, Error> {
        return AsyncThrowingStream<BatchProcessingResult, Error> { continuation in
            self.batchContinuation = continuation
            
            continuation.onTermination = { @Sendable _ in
                print("[MockEnhancedWebSocketClient] Batch message stream terminated")
            }
            
            Task {
                await self.sendMockBatchResults(continuation: continuation)
            }
        }
    }
    
    func configureBatchProcessing(enabled: Bool, batchSize: Int, batchInterval: TimeInterval) {
        print("[MockEnhancedWebSocketClient] Configuring batch processing: enabled=\(enabled), size=\(batchSize), interval=\(batchInterval)s")
    }
    
    func getStreamingMetrics() -> StreamingMetrics {
        return mockMetrics
    }
    
    // MARK: - Mock Message Generation
    
    private func sendMockMessages(continuation: AsyncThrowingStream<WebSocketMessage, Error>.Continuation) async {
        print("[MockEnhancedWebSocketClient] Starting enhanced mock message stream...")
        
        var counter = 0
        
        while _isConnected && counter < 50 {
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
            if !_isConnected { break }
            
            counter += 1
            
            let message = createMockMessage(counter: counter)
            mockMetrics.recordReceivedMessage(size: message.payload.count)
            continuation.yield(message)
        }
        
        print("[MockEnhancedWebSocketClient] Mock message stream ended")
    }
    
    private func sendMockProcessedMessages(continuation: AsyncThrowingStream<ProcessedMessage, Error>.Continuation) async {
        print("[MockEnhancedWebSocketClient] Starting mock processed message stream...")
        
        var counter = 0
        
        while _isConnected && counter < 40 {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            if !_isConnected { break }
            
            counter += 1
            
            let originalMessage = createMockMessage(counter: counter)
            let processedMessage = ProcessedMessage(
                originalMessage: originalMessage,
                validatedPayload: nil,
                transformedData: createMockTransformedData(for: originalMessage),
                processingTime: Double.random(in: 0.01...0.05),
                priority: [.low, .normal, .high].randomElement()!,
                metadata: [
                    "messageId": originalMessage.id.uuidString,
                    "processingTime": Date(),
                    "mockGenerated": true
                ]
            )
            
            continuation.yield(processedMessage)
        }
    }
    
    private func sendMockBatchResults(continuation: AsyncThrowingStream<BatchProcessingResult, Error>.Continuation) async {
        print("[MockEnhancedWebSocketClient] Starting mock batch results stream...")
        
        var counter = 0
        
        while _isConnected && counter < 20 {
            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
            
            if !_isConnected { break }
            
            counter += 1
            
            let batchSize = Int.random(in: 5...15)
            var processedMessages: [ProcessedMessage] = []
            
            for i in 0..<batchSize {
                let originalMessage = createMockMessage(counter: counter * 10 + i)
                let processedMessage = ProcessedMessage(
                    originalMessage: originalMessage,
                    validatedPayload: nil,
                    transformedData: createMockTransformedData(for: originalMessage),
                    processingTime: Double.random(in: 0.01...0.03),
                    priority: [.low, .normal, .high].randomElement()!,
                    metadata: ["batchId": "\(counter)"]
                )
                processedMessages.append(processedMessage)
            }
            
            let batchResult = BatchProcessingResult(
                processed: processedMessages,
                failed: [], // No failures in mock
                filtered: Int.random(in: 0...2),
                totalProcessingTime: Double.random(in: 0.1...0.3)
            )
            
            mockMetrics.recordBatchProcessing(messageCount: batchSize, successCount: batchSize)
            continuation.yield(batchResult)
        }
    }
    
    private func createMockMessage(counter: Int) -> WebSocketMessage {
        let messageTypes: [WebSocketMessage.MessageType] = [.systemMetrics, .agentStatus, .terminalOutput, .alert, .heartbeat]
        let messageType = messageTypes[counter % messageTypes.count]
        
        let payload: Data
        switch messageType {
        case .systemMetrics:
            let systemStatus = SystemStatus(
                timestamp: Date(),
                isHealthy: Bool.random(),
                cpuUsage: Double.random(in: 10...90),
                memoryUsage: Double.random(in: 20...80),
                diskUsage: Double.random(in: 30...70),
                activeAgents: Int.random(in: 1...8),
                totalModules: 12,
                uptime: Double(counter * 30)
            )
            payload = (try? JSONEncoder().encode(systemStatus)) ?? Data()
            
        case .agentStatus:
            let agent = Agent(
                id: UUID(),
                name: "Mock Agent \(counter)",
                type: AgentType.allCases.randomElement()!,
                status: AgentStatus.allCases.randomElement()!,
                description: "Enhanced mock agent for testing",
                startTime: Date().addingTimeInterval(-Double(counter * 60)),
                lastActivity: Date(),
                resourceUsage: ResourceUsage(
                    cpu: Double.random(in: 5...30),
                    memory: Double.random(in: 10...60),
                    threads: Int.random(in: 1...10),
                    handles: Int.random(in: 10...150)
                ),
                configuration: ["mockAgent": "true", "id": "\(counter)"]
            )
            payload = (try? JSONEncoder().encode(agent)) ?? Data()
            
        case .alert:
            let alert = Alert(
                id: UUID(),
                title: "Mock Alert \(counter)",
                message: "This is a mock alert message for testing enhanced functionality.",
                severity: Alert.Severity.allCases.randomElement()!,
                timestamp: Date(),
                source: "MockEnhancedClient"
            )
            payload = (try? JSONEncoder().encode(alert)) ?? Data()
            
        case .terminalOutput:
            let output = "Enhanced mock terminal output line \(counter) with additional details"
            payload = output.data(using: .utf8) ?? Data()
            
        case .heartbeat:
            let heartbeat = [
                "status": "alive",
                "timestamp": "\(Date())",
                "enhanced": true,
                "counter": counter
            ] as [String : Any]
            payload = (try? JSONSerialization.data(withJSONObject: heartbeat)) ?? Data()
        }
        
        return WebSocketMessage(
            id: UUID(),
            type: messageType,
            payload: payload,
            timestamp: Date()
        )
    }
    
    private func createMockTransformedData(for message: WebSocketMessage) -> Any? {
        switch message.type {
        case .systemMetrics:
            return try? JSONDecoder().decode(SystemStatus.self, from: message.payload)
        case .agentStatus:
            return try? JSONDecoder().decode(Agent.self, from: message.payload)
        case .alert:
            return try? JSONDecoder().decode(Alert.self, from: message.payload)
        case .terminalOutput:
            return String(data: message.payload, encoding: .utf8)
        case .heartbeat:
            return try? JSONSerialization.jsonObject(with: message.payload, options: [])
        }
    }
}