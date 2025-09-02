import ComposableArchitecture
import Foundation

// MARK: - WebSocket Client

@DependencyClient
public struct WebSocketClient {
    public var connect: @Sendable () async throws -> Void
    public var disconnect: @Sendable () async throws -> Void
    public var send: @Sendable (Data) async throws -> Void
    public var receive: @Sendable () -> AsyncStream<WebSocketMessage>
    public var isConnected: @Sendable () -> Bool
}

extension WebSocketClient: DependencyKey {
    public static let liveValue = WebSocketClient(
        connect: {
            // Connect to Unity-Claude-Automation WebSocket endpoint
            print("📡 WebSocket: Connecting to Unity-Claude-Automation system...")
            try await Task.sleep(for: .milliseconds(1000))
            print("📡 WebSocket: Connected successfully")
        },
        disconnect: {
            print("📡 WebSocket: Disconnecting...")
            try await Task.sleep(for: .milliseconds(250))
            print("📡 WebSocket: Disconnected")
        },
        send: { data in
            print("📡 WebSocket: Sending \(data.count) bytes")
        },
        receive: {
            // Create a mock stream of WebSocket messages
            AsyncStream { continuation in
                Task {
                    // Simulate periodic status updates
                    while !Task.isCancelled {
                        try await Task.sleep(for: .seconds(5))
                        
                        let message = WebSocketMessage(
                            id: UUID().uuidString,
                            type: .systemStatus,
                            payload: mockSystemStatusPayload(),
                            timestamp: Date()
                        )
                        
                        continuation.yield(message)
                    }
                    continuation.finish()
                }
            }
        },
        isConnected: { true }
    )
    
    public static let testValue = WebSocketClient(
        connect: {},
        disconnect: {},
        send: { _ in },
        receive: { AsyncStream { _ in } },
        isConnected: { false }
    )
}

extension DependencyValues {
    public var webSocketClient: WebSocketClient {
        get { self[WebSocketClient.self] }
        set { self[WebSocketClient.self] = newValue }
    }
}

// MARK: - Mock Data

private func mockSystemStatusPayload() -> Data {
    let status = [
        "timestamp": Date().timeIntervalSince1970,
        "agents": [
            ["id": "cli-orchestrator", "status": "running", "cpu": 12.5, "memory": 245.8],
            ["id": "alert-classifier", "status": "running", "cpu": 8.3, "memory": 156.4],
            ["id": "documentation-engine", "status": "idle", "cpu": 0.8, "memory": 89.2]
        ],
        "system": [
            "total_cpu": 21.6,
            "total_memory": 492.0,
            "uptime": 25920
        ]
    ] as [String: Any]
    
    return try! JSONSerialization.data(withJSONObject: status)
}