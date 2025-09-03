//
//  OnboardingView.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Interactive onboarding flow for new users
//

import SwiftUI
import ComposableArchitecture

// MARK: - Onboarding Models

struct OnboardingStep {
    let id: Int
    let title: String
    let subtitle: String
    let description: String
    let imageName: String
    let primaryAction: String
    let secondaryAction: String?
    let isInteractive: Bool
    let featureDemo: (() -> Void)?
    
    init(
        id: Int,
        title: String,
        subtitle: String,
        description: String,
        imageName: String,
        primaryAction: String,
        secondaryAction: String? = nil,
        isInteractive: Bool = false,
        featureDemo: (() -> Void)? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.imageName = imageName
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
        self.isInteractive = isInteractive
        self.featureDemo = featureDemo
    }
}

// MARK: - Onboarding View

struct OnboardingView: View {
    @State private var currentStep: Int = 0
    @State private var isCompleted: Bool = false
    @State private var showDemo: Bool = false
    
    @Dependency(\.hapticService) var hapticService
    @Dependency(\.animationService) var animationService
    
    let onComplete: () -> Void
    
    private let onboardingSteps: [OnboardingStep] = [
        OnboardingStep(
            id: 0,
            title: "Welcome to AgentDashboard",
            subtitle: "Your Unity-Claude Automation Command Center",
            description: "Monitor and control your autonomous agents, view real-time analytics, and manage your automation workflow from anywhere.",
            imageName: "app.badge.checkmark",
            primaryAction: "Get Started",
            isInteractive: false
        ),
        OnboardingStep(
            id: 1,
            title: "Agent Management",
            subtitle: "Control Your Automation Agents",
            description: "Start, stop, restart, and monitor your agents in real-time. Get instant feedback on agent status and performance.",
            imageName: "cpu",
            primaryAction: "Try Agent Control",
            secondaryAction: "Skip Demo",
            isInteractive: true
        ),
        OnboardingStep(
            id: 2,
            title: "Real-time Analytics",
            subtitle: "Monitor System Performance",
            description: "Track CPU, memory, and system metrics with beautiful charts. Export data and analyze trends over time.",
            imageName: "chart.line.uptrend.xyaxis",
            primaryAction: "View Analytics",
            secondaryAction: "Skip Demo",
            isInteractive: true
        ),
        OnboardingStep(
            id: 3,
            title: "Secure & Connected",
            subtitle: "Biometric Authentication & Real-time Updates",
            description: "Your data is protected with Face ID/Touch ID authentication and encrypted storage. Stay connected with live WebSocket updates.",
            imageName: "shield.checkered",
            primaryAction: "Enable Security",
            secondaryAction: "Setup Later",
            isInteractive: true
        ),
        OnboardingStep(
            id: 4,
            title: "You're All Set!",
            subtitle: "Ready to Automate with Confidence",
            description: "Start exploring your dashboard, control your agents, and experience the power of Unity-Claude automation.",
            imageName: "checkmark.seal.fill",
            primaryAction: "Start Using App",
            isInteractive: false
        )
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(.systemBlue).opacity(0.1),
                    Color(.systemPurple).opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator
                OnboardingProgressBar(
                    currentStep: currentStep,
                    totalSteps: onboardingSteps.count
                )
                .padding(.top, 20)
                
                // Main content
                TabView(selection: $currentStep) {
                    ForEach(onboardingSteps, id: \.id) { step in
                        OnboardingStepView(
                            step: step,
                            isCurrentStep: currentStep == step.id,
                            onPrimaryAction: {
                                handlePrimaryAction(for: step)
                            },
                            onSecondaryAction: {
                                handleSecondaryAction(for: step)
                            }
                        )
                        .tag(step.id)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            hapticService.triggerHaptic(.selection)
                            
                            if value.translation.x < -50 && currentStep < onboardingSteps.count - 1 {
                                // Swipe left - next step
                                withAnimation(animationService.getAnimation(for: .slideIn)) {
                                    currentStep += 1
                                }
                            } else if value.translation.x > 50 && currentStep > 0 {
                                // Swipe right - previous step
                                withAnimation(animationService.getAnimation(for: .slideOut)) {
                                    currentStep -= 1
                                }
                            }
                        }
                )
                
                Spacer()
                
                // Navigation controls
                OnboardingNavigationControls(
                    currentStep: $currentStep,
                    totalSteps: onboardingSteps.count,
                    onSkip: {
                        completeOnboarding()
                    },
                    onNext: {
                        nextStep()
                    },
                    onPrevious: {
                        previousStep()
                    }
                )
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            hapticService.triggerHaptic(.success)
        }
    }
    
    // MARK: - Action Handlers
    
    private func handlePrimaryAction(for step: OnboardingStep) {
        hapticService.triggerHaptic(.buttonPress)
        
        switch step.id {
        case 0:
            nextStep()
        case 1:
            showAgentDemo()
        case 2:
            showAnalyticsDemo()
        case 3:
            showSecurityDemo()
        case 4:
            completeOnboarding()
        default:
            nextStep()
        }
    }
    
    private func handleSecondaryAction(for step: OnboardingStep) {
        hapticService.triggerHaptic(.selection)
        nextStep()
    }
    
    private func nextStep() {
        guard currentStep < onboardingSteps.count - 1 else {
            completeOnboarding()
            return
        }
        
        withAnimation(animationService.getAnimation(for: .slideIn)) {
            currentStep += 1
        }
    }
    
    private func previousStep() {
        guard currentStep > 0 else { return }
        
        withAnimation(animationService.getAnimation(for: .slideOut)) {
            currentStep -= 1
        }
    }
    
    private func completeOnboarding() {
        hapticService.triggerHaptic(.success)
        
        withAnimation(animationService.getAnimation(for: .scaleUp)) {
            isCompleted = true
        }
        
        // Mark onboarding as completed
        UserDefaults.standard.set(true, forKey: "onboardingCompleted")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onComplete()
        }
    }
    
    private func showAgentDemo() {
        // Simulate agent control demo
        showDemo = true
        hapticService.triggerHaptic(.agentStart)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showDemo = false
            nextStep()
        }
    }
    
    private func showAnalyticsDemo() {
        // Simulate analytics demo
        showDemo = true
        hapticService.triggerHaptic(.dataRefresh)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showDemo = false
            nextStep()
        }
    }
    
    private func showSecurityDemo() {
        // Simulate security demo
        showDemo = true
        hapticService.triggerHaptic(.success)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showDemo = false
            nextStep()
        }
    }
}

