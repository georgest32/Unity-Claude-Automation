//
//  AgentStatusTimelineChart.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Custom timeline chart for visualizing agent status changes over time
//

import SwiftUI
import Charts

// MARK: - Agent Status Timeline Chart

struct AgentStatusTimelineChart: View {
    let agents: [Agent]
    let timeRange: TimeInterval
    
    @State private var selectedAgent: Agent?
    @State private var selectedTimePoint: Date?
    
    init(agents: [Agent], timeRange: TimeInterval = 3600) { // Default 1 hour
        self.agents = agents
        self.timeRange = timeRange
        
        print("[AgentStatusTimelineChart] Initialized with \(agents.count) agents, time range: \(timeRange)s")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            timelineHeader
            
            // Timeline Chart
            Chart {
                ForEach(agentTimelineData, id: \.agentId) { agentData in
                    ForEach(agentData.statusPeriods, id: \.id) { period in
                        // Status band
                        RectangleMark(
                            xStart: .value("Start", period.startTime),
                            xEnd: .value("End", period.endTime),
                            yStart: .value("Agent Start", agentData.yPosition - 0.4),
                            yEnd: .value("Agent End", agentData.yPosition + 0.4)
                        )
                        .foregroundStyle(period.status.color)
                        .opacity(0.8)
                        
                        // Status transition markers
                        if period != agentData.statusPeriods.last {
                            PointMark(
                                x: .value("Transition", period.endTime),
                                y: .value("Agent", agentData.yPosition)
                            )
                            .foregroundStyle(.primary)
                            .symbolSize(30)
                        }
                    }
                    
                    // Agent name label
                    RuleMark(
                        yStart: .value("Agent", agentData.yPosition - 0.45),
                        yEnd: .value("Agent", agentData.yPosition + 0.45)
                    )
                    .foregroundStyle(.clear)
                    .annotation(position: .leading) {
                        Text(agentData.agentName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Selection indicator
                if let selectedTime = selectedTimePoint {
                    RuleMark(x: .value("Selected", selectedTime))
                        .foregroundStyle(.blue)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                }
            }
            .frame(height: CGFloat(agents.count * 60 + 40))
            .chartXAxis {
                AxisMarks(values: .stride(by: .minute, count: 15)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .omitted)).minute())
                }
            }
            .chartYAxis(.hidden)
            .chartBackground { chartProxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            handleTimelineSelection(location: location, geometry: geometry, chartProxy: chartProxy)
                        }
                }
            }
            
            // Selection info
            if let selectedTime = selectedTimePoint {
                timelineSelectionInfo(at: selectedTime)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Timeline Header
    
    private var timelineHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Agent Status Timeline")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("\(agents.count) agents • \(formatTimeRange(timeRange))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Status legend
            HStack(spacing: 12) {
                ForEach(AgentStatus.allCases, id: \.rawValue) { status in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(status.color)
                            .frame(width: 8, height: 8)
                        Text(status.rawValue.capitalized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Timeline Data Processing
    
    private var agentTimelineData: [AgentTimelineData] {
        let endTime = Date()
        let startTime = endTime.addingTimeInterval(-timeRange)
        
        return agents.enumerated().map { index, agent in
            let statusPeriods = generateStatusPeriods(for: agent, from: startTime, to: endTime)
            
            return AgentTimelineData(
                agentId: agent.id,
                agentName: agent.name,
                yPosition: Double(index),
                statusPeriods: statusPeriods
            )
        }
    }
    
    private func generateStatusPeriods(for agent: Agent, from startTime: Date, to endTime: Date) -> [StatusPeriod] {
        // For now, generate mock status periods based on current agent status
        // In a real implementation, this would come from historical data
        
        let periodDuration = timeRange / 4 // Divide timeline into 4 periods
        var periods: [StatusPeriod] = []
        
        let statuses: [AgentStatus] = [.idle, .running, agent.status, .running]
        
        for i in 0..<4 {
            let periodStart = startTime.addingTimeInterval(Double(i) * periodDuration)
            let periodEnd = startTime.addingTimeInterval(Double(i + 1) * periodDuration)
            
            let period = StatusPeriod(
                id: UUID(),
                status: statuses[i],
                startTime: periodStart,
                endTime: periodEnd
            )
            
            periods.append(period)
        }
        
        return periods
    }
    
    // MARK: - Selection Handling
    
    private func handleTimelineSelection(location: CGPoint, geometry: GeometryProxy, chartProxy: ChartProxy) {
        print("[AgentStatusTimelineChart] Timeline tapped at: \(location)")
        
        if let plotFrame = chartProxy.plotAreaFrame {
            let relativeX = location.x - plotFrame.minX
            let timeRatio = relativeX / plotFrame.width
            
            let selectedTime = Date().addingTimeInterval(-timeRange + (timeRange * Double(timeRatio)))
            selectedTimePoint = selectedTime
            
            print("[AgentStatusTimelineChart] Selected time: \(selectedTime)")
            
            // Auto-deselect after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                selectedTimePoint = nil
            }
        }
    }
    
    private func timelineSelectionInfo(at time: Date) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Selected Time")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(time, style: .time)
                .font(.subheadline)
                .fontWeight(.medium)
            
            // Show agent statuses at selected time
            VStack(alignment: .leading, spacing: 4) {
                ForEach(agents.prefix(3), id: \.id) { agent in
                    HStack {
                        Circle()
                            .fill(agent.status.color)
                            .frame(width: 6, height: 6)
                        Text(agent.name)
                            .font(.caption)
                        Spacer()
                        Text(agent.status.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
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
        } else {
            return "\(Int(seconds / 3600))h"
        }
    }
}

// MARK: - Timeline Data Models

struct AgentTimelineData {
    let agentId: UUID
    let agentName: String
    let yPosition: Double
    let statusPeriods: [StatusPeriod]
}

struct StatusPeriod: Equatable {
    let id: UUID
    let status: AgentStatus
    let startTime: Date
    let endTime: Date
    
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
}

// MARK: - Preview

#if DEBUG
struct AgentStatusTimelineChart_Previews: PreviewProvider {
    static var previews: some View {
        let sampleAgents = [
            Agent(
                id: UUID(),
                name: "CLI Orchestrator",
                type: .orchestrator,
                status: .running,
                description: "Main orchestrator",
                startTime: Date().addingTimeInterval(-3600),
                lastActivity: Date(),
                resourceUsage: nil,
                configuration: [:]
            ),
            Agent(
                id: UUID(),
                name: "System Monitor",
                type: .monitor,
                status: .idle,
                description: "Health monitor",
                startTime: Date().addingTimeInterval(-7200),
                lastActivity: Date().addingTimeInterval(-300),
                resourceUsage: nil,
                configuration: [:]
            )
        ]
        
        AgentStatusTimelineChart(agents: sampleAgents)
            .padding()
            .preferredColorScheme(.dark)
    }
}
#endif