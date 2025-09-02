//
//  QueueAnalyticsView.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Analytics dashboard for command queue performance monitoring
//  Hour 8.2: Analytics dashboard implementation
//

import SwiftUI
import Charts
import ComposableArchitecture

struct QueueAnalyticsView: View {
    let analytics: QueueAnalytics
    let onDismiss: () -> Void
    
    @State private var selectedTab: AnalyticsTab = .overview
    
    enum AnalyticsTab: String, CaseIterable {
        case overview = "Overview"
        case performance = "Performance"
        case trends = "Trends"
        case resources = "Resources"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab selector
                analyticsTabPicker
                
                // Content based on selected tab
                switch selectedTab {
                case .overview:
                    overviewSection
                case .performance:
                    performanceSection
                case .trends:
                    trendsSection
                case .resources:
                    resourcesSection
                }
            }
            .navigationTitle("Queue Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Tab Picker
    
    private var analyticsTabPicker: some View {
        Picker("Analytics Tab", selection: $selectedTab) {
            ForEach(AnalyticsTab.allCases, id: \.self) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding()
    }
    
    // MARK: - Overview Section
    
    private var overviewSection: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Summary metrics
                summaryMetricsGrid
                
                // Efficiency score
                efficiencyScoreCard
                
                // Quick stats
                quickStatsSection
            }
            .padding()
        }
    }
    
    private var summaryMetricsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            MetricCard(
                title: "Total Processed",
                value: "\(analytics.totalProcessed)",
                subtitle: "Commands",
                color: .blue,
                icon: "tray.full"
            )
            
            MetricCard(
                title: "Success Rate",
                value: "\(Int(analytics.successRate * 100))%",
                subtitle: "Completion rate",
                color: .green,
                icon: "checkmark.circle"
            )
            
            MetricCard(
                title: "Avg Queue Time",
                value: "\(Int(analytics.averageQueueTime))s",
                subtitle: "Wait time",
                color: .orange,
                icon: "clock"
            )
            
            MetricCard(
                title: "Throughput",
                value: "\(Int(analytics.throughputPerHour))",
                subtitle: "Commands/hour",
                color: .purple,
                icon: "speedometer"
            )
        }
    }
    
    private var efficiencyScoreCard: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Queue Efficiency")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(Int(analytics.efficiencyScore * 100))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(efficiencyColor)
            }
            
            ProgressView(value: analytics.efficiencyScore)
                .progressViewStyle(LinearProgressViewStyle(tint: efficiencyColor))
                .scaleEffect(y: 2)
            
            Text(efficiencyDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var efficiencyColor: Color {
        switch analytics.efficiencyScore {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .orange
        default: return .red
        }
    }
    
    private var efficiencyDescription: String {
        switch analytics.efficiencyScore {
        case 0.8...1.0: return "Excellent queue performance with optimal resource utilization"
        case 0.6..<0.8: return "Good performance with room for optimization"
        default: return "Performance needs improvement - consider increasing concurrency or system resources"
        }
    }
    
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Statistics")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                StatRow(label: "Peak Queue Depth", value: "\(analytics.peakQueueDepth)")
                StatRow(label: "Average Execution Time", value: "\(analytics.averageExecutionTime, specifier: "%.1f")s")
                StatRow(label: "Resource Health", value: "\(Int(analytics.resourceUtilization.overallHealth * 100))%")
                StatRow(label: "Last Updated", value: analytics.lastUpdated.formatted(date: .omitted, time: .shortened))
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Performance Section
    
    private var performanceSection: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Execution time chart
                executionTimeChart
                
                // Throughput chart
                throughputChart
                
                // Queue depth chart
                queueDepthChart
            }
            .padding()
        }
    }
    
    private var executionTimeChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Execution Time Trends")
                .font(.headline)
                .fontWeight(.semibold)
            
            Chart(analytics.trendData.suffix(20)) { dataPoint in
                LineMark(
                    x: .value("Time", dataPoint.timestamp),
                    y: .value("Queue Depth", dataPoint.queueDepth)
                )
                .foregroundStyle(.blue)
                .symbol(.circle)
            }
            .frame(height: 150)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks(format: .dateTime.hour().minute())
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var throughputChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Completion Rate")
                .font(.headline)
                .fontWeight(.semibold)
            
            Chart(analytics.trendData.suffix(20)) { dataPoint in
                AreaMark(
                    x: .value("Time", dataPoint.timestamp),
                    y: .value("Rate", dataPoint.completionRate)
                )
                .foregroundStyle(.green.opacity(0.3))
                
                LineMark(
                    x: .value("Time", dataPoint.timestamp),
                    y: .value("Rate", dataPoint.completionRate)
                )
                .foregroundStyle(.green)
            }
            .frame(height: 120)
            .chartYScale(domain: 0...1)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var queueDepthChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Queue Depth Over Time")
                .font(.headline)
                .fontWeight(.semibold)
            
            Chart(analytics.trendData.suffix(20)) { dataPoint in
                BarMark(
                    x: .value("Time", dataPoint.timestamp),
                    y: .value("Depth", dataPoint.queueDepth)
                )
                .foregroundStyle(.orange)
            }
            .frame(height: 120)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Trends Section
    
    private var trendsSection: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Resource utilization over time
                resourceTrendChart
                
                // Wait time trends
                waitTimeTrendChart
                
                // Success rate trends
                successRateTrendChart
            }
            .padding()
        }
    }
    
    private var resourceTrendChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Resource Usage Trends")
                .font(.headline)
                .fontWeight(.semibold)
            
            Chart(analytics.trendData.suffix(20)) { dataPoint in
                LineMark(
                    x: .value("Time", dataPoint.timestamp),
                    y: .value("Usage", dataPoint.resourceUsage)
                )
                .foregroundStyle(.red)
                .symbol(.circle)
            }
            .frame(height: 120)
            .chartYScale(domain: 0...1)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var waitTimeTrendChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Average Wait Time")
                .font(.headline)
                .fontWeight(.semibold)
            
            Chart(analytics.trendData.suffix(20)) { dataPoint in
                AreaMark(
                    x: .value("Time", dataPoint.timestamp),
                    y: .value("Wait Time", dataPoint.averageWaitTime)
                )
                .foregroundStyle(.purple.opacity(0.3))
                
                LineMark(
                    x: .value("Time", dataPoint.timestamp),
                    y: .value("Wait Time", dataPoint.averageWaitTime)
                )
                .foregroundStyle(.purple)
            }
            .frame(height: 120)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var successRateTrendChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Success Rate Trends")
                .font(.headline)
                .fontWeight(.semibold)
            
            Chart(analytics.trendData.suffix(20)) { dataPoint in
                LineMark(
                    x: .value("Time", dataPoint.timestamp),
                    y: .value("Success Rate", dataPoint.completionRate)
                )
                .foregroundStyle(.mint)
                .symbol(.square)
            }
            .frame(height: 120)
            .chartYScale(domain: 0...1)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Resources Section
    
    private var resourcesSection: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Resource utilization summary
                resourceUtilizationCard
                
                // Resource health indicators
                resourceHealthGrid
                
                // Performance recommendations
                performanceRecommendations
            }
            .padding()
        }
    }
    
    private var resourceUtilizationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Resource Utilization")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 10) {
                ResourceBar(label: "CPU", usage: analytics.resourceUtilization.cpuUsage, color: .blue)
                ResourceBar(label: "Memory", usage: analytics.resourceUtilization.memoryUsage, color: .orange)
                ResourceBar(label: "Network", usage: analytics.resourceUtilization.networkUsage, color: .green)
            }
            
            HStack {
                Text("Overall Health:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("\(Int(analytics.resourceUtilization.overallHealth * 100))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(healthColor)
                
                Spacer()
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var healthColor: Color {
        switch analytics.resourceUtilization.overallHealth {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .orange
        default: return .red
        }
    }
    
    private var resourceHealthGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            HealthIndicatorCard(
                title: "CPU Efficiency",
                value: analytics.resourceUtilization.cpuEfficiency,
                icon: "cpu",
                color: .blue
            )
            
            HealthIndicatorCard(
                title: "Memory Efficiency", 
                value: analytics.resourceUtilization.memoryEfficiency,
                icon: "memorychip",
                color: .orange
            )
        }
    }
    
    private var performanceRecommendations: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Recommendations")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(generateRecommendations(), id: \.self) { recommendation in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lightbulb")
                            .foregroundColor(.yellow)
                            .font(.subheadline)
                        
                        Text(recommendation)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func generateRecommendations() -> [String] {
        var recommendations: [String] = []
        
        if analytics.averageQueueTime > 30 {
            recommendations.append("Consider increasing concurrency limits to reduce queue wait time")
        }
        
        if analytics.successRate < 0.9 {
            recommendations.append("Review failed commands to identify common failure patterns")
        }
        
        if analytics.resourceUtilization.cpuUsage > 0.8 {
            recommendations.append("High CPU usage detected - consider reducing concurrent executions")
        }
        
        if analytics.peakQueueDepth > 20 {
            recommendations.append("Queue depth peaks suggest need for better load balancing")
        }
        
        if recommendations.isEmpty {
            recommendations.append("Queue is performing optimally!")
        }
        
        return recommendations
    }
}

