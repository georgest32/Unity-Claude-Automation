//
//  AppFeature.swift
//  AgentDashboard
//
//  Created on 2025-08-31
//  Root TCA Feature for app state management
//

import ComposableArchitecture
import Foundation

@Reducer
struct AppFeature {
    // MARK: - State
    struct State: Equatable {
        // Navigation
        var selectedTab: Tab = .dashboard
        
        // Feature states
        var dashboard = DashboardFeature.State()
        var agents = AgentsFeature.State()
        var terminal = TerminalFeature.State()
        var analytics = AnalyticsFeature.State()
        var settings = SettingsFeature.State()
        
        // Global app state
        var isConnected: Bool = false
        var connectionStatus: ConnectionStatus = .disconnected
        var currentUser: User?
        var systemStatus: SystemStatus?
        
        // Debug mode
        var isDebugMode: Bool = false
        
        enum Tab: String, CaseIterable {
            case dashboard = "Dashboard"
            case agents = "Agents"
            case terminal = "Terminal"
            case analytics = "Analytics"
            case settings = "Settings"
            
            var icon: String {
                switch self {
                case .dashboard: return "square.grid.2x2"
                case .agents: return "cpu"
                case .terminal: return "terminal"
                case .analytics: return "chart.line.uptrend.xyaxis"
                case .settings: return "gear"
                }
            }
        }
    }
    
    // MARK: - Action
    enum Action: Equatable {
        // Navigation
        case tabSelected(State.Tab)
        
        // Feature actions
        case dashboard(DashboardFeature.Action)
        case agents(AgentsFeature.Action)
        case terminal(TerminalFeature.Action)
        case analytics(AnalyticsFeature.Action)
        case settings(SettingsFeature.Action)
        
        // Connection actions
        case connect
        case disconnect
        case connectionStatusChanged(ConnectionStatus)
        
        // WebSocket events
        case webSocketConnected
        case webSocketDisconnected
        case webSocketMessageReceived(WebSocketMessage)
        case webSocketError(String)
        
        // App lifecycle
        case onAppear
        case onDisappear
        case enterBackground
        case enterForeground
        
        // Debug actions
        case toggleDebugMode
    }
    
    // MARK: - Dependencies
    @Dependency(\.apiClient) var apiClient
    @Dependency(\.webSocketClient) var webSocketClient
    @Dependency(\.continuousClock) var clock
    
    // MARK: - Reducer
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            // Navigation
            case let .tabSelected(tab):
                print("[AppFeature] Tab selected: \(tab.rawValue)")
                state.selectedTab = tab
                return .none
                
            // Connection management
            case .connect:
                print("[AppFeature] Initiating connection...")
                state.connectionStatus = .connecting
                return .run { send in
                    do {
                        try await webSocketClient.connect()
                        await send(.webSocketConnected)
                    } catch {
                        await send(.webSocketError(error.localizedDescription))
                    }
                }
                
            case .disconnect:
                print("[AppFeature] Disconnecting...")
                state.connectionStatus = .disconnecting
                return .run { send in
                    await webSocketClient.disconnect()
                    await send(.webSocketDisconnected)
                }
                
            case let .connectionStatusChanged(status):
                print("[AppFeature] Connection status changed: \(status)")
                state.connectionStatus = status
                state.isConnected = (status == .connected)
                return .none
                
            // WebSocket events
            case .webSocketConnected:
                print("[AppFeature] WebSocket connected successfully")
                state.connectionStatus = .connected
                state.isConnected = true
                return .run { send in
                    // Start listening for messages
                    for await message in webSocketClient.messages() {
                        await send(.webSocketMessageReceived(message))
                    }
                }
                
            case .webSocketDisconnected:
                print("[AppFeature] WebSocket disconnected")
                state.connectionStatus = .disconnected
                state.isConnected = false
                return .none
                
            case let .webSocketMessageReceived(message):
                print("[AppFeature] Received WebSocket message: \(message.type)")
                // Route message to appropriate feature
                return routeWebSocketMessage(message, state: &state)
                
            case let .webSocketError(error):
                print("[AppFeature] WebSocket error: \(error)")
                state.connectionStatus = .error(error)
                state.isConnected = false
                return .none
                
            // App lifecycle
            case .onAppear:
                print("[AppFeature] App appeared")
                return .send(.connect)
                
            case .onDisappear:
                print("[AppFeature] App disappeared")
                return .send(.disconnect)
                
            case .enterBackground:
                print("[AppFeature] App entering background")
                // Maintain connection for up to 3 minutes
                return .none
                
            case .enterForeground:
                print("[AppFeature] App entering foreground")
                if !state.isConnected {
                    return .send(.connect)
                }
                return .none
                
            // Debug
            case .toggleDebugMode:
                state.isDebugMode.toggle()
                print("[AppFeature] Debug mode: \(state.isDebugMode)")
                return .none
                
            // Feature actions (handled by child reducers)
            case .dashboard, .agents, .terminal, .analytics, .settings:
                return .none
            }
        }
        
        // Compose child reducers
        Scope(state: \.dashboard, action: /Action.dashboard) {
            DashboardFeature()
        }
        Scope(state: \.agents, action: /Action.agents) {
            AgentsFeature()
        }
        Scope(state: \.terminal, action: /Action.terminal) {
            TerminalFeature()
        }
        Scope(state: \.analytics, action: /Action.analytics) {
            AnalyticsFeature()
        }
        Scope(state: \.settings, action: /Action.settings) {
            SettingsFeature()
        }
    }
    
    // MARK: - Helper Methods
    private func routeWebSocketMessage(_ message: WebSocketMessage, state: inout State) -> Effect<Action> {
        switch message.type {
        case .agentStatus:
            return .send(.agents(.updateAgentStatus(message.payload)))
        case .systemMetrics:
            return .send(.dashboard(.updateMetrics(message.payload)))
        case .terminalOutput:
            return .send(.terminal(.appendOutput(message.payload)))
        case .alert:
            return .send(.dashboard(.showAlert(message.payload)))
        default:
            print("[AppFeature] Unhandled message type: \(message.type)")
            return .none
        }
    }
}