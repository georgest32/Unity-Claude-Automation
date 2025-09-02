/**
 * Unity-Claude Automation - Graph Controls
 * Interactive control system for D3.js visualization
 * Handles search, filtering, simulation controls, and visual settings
 */

// Control state variables
let searchQuery = '';
let filteredNodes = [];
let filteredLinks = [];
let showLabels = false;
let isPaused = false;

// Control elements cache
let controlElements = {};

/**
 * Initialize all graph controls
 */
function setupControls() {
    console.log('⚙️ Setting up graph controls...');
    
    // Cache control elements
    cacheControlElements();
    
    // Set up control panel toggle
    setupPanelToggle();
    
    // Set up search and filter controls
    setupSearchControls();
    
    // Set up simulation controls
    setupSimulationControls();
    
    // Set up visual settings
    setupVisualControls();
    
    // Set up data controls
    setupDataControls();
    
    // Set up keyboard shortcuts
    setupKeyboardShortcuts();
    
    console.log('✅ Graph controls initialized successfully');
}

/**
 * Cache control elements for performance
 */
function cacheControlElements() {
    controlElements = {
        panel: document.getElementById('control-panel'),
        panelToggle: document.getElementById('panel-toggle'),
        searchBox: document.getElementById('search-box'),
        clearSearch: document.getElementById('clear-search'),
        forceStrength: document.getElementById('force-strength'),
        forceValue: document.getElementById('force-value'),
        chargeStrength: document.getElementById('charge-strength'),
        chargeValue: document.getElementById('charge-value'),
        restartSimulation: document.getElementById('restart-simulation'),
        pauseSimulation: document.getElementById('pause-simulation'),
        toggleLabels: document.getElementById('toggle-labels'),
        toggleRenderer: document.getElementById('toggle-renderer'),
        centerGraph: document.getElementById('center-graph'),
        refreshData: document.getElementById('refresh-data'),
        exportData: document.getElementById('export-data')
    };
}

/**
 * Set up control panel collapse/expand functionality
 */
function setupPanelToggle() {
    controlElements.panelToggle.addEventListener('click', () => {
        const panel = controlElements.panel;
        const isCollapsed = panel.classList.contains('collapsed');
        
        if (isCollapsed) {
            panel.classList.remove('collapsed');
            controlElements.panelToggle.textContent = '⚙️';
        } else {
            panel.classList.add('collapsed');
            controlElements.panelToggle.textContent = '📖';
        }
    });
}

/**
 * Set up search and filter controls
 */
function setupSearchControls() {
    // Real-time search as user types
    controlElements.searchBox.addEventListener('input', (event) => {
        searchQuery = event.target.value.toLowerCase().trim();
        performSearch();
    });
    
    // Clear search button
    controlElements.clearSearch.addEventListener('click', () => {
        controlElements.searchBox.value = '';
        searchQuery = '';
        clearSearch();
    });
    
    // Search on Enter key
    controlElements.searchBox.addEventListener('keypress', (event) => {
        if (event.key === 'Enter') {
            performSearch();
        }
    });
}

/**
 * Perform search and highlight matching nodes
 */
function performSearch() {
    if (!searchQuery) {
        clearSearch();
        return;
    }
    
    console.log(`🔍 Searching for: "${searchQuery}"`);
    
    // Find matching nodes
    filteredNodes = graphData.nodes.filter(node => 
        node.id.toLowerCase().includes(searchQuery) ||
        (node.type && node.type.toLowerCase().includes(searchQuery)) ||
        (node.group && node.group.toLowerCase().includes(searchQuery))
    );
    
    // Find links connected to matching nodes
    const filteredNodeIds = new Set(filteredNodes.map(n => n.id));
    filteredLinks = graphData.links.filter(link =>
        filteredNodeIds.has(link.source.id || link.source) ||
        filteredNodeIds.has(link.target.id || link.target)
    );
    
    // Apply visual highlighting
    applySearchHighlighting();
    
    console.log(`🎯 Found ${filteredNodes.length} matching nodes`);
}

/**
 * Apply search highlighting to nodes and links
 */
