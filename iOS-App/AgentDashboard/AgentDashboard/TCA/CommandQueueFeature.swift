//
//  CommandQueueFeature.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Command queue management with priority, cancellation, and progress tracking
//  Phase 2 Week 4 Days 3-4 Hour 5-8 Implementation
//

import ComposableArchitecture
import Foundation
import IdentifiedCollections

@Reducer
struct CommandQueueFeature {
    // MARK: - State
    struct State: Equatable {
        // Queue management
        var queuedCommands: IdentifiedArrayOf<QueuedCommand> = []
        var executingCommands: IdentifiedArrayOf<QueuedCommand> = []
        var completedCommands: IdentifiedArrayOf<QueuedCommand> = []
        
        // Execution control
        var maxConcurrentExecutions: Int = 3
        var isProcessing: Bool = false
        var totalQueuedCount: Int = 0
        var totalExecutingCount: Int = 0
        
        // System status
        var systemResourceUsage: SystemResourceUsage = SystemResourceUsage()
        var lastProcessedAt: Date?
        var error: String?
        
        // Queue statistics
        var queueStatistics: QueueStatistics = QueueStatistics()
        
        // Hour 7: Enhanced cancellation support
        var isInEditMode: Bool = false
        var selectedCommandIDs: Set<QueuedCommand.ID> = []
        var confirmationDialog: ConfirmationDialogState? = nil
        var undoableOperations: [UndoableOperation] = []
        
        // Hour 8: Advanced progress tracking
        var queueAnalytics: QueueAnalytics? = nil
        var isShowingAnalytics: Bool = false
        var executionMetrics: [QueuedCommand.ID: ExecutionMetrics] = [:]
        var trendHistory: [TrendDataPoint] = []
        
        // Computed properties
        var canAcceptNewCommands: Bool {
            queuedCommands.count < maxQueueCapacity
        }
        
        var maxQueueCapacity: Int { 50 }
        
        var availableExecutionSlots: Int {
            max(0, maxConcurrentExecutions - executingCommands.count)
        }
        
        var hasQueuedCommands: Bool {
            !queuedCommands.isEmpty
        }
        
        var nextCommandForExecution: QueuedCommand? {
            queuedCommands.first
        }
        
        var allCommands: [QueuedCommand] {
            Array(queuedCommands) + Array(executingCommands) + Array(completedCommands)
        }
        
        // Queue health status
        var queueHealth: QueueHealth {
            let queuedCount = queuedCommands.count
            let executingCount = executingCommands.count
            
            if executingCount >= maxConcurrentExecutions && queuedCount > 10 {
                return .overloaded
            } else if queuedCount > 25 {
                return .busy
            } else if executingCount > 0 || queuedCount > 0 {
                return .active
            } else {
                return .idle
            }
        }
    }
    
    // MARK: - Action
    enum Action: Equatable {
        // Command lifecycle
        case enqueueCommand(CommandRequest)
        case commandEnqueued(QueuedCommand)
        case startNextExecution
        case commandStarted(QueuedCommand.ID)
        case commandCompleted(QueuedCommand.ID, CommandResult)
        case commandFailed(QueuedCommand.ID, String)
        
        // Queue management
        case processQueue
        case queueProcessed
        case updateQueueStatistics
        case cleanupCompletedCommands
        
        // Cancellation
        case cancelCommand(QueuedCommand.ID)
        case cancelAllQueuedCommands
        case cancelAllExecutingCommands
        case cancelCommandsByPriority(CommandPriority)
        case cancelCommandsBySystem(AISystem)
        case commandCancelled(QueuedCommand.ID)
        
        // Hour 7: Enhanced cancellation
        case enterEditMode
        case exitEditMode
        case toggleCommandSelection(QueuedCommand.ID)
        case selectAllCommands
        case deselectAllCommands
        case cancelSelectedCommands
        case showConfirmationDialog(ConfirmationDialogState)
        case dismissConfirmationDialog
        case confirmDialogAction
        case undoLastOperation
        case cancelCommandsByTimeRange(TimeInterval)
        
        // Progress tracking
        case progressUpdated(QueuedCommand.ID, Double)
        case updateExecutionProgress(QueuedCommand.ID, ExecutionProgress)
        
        // Hour 8: Advanced progress tracking
        case updateDetailedProgress(QueuedCommand.ID, DetailedExecutionProgress)
        case updateExecutionPhase(QueuedCommand.ID, DetailedExecutionProgress.ExecutionPhase)
        case recordExecutionMetrics(QueuedCommand.ID, ExecutionMetrics)
        case generateAnalytics
        case updateQueueAnalytics(QueueAnalytics)
        case showAnalyticsDashboard
        case dismissAnalyticsDashboard
        
