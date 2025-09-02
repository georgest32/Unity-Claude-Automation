import SwiftUI
import ComposableArchitecture

struct AgentMonitorWidget: View {
    @State private var agents: [Agent] = Agent.realAgents
    @State private var selectedAgentId: String?
    
    var body: some View {
        WidgetContainerView(
            title: "Agent Monitor",
            icon: "person.2.fill",
            size: .large
        ) {
            VStack(spacing: 12) {
                // Summary Row
                HStack(spacing: 16) {
                    AgentSummaryCard(
                        title: "Active",
                        count: activeAgentsCount,
                        color: .green
                    )
                    
                    AgentSummaryCard(
                        title: "Idle",
                        count: idleAgentsCount,
                        color: .orange
                    )
                    
                    AgentSummaryCard(
                        title: "Error",
                        count: errorAgentsCount,
                        color: .red
                    )
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                
                Divider()
                
                // Agent List
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(agents) { agent in
                            AgentRowView(
                                agent: agent,
                                isSelected: selectedAgentId == agent.id,
                                onTap: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedAgentId = agent.id
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                
                // Quick Actions
                HStack(spacing: 12) {
                    Button(action: startAllAgents) {
                        Label("Start All", systemImage: "play.fill")
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    
                    Button(action: stopAllAgents) {
                        Label("Stop All", systemImage: "stop.fill")
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
        .onAppear {
            agents = Agent.realAgents
        }
    }
    
    private var activeAgentsCount: Int {
        agents.filter { $0.status == .running }.count
    }
    
    private var idleAgentsCount: Int {
        agents.filter { $0.status == .idle }.count
    }
    
    private var errorAgentsCount: Int {
        agents.filter { $0.status == .error }.count
    }
    
    private func startAllAgents() {
        print("Starting all agents...")
        // TODO: Implement start all agents
    }
    
    private func stopAllAgents() {
        print("Stopping all agents...")
        // TODO: Implement stop all agents
    }
}

// MARK: - Agent Summary Card

struct AgentSummaryCard: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Agent Row View

struct AgentRowView: View {
    let agent: Agent
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Status Indicator
                Circle()
                    .fill(agent.status.color)
                    .frame(width: 8, height: 8)
                
                // Agent Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(agent.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(agent.description ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Resource Usage
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "cpu")
                            .font(.system(size: 10))
                        Text("\(agent.cpuUsage, specifier: "%.1f")%")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "memorychip")
                            .font(.system(size: 10))
                        Text("\(agent.memoryUsage, specifier: "%.0f") MB")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.secondary)
                }
                
                // Action Button
                Button(action: {}) {
                    Image(systemName: agent.status == .running ? "pause.fill" : "play.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    AgentMonitorWidget()
        .frame(height: 240)
        .padding()
}