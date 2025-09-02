//
//  MessageTransformer.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Message transformation and payload parsing for different message types
//

import Foundation

// MARK: - Message Transformer Protocol

protocol MessageTransformerProtocol {
    func transform(_ message: WebSocketMessage) async throws -> Any?
    func transformBatch(_ messages: [WebSocketMessage]) async throws -> [String: Any]
}

// MARK: - Transformation Errors

enum TransformationError: Error, LocalizedError {
    case unsupportedMessageType(WebSocketMessage.MessageType)
    case invalidPayloadFormat(String)
    case missingRequiredData(String)
    case transformationFailed(String, Error)
    
    var errorDescription: String? {
        switch self {
        case .unsupportedMessageType(let type):
            return "Unsupported message type: \(type.rawValue)"
        case .invalidPayloadFormat(let reason):
            return "Invalid payload format: \(reason)"
        case .missingRequiredData(let field):
            return "Missing required data: \(field)"
        case .transformationFailed(let context, let error):
            return "Transformation failed in \(context): \(error.localizedDescription)"
        }
    }
}

// MARK: - Message Transformer Implementation

final class MessageTransformer: MessageTransformerProtocol {
    
    private let decoder = JSONDecoder.apiDecoder
    private var transformationCache: [UUID: Any] = [:]
    private let cacheQueue = DispatchQueue(label: "com.agentdashboard.transformer.cache")
    
    func transform(_ message: WebSocketMessage) async throws -> Any? {
        print("[MessageTransformer] Transforming message type: \(message.type.rawValue)")
        
        // Check cache first
        if let cached = getCachedTransformation(for: message.id) {
            print("[MessageTransformer] Using cached transformation")
            return cached
        }
        
        let transformed: Any?
        
        switch message.type {
        case .systemMetrics:
            transformed = try await transformSystemMetrics(message.payload)
        case .agentStatus:
            transformed = try await transformAgentStatus(message.payload)
        case .terminalOutput:
            transformed = try await transformTerminalOutput(message.payload)
        case .commandResult:
            transformed = try await transformCommandResult(message.payload)
        case .alert:
            transformed = try await transformAlert(message.payload)
        case .heartbeat:
            transformed = try await transformHeartbeat(message.payload)
        }
        
        // Cache the transformation result
        if let transformed = transformed {
            cacheTransformation(for: message.id, result: transformed)
        }
        
        print("[MessageTransformer] Transformation completed successfully")
        return transformed
    }
    
    func transformBatch(_ messages: [WebSocketMessage]) async throws -> [String: Any] {
        print("[MessageTransformer] Transforming batch of \(messages.count) messages")
        
        var results: [String: Any] = [:]
        var systemMetrics: [SystemStatus] = []
        var agents: [Agent] = []
        var alerts: [Alert] = []
        var terminalLines: [String] = []
        
        // Transform messages concurrently
        await withTaskGroup(of: (UUID, Any?).self) { group in
            for message in messages {
                group.addTask {
                    do {
                        let transformed = try await self.transform(message)
                        return (message.id, transformed)
                    } catch {
                        print("[MessageTransformer] Failed to transform message \(message.id): \(error)")
                        return (message.id, nil)
                    }
                }
            }
            
            for await (messageId, transformed) in group {
                guard let transformed = transformed else { continue }
                
                // Group by type
                if let systemStatus = transformed as? SystemStatus {
                    systemMetrics.append(systemStatus)
                } else if let agent = transformed as? Agent {
                    agents.append(agent)
                } else if let alert = transformed as? Alert {
                    alerts.append(alert)
                } else if let terminalOutput = transformed as? String {
                    terminalLines.append(terminalOutput)
                }
            }
        }
        
        // Create batch results
        if !systemMetrics.isEmpty {
            results["systemMetrics"] = systemMetrics
            results["latestSystemStatus"] = systemMetrics.last
        }
        
        if !agents.isEmpty {
            results["agents"] = agents
            results["agentSummary"] = createAgentSummary(agents)
        }
        
        if !alerts.isEmpty {
            results["alerts"] = alerts
            results["criticalAlerts"] = alerts.filter { $0.severity == .critical || $0.severity == .error }
        }
        
        if !terminalLines.isEmpty {
            results["terminalOutput"] = terminalLines
            results["terminalSummary"] = ["lineCount": terminalLines.count, "lastOutput": terminalLines.last ?? ""]
        }
        
        results["batchMetadata"] = [
            "messageCount": messages.count,
            "transformedCount": systemMetrics.count + agents.count + alerts.count + terminalLines.count,
            "processingTime": Date(),
            "types": Set(messages.map { $0.type.rawValue }).sorted()
        ]
        
        print("[MessageTransformer] Batch transformation completed")
        return results
    }
    