        // Priority management
        case reprioritizeCommand(QueuedCommand.ID, CommandPriority)
        case reorderQueue
        
        // System monitoring
        case updateSystemResources(SystemResourceUsage)
        case adjustConcurrencyLimits
        
        // Error handling
        case queueError(String)
        case clearError
        
        // Lifecycle
        case onAppear
        case onDisappear
        case startMonitoring
        case stopMonitoring
        
        // Delegates
        case delegate(Delegate)
        
        enum Delegate: Equatable {
            case commandCompleted(CommandRequest, CommandResult)
            case queueStatusChanged(QueueHealth)
            case executionError(String)
            case responseGenerated(CommandResult, CommandRequest) // Hour 9: Response integration
        }
    }
    
    // MARK: - Dependencies
    @Dependency(\.continuousClock) var clock
    @Dependency(\.uuid) var uuid
    @Dependency(\.date) var date
    
    // MARK: - Reducer
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            // MARK: - Lifecycle
            case .onAppear:
                print("[CommandQueue] Command queue feature appeared")
                state.lastProcessedAt = date()
                return .merge(
                    .send(.startMonitoring),
                    .send(.updateQueueStatistics),
                    .send(.processQueue)
                )
                
            case .onDisappear:
                print("[CommandQueue] Command queue feature disappeared")
                return .send(.stopMonitoring)
                
            case .startMonitoring:
                print("[CommandQueue] Starting queue monitoring")
                return .run { send in
                    while !Task.isCancelled {
                        try await clock.sleep(for: .seconds(1))
                        await send(.processQueue)
                        await send(.updateSystemResources(SystemResourceUsage.current()))
                    }
                }
                .cancellable(id: "QueueMonitoring")
                
            case .stopMonitoring:
                print("[CommandQueue] Stopping queue monitoring")
                return .cancel(id: "QueueMonitoring")
                
            // MARK: - Command Enqueuing
            case let .enqueueCommand(request):
                print("[CommandQueue] Enqueuing command: \(request.id)")
                
                guard state.canAcceptNewCommands else {
                    let errorMessage = "Queue at capacity (\(state.queuedCommands.count)/\(state.maxQueueCapacity))"
                    print("[CommandQueue] Error: \(errorMessage)")
                    return .send(.queueError(errorMessage))
                }
                
                let queuedCommand = QueuedCommand(
                    id: request.id,
                    request: request,
                    priority: determinePriority(for: request),
                    enqueuedAt: date(),
                    status: .queued,
                    progress: 0.0,
                    estimatedDuration: request.estimatedDuration ?? estimateExecutionTime(for: request)
                )
                
                return .send(.commandEnqueued(queuedCommand))
                
            case let .commandEnqueued(command):
                print("[CommandQueue] Command enqueued: \(command.id) (Priority: \(command.priority))")
                
                // Insert with priority ordering
                insertCommandWithPriority(command, into: &state.queuedCommands)
                state.totalQueuedCount += 1
                
                // Update statistics
                state.queueStatistics.totalEnqueued += 1
                state.queueStatistics.currentQueueDepth = state.queuedCommands.count
                
                return .merge(
                    .send(.updateQueueStatistics),
                    .send(.processQueue),
                    .send(.delegate(.queueStatusChanged(state.queueHealth)))
                )
                
            // MARK: - Queue Processing
            case .processQueue:
                guard !state.isProcessing else { return .none }
                
                state.isProcessing = true
                state.lastProcessedAt = date()
                
                let effects: [Effect<Action>] = []
                var effects = effects
                
                // Start new executions if we have capacity and queued commands
                while state.availableExecutionSlots > 0 && state.hasQueuedCommands {
                    if let nextCommand = state.nextCommandForExecution {
                        effects.append(.send(.startNextExecution))
                    } else {
                        break
                    }
                }
                
                effects.append(.send(.queueProcessed))
                return .merge(effects)
                
            case .queueProcessed:
                state.isProcessing = false
                print("[CommandQueue] Queue processing completed. Queued: \(state.queuedCommands.count), Executing: \(state.executingCommands.count)")
                return .none
                
            case .startNextExecution:
                guard let command = state.queuedCommands.first else {
                    print("[CommandQueue] No commands to execute")
                    return .none
                }
                
                print("[CommandQueue] Starting execution of command: \(command.id)")
                
                // Move from queued to executing
                state.queuedCommands.remove(id: command.id)
                var executingCommand = command
                executingCommand.status = .executing
                executingCommand.startedAt = date()
                state.executingCommands.append(executingCommand)
                
                state.totalExecutingCount += 1
                state.queueStatistics.totalStarted += 1
                state.queueStatistics.currentExecutingCount = state.executingCommands.count
                
