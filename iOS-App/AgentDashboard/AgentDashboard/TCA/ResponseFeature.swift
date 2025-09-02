//
//  ResponseFeature.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Response handling and management feature for AI command responses
//  Hour 9: Response feature infrastructure with search and lifecycle management
//

import ComposableArchitecture
import Foundation
import SwiftData

@Reducer
struct ResponseFeature {
    // MARK: - State
    struct State: Equatable {
        // Response management
        var responses: [Response] = []
        var selectedResponse: Response? = nil
        var searchQuery: ResponseSearchQuery = ResponseSearchQuery()
        var filteredResponses: [Response] = []
        
        // UI state
        var isLoading: Bool = false
        var isShowingDetail: Bool = false
        var isShowingSearch: Bool = false
        var isShowingFilters: Bool = false
        var selectedResponseID: Response.ID? = nil
        
        // Search and filtering
        var searchText: String = ""
        var selectedCategory: String? = nil
        var selectedAISystem: String? = nil
        var showFavoritesOnly: Bool = false
        var includeArchived: Bool = false
        
        // Response actions
        var isShowingExportSheet: Bool = false
        var exportFormat: ExportFormat = .markdown
        var isShowingShareSheet: Bool = false
        var shareContent: ShareContent? = nil
        
        // Statistics
        var responseStats: ResponseStatistics = ResponseStatistics()
        var lastUpdated: Date? = nil
        var error: String? = nil
        
        // Response categories and tags
        var availableCategories: [String] = ["General", "Code", "Documentation", "Error Analysis", "Detailed Analysis"]
        var availableTags: [String] = []
        var recentSearches: [String] = []
        
        enum ExportFormat: String, CaseIterable {
            case markdown = "Markdown"
            case plainText = "Plain Text"
            case json = "JSON"
            case pdf = "PDF"
            
            var fileExtension: String {
                switch self {
                case .markdown: return ".md"
                case .plainText: return ".txt"
                case .json: return ".json"
                case .pdf: return ".pdf"
                }
            }
        }
        
        struct ShareContent: Equatable {
            let content: String
            let title: String
            let metadata: String
        }
        
        // Computed properties
        var hasResponses: Bool {
            !responses.isEmpty
        }
        
        var hasFilteredResponses: Bool {
            !filteredResponses.isEmpty
        }
        
        var activeFiltersCount: Int {
            var count = 0
            if !searchText.isEmpty { count += 1 }
            if selectedCategory != nil { count += 1 }
            if selectedAISystem != nil { count += 1 }
            if showFavoritesOnly { count += 1 }
            if !includeArchived { count += 1 }
            return count
        }
        
        var canExport: Bool {
            selectedResponse != nil || !filteredResponses.isEmpty
        }
        
        var searchPlaceholder: String {
            "Search \(responses.count) responses..."
        }
    }
    
    // MARK: - Action
    enum Action: Equatable {
        // Lifecycle
        case onAppear
        case onDisappear
        case loadResponses
        case responsesLoaded([Response])
        case refreshResponses
        
        // Response management
        case responseReceived(CommandResult, CommandRequest)
        case selectResponse(Response.ID?)
        case toggleResponseFavorite(Response.ID)
        case archiveResponse(Response.ID)
        case deleteResponse(Response.ID)
        case updateResponseTags(Response.ID, [String])
        case updateResponseCategory(Response.ID, String)
        
        // Search and filtering
        case searchTextChanged(String)
        case categoryFilterChanged(String?)
        case aiSystemFilterChanged(String?)
        case toggleFavoritesFilter
        case toggleArchivedFilter
        case clearFilters
        case applyFilters
        case filtersApplied
        
        // Response actions
        case copyResponseToClipboard(Response.ID)
        case shareResponse(Response.ID)
        case exportResponse(Response.ID, State.ExportFormat)
        case exportMultipleResponses([Response.ID], State.ExportFormat)
        case showExportSheet
        case hideExportSheet
        case showShareSheet(State.ShareContent)
        case hideShareSheet
        
        // Response detail
        case showResponseDetail(Response.ID)
        case hideResponseDetail
        case updateLastViewed(Response.ID)
        
        // Statistics and analytics
        case updateResponseStatistics
        case statisticsUpdated(ResponseStatistics)
        case generateResponseInsights
        
