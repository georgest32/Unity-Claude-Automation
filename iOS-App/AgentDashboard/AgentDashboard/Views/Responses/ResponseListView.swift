//
//  ResponseListView.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Response list view with search, filtering, and SwiftData integration
//  Hour 9.2: Response viewer UI foundation
//

import SwiftUI
import SwiftData
import ComposableArchitecture

struct ResponseListView: View {
    let store: StoreOf<ResponseFeature>
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            NavigationView {
                VStack(spacing: 0) {
                    // Response statistics header
                    responseStatsHeader(viewStore: viewStore)
                    
                    // Response list
                    responseList(viewStore: viewStore)
                }
                .navigationTitle("AI Responses")
                .searchable(
                    text: viewStore.binding(
                        get: \.searchText,
                        send: ResponseFeature.Action.searchTextChanged
                    ),
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: viewStore.searchPlaceholder
                ) {
                    searchSuggestions(viewStore: viewStore)
                }
                .toolbar {
                    responseToolbar(viewStore: viewStore)
                }
                .refreshable {
                    viewStore.send(.refreshResponses)
                }
                .sheet(isPresented: .constant(viewStore.isShowingDetail)) {
                    if let selectedResponse = viewStore.selectedResponse {
                        ResponseDetailView(
                            response: selectedResponse,
                            onDismiss: { viewStore.send(.hideResponseDetail) },
                            onFavoriteToggle: { viewStore.send(.toggleResponseFavorite(selectedResponse.id)) },
                            onShare: { viewStore.send(.shareResponse(selectedResponse.id)) },
                            onDelete: { viewStore.send(.deleteResponse(selectedResponse.id)) }
                        )
                    }
                }
                .alert("Response Error", isPresented: .constant(viewStore.error != nil)) {
                    Button("OK") { viewStore.send(.clearError) }
                } message: {
                    if let error = viewStore.error {
                        Text(error)
                    }
                }
            }
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
    }
    
    // MARK: - Response Statistics Header
    
    private func responseStatsHeader(viewStore: ViewStoreOf<ResponseFeature>) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 20) {
                ResponseStatCard(
                    title: "Total",
                    value: "\(viewStore.responseStats.totalResponses)",
                    color: .blue
                )
                
                ResponseStatCard(
                    title: "Favorites",
                    value: "\(viewStore.responseStats.favoriteResponses)",
                    color: .orange
                )
                
                ResponseStatCard(
                    title: "This Session",
                    value: "\(viewStore.filteredResponses.count)",
                    color: .green
                )
                
                Spacer()
            }
            
            // Active filters indicator
            if viewStore.activeFiltersCount > 0 {
                HStack {
                    Text("\(viewStore.activeFiltersCount) filter\(viewStore.activeFiltersCount == 1 ? "" : "s") active")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Clear") {
                        viewStore.send(.clearFilters)
                    }
                    .font(.caption)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
    }
    
    // MARK: - Response List
    
    private func responseList(viewStore: ViewStoreOf<ResponseFeature>) -> some View {
        Group {
            if viewStore.isLoading {
                VStack {
                    ProgressView()
                    Text("Loading responses...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewStore.hasFilteredResponses {
                List {
                    ForEach(viewStore.filteredResponses, id: \.id) { response in
                        ResponseRow(
                            response: response,
                            isSelected: viewStore.selectedResponseID == response.id,
                            onTap: { viewStore.send(.showResponseDetail(response.id)) },
                            onFavoriteToggle: { viewStore.send(.toggleResponseFavorite(response.id)) },
                            onShare: { viewStore.send(.shareResponse(response.id)) },
                            onCopy: { viewStore.send(.copyResponseToClipboard(response.id)) }
                        )
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let response = viewStore.filteredResponses[index]
                            viewStore.send(.deleteResponse(response.id))
                        }
                    }
                }
                .listStyle(.insetGrouped)
            } else {
                ResponseEmptyState(
                    hasResponses: viewStore.hasResponses,
                    activeFiltersCount: viewStore.activeFiltersCount,
                    onClearFilters: { viewStore.send(.clearFilters) }
                )
            }
        }
    }
    
    // MARK: - Search Suggestions
    
    private func searchSuggestions(viewStore: ViewStoreOf<ResponseFeature>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if !viewStore.recentSearches.isEmpty {
                Text("Recent Searches")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                ForEach(viewStore.recentSearches, id: \.self) { search in
                    Button(search) {
                        viewStore.send(.searchTextChanged(search))
                    }
                }
            }
            
            Text("Popular Topics")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            ForEach(["error", "performance", "optimization", "code", "analysis"], id: \.self) { topic in
                Button(topic) {
                    viewStore.send(.searchTextChanged(topic))
                }
            }
        }
    }
    
    // MARK: - Toolbar
    
    private func responseToolbar(viewStore: ViewStoreOf<ResponseFeature>) -> some View {
        Group {
            Menu {
                Button("Show Favorites Only") {
                    viewStore.send(.toggleFavoritesFilter)
                }
                
                Button("Include Archived") {
                    viewStore.send(.toggleArchivedFilter)
                }
                
                Divider()
                
                Menu("Filter by AI System") {
                    Button("All Systems") {
                        viewStore.send(.aiSystemFilterChanged(nil))
                    }
                    
                    ForEach(["Claude Code CLI", "AutoGen", "LangGraph"], id: \.self) { system in
                        Button(system) {
                            viewStore.send(.aiSystemFilterChanged(system))
                        }
                    }
                }
                
                Menu("Filter by Category") {
                    Button("All Categories") {
                        viewStore.send(.categoryFilterChanged(nil))
                    }
                    
                    ForEach(viewStore.availableCategories, id: \.self) { category in
                        Button(category) {
                            viewStore.send(.categoryFilterChanged(category))
                        }
                    }
                }
                
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
            }
            
            Button(action: {
                viewStore.send(.showExportSheet)
            }) {
                Image(systemName: "square.and.arrow.up")
            }
            .disabled(!viewStore.canExport)
        }
    }
}

