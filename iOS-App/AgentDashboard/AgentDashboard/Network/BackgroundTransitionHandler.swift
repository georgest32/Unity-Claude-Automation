//
//  BackgroundTransitionHandler.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Handle background/foreground transitions for WebSocket connections with iOS limitations
//

import Foundation
import UIKit
import Combine

// MARK: - Background Transition Handler Protocol

protocol BackgroundTransitionHandlerProtocol {
    func configureBackgroundHandling()
    func handleWillEnterBackground()
    func handleDidEnterForeground()
    var backgroundTransitionMetrics: BackgroundTransitionMetrics { get }
}

// MARK: - Background Strategy

enum BackgroundStrategy {
    case disconnect           // Disconnect immediately on background
    case maintainBriefly     // Try to maintain for 3 minutes
    case scheduleReconnect   // Disconnect and schedule reconnection on foreground
    case pushNotificationFallback // Use push notifications for background updates
}

// MARK: - Background Transition Handler Implementation

final class BackgroundTransitionHandler: BackgroundTransitionHandlerProtocol {
    
    // Dependencies
    private weak var webSocketClient: WebSocketClientProtocol?
    private weak var reconnectionManager: ReconnectionManagerProtocol?
    
    // Configuration
    private let backgroundStrategy: BackgroundStrategy
    private let backgroundGracePeriod: TimeInterval = 180.0 // 3 minutes iOS limit
    
    // State
    private var isInBackground: Bool = false
    private var backgroundStartTime: Date?
    private var wasConnectedBeforeBackground: Bool = false
    
    // Tasks
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var backgroundGraceTask: Task<Void, Never>?
    
    // Notifications
    private var notificationSubscriptions: Set<AnyCancellable> = []
    
    // Metrics
    private var _backgroundTransitionMetrics = BackgroundTransitionMetrics()
    
    init(webSocketClient: WebSocketClientProtocol?,
         reconnectionManager: ReconnectionManagerProtocol?,
         backgroundStrategy: BackgroundStrategy = .scheduleReconnect) {
        
        self.webSocketClient = webSocketClient
        self.reconnectionManager = reconnectionManager
        self.backgroundStrategy = backgroundStrategy
        
        print("[BackgroundTransitionHandler] Initialized with strategy: \(backgroundStrategy)")
    }
    
    var backgroundTransitionMetrics: BackgroundTransitionMetrics {
        return _backgroundTransitionMetrics
    }
    
