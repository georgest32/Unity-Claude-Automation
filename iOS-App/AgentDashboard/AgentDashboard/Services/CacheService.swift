//
//  CacheService.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Multi-layer caching service for performance optimization
//

import Foundation
import SwiftUI
import Dependencies

// MARK: - Cache Service Protocol

protocol CacheServiceProtocol {
    /// Store value in cache
    func setValue<T: Codable>(_ value: T, forKey key: String, expiration: CacheExpiration?) async
    
    /// Retrieve value from cache
    func getValue<T: Codable>(forKey key: String, type: T.Type) async -> T?
    
    /// Remove value from cache
    func removeValue(forKey key: String) async
    
    /// Clear all cache
    func clearCache() async
    
    /// Get cache statistics
    func getCacheStatistics() async -> CacheStatistics
    
    /// Preload data into cache
    func preloadData<T: Codable>(_ data: [T], forKeyPrefix prefix: String) async
    
    /// Check if key exists in cache
    func containsKey(_ key: String) async -> Bool
}

// MARK: - Cache Models

enum CacheExpiration {
    case never
    case seconds(TimeInterval)
    case minutes(Int)
    case hours(Int)
    case days(Int)
    case custom(Date)
    
    var expirationDate: Date? {
        switch self {
        case .never:
            return nil
        case .seconds(let seconds):
            return Date().addingTimeInterval(seconds)
        case .minutes(let minutes):
            return Date().addingTimeInterval(TimeInterval(minutes * 60))
        case .hours(let hours):
            return Date().addingTimeInterval(TimeInterval(hours * 3600))
        case .days(let days):
            return Date().addingTimeInterval(TimeInterval(days * 86400))
        case .custom(let date):
            return date
        }
    }
}

struct CacheEntry<T: Codable>: Codable {
    let value: T
    let key: String
    let createdAt: Date
    let expiresAt: Date?
    let accessCount: Int
    let lastAccessedAt: Date
    
    init(value: T, key: String, expiration: CacheExpiration?) {
        self.value = value
        self.key = key
        self.createdAt = Date()
        self.expiresAt = expiration?.expirationDate
        self.accessCount = 0
        self.lastAccessedAt = Date()
    }
    
    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }
    
    var age: TimeInterval {
        Date().timeIntervalSince(createdAt)
    }
    
    func withIncrementedAccess() -> CacheEntry<T> {
        CacheEntry(
            value: value,
            key: key,
            createdAt: createdAt,
            expiresAt: expiresAt,
            accessCount: accessCount + 1,
            lastAccessedAt: Date()
        )
    }
}

struct CacheStatistics {
    let memoryUsage: Int // bytes
    let diskUsage: Int // bytes
    let hitRate: Double // percentage
    let entryCount: Int
    let oldestEntry: Date?
    let newestEntry: Date?
    let averageAccessCount: Double
    let expiredEntries: Int
    
    var memoryUsageMB: Double {
        Double(memoryUsage) / 1024.0 / 1024.0
    }
    
    var diskUsageMB: Double {
        Double(diskUsage) / 1024.0 / 1024.0
    }
    
    var totalUsageMB: Double {
        memoryUsageMB + diskUsageMB
    }
}

// MARK: - Production Cache Service Implementation

final class CacheService: CacheServiceProtocol {
    private let memoryCache = NSCache<NSString, CacheWrapper>()
    private let diskCacheDirectory: URL
    private let fileManager = FileManager.default
    private let logger = Logger(subsystem: "AgentDashboard", category: "CacheService")
    private let queue = DispatchQueue(label: "cache-service", qos: .utility)
    
    // Cache configuration
    private let maxMemoryEntries = 200
    private let maxDiskSize = 50_000_000 // 50MB
    private let cleanupThreshold = 0.8 // Clean when 80% full
    
    // Performance tracking
    private var hitCount = 0
    private var missCount = 0
    
    init() {
        // Create disk cache directory
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        diskCacheDirectory = documentsPath.appendingPathComponent("Cache", isDirectory: true)
        
        setupCache()
        logger.info("CacheService initialized - Memory limit: \(maxMemoryEntries), Disk limit: \(maxDiskSize / 1024 / 1024)MB")
    }
    
    private func setupCache() {
        // Configure memory cache
        memoryCache.countLimit = maxMemoryEntries
        memoryCache.totalCostLimit = 20_000_000 // 20MB memory limit
        
        // Create disk cache directory
        do {
            try fileManager.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true)
            logger.debug("Cache directory created/verified: \(diskCacheDirectory.path)")
        } catch {
            logger.error("Failed to create cache directory: \(error.localizedDescription)")
        }
        