        // Error handling
        case responseError(String)
        case clearError
        
        // Delegate actions
        case delegate(Delegate)
        
        enum Delegate: Equatable {
            case responseCreated(Response)
            case responseSelected(Response)
            case responseDeleted(Response.ID)
            case showResponseInQueue(UUID) // Show related command in queue
        }
    }
    
    // MARK: - Dependencies
    @Dependency(\.continuousClock) var clock
    @Dependency(\.uuid) var uuid
    @Dependency(\.date) var date
    
    // MARK: - Reducer
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            // MARK: - Lifecycle
            case .onAppear:
                print("[ResponseFeature] Response feature appeared")
                return .merge(
                    .send(.loadResponses),
                    .send(.updateResponseStatistics)
                )
                
            case .onDisappear:
                print("[ResponseFeature] Response feature disappeared")
                return .none
                
            case .loadResponses:
                print("[ResponseFeature] Loading responses from SwiftData")
                state.isLoading = true
                return .run { send in
                    // In real implementation, would load from SwiftData
                    let mockResponses = generateMockResponses()
                    await send(.responsesLoaded(mockResponses))
                }
                
            case let .responsesLoaded(responses):
                print("[ResponseFeature] Loaded \(responses.count) responses")
                state.isLoading = false
                state.responses = responses
                state.lastUpdated = date()
                return .send(.applyFilters)
                
            case .refreshResponses:
                print("[ResponseFeature] Refreshing responses")
                return .send(.loadResponses)
                
            // MARK: - Response Management
            case let .responseReceived(commandResult, commandRequest):
                print("[ResponseFeature] Response received from command: \(commandRequest.id)")
                
                guard commandResult.success, let output = commandResult.output else {
                    return .send(.responseError("Invalid command result: no output"))
                }
                
                let response = Response(
                    content: output,
                    sourceCommandID: commandRequest.id,
                    aiSystem: commandRequest.targetSystem.rawValue,
                    aiMode: commandRequest.mode.rawValue
                )
                
                // Add to responses list
                state.responses.insert(response, at: 0) // Most recent first
                
                // Update statistics
                state.responseStats.totalResponses += 1
                state.responseStats.lastResponseTime = date()
                
                return .merge(
                    .send(.applyFilters),
                    .send(.updateResponseStatistics),
                    .send(.delegate(.responseCreated(response)))
                )
                
            case let .selectResponse(responseID):
                if let responseID = responseID {
                    print("[ResponseFeature] Selecting response: \(responseID)")
                    if let response = state.responses.first(where: { $0.id == responseID }) {
                        state.selectedResponse = response
                        state.selectedResponseID = responseID
                        return .merge(
                            .send(.updateLastViewed(responseID)),
                            .send(.delegate(.responseSelected(response)))
                        )
                    }
                } else {
                    print("[ResponseFeature] Deselecting response")
                    state.selectedResponse = nil
                    state.selectedResponseID = nil
                }
                return .none
                
            case let .toggleResponseFavorite(responseID):
                if let index = state.responses.firstIndex(where: { $0.id == responseID }) {
                    state.responses[index].isFavorite.toggle()
                    print("[ResponseFeature] Toggled favorite for response: \(responseID)")
                    return .send(.applyFilters)
                }
                return .none
                
            case let .archiveResponse(responseID):
                if let index = state.responses.firstIndex(where: { $0.id == responseID }) {
                    state.responses[index].isArchived.toggle()
                    print("[ResponseFeature] Toggled archive for response: \(responseID)")
                    return .send(.applyFilters)
                }
                return .none
                
            case let .deleteResponse(responseID):
                print("[ResponseFeature] Deleting response: \(responseID)")
                state.responses.removeAll { $0.id == responseID }
                if state.selectedResponseID == responseID {
                    state.selectedResponse = nil
                    state.selectedResponseID = nil
                }
                return .merge(
                    .send(.applyFilters),
                    .send(.delegate(.responseDeleted(responseID)))
                )
                
            // MARK: - Search and Filtering
            case let .searchTextChanged(text):
                state.searchText = text
                state.searchQuery.searchText = text
                
