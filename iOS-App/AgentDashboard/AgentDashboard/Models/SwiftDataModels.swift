//
//  SwiftDataModels.swift
//  AgentDashboard
//
//  Created on 2025-08-31
//  SwiftData models for persistence
//

import Foundation
import SwiftData

// MARK: - SwiftData Schema Models

@Model
final class PersistedAgent {
    @Attribute(.unique) var id: String
    var name: String
    var type: String
    var status: String
    var agentDescription: String
    var startTime: Date?
    var lastActivity: Date?
    var cpuUsage: Double
    var memoryUsage: Double
    var configuration: [String: String]
    var createdAt: Date
    var updatedAt: Date
    
    init(id: String = UUID().uuidString,
         name: String,
         type: String,
         status: String = "idle",
         agentDescription: String = "",
         startTime: Date? = nil,
         lastActivity: Date? = nil,
         cpuUsage: Double = 0,
         memoryUsage: Double = 0,
         configuration: [String: String] = [:]) {
        self.id = id
        self.name = name
        self.type = type
        self.status = status
        self.agentDescription = agentDescription
        self.startTime = startTime
        self.lastActivity = lastActivity
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
        self.configuration = configuration
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // Convert to domain model
    func toAgent() -> Agent {
        return Agent(
            id: UUID(uuidString: id) ?? UUID(),
            name: name,
            type: AgentType(rawValue: type) ?? .orchestrator,
            status: AgentStatus(rawValue: status) ?? .idle,
            description: agentDescription,
            startTime: startTime,
            lastActivity: lastActivity,
            resourceUsage: ResourceUsage(
                cpu: cpuUsage,
                memory: memoryUsage,
                threads: 0,
                handles: 0
            ),
            configuration: configuration
        )
    }
    
    // Update from domain model
    func update(from agent: Agent) {
        self.name = agent.name
        self.type = agent.type.rawValue
        self.status = agent.status.rawValue
        self.agentDescription = agent.description
        self.startTime = agent.startTime
        self.lastActivity = agent.lastActivity
        self.cpuUsage = agent.resourceUsage?.cpu ?? 0
        self.memoryUsage = agent.resourceUsage?.memory ?? 0
        self.configuration = agent.configuration
        self.updatedAt = Date()
    }
}

@Model
final class PersistedModule {
    @Attribute(.unique) var id: String
    var name: String
    var version: String
    var isLoaded: Bool
    var dependencies: [String]
    var lastModified: Date
    var createdAt: Date
    var updatedAt: Date
    
    init(id: String = UUID().uuidString,
         name: String,
         version: String,
         isLoaded: Bool = false,
         dependencies: [String] = [],
         lastModified: Date = Date()) {
        self.id = id
        self.name = name
        self.version = version
        self.isLoaded = isLoaded
        self.dependencies = dependencies
        self.lastModified = lastModified
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // Convert to domain model
    func toModule() -> Module {
        return Module(
            id: UUID(uuidString: id) ?? UUID(),
            name: name,
            version: version,
            isLoaded: isLoaded,
            dependencies: dependencies,
            lastModified: lastModified
        )
    }
    
    // Update from domain model
    func update(from module: Module) {
        self.name = module.name
        self.version = module.version
        self.isLoaded = module.isLoaded
        self.dependencies = module.dependencies
        self.lastModified = module.lastModified
        self.updatedAt = Date()
    }
}

@Model
final class PersistedCommand {
    @Attribute(.unique) var id: String
    var text: String
    var timestamp: Date
    var source: String
    var status: String
    var output: String?
    var error: String?
    var executionTime: TimeInterval?
    var createdAt: Date
    
    init(id: String = UUID().uuidString,
         text: String,
         timestamp: Date = Date(),
         source: String = "user",
         status: String = "pending",
         output: String? = nil,
         error: String? = nil,
         executionTime: TimeInterval? = nil) {
        self.id = id
        self.text = text
        self.timestamp = timestamp
        self.source = source
        self.status = status
        self.output = output
        self.error = error
        self.executionTime = executionTime
        self.createdAt = Date()
    }
    
