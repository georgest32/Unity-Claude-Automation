// Graph Controls - Interactive controls for the force-directed graph

class GraphControls {
    constructor(graphRenderer, dataManager) {
        this.graphRenderer = graphRenderer;
        this.dataManager = dataManager;
        
        // Control elements
        this.controls = {
            nodeRadius: document.getElementById('nodeRadius'),
            linkDistance: document.getElementById('linkDistance'),
            chargeStrength: document.getElementById('chargeStrength'),
            zoomIn: document.getElementById('zoomIn'),
            zoomOut: document.getElementById('zoomOut'),
            resetZoom: document.getElementById('resetZoom'),
            fitToScreen: document.getElementById('fitToScreen'),
            
            // Filters
            nodeTypeFilters: document.getElementById('nodeTypeFilters'),
            fileExtFilters: document.getElementById('fileExtFilters'),
            searchFilter: document.getElementById('searchFilter'),
            applyFilters: document.getElementById('applyFilters'),
            clearFilters: document.getElementById('clearFilters'),
            
            // Path highlighting
            sourceNode: document.getElementById('sourceNode'),
            targetNode: document.getElementById('targetNode'),
            highlightPath: document.getElementById('highlightPath'),
            clearPaths: document.getElementById('clearPaths'),
            showAllPaths: document.getElementById('showAllPaths'),
            animatePath: document.getElementById('animatePath'),
            maxDepth: document.getElementById('maxDepth')
        };
        
        // State management
        this.searchTimeout = null;
        this.lastSearchQuery = '';
        this.selectedSourceNode = null;
        this.selectedTargetNode = null;
        this.activePathIds = new Set();
        
        // Node autocomplete data
        this.nodeSearchIndex = [];
        
        this.initializeControls();
        this.setupEventListeners();
        
        console.log('GraphControls initialized');
    }
    
    initializeControls() {
        // Set initial values from configuration
        const config = DashboardConfig.graph.simulation.forces;
        
        if (this.controls.nodeRadius) {
            this.controls.nodeRadius.value = DashboardConfig.graph.nodes.defaultRadius;
        }
        if (this.controls.linkDistance) {
            this.controls.linkDistance.value = config.link.distance;
        }
        if (this.controls.chargeStrength) {
            this.controls.chargeStrength.value = config.charge.strength;
        }
        if (this.controls.maxDepth) {
            this.controls.maxDepth.value = 3;
        }
        
        // Initialize filter checkboxes
        this.initializeFilterCheckboxes();
        
        // Create autocomplete for node inputs
        this.setupNodeAutocomplete();
    }
    
    initializeFilterCheckboxes() {
        // Node type filters
        if (this.controls.nodeTypeFilters) {
            const nodeTypes = Object.keys(DashboardConfig.graph.nodes.types);
            const defaultTypes = DashboardConfig.filters.defaults.nodeTypes;
            
            this.controls.nodeTypeFilters.innerHTML = '';
            nodeTypes.forEach(type => {
                const label = document.createElement('label');
                const checkbox = document.createElement('input');
                checkbox.type = 'checkbox';
                checkbox.value = type;
                checkbox.checked = defaultTypes.includes(type);
                
                label.appendChild(checkbox);
                label.appendChild(document.createTextNode(
                    ConfigUtils.getNodeConfig(type).label || type
                ));
                
                this.controls.nodeTypeFilters.appendChild(label);
            });
        }
        
        // File extension filters
        if (this.controls.fileExtFilters) {
            const extensions = DashboardConfig.filters.defaults.fileExtensions;
            
            this.controls.fileExtFilters.innerHTML = '';
            extensions.forEach(ext => {
                const label = document.createElement('label');
                const checkbox = document.createElement('input');
                checkbox.type = 'checkbox';
                checkbox.value = ext;
                checkbox.checked = true;
                
                label.appendChild(checkbox);
                label.appendChild(document.createTextNode(
                    ext.toUpperCase() + ` (.${ext})`
                ));
                
                this.controls.fileExtFilters.appendChild(label);
            });
        }
    }
    
    setupNodeAutocomplete() {
        if (this.controls.sourceNode) {
            this.setupAutocomplete(this.controls.sourceNode, 'source');
        }
        if (this.controls.targetNode) {
            this.setupAutocomplete(this.controls.targetNode, 'target');
        }
    }
    
