//
//  ChartPerformanceOptimizer.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Performance optimization for interactive chart features with 60fps maintenance
//

import SwiftUI
import Charts

// MARK: - Chart Performance Optimizer

final class ChartPerformanceOptimizer: ObservableObject {
    
    // Performance configuration
    struct PerformanceConfig {
        let maxDataPointsForInteraction: Int = 1000
        let interactionThrottleInterval: TimeInterval = 0.016 // 60fps
        let animationDuration: TimeInterval = 0.3
        let reducedMotionFallback: TimeInterval = 0.1
        let memoryThreshold: Int = 100 * 1024 * 1024 // 100MB
    }
    
    private let config = PerformanceConfig()
    
    // Performance metrics
    @Published var currentFrameRate: Double = 60.0
    @Published var memoryUsage: Int = 0
    @Published var interactionLatency: TimeInterval = 0
    
    // Throttling state
    private var lastInteractionTime: Date = Date()
    private var interactionQueue: DispatchQueue
    
    // Performance monitoring
    private var performanceMetrics = InteractiveChartMetrics()
    
    init() {
        self.interactionQueue = DispatchQueue(label: "com.agentdashboard.chart.performance", qos: .userInteractive)
        
        print("[ChartPerformanceOptimizer] Initialized with max data points: \(config.maxDataPointsForInteraction)")
    }
    
    // MARK: - Interaction Throttling
    
    func throttledInteraction<T>(_ action: @escaping () -> T) -> T? {
        let now = Date()
        
        guard now.timeIntervalSince(lastInteractionTime) >= config.interactionThrottleInterval else {
            performanceMetrics.recordThrottledInteraction()
            return nil
        }
        
        lastInteractionTime = now
        
        let startTime = Date()
        let result = action()
        let duration = Date().timeIntervalSince(startTime)
        
        performanceMetrics.recordInteraction(duration: duration)
        interactionLatency = duration
        
        return result
    }
    
    func asyncThrottledInteraction(_ action: @escaping () async -> Void) {
        let now = Date()
        
        guard now.timeIntervalSince(lastInteractionTime) >= config.interactionThrottleInterval else {
            performanceMetrics.recordThrottledInteraction()
            return
        }
        
        lastInteractionTime = now
        
        Task {
            let startTime = Date()
            await action()
            let duration = Date().timeIntervalSince(startTime)
            
            await MainActor.run {
                performanceMetrics.recordInteraction(duration: duration)
                interactionLatency = duration
            }
        }
    }
    
    // MARK: - Data Optimization
    
    func optimizeChartData(_ chartData: ChartData) -> ChartData {
        guard chartData.points.count > config.maxDataPointsForInteraction else {
            return chartData // No optimization needed
        }
        
        print("[ChartPerformanceOptimizer] Optimizing chart data from \(chartData.points.count) to \(config.maxDataPointsForInteraction) points")
        
        // Use adaptive sampling to maintain chart shape while reducing points
        let optimizedPoints = adaptiveSample(chartData.points, targetCount: config.maxDataPointsForInteraction)
        
        performanceMetrics.recordDataOptimization(
            originalCount: chartData.points.count,
            optimizedCount: optimizedPoints.count
        )
        
        return ChartData(
            title: chartData.title,
            points: optimizedPoints,
            type: chartData.type
        )
    }
    
    private func adaptiveSample(_ points: [MetricPoint], targetCount: Int) -> [MetricPoint] {
        guard points.count > targetCount else { return points }
        
        let step = Double(points.count) / Double(targetCount)
        var sampledPoints: [MetricPoint] = []
        
        for i in 0..<targetCount {
            let index = Int(Double(i) * step)
            if index < points.count {
                sampledPoints.append(points[index])
            }
        }
        
        // Always include the last point
        if let lastPoint = points.last, !sampledPoints.contains(where: { $0.timestamp == lastPoint.timestamp }) {
            sampledPoints.append(lastPoint)
        }
        
        return sampledPoints
    }
    
    // MARK: - Memory Management
    
    func monitorMemoryUsage() {
        let usage = getCurrentMemoryUsage()
        memoryUsage = usage
        
        performanceMetrics.recordMemoryUsage(usage)
        
        if usage > config.memoryThreshold {
            print("[ChartPerformanceOptimizer] Memory threshold exceeded: \(usage) bytes")
            performanceMetrics.recordMemoryWarning()
        }
    }
    
