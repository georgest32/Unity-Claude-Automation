//
//  HapticFeedbackService.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Haptic feedback service using Core Haptics and UIFeedbackGenerator
//

import Foundation
import CoreHaptics
import SwiftUI
import ComposableArchitecture

// MARK: - Haptic Feedback Service Protocol

protocol HapticFeedbackServiceProtocol {
    /// Trigger simple haptic feedback
    func triggerHaptic(_ type: HapticType)
    
    /// Play custom haptic pattern
    func playCustomPattern(_ pattern: HapticPattern) async
    
    /// Check if haptics are supported on device
    func isHapticsSupported() -> Bool
    
    /// Prepare haptic engine for optimal performance
    func prepareHaptics()
    
    /// Configure haptic preferences
    func configureHaptics(enabled: Bool, intensity: Float)
    
    /// Get haptic capabilities for current device
    func getHapticCapabilities() -> HapticCapabilities
}

// MARK: - Haptic Models

enum HapticType: CaseIterable {
    // UIFeedbackGenerator types
    case success           // Successful operations
    case warning           // Validation warnings
    case error            // Error conditions
    case light            // Light interactions
    case medium           // Medium interactions  
    case heavy            // Heavy interactions
    case selection        // Selection changes
    
    // Custom Core Haptics patterns
    case agentStart       // Agent startup
    case agentStop        // Agent shutdown
    case dataRefresh      // Data updates
    case criticalAlert    // Critical system alerts
    case buttonPress      // Button interactions
    case cardFlip         // Card state changes
    case connectionLost   // Network issues
    case connectionRestored // Network recovery
    
    var description: String {
        switch self {
        case .success:
            return "Success operation feedback"
        case .warning:
            return "Warning condition feedback"
        case .error:
            return "Error condition feedback"
        case .light:
            return "Light interaction feedback"
        case .medium:
            return "Medium interaction feedback"
        case .heavy:
            return "Heavy interaction feedback"
        case .selection:
            return "Selection change feedback"
        case .agentStart:
            return "Agent startup feedback"
        case .agentStop:
            return "Agent shutdown feedback"
        case .dataRefresh:
            return "Data refresh feedback"
        case .criticalAlert:
            return "Critical alert feedback"
        case .buttonPress:
            return "Button press feedback"
        case .cardFlip:
            return "Card flip feedback"
        case .connectionLost:
            return "Connection lost feedback"
        case .connectionRestored:
            return "Connection restored feedback"
        }
    }
    
    var intensity: Float {
        switch self {
        case .light, .selection:
            return 0.3
        case .medium, .buttonPress, .dataRefresh:
            return 0.6
        case .heavy, .success, .agentStart, .agentStop:
            return 0.8
        case .warning, .cardFlip:
            return 0.7
        case .error, .criticalAlert, .connectionLost:
            return 1.0
        case .connectionRestored:
            return 0.9
        }
    }
    
    var sharpness: Float {
        switch self {
        case .light, .selection, .dataRefresh:
            return 0.3
        case .medium, .buttonPress:
            return 0.5
        case .heavy, .success, .warning:
            return 0.7
        case .error, .criticalAlert, .connectionLost:
            return 1.0
        case .agentStart, .agentStop, .cardFlip:
            return 0.8
        case .connectionRestored:
            return 0.6
        }
    }
}

struct HapticPattern {
    let events: [HapticEvent]
    let duration: TimeInterval
    let name: String
    
    init(name: String, events: [HapticEvent]) {
        self.name = name
        self.events = events
        self.duration = events.map { $0.time + $0.duration }.max() ?? 0.5
    }
    
    static let agentStartupPattern = HapticPattern(
        name: "Agent Startup",
        events: [
            HapticEvent(time: 0.0, duration: 0.1, intensity: 0.6, sharpness: 0.5),
            HapticEvent(time: 0.15, duration: 0.1, intensity: 0.8, sharpness: 0.7),
            HapticEvent(time: 0.3, duration: 0.2, intensity: 1.0, sharpness: 0.8)
        ]
    )
    
    static let agentShutdownPattern = HapticPattern(
        name: "Agent Shutdown", 
        events: [
            HapticEvent(time: 0.0, duration: 0.2, intensity: 0.8, sharpness: 0.7),
            HapticEvent(time: 0.25, duration: 0.1, intensity: 0.4, sharpness: 0.3)
        ]
    )
    
    static let criticalAlertPattern = HapticPattern(
        name: "Critical Alert",
        events: [
            HapticEvent(time: 0.0, duration: 0.1, intensity: 1.0, sharpness: 1.0),
            HapticEvent(time: 0.2, duration: 0.1, intensity: 1.0, sharpness: 1.0),
            HapticEvent(time: 0.4, duration: 0.1, intensity: 1.0, sharpness: 1.0)
        ]
    )
}

