//
//  TerminalFeature.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Terminal feature for command execution and output display
//

import ComposableArchitecture
import Foundation

@Reducer
struct TerminalFeature {
    // MARK: - State
    struct State: Equatable {
        var outputLines: [TerminalLine] = []
        var commandHistory: [String] = []
        var currentCommand: String = ""
        var isExecuting: Bool = false
        var error: String?
        var historyIndex: Int = 0
        var maxOutputLines: Int = 1000
        
        // Terminal settings
        var fontSize: Double = 13.0
        var isWrapText: Bool = true
        var showTimestamps: Bool = true
        var autoScroll: Bool = true
        
        // Filtering
        var filterText: String = ""
        var filterLevel: LogLevel? = nil
        
        enum LogLevel: String, CaseIterable {
            case info = "INFO"
            case warning = "WARNING" 
            case error = "ERROR"
            case debug = "DEBUG"
        }
        
        // Computed properties
        var filteredOutputLines: [TerminalLine] {
            var lines = outputLines
            
            // Apply text filter
            if !filterText.isEmpty {
                lines = lines.filter { $0.content.localizedCaseInsensitiveContains(filterText) }
            }
            
            // Apply level filter
            if let filterLevel = filterLevel {
                lines = lines.filter { $0.level == filterLevel }
            }
            
            return lines
        }
        
        var commandPrompt: String {
            "AgentDashboard> "
        }
    }
    
    struct TerminalLine: Equatable, Identifiable {
        let id = UUID()
        let content: String
        let timestamp: Date
        let level: State.LogLevel
        let source: String?
        
        init(content: String, level: State.LogLevel = .info, source: String? = nil) {
            self.content = content
            self.level = level
            self.source = source
            self.timestamp = Date()
        }
    }
    
    // MARK: - Action
    enum Action: Equatable {
        // Command execution
        case commandTextChanged(String)
        case executeCommand
        case commandExecuted(CommandResult)
        case executionFailed(String)
        
        // Output management
        case appendOutput(Data)
        case clearOutput
        case outputLineAdded(TerminalLine)
        
        // History management
        case navigateHistoryUp
        case navigateHistoryDown
        case clearHistory
        
        // Filtering and display
        case filterTextChanged(String)
        case filterLevelChanged(State.LogLevel?)
        case toggleTimestamps
        case toggleWrapText
        case toggleAutoScroll
        case fontSizeChanged(Double)
        
        // Terminal control
        case copyOutput
        case exportOutput
        case scrollToBottom
        
        // Terminal integration
        case terminalResized(cols: Int, rows: Int)
        case terminalTitleChanged(String)
        
        // Lifecycle
        case onAppear
        case onDisappear
    }
    
    // MARK: - Dependencies
    @Dependency(\.apiClient) var apiClient
    @Dependency(\.continuousClock) var clock
    
    // MARK: - Reducer
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            // Lifecycle
            case .onAppear:
                print("[TerminalFeature] Terminal appeared")
                // Add welcome message
                let welcomeLine = TerminalLine(
                    content: "Unity-Claude-Automation Terminal Ready",
                    level: .info,
                    source: "system"
                )
                return .send(.outputLineAdded(welcomeLine))
                
            case .onDisappear:
                print("[TerminalFeature] Terminal disappeared")
                return .none
                
            // Command execution
            case let .commandTextChanged(text):
                state.currentCommand = text
                return .none
                
            case .executeCommand:
                let command = state.currentCommand.trimmingCharacters(in: .whitespacesAndNewlines)
                
                guard !command.isEmpty else { return .none }
                
                print("[TerminalFeature] Executing command: \(command)")
                
                // Add command to history
                if !state.commandHistory.contains(command) {
                    state.commandHistory.append(command)
                }
                state.historyIndex = state.commandHistory.count
                
                // Add command to output
                let commandLine = TerminalLine(
                    content: "\(state.commandPrompt)\(command)",
                    level: .info,
                    source: "user"
                )
                state.outputLines.append(commandLine)
                
                // Clear current command
                state.currentCommand = ""
                state.isExecuting = true
                state.error = nil
                
                return .run { send in
                    do {
                        let result = try await apiClient.executeCommand(command)
                        await send(.commandExecuted(result))
                    } catch {
                        await send(.executionFailed(error.localizedDescription))
                    }
                }
                
            case let .commandExecuted(result):
                print("[TerminalFeature] Command executed with exit code: \(result.exitCode)")
                state.isExecuting = false
                
