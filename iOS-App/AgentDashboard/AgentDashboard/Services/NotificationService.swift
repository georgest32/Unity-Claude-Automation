//
//  NotificationService.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Notification service for push notifications and in-app alerts
//

import Foundation
import UserNotifications
import SwiftUI
import Dependencies

// MARK: - Notification Service Protocol

protocol NotificationServiceProtocol {
    func requestPermissions() async -> Bool
    func scheduleLocalNotification(alert: Alert) async -> Bool
    func scheduleAgentStatusNotification(agent: Agent, oldStatus: AgentStatus) async -> Bool
    func scheduleSystemAlert(title: String, message: String, severity: Alert.Severity) async -> Bool
    func cancelNotification(identifier: String)
    func cancelAllNotifications()
    func getNotificationSettings() async -> NotificationSettings
    func updateNotificationPreferences(_ preferences: NotificationPreferences)
}

// MARK: - Notification Models

struct NotificationSettings {
    let isAuthorized: Bool
    let alertsEnabled: Bool
    let soundEnabled: Bool
    let badgeEnabled: Bool
    let criticalAlertsEnabled: Bool
    let provisionalEnabled: Bool
    
    static let denied = NotificationSettings(
        isAuthorized: false,
        alertsEnabled: false,
        soundEnabled: false,
        badgeEnabled: false,
        criticalAlertsEnabled: false,
        provisionalEnabled: false
    )
}

struct NotificationPreferences: Codable {
    var agentStatusChanges: Bool = true
    var systemAlerts: Bool = true
    var errorNotifications: Bool = true
    var performanceWarnings: Bool = false
    var maintenanceReminders: Bool = true
    var soundEnabled: Bool = true
    var badgeEnabled: Bool = true
    var quietHoursEnabled: Bool = false
    var quietHoursStart: Date = Calendar.current.date(from: DateComponents(hour: 22, minute: 0))!
    var quietHoursEnd: Date = Calendar.current.date(from: DateComponents(hour: 8, minute: 0))!
    
    // Severity filtering
    var minimumSeverity: Alert.Severity = .info
    
    var isInQuietHours: Bool {
        guard quietHoursEnabled else { return false }
        
        let now = Date()
        let calendar = Calendar.current
        
        let nowComponents = calendar.dateComponents([.hour, .minute], from: now)
        let startComponents = calendar.dateComponents([.hour, .minute], from: quietHoursStart)
        let endComponents = calendar.dateComponents([.hour, .minute], from: quietHoursEnd)
        
        let nowMinutes = (nowComponents.hour ?? 0) * 60 + (nowComponents.minute ?? 0)
        let startMinutes = (startComponents.hour ?? 0) * 60 + (startComponents.minute ?? 0)
        let endMinutes = (endComponents.hour ?? 0) * 60 + (endComponents.minute ?? 0)
        
        if startMinutes <= endMinutes {
            // Same day quiet hours (e.g., 14:00 - 18:00)
            return nowMinutes >= startMinutes && nowMinutes <= endMinutes
        } else {
            // Overnight quiet hours (e.g., 22:00 - 08:00)
            return nowMinutes >= startMinutes || nowMinutes <= endMinutes
        }
    }
}

// MARK: - Notification Service Implementation

final class NotificationService: NotificationServiceProtocol {
    private let userNotificationCenter = UNUserNotificationCenter.current()
    private var preferences = NotificationPreferences()
    
    init() {
        print("[NotificationService] Initializing notification service")
        setupNotificationCategories()
        loadPreferences()
    }
    
    // MARK: - Permission Management
    
    func requestPermissions() async -> Bool {
        print("[NotificationService] Requesting notification permissions")
        
        do {
            let granted = try await userNotificationCenter.requestAuthorization(options: [
                .alert,
                .sound,
                .badge,
                .provisional, // iOS 12+ for quiet notifications
                .criticalAlert // Requires special entitlement
            ])
            
            print("[NotificationService] Permission request result: \(granted)")
            return granted
        } catch {
            print("[NotificationService] Permission request failed: \(error.localizedDescription)")
            return false
        }
    }
    
    func getNotificationSettings() async -> NotificationSettings {
        let settings = await userNotificationCenter.notificationSettings()
        
        return NotificationSettings(
            isAuthorized: settings.authorizationStatus == .authorized,
            alertsEnabled: settings.alertSetting == .enabled,
            soundEnabled: settings.soundSetting == .enabled,
            badgeEnabled: settings.badgeSetting == .enabled,
            criticalAlertsEnabled: settings.criticalAlertSetting == .enabled,
            provisionalEnabled: settings.authorizationStatus == .provisional
        )
    }
    
    // MARK: - Notification Scheduling
    