// MARK: - Supporting Views

struct ResponseStatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct ResponseRow: View {
    let response: Response
    let isSelected: Bool
    let onTap: () -> Void
    let onFavoriteToggle: () -> Void
    let onShare: () -> Void
    let onCopy: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with AI system and timestamp
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: aiSystemIcon(response.aiSystem))
                        .foregroundColor(.blue)
                        .font(.subheadline)
                    
                    Text(response.aiSystem)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                // Favorite indicator
                if response.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
                
                Text(response.formattedCreatedAt)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Response preview
            Text(response.displayTitle)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(2)
            
            // Metadata
            HStack {
                // Category badge
                Text(response.category)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.blue)
                    .clipShape(Capsule())
                
                // Word count
                Text("\(response.wordCount) words")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Reading time
                Text("~\(Int(response.readingTimeMinutes))m read")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Complexity indicator
                if let metadata = response.responseMetadata {
                    Text(metadata.complexity.rawValue)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(metadata.complexity.color)
                        .clipShape(Capsule())
                }
            }
            
            // Tags (if any)
            if !response.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(response.tags.prefix(3), id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(.gray.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
        }
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .swipeActions(edge: .trailing) {
            Button("Share") {
                onShare()
            }
            .tint(.blue)
            
            Button("Copy") {
                onCopy()
            }
            .tint(.green)
        }
        .swipeActions(edge: .leading) {
            Button(response.isFavorite ? "Unfavorite" : "Favorite") {
                onFavoriteToggle()
            }
            .tint(.orange)
        }
        .contextMenu {
            ResponseContextMenu(
                response: response,
                onFavoriteToggle: onFavoriteToggle,
                onShare: onShare,
                onCopy: onCopy
            )
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

struct ResponseEmptyState: View {
    let hasResponses: Bool
    let activeFiltersCount: Int
    let onClearFilters: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: hasResponses ? "magnifyingglass" : "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(hasResponses ? "No Matching Responses" : "No Responses Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(hasResponses ? 
                 "Try adjusting your search terms or filters" : 
                 "Submit prompts from the AI Prompt tab to see responses here"
            )
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            
            if hasResponses && activeFiltersCount > 0 {
                Button("Clear Filters") {
                    onClearFilters()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct ResponseContextMenu: View {
    let response: Response
    let onFavoriteToggle: () -> Void
    let onShare: () -> Void
    let onCopy: () -> Void
    
    var body: some View {
        Group {
            Button(response.isFavorite ? "Remove from Favorites" : "Add to Favorites") {
                onFavoriteToggle()
            }
            
            Button("Copy Content") {
                onCopy()
            }
            
            Button("Share Response") {
                onShare()
            }
            
            Divider()
            
            Button("Copy Response ID") {
                UIPasteboard.general.string = response.id.uuidString
            }
            
            if !response.isArchived {
                Button("Archive") {
                    // Archive action would go here
                }
            }
        }
    }
}

// MARK: - Preview

struct ResponseListView_Previews: PreviewProvider {
    static var previews: some View {
        ResponseListView(
            store: Store(initialState: ResponseFeature.State()) {
                ResponseFeature()
            }
        )
    }
}