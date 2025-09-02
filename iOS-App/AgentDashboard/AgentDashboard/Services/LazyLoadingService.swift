//
//  LazyLoadingService.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Lazy loading service for performance optimization
//

import Foundation
import SwiftUI
import Dependencies

// MARK: - Lazy Loading Service Protocol

protocol LazyLoadingServiceProtocol {
    /// Load data page by page
    func loadPage<T: Codable>(_ pageRequest: PageRequest, type: T.Type) async throws -> PageResponse<T>
    
    /// Check if more data is available
    func hasMoreData(for request: PageRequest) -> Bool
    
    /// Preload next page in background
    func preloadNextPage<T: Codable>(_ pageRequest: PageRequest, type: T.Type) async
    
    /// Clear cached pages
    func clearCache(for request: PageRequest)
    
    /// Get loading state for page
    func isLoading(for request: PageRequest) -> Bool
}

// MARK: - Pagination Models

struct PageRequest: Hashable, Codable {
    let resource: String
    let pageNumber: Int
    let pageSize: Int
    let sortBy: String?
    let filterBy: [String: String]
    
    init(resource: String, pageNumber: Int = 0, pageSize: Int = 20, sortBy: String? = nil, filterBy: [String: String] = [:]) {
        self.resource = resource
        self.pageNumber = pageNumber
        self.pageSize = pageSize
        self.sortBy = sortBy
        self.filterBy = filterBy
    }
    
    var cacheKey: String {
        let filterString = filterBy.map { "\($0.key):\($0.value)" }.joined(separator: ",")
        return "\(resource)_p\(pageNumber)_s\(pageSize)_\(sortBy ?? "default")_\(filterString)"
    }
    
    func nextPage() -> PageRequest {
        PageRequest(
            resource: resource,
            pageNumber: pageNumber + 1,
            pageSize: pageSize,
            sortBy: sortBy,
            filterBy: filterBy
        )
    }
}

struct PageResponse<T: Codable>: Codable {
    let data: [T]
    let pageNumber: Int
    let pageSize: Int
    let totalCount: Int
    let hasMore: Bool
    let loadTime: TimeInterval
    let timestamp: Date
    
    init(data: [T], pageNumber: Int, pageSize: Int, totalCount: Int, loadTime: TimeInterval) {
        self.data = data
        self.pageNumber = pageNumber
        self.pageSize = pageSize
        self.totalCount = totalCount
        self.hasMore = (pageNumber + 1) * pageSize < totalCount
        self.loadTime = loadTime
        self.timestamp = Date()
    }
    
    var isFirstPage: Bool { pageNumber == 0 }
    var isLastPage: Bool { !hasMore }
    var startIndex: Int { pageNumber * pageSize }
    var endIndex: Int { min(startIndex + data.count, totalCount) }
}

// MARK: - Lazy Loading State Management

@MainActor
class LazyLoadingManager<T: Codable & Identifiable>: ObservableObject {
    @Published var items: [T] = []
    @Published var isLoading: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var error: String?
    @Published var hasMore: Bool = true
    
    private let lazyLoadingService: LazyLoadingServiceProtocol
    private let resource: String
    private let pageSize: Int
    private var currentPage: Int = 0
    private let logger: Logger
    
    init(resource: String, pageSize: Int = 20, lazyLoadingService: LazyLoadingServiceProtocol) {
        self.resource = resource
        self.pageSize = pageSize
        self.lazyLoadingService = lazyLoadingService
        self.logger = Logger(subsystem: "AgentDashboard", category: "LazyLoading-\(resource)")
        
        logger.info("LazyLoadingManager initialized for resource: \(resource), pageSize: \(pageSize)")
    }
    
