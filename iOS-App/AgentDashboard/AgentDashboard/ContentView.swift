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
            
            AgentsView()
                .tabItem {
                    Image(systemName: Tab.agents.iconName)
                    Text(Tab.agents.rawValue)
                }
                .tag(Tab.agents)
            
            TerminalView()
                .tabItem {
                    Image(systemName: Tab.terminal.iconName)
                    Text(Tab.terminal.rawValue)
                }
                .tag(Tab.terminal)
            
            AnalyticsView()
                .tabItem {
                    Image(systemName: Tab.analytics.iconName)
                    Text(Tab.analytics.rawValue)
                }
                .tag(Tab.analytics)
            
            SettingsView()
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

// Basic placeholder views for each tab
struct DashboardView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "square.grid.2x2")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                Text("Agent Dashboard")
                    .font(.title)
                    .padding()
                Text("Unity-Claude-Automation iOS App")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("Dashboard")
        }
    }
}

struct AgentsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "person.2")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                Text("Agents")
                    .font(.title)
                    .padding()
                Text("Agent Management")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("Agents")
        }
    }
}

struct TerminalView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "terminal")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                Text("Terminal")
                    .font(.title)
                    .padding()
                Text("Command Interface")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("Terminal")
        }
    }
}

struct AnalyticsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                Text("Analytics")
                    .font(.title)
                    .padding()
                Text("Performance Metrics")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("Analytics")
        }
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "gear")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                Text("Settings")
                    .font(.title)
                    .padding()
                Text("App Configuration")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("Settings")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}