    setupAutocomplete(input, type) {
        // Create autocomplete container
        const container = document.createElement('div');
        container.className = 'autocomplete-container';
        container.style.position = 'relative';
        
        const suggestions = document.createElement('div');
        suggestions.className = 'autocomplete-suggestions';
        suggestions.style.cssText = `
            position: absolute;
            top: 100%;
            left: 0;
            right: 0;
            background: white;
            border: 1px solid #e2e8f0;
            border-top: none;
            border-radius: 0 0 6px 6px;
            max-height: 200px;
            overflow-y: auto;
            z-index: 1000;
            display: none;
        `;
        
        input.parentElement.insertBefore(container, input);
        container.appendChild(input);
        container.appendChild(suggestions);
        
        let selectedSuggestionIndex = -1;
        
        input.addEventListener('input', (e) => {
            const query = e.target.value.toLowerCase().trim();
            
            if (query.length < 2) {
                suggestions.style.display = 'none';
                return;
            }
            
            const matches = this.nodeSearchIndex
                .filter(node => 
                    node.name.toLowerCase().includes(query) ||
                    (node.file && node.file.toLowerCase().includes(query))
                )
                .slice(0, 10);
            
            if (matches.length === 0) {
                suggestions.style.display = 'none';
                return;
            }
            
            suggestions.innerHTML = '';
            matches.forEach((node, index) => {
                const item = document.createElement('div');
                item.className = 'autocomplete-item';
                item.style.cssText = `
                    padding: 8px 12px;
                    cursor: pointer;
                    border-bottom: 1px solid #f1f5f9;
                `;
                
                item.innerHTML = `
                    <div style="font-weight: 500;">${this.highlightMatch(node.name, query)}</div>
                    <div style="font-size: 0.75rem; color: #64748b;">${node.type} • ${node.file || 'Unknown file'}</div>
                `;
                
                item.addEventListener('click', () => {
                    input.value = node.name;
                    suggestions.style.display = 'none';
                    
                    if (type === 'source') {
                        this.selectedSourceNode = node;
                    } else {
                        this.selectedTargetNode = node;
                    }
                });
                
                item.addEventListener('mouseenter', () => {
                    selectedSuggestionIndex = index;
                    this.highlightSuggestion(suggestions, selectedSuggestionIndex);
                });
                
                suggestions.appendChild(item);
            });
            
            suggestions.style.display = 'block';
            selectedSuggestionIndex = -1;
        });
        
        input.addEventListener('keydown', (e) => {
            const items = suggestions.querySelectorAll('.autocomplete-item');
            
            switch (e.key) {
                case 'ArrowDown':
                    e.preventDefault();
                    selectedSuggestionIndex = Math.min(selectedSuggestionIndex + 1, items.length - 1);
                    this.highlightSuggestion(suggestions, selectedSuggestionIndex);
                    break;
                    
                case 'ArrowUp':
                    e.preventDefault();
                    selectedSuggestionIndex = Math.max(selectedSuggestionIndex - 1, -1);
                    this.highlightSuggestion(suggestions, selectedSuggestionIndex);
                    break;
                    
                case 'Enter':
                    e.preventDefault();
                    if (selectedSuggestionIndex >= 0 && items[selectedSuggestionIndex]) {
                        items[selectedSuggestionIndex].click();
                    }
                    break;
                    
                case 'Escape':
                    suggestions.style.display = 'none';
                    selectedSuggestionIndex = -1;
                    break;
            }
        });
        
        // Hide suggestions when clicking outside
        document.addEventListener('click', (e) => {
            if (!container.contains(e.target)) {
                suggestions.style.display = 'none';
                selectedSuggestionIndex = -1;
            }
        });
    }
    
    highlightMatch(text, query) {
        const index = text.toLowerCase().indexOf(query);
        if (index === -1) return text;
        
        return text.substring(0, index) +
               `<mark style="background-color: #fef3c7;">${text.substring(index, index + query.length)}</mark>` +
               text.substring(index + query.length);
    }
    
    highlightSuggestion(container, index) {
        const items = container.querySelectorAll('.autocomplete-item');
        items.forEach((item, i) => {
            if (i === index) {
                item.style.backgroundColor = '#f1f5f9';
            } else {
                item.style.backgroundColor = 'white';
            }
        });
    }
    