    // MARK: - Type-Specific Transformations
    
    private func transformSystemMetrics(_ payload: Data) async throws -> SystemStatus {
        do {
            // Try direct deserialization first
            if let systemStatus = try? decoder.decode(SystemStatus.self, from: payload) {
                return enhanceSystemStatus(systemStatus)
            }
            
            // Try DTO transformation
            if let dto = try? decoder.decode(SystemStatusDTO.self, from: payload) {
                let metricsDTO = try? decoder.decode(SystemMetricsDTO.self, from: payload)
                return enhanceSystemStatus(dto.toSystemStatus(with: metricsDTO))
            }
            
            throw TransformationError.invalidPayloadFormat("Unable to parse SystemStatus or SystemStatusDTO")
        } catch {
            throw TransformationError.transformationFailed("SystemMetrics", error)
        }
    }
    
    private func transformAgentStatus(_ payload: Data) async throws -> Agent {
        do {
            // Try direct deserialization first
            if let agent = try? decoder.decode(Agent.self, from: payload) {
                return enhanceAgent(agent)
            }
            
            // Try DTO transformation
            if let dto = try? decoder.decode(AgentDTO.self, from: payload) {
                return enhanceAgent(dto.toAgent())
            }
            
            throw TransformationError.invalidPayloadFormat("Unable to parse Agent or AgentDTO")
        } catch {
            throw TransformationError.transformationFailed("AgentStatus", error)
        }
    }
    
    private func transformTerminalOutput(_ payload: Data) async throws -> String {
        do {
            // Try string decoding
            if let outputString = String(data: payload, encoding: .utf8) {
                return cleanTerminalOutput(outputString)
            }
            
            // Try JSON structure
            if let json = try? JSONSerialization.jsonObject(with: payload, options: []) as? [String: Any],
               let output = json["output"] as? String {
                return cleanTerminalOutput(output)
            }
            
            throw TransformationError.invalidPayloadFormat("Terminal output must be UTF-8 string or JSON with 'output' field")
        } catch {
            throw TransformationError.transformationFailed("TerminalOutput", error)
        }
    }
    
    private func transformCommandResult(_ payload: Data) async throws -> CommandResult {
        do {
            // Try direct deserialization first
            if let result = try? decoder.decode(CommandResult.self, from: payload) {
                return enhanceCommandResult(result)
            }
            
            // Try DTO transformation
            if let dto = try? decoder.decode(CommandResultDTO.self, from: payload) {
                return CommandResult(
                    id: UUID(),
                    command: "Unknown",
                    output: dto.output,
                    error: dto.errorMessage,
                    exitCode: dto.success ? 0 : 1,
                    executionTime: dto.executionTime ?? 0,
                    timestamp: Date()
                )
            }
            
            throw TransformationError.invalidPayloadFormat("Unable to parse CommandResult or CommandResultDTO")
        } catch {
            throw TransformationError.transformationFailed("CommandResult", error)
        }
    }
    
    private func transformAlert(_ payload: Data) async throws -> Alert {
        do {
            if let alert = try? decoder.decode(Alert.self, from: payload) {
                return enhanceAlert(alert)
            }
            
            throw TransformationError.invalidPayloadFormat("Unable to parse Alert")
        } catch {
            throw TransformationError.transformationFailed("Alert", error)
        }
    }
    
    private func transformHeartbeat(_ payload: Data) async throws -> [String: Any] {
        // Heartbeat can be empty or contain basic status info
        if payload.isEmpty {
            return ["status": "alive", "timestamp": Date()]
        }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: payload, options: []) as? [String: Any] {
                var heartbeat = json
                heartbeat["receivedAt"] = Date()
                return heartbeat
            }
            