    func scheduleLocalNotification(alert: Alert) async -> Bool {
        print("[NotificationService] Scheduling notification for alert: \(alert.title)")
        
        // Check if notifications are allowed for this severity
        guard shouldSendNotification(for: alert.severity) else {
            print("[NotificationService] Notification filtered by preferences")
            return false
        }
        
        let content = UNMutableNotificationContent()
        content.title = alert.title
        content.body = alert.message
        content.categoryIdentifier = "ALERT_CATEGORY"
        content.userInfo = [
            "alertId": alert.id.uuidString,
            "severity": alert.severity.rawValue,
            "source": alert.source,
            "timestamp": alert.timestamp.timeIntervalSince1970
        ]
        
        // Set sound based on severity and preferences
        if preferences.soundEnabled {
            content.sound = notificationSound(for: alert.severity)
        }
        
        // Set badge if enabled
        if preferences.badgeEnabled {
            content.badge = 1
        }
        
        // Add custom actions
        content.categoryIdentifier = categoryIdentifier(for: alert.severity)
        
        // Schedule immediately
        let request = UNNotificationRequest(
            identifier: alert.id.uuidString,
            content: content,
            trigger: nil // Send immediately
        )
        
        do {
            try await userNotificationCenter.add(request)
            print("[NotificationService] Notification scheduled successfully")
            return true
        } catch {
            print("[NotificationService] Failed to schedule notification: \(error.localizedDescription)")
            return false
        }
    }
    
    func scheduleAgentStatusNotification(agent: Agent, oldStatus: AgentStatus) async -> Bool {
        print("[NotificationService] Agent status notification: \(agent.name) \(oldStatus.rawValue) → \(agent.status.rawValue)")
        
        guard preferences.agentStatusChanges else {
            print("[NotificationService] Agent status notifications disabled")
            return false
        }
        
        // Only notify for significant status changes
        let significantChanges: [(from: AgentStatus, to: AgentStatus)] = [
            (.running, .stopped),
            (.running, .error),
            (.stopped, .running),
            (.error, .running),
            (.idle, .error)
        ]
        
        let isSignificantChange = significantChanges.contains { $0.from == oldStatus && $0.to == agent.status }
        guard isSignificantChange else {
            print("[NotificationService] Status change not significant enough for notification")
            return false
        }
        
        let alert = Alert(
            id: UUID(),
            title: "Agent Status Changed",
            message: "\(agent.name) is now \(agent.status.rawValue)",
            severity: severityForStatusChange(from: oldStatus, to: agent.status),
            timestamp: Date(),
            source: "System"
        )
        
        return await scheduleLocalNotification(alert: alert)
    }
    
    func scheduleSystemAlert(title: String, message: String, severity: Alert.Severity) async -> Bool {
        print("[NotificationService] System alert: \(title) [\(severity.rawValue)]")
        
        guard preferences.systemAlerts else {
            print("[NotificationService] System alerts disabled")
            return false
        }
        
        let alert = Alert(
            id: UUID(),
            title: title,
            message: message,
            severity: severity,
            timestamp: Date(),
            source: "System"
        )
        
        return await scheduleLocalNotification(alert: alert)
    }
    
    // MARK: - Notification Management
    
