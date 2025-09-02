//
//  RealTimeUpdateManager.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Real-time UI update management with batching and offline queuing
//

import Foundation
import ComposableArchitecture

// MARK: - Real-Time Update Manager Protocol

protocol RealTimeUpdateManagerProtocol {
    func startRealtimeUpdates() async
    func stopRealtimeUpdates()
    func configureUpdateFrequency(_ frequency: UpdateFrequency)
    func enableOfflineQueuing(_ enabled: Bool)
    func getQueuedUpdates() -> [QueuedUpdate]
    func clearQueue()
}

// MARK: - Update Configuration

enum UpdateFrequency {
    case realtime // Immediate processing
    case high     // 0.5 second batching
    case medium   // 1.0 second batching
    case low      // 2.0 second batching
    
    var batchInterval: TimeInterval {
        switch self {
        case .realtime: return 0.0
        case .high: return 0.5
        case .medium: return 1.0
        case .low: return 2.0
        }
    }
}

struct QueuedUpdate {
    let id: UUID
    let feature: FeatureTarget
    let action: Any
    let timestamp: Date
    let priority: UpdatePriority
    let retryCount: Int
    
    enum FeatureTarget {
        case dashboard
        case agents
        case terminal
        case analytics
        case settings
        case global
    }
    
    enum UpdatePriority: Int, Comparable {
        case low = 0
        case normal = 1
        case high = 2
        case critical = 3
        
        static func < (lhs: UpdatePriority, rhs: UpdatePriority) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    }
}

// MARK: - Real-Time Update Manager Implementation

final class RealTimeUpdateManager: RealTimeUpdateManagerProtocol {
    
    // Dependencies
    private let store: StoreOf<AppFeature>
    private let enhancedWebSocketClient: EnhancedWebSocketClientProtocol
    
    // Configuration
    private var updateFrequency: UpdateFrequency = .medium
    private var isOfflineQueuingEnabled: Bool = true
    private var isRunning: Bool = false
    
    // Update batching
    private var updateBatcher: UpdateBatcher
    private var queuedUpdates: [QueuedUpdate] = []
    private let queueLock = NSLock()
    
    // Metrics
    private var updateMetrics = RealTimeMetrics()
    
    // Tasks
    private var updateTask: Task<Void, Never>?
    private var batchTask: Task<Void, Never>?
    
    init(store: StoreOf<AppFeature>, enhancedWebSocketClient: EnhancedWebSocketClientProtocol) {
        self.store = store
        self.enhancedWebSocketClient = enhancedWebSocketClient
        self.updateBatcher = UpdateBatcher(interval: updateFrequency.batchInterval)
        
        print("[RealTimeUpdateManager] Initialized with frequency: \(updateFrequency)")
    }
    
    func startRealtimeUpdates() async {
        guard !isRunning else {
            print("[RealTimeUpdateManager] Already running")
            return
        }
        
        print("[RealTimeUpdateManager] Starting real-time updates")
        isRunning = true
        updateMetrics.recordStart()
        
        // Start processing individual messages
        updateTask = Task {
            await processRealtimeUpdates()
        }
        
        // Start processing batches if not in realtime mode
        if updateFrequency != .realtime {
            batchTask = Task {
                await processBatchedUpdates()
            }
        }
        
        // Process any queued offline updates
        await processQueuedUpdates()
    }
    
    func stopRealtimeUpdates() {
        guard isRunning else { return }
        
        print("[RealTimeUpdateManager] Stopping real-time updates")
        isRunning = false
        
        updateTask?.cancel()
        batchTask?.cancel()
        updateTask = nil
        batchTask = nil
        
        updateMetrics.recordStop()
    }
    
    func configureUpdateFrequency(_ frequency: UpdateFrequency) {
        print("[RealTimeUpdateManager] Configuring update frequency: \(frequency)")
        
        let wasRunning = isRunning
        if wasRunning {
            stopRealtimeUpdates()
        }
        
        updateFrequency = frequency
        updateBatcher = UpdateBatcher(interval: frequency.batchInterval)
        
        if wasRunning {
            Task {
                await startRealtimeUpdates()
            }
        }
    }
    
