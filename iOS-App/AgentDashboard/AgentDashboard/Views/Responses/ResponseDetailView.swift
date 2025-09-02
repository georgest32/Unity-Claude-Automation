//
//  ResponseDetailView.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Detailed response viewer with Markdown formatting and actions
//  Hour 9.2: Response viewer UI foundation
//

import SwiftUI

struct ResponseDetailView: View {
    let response: Response
    let onDismiss: () -> Void
    let onFavoriteToggle: () -> Void
    let onShare: () -> Void
    let onDelete: () -> Void
    
    @State private var showingFullMetadata = false
    @State private var isShowingShareSheet = false
    @State private var shareContent: ShareContent? = nil
    
    struct ShareContent {
        let content: String
        let title: String
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Response header
                    responseHeader
                    
                    // Response content
                    responseContent
                    
                    // Response metadata
                    responseMetadata
                    
                    // Response actions
                    responseActions
                }
                .padding()
            }
            .navigationTitle("Response Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                responseDetailToolbar
            }
        }
        .sheet(isPresented: $isShowingShareSheet) {
            if let shareContent = shareContent {
                ActivityViewController(activityItems: [shareContent.content])
            }
        }
    }
    
    // MARK: - Response Header
    
    private var responseHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: aiSystemIcon(response.aiSystem))
                        .foregroundColor(.blue)
                        .font(.title3)
                    
                    Text(response.aiSystem)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                Button(action: onFavoriteToggle) {
                    Image(systemName: response.isFavorite ? "star.fill" : "star")
                        .foregroundColor(response.isFavorite ? .yellow : .gray)
                        .font(.title3)
                }
            }
            
            HStack {
                Text("Generated \(response.createdAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(response.wordCount) words • ~\(Int(response.readingTimeMinutes))m read")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Category and type badges
            HStack(spacing: 8) {
                Text(response.category)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.blue)
                    .clipShape(Capsule())
                
                Text(response.responseType)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.green)
                    .clipShape(Capsule())
                
                if let metadata = response.responseMetadata {
                    Text(metadata.complexity.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(metadata.complexity.color)
                        .clipShape(Capsule())
                }
                
                Spacer()
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Response Content
    
    private var responseContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Response Content")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Enhanced content display with Markdown-like formatting
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Note: In production, would use MarkdownUI library
                    // For now, using enhanced Text with basic Markdown support
                    Text(LocalizedStringKey(response.content))
                        .font(.body)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Code blocks detection and highlighting
                    if response.content.contains("```") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Code Blocks Detected")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            // In production, would extract and highlight code blocks
                            Text("💡 Enhanced code highlighting available in production build")
                                .font(.caption)
                                .italic()
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .frame(minHeight: 200)
            .padding()
            .background(.gray.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    // MARK: - Response Metadata
    
    private var responseMetadata: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Metadata")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(showingFullMetadata ? "Less" : "More") {
                    showingFullMetadata.toggle()
                }
                .font(.caption)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                MetadataRow(label: "Response ID", value: response.id.uuidString.prefix(8) + "...")
                MetadataRow(label: "Source Command", value: response.sourceCommandID.uuidString.prefix(8) + "...")
                MetadataRow(label: "AI Mode", value: response.aiMode.capitalized)
                
                if showingFullMetadata {
                    MetadataRow(label: "Created", value: response.createdAt.formatted())
                    MetadataRow(label: "Last Viewed", value: response.lastViewedAt?.formatted() ?? "Never")
                    
                    if let metadata = response.responseMetadata {
                        MetadataRow(label: "Execution Time", value: "\(metadata.executionTime, specifier: "%.1f")s")
                        MetadataRow(label: "Prompt Length", value: "\(metadata.promptLength) chars")
                        MetadataRow(label: "Has Code", value: metadata.hasCodeBlocks ? "Yes" : "No")
                        MetadataRow(label: "Has Links", value: metadata.hasLinks ? "Yes" : "No")
                        MetadataRow(label: "Sentiment", value: metadata.sentiment.rawValue)
                        
                        if !metadata.topics.isEmpty {
                            MetadataRow(label: "Topics", value: metadata.topics.joined(separator: ", "))
                        }
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Response Actions
    
    private var responseActions: some View {
        VStack(spacing: 12) {
            Text("Actions")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ActionButton(
                    title: "Copy Content",
                    icon: "doc.on.clipboard",
                    color: .blue
                ) {
                    UIPasteboard.general.string = response.content
                }
                
                ActionButton(
                    title: "Share Response",
                    icon: "square.and.arrow.up",
                    color: .green
                ) {
                    shareContent = ShareContent(
                        content: response.content,
                        title: response.displayTitle
                    )
                    isShowingShareSheet = true
                }
                
                ActionButton(
                    title: response.isFavorite ? "Unfavorite" : "Favorite",
                    icon: response.isFavorite ? "star.slash" : "star",
                    color: .orange
                ) {
                    onFavoriteToggle()
                }
                
                ActionButton(
                    title: "Delete",
                    icon: "trash",
                    color: .red
                ) {
                    onDelete()
                    onDismiss()
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Toolbar
    
    private var responseDetailToolbar: some View {
        Group {
            Button("Done") {
                onDismiss()
            }
        }
    }
    
    private func aiSystemIcon(_ system: String) -> String {
        switch system {
        case "Claude Code CLI": return "terminal"
        case "AutoGen": return "person.3"
        case "LangGraph": return "flowchart"
        default: return "gear"
        }
    }
}

// MARK: - Supporting Views

struct MetadataRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
            
            Spacer()
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// UIActivityViewController wrapper for SwiftUI
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) {
        // No updates needed
    }
}

// MARK: - Preview

struct ResponseDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleResponse = Response(
            content: "# System Analysis Results\n\nThe current system is performing well with 94% uptime. Here are the key findings:\n\n## Performance Metrics\n- CPU Usage: 45%\n- Memory Usage: 62%\n- Queue Depth: 3 commands\n\n```swift\nfunc optimizePerformance() {\n    // Implementation here\n}\n```\n\n## Recommendations\n1. Increase memory allocation\n2. Implement caching\n3. Monitor queue depth",
            sourceCommandID: UUID(),
            aiSystem: "Claude Code CLI"
        )
        
        ResponseDetailView(
            response: sampleResponse,
            onDismiss: {},
            onFavoriteToggle: {},
            onShare: {},
            onDelete: {}
        )
    }
}