//
//  DashboardFeature.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Dashboard feature for system overview and real-time metrics
//

import ComposableArchitecture
import Foundation

@Reducer
struct DashboardFeature: Sendable {
    // MARK: - State
    @ObservableState
    struct State: Equatable {
        var systemStatus: SystemStatus?
        var agents: [Agent] = []
        var alerts: [Alert] = []
        var isLoading: Bool = false
        var error: String?
        var lastUpdate: Date?
        
        // Computed properties
        var activeAgentCount: Int {
            agents.filter { $0.status == .running }.count
        }
        
        var systemHealthColor: String {
            guard let status = systemStatus else { return "gray" }
            return status.isHealthy ? "green" : "red"
        }
    }
    
    // MARK: - Action
    enum Action: Equatable {
        // Data loading
        case loadDashboard
        case systemStatusLoaded(SystemStatus)
        case agentsLoaded([Agent])
        case loadingFailed(String)
        
        // Real-time updates
        case updateMetrics(Data)
        case showAlert(Data)
        case clearAlert(UUID)
        
        // User interactions
        case refreshRequested
        case alertTapped(Alert)
        
        // Lifecycle
        case onAppear
        case onDisappear
    }
    
    // MARK: - Dependencies
    @Dependency(\.continuousClock) var clock
    // Note: apiClient dependency to be added when APIClient is properly defined
    
    // MARK: - Reducer
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            // Lifecycle
            case .onAppear:
                print("[DashboardFeature] Dashboard appeared")
                return .send(.loadDashboard)
                
            case .onDisappear:
                print("[DashboardFeature] Dashboard disappeared")
                return .none
                
            // Data loading
            case .loadDashboard:
                print("[DashboardFeature] Loading dashboard data...")
                state.isLoading = true
                state.error = nil
                
                return .run { send in
                    do {
                        async let systemStatus = apiClient.fetchSystemStatus()
                        async let agents = apiClient.fetchAgents()
                        
                        let (status, agentList) = try await (systemStatus, agents)
                        
                        await send(.systemStatusLoaded(status))
                        await send(.agentsLoaded(agentList))
                    } catch {
                        await send(.loadingFailed(error.localizedDescription))
                    }
                }
                
            case let .systemStatusLoaded(systemStatus):
                print("[DashboardFeature] System status loaded")
                systemStatus.debugDescription
                state.systemStatus = systemStatus
                state.lastUpdate = Date()
                state.isLoading = false
                return .none
                
            case let .agentsLoaded(agents):
                print("[DashboardFeature] Loaded \(agents.count) agents")
                state.agents = agents
                return .none
                
            case let .loadingFailed(error):
                print("[DashboardFeature] Loading failed: \(error)")
                state.error = error
                state.isLoading = false
                return .none
                
            // Real-time updates
            case let .updateMetrics(data):
                print("[DashboardFeature] Received metrics update")
                
                // Try to decode as SystemStatus
                if let systemStatus = try? JSONDecoder().decode(SystemStatus.self, from: data) {
                    state.systemStatus = systemStatus
                    state.lastUpdate = Date()
                    print("[DashboardFeature] System status updated from WebSocket")
                }
                
                return .none
                
            case let .showAlert(data):
                print("[DashboardFeature] Received alert")
                
                // Try to decode as Alert
                if let alert = try? JSONDecoder().decode(Alert.self, from: data) {
                    state.alerts.insert(alert, at: 0) // Insert at beginning
                    alert.logAlert()
                    
                    // Auto-dismiss info alerts after 5 seconds
                    if alert.severity == .info {
                        return .run { send in
                            try await clock.sleep(for: .seconds(5))
                            await send(.clearAlert(alert.id))
                        }
                    }
                }
                
                return .none
                
            case let .clearAlert(id):
                print("[DashboardFeature] Clearing alert: \(id)")
                state.alerts.removeAll { $0.id == id }
                return .none
                
            // User interactions
            case .refreshRequested:
                print("[DashboardFeature] Manual refresh requested")
                return .send(.loadDashboard)
                
            case let .alertTapped(alert):
                print("[DashboardFeature] Alert tapped: \(alert.title)")
                // Handle alert tap - could show detail view or dismiss
                return .send(.clearAlert(alert.id))
            }
        }
    }
}

// MARK: - Helper Extensions

extension DashboardFeature.State {
    var statusSummary: String {
        guard let status = systemStatus else {
            return "Loading..."
        }
        
        let health = status.isHealthy ? "Healthy" : "Unhealthy"
        let cpu = String(format: "%.1f%%", status.cpuUsage)
        let memory = String(format: "%.1f%%", status.memoryUsage)
        
        return "\(health) • CPU: \(cpu) • Memory: \(memory) • \(activeAgentCount)/\(agents.count) agents active"
    }
    
    var uptimeFormatted: String {
        guard let uptime = systemStatus?.uptime else { return "Unknown" }
        
        let hours = Int(uptime) / 3600
        let minutes = Int(uptime) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}