                // Add to recent searches if meaningful
                if text.count > 2 && !state.recentSearches.contains(text) {
                    state.recentSearches.insert(text, at: 0)
                    if state.recentSearches.count > 10 {
                        state.recentSearches = Array(state.recentSearches.prefix(10))
                    }
                }
                
                return .send(.applyFilters)
                
            case let .categoryFilterChanged(category):
                state.selectedCategory = category
                state.searchQuery.categoryFilter = category
                print("[ResponseFeature] Category filter changed: \(category ?? "none")")
                return .send(.applyFilters)
                
            case let .aiSystemFilterChanged(aiSystem):
                state.selectedAISystem = aiSystem
                state.searchQuery.aiSystemFilter = aiSystem
                print("[ResponseFeature] AI system filter changed: \(aiSystem ?? "none")")
                return .send(.applyFilters)
                
            case .toggleFavoritesFilter:
                state.showFavoritesOnly.toggle()
                state.searchQuery.isFavoriteOnly = state.showFavoritesOnly
                print("[ResponseFeature] Favorites filter: \(state.showFavoritesOnly)")
                return .send(.applyFilters)
                
            case .toggleArchivedFilter:
                state.includeArchived.toggle()
                state.searchQuery.includeArchived = state.includeArchived
                print("[ResponseFeature] Include archived: \(state.includeArchived)")
                return .send(.applyFilters)
                
            case .clearFilters:
                print("[ResponseFeature] Clearing all filters")
                state.searchText = ""
                state.selectedCategory = nil
                state.selectedAISystem = nil
                state.showFavoritesOnly = false
                state.includeArchived = false
                state.searchQuery = ResponseSearchQuery()
                return .send(.applyFilters)
                
            case .applyFilters:
                print("[ResponseFeature] Applying filters")
                state.filteredResponses = filterResponses(
                    responses: state.responses,
                    query: state.searchQuery,
                    searchText: state.searchText,
                    categoryFilter: state.selectedCategory,
                    aiSystemFilter: state.selectedAISystem,
                    favoritesOnly: state.showFavoritesOnly,
                    includeArchived: state.includeArchived
                )
                return .send(.filtersApplied)
                
            case .filtersApplied:
                print("[ResponseFeature] Filters applied - \(state.filteredResponses.count) results")
                return .none
                
            // MARK: - Response Actions
            case let .copyResponseToClipboard(responseID):
                if let response = state.responses.first(where: { $0.id == responseID }) {
                    print("[ResponseFeature] Copying response to clipboard: \(responseID)")
                    // In real implementation, would copy to UIPasteboard
                    return .none
                }
                return .none
                
            case let .shareResponse(responseID):
                if let response = state.responses.first(where: { $0.id == responseID }) {
                    print("[ResponseFeature] Sharing response: \(responseID)")
                    let shareContent = State.ShareContent(
                        content: response.content,
                        title: response.displayTitle,
                        metadata: "Generated by \(response.aiSystem) on \(response.formattedCreatedAt)"
                    )
                    return .send(.showShareSheet(shareContent))
                }
                return .none
                
            // MARK: - Statistics
            case .updateResponseStatistics:
                let stats = calculateResponseStatistics(state.responses)
                return .send(.statisticsUpdated(stats))
                
            case let .statisticsUpdated(stats):
                state.responseStats = stats
                return .none
                
            // MARK: - Error Handling
            case let .responseError(error):
                print("[ResponseFeature] Response error: \(error)")
                state.error = error
                state.isLoading = false
                return .none
                
            case .clearError:
                state.error = nil
                return .none
                
            // MARK: - Delegate Actions
            case .delegate:
                return .none
                
            // MARK: - UI State Management
            case let .showResponseDetail(responseID):
                state.isShowingDetail = true
                return .send(.selectResponse(responseID))
                
            case .hideResponseDetail:
                state.isShowingDetail = false
                return .none
                
            case let .showShareSheet(content):
                state.shareContent = content
                state.isShowingShareSheet = true
                return .none
                
            case .hideShareSheet:
                state.shareContent = nil
                state.isShowingShareSheet = false
                return .none
                
            case .showExportSheet:
                state.isShowingExportSheet = true
                return .none
                
            case .hideExportSheet:
                state.isShowingExportSheet = false
                return .none
                
            // Default cases for unhandled actions
            default:
                return .none
            }
        }
    }
}

// MARK: - Supporting Models

