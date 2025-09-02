//
//  PromptFeature.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  AI prompt submission feature for Claude Code CLI and other AI systems
//

import ComposableArchitecture
import Foundation

@Reducer
struct PromptFeature {
    // MARK: - State
    struct State: Equatable {
        // Prompt composition
        var currentPrompt: String = ""
        var promptDraft: String = ""
        var characterCount: Int = 0
        var maxCharacters: Int = 10000
        
        // Target system selection
        var selectedAISystem: AISystem = .claudeCode
        var selectedMode: AIMode = .normal
        var systemStatus: SystemConnectionStatus = .disconnected
        
        // Prompt enhancement
        var includeSystemContext: Bool = true
        var includeErrorLogs: Bool = false
        var includeTimestamp: Bool = true
        var responseFormat: ResponseFormat = .markdown
        
        // Execution state
        var isSubmitting: Bool = false
        var submissionProgress: Double = 0.0
        var lastSubmissionTime: Date?
        var error: String?
        
        // Templates and suggestions
        var availableTemplates: [PromptTemplate] = []
        var recentPrompts: [String] = []
        var promptSuggestions: [String] = []
        
        enum AISystem: String, CaseIterable {
            case claudeCode = "Claude Code CLI"
            case autoGen = "AutoGen"
            case langGraph = "LangGraph"
            case custom = "Custom System"
            
            var icon: String {
                switch self {
                case .claudeCode: return "terminal"
                case .autoGen: return "person.3"
                case .langGraph: return "flowchart"
                case .custom: return "gear"
                }
            }
            
            var supportsModes: Bool {
                switch self {
                case .claudeCode: return true
                default: return false
                }
            }
        }
        
        enum AIMode: String, CaseIterable {
            case normal = "Normal"
            case headless = "Headless"
            
            var description: String {
                switch self {
                case .normal: return "Interactive mode with full UI"
                case .headless: return "Background execution without UI"
                }
            }
        }
        
        enum SystemConnectionStatus: String {
            case connected = "Connected"
            case disconnected = "Disconnected"
            case connecting = "Connecting"
            case error = "Error"
            
            var color: String {
                switch self {
                case .connected: return "green"
                case .disconnected: return "gray"
                case .connecting: return "orange"
                case .error: return "red"
                }
            }
        }
        
        enum ResponseFormat: String, CaseIterable {
            case markdown = "Markdown"
            case plainText = "Plain Text"
            case json = "JSON"
            case structured = "Structured"
        }
        
        // Computed properties
        var isPromptValid: Bool {
            !currentPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            characterCount <= maxCharacters
        }
        
        var canSubmit: Bool {
            isPromptValid && !isSubmitting && systemStatus == .connected
        }
        
        var promptPreview: String {
            var preview = currentPrompt
            
            if includeTimestamp {
                preview = "Timestamp: \(Date())\n\n" + preview
            }
            
            if includeSystemContext {
                preview += "\n\n[System context would be injected here]"
            }
            
            if includeErrorLogs {
                preview += "\n\n[Recent error logs would be included here]"
            }
            
            return preview
        }
    }
    
    // MARK: - Action
    enum Action: Equatable {
        // Prompt composition
        case promptTextChanged(String)
        case draftSaved
        case draftLoaded
        case clearPrompt
        
        // System selection
        case aiSystemChanged(State.AISystem)
        case aiModeChanged(State.AIMode)
        case systemStatusUpdated(State.SystemConnectionStatus)
        
        // Enhancement options
        case toggleSystemContext
        case toggleErrorLogs
        case toggleTimestamp
        case responseFormatChanged(State.ResponseFormat)
        
        // Template management
        case templateSelected(PromptTemplate)
        case loadTemplates
        case templatesLoaded([PromptTemplate])
        
        // Prompt submission
        case submitPrompt
        case promptSubmitted(PromptSubmissionResult)
        case submissionFailed(String)
        case cancelSubmission
        case submissionProgressUpdated(Double)
        
        // Command queue integration
        case enqueuePromptInQueue(CommandRequest)
        case promptEnqueuedInQueue
        
        // Delegate actions
        case delegate(Delegate)
        
        enum Delegate: Equatable {
            case enqueueCommand(CommandRequest)
            case showCommandQueue
        }
        
        // Suggestions and history
        case loadSuggestions
        case suggestionsLoaded([String])
        case addToRecentPrompts(String)
        
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
                print("[PromptFeature] Prompt submission view appeared")
                return .merge(
                    .send(.loadTemplates),
                    .send(.loadSuggestions)
                )
                
            case .onDisappear:
                print("[PromptFeature] Prompt submission view disappeared")
                return .send(.draftSaved)
                
            // Prompt composition
            case let .promptTextChanged(text):
                state.currentPrompt = text
                state.characterCount = text.count
                
