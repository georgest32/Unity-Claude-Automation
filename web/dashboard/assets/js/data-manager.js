// Data Manager - Handles graph data loading, processing, and caching

class DataManager {
    constructor() {
        this.cache = new Map();
        this.lastUpdateTime = 0;
        this.isLoading = false;
        this.loadingPromises = new Map();
        
        // Initialize event system
        this.eventListeners = {};
        
        // Data storage
        this.rawData = {
            nodes: [],
            links: [],
            metrics: {}
        };
        
        this.processedData = {
            nodes: [],
            links: [],
            nodeMap: new Map(),
            linkMap: new Map()
        };
        
        // Filters
        this.activeFilters = {
            nodeTypes: new Set(['function', 'class', 'module', 'variable']),
            fileExtensions: new Set(['ps1', 'psm1', 'py', 'js', 'cs']),
            searchQuery: '',
            showConnected: true,
            showIsolated: false
        };
        
        console.log('DataManager initialized');
    }
    
    // Data loading methods
    async loadGraphData(options = {}) {
        const cacheKey = this.getCacheKey('graph', options);
        
        // Return cached data if available and fresh
        if (this.cache.has(cacheKey) && !options.force) {
            const cached = this.cache.get(cacheKey);
            if (Date.now() - cached.timestamp < 300000) { // 5 minutes
                console.log('Returning cached graph data');
                return cached.data;
            }
        }
        
        // Prevent duplicate requests
        if (this.loadingPromises.has(cacheKey)) {
            return this.loadingPromises.get(cacheKey);
        }
        
        const loadingPromise = this.fetchGraphData(options);
        this.loadingPromises.set(cacheKey, loadingPromise);
        
        try {
            const data = await loadingPromise;
            
            // Cache the result
            this.cache.set(cacheKey, {
                data,
                timestamp: Date.now()
            });
            
            // Store raw data
            this.rawData = data;
            
            // Process data for visualization
            this.processData();
            
            // Emit data loaded event
            this.emit('dataLoaded', this.processedData);
            
            return data;
        } catch (error) {
            console.error('Failed to load graph data:', error);
            this.emit('dataError', error);
            throw error;
        } finally {
            this.loadingPromises.delete(cacheKey);
        }
    }
    
