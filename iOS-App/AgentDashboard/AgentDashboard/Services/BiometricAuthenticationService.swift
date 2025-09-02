//
//  BiometricAuthenticationService.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Biometric authentication service using LocalAuthentication framework
//

import Foundation
import LocalAuthentication
import SwiftUI
import Dependencies

// MARK: - Biometric Authentication Service Protocol

protocol BiometricAuthenticationServiceProtocol {
    /// Check if biometric authentication is available on device
    func isBiometricAuthenticationAvailable() -> BiometricAvailability
    
    /// Authenticate user with biometrics or device passcode
    func authenticateUser(reason: String) async -> BiometricAuthResult
    
    /// Check specific biometric type available
    func getBiometricType() -> BiometricType
    
    /// Evaluate policy without authentication (check availability)
    func canEvaluatePolicy() -> Bool
}

// MARK: - Biometric Models

enum BiometricAvailability {
    case available(BiometricType)
    case notAvailable(LAError.Code)
    case notConfigured
    case unknown
    
    var isAvailable: Bool {
        switch self {
        case .available:
            return true
        default:
            return false
        }
    }
    
    var description: String {
        switch self {
        case .available(let type):
            return "\(type.displayName) is available"
        case .notAvailable(let error):
            return "Biometrics not available: \(error.localizedDescription)"
        case .notConfigured:
            return "Biometrics not configured on this device"
        case .unknown:
            return "Biometric availability unknown"
        }
    }
}

enum BiometricType {
    case faceID
    case touchID
    case opticID
    case none
    
    var displayName: String {
        switch self {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        case .none:
            return "No Biometrics"
        }
    }
    
    var icon: String {
        switch self {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        case .none:
            return "person.badge.key"
        }
    }
}

struct BiometricAuthResult {
    let success: Bool
    let error: LAError?
    let authenticationTime: TimeInterval
    let authenticationMethod: String
    
    init(success: Bool, error: LAError? = nil, authenticationTime: TimeInterval, authenticationMethod: String = "biometric") {
        self.success = success
        self.error = error
        self.authenticationTime = authenticationTime
        self.authenticationMethod = authenticationMethod
    }
    
    var errorDescription: String? {
        return error?.localizedDescription
    }
    
    var detailedError: String? {
        guard let error = error else { return nil }
        
        switch error.code {
        case .userCancel:
            return "User cancelled authentication"
        case .userFallback:
            return "User chose to enter passcode"
        case .systemCancel:
            return "Authentication cancelled by system"
        case .passcodeNotSet:
            return "Device passcode not set"
        case .biometryNotAvailable:
            return "Biometric authentication not available"
        case .biometryNotEnrolled:
            return "No biometric data enrolled"
        case .biometryLockout:
            return "Biometric authentication locked out"
        case .appCancel:
            return "Authentication cancelled by app"
        case .invalidContext:
            return "Invalid authentication context"
        case .notInteractive:
            return "Authentication not interactive"
        default:
            return error.localizedDescription
        }
    }
}

// MARK: - Production Biometric Authentication Service

final class BiometricAuthenticationService: BiometricAuthenticationServiceProtocol {
    private let logger: Logger
    
    init(logger: Logger = Logger(subsystem: "AgentDashboard", category: "BiometricAuth")) {
        self.logger = logger
        logger.info("BiometricAuthenticationService initialized")
    }
    
    func isBiometricAuthenticationAvailable() -> BiometricAvailability {
        let context = LAContext()
        var error: NSError?
        
        logger.debug("Checking biometric authentication availability")
        
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
        
        if canEvaluate {
            let biometricType = getBiometricType()
            logger.info("Biometric authentication available: \(biometricType.displayName)")
            return .available(biometricType)
        } else if let laError = error as? LAError {
            logger.warning("Biometric authentication not available: \(laError.localizedDescription)")
            return .notAvailable(laError.code)
        } else {
            logger.warning("Biometric authentication availability unknown")
            return .unknown
        }
    }
    
    func getBiometricType() -> BiometricType {
        let context = LAContext()
        
        switch context.biometryType {
        case .faceID:
            logger.debug("Device supports Face ID")
            return .faceID
        case .touchID:
            logger.debug("Device supports Touch ID")
            return .touchID
        case .opticID:
            logger.debug("Device supports Optic ID")
            return .opticID
        case .none:
            logger.debug("Device does not support biometrics")
            return .none
        @unknown default:
            logger.debug("Unknown biometric type")
            return .none
        }
    }
    
    func canEvaluatePolicy() -> Bool {
        let context = LAContext()
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        
        logger.debug("Can evaluate authentication policy: \(canEvaluate)")
        return canEvaluate
    }
    
