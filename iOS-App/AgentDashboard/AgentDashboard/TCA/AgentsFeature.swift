//
//  AgentsFeature.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Agents management feature for monitoring and controlling agents
//

import ComposableArchitecture
import Foundation
import SwiftUI
import IdentifiedCollections

@Reducer
public struct AgentsFeature {
    // MARK: - State
    @ObservableState
    public struct State: Equatable {
        public var agents: IdentifiedArrayOf<Agent> = []
        public var selectedAgent: Agent?
        public var isLoading: Bool = false
        public var searchText: String = ""
        public var filterStatus: Agent.Status?
        public var sortOrder: SortOrder = .name
        public var isCreatingNewAgent: Bool = false
        public var newAgentForm: NewAgentForm = NewAgentForm()
        public var alertMessage: String?
        
        public enum SortOrder: String, CaseIterable {
            case name = "Name"
            case status = "Status"
            case lastActivity = "Last Activity"
            case type = "Type"
        }
        
        public struct NewAgentForm: Equatable {
            public var name: String = ""
            public var type: String = "Analysis"
            public var configuration: [String: String] = [:]
            public var isValid: Bool {
                !name.isEmpty && !type.isEmpty
            }
        }
        
        public var filteredAgents: [Agent] {
            var filtered = agents.elements
            
            // Apply search filter
            if !searchText.isEmpty {
                filtered = filtered.filter { agent in
                    agent.name.localizedCaseInsensitiveContains(searchText) ||
                    agent.type.localizedCaseInsensitiveContains(searchText)
                }
            }
            
            // Apply status filter
            if let statusFilter = filterStatus {
                filtered = filtered.filter { $0.status == statusFilter }
            }
            
            // Apply sorting
            switch sortOrder {
            case .name:
                filtered.sort { $0.name < $1.name }
            case .status:
                filtered.sort { $0.status.rawValue < $1.status.rawValue }
            case .lastActivity:
                filtered.sort { ($0.lastActivity ?? Date.distantPast) > ($1.lastActivity ?? Date.distantPast) }
            case .type:
                filtered.sort { $0.type < $1.type }
            }
            
            return filtered
        }
        
        public init() {}
    }
    
    public enum Action: Equatable {
        case onAppear
        case onDisappear
        case refreshButtonTapped
        case searchTextChanged(String)
        case filterStatusChanged(Agent.Status?)
        case sortOrderChanged(State.SortOrder)
        case agentSelected(Agent?)
        case startAgent(Agent)
        case stopAgent(Agent)
        case restartAgent(Agent)
        case deleteAgent(Agent)
        case createNewAgentTapped
        case cancelNewAgent
        case saveNewAgent
        case newAgentFormUpdated(State.NewAgentForm)
        case agentsReceived([Agent])
        case agentActionCompleted(String)
        case agentActionFailed(String)
        case loadingStateChanged(Bool)
        case alertDismissed
        case webSocketUpdate
    }
    
    @Dependency(\.continuousClock) var clock
    @Dependency(\.uuid) var uuid
    
    public init() {}
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                print("🎯 AgentsFeature: View appeared")
                return .run { send in
                    await send(.refreshButtonTapped)
                    // Start periodic refresh
                    for await _ in self.clock.timer(interval: .seconds(10)) {
                        await send(.refreshButtonTapped)
                    }
                }
                .cancellable(id: CancelID.refreshTimer)
                
            case .onDisappear:
                print("👋 AgentsFeature: View disappeared")
                return .cancel(id: CancelID.refreshTimer)
                
            case .refreshButtonTapped:
                print("🔄 AgentsFeature: Refreshing agents list")
                state.isLoading = true
                
                return .run { send in
                    // Simulate API call - replace with actual API integration
                    try await clock.sleep(for: .milliseconds(500))
                    
                    // Use real agent data from the Unity-Claude-Automation system
                    let mockAgents = Agent.realAgents
                    
                    await send(.agentsReceived(mockAgents))
                    await send(.loadingStateChanged(false))
                } catch: { error, send in
                    await send(.loadingStateChanged(false))
                    await send(.agentActionFailed("Failed to load agents: \(error.localizedDescription)"))
                }
                
            case let .searchTextChanged(text):
                print("🔍 AgentsFeature: Search text changed to '\(text)'")
                state.searchText = text
                return .none
                
            case let .filterStatusChanged(status):
                print("🎯 AgentsFeature: Filter status changed to \(status?.rawValue ?? "all")")
                state.filterStatus = status
                return .none
                
            case let .sortOrderChanged(order):
                print("📋 AgentsFeature: Sort order changed to \(order.rawValue)")
                state.sortOrder = order
                return .none
                
