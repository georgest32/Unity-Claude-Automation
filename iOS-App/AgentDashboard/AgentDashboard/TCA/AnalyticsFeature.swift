//
//  AnalyticsFeature.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Analytics feature for performance metrics and data visualization
//

import ComposableArchitecture
import Foundation

@Reducer
public struct AnalyticsFeature: Sendable {
    // MARK: - State
    public struct State: Equatable, Sendable {
        var charts: [ChartData] = []
        var isLoading: Bool = false
        var error: String?
        var selectedTimeRange: TimeRange = .hour
        var selectedMetric: MetricType = .system
        var refreshRate: RefreshRate = .medium
        
        enum TimeRange: String, CaseIterable {
            case minute = "1m"
            case fiveMinutes = "5m" 
            case fifteenMinutes = "15m"
            case hour = "1h"
            case fourHours = "4h"
            case day = "1d"
            case week = "1w"
            
            var displayName: String {
                switch self {
                case .minute: return "Last Minute"
                case .fiveMinutes: return "Last 5 Minutes"
                case .fifteenMinutes: return "Last 15 Minutes"
                case .hour: return "Last Hour"
                case .fourHours: return "Last 4 Hours"
                case .day: return "Last Day"
                case .week: return "Last Week"
                }
            }
            
            var seconds: TimeInterval {
                switch self {
                case .minute: return 60
                case .fiveMinutes: return 300
                case .fifteenMinutes: return 900
                case .hour: return 3600
                case .fourHours: return 14400
                case .day: return 86400
                case .week: return 604800
                }
            }
        }
        
        enum MetricType: String, CaseIterable {
            case system = "System"
            case agents = "Agents"
            case performance = "Performance"
            case network = "Network"
            
            var icon: String {
                switch self {
                case .system: return "cpu"
                case .agents: return "person.3"
                case .performance: return "speedometer"
                case .network: return "network"
                }
            }
        }
        
        enum RefreshRate: String, CaseIterable {
            case slow = "30s"
            case medium = "10s"
            case fast = "5s"
            case realtime = "1s"
            
            var interval: TimeInterval {
                switch self {
                case .slow: return 30
                case .medium: return 10
                case .fast: return 5
                case .realtime: return 1
                }
            }
        }
        
        // Computed properties
        var filteredCharts: [ChartData] {
            // Filter charts based on selected metric type
            return charts.filter { chart in
                switch selectedMetric {
                case .system:
                    return chart.title.contains("CPU") || chart.title.contains("Memory") || chart.title.contains("Disk")
                case .agents:
                    return chart.title.contains("Agent") || chart.title.contains("Task")
                case .performance:
                    return chart.title.contains("Response") || chart.title.contains("Throughput") || chart.title.contains("Latency")
                case .network:
                    return chart.title.contains("Network") || chart.title.contains("Connection") || chart.title.contains("Bandwidth")
                }
            }
        }
        
        var isRealTimeEnabled: Bool {
            refreshRate == .realtime || refreshRate == .fast
        }
    }
    
    // MARK: - Action  
    public enum Action: Equatable {
        // Data loading
        case loadAnalytics
        case analyticsLoaded([ChartData])
        case loadingFailed(String)
        
        // Real-time updates
        case metricsUpdated(Data)
        case startRealTimeUpdates
        case stopRealTimeUpdates
        
        // User interactions
        case timeRangeChanged(State.TimeRange)
        case metricTypeChanged(State.MetricType)
        case refreshRateChanged(State.RefreshRate)
        case refreshRequested
        case chartTapped(ChartData)
        
        // Export and sharing
        case exportData
        case shareChart(ChartData)
        
        // Lifecycle
        case onAppear
        case onDisappear
    }
    
    // MARK: - Dependencies
    @Dependency(\.apiClient) var apiClient
    @Dependency(\.continuousClock) var clock
    
    // MARK: - Reducer
    public init() {}
    
    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            // Lifecycle
            case .onAppear:
                print("[AnalyticsFeature] Analytics view appeared")
                return .merge(
                    .send(.loadAnalytics),
                    .send(.startRealTimeUpdates)
                )
                
            case .onDisappear:
                print("[AnalyticsFeature] Analytics view disappeared")
                return .send(.stopRealTimeUpdates)
                
