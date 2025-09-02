//
//  SettingsFeature.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Settings feature for app configuration and preferences
//

import ComposableArchitecture
import Foundation

@Reducer
struct SettingsFeature {
    // MARK: - State
    struct State: Equatable {
        // Connection settings
        var serverURL: String = "ws://localhost:8080/ws"
        var apiURL: String = "http://localhost:8080"
        var isAutoConnect: Bool = true
        var connectionTimeout: Double = 30.0
        
        // Display settings
        var theme: Theme = .automatic
        var fontSize: FontSize = .medium
        var isReduceMotion: Bool = false
        var isHighContrast: Bool = false
        
        // Notification settings
        var isNotificationsEnabled: Bool = true
        var isAlertSoundsEnabled: Bool = true
        var alertSeverityFilter: Alert.Severity = .warning
        
        // Terminal settings
        var terminalFontSize: Double = 13.0
        var isTerminalWrapText: Bool = true
        var terminalMaxLines: Int = 1000
        var isTerminalTimestamps: Bool = true
        
        // Data settings
        var dataRetentionDays: Int = 7
        var maxCacheSize: Int = 100 // MB
        var isAnalyticsEnabled: Bool = true
        
        // Debug settings
        var isDebugMode: Bool = false
        var isVerboseLogging: Bool = false
        
        // About info
        var appVersion: String = "1.0.0"
        var buildNumber: String = "1"
        
        enum Theme: String, CaseIterable {
            case light = "Light"
            case dark = "Dark" 
            case automatic = "Automatic"
        }
        
        enum FontSize: String, CaseIterable {
            case small = "Small"
            case medium = "Medium"
            case large = "Large"
            case extraLarge = "Extra Large"
            
            var scale: Double {
                switch self {
                case .small: return 0.9
                case .medium: return 1.0
                case .large: return 1.1
                case .extraLarge: return 1.2
                }
            }
        }
    }
    
    // MARK: - Action
    enum Action: Equatable {
        // Connection settings
        case serverURLChanged(String)
        case apiURLChanged(String)
        case autoConnectToggled
        case connectionTimeoutChanged(Double)
        case testConnection
        case connectionTestResult(Bool)
        
        // Display settings
        case themeChanged(State.Theme)
        case fontSizeChanged(State.FontSize)
        case reduceMotionToggled
        case highContrastToggled
        
        // Notification settings
        case notificationsToggled
        case alertSoundsToggled
        case alertSeverityFilterChanged(Alert.Severity)
        
        // Terminal settings
        case terminalFontSizeChanged(Double)
        case terminalWrapTextToggled
        case terminalMaxLinesChanged(Int)
        case terminalTimestampsToggled
        
        // Data settings
        case dataRetentionDaysChanged(Int)
        case maxCacheSizeChanged(Int)
        case analyticsToggled
        case clearCache
        case exportData
        
        // Debug settings
        case debugModeToggled
        case verboseLoggingToggled
        
        // Actions
        case resetToDefaults
        case resetConfirmed
        case resetCancelled
        
        // Lifecycle
        case onAppear
        case onDisappear
    }
    
    // MARK: - Dependencies
    @Dependency(\.apiClient) var apiClient
    @Dependency(\.continuousClock) var clock
    
    // MARK: - Reducer
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            // Lifecycle
            case .onAppear:
                print("[SettingsFeature] Settings view appeared")
                return .none
                
            case .onDisappear:
                print("[SettingsFeature] Settings view disappeared")
                return .none
                
            // Connection settings
            case let .serverURLChanged(url):
                print("[SettingsFeature] Server URL changed: \(url)")
                state.serverURL = url
                return .none
                
            case let .apiURLChanged(url):
                print("[SettingsFeature] API URL changed: \(url)")
                state.apiURL = url
                return .none
                
            case .autoConnectToggled:
                state.isAutoConnect.toggle()
                print("[SettingsFeature] Auto-connect: \(state.isAutoConnect)")
                return .none
                
            case let .connectionTimeoutChanged(timeout):
                state.connectionTimeout = timeout
                print("[SettingsFeature] Connection timeout: \(timeout)s")
                return .none
                
            case .testConnection:
                print("[SettingsFeature] Testing connection...")
                return .run { [serverURL = state.serverURL] send in
                    do {
                        // Simple connection test
                        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                        // In real implementation, would test actual connection
                        let success = !serverURL.isEmpty
                        await send(.connectionTestResult(success))
                    } catch {
                        await send(.connectionTestResult(false))
                    }
                }
                
            case let .connectionTestResult(success):
                print("[SettingsFeature] Connection test result: \(success)")
                // Could show toast or update UI
                return .none
                
            // Display settings
            case let .themeChanged(theme):
                print("[SettingsFeature] Theme changed: \(theme.rawValue)")
                state.theme = theme
                return .none
                
            case let .fontSizeChanged(fontSize):
                print("[SettingsFeature] Font size changed: \(fontSize.rawValue)")
                state.fontSize = fontSize
                return .none
                