    func authenticateUser(reason: String) async -> BiometricAuthResult {
        let startTime = Date()
        logger.info("Starting biometric authentication with reason: \(reason)")
        
        let context = LAContext()
        
        // Configure context
        context.localizedFallbackTitle = "Enter Passcode"
        context.localizedCancelTitle = "Cancel"
        
        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
            let authTime = Date().timeIntervalSince(startTime)
            
            if success {
                logger.info("Biometric authentication successful in \(String(format: "%.2f", authTime))s")
                return BiometricAuthResult(
                    success: true,
                    authenticationTime: authTime,
                    authenticationMethod: getBiometricType().displayName
                )
            } else {
                logger.warning("Biometric authentication failed")
                return BiometricAuthResult(
                    success: false,
                    authenticationTime: authTime,
                    authenticationMethod: "failed"
                )
            }
        } catch let error as LAError {
            let authTime = Date().timeIntervalSince(startTime)
            logger.error("Biometric authentication error: \(error.localizedDescription)")
            
            return BiometricAuthResult(
                success: false,
                error: error,
                authenticationTime: authTime,
                authenticationMethod: "error"
            )
        } catch {
            let authTime = Date().timeIntervalSince(startTime)
            logger.error("Unexpected authentication error: \(error.localizedDescription)")
            
            return BiometricAuthResult(
                success: false,
                authenticationTime: authTime,
                authenticationMethod: "unexpected_error"
            )
        }
    }
}

// MARK: - Mock Biometric Authentication Service

final class MockBiometricAuthenticationService: BiometricAuthenticationServiceProtocol {
    private let logger: Logger
    private let shouldSucceed: Bool
    private let simulatedBiometricType: BiometricType
    
    init(shouldSucceed: Bool = true, biometricType: BiometricType = .faceID) {
        self.shouldSucceed = shouldSucceed
        self.simulatedBiometricType = biometricType
        self.logger = Logger(subsystem: "AgentDashboard", category: "MockBiometricAuth")
        logger.info("MockBiometricAuthenticationService initialized - Success: \(shouldSucceed), Type: \(biometricType.displayName)")
    }
    
    func isBiometricAuthenticationAvailable() -> BiometricAvailability {
        logger.debug("Mock biometric availability check")
        return .available(simulatedBiometricType)
    }
    
    func getBiometricType() -> BiometricType {
        logger.debug("Mock biometric type: \(simulatedBiometricType.displayName)")
        return simulatedBiometricType
    }
    
    func canEvaluatePolicy() -> Bool {
        logger.debug("Mock policy evaluation: true")
        return true
    }
    
    func authenticateUser(reason: String) async -> BiometricAuthResult {
        logger.info("Mock biometric authentication - Reason: \(reason)")
        
        // Simulate authentication delay
        try? await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
        
        if shouldSucceed {
            logger.info("Mock biometric authentication successful")
            return BiometricAuthResult(
                success: true,
                authenticationTime: 0.8,
                authenticationMethod: simulatedBiometricType.displayName
            )
        } else {
            logger.warning("Mock biometric authentication failed")
            let mockError = LAError(.userCancel)
            return BiometricAuthResult(
                success: false,
                error: mockError,
                authenticationTime: 0.8,
                authenticationMethod: "cancelled"
            )
        }
    }
}

// MARK: - Dependency Registration

private enum BiometricAuthKey: DependencyKey {
    static let liveValue: BiometricAuthenticationServiceProtocol = BiometricAuthenticationService()
    static let testValue: BiometricAuthenticationServiceProtocol = MockBiometricAuthenticationService()
    static let previewValue: BiometricAuthenticationServiceProtocol = MockBiometricAuthenticationService()
}

extension DependencyValues {
    var biometricAuth: BiometricAuthenticationServiceProtocol {
        get { self[BiometricAuthKey.self] }
        set { self[BiometricAuthKey.self] = newValue }
    }
}

// MARK: - SwiftUI Integration Helper

@MainActor
class BiometricAuthManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var authenticationError: String?
    @Published var biometricType: BiometricType = .none
    @Published var isAuthenticating: Bool = false
    
    private let biometricService: BiometricAuthenticationServiceProtocol
    private let logger = Logger(subsystem: "AgentDashboard", category: "BiometricAuthManager")
    
    init(biometricService: BiometricAuthenticationServiceProtocol = BiometricAuthenticationService()) {
        self.biometricService = biometricService
        updateBiometricType()
        logger.info("BiometricAuthManager initialized")
    }
    
    func updateBiometricType() {
        biometricType = biometricService.getBiometricType()
        logger.debug("Biometric type updated: \(biometricType.displayName)")
    }
    
    func requestAuthentication(reason: String = "Authenticate to access secure features") async {
        logger.info("Requesting biometric authentication")
        
        await MainActor.run {
            isAuthenticating = true
            authenticationError = nil
        }
        
        let result = await biometricService.authenticateUser(reason: reason)
        
        await MainActor.run {
            isAuthenticating = false
            isAuthenticated = result.success
            
            if !result.success {
                authenticationError = result.detailedError
                logger.warning("Authentication failed: \(result.detailedError ?? "Unknown error")")
            } else {
                authenticationError = nil
                logger.info("Authentication successful via \(result.authenticationMethod)")
            }
        }
    }
    
    func logout() {
        logger.info("User logout - clearing authentication state")
        isAuthenticated = false
        authenticationError = nil
    }
    
    var canUseBiometrics: Bool {
        biometricService.isBiometricAuthenticationAvailable().isAvailable
    }
}