    func loadInitialData(sortBy: String? = nil, filterBy: [String: String] = [:]) async {
        logger.info("Loading initial data for resource: \(resource)")
        
        isLoading = true
        error = nil
        currentPage = 0
        
        do {
            let request = PageRequest(resource: resource, pageNumber: 0, pageSize: pageSize, sortBy: sortBy, filterBy: filterBy)
            let response = try await lazyLoadingService.loadPage(request, type: T.self)
            
            items = response.data
            hasMore = response.hasMore
            currentPage = response.pageNumber
            
            logger.info("Initial data loaded - Items: \(items.count), HasMore: \(hasMore), LoadTime: \(String(format: "%.3f", response.loadTime))s")
            
        } catch {
            logger.error("Failed to load initial data: \(error.localizedDescription)")
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadMoreData(sortBy: String? = nil, filterBy: [String: String] = [:]) async {
        guard hasMore && !isLoadingMore else { 
            logger.debug("Skipping load more - HasMore: \(hasMore), IsLoadingMore: \(isLoadingMore)")
            return 
        }
        
        logger.debug("Loading more data - CurrentPage: \(currentPage), Resource: \(resource)")
        
        isLoadingMore = true
        
        do {
            let request = PageRequest(resource: resource, pageNumber: currentPage + 1, pageSize: pageSize, sortBy: sortBy, filterBy: filterBy)
            let response = try await lazyLoadingService.loadPage(request, type: T.self)
            
            items.append(contentsOf: response.data)
            hasMore = response.hasMore
            currentPage = response.pageNumber
            
            logger.info("More data loaded - New items: \(response.data.count), Total: \(items.count), HasMore: \(hasMore)")
            
        } catch {
            logger.error("Failed to load more data: \(error.localizedDescription)")
            self.error = error.localizedDescription
        }
        
        isLoadingMore = false
    }
    
    func refresh(sortBy: String? = nil, filterBy: [String: String] = [:]) async {
        logger.info("Refreshing data for resource: \(resource)")
        
        // Clear cache and reload
        let request = PageRequest(resource: resource, pageNumber: 0, pageSize: pageSize, sortBy: sortBy, filterBy: filterBy)
        lazyLoadingService.clearCache(for: request)
        
        await loadInitialData(sortBy: sortBy, filterBy: filterBy)
    }
    
    func shouldLoadMore(for item: T) -> Bool {
        // Load more when we're near the end of the list
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return false }
        let threshold = max(5, pageSize / 4) // Load when 5 items or 25% of page size remaining
        
        return index >= items.count - threshold && hasMore && !isLoadingMore
    }
}

// MARK: - Production Lazy Loading Service

final class LazyLoadingService: LazyLoadingServiceProtocol {
    private let apiClient: APIClientProtocol
    private let cacheService: CacheServiceProtocol
    private let logger = Logger(subsystem: "AgentDashboard", category: "LazyLoading")
    private var loadingStates: [String: Bool] = [:]
    private var pageCache: [String: Any] = [:]
    
    init(apiClient: APIClientProtocol, cacheService: CacheServiceProtocol) {
        self.apiClient = apiClient
        self.cacheService = cacheService
        logger.info("LazyLoadingService initialized with API and cache integration")
    }
    
    func loadPage<T: Codable>(_ pageRequest: PageRequest, type: T.Type) async throws -> PageResponse<T> {
        let startTime = Date()
        logger.debug("Loading page \(pageRequest.pageNumber) for resource: \(pageRequest.resource)")
        
        // Check cache first
        if let cachedResponse = await getCachedPage(pageRequest, type: type) {
            logger.debug("Returning cached page \(pageRequest.pageNumber) for resource: \(pageRequest.resource)")
            return cachedResponse
        }
        
        // Set loading state
        setLoadingState(for: pageRequest, isLoading: true)
        
        defer {
            setLoadingState(for: pageRequest, isLoading: false)
        }
        
        do {
            // Simulate API call based on resource type
            let response = try await loadPageFromAPI(pageRequest, type: type)
            let loadTime = Date().timeIntervalSince(startTime)
            
            let pageResponse = PageResponse(
                data: response,
                pageNumber: pageRequest.pageNumber,
                pageSize: pageRequest.pageSize,
                totalCount: calculateTotalCount(for: pageRequest, currentData: response),
                loadTime: loadTime
            )
            
            // Cache the response
            await cachePage(pageRequest, response: pageResponse)
            
            logger.info("Page loaded - Resource: \(pageRequest.resource), Page: \(pageRequest.pageNumber), Items: \(response.count), LoadTime: \(String(format: "%.3f", loadTime))s")
            
            return pageResponse
            
        } catch {
            logger.error("Failed to load page \(pageRequest.pageNumber) for resource \(pageRequest.resource): \(error.localizedDescription)")
            throw error
        }
    }
    
