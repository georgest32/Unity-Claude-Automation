/**
 * Unity-Claude Automation - Interactive Exploration and Drill-Down System
 * Day 7 Hour 5-6: Enable deep interactive exploration of module relationships
 * Advanced filtering, search, path analysis, and clustering capabilities
 */

// Global exploration state
let explorationState = {
    currentLevel: 'module', // module, function, statement
    breadcrumbs: [],
    filters: new Map(),
    searchQuery: '',
    savedBookmarks: [],
    focusedNodes: new Set(),
    pathAnalysis: null
};

// Search and filter configuration
const SEARCH_CONFIG = {
    debounceMs: 300,
    minQueryLength: 2,
    maxResults: 50,
    fuzzyThreshold: 0.6
};

// Clustering configuration
const CLUSTER_CONFIG = {
    maxClusterSize: 15,
    minClusterNodes: 3,
    clusterDistanceThreshold: 100,
    domainClusters: ['Core', 'Analysis', 'UI', 'Testing', 'Integration', 'Utility']
};

// Filter types and their configurations
const FILTER_TYPES = {
    nodeType: { label: 'Node Type', values: ['module', 'function', 'class', 'component'] },
    strength: { label: 'Relationship Strength', values: ['weak', 'medium', 'strong', 'critical'] },
    frequency: { label: 'Usage Frequency', values: ['low', 'medium', 'high'] },
    domain: { label: 'Domain', values: CLUSTER_CONFIG.domainClusters }
};

/**
 * Initialize interactive exploration system
 */
function initializeInteractiveExploration() {
    console.log('🔍 Initializing Interactive Exploration System...');
    
    // Create exploration UI panels
    createExplorationPanels();
    
    // Initialize search functionality
    initializeAdvancedSearch();
    
    // Initialize filtering system
    initializeAdvancedFiltering();
    
    // Initialize path analysis tools
    initializePathAnalysis();
    
    // Initialize clustering and grouping
    initializeClustering();
    
    // Set up drill-down navigation
    setupDrillDownNavigation();
    
    // Initialize context panels
    initializeContextPanels();
    
    console.log('✅ Interactive exploration system initialized');
}

/**
 * Create exploration UI panels
 */
function createExplorationPanels() {
    const container = d3.select('.visualization-container');
    
    // Create exploration sidebar
    const sidebar = container.append('div')
        .attr('class', 'exploration-sidebar')
        .style('position', 'absolute')
        .style('top', '0')
        .style('right', '0')
        .style('width', '300px')
        .style('height', '100%')
        .style('background', 'rgba(255, 255, 255, 0.95)')
        .style('border-left', '1px solid #ddd')
        .style('padding', '20px')
        .style('overflow-y', 'auto')
        .style('z-index', 100);
    
    // Add toggle button for sidebar
    const toggleBtn = container.append('button')
        .attr('class', 'sidebar-toggle')
        .style('position', 'absolute')
        .style('top', '20px')
        .style('right', '10px')
        .style('z-index', 101)
        .style('background', '#2196F3')
        .style('color', 'white')
        .style('border', 'none')
        .style('padding', '8px 12px')
        .style('border-radius', '4px')
        .style('cursor', 'pointer')
        .text('🔍 Explore')
        .on('click', toggleExplorationSidebar);
    
    // Create breadcrumb navigation
    sidebar.append('div')
        .attr('class', 'breadcrumb-container')
        .style('margin-bottom', '20px');
    
    // Create search container
    sidebar.append('div')
        .attr('class', 'search-container')
        .style('margin-bottom', '20px');
    
    // Create filter container
    sidebar.append('div')
        .attr('class', 'filter-container')
        .style('margin-bottom', '20px');
    
    // Create path analysis container
    sidebar.append('div')
        .attr('class', 'path-analysis-container')
        .style('margin-bottom', '20px');
    
    // Create context information panel
    sidebar.append('div')
        .attr('class', 'context-panel')
        .style('margin-bottom', '20px');
    
    console.log('🎛️ Exploration panels created');
}

/**
 * Initialize advanced search functionality
 */
