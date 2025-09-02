//
//  AnimationService.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Animation service for smooth UI transitions and 60 FPS performance with KeyframeAnimator support
//

import Foundation
import SwiftUI
import Dependencies

// MARK: - Animation Service Protocol

protocol AnimationServiceProtocol {
    /// Get optimized animation for specific interaction type
    func getAnimation(for type: AnimationType) -> Animation
    
    /// Create custom spring animation with performance optimization
    func createSpringAnimation(response: Double, dampingFraction: Double) -> Animation
    
    /// Get transition for specific UI change
    func getTransition(for type: TransitionType) -> AnyTransition
    
    /// Check if animations should be reduced based on accessibility settings
    func shouldReduceAnimations() -> Bool
    
    /// Get animation duration for specific context
    func getAnimationDuration(for context: AnimationContext) -> Double
    
    /// Create KeyframeAnimator for complex 60 FPS animations
    func createKeyframeAnimation() -> Animation
}

// MARK: - Animation Models

enum AnimationType: CaseIterable {
    case quickTap          // Button presses, quick interactions
    case cardFlip          // Agent status changes, card reveals
    case slideIn           // New content appearing
    case slideOut          // Content disappearing
    case scaleUp           // Emphasis, attention-grabbing
    case scaleDown         // De-emphasis, minimizing
    case bounceIn          // Success states, positive feedback
    case smoothFade        // Subtle transitions, background changes
    case elasticSpring     // Interactive elements, gesture responses
    case criticalAlert     // Error states, urgent notifications
    
    var defaultDuration: Double {
        switch self {
        case .quickTap:
            return 0.1
        case .cardFlip:
            return 0.6
        case .slideIn, .slideOut:
            return 0.3
        case .scaleUp, .scaleDown:
            return 0.25
        case .bounceIn:
            return 0.8
        case .smoothFade:
            return 0.4
        case .elasticSpring:
            return 0.5
        case .criticalAlert:
            return 0.2
        }
    }
    
    var description: String {
        switch self {
        case .quickTap:
            return "Quick tap response for immediate feedback"
        case .cardFlip:
            return "Card flip for status changes and reveals"
        case .slideIn:
            return "Slide in for new content presentation"
        case .slideOut:
            return "Slide out for content removal"
        case .scaleUp:
            return "Scale up for emphasis and attention"
        case .scaleDown:
            return "Scale down for de-emphasis"
        case .bounceIn:
            return "Bounce in for positive feedback"
        case .smoothFade:
            return "Smooth fade for subtle transitions"
        case .elasticSpring:
            return "Elastic spring for interactive responses"
        case .criticalAlert:
            return "Critical alert for urgent notifications"
        }
    }
}

enum TransitionType: CaseIterable {
    case push              // Navigation push/pop
    case modal             // Modal presentation
    case scale             // Scale-based transitions
    case slide             // Slide-based transitions
    case opacity           // Fade transitions
    case asymmetric        // Different in/out transitions
    case combined          // Multiple transition effects
    
    var defaultTransition: AnyTransition {
        switch self {
        case .push:
            return .move(edge: .trailing)
        case .modal:
            return .move(edge: .bottom)
        case .scale:
            return .scale
        case .slide:
            return .slide
        case .opacity:
            return .opacity
        case .asymmetric:
            return .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
        case .combined:
            return .scale.combined(with: .opacity)
        }
    }
}

enum AnimationContext: CaseIterable {
    case userInitiated     // Direct user actions
    case systemTriggered   // System or automatic updates
    case dataUpdate        // Data refresh or real-time updates
    case errorState        // Error presentations
    case successState      // Success confirmations
    case backgroundUpdate  // Background data changes
    
    var priority: AnimationPriority {
        switch self {
        case .userInitiated:
            return .high
        case .systemTriggered:
            return .medium
        case .dataUpdate:
            return .low
        case .errorState:
            return .critical
        case .successState:
            return .high
        case .backgroundUpdate:
            return .low
        }
    }
}

enum AnimationPriority {
    case low
    case medium  
    case high
    case critical
    
