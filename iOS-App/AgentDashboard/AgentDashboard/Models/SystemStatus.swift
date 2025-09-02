import Foundation

// MARK: - System Status

public struct SystemStatus: Identifiable, Codable, Equatable {
    public let id: String
    public let isOnline: Bool
    public let uptime: String
    public let lastHeartbeat: Date
    public let version: String
    public let environment: String
    public let totalCpuUsage: Double
    public let totalMemoryUsage: Double
    public let activeProcesses: Int
    public let activeAgents: Int
    public let errorCount: Int
    public let warningCount: Int
    
    public init(
        id: String = UUID().uuidString,
        isOnline: Bool,
        uptime: String,
        lastHeartbeat: Date,
        version: String,
        environment: String,
        totalCpuUsage: Double = 0,
        totalMemoryUsage: Double = 0,
        activeProcesses: Int = 0,
        activeAgents: Int = 0,
        errorCount: Int = 0,
        warningCount: Int = 0
    ) {
        self.id = id
        self.isOnline = isOnline
        self.uptime = uptime
        self.lastHeartbeat = lastHeartbeat
        self.version = version
        self.environment = environment
        self.totalCpuUsage = totalCpuUsage
        self.totalMemoryUsage = totalMemoryUsage
        self.activeProcesses = activeProcesses
        self.activeAgents = activeAgents
        self.errorCount = errorCount
        self.warningCount = warningCount
    }
}

// MARK: - Module

public struct Module: Identifiable, Codable, Equatable {
    public let id: String
    public let name: String
    public let version: String
    public let status: Status
    public let loadTime: Date
    public let dependencies: [String]
    public let description: String?
    public let author: String
    public let exportedFunctions: [String]
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        version: String,
        status: Status,
        loadTime: Date,
        dependencies: [String] = [],
        description: String? = nil,
        author: String = "Unity-Claude-Automation",
        exportedFunctions: [String] = []
    ) {
        self.id = id
        self.name = name
        self.version = version
        self.status = status
        self.loadTime = loadTime
        self.dependencies = dependencies
        self.description = description
        self.author = author
        self.exportedFunctions = exportedFunctions
    }
    
    public enum Status: String, CaseIterable, Codable {
        case active = "active"
        case inactive = "inactive"
        case loading = "loading"
        case error = "error"
        
        public var color: String {
            switch self {
            case .active: return "green"
            case .inactive: return "gray"
            case .loading: return "blue"
            case .error: return "red"
            }
        }
        
        public var systemImage: String {
            switch self {
            case .active: return "checkmark.circle.fill"
            case .inactive: return "minus.circle.fill"
            case .loading: return "hourglass.circle.fill"
            case .error: return "exclamationmark.triangle.fill"
            }
        }
    }
}

// MARK: - Extensions

extension SystemStatus {
    public var healthStatus: HealthStatus {
        if !isOnline || errorCount > 10 {
            return .critical
        } else if errorCount > 5 || warningCount > 20 {
            return .warning
        } else if errorCount > 0 || warningCount > 5 {
            return .moderate
        } else {
            return .healthy
        }
    }
    
    public enum HealthStatus: String, CaseIterable {
        case healthy = "Healthy"
        case moderate = "Moderate"
        case warning = "Warning"
        case critical = "Critical"
        
        public var color: String {
            switch self {
            case .healthy: return "green"
            case .moderate: return "yellow"
            case .warning: return "orange"
            case .critical: return "red"
            }
        }
        
        public var systemImage: String {
            switch self {
            case .healthy: return "checkmark.shield.fill"
            case .moderate: return "exclamationmark.shield.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .critical: return "xmark.shield.fill"
            }
        }
    }
}

extension Module {
    public var isActive: Bool {
        status == .active
    }
    
    public var hasError: Bool {
        status == .error
    }
    
    public var loadTimeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: loadTime)
    }
    
    public var uptimeSinceLoad: TimeInterval {
        Date().timeIntervalSince(loadTime)
    }
    
    public var uptimeFormatted: String {
        let uptime = uptimeSinceLoad
        let hours = Int(uptime) / 3600
        let minutes = Int(uptime) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}