    func enableOfflineQueuing(_ enabled: Bool) {
        print("[RealTimeUpdateManager] Offline queuing: \(enabled)")
        isOfflineQueuingEnabled = enabled
        
        if !enabled {
            clearQueue()
        }
    }
    
    func getQueuedUpdates() -> [QueuedUpdate] {
        queueLock.lock()
        defer { queueLock.unlock() }
        return queuedUpdates
    }
    
    func clearQueue() {
        queueLock.lock()
        defer { queueLock.unlock() }
        
        let count = queuedUpdates.count
        queuedUpdates.removeAll()
        
        if count > 0 {
            print("[RealTimeUpdateManager] Cleared \(count) queued updates")
        }
    }
    
    // MARK: - Private Processing Methods
    
    private func processRealtimeUpdates() async {
        print("[RealTimeUpdateManager] Starting realtime update processing")
        
        do {
            for try await processedMessage in enhancedWebSocketClient.processedMessages() {
                guard isRunning else { break }
                
                let startTime = Date()
                await processMessage(processedMessage)
                let processingTime = Date().timeIntervalSince(startTime)
                
                updateMetrics.recordUpdate(processingTime: processingTime)
                
                // Add small delay for realtime mode to prevent UI overwhelming
                if updateFrequency == .realtime {
                    try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
                }
            }
        } catch {
            print("[RealTimeUpdateManager] Error in realtime processing: \(error)")
            updateMetrics.recordError()
        }
    }
    
    private func processBatchedUpdates() async {
        print("[RealTimeUpdateManager] Starting batched update processing")
        
        do {
            for try await batchResult in enhancedWebSocketClient.batchProcessedMessages() {
                guard isRunning else { break }
                
                let startTime = Date()
                await processBatch(batchResult)
                let processingTime = Date().timeIntervalSince(startTime)
                
                updateMetrics.recordBatchUpdate(
                    messageCount: batchResult.totalCount,
                    processingTime: processingTime
                )
            }
        } catch {
            print("[RealTimeUpdateManager] Error in batch processing: \(error)")
            updateMetrics.recordError()
        }
    }
    
    private func processMessage(_ processedMessage: ProcessedMessage) async {
        let action = createAction(from: processedMessage)
        let priority = mapPriority(processedMessage.priority)
        
        // Check if we're online and can send immediately
        let isOnline = await enhancedWebSocketClient.isConnected
        
        if isOnline {
            await sendAction(action, priority: priority)
        } else if isOfflineQueuingEnabled {
            queueUpdate(action: action, priority: priority, message: processedMessage)
        }
    }
    
    private func processBatch(_ batchResult: BatchProcessingResult) async {
        print("[RealTimeUpdateManager] Processing batch of \(batchResult.totalCount) messages")
        
        // Group messages by feature for efficient updates
        var dashboardUpdates: [Any] = []
        var agentUpdates: [Any] = []
        var terminalUpdates: [Any] = []
        var analyticsUpdates: [Any] = []
        var alertUpdates: [Any] = []
        
        for processedMessage in batchResult.processed {
            let action = createAction(from: processedMessage)
            
            switch processedMessage.originalMessage.type {
            case .systemMetrics:
                dashboardUpdates.append(action)
                analyticsUpdates.append(action)
            case .agentStatus:
                agentUpdates.append(action)
                dashboardUpdates.append(action)
            case .terminalOutput:
                terminalUpdates.append(action)
            case .alert:
                alertUpdates.append(action)
                dashboardUpdates.append(action)
            case .commandResult:
                terminalUpdates.append(action)
            case .heartbeat:
                // Skip heartbeat for batch processing
                continue
            }
        }
        
        // Send batched updates
        let isOnline = await enhancedWebSocketClient.isConnected
        
        if isOnline {
            await sendBatchedUpdates(
                dashboard: dashboardUpdates,
                agents: agentUpdates,
                terminal: terminalUpdates,
                analytics: analyticsUpdates,
                alerts: alertUpdates
            )
        } else if isOfflineQueuingEnabled {
            queueBatchUpdates(
                dashboard: dashboardUpdates,
                agents: agentUpdates,
                terminal: terminalUpdates,
                analytics: analyticsUpdates,
                alerts: alertUpdates
            )
        }
    }
    