    private func getCurrentMemoryUsage() -> Int {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return result == KERN_SUCCESS ? Int(info.resident_size) : 0
    }
    
    // MARK: - Animation Control
    
    func optimizedAnimation(for reduceMotion: Bool) -> Animation? {
        if reduceMotion {
            return .easeInOut(duration: config.reducedMotionFallback)
        } else {
            return .easeInOut(duration: config.animationDuration)
        }
    }
    
    func shouldEnableAnimation(dataPointCount: Int, reduceMotion: Bool) -> Bool {
        guard !reduceMotion else { return false }
        
        // Disable animations for large datasets to maintain performance
        return dataPointCount <= config.maxDataPointsForInteraction
    }
    
    // MARK: - Metrics Access
    
    func getMetrics() -> InteractiveChartMetrics {
        return performanceMetrics
    }
    
    func resetMetrics() {
        performanceMetrics = InteractiveChartMetrics()
        print("[ChartPerformanceOptimizer] Metrics reset")
    }
}

// MARK: - Interactive Chart Metrics

struct InteractiveChartMetrics {
    private(set) var totalInteractions: Int = 0
    private(set) var throttledInteractions: Int = 0
    private(set) var averageInteractionTime: TimeInterval = 0
    private(set) var dataOptimizations: Int = 0
    private(set) var memoryWarnings: Int = 0
    private(set) var peakMemoryUsage: Int = 0
    
    private var totalInteractionTime: TimeInterval = 0
    
    var throttleRate: Double {
        let total = totalInteractions + throttledInteractions
        return total > 0 ? Double(throttledInteractions) / Double(total) : 0
    }
    
    var averageFrameTime: TimeInterval {
        return averageInteractionTime * 1000 // Convert to milliseconds
    }
    
    mutating func recordInteraction(duration: TimeInterval) {
        totalInteractions += 1
        totalInteractionTime += duration
        averageInteractionTime = totalInteractionTime / Double(totalInteractions)
    }
    
    mutating func recordThrottledInteraction() {
        throttledInteractions += 1
    }
    
    mutating func recordDataOptimization(originalCount: Int, optimizedCount: Int) {
        dataOptimizations += 1
        print("[InteractiveChartMetrics] Data optimized: \(originalCount) -> \(optimizedCount) points")
    }
    
    mutating func recordMemoryUsage(_ usage: Int) {
        peakMemoryUsage = max(peakMemoryUsage, usage)
    }
    
    mutating func recordMemoryWarning() {
        memoryWarnings += 1
    }
    
    func debugDescription() -> String {
        return """
        [InteractiveChartMetrics]
        Total Interactions: \(totalInteractions)
        Throttled: \(throttledInteractions) (\(String(format: "%.1f%%", throttleRate * 100)))
        Avg Interaction Time: \(String(format: "%.2fms", averageFrameTime))
        Data Optimizations: \(dataOptimizations)
        Memory Warnings: \(memoryWarnings)
        Peak Memory: \(peakMemoryUsage) bytes
        """
    }
}

// MARK: - Performance-Optimized Chart View Modifier

struct PerformanceOptimizedChartModifier: ViewModifier {
    @ObservedObject var optimizer: ChartPerformanceOptimizer
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    let chartData: ChartData
    
    func body(content: Content) -> some View {
        let optimizedData = optimizer.optimizeChartData(chartData)
        let shouldAnimate = optimizer.shouldEnableAnimation(
            dataPointCount: optimizedData.points.count,
            reduceMotion: reduceMotion
        )
        
        content
            .animation(
                shouldAnimate ? optimizer.optimizedAnimation(for: reduceMotion) : .none,
                value: optimizedData.points
            )
            .onAppear {
                optimizer.monitorMemoryUsage()
            }
            .onReceive(Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()) { _ in
                optimizer.monitorMemoryUsage()
            }
    }
}

// MARK: - View Extensions

extension View {
    func performanceOptimized(with optimizer: ChartPerformanceOptimizer, chartData: ChartData) -> some View {
        self.modifier(PerformanceOptimizedChartModifier(optimizer: optimizer, chartData: chartData))
    }
}