//
//  AnalyticsChartView.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Complete analytics view with Swift Charts integration and real-time updates
//

import SwiftUI
import Charts
import ComposableArchitecture

// MARK: - Analytics Chart View

struct AnalyticsChartView: View {
    let store: StoreOf<AnalyticsFeature>
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            NavigationView {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Time range selector
                        timeRangeSelector(viewStore: viewStore)
                        
                        // Metric type selector
                        metricTypeSelector(viewStore: viewStore)
                        
                        // Standard charts grid
                        chartsGrid(viewStore: viewStore)
                        
                        // Custom charts section
                        customChartsSection(viewStore: viewStore)
                        
                        // Analytics summary
                        analyticsSummary(viewStore: viewStore)
                    }
                    .padding()
                }
                .navigationTitle("Analytics")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        refreshButton(viewStore: viewStore)
                    }
                }
                .refreshable {
                    viewStore.send(.refreshRequested)
                }
                .onAppear {
                    print("[AnalyticsChartView] Analytics view appeared")
                    viewStore.send(.onAppear)
                }
                .onDisappear {
                    print("[AnalyticsChartView] Analytics view disappeared")
                    viewStore.send(.onDisappear)
                }
            }
        }
    }
    
    // MARK: - Time Range Selector
    
    private func timeRangeSelector(viewStore: ViewStoreOf<AnalyticsFeature>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Time Range")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(AnalyticsFeature.State.TimeRange.allCases, id: \.rawValue) { timeRange in
                        Button(action: {
                            print("[AnalyticsChartView] Time range selected: \(timeRange.displayName)")
                            viewStore.send(.timeRangeChanged(timeRange))
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
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Metric Type Selector
    
    private func metricTypeSelector(viewStore: ViewStoreOf<AnalyticsFeature>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Metrics")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(AnalyticsFeature.State.MetricType.allCases, id: \.rawValue) { metricType in
                    Button(action: {
                        print("[AnalyticsChartView] Metric type selected: \(metricType.rawValue)")
                        viewStore.send(.metricTypeChanged(metricType))
                    }) {
                        HStack {
                            Image(systemName: metricType.icon)
                                .font(.title2)
                            
                            Text(metricType.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                        }
                        .padding()
                        .background(
                            viewStore.selectedMetric == metricType ? 
                                .blue.opacity(0.2) : .quaternary
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    viewStore.selectedMetric == metricType ? 
                                        .blue : .clear, 
                                    lineWidth: 2
                                )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Charts Grid
    
    private func chartsGrid(viewStore: ViewStoreOf<AnalyticsFeature>) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 1), spacing: 16) {
            ForEach(viewStore.filteredCharts) { chartData in
                SystemMetricsChartView(
                    chartData: chartData,
                    showAnimation: !viewStore.isRealTimeEnabled,
                    interactionEnabled: true
                )
                .onTapGesture {
                    print("[AnalyticsChartView] Chart tapped: \(chartData.title)")
                    viewStore.send(.chartTapped(chartData))
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Analytics Summary
    
    private func analyticsSummary(viewStore: ViewStoreOf<AnalyticsFeature>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Summary")
                .font(.headline)
            
            VStack(spacing: 8) {
                summaryRow(
                    title: "Data Points",
                    value: "\(viewStore.charts.reduce(0) { $0 + $1.points.count })",
                    icon: "chart.dots.scatter"
                )
                
                summaryRow(
                    title: "Time Range", 
                    value: viewStore.selectedTimeRange.displayName,
                    icon: "clock"
                )
                
                summaryRow(
                    title: "Update Rate",
                    value: viewStore.refreshRate.rawValue,
                    icon: "arrow.clockwise"
                )
                
                if let avgCPU = viewStore.averageCPU {
                    summaryRow(
                        title: "Avg CPU",
                        value: "\(avgCPU, specifier: "%.1f")%",
                        icon: "cpu"
                    )
                }
                
                if let avgMemory = viewStore.averageMemory {
                    summaryRow(
                        title: "Avg Memory", 
                        value: "\(avgMemory, specifier: "%.1f")%",
                        icon: "memorychip"
                    )
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
    
    private func summaryRow(title: String, value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
    
    // MARK: - Custom Charts Section
    
    private func customChartsSection(viewStore: ViewStoreOf<AnalyticsFeature>) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Specialized Monitoring")
                .font(.headline)
                .padding(.horizontal)
            
            // System Health Gauge
            if let systemStatus = viewStore.charts.first(where: { $0.title.contains("System") }) {
                let mockSystemStatus = SystemStatus(
                    timestamp: Date(),
                    isHealthy: true,
                    cpuUsage: systemStatus.points.last?.value ?? 50,
                    memoryUsage: 65.0,
                    diskUsage: 45.0,
                    activeAgents: 4,
                    totalModules: 12,
                    uptime: 7200
                )
                
                SystemHealthGauge(systemStatus: mockSystemStatus, showDetails: true)
                    .padding(.horizontal)
            }
            
            // Agent Status Timeline
            AgentStatusTimelineChart(
                agents: createMockAgents(),
                timeRange: Double(viewStore.selectedTimeRange.seconds)
            )
            .padding(.horizontal)
            
            // Error Frequency Heatmap
            ErrorFrequencyHeatmap(
                errorData: createMockErrorData(),
                timeRange: 604800
            )
            .padding(.horizontal)
            
            // Command Success Rate Chart
            CommandSuccessRateChart(
                commandData: createMockCommandData(),
                timeRange: Double(viewStore.selectedTimeRange.seconds)
            )
            .padding(.horizontal)
        }
    }
    
    // MARK: - Mock Data Helpers
    
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
            ),
            Agent(
                id: UUID(),
                name: "System Monitor",
                type: .monitor,
                status: .idle,
                description: "Health monitor",
                startTime: Date().addingTimeInterval(-7200),
                lastActivity: Date().addingTimeInterval(-300),
                resourceUsage: ResourceUsage(cpu: 8.3, memory: 25.1, threads: 2, handles: 18),
                configuration: ["interval": "30s"]
            )
        ]
    }
    
    private func createMockErrorData() -> [ErrorDataPoint] {
        var errors: [ErrorDataPoint] = []
        let now = Date()
        
        for _ in 0..<25 {
            let randomOffset = Double.random(in: 0...604800)
            let timestamp = now.addingTimeInterval(-randomOffset)
            
            let error = ErrorDataPoint(
                id: UUID(),
                timestamp: timestamp,
                errorType: ["NetworkError", "ValidationError", "TimeoutError"].randomElement()!,
                severity: ErrorDataPoint.ErrorSeverity.allCases.randomElement()!,
                source: ["WebSocket", "API", "Database"].randomElement()!,
                message: "Mock error"
            )
            
            errors.append(error)
        }
        
        return errors
    }
    
    private func createMockCommandData() -> [CommandExecutionData] {
        return CommandExecutionData.createSample()
    }
    
    // MARK: - Refresh Button
    
    private func refreshButton(viewStore: ViewStoreOf<AnalyticsFeature>) -> some View {
        Button(action: {
            print("[AnalyticsChartView] Manual refresh requested")
            viewStore.send(.refreshRequested)
        }) {
            Image(systemName: "arrow.clockwise")
        }
        .disabled(viewStore.isLoading)
    }
}

// MARK: - Multi-Chart Container

struct MultiChartContainer: View {
    let charts: [ChartData]
    let columns: Int = 2
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: columns), spacing: 16) {
            ForEach(charts) { chartData in
                CompactChartView(chartData: chartData)
            }
        }
    }
}

// MARK: - Compact Chart View

struct CompactChartView: View {
    let chartData: ChartData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(chartData.title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Chart(chartData.points, id: \.timestamp) { point in
                switch chartData.type {
                case .line:
                    LineMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                    
                case .area:
                    AreaMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange.opacity(0.6), .orange.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                case .bar:
                    BarMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(.green)
                    
                case .scatter:
                    PointMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(.purple)
                    .symbolSize(25)
                }
            }
            .frame(height: 120)
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            
            // Latest value
            if let latestPoint = chartData.points.last {
                Text("\(latestPoint.value, specifier: "%.1f")")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#if DEBUG
struct AnalyticsChartView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsChartView(
            store: Store(initialState: AnalyticsFeature.State()) {
                AnalyticsFeature()
            }
        )
        .preferredColorScheme(.dark)
    }
}
#endif