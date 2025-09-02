//
//  iPadAdaptiveView.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  iPad-optimized adaptive layouts with responsive design
//

import SwiftUI

// MARK: - iPad Adaptive Layout Service

protocol iPadLayoutServiceProtocol {
    /// Get appropriate layout for current size class
    func getLayout(for sizeClass: UserInterfaceSizeClass?) -> iPadLayoutType
    
    /// Calculate optimal column count for grid layouts
    func getOptimalColumnCount(for width: CGFloat) -> Int
    
    /// Get spacing values for current device
    func getSpacing(for device: iPadDeviceType) -> iPadSpacing
    
    /// Check if device supports split view
    func supportsSplitView() -> Bool
}

// MARK: - iPad Layout Models

enum iPadLayoutType {
    case compact           // iPhone-like layout
    case regular           // Standard iPad layout
    case splitView         // iPad split view layout
    case fullScreen        // iPad full screen layout
    
    var columnCount: Int {
        switch self {
        case .compact:
            return 2
        case .regular:
            return 3
        case .splitView:
            return 4
        case .fullScreen:
            return 5
        }
    }
    
    var cardSpacing: CGFloat {
        switch self {
        case .compact:
            return 12
        case .regular:
            return 16
        case .splitView:
            return 20
        case .fullScreen:
            return 24
        }
    }
}

enum iPadDeviceType {
    case iPadMini
    case iPad
    case iPadAir
    case iPadPro11
    case iPadPro12_9
    case unknown
    
    static func current() -> iPadDeviceType {
        let screenSize = UIScreen.main.bounds
        let maxDimension = max(screenSize.width, screenSize.height)
        
        switch maxDimension {
        case 0...1080:
            return .iPadMini
        case 1081...1200:
            return .iPad
        case 1201...1400:
            return .iPadAir
        case 1401...1500:
            return .iPadPro11
        case 1501...:
            return .iPadPro12_9
        default:
            return .unknown
        }
    }
    
    var displayName: String {
        switch self {
        case .iPadMini:
            return "iPad mini"
        case .iPad:
            return "iPad"
        case .iPadAir:
            return "iPad Air"
        case .iPadPro11:
            return "iPad Pro 11\""
        case .iPadPro12_9:
            return "iPad Pro 12.9\""
        case .unknown:
            return "Unknown iPad"
        }
    }
}

struct iPadSpacing {
    let edge: CGFloat
    let section: CGFloat
    let item: CGFloat
    let grid: CGFloat
    
    static let compact = iPadSpacing(edge: 16, section: 20, item: 12, grid: 16)
    static let regular = iPadSpacing(edge: 20, section: 24, item: 16, grid: 20)
    static let large = iPadSpacing(edge: 24, section: 28, item: 20, grid: 24)
}

// MARK: - Adaptive Grid Layout

struct AdaptiveGridLayout<Content: View>: View {
    let items: [AnyHashable]
    let content: (AnyHashable) -> Content
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    @State private var deviceType: iPadDeviceType = .unknown
    @State private var layoutType: iPadLayoutType = .regular
    
    init<T: Hashable>(items: [T], @ViewBuilder content: @escaping (T) -> Content) {
        self.items = items.map(AnyHashable.init)
        self.content = { anyItem in
            if let typedItem = anyItem.base as? T {
                return content(typedItem)
            } else {
                return content(items[0]) // Fallback
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let columns = getAdaptiveColumns(for: geometry.size.width)
            
            LazyVGrid(columns: columns, spacing: layoutType.cardSpacing) {
                ForEach(items.indices, id: \.self) { index in
                    content(items[index])
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1.2, contentMode: .fit)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 2)
                        .scaleEffect(1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: layoutType)
                }
            }
            .padding(.horizontal, getEdgePadding())
        }
        .onAppear {
            updateLayout()
        }
        .onChange(of: horizontalSizeClass) { _ in
            updateLayout()
        }
        .onChange(of: verticalSizeClass) { _ in
            updateLayout()
        }
    }
    
    private func updateLayout() {
        deviceType = iPadDeviceType.current()
        
        switch (horizontalSizeClass, verticalSizeClass) {
        case (.compact, _):
            layoutType = .compact
        case (.regular, .regular):
            layoutType = .fullScreen
        case (.regular, .compact):
            layoutType = .splitView
        default:
            layoutType = .regular
        }
    }
    
    private func getAdaptiveColumns(for width: CGFloat) -> [GridItem] {
        let columnCount = layoutType.columnCount
        let spacing = layoutType.cardSpacing
        
        let columns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnCount)
        return columns
    }
    
    private func getEdgePadding() -> CGFloat {
        switch deviceType {
        case .iPadMini:
            return 16
        case .iPad, .iPadAir:
            return 20
        case .iPadPro11:
            return 24
        case .iPadPro12_9:
            return 32
        case .unknown:
            return 20
        }
    }
}

// MARK: - iPad Split View Container

struct iPadSplitViewContainer<Sidebar: View, Detail: View>: View {
    let sidebar: Sidebar
    let detail: Detail
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var sidebarVisibility: NavigationSplitViewVisibility = .automatic
    
