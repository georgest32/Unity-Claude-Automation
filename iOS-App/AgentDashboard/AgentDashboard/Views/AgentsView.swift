//
//  AgentsView.swift
//  AgentDashboard
//

import SwiftUI
import ComposableArchitecture

struct AgentsView: View {
    let store: StoreOf<AgentsFeature>
    
    var body: some View {
        WithPerceptionTracking {
            NavigationView {
                List {
                    ForEach(store.agents) { agent in
                        AgentRow(agent: agent) {
                            store.send(.agentTapped(agent))
                        }
                    }
                }
                .navigationTitle("Agents")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            store.send(.refreshAgents)
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
                .refreshable {
                    await store.send(.refreshAgents).finish()
                }
            }
            .onAppear {
                store.send(.onAppear)
            }
        }
    }
}

struct AgentRow: View {
    let agent: Agent
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Circle()
                    .fill(agent.isActive ? Color.green : Color.gray)
                    .frame(width: 12, height: 12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(agent.name)
                        .font(.headline)
                    Text(agent.status.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(agent.type.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.1))
                        .clipShape(Capsule())
                    
                    if let lastSeen = agent.lastSeen {
                        Text(lastSeen, style: .relative)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}