    func cancelNotification(identifier: String) {
        print("[NotificationService] Canceling notification: \(identifier)")
        userNotificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        userNotificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])
    }
    
    func cancelAllNotifications() {
        print("[NotificationService] Canceling all notifications")
        userNotificationCenter.removeAllPendingNotificationRequests()
        userNotificationCenter.removeAllDeliveredNotifications()
    }
    
    // MARK: - Preferences Management
    
    func updateNotificationPreferences(_ preferences: NotificationPreferences) {
        print("[NotificationService] Updating notification preferences")
        self.preferences = preferences
        savePreferences()
    }
    
    // MARK: - Private Helper Methods
    
    private func setupNotificationCategories() {
        // Define notification actions
        let viewAction = UNNotificationAction(
            identifier: "VIEW_ALERT",
            title: "View Details",
            options: [.foreground]
        )
        
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_ALERT",
            title: "Dismiss",
            options: []
        )
        
        // Define categories for different severity levels
        let infoCategory = UNNotificationCategory(
            identifier: "INFO_ALERT",
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        let warningCategory = UNNotificationCategory(
            identifier: "WARNING_ALERT",
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        let errorCategory = UNNotificationCategory(
            identifier: "ERROR_ALERT",
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        let criticalCategory = UNNotificationCategory(
            identifier: "CRITICAL_ALERT",
            actions: [viewAction],
            intentIdentifiers: [],
            options: [.customDismissAction, .hiddenPreviewsShowTitle]
        )
        
        userNotificationCenter.setNotificationCategories([
            infoCategory,
            warningCategory,
            errorCategory,
            criticalCategory
        ])
        
        print("[NotificationService] Notification categories configured")
    }
    
    private func shouldSendNotification(for severity: Alert.Severity) -> Bool {
        // Check minimum severity
        let severityLevels: [Alert.Severity: Int] = [.info: 0, .warning: 1, .error: 2, .critical: 3]
        let currentLevel = severityLevels[severity] ?? 0
        let minimumLevel = severityLevels[preferences.minimumSeverity] ?? 0
        
        guard currentLevel >= minimumLevel else { return false }
        
        // Check quiet hours for non-critical alerts
        if severity != .critical && preferences.isInQuietHours {
            print("[NotificationService] Suppressing notification due to quiet hours")
            return false
        }
        
        return true
    }
    
    private func notificationSound(for severity: Alert.Severity) -> UNNotificationSound {
        switch severity {
        case .info:
            return .default
        case .warning:
            return UNNotificationSound(named: UNNotificationSoundName("warning.wav"))
        case .error:
            return UNNotificationSound(named: UNNotificationSoundName("error.wav"))
        case .critical:
            return .defaultCritical
        }
    }
    
    private func categoryIdentifier(for severity: Alert.Severity) -> String {
        switch severity {
        case .info:
            return "INFO_ALERT"
        case .warning:
            return "WARNING_ALERT"
        case .error:
            return "ERROR_ALERT"
        case .critical:
            return "CRITICAL_ALERT"
        }
    }
    
    private func severityForStatusChange(from oldStatus: AgentStatus, to newStatus: AgentStatus) -> Alert.Severity {
        switch (oldStatus, newStatus) {
        case (_, .error):
            return .error
        case (.error, .running):
            return .info
        case (.running, .stopped):
            return .warning
        case (.stopped, .running):
            return .info
        default:
            return .info
        }
    }
    
    private func loadPreferences() {
        if let data = UserDefaults.standard.data(forKey: "NotificationPreferences"),
           let decoded = try? JSONDecoder().decode(NotificationPreferences.self, from: data) {
            preferences = decoded
            print("[NotificationService] Loaded notification preferences")
        }
    }
    
    private func savePreferences() {
        if let encoded = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(encoded, forKey: "NotificationPreferences")
            print("[NotificationService] Saved notification preferences")
        }
    }
}

// MARK: - Mock Notification Service for Testing

final class MockNotificationService: NotificationServiceProtocol {
    private var isAuthorized = false
    private var scheduledNotifications: [String] = []
    
    func requestPermissions() async -> Bool {
        print("[MockNotificationService] Mock permission request")
        try? await Task.sleep(nanoseconds: 200_000_000)
        isAuthorized = true
        return true
    }
    
    func scheduleLocalNotification(alert: Alert) async -> Bool {
        print("[MockNotificationService] Mock scheduling notification: \(alert.title)")
        scheduledNotifications.append(alert.id.uuidString)
        return true
    }
    
    func scheduleAgentStatusNotification(agent: Agent, oldStatus: AgentStatus) async -> Bool {
        print("[MockNotificationService] Mock agent status notification: \(agent.name)")
        return true
    }
    
    func scheduleSystemAlert(title: String, message: String, severity: Alert.Severity) async -> Bool {
        print("[MockNotificationService] Mock system alert: \(title)")
        return true
    }
    
    func cancelNotification(identifier: String) {
        print("[MockNotificationService] Mock cancel notification: \(identifier)")
        scheduledNotifications.removeAll { $0 == identifier }
    }
    
    func cancelAllNotifications() {
        print("[MockNotificationService] Mock cancel all notifications")
        scheduledNotifications.removeAll()
    }
    
    func getNotificationSettings() async -> NotificationSettings {
        return NotificationSettings(
            isAuthorized: isAuthorized,
            alertsEnabled: true,
            soundEnabled: true,
            badgeEnabled: true,
            criticalAlertsEnabled: false,
            provisionalEnabled: false
        )
    }
    
    func updateNotificationPreferences(_ preferences: NotificationPreferences) {
        print("[MockNotificationService] Mock update preferences")
    }
}

// MARK: - Dependency Registration

private enum NotificationServiceKey: DependencyKey {
    static let liveValue: NotificationServiceProtocol = NotificationService()
    static let testValue: NotificationServiceProtocol = MockNotificationService()
    static let previewValue: NotificationServiceProtocol = MockNotificationService()
}

extension DependencyValues {
    var notificationService: NotificationServiceProtocol {
        get { self[NotificationServiceKey.self] }
        set { self[NotificationServiceKey.self] = newValue }
    }
}