                // Add output to terminal
                if let output = result.output, !output.isEmpty {
                    let outputLine = TerminalLine(
                        content: output,
                        level: result.exitCode == 0 ? .info : .error,
                        source: "system"
                    )
                    state.outputLines.append(outputLine)
                }
                
                // Add error if present
                if let error = result.error, !error.isEmpty {
                    let errorLine = TerminalLine(
                        content: error,
                        level: .error,
                        source: "system"
                    )
                    state.outputLines.append(errorLine)
                }
                
                // Add execution time info
                let executionInfo = String(format: "Command completed in %.2fs (exit code: %d)", 
                                          result.executionTime, result.exitCode)
                let infoLine = TerminalLine(
                    content: executionInfo,
                    level: .debug,
                    source: "system"
                )
                state.outputLines.append(infoLine)
                
                return .send(.scrollToBottom)
                
            case let .executionFailed(error):
                print("[TerminalFeature] Command execution failed: \(error)")
                state.isExecuting = false
                state.error = error
                
                let errorLine = TerminalLine(
                    content: "Execution failed: \(error)",
                    level: .error,
                    source: "system"
                )
                state.outputLines.append(errorLine)
                
                return .send(.scrollToBottom)
                
            // Output management
            case let .appendOutput(data):
                print("[TerminalFeature] Received terminal output")
                
                // Try to decode as string
                if let outputString = String(data: data, encoding: .utf8) {
                    let outputLine = TerminalLine(
                        content: outputString,
                        level: .info,
                        source: "websocket"
                    )
                    return .send(.outputLineAdded(outputLine))
                }
                
                return .none
                
            case let .outputLineAdded(line):
                state.outputLines.append(line)
                
                // Trim output if it exceeds max lines
                if state.outputLines.count > state.maxOutputLines {
                    state.outputLines.removeFirst(state.outputLines.count - state.maxOutputLines)
                }
                
                return state.autoScroll ? .send(.scrollToBottom) : .none
                
            case .clearOutput:
                print("[TerminalFeature] Clearing output")
                state.outputLines.removeAll()
                return .none
                
            // History management
            case .navigateHistoryUp:
                if state.historyIndex > 0 {
                    state.historyIndex -= 1
                    state.currentCommand = state.commandHistory[state.historyIndex]
                }
                return .none
                
            case .navigateHistoryDown:
                if state.historyIndex < state.commandHistory.count - 1 {
                    state.historyIndex += 1
                    state.currentCommand = state.commandHistory[state.historyIndex]
                } else {
                    state.historyIndex = state.commandHistory.count
                    state.currentCommand = ""
                }
                return .none
                
            case .clearHistory:
                print("[TerminalFeature] Clearing command history")
                state.commandHistory.removeAll()
                state.historyIndex = 0
                return .none
                
            // Filtering and display
            case let .filterTextChanged(text):
                state.filterText = text
                return .none
                
            case let .filterLevelChanged(level):
                state.filterLevel = level
                return .none
                
            case .toggleTimestamps:
                state.showTimestamps.toggle()
                return .none
                
            case .toggleWrapText:
                state.isWrapText.toggle()
                return .none
                
            case .toggleAutoScroll:
                state.autoScroll.toggle()
                return .none
                
            case let .fontSizeChanged(size):
                state.fontSize = max(8, min(24, size)) // Clamp between 8-24
                return .none
                
            // Terminal control
            case .copyOutput:
                print("[TerminalFeature] Copying output to clipboard")
                // TODO: Implement clipboard copy
                return .none
                
            case .exportOutput:
                print("[TerminalFeature] Exporting output")
                // TODO: Implement export functionality
                return .none
                
            case .scrollToBottom:
                // This would be handled by the view layer
                return .none
                
            // Terminal integration
            case let .terminalResized(cols, rows):
                print("[TerminalFeature] Terminal resized: \(cols)x\(rows)")
                // Could store terminal dimensions in state if needed
                return .none
                
            case let .terminalTitleChanged(title):
                print("[TerminalFeature] Terminal title changed: \(title)")
                // Could store terminal title in state if needed
                return .none
            }
        }
    }
}

// MARK: - Helper Extensions

extension TerminalFeature.State {
    var outputSummary: String {
        let total = outputLines.count
        let errors = outputLines.filter { $0.level == .error }.count
        let warnings = outputLines.filter { $0.level == .warning }.count
        
        if errors > 0 {
            return "\(total) lines (\(errors) errors, \(warnings) warnings)"
        } else if warnings > 0 {
            return "\(total) lines (\(warnings) warnings)"
        } else {
            return "\(total) lines"
        }
    }
    
    var recentCommand: String? {
        commandHistory.last
    }
}