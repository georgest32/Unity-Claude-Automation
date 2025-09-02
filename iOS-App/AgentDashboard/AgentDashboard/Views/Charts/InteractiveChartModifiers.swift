//
//  InteractiveChartModifiers.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Enhanced interactive modifiers for charts with advanced gestures, haptic feedback, and data export
//

import SwiftUI
import Charts

// MARK: - Enhanced Interactive Chart Modifier

struct EnhancedInteractiveChartModifier: ViewModifier {
    
    // Selection state
    @Binding var selectedRange: ClosedRange<Date>?
    @Binding var selectedValue: Double?
    
    // Configuration
    let enableHapticFeedback: Bool
    let enableDataExport: Bool
    let enableRangeSelection: Bool
    
    // Internal state
    @State private var dragStartLocation: CGPoint?
    @State private var dragCurrentLocation: CGPoint?
    @State private var showShareSheet: Bool = false
    @State private var exportData: ChartExportData?
    
    init(selectedRange: Binding<ClosedRange<Date>?> = .constant(nil),
         selectedValue: Binding<Double?> = .constant(nil),
         enableHapticFeedback: Bool = true,
         enableDataExport: Bool = true,
         enableRangeSelection: Bool = true) {
        
        self._selectedRange = selectedRange
        self._selectedValue = selectedValue
        self.enableHapticFeedback = enableHapticFeedback
        self.enableDataExport = enableDataExport
        self.enableRangeSelection = enableRangeSelection
        
        print("[EnhancedInteractiveChartModifier] Initialized with haptic: \(enableHapticFeedback), export: \(enableDataExport), range: \(enableRangeSelection)")
    }
    
    func body(content: Content) -> some View {
        content
            .sensoryFeedback(.selection, trigger: selectedValue) { oldValue, newValue in
                enableHapticFeedback && newValue != nil
            }
            .sensoryFeedback(.impact(flexibility: .soft), trigger: selectedRange) { oldRange, newRange in
                enableHapticFeedback && newRange != nil
            }
            .onLongPressGesture(minimumDuration: 0.5) {
                if enableDataExport {
                    handleLongPress()
                }
            }
            .simultaneousGesture(
                dragGesture
            )
            .sheet(isPresented: $showShareSheet) {
                if let exportData = exportData {
                    ShareSheet(items: [exportData.csvData, exportData.imageData].compactMap { $0 })
                }
            }
    }
    