// MARK: - Supporting Views

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ResourceBar: View {
    let label: String
    let usage: Double
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .frame(width: 60, alignment: .leading)
            
            ProgressView(value: usage)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
            
            Text("\(Int(usage * 100))%")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
                .frame(width: 40, alignment: .trailing)
        }
    }
}

struct HealthIndicatorCard: View {
    let title: String
    let value: Double
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text("\(Int(value * 100))%")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

extension QueueAnalyticsView {
    // Performance section implementation
    var performanceSection: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Performance charts would go here")
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
    
    // Trends section implementation
    var trendsSection: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Trend analysis would go here")
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
    
    // Resources section implementation
    var resourcesSection: some View {
        ScrollView {
            VStack(spacing: 16) {
                resourceUtilizationCard
                resourceHealthGrid
                performanceRecommendations
            }
            .padding()
        }
    }
}

// MARK: - Preview

struct QueueAnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleAnalytics = QueueAnalytics(
            totalProcessed: 150,
            averageQueueTime: 25.5,
            averageExecutionTime: 12.3,
            peakQueueDepth: 8,
            successRate: 0.94,
            throughputPerHour: 15.0,
            resourceUtilization: ResourceUtilization(
                cpuUsage: 0.65,
                memoryUsage: 0.45,
                networkUsage: 0.12,
                cpuEfficiency: 0.78,
                memoryEfficiency: 0.85,
                timestamp: Date()
            ),
            trendData: [],
            lastUpdated: Date()
        )
        
        QueueAnalyticsView(analytics: sampleAnalytics) {}
    }
}