    func hasMoreData(for request: PageRequest) -> Bool {
        // Check cached metadata or estimate based on last loaded page
        let hasMore = estimateHasMoreData(for: request)
        logger.debug("HasMoreData check for \(request.resource) page \(request.pageNumber): \(hasMore)")
        return hasMore
    }
    
    func preloadNextPage<T: Codable>(_ pageRequest: PageRequest, type: T.Type) async {
        let nextPageRequest = pageRequest.nextPage()
        logger.debug("Preloading next page \(nextPageRequest.pageNumber) for resource: \(nextPageRequest.resource)")
        
        Task {
            do {
                _ = try await loadPage(nextPageRequest, type: type)
                logger.debug("Preload successful for page \(nextPageRequest.pageNumber)")
            } catch {
                logger.debug("Preload failed for page \(nextPageRequest.pageNumber): \(error.localizedDescription)")
            }
        }
    }
    
    func clearCache(for request: PageRequest) {
        logger.debug("Clearing cache for resource: \(request.resource)")
        
        Task {
            await cacheService.removeValue(forKey: request.cacheKey)
            pageCache.removeValue(forKey: request.cacheKey)
        }
    }
    
    func isLoading(for request: PageRequest) -> Bool {
        return loadingStates[request.cacheKey] ?? false
    }
    
    // MARK: - Private Helper Methods
    
    private func setLoadingState(for request: PageRequest, isLoading: Bool) {
        loadingStates[request.cacheKey] = isLoading
    }
    
    private func getCachedPage<T: Codable>(_ request: PageRequest, type: T.Type) async -> PageResponse<T>? {
        if let cached = await cacheService.getValue(forKey: request.cacheKey, type: PageResponse<T>.self) {
            // Check if cache is still fresh (5 minutes for real-time data)
            let cacheAge = Date().timeIntervalSince(cached.timestamp)
            if cacheAge < 300 { // 5 minutes
                return cached
            } else {
                logger.debug("Cache expired for \(request.cacheKey), age: \(String(format: "%.1f", cacheAge))s")
            }
        }
        return nil
    }
    
    private func cachePage<T: Codable>(_ request: PageRequest, response: PageResponse<T>) async {
        await cacheService.setValue(response, forKey: request.cacheKey)
        logger.debug("Cached page response for key: \(request.cacheKey)")
    }
    
    private func loadPageFromAPI<T: Codable>(_ request: PageRequest, type: T.Type) async throws -> [T] {
        // Simulate different resource types
        switch request.resource {
        case "agents":
            let agents = try await apiClient.fetchAgents()
            return try convertToType(agents, as: type)
            
        case "modules":
            let modules = try await apiClient.fetchModules()
            return try convertToType(modules, as: type)
            
        case "analytics":
            // For analytics, generate paginated mock data
            return try generateMockAnalyticsData(for: request, type: type)
            
        default:
            logger.warning("Unknown resource type: \(request.resource)")
            return []
        }
    }
    
    private func convertToType<T: Codable>(_ data: Any, as type: T.Type) throws -> [T] {
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        return try JSONDecoder().decode([T].self, from: jsonData)
    }
    