struct ResponseStatistics: Equatable {
    var totalResponses: Int = 0
    var favoriteResponses: Int = 0
    var archivedResponses: Int = 0
    var averageWordCount: Double = 0.0
    var averageReadingTime: Double = 0.0
    var responsesByAISystem: [String: Int] = [:]
    var responsesByCategory: [String: Int] = [:]
    var lastResponseTime: Date? = nil
    
    var favoriteRate: Double {
        guard totalResponses > 0 else { return 0.0 }
        return Double(favoriteResponses) / Double(totalResponses)
    }
}

// MARK: - Helper Functions

private func generateMockResponses() -> [Response] {
    // Generate mock responses for development/testing
    return [
        Response(
            content: "# System Analysis Results\n\nThe current system is performing well with 94% uptime. Here are the key findings:\n\n## Performance Metrics\n- CPU Usage: 45%\n- Memory Usage: 62%\n- Queue Depth: 3 commands\n\n## Recommendations\n1. Increase memory allocation for better performance\n2. Implement caching for frequently accessed data\n3. Monitor queue depth during peak hours",
            sourceCommandID: UUID(),
            aiSystem: "Claude Code CLI"
        ),
        Response(
            content: "```swift\n// Solution for the threading issue\nfunc performBackgroundTask() async {\n    await withTaskGroup(of: Void.self) { group in\n        group.addTask {\n            // Background work here\n        }\n    }\n}\n```\n\nThis implementation uses structured concurrency to handle background tasks safely.",
            sourceCommandID: UUID(),
            aiSystem: "AutoGen"
        ),
        Response(
            content: "Error analysis complete. The following issues were identified:\n\n⚠️ **Critical Issues:**\n- Memory leak in background processing\n- Potential race condition in queue management\n\n✅ **Resolved Issues:**\n- Fixed authentication timeout\n- Corrected API response parsing",
            sourceCommandID: UUID(),
            aiSystem: "LangGraph"
        )
    ]
}

private func filterResponses(
    responses: [Response],
    query: ResponseSearchQuery,
    searchText: String,
    categoryFilter: String?,
    aiSystemFilter: String?,
    favoritesOnly: Bool,
    includeArchived: Bool
) -> [Response] {
    
    var filtered = responses
    
    // Text search
    if !searchText.isEmpty {
        filtered = filtered.filter { response in
            response.content.localizedCaseInsensitiveContains(searchText) ||
            response.tags.contains { $0.localizedCaseInsensitiveContains(searchText) } ||
            response.category.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // Category filter
    if let category = categoryFilter {
        filtered = filtered.filter { $0.category == category }
    }
    
    // AI system filter
    if let aiSystem = aiSystemFilter {
        filtered = filtered.filter { $0.aiSystem == aiSystem }
    }
    
    // Favorites filter
    if favoritesOnly {
        filtered = filtered.filter { $0.isFavorite }
    }
    
    // Archived filter
    if !includeArchived {
        filtered = filtered.filter { !$0.isArchived }
    }
    
    // Sort by most recent first
    return filtered.sorted { $0.createdAt > $1.createdAt }
}

private func calculateResponseStatistics(_ responses: [Response]) -> ResponseStatistics {
    guard !responses.isEmpty else { return ResponseStatistics() }
    
    let favoriteCount = responses.filter { $0.isFavorite }.count
    let archivedCount = responses.filter { $0.isArchived }.count
    let totalWords = responses.map { $0.wordCount }.reduce(0, +)
    let averageWords = Double(totalWords) / Double(responses.count)
    let averageReading = responses.map { $0.readingTimeMinutes }.reduce(0.0, +) / Double(responses.count)
    
    var systemCounts: [String: Int] = [:]
    var categoryCounts: [String: Int] = [:]
    
    for response in responses {
        systemCounts[response.aiSystem, default: 0] += 1
        categoryCounts[response.category, default: 0] += 1
    }
    
    return ResponseStatistics(
        totalResponses: responses.count,
        favoriteResponses: favoriteCount,
        archivedResponses: archivedCount,
        averageWordCount: averageWords,
        averageReadingTime: averageReading,
        responsesByAISystem: systemCounts,
        responsesByCategory: categoryCounts,
        lastResponseTime: responses.first?.createdAt
    )
}