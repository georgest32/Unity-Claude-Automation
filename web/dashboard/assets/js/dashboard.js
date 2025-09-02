// Main Dashboard Integration - Coordinates all dashboard components
// This file initializes and orchestrates the entire D3.js visualization dashboard

class Dashboard {
    constructor() {
        this.components = {};
        this.isInitialized = false;
        this.isDestroyed = false;
        
        // Component references
        this.dataManager = null;
        this.graphRenderer = null;
        this.graphControls = null;
        this.metricsCharts = null;
        this.exportHandler = null;
        this.websocketManager = null;
        
        // State management
        this.state = {
            currentData: null,
            selectedNodes: new Set(),
            highlightedPath: null,
            activeFilters: {},
            viewMode: 'graph', // 'graph', 'metrics', 'split'
            lastUpdateTime: null
        };
        
        // Performance monitoring
        this.performanceMetrics = {
            initTime: 0,
            renderTime: 0,
            updateTime: 0,
            frameCount: 0,
            averageFps: 0
        };
        
        // Event handlers bound to this instance
        this.boundEventHandlers = {
            resize: this.handleResize.bind(this),
            keydown: this.handleKeydown.bind(this),
            visibilityChange: this.handleVisibilityChange.bind(this)
        };
        
        console.log('Dashboard initialized');
    }
    
    // Main initialization method
    async initialize() {
        if (this.isInitialized) {
            console.warn('Dashboard already initialized');
            return;
        }
        
        const startTime = performance.now();
        
        try {
            console.log('Starting dashboard initialization...');
            
            // Show loading indicator
            this.showLoadingIndicator();
            
            // Initialize components in dependency order
            await this.initializeCore();
            await this.initializeDataLayer();
            await this.initializeVisualization();
            await this.initializeControls();
            await this.initializeMetrics();
            await this.initializeExport();
            await this.initializeWebSocket();
            
            // Set up event listeners
            this.setupEventListeners();
            
            // Load initial data
            await this.loadInitialData();
            
            // Setup periodic updates
            this.setupPeriodicUpdates();
            
            // Mark as initialized
            this.isInitialized = true;
            this.performanceMetrics.initTime = performance.now() - startTime;
            
            // Hide loading indicator
            this.hideLoadingIndicator();
            
            console.log(`Dashboard initialization complete in ${this.performanceMetrics.initTime.toFixed(2)}ms`);
            
            // Emit ready event
            this.emit('dashboardReady', {
                initTime: this.performanceMetrics.initTime,
                componentCount: Object.keys(this.components).length
            });
            
        } catch (error) {
            console.error('Dashboard initialization failed:', error);
            this.showErrorMessage('Failed to initialize dashboard: ' + error.message);
            throw error;
        }
    }
    
    // Core initialization
    async initializeCore() {
        // Verify required DOM elements exist
        const requiredElements = [
            'graphCanvas', 'graphSvg', 'metricsContainer', 
            'controlsPanel', 'loadingIndicator'
        ];
        
        for (const elementId of requiredElements) {
            const element = document.getElementById(elementId);
            if (!element) {
                throw new Error(`Required DOM element '${elementId}' not found`);
            }
        }
        
        // Validate browser capabilities
        if (!this.validateBrowserCapabilities()) {
            throw new Error('Browser does not support required features');
        }
        
        console.log('Core initialization complete');
    }
    
    // Initialize data management layer
    async initializeDataLayer() {
        this.dataManager = new DataManager();
        this.components.dataManager = this.dataManager;
        
        // Set up data manager event listeners
        this.dataManager.on('dataLoaded', this.handleDataLoaded.bind(this));
        this.dataManager.on('dataFiltered', this.handleDataFiltered.bind(this));
        this.dataManager.on('dataError', this.handleDataError.bind(this));
        
        console.log('Data layer initialized');
    }
    
