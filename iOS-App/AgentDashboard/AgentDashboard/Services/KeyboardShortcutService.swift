//
//  KeyboardShortcutService.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Keyboard shortcut service for iPad productivity and accessibility
//

import SwiftUI
import Dependencies

// MARK: - Keyboard Shortcut Service Protocol

protocol KeyboardShortcutServiceProtocol {
    /// Register keyboard shortcut with action
    func registerShortcut(_ shortcut: KeyboardShortcut, action: @escaping () -> Void)
    
    /// Get all available shortcuts for help display
    func getAvailableShortcuts() -> [KeyboardShortcut]
    
    /// Check if shortcuts are enabled
    func areShortcutsEnabled() -> Bool
    
    /// Toggle shortcut availability
    func setShortcutsEnabled(_ enabled: Bool)
    
    /// Get shortcuts for specific context
    func getShortcuts(for context: ShortcutContext) -> [KeyboardShortcut]
}

// MARK: - Keyboard Shortcut Models

struct KeyboardShortcut: Identifiable, Hashable {
    let id = UUID()
    let key: KeyEquivalent
    let modifiers: EventModifiers
    let title: String
    let description: String
    let context: ShortcutContext
    let category: ShortcutCategory
    
    init(
        key: KeyEquivalent,
        modifiers: EventModifiers = [],
        title: String,
        description: String,
        context: ShortcutContext = .global,
        category: ShortcutCategory = .navigation
    ) {
        self.key = key
        self.modifiers = modifiers
        self.title = title
        self.description = description
        self.context = context
        self.category = category
    }
    
    var displayString: String {
        var components: [String] = []
        
        if modifiers.contains(.command) {
            components.append("⌘")
        }
        if modifiers.contains(.shift) {
            components.append("⇧")
        }
        if modifiers.contains(.option) {
            components.append("⌥")
        }
        if modifiers.contains(.control) {
            components.append("⌃")
        }
        
        components.append(key.character?.uppercased() ?? "?")
        
        return components.joined()
    }
}

enum ShortcutContext: String, CaseIterable {
    case global = "Global"
    case dashboard = "Dashboard"
    case agents = "Agents"
    case analytics = "Analytics"
    case terminal = "Terminal"
    case settings = "Settings"
    
    var displayName: String {
        return rawValue
    }
}

enum ShortcutCategory: String, CaseIterable {
    case navigation = "Navigation"
    case actions = "Actions"
    case editing = "Editing"
    case view = "View"
    case help = "Help"
    
    var displayName: String {
        return rawValue
    }
    
    var icon: String {
        switch self {
        case .navigation:
            return "arrow.triangle.turn.up.right.diamond"
        case .actions:
            return "bolt"
        case .editing:
            return "pencil"
        case .view:
            return "eye"
        case .help:
            return "questionmark.circle"
        }
    }
}

// MARK: - Default Keyboard Shortcuts

extension KeyboardShortcut {
    // Global Navigation Shortcuts
    static let showDashboard = KeyboardShortcut(
        key: "1",
        modifiers: .command,
        title: "Dashboard",
        description: "Show dashboard overview",
        context: .global,
        category: .navigation
    )
    
    static let showAgents = KeyboardShortcut(
        key: "2", 
        modifiers: .command,
        title: "Agents",
        description: "Show agents management",
        context: .global,
        category: .navigation
    )
    
    static let showAnalytics = KeyboardShortcut(
        key: "3",
        modifiers: .command,
        title: "Analytics",
        description: "Show analytics dashboard",
        context: .global,
        category: .navigation
    )
    
    static let showTerminal = KeyboardShortcut(
        key: "4",
        modifiers: .command,
        title: "Terminal",
        description: "Show terminal interface",
        context: .global,
        category: .navigation
    )
    
    static let showSettings = KeyboardShortcut(
        key: ",",
        modifiers: .command,
        title: "Settings",
        description: "Show app settings",
        context: .global,
        category: .navigation
    )
    
    // Action Shortcuts
    static let refresh = KeyboardShortcut(
        key: "r",
        modifiers: .command,
        title: "Refresh",
        description: "Refresh current data",
        context: .global,
        category: .actions
    )
    
    static let search = KeyboardShortcut(
        key: "f",
        modifiers: .command,
        title: "Search",
        description: "Open search interface",
        context: .global,
        category: .actions
    )
    
    static let newPrompt = KeyboardShortcut(
        key: "n",
        modifiers: .command,
        title: "New Prompt",
        description: "Create new prompt",
        context: .global,
        category: .actions
    )
    
