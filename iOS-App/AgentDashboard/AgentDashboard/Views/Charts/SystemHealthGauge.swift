//
//  SystemHealthGauge.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Custom system health gauge using SwiftUI Gauge for composite health visualization
//

import SwiftUI

// MARK: - System Health Gauge

struct SystemHealthGauge: View {
    let systemStatus: SystemStatus?
    let showDetails: Bool
    
    @State private var animatedValue: Double = 0
    
    init(systemStatus: SystemStatus?, showDetails: Bool = true) {
        self.systemStatus = systemStatus
        self.showDetails = showDetails
        
        print("[SystemHealthGauge] Initialized with system status: \(systemStatus?.isHealthy ?? false)")
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Main Health Gauge
            healthGauge
            
            // Health Details
            if showDetails {
                healthDetailsGrid
            }
            
            // Health Score Breakdown
            if showDetails {
                healthScoreBreakdown
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
            animateHealthValue()
        }
        .onChange(of: systemStatus?.timestamp) { _ in
            animateHealthValue()
        }
    }
    
    // MARK: - Health Gauge
    
    private var healthGauge: some View {
        VStack(spacing: 12) {
            Text("System Health")
                .font(.headline)
                .fontWeight(.semibold)
            
            Gauge(value: animatedValue, in: 0...100) {
                Text("Health")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } currentValueLabel: {
                Text("\(Int(animatedValue))")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(healthScoreColor)
            } minimumValueLabel: {
                Text("0")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } maximumValueLabel: {
                Text("100")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(healthScoreGradient)
            .scaleEffect(1.2)
        }
    }
    
    // MARK: - Health Details Grid
    
    private var healthDetailsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            // CPU Usage
            MetricCard(
                title: "CPU",
                value: systemStatus?.cpuUsage ?? 0,
                unit: "%",
                icon: "cpu",
                color: .blue,
                threshold: 80
            )
            
            // Memory Usage
            MetricCard(
                title: "Memory",
                value: systemStatus?.memoryUsage ?? 0,
                unit: "%", 
                icon: "memorychip",
                color: .orange,
                threshold: 85
            )
            
            // Disk Usage
            MetricCard(
                title: "Disk",
                value: systemStatus?.diskUsage ?? 0,
                unit: "%",
                icon: "internaldrive",
                color: .red,
                threshold: 90
            )
            
            // Active Agents
            MetricCard(
                title: "Agents",
                value: Double(systemStatus?.activeAgents ?? 0),
                unit: "",
                icon: "person.3",
                color: .green,
                threshold: 10,
                isReversed: true // More agents is better
            )
        }
    }
    
    // MARK: - Health Score Breakdown
    
    private var healthScoreBreakdown: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Health Score Breakdown")
                .font(.subheadline)
                .fontWeight(.medium)
            
            VStack(spacing: 6) {
                healthScoreComponent(
                    name: "CPU Health",
                    score: cpuHealthScore,
                    weight: 0.3
                )
                
                healthScoreComponent(
                    name: "Memory Health", 
                    score: memoryHealthScore,
                    weight: 0.3
                )
                
                healthScoreComponent(
                    name: "Disk Health",
                    score: diskHealthScore,
                    weight: 0.2
                )
                
                healthScoreComponent(
                    name: "Agent Activity",
                    score: agentActivityScore,
                    weight: 0.2
                )
            }
        }
        .padding(.top, 8)
    }
    
    private func healthScoreComponent(name: String, score: Double, weight: Double) -> some View {
        HStack {
            Text(name)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Mini gauge
            Gauge(value: score, in: 0...100) {
                EmptyView()
            }
            .gaugeStyle(.accessoryLinear)
            .tint(scoreColor(score))
            .frame(width: 60)
            
            Text("\(Int(score))")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(scoreColor(score))
                .frame(width: 25, alignment: .trailing)
            
            Text("(\(Int(weight * 100))%)")
                .font(.caption2)
                .foregroundColor(.tertiary)
                .frame(width: 30, alignment: .trailing)
        }
    }
    
    // MARK: - Computed Properties
    
    private var overallHealthScore: Double {
        guard let status = systemStatus else { return 0 }
        
        let cpuScore = cpuHealthScore * 0.3
        let memoryScore = memoryHealthScore * 0.3
        let diskScore = diskHealthScore * 0.2
        let agentScore = agentActivityScore * 0.2
        
        return cpuScore + memoryScore + diskScore + agentScore
    }
    
    private var cpuHealthScore: Double {
        guard let status = systemStatus else { return 0 }
        return max(0, 100 - status.cpuUsage)
    }
    
    private var memoryHealthScore: Double {
        guard let status = systemStatus else { return 0 }
        return max(0, 100 - status.memoryUsage)
    }
    
    private var diskHealthScore: Double {
        guard let status = systemStatus else { return 0 }
        return max(0, 100 - status.diskUsage)
    }
    
    private var agentActivityScore: Double {
        guard let status = systemStatus else { return 0 }
        let idealAgentCount = 5.0
        let agentRatio = Double(status.activeAgents) / idealAgentCount
        return min(100, agentRatio * 100)
    }
    
    private var healthScoreColor: Color {
        let score = overallHealthScore
        switch score {
        case 80...100: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }
    
    private var healthScoreGradient: LinearGradient {
        LinearGradient(
            colors: [.red, .orange, .yellow, .green],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }
    
    // MARK: - Animation
    
    private func animateHealthValue() {
        let targetValue = overallHealthScore
        
        withAnimation(.easeInOut(duration: 1.0)) {
            animatedValue = targetValue
        }
        
        print("[SystemHealthGauge] Animated health value to: \(targetValue)")
    }
}

// MARK: - Metric Card

struct MetricCard: View {
    let title: String
    let value: Double
    let unit: String
    let icon: String
    let color: Color
    let threshold: Double
    let isReversed: Bool // For metrics where higher is better
    
    init(title: String, value: Double, unit: String, icon: String, color: Color, threshold: Double, isReversed: Bool = false) {
        self.title = title
        self.value = value
        self.unit = unit
        self.icon = icon
        self.color = color
        self.threshold = threshold
        self.isReversed = isReversed
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            HStack(alignment: .bottom, spacing: 4) {
                Text("\(value, specifier: "%.1f")")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(metricColor)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Status indicator
                Circle()
                    .fill(metricColor)
                    .frame(width: 8, height: 8)
            }
            
            // Mini progress bar
            ProgressView(value: progressValue, total: 100)
                .tint(metricColor)
                .scaleEffect(y: 0.5)
        }
        .padding(12)
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var metricColor: Color {
        if isReversed {
            return value >= threshold ? .green : (value >= threshold * 0.5 ? .orange : .red)
        } else {
            return value <= threshold ? .green : (value <= threshold * 1.2 ? .orange : .red)
        }
    }
    
    private var progressValue: Double {
        if isReversed {
            return value
        } else {
            return min(100, value)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct SystemHealthGauge_Previews: PreviewProvider {
    static var previews: some View {
        let sampleStatus = SystemStatus(
            timestamp: Date(),
            isHealthy: true,
            cpuUsage: 45.5,
            memoryUsage: 62.3,
            diskUsage: 78.1,
            activeAgents: 4,
            totalModules: 12,
            uptime: 7200
        )
        
        SystemHealthGauge(systemStatus: sampleStatus)
            .padding()
            .preferredColorScheme(.dark)
    }
}
#endif