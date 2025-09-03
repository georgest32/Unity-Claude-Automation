//
//  SettingsView.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Comprehensive settings interface with theme customization and preferences
//

import SwiftUI
import ComposableArchitecture

// MARK: - Settings View

struct SettingsView: View {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var settingsManager = SettingsManager()
    
    @State private var showingBackupRestore = false
    @State private var showingAbout = false
    
    @Dependency(\.hapticService) var hapticService
    @Dependency(\.biometricAuth) var biometricAuth
    @Dependency(\.keyboardService) var keyboardService
    
    var body: some View {
        NavigationView {
            List {
                // User Profile Section
                Section {
                    UserProfileRow()
                }
                
                // Appearance Section
                Section("Appearance") {
                    ThemeSelectionRow(themeManager: themeManager)
                    
                    ColorSchemeRow(themeManager: themeManager)
                    
                    HStack {
                        Label("App Icon", systemImage: "app.badge")
                        Spacer()
                        Button("Change") {
                            hapticService.triggerHaptic(.buttonPress)
                            // App icon change logic
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                    }
                }
                
                // Dashboard Section
                Section("Dashboard") {
                    NavigationLink(destination: WidgetConfigurationView()) {
                        Label("Widget Configuration", systemImage: "square.grid.2x2")
                    }
                    
                    HStack {
                        Label("Auto-refresh", systemImage: "arrow.clockwise")
                        Spacer()
                        Toggle("", isOn: $settingsManager.autoRefreshEnabled)
                            .onChange(of: settingsManager.autoRefreshEnabled) { _ in
                                hapticService.triggerHaptic(.selection)
                            }
                    }
                    
                    if settingsManager.autoRefreshEnabled {
                        HStack {
                            Text("Refresh Interval")
                                .foregroundColor(.secondary)
                            Spacer()
                            Picker("Interval", selection: $settingsManager.refreshInterval) {
                                Text("5 seconds").tag(5)
                                Text("10 seconds").tag(10)
                                Text("30 seconds").tag(30)
                                Text("1 minute").tag(60)
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        .padding(.leading, 32)
                    }
                }
                
                // Security Section
                Section("Security") {
                    HStack {
                        Label("Biometric Authentication", systemImage: "faceid")
                        Spacer()
                        Toggle("", isOn: $settingsManager.biometricAuthEnabled)
                            .onChange(of: settingsManager.biometricAuthEnabled) { enabled in
                                hapticService.triggerHaptic(.selection)
                                if enabled {
                                    requestBiometricPermission()
                                }
                            }
                    }
                    
                    HStack {
                        Label("Auto-lock", systemImage: "lock.rotation")
                        Spacer()
                        Picker("Auto-lock", selection: $settingsManager.autoLockTimeout) {
                            Text("Never").tag(0)
                            Text("1 minute").tag(60)
                            Text("5 minutes").tag(300)
                            Text("15 minutes").tag(900)
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    NavigationLink(destination: AuditLogView()) {
                        Label("Audit Logs", systemImage: "doc.text.magnifyingglass")
                    }
                }
                
                // Notifications Section
                Section("Notifications") {
                    HStack {
                        Label("Push Notifications", systemImage: "bell")
                        Spacer()
                        Toggle("", isOn: $settingsManager.notificationsEnabled)
                            .onChange(of: settingsManager.notificationsEnabled) { _ in
                                hapticService.triggerHaptic(.selection)
                            }
                    }
                    
                    HStack {
                        Label("Haptic Feedback", systemImage: "iphone.radiowaves.left.and.right")
                        Spacer()
                        Toggle("", isOn: $settingsManager.hapticsEnabled)
                            .onChange(of: settingsManager.hapticsEnabled) { enabled in
                                hapticService.triggerHaptic(.selection)
                                hapticService.configureHaptics(enabled: enabled, intensity: settingsManager.hapticIntensity)
                            }
                    }
                    
                    if settingsManager.hapticsEnabled {
                        HStack {
                            Text("Haptic Intensity")
                                .foregroundColor(.secondary)
                            Spacer()
                            Slider(value: $settingsManager.hapticIntensity, in: 0.1...1.0, step: 0.1)
                                .frame(width: 120)
                                .onChange(of: settingsManager.hapticIntensity) { intensity in
                                    hapticService.configureHaptics(enabled: true, intensity: intensity)
                                    hapticService.triggerHaptic(.selection)
                                }
                        }
                        .padding(.leading, 32)
                    }
                }
                
                // Productivity Section
                Section("Productivity") {
                    HStack {
                        Label("Keyboard Shortcuts", systemImage: "keyboard")
                        Spacer()
                        Toggle("", isOn: $settingsManager.keyboardShortcutsEnabled)
                            .onChange(of: settingsManager.keyboardShortcutsEnabled) { enabled in
                                hapticService.triggerHaptic(.selection)
                                keyboardService.setShortcutsEnabled(enabled)
                            }
                    }
                    
                    NavigationLink(destination: KeyboardShortcutsHelpView()) {
                        Label("View Shortcuts", systemImage: "command")
                    }
                    
                    HStack {
                        Label("Show Performance Metrics", systemImage: "speedometer")
                        Spacer()
                        Toggle("", isOn: $settingsManager.showPerformanceMetrics)
                            .onChange(of: settingsManager.showPerformanceMetrics) { _ in
                                hapticService.triggerHaptic(.selection)
                            }
                    }
                }
                
                // Data & Storage Section
                Section("Data & Storage") {
                    NavigationLink(destination: BackupRestoreView()) {
                        Label("Backup & Restore", systemImage: "icloud.and.arrow.up")
                    }
                    
                    HStack {
                        Label("iCloud Sync", systemImage: "icloud")
                        Spacer()
                        Toggle("", isOn: $settingsManager.iCloudSyncEnabled)
                            .onChange(of: settingsManager.iCloudSyncEnabled) { _ in
                                hapticService.triggerHaptic(.selection)
                            }
                    }
                    
                    Button("Clear Cache") {
                        hapticService.triggerHaptic(.warning)
                        clearCache()
                    }
                    .foregroundColor(.red)
                }
                
                // About Section
                Section("About") {
                    NavigationLink(destination: AboutView()) {
                        Label("About Agent Dashboard", systemImage: "info.circle")
                    }
                    
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0 (Beta)")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Send Feedback") {
                        hapticService.triggerHaptic(.buttonPress)
                        sendFeedback()
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingBackupRestore) {
            BackupRestoreView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }
    
    private func requestBiometricPermission() {
        Task {
            let result = await biometricAuth.authenticateUser(reason: "Enable biometric authentication for secure access")
            if result.success {
                hapticService.triggerHaptic(.success)
            } else {
                hapticService.triggerHaptic(.error)
                settingsManager.biometricAuthEnabled = false
            }
        }
    }
    
    private func clearCache() {
        // Clear cache logic
        Task {
            @Dependency(\.cacheService) var cacheService
            await cacheService.clearCache()
            hapticService.triggerHaptic(.success)
        }
    }
    
    private func sendFeedback() {
        // Send feedback logic
        if let url = URL(string: "mailto:feedback@unity-claude.local") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Settings Components

struct UserProfileRow: View {
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.blue.gradient)
                .frame(width: 60, height: 60)
                .overlay(
                    Text("AD")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Admin User")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("admin@unity-claude.local")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Connected to PowerShell API")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            Button("Edit") {
                // Edit profile action
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
        }
        .padding(.vertical, 8)
    }
}

struct ThemeSelectionRow: View {
    @ObservedObject var themeManager: ThemeManager
    
    @Dependency(\.hapticService) var hapticService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Theme", systemImage: "paintbrush")
                Spacer()
                Text(themeManager.currentTheme.displayName)
                    .foregroundColor(.secondary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        ThemePreviewCard(
                            theme: theme,
                            isSelected: themeManager.currentTheme == theme
                        ) {
                            hapticService.triggerHaptic(.selection)
                            themeManager.setTheme(theme)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}

struct ThemePreviewCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // Color preview
            HStack(spacing: 2) {
                ForEach(theme.previewColors, id: \.self) { color in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: 16, height: 16)
                }
            }
            
            Text(theme.displayName)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(8)
        .background(isSelected ? Color.blue.opacity(0.2) : Color(.systemGray6))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            onSelect()
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct ColorSchemeRow: View {
    @ObservedObject var themeManager: ThemeManager
    
    @Dependency(\.hapticService) var hapticService
    
    var body: some View {
        HStack {
            Label("Appearance", systemImage: "moon.stars")
            Spacer()
            
            Picker("Color Scheme", selection: $themeManager.colorScheme) {
                Text("System").tag(ColorScheme?.none)
                Text("Light").tag(ColorScheme?.some(.light))
                Text("Dark").tag(ColorScheme?.some(.dark))
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 200)
            .onChange(of: themeManager.colorScheme) { _ in
                hapticService.triggerHaptic(.selection)
            }
        }
    }
}

// MARK: - Theme Management

enum AppTheme: String, CaseIterable {
    case system = "System"
    case blue = "Blue"
    case purple = "Purple"
    case green = "Green"
    case orange = "Orange"
    case red = "Red"
    case minimal = "Minimal"
    case professional = "Professional"
    
    var displayName: String {
        return rawValue
    }
    
    var primaryColor: Color {
        switch self {
        case .system:
            return .accentColor
        case .blue:
            return .blue
        case .purple:
            return .purple
        case .green:
            return .green
        case .orange:
            return .orange
        case .red:
            return .red
        case .minimal:
            return .gray
        case .professional:
            return Color(.systemIndigo)
        }
    }
    
    var secondaryColor: Color {
        return primaryColor.opacity(0.6)
    }
    
    var previewColors: [Color] {
        return [primaryColor, secondaryColor, Color(.systemBackground)]
    }
}

@MainActor
class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme = .system
    @Published var colorScheme: ColorScheme? = nil
    
    private let logger = Logger(subsystem: "AgentDashboard", category: "ThemeManager")
    
    init() {
        loadThemePreferences()
        logger.info("ThemeManager initialized with theme: \(currentTheme.rawValue)")
    }
    
    func setTheme(_ theme: AppTheme) {
        logger.info("Setting theme: \(theme.rawValue)")
        currentTheme = theme
        saveThemePreferences()
    }
    
    func setColorScheme(_ scheme: ColorScheme?) {
        logger.info("Setting color scheme: \(scheme?.description ?? "system")")
        colorScheme = scheme
        saveThemePreferences()
    }
    
    private func loadThemePreferences() {
        if let themeString = UserDefaults.standard.string(forKey: "selectedTheme"),
           let theme = AppTheme(rawValue: themeString) {
            currentTheme = theme
        }
        
        if let schemeString = UserDefaults.standard.string(forKey: "colorScheme") {
            switch schemeString {
            case "light":
                colorScheme = .light
            case "dark":
                colorScheme = .dark
            default:
                colorScheme = nil
            }
        }
        
        logger.debug("Loaded theme preferences")
    }
    
    private func saveThemePreferences() {
        UserDefaults.standard.set(currentTheme.rawValue, forKey: "selectedTheme")
        
        if let colorScheme = colorScheme {
            UserDefaults.standard.set(colorScheme == .light ? "light" : "dark", forKey: "colorScheme")
        } else {
            UserDefaults.standard.removeObject(forKey: "colorScheme")
        }
        
        logger.debug("Saved theme preferences")
    }
}

// MARK: - Settings Manager

@MainActor
class SettingsManager: ObservableObject {
    @Published var autoRefreshEnabled: Bool = true
    @Published var refreshInterval: Int = 30
    @Published var biometricAuthEnabled: Bool = false
    @Published var autoLockTimeout: Int = 300
    @Published var notificationsEnabled: Bool = true
    @Published var hapticsEnabled: Bool = true
    @Published var hapticIntensity: Float = 1.0
    @Published var keyboardShortcutsEnabled: Bool = true
    @Published var showPerformanceMetrics: Bool = false
    @Published var iCloudSyncEnabled: Bool = false
    
    private let logger = Logger(subsystem: "AgentDashboard", category: "SettingsManager")
    
    init() {
        loadSettings()
        logger.info("SettingsManager initialized")
    }
    
    private func loadSettings() {
        autoRefreshEnabled = UserDefaults.standard.object(forKey: "autoRefreshEnabled") as? Bool ?? true
        refreshInterval = UserDefaults.standard.object(forKey: "refreshInterval") as? Int ?? 30
        biometricAuthEnabled = UserDefaults.standard.object(forKey: "biometricAuthEnabled") as? Bool ?? false
        autoLockTimeout = UserDefaults.standard.object(forKey: "autoLockTimeout") as? Int ?? 300
        notificationsEnabled = UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true
        hapticsEnabled = UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true
        hapticIntensity = UserDefaults.standard.object(forKey: "hapticIntensity") as? Float ?? 1.0
        keyboardShortcutsEnabled = UserDefaults.standard.object(forKey: "keyboardShortcutsEnabled") as? Bool ?? true
        showPerformanceMetrics = UserDefaults.standard.object(forKey: "showPerformanceMetrics") as? Bool ?? false
        iCloudSyncEnabled = UserDefaults.standard.object(forKey: "iCloudSyncEnabled") as? Bool ?? false
        
        logger.debug("Settings loaded from UserDefaults")
    }
    
    func saveSettings() {
        UserDefaults.standard.set(autoRefreshEnabled, forKey: "autoRefreshEnabled")
        UserDefaults.standard.set(refreshInterval, forKey: "refreshInterval")
        UserDefaults.standard.set(biometricAuthEnabled, forKey: "biometricAuthEnabled")
        UserDefaults.standard.set(autoLockTimeout, forKey: "autoLockTimeout")
        UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        UserDefaults.standard.set(hapticsEnabled, forKey: "hapticsEnabled")
        UserDefaults.standard.set(hapticIntensity, forKey: "hapticIntensity")
        UserDefaults.standard.set(keyboardShortcutsEnabled, forKey: "keyboardShortcutsEnabled")
        UserDefaults.standard.set(showPerformanceMetrics, forKey: "showPerformanceMetrics")
        UserDefaults.standard.set(iCloudSyncEnabled, forKey: "iCloudSyncEnabled")
        
        logger.debug("Settings saved to UserDefaults")
    }
}

// MARK: - Widget Configuration View

struct WidgetConfigurationView: View {
    @State private var enabledWidgets: Set<String> = ["agents", "system", "analytics"]
    @State private var widgetOrder: [String] = ["agents", "system", "analytics", "terminal"]
    
    var body: some View {
        List {
            Section("Available Widgets") {
                ForEach(widgetOrder, id: \.self) { widget in
                    HStack {
                        Image(systemName: getWidgetIcon(widget))
                            .foregroundColor(.blue)
                        
                        Text(getWidgetName(widget))
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { enabledWidgets.contains(widget) },
                            set: { enabled in
                                if enabled {
                                    enabledWidgets.insert(widget)
                                } else {
                                    enabledWidgets.remove(widget)
                                }
                            }
                        ))
                    }
                }
                .onMove { from, to in
                    widgetOrder.move(fromOffsets: from, toOffset: to)
                }
            }
            
            Section("Layout Options") {
                HStack {
                    Text("Grid Columns")
                    Spacer()
                    Picker("Columns", selection: .constant(2)) {
                        Text("2").tag(2)
                        Text("3").tag(3)
                        Text("4").tag(4)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 120)
                }
                
                HStack {
                    Text("Widget Size")
                    Spacer()
                    Picker("Size", selection: .constant("Medium")) {
                        Text("Small").tag("Small")
                        Text("Medium").tag("Medium")
                        Text("Large").tag("Large")
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
        }
        .navigationTitle("Widget Configuration")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
    }
    
    private func getWidgetIcon(_ widget: String) -> String {
        switch widget {
        case "agents":
            return "cpu"
        case "system":
            return "chart.bar"
        case "analytics":
            return "chart.line.uptrend.xyaxis"
        case "terminal":
            return "terminal"
        default:
            return "square"
        }
    }
    
    private func getWidgetName(_ widget: String) -> String {
        switch widget {
        case "agents":
            return "Agent Status"
        case "system":
            return "System Metrics"
        case "analytics":
            return "Analytics"
        case "terminal":
            return "Terminal Output"
        default:
            return widget.capitalized
        }
    }
}

// MARK: - Backup & Restore View

struct BackupRestoreView: View {
    @State private var isBackingUp = false
    @State private var isRestoring = false
    @State private var showingFilePicker = false
    
    @Dependency(\.hapticService) var hapticService
    
    var body: some View {
        NavigationView {
            List {
                Section("Backup") {
                    Button("Create Backup") {
                        hapticService.triggerHaptic(.buttonPress)
                        createBackup()
                    }
                    .disabled(isBackingUp)
                    
                    if isBackingUp {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Creating backup...")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Restore") {
                    Button("Restore from File") {
                        hapticService.triggerHaptic(.buttonPress)
                        showingFilePicker = true
                    }
                    .disabled(isRestoring)
                    
                    Button("Restore from iCloud") {
                        hapticService.triggerHaptic(.buttonPress)
                        restoreFromiCloud()
                    }
                    .disabled(isRestoring)
                    
                    if isRestoring {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Restoring data...")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Data Export") {
                    Button("Export Settings") {
                        hapticService.triggerHaptic(.buttonPress)
                        exportSettings()
                    }
                    
                    Button("Export Audit Logs") {
                        hapticService.triggerHaptic(.buttonPress)
                        exportAuditLogs()
                    }
                }
            }
            .navigationTitle("Backup & Restore")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Dismiss view
                    }
                }
            }
        }
        .fileImporter(isPresented: $showingFilePicker, allowedContentTypes: [.json]) { result in
            handleFileImport(result)
        }
    }
    
    private func createBackup() {
        isBackingUp = true
        
        Task {
            // Simulate backup creation
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            await MainActor.run {
                isBackingUp = false
                hapticService.triggerHaptic(.success)
            }
        }
    }
    
    private func restoreFromiCloud() {
        isRestoring = true
        
        Task {
            // Simulate iCloud restore
            try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            
            await MainActor.run {
                isRestoring = false
                hapticService.triggerHaptic(.success)
            }
        }
    }
    
    private func exportSettings() {
        // Export settings logic
    }
    
    private func exportAuditLogs() {
        // Export audit logs logic
    }
    
    private func handleFileImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            // Handle file import
            hapticService.triggerHaptic(.success)
        case .failure(let error):
            hapticService.triggerHaptic(.error)
            print("File import failed: \(error)")
        }
    }
}

// MARK: - About View

struct AboutView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // App icon and info
                    VStack(spacing: 16) {
                        Image(systemName: "app.badge.checkmark")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        VStack(spacing: 8) {
                            Text("Agent Dashboard")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("Unity-Claude Automation")
                                .font(.title3)
                                .foregroundColor(.secondary)
                            
                            Text("Version 1.0.0 (Beta)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Features overview
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Features")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            FeatureRow(icon: "cpu", title: "Agent Management", description: "Monitor and control automation agents")
                            FeatureRow(icon: "chart.bar", title: "Real-time Analytics", description: "Performance metrics and data visualization")
                            FeatureRow(icon: "terminal", title: "Terminal Interface", description: "Direct command-line access")
                            FeatureRow(icon: "shield.checkered", title: "Enterprise Security", description: "Biometric auth and encrypted storage")
                        }
                    }
                    
                    // Links
                    VStack(spacing: 12) {
                        Button("Privacy Policy") {
                            // Open privacy policy
                        }
                        
                        Button("Terms of Service") {
                            // Open terms
                        }
                        
                        Button("Send Feedback") {
                            // Send feedback
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding(32)
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}