    // Initialize graph visualization
    async initializeVisualization() {
        this.graphRenderer = new GraphRenderer('#graphCanvas', '#graphSvg');
        this.components.graphRenderer = this.graphRenderer;
        
        // Set up graph renderer event listeners
        this.graphRenderer.on('nodeSelected', this.handleNodeSelected.bind(this));
        this.graphRenderer.on('nodeHovered', this.handleNodeHovered.bind(this));
        this.graphRenderer.on('pathHighlighted', this.handlePathHighlighted.bind(this));
        this.graphRenderer.on('renderComplete', this.handleRenderComplete.bind(this));
        
        console.log('Graph visualization initialized');
    }
    
    // Initialize interactive controls
    async initializeControls() {
        this.graphControls = new GraphControls(this.dataManager, this.graphRenderer);
        this.components.graphControls = this.graphControls;
        
        // Set up controls event listeners
        this.graphControls.on('filterApplied', this.handleFilterApplied.bind(this));
        this.graphControls.on('searchPerformed', this.handleSearchPerformed.bind(this));
        this.graphControls.on('pathRequested', this.handlePathRequested.bind(this));
        this.graphControls.on('layoutChanged', this.handleLayoutChanged.bind(this));
        
        console.log('Interactive controls initialized');
    }
    
    // Initialize metrics dashboard
    async initializeMetrics() {
        this.metricsCharts = new MetricsCharts();
        this.components.metricsCharts = this.metricsCharts;
        
        // Set up metrics event listeners
        this.metricsCharts.on('chartReady', this.handleChartReady.bind(this));
        this.metricsCharts.on('chartError', this.handleChartError.bind(this));
        this.metricsCharts.on('dataPointSelected', this.handleDataPointSelected.bind(this));
        
        console.log('Metrics dashboard initialized');
    }
    
    // Initialize export functionality
    async initializeExport() {
        this.exportHandler = new ExportHandler(this.graphRenderer, this.metricsCharts);
        this.components.exportHandler = this.exportHandler;
        
        // Set up export event listeners
        this.exportHandler.on('exportStarted', this.handleExportStarted.bind(this));
        this.exportHandler.on('exportComplete', this.handleExportComplete.bind(this));
        this.exportHandler.on('exportError', this.handleExportError.bind(this));
        
        console.log('Export functionality initialized');
    }
    
    // Initialize WebSocket connection
    async initializeWebSocket() {
        this.websocketManager = new WebSocketManager();
        this.components.websocketManager = this.websocketManager;
        
        // Set up WebSocket event listeners
        this.websocketManager.on('connected', this.handleWebSocketConnected.bind(this));
        this.websocketManager.on('disconnected', this.handleWebSocketDisconnected.bind(this));
        this.websocketManager.on('graphUpdate', this.handleGraphUpdate.bind(this));
        this.websocketManager.on('metricsUpdate', this.handleMetricsUpdate.bind(this));
        this.websocketManager.on('fileChange', this.handleFileChange.bind(this));
        
        // Connect to WebSocket
        this.websocketManager.connect();
        
        console.log('WebSocket connection initialized');
    }
    
    // Load initial data
    async loadInitialData() {
        try {
            console.log('Loading initial data...');
            
            // Load graph data
            const graphData = await this.dataManager.loadGraphData({
                includeMetrics: true,
                maxNodes: DashboardConfig.graph.maxNodes
            });
            
            if (graphData && graphData.nodes && graphData.nodes.length > 0) {
                // Render initial graph
                await this.graphRenderer.renderGraph(graphData);
                
                // Update metrics
                await this.metricsCharts.updateAllCharts(graphData.metrics || {});
                
                // Update state
                this.state.currentData = graphData;
                this.state.lastUpdateTime = Date.now();
                
                console.log(`Initial data loaded: ${graphData.nodes.length} nodes, ${graphData.links.length} links`);
            } else {
                console.warn('No initial data available, using mock data');
                await this.loadMockData();
            }
            
        } catch (error) {
            console.error('Failed to load initial data:', error);
            await this.loadMockData();
        }
    }
    
    // Load mock data as fallback
    async loadMockData() {
        console.log('Loading mock data...');
        
        const mockData = this.dataManager.generateMockData({
            nodeCount: 50,
            linkCount: 100
        });
        
        await this.graphRenderer.renderGraph(mockData);
        await this.metricsCharts.updateAllCharts(mockData.metrics);
        
        this.state.currentData = mockData;
        this.state.lastUpdateTime = Date.now();
        
        console.log('Mock data loaded');
    }
    
