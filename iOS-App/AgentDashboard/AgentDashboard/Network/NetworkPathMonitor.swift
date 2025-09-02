//
//  NetworkPathMonitor.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Network reachability monitoring using NWPathMonitor for connection quality detection
//

import Foundation
import Network
import Combine

// MARK: - Network Path Monitor Protocol

protocol NetworkPathMonitorProtocol {
    func startMonitoring()
    func stopMonitoring()
    var networkStatus: NetworkStatus { get async }
    var networkStatusPublisher: AnyPublisher<NetworkStatus, Never> { get }
}

// MARK: - Network Status

struct NetworkStatus: Equatable {
    let isConnected: Bool
    let connectionType: ConnectionType
    let isExpensive: Bool
    let isConstrained: Bool
    let availableInterfaces: [InterfaceType]
    let timestamp: Date
    
    enum ConnectionType: String, CaseIterable {
        case wifi = "WiFi"
        case cellular = "Cellular"
        case ethernet = "Ethernet"
        case other = "Other"
        case none = "None"
        
        var priority: Int {
            switch self {
            case .ethernet: return 4
            case .wifi: return 3
            case .cellular: return 2
            case .other: return 1
            case .none: return 0
            }
        }
    }
    
    enum InterfaceType: String, CaseIterable {
        case wifi
        case cellular
        case wiredEthernet
        case loopback
        case other
        
        static func from(_ nwInterface: NWInterface.InterfaceType) -> InterfaceType {
            switch nwInterface {
            case .wifi: return .wifi
            case .cellular: return .cellular
            case .wiredEthernet: return .wiredEthernet
            case .loopback: return .loopback
            case .other: return .other
            @unknown default: return .other
            }
        }
    }
    
    var qualityScore: Double {
        var score: Double = 0
        
        // Base score from connection type
        score += Double(connectionType.priority) * 20
        
        // Penalty for expensive connections
        if isExpensive {
            score -= 15
        }
        
        // Penalty for constrained connections  
        if isConstrained {
            score -= 10
        }
        
        // Bonus for multiple interfaces
        score += Double(availableInterfaces.count) * 5
        
        return max(0, min(100, score))
    }
    
    var isOptimal: Bool {
        return isConnected && connectionType == .wifi && !isExpensive && !isConstrained
    }
    
    var description: String {
        if !isConnected {
            return "No Connection"
        }
        
        var desc = connectionType.rawValue
        
        if isExpensive {
            desc += " (Expensive)"
        }
        
        if isConstrained {
            desc += " (Constrained)"
        }
        
        return desc
    }
}

// MARK: - Network Path Monitor Implementation

final class NetworkPathMonitor: NetworkPathMonitorProtocol {
    
    // Core monitoring
    private let pathMonitor: NWPathMonitor
    private let monitorQueue: DispatchQueue
    
    // State
    private var _networkStatus: NetworkStatus
    private let networkStatusSubject = CurrentValueSubject<NetworkStatus, Never>(
        NetworkStatus(
            isConnected: false,
            connectionType: .none,
            isExpensive: false,
            isConstrained: false,
            availableInterfaces: [],
            timestamp: Date()
        )
    )
    
    // Configuration
    private let updateDebounceInterval: TimeInterval = 0.5
    private var debounceTimer: Timer?
    
    // Metrics
    private var pathMonitorMetrics = PathMonitorMetrics()
    
    init() {
        self.pathMonitor = NWPathMonitor()
        self.monitorQueue = DispatchQueue(label: "com.agentdashboard.network.monitor", qos: .utility)
        self._networkStatus = NetworkStatus(
            isConnected: false,
            connectionType: .none,
            isExpensive: false,
            isConstrained: false,
            availableInterfaces: [],
            timestamp: Date()
        )
        
        print("[NetworkPathMonitor] Initialized")
        
        setupPathUpdateHandler()
    }
    
    deinit {
        stopMonitoring()
    }
    
    var networkStatus: NetworkStatus {
        get async {
            return _networkStatus
        }
    }
    
    var networkStatusPublisher: AnyPublisher<NetworkStatus, Never> {
        return networkStatusSubject.eraseToAnyPublisher()
    }
    
    func startMonitoring() {
        print("[NetworkPathMonitor] Starting network monitoring")
        
        pathMonitor.start(queue: monitorQueue)
        pathMonitorMetrics.recordStart()
    }
    
    func stopMonitoring() {
        print("[NetworkPathMonitor] Stopping network monitoring")
        
        pathMonitor.cancel()
        debounceTimer?.invalidate()
        debounceTimer = nil
        pathMonitorMetrics.recordStop()
    }
    
