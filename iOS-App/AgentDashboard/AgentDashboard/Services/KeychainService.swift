//
//  KeychainService.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Secure storage service using iOS Keychain Services
//

import Foundation
import Security
import ComposableArchitecture

// MARK: - Keychain Service Protocol

protocol KeychainServiceProtocol {
    /// Store data securely in keychain
    func store(_ data: Data, for account: String, service: String) -> Bool
    
    /// Retrieve data from keychain
    func retrieve(for account: String, service: String) -> Data?
    
    /// Delete data from keychain
    func delete(for account: String, service: String) -> Bool
    
    /// Store string securely in keychain
    func storeString(_ string: String, for account: String, service: String) -> Bool
    
    /// Retrieve string from keychain
    func retrieveString(for account: String, service: String) -> String?
    
    /// Store JWT token securely
    func storeJWTToken(_ token: String, for username: String) -> Bool
    
    /// Retrieve JWT token
    func retrieveJWTToken(for username: String) -> String?
    
    /// Store refresh token securely
    func storeRefreshToken(_ token: String, for username: String) -> Bool
    
    /// Retrieve refresh token
    func retrieveRefreshToken(for username: String) -> String?
    
    /// Clear all authentication tokens
    func clearAuthenticationTokens(for username: String) -> Bool
    
    /// Check if user has stored credentials
    func hasStoredCredentials(for username: String) -> Bool
}

// MARK: - Keychain Error Types

enum KeychainError: Error, LocalizedError {
    case duplicateItem
    case itemNotFound
    case invalidData
    case unexpectedStatus(OSStatus)
    case stringEncodingFailed
    
    var errorDescription: String? {
        switch self {
        case .duplicateItem:
            return "Keychain item already exists"
        case .itemNotFound:
            return "Keychain item not found"
        case .invalidData:
            return "Invalid data format"
        case .unexpectedStatus(let status):
            return "Unexpected keychain status: \(status)"
        case .stringEncodingFailed:
            return "String encoding failed"
        }
    }
}

// MARK: - Production Keychain Service

final class KeychainService: KeychainServiceProtocol {
    private let logger = Logger(subsystem: "AgentDashboard", category: "KeychainService")
    
    // Service identifiers for different types of data
    private let jwtTokenService = "com.unity-claude.agentdashboard.jwt"
    private let refreshTokenService = "com.unity-claude.agentdashboard.refresh"
    private let credentialsService = "com.unity-claude.agentdashboard.credentials"
    
    init() {
        logger.info("KeychainService initialized with secure storage capabilities")
    }
    
    // MARK: - Core Keychain Operations
    
    func store(_ data: Data, for account: String, service: String) -> Bool {
        logger.debug("Storing data in keychain - Account: \(account), Service: \(service), Size: \(data.count) bytes")
        
        // First, try to update existing item
        let updateQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service
        ]
        
        let updateAttributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        let updateStatus = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
        
        if updateStatus == errSecSuccess {
            logger.debug("Successfully updated existing keychain item")
            return true
        } else if updateStatus == errSecItemNotFound {
            // Item doesn't exist, create new one
            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: account,
                kSecAttrService as String: service,
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
            ]
            
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            
            if addStatus == errSecSuccess {
                logger.info("Successfully stored new keychain item")
                return true
            } else {
                logger.error("Failed to store keychain item - Status: \(addStatus)")
                return false
            }
        } else {
            logger.error("Failed to update keychain item - Status: \(updateStatus)")
            return false
        }
    }
    
    func retrieve(for account: String, service: String) -> Data? {
        logger.debug("Retrieving data from keychain - Account: \(account), Service: \(service)")
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            if let data = result as? Data {
                logger.debug("Successfully retrieved keychain data - Size: \(data.count) bytes")
                return data
            } else {
                logger.error("Retrieved keychain item is not Data type")
                return nil
            }
        } else if status == errSecItemNotFound {
            logger.debug("Keychain item not found")
            return nil
        } else {
            logger.error("Failed to retrieve keychain item - Status: \(status)")
            return nil
        }
    }
    
    func delete(for account: String, service: String) -> Bool {
        logger.debug("Deleting keychain item - Account: \(account), Service: \(service)")
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess || status == errSecItemNotFound {
            logger.info("Successfully deleted keychain item (or item didn't exist)")
            return true
        } else {
            logger.error("Failed to delete keychain item - Status: \(status)")
            return false
        }
    }
    
    // MARK: - String Convenience Methods
    
    func storeString(_ string: String, for account: String, service: String) -> Bool {
        guard let data = string.data(using: .utf8) else {
            logger.error("Failed to encode string to UTF-8 data")
            return false
        }
        
        return store(data, for: account, service: service)
    }
    
    func retrieveString(for account: String, service: String) -> String? {
        guard let data = retrieve(for: account, service: service) else {
            return nil
        }
        
        guard let string = String(data: data, encoding: .utf8) else {
            logger.error("Failed to decode keychain data to UTF-8 string")
            return nil
        }
        
        return string
    }
    
    // MARK: - Authentication Token Methods
    
    func storeJWTToken(_ token: String, for username: String) -> Bool {
        logger.info("Storing JWT token for user: \(username)")
        let success = storeString(token, for: username, service: jwtTokenService)
        
        if success {
            logger.info("JWT token stored successfully for user: \(username)")
        } else {
            logger.error("Failed to store JWT token for user: \(username)")
        }
        
        return success
    }
    
    func retrieveJWTToken(for username: String) -> String? {
        logger.debug("Retrieving JWT token for user: \(username)")
        let token = retrieveString(for: username, service: jwtTokenService)
        
        if token != nil {
            logger.debug("JWT token retrieved for user: \(username)")
        } else {
            logger.debug("No JWT token found for user: \(username)")
        }
        
        return token
    }
    
    func storeRefreshToken(_ token: String, for username: String) -> Bool {
        logger.info("Storing refresh token for user: \(username)")
        let success = storeString(token, for: username, service: refreshTokenService)
        
        if success {
            logger.info("Refresh token stored successfully for user: \(username)")
        } else {
            logger.error("Failed to store refresh token for user: \(username)")
        }
        
        return success
    }
    
    func retrieveRefreshToken(for username: String) -> String? {
        logger.debug("Retrieving refresh token for user: \(username)")
        let token = retrieveString(for: username, service: refreshTokenService)
        
        if token != nil {
            logger.debug("Refresh token retrieved for user: \(username)")
        } else {
            logger.debug("No refresh token found for user: \(username)")
        }
        
        return token
    }
    
    func clearAuthenticationTokens(for username: String) -> Bool {
        logger.info("Clearing all authentication tokens for user: \(username)")
        
        let jwtDeleted = delete(for: username, service: jwtTokenService)
        let refreshDeleted = delete(for: username, service: refreshTokenService)
        
        let success = jwtDeleted && refreshDeleted
        
        if success {
            logger.info("All authentication tokens cleared for user: \(username)")
        } else {
            logger.warning("Some authentication tokens may not have been cleared for user: \(username)")
        }
        
        return success
    }
    
    func hasStoredCredentials(for username: String) -> Bool {
        let hasJWT = retrieveJWTToken(for: username) != nil
        let hasRefresh = retrieveRefreshToken(for: username) != nil
        
        logger.debug("Credential check for user \(username) - JWT: \(hasJWT), Refresh: \(hasRefresh)")
        
        return hasJWT || hasRefresh
    }
}

