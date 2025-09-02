import SwiftUI
import Foundation

struct ActivityFeedWidget: View {
    @State private var activities: [ActivityItem] = ActivityItem.sampleData
    @State private var selectedSeverity: ActivitySeverity? = nil
    
    var body: some View {
        WidgetContainerView(
            title: "Activity Feed",
            icon: "list.bullet.rectangle",
            size: .large
        ) {
            VStack(spacing: 12) {
                // Filter Controls
                HStack(spacing: 8) {
                    ForEach(ActivitySeverity.allCases, id: \.self) { severity in
                        FilterButton(
                            title: severity.shortName,
                            count: activities.filter { $0.severity == severity }.count,
                            color: severity.color,
                            isSelected: selectedSeverity == severity
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedSeverity = selectedSeverity == severity ? nil : severity
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Button {
                        selectedSeverity = nil
                    } label: {
                        Text("All")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(selectedSeverity == nil ? Color.accentColor : Color.gray.opacity(0.2))
                            .foregroundColor(selectedSeverity == nil ? .white : .primary)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 12)
                
                // Activity List
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredActivities) { activity in
                            ActivityRowView(activity: activity)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                
                // Footer with last update time
                HStack {
                    Text("Last updated: \(lastUpdateTimeFormatted)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button {
                        refreshActivities()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
        }
    }
    
    private var filteredActivities: [ActivityItem] {
        if let selectedSeverity = selectedSeverity {
            return activities.filter { $0.severity == selectedSeverity }
        }
        return activities
    }
    
    private var lastUpdateTimeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
    
    private func refreshActivities() {
        withAnimation {
            // In a real app, this would fetch from the API
            activities = ActivityItem.sampleData
        }
    }
}

// MARK: - Filter Button

struct FilterButton: View {
    let title: String
    let count: Int
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                
                Text(title)
                    .font(.caption)
                
                Text("\(count)")
                    .font(.caption2)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(color.opacity(0.2))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isSelected ? color.opacity(0.15) : Color.gray.opacity(0.1))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Activity Row View

struct ActivityRowView: View {
    let activity: ActivityItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Severity Indicator
            VStack {
                Circle()
                    .fill(activity.severity.color)
                    .frame(width: 8, height: 8)
                
                if activity.severity != .info {
                    Rectangle()
                        .fill(activity.severity.color.opacity(0.3))
                        .frame(width: 2)
                }
            }
            .frame(height: 40)
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(activity.title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(activity.timeAgo)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Text(activity.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                if let source = activity.source {
                    Text("from \(source)")
                        .font(.caption2)
                        .foregroundColor(.tertiary)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(UIColor.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Activity Models

struct ActivityItem: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let description: String
    let severity: ActivitySeverity
    let timestamp: Date
    let source: String?
    
    var timeAgo: String {
        let interval = Date().timeIntervalSince(timestamp)
        
        if interval < 60 {
            return "now"
        } else if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))h ago"
        } else {
            return "\(Int(interval / 86400))d ago"
        }
    }
    
    static let sampleData: [ActivityItem] = [
        ActivityItem(
            title: "CLI Orchestrator Started",
            description: "Main orchestration system initialized successfully",
            severity: .success,
            timestamp: Date().addingTimeInterval(-120),
            source: "CLIOrchestrator"
        ),
        ActivityItem(
            title: "High Memory Usage Detected",
            description: "Memory usage exceeded 85% threshold",
            severity: .warning,
            timestamp: Date().addingTimeInterval(-300),
            source: "PerformanceMonitor"
        ),
        ActivityItem(
            title: "Agent Connection Failed",
            description: "Unable to establish connection with Change Intelligence agent",
            severity: .error,
            timestamp: Date().addingTimeInterval(-450),
            source: "ChangeIntelligence"
        ),
        ActivityItem(
            title: "Documentation Generated",
            description: "Successfully generated 15 documentation pages",
            severity: .info,
            timestamp: Date().addingTimeInterval(-600),
            source: "DocumentationEngine"
        ),
        ActivityItem(
            title: "Alert Classification Updated",
            description: "ML model updated with 97.8% accuracy",
            severity: .success,
            timestamp: Date().addingTimeInterval(-840),
            source: "AlertClassifier"
        ),
        ActivityItem(
            title: "System Health Check",
            description: "All core systems operating within normal parameters",
            severity: .info,
            timestamp: Date().addingTimeInterval(-1200),
            source: "SystemMonitor"
        )
    ]
}

enum ActivitySeverity: String, CaseIterable {
    case error = "error"
    case warning = "warning"
    case success = "success"
    case info = "info"
    
    var color: Color {
        switch self {
        case .error: return .red
        case .warning: return .orange
        case .success: return .green
        case .info: return .blue
        }
    }
    
    var shortName: String {
        switch self {
        case .error: return "Errors"
        case .warning: return "Warnings"
        case .success: return "Success"
        case .info: return "Info"
        }
    }
}

// MARK: - Preview

#Preview {
    ActivityFeedWidget()
        .frame(height: 200)
        .padding()
}