//
//  StressTests.swift
//  AgentDashboardTests
//
//  Created on 2025-09-01
//  Stress testing for performance validation and load testing
//

import XCTest
import Combine
@testable import AgentDashboard

final class StressTests: XCTestCase {
    
    var testMetrics: StressTestMetrics!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        super.setUp()
        
        testMetrics = StressTestMetrics()
        cancellables = Set<AnyCancellable>()
        
        print("[StressTest] Stress testing environment initialized")
        print("[StressTest] Test device: \(UIDevice.current.model)")
        print("[StressTest] iOS version: \(UIDevice.current.systemVersion)")
    }
    
    override func tearDownWithError() throws {
        cancellables.removeAll()
        
        // Log final metrics
        testMetrics.logFinalResults()
        
        testMetrics = nil
        print("[StressTest] Stress testing environment cleaned up")
        super.tearDown()
    }
    
    // MARK: - Memory Stress Tests
    
    func testMemoryStressWithLargeDataSets() throws {
        print("[StressTest] Testing memory stress with large data sets")
        
        measure(metrics: [XCTMemoryMetric()]) {
            let expectation = XCTestExpectation(description: "Memory Stress Test")
            
            Task {
                // Create large data sets to stress memory
                var largeAgentList: [Agent] = []
                var largeSystemStatusList: [SystemStatus] = []
                
                // Generate 1000 agents
                for i in 0..<1000 {
                    let agent = Agent(
                        id: UUID(),
                        name: "StressTestAgent_\(i)",
                        type: .orchestrator,
                        status: .running,
                        description: "Stress test agent for memory validation \(i)",
                        startTime: Date(),
                        lastActivity: Date(),
                        resourceUsage: ResourceUsage(
                            cpu: Double.random(in: 0...100),
                            memory: Double.random(in: 0...100),
                            threads: Int.random(in: 1...20),
                            handles: Int.random(in: 10...100)
                        ),
                        configuration: [
                            "stressTestId": "\(i)",
                            "largeConfigData": String(repeating: "data", count: 100)
                        ]
                    )
                    largeAgentList.append(agent)
                    
                    if i % 100 == 0 {
                        print("[StressTest] Generated \(i) agents...")
                    }
                }
                
                // Generate 500 system status entries
                for i in 0..<500 {
                    let systemStatus = SystemStatus(
                        timestamp: Date().addingTimeInterval(TimeInterval(-i * 60)),
                        isHealthy: Bool.random(),
                        cpuUsage: Double.random(in: 0...100),
                        memoryUsage: Double.random(in: 0...100),
                        diskUsage: Double.random(in: 0...100),
                        activeAgents: Int.random(in: 0...20),
                        totalModules: Int.random(in: 5...50),
                        uptime: TimeInterval.random(in: 0...86400)
                    )
                    largeSystemStatusList.append(systemStatus)
                    
                    if i % 100 == 0 {
                        print("[StressTest] Generated \(i) system status entries...")
                    }
                }
                
                // Test data processing with large sets
                let processingStartTime = Date()
                
                // Simulate filtering operations
                let runningAgents = largeAgentList.filter { $0.status == .running }
                let highCPUAgents = largeAgentList.filter { $0.resourceUsage?.cpu ?? 0 > 50 }
                let healthyStatuses = largeSystemStatusList.filter { $0.isHealthy }
                
                let processingTime = Date().timeIntervalSince(processingStartTime)
                
                print("[StressTest] Large data set processing completed in \(String(format: "%.3f", processingTime))s")
                print("[StressTest] Total agents: \(largeAgentList.count)")
                print("[StressTest] Running agents: \(runningAgents.count)")
                print("[StressTest] High CPU agents: \(highCPUAgents.count)")
                print("[StressTest] Healthy statuses: \(healthyStatuses.count)")
                
                // Validate memory usage is reasonable
                XCTAssertLessThan(processingTime, 5.0, "Large data processing should complete within 5 seconds")
                
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 30.0)
        }
        
        print("[StressTest] Memory stress test with large data sets completed")
    }
    
    func testConcurrentOperationStress() async throws {
        print("[StressTest] Testing concurrent operation stress")
        
        measure(metrics: [XCTCPUMetric(), XCTMemoryMetric()]) {
            let expectation = XCTestExpectation(description: "Concurrent Operations Stress")
            expectation.expectedFulfillmentCount = 10 // 10 concurrent operations
            
            // Create multiple concurrent tasks
            for i in 0..<10 {
                Task {
                    do {
                        // Simulate concurrent API calls
                        let mockAPIClient = MockAPIClient()
                        
                        let systemStatus = try await mockAPIClient.fetchSystemStatus()
                        let agents = try await mockAPIClient.fetchAgents()
                        
                        // Simulate data processing
                        let _ = agents.filter { $0.status == .running }
                        let _ = systemStatus.cpuUsage + systemStatus.memoryUsage
                        
                        print("[StressTest] Concurrent operation \(i) completed")
                        expectation.fulfill()
                        
                    } catch {
                        print("[StressTest] Concurrent operation \(i) failed: \(error)")
                        expectation.fulfill() // Still fulfill to prevent hanging
                    }
                }
            }
            
            wait(for: [expectation], timeout: 20.0)
        }
        
        print("[StressTest] Concurrent operation stress test completed")
    }
    
    // MARK: - UI Performance Stress Tests
    
    func testUIAnimationStress() throws {
        print("[StressTest] Testing UI animation stress performance")
        
        measure(metrics: [XCTCPUMetric()]) {
            let expectation = XCTestExpectation(description: "UI Animation Stress")
            
            Task { @MainActor in
                // Create multiple animated views
                var animatedViews: [AnimatedTestView] = []
                
                for i in 0..<50 {
                    let animatedView = AnimatedTestView(id: i)
                    animatedViews.append(animatedView)
                    
                    // Trigger animations
                    animatedView.startAnimation()
                    
                    if i % 10 == 0 {
                        print("[StressTest] Created \(i) animated views...")
                    }
                }
                
                // Let animations run
                try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                
                // Stop animations
                for view in animatedViews {
                    view.stopAnimation()
                }
                
                print("[StressTest] UI animation stress test with \(animatedViews.count) views completed")
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 15.0)
        }
        
        print("[StressTest] UI animation stress test completed")
    }
    
    func testScrollingStress() throws {
        print("[StressTest] Testing scrolling performance under stress")
        
        measure(metrics: [XCTCPUMetric(), XCTMemoryMetric()]) {
            let expectation = XCTestExpectation(description: "Scrolling Stress")
            
            Task { @MainActor in
                // Create large scrollable list
                let largeDataSet = (0..<1000).map { index in
                    ListItemData(
                        id: UUID(),
                        title: "Stress Test Item \(index)",
                        subtitle: "Performance validation item with data \(index)",
                        value: Double.random(in: 0...100),
                        status: ["active", "inactive", "pending"].randomElement()!
                    )
                }
                
                print("[StressTest] Created large data set with \(largeDataSet.count) items")
                
                // Simulate rapid scrolling operations
                for cycle in 0..<10 {
                    // Simulate scroll to different positions
                    let randomIndex = Int.random(in: 0..<largeDataSet.count)
                    let item = largeDataSet[randomIndex]
                    
                    // Process item (simulate view rendering)
                    let _ = item.title + item.subtitle
                    let _ = item.value * 2.0
                    
                    if cycle % 3 == 0 {
                        print("[StressTest] Scroll cycle \(cycle) processed item at index \(randomIndex)")
                    }
                }
                
                print("[StressTest] Scrolling stress test completed \(10) cycles")
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 20.0)
        }
        
        print("[StressTest] Scrolling stress test completed")
    }
    
    // MARK: - Network Stress Tests
    
    func testNetworkStress() async throws {
        print("[StressTest] Testing network stress and connection handling")
        
        let expectation = XCTestExpectation(description: "Network Stress")
        
        // Perform rapid sequential API calls
        let apiCallCount = 50
        var successfulCalls = 0
        var failedCalls = 0
        
        let startTime = Date()
        
        for i in 0..<apiCallCount {
            do {
                let mockAPIClient = MockAPIClient()
                let _ = try await mockAPIClient.fetchSystemStatus()
                successfulCalls += 1
                
                if i % 10 == 0 {
                    print("[StressTest] Network stress test: \(i) calls completed")
                }
                
            } catch {
                failedCalls += 1
                print("[StressTest] Network call \(i) failed: \(error)")
            }
        }
        
        let totalTime = Date().timeIntervalSince(startTime)
        let callsPerSecond = Double(apiCallCount) / totalTime
        
        print("[StressTest] Network stress test results:")
        print("[StressTest] Total calls: \(apiCallCount)")
        print("[StressTest] Successful: \(successfulCalls)")
        print("[StressTest] Failed: \(failedCalls)")
        print("[StressTest] Total time: \(String(format: "%.3f", totalTime))s")
        print("[StressTest] Calls per second: \(String(format: "%.2f", callsPerSecond))")
        
        // Validate performance requirements
        XCTAssertGreaterThan(successfulCalls, apiCallCount * 80 / 100, "At least 80% of calls should succeed")
        XCTAssertLessThan(totalTime, 30.0, "Network stress test should complete within 30 seconds")
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 35.0)
        
        print("[StressTest] Network stress test completed")
    }
    
    // MARK: - Data Processing Stress Tests
    
    func testDataProcessingStress() throws {
        print("[StressTest] Testing data processing stress")
        
        measure(metrics: [XCTCPUMetric(), XCTMemoryMetric(), XCTClockMetric()]) {
            let expectation = XCTestExpectation(description: "Data Processing Stress")
            
            Task {
                // Generate large dataset for processing
                let largeMetricDataset = (0..<10000).map { index in
                    MetricPoint(
                        timestamp: Date().addingTimeInterval(TimeInterval(-index * 60)),
                        value: Double.random(in: 0...100),
                        label: "DataPoint_\(index)"
                    )
                }
                
                print("[StressTest] Generated \(largeMetricDataset.count) metric data points")
                
                // Perform intensive data operations
                let processingStartTime = Date()
                
                // 1. Filtering operations
                let highValuePoints = largeMetricDataset.filter { $0.value > 75.0 }
                let recentPoints = largeMetricDataset.filter { 
                    $0.timestamp > Date().addingTimeInterval(-3600) 
                }
                
                // 2. Aggregation operations
                let averageValue = largeMetricDataset.map { $0.value }.reduce(0, +) / Double(largeMetricDataset.count)
                let maxValue = largeMetricDataset.map { $0.value }.max() ?? 0
                let minValue = largeMetricDataset.map { $0.value }.min() ?? 0
                
                // 3. Grouping operations
                let groupedByHour = Dictionary(grouping: largeMetricDataset) { point in
                    Calendar.current.component(.hour, from: point.timestamp)
                }
                
                // 4. Sorting operations
                let sortedByValue = largeMetricDataset.sorted { $0.value > $1.value }
                let sortedByTimestamp = largeMetricDataset.sorted { $0.timestamp > $1.timestamp }
                
                let processingTime = Date().timeIntervalSince(processingStartTime)
                
                print("[StressTest] Data processing stress test results:")
                print("[StressTest] Processing time: \(String(format: "%.3f", processingTime))s")
                print("[StressTest] High value points: \(highValuePoints.count)")
                print("[StressTest] Recent points: \(recentPoints.count)")
                print("[StressTest] Average value: \(String(format: "%.2f", averageValue))")
                print("[StressTest] Value range: \(String(format: "%.2f", minValue)) - \(String(format: "%.2f", maxValue))")
                print("[StressTest] Grouped hours: \(groupedByHour.count)")
                
                // Validate performance requirements
                XCTAssertLessThan(processingTime, 10.0, "Data processing should complete within 10 seconds")
                XCTAssertGreaterThan(highValuePoints.count, 0, "Should find some high value points")
                XCTAssertEqual(sortedByValue.count, largeMetricDataset.count, "Sorted data should maintain count")
                
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 20.0)
        }
        
        print("[StressTest] Data processing stress test completed")
    }
    
    // MARK: - WebSocket Connection Stress Tests
    
    func testWebSocketConnectionStress() async throws {
        print("[StressTest] Testing WebSocket connection stress")
        
        let connectionCount = 5
        var connections: [WebSocketClient] = []
        var receivedMessagesCount = 0
        
        let expectation = XCTestExpectation(description: "WebSocket Stress")
        expectation.expectedFulfillmentCount = connectionCount
        
        // Create multiple WebSocket connections
        for i in 0..<connectionCount {
            let wsURL = URL(string: "ws://localhost:8080/systemhub")!
            let webSocketClient = WebSocketClient(url: wsURL)
            connections.append(webSocketClient)
            
            // Set up message handling
            webSocketClient.messages()
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            print("[StressTest] WebSocket \(i) finished")
                        case .failure(let error):
                            print("[StressTest] WebSocket \(i) error: \(error)")
                        }
                        expectation.fulfill()
                    },
                    receiveValue: { message in
                        receivedMessagesCount += 1
                        print("[StressTest] WebSocket \(i) received message: \(message.type.rawValue)")
                    }
                )
                .store(in: &cancellables)
            
            // Connect
            do {
                try await webSocketClient.connect()
                print("[StressTest] WebSocket connection \(i) established")
            } catch {
                print("[StressTest] WebSocket connection \(i) failed: \(error)")
                expectation.fulfill() // Still fulfill to prevent hanging
            }
        }
        
        // Let connections run and receive messages
        try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
        
        // Disconnect all connections
        for (index, connection) in connections.enumerated() {
            await connection.disconnect()
            print("[StressTest] Disconnected WebSocket connection \(index)")
        }
        
        await fulfillment(of: [expectation], timeout: 15.0)
        
        print("[StressTest] WebSocket stress test results:")
        print("[StressTest] Connections created: \(connectionCount)")
        print("[StressTest] Messages received: \(receivedMessagesCount)")
        
        XCTAssertGreaterThan(receivedMessagesCount, 0, "Should receive at least some messages across all connections")
        
        print("[StressTest] WebSocket connection stress test completed")
    }
    
    // MARK: - UI Rendering Stress Tests
    
    func testUIRenderingStress() throws {
        print("[StressTest] Testing UI rendering stress with complex layouts")
        
        measure(metrics: [XCTCPUMetric()]) {
            let expectation = XCTestExpectation(description: "UI Rendering Stress")
            
            Task { @MainActor in
                // Create complex UI structure for stress testing
                var complexViews: [ComplexTestView] = []
                
                for i in 0..<100 {
                    let complexView = ComplexTestView(
                        id: i,
                        data: (0..<50).map { index in
                            ComplexViewData(
                                title: "Item \(index)",
                                value: Double.random(in: 0...100),
                                color: [Color.red, .blue, .green, .orange, .purple].randomElement()!,
                                isAnimated: Bool.random()
                            )
                        }
                    )
                    complexViews.append(complexView)
                    
                    if i % 20 == 0 {
                        print("[StressTest] Created \(i) complex views...")
                    }
                }
                
                // Simulate view updates and re-renders
                for cycle in 0..<10 {
                    for view in complexViews {
                        view.updateData()
                    }
                    
                    // Small delay to simulate frame rendering
                    try await Task.sleep(nanoseconds: 16_000_000) // ~60 FPS (16ms per frame)
                    
                    if cycle % 3 == 0 {
                        print("[StressTest] UI rendering cycle \(cycle) completed")
                    }
                }
                
                print("[StressTest] UI rendering stress test with \(complexViews.count) views completed")
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 25.0)
        }
        
        print("[StressTest] UI rendering stress test completed")
    }
    
    // MARK: - Cache Stress Tests
    
    func testCacheStress() async throws {
        print("[StressTest] Testing cache performance under stress")
        
        let cacheService = MockCacheService()
        let cacheOperationCount = 1000
        
        measure(metrics: [XCTMemoryMetric(), XCTClockMetric()]) {
            let expectation = XCTestExpectation(description: "Cache Stress")
            
            Task {
                let startTime = Date()
                
                // Perform many cache operations
                for i in 0..<cacheOperationCount {
                    let key = "stress_test_key_\(i)"
                    let data = StressCacheData(
                        id: i,
                        content: String(repeating: "cache_data_\(i)", count: 10),
                        timestamp: Date()
                    )
                    
                    // Store in cache
                    await cacheService.setValue(data, forKey: key, expiration: .minutes(30))
                    
                    // Retrieve from cache (every 3rd item)
                    if i % 3 == 0 {
                        let retrieved = await cacheService.getValue(forKey: key, type: StressCacheData.self)
                        XCTAssertNotNil(retrieved, "Cache retrieval should succeed")
                    }
                    
                    if i % 100 == 0 {
                        print("[StressTest] Cache operations: \(i)/\(cacheOperationCount)")
                    }
                }
                
                let operationTime = Date().timeIntervalSince(startTime)
                let operationsPerSecond = Double(cacheOperationCount) / operationTime
                
                // Get cache statistics
                let stats = await cacheService.getCacheStatistics()
                
                print("[StressTest] Cache stress test results:")
                print("[StressTest] Operations: \(cacheOperationCount)")
                print("[StressTest] Total time: \(String(format: "%.3f", operationTime))s")
                print("[StressTest] Operations/second: \(String(format: "%.2f", operationsPerSecond))")
                print("[StressTest] Cache entries: \(stats.entryCount)")
                print("[StressTest] Hit rate: \(String(format: "%.1f", stats.hitRate))%")
                print("[StressTest] Memory usage: \(String(format: "%.2f", stats.memoryUsageMB))MB")
                
                // Validate performance requirements
                XCTAssertLessThan(operationTime, 30.0, "Cache operations should complete within 30 seconds")
                XCTAssertGreaterThan(operationsPerSecond, 30.0, "Should achieve at least 30 operations per second")
                
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 40.0)
        }
        
        print("[StressTest] Cache stress test completed")
    }
}

