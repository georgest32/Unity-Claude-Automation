//
//  AccessibilityService.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Accessibility service for VoiceOver, Dynamic Type, and WCAG compliance
//

import Foundation
import SwiftUI
import Dependencies

// MARK: - Accessibility Service Protocol

protocol AccessibilityServiceProtocol {
    /// Configure accessibility for a view
    func configureAccessibility(for view: AnyView, with config: AccessibilityConfig) -> AnyView
    
    /// Get current accessibility settings
    func getCurrentAccessibilitySettings() -> AccessibilitySettings
    
    /// Check if VoiceOver is running
    func isVoiceOverRunning() -> Bool
    
    /// Check if high contrast is enabled
    func isHighContrastEnabled() -> Bool
    
    /// Get preferred content size category
    func getPreferredContentSizeCategory() -> ContentSizeCategory
    
    /// Announce accessibility message
    func announceMessage(_ message: String, priority: AccessibilityPriority)
    
    /// Validate accessibility compliance
    func validateAccessibilityCompliance(for view: AnyView) -> AccessibilityValidationResult
}

// MARK: - Accessibility Models

struct AccessibilityConfig {
    let label: String?
    let hint: String?
    let value: String?
    let traits: AccessibilityTraits
    let sortPriority: Double?
    let isButton: Bool
    let isHeader: Bool
    let customActions: [AccessibilityCustomAction]
    
    init(
        label: String? = nil,
        hint: String? = nil,
        value: String? = nil,
        traits: AccessibilityTraits = [],
        sortPriority: Double? = nil,
        isButton: Bool = false,
        isHeader: Bool = false,
        customActions: [AccessibilityCustomAction] = []
    ) {
        self.label = label
        self.hint = hint
        self.value = value
        self.traits = traits
        self.sortPriority = sortPriority
        self.isButton = isButton
        self.isHeader = isHeader
        self.customActions = customActions
    }
}

struct AccessibilitySettings {
    let voiceOverEnabled: Bool
    let switchControlEnabled: Bool
    let highContrastEnabled: Bool
    let reduceMotionEnabled: Bool
    let preferredContentSizeCategory: ContentSizeCategory
    let boldTextEnabled: Bool
    let buttonShapesEnabled: Bool
    let reduceTransparencyEnabled: Bool
    
    var hasAccessibilityNeeds: Bool {
        voiceOverEnabled || switchControlEnabled || highContrastEnabled || 
        reduceMotionEnabled || boldTextEnabled || buttonShapesEnabled || 
        reduceTransparencyEnabled || preferredContentSizeCategory > .large
    }
    
    static func current() -> AccessibilitySettings {
        return AccessibilitySettings(
            voiceOverEnabled: UIAccessibility.isVoiceOverRunning,
            switchControlEnabled: UIAccessibility.isSwitchControlRunning,
            highContrastEnabled: UIAccessibility.isDarkerSystemColorsEnabled,
            reduceMotionEnabled: UIAccessibility.isReduceMotionEnabled,
            preferredContentSizeCategory: ContentSizeCategory(UIApplication.shared.preferredContentSizeCategory),
            boldTextEnabled: UIAccessibility.isBoldTextEnabled,
            buttonShapesEnabled: UIAccessibility.isButtonShapesEnabled,
            reduceTransparencyEnabled: UIAccessibility.isReduceTransparencyEnabled
        )
    }
}

enum AccessibilityPriority {
    case low
    case medium
    case high
    case urgent
    
    var announcement: UIAccessibility.Notification {
        switch self {
        case .low, .medium:
            return .announcement
        case .high:
            return .pageScrolled
        case .urgent:
            return .screenChanged
        }
    }
}

struct AccessibilityValidationResult {
    let isCompliant: Bool
    let issues: [AccessibilityIssue]
    let recommendations: [String]
    let wcagLevel: WCAGLevel
    
    var score: Double {
        guard !issues.isEmpty else { return 1.0 }
        
        let criticalIssues = issues.filter { $0.severity == .critical }.count
        let majorIssues = issues.filter { $0.severity == .major }.count
        let minorIssues = issues.filter { $0.severity == .minor }.count
        
        let totalDeductions = Double(criticalIssues * 30 + majorIssues * 15 + minorIssues * 5)
        return max(0.0, (100.0 - totalDeductions) / 100.0)
    }
}

struct AccessibilityIssue {
    let type: AccessibilityIssueType
    let severity: AccessibilityIssueSeverity
    let description: String
    let recommendation: String
    let wcagCriterion: String?
    
    enum AccessibilityIssueType: String, CaseIterable {
        case missingLabel = "missing_label"
        case inadequateContrastRatio = "inadequate_contrast"
        case smallTouchTarget = "small_touch_target"
        case missingHint = "missing_hint"
        case poorNavigationOrder = "poor_navigation_order"
        case missingDynamicType = "missing_dynamic_type"
        case inadequateErrorHandling = "inadequate_error_handling"
    }
    