    setupEventListeners() {
        // Graph parameter controls
        if (this.controls.nodeRadius) {
            this.controls.nodeRadius.addEventListener('input', (e) => {
                this.updateGraphSettings({ nodeRadius: parseFloat(e.target.value) });
            });
        }
        
        if (this.controls.linkDistance) {
            this.controls.linkDistance.addEventListener('input', (e) => {
                this.updateGraphSettings({ linkDistance: parseFloat(e.target.value) });
            });
        }
        
        if (this.controls.chargeStrength) {
            this.controls.chargeStrength.addEventListener('input', (e) => {
                this.updateGraphSettings({ chargeStrength: parseFloat(e.target.value) });
            });
        }
        
        // Zoom controls
        if (this.controls.zoomIn) {
            this.controls.zoomIn.addEventListener('click', () => {
                this.graphRenderer.zoomIn();
            });
        }
        
        if (this.controls.zoomOut) {
            this.controls.zoomOut.addEventListener('click', () => {
                this.graphRenderer.zoomOut();
            });
        }
        
        if (this.controls.resetZoom) {
            this.controls.resetZoom.addEventListener('click', () => {
                this.graphRenderer.resetZoom();
            });
        }
        
        if (this.controls.fitToScreen) {
            this.controls.fitToScreen.addEventListener('click', () => {
                this.graphRenderer.fitToScreen();
            });
        }
        
        // Filter controls
        if (this.controls.searchFilter) {
            this.controls.searchFilter.addEventListener('input', (e) => {
                this.handleSearchInput(e.target.value);
            });
        }
        
        if (this.controls.applyFilters) {
            this.controls.applyFilters.addEventListener('click', () => {
                this.applyFilters();
            });
        }
        
        if (this.controls.clearFilters) {
            this.controls.clearFilters.addEventListener('click', () => {
                this.clearFilters();
            });
        }
        
        // Path highlighting controls
        if (this.controls.highlightPath) {
            this.controls.highlightPath.addEventListener('click', () => {
                this.highlightPath();
            });
        }
        
        if (this.controls.clearPaths) {
            this.controls.clearPaths.addEventListener('click', () => {
                this.clearPaths();
            });
        }
        
        // Graph event listeners
        this.graphRenderer.on('nodeClick', (node, selectedNodes) => {
            this.handleNodeClick(node, selectedNodes);
        });
        
        this.graphRenderer.on('nodeDoubleClick', (node) => {
            this.handleNodeDoubleClick(node);
        });
        
        this.graphRenderer.on('nodeHover', (node) => {
            this.handleNodeHover(node);
        });
        
        this.graphRenderer.on('selectionChange', (selectedNodes) => {
            this.handleSelectionChange(selectedNodes);
        });
        
        // Data manager event listeners
        this.dataManager.on('dataProcessed', (data) => {
            this.updateNodeSearchIndex(data.nodes);
        });
        
        // Keyboard shortcuts
        if (ConfigUtils.isFeatureEnabled('keyboardShortcuts')) {
            document.addEventListener('keydown', (e) => {
                this.handleKeyboardShortcut(e);
            });
        }
    }
    
    // Event handlers
    handleSearchInput(value) {
        if (this.searchTimeout) {
            clearTimeout(this.searchTimeout);
        }
        
        this.searchTimeout = setTimeout(() => {
            if (value !== this.lastSearchQuery) {
                this.lastSearchQuery = value;
                this.performSearch(value);
            }
        }, DashboardConfig.filters.debounceDelay);
    }
    
    handleNodeClick(node, selectedNodes) {
        this.updateNodeInfo(node);
        
        // Auto-populate path inputs if enabled
        if (selectedNodes.length === 1) {
            const selectedNode = this.dataManager.processedData.nodeMap.get(selectedNodes[0]);
            if (selectedNode && this.controls.sourceNode && !this.controls.sourceNode.value) {
                this.controls.sourceNode.value = selectedNode.name;
                this.selectedSourceNode = selectedNode;
            }
        } else if (selectedNodes.length === 2) {
            const nodes = selectedNodes.map(id => this.dataManager.processedData.nodeMap.get(id));
            if (nodes[0] && nodes[1]) {
                if (this.controls.sourceNode) {
                    this.controls.sourceNode.value = nodes[0].name;
                    this.selectedSourceNode = nodes[0];
                }
                if (this.controls.targetNode) {
                    this.controls.targetNode.value = nodes[1].name;
                    this.selectedTargetNode = nodes[1];
                }
            }
        }
    }
    