struct HapticEvent {
    let time: TimeInterval
    let duration: TimeInterval
    let intensity: Float
    let sharpness: Float
}

struct HapticCapabilities {
    let supportsHaptics: Bool
    let supportsCoreHaptics: Bool
    let supportsAdvancedPatterns: Bool
    let deviceType: String
    
    static func current() -> HapticCapabilities {
        let supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
        let supportsCoreHaptics = CHHapticEngine.capabilitiesForHardware().supportsAudio
        
        return HapticCapabilities(
            supportsHaptics: supportsHaptics,
            supportsCoreHaptics: supportsCoreHaptics,
            supportsAdvancedPatterns: supportsHaptics,
            deviceType: UIDevice.current.model
        )
    }
}

// MARK: - Production Haptic Feedback Service

final class HapticFeedbackService: HapticFeedbackServiceProtocol {
    private let logger = Logger(subsystem: "AgentDashboard", category: "HapticFeedback")
    private var hapticEngine: CHHapticEngine?
    private var isHapticsEnabled: Bool = true
    private var hapticIntensity: Float = 1.0
    
    // Feedback generators
    private let impactGeneratorLight = UIImpactFeedbackGenerator(style: .light)
    private let impactGeneratorMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactGeneratorHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()
    
    init() {
        logger.info("HapticFeedbackService initializing...")
        initializeHapticEngine()
        prepareHaptics()
        logger.info("HapticFeedbackService initialized - Haptics supported: \(isHapticsSupported())")
    }
    
    private func initializeHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            logger.warning("Device does not support haptics")
            return
        }
        
        do {
            hapticEngine = try CHHapticEngine()
            
            // Configure engine
            hapticEngine?.stoppedHandler = { [weak self] reason in
                self?.logger.warning("Haptic engine stopped: \(reason)")
                self?.restartHapticEngine()
            }
            
            hapticEngine?.resetHandler = { [weak self] in
                self?.logger.info("Haptic engine reset")
                self?.restartHapticEngine()
            }
            
            try hapticEngine?.start()
            logger.info("Core Haptics engine initialized successfully")
            
        } catch {
            logger.error("Failed to initialize haptic engine: \(error.localizedDescription)")
        }
    }
    
    private func restartHapticEngine() {
        logger.info("Restarting haptic engine")
        
        do {
            try hapticEngine?.start()
        } catch {
            logger.error("Failed to restart haptic engine: \(error.localizedDescription)")
        }
    }
    
    func triggerHaptic(_ type: HapticType) {
        guard isHapticsEnabled && isHapticsSupported() else {
            logger.debug("Haptics disabled or not supported")
            return
        }
        
        logger.debug("Triggering haptic: \(type)")
        
        switch type {
        // Simple UIFeedbackGenerator patterns
        case .success:
            notificationGenerator.notificationOccurred(.success)
        case .warning:
            notificationGenerator.notificationOccurred(.warning)
        case .error:
            notificationGenerator.notificationOccurred(.error)
        case .light:
            impactGeneratorLight.impactOccurred(intensity: type.intensity * hapticIntensity)
        case .medium:
            impactGeneratorMedium.impactOccurred(intensity: type.intensity * hapticIntensity)
        case .heavy:
            impactGeneratorHeavy.impactOccurred(intensity: type.intensity * hapticIntensity)
        case .selection:
            selectionGenerator.selectionChanged()
            
        // Custom Core Haptics patterns
        case .agentStart:
            Task { await playCustomPattern(.agentStartupPattern) }
        case .agentStop:
            Task { await playCustomPattern(.agentShutdownPattern) }
        case .criticalAlert:
            Task { await playCustomPattern(.criticalAlertPattern) }
        case .buttonPress:
            impactGeneratorMedium.impactOccurred(intensity: 0.6)
        case .cardFlip:
            impactGeneratorMedium.impactOccurred(intensity: 0.7)
        case .dataRefresh:
            impactGeneratorLight.impactOccurred(intensity: 0.4)
        case .connectionLost:
            notificationGenerator.notificationOccurred(.error)
        case .connectionRestored:
            notificationGenerator.notificationOccurred(.success)
        }
    }
    
    func playCustomPattern(_ pattern: HapticPattern) async {
        guard isHapticsEnabled,
              let hapticEngine = hapticEngine else {
            logger.debug("Custom haptic pattern skipped - engine not available")
            return
        }
        
        logger.info("Playing custom haptic pattern: \(pattern.name)")
        
        do {
            var hapticEvents: [CHHapticEvent] = []
            
            for event in pattern.events {
                let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: event.intensity * hapticIntensity)
                let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: event.sharpness)
                
                let hapticEvent = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [intensity, sharpness],
                    relativeTime: event.time,
                    duration: event.duration
                )
                
                hapticEvents.append(hapticEvent)
            }
            
            let hapticPattern = try CHHapticPattern(events: hapticEvents, parameters: [])
            let player = try hapticEngine.makePlayer(with: hapticPattern)
            
            try player.start(atTime: CHHapticTimeImmediate)
            
            logger.debug("Custom haptic pattern played successfully: \(pattern.name)")
            
        } catch {
            logger.error("Failed to play custom haptic pattern \(pattern.name): \(error.localizedDescription)")
        }
    }
    
    func isHapticsSupported() -> Bool {
        return CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }
    
    func prepareHaptics() {
        logger.debug("Preparing haptic generators for optimal performance")
        
        // Prepare all generators for minimal latency
        impactGeneratorLight.prepare()
        impactGeneratorMedium.prepare()
        impactGeneratorHeavy.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }
    
    func configureHaptics(enabled: Bool, intensity: Float) {
        logger.info("Configuring haptics - Enabled: \(enabled), Intensity: \(intensity)")
        
        isHapticsEnabled = enabled
        hapticIntensity = max(0.0, min(1.0, intensity)) // Clamp between 0 and 1
        
        if enabled {
            prepareHaptics()
        }
    }
    
    func getHapticCapabilities() -> HapticCapabilities {
        return HapticCapabilities.current()
    }
}