    // Agent-specific shortcuts
    static let startAgent = KeyboardShortcut(
        key: "s",
        modifiers: [.command, .shift],
        title: "Start Agent",
        description: "Start selected agent",
        context: .agents,
        category: .actions
    )
    
    static let stopAgent = KeyboardShortcut(
        key: "s",
        modifiers: [.command, .option],
        title: "Stop Agent",
        description: "Stop selected agent",
        context: .agents,
        category: .actions
    )
    
    static let restartAgent = KeyboardShortcut(
        key: "r",
        modifiers: [.command, .shift],
        title: "Restart Agent",
        description: "Restart selected agent",
        context: .agents,
        category: .actions
    )
    
    // View shortcuts
    static let toggleSidebar = KeyboardShortcut(
        key: "s",
        modifiers: [.command, .control],
        title: "Toggle Sidebar",
        description: "Show or hide sidebar",
        context: .global,
        category: .view
    )
    
    static let fullScreen = KeyboardShortcut(
        key: "f",
        modifiers: [.command, .control],
        title: "Toggle Fullscreen",
        description: "Enter or exit fullscreen",
        context: .global,
        category: .view
    )
    
    // Help shortcuts
    static let showHelp = KeyboardShortcut(
        key: "?",
        modifiers: .command,
        title: "Show Help",
        description: "Show keyboard shortcuts help",
        context: .global,
        category: .help
    )
}

// MARK: - Keyboard Shortcut Service Implementation

final class KeyboardShortcutService: KeyboardShortcutServiceProtocol {
    private let logger = Logger(subsystem: "AgentDashboard", category: "KeyboardShortcuts")
    private var registeredShortcuts: [KeyboardShortcut] = []
    private var shortcutActions: [UUID: () -> Void] = [:]
    private var isEnabled: Bool = true
    
    init() {
        logger.info("KeyboardShortcutService initialized")
        setupDefaultShortcuts()
    }
    
    private func setupDefaultShortcuts() {
        let defaultShortcuts: [KeyboardShortcut] = [
            .showDashboard, .showAgents, .showAnalytics, .showTerminal, .showSettings,
            .refresh, .search, .newPrompt,
            .startAgent, .stopAgent, .restartAgent,
            .toggleSidebar, .fullScreen, .showHelp
        ]
        
        for shortcut in defaultShortcuts {
            registeredShortcuts.append(shortcut)
        }
        
        logger.info("Registered \(defaultShortcuts.count) default keyboard shortcuts")
    }
    
    func registerShortcut(_ shortcut: KeyboardShortcut, action: @escaping () -> Void) {
        logger.debug("Registering keyboard shortcut: \(shortcut.displayString) - \(shortcut.title)")
        
        registeredShortcuts.append(shortcut)
        shortcutActions[shortcut.id] = action
    }
    
    func getAvailableShortcuts() -> [KeyboardShortcut] {
        return registeredShortcuts.sorted { shortcut1, shortcut2 in
            if shortcut1.category != shortcut2.category {
                return shortcut1.category.rawValue < shortcut2.category.rawValue
            }
            return shortcut1.title < shortcut2.title
        }
    }
    
    func areShortcutsEnabled() -> Bool {
        return isEnabled
    }
    
    func setShortcutsEnabled(_ enabled: Bool) {
        logger.info("Setting keyboard shortcuts enabled: \(enabled)")
        isEnabled = enabled
    }
    
    func getShortcuts(for context: ShortcutContext) -> [KeyboardShortcut] {
        let contextShortcuts = registeredShortcuts.filter { 
            $0.context == context || $0.context == .global 
        }
        
        logger.debug("Found \(contextShortcuts.count) shortcuts for context: \(context.rawValue)")
        return contextShortcuts
    }
}

// MARK: - Keyboard Shortcuts Help View

struct KeyboardShortcutsHelpView: View {
    @Dependency(\.keyboardService) var keyboardService
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                let shortcuts = keyboardService.getAvailableShortcuts()
                let groupedShortcuts = Dictionary(grouping: shortcuts) { $0.category }
                
                ForEach(ShortcutCategory.allCases, id: \.self) { category in
                    if let categoryShortcuts = groupedShortcuts[category], !categoryShortcuts.isEmpty {
                        Section(category.displayName) {
                            ForEach(categoryShortcuts) { shortcut in
                                KeyboardShortcutRow(shortcut: shortcut)
                            }
                        }
                    }
                }
                
