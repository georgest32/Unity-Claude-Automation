//
//  ReconnectionManager.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Basic reconnection logic with automatic retry and connection state tracking
//

import Foundation
import Combine

// MARK: - Reconnection Manager Protocol

protocol ReconnectionManagerProtocol {
    func startMonitoring()
    func stopMonitoring()
    func triggerReconnection()
    func setReconnectionEnabled(_ enabled: Bool)
    var connectionState: ConnectionState { get async }
    var reconnectionMetrics: ReconnectionMetrics { get }
}

// MARK: - Connection State

enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case reconnecting(attempt: Int)
    case failed(error: String)
    case disabled
    
    var isConnected: Bool {
        switch self {
        case .connected: return true
        default: return false
        }
    }
    
    var isAttemptingConnection: Bool {
        switch self {
        case .connecting, .reconnecting: return true
        default: return false
        }
    }
}

// MARK: - Reconnection Metrics

struct ReconnectionMetrics {
    private(set) var totalReconnectionAttempts: Int = 0
    private(set) var successfulReconnections: Int = 0
    private(set) var failedReconnections: Int = 0
    private(set) var averageReconnectionTime: TimeInterval = 0
    private(set) var longestDowntime: TimeInterval = 0
    private(set) var totalDowntime: TimeInterval = 0
    private(set) var lastReconnectionTime: Date?
    
    private var totalReconnectionTime: TimeInterval = 0
    private var currentDowntimeStart: Date?
    
    var successRate: Double {
        let total = successfulReconnections + failedReconnections
        return total > 0 ? Double(successfulReconnections) / Double(total) : 0
    }
    
    mutating func recordReconnectionAttempt() {
        totalReconnectionAttempts += 1
    }
    
    mutating func recordReconnectionSuccess(duration: TimeInterval) {
        successfulReconnections += 1
        totalReconnectionTime += duration
        averageReconnectionTime = totalReconnectionTime / Double(successfulReconnections)
        lastReconnectionTime = Date()
        
        // Record downtime if we were tracking it
        if let downtimeStart = currentDowntimeStart {
            let downtime = Date().timeIntervalSince(downtimeStart)
            totalDowntime += downtime
            longestDowntime = max(longestDowntime, downtime)
            currentDowntimeStart = nil
        }
    }
    
    mutating func recordReconnectionFailure() {
        failedReconnections += 1
    }
    
    mutating func recordDisconnection() {
        currentDowntimeStart = Date()
    }
    
    func debugDescription() -> String {
        return """
        [ReconnectionMetrics]
        Total Attempts: \(totalReconnectionAttempts)
        Successful: \(successfulReconnections)
        Failed: \(failedReconnections)
        Success Rate: \(String(format: "%.1f%%", successRate * 100))
        Avg Reconnection Time: \(String(format: "%.2fs", averageReconnectionTime))
        Total Downtime: \(String(format: "%.1fs", totalDowntime))
        Longest Downtime: \(String(format: "%.1fs", longestDowntime))
        Last Reconnection: \(lastReconnectionTime?.description ?? "Never")
        """
    }
}

// MARK: - Basic Reconnection Manager

final class ReconnectionManager: ReconnectionManagerProtocol {
    
    // Dependencies
    private weak var webSocketClient: WebSocketClientProtocol?
    
    // Configuration
    private let basicRetryInterval: TimeInterval
    private let maxRetryAttempts: Int
    private let connectionTimeout: TimeInterval
    
    // State
    private var _connectionState: ConnectionState = .disconnected
    private var reconnectionMetrics = ReconnectionMetrics()
    private var isReconnectionEnabled: Bool = true
    private var currentAttempt: Int = 0
    
    // Tasks and timers
    private var reconnectionTask: Task<Void, Never>?
    private var connectionMonitorTask: Task<Void, Never>?
    
    // Thread safety
    private let stateQueue = DispatchQueue(label: "com.agentdashboard.reconnection.state")
    
    init(webSocketClient: WebSocketClientProtocol?,
         basicRetryInterval: TimeInterval = 5.0,
         maxRetryAttempts: Int = 5,
         connectionTimeout: TimeInterval = 30.0) {
        self.webSocketClient = webSocketClient
        self.basicRetryInterval = basicRetryInterval
        self.maxRetryAttempts = maxRetryAttempts
        self.connectionTimeout = connectionTimeout
        
        print("[ReconnectionManager] Initialized with retry interval: \(basicRetryInterval)s, max attempts: \(maxRetryAttempts)")
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
        return stateQueue.sync { reconnectionMetrics }
    }
    
    func startMonitoring() {
        print("[ReconnectionManager] Starting connection monitoring")
        
        connectionMonitorTask = Task {
            await monitorConnection()
        }
    }
    
    func stopMonitoring() {
        print("[ReconnectionManager] Stopping connection monitoring")
        
        reconnectionTask?.cancel()
        connectionMonitorTask?.cancel()
        reconnectionTask = nil
        connectionMonitorTask = nil
        
        updateConnectionState(.disabled)
    }
    
    func triggerReconnection() {
        guard isReconnectionEnabled else {
            print("[ReconnectionManager] Reconnection triggered but disabled")
            return
        }
        
        print("[ReconnectionManager] Manual reconnection triggered")
        
        // Cancel any existing reconnection attempts
        reconnectionTask?.cancel()
        
        // Reset attempt counter for manual triggers
        currentAttempt = 0
        
        // Start reconnection
        startReconnection()
    }
    
    func setReconnectionEnabled(_ enabled: Bool) {
        print("[ReconnectionManager] Reconnection enabled: \(enabled)")
        isReconnectionEnabled = enabled
        
        if !enabled {
            reconnectionTask?.cancel()
            reconnectionTask = nil
        }
    }
    
