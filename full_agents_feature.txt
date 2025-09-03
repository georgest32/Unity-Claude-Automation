//
//  AgentsFeature.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Agents management feature for monitoring and controlling agents
//

import ComposableArchitecture
import Foundation

@Reducer
struct AgentsFeature {
    // MARK: - State
    struct State: Equatable {
        var agents: [Agent] = []
        var selectedAgent: Agent?
        var isLoading: Bool = false
        var error: String?
        var filterStatus: AgentStatus?
        var sortOrder: SortOrder = .name
        
        enum SortOrder: String, CaseIterable {
            case name = "Name"
            case status = "Status" 
            case type = "Type"
            case lastActivity = "Last Activity"
            case resourceUsage = "CPU Usage"
        }
        
        // Computed properties
        var filteredAndSortedAgents: [Agent] {
            var filtered = agents
            
            // Apply status filter
            if let filterStatus = filterStatus {
                filtered = filtered.filter { $0.status == filterStatus }
            }
            
            // Apply sorting
            switch sortOrder {
            case .name:
                filtered.sort { $0.name < $1.name }
            case .status:
                filtered.sort { $0.status.rawValue < $1.status.rawValue }
            case .type:
                filtered.sort { $0.type.rawValue < $1.type.rawValue }
            case .lastActivity:
                filtered.sort { 
                    let date1 = $0.lastActivity ?? Date.distantPast
                    let date2 = $1.lastActivity ?? Date.distantPast
                    return date1 > date2 // Most recent first
                }
            case .resourceUsage:
                filtered.sort { 
                    let cpu1 = $0.resourceUsage?.cpu ?? 0
                    let cpu2 = $1.resourceUsage?.cpu ?? 0
                    return cpu1 > cpu2 // Highest usage first
                }
            }
            
            return filtered
        }
        
        var statusCounts: [AgentStatus: Int] {
            var counts: [AgentStatus: Int] = [:]
            for agent in agents {
                counts[agent.status, default: 0] += 1
            }
            return counts
        }
    }
    
    // MARK: - Action
    enum Action: Equatable {
        // Data loading
        case loadAgents
        case agentsLoaded([Agent])
        case loadingFailed(String)
        
        // Real-time updates
        case updateAgentStatus(Data)
        case agentStatusUpdated(Agent)
        
        // User interactions
        case agentTapped(Agent)
        case agentSelected(Agent?)
        case filterByStatus(AgentStatus?)
        case sortOrderChanged(State.SortOrder)
        case refreshRequested
        
        // Agent control
        case startAgent(UUID)
        case stopAgent(UUID)
        case restartAgent(UUID)
        case pauseAgent(UUID)
        case resumeAgent(UUID)
        
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
                print("[AgentsFeature] Agents view appeared")
                return .send(.loadAgents)
                
            case .onDisappear:
                print("[AgentsFeature] Agents view disappeared")
                return .none
                
            // Data loading
            case .loadAgents:
                print("[AgentsFeature] Loading agents...")
                state.isLoading = true
                state.error = nil
                
                return .run { send in
                    do {
                        let agents = try await apiClient.fetchAgents()
                        await send(.agentsLoaded(agents))
                    } catch {
                        await send(.loadingFailed(error.localizedDescription))
                    }
                }
                
            case let .agentsLoaded(agents):
                print("[AgentsFeature] Loaded \(agents.count) agents")
                for agent in agents {
                    agent.logStatus()
                }
                state.agents = agents
                state.isLoading = false
                return .none
                
            case let .loadingFailed(error):
                print("[AgentsFeature] Loading failed: \(error)")
                state.error = error
                state.isLoading = false
                return .none
                
            // Real-time updates
            case let .updateAgentStatus(data):
                print("[AgentsFeature] Received agent status update")
                
                // Try to decode as Agent
                if let updatedAgent = try? JSONDecoder().decode(Agent.self, from: data) {
                    return .send(.agentStatusUpdated(updatedAgent))
                }
                
                return .none
                
            case let .agentStatusUpdated(updatedAgent):
                print("[AgentsFeature] Updating agent: \(updatedAgent.name)")
                updatedAgent.logStatus()
                
                // Update the agent in the array
                if let index = state.agents.firstIndex(where: { $0.id == updatedAgent.id }) {
                    state.agents[index] = updatedAgent
                } else {
                    // New agent - add to array
                    state.agents.append(updatedAgent)
                }
                