    // Event listeners setup
    setupEventListeners() {
        // Window events
        window.addEventListener('resize', this.boundEventHandlers.resize);
        document.addEventListener('keydown', this.boundEventHandlers.keydown);
        document.addEventListener('visibilitychange', this.boundEventHandlers.visibilityChange);
        
        // Custom dashboard events
        document.addEventListener('dashboard-export-request', this.handleExportRequest.bind(this));
        document.addEventListener('dashboard-view-change', this.handleViewChange.bind(this));
        document.addEventListener('dashboard-refresh-request', this.handleRefreshRequest.bind(this));
        
        console.log('Event listeners setup complete');
    }
    
    // Periodic updates setup
    setupPeriodicUpdates() {
        // Auto-refresh data every 30 seconds
        setInterval(async () => {
            if (this.isDestroyed || document.hidden) return;
            
            try {
                await this.refreshData({ incremental: true });
            } catch (error) {
                console.warn('Periodic refresh failed:', error);
            }
        }, DashboardConfig.updates.refreshInterval);
        
        // Performance monitoring every second
        setInterval(() => {
            this.updatePerformanceMetrics();
        }, 1000);
        
        console.log('Periodic updates configured');
    }
    
    // Event Handlers
    handleDataLoaded(data) {
        console.log('Data loaded event received:', data);
        this.state.currentData = data;
        this.state.lastUpdateTime = Date.now();
        
        // Update UI elements
        this.updateDataInfo(data);
        this.emit('dataUpdated', data);
    }
    
    handleDataFiltered(filteredData) {
        console.log('Data filtered:', filteredData);
        this.graphRenderer.renderGraph(filteredData);
        this.emit('viewUpdated', filteredData);
    }
    
    handleNodeSelected(nodeData) {
        console.log('Node selected:', nodeData);
        
        this.state.selectedNodes.clear();
        this.state.selectedNodes.add(nodeData.id);
        
        // Update controls
        this.graphControls.setSelectedNode(nodeData);
        
        // Update metrics for selected node
        this.metricsCharts.highlightNodeMetrics(nodeData);
        
        this.emit('nodeSelectionChanged', {
            selectedNodes: Array.from(this.state.selectedNodes),
            nodeData
        });
    }
    
    handlePathHighlighted(pathData) {
        console.log('Path highlighted:', pathData);
        
        this.state.highlightedPath = pathData;
        
        // Update metrics for path
        if (pathData && pathData.length > 0) {
            this.metricsCharts.showPathMetrics(pathData);
        }
        
        this.emit('pathHighlighted', pathData);
    }
    
    handleWebSocketConnected() {
        console.log('WebSocket connected');
        this.updateConnectionStatus(true);
        
        // Subscribe to relevant updates
        this.websocketManager.subscribeToFileChanges(['*.ps1', '*.psm1', '*.psd1']);
        this.websocketManager.requestMetricsUpdate();
    }
    
    handleWebSocketDisconnected() {
        console.log('WebSocket disconnected');
        this.updateConnectionStatus(false);
    }
    
    handleGraphUpdate(updateData) {
        console.log('Graph update received:', updateData);
        
        if (updateData.updateType === 'full') {
            this.refreshData({ force: true });
        } else {
            this.dataManager.applyIncrementalUpdate(updateData);
        }
    }
    
    handleMetricsUpdate(metricsData) {
        console.log('Metrics update received:', metricsData);
        this.metricsCharts.updateAllCharts(metricsData);
    }
    
    handleFileChange(fileData) {
        console.log('File change detected:', fileData);
        
        // Show file change notification
        this.showNotification(`File changed: ${fileData.path}`, 'info');
        
        // Request updated data
        setTimeout(() => {
            this.refreshData({ incremental: true });
        }, 2000);
    }
    