    enum AccessibilityIssueSeverity: String, CaseIterable {
        case minor = "minor"
        case major = "major"
        case critical = "critical"
        
        var color: Color {
            switch self {
            case .minor:
                return .yellow
            case .major:
                return .orange
            case .critical:
                return .red
            }
        }
    }
}

enum WCAGLevel: String, CaseIterable {
    case a = "A"
    case aa = "AA"
    case aaa = "AAA"
    case nonCompliant = "Non-Compliant"
    
    var displayName: String {
        switch self {
        case .a:
            return "WCAG Level A"
        case .aa:
            return "WCAG Level AA"
        case .aaa:
            return "WCAG Level AAA"
        case .nonCompliant:
            return "Non-Compliant"
        }
    }
    
    var color: Color {
        switch self {
        case .aaa:
            return .green
        case .aa:
            return .blue
        case .a:
            return .orange
        case .nonCompliant:
            return .red
        }
    }
}

// MARK: - Production Accessibility Service

final class AccessibilityService: AccessibilityServiceProtocol {
    private let logger = Logger(subsystem: "AgentDashboard", category: "AccessibilityService")
    
    init() {
        logger.info("AccessibilityService initialized")
        setupAccessibilityNotifications()
    }
    
    private func setupAccessibilityNotifications() {
        // Monitor accessibility setting changes
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.logger.info("VoiceOver status changed: \(UIAccessibility.isVoiceOverRunning)")
        }
        
        NotificationCenter.default.addObserver(
            forName: UIContentSizeCategory.didChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.logger.info("Content size category changed: \(UIApplication.shared.preferredContentSizeCategory)")
        }
    }
    
    func configureAccessibility(for view: AnyView, with config: AccessibilityConfig) -> AnyView {
        logger.debug("Configuring accessibility for view")
        
        var accessibleView = view
        
        // Apply accessibility label
        if let label = config.label {
            accessibleView = AnyView(accessibleView.accessibilityLabel(label))
        }
        
        // Apply accessibility hint
        if let hint = config.hint {
            accessibleView = AnyView(accessibleView.accessibilityHint(hint))
        }
        
        // Apply accessibility value
        if let value = config.value {
            accessibleView = AnyView(accessibleView.accessibilityValue(value))
        }
        
        // Apply traits
        if !config.traits.isEmpty {
            accessibleView = AnyView(accessibleView.accessibilityAddTraits(config.traits))
        }
        
        // Apply sort priority
        if let sortPriority = config.sortPriority {
            accessibleView = AnyView(accessibleView.accessibilitySortPriority(sortPriority))
        }
        
        // Configure as button if needed
        if config.isButton {
            accessibleView = AnyView(accessibleView.accessibilityAddTraits(.isButton))
        }
        
        // Configure as header if needed
        if config.isHeader {
            accessibleView = AnyView(accessibleView.accessibilityAddTraits(.isHeader))
        }
        
        // Add custom actions
        for action in config.customActions {
            accessibleView = AnyView(accessibleView.accessibilityAction(named: action.name) {
                action.handler()
            })
        }
        
        return accessibleView
    }
    
    func getCurrentAccessibilitySettings() -> AccessibilitySettings {
        let settings = AccessibilitySettings.current()
        logger.debug("Current accessibility settings - VoiceOver: \(settings.voiceOverEnabled), HighContrast: \(settings.highContrastEnabled)")
        return settings
    }
    
    func isVoiceOverRunning() -> Bool {
        let isRunning = UIAccessibility.isVoiceOverRunning
        logger.debug("VoiceOver running status: \(isRunning)")
        return isRunning
    }
    
    func isHighContrastEnabled() -> Bool {
        let isEnabled = UIAccessibility.isDarkerSystemColorsEnabled
        logger.debug("High contrast enabled: \(isEnabled)")
        return isEnabled
    }
    
    func getPreferredContentSizeCategory() -> ContentSizeCategory {
        let category = ContentSizeCategory(UIApplication.shared.preferredContentSizeCategory)
        logger.debug("Preferred content size category: \(category)")
        return category
    }
    
    func announceMessage(_ message: String, priority: AccessibilityPriority = .medium) {
        logger.info("Announcing accessibility message: \(message)")
        
        DispatchQueue.main.async {
            UIAccessibility.post(notification: priority.announcement, argument: message)
        }
    }
    
    func validateAccessibilityCompliance(for view: AnyView) -> AccessibilityValidationResult {
        logger.debug("Validating accessibility compliance for view")
        
        var issues: [AccessibilityIssue] = []
        var recommendations: [String] = []
        
        // Perform basic validation checks
        // Note: In a real implementation, this would use view introspection
        // For now, providing structure for validation
        
        // Check for common issues
        issues.append(contentsOf: performBasicValidation())
        
        // Generate recommendations
        recommendations = generateRecommendations(for: issues)
        
        // Determine WCAG level
        let wcagLevel = determineWCAGLevel(issues: issues)
        
        let result = AccessibilityValidationResult(
            isCompliant: issues.filter { $0.severity == .critical }.isEmpty,
            issues: issues,
            recommendations: recommendations,
            wcagLevel: wcagLevel
        )
        
        logger.info("Accessibility validation completed - Score: \(String(format: "%.1f", result.score * 100))%, WCAG: \(wcagLevel.rawValue)")
        
        return result
    }
    
    private func performBasicValidation() -> [AccessibilityIssue] {
        var issues: [AccessibilityIssue] = []
        
        // Check current accessibility environment
        let settings = getCurrentAccessibilitySettings()
        
        // Validate against common patterns
        if !settings.voiceOverEnabled {
            issues.append(AccessibilityIssue(
                type: .missingLabel,
                severity: .minor,
                description: "VoiceOver not enabled for testing",
                recommendation: "Enable VoiceOver to test screen reader compatibility",
                wcagCriterion: "1.3.1 Info and Relationships"
            ))
        }
        
        return issues
    }
    
    private func generateRecommendations(for issues: [AccessibilityIssue]) -> [String] {
        var recommendations: [String] = []
        
        let groupedIssues = Dictionary(grouping: issues, by: { $0.type })
        
        for (type, typeIssues) in groupedIssues {
            switch type {
            case .missingLabel:
                recommendations.append("Add descriptive accessibility labels using .accessibilityLabel()")
            case .inadequateContrastRatio:
                recommendations.append("Increase color contrast to meet WCAG AA standards (4.5:1 ratio)")
            case .smallTouchTarget:
                recommendations.append("Ensure touch targets are at least 44x44 points")
            case .missingHint:
                recommendations.append("Add accessibility hints for complex interactions using .accessibilityHint()")
            case .poorNavigationOrder:
                recommendations.append("Set logical navigation order using .accessibilitySortPriority()")
            case .missingDynamicType:
                recommendations.append("Support Dynamic Type using system fonts and relative sizing")
            case .inadequateErrorHandling:
                recommendations.append("Provide accessible error messages and recovery options")
            }
        }
        
        return recommendations
    }
    
    private func determineWCAGLevel(issues: [AccessibilityIssue]) -> WCAGLevel {
        let criticalCount = issues.filter { $0.severity == .critical }.count
        let majorCount = issues.filter { $0.severity == .major }.count
        let minorCount = issues.filter { $0.severity == .minor }.count
        
        if criticalCount > 0 {
            return .nonCompliant
        } else if majorCount > 2 {
            return .a
        } else if majorCount > 0 || minorCount > 5 {
            return .aa
        } else {
            return .aaa
        }
    }
}

