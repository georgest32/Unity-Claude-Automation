//
//  iPadSplitView.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  iPad split view implementation for multitasking and desktop-class experience
//

import SwiftUI

// MARK: - iPad Split View Main Container

struct iPadSplitView: View {
    @State private var selectedSidebarItem: SidebarItem? = .dashboard
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        if horizontalSizeClass == .regular {
            NavigationSplitView(columnVisibility: $columnVisibility) {
                iPadSidebarView(selectedItem: $selectedSidebarItem)
                    .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 400)
            } detail: {
                iPadDetailView(selectedItem: selectedSidebarItem)
            }
            .navigationSplitViewStyle(.balanced)
            .onAppear {
                // Default to showing both columns on iPad
                columnVisibility = .all
            }
        } else {
            // iPhone fallback - use TabView
            TabView {
                DashboardView()
                    .tabItem {
                        Label("Dashboard", systemImage: "square.grid.2x2")
                    }
                
                AgentsView()
                    .tabItem {
                        Label("Agents", systemImage: "cpu")
                    }
                
                AnalyticsView()
                    .tabItem {
                        Label("Analytics", systemImage: "chart.bar")
                    }
                
                TerminalView()
                    .tabItem {
                        Label("Terminal", systemImage: "terminal")
                    }
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }
        }
    }
}

// MARK: - Sidebar Navigation

enum SidebarItem: String, CaseIterable {
    case dashboard = "Dashboard"
    case agents = "Agents"
    case analytics = "Analytics"
    case terminal = "Terminal"
    case responses = "Responses"
    case settings = "Settings"
    
    var iconName: String {
        switch self {
        case .dashboard:
            return "square.grid.2x2"
        case .agents:
            return "cpu"
        case .analytics:
            return "chart.bar"
        case .terminal:
            return "terminal"
        case .responses:
            return "bubble.left.and.bubble.right"
        case .settings:
            return "gear"
        }
    }
    
    var description: String {
        switch self {
        case .dashboard:
            return "Overview of system status and key metrics"
        case .agents:
            return "Monitor and control automation agents"
        case .analytics:
            return "Performance metrics and data analysis"
        case .terminal:
            return "Direct command-line interface"
        case .responses:
            return "Claude AI responses and history"
        case .settings:
            return "App preferences and configuration"
        }
    }
}

struct iPadSidebarView: View {
    @Binding var selectedItem: SidebarItem?
    
    @State private var isExpanded: Bool = true
    @State private var searchText: String = ""
    
    @Dependency(\.hapticService) var hapticService
    
    var body: some View {
        List(selection: $selectedItem) {
            // Header section
            Section {
                HStack {
                    Image(systemName: "app.badge.checkmark")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    if isExpanded {
                        VStack(alignment: .leading) {
                            Text("Agent Dashboard")
                                .font(.headline)
                                .fontWeight(.bold)
                            
                            Text("Unity-Claude Automation")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button {
                        hapticService.triggerHaptic(.selection)
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: isExpanded ? "sidebar.left" : "sidebar.right")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.vertical, 8)
            }
            .listSectionSeparator(.hidden)
            
            // Search section (when expanded)
            if isExpanded {
                Section {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                .listSectionSeparator(.hidden)
            }
            
            // Navigation items
            Section(isExpanded ? "Navigation" : "") {
                ForEach(SidebarItem.allCases, id: \.self) { item in
                    SidebarItemView(
                        item: item,
                        isSelected: selectedItem == item,
                        isExpanded: isExpanded
                    )
                    .onTapGesture {
                        hapticService.triggerHaptic(.selection)
                        selectedItem = item
                    }
                }
            }
            
            Spacer()
        }
        .listStyle(SidebarListStyle())
        .navigationTitle(isExpanded ? "Dashboard" : "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    hapticService.triggerHaptic(.selection)
                    // Toggle column visibility
                    columnVisibility = columnVisibility == .all ? .detailOnly : .all
                } label: {
                    Image(systemName: "sidebar.trailing")
                }
            }
        }
    }
    
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
}

struct SidebarItemView: View {
    let item: SidebarItem
    let isSelected: Bool
    let isExpanded: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.iconName)
                .font(.title3)
                .foregroundColor(isSelected ? .white : .blue)
                .frame(width: 24, height: 24)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(item.description)
                        .font(.caption2)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            if isSelected && isExpanded {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue : Color.clear)
        )
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - iPad Detail View

struct iPadDetailView: View {
    let selectedItem: SidebarItem?
    
    var body: some View {
        Group {
            switch selectedItem {
            case .dashboard:
                iPadDashboardView()
            case .agents:
                iPadAgentsView()
            case .analytics:
                iPadAnalyticsView()
            case .terminal:
                iPadTerminalView()
            case .responses:
                iPadResponsesView()
            case .settings:
                iPadSettingsView()
            case .none:
                iPadWelcomeView()
            }
        }
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                iPadToolbarButtons(for: selectedItem)
            }
        }
    }
}

struct iPadWelcomeView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "app.badge.checkmark")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            VStack(spacing: 12) {
                Text("Welcome to Agent Dashboard")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Select an item from the sidebar to get started")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            HStack(spacing: 16) {
                Button("View Dashboard") {
                    // Navigate to dashboard
                }
                .buttonStyle(.borderedProminent)
                
