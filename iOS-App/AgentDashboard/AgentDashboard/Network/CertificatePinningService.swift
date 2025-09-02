//
//  CertificatePinningService.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Certificate pinning service for secure API communication
//

import Foundation
import Network
import CommonCrypto

// MARK: - Certificate Pinning Service Protocol

protocol CertificatePinningServiceProtocol {
    /// Validate server certificate against pinned certificates
    func validateServerTrust(_ serverTrust: SecTrust, for host: String) -> Bool
    
    /// Add pinned certificate for host
    func addPinnedCertificate(_ certificate: Data, for host: String)
    
    /// Add pinned public key for host
    func addPinnedPublicKey(_ publicKey: Data, for host: String)
    
    /// Remove pinned data for host
    func removePinnedData(for host: String)
    
    /// Check if host has pinned certificates
    func hasPinnedCertificates(for host: String) -> Bool
}

// MARK: - Certificate Pinning Models

struct PinnedCertificate {
    let host: String
    let certificateData: Data
    let publicKeyData: Data?
    let addedDate: Date
    let expirationDate: Date?
    
    init(host: String, certificateData: Data, publicKeyData: Data? = nil, expirationDate: Date? = nil) {
        self.host = host
        self.certificateData = certificateData
        self.publicKeyData = publicKeyData
        self.addedDate = Date()
        self.expirationDate = expirationDate
    }
    
    var isExpired: Bool {
        guard let expirationDate = expirationDate else { return false }
        return Date() > expirationDate
    }
}

enum CertificatePinningError: Error, LocalizedError {
    case invalidCertificate
    case hostMismatch
    case certificateNotPinned
    case validationFailed
    case publicKeyExtractionFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidCertificate:
            return "Invalid certificate format"
        case .hostMismatch:
            return "Certificate host mismatch"
        case .certificateNotPinned:
            return "No pinned certificate for host"
        case .validationFailed:
            return "Certificate validation failed"
        case .publicKeyExtractionFailed:
            return "Failed to extract public key from certificate"
        }
    }
}

// MARK: - Production Certificate Pinning Service

final class CertificatePinningService: NSObject, CertificatePinningServiceProtocol {
    private var pinnedCertificates: [String: [PinnedCertificate]] = [:]
    private let logger = Logger(subsystem: "AgentDashboard", category: "CertificatePinning")
    private let queue = DispatchQueue(label: "certificate-pinning", qos: .utility)
    
    override init() {
        super.init()
        logger.info("CertificatePinningService initialized")
        loadDefaultPinnedCertificates()
    }
    
    private func loadDefaultPinnedCertificates() {
        // In production, load pinned certificates for your API endpoints
        // For localhost development, we'll skip certificate pinning
        logger.debug("Loading default pinned certificates (skipped for localhost)")
        
        // Example for production:
        // addPinnedCertificate(prodCertData, for: "api.unity-claude.com")
    }
    
    func validateServerTrust(_ serverTrust: SecTrust, for host: String) -> Bool {
        logger.debug("Validating server trust for host: \(host)")
        
        // Skip certificate pinning for localhost development
        if host.contains("localhost") || host.contains("127.0.0.1") {
            logger.debug("Skipping certificate pinning for localhost development")
            return validateStandardTrust(serverTrust)
        }
        
        // Check if we have pinned certificates for this host
        guard let pinnedCerts = pinnedCertificates[host], !pinnedCerts.isEmpty else {
            logger.warning("No pinned certificates found for host: \(host)")
            // Fallback to standard validation for now
            return validateStandardTrust(serverTrust)
        }
        
        // Get server certificate chain
        let serverCertCount = SecTrustGetCertificateCount(serverTrust)
        guard serverCertCount > 0 else {
            logger.error("No server certificates found in trust chain")
            return false
        }
        
        // Validate against pinned certificates
        for pinnedCert in pinnedCerts {
            if pinnedCert.isExpired {
                logger.warning("Skipping expired pinned certificate for host: \(host)")
                continue
            }
            
            // Check each certificate in the server chain
            for i in 0..<serverCertCount {
                if let serverCert = SecTrustGetCertificateAtIndex(serverTrust, i) {
                    let serverCertData = SecCertificateCopyData(serverCert)
                    
                    if CFEqual(serverCertData, pinnedCert.certificateData as CFData) {
                        logger.info("Certificate pinning validation successful for host: \(host)")
                        return true
                    }
                    
                    // Also check public key if available
                    if let pinnedPublicKey = pinnedCert.publicKeyData,
                       let serverPublicKey = extractPublicKey(from: serverCert) {
                        if serverPublicKey == pinnedPublicKey {
                            logger.info("Public key pinning validation successful for host: \(host)")
                            return true
                        }
                    }
                }
            }
        }
        
        logger.error("Certificate pinning validation failed for host: \(host)")
        return false
    }
    
