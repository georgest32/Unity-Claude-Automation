import Foundation
import SwiftUI
import Combine

// Lightweight TCA-like Store implementation for Xcode 16.0 compatibility
@MainActor
class AppStore: ObservableObject {
    @Published var state: AppState
    
    init(initialState: AppState = AppState()) {
        self.state = initialState
    }
    
    func send(_ action: AppAction) {
        let newState = reduce(state: state, action: action)
        state = newState
    }
    
    private func reduce(state: AppState, action: AppAction) -> AppState {
        var newState = state
        
        switch action {
        case let .tabSelected(tab):
            newState.selectedTab = tab
            
        case .loadAgents:
            newState.agents = Agent.mockAgents
            
        case .loadSystemStatus:
            newState.systemStatus = SystemStatus.mock
            
        case .refresh:
            // Simulate refresh
            newState.lastUpdate = Date()
        }
        
        return newState
    }
}

// MARK: - State
struct AppState: Equatable {
    var selectedTab: Tab = .dashboard
    var agents: [Agent] = []
    var systemStatus: SystemStatus?
    var lastUpdate: Date?
    
    enum Tab: String, CaseIterable {
        case dashboard = "Dashboard"
        case agents = "Agents"
        case terminal = "Terminal"
        case analytics = "Analytics"
        case settings = "Settings"
        
        var iconName: String {
            switch self {
            case .dashboard: return "square.grid.2x2"
            case .agents: return "person.2"
            case .terminal: return "terminal"
            case .analytics: return "chart.line.uptrend.xyaxis"
            case .settings: return "gear"
            }
        }
    }
}

// MARK: - Actions
enum AppAction: Equatable {
    case tabSelected(AppState.Tab)
    case loadAgents
    case loadSystemStatus
    case refresh
}