    handleResize() {
        if (this.isDestroyed) return;
        
        console.log('Window resized');
        
        // Resize graph renderer
        if (this.graphRenderer) {
            this.graphRenderer.handleResize();
        }
        
        // Resize metrics charts
        if (this.metricsCharts) {
            this.metricsCharts.handleResize();
        }
    }
    
    handleKeydown(event) {
        if (this.isDestroyed) return;
        
        // Global keyboard shortcuts
        if (event.ctrlKey || event.metaKey) {
            switch (event.key) {
                case 'r':
                    event.preventDefault();
                    this.refreshData({ force: true });
                    break;
                case 'e':
                    event.preventDefault();
                    this.exportHandler.showExportDialog();
                    break;
                case 'f':
                    event.preventDefault();
                    this.graphControls.focusSearchInput();
                    break;
            }
        }
    }
    
    handleVisibilityChange() {
        if (document.hidden) {
            console.log('Dashboard hidden, pausing updates');
            this.pauseUpdates();
        } else {
            console.log('Dashboard visible, resuming updates');
            this.resumeUpdates();
        }
    }
    
    // Public API Methods
    async refreshData(options = {}) {
        const startTime = performance.now();
        
        try {
            console.log('Refreshing data...', options);
            
            const refreshOptions = {
                force: options.force || false,
                incremental: options.incremental || false,
                includeMetrics: true
            };
            
            const data = await this.dataManager.loadGraphData(refreshOptions);
            
            if (data) {
                if (options.incremental && this.state.currentData) {
                    // Merge with existing data
                    const mergedData = this.dataManager.mergeData(this.state.currentData, data);
                    this.state.currentData = mergedData;
                } else {
                    this.state.currentData = data;
                }
                
                // Re-render graph
                await this.graphRenderer.renderGraph(this.state.currentData);
                
                // Update metrics
                if (data.metrics) {
                    await this.metricsCharts.updateAllCharts(data.metrics);
                }
                
                this.state.lastUpdateTime = Date.now();
                this.performanceMetrics.updateTime = performance.now() - startTime;
                
                console.log(`Data refresh complete in ${this.performanceMetrics.updateTime.toFixed(2)}ms`);
                
                this.emit('dataRefreshed', {
                    data: this.state.currentData,
                    updateTime: this.performanceMetrics.updateTime
                });
            }
            
        } catch (error) {
            console.error('Data refresh failed:', error);
            this.showErrorMessage('Failed to refresh data: ' + error.message);
        }
    }
    
    setViewMode(mode) {
        if (['graph', 'metrics', 'split'].includes(mode)) {
            this.state.viewMode = mode;
            document.body.setAttribute('data-view-mode', mode);
            
            this.emit('viewModeChanged', { mode });
            console.log('View mode changed to:', mode);
        }
    }
    
    getState() {
        return { ...this.state };
    }
    
    getPerformanceMetrics() {
        return { ...this.performanceMetrics };
    }
    
    // Utility Methods
    validateBrowserCapabilities() {
        // Check for required features
        const required = [
            'WebSocket',
            'Worker',
            'Canvas',
            'SVG',
            'JSON',
            'Promise'
        ];
        
        for (const feature of required) {
            if (!(feature in window)) {
                console.error(`Required feature '${feature}' not supported`);
                return false;
            }
        }
        
        // Check Canvas 2D context
        const canvas = document.createElement('canvas');
        if (!canvas.getContext('2d')) {
            console.error('Canvas 2D context not supported');
            return false;
        }
        
        return true;
    }
    
    updatePerformanceMetrics() {
        this.performanceMetrics.frameCount++;
        
        if (this.graphRenderer && this.graphRenderer.getStats) {
            const stats = this.graphRenderer.getStats();
            this.performanceMetrics.averageFps = stats.averageFps;
            this.performanceMetrics.renderTime = stats.lastRenderTime;
        }
    }
    
    updateConnectionStatus(isConnected) {
        const indicator = document.getElementById('connectionStatus');
        if (indicator) {
            indicator.textContent = isConnected ? 'Connected' : 'Disconnected';
            indicator.className = `connection-status ${isConnected ? 'connected' : 'disconnected'}`;
        }
    }
    
