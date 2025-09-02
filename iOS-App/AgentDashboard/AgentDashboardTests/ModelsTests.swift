//
//  ModelsTests.swift
//  AgentDashboardTests
//
//  Created on 2025-08-31
//  Unit tests for data models
//

import XCTest
@testable import AgentDashboard

final class ModelsTests: XCTestCase {
    
    // MARK: - Agent Tests
    
    func testAgentCreation() {
        let agent = Agent(
            id: UUID(),
            name: "TestAgent",
            type: .orchestrator,
            status: .running,
            description: "Test Description",
            startTime: Date(),
            lastActivity: Date(),
            resourceUsage: ResourceUsage(cpu: 50.0, memory: 60.0, threads: 10, handles: 20),
            configuration: ["key": "value"]
        )
        
        XCTAssertEqual(agent.name, "TestAgent")
        XCTAssertEqual(agent.type, .orchestrator)
        XCTAssertEqual(agent.status, .running)
        XCTAssertNotNil(agent.resourceUsage)
        XCTAssertEqual(agent.resourceUsage?.cpu, 50.0)
    }
    
    func testAgentStatusColors() {
        XCTAssertEqual(AgentStatus.idle.color, .gray)
        XCTAssertEqual(AgentStatus.running.color, .green)
        XCTAssertEqual(AgentStatus.paused.color, .orange)
        XCTAssertEqual(AgentStatus.stopped.color, .red)
        XCTAssertEqual(AgentStatus.error.color, .red)
    }
    
    func testAgentTypeIcons() {
        XCTAssertEqual(AgentType.orchestrator.icon, "cpu")
        XCTAssertEqual(AgentType.monitor.icon, "eye")
        XCTAssertEqual(AgentType.analyzer.icon, "magnifyingglass")
        XCTAssertEqual(AgentType.builder.icon, "hammer")
        XCTAssertEqual(AgentType.tester.icon, "checkmark.circle")
        XCTAssertEqual(AgentType.reporter.icon, "doc.text")
    }
    
    // MARK: - Module Tests
    
    func testModuleCreation() {
        let module = Module(
            id: UUID(),
            name: "TestModule",
            version: "1.0.0",
            isLoaded: true,
            dependencies: ["Dep1", "Dep2"],
            lastModified: Date()
        )
        
        XCTAssertEqual(module.name, "TestModule")
        XCTAssertEqual(module.version, "1.0.0")
        XCTAssertTrue(module.isLoaded)
        XCTAssertEqual(module.dependencies.count, 2)
        XCTAssertEqual(module.dependencies.first, "Dep1")
    }
    
    // MARK: - SystemStatus Tests
    
    func testSystemStatusCreation() {
        let status = SystemStatus(
            timestamp: Date(),
            isHealthy: true,
            cpuUsage: 45.5,
            memoryUsage: 60.2,
            diskUsage: 70.0,
            activeAgents: 5,
            totalModules: 10,
            uptime: 3600
        )
        
        XCTAssertTrue(status.isHealthy)
        XCTAssertEqual(status.cpuUsage, 45.5, accuracy: 0.01)
        XCTAssertEqual(status.memoryUsage, 60.2, accuracy: 0.01)
        XCTAssertEqual(status.activeAgents, 5)
        XCTAssertEqual(status.totalModules, 10)
        XCTAssertEqual(status.uptime, 3600)
    }
    
    // MARK: - Command Tests
    
    func testCommandCreation() {
        let command = Command(
            id: UUID(),
            text: "test command",
            timestamp: Date(),
            source: .user,
            status: .pending,
            output: nil,
            error: nil
        )
        
        XCTAssertEqual(command.text, "test command")
        XCTAssertEqual(command.source, .user)
        XCTAssertEqual(command.status, .pending)
        XCTAssertNil(command.output)
        XCTAssertNil(command.error)
    }
    
    func testCommandStatusFlow() {
        var command = Command(
            id: UUID(),
            text: "test",
            timestamp: Date(),
            source: .user,
            status: .pending,
            output: nil,
            error: nil
        )
        
        // Test status progression
        XCTAssertEqual(command.status, .pending)
        
        command.status = .executing
        XCTAssertEqual(command.status, .executing)
        
        command.status = .completed
        command.output = "Success"
        XCTAssertEqual(command.status, .completed)
        XCTAssertNotNil(command.output)
    }
    
    // MARK: - Alert Tests
    
    func testAlertCreation() {
        let alert = Alert(
            id: UUID(),
            title: "Test Alert",
            message: "This is a test alert",
            severity: .warning,
            timestamp: Date(),
            source: "TestSource"
        )
        
        XCTAssertEqual(alert.title, "Test Alert")
        XCTAssertEqual(alert.message, "This is a test alert")
        XCTAssertEqual(alert.severity, .warning)
        XCTAssertEqual(alert.source, "TestSource")
    }
    
    func testAlertSeverityColors() {
        XCTAssertEqual(Alert.Severity.info.color, .blue)
        XCTAssertEqual(Alert.Severity.warning.color, .orange)
        XCTAssertEqual(Alert.Severity.error.color, .red)
        XCTAssertEqual(Alert.Severity.critical.color, .purple)
    }
    
    func testAlertSeverityIcons() {
        XCTAssertEqual(Alert.Severity.info.icon, "info.circle")
        XCTAssertEqual(Alert.Severity.warning.icon, "exclamationmark.triangle")
        XCTAssertEqual(Alert.Severity.error.icon, "xmark.circle")
        XCTAssertEqual(Alert.Severity.critical.icon, "exclamationmark.octagon")
    }
    
    // MARK: - WebSocketMessage Tests
    
    func testWebSocketMessageCreation() {
        let data = "test payload".data(using: .utf8)!
        let message = WebSocketMessage(
            id: UUID(),
            type: .agentStatus,
            payload: data,
            timestamp: Date()
        )
        
        XCTAssertEqual(message.type, .agentStatus)
        XCTAssertEqual(message.payload, data)
        XCTAssertNotNil(message.timestamp)
    }
    
    // MARK: - ConnectionStatus Tests
    
    func testConnectionStatusDescriptions() {
        XCTAssertEqual(ConnectionStatus.disconnected.description, "Disconnected")
        XCTAssertEqual(ConnectionStatus.connecting.description, "Connecting...")
        XCTAssertEqual(ConnectionStatus.connected.description, "Connected")
        XCTAssertEqual(ConnectionStatus.disconnecting.description, "Disconnecting...")
        
        let errorStatus = ConnectionStatus.error("Test error")
        XCTAssertEqual(errorStatus.description, "Error: Test error")
    }
    
    func testConnectionStatusColors() {
        XCTAssertEqual(ConnectionStatus.disconnected.color, .gray)
        XCTAssertEqual(ConnectionStatus.connecting.color, .orange)
        XCTAssertEqual(ConnectionStatus.connected.color, .green)
        XCTAssertEqual(ConnectionStatus.disconnecting.color, .orange)
        XCTAssertEqual(ConnectionStatus.error("").color, .red)
    }
}