                return .merge(
                    .send(.commandStarted(command.id)),
                    .run { [request = command.request] send in
                        await executeCommandAsync(request, send: send)
                    }
                    .cancellable(id: "CommandExecution-\(command.id)")
                )
                
            case let .commandStarted(commandID):
                print("[CommandQueue] Command started: \(commandID)")
                return .none
                
            // MARK: - Command Completion
            case let .commandCompleted(commandID, result):
                print("[CommandQueue] Command completed: \(commandID)")
                
                guard var command = state.executingCommands[id: commandID] else {
                    print("[CommandQueue] Warning: Completed command not found in executing commands")
                    return .none
                }
                
                // Move from executing to completed
                state.executingCommands.remove(id: commandID)
                command.status = .completed
                command.completedAt = date()
                command.result = result
                command.progress = 1.0
                
                // Store in completed commands (keep last 100)
                state.completedCommands.append(command)
                if state.completedCommands.count > 100 {
                    state.completedCommands.remove(at: 0)
                }
                
                // Update statistics
                state.queueStatistics.totalCompleted += 1
                state.queueStatistics.currentExecutingCount = state.executingCommands.count
                if let duration = command.executionDuration {
                    state.queueStatistics.averageExecutionTime = calculateAverageExecutionTime(
                        current: state.queueStatistics.averageExecutionTime,
                        newDuration: duration,
                        completedCount: state.queueStatistics.totalCompleted
                    )
                }
                
                return .merge(
                    .send(.processQueue), // Process next command
                    .send(.updateQueueStatistics),
                    .send(.delegate(.commandCompleted(command.request, result))),
                    .send(.delegate(.responseGenerated(result, command.request))), // Hour 9: Response integration
                    .send(.delegate(.queueStatusChanged(state.queueHealth))),
                    .cancel(id: "CommandExecution-\(commandID)")
                )
                
            case let .commandFailed(commandID, error):
                print("[CommandQueue] Command failed: \(commandID), Error: \(error)")
                
                guard var command = state.executingCommands[id: commandID] else {
                    print("[CommandQueue] Warning: Failed command not found in executing commands")
                    return .none
                }
                
                // Move from executing to completed with error
                state.executingCommands.remove(id: commandID)
                command.status = .failed
                command.completedAt = date()
                command.error = error
                state.completedCommands.append(command)
                
                // Update statistics
                state.queueStatistics.totalFailed += 1
                state.queueStatistics.currentExecutingCount = state.executingCommands.count
                
                return .merge(
                    .send(.processQueue), // Process next command
                    .send(.updateQueueStatistics),
                    .send(.delegate(.executionError(error))),
                    .send(.delegate(.queueStatusChanged(state.queueHealth))),
                    .cancel(id: "CommandExecution-\(commandID)")
                )
                
            // MARK: - Progress Tracking
            case let .progressUpdated(commandID, progress):
                if var command = state.executingCommands[id: commandID] {
                    command.progress = max(0.0, min(1.0, progress))
                    state.executingCommands[id: commandID] = command
                    print("[CommandQueue] Progress updated for \(commandID): \(Int(progress * 100))%")
                }
                return .none
                
            case let .updateExecutionProgress(commandID, executionProgress):
                if var command = state.executingCommands[id: commandID] {
                    command.progress = executionProgress.completionRatio
                    command.executionProgress = executionProgress
                    state.executingCommands[id: commandID] = command
                }
                return .none
                
            // MARK: - Cancellation
            case let .cancelCommand(commandID):
                print("[CommandQueue] Cancelling command: \(commandID)")
                
                // Cancel if queued
                if let queuedIndex = state.queuedCommands.index(id: commandID) {
                    var command = state.queuedCommands[queuedIndex]
                    command.status = .cancelled
                    command.completedAt = date()
                    state.queuedCommands.remove(at: queuedIndex)
                    state.completedCommands.append(command)
                    state.queueStatistics.totalCancelled += 1
                    return .send(.commandCancelled(commandID))
                }
                
                // Cancel if executing
                if let executingIndex = state.executingCommands.index(id: commandID) {
                    var command = state.executingCommands[executingIndex]
                    command.status = .cancelled
                    command.completedAt = date()
                    state.executingCommands.remove(at: executingIndex)
                    state.completedCommands.append(command)
                    state.queueStatistics.totalCancelled += 1
                    state.queueStatistics.currentExecutingCount = state.executingCommands.count
                    
                    return .merge(
                        .send(.commandCancelled(commandID)),
                        .send(.processQueue), // Process next command
                        .cancel(id: "CommandExecution-\(commandID)")
                    )
                }
                
                print("[CommandQueue] Warning: Command \(commandID) not found for cancellation")
                return .none
                