                // Auto-save draft every 10 characters
                if text.count % 10 == 0 {
                    state.promptDraft = text
                }
                
                return .none
                
            case .draftSaved:
                print("[PromptFeature] Draft saved: \(state.currentPrompt.count) characters")
                state.promptDraft = state.currentPrompt
                return .none
                
            case .draftLoaded:
                print("[PromptFeature] Draft loaded")
                state.currentPrompt = state.promptDraft
                state.characterCount = state.promptDraft.count
                return .none
                
            case .clearPrompt:
                print("[PromptFeature] Prompt cleared")
                state.currentPrompt = ""
                state.characterCount = 0
                state.error = nil
                return .none
                
            // System selection
            case let .aiSystemChanged(system):
                print("[PromptFeature] AI system changed: \(system.rawValue)")
                state.selectedAISystem = system
                
                // Reset mode if system doesn't support modes
                if !system.supportsModes {
                    state.selectedMode = .normal
                }
                
                return .send(.systemStatusUpdated(.connecting))
                
            case let .aiModeChanged(mode):
                print("[PromptFeature] AI mode changed: \(mode.rawValue)")
                state.selectedMode = mode
                return .none
                
            case let .systemStatusUpdated(status):
                print("[PromptFeature] System status updated: \(status.rawValue)")
                state.systemStatus = status
                return .none
                
            // Enhancement options
            case .toggleSystemContext:
                state.includeSystemContext.toggle()
                print("[PromptFeature] System context: \(state.includeSystemContext)")
                return .none
                
            case .toggleErrorLogs:
                state.includeErrorLogs.toggle()
                print("[PromptFeature] Error logs: \(state.includeErrorLogs)")
                return .none
                
            case .toggleTimestamp:
                state.includeTimestamp.toggle()
                print("[PromptFeature] Timestamp: \(state.includeTimestamp)")
                return .none
                
            case let .responseFormatChanged(format):
                print("[PromptFeature] Response format changed: \(format.rawValue)")
                state.responseFormat = format
                return .none
                
            // Template management
            case let .templateSelected(template):
                print("[PromptFeature] Template selected: \(template.name)")
                state.currentPrompt = template.content
                state.characterCount = template.content.count
                return .none
                
            case .loadTemplates:
                print("[PromptFeature] Loading prompt templates")
                return .run { send in
                    // Simulate loading templates
                    let templates = generateDefaultTemplates()
                    await send(.templatesLoaded(templates))
                }
                
            case let .templatesLoaded(templates):
                print("[PromptFeature] Loaded \(templates.count) templates")
                state.availableTemplates = templates
                return .none
                
            // Prompt submission
            case .submitPrompt:
                guard state.canSubmit else {
                    print("[PromptFeature] Cannot submit - validation failed")
                    return .none
                }
                
                print("[PromptFeature] Creating command request for queue submission")
                
                // Create CommandRequest for the queue
                let commandRequest = CommandRequest(
                    id: UUID(),
                    prompt: state.promptPreview,
                    targetSystem: mapToCommandRequestAISystem(state.selectedAISystem),
                    mode: mapToCommandRequestAIMode(state.selectedMode),
                    enhancementOptions: PromptEnhancementOptions(
                        includeSystemContext: state.includeSystemContext,
                        includeErrorLogs: state.includeErrorLogs,
                        includeTimestamp: state.includeTimestamp,
                        responseFormat: mapToCommandRequestResponseFormat(state.responseFormat)
                    ),
                    estimatedDuration: estimateExecutionTime(for: state.selectedAISystem, promptLength: state.currentPrompt.count),
                    createdAt: Date()
                )
                
                state.isSubmitting = true
                state.submissionProgress = 0.0
                state.error = nil
                state.lastSubmissionTime = Date()
                
                return .send(.enqueuePromptInQueue(commandRequest))
                
            case let .promptSubmitted(result):
                print("[PromptFeature] Prompt submitted successfully: \(result.id)")
                state.isSubmitting = false
                state.submissionProgress = 1.0
                
                // Add to recent prompts
                return .send(.addToRecentPrompts(state.currentPrompt))
                
            case let .submissionFailed(error):
                print("[PromptFeature] Prompt submission failed: \(error)")
                state.isSubmitting = false
                state.submissionProgress = 0.0
                state.error = error
                return .none
                
            case .cancelSubmission:
                print("[PromptFeature] Prompt submission cancelled")
                state.isSubmitting = false
                state.submissionProgress = 0.0
                return .none
                
            case let .submissionProgressUpdated(progress):
                state.submissionProgress = progress
                return .none
                