function initializeAdvancedSearch() {
    console.log('🔍 Initializing advanced search...');
    
    const searchContainer = d3.select('.search-container');
    
    // Add search header
    searchContainer.append('h3')
        .style('margin', '0 0 10px 0')
        .style('font-size', '16px')
        .text('🔍 Search & Filter');
    
    // Add search input
    const searchInput = searchContainer.append('input')
        .attr('type', 'text')
        .attr('class', 'search-input')
        .attr('placeholder', 'Search nodes, functions, modules...')
        .style('width', '100%')
        .style('padding', '8px')
        .style('border', '1px solid #ddd')
        .style('border-radius', '4px')
        .style('margin-bottom', '10px')
        .on('input', debounce(handleSearchInput, SEARCH_CONFIG.debounceMs));
    
    // Add search results container
    searchContainer.append('div')
        .attr('class', 'search-results')
        .style('max-height', '200px')
        .style('overflow-y', 'auto')
        .style('border', '1px solid #eee')
        .style('border-radius', '4px')
        .style('display', 'none');
    
    // Add advanced search options
    const advancedOptions = searchContainer.append('div')
        .attr('class', 'advanced-search-options')
        .style('margin-top', '10px');
    
    advancedOptions.append('label')
        .style('display', 'block')
        .style('margin-bottom', '5px')
        .html('<input type="checkbox" class="fuzzy-search-cb"> Fuzzy Search');
    
    advancedOptions.append('label')
        .style('display', 'block')
        .style('margin-bottom', '5px')
        .html('<input type="checkbox" class="regex-search-cb"> Regex Search');
    
    advancedOptions.append('label')
        .style('display', 'block')
        .html('<input type="checkbox" class="case-sensitive-cb"> Case Sensitive');
    
    console.log('🔍 Advanced search initialized');
}

/**
 * Initialize advanced filtering system
 */
function initializeAdvancedFiltering() {
    console.log('🎛️ Initializing advanced filtering...');
    
    const filterContainer = d3.select('.filter-container');
    
    // Add filter header
    filterContainer.append('h3')
        .style('margin', '0 0 10px 0')
        .style('font-size', '16px')
        .text('🎛️ Filters');
    
    // Create filter controls for each type
    Object.entries(FILTER_TYPES).forEach(([filterType, config]) => {
        const filterGroup = filterContainer.append('div')
            .attr('class', `filter-group filter-${filterType}`)
            .style('margin-bottom', '15px');
        
        filterGroup.append('label')
            .style('display', 'block')
            .style('font-weight', 'bold')
            .style('margin-bottom', '5px')
            .text(config.label);
        
        const checkboxContainer = filterGroup.append('div')
            .style('display', 'flex')
            .style('flex-direction', 'column')
            .style('gap', '3px');
        
        config.values.forEach(value => {
            const checkboxLabel = checkboxContainer.append('label')
                .style('display', 'flex')
                .style('align-items', 'center')
                .style('cursor', 'pointer');
            
            checkboxLabel.append('input')
                .attr('type', 'checkbox')
                .attr('class', `filter-cb filter-${filterType}-${value}`)
                .style('margin-right', '8px')
                .property('checked', true)
                .on('change', () => updateFilter(filterType, value));
            
            checkboxLabel.append('span')
                .style('font-size', '12px')
                .text(value);
        });
    });
    
    // Add clear filters button
    filterContainer.append('button')
        .attr('class', 'clear-filters-btn')
        .style('width', '100%')
        .style('padding', '8px')
        .style('background', '#f44336')
        .style('color', 'white')
        .style('border', 'none')
        .style('border-radius', '4px')
        .style('cursor', 'pointer')
        .style('margin-top', '10px')
        .text('Clear All Filters')
        .on('click', clearAllFilters);
    
    console.log('🎛️ Advanced filtering initialized');
}

/**
 * Initialize path analysis tools
 */