// MARK: - Haptic Feedback Manager

@MainActor
class HapticFeedbackManager: ObservableObject {
    @Published var isHapticsEnabled: Bool = true
    @Published var hapticIntensity: Float = 1.0
    @Published var capabilities: HapticCapabilities
    
    private let hapticService: HapticFeedbackServiceProtocol
    private let logger = Logger(subsystem: "AgentDashboard", category: "HapticManager")
    
    init(hapticService: HapticFeedbackServiceProtocol) {
        self.hapticService = hapticService
        self.capabilities = hapticService.getHapticCapabilities()
        
        // Load user preferences
        loadHapticPreferences()
        
        // Apply configuration
        hapticService.configureHaptics(enabled: isHapticsEnabled, intensity: hapticIntensity)
        
        logger.info("HapticFeedbackManager initialized - Enabled: \(isHapticsEnabled), Intensity: \(hapticIntensity)")
    }
    
    func triggerHaptic(_ type: HapticType) {
        logger.debug("Triggering haptic from manager: \(type)")
        hapticService.triggerHaptic(type)
    }
    
    func playCustomPattern(_ pattern: HapticPattern) {
        logger.debug("Playing custom pattern from manager: \(pattern.name)")
        Task {
            await hapticService.playCustomPattern(pattern)
        }
    }
    
    func updateHapticSettings(enabled: Bool, intensity: Float) {
        logger.info("Updating haptic settings - Enabled: \(enabled), Intensity: \(intensity)")
        
        isHapticsEnabled = enabled
        hapticIntensity = intensity
        
        hapticService.configureHaptics(enabled: enabled, intensity: intensity)
        saveHapticPreferences()
    }
    
    private func loadHapticPreferences() {
        isHapticsEnabled = UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true
        hapticIntensity = UserDefaults.standard.object(forKey: "hapticIntensity") as? Float ?? 1.0
        
        logger.debug("Loaded haptic preferences - Enabled: \(isHapticsEnabled), Intensity: \(hapticIntensity)")
    }
    
    private func saveHapticPreferences() {
        UserDefaults.standard.set(isHapticsEnabled, forKey: "hapticsEnabled")
        UserDefaults.standard.set(hapticIntensity, forKey: "hapticIntensity")
        
        logger.debug("Saved haptic preferences")
    }
}

// MARK: - SwiftUI Haptic Extensions

extension View {
    /// Add haptic feedback to button presses
    func hapticButton(_ hapticType: HapticType = .buttonPress) -> some View {
        self.onTapGesture {
            @Dependency(\.hapticService) var hapticService
            hapticService.triggerHaptic(hapticType)
        }
    }
    
    /// Add haptic feedback to successful operations
    func hapticSuccess() -> some View {
        self.onAppear {
            @Dependency(\.hapticService) var hapticService
            hapticService.triggerHaptic(.success)
        }
    }
    
    /// Add haptic feedback to error states
    func hapticError() -> some View {
        self.onAppear {
            @Dependency(\.hapticService) var hapticService
            hapticService.triggerHaptic(.error)
        }
    }
    
    /// Add haptic feedback to selection changes
    func hapticSelection() -> some View {
        self.onChange(of: true) { _ in
            @Dependency(\.hapticService) var hapticService
            hapticService.triggerHaptic(.selection)
        }
    }
}

// MARK: - Haptic Feedback Demo View