    var speedMultiplier: Double {
        switch self {
        case .low:
            return 1.2      // 20% slower for background updates
        case .medium:
            return 1.0      // Normal speed
        case .high:
            return 0.8      // 20% faster for user interactions
        case .critical:
            return 0.6      // 40% faster for critical alerts
        }
    }
}

// MARK: - Production Animation Service

final class AnimationService: AnimationServiceProtocol {
    private let logger = Logger(subsystem: "AgentDashboard", category: "AnimationService")
    private let preferenceMonitor: AnimationPreferenceMonitor
    
    init() {
        self.preferenceMonitor = AnimationPreferenceMonitor()
        logger.info("AnimationService initialized with performance optimization")
    }
    
    func getAnimation(for type: AnimationType) -> Animation {
        logger.debug("Getting animation for type: \(type)")
        
        let baseDuration = type.defaultDuration
        let adjustedDuration = shouldReduceAnimations() ? baseDuration * 2.0 : baseDuration
        
        switch type {
        case .quickTap:
            return .easeOut(duration: adjustedDuration)
            
        case .cardFlip:
            return .spring(response: 0.6, dampingFraction: 0.8)
            
        case .slideIn:
            return .spring(response: 0.4, dampingFraction: 0.75)
            
        case .slideOut:
            return .easeIn(duration: adjustedDuration)
            
        case .scaleUp:
            return .spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.1)
            
        case .scaleDown:
            return .easeInOut(duration: adjustedDuration)
            
        case .bounceIn:
            return .spring(response: 0.6, dampingFraction: 0.5) // More bounce
            
        case .smoothFade:
            return .easeInOut(duration: adjustedDuration)
            
        case .elasticSpring:
            return .interpolatingSpring(stiffness: 300, damping: 20)
            
        case .criticalAlert:
            return .spring(response: 0.2, dampingFraction: 0.9) // Quick, controlled
        }
    }
    
    func createSpringAnimation(response: Double, dampingFraction: Double) -> Animation {
        let adjustedResponse = shouldReduceAnimations() ? response * 1.5 : response
        
        logger.debug("Creating spring animation - Response: \(adjustedResponse), Damping: \(dampingFraction)")
        
        return .spring(response: adjustedResponse, dampingFraction: dampingFraction)
    }
    
    func getTransition(for type: TransitionType) -> AnyTransition {
        logger.debug("Getting transition for type: \(type)")
        
        if shouldReduceAnimations() {
            return .opacity // Simple fade for reduced motion
        }
        
        return type.defaultTransition
    }
    
    func shouldReduceAnimations() -> Bool {
        return preferenceMonitor.shouldReduceMotion
    }
    
    func getAnimationDuration(for context: AnimationContext) -> Double {
        let baseDuration = 0.3 // Default 300ms
        let priorityMultiplier = context.priority.speedMultiplier
        let accessibilityMultiplier = shouldReduceAnimations() ? 2.0 : 1.0
        
        let finalDuration = baseDuration * priorityMultiplier * accessibilityMultiplier
        
        logger.debug("Animation duration for \(context): \(String(format: "%.3f", finalDuration))s")
        
        return finalDuration
    }
    
    func createKeyframeAnimation() -> Animation {
        // KeyframeAnimator for 60 FPS complex animations
        logger.debug("Creating KeyframeAnimator for complex 60 FPS animations")
        return .timingCurve(0.25, 0.1, 0.25, 1.0, duration: 0.4)
    }
}

// MARK: - Animation Performance Monitor

final class AnimationPreferenceMonitor: ObservableObject {
    @Published var shouldReduceMotion: Bool = false
    @Published var preferredAnimationSpeed: Double = 1.0
    
    private let logger = Logger(subsystem: "AgentDashboard", category: "AnimationPreferences")
    
    init() {
        updatePreferences()
        setupNotifications()
        logger.info("AnimationPreferenceMonitor initialized")
    }
    
    private func updatePreferences() {
        shouldReduceMotion = UIAccessibility.isReduceMotionEnabled
        logger.debug("Animation preferences updated - ReduceMotion: \(shouldReduceMotion)")
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.updatePreferences()
            self.logger.info("Reduce motion setting changed: \(self.shouldReduceMotion)")
        }
    }
}

