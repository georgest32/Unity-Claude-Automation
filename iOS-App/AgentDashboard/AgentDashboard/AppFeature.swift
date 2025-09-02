import ComposableArchitecture
import Foundation

@Reducer
public struct AppFeature {
    @ObservableState
    public struct State: Equatable {
        var selectedTab: Tab = .dashboard
        var isAuthenticated = false
        var appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        var buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        
        public enum Tab: String, CaseIterable, Equatable {
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
    
    public enum Action: Equatable {
        case tabSelected(State.Tab)
        case authenticateUser
        case logout
        case checkAuthenticationStatus
        case applicationDidBecomeActive
    }
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .tabSelected(tab):
                state.selectedTab = tab
                return .none
                
            case .authenticateUser:
                // Simple mock authentication
                state.isAuthenticated = true
                return .none
                
            case .logout:
                state.isAuthenticated = false
                return .none
                
            case .checkAuthenticationStatus:
                // Check authentication status
                return .none
                
            case .applicationDidBecomeActive:
                // Handle app becoming active
                return .none
            }
        }
    }
}