            case let .commandCancelled(commandID):
                print("[CommandQueue] Command cancelled: \(commandID)")
                return .merge(
                    .send(.updateQueueStatistics),
                    .send(.delegate(.queueStatusChanged(state.queueHealth)))
                )
                
            case .cancelAllQueuedCommands:
                print("[CommandQueue] Cancelling all queued commands (\(state.queuedCommands.count))")
                
                let cancelledCommands = state.queuedCommands.map { command in
                    var cancelled = command
                    cancelled.status = .cancelled
                    cancelled.completedAt = date()
                    return cancelled
                }
                
                state.completedCommands.append(contentsOf: cancelledCommands)
                state.queuedCommands.removeAll()
                state.queueStatistics.totalCancelled += cancelledCommands.count
                
                return .merge(
                    .send(.updateQueueStatistics),
                    .send(.delegate(.queueStatusChanged(state.queueHealth)))
                )
                
            case .cancelAllExecutingCommands:
                print("[CommandQueue] Cancelling all executing commands (\(state.executingCommands.count))")
                
                let executingIDs = state.executingCommands.map(\.id)
                let effects = executingIDs.map { id in
                    Effect<Action>.cancel(id: "CommandExecution-\(id)")
                }
                
                let cancelledCommands = state.executingCommands.map { command in
                    var cancelled = command
                    cancelled.status = .cancelled
                    cancelled.completedAt = date()
                    return cancelled
                }
                
                state.completedCommands.append(contentsOf: cancelledCommands)
                state.executingCommands.removeAll()
                state.queueStatistics.totalCancelled += cancelledCommands.count
                state.queueStatistics.currentExecutingCount = 0
                
                return .merge([
                    .merge(effects),
                    .send(.updateQueueStatistics),
                    .send(.delegate(.queueStatusChanged(state.queueHealth))),
                    .send(.processQueue)
                ])
                
            // MARK: - Statistics and Monitoring
            case .updateQueueStatistics:
                state.queueStatistics.currentQueueDepth = state.queuedCommands.count
                state.queueStatistics.currentExecutingCount = state.executingCommands.count
                state.queueStatistics.lastUpdated = date()
                return .none
                
            case let .updateSystemResources(resources):
                state.systemResourceUsage = resources
                return .send(.adjustConcurrencyLimits)
                
            case .adjustConcurrencyLimits:
                let newLimit = calculateOptimalConcurrencyLimit(
                    currentLimit: state.maxConcurrentExecutions,
                    systemResources: state.systemResourceUsage,
                    queueDepth: state.queuedCommands.count
                )
                
                if newLimit != state.maxConcurrentExecutions {
                    print("[CommandQueue] Adjusting concurrency limit: \(state.maxConcurrentExecutions) → \(newLimit)")
                    state.maxConcurrentExecutions = newLimit
                    return .send(.processQueue)
                }
                return .none
                
            // MARK: - Error Handling
            case let .queueError(error):
                print("[CommandQueue] Queue error: \(error)")
                state.error = error
                return .send(.delegate(.executionError(error)))
                
            case .clearError:
                state.error = nil
                return .none
                
            // MARK: - Priority Management
            case let .reprioritizeCommand(commandID, newPriority):
                print("[CommandQueue] Reprioritizing command \(commandID) to \(newPriority)")
                
                if let index = state.queuedCommands.index(id: commandID) {
                    var command = state.queuedCommands[index]
                    command.priority = newPriority
                    state.queuedCommands.remove(at: index)
                    insertCommandWithPriority(command, into: &state.queuedCommands)
                    return .send(.reorderQueue)
                }
                return .none
                
            case .reorderQueue:
                print("[CommandQueue] Reordering queue based on priority")
                let sortedCommands = state.queuedCommands.sorted { cmd1, cmd2 in
                    if cmd1.priority.rawValue != cmd2.priority.rawValue {
                        return cmd1.priority.rawValue > cmd2.priority.rawValue
                    }
                    return cmd1.enqueuedAt < cmd2.enqueuedAt
                }
                state.queuedCommands = IdentifiedArrayOf(uniqueElements: sortedCommands)
                return .none
                
            // MARK: - Cleanup
            case .cleanupCompletedCommands:
                let oldCount = state.completedCommands.count
                let cutoff = date().addingTimeInterval(-3600) // Keep 1 hour of history
                state.completedCommands.removeAll { $0.completedAt ?? Date.distantPast < cutoff }
                print("[CommandQueue] Cleaned up completed commands: \(oldCount) → \(state.completedCommands.count)")
                return .none
                
            // MARK: - Enhanced Cancellation (Hour 7)
            case .enterEditMode:
                print("[CommandQueue] Entering edit mode")
                state.isInEditMode = true
                state.selectedCommandIDs.removeAll()
                return .none
                
