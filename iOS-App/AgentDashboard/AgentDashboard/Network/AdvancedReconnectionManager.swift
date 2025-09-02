//
//  AdvancedReconnectionManager.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Advanced reconnection with exponential backoff, circuit breaker, and network monitoring
//

import Foundation
import Network
import Combine

// MARK: - Advanced Reconnection Manager

final class AdvancedReconnectionManager: ReconnectionManagerProtocol {
    
    // Core components
    private weak var webSocketClient: WebSocketClientProtocol?
    private let backoffManager: ExponentialBackoffManager
    private let circuitBreaker: CircuitBreaker
    private let networkMonitor: NetworkPathMonitorProtocol
    
    // Configuration
    private let heartbeatInterval: TimeInterval
    private let connectionQualityThreshold: Double
    
    // State
    private var _connectionState: ConnectionState = .disconnected
    private var isReconnectionEnabled: Bool = true
    private var isMonitoring: Bool = false
    
    // Tasks and subscriptions
    private var reconnectionTask: Task<Void, Never>?
    private var heartbeatTask: Task<Void, Never>?
    private var networkSubscription: AnyCancellable?
    
    // Metrics
    private var advancedMetrics = AdvancedReconnectionMetrics()
    
    // Thread safety
    private let stateQueue = DispatchQueue(label: "com.agentdashboard.advanced.reconnection")
    