            return ["status": "alive", "timestamp": Date(), "rawPayload": payload.count]
        } catch {
            return ["status": "alive", "timestamp": Date(), "error": error.localizedDescription]
        }
    }
    
    // MARK: - Enhancement Methods
    
    private func enhanceSystemStatus(_ status: SystemStatus) -> SystemStatus {
        // Add computed properties or derived metrics
        var enhanced = status
        
        // Add health score based on metrics
        let healthScore = calculateHealthScore(
            cpu: status.cpuUsage,
            memory: status.memoryUsage,
            disk: status.diskUsage
        )
        
        // Return enhanced system status (would need to modify SystemStatus to be mutable or create new instance)
        return status
    }
    
    private func enhanceAgent(_ agent: Agent) -> Agent {
        // Add computed properties or derived metrics
        var enhanced = agent
        
        // Calculate efficiency score if resource usage is available
        if let resourceUsage = agent.resourceUsage {
            let efficiencyScore = calculateEfficiencyScore(resourceUsage)
            // Would add to agent if it had efficiency property
        }
        
        return agent
    }
    
    private func enhanceCommandResult(_ result: CommandResult) -> CommandResult {
        // Parse and categorize command results
        return result
    }
    
    private func enhanceAlert(_ alert: Alert) -> Alert {
        // Add context or categorization
        return alert
    }
    
    private func cleanTerminalOutput(_ output: String) -> String {
        // Remove ANSI escape codes and clean up terminal output
        let cleaned = output.replacingOccurrences(of: "\\u001b\\[[0-9;]*m", with: "", options: .regularExpression)
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func calculateHealthScore(cpu: Double, memory: Double, disk: Double) -> Double {
        // Simple health score calculation
        let cpuScore = max(0, 100 - cpu) / 100.0
        let memoryScore = max(0, 100 - memory) / 100.0
        let diskScore = max(0, 100 - disk) / 100.0
        
        return (cpuScore + memoryScore + diskScore) / 3.0
    }
    
    private func calculateEfficiencyScore(_ resourceUsage: ResourceUsage) -> Double {
        // Calculate efficiency based on resource usage patterns
        let cpuEfficiency = min(resourceUsage.cpu / 50.0, 1.0) // Optimal around 50% CPU
        let memoryEfficiency = min(resourceUsage.memory / 60.0, 1.0) // Optimal around 60% memory
        
        return (cpuEfficiency + memoryEfficiency) / 2.0
    }
    
    private func createAgentSummary(_ agents: [Agent]) -> [String: Any] {
        let statusCounts = agents.reduce(into: [String: Int]()) { counts, agent in
            counts[agent.status.rawValue, default: 0] += 1
        }
        
        let typeCounts = agents.reduce(into: [String: Int]()) { counts, agent in
            counts[agent.type.rawValue, default: 0] += 1
        }
        
        let totalCPU = agents.compactMap { $0.resourceUsage?.cpu }.reduce(0, +)
        let totalMemory = agents.compactMap { $0.resourceUsage?.memory }.reduce(0, +)
        
        return [
            "totalAgents": agents.count,
            "statusCounts": statusCounts,
            "typeCounts": typeCounts,
            "averageCPU": agents.isEmpty ? 0 : totalCPU / Double(agents.count),
            "averageMemory": agents.isEmpty ? 0 : totalMemory / Double(agents.count),
            "lastUpdate": Date()
        ]
    }
    
    // MARK: - Caching
    
    private func getCachedTransformation(for messageId: UUID) -> Any? {
        return cacheQueue.sync {
            return transformationCache[messageId]
        }
    }
    
    private func cacheTransformation(for messageId: UUID, result: Any) {
        cacheQueue.sync {
            transformationCache[messageId] = result
            
            // Limit cache size
            if transformationCache.count > 100 {
                let oldestKey = transformationCache.keys.first!
                transformationCache.removeValue(forKey: oldestKey)
            }
        }
    }
    
    func clearCache() {
        cacheQueue.sync {
            transformationCache.removeAll()
            print("[MessageTransformer] Cache cleared")
        }
    }
}