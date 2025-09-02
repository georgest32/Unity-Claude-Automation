import Foundation
import SwiftUI

// MARK: - Agent Model

/// Represents a Unity-Claude-Automation PowerShell agent/module
public struct Agent: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let description: String?
    public let type: String
    public let version: String
    public let status: Status
    public let startTime: Date?
    public let lastActivity: Date?
    public let cpuUsage: Double
    public let memoryUsage: Double
    public let metrics: [String: Double]
    public let errorMessage: String?
    public let moduleInfo: ModuleInfo
    
    public init(
        id: String,
        name: String,
        description: String? = nil,
        type: String,
        version: String = "1.0.0",
        status: Status = .idle,
        startTime: Date? = nil,
        lastActivity: Date? = nil,
        cpuUsage: Double = 0,
        memoryUsage: Double = 0,
        metrics: [String: Double] = [:],
        errorMessage: String? = nil,
        moduleInfo: ModuleInfo = ModuleInfo()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.type = type
        self.version = version
        self.status = status
        self.startTime = startTime
        self.lastActivity = lastActivity
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
        self.metrics = metrics
        self.errorMessage = errorMessage
        self.moduleInfo = moduleInfo
    }
    
    /// Agent execution status
    public enum Status: String, CaseIterable, Codable, Sendable {
        case idle = "idle"
        case running = "running"
        case stopped = "stopped"
        case error = "error"
        case initializing = "initializing"
        case suspended = "suspended"
        
        public var color: Color {
            switch self {
            case .idle: return .orange
            case .running: return .green
            case .stopped: return .gray
            case .error: return .red
            case .initializing: return .blue
            case .suspended: return .yellow
            }
        }
        
        public var systemImage: String {
            switch self {
            case .idle: return "pause.circle.fill"
            case .running: return "play.circle.fill"
            case .stopped: return "stop.circle.fill"
            case .error: return "exclamationmark.triangle.fill"
            case .initializing: return "hourglass.circle.fill"
            case .suspended: return "moon.circle.fill"
            }
        }
    }
}

// MARK: - Module Info

/// PowerShell module information from .psd1 manifest
public struct ModuleInfo: Codable, Equatable, Sendable {
    public let guid: String
    public let author: String
    public let companyName: String
    public let copyright: String
    public let powerShellVersion: String
    public let rootModule: String
    public let nestedModules: [String]
    public let functionsToExport: [String]
    public let commandsAvailable: [String]
    
    public init(
        guid: String = "",
        author: String = "Unity-Claude-Automation",
        companyName: String = "Unity-Claude-Automation Project",
        copyright: String = "(c) 2025 Unity-Claude-Automation",
        powerShellVersion: String = "5.1",
        rootModule: String = "",
        nestedModules: [String] = [],
        functionsToExport: [String] = [],
        commandsAvailable: [String] = []
    ) {
        self.guid = guid
        self.author = author
        self.companyName = companyName
        self.copyright = copyright
        self.powerShellVersion = powerShellVersion
        self.rootModule = rootModule
        self.nestedModules = nestedModules
        self.functionsToExport = functionsToExport
        self.commandsAvailable = commandsAvailable
    }
}

// MARK: - Agent Extensions

extension Agent {
    /// Check if agent is currently active (running or initializing)
    public var isActive: Bool {
        status == .running || status == .initializing
    }
    
    /// Check if agent has errors
    public var hasError: Bool {
        status == .error || errorMessage != nil
    }
    
    /// Get uptime since start
    public var uptime: TimeInterval? {
        guard let startTime = startTime else { return nil }
        return Date().timeIntervalSince(startTime)
    }
    
