//
//  SystemMetricsChartView.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  System metrics visualization using Swift Charts with real-time updates
//

import SwiftUI
import Charts

// MARK: - System Metrics Chart View

struct SystemMetricsChartView: View {
    let chartData: ChartData
    let showAnimation: Bool
    let interactionEnabled: Bool
    
    @State private var selectedPoint: MetricPoint?
    @State private var chartScale: Double = 1.0
    
    init(chartData: ChartData, 
         showAnimation: Bool = true,
         interactionEnabled: Bool = true) {
        self.chartData = chartData
        self.showAnimation = showAnimation
        self.interactionEnabled = interactionEnabled
        
        print("[SystemMetricsChartView] Initialized chart: \(chartData.title) with \(chartData.points.count) points")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Chart Header
            chartHeader
            
            // Main Chart
            Chart(chartData.points, id: \.timestamp) { point in
                switch chartData.type {
                case .line:
                    LineMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(chartColor)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                    
                case .area:
                    AreaMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(chartGradient)
                    .interpolationMethod(.catmullRom)
                    
                case .bar:
                    BarMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(chartColor)
                    
                case .scatter:
                    PointMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(chartColor)
                    .symbolSize(50)
                }
                
                // Add selection indicator
                if let selectedPoint = selectedPoint,
                   selectedPoint.timestamp == point.timestamp {
                    RuleMark(x: .value("Selected", point.timestamp))
                        .foregroundStyle(.secondary)
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                }
            }
            .frame(height: 200)
            .chartBackground { chartProxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            if interactionEnabled {
                                handleChartTap(location: location, geometry: geometry, chartProxy: chartProxy)
                            }
                        }
                }
            }
            .chartAngleSelection(value: .constant(nil))
            .chartXAxis {
                AxisMarks(values: .stride(by: .hour)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.hour())
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .animation(showAnimation ? .easeInOut(duration: 0.5) : .none, value: chartData.points)
            .scaleEffect(chartScale)
            .onMagnificationChanged { value in
                if interactionEnabled {
                    chartScale = max(0.5, min(2.0, value))
                }
            }
            
            // Selection Info
            if let selectedPoint = selectedPoint {
                selectionInfoView(for: selectedPoint)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            print("[SystemMetricsChartView] Chart appeared: \(chartData.title)")
        }
    }
    
    // MARK: - Chart Components
    
    private var chartHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(chartData.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if let latestPoint = chartData.points.last {
                    Text("\(latestPoint.value, specifier: "%.1f")")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(chartColor)
                }
            }
            
            Spacer()
            
            // Chart type indicator
            Image(systemName: chartTypeIcon)
                .font(.title2)
                .foregroundColor(.secondary)
        }
    }
    
    private func selectionInfoView(for point: MetricPoint) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Selected Point")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Text(point.timestamp, style: .time)
                    .font(.subheadline)
                Spacer()
                Text("\(point.value, specifier: "%.2f")")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .transition(.opacity.combined(with: .scale))
    }
    
    // MARK: - Chart Styling
    
    private var chartColor: Color {
        switch chartData.title {
        case let title where title.contains("CPU"):
            return .blue
        case let title where title.contains("Memory"):
            return .orange
        case let title where title.contains("Disk"):
            return .red
        case let title where title.contains("Agent"):
            return .green
        default:
            return .primary
        }
    }
    
    private var chartGradient: LinearGradient {
        LinearGradient(
            colors: [chartColor.opacity(0.6), chartColor.opacity(0.1)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var chartTypeIcon: String {
        switch chartData.type {
        case .line: return "chart.xyaxis.line"
        case .area: return "chart.line.uptrend.xyaxis"
        case .bar: return "chart.bar"
        case .scatter: return "chart.dots.scatter"
        }
    }
    
    // MARK: - Interaction Handling
    
    private func handleChartTap(location: CGPoint, geometry: GeometryProxy, chartProxy: ChartProxy) {
        print("[SystemMetricsChartView] Chart tapped at location: \(location)")
        
        // Convert tap location to data point
        if let plotFrame = chartProxy.plotAreaFrame {
            let relativeX = location.x - plotFrame.minX
            let relativePosition = relativeX / plotFrame.width
            
            // Find closest data point
            if !chartData.points.isEmpty {
                let dataIndex = Int(relativePosition * Double(chartData.points.count))
                let clampedIndex = max(0, min(chartData.points.count - 1, dataIndex))
                
                selectedPoint = chartData.points[clampedIndex]
                print("[SystemMetricsChartView] Selected point: \(selectedPoint?.timestamp ?? Date())")
                
                // Auto-deselect after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    selectedPoint = nil
                }
            }
        }
    }
}

// MARK: - Magnification Gesture Extension

extension View {
    func onMagnificationChanged(perform action: @escaping (Double) -> Void) -> some View {
        self.gesture(
            MagnificationGesture()
                .onChanged { value in
                    action(value)
                }
        )
    }
}

// MARK: - Preview

#if DEBUG
struct SystemMetricsChartView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleData = ChartData(
            title: "CPU Usage",
            points: generateSamplePoints(),
            type: .line
        )
        
        SystemMetricsChartView(chartData: sampleData)
            .padding()
            .preferredColorScheme(.dark)
    }
    
    static func generateSamplePoints() -> [MetricPoint] {
        let now = Date()
        return (0..<50).map { i in
            MetricPoint(
                timestamp: now.addingTimeInterval(Double(i) * 60), // 1 minute intervals
                value: 30 + sin(Double(i) * 0.2) * 20 + Double.random(in: -5...5),
                label: "CPU"
            )
        }
    }
}
#endif