            // Suggestions and history
            case .loadSuggestions:
                print("[PromptFeature] Loading prompt suggestions")
                return .run { send in
                    let suggestions = generatePromptSuggestions()
                    await send(.suggestionsLoaded(suggestions))
                }
                
            case let .suggestionsLoaded(suggestions):
                print("[PromptFeature] Loaded \(suggestions.count) suggestions")
                state.promptSuggestions = suggestions
                return .none
                
            case let .addToRecentPrompts(prompt):
                print("[PromptFeature] Adding to recent prompts")
                let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty && !state.recentPrompts.contains(trimmed) {
                    state.recentPrompts.insert(trimmed, at: 0)
                    // Keep only last 10 prompts
                    if state.recentPrompts.count > 10 {
                        state.recentPrompts = Array(state.recentPrompts.prefix(10))
                    }
                }
                return .none
                
            // Command queue integration
            case let .enqueuePromptInQueue(commandRequest):
                print("[PromptFeature] Enqueueing prompt in command queue: \(commandRequest.id)")
                return .merge(
                    .send(.delegate(.enqueueCommand(commandRequest))),
                    .send(.promptEnqueuedInQueue)
                )
                
            case .promptEnqueuedInQueue:
                print("[PromptFeature] Prompt successfully enqueued in command queue")
                state.isSubmitting = false
                state.submissionProgress = 1.0
                
                // Add to recent prompts
                return .send(.addToRecentPrompts(state.currentPrompt))
                
            // Delegate actions
            case .delegate:
                return .none
            }
        }
    }
}

// MARK: - Supporting Models

struct PromptTemplate: Equatable, Identifiable {
    let id = UUID()
    let name: String
    let content: String
    let category: String
    let description: String
}

struct PromptSubmissionResult: Equatable {
    let id: UUID
    let submittedAt: Date
    let aiSystem: PromptFeature.State.AISystem
    let responseReceived: Bool
    let executionTime: TimeInterval
}

// MARK: - Helper Functions

private func generateDefaultTemplates() -> [PromptTemplate] {
    return [
        PromptTemplate(
            name: "System Analysis",
            content: "Please analyze the current system status and provide recommendations for optimization.",
            category: "System",
            description: "General system analysis prompt"
        ),
        PromptTemplate(
            name: "Error Investigation", 
            content: "Investigate the recent errors and suggest solutions:\n\n[Error details will be inserted here]",
            category: "Debugging",
            description: "Template for error analysis"
        ),
        PromptTemplate(
            name: "Performance Review",
            content: "Review system performance metrics and identify bottlenecks or improvement opportunities.",
            category: "Performance",
            description: "Performance analysis template"
        )
    ]
}

private func generatePromptSuggestions() -> [String] {
    return [
        "Analyze current agent performance",
        "Review recent error patterns",
        "Optimize system configuration",
        "Generate status report",
        "Check module dependencies"
    ]
}

// MARK: - Helper Functions for Command Queue Integration

private func mapToCommandRequestAISystem(_ system: PromptFeature.State.AISystem) -> CommandRequest.AISystem {
    switch system {
    case .claudeCode: return .claudeCode
    case .autoGen: return .autoGen
    case .langGraph: return .langGraph
    case .custom: return .custom
    }
}

private func mapToCommandRequestAIMode(_ mode: PromptFeature.State.AIMode) -> CommandRequest.AIMode {
    switch mode {
    case .normal: return .normal
    case .headless: return .headless
    }
}

private func mapToCommandRequestResponseFormat(_ format: PromptFeature.State.ResponseFormat) -> PromptEnhancementOptions.ResponseFormat {
    switch format {
    case .markdown: return .markdown
    case .plainText: return .plainText
    case .json: return .json
    case .structured: return .structured
    }
}

private func estimateExecutionTime(for system: PromptFeature.State.AISystem, promptLength: Int) -> TimeInterval {
    let baseTime: TimeInterval = 5.0 // 5 seconds base
    let lengthMultiplier = Double(promptLength) / 100.0 // 1 second per 100 characters
    
    let systemMultiplier: Double
    switch system {
    case .claudeCode: systemMultiplier = 1.0
    case .autoGen: systemMultiplier = 1.5
    case .langGraph: systemMultiplier = 2.0
    case .custom: systemMultiplier = 1.2
    }
    
    return baseTime + lengthMultiplier * systemMultiplier
}

private func submitPromptToAISystem(prompt: String, system: PromptFeature.State.AISystem) async throws -> PromptSubmissionResult {
    // Simulate prompt submission (legacy - now using command queue)
    print("[PromptFeature] Submitting to \(system.rawValue): \(prompt.prefix(50))...")
    
    try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
    
    return PromptSubmissionResult(
        id: UUID(),
        submittedAt: Date(),
        aiSystem: system,
        responseReceived: true,
        executionTime: 2.0
    )
}