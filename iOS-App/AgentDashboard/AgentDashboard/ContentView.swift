import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .dashboard
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Image(systemName: Tab.dashboard.iconName)
                    Text(Tab.dashboard.rawValue)
                }
                .tag(Tab.dashboard)
            
            Text("Agents")
                .tabItem {
                    Image(systemName: Tab.agents.iconName)
                    Text(Tab.agents.rawValue)
                }
                .tag(Tab.agents)
            
            Text("Terminal")
                .tabItem {
                    Image(systemName: Tab.terminal.iconName)
                    Text(Tab.terminal.rawValue)
                }
                .tag(Tab.terminal)
            
            Text("Analytics")
                .tabItem {
                    Image(systemName: Tab.analytics.iconName)
                    Text(Tab.analytics.rawValue)
                }
                .tag(Tab.analytics)
            
            Text("Settings")
                .tabItem {
                    Image(systemName: Tab.settings.iconName)
                    Text(Tab.settings.rawValue)
                }
                .tag(Tab.settings)
        }
    }
    
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

// Note: Sophisticated views are implemented in separate files:
// - DashboardView: Views/DashboardView.swift (TCA-based with widgets)
// - AgentsView: Views/Agents/ directory  
// - TerminalView: Views/Terminal/ directory
// - AnalyticsView: Views/Analytics/ directory
// - SettingsView: Views/Settings/ directory