    handleNodeDoubleClick(node) {
        // Auto-highlight paths from double-clicked node
        if (this.selectedSourceNode && this.selectedSourceNode.id !== node.id) {
            this.selectedTargetNode = node;
            if (this.controls.targetNode) {
                this.controls.targetNode.value = node.name;
            }
            this.highlightPath();
        } else {
            this.selectedSourceNode = node;
            if (this.controls.sourceNode) {
                this.controls.sourceNode.value = node.name;
            }
        }
    }
    
    handleNodeHover(node) {
        if (node) {
            this.showNodeTooltip(node);
        } else {
            this.hideNodeTooltip();
        }
    }
    
    handleSelectionChange(selectedNodes) {
        // Update UI to reflect selection changes
        if (selectedNodes.length > 0) {
            console.log(`Selected ${selectedNodes.length} nodes`);
        }
    }
    
    handleKeyboardShortcut(event) {
        if (event.target.tagName === 'INPUT') return; // Don't interfere with input fields
        
        const shortcuts = DashboardConfig.accessibility.shortcuts;
        
        switch (event.code) {
            case shortcuts.search:
                event.preventDefault();
                if (this.controls.searchFilter) {
                    this.controls.searchFilter.focus();
                }
                break;
        }
    }
    
    // Control methods
    updateGraphSettings(settings) {
        this.graphRenderer.updateSettings(settings);
        
        // Provide visual feedback
        this.showSettingsUpdateFeedback();
    }
    
    showSettingsUpdateFeedback() {
        // Flash the graph briefly to indicate settings changed
        const canvas = this.graphRenderer.canvas.node();
        if (canvas) {
            canvas.style.filter = 'brightness(1.1)';
            setTimeout(() => {
                canvas.style.filter = '';
            }, 150);
        }
    }
    
    performSearch(query) {
        if (!query || query.length < DashboardConfig.filters.minSearchLength) {
            this.clearSearchHighlight();
            return;
        }
        
        const results = this.dataManager.searchNodes(query, 50);
        this.highlightSearchResults(results);
        
        console.log(`Search for "${query}": ${results.length} results`);
    }
    
    highlightSearchResults(nodes) {
        // Clear previous highlights
        this.clearSearchHighlight();
        
        // Dim all nodes
        if (this.dataManager.processedData.nodes) {
            this.dataManager.processedData.nodes.forEach(node => {
                node.dimmed = true;
            });
        }
        
        // Highlight matching nodes
        nodes.forEach(node => {
            node.dimmed = false;
            node.highlighted = true;
        });
        
        this.graphRenderer.render();
        
        // Auto-fit to search results if there are few results
        if (nodes.length <= 10 && nodes.length > 0) {
            setTimeout(() => {
                this.fitToNodes(nodes);
            }, 300);
        }
    }
    
    clearSearchHighlight() {
        if (this.dataManager.processedData.nodes) {
            this.dataManager.processedData.nodes.forEach(node => {
                node.dimmed = false;
                node.highlighted = false;
            });
        }
        this.graphRenderer.render();
    }
    
    applyFilters() {
        const filters = this.collectFilterValues();
        this.dataManager.updateFilters(filters);
        
        console.log('Filters applied:', filters);
        this.showFilterFeedback('Filters applied');
    }
    
    clearFilters() {
        // Reset all filter controls
        if (this.controls.searchFilter) {
            this.controls.searchFilter.value = '';
        }
        
        // Reset checkboxes to defaults
        const nodeTypeCheckboxes = this.controls.nodeTypeFilters?.querySelectorAll('input[type="checkbox"]');
        if (nodeTypeCheckboxes) {
            nodeTypeCheckboxes.forEach(cb => {
                cb.checked = DashboardConfig.filters.defaults.nodeTypes.includes(cb.value);
            });
        }
        
        const fileExtCheckboxes = this.controls.fileExtFilters?.querySelectorAll('input[type="checkbox"]');
        if (fileExtCheckboxes) {
            fileExtCheckboxes.forEach(cb => {
                cb.checked = DashboardConfig.filters.defaults.fileExtensions.includes(cb.value);
            });
        }
        
        this.dataManager.clearFilters();
        this.clearSearchHighlight();
        
        console.log('Filters cleared');
        this.showFilterFeedback('Filters cleared');
    }
    