            case .exitEditMode:
                print("[CommandQueue] Exiting edit mode")
                state.isInEditMode = false
                state.selectedCommandIDs.removeAll()
                state.confirmationDialog = nil
                return .none
                
            case let .toggleCommandSelection(commandID):
                if state.selectedCommandIDs.contains(commandID) {
                    state.selectedCommandIDs.remove(commandID)
                    print("[CommandQueue] Deselected command: \(commandID)")
                } else {
                    state.selectedCommandIDs.insert(commandID)
                    print("[CommandQueue] Selected command: \(commandID)")
                }
                return .none
                
            case .selectAllCommands:
                print("[CommandQueue] Selecting all commands")
                state.selectedCommandIDs = Set(
                    state.queuedCommands.map(\.id) + state.executingCommands.map(\.id)
                )
                return .none
                
            case .deselectAllCommands:
                print("[CommandQueue] Deselecting all commands")
                state.selectedCommandIDs.removeAll()
                return .none
                
            case .cancelSelectedCommands:
                guard !state.selectedCommandIDs.isEmpty else {
                    print("[CommandQueue] No commands selected for cancellation")
                    return .none
                }
                
                let selectedCount = state.selectedCommandIDs.count
                let confirmationDialog = ConfirmationDialogState(
                    title: "Cancel \(selectedCount) Command\(selectedCount == 1 ? "" : "s")?",
                    message: "This action cannot be undone.",
                    confirmButtonTitle: "Cancel Commands",
                    isDestructive: true,
                    action: .cancelSelectedCommands
                )
                
                return .send(.showConfirmationDialog(confirmationDialog))
                
            case let .showConfirmationDialog(dialogState):
                print("[CommandQueue] Showing confirmation dialog: \(dialogState.title)")
                state.confirmationDialog = dialogState
                return .none
                
            case .dismissConfirmationDialog:
                print("[CommandQueue] Dismissing confirmation dialog")
                state.confirmationDialog = nil
                return .none
                
            case .confirmDialogAction:
                guard let dialog = state.confirmationDialog else { return .none }
                state.confirmationDialog = nil
                
                switch dialog.action {
                case .cancelSelectedCommands:
                    let commandsToCancel = state.selectedCommandIDs
                    let undoOperation = UndoableOperation(
                        type: .cancelCommands,
                        affectedCommands: commandsToCancel,
                        timestamp: date()
                    )
                    
                    state.undoableOperations.append(undoOperation)
                    if state.undoableOperations.count > 10 {
                        state.undoableOperations.removeFirst()
                    }
                    
                    let effects = commandsToCancel.map { commandID in
                        Effect<Action>.send(.cancelCommand(commandID))
                    }
                    
                    state.selectedCommandIDs.removeAll()
                    return .merge(effects)
                    
                case .cancelAllQueued:
                    return .send(.cancelAllQueuedCommands)
                    
                case .cancelAllExecuting:
                    return .send(.cancelAllExecutingCommands)
                }
                
            case .undoLastOperation:
                guard let lastOperation = state.undoableOperations.last else {
                    print("[CommandQueue] No operations to undo")
                    return .none
                }
                
                state.undoableOperations.removeLast()
                print("[CommandQueue] Undoing operation: \(lastOperation.type)")
                
                // For now, we only support undo for cancel operations
                // In a real implementation, we would restore cancelled commands
                return .none
                
            case let .cancelCommandsByTimeRange(olderThanSeconds):
                print("[CommandQueue] Cancelling commands older than \(olderThanSeconds) seconds")
                let cutoffTime = date().addingTimeInterval(-olderThanSeconds)
                
                let oldCommands = state.queuedCommands.filter { $0.enqueuedAt < cutoffTime }
                let commandIDs = oldCommands.map(\.id)
                
                guard !commandIDs.isEmpty else {
                    print("[CommandQueue] No old commands found for cancellation")
                    return .none
                }
                
                let confirmationDialog = ConfirmationDialogState(
                    title: "Cancel \(commandIDs.count) Old Commands?",
                    message: "This will cancel commands queued more than \(Int(olderThanSeconds)) seconds ago.",
                    confirmButtonTitle: "Cancel Old Commands",
                    isDestructive: true,
                    action: .cancelSelectedCommands
                )
                
                state.selectedCommandIDs = Set(commandIDs)
                return .send(.showConfirmationDialog(confirmationDialog))
                
            // MARK: - Advanced Progress Tracking (Hour 8)
            case let .updateDetailedProgress(commandID, detailedProgress):
                if var command = state.executingCommands[id: commandID] {
                    command.progress = detailedProgress.completionRatio
                    command.detailedProgress = detailedProgress
                    state.executingCommands[id: commandID] = command
                    
                    print("[CommandQueue] Detailed progress updated for \(commandID): \(detailedProgress.progressDescription)")
                }
                return .none
                
