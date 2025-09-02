//
//  CommandSuccessRateChart.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Custom chart for visualizing automation command success rates and trends
//

import SwiftUI
import Charts

// MARK: - Command Success Rate Chart

struct CommandSuccessRateChart: View {
    let commandData: [CommandExecutionData]
    let timeRange: TimeInterval
    
    @State private var selectedPeriod: CommandPeriodData?
    @State private var showTrendLine: Bool = true
    
    init(commandData: [CommandExecutionData], timeRange: TimeInterval = 86400) { // Default 1 day
        self.commandData = commandData
        self.timeRange = timeRange
        
        print("[CommandSuccessRateChart] Initialized with \(commandData.count) command executions")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with controls
            chartHeader
            
            // Success Rate Chart
            Chart(aggregatedData, id: \.id) { periodData in
                // Success bars
                BarMark(
                    x: .value("Time", periodData.timestamp),
                    y: .value("Successful", periodData.successfulCommands)
                )
                .foregroundStyle(.green.opacity(0.8))
                
                // Failure bars (stacked)
                BarMark(
                    x: .value("Time", periodData.timestamp),
                    y: .value("Failed", periodData.failedCommands),
                    stacking: .standard
                )
                .foregroundStyle(.red.opacity(0.8))
                
                // Success rate trend line
                if showTrendLine {
                    LineMark(
                        x: .value("Time", periodData.timestamp),
                        y: .value("Success Rate", periodData.successRate * Double(periodData.totalCommands))
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .symbol(.circle)
                    .symbolSize(40)
                }
            }
            .frame(height: 200)
            .chartLegend(position: .top, alignment: .leading) {
                HStack(spacing: 16) {
                    legendItem(color: .green, text: "Successful")
                    legendItem(color: .red, text: "Failed")
                    if showTrendLine {
                        legendItem(color: .blue, text: "Success Rate")
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .hour, count: 4)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .omitted)))
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .chartBackground { chartProxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            handleChartSelection(location: location, geometry: geometry, chartProxy: chartProxy)
                        }
                }
            }
            
            // Success rate summary
            successRateSummary
            
            // Selection details
            if let selectedPeriod = selectedPeriod {
                selectionDetails(for: selectedPeriod)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Chart Header
    
    private var chartHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Command Success Rate")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("\(commandData.count) commands • \(formatTimeRange(timeRange))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Controls
            HStack(spacing: 12) {
                Button(action: {
                    showTrendLine.toggle()
                    print("[CommandSuccessRateChart] Trend line toggled: \(showTrendLine)")
                }) {
                    Image(systemName: showTrendLine ? "chart.line.uptrend.xyaxis" : "chart.line.uptrend.xyaxis.circle")
                        .foregroundColor(showTrendLine ? .blue : .secondary)
                }
                
                Text("\(String(format: "%.1f%%", overallSuccessRate))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(overallSuccessRate >= 90 ? .green : (overallSuccessRate >= 70 ? .orange : .red))
            }
        }
    }
    
    // MARK: - Success Rate Summary
    
    private var successRateSummary: some View {
        HStack {
            summaryMetric(
                title: "Total Commands",
                value: "\(commandData.count)",
                color: .primary
            )
            
            Divider().frame(height: 20)
            
            summaryMetric(
                title: "Successful",
                value: "\(successfulCount)",
                color: .green
            )
            
            Divider().frame(height: 20)
            
            summaryMetric(
                title: "Failed", 
                value: "\(failedCount)",
                color: .red
            )
            
            Divider().frame(height: 20)
            
            summaryMetric(
                title: "Success Rate",
                value: "\(String(format: "%.1f%%", overallSuccessRate))",
                color: overallSuccessRate >= 90 ? .green : .orange
            )
        }
        .padding(.vertical, 8)
    }
    
    private func summaryMetric(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: 4) {
            Rectangle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Data Processing
    
    private var aggregatedData: [CommandPeriodData] {
        let endTime = Date()
        let startTime = endTime.addingTimeInterval(-timeRange)
        let intervalCount = 12 // Divide time range into 12 periods
        let intervalDuration = timeRange / Double(intervalCount)
        
        var periods: [CommandPeriodData] = []
        
        for i in 0..<intervalCount {
            let periodStart = startTime.addingTimeInterval(Double(i) * intervalDuration)
            let periodEnd = startTime.addingTimeInterval(Double(i + 1) * intervalDuration)
            
            let periodCommands = commandData.filter { command in
                command.timestamp >= periodStart && command.timestamp < periodEnd
            }
            
            let successful = periodCommands.filter { $0.isSuccessful }.count
            let failed = periodCommands.count - successful
            let successRate = periodCommands.isEmpty ? 0 : Double(successful) / Double(periodCommands.count)
            
            let periodData = CommandPeriodData(
                id: UUID(),
                timestamp: periodStart,
                successfulCommands: successful,
                failedCommands: failed,
                totalCommands: periodCommands.count,
                successRate: successRate
            )
            
            periods.append(periodData)
        }
        
        return periods
    }
    
    // MARK: - Computed Properties
    
    private var successfulCount: Int {
        commandData.filter { $0.isSuccessful }.count
    }
    
    private var failedCount: Int {
        commandData.count - successfulCount
    }
    
    private var overallSuccessRate: Double {
        commandData.isEmpty ? 0 : Double(successfulCount) / Double(commandData.count) * 100
    }
    
    // MARK: - Selection Handling
    
    private func handleChartSelection(location: CGPoint, geometry: GeometryProxy, chartProxy: ChartProxy) {
        print("[CommandSuccessRateChart] Chart tapped at: \(location)")
        
        if let plotFrame = chartProxy.plotAreaFrame {
            let relativeX = (location.x - plotFrame.minX) / plotFrame.width
            let dataIndex = Int(relativeX * Double(aggregatedData.count))
            let clampedIndex = max(0, min(aggregatedData.count - 1, dataIndex))
            
            selectedPeriod = aggregatedData[clampedIndex]
            
            print("[CommandSuccessRateChart] Selected period: \(selectedPeriod?.timestamp ?? Date())")
            
            // Auto-deselect after 4 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                selectedPeriod = nil
            }
        }
    }
    
    private func selectionDetails(for period: CommandPeriodData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Period Details")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Text(period.timestamp, style: .time)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(String(format: "%.1f%%", period.successRate * 100)) success rate")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(period.successRate >= 0.9 ? .green : .orange)
            }
            
            HStack {
                Text("\(period.successfulCommands) successful")
                    .font(.caption)
                    .foregroundColor(.green)
                
                Text("•")
                    .foregroundColor(.secondary)
                
                Text("\(period.failedCommands) failed")
                    .font(.caption)
                    .foregroundColor(.red)
                
                Spacer()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func formatTimeRange(_ seconds: TimeInterval) -> String {
        if seconds < 3600 {
            return "\(Int(seconds / 60))m"
        } else if seconds < 86400 {
            return "\(Int(seconds / 3600))h"
        } else {
            return "\(Int(seconds / 86400))d"
        }
    }
}