            case .reduceMotionToggled:
                state.isReduceMotion.toggle()
                print("[SettingsFeature] Reduce motion: \(state.isReduceMotion)")
                return .none
                
            case .highContrastToggled:
                state.isHighContrast.toggle()
                print("[SettingsFeature] High contrast: \(state.isHighContrast)")
                return .none
                
            // Notification settings
            case .notificationsToggled:
                state.isNotificationsEnabled.toggle()
                print("[SettingsFeature] Notifications: \(state.isNotificationsEnabled)")
                return .none
                
            case .alertSoundsToggled:
                state.isAlertSoundsEnabled.toggle()
                print("[SettingsFeature] Alert sounds: \(state.isAlertSoundsEnabled)")
                return .none
                
            case let .alertSeverityFilterChanged(severity):
                print("[SettingsFeature] Alert severity filter: \(severity.rawValue)")
                state.alertSeverityFilter = severity
                return .none
                
            // Terminal settings
            case let .terminalFontSizeChanged(size):
                state.terminalFontSize = max(8, min(24, size))
                print("[SettingsFeature] Terminal font size: \(state.terminalFontSize)")
                return .none
                
            case .terminalWrapTextToggled:
                state.isTerminalWrapText.toggle()
                print("[SettingsFeature] Terminal wrap text: \(state.isTerminalWrapText)")
                return .none
                
            case let .terminalMaxLinesChanged(lines):
                state.terminalMaxLines = max(100, min(10000, lines))
                print("[SettingsFeature] Terminal max lines: \(state.terminalMaxLines)")
                return .none
                
            case .terminalTimestampsToggled:
                state.isTerminalTimestamps.toggle()
                print("[SettingsFeature] Terminal timestamps: \(state.isTerminalTimestamps)")
                return .none
                
            // Data settings
            case let .dataRetentionDaysChanged(days):
                state.dataRetentionDays = max(1, min(30, days))
                print("[SettingsFeature] Data retention: \(state.dataRetentionDays) days")
                return .none
                
            case let .maxCacheSizeChanged(size):
                state.maxCacheSize = max(10, min(1000, size))
                print("[SettingsFeature] Max cache size: \(state.maxCacheSize) MB")
                return .none
                
            case .analyticsToggled:
                state.isAnalyticsEnabled.toggle()
                print("[SettingsFeature] Analytics: \(state.isAnalyticsEnabled)")
                return .none
                
            case .clearCache:
                print("[SettingsFeature] Clearing cache...")
                return .run { send in
                    // Simulate cache clearing
                    try await Task.sleep(nanoseconds: 500_000_000)
                    print("[SettingsFeature] Cache cleared")
                }
                
            case .exportData:
                print("[SettingsFeature] Exporting data...")
                return .run { send in
                    // TODO: Implement data export
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    print("[SettingsFeature] Data exported")
                }
                
            // Debug settings
            case .debugModeToggled:
                state.isDebugMode.toggle()
                print("[SettingsFeature] Debug mode: \(state.isDebugMode)")
                return .none
                
            case .verboseLoggingToggled:
                state.isVerboseLogging.toggle()
                print("[SettingsFeature] Verbose logging: \(state.isVerboseLogging)")
                return .none
                
            // Reset actions
            case .resetToDefaults:
                print("[SettingsFeature] Reset to defaults requested")
                // This would typically show a confirmation dialog
                return .send(.resetConfirmed)
                
            case .resetConfirmed:
                print("[SettingsFeature] Resetting to defaults...")
                state = State() // Reset to default values
                return .none
                
            case .resetCancelled:
                print("[SettingsFeature] Reset cancelled")
                return .none
            }
        }
    }
}

// MARK: - Helper Extensions

extension SettingsFeature.State {
    var connectionSummary: String {
        let autoConnect = isAutoConnect ? "Auto" : "Manual"
        let timeout = String(format: "%.0fs", connectionTimeout)
        return "\(autoConnect) connect, \(timeout) timeout"
    }
    
    var displaySummary: String {
        return "\(theme.rawValue) theme, \(fontSize.rawValue) text"
    }
    
    var notificationSummary: String {
        if isNotificationsEnabled {
            return "Enabled, \(alertSeverityFilter.rawValue)+ alerts"
        } else {
            return "Disabled"
        }
    }
    
    var terminalSummary: String {
        let fontSize = String(format: "%.0fpt", terminalFontSize)
        let maxLines = "\(terminalMaxLines)"
        return "\(fontSize) font, \(maxLines) lines max"
    }
    
    var dataSummary: String {
        return "\(dataRetentionDays) days retention, \(maxCacheSize)MB cache"
    }
    
    var debugSummary: String {
        if isDebugMode {
            return isVerboseLogging ? "Debug + Verbose" : "Debug only"
        } else {
            return "Disabled"
        }
    }
    
    var appInfo: String {
        return "Version \(appVersion) (\(buildNumber))"
    }
}