            // Data loading
            case .loadAnalytics:
                print("[AnalyticsFeature] Loading analytics data...")
                state.isLoading = true
                state.error = nil
                
                return .run { [timeRange = state.selectedTimeRange] send in
                    do {
                        // Generate mock chart data for now
                        let charts = generateMockChartData(for: timeRange)
                        await send(.analyticsLoaded(charts))
                    } catch {
                        await send(.loadingFailed(error.localizedDescription))
                    }
                }
                
            case let .analyticsLoaded(charts):
                print("[AnalyticsFeature] Loaded \(charts.count) charts")
                state.charts = charts
                state.isLoading = false
                return .none
                
            case let .loadingFailed(error):
                print("[AnalyticsFeature] Loading failed: \(error)")
                state.error = error
                state.isLoading = false
                return .none
                
            // Real-time updates
            case let .metricsUpdated(data):
                print("[AnalyticsFeature] Received metrics update")
                
                // Try to decode and update charts with new data
                if let systemStatus = try? JSONDecoder().decode(SystemStatus.self, from: data) {
                    return updateChartsWithSystemStatus(systemStatus, state: &state)
                }
                
                return .none
                
            case .startRealTimeUpdates:
                print("[AnalyticsFeature] Starting real-time updates")
                
                return .run { [refreshRate = state.refreshRate] send in
                    while true {
                        try await clock.sleep(for: .seconds(refreshRate.interval))
                        // In a real implementation, this would fetch new data
                        // For now, we'll generate mock updates
                        let mockSystemStatus = SystemStatus(
                            timestamp: Date(),
                            isHealthy: true,
                            cpuUsage: Double.random(in: 10...80),
                            memoryUsage: Double.random(in: 30...70),
                            diskUsage: Double.random(in: 20...60),
                            activeAgents: Int.random(in: 3...8),
                            totalModules: 12,
                            uptime: TimeInterval.random(in: 3600...86400)
                        )
                        
                        if let data = try? JSONEncoder().encode(mockSystemStatus) {
                            await send(.metricsUpdated(data))
                        }
                    }
                }
                .cancellable(id: "realtime_updates")
                
            case .stopRealTimeUpdates:
                print("[AnalyticsFeature] Stopping real-time updates")
                return .cancel(id: "realtime_updates")
                
            // User interactions
            case let .timeRangeChanged(timeRange):
                print("[AnalyticsFeature] Time range changed: \(timeRange.displayName)")
                state.selectedTimeRange = timeRange
                return .send(.loadAnalytics)
                
            case let .metricTypeChanged(metricType):
                print("[AnalyticsFeature] Metric type changed: \(metricType.rawValue)")
                state.selectedMetric = metricType
                return .none
                
            case let .refreshRateChanged(refreshRate):
                print("[AnalyticsFeature] Refresh rate changed: \(refreshRate.rawValue)")
                state.refreshRate = refreshRate
                return .merge(
                    .send(.stopRealTimeUpdates),
                    .send(.startRealTimeUpdates)
                )
                
            case .refreshRequested:
                print("[AnalyticsFeature] Manual refresh requested")
                return .send(.loadAnalytics)
                
            case let .chartTapped(chart):
                print("[AnalyticsFeature] Chart tapped: \(chart.title)")
                // TODO: Show detailed chart view
                return .none
                
            // Export and sharing with comprehensive functionality
            case .exportData:
                print("[AnalyticsFeature] Exporting analytics data")
                state.isLoading = true
                
                return .run { [charts = state.charts, timeRange = state.selectedTimeRange] send in
                    do {
                        // Generate comprehensive export data
                        let exportData = ExportData(
                            charts: charts,
                            timeRange: timeRange.displayName,
                            exportDate: Date(),
                            totalDataPoints: charts.reduce(0) { $0 + $1.points.count }
                        )
                        
                        // Create CSV data
                        let csvData = generateCSVData(from: exportData)
                        
                        // Create JSON data  
                        let jsonData = try JSONEncoder().encode(exportData)
                        
                        print("[AnalyticsFeature] Generated export data: CSV(\(csvData.count) bytes), JSON(\(jsonData.count) bytes)")
                        
                        // In real implementation, would trigger file save dialog
                        // For now, just complete the operation
                        await send(.analyticsLoaded(charts)) // Refresh to clear loading state
                        
                    } catch {
                        print("[AnalyticsFeature] Export failed: \(error.localizedDescription)")
                        await send(.loadingFailed("Failed to export data: \(error.localizedDescription)"))
                    }
                }
                