function initializePathAnalysis() {
    console.log('🛤️ Initializing path analysis...');
    
    const pathContainer = d3.select('.path-analysis-container');
    
    // Add path analysis header
    pathContainer.append('h3')
        .style('margin', '0 0 10px 0')
        .style('font-size', '16px')
        .text('🛤️ Path Analysis');
    
    // Add shortest path controls
    const shortestPathGroup = pathContainer.append('div')
        .attr('class', 'shortest-path-group')
        .style('margin-bottom', '15px');
    
    shortestPathGroup.append('label')
        .style('display', 'block')
        .style('margin-bottom', '5px')
        .text('Shortest Path Between Nodes:');
    
    const pathInputGroup = shortestPathGroup.append('div')
        .style('display', 'flex')
        .style('gap', '5px');
    
    pathInputGroup.append('input')
        .attr('type', 'text')
        .attr('class', 'path-source-input')
        .attr('placeholder', 'Source node')
        .style('flex', '1')
        .style('padding', '4px')
        .style('border', '1px solid #ddd')
        .style('border-radius', '3px');
    
    pathInputGroup.append('input')
        .attr('type', 'text')
        .attr('class', 'path-target-input')
        .attr('placeholder', 'Target node')
        .style('flex', '1')
        .style('padding', '4px')
        .style('border', '1px solid #ddd')
        .style('border-radius', '3px');
    
    pathInputGroup.append('button')
        .attr('class', 'find-path-btn')
        .style('padding', '4px 8px')
        .style('background', '#4CAF50')
        .style('color', 'white')
        .style('border', 'none')
        .style('border-radius', '3px')
        .style('cursor', 'pointer')
        .text('Find')
        .on('click', findShortestPath);
    
    // Add dependency chain analysis
    const depChainGroup = pathContainer.append('div')
        .attr('class', 'dependency-chain-group')
        .style('margin-bottom', '15px');
    
    depChainGroup.append('button')
        .attr('class', 'analyze-dependencies-btn')
        .style('width', '100%')
        .style('padding', '8px')
        .style('background', '#FF9800')
        .style('color', 'white')
        .style('border', 'none')
        .style('border-radius', '4px')
        .style('cursor', 'pointer')
        .text('Analyze Dependency Chains')
        .on('click', analyzeDependencyChains);
    
    // Add circular dependency detection
    depChainGroup.append('button')
        .attr('class', 'detect-circular-btn')
        .style('width', '100%')
        .style('padding', '8px')
        .style('background', '#F44336')
        .style('color', 'white')
        .style('border', 'none')
        .style('border-radius', '4px')
        .style('cursor', 'pointer')
        .style('margin-top', '5px')
        .text('Detect Circular Dependencies')
        .on('click', detectCircularDependencies);
    
    // Add path results container
    pathContainer.append('div')
        .attr('class', 'path-results')
        .style('margin-top', '10px')
        .style('font-size', '12px')
        .style('background', '#f9f9f9')
        .style('padding', '8px')
        .style('border-radius', '4px')
        .style('display', 'none');
    
    console.log('🛤️ Path analysis tools initialized');
}

/**
 * Initialize clustering and grouping functionality
 */
function initializeClustering() {
    console.log('🔗 Initializing clustering and grouping...');
    
    // Add clustering controls to context panel
    const contextPanel = d3.select('.context-panel');
    
    contextPanel.append('h3')
        .style('margin', '0 0 10px 0')
        .style('font-size', '16px')
        .text('🔗 Clustering');
    
    // Auto-clustering button
    contextPanel.append('button')
        .attr('class', 'auto-cluster-btn')
        .style('width', '100%')
        .style('padding', '8px')
        .style('background', '#9C27B0')
        .style('color', 'white')
        .style('border', 'none')
        .style('border-radius', '4px')
        .style('cursor', 'pointer')
        .style('margin-bottom', '10px')
        .text('Auto-Cluster by Domain')
        .on('click', performAutomaticClustering);
    
    // Manual grouping controls
    const manualGroup = contextPanel.append('div')
        .attr('class', 'manual-grouping')
        .style('margin-bottom', '15px');
    
    manualGroup.append('label')
        .style('display', 'block')
        .style('margin-bottom', '5px')
        .text('Manual Grouping:');
    
    const groupControls = manualGroup.append('div')
        .style('display', 'flex')
        .style('gap', '5px');
    
    groupControls.append('input')
        .attr('type', 'text')
        .attr('class', 'group-name-input')
        .attr('placeholder', 'Group name')
        .style('flex', '1')
        .style('padding', '4px')
        .style('border', '1px solid #ddd')
        .style('border-radius', '3px');
    
    groupControls.append('button')
        .attr('class', 'create-group-btn')
        .style('padding', '4px 8px')
        .style('background', '#4CAF50')
        .style('color', 'white')
        .style('border', 'none')
        .style('border-radius', '3px')
        .style('cursor', 'pointer')
        .text('Group')
        .on('click', createManualGroup);
    
    // Add architectural view toggle
    contextPanel.append('div')
        .attr('class', 'view-controls')
        .style('margin-top', '15px');
    
    const viewControls = contextPanel.select('.view-controls');
    
    viewControls.append('h4')
        .style('margin', '0 0 8px 0')
        .text('View Mode:');
    
    const viewButtons = viewControls.append('div')
        .style('display', 'flex')
        .style('flex-direction', 'column')
        .style('gap', '5px');
    
    ['Detailed', 'Architectural', 'Focus+Context'].forEach(viewMode => {
        viewButtons.append('button')
            .attr('class', `view-mode-btn view-${viewMode.toLowerCase()}`)
            .style('padding', '6px')
            .style('background', '#607D8B')
            .style('color', 'white')
            .style('border', 'none')
            .style('border-radius', '3px')
            .style('cursor', 'pointer')
            .text(viewMode)
            .on('click', () => switchViewMode(viewMode.toLowerCase()));
    });
    
    console.log('🔗 Clustering and grouping initialized');
}