            case let .updateExecutionPhase(commandID, phase):
                if var command = state.executingCommands[id: commandID] {
                    if var detailedProgress = command.detailedProgress {
                        detailedProgress = DetailedExecutionProgress(
                            currentStep: detailedProgress.currentStep,
                            stepNumber: detailedProgress.stepNumber,
                            totalSteps: detailedProgress.totalSteps,
                            completionRatio: detailedProgress.completionRatio,
                            estimatedTimeRemaining: detailedProgress.estimatedTimeRemaining,
                            executionPhase: phase,
                            stepStartTime: Date(),
                            subSteps: detailedProgress.subSteps
                        )
                        command.detailedProgress = detailedProgress
                        state.executingCommands[id: commandID] = command
                    }
                    
                    print("[CommandQueue] Execution phase updated for \(commandID): \(phase.rawValue)")
                }
                return .none
                
            case let .recordExecutionMetrics(commandID, metrics):
                state.executionMetrics[commandID] = metrics
                print("[CommandQueue] Execution metrics recorded for \(commandID)")
                return .none
                
            case .generateAnalytics:
                print("[CommandQueue] Generating queue analytics")
                
                let analytics = generateQueueAnalytics(
                    queuedCommands: state.queuedCommands,
                    executingCommands: state.executingCommands,
                    completedCommands: state.completedCommands,
                    statistics: state.queueStatistics,
                    resourceUsage: state.systemResourceUsage,
                    trendHistory: state.trendHistory
                )
                
                return .send(.updateQueueAnalytics(analytics))
                
            case let .updateQueueAnalytics(analytics):
                print("[CommandQueue] Queue analytics updated")
                state.queueAnalytics = analytics
                
                // Update trend history
                let trendPoint = TrendDataPoint(
                    timestamp: date(),
                    queueDepth: state.queuedCommands.count,
                    executingCount: state.executingCommands.count,
                    completionRate: analytics.successRate,
                    averageWaitTime: analytics.averageQueueTime,
                    resourceUsage: state.systemResourceUsage.cpuUsage
                )
                
                state.trendHistory.append(trendPoint)
                
                // Keep only last 100 trend points
                if state.trendHistory.count > 100 {
                    state.trendHistory.removeFirst()
                }
                
                return .none
                
            case .showAnalyticsDashboard:
                print("[CommandQueue] Showing analytics dashboard")
                state.isShowingAnalytics = true
                
                // Generate fresh analytics when showing dashboard
                return .send(.generateAnalytics)
                
            case .dismissAnalyticsDashboard:
                print("[CommandQueue] Dismissing analytics dashboard")
                state.isShowingAnalytics = false
                return .none

            // MARK: - Delegate Actions
            case .delegate:
                return .none
            }
        }
    }
}

// MARK: - Helper Functions

private func insertCommandWithPriority(_ command: QueuedCommand, into queue: inout IdentifiedArrayOf<QueuedCommand>) {
    let insertIndex = queue.firstIndex { existingCommand in
        // Higher priority value comes first
        if command.priority.rawValue > existingCommand.priority.rawValue {
            return true
        }
        // Same priority: FIFO order (earlier enqueue time first)
        if command.priority == existingCommand.priority {
            return command.enqueuedAt < existingCommand.enqueuedAt
        }
        return false
    } ?? queue.endIndex
    
    queue.insert(command, at: insertIndex)
}

private func determinePriority(for request: CommandRequest) -> CommandPriority {
    // Smart priority determination based on request characteristics
    switch request.targetSystem {
    case .claudeCode:
        return request.prompt.count > 500 ? .normal : .high
    case .autoGen, .langGraph:
        return .normal
    case .custom:
        return .low
    }
}

private func estimateExecutionTime(for request: CommandRequest) -> TimeInterval {
    // Estimate based on prompt length, system type, and complexity
    let baseTime: TimeInterval = 5.0 // 5 seconds base
    let lengthMultiplier = Double(request.prompt.count) / 100.0 // 1 second per 100 characters
    
    let systemMultiplier: Double
    switch request.targetSystem {
    case .claudeCode: systemMultiplier = 1.0
    case .autoGen: systemMultiplier = 1.5
    case .langGraph: systemMultiplier = 2.0
    case .custom: systemMultiplier = 1.2
    }
    
    return baseTime + lengthMultiplier * systemMultiplier
}

private func calculateAverageExecutionTime(current: TimeInterval, newDuration: TimeInterval, completedCount: Int) -> TimeInterval {
    guard completedCount > 0 else { return newDuration }
    let weight = 1.0 / Double(completedCount)
    return current * (1.0 - weight) + newDuration * weight
}

