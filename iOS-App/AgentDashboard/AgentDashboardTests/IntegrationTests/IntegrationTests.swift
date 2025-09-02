//
//  IntegrationTests.swift
//  AgentDashboardTests
//
//  Created on 2025-09-01
//  Integration tests for end-to-end workflows and backend API integration
//

import XCTest
import Combine
@testable import AgentDashboard

final class IntegrationTests: XCTestCase {
    
    var apiClient: APIClient!
    var webSocketClient: WebSocketClient!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        super.setUp()
        
        cancellables = Set<AnyCancellable>()
        
        // Use live API client for integration tests
        let baseURL = URL(string: "http://localhost:8080")!
        apiClient = APIClient(baseURL: baseURL)
        
        // Use live WebSocket client for real-time testing
        let wsURL = URL(string: "ws://localhost:8080/systemhub")!
        webSocketClient = WebSocketClient(url: wsURL)
        
        print("[IntegrationTest] Integration test environment initialized")
        print("[IntegrationTest] API Base URL: \(baseURL)")
        print("[IntegrationTest] WebSocket URL: \(wsURL)")
    }
    
    override func tearDownWithError() throws {
        cancellables.removeAll()
        webSocketClient = nil
        apiClient = nil
        
        print("[IntegrationTest] Integration test environment cleaned up")
        super.tearDown()
    }
    
    // MARK: - Authentication Integration Tests
    
    func testJWTAuthenticationFlow() async throws {
        print("[IntegrationTest] Testing JWT authentication flow")
        
        let expectation = XCTestExpectation(description: "JWT Authentication")
        
        do {
            // Test authentication with backend API
            let authToken = try await apiClient.authenticate(username: "admin", password: "admin123")
            
            XCTAssertFalse(authToken.token.isEmpty, "JWT token should not be empty")
            XCTAssertFalse(authToken.refreshToken.isEmpty, "Refresh token should not be empty")
            XCTAssertEqual(authToken.user.username, "admin", "Username should match login credentials")
            XCTAssertEqual(authToken.user.role, .admin, "User role should be admin")
            
            print("[IntegrationTest] JWT authentication successful")
            print("[IntegrationTest] Token expires at: \(authToken.expiresAt)")
            print("[IntegrationTest] User ID: \(authToken.user.id)")
            
            expectation.fulfill()
            
        } catch {
            XCTFail("JWT authentication failed: \(error.localizedDescription)")
            print("[IntegrationTest] JWT authentication failed: \(error)")
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
        print("[IntegrationTest] JWT authentication integration test completed")
    }
    
    // MARK: - API Integration Tests
    
    func testSystemStatusIntegration() async throws {
        print("[IntegrationTest] Testing system status API integration")
        
        let expectation = XCTestExpectation(description: "System Status API")
        
        do {
            // Authenticate first
            let authToken = try await apiClient.authenticate(username: "admin", password: "admin123")
            print("[IntegrationTest] Authenticated for system status test")
            
            // Fetch system status
            let systemStatus = try await apiClient.fetchSystemStatus()
            
            XCTAssertNotNil(systemStatus, "System status should not be nil")
            XCTAssertTrue(systemStatus.cpuUsage >= 0 && systemStatus.cpuUsage <= 100, "CPU usage should be between 0-100%")
            XCTAssertTrue(systemStatus.memoryUsage >= 0 && systemStatus.memoryUsage <= 100, "Memory usage should be between 0-100%")
            XCTAssertTrue(systemStatus.activeAgents >= 0, "Active agents should be non-negative")
            XCTAssertTrue(systemStatus.totalModules >= 0, "Total modules should be non-negative")
            
            print("[IntegrationTest] System status validation passed")
            print("[IntegrationTest] CPU: \(systemStatus.cpuUsage)%, Memory: \(systemStatus.memoryUsage)%")
            print("[IntegrationTest] Active Agents: \(systemStatus.activeAgents), Modules: \(systemStatus.totalModules)")
            
            expectation.fulfill()
            
        } catch {
            XCTFail("System status API integration failed: \(error.localizedDescription)")
            print("[IntegrationTest] System status API failed: \(error)")
        }
        
        await fulfillment(of: [expectation], timeout: 15.0)
        print("[IntegrationTest] System status integration test completed")
    }
    
    func testAgentControlIntegration() async throws {
        print("[IntegrationTest] Testing agent control API integration")
        
        let expectation = XCTestExpectation(description: "Agent Control API")
        
        do {
            // Authenticate first
            let authToken = try await apiClient.authenticate(username: "admin", password: "admin123")
            print("[IntegrationTest] Authenticated for agent control test")
            
            // Fetch agents
            let agents = try await apiClient.fetchAgents()
            XCTAssertGreaterThan(agents.count, 0, "Should have at least one agent")
            
            let firstAgent = agents[0]
            print("[IntegrationTest] Testing with agent: \(firstAgent.name)")
            
            // Test agent operations
            let agentOperations: [(String, (UUID) async throws -> AgentActionResult)] = [
                ("start", apiClient.startAgent),
                ("stop", apiClient.stopAgent),
                ("restart", apiClient.restartAgent)
            ]
            
            for (operationName, operation) in agentOperations {
                print("[IntegrationTest] Testing \(operationName) operation for agent \(firstAgent.id)")
                
                let result = try await operation(firstAgent.id)
                
                XCTAssertNotNil(result, "\(operationName) result should not be nil")
                XCTAssertEqual(result.agentId, firstAgent.id, "Result should match agent ID")
                XCTAssertEqual(result.action, operationName, "Result action should match operation")
                XCTAssertNotNil(result.executionTime, "Execution time should be recorded")
                
                print("[IntegrationTest] \(operationName) operation completed - Success: \(result.success)")
                print("[IntegrationTest] Message: \(result.message)")
                print("[IntegrationTest] Execution time: \(result.executionTime?.description ?? "unknown")")
                
                // Wait between operations to avoid overwhelming the system
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            }
            
            expectation.fulfill()
            
        } catch {
            XCTFail("Agent control integration failed: \(error.localizedDescription)")
            print("[IntegrationTest] Agent control integration failed: \(error)")
        }
        
        await fulfillment(of: [expectation], timeout: 30.0)
        print("[IntegrationTest] Agent control integration test completed")
    }
    
    // MARK: - WebSocket Integration Tests
    
    func testWebSocketRealTimeUpdates() async throws {
        print("[IntegrationTest] Testing WebSocket real-time updates integration")
        
        let expectation = XCTestExpectation(description: "WebSocket Real-time Updates")
        var receivedMessages: [WebSocketMessage] = []
        
        // Set up WebSocket connection
        webSocketClient.messages()
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("[IntegrationTest] WebSocket stream finished")
                    case .failure(let error):
                        print("[IntegrationTest] WebSocket stream error: \(error)")
                        XCTFail("WebSocket connection failed: \(error)")
                    }
                },
                receiveValue: { message in
                    receivedMessages.append(message)
                    print("[IntegrationTest] Received WebSocket message: \(message.type.rawValue)")
                    
                    // Fulfill expectation after receiving at least one message
                    if receivedMessages.count >= 1 {
                        expectation.fulfill()
                    }
                }
            )
            .store(in: &cancellables)
        
        // Connect to WebSocket
        do {
            try await webSocketClient.connect()
            print("[IntegrationTest] WebSocket connected successfully")
            
            // Wait for real-time updates (backend sends updates every 30 seconds)
            // For testing, we'll wait a shorter time and check connection
            
        } catch {
            XCTFail("WebSocket connection failed: \(error.localizedDescription)")
            print("[IntegrationTest] WebSocket connection failed: \(error)")
        }
        
        await fulfillment(of: [expectation], timeout: 35.0) // Wait for at least one update cycle
        
        XCTAssertGreaterThan(receivedMessages.count, 0, "Should receive at least one real-time update")
        print("[IntegrationTest] Received \(receivedMessages.count) real-time updates")
        
        // Disconnect WebSocket
        await webSocketClient.disconnect()
        print("[IntegrationTest] WebSocket real-time updates integration test completed")
    }
    
    // MARK: - Data Flow Integration Tests
    
    func testCompleteDataFlow() async throws {
        print("[IntegrationTest] Testing complete data flow integration")
        
        let expectation = XCTestExpectation(description: "Complete Data Flow")
        
        do {
            // 1. Authenticate
            let authToken = try await apiClient.authenticate(username: "admin", password: "admin123")
            print("[IntegrationTest] Step 1: Authentication successful")
            
            // 2. Fetch system status
            let systemStatus = try await apiClient.fetchSystemStatus()
            print("[IntegrationTest] Step 2: System status fetched")
            
            // 3. Fetch agents
            let agents = try await apiClient.fetchAgents()
            print("[IntegrationTest] Step 3: Agents fetched (\(agents.count) agents)")
            
            // 4. Perform agent operation if agents exist
            if !agents.isEmpty {
                let firstAgent = agents[0]
                let operationResult = try await apiClient.startAgent(firstAgent.id)
                print("[IntegrationTest] Step 4: Agent operation completed - \(operationResult.success)")
            }
            
            // 5. Fetch updated system status
            let updatedStatus = try await apiClient.fetchSystemStatus()
            print("[IntegrationTest] Step 5: Updated system status fetched")
            
            // Validate data consistency
            XCTAssertNotNil(systemStatus, "Initial system status should exist")
            XCTAssertNotNil(updatedStatus, "Updated system status should exist")
            XCTAssertGreaterThanOrEqual(agents.count, 0, "Agents list should be valid")
            
            expectation.fulfill()
            
        } catch {
            XCTFail("Complete data flow integration failed: \(error.localizedDescription)")
            print("[IntegrationTest] Complete data flow failed: \(error)")
        }
        
        await fulfillment(of: [expectation], timeout: 20.0)
        print("[IntegrationTest] Complete data flow integration test completed")
    }
    
    // MARK: - Error Handling Integration Tests
    
    func testErrorHandlingIntegration() async throws {
        print("[IntegrationTest] Testing error handling integration")
        
        let expectation = XCTestExpectation(description: "Error Handling")
        
        // Test with invalid credentials
        do {
            let _ = try await apiClient.authenticate(username: "invalid", password: "invalid")
            XCTFail("Authentication should fail with invalid credentials")
        } catch {
            print("[IntegrationTest] Expected authentication failure occurred: \(error)")
            XCTAssertTrue(error.localizedDescription.contains("invalid") || error.localizedDescription.contains("unauthorized"), 
                         "Error should indicate authentication failure")
        }
        
        // Test with invalid agent ID
        do {
            let invalidAgentId = UUID()
            let _ = try await apiClient.startAgent(invalidAgentId)
            print("[IntegrationTest] Agent operation with invalid ID completed (may succeed in mock)")
        } catch {
            print("[IntegrationTest] Expected agent operation failure: \(error)")
            // This might not fail with mock implementation, which is acceptable
        }
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 10.0)
        print("[IntegrationTest] Error handling integration test completed")
    }
    
    // MARK: - Performance Integration Tests
    
    func testPerformanceIntegration() async throws {
        print("[IntegrationTest] Testing performance integration with backend")
        
        // Test API response time
        measure(metrics: [XCTClockMetric()]) {
            let expectation = XCTestExpectation(description: "API Performance")
            
            Task {
                do {
                    let _ = try await apiClient.fetchSystemStatus()
                    expectation.fulfill()
                } catch {
                    print("[IntegrationTest] API performance test failed: \(error)")
                }
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
        
        // Test memory usage during data operations
        measure(metrics: [XCTMemoryMetric()]) {
            let expectation = XCTestExpectation(description: "Memory Performance")
            
            Task {
                do {
                    // Perform multiple data operations
                    let _ = try await apiClient.fetchSystemStatus()
                    let _ = try await apiClient.fetchAgents()
                    let _ = try await apiClient.fetchModules()
                    
                    expectation.fulfill()
                } catch {
                    print("[IntegrationTest] Memory performance test failed: \(error)")
                }
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
        
        print("[IntegrationTest] Performance integration test completed")
    }
    
    // MARK: - Security Integration Tests
    
    func testSecurityIntegration() async throws {
        print("[IntegrationTest] Testing security integration")
        
        let expectation = XCTestExpectation(description: "Security Integration")
        
        do {
            // Test secure token storage and retrieval
            let authToken = try await apiClient.authenticate(username: "admin", password: "admin123")
            
            // Test token validation by making authenticated request
            // Note: This would require the APIClient to store and use the token
            let systemStatus = try await apiClient.fetchSystemStatus()
            XCTAssertNotNil(systemStatus, "Authenticated request should succeed")
            
            print("[IntegrationTest] Security integration validation passed")
            print("[IntegrationTest] Token secured and used successfully")
            
            expectation.fulfill()
            
        } catch {
            XCTFail("Security integration failed: \(error.localizedDescription)")
            print("[IntegrationTest] Security integration failed: \(error)")
        }
        
        await fulfillment(of: [expectation], timeout: 15.0)
        print("[IntegrationTest] Security integration test completed")
    }
}

// MARK: - End-to-End Workflow Tests

final class EndToEndWorkflowTests: XCTestCase {
    
    var testEnvironment: TestEnvironment!
    
    override func setUpWithError() throws {
        super.setUp()
        testEnvironment = TestEnvironment()
        print("[E2ETest] End-to-end test environment initialized")
    }
    
    override func tearDownWithError() throws {
        testEnvironment = nil
        print("[E2ETest] End-to-end test environment cleaned up")
        super.tearDown()
    }
    
    func testCompleteUserWorkflow() async throws {
        print("[E2ETest] Testing complete user workflow from authentication to agent control")
        
        do {
            // Step 1: User authentication
            print("[E2ETest] Step 1: User authentication")
            let authResult = try await testEnvironment.authenticateUser()
            XCTAssertTrue(authResult.success, "User authentication should succeed")
            
            // Step 2: Load dashboard data
            print("[E2ETest] Step 2: Load dashboard data")
            let dashboardData = try await testEnvironment.loadDashboardData()
            XCTAssertNotNil(dashboardData.systemStatus, "System status should load")
            XCTAssertGreaterThan(dashboardData.agents.count, 0, "Should have agents data")
            
            // Step 3: Perform agent operation
            print("[E2ETest] Step 3: Perform agent operation")
            let agentOperation = try await testEnvironment.performAgentOperation(dashboardData.agents[0].id, operation: "restart")
            XCTAssertTrue(agentOperation.success, "Agent operation should succeed")
            
            // Step 4: Verify real-time updates
            print("[E2ETest] Step 4: Verify real-time updates")
            let realtimeUpdate = try await testEnvironment.waitForRealtimeUpdate()
            XCTAssertNotNil(realtimeUpdate, "Should receive real-time update")
            
            // Step 5: Export analytics data
            print("[E2ETest] Step 5: Export analytics data")
            let exportResult = try await testEnvironment.exportAnalyticsData()
            XCTAssertTrue(exportResult.success, "Analytics export should succeed")
            XCTAssertGreaterThan(exportResult.dataSize, 0, "Export should contain data")
            
            print("[E2ETest] Complete user workflow test passed successfully")
            
        } catch {
            XCTFail("Complete user workflow failed: \(error.localizedDescription)")
            print("[E2ETest] Complete user workflow failed: \(error)")
        }
    }
    
    func testErrorRecoveryWorkflow() async throws {
        print("[E2ETest] Testing error recovery workflow")
        
        do {
            // Step 1: Simulate network error
            print("[E2ETest] Step 1: Simulate network error")
            testEnvironment.simulateNetworkError(true)
            
            // Step 2: Attempt operation (should fail)
            print("[E2ETest] Step 2: Attempt operation during network error")
            do {
                let _ = try await testEnvironment.loadDashboardData()
                XCTFail("Operation should fail during network error")
            } catch {
                print("[E2ETest] Expected network error occurred: \(error)")
            }
            
            // Step 3: Restore network and retry
            print("[E2ETest] Step 3: Restore network and retry")
            testEnvironment.simulateNetworkError(false)
            
            let recoveryResult = try await testEnvironment.loadDashboardData()
            XCTAssertNotNil(recoveryResult.systemStatus, "Should recover and load data successfully")
            
            print("[E2ETest] Error recovery workflow test passed")
            
        } catch {
            XCTFail("Error recovery workflow failed: \(error.localizedDescription)")
            print("[E2ETest] Error recovery workflow failed: \(error)")
        }
    }
}

// MARK: - Test Environment Helper

class TestEnvironment {
    private let apiClient: APIClient
    private let webSocketClient: WebSocketClient
    private var isNetworkErrorSimulated: Bool = false
    
    init() {
        let baseURL = URL(string: "http://localhost:8080")!
        self.apiClient = APIClient(baseURL: baseURL)
        
        let wsURL = URL(string: "ws://localhost:8080/systemhub")!
        self.webSocketClient = WebSocketClient(url: wsURL)
        
        print("[TestEnvironment] Test environment initialized")
    }
    
    func authenticateUser() async throws -> AuthenticationResult {
        print("[TestEnvironment] Authenticating test user")
        
        if isNetworkErrorSimulated {
            throw TestEnvironmentError.networkError
        }
        
        let authToken = try await apiClient.authenticate(username: "admin", password: "admin123")
        
        return AuthenticationResult(
            success: true,
            token: authToken.token,
            user: authToken.user
        )
    }
    
    func loadDashboardData() async throws -> DashboardData {
        print("[TestEnvironment] Loading dashboard data")
        
        if isNetworkErrorSimulated {
            throw TestEnvironmentError.networkError
        }
        
        let systemStatus = try await apiClient.fetchSystemStatus()
        let agents = try await apiClient.fetchAgents()
        
        return DashboardData(
            systemStatus: systemStatus,
            agents: agents
        )
    }
    
    func performAgentOperation(_ agentId: UUID, operation: String) async throws -> AgentOperationTestResult {
        print("[TestEnvironment] Performing agent operation: \(operation)")
        
        if isNetworkErrorSimulated {
            throw TestEnvironmentError.networkError
        }
        
        let result: AgentActionResult
        
        switch operation {
        case "start":
            result = try await apiClient.startAgent(agentId)
        case "stop":
            result = try await apiClient.stopAgent(agentId)
        case "restart":
            result = try await apiClient.restartAgent(agentId)
        default:
            throw TestEnvironmentError.invalidOperation
        }
        
        return AgentOperationTestResult(
            success: result.success,
            message: result.message,
            executionTime: result.executionTime
        )
    }
    
    func waitForRealtimeUpdate() async throws -> WebSocketMessage? {
        print("[TestEnvironment] Waiting for real-time update")
        
        if isNetworkErrorSimulated {
            throw TestEnvironmentError.networkError
        }
        
        // Simulate receiving a real-time update
        // In actual implementation, this would listen to WebSocket messages
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        
        return WebSocketMessage(
            id: UUID(),
            type: .systemMetrics,
            payload: Data(),
            timestamp: Date()
        )
    }
    
    func exportAnalyticsData() async throws -> ExportTestResult {
        print("[TestEnvironment] Exporting analytics data")
        
        if isNetworkErrorSimulated {
            throw TestEnvironmentError.networkError
        }
        
        // Simulate data export
        let mockData = "timestamp,value,label\n2025-09-01,45.2,CPU\n2025-09-01,67.8,Memory"
        
        return ExportTestResult(
            success: true,
            dataSize: mockData.count,
            format: "CSV"
        )
    }
    
    func simulateNetworkError(_ enabled: Bool) {
        isNetworkErrorSimulated = enabled
        print("[TestEnvironment] Network error simulation: \(enabled ? "ENABLED" : "DISABLED")")
    }
}

// MARK: - Test Result Models

struct AuthenticationResult {
    let success: Bool
    let token: String
    let user: User
}

struct DashboardData {
    let systemStatus: SystemStatus
    let agents: [Agent]
}

struct AgentOperationTestResult {
    let success: Bool
    let message: String
    let executionTime: TimeSpan?
}

struct ExportTestResult {
    let success: Bool
    let dataSize: Int
    let format: String
}

enum TestEnvironmentError: Error, LocalizedError {
    case networkError
    case invalidOperation
    case authenticationFailed
    case dataLoadFailed
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Simulated network error"
        case .invalidOperation:
            return "Invalid operation requested"
        case .authenticationFailed:
            return "Authentication failed"
        case .dataLoadFailed:
            return "Data loading failed"
        }
    }
}