    init(webSocketClient: WebSocketClientProtocol?,
         backoffStrategy: BackoffStrategy = .exponential(base: 1.0, multiplier: 2.0, maxDelay: 60.0),
         jitterStrategy: JitterStrategy = .full,
         heartbeatInterval: TimeInterval = 30.0,
         connectionQualityThreshold: Double = 50.0) {
        
        self.webSocketClient = webSocketClient
        self.backoffManager = ExponentialBackoffManager(strategy: backoffStrategy, jitterStrategy: jitterStrategy)
        self.circuitBreaker = CircuitBreaker()
        self.networkMonitor = NetworkPathMonitor()
        self.heartbeatInterval = heartbeatInterval
        self.connectionQualityThreshold = connectionQualityThreshold
        
        print("[AdvancedReconnectionManager] Initialized with heartbeat: \(heartbeatInterval)s, quality threshold: \(connectionQualityThreshold)")
        
        setupNetworkMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    var connectionState: ConnectionState {
        get async {
            return await withCheckedContinuation { continuation in
                stateQueue.async {
                    continuation.resume(returning: self._connectionState)
                }
            }
        }
    }
    
    var reconnectionMetrics: ReconnectionMetrics {
        return advancedMetrics.basicMetrics
    }
    
    func startMonitoring() {
        guard !isMonitoring else {
            print("[AdvancedReconnectionManager] Already monitoring")
            return
        }
        
        print("[AdvancedReconnectionManager] Starting advanced monitoring")
        isMonitoring = true
        
        // Start network monitoring
        networkMonitor.startMonitoring()
        
        // Start connection monitoring
        startConnectionMonitoring()
        
        // Start heartbeat monitoring
        startHeartbeatMonitoring()
        
        advancedMetrics.recordStart()
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        print("[AdvancedReconnectionManager] Stopping advanced monitoring")
        isMonitoring = false
        
        // Stop all tasks
        reconnectionTask?.cancel()
        heartbeatTask?.cancel()
        reconnectionTask = nil
        heartbeatTask = nil
        
        // Stop network monitoring
        networkMonitor.stopMonitoring()
        networkSubscription?.cancel()
        
        updateConnectionState(.disabled)
        advancedMetrics.recordStop()
    }
    
    func triggerReconnection() {
        guard isReconnectionEnabled else {
            print("[AdvancedReconnectionManager] Reconnection triggered but disabled")
            return
        }
        
        print("[AdvancedReconnectionManager] Manual reconnection triggered")
        
        // Reset backoff and circuit breaker for manual attempts
        backoffManager.reset()
        
        // Cancel any existing attempts
        reconnectionTask?.cancel()
        
        // Start immediate reconnection
        startAdvancedReconnection()
    }
    
    func setReconnectionEnabled(_ enabled: Bool) {
        print("[AdvancedReconnectionManager] Reconnection enabled: \(enabled)")
        isReconnectionEnabled = enabled
        
        if !enabled {
            reconnectionTask?.cancel()
            reconnectionTask = nil
        }
    }
    
    func getAdvancedMetrics() -> AdvancedReconnectionMetrics {
        return stateQueue.sync { advancedMetrics }
    }
    
    // MARK: - Private Implementation
    
    private func setupNetworkMonitoring() {
        networkSubscription = networkMonitor.networkStatusPublisher
            .sink { [weak self] networkStatus in
                self?.handleNetworkStatusChange(networkStatus)
            }
    }
    
    private func handleNetworkStatusChange(_ networkStatus: NetworkStatus) {
        print("[AdvancedReconnectionManager] Network status changed: \(networkStatus.description)")
        
        stateQueue.async {
            self.advancedMetrics.recordNetworkChange(networkStatus)
        }
        
        // Check if we should trigger reconnection based on network quality
        Task {
            let currentState = await connectionState
            let isConnected = await webSocketClient?.isConnected ?? false
            
            if networkStatus.isConnected && !isConnected && currentState != .connecting {
                // Network available but not connected - trigger reconnection
                if networkStatus.qualityScore >= connectionQualityThreshold {
                    print("[AdvancedReconnectionManager] Good network detected - triggering reconnection")
                    triggerReconnection()
                } else {
                    print("[AdvancedReconnectionManager] Poor network quality (\(String(format: "%.0f", networkStatus.qualityScore))) - delaying reconnection")
                }
            } else if !networkStatus.isConnected && isConnected {
                // Network lost - connection will be detected by heartbeat
                print("[AdvancedReconnectionManager] Network lost - heartbeat will detect connection failure")
            }
        }
    }
    
    private func startConnectionMonitoring() {
        reconnectionTask = Task {
            await monitorConnectionHealth()
        }
    }
    
    private func startHeartbeatMonitoring() {
        heartbeatTask = Task {
            await performHeartbeatMonitoring()
        }
    }
    
    private func monitorConnectionHealth() async {
        print("[AdvancedReconnectionManager] Starting connection health monitoring")
        
        while !Task.isCancelled && isMonitoring {
            let isConnected = await webSocketClient?.isConnected ?? false
            let currentState = await connectionState
            
            if !isConnected && currentState.isConnected {
                print("[AdvancedReconnectionManager] Connection lost detected")
                updateConnectionState(.disconnected)
                
                if isReconnectionEnabled && circuitBreaker.canAttemptConnection() {
                    startAdvancedReconnection()
                }
            }
            
            // Check every 5 seconds
            try? await Task.sleep(nanoseconds: 5_000_000_000)
        }
    }
    
    private func performHeartbeatMonitoring() async {
        print("[AdvancedReconnectionManager] Starting heartbeat monitoring")
        
        while !Task.isCancelled && isMonitoring {
            let isConnected = await webSocketClient?.isConnected ?? false
            
            if isConnected {
                // Send heartbeat message
                let heartbeat = WebSocketMessage(
                    id: UUID(),
                    type: .heartbeat,
                    payload: Data("heartbeat".utf8),
                    timestamp: Date()
                )
                
                do {
                    try await webSocketClient?.send(heartbeat)
                    print("[AdvancedReconnectionManager] Heartbeat sent")
                    
                    stateQueue.async {
                        self.advancedMetrics.recordHeartbeatSent()
                    }
                    
                    circuitBreaker.recordSuccess()
                } catch {
                    print("[AdvancedReconnectionManager] Heartbeat failed: \(error)")
                    
                    stateQueue.async {
                        self.advancedMetrics.recordHeartbeatFailed()
                    }
                    
                    circuitBreaker.recordFailure()
                }
            }
            
            // Wait for heartbeat interval
            try? await Task.sleep(nanoseconds: UInt64(heartbeatInterval * 1_000_000_000))
        }
    }
    
    private func startAdvancedReconnection() {
        guard isReconnectionEnabled else { return }
        
        print("[AdvancedReconnectionManager] Starting advanced reconnection with backoff")
        
        reconnectionTask?.cancel()
        reconnectionTask = Task {
            await performAdvancedReconnectionAttempts()
        }
    }
    
    private func performAdvancedReconnectionAttempts() async {
        while !backoffManager.hasExceededMaxAttempts() && !Task.isCancelled && isReconnectionEnabled {
            
            // Check circuit breaker
            guard circuitBreaker.canAttemptConnection() else {
                print("[AdvancedReconnectionManager] Circuit breaker open - waiting for recovery")
                updateConnectionState(.failed(error: "Circuit breaker open"))
                
                // Wait for circuit breaker timeout
                try? await Task.sleep(nanoseconds: 60_000_000_000) // 60 seconds
                continue
            }
            
            // Check network quality before attempting
            let networkStatus = await networkMonitor.networkStatus
            guard networkStatus.isConnected else {
                print("[AdvancedReconnectionManager] No network available - waiting")
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                continue
            }
            
            guard networkStatus.qualityScore >= connectionQualityThreshold else {
                print("[AdvancedReconnectionManager] Network quality too low (\(String(format: "%.0f", networkStatus.qualityScore))) - waiting")
                try? await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
                continue
            }
            
            // Calculate delay with exponential backoff and jitter
            let delay = backoffManager.incrementAttempt()
            let attempt = backoffManager.currentAttempt
            
            print("[AdvancedReconnectionManager] Advanced reconnection attempt \(attempt) after \(String(format: "%.2fs", delay)) delay")
            
            updateConnectionState(.reconnecting(attempt: attempt))
            
            // Wait for calculated delay
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            
            // Attempt connection
            let attemptStartTime = Date()
            let success = await attemptAdvancedConnection()
            let attemptDuration = Date().timeIntervalSince(attemptStartTime)
            
            if success {
                print("[AdvancedReconnectionManager] Advanced reconnection successful after \(attempt) attempts")
                
                updateConnectionState(.connected)
                backoffManager.reset()
                circuitBreaker.recordSuccess()
                
                stateQueue.async {
                    self.advancedMetrics.recordSuccessfulReconnection(
                        attempt: attempt,
                        duration: attemptDuration,
                        networkQuality: networkStatus.qualityScore
                    )
                }
                
                return // Success - exit loop
            } else {
                print("[AdvancedReconnectionManager] Advanced reconnection attempt \(attempt) failed")
                
                circuitBreaker.recordFailure()
                
                stateQueue.async {
                    self.advancedMetrics.recordFailedReconnection(
                        attempt: attempt,
                        networkQuality: networkStatus.qualityScore
                    )
                }
            }
        }
        
        // All attempts failed
        if backoffManager.hasExceededMaxAttempts() {
            print("[AdvancedReconnectionManager] All advanced reconnection attempts failed")
            updateConnectionState(.failed(error: "Maximum attempts exceeded with exponential backoff"))
        }
    }
    
    private func attemptAdvancedConnection() async -> Bool {
        guard let client = webSocketClient else {
            print("[AdvancedReconnectionManager] No WebSocket client available")
            return false
        }
        
        print("[AdvancedReconnectionManager] Attempting advanced connection...")
        
        do {
            updateConnectionState(.connecting)
            
            try await client.connect()
            
            // Verify connection with a test message
            let testMessage = WebSocketMessage(
                id: UUID(),
                type: .heartbeat,
                payload: Data("connection_test".utf8),
                timestamp: Date()
            )
            
            try await client.send(testMessage)
            
            let isConnected = await client.isConnected
            
            if isConnected {
                print("[AdvancedReconnectionManager] Advanced connection successful and verified")
                return true
            } else {
                print("[AdvancedReconnectionManager] Advanced connection failed verification")
                return false
            }
            
        } catch {
            print("[AdvancedReconnectionManager] Advanced connection failed: \(error)")
            return false
        }
    }
    
    private func updateConnectionState(_ newState: ConnectionState) {
        stateQueue.async {
            let oldState = self._connectionState
            self._connectionState = newState
            
            print("[AdvancedReconnectionManager] Advanced state transition: \(oldState) -> \(newState)")
            
            self.advancedMetrics.recordStateChange(from: oldState, to: newState)
        }
    }
}

// MARK: - Advanced Reconnection Metrics

struct AdvancedReconnectionMetrics {
    private(set) var basicMetrics = ReconnectionMetrics()
    