    func configureBackgroundHandling() {
        print("[BackgroundTransitionHandler] Configuring background handling")
        
        // Subscribe to app lifecycle notifications
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.handleWillEnterForeground()
            }
            .store(in: &notificationSubscriptions)
        
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.handleDidEnterBackground()
            }
            .store(in: &notificationSubscriptions)
        
        NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)
            .sink { [weak self] _ in
                self?.handleWillTerminate()
            }
            .store(in: &notificationSubscriptions)
    }
    
    func handleWillEnterBackground() {
        print("[BackgroundTransitionHandler] App entering background")
        
        isInBackground = true
        backgroundStartTime = Date()
        _backgroundTransitionMetrics.recordBackgroundEntry()
        
        Task {
            wasConnectedBeforeBackground = await webSocketClient?.isConnected ?? false
        }
        
        switch backgroundStrategy {
        case .disconnect:
            handleDisconnectStrategy()
        case .maintainBriefly:
            handleMaintainBrieflyStrategy()
        case .scheduleReconnect:
            handleScheduleReconnectStrategy()
        case .pushNotificationFallback:
            handlePushNotificationStrategy()
        }
    }
    
    func handleDidEnterForeground() {
        print("[BackgroundTransitionHandler] App entering foreground")
        
        let backgroundDuration = backgroundStartTime.map { Date().timeIntervalSince($0) } ?? 0
        
        isInBackground = false
        backgroundStartTime = nil
        
        _backgroundTransitionMetrics.recordForegroundEntry(backgroundDuration: backgroundDuration)
        
        // Clean up background task
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
        
        backgroundGraceTask?.cancel()
        backgroundGraceTask = nil
        
        // Handle reconnection based on strategy
        handleForegroundReconnection()
    }
    
    // MARK: - Strategy Implementations
    
    private func handleDisconnectStrategy() {
        print("[BackgroundTransitionHandler] Executing disconnect strategy")
        
        Task {
            await webSocketClient?.disconnect()
            print("[BackgroundTransitionHandler] Disconnected for background")
        }
    }
    
    private func handleMaintainBrieflyStrategy() {
        print("[BackgroundTransitionHandler] Executing maintain briefly strategy")
        
        // Request background time
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "WebSocket Maintenance") {
            print("[BackgroundTransitionHandler] Background task expiring - disconnecting")
            
            Task {
                await self.webSocketClient?.disconnect()
            }
            
            if self.backgroundTask != .invalid {
                UIApplication.shared.endBackgroundTask(self.backgroundTask)
                self.backgroundTask = .invalid
            }
        }
        
        // Set up grace period timer
        backgroundGraceTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(backgroundGracePeriod * 1_000_000_000))
            
            if !Task.isCancelled {
                print("[BackgroundTransitionHandler] Grace period expired - disconnecting")
                await webSocketClient?.disconnect()
                
                if backgroundTask != .invalid {
                    UIApplication.shared.endBackgroundTask(backgroundTask)
                    backgroundTask = .invalid
                }
            }
        }
    }
    
    private func handleScheduleReconnectStrategy() {
        print("[BackgroundTransitionHandler] Executing schedule reconnect strategy")
        
        // Gracefully disconnect
        Task {
            await webSocketClient?.disconnect()
            print("[BackgroundTransitionHandler] Disconnected - will reconnect on foreground")
        }
        
        // Stop reconnection attempts while in background
        reconnectionManager?.setReconnectionEnabled(false)
    }
    
    private func handlePushNotificationStrategy() {
        print("[BackgroundTransitionHandler] Executing push notification fallback strategy")
        
        // Disconnect WebSocket and rely on push notifications
        Task {
            await webSocketClient?.disconnect()
            print("[BackgroundTransitionHandler] Disconnected - using push notifications for background updates")
        }
        
        // TODO: Register for push notifications if not already registered
        // This would typically involve server-side coordination
    }
    
    private func handleForegroundReconnection() {
        print("[BackgroundTransitionHandler] Handling foreground reconnection")
        
        // Re-enable reconnection if it was disabled
        reconnectionManager?.setReconnectionEnabled(true)
        
        // Attempt reconnection if we were connected before background
        if wasConnectedBeforeBackground {
            print("[BackgroundTransitionHandler] Was connected before background - triggering reconnection")
            reconnectionManager?.triggerReconnection()
        } else {
            print("[BackgroundTransitionHandler] Was not connected before background - no reconnection needed")
        }
    }
    
    private func handleWillTerminate() {
        print("[BackgroundTransitionHandler] App terminating - cleaning up connections")
        
        // Clean shutdown
        Task {
            await webSocketClient?.disconnect()
        }
        
        reconnectionManager?.stopMonitoring()
        
        // Clean up background task
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
}

// MARK: - Background Transition Metrics

struct BackgroundTransitionMetrics {
    private(set) var backgroundEntries: Int = 0
    private(set) var foregroundEntries: Int = 0
    private(set) var totalBackgroundTime: TimeInterval = 0
    private(set) var averageBackgroundTime: TimeInterval = 0
    private(set) var longestBackgroundTime: TimeInterval = 0
    private(set) var reconnectionsAfterBackground: Int = 0
    private(set) var failedReconnectionsAfterBackground: Int = 0
    
    var backgroundReconnectionSuccessRate: Double {
        let total = reconnectionsAfterBackground + failedReconnectionsAfterBackground
        return total > 0 ? Double(reconnectionsAfterBackground) / Double(total) : 0
    }
    
    mutating func recordBackgroundEntry() {
        backgroundEntries += 1
    }
    
    mutating func recordForegroundEntry(backgroundDuration: TimeInterval) {
        foregroundEntries += 1
        totalBackgroundTime += backgroundDuration
        averageBackgroundTime = totalBackgroundTime / Double(foregroundEntries)
        longestBackgroundTime = max(longestBackgroundTime, backgroundDuration)
        
        print("[BackgroundTransitionMetrics] Background duration: \(String(format: "%.1fs", backgroundDuration))")
    }
    
    mutating func recordSuccessfulReconnectionAfterBackground() {
        reconnectionsAfterBackground += 1
    }
    
    mutating func recordFailedReconnectionAfterBackground() {
        failedReconnectionsAfterBackground += 1
    }
    
    func debugDescription() -> String {
        return """
        [BackgroundTransitionMetrics]
        Background Entries: \(backgroundEntries)
        Foreground Entries: \(foregroundEntries)
        Total Background Time: \(String(format: "%.1fs", totalBackgroundTime))
        Average Background Time: \(String(format: "%.1fs", averageBackgroundTime))
        Longest Background Time: \(String(format: "%.1fs", longestBackgroundTime))
        Reconnections After Background: \(reconnectionsAfterBackground)/\(reconnectionsAfterBackground + failedReconnectionsAfterBackground) (\(String(format: "%.1f%%", backgroundReconnectionSuccessRate * 100)))
        """
    }
}