function applySearchHighlighting() {
    if (currentRenderMode === 'svg') {
        // SVG mode - use CSS classes for highlighting
        svg.selectAll('.node')
            .classed('search-highlight', d => filteredNodes.includes(d))
            .style('opacity', d => 
                !searchQuery || filteredNodes.includes(d) ? 1.0 : 0.3
            );
        
        svg.selectAll('.link')
            .style('opacity', d => 
                !searchQuery || filteredLinks.includes(d) ? 0.6 : 0.1
            );
        
        svg.selectAll('.label')
            .style('opacity', d => 
                !searchQuery || filteredNodes.includes(d) ? 1.0 : 0.3
            );
    } else {
        // Canvas mode - trigger redraw with highlighting
        renderCanvas();
    }
}

/**
 * Clear search highlighting
 */
function clearSearch() {
    filteredNodes = [];
    filteredLinks = [];
    
    if (currentRenderMode === 'svg') {
        svg.selectAll('.node')
            .classed('search-highlight', false)
            .style('opacity', 1.0);
        
        svg.selectAll('.link')
            .style('opacity', 0.6);
        
        svg.selectAll('.label')
            .style('opacity', 1.0);
    } else {
        renderCanvas();
    }
    
    console.log('🧹 Search cleared');
}

/**
 * Set up simulation parameter controls
 */
function setupSimulationControls() {
    // Force strength slider
    controlElements.forceStrength.addEventListener('input', (event) => {
        const value = parseInt(event.target.value);
        controlElements.forceValue.textContent = value;
        
        if (simulation) {
            simulation.force('link').strength(value / 100);
            simulation.alpha(0.3).restart();
        }
    });
    
    // Charge strength slider
    controlElements.chargeStrength.addEventListener('input', (event) => {
        const value = parseInt(event.target.value);
        controlElements.chargeValue.textContent = value;
        
        if (simulation) {
            simulation.force('charge').strength(value);
            simulation.alpha(0.3).restart();
        }
    });
    
    // Restart simulation button
    controlElements.restartSimulation.addEventListener('click', () => {
        if (simulation) {
            simulation.alpha(1).restart();
            console.log('🔄 Simulation restarted');
        }
    });
    
    // Pause/resume simulation button
    controlElements.pauseSimulation.addEventListener('click', () => {
        if (simulation) {
            if (isPaused) {
                simulation.restart();
                controlElements.pauseSimulation.innerHTML = '⏸️ Pause';
                isPaused = false;
                console.log('▶️ Simulation resumed');
            } else {
                simulation.stop();
                controlElements.pauseSimulation.innerHTML = '▶️ Resume';
                isPaused = true;
                console.log('⏸️ Simulation paused');
            }
        }
    });
}

/**
 * Set up visual settings controls
 */
function setupVisualControls() {
    // Toggle labels button
    controlElements.toggleLabels.addEventListener('click', () => {
        showLabels = !showLabels;
        
        if (currentRenderMode === 'svg') {
            svg.select('.labels')
                .style('display', showLabels ? 'block' : 'none');
        }
        
        controlElements.toggleLabels.innerHTML = showLabels ? 
            '🏷️ Hide Labels' : '🏷️ Show Labels';
        
        console.log(`🏷️ Labels ${showLabels ? 'shown' : 'hidden'}`);
    });
    
    // Toggle renderer button
    controlElements.toggleRenderer.addEventListener('click', () => {
        const newMode = currentRenderMode === 'svg' ? 'canvas' : 'svg';
        switchRenderMode(newMode);
        
        controlElements.toggleRenderer.innerHTML = newMode === 'canvas' ? 
            '🖼️ SVG Mode' : '⚡ Canvas Mode';
        
        console.log(`🔄 Switched to ${newMode.toUpperCase()} mode`);
    });
    
    // Center graph button
    controlElements.centerGraph.addEventListener('click', () => {
        centerGraph();
        console.log('🎯 Graph centered');
    });
}

/**
 * Set up data refresh and export controls
 */
function setupDataControls() {
    // Refresh data button
    controlElements.refreshData.addEventListener('click', async () => {
        controlElements.refreshData.innerHTML = '🔄 Loading...';
        controlElements.refreshData.disabled = true;
        
        try {
            await refreshGraphData();
            console.log('📊 Data refreshed successfully');
        } catch (error) {
            console.error('❌ Failed to refresh data:', error);
        } finally {
            controlElements.refreshData.innerHTML = '🔄 Refresh';
            controlElements.refreshData.disabled = false;
        }
    });
    
    // Export data button
    controlElements.exportData.addEventListener('click', () => {
        exportGraphData();
    });
}

