//
//  CommandQueueView.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Command queue management interface with priority display and cancellation
//

import SwiftUI
import ComposableArchitecture

struct CommandQueueView: View {
    let store: StoreOf<CommandQueueFeature>
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            NavigationView {
                VStack(spacing: 0) {
                    // Queue status header
                    queueStatusHeader(viewStore: viewStore)
                    
                    // Command queue list
                    commandQueueList(viewStore: viewStore)
                }
                .navigationTitle("Command Queue")
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        if viewStore.isInEditMode {
                            editModeLeadingToolbar(viewStore: viewStore)
                        }
                    }
                    
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        if viewStore.isInEditMode {
                            editModeTrailingToolbar(viewStore: viewStore)
                        } else {
                            queueControlsToolbar(viewStore: viewStore)
                        }
                    }
                }
                .confirmationDialog(
                    viewStore.confirmationDialog?.title ?? "",
                    isPresented: .constant(viewStore.confirmationDialog != nil),
                    presenting: viewStore.confirmationDialog
                ) { dialog in
                    confirmationDialogButtons(dialog: dialog, viewStore: viewStore)
                } message: { dialog in
                    if let message = dialog.message {
                        Text(message)
                    }
                }
                .sheet(isPresented: .constant(viewStore.isShowingAnalytics)) {
                    if let analytics = viewStore.queueAnalytics {
                        QueueAnalyticsView(analytics: analytics) {
                            viewStore.send(.dismissAnalyticsDashboard)
                        }
                    }
                }
            }
            .onAppear {
                viewStore.send(.onAppear)
            }
            .onDisappear {
                viewStore.send(.onDisappear)
            }
        }
    }
    
    // MARK: - Queue Status Header
    
    private func queueStatusHeader(viewStore: ViewStoreOf<CommandQueueFeature>) -> some View {
        VStack(spacing: 12) {
            // Health indicator
            HStack {
                Circle()
                    .fill(viewStore.queueHealth.color)
                    .frame(width: 12, height: 12)
                
                Text(viewStore.queueHealth.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                if viewStore.isProcessing {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            // Queue metrics
            HStack(spacing: 24) {
                QueueMetricView(
                    title: "Queued",
                    value: "\(viewStore.queuedCommands.count)",
                    color: .gray
                )
                
                QueueMetricView(
                    title: "Executing",
                    value: "\(viewStore.executingCommands.count)",
                    color: .blue
                )
                
                QueueMetricView(
                    title: "Completed",
                    value: "\(viewStore.completedCommands.count)",
                    color: .green
                )
                
                Spacer()
            }
            
            // Concurrency info
            HStack {
                Text("Concurrency: \(viewStore.executingCommands.count)/\(viewStore.maxConcurrentExecutions)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let lastProcessed = viewStore.lastProcessedAt {
                    Text("Last updated: \(lastProcessed, formatter: timeFormatter)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
    }
    
    // MARK: - Command Queue List
    
    private func commandQueueList(viewStore: ViewStoreOf<CommandQueueFeature>) -> some View {
        List {
            // Executing commands section
            if !viewStore.executingCommands.isEmpty {
                Section(executingSectionHeader(count: viewStore.executingCommands.count, viewStore: viewStore)) {
                    ForEach(viewStore.executingCommands) { command in
                        SelectableCommandRow(
                            command: command,
                            isSelected: viewStore.selectedCommandIDs.contains(command.id),
                            isInEditMode: viewStore.isInEditMode,
                            onSelectionToggle: { viewStore.send(.toggleCommandSelection(command.id)) },
                            onCancel: { viewStore.send(.cancelCommand(command.id)) },
                            onReprioritize: { priority in
                                viewStore.send(.reprioritizeCommand(command.id, priority))
                            }
                        )
                    }
                }
            }
            
            // Queued commands section
            if !viewStore.queuedCommands.isEmpty {
                Section(queuedSectionHeader(count: viewStore.queuedCommands.count, viewStore: viewStore)) {
                    ForEach(viewStore.queuedCommands) { command in
                        SelectableCommandRow(
                            command: command,
                            isSelected: viewStore.selectedCommandIDs.contains(command.id),
                            isInEditMode: viewStore.isInEditMode,
                            onSelectionToggle: { viewStore.send(.toggleCommandSelection(command.id)) },
                            onCancel: { viewStore.send(.cancelCommand(command.id)) },
                            onReprioritize: { priority in
                                viewStore.send(.reprioritizeCommand(command.id, priority))
                            }
                        )
                    }
                }
            }
            
            // Recent completed commands section
            if !viewStore.completedCommands.isEmpty {
                Section("Recent Completed (\(min(viewStore.completedCommands.count, 10)))") {
                    ForEach(viewStore.completedCommands.suffix(10).reversed(), id: \.id) { command in
                        CompletedCommandRow(command: command)
                    }
                }
            }
            
            // Empty state
            if viewStore.allCommands.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No Commands")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Submit prompts from the AI Prompt tab to see commands in the queue")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Toolbar Controls
    
    private func queueControlsToolbar(viewStore: ViewStoreOf<CommandQueueFeature>) -> some View {
        Group {
            Button("Select") {
                viewStore.send(.enterEditMode)
            }
            .disabled(viewStore.allCommands.isEmpty)
            
            Menu {
                Button("Cancel All Queued", role: .destructive) {
                    viewStore.send(.cancelAllQueuedCommands)
                }
                .disabled(viewStore.queuedCommands.isEmpty)
                
                Button("Cancel All Executing", role: .destructive) {
                    viewStore.send(.cancelAllExecutingCommands)
                }
                .disabled(viewStore.executingCommands.isEmpty)
                
                Divider()
                
                Button("Cancel Old Commands") {
                    viewStore.send(.cancelCommandsByTimeRange(300)) // 5 minutes
                }
                .disabled(viewStore.queuedCommands.isEmpty)
                
                Divider()
                
                Button("Clean Completed") {
                    viewStore.send(.cleanupCompletedCommands)
                }
                .disabled(viewStore.completedCommands.isEmpty)
                
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            
            Button(action: {
                viewStore.send(.processQueue)
            }) {
                Image(systemName: "arrow.clockwise")
            }
            
            Button(action: {
                viewStore.send(.showAnalyticsDashboard)
            }) {
                Image(systemName: "chart.line.uptrend.xyaxis")
            }
        }
    }
    
    private func editModeLeadingToolbar(viewStore: ViewStoreOf<CommandQueueFeature>) -> some View {
        Button("Cancel") {
            viewStore.send(.exitEditMode)
        }
    }
    
    private func editModeTrailingToolbar(viewStore: ViewStoreOf<CommandQueueFeature>) -> some View {
        Group {
            if !viewStore.selectedCommandIDs.isEmpty {
                Button("Cancel Selected", role: .destructive) {
                    viewStore.send(.cancelSelectedCommands)
                }
            }
            
            Menu {
                Button("Select All") {
                    viewStore.send(.selectAllCommands)
                }
                .disabled(viewStore.allCommands.isEmpty)
                
                Button("Deselect All") {
                    viewStore.send(.deselectAllCommands)
                }
                .disabled(viewStore.selectedCommandIDs.isEmpty)
                
                Divider()
                
                if !viewStore.undoableOperations.isEmpty {
                    Button("Undo Last Action") {
                        viewStore.send(.undoLastOperation)
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
    
    private func executingSectionHeader(count: Int, viewStore: ViewStoreOf<CommandQueueFeature>) -> String {
        if viewStore.isInEditMode {
            let selectedCount = viewStore.selectedCommandIDs.intersection(Set(viewStore.executingCommands.map(\.id))).count
            return selectedCount > 0 ? "Executing (\(count)) - \(selectedCount) selected" : "Executing (\(count))"
        } else {
            return "Executing (\(count))"
        }
    }
    
    private func queuedSectionHeader(count: Int, viewStore: ViewStoreOf<CommandQueueFeature>) -> String {
        if viewStore.isInEditMode {
            let selectedCount = viewStore.selectedCommandIDs.intersection(Set(viewStore.queuedCommands.map(\.id))).count
            return selectedCount > 0 ? "Queued (\(count)) - \(selectedCount) selected" : "Queued (\(count))"
        } else {
            return "Queued (\(count))"
        }
    }
    
    private func confirmationDialogButtons(dialog: ConfirmationDialogState, viewStore: ViewStoreOf<CommandQueueFeature>) -> some View {
        Group {
            Button(dialog.confirmButtonTitle, role: dialog.isDestructive ? .destructive : .none) {
                viewStore.send(.confirmDialogAction)
            }
            
            Button("Cancel", role: .cancel) {
                viewStore.send(.dismissConfirmationDialog)
            }
        }
    }
}

// MARK: - Supporting Views

struct QueueMetricView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct QueuedCommandRow: View {
    let command: QueuedCommand
    let onCancel: () -> Void
    let onReprioritize: (CommandPriority) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with status and priority
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: command.status.icon)
                        .foregroundColor(command.status.color)
                    
                    Text(command.status.rawValue.capitalized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                // Priority badge
                Text(command.priority.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(command.priority.color)
                    .clipShape(Capsule())
            }
            
            // Command preview
            Text(command.request.prompt.prefix(100) + (command.request.prompt.count > 100 ? "..." : ""))
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(2)
            
            // Progress bar (if executing)
            if command.status == .executing {
                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(value: command.progress)
                        .progressViewStyle(LinearProgressViewStyle())
                    
                    HStack {
                        Text("\(Int(command.progress * 100))% complete")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if let executionProgress = command.executionProgress {
                            Text(executionProgress.progressDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Metadata
            HStack {
                Text(command.request.targetSystem.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(command.enqueuedAt, formatter: timeFormatter)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .swipeActions(edge: .trailing) {
            if command.canBeCancelled {
                Button("Cancel", role: .destructive) {
                    onCancel()
                }
            }
        }
        .contextMenu {
            if command.status == .queued {
                Menu("Change Priority") {
                    ForEach(CommandPriority.allCases, id: \.self) { priority in
                        Button(priority.displayName) {
                            onReprioritize(priority)
                        }
                    }
                }
            }
            
            if command.canBeCancelled {
                Button("Cancel Command", role: .destructive) {
                    onCancel()
                }
            }
        }
    }
}

struct CompletedCommandRow: View {
    let command: QueuedCommand
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: command.status.icon)
                        .foregroundColor(command.status.color)
                    
                    Text(command.status.rawValue.capitalized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                if let duration = command.executionDuration {
                    Text("\(duration, specifier: "%.1f")s")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(command.request.prompt.prefix(80) + (command.request.prompt.count > 80 ? "..." : ""))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            if let completedAt = command.completedAt {
                Text(completedAt, formatter: timeFormatter)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Formatters

private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.dateStyle = .none
    return formatter
}()

// MARK: - Preview

struct CommandQueueView_Previews: PreviewProvider {
    static var previews: some View {
        CommandQueueView(
            store: Store(initialState: CommandQueueFeature.State()) {
                CommandQueueFeature()
            }
        )
    }
}