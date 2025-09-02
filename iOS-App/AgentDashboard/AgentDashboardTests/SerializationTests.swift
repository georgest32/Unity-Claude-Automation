//
//  SerializationTests.swift
//  AgentDashboardTests
//
//  Created on 2025-08-31
//  Unit tests for model serialization/deserialization
//

import XCTest
@testable import AgentDashboard

final class SerializationTests: XCTestCase {
    
    var encoder: JSONEncoder!
    var decoder: JSONDecoder!
    
    override func setUp() {
        super.setUp()
        encoder = JSONEncoder.apiEncoder
        decoder = JSONDecoder.apiDecoder
    }
    
    override func tearDown() {
        encoder = nil
        decoder = nil
        super.tearDown()
    }
    
    // MARK: - AgentDTO Tests
    
    func testAgentDTOSerialization() throws {
        let agentDTO = AgentDTO(
            id: UUID().uuidString,
            name: "TestAgent",
            status: "running",
            type: "CLI Orchestrator",
            startTime: "2025-08-31T12:00:00Z",
            lastActivity: "2025-08-31T14:00:00Z",
            metrics: ["cpu": 50.0, "memory": 60.0],
            errorMessage: nil
        )
        
        let data = try encoder.encode(agentDTO)
        let decodedDTO = try decoder.decode(AgentDTO.self, from: data)
        
        XCTAssertEqual(agentDTO.id, decodedDTO.id)
        XCTAssertEqual(agentDTO.name, decodedDTO.name)
        XCTAssertEqual(agentDTO.status, decodedDTO.status)
        XCTAssertEqual(agentDTO.type, decodedDTO.type)
    }
    
    func testAgentDTOToAgentConversion() {
        let agentDTO = AgentDTO(
            id: UUID().uuidString,
            name: "TestAgent",
            status: "running",
            type: "CLI Orchestrator",
            startTime: "2025-08-31T12:00:00Z",
            lastActivity: nil,
            metrics: ["cpu": 50.0, "memory": 60.0],
            errorMessage: nil
        )
        
        let agent = agentDTO.toAgent()
        
        XCTAssertEqual(agent.name, "TestAgent")
        XCTAssertEqual(agent.status, .running)
        XCTAssertEqual(agent.type, .orchestrator)
        XCTAssertNotNil(agent.resourceUsage)
        XCTAssertEqual(agent.resourceUsage?.cpu, 50.0)
        XCTAssertEqual(agent.resourceUsage?.memory, 60.0)
    }
    
    // MARK: - ModuleDTO Tests
    
    func testModuleDTOSerialization() throws {
        let moduleDTO = ModuleDTO(
            id: UUID().uuidString,
            name: "TestModule",
            version: "1.0.0",
            status: "active",
            loadTime: "2025-08-31T12:00:00Z",
            dependencies: ["Dep1", "Dep2"]
        )
        
        let data = try encoder.encode(moduleDTO)
        let decodedDTO = try decoder.decode(ModuleDTO.self, from: data)
        
        XCTAssertEqual(moduleDTO.id, decodedDTO.id)
        XCTAssertEqual(moduleDTO.name, decodedDTO.name)
        XCTAssertEqual(moduleDTO.version, decodedDTO.version)
        XCTAssertEqual(moduleDTO.dependencies.count, 2)
    }
    
    func testModuleDTOToModuleConversion() {
        let moduleDTO = ModuleDTO(
            id: UUID().uuidString,
            name: "TestModule",
            version: "1.0.0",
            status: "active",
            loadTime: "2025-08-31T12:00:00Z",
            dependencies: ["Dep1"]
        )
        
        let module = moduleDTO.toModule()
        
        XCTAssertEqual(module.name, "TestModule")
        XCTAssertEqual(module.version, "1.0.0")
        XCTAssertTrue(module.isLoaded)
        XCTAssertEqual(module.dependencies.first, "Dep1")
    }
    
    // MARK: - API Response Tests
    
