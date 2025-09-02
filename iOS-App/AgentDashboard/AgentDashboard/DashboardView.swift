import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var store: AppStore
    
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    // Agent Monitor Widget (2x2)
                    AgentMonitorWidget()
                        .frame(height: 240)
                        .onTapGesture {
                            store.send(.tabSelected(.agents))
                        }
                    
                    // Performance Metrics Widget (2x1)
                    PerformanceMetricsWidget()
                        .frame(height: 160)
                    
                    // System Overview Widget
                    SystemOverviewWidget()
                        .frame(height: 120)
                    
                    // Activity Feed Widget
                    ActivityFeedWidget()
                        .frame(height: 200)
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                store.send(.refresh)
            }
        }
        .onAppear {
            store.send(.loadAgents)
            store.send(.loadSystemStatus)
        }
    }
}

// MARK: - Widgets

struct AgentMonitorWidget: View {
    @EnvironmentObject var store: AppStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.blue)
                Text("CLI Orchestrator")
                    .font(.headline)
                Spacer()
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Status:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Running")
                        .font(.caption)
                        .foregroundColor(.green)
                    Spacer()
                }
                
                HStack {
                    Text("Agents:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(store.state.agents.count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Spacer()
                }
                
                HStack {
                    Text("Last Update:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(store.state.lastUpdate?.formatted(date: .omitted, time: .shortened) ?? "Never")
                        .font(.caption)
                    Spacer()
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct PerformanceMetricsWidget: View {
    @EnvironmentObject var store: AppStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "speedometer")
                    .foregroundColor(.orange)
                Text("Performance")
                    .font(.headline)
                Spacer()
            }
            
            HStack(spacing: 20) {
                VStack {
                    Text("CPU")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("23%")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                VStack {
                    Text("Memory")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("1.2GB")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct SystemOverviewWidget: View {
    @EnvironmentObject var store: AppStore
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("System Health")
                    .font(.headline)
                Text("All systems operational")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct ActivityFeedWidget: View {
    @EnvironmentObject var store: AppStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.bullet")
                    .foregroundColor(.purple)
                Text("Recent Activity")
                    .font(.headline)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(0..<4, id: \.self) { index in
                    HStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 6, height: 6)
                        
                        Text("Unity compilation completed")
                            .font(.caption)
                        
                        Spacer()
                        
                        Text("2m ago")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Preview
#Preview {
    DashboardView()
        .environmentObject(AppStore())
}