    collectFilterValues() {
        const filters = {};
        
        // Node types
        const nodeTypeCheckboxes = this.controls.nodeTypeFilters?.querySelectorAll('input[type="checkbox"]:checked');
        if (nodeTypeCheckboxes) {
            filters.nodeTypes = Array.from(nodeTypeCheckboxes).map(cb => cb.value);
        }
        
        // File extensions
        const fileExtCheckboxes = this.controls.fileExtFilters?.querySelectorAll('input[type="checkbox"]:checked');
        if (fileExtCheckboxes) {
            filters.fileExtensions = Array.from(fileExtCheckboxes).map(cb => cb.value);
        }
        
        // Search query
        if (this.controls.searchFilter) {
            filters.searchQuery = this.controls.searchFilter.value.trim();
        }
        
        return filters;
    }
    
    showFilterFeedback(message) {
        // Create temporary feedback message
        const feedback = document.createElement('div');
        feedback.textContent = message;
        feedback.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            background: #10b981;
            color: white;
            padding: 8px 16px;
            border-radius: 6px;
            font-size: 0.875rem;
            z-index: 1000;
            animation: fadeInOut 2s ease-in-out;
        `;
        
        document.body.appendChild(feedback);
        
        setTimeout(() => {
            document.body.removeChild(feedback);
        }, 2000);
    }
    
    // Path highlighting methods
    highlightPath() {
        if (!this.selectedSourceNode || !this.selectedTargetNode) {
            alert('Please select both source and target nodes');
            return;
        }
        
        const showAllPaths = this.controls.showAllPaths?.checked || false;
        const animatePaths = this.controls.animatePath?.checked !== false;
        const maxDepth = parseInt(this.controls.maxDepth?.value || 3);
        
        if (showAllPaths) {
            this.highlightAllPaths(maxDepth, animatePaths);
        } else {
            this.highlightSinglePath(maxDepth, animatePaths);
        }
    }
    
    highlightSinglePath(maxDepth, animated) {
        const path = this.dataManager.findPath(
            this.selectedSourceNode.id,
            this.selectedTargetNode.id,
            maxDepth
        );
        
        if (path) {
            const pathId = this.graphRenderer.highlightPath(path, {
                animated,
                duration: DashboardConfig.paths.animation.duration
            });
            
            this.activePathIds.add(pathId);
            
            console.log(`Path found: ${path.length} nodes`);
            this.showPathFeedback(`Path found: ${path.length} nodes`);
        } else {
            console.log('No path found');
            this.showPathFeedback('No path found', 'error');
        }
    }
    
    highlightAllPaths(maxDepth, animated) {
        const paths = this.dataManager.findAllPaths(
            this.selectedSourceNode.id,
            this.selectedTargetNode.id,
            maxDepth,
            DashboardConfig.paths.maxPaths
        );
        
        if (paths.length > 0) {
            paths.forEach((path, index) => {
                const pathId = this.graphRenderer.highlightPath(path, {
                    id: `multi-path-${index}`,
                    animated,
                    duration: DashboardConfig.paths.animation.duration + index * 100
                });
                
                this.activePathIds.add(pathId);
            });
            
            console.log(`Found ${paths.length} paths`);
            this.showPathFeedback(`Found ${paths.length} paths`);
        } else {
            console.log('No paths found');
            this.showPathFeedback('No paths found', 'error');
        }
    }
    
    clearPaths() {
        this.graphRenderer.clearPaths();
        this.activePathIds.clear();
        
        console.log('Paths cleared');
        this.showPathFeedback('Paths cleared');
    }
    
    showPathFeedback(message, type = 'success') {
        const color = type === 'error' ? '#ef4444' : '#10b981';
        
        const feedback = document.createElement('div');
        feedback.textContent = message;
        feedback.style.cssText = `
            position: fixed;
            top: 60px;
            right: 20px;
            background: ${color};
            color: white;
            padding: 8px 16px;
            border-radius: 6px;
            font-size: 0.875rem;
            z-index: 1000;
            animation: fadeInOut 3s ease-in-out;
        `;
        
        document.body.appendChild(feedback);
        
        setTimeout(() => {
            if (document.body.contains(feedback)) {
                document.body.removeChild(feedback);
            }
        }, 3000);
    }
    
    // UI update methods
    updateNodeInfo(node) {
        const nodeInfo = document.getElementById('nodeInfo');
        if (!nodeInfo) return;
        
        if (node) {
            document.getElementById('nodeTitle').textContent = `${node.name} Details`;
            document.getElementById('nodeType').textContent = node.type;
            document.getElementById('nodeName').textContent = node.name;
            document.getElementById('nodeFile').textContent = node.file || 'Unknown';
            document.getElementById('nodeLine').textContent = node.line || 'Unknown';
            
            const dependencies = this.dataManager.getConnectedNodeIds(node.id);
            document.getElementById('nodeDependencies').textContent = dependencies.length;
            
            nodeInfo.classList.remove('hidden');
        } else {
            nodeInfo.classList.add('hidden');
        }
    }
    
    showNodeTooltip(node) {
        // Implementation would create/show a tooltip
        // For now, just update the cursor
        document.body.style.cursor = 'pointer';
    }
    
    hideNodeTooltip() {
        document.body.style.cursor = '';
    }
    
    updateNodeSearchIndex(nodes) {
        this.nodeSearchIndex = nodes.map(node => ({
            id: node.id,
            name: node.name,
            type: node.type,
            file: node.file
        }));
        
        console.log(`Node search index updated: ${this.nodeSearchIndex.length} entries`);
    }
    
    fitToNodes(nodes) {
        if (!nodes || nodes.length === 0) return;
        
        // Calculate bounds
        const padding = 100;
        const xExtent = d3.extent(nodes, d => d.x);
        const yExtent = d3.extent(nodes, d => d.y);
        
        if (!xExtent[0] || !yExtent[0]) return;
        
        const width = xExtent[1] - xExtent[0];
        const height = yExtent[1] - yExtent[0];
        const centerX = (xExtent[0] + xExtent[1]) / 2;
        const centerY = (yExtent[0] + yExtent[1]) / 2;
        
        const scale = Math.min(
            (this.graphRenderer.width - padding * 2) / Math.max(width, 100),
            (this.graphRenderer.height - padding * 2) / Math.max(height, 100),
            DashboardConfig.graph.zoom.max
        );
        
        const transform = d3.zoomIdentity
            .translate(this.graphRenderer.width / 2, this.graphRenderer.height / 2)
            .scale(scale)
            .translate(-centerX, -centerY);
        
        this.graphRenderer.canvas.transition()
            .duration(750)
            .call(this.graphRenderer.zoom.transform, transform);
    }
    
    // Public API methods
    selectNode(nodeId) {
        const node = this.dataManager.processedData.nodeMap.get(nodeId);
        if (node) {
            this.graphRenderer.selectedNodes.clear();
            this.graphRenderer.selectedNodes.add(nodeId);
            this.graphRenderer.render();
            this.updateNodeInfo(node);
            this.graphRenderer.focusOnNode(node);
        }
    }
    
    searchAndHighlight(query) {
        if (this.controls.searchFilter) {
            this.controls.searchFilter.value = query;
        }
        this.performSearch(query);
    }
    
    destroy() {
        // Clean up event listeners and timeouts
        if (this.searchTimeout) {
            clearTimeout(this.searchTimeout);
        }
        
        // Remove event listeners from controls
        Object.values(this.controls).forEach(control => {
            if (control && control.removeEventListener) {
                control.removeEventListener();
            }
        });
        
        this.activePathIds.clear();
        this.nodeSearchIndex = [];
        
        console.log('GraphControls destroyed');
    }
}

// CSS for autocomplete animations (add to dashboard.css or inject)
const autocompleteCSS = `
@keyframes fadeInOut {
    0% { opacity: 0; transform: translateY(-10px); }
    10% { opacity: 1; transform: translateY(0); }
    90% { opacity: 1; transform: translateY(0); }
    100% { opacity: 0; transform: translateY(-10px); }
}

.autocomplete-item:hover {
    background-color: #f1f5f9 !important;
}
`;

// Inject CSS if not already present
if (!document.getElementById('autocomplete-styles')) {
    const style = document.createElement('style');
    style.id = 'autocomplete-styles';
    style.textContent = autocompleteCSS;
    document.head.appendChild(style);
}

// Export for module systems
if (typeof module !== 'undefined' && module.exports) {
    module.exports = GraphControls;
}

// Global availability
window.GraphControls = GraphControls;