    func getMetrics() -> PathMonitorMetrics {
        return pathMonitorMetrics
    }
    
    // MARK: - Private Implementation
    
    private func setupPathUpdateHandler() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            print("[NetworkPathMonitor] Network path update received")
            
            let newStatus = self.createNetworkStatus(from: path)
            
            // Debounce rapid network changes
            self.debounceNetworkUpdate(newStatus)
        }
    }
    
    private func createNetworkStatus(from path: NWPath) -> NetworkStatus {
        let isConnected = (path.status == .satisfied)
        let connectionType = determineConnectionType(from: path)
        let availableInterfaces = path.availableInterfaces.map { 
            NetworkStatus.InterfaceType.from($0.type) 
        }
        
        let status = NetworkStatus(
            isConnected: isConnected,
            connectionType: connectionType,
            isExpensive: path.isExpensive,
            isConstrained: path.isConstrained,
            availableInterfaces: availableInterfaces,
            timestamp: Date()
        )
        
        print("[NetworkPathMonitor] Network status: \(status.description), quality: \(String(format: "%.0f", status.qualityScore))")
        
        return status
    }
    
    private func determineConnectionType(from path: NWPath) -> NetworkStatus.ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else if path.status == .satisfied {
            return .other
        } else {
            return .none
        }
    }
    
    private func debounceNetworkUpdate(_ newStatus: NetworkStatus) {
        // Cancel existing timer
        debounceTimer?.invalidate()
        
        // Create new timer for debounced update
        debounceTimer = Timer.scheduledTimer(withTimeInterval: updateDebounceInterval, repeats: false) { [weak self] _ in
            self?.updateNetworkStatus(newStatus)
        }
    }
    
    private func updateNetworkStatus(_ newStatus: NetworkStatus) {
        let oldStatus = _networkStatus
        _networkStatus = newStatus
        
        // Check if this is a meaningful change
        let isSignificantChange = (
            oldStatus.isConnected != newStatus.isConnected ||
            oldStatus.connectionType != newStatus.connectionType ||
            oldStatus.isExpensive != newStatus.isExpensive
        )
        
        if isSignificantChange {
            print("[NetworkPathMonitor] Significant network change detected")
            pathMonitorMetrics.recordSignificantChange(
                from: oldStatus.connectionType,
                to: newStatus.connectionType
            )
        }
        
        // Always publish updates for subscribers
        networkStatusSubject.send(newStatus)
        pathMonitorMetrics.recordUpdate()
    }
}

// MARK: - Path Monitor Metrics

struct PathMonitorMetrics {
    private(set) var monitoringStartTime: Date?
    private(set) var totalUpdates: Int = 0
    private(set) var significantChanges: Int = 0
    private(set) var connectionTypeChanges: [String: Int] = [:]
    private(set) var totalMonitoringTime: TimeInterval = 0
    
    var updatesPerMinute: Double {
        return totalMonitoringTime > 0 ? Double(totalUpdates) / (totalMonitoringTime / 60.0) : 0
    }
    
    var significantChangeRate: Double {
        return totalUpdates > 0 ? Double(significantChanges) / Double(totalUpdates) : 0
    }
    
    mutating func recordStart() {
        monitoringStartTime = Date()
    }
    
    mutating func recordStop() {
        if let startTime = monitoringStartTime {
            totalMonitoringTime += Date().timeIntervalSince(startTime)
        }
        monitoringStartTime = nil
    }
    
    mutating func recordUpdate() {
        totalUpdates += 1
    }
    
    mutating func recordSignificantChange(from oldType: NetworkStatus.ConnectionType, to newType: NetworkStatus.ConnectionType) {
        significantChanges += 1
        let changeKey = "\(oldType.rawValue) -> \(newType.rawValue)"
        connectionTypeChanges[changeKey, default: 0] += 1
    }
    
    func debugDescription() -> String {
        return """
        [PathMonitorMetrics]
        Monitoring Time: \(String(format: "%.1fs", totalMonitoringTime))
        Total Updates: \(totalUpdates)
        Significant Changes: \(significantChanges) (\(String(format: "%.1f%%", significantChangeRate * 100)))
        Updates/Minute: \(String(format: "%.1f", updatesPerMinute))
        Connection Changes: \(connectionTypeChanges)
        """
    }
}

// MARK: - Extensions

extension NSLock {
    func withLock<T>(_ block: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try block()
    }
}