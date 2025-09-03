//
//  ContentView.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Main content view with tab navigation
//

import SwiftUI
import ComposableArchitecture

struct ContentView: View {
    let store: StoreOf<AppFeature>
    
    var body: some View {
        WithPerceptionTracking {
            TabView(selection: .init(
                get: { store.state.selectedTab },
                set: { store.send(.tabSelected($0)) }
            )) {
                // Dashboard Tab
                DashboardView(
                    store: store.scope(
                        state: \.dashboard,
                        action: \.dashboard
                    )
                )
                .tabItem {
                    Image(systemName: "square.grid.2x2")
                    Text("Dashboard")
                }
                .tag(AppFeature.State.Tab.dashboard)
                
                // Agents Tab
                AgentsView(
                    store: store.scope(
                        state: \.agents,
                        action: \.agents
                    )
                )
                .tabItem {
                    Image(systemName: "cpu")
                    Text("Agents")
                }
                .tag(AppFeature.State.Tab.agents)
                
                // Terminal Tab
                TerminalView(
                    store: store.scope(
                        state: \.terminal,
                        action: \.terminal
                    )
                )
                .tabItem {
                    Image(systemName: "terminal")
                    Text("Terminal")
                }
                .tag(AppFeature.State.Tab.terminal)
                
                // Analytics Tab
                AnalyticsView(
                    store: store.scope(
                        state: \.analytics,
                        action: \.analytics
                    )
                )
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Analytics")
                }
                .tag(AppFeature.State.Tab.analytics)
                
                // Settings Tab
                SettingsView(
                    store: store.scope(
                        state: \.settings,
                        action: \.settings
                    )
                )
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(AppFeature.State.Tab.settings)
            }
            .onAppear {
                print("🚀 [ContentView] App appeared - initializing features")
                store.send(.onAppear)
            }
            .onDisappear {
                print("[ContentView] App disappeared")
                store.send(.onDisappear)
            }
            .onReceive(
                NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            ) { _ in
                print("[ContentView] App entering foreground")
                store.send(.enterForeground)
            }
            .onReceive(
                NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            ) { _ in
                print("[ContentView] App entering background")
                store.send(.enterBackground)
            }
        }
    }
}

// MARK: - Connection Status Bar

struct ConnectionStatusBar: View {
    let connectionStatus: ConnectionStatus
    let isConnected: Bool
    
    var body: some View {
        if !isConnected || connectionStatus != .connected {
            HStack {
                Circle()
                    .fill(connectionStatus.color)
                    .frame(width: 8, height: 8)
                
                Text(connectionStatus.description)
                    .font(.caption)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 16)
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }
}

// MARK: - Placeholder Views

struct DashboardView: View {
    let store: StoreOf<DashboardFeature>
    
    var body: some View {
        WithPerceptionTracking {
            NavigationView {
                VStack(spacing: 20) {
                    // System Status Card
                    if let systemStatus = store.state.systemStatus {
                        SystemStatusCard(systemStatus: systemStatus)
                    } else if store.state.isRefreshing {
                        ProgressView("Loading system status...")
                            .frame(maxWidth: .infinity, minHeight: 120)
                    }
                    
                    // Agents Summary
                    AgentsSummaryCard(
                        activeCount: store.state.activeAgents.filter { $0.isActive }.count,
                        totalCount: store.state.activeAgents.count
                    )
                    
                    Spacer()
                }
                .padding()
                .navigationTitle("Dashboard")
                .refreshable {
                    store.send(.refreshButtonTapped)
                }
            }
            .onAppear {
                print("📊 [DashboardView] Dashboard appeared - loading system status")
                store.send(.onAppear)
            }
        }
    }
}

struct SystemStatusCard: View {
    let systemStatus: SystemStatus
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("System Status")
                    .font(.headline)
                Spacer()
                Circle()
                    .fill(systemStatus.isHealthy ? .green : .red)
                    .frame(width: 12, height: 12)
            }
            
            HStack(spacing: 20) {
                MetricView(title: "CPU", value: systemStatus.cpuUsage, unit: "%")
                MetricView(title: "Memory", value: systemStatus.memoryUsage, unit: "%")
                MetricView(title: "Disk", value: systemStatus.diskUsage, unit: "%")
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct MetricView: View {
    let title: String
    let value: Double
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(value, specifier: "%.1f")\(unit)")
                .font(.title2)
                .fontWeight(.semibold)
        }
    }
}

struct AgentsSummaryCard: View {
    let activeCount: Int
    let totalCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Agents")
                .font(.headline)
            
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Active")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(activeCount)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                VStack(alignment: .leading) {
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(totalCount)")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct RecentAlertsCard: View {
    let alerts: [Alert]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Alerts")
                .font(.headline)
            
            ForEach(alerts) { alert in
                HStack {
                    Image(systemName: alert.severity.icon)
                        .foregroundColor(alert.severity.color)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(alert.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(alert.message)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    Text(alert.timestamp, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 2)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Other Placeholder Views

struct AgentsView: View {
    let store: StoreOf<AgentsFeature>
    
    var body: some View {
        WithPerceptionTracking {
            NavigationView {
                Text("Agents View - Coming Soon")
                    .navigationTitle("Agents")
            }
            .onAppear {
                store.send(.onAppear)
            }
        }
    }
}

struct TerminalView: View {
    let store: StoreOf<TerminalFeature>
    
    var body: some View {
        TerminalInterfaceView(store: store)
    }
}

struct AnalyticsView: View {
    let store: StoreOf<AnalyticsFeature>
    
    var body: some View {
        EnhancedAnalyticsView(store: store)
    }
}

struct SettingsView: View {
    let store: StoreOf<SettingsFeature>
    
    var body: some View {
        WithPerceptionTracking {
            NavigationView {
                Text("Settings View - Coming Soon")
                    .navigationTitle("Settings")
            }
            .onAppear {
                store.send(.onAppear)
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(store: Store(initialState: AppFeature.State()) {
            AppFeature()
        })
        .preferredColorScheme(.dark)
    }
}
#endif