                Section("About Keyboard Shortcuts") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Keyboard shortcuts make it faster to navigate and control the app using an external keyboard.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Shortcuts work best on iPad with a connected keyboard or trackpad.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Keyboard Shortcuts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct KeyboardShortcutRow: View {
    let shortcut: KeyboardShortcut
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(shortcut.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(shortcut.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(shortcut.displayString)
                .font(.footnote)
                .fontWeight(.semibold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray5))
                .cornerRadius(6)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - SwiftUI Keyboard Shortcut Extensions

extension View {
    /// Add keyboard shortcut with haptic feedback
    func keyboardShortcut(
        _ shortcut: KeyboardShortcut,
        action: @escaping () -> Void
    ) -> some View {
        self.keyboardShortcut(shortcut.key, modifiers: shortcut.modifiers) {
            @Dependency(\.hapticService) var hapticService
            hapticService.triggerHaptic(.selection)
            action()
        }
    }
    
    /// Add multiple keyboard shortcuts
    func keyboardShortcuts(
        _ shortcuts: [KeyboardShortcut],
        actions: [() -> Void]
    ) -> some View {
        var view = self
        
        for (shortcut, action) in zip(shortcuts, actions) {
            view = AnyView(view.keyboardShortcut(shortcut, action: action))
        }
        
        return view
    }
}

// MARK: - Keyboard Shortcut Discovery View

struct KeyboardShortcutDiscovery: View {
    @State private var showingHelp = false
    @State private var recentlyUsedShortcuts: [KeyboardShortcut] = []
    
    @Dependency(\.keyboardService) var keyboardService
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "keyboard")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text("Keyboard Shortcuts Available")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Press ⌘? to see all shortcuts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("View All") {
                    showingHelp = true
                }
                .buttonStyle(.bordered)
            }
            
            if !recentlyUsedShortcuts.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recently Used")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        ForEach(recentlyUsedShortcuts.prefix(3)) { shortcut in
                            HStack(spacing: 4) {
                                Text(shortcut.displayString)
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(4)
                                
                                Text(shortcut.title)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .sheet(isPresented: $showingHelp) {
            KeyboardShortcutsHelpView()
        }
        .keyboardShortcut(.showHelp) {
            showingHelp = true
        }
    }
}

// MARK: - Mock Keyboard Shortcut Service

final class MockKeyboardShortcutService: KeyboardShortcutServiceProtocol {
    private let logger = Logger(subsystem: "AgentDashboard", category: "MockKeyboardShortcuts")
    private var shortcuts: [KeyboardShortcut] = []
    private var isEnabled: Bool = true
    
    init() {
        logger.info("MockKeyboardShortcutService initialized")
        setupMockShortcuts()
    }
    
    private func setupMockShortcuts() {
        shortcuts = [
            .showDashboard, .showAgents, .showAnalytics,
            .refresh, .search, .showHelp
        ]
    }
    
    func registerShortcut(_ shortcut: KeyboardShortcut, action: @escaping () -> Void) {
        logger.debug("Mock registering shortcut: \(shortcut.title)")
        shortcuts.append(shortcut)
    }
    
    func getAvailableShortcuts() -> [KeyboardShortcut] {
        logger.debug("Mock returning \(shortcuts.count) available shortcuts")
        return shortcuts
    }
    
    func areShortcutsEnabled() -> Bool {
        return isEnabled
    }
    
    func setShortcutsEnabled(_ enabled: Bool) {
        logger.info("Mock setting shortcuts enabled: \(enabled)")
        isEnabled = enabled
    }
    
    func getShortcuts(for context: ShortcutContext) -> [KeyboardShortcut] {
        let contextShortcuts = shortcuts.filter { $0.context == context || $0.context == .global }
        logger.debug("Mock returning \(contextShortcuts.count) shortcuts for context: \(context.rawValue)")
        return contextShortcuts
    }
}

// MARK: - Dependency Registration

private enum KeyboardServiceKey: DependencyKey {
    static let liveValue: KeyboardShortcutServiceProtocol = KeyboardShortcutService()
    static let testValue: KeyboardShortcutServiceProtocol = MockKeyboardShortcutService()
    static let previewValue: KeyboardShortcutServiceProtocol = MockKeyboardShortcutService()
}

extension DependencyValues {
    var keyboardService: KeyboardShortcutServiceProtocol {
        get { self[KeyboardServiceKey.self] }
        set { self[KeyboardServiceKey.self] = newValue }
    }
}