    // Convert to domain model
    func toCommand() -> Command {
        return Command(
            id: UUID(uuidString: id) ?? UUID(),
            text: text,
            timestamp: timestamp,
            source: CommandSource(rawValue: source) ?? .user,
            status: CommandStatus(rawValue: status) ?? .pending,
            output: output,
            error: error
        )
    }
    
    // Update from domain model
    func update(from command: Command) {
        self.text = command.text
        self.timestamp = command.timestamp
        self.source = command.source.rawValue
        self.status = command.status.rawValue
        self.output = command.output
        self.error = command.error
    }
}

@Model
final class PersistedSystemStatus {
    @Attribute(.unique) var id: String
    var timestamp: Date
    var isHealthy: Bool
    var cpuUsage: Double
    var memoryUsage: Double
    var diskUsage: Double
    var activeAgents: Int
    var totalModules: Int
    var uptime: TimeInterval
    var version: String
    var environment: String
    var createdAt: Date
    
    init(id: String = UUID().uuidString,
         timestamp: Date = Date(),
         isHealthy: Bool = true,
         cpuUsage: Double = 0,
         memoryUsage: Double = 0,
         diskUsage: Double = 0,
         activeAgents: Int = 0,
         totalModules: Int = 0,
         uptime: TimeInterval = 0,
         version: String = "1.0.0",
         environment: String = "Production") {
        self.id = id
        self.timestamp = timestamp
        self.isHealthy = isHealthy
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
        self.diskUsage = diskUsage
        self.activeAgents = activeAgents
        self.totalModules = totalModules
        self.uptime = uptime
        self.version = version
        self.environment = environment
        self.createdAt = Date()
    }
    
    // Convert to domain model
    func toSystemStatus() -> SystemStatus {
        return SystemStatus(
            timestamp: timestamp,
            isHealthy: isHealthy,
            cpuUsage: cpuUsage,
            memoryUsage: memoryUsage,
            diskUsage: diskUsage,
            activeAgents: activeAgents,
            totalModules: totalModules,
            uptime: uptime
        )
    }
    
    // Update from domain model
    func update(from status: SystemStatus) {
        self.timestamp = status.timestamp
        self.isHealthy = status.isHealthy
        self.cpuUsage = status.cpuUsage
        self.memoryUsage = status.memoryUsage
        self.diskUsage = status.diskUsage
        self.activeAgents = status.activeAgents
        self.totalModules = status.totalModules
        self.uptime = status.uptime
    }
}

@Model
final class PersistedAlert {
    @Attribute(.unique) var id: String
    var title: String
    var message: String
    var severity: String
    var timestamp: Date
    var source: String
    var isRead: Bool
    var isResolved: Bool
    var createdAt: Date
    
    init(id: String = UUID().uuidString,
         title: String,
         message: String,
         severity: String = "info",
         timestamp: Date = Date(),
         source: String = "system",
         isRead: Bool = false,
         isResolved: Bool = false) {
        self.id = id
        self.title = title
        self.message = message
        self.severity = severity
        self.timestamp = timestamp
        self.source = source
        self.isRead = isRead
        self.isResolved = isResolved
        self.createdAt = Date()
    }
    
    // Convert to domain model
    func toAlert() -> Alert {
        return Alert(
            id: UUID(uuidString: id) ?? UUID(),
            title: title,
            message: message,
            severity: Alert.Severity(rawValue: severity) ?? .info,
            timestamp: timestamp,
            source: source
        )
    }
    
    // Update from domain model
    func update(from alert: Alert) {
        self.title = alert.title
        self.message = alert.message
        self.severity = alert.severity.rawValue
        self.timestamp = alert.timestamp
        self.source = alert.source
    }
}

// MARK: - SwiftData Model Container

extension ModelContainer {
    static let appContainer: ModelContainer = {
        let schema = Schema([
            PersistedAgent.self,
            PersistedModule.self,
            PersistedCommand.self,
            PersistedSystemStatus.self,
            PersistedAlert.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        
        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}