    async fetchGraphData(options = {}) {
        this.isLoading = true;
        this.emit('loadingStart');
        
        try {
            // Check if we should use mock data for development
            if (DashboardConfig.debug.mockData) {
                return this.generateMockData(options);
            }
            
            // Fetch from API
            const response = await fetch(ConfigUtils.getApiUrl('graphData'), {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    filters: options.filters,
                    includeDependencies: options.includeDependencies !== false,
                    includeMetrics: options.includeMetrics !== false,
                    maxDepth: options.maxDepth || 10
                })
            });
            
            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }
            
            const data = await response.json();
            
            console.log(`Loaded graph data: ${data.nodes.length} nodes, ${data.links.length} links`);
            
            return data;
        } finally {
            this.isLoading = false;
            this.emit('loadingEnd');
        }
    }
    
    generateMockData(options = {}) {
        console.log('Generating mock graph data');
        
        const nodeCount = options.nodeCount || 100;
        const linkDensity = options.linkDensity || 0.05;
        
        // Node types and their relative frequencies
        const nodeTypes = [
            { type: 'function', weight: 0.5, color: '#2563eb' },
            { type: 'class', weight: 0.2, color: '#dc2626' },
            { type: 'module', weight: 0.15, color: '#059669' },
            { type: 'variable', weight: 0.1, color: '#7c3aed' },
            { type: 'interface', weight: 0.05, color: '#ea580c' }
        ];
        
        // File extensions
        const fileExtensions = ['ps1', 'psm1', 'py', 'js', 'cs', 'ts'];
        
        // Generate nodes
        const nodes = [];
        for (let i = 0; i < nodeCount; i++) {
            // Select node type based on weights
            let randomValue = Math.random();
            let selectedType = nodeTypes[0];
            
            for (const nodeType of nodeTypes) {
                if (randomValue < nodeType.weight) {
                    selectedType = nodeType;
                    break;
                }
                randomValue -= nodeType.weight;
            }
            
            const fileExt = fileExtensions[Math.floor(Math.random() * fileExtensions.length)];
            const fileName = `File${Math.floor(i / 10) + 1}.${fileExt}`;
            
            nodes.push({
                id: `node-${i}`,
                name: `${selectedType.type.charAt(0).toUpperCase() + selectedType.type.slice(1)}${i}`,
                type: selectedType.type,
                file: fileName,
                line: Math.floor(Math.random() * 1000) + 1,
                importance: Math.random(),
                dependencies: [],
                metrics: {
                    complexity: Math.floor(Math.random() * 20) + 1,
                    usage: Math.floor(Math.random() * 100),
                    lastModified: Date.now() - Math.random() * 86400000 * 30 // Last 30 days
                }
            });
        }
        
        // Generate links
        const links = [];
        const linkTypes = ['calls', 'imports', 'inherits', 'references', 'contains'];
        const expectedLinks = Math.floor(nodeCount * linkDensity * nodeCount);
        
        for (let i = 0; i < expectedLinks; i++) {
            const sourceIndex = Math.floor(Math.random() * nodeCount);
            const targetIndex = Math.floor(Math.random() * nodeCount);
            
            // Avoid self-links and duplicates
            if (sourceIndex === targetIndex) continue;
            
            const linkId = `${sourceIndex}-${targetIndex}`;
            if (links.some(link => link.id === linkId)) continue;
            
            const linkType = linkTypes[Math.floor(Math.random() * linkTypes.length)];
            
            links.push({
                id: linkId,
                source: `node-${sourceIndex}`,
                target: `node-${targetIndex}`,
                type: linkType,
                strength: Math.random() * 0.8 + 0.2,
                directed: linkType !== 'references'
            });
        }
        
        // Generate metrics
        const metrics = {
            codeHealth: {
                score: 75 + Math.random() * 20,
                issues: Math.floor(Math.random() * 50),
                lastCheck: Date.now()
            },
            obsolescence: {
                deadCodePercentage: Math.random() * 5,
                unusedFunctions: Math.floor(Math.random() * 20),
                lastAnalysis: Date.now()
            },
            coverage: {
                documentation: 60 + Math.random() * 30,
                tests: 50 + Math.random() * 40,
                comments: 70 + Math.random() * 25,
                lastUpdate: Date.now()
            },
            performance: {
                averageComplexity: 5 + Math.random() * 10,
                hotspots: Math.floor(Math.random() * 10),
                lastProfiled: Date.now()
            }
        };
        
        return { nodes, links, metrics };
    }
    
    // Data processing methods
    processData() {
        const startTime = performance.now();
        
        // Apply filters to nodes
        const filteredNodes = this.applyNodeFilters(this.rawData.nodes);
        
        // Create node map for efficient lookup
        const nodeMap = new Map();
        filteredNodes.forEach(node => {
            nodeMap.set(node.id, node);
        });
        
        // Apply filters to links (only keep links between filtered nodes)
        const filteredLinks = this.rawData.links.filter(link => {
            const sourceId = typeof link.source === 'string' ? link.source : link.source.id;
            const targetId = typeof link.target === 'string' ? link.target : link.target.id;
            
            return nodeMap.has(sourceId) && nodeMap.has(targetId);
        });
        
        // Create link map
        const linkMap = new Map();
        filteredLinks.forEach(link => {
            linkMap.set(link.id, link);
        });
        
        // Calculate additional metrics
        this.calculateNodeMetrics(filteredNodes, filteredLinks);
        
        // Store processed data
        this.processedData = {
            nodes: filteredNodes,
            links: filteredLinks,
            nodeMap,
            linkMap,
            processingTime: performance.now() - startTime
        };
        
        console.log(`Processed data: ${filteredNodes.length} nodes, ${filteredLinks.length} links (${this.processedData.processingTime.toFixed(2)}ms)`);
        
        // Emit processed data event
        this.emit('dataProcessed', this.processedData);
    }
    
    applyNodeFilters(nodes) {
        return nodes.filter(node => {
            // Node type filter
            if (!this.activeFilters.nodeTypes.has(node.type)) {
                return false;
            }
            
            // File extension filter
            if (node.file) {
                const extension = node.file.split('.').pop().toLowerCase();
                if (!this.activeFilters.fileExtensions.has(extension)) {
                    return false;
                }
            }
            
            // Search query filter
            if (this.activeFilters.searchQuery) {
                const query = this.activeFilters.searchQuery.toLowerCase();
                const searchableText = [
                    node.name || '',
                    node.file || '',
                    node.type || ''
                ].join(' ').toLowerCase();
                
                if (!searchableText.includes(query)) {
                    return false;
                }
            }
            
            return true;
        });
    }
    
    calculateNodeMetrics(nodes, links) {
        const nodeConnections = new Map();
        
        // Calculate node connections
        links.forEach(link => {
            const sourceId = typeof link.source === 'string' ? link.source : link.source.id;
            const targetId = typeof link.target === 'string' ? link.target : link.target.id;
            
            if (!nodeConnections.has(sourceId)) {
                nodeConnections.set(sourceId, { incoming: 0, outgoing: 0, total: 0 });
            }
            if (!nodeConnections.has(targetId)) {
                nodeConnections.set(targetId, { incoming: 0, outgoing: 0, total: 0 });
            }
            
            nodeConnections.get(sourceId).outgoing++;
            nodeConnections.get(sourceId).total++;
            nodeConnections.get(targetId).incoming++;
            nodeConnections.get(targetId).total++;
        });
        
        // Apply connection metrics to nodes
        nodes.forEach(node => {
            const connections = nodeConnections.get(node.id) || { incoming: 0, outgoing: 0, total: 0 };
            
            node.connections = connections;
            node.centrality = connections.total / Math.max(1, links.length * 2); // Normalized
            node.importance = (node.importance || 0) + connections.total * 0.1;
            
            // Apply isolation filter
            if (!this.activeFilters.showIsolated && connections.total === 0) {
                node.filtered = true;
            }
            if (!this.activeFilters.showConnected && connections.total > 0) {
                node.filtered = true;
            }
        });
    }
    
    // Filter management
    updateFilters(newFilters) {
        let filtersChanged = false;
        
        Object.keys(newFilters).forEach(key => {
            if (key === 'nodeTypes' || key === 'fileExtensions') {
                // Handle Set-based filters
                const currentSet = this.activeFilters[key];
                const newSet = new Set(newFilters[key]);
                
                if (currentSet.size !== newSet.size || 
                    ![...currentSet].every(item => newSet.has(item))) {
                    this.activeFilters[key] = newSet;
                    filtersChanged = true;
                }
            } else if (this.activeFilters[key] !== newFilters[key]) {
                this.activeFilters[key] = newFilters[key];
                filtersChanged = true;
            }
        });
        
        if (filtersChanged) {
            console.log('Filters updated:', this.activeFilters);
            this.processData();
            this.emit('filtersChanged', this.activeFilters);
        }
    }
    
    clearFilters() {
        this.activeFilters = {
            nodeTypes: new Set(['function', 'class', 'module', 'variable']),
            fileExtensions: new Set(['ps1', 'psm1', 'py', 'js', 'cs']),
            searchQuery: '',
            showConnected: true,
            showIsolated: false
        };
        
        this.processData();
        this.emit('filtersCleared', this.activeFilters);
    }
    
    // Search methods
    searchNodes(query, maxResults = 50) {
        if (!query || query.length < DashboardConfig.filters.minSearchLength) {
            return [];
        }
        
        const queryLower = query.toLowerCase();
        const results = [];
        
        for (const node of this.processedData.nodes) {
            if (results.length >= maxResults) break;
            
            const searchableText = [
                node.name || '',
                node.file || '',
                node.type || ''
            ].join(' ').toLowerCase();
            
            if (searchableText.includes(queryLower)) {
                // Calculate relevance score
                let score = 0;
                if (node.name && node.name.toLowerCase().includes(queryLower)) {
                    score += 10;
                    if (node.name.toLowerCase().startsWith(queryLower)) {
                        score += 20;
                    }
                }
                if (node.file && node.file.toLowerCase().includes(queryLower)) {
                    score += 5;
                }
                if (node.type && node.type.toLowerCase().includes(queryLower)) {
                    score += 3;
                }
                
                results.push({
                    node,
                    score,
                    matchedFields: []
                });
            }
        }
        
        // Sort by relevance score
        results.sort((a, b) => b.score - a.score);
        
        return results.map(result => result.node);
    }
    
    // Path analysis methods
    findPath(sourceId, targetId, maxDepth = 5) {
        const queue = [[sourceId]];
        const visited = new Set([sourceId]);
        const nodeMap = this.processedData.nodeMap;
        
        while (queue.length > 0) {
            const path = queue.shift();
            const currentId = path[path.length - 1];
            
            if (currentId === targetId) {
                // Convert IDs to node objects
                return path.map(id => nodeMap.get(id)).filter(Boolean);
            }
            
            if (path.length >= maxDepth) continue;
            
            // Find connected nodes
            const connectedIds = this.getConnectedNodeIds(currentId);
            
            for (const nextId of connectedIds) {
                if (!visited.has(nextId)) {
                    visited.add(nextId);
                    queue.push([...path, nextId]);
                }
            }
        }
        
        return null; // No path found
    }
    
    findAllPaths(sourceId, targetId, maxDepth = 3, maxPaths = 10) {
        const paths = [];
        const nodeMap = this.processedData.nodeMap;
        
        const findPathsRecursive = (currentPath, visited, depth) => {
            if (paths.length >= maxPaths || depth > maxDepth) return;
            
            const currentId = currentPath[currentPath.length - 1];
            
            if (currentId === targetId && currentPath.length > 1) {
                paths.push([...currentPath]);
                return;
            }
            
            const connectedIds = this.getConnectedNodeIds(currentId);
            
            for (const nextId of connectedIds) {
                if (!visited.has(nextId)) {
                    const newVisited = new Set(visited);
                    newVisited.add(nextId);
                    findPathsRecursive([...currentPath, nextId], newVisited, depth + 1);
                }
            }
        };
        
        findPathsRecursive([sourceId], new Set([sourceId]), 0);
        
        // Convert IDs to node objects
        return paths.map(path => 
            path.map(id => nodeMap.get(id)).filter(Boolean)
        );
    }
    
    getConnectedNodeIds(nodeId) {
        const connectedIds = new Set();
        
        this.processedData.links.forEach(link => {
            const sourceId = typeof link.source === 'string' ? link.source : link.source.id;
            const targetId = typeof link.target === 'string' ? link.target : link.target.id;
            
            if (sourceId === nodeId) {
                connectedIds.add(targetId);
            } else if (targetId === nodeId && !link.directed) {
                connectedIds.add(sourceId);
            }
        });
        
        return Array.from(connectedIds);
    }
    
    // Node details methods
    async getNodeDetails(nodeId) {
        const cacheKey = `node-details-${nodeId}`;
        
        // Check cache first
        if (this.cache.has(cacheKey)) {
            const cached = this.cache.get(cacheKey);
            if (Date.now() - cached.timestamp < 60000) { // 1 minute
                return cached.data;
            }
        }
        
        try {
            const response = await fetch(ConfigUtils.getApiUrl('nodeDetails', { id: nodeId }));
            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }
            
            const details = await response.json();
            
            // Cache the result
            this.cache.set(cacheKey, {
                data: details,
                timestamp: Date.now()
            });
            
            return details;
        } catch (error) {
            console.error('Failed to load node details:', error);
            
            // Return basic details from processed data
            const node = this.processedData.nodeMap.get(nodeId);
            return node ? {
                ...node,
                detailsUnavailable: true
            } : null;
        }
    }
    
    // Metrics methods
    async loadMetrics(force = false) {
        const cacheKey = 'metrics';
        
        if (!force && this.cache.has(cacheKey)) {
            const cached = this.cache.get(cacheKey);
            if (Date.now() - cached.timestamp < 30000) { // 30 seconds
                return cached.data;
            }
        }
        
        try {
            const response = await fetch(ConfigUtils.getApiUrl('metrics'));
            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }
            
            const metrics = await response.json();
            
            this.cache.set(cacheKey, {
                data: metrics,
                timestamp: Date.now()
            });
            
            this.emit('metricsUpdated', metrics);
            
            return metrics;
        } catch (error) {
            console.error('Failed to load metrics:', error);
            this.emit('metricsError', error);
            
            // Return mock metrics if available
            return this.rawData.metrics || {};
        }
    }
    
    // Utility methods
    getCacheKey(type, options) {
        return `${type}-${JSON.stringify(options)}`;
    }
    
    clearCache() {
        this.cache.clear();
        console.log('Data cache cleared');
    }
    
    getStats() {
        return {
            cache: {
                size: this.cache.size,
                keys: Array.from(this.cache.keys())
            },
            data: {
                rawNodes: this.rawData.nodes?.length || 0,
                rawLinks: this.rawData.links?.length || 0,
                processedNodes: this.processedData.nodes?.length || 0,
                processedLinks: this.processedData.links?.length || 0,
                processingTime: this.processedData.processingTime || 0
            },
            filters: this.activeFilters,
            isLoading: this.isLoading,
            lastUpdateTime: this.lastUpdateTime
        };
    }
    
    // Event system
    on(eventName, callback) {
        if (!this.eventListeners[eventName]) {
            this.eventListeners[eventName] = [];
        }
        this.eventListeners[eventName].push(callback);
        
        return () => {
            const index = this.eventListeners[eventName].indexOf(callback);
            if (index > -1) {
                this.eventListeners[eventName].splice(index, 1);
            }
        };
    }
    
    emit(eventName, data) {
        if (this.eventListeners[eventName]) {
            this.eventListeners[eventName].forEach(callback => {
                try {
                    callback(data);
                } catch (error) {
                    console.error(`Error in ${eventName} event handler:`, error);
                }
            });
        }
        
        // Also emit as custom DOM event
        const event = new CustomEvent(`data-${eventName}`, { 
            detail: data 
        });
        document.dispatchEvent(event);
    }
    
    destroy() {
        this.clearCache();
        this.eventListeners = {};
        console.log('DataManager destroyed');
    }
}

// Export for module systems
if (typeof module !== 'undefined' && module.exports) {
    module.exports = DataManager;
}

// Global availability
window.DataManager = DataManager;