    // MARK: - Gestures
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                if enableRangeSelection {
                    handleDragChanged(value: value)
                }
            }
            .onEnded { value in
                if enableRangeSelection {
                    handleDragEnded(value: value)
                }
            }
    }
    
    private func handleDragChanged(value: DragGesture.Value) {
        dragCurrentLocation = value.location
        
        // Visual feedback for range selection
        if enableHapticFeedback {
            // Light impact every 50 points of drag
            let distance = sqrt(pow(value.translation.x, 2) + pow(value.translation.y, 2))
            if Int(distance) % 50 == 0 {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
    }
    
    private func handleDragEnded(value: DragGesture.Value) {
        print("[EnhancedInteractiveChartModifier] Drag ended - range selection")
        
        // Calculate selected range based on drag distance
        // This would need ChartProxy integration for proper coordinate mapping
        dragStartLocation = nil
        dragCurrentLocation = nil
        
        if enableHapticFeedback {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
    
    private func handleLongPress() {
        print("[EnhancedInteractiveChartModifier] Long press detected - showing export options")
        
        // Create export data
        exportData = ChartExportData(
            csvData: generateCSVData(),
            imageData: nil // Would capture chart as image
        )
        
        showShareSheet = true
        
        if enableHapticFeedback {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
    }
    
    private func generateCSVData() -> Data {
        // Mock CSV generation - would be enhanced with actual chart data
        let csvString = "timestamp,value,label\n2025-01-01T00:00:00Z,50.0,Sample\n"
        return csvString.data(using: .utf8) ?? Data()
    }
}

// MARK: - Chart Export Data

struct ChartExportData {
    let csvData: Data
    let imageData: Data?
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    let excludedActivityTypes: [UIActivity.ActivityType]?
    
    init(items: [Any], excludedActivityTypes: [UIActivity.ActivityType]? = nil) {
        self.items = items
        self.excludedActivityTypes = excludedActivityTypes
    }
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        activityVC.excludedActivityTypes = excludedActivityTypes
        
        // Configure for iPad
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
            popover.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        return activityVC
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Chart Coordination Manager

final class ChartCoordinationManager: ObservableObject {
    
    // Shared selection state across charts
    @Published var globalSelectedTimeRange: ClosedRange<Date>?
    @Published var globalSelectedValue: Double?
    @Published var globalZoomLevel: Double = 1.0
    @Published var isCoordinationEnabled: Bool = true
    
    // Chart synchronization
    private var chartSubscriptions: Set<UUID> = []
    
    func subscribeChart(_ chartId: UUID) {
        chartSubscriptions.insert(chartId)
        print("[ChartCoordinationManager] Chart subscribed: \(chartId)")
    }
    
    func unsubscribeChart(_ chartId: UUID) {
        chartSubscriptions.remove(chartId)
        print("[ChartCoordinationManager] Chart unsubscribed: \(chartId)")
    }
    
    func updateSelection(timeRange: ClosedRange<Date>?, from chartId: UUID) {
        guard isCoordinationEnabled else { return }
        
        print("[ChartCoordinationManager] Updating global selection from chart: \(chartId)")
        
        globalSelectedTimeRange = timeRange
        
        // Trigger haptic feedback for coordinated selection
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    func updateZoom(level: Double, from chartId: UUID) {
        guard isCoordinationEnabled else { return }
        
        print("[ChartCoordinationManager] Updating global zoom from chart: \(chartId)")
        
        globalZoomLevel = max(0.5, min(3.0, level))
    }
    
    func resetCoordination() {
        print("[ChartCoordinationManager] Resetting coordination state")
        
        globalSelectedTimeRange = nil
        globalSelectedValue = nil
        globalZoomLevel = 1.0
    }
    
    func getCoordinationMetrics() -> ChartCoordinationMetrics {
        return ChartCoordinationMetrics(
            subscribedCharts: chartSubscriptions.count,
            coordinationEnabled: isCoordinationEnabled,
            hasGlobalSelection: globalSelectedTimeRange != nil,
            currentZoomLevel: globalZoomLevel
        )
    }
}

struct ChartCoordinationMetrics {
    let subscribedCharts: Int
    let coordinationEnabled: Bool
    let hasGlobalSelection: Bool
    let currentZoomLevel: Double
}

// MARK: - View Extensions

extension View {
    func enhancedChartInteractivity(
        selectedRange: Binding<ClosedRange<Date>?> = .constant(nil),
        selectedValue: Binding<Double?> = .constant(nil),
        enableHapticFeedback: Bool = true,
        enableDataExport: Bool = true,
        enableRangeSelection: Bool = true
    ) -> some View {
        self.modifier(
            EnhancedInteractiveChartModifier(
                selectedRange: selectedRange,
                selectedValue: selectedValue,
                enableHapticFeedback: enableHapticFeedback,
                enableDataExport: enableDataExport,
                enableRangeSelection: enableRangeSelection
            )
        )
    }
    
    func coordinatedChart(
        with manager: ChartCoordinationManager,
        chartId: UUID = UUID()
    ) -> some View {
        self
            .onAppear {
                manager.subscribeChart(chartId)
            }
            .onDisappear {
                manager.unsubscribeChart(chartId)
            }
            .scaleEffect(manager.globalZoomLevel)
            .animation(.easeInOut(duration: 0.3), value: manager.globalZoomLevel)
    }
}