/**
 * Real-Time Performance Optimizer
 * Optimizes performance for continuous real-time analysis and visualization
 * Part of Day 9 Hour 5-6 Implementation
 */

(function() {
    'use strict';

    console.log('⚡ Initializing Real-Time Performance Optimizer...');

    // Performance optimization state
    const optimizerState = {
        throttling: {
            active: false,
            level: 0, // 0-5, higher = more throttling
            adaptiveEnabled: true
        },
        caching: {
            analysisCache: new Map(),
            renderCache: new Map(),
            maxCacheSize: 1000,
            cacheHitRate: 0,
            totalRequests: 0,
            hits: 0
        },
        incremental: {
            diffEngine: null,
            lastState: null,
            patchQueue: []
        },
        monitoring: {
            fps: 60,
            frameTime: [],
            cpuUsage: 0,
            memoryUsage: 0,
            updateFrequency: 0,
            lastMonitorTime: Date.now()
        },
        config: {
            targetFPS: 30,
            minFPS: 15,
            maxUpdateFrequency: 60, // updates per second
            adaptiveThrottleStep: 0.2,
            cacheExpiry: 60000, // 1 minute
            monitorInterval: 1000 // 1 second
        }
    };

    /**
     * Initialize performance monitoring
     */
    function initializeMonitoring() {
        console.log('📊 Starting performance monitoring...');
        
        // FPS monitoring
        let lastFrameTime = performance.now();
        let frameCount = 0;
        
        function measureFPS() {
            const now = performance.now();
            const delta = now - lastFrameTime;
            
            frameCount++;
            optimizerState.monitoring.frameTime.push(delta);
            
            // Keep only last 60 frames
            if (optimizerState.monitoring.frameTime.length > 60) {
                optimizerState.monitoring.frameTime.shift();
            }
            
            // Calculate average FPS every second
            if (frameCount >= 60) {
                const avgFrameTime = optimizerState.monitoring.frameTime.reduce((a, b) => a + b, 0) / 
                                   optimizerState.monitoring.frameTime.length;
                optimizerState.monitoring.fps = 1000 / avgFrameTime;
                frameCount = 0;
                
                // Check if adaptive throttling needed
                if (optimizerState.throttling.adaptiveEnabled) {
                    adaptiveThrottleAdjustment();
                }
            }
            
            lastFrameTime = now;
            requestAnimationFrame(measureFPS);
        }
        
        requestAnimationFrame(measureFPS);
        
        // Resource monitoring
        setInterval(monitorResources, optimizerState.config.monitorInterval);
    }

    /**
     * Monitor system resources
     */
    async function monitorResources() {
        // Memory usage (if available)
        if (performance.memory) {
            const used = performance.memory.usedJSHeapSize;
            const total = performance.memory.totalJSHeapSize;
            optimizerState.monitoring.memoryUsage = (used / total) * 100;
        }
        
        // Estimate CPU usage based on frame timing
        const frameVariance = calculateFrameVariance();
        optimizerState.monitoring.cpuUsage = Math.min(100, frameVariance * 2);
        
        // Calculate update frequency
        const now = Date.now();
        const timeDelta = now - optimizerState.monitoring.lastMonitorTime;
        optimizerState.monitoring.updateFrequency = 
            (optimizerState.incremental.patchQueue.length / timeDelta) * 1000;
        optimizerState.monitoring.lastMonitorTime = now;
        
        // Emit monitoring update
        document.dispatchEvent(new CustomEvent('performanceMonitorUpdate', {
            detail: {
                fps: optimizerState.monitoring.fps,
                cpu: optimizerState.monitoring.cpuUsage,
                memory: optimizerState.monitoring.memoryUsage,
                updateFreq: optimizerState.monitoring.updateFrequency,
                throttleLevel: optimizerState.throttling.level,
                cacheHitRate: optimizerState.caching.cacheHitRate
            }
        }));
    }

    /**
     * Adaptive throttling adjustment
     */
    function adaptiveThrottleAdjustment() {
        const currentFPS = optimizerState.monitoring.fps;
        const targetFPS = optimizerState.config.targetFPS;
        const minFPS = optimizerState.config.minFPS;
        
        if (currentFPS < minFPS) {
            // Critical performance - increase throttling
            increaseThrottling(2);
        } else if (currentFPS < targetFPS) {
            // Below target - increase throttling slightly
            increaseThrottling(1);
        } else if (currentFPS > targetFPS * 1.5) {
            // Well above target - can reduce throttling
            decreaseThrottling(1);
        }
        
        console.log(`🎯 Adaptive throttle: FPS=${currentFPS.toFixed(1)}, Level=${optimizerState.throttling.level}`);
    }

    /**
     * Increase throttling level
     */
    function increaseThrottling(steps = 1) {
        const newLevel = Math.min(5, optimizerState.throttling.level + steps * optimizerState.config.adaptiveThrottleStep);
        
        if (newLevel !== optimizerState.throttling.level) {
            optimizerState.throttling.level = newLevel;
            optimizerState.throttling.active = newLevel > 0;
            
            applyThrottlingSettings(newLevel);
            
            console.log(`⬆️ Throttling increased to level ${newLevel.toFixed(1)}`);
        }
    }

    /**
     * Decrease throttling level
     */
    function decreaseThrottling(steps = 1) {
        const newLevel = Math.max(0, optimizerState.throttling.level - steps * optimizerState.config.adaptiveThrottleStep);
        
        if (newLevel !== optimizerState.throttling.level) {
            optimizerState.throttling.level = newLevel;
            optimizerState.throttling.active = newLevel > 0;
            
            applyThrottlingSettings(newLevel);
            
            console.log(`⬇️ Throttling decreased to level ${newLevel.toFixed(1)}`);
        }
    }

    /**
     * Apply throttling settings based on level
     */
    function applyThrottlingSettings(level) {
        // Adjust update frequencies based on throttle level
        const baseDelay = 16; // 60 FPS baseline
        const throttleMultiplier = 1 + level;
        
        // Update debounce delays
        if (window.RealTimeFileWatcher) {
            window.RealTimeFileWatcher.setConfig({
                debounceDelay: baseDelay * throttleMultiplier * 20,
                batchDelay: baseDelay * throttleMultiplier * 6
            });
        }
        
        // Update analysis batch size
        if (window.LiveAnalysisPipeline) {
            const batchSize = Math.max(1, Math.floor(10 / throttleMultiplier));
            // Would update pipeline config here
        }
        
        // Update rendering frequency
        updateRenderingFrequency(throttleMultiplier);
    }

    /**
     * Update rendering frequency
     */
    function updateRenderingFrequency(multiplier) {
        // Skip frames based on throttle level
        const skipFrames = Math.floor(multiplier - 1);
        
        // Apply to D3 force simulation if available
        if (window.d3 && window.forceSimulation) {
            const ticksPerRender = 1 + skipFrames;
            // Would update simulation here
        }
        
        document.dispatchEvent(new CustomEvent('throttleSettingsChanged', {
            detail: {
                level: optimizerState.throttling.level,
                skipFrames,
                multiplier
            }
        }));
    }

    /**
     * Intelligent caching system
     */
    class IntelligentCache {
        constructor(maxSize = 1000, expiry = 60000) {
            this.cache = new Map();
            this.maxSize = maxSize;
            this.expiry = expiry;
            this.accessFrequency = new Map();
        }
        
        get(key) {
            optimizerState.caching.totalRequests++;
            
            if (this.cache.has(key)) {
                const entry = this.cache.get(key);
                
                // Check expiry
                if (Date.now() - entry.timestamp > this.expiry) {
                    this.cache.delete(key);
                    return null;
                }
                
                // Update access frequency
                this.accessFrequency.set(key, (this.accessFrequency.get(key) || 0) + 1);
                
                // Move to end (LRU)
                this.cache.delete(key);
                this.cache.set(key, entry);
                
                optimizerState.caching.hits++;
                optimizerState.caching.cacheHitRate = 
                    optimizerState.caching.hits / optimizerState.caching.totalRequests;
                
                return entry.value;
            }
            
            return null;
        }
        
        set(key, value) {
            // Check cache size
            if (this.cache.size >= this.maxSize) {
                // Evict least recently used with lowest frequency
                this.evictLFU();
            }
            
            this.cache.set(key, {
                value,
                timestamp: Date.now()
            });
        }
        
        evictLFU() {
            let minFreq = Infinity;
            let evictKey = null;
            
            // Find least frequently used
            for (const [key] of this.cache) {
                const freq = this.accessFrequency.get(key) || 0;
                if (freq < minFreq) {
                    minFreq = freq;
                    evictKey = key;
                }
            }
            
            if (evictKey) {
                this.cache.delete(evictKey);
                this.accessFrequency.delete(evictKey);
            }
        }
        
        clear() {
            this.cache.clear();
            this.accessFrequency.clear();
        }
        
        getStats() {
            return {
                size: this.cache.size,
                maxSize: this.maxSize,
                hitRate: optimizerState.caching.cacheHitRate,
                totalRequests: optimizerState.caching.totalRequests
            };
        }
    }

    // Initialize caches
    const analysisCache = new IntelligentCache(
        optimizerState.caching.maxCacheSize,
        optimizerState.config.cacheExpiry
    );
    
    const renderCache = new IntelligentCache(
        500, // Smaller cache for render data
        30000 // 30 second expiry
    );

    /**
     * Incremental update algorithms
     */
    class IncrementalDiffEngine {
        constructor() {
            this.lastState = {
                nodes: new Map(),
                links: new Map()
            };
        }
        
        computeDiff(newState) {
            const diff = {
                nodes: {
                    added: [],
                    modified: [],
                    removed: []
                },
                links: {
                    added: [],
                    modified: [],
                    removed: []
                }
            };
            
            // Diff nodes
            const newNodeMap = new Map(newState.nodes.map(n => [n.id, n]));
            
            // Find added and modified nodes
            newNodeMap.forEach((node, id) => {
                if (!this.lastState.nodes.has(id)) {
                    diff.nodes.added.push(node);
                } else {
                    const oldNode = this.lastState.nodes.get(id);
                    if (this.hasNodeChanged(oldNode, node)) {
                        diff.nodes.modified.push(node);
                    }
                }
            });
            
            // Find removed nodes
            this.lastState.nodes.forEach((node, id) => {
                if (!newNodeMap.has(id)) {
                    diff.nodes.removed.push(id);
                }
            });
            
            // Similar for links
            const newLinkMap = new Map(newState.links.map(l => [this.getLinkId(l), l]));
            
            newLinkMap.forEach((link, id) => {
                if (!this.lastState.links.has(id)) {
                    diff.links.added.push(link);
                } else {
                    const oldLink = this.lastState.links.get(id);
                    if (this.hasLinkChanged(oldLink, link)) {
                        diff.links.modified.push(link);
                    }
                }
            });
            
            this.lastState.links.forEach((link, id) => {
                if (!newLinkMap.has(id)) {
                    diff.links.removed.push(id);
                }
            });
            
            // Update last state
            this.lastState.nodes = newNodeMap;
            this.lastState.links = newLinkMap;
            
            return diff;
        }
        
        hasNodeChanged(oldNode, newNode) {
            // Check relevant properties for changes
            return oldNode.x !== newNode.x ||
                   oldNode.y !== newNode.y ||
                   oldNode.label !== newNode.label ||
                   oldNode.type !== newNode.type;
        }
        
        hasLinkChanged(oldLink, newLink) {
            return oldLink.weight !== newLink.weight ||
                   oldLink.type !== newLink.type;
        }
        
        getLinkId(link) {
            const source = link.source.id || link.source;
            const target = link.target.id || link.target;
            return `${source}-${target}`;
        }
        
        applyPatch(currentState, patch) {
            // Apply incremental changes
            const newState = {
                nodes: [...currentState.nodes],
                links: [...currentState.links]
            };
            
            // Apply node patches
            patch.nodes.removed.forEach(id => {
                const index = newState.nodes.findIndex(n => n.id === id);
                if (index !== -1) newState.nodes.splice(index, 1);
            });
            
            patch.nodes.added.forEach(node => {
                newState.nodes.push(node);
            });
            
            patch.nodes.modified.forEach(node => {
                const index = newState.nodes.findIndex(n => n.id === node.id);
                if (index !== -1) newState.nodes[index] = node;
            });
            
            // Apply link patches
            patch.links.removed.forEach(id => {
                const index = newState.links.findIndex(l => this.getLinkId(l) === id);
                if (index !== -1) newState.links.splice(index, 1);
            });
            
            patch.links.added.forEach(link => {
                newState.links.push(link);
            });
            
            patch.links.modified.forEach(link => {
                const id = this.getLinkId(link);
                const index = newState.links.findIndex(l => this.getLinkId(l) === id);
                if (index !== -1) newState.links[index] = link;
            });
            
            return newState;
        }
    }

    // Initialize diff engine
    optimizerState.incremental.diffEngine = new IncrementalDiffEngine();

    /**
     * Optimize incremental updates
     */
    function optimizeIncrementalUpdate(updateData) {
        const cacheKey = generateCacheKey(updateData);
        
        // Check cache first
        const cached = analysisCache.get(cacheKey);
        if (cached) {
            console.log('✅ Cache hit for incremental update');
            return cached;
        }
        
        // Compute optimized update
        const optimized = {
            ...updateData,
            optimized: true,
            timestamp: Date.now()
        };
        
        // Batch small updates
        if (updateData.nodes && updateData.nodes.length < 5) {
            optimizerState.incremental.patchQueue.push(optimized);
            
            if (optimizerState.incremental.patchQueue.length >= 10) {
                // Merge patches
                optimized.merged = mergePatchQueue();
            } else {
                // Defer update
                optimized.deferred = true;
            }
        }
        
        // Cache result
        analysisCache.set(cacheKey, optimized);
        
        return optimized;
    }

    /**
     * Merge patch queue
     */
    function mergePatchQueue() {
        const merged = {
            nodes: [],
            links: [],
            operations: []
        };
        
        optimizerState.incremental.patchQueue.forEach(patch => {
            if (patch.nodes) merged.nodes.push(...patch.nodes);
            if (patch.links) merged.links.push(...patch.links);
            if (patch.operation) merged.operations.push(patch.operation);
        });
        
        // Clear queue
        optimizerState.incremental.patchQueue = [];
        
        console.log(`🔀 Merged ${merged.nodes.length} nodes, ${merged.links.length} links`);
        
        return merged;
    }

    /**
     * Resource usage optimization
     */
    function optimizeResourceUsage() {
        const usage = {
            cpu: optimizerState.monitoring.cpuUsage,
            memory: optimizerState.monitoring.memoryUsage,
            fps: optimizerState.monitoring.fps
        };
        
        // Memory optimization
        if (usage.memory > 80) {
            console.log('⚠️ High memory usage, clearing caches');
            analysisCache.clear();
            renderCache.clear();
            
            // Force garbage collection if available
            if (window.gc) {
                window.gc();
            }
        }
        
        // CPU optimization
        if (usage.cpu > 80) {
            console.log('⚠️ High CPU usage, increasing throttling');
            increaseThrottling(2);
        }
        
        // FPS optimization
        if (usage.fps < optimizerState.config.minFPS) {
            console.log('⚠️ Low FPS, optimizing rendering');
            optimizeRendering();
        }
        
        return usage;
    }

    /**
     * Optimize rendering performance
     */
    function optimizeRendering() {
        // Reduce visual quality for performance
        document.dispatchEvent(new CustomEvent('reduceRenderQuality', {
            detail: {
                disableAnimations: true,
                reduceNodeDetails: true,
                simplifyLinks: true,
                disableShadows: true
            }
        }));
        
        // Enable hardware acceleration hints
        const svg = document.querySelector('svg');
        if (svg) {
            svg.style.transform = 'translateZ(0)';
            svg.style.willChange = 'transform';
        }
        
        // Reduce update frequency
        optimizerState.config.maxUpdateFrequency = 30;
    }

    /**
     * Utility functions
     */
    function calculateFrameVariance() {
        if (optimizerState.monitoring.frameTime.length < 2) return 0;
        
        const mean = optimizerState.monitoring.frameTime.reduce((a, b) => a + b, 0) / 
                    optimizerState.monitoring.frameTime.length;
        
        const variance = optimizerState.monitoring.frameTime.reduce((sum, time) => {
            return sum + Math.pow(time - mean, 2);
        }, 0) / optimizerState.monitoring.frameTime.length;
        
        return Math.sqrt(variance);
    }
    
    function generateCacheKey(data) {
        // Simple hash for cache key
        const str = JSON.stringify(data);
        let hash = 0;
        for (let i = 0; i < str.length; i++) {
            const char = str.charCodeAt(i);
            hash = ((hash << 5) - hash) + char;
            hash = hash & hash; // Convert to 32bit integer
        }
        return hash.toString(36);
    }

    /**
     * Initialize optimizer
     */
    function initialize() {
        console.log('🚀 Initializing performance optimizer...');
        
        initializeMonitoring();
        
        // Listen for update events
        document.addEventListener('incrementalGraphUpdate', (event) => {
            const optimized = optimizeIncrementalUpdate(event.detail);
            
            if (!optimized.deferred) {
                // Emit optimized update
                document.dispatchEvent(new CustomEvent('optimizedGraphUpdate', {
                    detail: optimized
                }));
            }
        });
        
        // Periodic resource optimization
        setInterval(optimizeResourceUsage, 10000);
        
        console.log('✅ Performance optimizer initialized');
    }

    // Initialize on load
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initialize);
    } else {
        initialize();
    }

    // Public API
    window.RealTimePerformanceOptimizer = {
        getMetrics: () => ({
            fps: optimizerState.monitoring.fps,
            cpu: optimizerState.monitoring.cpuUsage,
            memory: optimizerState.monitoring.memoryUsage,
            throttleLevel: optimizerState.throttling.level,
            cacheHitRate: optimizerState.caching.cacheHitRate
        }),
        setThrottleLevel: (level) => {
            optimizerState.throttling.level = Math.max(0, Math.min(5, level));
            applyThrottlingSettings(optimizerState.throttling.level);
        },
        enableAdaptiveThrottling: (enabled) => {
            optimizerState.throttling.adaptiveEnabled = enabled;
        },
        getCacheStats: () => ({
            analysis: analysisCache.getStats(),
            render: renderCache.getStats()
        }),
        clearCaches: () => {
            analysisCache.clear();
            renderCache.clear();
        },
        forceOptimization: () => {
            optimizeResourceUsage();
        }
    };

    console.log('✅ Real-Time Performance Optimizer module loaded');
})();