/**
 * Set up drill-down navigation system
 */
function setupDrillDownNavigation() {
    console.log('📊 Setting up drill-down navigation...');
    
    const breadcrumbContainer = d3.select('.breadcrumb-container');
    
    // Add breadcrumb header
    breadcrumbContainer.append('h3')
        .style('margin', '0 0 10px 0')
        .style('font-size', '16px')
        .text('📊 Navigation');
    
    // Add level indicators
    const levelContainer = breadcrumbContainer.append('div')
        .attr('class', 'level-indicators')
        .style('display', 'flex')
        .style('gap', '5px')
        .style('margin-bottom', '10px');
    
    ['Module', 'Function', 'Statement'].forEach((level, index) => {
        levelContainer.append('button')
            .attr('class', `level-btn level-${level.toLowerCase()}`)
            .style('flex', '1')
            .style('padding', '6px')
            .style('background', index === 0 ? '#2196F3' : '#ddd')
            .style('color', index === 0 ? 'white' : '#666')
            .style('border', 'none')
            .style('border-radius', '3px')
            .style('cursor', 'pointer')
            .style('font-size', '11px')
            .text(level)
            .on('click', () => navigateToLevel(level.toLowerCase()));
    });
    
    // Add breadcrumb trail
    breadcrumbContainer.append('div')
        .attr('class', 'breadcrumb-trail')
        .style('font-size', '12px')
        .style('color', '#666');
    
    // Add zoom-to-fit controls
    const zoomControls = breadcrumbContainer.append('div')
        .attr('class', 'zoom-controls')
        .style('margin-top', '10px')
        .style('display', 'flex')
        .style('gap', '5px');
    
    zoomControls.append('button')
        .attr('class', 'zoom-fit-btn')
        .style('flex', '1')
        .style('padding', '6px')
        .style('background', '#607D8B')
        .style('color', 'white')
        .style('border', 'none')
        .style('border-radius', '3px')
        .style('cursor', 'pointer')
        .style('font-size', '11px')
        .text('Fit All')
        .on('click', zoomToFitAll);
    
    zoomControls.append('button')
        .attr('class', 'zoom-selection-btn')
        .style('flex', '1')
        .style('padding', '6px')
        .style('background', '#607D8B')
        .style('color', 'white')
        .style('border', 'none')
        .style('border-radius', '3px')
        .style('cursor', 'pointer')
        .style('font-size', '11px')
        .text('Fit Selection')
        .on('click', zoomToFitSelection);
    
    console.log('📊 Drill-down navigation setup complete');
}

/**
 * Initialize context information panels
 */
function initializeContextPanels() {
    console.log('📋 Initializing context panels...');
    
    const contextPanel = d3.select('.context-panel');
    
    // Add selection info section
    const selectionInfo = contextPanel.append('div')
        .attr('class', 'selection-info')
        .style('margin-bottom', '15px');
    
    selectionInfo.append('h4')
        .style('margin', '0 0 8px 0')
        .text('📋 Selection Info');
    
    selectionInfo.append('div')
        .attr('class', 'selection-details')
        .style('font-size', '12px')
        .style('background', '#f9f9f9')
        .style('padding', '8px')
        .style('border-radius', '4px')
        .text('No nodes selected');
    
    // Add relationship analysis section
    const relationshipAnalysis = contextPanel.append('div')
        .attr('class', 'relationship-analysis')
        .style('margin-bottom', '15px');
    
    relationshipAnalysis.append('h4')
        .style('margin', '0 0 8px 0')
        .text('🔗 Relationships');
    
    relationshipAnalysis.append('div')
        .attr('class', 'relationship-details')
        .style('font-size', '12px')
        .style('background', '#f9f9f9')
        .style('padding', '8px')
        .style('border-radius', '4px')
        .text('Select nodes to see relationships');
    
    console.log('📋 Context panels initialized');
}

