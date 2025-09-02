import SwiftUI

struct PerformanceMetricsWidget: View {
    let cpuUsage: Double
    let memoryUsage: Double
    let processCount: Int
    
    var body: some View {
        WidgetContainerView(
            title: "Performance",
            icon: "speedometer",
            size: .medium
        ) {
            VStack(spacing: 16) {
                HStack(spacing: 20) {
                    // CPU Usage
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                                .frame(width: 50, height: 50)
                            
                            Circle()
                                .trim(from: 0, to: cpuUsage / 100)
                                .stroke(cpuUsage > 80 ? Color.red : cpuUsage > 60 ? Color.orange : Color.green, 
                                       style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .frame(width: 50, height: 50)
                                .rotationEffect(.degrees(-90))
                            
                            Text("\(Int(cpuUsage))%")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        
                        Text("CPU")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    // Memory Usage
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                                .frame(width: 50, height: 50)
                            
                            Circle()
                                .trim(from: 0, to: memoryUsage / 100)
                                .stroke(memoryUsage > 80 ? Color.red : memoryUsage > 60 ? Color.orange : Color.blue, 
                                       style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .frame(width: 50, height: 50)
                                .rotationEffect(.degrees(-90))
                            
                            Text("\(Int(memoryUsage))%")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        
                        Text("Memory")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    // Process Count
                    VStack(spacing: 8) {
                        VStack(spacing: 2) {
                            Text("\(processCount)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                            
                            Text("Processes")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(width: 50, height: 50)
                        .background(Color.purple.opacity(0.1))
                        .clipShape(Circle())
                        
                        Text("Active")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Performance Status Bar
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Circle()
                                .fill(getPerformanceStatusColor())
                                .frame(width: 8, height: 8)
                            
                            Text(getPerformanceStatus())
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        
                        Text(getPerformanceMessage())
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private func getPerformanceStatus() -> String {
        let maxUsage = max(cpuUsage, memoryUsage)
        
        if maxUsage > 90 {
            return "Critical"
        } else if maxUsage > 75 {
            return "High"
        } else if maxUsage > 50 {
            return "Moderate"
        } else {
            return "Normal"
        }
    }
    
    private func getPerformanceStatusColor() -> Color {
        let maxUsage = max(cpuUsage, memoryUsage)
        
        if maxUsage > 90 {
            return .red
        } else if maxUsage > 75 {
            return .orange
        } else if maxUsage > 50 {
            return .yellow
        } else {
            return .green
        }
    }
    
    private func getPerformanceMessage() -> String {
        let maxUsage = max(cpuUsage, memoryUsage)
        
        if maxUsage > 90 {
            return "System resources are critically high"
        } else if maxUsage > 75 {
            return "System resources are elevated"
        } else if maxUsage > 50 {
            return "System running normally"
        } else {
            return "System resources are optimal"
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        PerformanceMetricsWidget(
            cpuUsage: 45.2,
            memoryUsage: 67.8,
            processCount: 23
        )
        .frame(height: 160)
        
        PerformanceMetricsWidget(
            cpuUsage: 89.1,
            memoryUsage: 95.3,
            processCount: 47
        )
        .frame(height: 160)
    }
    .padding()
}