// MARK: - Command Data Models

struct CommandPeriodData: Identifiable {
    let id: UUID
    let timestamp: Date
    let successfulCommands: Int
    let failedCommands: Int
    let totalCommands: Int
    let successRate: Double
}

struct CommandExecutionData: Identifiable {
    let id: UUID
    let timestamp: Date
    let command: String
    let isSuccessful: Bool
    let executionTime: TimeInterval
    let source: String
    
    static func createSample() -> [CommandExecutionData] {
        var commands: [CommandExecutionData] = []
        let now = Date()
        
        for i in 0..<100 {
            let command = CommandExecutionData(
                id: UUID(),
                timestamp: now.addingTimeInterval(-Double(i * 300)), // Every 5 minutes
                command: ["Get-Process", "Get-Service", "Test-Connection", "Invoke-RestMethod"].randomElement()!,
                isSuccessful: Double.random(in: 0...1) > 0.2, // 80% success rate
                executionTime: Double.random(in: 0.1...5.0),
                source: ["User", "System", "Scheduled"].randomElement()!
            )
            commands.append(command)
        }
        
        return commands
    }
}

// MARK: - Preview

#if DEBUG
struct CommandSuccessRateChart_Previews: PreviewProvider {
    static var previews: some View {
        let sampleData = CommandExecutionData.createSample()
        
        CommandSuccessRateChart(commandData: sampleData)
            .padding()
            .preferredColorScheme(.dark)
    }
}
#endif