struct HapticDemoView: View {
    @StateObject private var hapticManager: HapticFeedbackManager
    @State private var selectedHapticType: HapticType = .medium
    
    init() {
        @Dependency(\.hapticService) var hapticService
        self._hapticManager = StateObject(wrappedValue: HapticFeedbackManager(hapticService: hapticService))
    }
    
    var body: some View {
        NavigationView {
            List {
                Section("Haptic Settings") {
                    Toggle("Enable Haptics", isOn: $hapticManager.isHapticsEnabled)
                        .onChange(of: hapticManager.isHapticsEnabled) { enabled in
                            hapticManager.updateHapticSettings(enabled: enabled, intensity: hapticManager.hapticIntensity)
                        }
                    
                    if hapticManager.isHapticsEnabled {
                        VStack {
                            Text("Intensity: \(String(format: "%.1f", hapticManager.hapticIntensity))")
                            Slider(value: $hapticManager.hapticIntensity, in: 0.1...1.0, step: 0.1)
                                .onChange(of: hapticManager.hapticIntensity) { intensity in
                                    hapticManager.updateHapticSettings(enabled: hapticManager.isHapticsEnabled, intensity: intensity)
                                }
                        }
                    }
                }
                
                Section("Device Capabilities") {
                    HStack {
                        Text("Haptics Supported")
                        Spacer()
                        Image(systemName: hapticManager.capabilities.supportsHaptics ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(hapticManager.capabilities.supportsHaptics ? .green : .red)
                    }
                    
                    HStack {
                        Text("Core Haptics")
                        Spacer()
                        Image(systemName: hapticManager.capabilities.supportsCoreHaptics ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(hapticManager.capabilities.supportsCoreHaptics ? .green : .red)
                    }
                    
                    HStack {
                        Text("Device Type")
                        Spacer()
                        Text(hapticManager.capabilities.deviceType)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Test Haptics") {
                    ForEach(HapticType.allCases, id: \.self) { hapticType in
                        Button(hapticType.description) {
                            hapticManager.triggerHaptic(hapticType)
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                Section("Custom Patterns") {
                    Button("Agent Startup Pattern") {
                        hapticManager.playCustomPattern(.agentStartupPattern)
                    }
                    
                    Button("Agent Shutdown Pattern") {
                        hapticManager.playCustomPattern(.agentShutdownPattern)
                    }
                    
                    Button("Critical Alert Pattern") {
                        hapticManager.playCustomPattern(.criticalAlertPattern)
                    }
                }
            }
            .navigationTitle("Haptic Demo")
        }
    }
}

// MARK: - Mock Haptic Feedback Service

final class MockHapticFeedbackService: HapticFeedbackServiceProtocol {
    private let logger = Logger(subsystem: "AgentDashboard", category: "MockHapticFeedback")
    private var isEnabled: Bool = true
    private var intensity: Float = 1.0
    
    init() {
        logger.info("MockHapticFeedbackService initialized")
    }
    
    func triggerHaptic(_ type: HapticType) {
        guard isEnabled else { return }
        logger.debug("Mock triggering haptic: \(type) with intensity: \(intensity)")
    }
    
    func playCustomPattern(_ pattern: HapticPattern) async {
        guard isEnabled else { return }
        logger.debug("Mock playing custom pattern: \(pattern.name) for \(pattern.duration)s")
        
        // Simulate pattern duration
        try? await Task.sleep(nanoseconds: UInt64(pattern.duration * 1_000_000_000))
    }
    
    func isHapticsSupported() -> Bool {
        logger.debug("Mock haptics supported: true")
        return true
    }
    
    func prepareHaptics() {
        logger.debug("Mock preparing haptics")
    }
    
    func configureHaptics(enabled: Bool, intensity: Float) {
        logger.info("Mock configuring haptics - Enabled: \(enabled), Intensity: \(intensity)")
        isEnabled = enabled
        self.intensity = intensity
    }
    
    func getHapticCapabilities() -> HapticCapabilities {
        return HapticCapabilities(
            supportsHaptics: true,
            supportsCoreHaptics: true,
            supportsAdvancedPatterns: true,
            deviceType: "Mock Device"
        )
    }
}

// MARK: - Dependency Registration

private enum HapticServiceKey: DependencyKey {
    static let liveValue: HapticFeedbackServiceProtocol = HapticFeedbackService()
    static let testValue: HapticFeedbackServiceProtocol = MockHapticFeedbackService()
    static let previewValue: HapticFeedbackServiceProtocol = MockHapticFeedbackService()
}

extension DependencyValues {
    var hapticService: HapticFeedbackServiceProtocol {
        get { self[HapticServiceKey.self] }
        set { self[HapticServiceKey.self] = newValue }
    }
}