/**
 * Export current graph data as JSON
 */
function exportGraphData() {
    console.log('💾 Exporting graph data...');
    
    const exportData = {
        nodes: graphData.nodes.map(node => ({
            id: node.id,
            group: node.group,
            type: node.type,
            x: node.x,
            y: node.y
        })),
        links: graphData.links.map(link => ({
            source: link.source.id || link.source,
            target: link.target.id || link.target,
            strength: link.strength
        })),
        metadata: {
            exportTime: new Date().toISOString(),
            nodeCount: graphData.nodes.length,
            linkCount: graphData.links.length,
            renderMode: currentRenderMode
        }
    };
    
    // Create and trigger download
    const blob = new Blob([JSON.stringify(exportData, null, 2)], {
        type: 'application/json'
    });
    
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `unity-claude-graph-${new Date().toISOString().split('T')[0]}.json`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
    
    console.log('✅ Graph data exported successfully');
}

/**
 * Set up keyboard shortcuts
 */
function setupKeyboardShortcuts() {
    document.addEventListener('keydown', (event) => {
        // Skip if typing in input fields
        if (event.target.tagName === 'INPUT') return;
        
        switch (event.key.toLowerCase()) {
            case 'r':
                // R - Restart simulation
                if (simulation) {
                    simulation.alpha(1).restart();
                    console.log('🔄 Simulation restarted (keyboard)');
                }
                break;
            
            case 'p':
                // P - Pause/resume simulation
                if (simulation) {
                    if (isPaused) {
                        simulation.restart();
                        isPaused = false;
                        controlElements.pauseSimulation.innerHTML = '⏸️ Pause';
                    } else {
                        simulation.stop();
                        isPaused = true;
                        controlElements.pauseSimulation.innerHTML = '▶️ Resume';
                    }
                    console.log(`⏸️ Simulation ${isPaused ? 'paused' : 'resumed'} (keyboard)`);
                }
                break;
            
            case 'l':
                // L - Toggle labels
                showLabels = !showLabels;
                if (currentRenderMode === 'svg') {
                    svg.select('.labels')
                        .style('display', showLabels ? 'block' : 'none');
                }
                controlElements.toggleLabels.innerHTML = showLabels ? 
                    '🏷️ Hide Labels' : '🏷️ Show Labels';
                break;
            
            case 'c':
                // C - Center graph
                centerGraph();
                break;
            
            case 't':
                // T - Toggle renderer
                const newMode = currentRenderMode === 'svg' ? 'canvas' : 'svg';
                switchRenderMode(newMode);
                controlElements.toggleRenderer.innerHTML = newMode === 'canvas' ? 
                    '🖼️ SVG Mode' : '⚡ Canvas Mode';
                break;
            
            case 'f':
                // F - Focus on search box
                controlElements.searchBox.focus();
                break;
            
            case 'escape':
                // Escape - Clear search
                if (searchQuery) {
                    controlElements.searchBox.value = '';
                    searchQuery = '';
                    clearSearch();
                }
                break;
        }
    });
    
    console.log('⌨️ Keyboard shortcuts enabled: R(restart), P(pause), L(labels), C(center), T(toggle renderer), F(search), ESC(clear)');
}

/**
 * Filter nodes by type or group
 */
function filterByType(type) {
    console.log(`🔍 Filtering by type: ${type}`);
    
    if (type === 'all') {
        // Show all nodes
        filteredNodes = [...graphData.nodes];
        filteredLinks = [...graphData.links];
    } else {
        // Filter by type or group
        filteredNodes = graphData.nodes.filter(node => 
            node.type === type || node.group === type
        );
        
        const filteredNodeIds = new Set(filteredNodes.map(n => n.id));
        filteredLinks = graphData.links.filter(link =>
            filteredNodeIds.has(link.source.id || link.source) &&
            filteredNodeIds.has(link.target.id || link.target)
        );
    }
    
    applySearchHighlighting();
}

/**
 * Get available node types for filtering
 */
function getNodeTypes() {
    const types = new Set();
    graphData.nodes.forEach(node => {
        if (node.type) types.add(node.type);
        if (node.group) types.add(node.group);
    });
    return Array.from(types).sort();
}

// Export functions for external use
window.setupControls = setupControls;
window.performSearch = performSearch;
window.clearSearch = clearSearch;
window.filterByType = filterByType;
window.getNodeTypes = getNodeTypes;