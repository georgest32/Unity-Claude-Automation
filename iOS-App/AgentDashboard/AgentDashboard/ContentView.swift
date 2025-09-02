import SwiftUI
import ComposableArchitecture

struct ContentView: View {
    let store: StoreOf<AppFeature>
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            TabView(selection: viewStore.binding(
                get: \.selectedTab,
                send: AppFeature.Action.tabSelected
            )) {
                DashboardView()
                    .tabItem {
                        Image(systemName: AppFeature.State.Tab.dashboard.iconName)
                        Text(AppFeature.State.Tab.dashboard.rawValue)
                    }
                    .tag(AppFeature.State.Tab.dashboard)
                
                AgentsView()
                    .tabItem {
                        Image(systemName: AppFeature.State.Tab.agents.iconName)
                        Text(AppFeature.State.Tab.agents.rawValue)
                    }
                    .tag(AppFeature.State.Tab.agents)
                
                TerminalView()
                    .tabItem {
                        Image(systemName: AppFeature.State.Tab.terminal.iconName)
                        Text(AppFeature.State.Tab.terminal.rawValue)
                    }
                    .tag(AppFeature.State.Tab.terminal)
                
                AnalyticsView()
                    .tabItem {
                        Image(systemName: AppFeature.State.Tab.analytics.iconName)
                        Text(AppFeature.State.Tab.analytics.rawValue)
                    }
                    .tag(AppFeature.State.Tab.analytics)
                
                SettingsView()
                    .tabItem {
                        Image(systemName: AppFeature.State.Tab.settings.iconName)
                        Text(AppFeature.State.Tab.settings.rawValue)
                    }
                    .tag(AppFeature.State.Tab.settings)
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
        ContentView(store: Store(initialState: AppFeature.State()) {
            AppFeature()
        })
    }
}