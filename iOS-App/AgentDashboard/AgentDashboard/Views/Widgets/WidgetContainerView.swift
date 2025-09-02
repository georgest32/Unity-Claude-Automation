import SwiftUI

enum WidgetSize: Sendable {
    case small, medium, large
    
    var height: CGFloat {
        switch self {
        case .small: return 120
        case .medium: return 160
        case .large: return 240
        }
    }
}

@MainActor
struct WidgetContainerView<Content: View>: View {
    let title: String
    let icon: String
    let size: WidgetSize
    let content: Content
    
    init(
        title: String,
        icon: String,
        size: WidgetSize,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.size = size
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.accentColor)
                    
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            // Content
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
        .frame(height: size.height)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        WidgetContainerView(
            title: "Sample Widget",
            icon: "chart.bar.fill",
            size: .medium
        ) {
            VStack {
                Text("Widget Content")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .frame(width: 300)
        
        WidgetContainerView(
            title: "Large Widget",
            icon: "person.2.fill",
            size: .large
        ) {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(0..<5, id: \.self) { index in
                        HStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                            
                            Text("Item \(index + 1)")
                                .font(.caption)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(UIColor.tertiarySystemBackground))
                        .cornerRadius(6)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .frame(width: 300)
    }
    .padding()
}