        // Schedule periodic cleanup
        schedulePeriodicCleanup()
    }
    
    func setValue<T: Codable>(_ value: T, forKey key: String, expiration: CacheExpiration? = nil) async {
        logger.debug("Storing value in cache - Key: \(key)")
        
        do {
            let cacheEntry = CacheEntry(value: value, key: key, expiration: expiration)
            let wrapper = CacheWrapper(entry: cacheEntry)
            
            // Store in memory cache
            let cost = MemoryLayout<T>.size
            memoryCache.setObject(wrapper, forKey: key as NSString, cost: cost)
            
            // Store in disk cache for persistence
            let encoded = try JSONEncoder().encode(cacheEntry)
            let fileURL = diskCacheURL(for: key)
            
            try encoded.write(to: fileURL)
            
            logger.debug("Value cached - Key: \(key), Size: \(encoded.count) bytes, Expiration: \(expiration?.expirationDate?.description ?? "never")")
            
        } catch {
            logger.error("Failed to cache value for key \(key): \(error.localizedDescription)")
        }
    }
    
    func getValue<T: Codable>(forKey key: String, type: T.Type) async -> T? {
        logger.debug("Retrieving value from cache - Key: \(key)")
        
        // Try memory cache first
        if let wrapper = memoryCache.object(forKey: key as NSString),
           let entry = wrapper.entry as? CacheEntry<T> {
            
            if !entry.isExpired {
                hitCount += 1
                logger.debug("Cache HIT (memory) - Key: \(key)")
                return entry.value
            } else {
                logger.debug("Cache entry expired (memory) - Key: \(key)")
                memoryCache.removeObject(forKey: key as NSString)
            }
        }
        
        // Try disk cache
        let fileURL = diskCacheURL(for: key)
        
        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                let data = try Data(contentsOf: fileURL)
                let entry = try JSONDecoder().decode(CacheEntry<T>.self, from: data)
                
                if !entry.isExpired {
                    hitCount += 1
                    
                    // Promote to memory cache
                    let wrapper = CacheWrapper(entry: entry)
                    memoryCache.setObject(wrapper, forKey: key as NSString)
                    
                    logger.debug("Cache HIT (disk) - Key: \(key), promoted to memory")
                    return entry.value
                } else {
                    logger.debug("Cache entry expired (disk) - Key: \(key)")
                    try fileManager.removeItem(at: fileURL)
                }
            } catch {
                logger.error("Failed to read cached value for key \(key): \(error.localizedDescription)")
            }
        }
        
        missCount += 1
        logger.debug("Cache MISS - Key: \(key)")
        return nil
    }
    
    func removeValue(forKey key: String) async {
        logger.debug("Removing value from cache - Key: \(key)")
        
        // Remove from memory cache
        memoryCache.removeObject(forKey: key as NSString)
        
        // Remove from disk cache
        let fileURL = diskCacheURL(for: key)
        do {
            try fileManager.removeItem(at: fileURL)
            logger.debug("Cache entry removed - Key: \(key)")
        } catch {
            logger.debug("Disk cache entry not found or already removed - Key: \(key)")
        }
    }
    
    func clearCache() async {
        logger.info("Clearing all cache")
        
        // Clear memory cache
        memoryCache.removeAllObjects()
        
        // Clear disk cache
        do {
            let files = try fileManager.contentsOfDirectory(at: diskCacheDirectory, includingPropertiesForKeys: nil)
            for file in files {
                try fileManager.removeItem(at: file)
            }
            logger.info("All cache cleared successfully")
        } catch {
            logger.error("Failed to clear disk cache: \(error.localizedDescription)")
        }
        
        // Reset statistics
        hitCount = 0
        missCount = 0
    }
    
    func getCacheStatistics() async -> CacheStatistics {
        let memoryUsage = calculateMemoryUsage()
        let diskUsage = await calculateDiskUsage()
        let totalRequests = hitCount + missCount
        let hitRate = totalRequests > 0 ? Double(hitCount) / Double(totalRequests) * 100 : 0
        
        let (oldestEntry, newestEntry, totalEntries, expiredCount) = await getCacheMetadata()
        
        let stats = CacheStatistics(
            memoryUsage: memoryUsage,
            diskUsage: diskUsage,
            hitRate: hitRate,
            entryCount: totalEntries,
            oldestEntry: oldestEntry,
            newestEntry: newestEntry,
            averageAccessCount: 1.0, // Simplified calculation
            expiredEntries: expiredCount
        )
        
        logger.debug("Cache statistics - Memory: \(String(format: "%.1f", stats.memoryUsageMB))MB, Disk: \(String(format: "%.1f", stats.diskUsageMB))MB, Hit rate: \(String(format: "%.1f", stats.hitRate))%")
        
        return stats
    }
    
    func preloadData<T: Codable>(_ data: [T], forKeyPrefix prefix: String) async {
        logger.info("Preloading \(data.count) items with key prefix: \(prefix)")
        
        for (index, item) in data.enumerated() {
            let key = "\(prefix)_\(index)"
            await setValue(item, forKey: key, expiration: .hours(1))
        }
        
        logger.info("Preload completed for prefix: \(prefix)")
    }
    
    func containsKey(_ key: String) async -> Bool {
        // Check memory cache
        if memoryCache.object(forKey: key as NSString) != nil {
            return true
        }
        
        // Check disk cache
        let fileURL = diskCacheURL(for: key)
        return fileManager.fileExists(atPath: fileURL.path)
    }
    
    // MARK: - Private Helper Methods
    
    private func diskCacheURL(for key: String) -> URL {
        let hashedKey = key.data(using: .utf8)?.base64EncodedString() ?? key
        return diskCacheDirectory.appendingPathComponent("\(hashedKey).cache")
    }
    
    private func calculateMemoryUsage() -> Int {
        // Estimate memory usage (simplified)
        return memoryCache.totalCostLimit
    }
    
    private func calculateDiskUsage() async -> Int {
        do {
            let files = try fileManager.contentsOfDirectory(at: diskCacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
            var totalSize = 0
            
            for file in files {
                if let fileSize = (try? file.resourceValues(forKeys: [.fileSizeKey]))?.fileSize {
                    totalSize += fileSize
                }
            }
            
            return totalSize
        } catch {
            logger.error("Failed to calculate disk usage: \(error.localizedDescription)")
            return 0
        }
    }
    
    private func getCacheMetadata() async -> (oldest: Date?, newest: Date?, total: Int, expired: Int) {
        do {
            let files = try fileManager.contentsOfDirectory(at: diskCacheDirectory, includingPropertiesForKeys: [.creationDateKey])
                .filter { $0.pathExtension == "cache" }
            
            var oldestDate: Date?
            var newestDate: Date?
            var expiredCount = 0
            
            for file in files {
                if let creationDate = (try? file.resourceValues(forKeys: [.creationDateKey]))?.creationDate {
                    if oldestDate == nil || creationDate < oldestDate! {
                        oldestDate = creationDate
                    }
                    if newestDate == nil || creationDate > newestDate! {
                        newestDate = creationDate
                    }
                }
                
                // Check if expired (simplified check)
                do {
                    let data = try Data(contentsOf: file)
                    if let decoded = try? JSONDecoder().decode([String: Any].self, from: data),
                       let expiresAtString = decoded["expiresAt"] as? String,
                       let expiresAt = ISO8601DateFormatter().date(from: expiresAtString),
                       Date() > expiresAt {
                        expiredCount += 1
                    }
                } catch {
                    // Count as expired if we can't read it
                    expiredCount += 1
                }
            }
            
            return (oldestDate, newestDate, files.count, expiredCount)
            
        } catch {
            logger.error("Failed to get cache metadata: \(error.localizedDescription)")
            return (nil, nil, 0, 0)
        }
    }
    
    private func schedulePeriodicCleanup() {
        // Schedule cleanup every 10 minutes
        Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { _ in
            Task {
                await self.performCleanup()
            }
        }
    }
    
    private func performCleanup() async {
        logger.debug("Performing cache cleanup")
        
        do {
            let files = try fileManager.contentsOfDirectory(at: diskCacheDirectory, includingPropertiesForKeys: [.fileSizeKey, .creationDateKey])
                .filter { $0.pathExtension == "cache" }
            
            var totalSize = 0
            var expiredFiles: [URL] = []
            var allFiles: [(url: URL, size: Int, date: Date)] = []
            
            for file in files {
                let size = (try? file.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                let date = (try? file.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                
                totalSize += size
                allFiles.append((file, size, date))
                
                // Check if file contains expired entry
                do {
                    let data = try Data(contentsOf: file)
                    if let decoded = try? JSONDecoder().decode([String: Any].self, from: data),
                       let expiresAtString = decoded["expiresAt"] as? String,
                       let expiresAt = ISO8601DateFormatter().date(from: expiresAtString),
                       Date() > expiresAt {
                        expiredFiles.append(file)
                    }
                } catch {
                    expiredFiles.append(file) // Remove unreadable files
                }
            }
            
            // Remove expired files
            for file in expiredFiles {
                try fileManager.removeItem(at: file)
                logger.debug("Cleaned expired cache file: \(file.lastPathComponent)")
            }
            
            // If still over threshold, remove oldest files
            if totalSize > Int(Double(maxDiskSize) * cleanupThreshold) {
                let sortedFiles = allFiles.sorted { $0.date < $1.date }
                let filesToRemove = sortedFiles.prefix(while: { _ in
                    totalSize > Int(Double(maxDiskSize) * 0.7) // Clean to 70%
                })
                
                for fileInfo in filesToRemove {
                    try fileManager.removeItem(at: fileInfo.url)
                    totalSize -= fileInfo.size
                    logger.debug("Cleaned old cache file: \(fileInfo.url.lastPathComponent)")
                }
            }
            
            logger.info("Cache cleanup completed - Removed \(expiredFiles.count) expired files")
            
        } catch {
            logger.error("Cache cleanup failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Cache Wrapper for NSCache

private class CacheWrapper: NSObject {
    let entry: Any
    
    init(entry: Any) {
        self.entry = entry
    }
}

// MARK: - Mock Cache Service

final class MockCacheService: CacheServiceProtocol {
    private var cache: [String: Any] = [:]
    private let logger = Logger(subsystem: "AgentDashboard", category: "MockCache")
    private var hitCount = 0
    private var missCount = 0
    
    init() {
        logger.info("MockCacheService initialized with in-memory storage")
    }
    
    func setValue<T: Codable>(_ value: T, forKey key: String, expiration: CacheExpiration? = nil) async {
        logger.debug("Mock storing value - Key: \(key)")
        
        let entry = CacheEntry(value: value, key: key, expiration: expiration)
        cache[key] = entry
    }
    
    func getValue<T: Codable>(forKey key: String, type: T.Type) async -> T? {
        logger.debug("Mock retrieving value - Key: \(key)")
        
        if let entry = cache[key] as? CacheEntry<T> {
            if !entry.isExpired {
                hitCount += 1
                logger.debug("Mock cache HIT - Key: \(key)")
                return entry.value
            } else {
                logger.debug("Mock cache entry expired - Key: \(key)")
                cache.removeValue(forKey: key)
            }
        }
        
        missCount += 1
        logger.debug("Mock cache MISS - Key: \(key)")
        return nil
    }
    
    func removeValue(forKey key: String) async {
        logger.debug("Mock removing value - Key: \(key)")
        cache.removeValue(forKey: key)
    }
    
    func clearCache() async {
        logger.info("Mock clearing all cache")
        cache.removeAll()
        hitCount = 0
        missCount = 0
    }
    
    func getCacheStatistics() async -> CacheStatistics {
        let totalRequests = hitCount + missCount
        let hitRate = totalRequests > 0 ? Double(hitCount) / Double(totalRequests) * 100 : 0
        
        return CacheStatistics(
            memoryUsage: cache.count * 1024, // Estimate 1KB per entry
            diskUsage: 0,
            hitRate: hitRate,
            entryCount: cache.count,
            oldestEntry: Date().addingTimeInterval(-3600),
            newestEntry: Date(),
            averageAccessCount: 1.0,
            expiredEntries: 0
        )
    }
    
    func preloadData<T: Codable>(_ data: [T], forKeyPrefix prefix: String) async {
        logger.debug("Mock preloading \(data.count) items with prefix: \(prefix)")
        
        for (index, item) in data.enumerated() {
            let key = "\(prefix)_\(index)"
            await setValue(item, forKey: key, expiration: .hours(1))
        }
    }
    
    func containsKey(_ key: String) async -> Bool {
        let contains = cache[key] != nil
        logger.debug("Mock contains key \(key): \(contains)")
        return contains
    }
}

// MARK: - Dependency Registration

private enum CacheServiceKey: DependencyKey {
    static let liveValue: CacheServiceProtocol = CacheService()
    static let testValue: CacheServiceProtocol = MockCacheService()
    static let previewValue: CacheServiceProtocol = MockCacheService()
}

extension DependencyValues {
    var cacheService: CacheServiceProtocol {
        get { self[CacheServiceKey.self] }
        set { self[CacheServiceKey.self] = newValue }
    }
}