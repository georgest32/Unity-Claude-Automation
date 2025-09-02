import ComposableArchitecture
import Foundation

// MARK: - Authentication Client

@DependencyClient
public struct AuthenticationClient {
    public var authenticate: @Sendable () async throws -> User
    public var logout: @Sendable () async throws -> Void
    public var isAuthenticated: @Sendable () async -> Bool
    public var getCurrentUser: @Sendable () async -> User?
}

extension AuthenticationClient: DependencyKey {
    public static let liveValue = AuthenticationClient(
        authenticate: {
            // Simulate authentication with biometric/PIN
            try await Task.sleep(for: .milliseconds(500))
            
            // For demo purposes, always succeed with a mock user
            return User(
                id: "user-001",
                username: "Developer",
                email: "dev@unity-claude-automation.com",
                roles: ["admin", "developer"],
                token: "mock-jwt-token-\(UUID().uuidString)"
            )
        },
        logout: {
            // Clear any stored credentials
            try await Task.sleep(for: .milliseconds(250))
        },
        isAuthenticated: {
            // Check if user is currently authenticated
            // For demo, return true after first authentication
            return true
        },
        getCurrentUser: {
            // Return current user if authenticated
            return User(
                id: "user-001",
                username: "Developer",
                email: "dev@unity-claude-automation.com",
                roles: ["admin", "developer"],
                token: "mock-jwt-token"
            )
        }
    )
    
    public static let testValue = AuthenticationClient(
        authenticate: { 
            User(id: "test", username: "Test User", email: "test@example.com", roles: ["user"])
        },
        logout: {},
        isAuthenticated: { false },
        getCurrentUser: { nil }
    )
}

extension DependencyValues {
    public var authenticationClient: AuthenticationClient {
        get { self[AuthenticationClient.self] }
        set { self[AuthenticationClient.self] = newValue }
    }
}