    private func generateMockAnalyticsData<T: Codable>(for request: PageRequest, type: T.Type) throws -> [T] {
        // Generate mock paginated data for analytics
        let startIndex = request.pageNumber * request.pageSize
        let endIndex = startIndex + request.pageSize
        
        var mockData: [Any] = []
        
        for i in startIndex..<endIndex {
            let mockItem = [
                "id": UUID().uuidString,
                "timestamp": Date().addingTimeInterval(TimeInterval(-i * 60)).ISO8601Format(),
                "value": Double.random(in: 0...100),
                "label": "Data Point \(i)"
            ]
            mockData.append(mockItem)
        }
        
        return try convertToType(mockData, as: type)
    }
    
    private func calculateTotalCount(for request: PageRequest, currentData: [Any]) -> Int {
        // Estimate total count based on resource type
        switch request.resource {
        case "agents":
            return currentData.count // Agents are typically small sets
        case "modules":
            return currentData.count // Modules are typically small sets
        case "analytics":
            return 1000 // Large analytics dataset for testing
        default:
            return currentData.count
        }
    }
    
    private func estimateHasMoreData(for request: PageRequest) -> Bool {
        switch request.resource {
        case "agents", "modules":
            return false // These are typically complete datasets
        case "analytics":
            return request.pageNumber < 50 // 50 pages of analytics data
        default:
            return false
        }
    }
}

// MARK: - Lazy Loading SwiftUI View Extensions

extension View {
    /// Add lazy loading behavior to a view
    func onLazyAppear<T: Codable & Identifiable>(
        item: T,
        in manager: LazyLoadingManager<T>,
        threshold: Int = 5,
        perform action: @escaping () async -> Void
    ) -> some View {
        self.onAppear {
            if manager.shouldLoadMore(for: item) {
                Task {
                    await action()
                }
            }
        }
    }
    
    /// Add pull-to-refresh with lazy loading
    func lazyRefreshable<T: Codable & Identifiable>(
        manager: LazyLoadingManager<T>,
        sortBy: String? = nil,
        filterBy: [String: String] = [:]
    ) -> some View {
        self.refreshable {
            await manager.refresh(sortBy: sortBy, filterBy: filterBy)
        }
    }
}

// MARK: - Lazy Loading List Component

struct LazyLoadingList<T: Codable & Identifiable, Content: View>: View {
    @StateObject private var manager: LazyLoadingManager<T>
    private let content: (T) -> Content
    private let sortBy: String?
    private let filterBy: [String: String]
    private let emptyStateView: AnyView?
    
    init(
        resource: String,
        pageSize: Int = 20,
        sortBy: String? = nil,
        filterBy: [String: String] = [:],
        emptyStateView: AnyView? = nil,
        @Dependency(\.lazyLoading) lazyLoadingService: LazyLoadingServiceProtocol,
        @ViewBuilder content: @escaping (T) -> Content
    ) {
        self._manager = StateObject(wrappedValue: LazyLoadingManager(
            resource: resource,
            pageSize: pageSize,
            lazyLoadingService: lazyLoadingService
        ))
        self.content = content
        self.sortBy = sortBy
        self.filterBy = filterBy
        self.emptyStateView = emptyStateView
    }
    