// MARK: - Onboarding Step View

struct OnboardingStepView: View {
    let step: OnboardingStep
    let isCurrentStep: Bool
    let onPrimaryAction: () -> Void
    let onSecondaryAction: () -> Void
    
    @State private var imageScale: CGFloat = 0.8
    @State private var textOpacity: Double = 0.0
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Feature illustration
            VStack(spacing: 24) {
                Image(systemName: step.imageName)
                    .font(.system(size: 80, weight: .light))
                    .foregroundColor(.blue)
                    .scaleEffect(imageScale)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: imageScale)
                
                VStack(spacing: 12) {
                    Text(step.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text(step.subtitle)
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text(step.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .opacity(textOpacity)
                .animation(.easeInOut(duration: 0.5).delay(0.2), value: textOpacity)
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 16) {
                Button(action: onPrimaryAction) {
                    Text(step.primaryAction)
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(25)
                }
                .buttonStyle(PressableButtonStyle())
                
                if let secondaryAction = step.secondaryAction {
                    Button(action: onSecondaryAction) {
                        Text(secondaryAction)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 32)
        }
        .onChange(of: isCurrentStep) { isCurrent in
            if isCurrent {
                imageScale = 1.0
                textOpacity = 1.0
            } else {
                imageScale = 0.8
                textOpacity = 0.6
            }
        }
        .onAppear {
            if isCurrentStep {
                imageScale = 1.0
                textOpacity = 1.0
            }
        }
    }
}

// MARK: - Progress Bar Component

struct OnboardingProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    
    var progress: CGFloat {
        CGFloat(currentStep) / CGFloat(totalSteps - 1)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Step \(currentStep + 1) of \(totalSteps)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 32)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 4)
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - Navigation Controls

struct OnboardingNavigationControls: View {
    @Binding var currentStep: Int
    let totalSteps: Int
    let onSkip: () -> Void
    let onNext: () -> Void
    let onPrevious: () -> Void
    