// MARK: - Mock Keychain Service

final class MockKeychainService: KeychainServiceProtocol {
    private var storage: [String: Data] = [:]
    private let logger = Logger(subsystem: "AgentDashboard", category: "MockKeychain")
    
    init() {
        logger.info("MockKeychainService initialized with in-memory storage")
    }
    
    private func key(for account: String, service: String) -> String {
        return "\(service):\(account)"
    }
    
    func store(_ data: Data, for account: String, service: String) -> Bool {
        let storageKey = key(for: account, service: service)
        storage[storageKey] = data
        logger.debug("Mock stored data - Key: \(storageKey), Size: \(data.count) bytes")
        return true
    }
    
    func retrieve(for account: String, service: String) -> Data? {
        let storageKey = key(for: account, service: service)
        let data = storage[storageKey]
        logger.debug("Mock retrieved data - Key: \(storageKey), Found: \(data != nil)")
        return data
    }
    
    func delete(for account: String, service: String) -> Bool {
        let storageKey = key(for: account, service: service)
        let existed = storage.removeValue(forKey: storageKey) != nil
        logger.debug("Mock deleted data - Key: \(storageKey), Existed: \(existed)")
        return true
    }
    
    func storeString(_ string: String, for account: String, service: String) -> Bool {
        guard let data = string.data(using: .utf8) else { return false }
        return store(data, for: account, service: service)
    }
    
    func retrieveString(for account: String, service: String) -> String? {
        guard let data = retrieve(for: account, service: service) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    func storeJWTToken(_ token: String, for username: String) -> Bool {
        logger.info("Mock storing JWT token for user: \(username)")
        return storeString(token, for: username, service: "jwt")
    }
    
    func retrieveJWTToken(for username: String) -> String? {
        logger.debug("Mock retrieving JWT token for user: \(username)")
        return retrieveString(for: username, service: "jwt")
    }
    
    func storeRefreshToken(_ token: String, for username: String) -> Bool {
        logger.info("Mock storing refresh token for user: \(username)")
        return storeString(token, for: username, service: "refresh")
    }
    
    func retrieveRefreshToken(for username: String) -> String? {
        logger.debug("Mock retrieving refresh token for user: \(username)")
        return retrieveString(for: username, service: "refresh")
    }
    
    func clearAuthenticationTokens(for username: String) -> Bool {
        logger.info("Mock clearing authentication tokens for user: \(username)")
        let jwtCleared = delete(for: username, service: "jwt")
        let refreshCleared = delete(for: username, service: "refresh")
        return jwtCleared && refreshCleared
    }
    
    func hasStoredCredentials(for username: String) -> Bool {
        let hasJWT = retrieveJWTToken(for: username) != nil
        let hasRefresh = retrieveRefreshToken(for: username) != nil
        return hasJWT || hasRefresh
    }
}

// MARK: - Dependency Registration

private enum KeychainServiceKey: DependencyKey {
    static let liveValue: KeychainServiceProtocol = KeychainService()
    static let testValue: KeychainServiceProtocol = MockKeychainService()
    static let previewValue: KeychainServiceProtocol = MockKeychainService()
}

extension DependencyValues {
    var keychainService: KeychainServiceProtocol {
        get { self[KeychainServiceKey.self] }
        set { self[KeychainServiceKey.self] = newValue }
    }
}