                Button("Learn More") {
                    // Show help
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - iPad-Specific Views

struct iPadDashboardView: View {
    let mockWidgets = [
        DashboardWidget(
            title: "Active Agents",
            type: .agentStatus,
            data: .init(primary: "3", secondary: "Running", value: nil, status: "healthy")
        ),
        DashboardWidget(
            title: "CPU Usage",
            type: .systemMetrics,
            data: .init(primary: "45.2%", secondary: "8 cores", value: 0.452, status: nil)
        ),
        DashboardWidget(
            title: "Memory",
            type: .performance,
            data: .init(primary: "67.8%", secondary: "16 GB", value: 0.678, status: nil)
        ),
        DashboardWidget(
            title: "Recent Activity",
            type: .recentActivity,
            data: .init(primary: "12", secondary: "Last hour", value: nil, status: nil)
        )
    ]
    
    var body: some View {
        ScrollView {
            ResponsiveDashboardGrid(widgets: mockWidgets)
        }
        .navigationTitle("Dashboard")
        .background(Color(.systemGroupedBackground))
    }
}

struct iPadAgentsView: View {
    var body: some View {
        Text("iPad Agents View - Enhanced for large screens")
            .font(.title)
            .navigationTitle("Agents")
    }
}

struct iPadAnalyticsView: View {
    var body: some View {
        Text("iPad Analytics View - Multi-chart layout")
            .font(.title)
            .navigationTitle("Analytics")
    }
}

struct iPadTerminalView: View {
    var body: some View {
        Text("iPad Terminal View - Split terminal layout")
            .font(.title)
            .navigationTitle("Terminal")
    }
}

struct iPadResponsesView: View {
    var body: some View {
        Text("iPad Responses View - Side-by-side view")
            .font(.title)
            .navigationTitle("Responses")
    }
}

struct iPadSettingsView: View {
    var body: some View {
        Text("iPad Settings View - Multi-column settings")
            .font(.title)
            .navigationTitle("Settings")
    }
}

// MARK: - iPad Toolbar

struct iPadToolbarButtons: View {
    let selectedItem: SidebarItem?
    
    @Dependency(\.hapticService) var hapticService
    
    var body: some View {
        HStack {
            switch selectedItem {
            case .dashboard:
                Button {
                    hapticService.triggerHaptic(.buttonPress)
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                
                Button {
                    hapticService.triggerHaptic(.buttonPress)
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                
            case .agents:
                Button {
                    hapticService.triggerHaptic(.buttonPress)
                } label: {
                    Image(systemName: "plus")
                }
                
                Button {
                    hapticService.triggerHaptic(.buttonPress)
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                
            case .analytics:
                Button {
                    hapticService.triggerHaptic(.buttonPress)
                } label: {
                    Image(systemName: "square.and.arrow.down")
                }
                
                Button {
                    hapticService.triggerHaptic(.buttonPress)
                } label: {
                    Image(systemName: "chart.bar.doc.horizontal")
                }
                
            default:
                Button {
                    hapticService.triggerHaptic(.buttonPress)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}

// MARK: - iPad-Optimized Components

struct iPadCard<Content: View>: View {
    let content: Content
    let title: String?
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let title = title {
                Text(title)
                    .font(horizontalSizeClass == .regular ? .title2 : .headline)
                    .fontWeight(.bold)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
            }
            
            content
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct iPadSection<Content: View>: View {
    let title: String
    let subtitle: String?
    let content: Content
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    init(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(horizontalSizeClass == .regular ? .title : .headline)
                    .fontWeight(.bold)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            content
        }
        .padding(horizontalSizeClass == .regular ? 24 : 16)
    }
}

// MARK: - Multi-Column Layout for iPad

struct iPadMultiColumnLayout<LeftContent: View, CenterContent: View, RightContent: View>: View {
    let leftContent: LeftContent
    let centerContent: CenterContent
    let rightContent: RightContent?
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    init(
        @ViewBuilder left: () -> LeftContent,
        @ViewBuilder center: () -> CenterContent,
        @ViewBuilder right: (() -> RightContent)? = nil
    ) {
        self.leftContent = left()
        self.centerContent = center()
        self.rightContent = right?()
    }
    
    var body: some View {
        if horizontalSizeClass == .regular {
            HStack(spacing: 20) {
                // Left column
                leftContent
                    .frame(maxWidth: .infinity)
                
                // Center column
                centerContent
                    .frame(maxWidth: .infinity)
                
                // Right column (optional)
                if let rightContent = rightContent {
                    rightContent
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(24)
        } else {
            // iPhone: Stack vertically
            VStack(spacing: 20) {
                leftContent
                centerContent
                
                if let rightContent = rightContent {
                    rightContent
                }
            }
            .padding(16)
        }
    }
}

// MARK: - iPad Responsive Text

struct iPadResponsiveText: View {
    let text: String
    let style: TextStyle
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    enum TextStyle {
        case title
        case headline
        case body
        case caption
        
        func font(for sizeClass: UserInterfaceSizeClass?) -> Font {
            let isRegular = sizeClass == .regular
            
            switch self {
            case .title:
                return isRegular ? .largeTitle : .title
            case .headline:
                return isRegular ? .title : .headline
            case .body:
                return isRegular ? .title3 : .body
            case .caption:
                return isRegular ? .body : .caption
            }
        }
    }
    
    var body: some View {
        Text(text)
            .font(style.font(for: horizontalSizeClass))
            .animation(.easeInOut(duration: 0.2), value: horizontalSizeClass)
    }
}

// MARK: - Context Menu Support for iPad

extension View {
    func iPadContextMenu<MenuItems: View>(
        @ViewBuilder menuItems: () -> MenuItems
    ) -> some View {
        self.contextMenu {
            menuItems()
        }
    }
    
    func iPadHover(isEnabled: Bool = true) -> some View {
        self.hoverEffect(.lift, isEnabled: isEnabled)
    }
}