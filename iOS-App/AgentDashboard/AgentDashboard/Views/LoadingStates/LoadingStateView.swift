//
//  LoadingStateView.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Enhanced loading states with skeleton screens and shimmer effects
//

import SwiftUI

// MARK: - Loading State Types

enum LoadingState: Equatable {
    case idle
    case loading(String?)
    case success(String?)
    case error(String)
    case skeleton
    
    var isLoading: Bool {
        switch self {
        case .loading, .skeleton:
            return true
        default:
            return false
        }
    }
    
    var message: String? {
        switch self {
        case .loading(let message):
            return message
        case .success(let message):
            return message
        case .error(let message):
            return message
        default:
            return nil
        }
    }
}

// MARK: - Enhanced Loading View

struct EnhancedLoadingView: View {
    let state: LoadingState
    let style: LoadingStyle
    
    init(state: LoadingState, style: LoadingStyle = .modern) {
        self.state = state
        self.style = style
    }
    
    var body: some View {
        Group {
            switch state {
            case .idle:
                EmptyView()
                
            case .loading(let message):
                LoadingSpinnerView(message: message, style: style)
                
            case .success(let message):
                SuccessStateView(message: message)
                
            case .error(let message):
                ErrorStateView(message: message)
                
            case .skeleton:
                SkeletonLoadingView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: state)
    }
}

enum LoadingStyle {
    case minimal
    case modern
    case sophisticated
    case playful
    
    var primaryColor: Color {
        switch self {
        case .minimal:
            return .gray
        case .modern:
            return .blue
        case .sophisticated:
            return .purple
        case .playful:
            return .orange
        }
    }
    
    var animationDuration: Double {
        switch self {
        case .minimal:
            return 1.0
        case .modern:
            return 0.8
        case .sophisticated:
            return 1.2
        case .playful:
            return 0.6
        }
    }
}

// MARK: - Loading Spinner Component

struct LoadingSpinnerView: View {
    let message: String?
    let style: LoadingStyle
    
    @State private var rotationAngle: Double = 0
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(style.primaryColor.opacity(0.2), lineWidth: 3)
                    .frame(width: 48, height: 48)
                
                // Animated arc
                Circle()
                    .trim(from: 0, to: 0.25)
                    .stroke(
                        style.primaryColor,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 48, height: 48)
                    .rotationEffect(.degrees(rotationAngle))
                    .scaleEffect(scale)
            }
            .onAppear {
                withAnimation(.linear(duration: style.animationDuration).repeatForever(autoreverses: false)) {
                    rotationAngle = 360
                }
                
                if style == .playful {
                    withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                        scale = 1.1
                    }
                }
            }
            
            if let message = message {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground).opacity(0.9))
    }
}

// MARK: - Success State View

struct SuccessStateView: View {
    let message: String?
    @State private var checkmarkScale: CGFloat = 0
    @State private var checkmarkOpacity: Double = 0
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.green)
                    .scaleEffect(checkmarkScale)
                    .opacity(checkmarkOpacity)
            }
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    checkmarkScale = 1.0
                    checkmarkOpacity = 1.0
                }
            }
            
            if let message = message {
                Text(message)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}

// MARK: - Error State View

struct ErrorStateView: View {
    let message: String
    @State private var shakeOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.red)
            }
            .offset(x: shakeOffset)
            .onAppear {
                // Shake animation for error emphasis
                withAnimation(.spring(response: 0.1, dampingFraction: 0.3)) {
                    shakeOffset = 5
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.1, dampingFraction: 0.3)) {
                        shakeOffset = -5
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.1, dampingFraction: 0.8)) {
                        shakeOffset = 0
                    }
                }
            }
            
            Text(message)
                .font(.headline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Skeleton Loading Component

struct SkeletonLoadingView: View {
    @State private var shimmerOffset: CGFloat = -200
    
    var body: some View {
        VStack(spacing: 12) {
            // Skeleton for agent cards
            ForEach(0..<3, id: \.self) { _ in
                SkeletonCard()
            }
            
            // Skeleton for chart area
            SkeletonChart()
        }
        .padding()
    }
}

struct SkeletonCard: View {
    var body: some View {
        HStack(spacing: 12) {
            // Avatar skeleton
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay(ShimmerOverlay())
            
            VStack(alignment: .leading, spacing: 6) {
                // Title skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(ShimmerOverlay())
                
                // Subtitle skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 12)
                    .overlay(ShimmerOverlay())
            }
            
            Spacer()
            
            // Status indicator skeleton
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 12, height: 12)
                .overlay(ShimmerOverlay())
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SkeletonChart: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Chart title skeleton
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 150, height: 20)
                .overlay(ShimmerOverlay())
            
            // Chart area skeleton
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 200)
                .overlay(ShimmerOverlay())
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ShimmerOverlay: View {
    @State private var shimmerOffset: CGFloat = -200
    
    var body: some View {
        LinearGradient(
            colors: [
                Color.white.opacity(0.0),
                Color.white.opacity(0.4),
                Color.white.opacity(0.0)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .offset(x: shimmerOffset)
        .mask(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.black)
        )
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                shimmerOffset = 200
            }
        }
    }
}

// MARK: - Custom Loading State Modifier

extension View {
    func loadingState(_ state: LoadingState, style: LoadingStyle = .modern) -> some View {
        ZStack {
            self
                .disabled(state.isLoading)
                .blur(radius: state.isLoading ? 2 : 0)
            
            if state.isLoading {
                EnhancedLoadingView(state: state, style: style)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: state.isLoading)
    }
    
    func skeletonLoading(isLoading: Bool) -> some View {
        ZStack {
            if isLoading {
                self
                    .redacted(reason: .placeholder)
                    .overlay(ShimmerOverlay())
            } else {
                self
            }
        }
    }
}