/**
 * Handle search input with advanced features
 */
function handleSearchInput(event) {
    const query = event.target.value.trim();
    explorationState.searchQuery = query;
    
    if (query.length < SEARCH_CONFIG.minQueryLength) {
        hideSearchResults();
        clearSearchHighlights();
        return;
    }
    
    console.log(`🔍 Searching for: "${query}"`);
    
    const options = {
        fuzzy: document.querySelector('.fuzzy-search-cb').checked,
        regex: document.querySelector('.regex-search-cb').checked,
        caseSensitive: document.querySelector('.case-sensitive-cb').checked
    };
    
    const results = performAdvancedSearch(query, options);
    displaySearchResults(results);
    highlightSearchResults(results);
}

/**
 * Perform advanced search with multiple algorithms
 */
function performAdvancedSearch(query, options) {
    if (!window.GraphRenderer?.graphData?.nodes) {
        return [];
    }
    
    const nodes = window.GraphRenderer.graphData.nodes;
    let results = [];
    
    if (options.regex) {
        // Regex search
        try {
            const regex = new RegExp(query, options.caseSensitive ? 'g' : 'gi');
            results = nodes.filter(node => {
                return regex.test(node.id) || 
                       regex.test(node.label || '') || 
                       regex.test(node.module || '');
            });
        } catch (e) {
            console.warn('Invalid regex pattern:', query);
            results = [];
        }
    } else if (options.fuzzy) {
        // Fuzzy search using simple scoring
        results = nodes.map(node => {
            const searchableText = [
                node.id,
                node.label || '',
                node.module || '',
                node.type || ''
            ].join(' ').toLowerCase();
            
            const queryLower = query.toLowerCase();
            const score = calculateFuzzyScore(searchableText, queryLower);
            
            return { node, score };
        })
        .filter(item => item.score >= SEARCH_CONFIG.fuzzyThreshold)
        .sort((a, b) => b.score - a.score)
        .map(item => item.node);
    } else {
        // Simple text search
        const searchTerm = options.caseSensitive ? query : query.toLowerCase();
        results = nodes.filter(node => {
            const searchableText = [
                node.id,
                node.label || '',
                node.module || '',
                node.type || ''
            ].join(' ');
            
            const text = options.caseSensitive ? searchableText : searchableText.toLowerCase();
            return text.includes(searchTerm);
        });
    }
    
    return results.slice(0, SEARCH_CONFIG.maxResults);
}

/**
 * Calculate fuzzy search score
 */
function calculateFuzzyScore(text, query) {
    if (text.includes(query)) return 1.0;
    
    // Simple character-based scoring
    let score = 0;
    let queryIndex = 0;
    
    for (let i = 0; i < text.length && queryIndex < query.length; i++) {
        if (text[i] === query[queryIndex]) {
            score += 1;
            queryIndex++;
        }
    }
    
    return queryIndex / query.length;
}

/**
 * Display search results
 */
function displaySearchResults(results) {
    const resultsContainer = d3.select('.search-results');
    
    if (results.length === 0) {
        resultsContainer.style('display', 'none');
        return;
    }
    
    resultsContainer.style('display', 'block');
    
    // Clear previous results
    resultsContainer.selectAll('*').remove();
    
    // Add result items
    const resultItems = resultsContainer.selectAll('.search-result-item')
        .data(results)
        .enter()
        .append('div')
        .attr('class', 'search-result-item')
        .style('padding', '8px')
        .style('border-bottom', '1px solid #eee')
        .style('cursor', 'pointer')
        .on('click', (event, d) => {
            selectAndFocusNode(d);
            hideSearchResults();
        })
        .on('mouseover', (event, d) => {
            highlightNode(d);
        });
    
    resultItems.append('div')
        .style('font-weight', 'bold')
        .style('font-size', '12px')
        .text(d => d.label || d.id);
    
    resultItems.append('div')
        .style('font-size', '10px')
        .style('color', '#666')
        .text(d => `${d.type} • ${d.module || 'No module'}`);
    
    console.log(`📊 Displayed ${results.length} search results`);
}

/**
 * Find shortest path between two nodes
 */