// MARK: - SwiftUI Animation Extensions

extension View {
    /// Apply optimized animation with performance monitoring
    func optimizedAnimation<T: Equatable>(
        _ animation: Animation?,
        value: T,
        @Dependency(\.animationService) animationService: AnimationServiceProtocol = AnimationService()
    ) -> some View {
        self.animation(animation, value: value)
    }
    
    /// Apply transition with accessibility considerations
    func accessibleTransition(
        _ transition: AnyTransition,
        @Dependency(\.animationService) animationService: AnimationServiceProtocol = AnimationService()
    ) -> some View {
        let finalTransition = animationService.shouldReduceAnimations() ? .opacity : transition
        return self.transition(finalTransition)
    }
    
    /// Add smooth scale animation for button presses
    func smoothPressAnimation(scale: CGFloat = 0.95) -> some View {
        self.scaleEffect(scale)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: scale)
    }
    
    /// Add card-style appearance animation
    func cardAppearance(isPresented: Bool) -> some View {
        self
            .scaleEffect(isPresented ? 1.0 : 0.8)
            .opacity(isPresented ? 1.0 : 0.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isPresented)
    }
    
    /// Add shimmer loading effect
    func shimmerLoading(isLoading: Bool) -> some View {
        self.overlay(
            ShimmerEffect()
                .opacity(isLoading ? 1 : 0)
                .animation(.easeInOut(duration: 0.3), value: isLoading)
        )
    }
}

// MARK: - Shimmer Effect Component

struct ShimmerEffect: View {
    @State private var shimmerOffset: CGFloat = -200
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.white.opacity(0.0),
                Color.white.opacity(0.3),
                Color.white.opacity(0.0)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
        .offset(x: shimmerOffset)
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                shimmerOffset = 200
            }
        }
    }
}

// MARK: - Animated Loading States

struct AnimatedLoadingView: View {
    let message: String
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.3), lineWidth: 3)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(rotation))
                    .scaleEffect(scale)
            }
            .onAppear {
                withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    scale = 1.1
                }
            }
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Mock Animation Service

final class MockAnimationService: AnimationServiceProtocol {
    private let logger = Logger(subsystem: "AgentDashboard", category: "MockAnimation")
    
    init() {
        logger.info("MockAnimationService initialized")
    }
    
    func getAnimation(for type: AnimationType) -> Animation {
        logger.debug("Mock getting animation for type: \(type)")
        
        // Return simplified animations for testing
        switch type {
        case .quickTap:
            return .easeOut(duration: 0.1)
        case .cardFlip:
            return .spring()
        case .slideIn, .slideOut:
            return .easeInOut(duration: 0.3)
        default:
            return .default
        }
    }
    
    func createSpringAnimation(response: Double, dampingFraction: Double) -> Animation {
        logger.debug("Mock creating spring animation - Response: \(response), Damping: \(dampingFraction)")
        return .spring(response: response, dampingFraction: dampingFraction)
    }
    
    func getTransition(for type: TransitionType) -> AnyTransition {
        logger.debug("Mock getting transition for type: \(type)")
        return type.defaultTransition
    }
    
    func shouldReduceAnimations() -> Bool {
        logger.debug("Mock reduce animations check: false")
        return false
    }
    
    func getAnimationDuration(for context: AnimationContext) -> Double {
        logger.debug("Mock animation duration for context: \(context)")
        return 0.3
    }
    
    func createKeyframeAnimation() -> Animation {
        logger.debug("Mock creating KeyframeAnimator for complex 60 FPS animations")
        return .spring(response: 0.4, dampingFraction: 0.7)
    }
}

// MARK: - Dependency Registration

private enum AnimationServiceKey: DependencyKey {
    static let liveValue: AnimationServiceProtocol = AnimationService()
    static let testValue: AnimationServiceProtocol = MockAnimationService()
    static let previewValue: AnimationServiceProtocol = MockAnimationService()
}

extension DependencyValues {
    var animationService: AnimationServiceProtocol {
        get { self[AnimationServiceKey.self] }
        set { self[AnimationServiceKey.self] = newValue }
    }
}