    // Advanced metrics
    private(set) var heartbeatsSent: Int = 0
    private(set) var heartbeatsFailed: Int = 0
    private(set) var networkChanges: Int = 0
    private(set) var circuitBreakerTrips: Int = 0
    private(set) var backoffResets: Int = 0
    private(set) var qualityBasedDelays: Int = 0
    
    // Network quality tracking
    private(set) var averageNetworkQualityAtReconnection: Double = 0
    private(set) var reconnectionsOnHighQuality: Int = 0
    private(set) var reconnectionsOnLowQuality: Int = 0
    
    // State tracking
    private(set) var stateChanges: [String: Int] = [:]
    private(set) var timeInStates: [String: TimeInterval] = [:]
    private var lastStateChangeTime: Date?
    
    private var totalNetworkQuality: Double = 0
    private var networkQualityMeasurements: Int = 0
    
    var heartbeatSuccessRate: Double {
        let total = heartbeatsSent
        let failed = heartbeatsFailed
        return total > 0 ? Double(total - failed) / Double(total) : 0
    }
    
    var highQualityReconnectionRate: Double {
        let total = reconnectionsOnHighQuality + reconnectionsOnLowQuality
        return total > 0 ? Double(reconnectionsOnHighQuality) / Double(total) : 0
    }
    
