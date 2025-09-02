//
//  WebSocketClient.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  WebSocket client implementation with AsyncThrowingStream integration
//

import Foundation
import Dependencies

// MARK: - WebSocket Client Protocol

protocol WebSocketClientProtocol {
    func connect() async throws
    func disconnect() async
    func send(_ message: WebSocketMessage) async throws
    func messages() -> AsyncThrowingStream<WebSocketMessage, Error>
    var isConnected: Bool { get async }
}

// MARK: - WebSocket Client Implementation

final class WebSocketClient: WebSocketClientProtocol {
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession
    private var url: URL
    private var isTaskConnected = false
    
    // Message stream continuation
    private var messageContinuation: AsyncThrowingStream<WebSocketMessage, Error>.Continuation?
    
    init(url: URL, session: URLSession = .shared) {
        self.url = url
        self.session = session
        print("[WebSocketClient] Initialized with URL: \(url)")
    }
    
    var isConnected: Bool {
        get async {
            return isTaskConnected
        }
    }
    
    func connect() async throws {
        print("[WebSocketClient] Attempting to connect to \(url)")
        
        // Clean up existing connection
        await disconnect()
        
        // Create new WebSocket task
        webSocketTask = session.webSocketTask(with: url)
        
        guard let task = webSocketTask else {
            throw WebSocketError.connectionFailed("Failed to create WebSocket task")
        }
        
        // Resume the task
        task.resume()
        
        // Wait a moment for connection to establish
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        isTaskConnected = true
        print("[WebSocketClient] Connected successfully")
    }
    
    func disconnect() async {
        print("[WebSocketClient] Disconnecting...")
        
        if let task = webSocketTask {
            task.cancel(with: .goingAway, reason: nil)
        }
        
        isTaskConnected = false
        webSocketTask = nil
        messageContinuation?.finish()
        messageContinuation = nil
        
        print("[WebSocketClient] Disconnected")
    }
    
    func send(_ message: WebSocketMessage) async throws {
        guard let task = webSocketTask, isTaskConnected else {
            throw WebSocketError.notConnected
        }
        
        print("[WebSocketClient] Sending message: \(message.type.rawValue)")
        
        do {
            let data = try JSONEncoder().encode(message)
            let urlMessage = URLSessionWebSocketTask.Message.data(data)
            try await task.send(urlMessage)
            
            print("[WebSocketClient] Message sent successfully")
        } catch {
            print("[WebSocketClient] Failed to send message: \(error)")
            throw WebSocketError.sendFailed(error)
        }
    }
    
    func messages() -> AsyncThrowingStream<WebSocketMessage, Error> {
        return AsyncThrowingStream<WebSocketMessage, Error> { continuation in
            self.messageContinuation = continuation
            
            continuation.onTermination = { @Sendable _ in
                print("[WebSocketClient] Message stream terminated")
            }
            
            // Start listening for messages
            Task {
                await self.startListening(continuation: continuation)
            }
        }
    }
    
    private func startListening(continuation: AsyncThrowingStream<WebSocketMessage, Error>.Continuation) async {
        print("[WebSocketClient] Starting message listening...")
        
        while isTaskConnected, let task = webSocketTask {
            do {
                let urlMessage = try await task.receive()
                
                switch urlMessage {
                case .data(let data):
                    do {
                        let message = try JSONDecoder().decode(WebSocketMessage.self, from: data)
                        message.logReceived()
                        continuation.yield(message)
                    } catch {
                        print("[WebSocketClient] Failed to decode message: \(error)")
                        continuation.yield(with: .failure(WebSocketError.decodingFailed(error)))
                    }
                    
                case .string(let text):
                    print("[WebSocketClient] Received text message: \(text)")
                    // For text messages, try to parse as JSON
                    if let data = text.data(using: .utf8) {
                        do {
                            let message = try JSONDecoder().decode(WebSocketMessage.self, from: data)
                            message.logReceived()
                            continuation.yield(message)
                        } catch {
                            print("[WebSocketClient] Failed to decode text message: \(error)")
                            continuation.yield(with: .failure(WebSocketError.decodingFailed(error)))
                        }
                    }
                    
                @unknown default:
                    print("[WebSocketClient] Unknown message type received")
                }
                
            } catch {
                print("[WebSocketClient] Error receiving message: \(error)")
                
                // Check if this is a connection error
                if (error as NSError).code == NSURLErrorCancelled {
                    print("[WebSocketClient] Connection was cancelled")
                } else {
                    continuation.yield(with: .failure(WebSocketError.receiveFailed(error)))
                }
                break
            }
        }
        
        print("[WebSocketClient] Message listening stopped")
    }
}

// MARK: - WebSocket Errors

enum WebSocketError: Error, LocalizedError {
    case notConnected
    case connectionFailed(String)
    case sendFailed(Error)
    case receiveFailed(Error)
    case decodingFailed(Error)
    case encodingFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "WebSocket is not connected"
        case .connectionFailed(let reason):
            return "Connection failed: \(reason)"
        case .sendFailed(let error):
            return "Failed to send message: \(error.localizedDescription)"
        case .receiveFailed(let error):
            return "Failed to receive message: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "Failed to decode message: \(error.localizedDescription)"
        case .encodingFailed(let error):
            return "Failed to encode message: \(error.localizedDescription)"
        }
    }
}