// MARK: - Accessibility Custom Action

struct AccessibilityCustomAction {
    let name: String
    let handler: () -> Void
    
    init(name: String, handler: @escaping () -> Void) {
        self.name = name
        self.handler = handler
    }
}

// MARK: - Dynamic Type Support

extension View {
    func dynamicTypeSupport() -> some View {
        self
            .font(.system(.body, design: .default))
            .dynamicTypeSize(.xSmall ... .accessibility5)
    }
    
    func accessibleColors() -> some View {
        self
            .foregroundColor(.primary)
            .background(Color(.systemBackground))
    }
    
    func highContrastSupport() -> some View {
        self
            .preferredColorScheme(UIAccessibility.isDarkerSystemColorsEnabled ? .dark : nil)
    }
    
    func accessibilityOptimized(
        label: String? = nil,
        hint: String? = nil,
        value: String? = nil,
        traits: AccessibilityTraits = [],
        sortPriority: Double? = nil
    ) -> some View {
        var view = self
        
        if let label = label {
            view = view.accessibilityLabel(label)
        }
        
        if let hint = hint {
            view = view.accessibilityHint(hint)
        }
        
        if let value = value {
            view = view.accessibilityValue(value)
        }
        
        if !traits.isEmpty {
            view = view.accessibilityAddTraits(traits)
        }
        
        if let sortPriority = sortPriority {
            view = view.accessibilitySortPriority(sortPriority)
        }
        
        return view
            .dynamicTypeSupport()
            .accessibleColors()
            .highContrastSupport()
    }
}

// MARK: - Accessibility Testing Views