                // Update selected agent if it matches
                if let selectedAgent = state.selectedAgent, selectedAgent.id == updatedAgent.id {
                    state.selectedAgent = updatedAgent
                }
                
                return .none
                
            // User interactions
            case let .agentTapped(agent):
                print("[AgentsFeature] Agent tapped: \(agent.name)")
                return .send(.agentSelected(agent))
                
            case let .agentSelected(agent):
                print("[AgentsFeature] Agent selected: \(agent?.name ?? "None")")
                state.selectedAgent = agent
                return .none
                
            case let .filterByStatus(status):
                print("[AgentsFeature] Filter by status: \(status?.rawValue ?? "All")")
                state.filterStatus = status
                return .none
                
            case let .sortOrderChanged(order):
                print("[AgentsFeature] Sort order changed: \(order.rawValue)")
                state.sortOrder = order
                return .none
                
            case .refreshRequested:
                print("[AgentsFeature] Manual refresh requested")
                return .send(.loadAgents)
                
            // Agent control with enhanced error handling and loading states
            case let .startAgent(id):
                print("[AgentsFeature] Start agent request: \(id)")
                
                // Find the agent to validate operation
                guard let agent = state.agents.first(where: { $0.id == id }) else {
                    print("[AgentsFeature] Error: Agent not found for start operation")
                    state.error = "Agent not found"
                    return .none
                }
                
                // Check if agent is in a valid state to start
                guard agent.status != .running else {
                    print("[AgentsFeature] Error: Agent already running")
                    state.error = "Agent is already running"
                    return .none
                }
                
                // Update agent state to show loading
                if let index = state.agents.firstIndex(where: { $0.id == id }) {
                    var updatedAgent = state.agents[index]
                    state.agents[index] = Agent(
                        id: updatedAgent.id,
                        name: updatedAgent.name,
                        type: updatedAgent.type,
                        status: .running, // Optimistically update
                        description: updatedAgent.description,
                        startTime: Date(),
                        lastActivity: Date(),
                        resourceUsage: updatedAgent.resourceUsage,
                        configuration: updatedAgent.configuration
                    )
                }
                
                return .run { send in
                    do {
                        let result = try await apiClient.startAgent(id)
                        print("[AgentsFeature] Start agent success: \(result)")
                        await send(.agentsLoaded(try await apiClient.fetchAgents()))
                    } catch {
                        print("[AgentsFeature] Start agent failed: \(error.localizedDescription)")
                        await send(.loadingFailed("Failed to start agent: \(error.localizedDescription)"))
                        // Refresh agents to restore correct state
                        await send(.loadAgents)
                    }
                }
                
            case let .stopAgent(id):
                print("[AgentsFeature] Stop agent request: \(id)")
                
                guard let agent = state.agents.first(where: { $0.id == id }) else {
                    print("[AgentsFeature] Error: Agent not found for stop operation")
                    state.error = "Agent not found"
                    return .none
                }
                
                guard agent.status == .running || agent.status == .paused else {
                    print("[AgentsFeature] Error: Agent not in stoppable state")
                    state.error = "Agent is not running"
                    return .none
                }
                
                // Optimistically update state
                if let index = state.agents.firstIndex(where: { $0.id == id }) {
                    var updatedAgent = state.agents[index]
                    state.agents[index] = Agent(
                        id: updatedAgent.id,
                        name: updatedAgent.name,
                        type: updatedAgent.type,
                        status: .stopped,
                        description: updatedAgent.description,
                        startTime: updatedAgent.startTime,
                        lastActivity: Date(),
                        resourceUsage: nil, // Clear resource usage when stopped
                        configuration: updatedAgent.configuration
                    )
                }
                
                return .run { send in
                    do {
                        let result = try await apiClient.stopAgent(id)
                        print("[AgentsFeature] Stop agent success: \(result)")
                        await send(.agentsLoaded(try await apiClient.fetchAgents()))
                    } catch {
                        print("[AgentsFeature] Stop agent failed: \(error.localizedDescription)")
                        await send(.loadingFailed("Failed to stop agent: \(error.localizedDescription)"))
                        await send(.loadAgents)
                    }
                }
                
            case let .restartAgent(id):
                print("[AgentsFeature] Restart agent request: \(id)")
                
                guard let agent = state.agents.first(where: { $0.id == id }) else {
                    state.error = "Agent not found"
                    return .none
                }
                