    mutating func recordStart() {
        lastStateChangeTime = Date()
    }
    
    mutating func recordStop() {
        lastStateChangeTime = nil
    }
    
    mutating func recordSuccessfulReconnection(attempt: Int, duration: TimeInterval, networkQuality: Double) {
        basicMetrics.recordReconnectionSuccess(duration: duration)
        
        // Track network quality
        totalNetworkQuality += networkQuality
        networkQualityMeasurements += 1
        averageNetworkQualityAtReconnection = totalNetworkQuality / Double(networkQualityMeasurements)
        
        if networkQuality >= 75 {
            reconnectionsOnHighQuality += 1
        } else {
            reconnectionsOnLowQuality += 1
        }
    }
    
    mutating func recordFailedReconnection(attempt: Int, networkQuality: Double) {
        basicMetrics.recordReconnectionFailure()
        
        if networkQuality < 50 {
            qualityBasedDelays += 1
        }
    }
    
    mutating func recordHeartbeatSent() {
        heartbeatsSent += 1
    }
    
    mutating func recordHeartbeatFailed() {
        heartbeatsFailed += 1
    }
    
    mutating func recordNetworkChange(_ networkStatus: NetworkStatus) {
        networkChanges += 1
    }
    
    mutating func recordStateChange(from oldState: ConnectionState, to newState: ConnectionState) {
        let transition = "\(oldState.description) -> \(newState.description)"
        stateChanges[transition, default: 0] += 1
        
        // Track time in previous state
        if let lastChange = lastStateChangeTime {
            let timeInState = Date().timeIntervalSince(lastChange)
            timeInStates[oldState.description, default: 0] += timeInState
        }
        
        lastStateChangeTime = Date()
    }
    
    func debugDescription() -> String {
        return """
        [AdvancedReconnectionMetrics]
        \(basicMetrics.debugDescription())
        
        Advanced Metrics:
        Heartbeats: \(heartbeatsSent) sent, \(heartbeatsFailed) failed (\(String(format: "%.1f%%", heartbeatSuccessRate * 100)) success)
        Network Changes: \(networkChanges)
        Circuit Breaker Trips: \(circuitBreakerTrips)
        Quality-based Delays: \(qualityBasedDelays)
        Avg Network Quality at Reconnect: \(String(format: "%.1f", averageNetworkQualityAtReconnection))
        High Quality Reconnections: \(String(format: "%.1f%%", highQualityReconnectionRate * 100))
        
        State Transitions: \(stateChanges)
        Time in States: \(timeInStates.mapValues { String(format: "%.1fs", $0) })
        """
    }
}