function findShortestPath() {
    const sourceInput = document.querySelector('.path-source-input');
    const targetInput = document.querySelector('.path-target-input');
    
    const sourceId = sourceInput.value.trim();
    const targetId = targetInput.value.trim();
    
    if (!sourceId || !targetId) {
        alert('Please enter both source and target nodes');
        return;
    }
    
    console.log(`🛤️ Finding shortest path: ${sourceId} → ${targetId}`);
    
    const path = calculateShortestPath(sourceId, targetId);
    displayPathResults(path, 'shortest-path');
    highlightPath(path);
}

/**
 * Calculate shortest path using Dijkstra's algorithm
 */
function calculateShortestPath(sourceId, targetId) {
    const graphData = window.GraphRenderer?.graphData;
    if (!graphData) return null;
    
    // Build adjacency list
    const adjacencyList = new Map();
    graphData.nodes.forEach(node => {
        adjacencyList.set(node.id, []);
    });
    
    graphData.links.forEach(link => {
        const sourceNodeId = link.source.id || link.source;
        const targetNodeId = link.target.id || link.target;
        
        adjacencyList.get(sourceNodeId)?.push({
            node: targetNodeId,
            weight: 1 / (link.strength || 1) // Invert strength for shortest path
        });
    });
    
    // Dijkstra's algorithm implementation
    const distances = new Map();
    const previous = new Map();
    const unvisited = new Set(graphData.nodes.map(n => n.id));
    
    // Initialize distances
    graphData.nodes.forEach(node => {
        distances.set(node.id, node.id === sourceId ? 0 : Infinity);
    });
    
    while (unvisited.size > 0) {
        // Find unvisited node with minimum distance
        let current = null;
        let minDistance = Infinity;
        
        unvisited.forEach(nodeId => {
            if (distances.get(nodeId) < minDistance) {
                minDistance = distances.get(nodeId);
                current = nodeId;
            }
        });
        
        if (current === null || minDistance === Infinity) break;
        
        unvisited.delete(current);
        
        // Update distances to neighbors
        const neighbors = adjacencyList.get(current) || [];
        neighbors.forEach(neighbor => {
            if (unvisited.has(neighbor.node)) {
                const newDistance = distances.get(current) + neighbor.weight;
                if (newDistance < distances.get(neighbor.node)) {
                    distances.set(neighbor.node, newDistance);
                    previous.set(neighbor.node, current);
                }
            }
        });
        
        // Stop if we reached the target
        if (current === targetId) break;
    }
    
    // Reconstruct path
    const path = [];
    let current = targetId;
    
    while (current !== undefined) {
        path.unshift(current);
        current = previous.get(current);
    }
    
    return path.length > 1 && path[0] === sourceId ? path : null;
}

/**
 * Analyze dependency chains for all nodes
 */
function analyzeDependencyChains() {
    console.log('🔗 Analyzing dependency chains...');
    
    const graphData = window.GraphRenderer?.graphData;
    if (!graphData) return;
    
    const chains = [];
    const visited = new Set();
    
    // Find all dependency chains
    graphData.nodes.forEach(node => {
        if (!visited.has(node.id)) {
            const chain = traceDependencyChain(node.id, graphData, visited);
            if (chain.length > 2) {
                chains.push(chain);
            }
        }
    });
    
    // Display results
    displayPathResults(chains, 'dependency-chains');
    
    // Highlight longest chains
    if (chains.length > 0) {
        const longestChain = chains.reduce((longest, current) => 
            current.length > longest.length ? current : longest
        );
        highlightPath(longestChain);
    }
    
    console.log(`🔗 Found ${chains.length} dependency chains`);
}

/**
 * Detect circular dependencies in the graph
 */
function detectCircularDependencies() {
    console.log('🔄 Detecting circular dependencies...');
    
    const graphData = window.GraphRenderer?.graphData;
    if (!graphData) return;
    
    const circularDeps = findCircularDependencies(graphData);
    
    displayPathResults(circularDeps, 'circular-dependencies');
    
    // Highlight circular dependencies
    circularDeps.forEach(cycle => {
        highlightPath(cycle, 'circular');
    });
    
    console.log(`🔄 Found ${circularDeps.length} circular dependencies`);
}

/**
 * Find circular dependencies using DFS
 */