    @Dependency(\.hapticService) var hapticService
    
    var body: some View {
        HStack {
            // Back button
            if currentStep > 0 {
                Button("Back") {
                    hapticService.triggerHaptic(.selection)
                    onPrevious()
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            } else {
                Button("Skip") {
                    hapticService.triggerHaptic(.selection)
                    onSkip()
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Next button
            if currentStep < totalSteps - 1 {
                Button("Next") {
                    hapticService.triggerHaptic(.buttonPress)
                    onNext()
                }
                .font(.headline)
                .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Pressable Button Style

struct PressableButtonStyle: ButtonStyle {
    @Dependency(\.hapticService) var hapticService
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { isPressed in
                if isPressed {
                    hapticService.triggerHaptic(.buttonPress)
                }
            }
    }
}

// MARK: - Onboarding Demo Views

struct AgentControlDemo: View {
    @State private var agentStatus: String = "Stopped"
    @State private var isAnimating: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Agent Control Demo")
                .font(.headline)
            
            HStack {
                Image(systemName: "cpu")
                    .font(.title)
                    .foregroundColor(agentStatus == "Running" ? .green : .red)
                
                VStack(alignment: .leading) {
                    Text("CLI Orchestrator")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("Status: \(agentStatus)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(agentStatus == "Running" ? "Stop" : "Start") {
                    withAnimation(.spring()) {
                        agentStatus = agentStatus == "Running" ? "Stopped" : "Running"
                        isAnimating = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isAnimating = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isAnimating)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .scaleEffect(isAnimating ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isAnimating)
        }
        .padding()
    }
}

struct AnalyticsDemo: View {
    @State private var dataPoints: [Double] = []
    @State private var isUpdating: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Analytics Demo")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("System Performance")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                // Mock chart with animated data
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(0..<8, id: \.self) { index in
                        let height = dataPoints.count > index ? CGFloat(dataPoints[index] * 50) : 20
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.blue.opacity(0.7))
                            .frame(width: 20, height: height)
                            .animation(.easeInOut(duration: 0.3).delay(Double(index) * 0.1), value: height)
                    }
                }
                .frame(height: 80)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("CPU Usage")
                        Text("45.2%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Memory")
                        Text("67.8%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .opacity(isUpdating ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: isUpdating)
        }
        .padding()
        .onAppear {
            generateMockData()
        }
    }
    
    private func generateMockData() {
        isUpdating = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dataPoints = (0..<8).map { _ in Double.random(in: 0.3...1.0) }
            isUpdating = false
        }
    }
}

struct SecurityDemo: View {
    @State private var isSecure: Bool = false
    @State private var authenticationStatus: String = "Not Authenticated"
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Security Demo")
                .font(.headline)
            
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: isSecure ? "lock.shield.fill" : "lock.open.fill")
                        .font(.title)
                        .foregroundColor(isSecure ? .green : .orange)
                    
                    VStack(alignment: .leading) {
                        Text("Security Status")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text(authenticationStatus)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                Button("Simulate Face ID") {
                    withAnimation(.spring()) {
                        isSecure.toggle()
                        authenticationStatus = isSecure ? "Face ID Authenticated" : "Not Authenticated"
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .padding()
    }
}

// MARK: - Onboarding Completion Check

extension UserDefaults {
    static var hasCompletedOnboarding: Bool {
        get {
            UserDefaults.standard.bool(forKey: "onboardingCompleted")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "onboardingCompleted")
        }
    }
}

// MARK: - Onboarding Wrapper View

struct OnboardingWrapper<Content: View>: View {
    @State private var showOnboarding = false
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        Group {
            if showOnboarding {
                OnboardingView {
                    showOnboarding = false
                }
            } else {
                content
            }
        }
        .onAppear {
            showOnboarding = !UserDefaults.hasCompletedOnboarding
        }
    }
}AHA moment
