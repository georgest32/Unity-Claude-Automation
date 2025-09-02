//
//  SelectableCommandRow.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Enhanced command row with multi-select capability for batch operations
//  Hour 7.2: Multi-select UI components
//

import SwiftUI
import ComposableArchitecture

struct SelectableCommandRow: View {
    let command: QueuedCommand
    let isSelected: Bool
    let isInEditMode: Bool
    let onSelectionToggle: () -> Void
    let onCancel: () -> Void
    let onReprioritize: (CommandPriority) -> Void
    
    @State private var isShowingDetails = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Selection checkbox (edit mode only)
            if isInEditMode {
                Button(action: onSelectionToggle) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(isSelected ? .accentColor : .secondary)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel(isSelected ? "Deselect command" : "Select command")
            }
            
            // Command content
            VStack(alignment: .leading, spacing: 8) {
                // Header with status and priority
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: command.status.icon)
                            .foregroundColor(command.status.color)
                            .font(.subheadline)
                        
                        Text(command.status.rawValue.capitalized)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    // Priority badge
                    PriorityBadge(priority: command.priority)
                    
                    // Details button
                    Button(action: { isShowingDetails.toggle() }) {
                        Image(systemName: "info.circle")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Command preview
                Text(command.request.prompt.prefix(120) + (command.request.prompt.count > 120 ? "..." : ""))
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(isShowingDetails ? nil : 2)
                    .animation(.easeInOut(duration: 0.2), value: isShowingDetails)
                
                // Enhanced progress section (if executing)
                if command.status == .executing {
                    ProgressSection(command: command)
                }
                
                // Command details (expandable)
                if isShowingDetails {
                    CommandDetailsSection(command: command)
                        .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                }
                
                // Metadata footer
                CommandMetadataFooter(command: command)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if isInEditMode {
                    onSelectionToggle()
                }
            }
        }
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
                .animation(.easeInOut(duration: 0.2), value: isSelected)
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if !isInEditMode && command.canBeCancelled {
                Button("Cancel", role: .destructive) {
                    onCancel()
                }
            }
        }
        .contextMenu {
            if !isInEditMode {
                CommandContextMenu(
                    command: command,
                    onCancel: onCancel,
                    onReprioritize: onReprioritize
                )
            }
        }
    }
}

// MARK: - Supporting Components

struct PriorityBadge: View {
    let priority: CommandPriority
    
    var body: some View {
        Text(priority.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(priority.color)
            .clipShape(Capsule())
    }
}

struct ProgressSection: View {
    let command: QueuedCommand
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Enhanced progress bar with phase indicator
            if let detailedProgress = command.detailedProgress {
                EnhancedProgressBar(detailedProgress: detailedProgress)
            } else {
                // Fallback to basic progress bar
                BasicProgressBar(progress: command.progress)
            }
            
            // Detailed progress information
            if let detailedProgress = command.detailedProgress {
                DetailedProgressInfo(detailedProgress: detailedProgress)
            }
            
            // Execution time (if completed)
            if command.status == .completed,
               let duration = command.executionDuration {
                HStack {
                    Image(systemName: "stopwatch")
                        .font(.caption2)
                    Text("Completed in \(duration, specifier: "%.1f")s")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
    }
}

struct EnhancedProgressBar: View {
    let detailedProgress: DetailedExecutionProgress
    