    private func createAction(from processedMessage: ProcessedMessage) -> Any {
        let message = processedMessage.originalMessage
        
        switch message.type {
        case .systemMetrics:
            return AppFeature.Action.dashboard(.updateMetrics(message.payload))
        case .agentStatus:
            return AppFeature.Action.agents(.updateAgentStatus(message.payload))
        case .terminalOutput:
            return AppFeature.Action.terminal(.appendOutput(message.payload))
        case .commandResult:
            return AppFeature.Action.terminal(.appendOutput(message.payload))
        case .alert:
            return AppFeature.Action.dashboard(.showAlert(message.payload))
        case .heartbeat:
            // Heartbeat doesn't need specific action
            return AppFeature.Action.connectionStatusChanged(.connected)
        }
    }
    
    private func sendAction(_ action: Any, priority: QueuedUpdate.UpdatePriority) async {
        if let appAction = action as? AppFeature.Action {
            await store.send(appAction).finish()
        }
    }
    
    private func sendBatchedUpdates(
        dashboard: [Any],
        agents: [Any],
        terminal: [Any],
        analytics: [Any],
        alerts: [Any]
    ) async {
        // Send updates in priority order
        
        // High priority: Alerts first
        for alert in alerts {
            if let action = alert as? AppFeature.Action {
                await store.send(action).finish()
            }
        }
        
        // Medium priority: Dashboard and agents
        for update in dashboard {
            if let action = update as? AppFeature.Action {
                await store.send(action).finish()
            }
        }
        
        for update in agents {
            if let action = update as? AppFeature.Action {
                await store.send(action).finish()
            }
        }
        
        // Lower priority: Terminal and analytics
        for update in terminal {
            if let action = update as? AppFeature.Action {
                await store.send(action).finish()
            }
        }
        
        for update in analytics {
            if let action = update as? AppFeature.Action {
                await store.send(action).finish()
            }
        }
    }
    
    private func queueUpdate(action: Any, priority: QueuedUpdate.UpdatePriority, message: ProcessedMessage) {
        queueLock.lock()
        defer { queueLock.unlock() }
        
        let queuedUpdate = QueuedUpdate(
            id: UUID(),
            feature: determineFeatureTarget(from: message),
            action: action,
            timestamp: Date(),
            priority: priority,
            retryCount: 0
        )
        
        queuedUpdates.append(queuedUpdate)
        
        // Sort by priority (highest first)
        queuedUpdates.sort { $0.priority > $1.priority }
        
        // Limit queue size
        if queuedUpdates.count > 1000 {
            queuedUpdates = Array(queuedUpdates.prefix(1000))
        }
        
        print("[RealTimeUpdateManager] Queued update for offline processing")
    }
    
    private func queueBatchUpdates(
        dashboard: [Any],
        agents: [Any],
        terminal: [Any],
        analytics: [Any],
        alerts: [Any]
    ) {
        // Queue each update with appropriate priority
        for alert in alerts {
            queueSingleUpdate(action: alert, feature: .dashboard, priority: .critical)
        }
        
        for update in dashboard {
            queueSingleUpdate(action: update, feature: .dashboard, priority: .high)
        }
        
        for update in agents {
            queueSingleUpdate(action: update, feature: .agents, priority: .high)
        }
        
        for update in terminal {
            queueSingleUpdate(action: update, feature: .terminal, priority: .normal)
        }
        
        for update in analytics {
            queueSingleUpdate(action: update, feature: .analytics, priority: .low)
        }
    }
    
    private func queueSingleUpdate(action: Any, feature: QueuedUpdate.FeatureTarget, priority: QueuedUpdate.UpdatePriority) {
        queueLock.lock()
        defer { queueLock.unlock() }
        
        let queuedUpdate = QueuedUpdate(
            id: UUID(),
            feature: feature,
            action: action,
            timestamp: Date(),
            priority: priority,
            retryCount: 0
        )
        
        queuedUpdates.append(queuedUpdate)
    }
    