    // MARK: - Private Implementation
    
    private func monitorConnection() async {
        print("[ReconnectionManager] Starting connection monitoring loop")
        
        while !Task.isCancelled {
            // Check connection status
            let isConnected = await webSocketClient?.isConnected ?? false
            let currentState = await connectionState
            
            // Update state based on actual connection
            if isConnected && currentState != .connected {
                print("[ReconnectionManager] Connection detected - updating state to connected")
                updateConnectionState(.connected)
            } else if !isConnected && currentState == .connected {
                print("[ReconnectionManager] Connection lost - triggering reconnection")
                updateConnectionState(.disconnected)
                
                stateQueue.async {
                    self.reconnectionMetrics.recordDisconnection()
                }
                
                if isReconnectionEnabled {
                    startReconnection()
                }
            }
            
            // Monitor every 2 seconds
            try? await Task.sleep(nanoseconds: 2_000_000_000)
        }
        
        print("[ReconnectionManager] Connection monitoring stopped")
    }
    
    private func startReconnection() {
        guard isReconnectionEnabled else { return }
        
        print("[ReconnectionManager] Starting basic reconnection logic")
        
        reconnectionTask = Task {
            await performReconnectionAttempts()
        }
    }
    
    private func performReconnectionAttempts() async {
        while currentAttempt < maxRetryAttempts && !Task.isCancelled && isReconnectionEnabled {
            currentAttempt += 1
            
            print("[ReconnectionManager] Reconnection attempt \(currentAttempt)/\(maxRetryAttempts)")
            
            updateConnectionState(.reconnecting(attempt: currentAttempt))
            
            stateQueue.async {
                self.reconnectionMetrics.recordReconnectionAttempt()
            }
            
            let attemptStartTime = Date()
            
            // Attempt connection with timeout
            let success = await attemptConnection()
            
            let attemptDuration = Date().timeIntervalSince(attemptStartTime)
            
            if success {
                print("[ReconnectionManager] Reconnection successful after \(currentAttempt) attempts")
                
                updateConnectionState(.connected)
                currentAttempt = 0 // Reset for next disconnection
                
                stateQueue.async {
                    self.reconnectionMetrics.recordReconnectionSuccess(duration: attemptDuration)
                }
                
                return // Success - exit reconnection loop
            } else {
                print("[ReconnectionManager] Reconnection attempt \(currentAttempt) failed")
                
                stateQueue.async {
                    self.reconnectionMetrics.recordReconnectionFailure()
                }
                
                // Wait before next attempt (basic fixed interval)
                if currentAttempt < maxRetryAttempts {
                    print("[ReconnectionManager] Waiting \(basicRetryInterval)s before next attempt")
                    try? await Task.sleep(nanoseconds: UInt64(basicRetryInterval * 1_000_000_000))
                }
            }
        }
        
        // If we reach here, all attempts failed
        if currentAttempt >= maxRetryAttempts {
            print("[ReconnectionManager] All reconnection attempts failed (\(maxRetryAttempts) attempts)")
            updateConnectionState(.failed(error: "Failed to reconnect after \(maxRetryAttempts) attempts"))
        }
        
        currentAttempt = 0 // Reset for manual retry
    }
    
    private func attemptConnection() async -> Bool {
        guard let client = webSocketClient else {
            print("[ReconnectionManager] No WebSocket client available")
            return false
        }
        
        print("[ReconnectionManager] Attempting connection...")
        
        do {
            // Attempt connection with timeout
            try await withThrowingTaskGroup(of: Void.self) { group in
                
                // Connection task
                group.addTask {
                    try await client.connect()
                }
                
                // Timeout task
                group.addTask {
                    try await Task.sleep(nanoseconds: UInt64(self.connectionTimeout * 1_000_000_000))
                    throw ReconnectionError.connectionTimeout
                }
                
                // Wait for first to complete
                try await group.next()
                group.cancelAll()
            }
            
            // Verify connection established
            let isConnected = await client.isConnected
            
            if isConnected {
                print("[ReconnectionManager] Connection attempt successful")
                return true
            } else {
                print("[ReconnectionManager] Connection attempt failed - not connected")
                return false
            }
            
        } catch {
            print("[ReconnectionManager] Connection attempt failed: \(error)")
            return false
        }
    }
    
    private func updateConnectionState(_ newState: ConnectionState) {
        stateQueue.async {
            let oldState = self._connectionState
            self._connectionState = newState
            
            print("[ReconnectionManager] State transition: \(oldState) -> \(newState)")
        }
    }
}

// MARK: - Reconnection Errors

enum ReconnectionError: Error, LocalizedError {
    case connectionTimeout
    case maxAttemptsReached
    case reconnectionDisabled
    case webSocketClientUnavailable
    
    var errorDescription: String? {
        switch self {
        case .connectionTimeout:
            return "Connection attempt timed out"
        case .maxAttemptsReached:
            return "Maximum reconnection attempts reached"
        case .reconnectionDisabled:
            return "Reconnection is disabled"
        case .webSocketClientUnavailable:
            return "WebSocket client is not available"
        }
    }
}

// MARK: - Helper Extensions

extension ConnectionState: CustomStringConvertible {
    var description: String {
        switch self {
        case .disconnected:
            return "disconnected"
        case .connecting:
            return "connecting"
        case .connected:
            return "connected"
        case .reconnecting(let attempt):
            return "reconnecting(attempt: \(attempt))"
        case .failed(let error):
            return "failed(\(error))"
        case .disabled:
            return "disabled"
        }
    }
}