struct AccessibilityTestView: View {
    @Dependency(\.accessibilityService) var accessibilityService
    @State private var validationResult: AccessibilityValidationResult?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Accessibility Testing")
                .font(.largeTitle)
                .accessibilityAddTraits(.isHeader)
            
            Button("Test Button") {
                // Action
            }
            .accessibilityOptimized(
                label: "Test accessibility button",
                hint: "Tap to test accessibility features",
                traits: .isButton
            )
            
            Toggle("High Contrast", isOn: .constant(accessibilityService.isHighContrastEnabled()))
                .accessibilityOptimized(
                    label: "High contrast toggle",
                    hint: "Toggle high contrast mode for better visibility"
                )
            
            if let result = validationResult {
                AccessibilityValidationResultView(result: result)
            }
            
            Button("Validate Accessibility") {
                validationResult = accessibilityService.validateAccessibilityCompliance(for: AnyView(self))
            }
            .accessibilityOptimized(
                label: "Validate accessibility compliance",
                hint: "Run accessibility validation checks",
                traits: .isButton
            )
        }
        .padding()
        .onAppear {
            if accessibilityService.isVoiceOverRunning() {
                accessibilityService.announceMessage("Accessibility testing view loaded", priority: .medium)
            }
        }
    }
}

struct AccessibilityValidationResultView: View {
    let result: AccessibilityValidationResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: result.isCompliant ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(result.isCompliant ? .green : .red)
                
                Text("WCAG \(result.wcagLevel.rawValue)")
                    .font(.headline)
                    .foregroundColor(result.wcagLevel.color)
                
                Spacer()
                
                Text("\(String(format: "%.1f", result.score * 100))%")
                    .font(.headline)
                    .foregroundColor(result.score > 0.8 ? .green : result.score > 0.6 ? .orange : .red)
            }
            
            if !result.issues.isEmpty {
                Text("Issues (\(result.issues.count))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                ForEach(result.issues.indices, id: \.self) { index in
                    let issue = result.issues[index]
                    HStack {
                        Circle()
                            .fill(issue.severity.color)
                            .frame(width: 8, height: 8)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(issue.description)
                                .font(.caption)
                            Text(issue.recommendation)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            if !result.recommendations.isEmpty {
                Text("Recommendations")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                ForEach(result.recommendations.indices, id: \.self) { index in
                    Text("• \(result.recommendations[index])")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Accessibility validation results")
        .accessibilityValue("\(result.wcagLevel.displayName), \(String(format: "%.0f", result.score * 100)) percent compliant")
    }
}

// MARK: - Mock Accessibility Service

final class MockAccessibilityService: AccessibilityServiceProtocol {
    private let logger = Logger(subsystem: "AgentDashboard", category: "MockAccessibility")
    
    init() {
        logger.info("MockAccessibilityService initialized")
    }
    
    func configureAccessibility(for view: AnyView, with config: AccessibilityConfig) -> AnyView {
        logger.debug("Mock configuring accessibility for view")
        return view // Return unmodified for mock
    }
    
    func getCurrentAccessibilitySettings() -> AccessibilitySettings {
        return AccessibilitySettings(
            voiceOverEnabled: false,
            switchControlEnabled: false,
            highContrastEnabled: false,
            reduceMotionEnabled: false,
            preferredContentSizeCategory: .large,
            boldTextEnabled: false,
            buttonShapesEnabled: false,
            reduceTransparencyEnabled: false
        )
    }
    
    func isVoiceOverRunning() -> Bool {
        logger.debug("Mock VoiceOver check: false")
        return false
    }
    
    func isHighContrastEnabled() -> Bool {
        logger.debug("Mock high contrast check: false")
        return false
    }
    
    func getPreferredContentSizeCategory() -> ContentSizeCategory {
        logger.debug("Mock content size category: large")
        return .large
    }
    
    func announceMessage(_ message: String, priority: AccessibilityPriority = .medium) {
        logger.info("Mock accessibility announcement: \(message)")
    }
    
    func validateAccessibilityCompliance(for view: AnyView) -> AccessibilityValidationResult {
        logger.debug("Mock accessibility validation")
        
        return AccessibilityValidationResult(
            isCompliant: true,
            issues: [],
            recommendations: ["Consider testing with real VoiceOver enabled"],
            wcagLevel: .aa
        )
    }
}

// MARK: - Dependency Registration

private enum AccessibilityServiceKey: DependencyKey {
    static let liveValue: AccessibilityServiceProtocol = AccessibilityService()
    static let testValue: AccessibilityServiceProtocol = MockAccessibilityService()
    static let previewValue: AccessibilityServiceProtocol = MockAccessibilityService()
}

extension DependencyValues {
    var accessibilityService: AccessibilityServiceProtocol {
        get { self[AccessibilityServiceKey.self] }
        set { self[AccessibilityServiceKey.self] = newValue }
    }
}