private func calculateOptimalConcurrencyLimit(currentLimit: Int, systemResources: SystemResourceUsage, queueDepth: Int) -> Int {
    // Adjust concurrency based on system resources and queue pressure
    let cpuFactor = systemResources.cpuUsage < 0.7 ? 1.0 : 0.5
    let memoryFactor = systemResources.memoryUsage < 0.8 ? 1.0 : 0.5
    let queuePressure = queueDepth > 10 ? 1.2 : 1.0
    
    let adjustmentFactor = cpuFactor * memoryFactor * queuePressure
    let newLimit = Int(Double(currentLimit) * adjustmentFactor)
    
    return max(1, min(6, newLimit)) // Keep between 1 and 6
}

// MARK: - Async Command Execution

// MARK: - Analytics Generation

private func generateQueueAnalytics(
    queuedCommands: IdentifiedArrayOf<QueuedCommand>,
    executingCommands: IdentifiedArrayOf<QueuedCommand>,
    completedCommands: IdentifiedArrayOf<QueuedCommand>,
    statistics: QueueStatistics,
    resourceUsage: SystemResourceUsage,
    trendHistory: [TrendDataPoint]
) -> QueueAnalytics {
    
    let totalProcessed = completedCommands.count
    let completedWithDuration = completedCommands.compactMap { $0.executionDuration }
    
    let averageExecutionTime = completedWithDuration.isEmpty ? 0.0 :
        completedWithDuration.reduce(0.0, +) / Double(completedWithDuration.count)
    
    let averageQueueTime = calculateAverageQueueTime(completedCommands: Array(completedCommands))
    
    let successfulCommands = completedCommands.filter { $0.status == .completed }.count
    let successRate = totalProcessed > 0 ? Double(successfulCommands) / Double(totalProcessed) : 1.0
    
    let maxDepth = trendHistory.map(\.queueDepth).max() ?? queuedCommands.count
    
    let throughputPerHour = calculateThroughput(completedCommands: Array(completedCommands))
    
    let resourceUtilization = ResourceUtilization(
        cpuUsage: resourceUsage.cpuUsage,
        memoryUsage: resourceUsage.memoryUsage,
        networkUsage: 0.1, // Simulated
        cpuEfficiency: calculateCPUEfficiency(resourceUsage: resourceUsage, queueDepth: queuedCommands.count),
        memoryEfficiency: 1.0 - resourceUsage.memoryUsage,
        timestamp: Date()
    )
    
    return QueueAnalytics(
        totalProcessed: totalProcessed,
        averageQueueTime: averageQueueTime,
        averageExecutionTime: averageExecutionTime,
        peakQueueDepth: maxDepth,
        successRate: successRate,
        throughputPerHour: throughputPerHour,
        resourceUtilization: resourceUtilization,
        trendData: trendHistory,
        lastUpdated: Date()
    )
}

private func calculateAverageQueueTime(completedCommands: [QueuedCommand]) -> TimeInterval {
    let queueTimes = completedCommands.compactMap { command -> TimeInterval? in
        guard let startedAt = command.startedAt else { return nil }
        return startedAt.timeIntervalSince(command.enqueuedAt)
    }
    
    return queueTimes.isEmpty ? 0.0 : queueTimes.reduce(0.0, +) / Double(queueTimes.count)
}

private func calculateThroughput(completedCommands: [QueuedCommand]) -> Double {
    let oneHourAgo = Date().addingTimeInterval(-3600)
    let recentCommands = completedCommands.filter { command in
        (command.completedAt ?? Date.distantPast) > oneHourAgo
    }
    return Double(recentCommands.count)
}

private func calculateCPUEfficiency(resourceUsage: SystemResourceUsage, queueDepth: Int) -> Double {
    guard queueDepth > 0 else { return 1.0 }
    let expectedCPU = min(0.8, Double(queueDepth) * 0.1) // 10% CPU per queued command, max 80%
    return min(1.0, expectedCPU / max(0.01, resourceUsage.cpuUsage))
}

// MARK: - Enhanced Command Execution

