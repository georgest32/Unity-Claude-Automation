/**
 * Real-Time File Watcher Integration
 * Monitors file system changes and triggers incremental visualization updates
 * Part of Day 9 Hour 1-2 Implementation
 */

(function() {
    'use strict';

    console.log('🔄 Initializing Real-Time File Watcher module...');

    // File watcher state management
    const fileWatcherState = {
        websocket: null,
        connected: false,
        watchedPaths: new Set(),
        changeQueue: [],
        processingQueue: false,
        debounceTimers: new Map(),
        batchTimeout: null,
        config: {
            debounceDelay: 300, // ms to wait after last change
            batchDelay: 100, // ms to batch multiple changes
            maxBatchSize: 50, // max changes to process at once
            reconnectDelay: 3000, // ms between reconnection attempts
            heartbeatInterval: 30000 // ms between heartbeat pings
        },
        metrics: {
            totalChanges: 0,
            processedChanges: 0,
            droppedChanges: 0,
            reconnectAttempts: 0,
            lastUpdate: null
        }
    };

    /**
     * Initialize WebSocket connection for file system events
     */
    function initializeWebSocket() {
        console.log('🔌 Establishing WebSocket connection for file system events...');
        
        const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        const wsUrl = `${protocol}//${window.location.host}/file-watcher`;
        
        try {
            fileWatcherState.websocket = new WebSocket(wsUrl);
            
            fileWatcherState.websocket.onopen = handleWebSocketOpen;
            fileWatcherState.websocket.onmessage = handleWebSocketMessage;
            fileWatcherState.websocket.onerror = handleWebSocketError;
            fileWatcherState.websocket.onclose = handleWebSocketClose;
            
        } catch (error) {
            console.error('❌ Failed to initialize WebSocket:', error);
            scheduleReconnect();
        }
    }

    /**
     * Handle WebSocket connection established
     */
    function handleWebSocketOpen(event) {
        console.log('✅ File watcher WebSocket connected');
        fileWatcherState.connected = true;
        fileWatcherState.metrics.reconnectAttempts = 0;
        
        // Send initial configuration
        sendWebSocketMessage({
            type: 'configure',
            config: {
                paths: Array.from(fileWatcherState.watchedPaths),
                events: ['add', 'change', 'unlink'],
                ignorePatterns: ['node_modules', '.git', '*.log'],
                usePolling: false,
                awaitWriteFinish: true,
                depth: 3
            }
        });
        
        // Start heartbeat
        startHeartbeat();
        
        // Dispatch connection event
        document.dispatchEvent(new CustomEvent('fileWatcherConnected', {
            detail: { timestamp: Date.now() }
        }));
    }

    /**
     * Handle incoming WebSocket messages
     */
    function handleWebSocketMessage(event) {
        try {
            const message = JSON.parse(event.data);
            console.log('📨 File watcher message:', message.type, message);
            
            switch (message.type) {
                case 'change':
                    handleFileChange(message);
                    break;
                case 'batch':
                    handleBatchChanges(message.changes);
                    break;
                case 'error':
                    handleWatcherError(message);
                    break;
                case 'stats':
                    updateWatcherStats(message.stats);
                    break;
                case 'pong':
                    // Heartbeat response
                    break;
                default:
                    console.warn('Unknown message type:', message.type);
            }
        } catch (error) {
            console.error('❌ Error processing WebSocket message:', error);
        }
    }

    /**
     * Handle file change event
     */
    function handleFileChange(change) {
        console.log(`📝 File ${change.event}: ${change.path}`);
        
        fileWatcherState.metrics.totalChanges++;
        
        // Apply debouncing per file
        const existingTimer = fileWatcherState.debounceTimers.get(change.path);
        if (existingTimer) {
            clearTimeout(existingTimer);
        }
        
        const timer = setTimeout(() => {
            fileWatcherState.debounceTimers.delete(change.path);
            queueChange(change);
        }, fileWatcherState.config.debounceDelay);
        
        fileWatcherState.debounceTimers.set(change.path, timer);
    }

    /**
     * Queue change for batch processing
     */
    function queueChange(change) {
        // Add timestamp if not present
        if (!change.timestamp) {
            change.timestamp = Date.now();
        }
        
        // Check for duplicate changes in queue
        const existingIndex = fileWatcherState.changeQueue.findIndex(
            c => c.path === change.path && c.event === change.event
        );
        
        if (existingIndex !== -1) {
            // Update existing change with latest timestamp
            fileWatcherState.changeQueue[existingIndex] = change;
        } else {
            fileWatcherState.changeQueue.push(change);
        }
        
        // Schedule batch processing
        scheduleBatchProcessing();
    }

    /**
     * Schedule batch processing of queued changes
     */
    function scheduleBatchProcessing() {
        if (fileWatcherState.batchTimeout) {
            clearTimeout(fileWatcherState.batchTimeout);
        }
        
        fileWatcherState.batchTimeout = setTimeout(() => {
            processBatchedChanges();
        }, fileWatcherState.config.batchDelay);
    }

    /**
     * Process batched changes
     */
    async function processBatchedChanges() {
        if (fileWatcherState.processingQueue || fileWatcherState.changeQueue.length === 0) {
            return;
        }
        
        fileWatcherState.processingQueue = true;
        
        // Extract batch of changes
        const batch = fileWatcherState.changeQueue.splice(0, fileWatcherState.config.maxBatchSize);
        console.log(`⚡ Processing batch of ${batch.length} changes`);
        
        try {
            // Group changes by type for efficient processing
            const grouped = groupChangesByType(batch);
            
            // Process each group
            if (grouped.add.length > 0) {
                await processAdditions(grouped.add);
            }
            if (grouped.change.length > 0) {
                await processModifications(grouped.change);
            }
            if (grouped.unlink.length > 0) {
                await processDeletions(grouped.unlink);
            }
            
            fileWatcherState.metrics.processedChanges += batch.length;
            fileWatcherState.metrics.lastUpdate = Date.now();
            
            // Dispatch batch complete event
            document.dispatchEvent(new CustomEvent('fileWatcherBatchProcessed', {
                detail: {
                    batch,
                    timestamp: Date.now(),
                    metrics: fileWatcherState.metrics
                }
            }));
            
        } catch (error) {
            console.error('❌ Error processing batch:', error);
            fileWatcherState.metrics.droppedChanges += batch.length;
        } finally {
            fileWatcherState.processingQueue = false;
            
            // Process remaining changes if any
            if (fileWatcherState.changeQueue.length > 0) {
                scheduleBatchProcessing();
            }
        }
    }

    /**
     * Group changes by event type
     */
    function groupChangesByType(changes) {
        return {
            add: changes.filter(c => c.event === 'add'),
            change: changes.filter(c => c.event === 'change'),
            unlink: changes.filter(c => c.event === 'unlink')
        };
    }

    /**
     * Process file additions
     */
    async function processAdditions(additions) {
        console.log(`➕ Processing ${additions.length} file additions`);
        
        const newNodes = [];
        const newLinks = [];
        
        for (const addition of additions) {
            // Parse file to extract module/dependency information
            const moduleInfo = await parseFileForModuleInfo(addition.path);
            
            if (moduleInfo) {
                // Create node for new file
                newNodes.push({
                    id: addition.path,
                    label: moduleInfo.name || getFileName(addition.path),
                    type: moduleInfo.type || 'module',
                    module: moduleInfo.module,
                    created: addition.timestamp,
                    x: Math.random() * 800,
                    y: Math.random() * 600
                });
                
                // Create links for dependencies
                if (moduleInfo.dependencies) {
                    moduleInfo.dependencies.forEach(dep => {
                        newLinks.push({
                            source: addition.path,
                            target: dep,
                            type: 'import',
                            created: addition.timestamp
                        });
                    });
                }
            }
        }
        
        // Trigger incremental graph update
        if (newNodes.length > 0 || newLinks.length > 0) {
            triggerIncrementalUpdate('add', newNodes, newLinks);
        }
    }

    /**
     * Process file modifications
     */
    async function processModifications(modifications) {
        console.log(`📝 Processing ${modifications.length} file modifications`);
        
        const updatedNodes = [];
        const updatedLinks = [];
        const removedLinks = [];
        
        for (const modification of modifications) {
            // Re-parse file to detect dependency changes
            const moduleInfo = await parseFileForModuleInfo(modification.path);
            
            if (moduleInfo) {
                // Update node information
                updatedNodes.push({
                    id: modification.path,
                    label: moduleInfo.name || getFileName(modification.path),
                    type: moduleInfo.type || 'module',
                    module: moduleInfo.module,
                    modified: modification.timestamp,
                    metrics: moduleInfo.metrics
                });
                
                // Detect dependency changes
                const changes = detectDependencyChanges(modification.path, moduleInfo.dependencies);
                updatedLinks.push(...changes.added);
                removedLinks.push(...changes.removed);
            }
        }
        
        // Trigger incremental graph update
        if (updatedNodes.length > 0 || updatedLinks.length > 0 || removedLinks.length > 0) {
            triggerIncrementalUpdate('modify', updatedNodes, updatedLinks, removedLinks);
        }
    }

    /**
     * Process file deletions
     */
    async function processDeletions(deletions) {
        console.log(`➖ Processing ${deletions.length} file deletions`);
        
        const removedNodes = [];
        const removedLinks = [];
        
        for (const deletion of deletions) {
            // Remove node
            removedNodes.push(deletion.path);
            
            // Remove all links connected to this node
            removedLinks.push({
                source: deletion.path,
                target: '*' // Special marker for all connections
            });
        }
        
        // Trigger incremental graph update
        if (removedNodes.length > 0) {
            triggerIncrementalUpdate('remove', removedNodes, [], removedLinks);
        }
    }

    /**
     * Parse file for module information (mock implementation)
     */
    async function parseFileForModuleInfo(filePath) {
        // In production, this would actually parse the file
        // For now, return mock data
        return {
            name: getFileName(filePath),
            type: getFileType(filePath),
            module: getModuleName(filePath),
            dependencies: generateMockDependencies(filePath),
            metrics: {
                lines: Math.floor(Math.random() * 500) + 50,
                complexity: Math.floor(Math.random() * 20) + 1
            }
        };
    }

    /**
     * Detect dependency changes
     */
    function detectDependencyChanges(filePath, newDependencies) {
        // In production, compare with cached dependencies
        // For now, return mock changes
        return {
            added: newDependencies.slice(0, 2).map(dep => ({
                source: filePath,
                target: dep,
                type: 'import'
            })),
            removed: []
        };
    }

    /**
     * Trigger incremental visualization update
     */
    function triggerIncrementalUpdate(operation, nodes, addedLinks, removedLinks) {
        console.log(`🎯 Triggering incremental update: ${operation}`);
        
        const updateEvent = new CustomEvent('incrementalGraphUpdate', {
            detail: {
                operation,
                nodes,
                addedLinks: addedLinks || [],
                removedLinks: removedLinks || [],
                timestamp: Date.now()
            }
        });
        
        document.dispatchEvent(updateEvent);
        
        // Log debug information
        console.log('📊 Incremental update details:', {
            operation,
            nodeCount: nodes.length,
            addedLinkCount: (addedLinks || []).length,
            removedLinkCount: (removedLinks || []).length
        });
    }

    /**
     * Handle batch changes
     */
    function handleBatchChanges(changes) {
        console.log(`📦 Received batch of ${changes.length} changes`);
        changes.forEach(change => queueChange(change));
    }

    /**
     * Handle watcher error
     */
    function handleWatcherError(error) {
        console.error('❌ File watcher error:', error);
        
        // Dispatch error event
        document.dispatchEvent(new CustomEvent('fileWatcherError', {
            detail: error
        }));
    }

    /**
     * Update watcher statistics
     */
    function updateWatcherStats(stats) {
        console.log('📊 Watcher stats:', stats);
        
        // Update UI if stats display exists
        const statsElement = document.getElementById('file-watcher-stats');
        if (statsElement) {
            statsElement.innerHTML = `
                <div>Files Watched: ${stats.filesWatched}</div>
                <div>Changes Detected: ${stats.changesDetected}</div>
                <div>Last Update: ${new Date(stats.lastUpdate).toLocaleTimeString()}</div>
            `;
        }
    }

    /**
     * Handle WebSocket error
     */
    function handleWebSocketError(error) {
        console.error('❌ WebSocket error:', error);
        fileWatcherState.connected = false;
    }

    /**
     * Handle WebSocket close
     */
    function handleWebSocketClose(event) {
        console.log('🔌 File watcher WebSocket disconnected');
        fileWatcherState.connected = false;
        stopHeartbeat();
        scheduleReconnect();
        
        // Dispatch disconnection event
        document.dispatchEvent(new CustomEvent('fileWatcherDisconnected', {
            detail: { timestamp: Date.now(), code: event.code }
        }));
    }

    /**
     * Schedule reconnection attempt
     */
    function scheduleReconnect() {
        fileWatcherState.metrics.reconnectAttempts++;
        
        console.log(`🔄 Scheduling reconnection attempt #${fileWatcherState.metrics.reconnectAttempts}`);
        
        setTimeout(() => {
            if (!fileWatcherState.connected) {
                initializeWebSocket();
            }
        }, fileWatcherState.config.reconnectDelay);
    }

    /**
     * Send WebSocket message
     */
    function sendWebSocketMessage(message) {
        if (fileWatcherState.websocket && fileWatcherState.websocket.readyState === WebSocket.OPEN) {
            fileWatcherState.websocket.send(JSON.stringify(message));
        } else {
            console.warn('WebSocket not connected, queuing message');
            // Could implement message queue here
        }
    }

    /**
     * Start heartbeat ping
     */
    let heartbeatTimer;
    function startHeartbeat() {
        heartbeatTimer = setInterval(() => {
            sendWebSocketMessage({ type: 'ping' });
        }, fileWatcherState.config.heartbeatInterval);
    }

    /**
     * Stop heartbeat ping
     */
    function stopHeartbeat() {
        if (heartbeatTimer) {
            clearInterval(heartbeatTimer);
            heartbeatTimer = null;
        }
    }

    /**
     * Add path to watch list
     */
    function watchPath(path) {
        fileWatcherState.watchedPaths.add(path);
        
        if (fileWatcherState.connected) {
            sendWebSocketMessage({
                type: 'watch',
                path: path
            });
        }
    }

    /**
     * Remove path from watch list
     */
    function unwatchPath(path) {
        fileWatcherState.watchedPaths.delete(path);
        
        if (fileWatcherState.connected) {
            sendWebSocketMessage({
                type: 'unwatch',
                path: path
            });
        }
    }

    /**
     * Utility functions
     */
    function getFileName(path) {
        return path.split(/[/\\]/).pop().split('.')[0];
    }
    
    function getFileType(path) {
        const ext = path.split('.').pop();
        const typeMap = {
            'js': 'javascript',
            'ts': 'typescript',
            'py': 'python',
            'cs': 'csharp',
            'ps1': 'powershell',
            'psm1': 'powershell',
            'json': 'data',
            'xml': 'data',
            'md': 'documentation'
        };
        return typeMap[ext] || 'unknown';
    }
    
    function getModuleName(path) {
        const parts = path.split(/[/\\]/);
        // Look for module indicators
        for (let i = parts.length - 1; i >= 0; i--) {
            if (parts[i] === 'modules' || parts[i] === 'src' || parts[i] === 'lib') {
                return parts[i + 1] || 'default';
            }
        }
        return 'default';
    }
    
    function generateMockDependencies(path) {
        // Generate some mock dependencies for testing
        const deps = [];
        const depCount = Math.floor(Math.random() * 5);
        for (let i = 0; i < depCount; i++) {
            deps.push(`module${Math.floor(Math.random() * 10)}`);
        }
        return deps;
    }

    /**
     * Initialize on document ready
     */
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initializeWebSocket);
    } else {
        initializeWebSocket();
    }

    // Public API
    window.RealTimeFileWatcher = {
        watchPath,
        unwatchPath,
        getMetrics: () => fileWatcherState.metrics,
        getConfig: () => fileWatcherState.config,
        setConfig: (config) => {
            Object.assign(fileWatcherState.config, config);
        },
        isConnected: () => fileWatcherState.connected,
        getQueueSize: () => fileWatcherState.changeQueue.length,
        forceProcessQueue: () => processBatchedChanges()
    };

    console.log('✅ Real-Time File Watcher module loaded');
})();