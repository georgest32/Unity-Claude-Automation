//
//  EnhancedAnalyticsView.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Enhanced analytics view with advanced interactive features, accessibility, and performance optimization
//

import SwiftUI
import Charts
import ComposableArchitecture

// MARK: - Enhanced Analytics View

struct EnhancedAnalyticsView: View {
    let store: StoreOf<AnalyticsFeature>
    
    // Interactive features
    @StateObject private var coordinationManager = ChartCoordinationManager()
    @StateObject private var performanceOptimizer = ChartPerformanceOptimizer()
    
    // Interaction state
    @State private var selectedTimeRange: ClosedRange<Date>?
    @State private var showingExportSheet: Bool = false
    @State private var exportData: AnalyticsExportData?
    
    // Accessibility
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            NavigationView {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Controls section
                        controlsSection(viewStore: viewStore)
                        
                        // Performance indicators
                        if viewStore.isDebugMode {
                            performanceIndicators
                        }
                        
                        // Enhanced charts section
                        enhancedChartsSection(viewStore: viewStore)
                        
                        // Accessibility information
                        accessibilitySection(viewStore: viewStore)
                    }
                    .padding()
                }
                .navigationTitle("Enhanced Analytics")
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        coordinationToggle
                        exportButton
                        refreshButton(viewStore: viewStore)
                    }
                }
                .sheet(isPresented: $showingExportSheet) {
                    if let exportData = exportData {
                        ShareSheet(items: [exportData.csvData])
                    }
                }
                .onAppear {
                    print("[EnhancedAnalyticsView] Enhanced analytics appeared")
                    viewStore.send(.onAppear)
                }
                .sensoryFeedback(.selection, trigger: selectedTimeRange)
                .sensoryFeedback(.success, trigger: exportData)
            }
        }
    }
    
    // MARK: - Controls Section
    
    private func controlsSection(viewStore: ViewStoreOf<AnalyticsFeature>) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Time range selector with haptic feedback
            VStack(alignment: .leading, spacing: 8) {
                Text("Time Range")
                    .font(.headline)
                    .dynamicTypeSize(dynamicTypeSize)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(AnalyticsFeature.State.TimeRange.allCases, id: \.rawValue) { timeRange in
                            Button(action: {
                                print("[EnhancedAnalyticsView] Time range selected: \(timeRange.displayName)")
                                viewStore.send(.timeRangeChanged(timeRange))
                                
                                // Haptic feedback for selection
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }) {
                                Text(timeRange.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        viewStore.selectedTimeRange == timeRange ? 
                                            .blue : .quaternary
                                    )
                                    .foregroundColor(
                                        viewStore.selectedTimeRange == timeRange ? 
                                            .white : .primary
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .accessibilityLabel("Select \(timeRange.displayName) time range")
                            .accessibilityAddTraits(viewStore.selectedTimeRange == timeRange ? .isSelected : [])
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // Chart coordination controls
            VStack(alignment: .leading, spacing: 8) {
                Text("Chart Coordination")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Toggle("Synchronize Charts", isOn: $coordinationManager.isCoordinationEnabled)
                    .accessibilityLabel("Enable chart synchronization")
                    .accessibilityHint("When enabled, interactions in one chart affect all charts")
                    .sensoryFeedback(.success, trigger: coordinationManager.isCoordinationEnabled)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Performance Indicators
    
    private var performanceIndicators: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Performance Metrics")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack {
                performanceMetric(
                    title: "Frame Rate",
                    value: "\(String(format: "%.1f", performanceOptimizer.currentFrameRate)) fps",
                    color: performanceOptimizer.currentFrameRate >= 55 ? .green : .orange
                )
                
                Spacer()
                
                performanceMetric(
                    title: "Memory",
                    value: "\(performanceOptimizer.memoryUsage / 1024 / 1024) MB",
                    color: performanceOptimizer.memoryUsage < 100 * 1024 * 1024 ? .green : .red
                )
                
                Spacer()
                
                performanceMetric(
                    title: "Latency",
                    value: "\(String(format: "%.1f", performanceOptimizer.interactionLatency * 1000)) ms",
                    color: performanceOptimizer.interactionLatency < 0.05 ? .green : .orange
                )
            }
        }
        .padding()
        .background(.quaternary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func performanceMetric(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Enhanced Charts Section
    
    private func enhancedChartsSection(viewStore: ViewStoreOf<AnalyticsFeature>) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Interactive Data Visualization")
                .font(.headline)
                .dynamicTypeSize(dynamicTypeSize)
            
            ForEach(viewStore.filteredCharts) { chartData in
                AccessibleChartContainer(coordinationManager: coordinationManager) {
                    SystemMetricsChartView(
                        chartData: performanceOptimizer.optimizeChartData(chartData),
                        showAnimation: !reduceMotion && viewStore.isRealTimeEnabled,
                        interactionEnabled: true
                    )
                    .performanceOptimized(with: performanceOptimizer, chartData: chartData)
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Interactive chart: \(chartData.title)")
                .onTapGesture {
                    // Throttled tap handling
                    performanceOptimizer.throttledInteraction {
                        print("[EnhancedAnalyticsView] Chart tapped: \(chartData.title)")
                        viewStore.send(.chartTapped(chartData))
                    }
                }
            }
            
            // Custom charts with accessibility
            customChartsWithAccessibility(viewStore: viewStore)
        }
    }
    
    // MARK: - Custom Charts with Accessibility
    
    private func customChartsWithAccessibility(viewStore: ViewStoreOf<AnalyticsFeature>) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Specialized Monitoring")
                .font(.headline)
                .dynamicTypeSize(dynamicTypeSize)
            
            // System Health Gauge with accessibility
            AccessibleChartView(
                chartData: createMockSystemHealthData(),
                accessibilityDescription: "System health gauge showing composite health score from CPU, memory, disk, and agent metrics"
            ) {
                SystemHealthGauge(
                    systemStatus: createMockSystemStatus(from: viewStore),
                    showDetails: true
                )
                .coordinatedChart(with: coordinationManager)
            }
            
            // Agent Timeline with accessibility
            AccessibleChartView(
                chartData: createMockAgentTimelineData(),
                accessibilityDescription: "Agent status timeline showing status changes over time for active agents"
            ) {
                AgentStatusTimelineChart(
                    agents: createMockAgents(),
                    timeRange: Double(viewStore.selectedTimeRange.seconds)
                )
                .coordinatedChart(with: coordinationManager)
            }
            
            // Error Heatmap with accessibility
            AccessibleChartView(
                chartData: createMockErrorHeatmapData(),
                accessibilityDescription: "Error frequency heatmap showing error patterns by day and hour over the past week"
            ) {
                ErrorFrequencyHeatmap(
                    errorData: createMockErrorData(),
                    timeRange: 604800
                )
                .coordinatedChart(with: coordinationManager)
            }
        }
    }
    
    // MARK: - Accessibility Section
    
    private func accessibilitySection(viewStore: ViewStoreOf<AnalyticsFeature>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Accessibility Features")
                .font(.headline)
                .dynamicTypeSize(dynamicTypeSize)
            
            VStack(alignment: .leading, spacing: 8) {
                accessibilityFeature(
                    icon: "speaker.wave.2",
                    title: "Audio Graphs",
                    description: "Use rotor to access audio representation of charts"
                )
                
                accessibilityFeature(
                    icon: "textformat.size",
                    title: "Dynamic Type", 
                    description: "Charts adapt to your preferred text size"
                )
                
                accessibilityFeature(
                    icon: "motion.accessibility",
                    title: "Reduced Motion",
                    description: "Animations respect accessibility preferences"
                )
                
                accessibilityFeature(
                    icon: "hand.tap",
                    title: "Touch Accommodations",
                    description: "Enhanced touch targets for easier interaction"
                )
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func accessibilityFeature(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Toolbar Controls
    
    private var coordinationToggle: some View {
        Button(action: {
            coordinationManager.isCoordinationEnabled.toggle()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }) {
            Image(systemName: coordinationManager.isCoordinationEnabled ? "link" : "link.badge.plus")
                .foregroundColor(coordinationManager.isCoordinationEnabled ? .blue : .secondary)
        }
        .accessibilityLabel("Toggle chart coordination")
        .accessibilityValue(coordinationManager.isCoordinationEnabled ? "Enabled" : "Disabled")
    }
    
    private var exportButton: some View {
        Button(action: {
            handleDataExport()
        }) {
            Image(systemName: "square.and.arrow.up")
        }
        .accessibilityLabel("Export analytics data")
    }
    
    private func refreshButton(viewStore: ViewStoreOf<AnalyticsFeature>) -> some View {
        Button(action: {
            performanceOptimizer.asyncThrottledInteraction {
                print("[EnhancedAnalyticsView] Throttled refresh requested")
                await MainActor.run {
                    viewStore.send(.refreshRequested)
                }
            }
        }) {
            Image(systemName: "arrow.clockwise")
        }
        .disabled(viewStore.isLoading)
        .accessibilityLabel("Refresh analytics data")
    }
    
    // MARK: - Data Export
    
    private func handleDataExport() {
        print("[EnhancedAnalyticsView] Preparing analytics data export")
        
        // Generate CSV data for all charts
        let csvData = generateAnalyticsCSV()
        
        exportData = AnalyticsExportData(
            csvData: csvData,
            metadata: generateExportMetadata()
        )
        
        showingExportSheet = true
        
        // Haptic feedback for export action
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    private func generateAnalyticsCSV() -> Data {
        var csvContent = "chart_title,timestamp,value,label\n"
        
        // This would iterate through actual chart data
        // For now, using mock data structure
        let sampleRow = "CPU Usage,2025-01-01T00:00:00Z,45.5,CPU\n"
        csvContent += sampleRow
        
        return csvContent.data(using: .utf8) ?? Data()
    }
    
    private func generateExportMetadata() -> [String: Any] {
        return [
            "export_time": Date(),
            "charts_included": 4,
            "data_points": 200,
            "time_range": "1 hour",
            "app_version": "1.0.0"
        ]
    }
    
    // MARK: - Mock Data Helpers
    
    private func createMockSystemHealthData() -> ChartData {
        let healthPoints = (0..<20).map { i in
            MetricPoint(
                timestamp: Date().addingTimeInterval(Double(i) * 180),
                value: 75 + sin(Double(i) * 0.3) * 15,
                label: "Health"
            )
        }
        
        return ChartData(title: "System Health", points: healthPoints, type: .line)
    }
    
    private func createMockAgentTimelineData() -> ChartData {
        let timelinePoints = (0..<10).map { i in
            MetricPoint(
                timestamp: Date().addingTimeInterval(Double(i) * 360),
                value: Double(i % 4), // Represents different agent states
                label: "Agent \(i)"
            )
        }
        
        return ChartData(title: "Agent Timeline", points: timelinePoints, type: .bar)
    }
    
    private func createMockErrorHeatmapData() -> ChartData {
        let errorPoints = (0..<168).map { i in // 7 days * 24 hours
            MetricPoint(
                timestamp: Date().addingTimeInterval(Double(i) * 3600),
                value: Double.random(in: 0...10),
                label: "Hour \(i)"
            )
        }
        
        return ChartData(title: "Error Heatmap", points: errorPoints, type: .scatter)
    }
    
    private func createMockSystemStatus(from viewStore: ViewStoreOf<AnalyticsFeature>) -> SystemStatus {
        let cpuValue = viewStore.charts.first(where: { $0.title.contains("CPU") })?.points.last?.value ?? 50
        
        return SystemStatus(
            timestamp: Date(),
            isHealthy: cpuValue < 80,
            cpuUsage: cpuValue,
            memoryUsage: 65.0,
            diskUsage: 45.0,
            activeAgents: 4,
            totalModules: 12,
            uptime: 7200
        )
    }
    
    private func createMockAgents() -> [Agent] {
        return [
            Agent(
                id: UUID(),
                name: "CLI Orchestrator",
                type: .orchestrator,
                status: .running,
                description: "Main orchestrator",
                startTime: Date().addingTimeInterval(-3600),
                lastActivity: Date(),
                resourceUsage: ResourceUsage(cpu: 15.5, memory: 45.2, threads: 4, handles: 32),
                configuration: ["mode": "auto"]
            )
        ]
    }
    
    private func createMockErrorData() -> [ErrorDataPoint] {
        return (0..<20).map { i in
            ErrorDataPoint(
                id: UUID(),
                timestamp: Date().addingTimeInterval(-Double(i * 3600)),
                errorType: "MockError",
                severity: .medium,
                source: "TestSource",
                message: "Mock error \(i)"
            )
        }
    }
}

// MARK: - Analytics Export Data

struct AnalyticsExportData {
    let csvData: Data
    let metadata: [String: Any]
}

// MARK: - Preview

#if DEBUG
struct EnhancedAnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        EnhancedAnalyticsView(
            store: Store(initialState: AnalyticsFeature.State()) {
                AnalyticsFeature()
            }
        )
        .preferredColorScheme(.dark)
    }
}
#endif