    updateDataInfo(data) {
        const infoElement = document.getElementById('dataInfo');
        if (infoElement && data) {
            const nodeCount = data.nodes ? data.nodes.length : 0;
            const linkCount = data.links ? data.links.length : 0;
            const lastUpdate = new Date(this.state.lastUpdateTime).toLocaleTimeString();
            
            infoElement.innerHTML = `
                <span>Nodes: ${nodeCount}</span>
                <span>Links: ${linkCount}</span>
                <span>Updated: ${lastUpdate}</span>
            `;
        }
    }
    
    showLoadingIndicator() {
        const indicator = document.getElementById('loadingIndicator');
        if (indicator) {
            indicator.style.display = 'flex';
        }
    }
    
    hideLoadingIndicator() {
        const indicator = document.getElementById('loadingIndicator');
        if (indicator) {
            indicator.style.display = 'none';
        }
    }
    
    showNotification(message, type = 'info') {
        // Simple notification system
        const notification = document.createElement('div');
        notification.className = `notification notification-${type}`;
        notification.textContent = message;
        
        document.body.appendChild(notification);
        
        setTimeout(() => {
            notification.style.opacity = '0';
            setTimeout(() => {
                document.body.removeChild(notification);
            }, 300);
        }, 3000);
    }
    
    showErrorMessage(message) {
        console.error(message);
        this.showNotification(message, 'error');
    }
    
    pauseUpdates() {
        // Implementation for pausing periodic updates
        if (this.websocketManager) {
            this.websocketManager.pause();
        }
    }
    
    resumeUpdates() {
        // Implementation for resuming periodic updates
        if (this.websocketManager) {
            this.websocketManager.resume();
        }
        
        // Trigger a refresh when resuming
        this.refreshData({ incremental: true });
    }
    
    // Event system
    emit(eventName, data) {
        const event = new CustomEvent(`dashboard-${eventName}`, {
            detail: data,
            bubbles: true
        });
        document.dispatchEvent(event);
        
        if (DashboardConfig.debug.enabled) {
            console.log(`Dashboard event: ${eventName}`, data);
        }
    }
    
    // Cleanup and destroy
    destroy() {
        if (this.isDestroyed) return;
        
        console.log('Destroying dashboard...');
        
        this.isDestroyed = true;
        
        // Remove event listeners
        window.removeEventListener('resize', this.boundEventHandlers.resize);
        document.removeEventListener('keydown', this.boundEventHandlers.keydown);
        document.removeEventListener('visibilitychange', this.boundEventHandlers.visibilityChange);
        
        // Destroy components
        Object.values(this.components).forEach(component => {
            if (component && typeof component.destroy === 'function') {
                try {
                    component.destroy();
                } catch (error) {
                    console.error('Error destroying component:', error);
                }
            }
        });
        
        // Clear state
        this.components = {};
        this.state = {
            currentData: null,
            selectedNodes: new Set(),
            highlightedPath: null,
            activeFilters: {},
            viewMode: 'graph',
            lastUpdateTime: null
        };
        
        console.log('Dashboard destroyed');
    }
}

// Initialize dashboard when DOM is ready
document.addEventListener('DOMContentLoaded', async () => {
    console.log('DOM loaded, initializing dashboard...');
    
    try {
        // Create and initialize dashboard
        window.dashboard = new Dashboard();
        await window.dashboard.initialize();
        
        console.log('Dashboard ready for use');
        
    } catch (error) {
        console.error('Failed to initialize dashboard:', error);
        
        // Show error message to user
        const errorContainer = document.getElementById('errorContainer') || document.body;
        errorContainer.innerHTML = `
            <div class="error-message">
                <h3>Dashboard Initialization Failed</h3>
                <p>${error.message}</p>
                <button onclick="location.reload()">Retry</button>
            </div>
        `;
    }
});

// Global error handler
window.addEventListener('error', (event) => {
    console.error('Global error:', event.error);
    
    if (window.dashboard) {
        window.dashboard.showErrorMessage('An unexpected error occurred');
    }
});

// Export for module systems
if (typeof module !== 'undefined' && module.exports) {
    module.exports = Dashboard;
}