    init(@ViewBuilder sidebar: () -> Sidebar, @ViewBuilder detail: () -> Detail) {
        self.sidebar = sidebar()
        self.detail = detail()
    }
    
    var body: some View {
        if horizontalSizeClass == .regular {
            // iPad: Use NavigationSplitView
            NavigationSplitView(columnVisibility: $sidebarVisibility) {
                sidebar
                    .navigationSplitViewColumnWidth(min: 300, ideal: 350, max: 400)
            } detail: {
                detail
            }
            .navigationSplitViewStyle(.balanced)
        } else {
            // iPhone: Use NavigationStack
            NavigationStack {
                sidebar
            }
        }
    }
}

// MARK: - Responsive Dashboard Grid

struct ResponsiveDashboardGrid: View {
    let widgets: [DashboardWidget]
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var body: some View {
        GeometryReader { geometry in
            let layout = getLayoutForSize(geometry.size)
            
            LazyVGrid(columns: layout.columns, spacing: layout.spacing) {
                ForEach(widgets) { widget in
                    DashboardWidgetView(widget: widget)
                        .frame(height: layout.widgetHeight)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(radius: 4)
                }
            }
            .padding(layout.edgePadding)
        }
    }
    
    private func getLayoutForSize(_ size: CGSize) -> DashboardLayout {
        let isLandscape = size.width > size.height
        let isLarge = size.width > 1000
        
        switch (horizontalSizeClass, isLandscape, isLarge) {
        case (.regular, true, true):
            // Large iPad landscape
            return DashboardLayout(
                columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 4),
                spacing: 20,
                edgePadding: 32,
                widgetHeight: 200
            )
            
        case (.regular, true, false):
            // Standard iPad landscape
            return DashboardLayout(
                columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3),
                spacing: 16,
                edgePadding: 24,
                widgetHeight: 180
            )
            
        case (.regular, false, _):
            // iPad portrait
            return DashboardLayout(
                columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2),
                spacing: 16,
                edgePadding: 20,
                widgetHeight: 220
            )
            
        default:
            // iPhone
            return DashboardLayout(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2),
                spacing: 12,
                edgePadding: 16,
                widgetHeight: 160
            )
        }
    }
}

struct DashboardLayout {
    let columns: [GridItem]
    let spacing: CGFloat
    let edgePadding: CGFloat
    let widgetHeight: CGFloat
}

struct DashboardWidget: Identifiable {
    let id = UUID()
    let title: String
    let type: WidgetType
    let data: WidgetData
    
    enum WidgetType {
        case agentStatus
        case systemMetrics
        case recentActivity
        case quickActions
        case performance
        case alerts
    }
    
    struct WidgetData {
        let primary: String
        let secondary: String?
        let value: Double?
        let status: String?
    }
}

struct DashboardWidgetView: View {
    let widget: DashboardWidget
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: widget.type.iconName)
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text(widget.title)
                    .font(horizontalSizeClass == .regular ? .headline : .subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(widget.data.primary)
                    .font(horizontalSizeClass == .regular ? .title : .title2)
                    .fontWeight(.bold)
                
                if let secondary = widget.data.secondary {
                    Text(secondary)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let value = widget.data.value {
                    ProgressView(value: value)
                        .progressViewStyle(LinearProgressViewStyle())
                        .scaleEffect(y: 0.5)
                }
            }
            
            Spacer()
        }
        .padding(horizontalSizeClass == .regular ? 20 : 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension DashboardWidget.WidgetType {
    var iconName: String {
        switch self {
        case .agentStatus:
            return "cpu"
        case .systemMetrics:
            return "chart.bar.xaxis"
        case .recentActivity:
            return "clock.arrow.circlepath"
        case .quickActions:
            return "bolt.circle"
        case .performance:
            return "speedometer"
        case .alerts:
            return "bell.badge"
        }
    }
}

// MARK: - Size Class Responsive View

struct SizeClassResponsiveView<CompactContent: View, RegularContent: View>: View {
    let compactContent: CompactContent
    let regularContent: RegularContent
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    init(
        @ViewBuilder compact: () -> CompactContent,
        @ViewBuilder regular: () -> RegularContent
    ) {
        self.compactContent = compact()
        self.regularContent = regular()
    }
    
    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                compactContent
            } else {
                regularContent
            }
        }
        .animation(.easeInOut(duration: 0.3), value: horizontalSizeClass)
    }
}

// MARK: - ViewThatFits Adaptive Component

struct AdaptiveContentView<Content: View>: View {
    let content: Content
    let maxWidth: CGFloat?
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    init(maxWidth: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.maxWidth = maxWidth
        self.content = content()
    }
    
    var body: some View {
        ViewThatFits(in: .horizontal) {
            // Try full layout first
            content
                .frame(maxWidth: maxWidth)
            
            // Fallback to compact layout
            content
                .font(.caption)
                .padding(.horizontal, 8)
        }
        .animation(.easeInOut(duration: 0.2), value: horizontalSizeClass)
    }
}