    /// Get formatted uptime string
    public var uptimeFormatted: String {
        guard let uptime = uptime else { return "N/A" }
        
        let hours = Int(uptime) / 3600
        let minutes = Int(uptime) % 3600 / 60
        let seconds = Int(uptime) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    /// Get time since last activity
    public var timeSinceLastActivity: TimeInterval? {
        guard let lastActivity = lastActivity else { return nil }
        return Date().timeIntervalSince(lastActivity)
    }
    
    /// Check if agent is recently active (within 5 minutes)
    public var isRecentlyActive: Bool {
        guard let timeSince = timeSinceLastActivity else { return false }
        return timeSince < 300 // 5 minutes
    }
}

// MARK: - Real Agent Data

extension Agent {
    /// Create mock agents based on actual Unity-Claude-Automation modules
    public static let realAgents: [Agent] = [
        Agent(
            id: "unity-claude-cli-orchestrator",
            name: "CLI Orchestrator",
            description: "Central orchestration system for Unity-Claude-Automation CLI operations",
            type: "Core Orchestration",
            version: "4.0.0",
            status: .running,
            startTime: Date().addingTimeInterval(-7200),
            lastActivity: Date().addingTimeInterval(-30),
            cpuUsage: 12.5,
            memoryUsage: 245.8,
            metrics: [
                "commands_processed": 1247,
                "success_rate": 94.2,
                "average_response_time": 1.8,
                "claude_interactions": 428
            ],
            moduleInfo: ModuleInfo(
                guid: "c9f6e0d3-7b1d-4e4f-0a9c-3d6b9f2e8c5b",
                author: "Unity-Claude-Automation",
                rootModule: "Unity-Claude-CLIOrchestrator.psm1",
                nestedModules: ["Core/OrchestrationCore.psm1", "Monitoring/CLIMonitoring.psm1", "Integration/ClaudeIntegration.psm1"],
                functionsToExport: ["Start-CLIOrchestrator", "Stop-CLIOrchestrator", "Get-OrchestratorStatus"],
                commandsAvailable: ["Invoke-ClaudeCommand", "Get-CLIMetrics", "Reset-OrchestratorState"]
            )
        ),
        
        Agent(
            id: "unity-claude-alert-classifier",
            name: "AI Alert Classifier",
            description: "ML-powered alert classification and routing system",
            type: "Machine Learning",
            version: "2.1.0",
            status: .running,
            startTime: Date().addingTimeInterval(-14400),
            lastActivity: Date().addingTimeInterval(-5),
            cpuUsage: 8.3,
            memoryUsage: 156.4,
            metrics: [
                "alerts_processed": 892,
                "classification_accuracy": 97.8,
                "false_positive_rate": 2.1
            ],
            moduleInfo: ModuleInfo(
                rootModule: "Unity-Claude-AIAlertClassifier.psm1",
                functionsToExport: ["Invoke-AlertClassification", "Train-ClassificationModel"],
                commandsAvailable: ["Get-AlertMetrics", "Update-MLModel"]
            )
        ),
        
        Agent(
            id: "unity-claude-documentation-engine",
            name: "Documentation Engine",
            description: "Autonomous documentation generation and maintenance",
            type: "Documentation",
            version: "1.5.2",
            status: .idle,
            startTime: Date().addingTimeInterval(-3600),
            lastActivity: Date().addingTimeInterval(-900),
            cpuUsage: 0.8,
            memoryUsage: 89.2,
            metrics: [
                "documents_generated": 45,
                "pages_updated": 123,
                "quality_score": 92.5
            ],
            moduleInfo: ModuleInfo(
                rootModule: "Unity-Claude-AutonomousDocumentationEngine.psm1",
                functionsToExport: ["Start-DocGeneration", "Update-Documentation"],
                commandsAvailable: ["Get-DocStats", "Validate-Documentation"]
            )
        ),
        
        Agent(
            id: "unity-claude-alert-analytics",
            name: "Alert Analytics",
            description: "Advanced analytics and reporting for system alerts",
            type: "Analytics",
            version: "1.8.1",
            status: .running,
            startTime: Date().addingTimeInterval(-10800),
            lastActivity: Date().addingTimeInterval(-120),
            cpuUsage: 15.7,
            memoryUsage: 312.6,
            metrics: [
                "reports_generated": 28,
                "data_points_analyzed": 15420,
                "trend_accuracy": 89.3
            ],
            moduleInfo: ModuleInfo(
                rootModule: "Unity-Claude-AlertAnalytics.psm1",
                functionsToExport: ["New-AnalyticsReport", "Get-TrendAnalysis"],
                commandsAvailable: ["Export-Metrics", "Generate-Dashboard"]
            )
        ),
        
        Agent(
            id: "unity-claude-change-intelligence",
            name: "Change Intelligence",
            description: "Intelligent change detection and impact analysis",
            type: "Monitoring",
            version: "2.0.3",
            status: .error,
            startTime: Date().addingTimeInterval(-1800),
            lastActivity: Date().addingTimeInterval(-300),
            cpuUsage: 0,
            memoryUsage: 45.8,
            metrics: [
                "changes_detected": 67,
                "impact_assessments": 34,
                "accuracy_score": 0
            ],
            errorMessage: "Failed to connect to repository monitoring service",
            moduleInfo: ModuleInfo(
                rootModule: "Unity-Claude-ChangeIntelligence.psm1",
                functionsToExport: ["Watch-Changes", "Analyze-Impact"],
                commandsAvailable: ["Get-ChangeHistory", "Predict-Impact"]
            )
        )
    ]
}