    func testAPIResponseSerialization() throws {
        let response = APIResponse(
            success: true,
            data: "Test Data",
            error: nil,
            timestamp: Date()
        )
        
        let data = try encoder.encode(response)
        let decoded = try decoder.decode(APIResponse<String>.self, from: data)
        
        XCTAssertTrue(decoded.success)
        XCTAssertEqual(decoded.data, "Test Data")
        XCTAssertNil(decoded.error)
    }
    
    func testAPIResponseWithError() throws {
        let response = APIResponse<String>(
            success: false,
            data: nil,
            error: "Test error message",
            timestamp: Date()
        )
        
        let data = try encoder.encode(response)
        let decoded = try decoder.decode(APIResponse<String>.self, from: data)
        
        XCTAssertFalse(decoded.success)
        XCTAssertNil(decoded.data)
        XCTAssertEqual(decoded.error, "Test error message")
    }
    
    // MARK: - Request Model Tests
    
    func testCreateAgentRequestSerialization() throws {
        let request = CreateAgentRequest(
            name: "NewAgent",
            type: "Monitor",
            configuration: ["key1": "value1", "key2": "value2"]
        )
        
        let data = try encoder.encode(request)
        let decoded = try decoder.decode(CreateAgentRequest.self, from: data)
        
        XCTAssertEqual(decoded.name, "NewAgent")
        XCTAssertEqual(decoded.type, "Monitor")
        XCTAssertEqual(decoded.configuration.count, 2)
    }
    
    func testExecuteCommandRequestSerialization() throws {
        let request = ExecuteCommandRequest(
            command: "Get-Process",
            parameters: ["Name": "powershell"],
            runAsJob: true
        )
        
        let data = try encoder.encode(request)
        let decoded = try decoder.decode(ExecuteCommandRequest.self, from: data)
        
        XCTAssertEqual(decoded.command, "Get-Process")
        XCTAssertEqual(decoded.parameters?["Name"], "powershell")
        XCTAssertTrue(decoded.runAsJob)
    }
    
    // MARK: - Uptime Parsing Tests
    
    func testSystemStatusDTOUptimeParsing() {
        let dto = SystemStatusDTO(
            id: UUID().uuidString,
            isOnline: true,
            uptime: "2d 14h 32m 15s",
            lastHeartbeat: "2025-08-31T12:00:00Z",
            version: "1.0.0",
            environment: "Production"
        )
        
        let status = dto.toSystemStatus(with: nil)
        
        // 2 days = 172800 seconds
        // 14 hours = 50400 seconds
        // 32 minutes = 1920 seconds
        // 15 seconds = 15 seconds
        // Total = 225135 seconds
        XCTAssertEqual(status.uptime, 225135, accuracy: 1)
    }
    
    // MARK: - ModelSerializer Tests
    
    func testModelSerializerSerialize() throws {
        let agent = Agent(
            id: UUID(),
            name: "Test",
            type: .orchestrator,
            status: .idle,
            description: "Test",
            startTime: nil,
            lastActivity: nil,
            resourceUsage: nil,
            configuration: [:]
        )
        
        let data = try ModelSerializer.serialize(agent)
        XCTAssertNotNil(data)
        XCTAssertGreaterThan(data.count, 0)
    }
    
    func testModelSerializerSerializeToString() throws {
        let dict = ["key": "value", "number": 123]
        let jsonString = try ModelSerializer.serializeToString(dict)
        
        XCTAssertTrue(jsonString.contains("\"key\""))
        XCTAssertTrue(jsonString.contains("\"value\""))
        XCTAssertTrue(jsonString.contains("123"))
    }
    
    func testSerializationErrorHandling() {
        XCTAssertEqual(
            SerializationError.encodingFailed.errorDescription,
            "Failed to encode model to JSON"
        )
        XCTAssertEqual(
            SerializationError.decodingFailed.errorDescription,
            "Failed to decode JSON to model"
        )
        XCTAssertEqual(
            SerializationError.invalidData.errorDescription,
            "Invalid data format"
        )
    }
}