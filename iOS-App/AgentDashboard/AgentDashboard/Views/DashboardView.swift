import SwiftUI
import ComposableArchitecture

/// Sophisticated dashboard view with modular widget system
@MainActor
struct DashboardView: View {
    @Bindable var store: StoreOf<DashboardFeature>
    
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        WithPerceptionTracking {
            NavigationView {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        // Agent Monitor Widget (2x2)
                        AgentMonitorWidget()
                            .frame(height: 240)
                            .onTapGesture {
                                store.send(.widgetTapped(.agentActivity))
                            }
                        
                        // Performance Metrics Widget (2x1)  
                        PerformanceMetricsWidget(
                            cpuUsage: store.cpuUsage,
                            memoryUsage: store.memoryUsage,
                            processCount: store.processCount
                        )
                            .frame(height: 160)
                            .onTapGesture {
                                store.send(.widgetTapped(.performanceMetrics))
                            }
                        
                        // System Overview Widget (2x1)
                        SystemOverviewWidget(
                            systemStatus: store.systemStatus,
                            errorCount: store.errorCount,
                            warningCount: store.warningCount
                        )
                            .frame(height: 120)
                            .onTapGesture {
                                store.send(.widgetTapped(.systemOverview))
                            }
                        
                        // Activity Feed Widget (2x2)
                        ActivityFeedWidget()
                            .frame(height: 200)
                            .onTapGesture {
                                store.send(.widgetTapped(.errorLog))
                            }
                        
                        // Module Status Widget (2x1)
                        ModuleStatusWidget(modules: store.activeModules)
                            .frame(height: 140)
                            .onTapGesture {
                                store.send(.widgetTapped(.moduleStatus))
                            }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
                .navigationTitle("Dashboard")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            store.send(.refreshButtonTapped)
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .rotationEffect(.degrees(store.isRefreshing ? 360 : 0))
                                .animation(store.isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: store.isRefreshing)
                        }
                        .disabled(store.isRefreshing)
                    }
                }
                .refreshable {
                    store.send(.refreshButtonTapped)
                }
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
        .onDisappear {
            store.send(.onDisappear)
        }
    }
}

// MARK: - System Overview Widget

struct SystemOverviewWidget: View {
    let systemStatus: SystemStatus?
    let errorCount: Int
    let warningCount: Int
    
    var body: some View {
        WidgetContainerView(
            title: "System Status",
            icon: "cpu",
            size: .medium
        ) {
            VStack(spacing: 12) {
                HStack(spacing: 20) {
                    // Online Status
                    VStack(spacing: 4) {
                        Circle()
                            .fill(systemStatus?.isOnline == true ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                        
                        Text(systemStatus?.isOnline == true ? "Online" : "Offline")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    
                    // Health Status
                    VStack(spacing: 4) {
                        Image(systemName: systemStatus?.healthStatus.systemImage ?? "questionmark.circle")
                            .font(.title3)
                            .foregroundColor(Color(systemStatus?.healthStatus.color ?? "gray"))
                        
                        Text(systemStatus?.healthStatus.rawValue ?? "Unknown")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
                
                HStack {
                    // Errors
                    VStack(spacing: 2) {
                        Text("\(errorCount)")
                            .font(.headline)
                            .foregroundColor(.red)
                        Text("Errors")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                        .frame(height: 30)
                    
                    // Warnings
                    VStack(spacing: 2) {
                        Text("\(warningCount)")
                            .font(.headline)
                            .foregroundColor(.orange)
                        Text("Warnings")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                        .frame(height: 30)
                    
                    // Uptime
                    VStack(spacing: 2) {
                        Text(systemStatus?.uptime ?? "N/A")
                            .font(.headline)
                            .foregroundColor(.blue)
                        Text("Uptime")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Module Status Widget

struct ModuleStatusWidget: View {
    let modules: [Module]
    
    var body: some View {
        WidgetContainerView(
            title: "Modules",
            icon: "cube.box",
            size: .medium
        ) {
            VStack(spacing: 8) {
                HStack {
                    Text("\(modules.filter(\.isActive).count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("of \(modules.count) active")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                
                VStack(spacing: 4) {
                    ForEach(modules.prefix(3)) { module in
                        HStack {
                            Circle()
                                .fill(Color(module.status.color))
                                .frame(width: 6, height: 6)
                            
                            Text(module.name)
                                .font(.caption)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text(module.version)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if modules.count > 3 {
                        HStack {
                            Text("+ \(modules.count - 3) more")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Widget Container

struct WidgetContainerView<Content: View>: View {
    let title: String
    let icon: String
    let size: WidgetSize
    let content: Content
    
    init(
        title: String,
        icon: String,
        size: WidgetSize,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.size = size
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.accentColor)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Content
            content
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

enum WidgetSize {
    case small  // 1x1
    case medium // 2x1
    case large  // 2x2
    case wide   // 4x2
}

// MARK: - Preview

#Preview {
    DashboardView(
        store: Store(initialState: DashboardFeature.State()) {
            DashboardFeature()
        }
    )
}