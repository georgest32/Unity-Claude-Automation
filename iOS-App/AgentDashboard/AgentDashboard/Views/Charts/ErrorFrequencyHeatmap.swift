//
//  ErrorFrequencyHeatmap.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Custom heatmap chart for visualizing error frequency patterns using RectangleMark
//

import SwiftUI
import Charts

// MARK: - Error Frequency Heatmap

struct ErrorFrequencyHeatmap: View {
    let errorData: [ErrorDataPoint]
    let timeRange: TimeInterval
    
    @State private var selectedCell: ErrorDataPoint?
    @State private var heatmapScale: Double = 1.0
    
    private let hoursInDay = 24
    private let daysToShow = 7
    
    init(errorData: [ErrorDataPoint], timeRange: TimeInterval = 604800) { // Default 1 week
        self.errorData = errorData
        self.timeRange = timeRange
        
        print("[ErrorFrequencyHeatmap] Initialized with \(errorData.count) error data points")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            heatmapHeader
            
            // Heatmap Chart
            Chart(processedHeatmapData, id: \.id) { dataPoint in
                RectangleMark(
                    xStart: .value("Hour Start", dataPoint.hour),
                    xEnd: .value("Hour End", dataPoint.hour + 1),
                    yStart: .value("Day Start", dataPoint.dayOfWeek),
                    yEnd: .value("Day End", dataPoint.dayOfWeek + 1)
                )
                .foregroundStyle(intensityColor(for: dataPoint.errorCount))
                .opacity(dataPoint.errorCount > 0 ? 0.8 : 0.2)
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: Array(stride(from: 0, through: 23, by: 4))) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let hour = value.as(Int.self) {
                            Text("\(hour):00")
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(values: Array(0..<7)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let day = value.as(Int.self) {
                            Text(dayName(for: day))
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartBackground { chartProxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            handleHeatmapSelection(location: location, geometry: geometry, chartProxy: chartProxy)
                        }
                }
            }
            .scaleEffect(heatmapScale)
            .onMagnificationChanged { value in
                heatmapScale = max(0.8, min(1.5, value))
            }
            
            // Legend
            heatmapLegend
            
            // Selection info
            if let selectedCell = selectedCell {
                selectionInfoView(for: selectedCell)
            }
            
            // Summary statistics
            heatmapSummary
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Header
    
    private var heatmapHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Error Frequency Heatmap")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Last 7 days • \(errorData.count) total errors")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("Peak: \(maxErrorCount)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
                
                Text("Avg: \(String(format: "%.1f", averageErrorCount))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Legend
    
    private var heatmapLegend: some View {
        HStack {
            Text("Less")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { intensity in
                    Rectangle()
                        .fill(legendColor(for: intensity))
                        .frame(width: 12, height: 12)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                }
            }
            
            Text("More")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("Errors per hour")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Summary
    
    private var heatmapSummary: some View {
        HStack {
            summaryItem(title: "Total Errors", value: "\(errorData.count)", color: .primary)
            Divider().frame(height: 20)
            summaryItem(title: "Peak Hour", value: peakHourString, color: .red)
            Divider().frame(height: 20)
            summaryItem(title: "Quiet Hour", value: quietHourString, color: .green)
        }
        .padding(.vertical, 8)
    }
    
    private func summaryItem(title: String, value: String, color: Color) -> some View {
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
    
    // MARK: - Data Processing
    
    private var processedHeatmapData: [HeatmapDataPoint] {
        var heatmapPoints: [HeatmapDataPoint] = []
        
        // Create grid of hour x day
        for day in 0..<daysToShow {
            for hour in 0..<hoursInDay {
                let errorCount = countErrorsForSlot(day: day, hour: hour)
                
                let dataPoint = HeatmapDataPoint(
                    id: UUID(),
                    hour: hour,
                    dayOfWeek: day,
                    errorCount: errorCount,
                    timestamp: dateForSlot(day: day, hour: hour)
                )
                
                heatmapPoints.append(dataPoint)
            }
        }
        
        return heatmapPoints
    }
    
    private func countErrorsForSlot(day: Int, hour: Int) -> Int {
        let slotDate = dateForSlot(day: day, hour: hour)
        let nextHour = slotDate.addingTimeInterval(3600)
        
        return errorData.filter { errorPoint in
            errorPoint.timestamp >= slotDate && errorPoint.timestamp < nextHour
        }.count
    }
    
    private func dateForSlot(day: Int, hour: Int) -> Date {
        let now = Date()
        let calendar = Calendar.current
        
        // Go back 'day' days and set to 'hour' o'clock
        let targetDate = calendar.date(byAdding: .day, value: -day, to: now) ?? now
        
        var components = calendar.dateComponents([.year, .month, .day], from: targetDate)
        components.hour = hour
        components.minute = 0
        components.second = 0
        
        return calendar.date(from: components) ?? now
    }
    
    // MARK: - Computed Values
    
    private var maxErrorCount: Int {
        processedHeatmapData.map { $0.errorCount }.max() ?? 0
    }
    
    private var averageErrorCount: Double {
        let total = processedHeatmapData.map { $0.errorCount }.reduce(0, +)
        return processedHeatmapData.isEmpty ? 0 : Double(total) / Double(processedHeatmapData.count)
    }
    
    private var peakHourString: String {
        guard let peakPoint = processedHeatmapData.max(by: { $0.errorCount < $1.errorCount }) else {
            return "N/A"
        }
        return "\(dayName(for: peakPoint.dayOfWeek)) \(peakPoint.hour):00"
    }
    
    private var quietHourString: String {
        guard let quietPoint = processedHeatmapData.min(by: { $0.errorCount < $1.errorCount }) else {
            return "N/A"
        }
        return "\(dayName(for: quietPoint.dayOfWeek)) \(quietPoint.hour):00"
    }
    
    // MARK: - Helper Methods
    
    private func intensityColor(for errorCount: Int) -> Color {
        guard maxErrorCount > 0 else { return .gray.opacity(0.1) }
        
        let intensity = Double(errorCount) / Double(maxErrorCount)
        
        switch intensity {
        case 0: return .gray.opacity(0.1)
        case 0..<0.2: return .green.opacity(0.3)
        case 0.2..<0.4: return .yellow.opacity(0.5)
        case 0.4..<0.6: return .orange.opacity(0.7)
        case 0.6..<0.8: return .red.opacity(0.8)
        default: return .red
        }
    }
    
    private func legendColor(for intensity: Int) -> Color {
        let normalizedIntensity = Double(intensity) / 4.0
        
        switch normalizedIntensity {
        case 0: return .gray.opacity(0.2)
        case 0.25: return .green.opacity(0.4)
        case 0.5: return .yellow.opacity(0.6)
        case 0.75: return .orange.opacity(0.8)
        default: return .red
        }
    }
    
    private func dayName(for dayIndex: Int) -> String {
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return dayNames[dayIndex % 7]
    }
    
    private func handleHeatmapSelection(location: CGPoint, geometry: GeometryProxy, chartProxy: ChartProxy) {
        print("[ErrorFrequencyHeatmap] Heatmap tapped at: \(location)")
        
        if let plotFrame = chartProxy.plotAreaFrame {
            let relativeX = (location.x - plotFrame.minX) / plotFrame.width
            let relativeY = (location.y - plotFrame.minY) / plotFrame.height
            
            let selectedHour = Int(relativeX * Double(hoursInDay))
            let selectedDay = Int((1 - relativeY) * Double(daysToShow)) // Invert Y
            
            // Find matching data point
            selectedCell = processedHeatmapData.first { point in
                point.hour == selectedHour && point.dayOfWeek == selectedDay
            }
            
            if let cell = selectedCell {
                print("[ErrorFrequencyHeatmap] Selected cell: \(dayName(for: cell.dayOfWeek)) \(cell.hour):00, errors: \(cell.errorCount)")
            }
            
            // Auto-deselect after 4 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                selectedCell = nil
            }
        }
    }
    
    private func selectionInfoView(for dataPoint: HeatmapDataPoint) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Selected Period")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Text("\(dayName(for: dataPoint.dayOfWeek)) \(dataPoint.hour):00")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(dataPoint.errorCount) errors")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(intensityColor(for: dataPoint.errorCount))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Heatmap Data Models

struct HeatmapDataPoint: Identifiable {
    let id: UUID
    let hour: Int // 0-23
    let dayOfWeek: Int // 0-6 (0 = Sunday)
    let errorCount: Int
    let timestamp: Date
}

struct ErrorDataPoint: Identifiable {
    let id: UUID
    let timestamp: Date
    let errorType: String
    let severity: ErrorSeverity
    let source: String
    let message: String
    
    enum ErrorSeverity: String, CaseIterable {
        case low = "Low"
        case medium = "Medium" 
        case high = "High"
        case critical = "Critical"
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .yellow
            case .high: return .orange
            case .critical: return .red
            }
        }
    }
}

// MARK: - Magnification Gesture Extension

extension View {
    func onMagnificationChanged(_ action: @escaping (Double) -> Void) -> some View {
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
struct ErrorFrequencyHeatmap_Previews: PreviewProvider {
    static var previews: some View {
        let sampleErrorData = generateSampleErrorData()
        
        ErrorFrequencyHeatmap(errorData: sampleErrorData)
            .padding()
            .preferredColorScheme(.dark)
    }
    
    static func generateSampleErrorData() -> [ErrorDataPoint] {
        var errors: [ErrorDataPoint] = []
        let now = Date()
        
        // Generate random errors over the past week
        for _ in 0..<50 {
            let randomOffset = Double.random(in: 0...604800) // Random time in past week
            let timestamp = now.addingTimeInterval(-randomOffset)
            
            let error = ErrorDataPoint(
                id: UUID(),
                timestamp: timestamp,
                errorType: ["NetworkError", "ValidationError", "TimeoutError", "AuthError"].randomElement()!,
                severity: ErrorDataPoint.ErrorSeverity.allCases.randomElement()!,
                source: ["WebSocket", "API", "Database", "Authentication"].randomElement()!,
                message: "Sample error message"
            )
            
            errors.append(error)
        }
        
        return errors
    }
}
#endif