                // For restart, we'll do a stop then start sequence
                return .run { send in
                    do {
                        print("[AgentsFeature] Initiating restart sequence for agent \(id)")
                        
                        // If agent is running, stop it first
                        if agent.status == .running || agent.status == .paused {
                            print("[AgentsFeature] Stopping agent before restart")
                            _ = try await apiClient.stopAgent(id)
                            // Small delay to ensure clean shutdown
                            try await clock.sleep(for: .seconds(1))
                        }
                        
                        // Start the agent
                        print("[AgentsFeature] Starting agent after restart")
                        let result = try await apiClient.startAgent(id)
                        print("[AgentsFeature] Restart agent success: \(result)")
                        
                        // Refresh all agents
                        await send(.agentsLoaded(try await apiClient.fetchAgents()))
                    } catch {
                        print("[AgentsFeature] Restart agent failed: \(error.localizedDescription)")
                        await send(.loadingFailed("Failed to restart agent: \(error.localizedDescription)"))
                        await send(.loadAgents)
                    }
                }
                
            case let .pauseAgent(id):
                print("[AgentsFeature] Pause agent request: \(id)")
                
                guard let agent = state.agents.first(where: { $0.id == id }) else {
                    state.error = "Agent not found"
                    return .none
                }
                
                guard agent.status == .running else {
                    state.error = "Agent must be running to pause"
                    return .none
                }
                
                // Optimistically update state
                if let index = state.agents.firstIndex(where: { $0.id == id }) {
                    var updatedAgent = state.agents[index]
                    state.agents[index] = Agent(
                        id: updatedAgent.id,
                        name: updatedAgent.name,
                        type: updatedAgent.type,
                        status: .paused,
                        description: updatedAgent.description,
                        startTime: updatedAgent.startTime,
                        lastActivity: Date(),
                        resourceUsage: updatedAgent.resourceUsage,
                        configuration: updatedAgent.configuration
                    )
                }
                
                return .run { send in
                    do {
                        let result = try await apiClient.pauseAgent(id)
                        print("[AgentsFeature] Pause agent success: \(result)")
                        await send(.agentsLoaded(try await apiClient.fetchAgents()))
                    } catch {
                        print("[AgentsFeature] Pause agent failed: \(error.localizedDescription)")
                        await send(.loadingFailed("Failed to pause agent: \(error.localizedDescription)"))
                        await send(.loadAgents)
                    }
                }
                
            case let .resumeAgent(id):
                print("[AgentsFeature] Resume agent request: \(id)")
                
                guard let agent = state.agents.first(where: { $0.id == id }) else {
                    state.error = "Agent not found"
                    return .none
                }
                
                guard agent.status == .paused else {
                    state.error = "Agent must be paused to resume"
                    return .none
                }
                
                // Optimistically update state
                if let index = state.agents.firstIndex(where: { $0.id == id }) {
                    var updatedAgent = state.agents[index]
                    state.agents[index] = Agent(
                        id: updatedAgent.id,
                        name: updatedAgent.name,
                        type: updatedAgent.type,
                        status: .running,
                        description: updatedAgent.description,
                        startTime: updatedAgent.startTime,
                        lastActivity: Date(),
                        resourceUsage: updatedAgent.resourceUsage,
                        configuration: updatedAgent.configuration
                    )
                }
                
                return .run { send in
                    do {
                        let result = try await apiClient.resumeAgent(id)
                        print("[AgentsFeature] Resume agent success: \(result)")
                        await send(.agentsLoaded(try await apiClient.fetchAgents()))
                    } catch {
                        print("[AgentsFeature] Resume agent failed: \(error.localizedDescription)")
                        await send(.loadingFailed("Failed to resume agent: \(error.localizedDescription)"))
                        await send(.loadAgents)
                    }
                }
            }
        }
    }
}

// MARK: - Helper Extensions

extension AgentsFeature.State {
    var totalAgents: Int { agents.count }
    var runningAgents: Int { statusCounts[.running] ?? 0 }
    var idleAgents: Int { statusCounts[.idle] ?? 0 }
    var stoppedAgents: Int { statusCounts[.stopped] ?? 0 }
    var errorAgents: Int { statusCounts[.error] ?? 0 }
    
    var healthSummary: String {
        let running = runningAgents
        let total = totalAgents
        let healthy = running + idleAgents
        
        if total == 0 {
            return "No agents"
        } else if errorAgents > 0 {
            return "\(errorAgents) error\(errorAgents == 1 ? "" : "s"), \(running)/\(total) running"
        } else {
            return "\(running)/\(total) running, \(healthy) healthy"
        }
    }
}