function findCircularDependencies(graphData) {
    const visited = new Set();
    const recursionStack = new Set();
    const cycles = [];
    
    // Build adjacency list
    const adjacencyList = new Map();
    graphData.nodes.forEach(node => {
        adjacencyList.set(node.id, []);
    });
    
    graphData.links.forEach(link => {
        const sourceId = link.source.id || link.source;
        const targetId = link.target.id || link.target;
        adjacencyList.get(sourceId)?.push(targetId);
    });
    
    // DFS to find cycles
    function dfs(nodeId, path) {
        visited.add(nodeId);
        recursionStack.add(nodeId);
        path.push(nodeId);
        
        const neighbors = adjacencyList.get(nodeId) || [];
        for (const neighbor of neighbors) {
            if (recursionStack.has(neighbor)) {
                // Found cycle
                const cycleStart = path.indexOf(neighbor);
                const cycle = path.slice(cycleStart).concat([neighbor]);
                cycles.push(cycle);
            } else if (!visited.has(neighbor)) {
                dfs(neighbor, [...path]);
            }
        }
        
        recursionStack.delete(nodeId);
    }
    
    graphData.nodes.forEach(node => {
        if (!visited.has(node.id)) {
            dfs(node.id, []);
        }
    });
    
    return cycles;
}

/**
 * Perform automatic clustering by domain
 */
function performAutomaticClustering() {
    console.log('🔗 Performing automatic clustering...');
    
    const graphData = window.GraphRenderer?.graphData;
    if (!graphData) return;
    
    // Group nodes by domain/module
    const clusters = new Map();
    
    graphData.nodes.forEach(node => {
        const domain = node.module || node.group || 'Uncategorized';
        if (!clusters.has(domain)) {
            clusters.set(domain, []);
        }
        clusters.get(domain).push(node);
    });
    
    // Apply clustering visualization
    applyClustering(clusters);
    
    console.log(`🔗 Created ${clusters.size} automatic clusters`);
}

/**
 * Apply clustering to visualization
 */
function applyClustering(clusters) {
    // Add cluster backgrounds
    const svg = d3.select('#graph-svg');
    svg.selectAll('.cluster-background').remove();
    
    const clusterGroup = svg.insert('g', '.links')
        .attr('class', 'cluster-backgrounds');
    
    clusters.forEach((nodes, clusterName) => {
        if (nodes.length >= CLUSTER_CONFIG.minClusterNodes) {
            // Calculate cluster bounds
            const bounds = calculateClusterBounds(nodes);
            
            // Add cluster background
            clusterGroup.append('ellipse')
                .attr('class', 'cluster-background')
                .attr('cx', bounds.centerX)
                .attr('cy', bounds.centerY)
                .attr('rx', bounds.width / 2 + 20)
                .attr('ry', bounds.height / 2 + 20)
                .style('fill', getClusterColor(clusterName))
                .style('opacity', 0.1)
                .style('stroke', getClusterColor(clusterName))
                .style('stroke-width', 2)
                .style('stroke-dasharray', '5,5');
            
            // Add cluster label
            clusterGroup.append('text')
                .attr('class', 'cluster-label')
                .attr('x', bounds.centerX)
                .attr('y', bounds.centerY - bounds.height / 2 - 10)
                .attr('text-anchor', 'middle')
                .style('font-size', '12px')
                .style('font-weight', 'bold')
                .style('fill', getClusterColor(clusterName))
                .text(clusterName);
        }
    });
}

/**
 * Helper functions for interactive exploration
 */
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

function calculateClusterBounds(nodes) {
    const xValues = nodes.map(n => n.x || 0);
    const yValues = nodes.map(n => n.y || 0);
    
    return {
        centerX: d3.mean(xValues),
        centerY: d3.mean(yValues),
        width: d3.max(xValues) - d3.min(xValues),
        height: d3.max(yValues) - d3.min(yValues)
    };
}

function getClusterColor(clusterName) {
    const colors = ['#4CAF50', '#2196F3', '#FF9800', '#9C27B0', '#F44336', '#607D8B'];
    const index = CLUSTER_CONFIG.domainClusters.indexOf(clusterName);
    return colors[index >= 0 ? index : 0];
}

/**
 * Export interactive exploration functionality
 */
window.InteractiveExploration = {
    initialize: initializeInteractiveExploration,
    search: performAdvancedSearch,
    findPath: calculateShortestPath,
    analyzeChains: analyzeDependencyChains,
    detectCircular: detectCircularDependencies,
    cluster: performAutomaticClustering,
    explorationState: () => explorationState
};

// Initialize when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeInteractiveExploration);
} else {
    // Delay to ensure other components are initialized first
    setTimeout(initializeInteractiveExploration, 200);
}