    var body: some View {
        Group {
            if manager.isLoading && manager.items.isEmpty {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if manager.items.isEmpty {
                emptyStateView ?? AnyView(
                    VStack {
                        Image(systemName: "tray")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No items available")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                )
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(manager.items) { item in
                        content(item)
                            .onLazyAppear(item: item, in: manager) {
                                await manager.loadMoreData(sortBy: sortBy, filterBy: filterBy)
                            }
                    }
                    
                    if manager.isLoadingMore {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading more...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                }
            }
        }
        .lazyRefreshable(manager: manager, sortBy: sortBy, filterBy: filterBy)
        .alert("Error", isPresented: .constant(manager.error != nil)) {
            Button("OK") {
                manager.error = nil
            }
            Button("Retry") {
                Task {
                    await manager.loadInitialData(sortBy: sortBy, filterBy: filterBy)
                }
            }
        } message: {
            Text(manager.error ?? "Unknown error")
        }
        .task {
            await manager.loadInitialData(sortBy: sortBy, filterBy: filterBy)
        }
    }
}

// MARK: - Mock Lazy Loading Service

final class MockLazyLoadingService: LazyLoadingServiceProtocol {
    private let logger = Logger(subsystem: "AgentDashboard", category: "MockLazyLoading")
    private var cache: [String: Any] = [:]
    private var loadingStates: [String: Bool] = [:]
    
    init() {
        logger.info("MockLazyLoadingService initialized")
    }
    
    func loadPage<T: Codable>(_ pageRequest: PageRequest, type: T.Type) async throws -> PageResponse<T> {
        logger.debug("Mock loading page \(pageRequest.pageNumber) for resource: \(pageRequest.resource)")
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64.random(in: 200_000_000...800_000_000)) // 0.2-0.8 seconds
        
        // Generate mock data
        let mockData = generateMockData(for: pageRequest, type: type)
        let totalCount = getTotalCount(for: pageRequest.resource)
        
        let response = PageResponse(
            data: mockData,
            pageNumber: pageRequest.pageNumber,
            pageSize: pageRequest.pageSize,
            totalCount: totalCount,
            loadTime: 0.5
        )
        
        logger.debug("Mock page loaded - Resource: \(pageRequest.resource), Items: \(mockData.count)")
        return response
    }
    
    func hasMoreData(for request: PageRequest) -> Bool {
        let totalCount = getTotalCount(for: request.resource)
        let hasMore = (request.pageNumber + 1) * request.pageSize < totalCount
        logger.debug("Mock hasMoreData for \(request.resource): \(hasMore)")
        return hasMore
    }
    
    func preloadNextPage<T: Codable>(_ pageRequest: PageRequest, type: T.Type) async {
        logger.debug("Mock preloading next page for resource: \(pageRequest.resource)")
        // Simulate preload without actual work
    }
    
    func clearCache(for request: PageRequest) {
        logger.debug("Mock clearing cache for resource: \(request.resource)")
        cache.removeValue(forKey: request.cacheKey)
    }
    
    func isLoading(for request: PageRequest) -> Bool {
        return loadingStates[request.cacheKey] ?? false
    }
    
    private func generateMockData<T: Codable>(for request: PageRequest, type: T.Type) -> [T] {
        // Generate mock data based on type and page
        let startIndex = request.pageNumber * request.pageSize
        var mockItems: [T] = []
        
        for i in 0..<request.pageSize {
            let itemIndex = startIndex + i
            if let mockItem = createMockItem(index: itemIndex, type: type) {
                mockItems.append(mockItem)
            }
        }
        
        return mockItems
    }
    
    private func createMockItem<T: Codable>(index: Int, type: T.Type) -> T? {
        // This would need to be implemented based on your specific data types
        // For now, return nil for unknown types
        logger.debug("Creating mock item \(index) of type: \(String(describing: type))")
        return nil
    }
    
    private func getTotalCount(for resource: String) -> Int {
        switch resource {
        case "agents":
            return 5
        case "modules":
            return 12
        case "analytics":
            return 1000
        default:
            return 100
        }
    }
}

// MARK: - Dependency Registration

private enum LazyLoadingKey: DependencyKey {
    static let liveValue: LazyLoadingServiceProtocol = {
        @Dependency(\.apiClient) var apiClient
        @Dependency(\.cacheService) var cacheService
        return LazyLoadingService(apiClient: apiClient, cacheService: cacheService)
    }()
    static let testValue: LazyLoadingServiceProtocol = MockLazyLoadingService()
    static let previewValue: LazyLoadingServiceProtocol = MockLazyLoadingService()
}

extension DependencyValues {
    var lazyLoading: LazyLoadingServiceProtocol {
        get { self[LazyLoadingKey.self] }
        set { self[LazyLoadingKey.self] = newValue }
    }
}