    private func processQueuedUpdates() async {
        guard isOfflineQueuingEnabled else { return }
        
        queueLock.lock()
        let updates = queuedUpdates
        queuedUpdates.removeAll()
        queueLock.unlock()
        
        if updates.isEmpty { return }
        
        print("[RealTimeUpdateManager] Processing \(updates.count) queued offline updates")
        
        for update in updates.sorted(by: { $0.priority > $1.priority }) {
            if let action = update.action as? AppFeature.Action {
                await store.send(action).finish()
            }
            
            // Small delay to prevent overwhelming the UI
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
        
        updateMetrics.recordQueueProcessing(count: updates.count)
    }
    
    private func determineFeatureTarget(from message: ProcessedMessage) -> QueuedUpdate.FeatureTarget {
        switch message.originalMessage.type {
        case .systemMetrics: return .dashboard
        case .agentStatus: return .agents
        case .terminalOutput, .commandResult: return .terminal
        case .alert: return .dashboard
        case .heartbeat: return .global
        }
    }
    
    private func mapPriority(_ messagePriority: ProcessedMessage.MessagePriority) -> QueuedUpdate.UpdatePriority {
        switch messagePriority {
        case .low: return .low
        case .normal: return .normal
        case .high: return .high
        case .critical: return .critical
        }
    }
    
    func getUpdateMetrics() -> RealTimeMetrics {
        return updateMetrics
    }
}

// MARK: - Update Batcher

private class UpdateBatcher {
    private let interval: TimeInterval
    private var timer: Task<Void, Never>?
    
    init(interval: TimeInterval) {
        self.interval = interval
    }
    
    func startBatching() {
        timer = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                // Batching logic would be implemented here
            }
        }
    }
    
    func stopBatching() {
        timer?.cancel()
        timer = nil
    }
}

// MARK: - Real-Time Metrics

struct RealTimeMetrics {
    private(set) var updatesProcessed: Int = 0
    private(set) var batchesProcessed: Int = 0
    private(set) var averageUpdateTime: TimeInterval = 0
    private(set) var averageBatchTime: TimeInterval = 0
    private(set) var queuedUpdatesProcessed: Int = 0
    private(set) var errors: Int = 0
    private(set) var startTime: Date?
    
    private var totalUpdateTime: TimeInterval = 0
    private var totalBatchTime: TimeInterval = 0
    
    var uptime: TimeInterval {
        guard let start = startTime else { return 0 }
        return Date().timeIntervalSince(start)
    }
    
    var updatesPerSecond: Double {
        return uptime > 0 ? Double(updatesProcessed) / uptime : 0
    }
    
    mutating func recordStart() {
        startTime = Date()
    }
    
    mutating func recordStop() {
        startTime = nil
    }
    
    mutating func recordUpdate(processingTime: TimeInterval) {
        updatesProcessed += 1
        totalUpdateTime += processingTime
        averageUpdateTime = totalUpdateTime / Double(updatesProcessed)
    }
    
    mutating func recordBatchUpdate(messageCount: Int, processingTime: TimeInterval) {
        batchesProcessed += 1
        totalBatchTime += processingTime
        averageBatchTime = totalBatchTime / Double(batchesProcessed)
    }
    
    mutating func recordQueueProcessing(count: Int) {
        queuedUpdatesProcessed += count
    }
    
    mutating func recordError() {
        errors += 1
    }
    
    func debugDescription() -> String {
        return """
        [RealTimeMetrics]
        Updates: \(updatesProcessed) (\(String(format: "%.1f", updatesPerSecond))/sec)
        Batches: \(batchesProcessed)
        Avg Update Time: \(String(format: "%.2fms", averageUpdateTime * 1000))
        Avg Batch Time: \(String(format: "%.2fms", averageBatchTime * 1000))
        Queued Processed: \(queuedUpdatesProcessed)
        Errors: \(errors)
        Uptime: \(String(format: "%.1fs", uptime))
        """
    }
}