            case let .agentSelected(agent):
                print("🤖 AgentsFeature: Agent selected: \(agent?.name ?? "none")")
                state.selectedAgent = agent
                return .none
                
            case let .startAgent(agent):
                print("▶️ AgentsFeature: Starting agent \(agent.name)")
                return .run { send in
                    // Simulate API call
                    try await clock.sleep(for: .milliseconds(500))
                    await send(.agentActionCompleted("Agent \(agent.name) started successfully"))
                    await send(.refreshButtonTapped)
                } catch: { error, send in
                    await send(.agentActionFailed("Failed to start agent: \(error.localizedDescription)"))
                }
                
            case let .stopAgent(agent):
                print("⏹️ AgentsFeature: Stopping agent \(agent.name)")
                return .run { send in
                    // Simulate API call
                    try await clock.sleep(for: .milliseconds(500))
                    await send(.agentActionCompleted("Agent \(agent.name) stopped successfully"))
                    await send(.refreshButtonTapped)
                } catch: { error, send in
                    await send(.agentActionFailed("Failed to stop agent: \(error.localizedDescription)"))
                }
                
            case let .restartAgent(agent):
                print("🔄 AgentsFeature: Restarting agent \(agent.name)")
                return .run { send in
                    // Simulate API call
                    try await clock.sleep(for: .milliseconds(1000))
                    await send(.agentActionCompleted("Agent \(agent.name) restarted successfully"))
                    await send(.refreshButtonTapped)
                } catch: { error, send in
                    await send(.agentActionFailed("Failed to restart agent: \(error.localizedDescription)"))
                }
                
            case let .deleteAgent(agent):
                print("🗑️ AgentsFeature: Deleting agent \(agent.name)")
                return .run { send in
                    // Simulate API call
                    try await clock.sleep(for: .milliseconds(500))
                    await send(.agentActionCompleted("Agent \(agent.name) deleted successfully"))
                    await send(.refreshButtonTapped)
                } catch: { error, send in
                    await send(.agentActionFailed("Failed to delete agent: \(error.localizedDescription)"))
                }
                
            case .createNewAgentTapped:
                print("➕ AgentsFeature: Create new agent tapped")
                state.isCreatingNewAgent = true
                state.newAgentForm = State.NewAgentForm()
                return .none
                
            case .cancelNewAgent:
                print("❌ AgentsFeature: Cancel new agent")
                state.isCreatingNewAgent = false
                state.newAgentForm = State.NewAgentForm()
                return .none
                
            case .saveNewAgent:
                print("💾 AgentsFeature: Saving new agent")
                guard state.newAgentForm.isValid else {
                    state.alertMessage = "Please fill in all required fields"
                    return .none
                }
                
                return .run { [form = state.newAgentForm] send in
                    // Simulate API call to create agent
                    try await clock.sleep(for: .milliseconds(750))
                    
                    let newAgent = Agent(
                        id: UUID().uuidString,
                        name: form.name,
                        description: "User created agent",
                        type: form.type,
                        status: .idle,
                        startTime: Date(),
                        lastActivity: Date(),
                        metrics: [:]
                    )
                    
                    await send(.agentActionCompleted("Agent \(newAgent.name) created successfully"))
                    await send(.cancelNewAgent)
                    await send(.refreshButtonTapped)
                } catch: { error, send in
                    await send(.agentActionFailed("Failed to create agent: \(error.localizedDescription)"))
                }
                
            case let .newAgentFormUpdated(form):
                print("📝 AgentsFeature: New agent form updated")
                state.newAgentForm = form
                return .none
                
            case let .agentsReceived(agents):
                print("📦 AgentsFeature: Received \(agents.count) agents")
                state.agents = IdentifiedArray(uniqueElements: agents)
                return .none
                
            case let .agentActionCompleted(message):
                print("✅ AgentsFeature: Action completed: \(message)")
                state.alertMessage = message
                return .none
                
            case let .agentActionFailed(error):
                print("❌ AgentsFeature: Action failed: \(error)")
                state.alertMessage = error
                return .none
                
            case let .loadingStateChanged(isLoading):
                print("🔄 AgentsFeature: Loading state changed to \(isLoading)")
                state.isLoading = isLoading
                return .none
                
            case .alertDismissed:
                print("💭 AgentsFeature: Alert dismissed")
                state.alertMessage = nil
                return .none
                
            case .webSocketUpdate:
                print("📡 AgentsFeature: WebSocket update received")
                // Parse WebSocket message and update agents
                // TODO: Implement actual WebSocket message parsing  
                return .none
            }
        }
    }
    
    private enum CancelID: Hashable {
        case refreshTimer
    }
}