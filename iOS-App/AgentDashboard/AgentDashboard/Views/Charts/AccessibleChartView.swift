//
//  AccessibleChartView.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Accessibility-enhanced chart wrapper with VoiceOver support and reduced motion handling
//

import SwiftUI
import Charts

// MARK: - Accessible Chart View Wrapper

struct AccessibleChartView<Content: View>: View {
    let chartContent: Content
    let chartData: ChartData
    let accessibilityDescription: String
    
    // Accessibility state
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @AccessibilityFocusState private var isChartFocused: Bool
    
    // Chart navigation for VoiceOver
    @State private var currentDataPointIndex: Int = 0
    @State private var isInAudioGraphMode: Bool = false
    
    init(chartData: ChartData, 
         accessibilityDescription: String,
         @ViewBuilder chartContent: () -> Content) {
        self.chartData = chartData
        self.accessibilityDescription = accessibilityDescription
        self.chartContent = chartContent()
        
        print("[AccessibleChartView] Initialized accessible chart: \(chartData.title)")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Chart title with dynamic type support
            Text(chartData.title)
                .font(.headline)
                .fontWeight(.semibold)
                .dynamicTypeSize(dynamicTypeSize)
            
            // Main chart content
            chartContent
                .accessibilityElement(children: .contain)
                .accessibilityLabel(accessibilityDescription)
                .accessibilityValue(currentAccessibilityValue)
                .accessibilityHint("Chart showing \(chartData.points.count) data points. Use rotor for audio graph.")
                .accessibilityFocused($isChartFocused)
                .accessibilityAddTraits(.allowsDirectInteraction)
                .accessibilityAction(.activate) {
                    handleAccessibilityActivation()
                }
                .accessibilityAction(.increment) {
                    navigateToNextDataPoint()
                }
                .accessibilityAction(.decrement) {
                    navigateToPreviousDataPoint()
                }
                .accessibilityChartDescriptor(createChartDescriptor())
            
            // Accessibility controls (hidden from visual users)
            if isChartFocused {
                accessibilityControls
                    .accessibilityHidden(false)
                    .opacity(0) // Visually hidden but accessible
            }
            
            // Data summary for screen readers
            accessibleDataSummary
        }
        .animation(reduceMotion ? .none : .easeInOut, value: chartData.points)
        .onAppear {
            print("[AccessibleChartView] Chart appeared - setting up accessibility")
        }
    }
    
    // MARK: - Accessibility Controls
    
    private var accessibilityControls: some View {
        VStack {
            Button("Previous Data Point") {
                navigateToPreviousDataPoint()
            }
            .accessibilityLabel("Navigate to previous data point")
            
            Button("Next Data Point") {
                navigateToNextDataPoint()
            }
            .accessibilityLabel("Navigate to next data point")
            
            Button("Enable Audio Graph") {
                enableAudioGraph()
            }
            .accessibilityLabel("Enable audio representation of chart data")
            
            Button("Chart Summary") {
                announceChartSummary()
            }
            .accessibilityLabel("Hear chart summary with key statistics")
        }
    }
    
    // MARK: - Accessible Data Summary
    
    private var accessibleDataSummary: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Chart Summary")
                .font(.caption)
                .fontWeight(.medium)
                .dynamicTypeSize(dynamicTypeSize)
            
            Text(generateAccessibleSummary())
                .font(.caption)
                .foregroundColor(.secondary)
                .dynamicTypeSize(dynamicTypeSize)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Chart summary: \(generateAccessibleSummary())")
    }
    
    // MARK: - Accessibility Actions
    
    private func handleAccessibilityActivation() {
        print("[AccessibleChartView] Accessibility activation - announcing current data point")
        
        guard currentDataPointIndex < chartData.points.count else { return }
        
        let point = chartData.points[currentDataPointIndex]
        let announcement = "Data point \(currentDataPointIndex + 1) of \(chartData.points.count). Value: \(point.value, specifier: "%.1f"). Time: \(point.timestamp, style: .time)"
        
        UIAccessibility.post(notification: .announcement, argument: announcement)
        
        // Haptic feedback
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    private func navigateToNextDataPoint() {
        guard !chartData.points.isEmpty else { return }
        
        currentDataPointIndex = min(currentDataPointIndex + 1, chartData.points.count - 1)
        announceCurrentDataPoint()
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    private func navigateToPreviousDataPoint() {
        guard !chartData.points.isEmpty else { return }
        
        currentDataPointIndex = max(currentDataPointIndex - 1, 0)
        announceCurrentDataPoint()
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    private func announceCurrentDataPoint() {
        guard currentDataPointIndex < chartData.points.count else { return }
        
        let point = chartData.points[currentDataPointIndex]
        let announcement = "Point \(currentDataPointIndex + 1): \(point.value, specifier: "%.1f") at \(point.timestamp, style: .time)"
        
        UIAccessibility.post(notification: .announcement, argument: announcement)
        
        print("[AccessibleChartView] Announced data point: \(currentDataPointIndex)")
    }
    
    private func enableAudioGraph() {
        print("[AccessibleChartView] Enabling audio graph representation")
        
        isInAudioGraphMode = true
        
        // Play audio representation of chart data
        playAudioGraph()
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    private func announceChartSummary() {
        let summary = generateAccessibleSummary()
        UIAccessibility.post(notification: .announcement, argument: "Chart summary: \(summary)")
        
        print("[AccessibleChartView] Announced chart summary")
    }
    
    // MARK: - Audio Graph
    
    private func playAudioGraph() {
        guard !chartData.points.isEmpty else { return }
        
        print("[AccessibleChartView] Playing audio graph for \(chartData.points.count) points")
        
        // Simple audio representation using system sounds
        let minValue = chartData.points.map { $0.value }.min() ?? 0
        let maxValue = chartData.points.map { $0.value }.max() ?? 100
        
        Task {
            for (index, point) in chartData.points.enumerated() {
                // Calculate pitch based on value
                let normalizedValue = (point.value - minValue) / (maxValue - minValue)
                let pitch = 0.5 + normalizedValue * 0.5 // 0.5 to 1.0 range
                
                // Play tone (simplified - would use AVAudioEngine for real implementation)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                
                // Wait between tones
                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                
                if index >= 20 { break } // Limit to prevent overly long audio
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var currentAccessibilityValue: String {
        guard currentDataPointIndex < chartData.points.count else {
            return "No data points available"
        }
        
        let point = chartData.points[currentDataPointIndex]
        return "Point \(currentDataPointIndex + 1) of \(chartData.points.count): \(point.value, specifier: "%.1f")"
    }
    
    private func generateAccessibleSummary() -> String {
        guard !chartData.points.isEmpty else {
            return "No data available"
        }
        
        let count = chartData.points.count
        let latest = chartData.points.last?.value ?? 0
        let min = chartData.points.map { $0.value }.min() ?? 0
        let max = chartData.points.map { $0.value }.max() ?? 0
        let average = chartData.points.map { $0.value }.reduce(0, +) / Double(count)
        
        return "\(count) data points. Latest: \(latest, specifier: "%.1f"). Range: \(min, specifier: "%.1f") to \(max, specifier: "%.1f"). Average: \(average, specifier: "%.1f")."
    }
    
    private func createChartDescriptor() -> AXChartDescriptor {
        let dataPoints = chartData.points.map { point in
            AXDataPoint(x: point.timestamp.timeIntervalSince1970, y: point.value)
        }
        
        let xAxis = AXCategoricalDataAxisDescriptor(
            title: "Time",
            categoryOrder: chartData.points.map { $0.timestamp.timeIntervalSince1970 }
        )
        
        let yAxis = AXNumericDataAxisDescriptor(
            title: "Value",
            range: Double(chartData.points.map { $0.value }.min() ?? 0)...Double(chartData.points.map { $0.value }.max() ?? 100),
            gridlinePositions: []
        )
        
        let series = AXDataSeriesDescriptor(
            name: chartData.title,
            isContinuous: true,
            dataPoints: dataPoints
        )
        
        return AXChartDescriptor(
            title: chartData.title,
            summary: generateAccessibleSummary(),
            xAxis: xAxis,
            yAxis: yAxis,
            additionalAxes: [],
            series: [series]
        )
    }
}

// MARK: - Accessible Chart Container

struct AccessibleChartContainer<Content: View>: View {
    let content: Content
    let coordinationManager: ChartCoordinationManager
    
    @State private var localSelectedRange: ClosedRange<Date>?
    @State private var localSelectedValue: Double?
    
    init(coordinationManager: ChartCoordinationManager, @ViewBuilder content: () -> Content) {
        self.coordinationManager = coordinationManager
        self.content = content()
    }
    
    var body: some View {
        content
            .enhancedChartInteractivity(
                selectedRange: $localSelectedRange,
                selectedValue: $localSelectedValue
            )
            .coordinatedChart(with: coordinationManager)
            .onReceive(coordinationManager.$globalSelectedTimeRange) { globalRange in
                if globalRange != localSelectedRange {
                    localSelectedRange = globalRange
                }
            }
            .onChange(of: localSelectedRange) { newRange in
                coordinationManager.updateSelection(timeRange: newRange, from: UUID())
            }
    }
}

// MARK: - Preview

#if DEBUG
struct AccessibleChartView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleChart = ChartData(
            title: "Sample Accessible Chart",
            points: (0..<20).map { i in
                MetricPoint(
                    timestamp: Date().addingTimeInterval(Double(i) * 300),
                    value: 30 + sin(Double(i) * 0.3) * 20,
                    label: "Point \(i)"
                )
            },
            type: .line
        )
        
        AccessibleChartView(
            chartData: sampleChart,
            accessibilityDescription: "Sample chart showing data trends over time"
        ) {
            SystemMetricsChartView(chartData: sampleChart)
        }
        .padding()
        .preferredColorScheme(.dark)
    }
}
#endif