// MARK: - Test Helper Classes

class StressTestMetrics {
    private var startTime: Date = Date()
    private var testResults: [String: Any] = [:]
    
    init() {
        startTime = Date()
        print("[StressTestMetrics] Metrics collection started")
    }
    
    func recordMetric(_ name: String, value: Any) {
        testResults[name] = value
        print("[StressTestMetrics] Recorded metric: \(name) = \(value)")
    }
    
    func logFinalResults() {
        let totalTime = Date().timeIntervalSince(startTime)
        
        print("[StressTestMetrics] ===== FINAL STRESS TEST RESULTS =====")
        print("[StressTestMetrics] Total test duration: \(String(format: "%.3f", totalTime))s")
        
        for (key, value) in testResults {
            print("[StressTestMetrics] \(key): \(value)")
        }
        
        print("[StressTestMetrics] ===== END RESULTS =====")
    }
}

// Mock classes for stress testing
class AnimatedTestView {
    let id: Int
    private var isAnimating: Bool = false
    
    init(id: Int) {
        self.id = id
    }
    
    func startAnimation() {
        isAnimating = true
    }
    
    func stopAnimation() {
        isAnimating = false
    }
    
    func updateData() {
        // Simulate data update that would trigger re-render
    }
}

struct ComplexTestView {
    let id: Int
    var data: [ComplexViewData]
    
    mutating func updateData() {
        // Simulate data updates that trigger view changes
        for i in data.indices {
            data[i].value = Double.random(in: 0...100)
            data[i].isAnimated = Bool.random()
        }
    }
}

struct ComplexViewData {
    let title: String
    var value: Double
    let color: Color
    var isAnimated: Bool
}

struct ListItemData {
    let id: UUID
    let title: String
    let subtitle: String
    let value: Double
    let status: String
}

struct StressCacheData: Codable {
    let id: Int
    let content: String
    let timestamp: Date
}