            case let .shareChart(chart):
                print("[AnalyticsFeature] Sharing chart: \(chart.title)")
                
                return .run { send in
                    do {
                        // Generate shareable chart data
                        let shareData = ChartShareData(
                            title: chart.title,
                            type: chart.type,
                            dataPoints: chart.points.count,
                            dateRange: "\(chart.points.first?.timestamp.formatted(date: .abbreviated, time: .omitted) ?? "N/A") - \(chart.points.last?.timestamp.formatted(date: .abbreviated, time: .omitted) ?? "N/A")",
                            summary: generateChartSummary(chart),
                            exportDate: Date()
                        )
                        
                        // Create CSV for sharing
                        let csvContent = generateChartCSV(chart)
                        
                        print("[AnalyticsFeature] Generated share data for \(chart.title): \(shareData.dataPoints) points")
                        
                        // In real implementation, would trigger share sheet
                        // For now, log the success
                        print("[AnalyticsFeature] Chart sharing prepared successfully")
                        
                    } catch {
                        print("[AnalyticsFeature] Share preparation failed: \(error.localizedDescription)")
                        await send(.loadingFailed("Failed to prepare chart for sharing: \(error.localizedDescription)"))
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateChartsWithSystemStatus(_ status: SystemStatus, state: inout State) -> Effect<Action> {
        let now = Date()
        
        // Update CPU chart
        if let cpuChartIndex = state.charts.firstIndex(where: { $0.title == "CPU Usage" }) {
            var cpuChart = state.charts[cpuChartIndex]
            let cpuPoint = MetricPoint(timestamp: now, value: status.cpuUsage, label: "CPU")
            
            // Add new point and keep only recent points based on time range
            var newPoints = cpuChart.points + [cpuPoint]
            let cutoffTime = now.addingTimeInterval(-state.selectedTimeRange.seconds)
            newPoints = newPoints.filter { $0.timestamp >= cutoffTime }
            
            cpuChart = ChartData(title: cpuChart.title, points: newPoints, type: cpuChart.type)
            state.charts[cpuChartIndex] = cpuChart
        }
        
        // Update Memory chart
        if let memoryChartIndex = state.charts.firstIndex(where: { $0.title == "Memory Usage" }) {
            var memoryChart = state.charts[memoryChartIndex]
            let memoryPoint = MetricPoint(timestamp: now, value: status.memoryUsage, label: "Memory")
            
            var newPoints = memoryChart.points + [memoryPoint]
            let cutoffTime = now.addingTimeInterval(-state.selectedTimeRange.seconds)
            newPoints = newPoints.filter { $0.timestamp >= cutoffTime }
            
            memoryChart = ChartData(title: memoryChart.title, points: newPoints, type: memoryChart.type)
            state.charts[memoryChartIndex] = memoryChart
        }
        
        return .none
    }
}

// MARK: - Mock Data Generation

private func generateMockChartData(for timeRange: AnalyticsFeature.State.TimeRange) -> [ChartData] {
    let now = Date()
    let startTime = now.addingTimeInterval(-timeRange.seconds)
    let interval = timeRange.seconds / 50 // Generate 50 data points
    
    var charts: [ChartData] = []
    
    // CPU Usage Chart
    var cpuPoints: [MetricPoint] = []
    for i in 0..<50 {
        let timestamp = startTime.addingTimeInterval(Double(i) * interval)
        let value = 30 + sin(Double(i) * 0.2) * 20 + Double.random(in: -5...5)
        cpuPoints.append(MetricPoint(timestamp: timestamp, value: max(0, min(100, value)), label: "CPU"))
    }
    charts.append(ChartData(title: "CPU Usage", points: cpuPoints, type: .line))
    
    // Memory Usage Chart
    var memoryPoints: [MetricPoint] = []
    for i in 0..<50 {
        let timestamp = startTime.addingTimeInterval(Double(i) * interval)
        let value = 45 + sin(Double(i) * 0.15) * 15 + Double.random(in: -3...3)
        memoryPoints.append(MetricPoint(timestamp: timestamp, value: max(0, min(100, value)), label: "Memory"))
    }
    charts.append(ChartData(title: "Memory Usage", points: memoryPoints, type: .area))
    
    // Agent Activity Chart
    var agentPoints: [MetricPoint] = []
    for i in 0..<50 {
        let timestamp = startTime.addingTimeInterval(Double(i) * interval)
        let value = Double(Int.random(in: 3...7))
        agentPoints.append(MetricPoint(timestamp: timestamp, value: value, label: "Active"))
    }
    charts.append(ChartData(title: "Agent Activity", points: agentPoints, type: .bar))
    
    return charts
}

// MARK: - Helper Extensions

extension AnalyticsFeature.State {
    var dataSummary: String {
        let totalPoints = charts.reduce(0) { $0 + $1.points.count }
        let timeSpan = selectedTimeRange.displayName
        return "\(totalPoints) data points over \(timeSpan)"
    }
    
    var averageCPU: Double? {
        guard let cpuChart = charts.first(where: { $0.title == "CPU Usage" }) else { return nil }
        let values = cpuChart.points.map { $0.value }
        return values.isEmpty ? nil : values.reduce(0, +) / Double(values.count)
    }
    
    var averageMemory: Double? {
        guard let memoryChart = charts.first(where: { $0.title == "Memory Usage" }) else { return nil }
        let values = memoryChart.points.map { $0.value }
        return values.isEmpty ? nil : values.reduce(0, +) / Double(values.count)
    }
}

// MARK: - Export Data Models

struct ExportData: Codable {
    let charts: [ChartExportData]
    let timeRange: String
    let exportDate: Date
    let totalDataPoints: Int
    
    init(charts: [ChartData], timeRange: String, exportDate: Date, totalDataPoints: Int) {
        self.charts = charts.map { ChartExportData(from: $0) }
        self.timeRange = timeRange
        self.exportDate = exportDate
        self.totalDataPoints = totalDataPoints
    }
}

struct ChartExportData: Codable {
    let title: String
    let type: String
    let points: [MetricPointExport]
    
    init(from chartData: ChartData) {
        self.title = chartData.title
        self.type = chartData.type.rawValue
        self.points = chartData.points.map { MetricPointExport(from: $0) }
    }
}

struct MetricPointExport: Codable {
    let timestamp: TimeInterval
    let value: Double
    let label: String?
    
    init(from point: MetricPoint) {
        self.timestamp = point.timestamp.timeIntervalSince1970
        self.value = point.value
        self.label = point.label
    }
}

struct ChartShareData {
    let title: String
    let type: ChartData.ChartType
    let dataPoints: Int
    let dateRange: String
    let summary: String
    let exportDate: Date
}

// MARK: - Export Helper Functions

private func generateCSVData(from exportData: ExportData) -> Data {
    var csvString = "Chart Title,Chart Type,Timestamp,Value,Label\n"
    
    for chart in exportData.charts {
        for point in chart.points {
            let timestamp = Date(timeIntervalSince1970: point.timestamp).formatted(date: .abbreviated, time: .shortened)
            let label = point.label ?? ""
            csvString += "\(chart.title),\(chart.type),\(timestamp),\(point.value),\(label)\n"
        }
    }
    
    return csvString.data(using: .utf8) ?? Data()
}

private func generateChartSummary(_ chart: ChartData) -> String {
    let values = chart.points.map { $0.value }
    guard !values.isEmpty else { return "No data available" }
    
    let min = values.min() ?? 0
    let max = values.max() ?? 0
    let avg = values.reduce(0, +) / Double(values.count)
    
    return """
    Data Points: \(chart.points.count)
    Range: \(String(format: "%.1f", min)) - \(String(format: "%.1f", max))
    Average: \(String(format: "%.1f", avg))
    """
}

private func generateChartCSV(_ chart: ChartData) -> String {
    var csvString = "Timestamp,Value,Label\n"
    
    for point in chart.points {
        let timestamp = point.timestamp.formatted(date: .abbreviated, time: .shortened)
        let label = point.label ?? ""
        csvString += "\(timestamp),\(point.value),\(label)\n"
    }
    
    return csvString
}