    func addPinnedCertificate(_ certificate: Data, for host: String) {
        logger.info("Adding pinned certificate for host: \(host)")
        
        queue.async {
            let pinnedCert = PinnedCertificate(host: host, certificateData: certificate)
            
            if self.pinnedCertificates[host] == nil {
                self.pinnedCertificates[host] = []
            }
            
            self.pinnedCertificates[host]?.append(pinnedCert)
            self.logger.debug("Pinned certificate added for host: \(host)")
        }
    }
    
    func addPinnedPublicKey(_ publicKey: Data, for host: String) {
        logger.info("Adding pinned public key for host: \(host)")
        
        queue.async {
            let pinnedCert = PinnedCertificate(host: host, certificateData: Data(), publicKeyData: publicKey)
            
            if self.pinnedCertificates[host] == nil {
                self.pinnedCertificates[host] = []
            }
            
            self.pinnedCertificates[host]?.append(pinnedCert)
            self.logger.debug("Pinned public key added for host: \(host)")
        }
    }
    
    func removePinnedData(for host: String) {
        logger.info("Removing pinned data for host: \(host)")
        
        queue.async {
            self.pinnedCertificates.removeValue(forKey: host)
            self.logger.debug("Pinned data removed for host: \(host)")
        }
    }
    
    func hasPinnedCertificates(for host: String) -> Bool {
        let hasCerts = pinnedCertificates[host]?.isEmpty == false
        logger.debug("Host \(host) has pinned certificates: \(hasCerts)")
        return hasCerts
    }
    
    // MARK: - Private Helper Methods
    
    private func validateStandardTrust(_ serverTrust: SecTrust) -> Bool {
        var result: SecTrustResultType = .invalid
        let status = SecTrustEvaluate(serverTrust, &result)
        
        if status == errSecSuccess {
            let isValid = result == .unspecified || result == .proceed
            logger.debug("Standard trust validation: \(isValid)")
            return isValid
        } else {
            logger.error("Standard trust evaluation failed with status: \(status)")
            return false
        }
    }
    
    private func extractPublicKey(from certificate: SecCertificate) -> Data? {
        var trust: SecTrust?
        let policy = SecPolicyCreateBasicX509()
        
        let status = SecTrustCreateWithCertificates(certificate, policy, &trust)
        guard status == errSecSuccess, let validTrust = trust else {
            logger.error("Failed to create trust for public key extraction")
            return nil
        }
        
        guard let publicKey = SecTrustCopyPublicKey(validTrust) else {
            logger.error("Failed to extract public key from certificate")
            return nil
        }
        
        var error: Unmanaged<CFError>?
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) else {
            logger.error("Failed to get external representation of public key")
            return nil
        }
        
        return publicKeyData as Data
    }
}

// MARK: - Mock Certificate Pinning Service

final class MockCertificatePinningService: CertificatePinningServiceProtocol {
    private let logger = Logger(subsystem: "AgentDashboard", category: "MockCertificatePinning")
    private var shouldValidate: Bool
    
    init(shouldValidate: Bool = true) {
        self.shouldValidate = shouldValidate
        logger.info("MockCertificatePinningService initialized - Validation: \(shouldValidate)")
    }
    
    func validateServerTrust(_ serverTrust: SecTrust, for host: String) -> Bool {
        logger.debug("Mock certificate validation for host: \(host) - Result: \(shouldValidate)")
        return shouldValidate
    }
    
    func addPinnedCertificate(_ certificate: Data, for host: String) {
        logger.debug("Mock adding pinned certificate for host: \(host)")
    }
    
    func addPinnedPublicKey(_ publicKey: Data, for host: String) {
        logger.debug("Mock adding pinned public key for host: \(host)")
    }
    
    func removePinnedData(for host: String) {
        logger.debug("Mock removing pinned data for host: \(host)")
    }
    
    func hasPinnedCertificates(for host: String) -> Bool {
        logger.debug("Mock pinned certificate check for host: \(host)")
        return shouldValidate
    }
}

// MARK: - Dependency Registration

private enum CertificatePinningKey: DependencyKey {
    static let liveValue: CertificatePinningServiceProtocol = CertificatePinningService()
    static let testValue: CertificatePinningServiceProtocol = MockCertificatePinningService()
    static let previewValue: CertificatePinningServiceProtocol = MockCertificatePinningService()
}

extension DependencyValues {
    var certificatePinning: CertificatePinningServiceProtocol {
        get { self[CertificatePinningKey.self] }
        set { self[CertificatePinningKey.self] = newValue }
    }
}URLSessionDelegate