    var body: some View {
        VStack(spacing: 4) {
            // Main progress with phase color
            HStack {
                ProgressView(value: detailedProgress.completionRatio)
                    .progressViewStyle(LinearProgressViewStyle(tint: detailedProgress.executionPhase.color))
                    .scaleEffect(y: 1.8)
                
                Text("\(Int(detailedProgress.completionRatio * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(detailedProgress.executionPhase.color)
                    .frame(minWidth: 35)
            }
            
            // Phase indicator
            HStack(spacing: 6) {
                Image(systemName: detailedProgress.executionPhase.icon)
                    .font(.caption2)
                    .foregroundColor(detailedProgress.executionPhase.color)
                
                Text(detailedProgress.executionPhase.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(detailedProgress.executionPhase.color)
                
                Spacer()
                
                Text(detailedProgress.etaDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct BasicProgressBar: View {
    let progress: Double
    
    var body: some View {
        HStack {
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle())
                .scaleEffect(y: 1.5)
            
            Text("\(Int(progress * 100))%")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(minWidth: 35)
        }
    }
}

struct DetailedProgressInfo: View {
    let detailedProgress: DetailedExecutionProgress
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Current step
            HStack {
                Text(detailedProgress.progressDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let eta = detailedProgress.estimatedTimeRemaining, eta > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(detailedProgress.etaDescription)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            
            // Sub-steps (if available and not too many)
            if !detailedProgress.subSteps.isEmpty && detailedProgress.subSteps.count <= 3 {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(detailedProgress.subSteps.prefix(3), id: \.id) { subStep in
                        HStack(spacing: 6) {
                            Image(systemName: subStep.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.caption2)
                                .foregroundColor(subStep.isCompleted ? .green : .gray)
                            
                            Text(subStep.name)
                                .font(.caption2)
                                .foregroundColor(subStep.isCompleted ? .secondary : .primary)
                                .strikethrough(subStep.isCompleted)
                            
                            Spacer()
                            
                            if let duration = subStep.duration {
                                Text("\(duration, specifier: "%.1f")s")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(.leading, 8)
            }
        }
    }
}

struct CommandDetailsSection: View {
    let command: QueuedCommand
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Divider()
            
            // Target system and mode
            HStack {
                Label(command.request.targetSystem.rawValue, systemImage: "cpu")
                Spacer()
                if command.request.targetSystem == .claudeCode {
                    Label(command.request.mode.rawValue, systemImage: "gear")
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            // Enhancement options
            if command.request.enhancementOptions.includeSystemContext ||
               command.request.enhancementOptions.includeErrorLogs ||
               command.request.enhancementOptions.includeTimestamp {
                HStack {
                    Text("Enhancements:")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 8) {
                        if command.request.enhancementOptions.includeSystemContext {
                            Text("Context")
                                .font(.caption2)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(.blue.opacity(0.2))
                                .cornerRadius(4)
                        }
                        if command.request.enhancementOptions.includeErrorLogs {
                            Text("Logs")
                                .font(.caption2)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(.orange.opacity(0.2))
                                .cornerRadius(4)
                        }
                        if command.request.enhancementOptions.includeTimestamp {
                            Text("Timestamp")
                                .font(.caption2)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(.green.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    
                    Spacer()
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            // Response format
            HStack {
                Text("Output format:")
                    .font(.caption)
                Text(command.request.enhancementOptions.responseFormat.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
            }
            .foregroundColor(.secondary)
            
            // Command result (if completed)
            if let result = command.result {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Result:")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Text(result.displayOutput.prefix(100) + (result.displayOutput.count > 100 ? "..." : ""))
                        .font(.caption)
                        .padding(8)
                        .background(.gray.opacity(0.1))
                        .cornerRadius(6)
                }
                .foregroundColor(.secondary)
            }
        }
    }
}

struct CommandMetadataFooter: View {
    let command: QueuedCommand
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
    
    var body: some View {
        HStack {
            // Enqueue time
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption2)
                Text("Queued \(command.enqueuedAt, formatter: timeFormatter)")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            Spacer()
            
            // Estimated duration
            if let estimatedDuration = command.request.estimatedDuration {
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.caption2)
                    Text("~\(Int(estimatedDuration))s")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
    }
}

struct CommandContextMenu: View {
    let command: QueuedCommand
    let onCancel: () -> Void
    let onReprioritize: (CommandPriority) -> Void
    
    var body: some View {
        Group {
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
            
            Button("Copy Command ID") {
                UIPasteboard.general.string = command.id.uuidString
            }
        }
    }
}

// MARK: - Preview

struct SelectableCommandRow_Previews: PreviewProvider {
    static var previews: some View {
        let sampleCommand = QueuedCommand(
            id: UUID(),
            request: CommandRequest(
                id: UUID(),
                prompt: "Analyze the current system performance and provide optimization recommendations based on recent metrics.",
                targetSystem: .claudeCode,
                mode: .normal,
                enhancementOptions: PromptEnhancementOptions(
                    includeSystemContext: true,
                    includeErrorLogs: false,
                    includeTimestamp: true,
                    responseFormat: .markdown
                ),
                estimatedDuration: 30.0,
                createdAt: Date()
            ),
            priority: .high,
            enqueuedAt: Date(),
            status: .executing,
            progress: 0.65,
            estimatedDuration: 30.0
        )
        
        VStack {
            SelectableCommandRow(
                command: sampleCommand,
                isSelected: false,
                isInEditMode: false,
                onSelectionToggle: {},
                onCancel: {},
                onReprioritize: { _ in }
            )
            
            SelectableCommandRow(
                command: sampleCommand,
                isSelected: true,
                isInEditMode: true,
                onSelectionToggle: {},
                onCancel: {},
                onReprioritize: { _ in }
            )
        }
        .padding()
    }
}