private func executeCommandAsync(_ request: CommandRequest, send: Send<CommandQueueFeature.Action>) async {
    let startTime = Date()
    let phases: [DetailedExecutionProgress.ExecutionPhase] = [.initialization, .validation, .execution, .postProcessing, .completion]
    
    do {
        print("[CommandQueue] Executing command: \(request.id)")
        
        for (phaseIndex, phase) in phases.enumerated() {
            try Task.checkCancellation()
            
            // Update execution phase
            await send(.updateExecutionPhase(request.id, phase))
            
            let phaseSteps = 2 // 2 steps per phase
            for step in 1...phaseSteps {
                try Task.checkCancellation()
                
                let overallProgress = (Double(phaseIndex * phaseSteps + step) / Double(phases.count * phaseSteps))
                let stepName = "\(phase.rawValue) - Step \(step)"
                
                let detailedProgress = DetailedExecutionProgress(
                    currentStep: stepName,
                    stepNumber: phaseIndex * phaseSteps + step,
                    totalSteps: phases.count * phaseSteps,
                    completionRatio: overallProgress,
                    estimatedTimeRemaining: calculateRemainingTime(progress: overallProgress, startTime: startTime, estimatedTotal: request.estimatedDuration ?? 10.0),
                    executionPhase: phase,
                    stepStartTime: Date(),
                    subSteps: generateSubSteps(for: phase, step: step)
                )
                
                await send(.updateDetailedProgress(request.id, detailedProgress))
                
                // Simulate step execution time
                let stepDuration = (request.estimatedDuration ?? 10.0) / Double(phases.count * phaseSteps)
                try await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
            }
        }
        
        // Record execution metrics
        let metrics = ExecutionMetrics(
            commandID: request.id,
            startTime: startTime,
            endTime: Date(),
            totalDuration: Date().timeIntervalSince(startTime),
            phaseTimings: [:], // Would be populated in real implementation
            resourcePeak: ResourceUtilization(
                cpuUsage: 0.5,
                memoryUsage: 0.3,
                networkUsage: 0.1,
                cpuEfficiency: 0.8,
                memoryEfficiency: 0.7,
                timestamp: Date()
            ),
            stepCount: phases.count * 2,
            stepDurations: [],
            errorCount: 0,
            retryCount: 0
        )
        
        await send(.recordExecutionMetrics(request.id, metrics))
        
        // Simulate successful result
        let result = CommandResult(
            id: UUID(),
            success: true,
            output: "Command executed successfully: \(request.prompt.prefix(50))...",
            executionTime: Date().timeIntervalSince(startTime),
            timestamp: Date()
        )
        
        await send(.commandCompleted(request.id, result))
        
    } catch is CancellationError {
        print("[CommandQueue] Command cancelled: \(request.id)")
        await send(.commandCancelled(request.id))
    } catch {
        print("[CommandQueue] Command failed: \(request.id), Error: \(error)")
        await send(.commandFailed(request.id, error.localizedDescription))
    }
}

private func calculateRemainingTime(progress: Double, startTime: Date, estimatedTotal: TimeInterval) -> TimeInterval? {
    guard progress > 0 else { return estimatedTotal }
    let elapsed = Date().timeIntervalSince(startTime)
    let estimatedTotal = elapsed / progress
    return estimatedTotal - elapsed
}

private func generateSubSteps(for phase: DetailedExecutionProgress.ExecutionPhase, step: Int) -> [ExecutionSubStep] {
    switch phase {
    case .initialization:
        return [
            ExecutionSubStep(name: "Load configuration", isCompleted: step > 1, duration: 0.5, startTime: Date(), endTime: step > 1 ? Date() : nil),
            ExecutionSubStep(name: "Initialize resources", isCompleted: step > 1, duration: 0.3, startTime: Date(), endTime: step > 1 ? Date() : nil)
        ]
    case .validation:
        return [
            ExecutionSubStep(name: "Validate input", isCompleted: step > 1, duration: 0.2, startTime: Date(), endTime: step > 1 ? Date() : nil),
            ExecutionSubStep(name: "Check dependencies", isCompleted: step > 1, duration: 0.4, startTime: Date(), endTime: step > 1 ? Date() : nil)
        ]
    case .execution:
        return [
            ExecutionSubStep(name: "Process command", isCompleted: step > 1, duration: 2.0, startTime: Date(), endTime: step > 1 ? Date() : nil),
            ExecutionSubStep(name: "Generate response", isCompleted: step > 1, duration: 1.5, startTime: Date(), endTime: step > 1 ? Date() : nil)
        ]
    case .postProcessing:
        return [
            ExecutionSubStep(name: "Format output", isCompleted: step > 1, duration: 0.3, startTime: Date(), endTime: step > 1 ? Date() : nil),
            ExecutionSubStep(name: "Update statistics", isCompleted: step > 1, duration: 0.1, startTime: Date(), endTime: step > 1 ? Date() : nil)
        ]
    case .completion:
        return [
            ExecutionSubStep(name: "Finalize result", isCompleted: step > 1, duration: 0.1, startTime: Date(), endTime: step > 1 ? Date() : nil),
            ExecutionSubStep(name: "Cleanup resources", isCompleted: step > 1, duration: 0.2, startTime: Date(), endTime: step > 1 ? Date() : nil)
        ]
    }
}