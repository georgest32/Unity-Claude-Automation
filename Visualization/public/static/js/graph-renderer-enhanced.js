/**
 * Unity-Claude Automation - Enhanced D3.js Graph Renderer
 * Day 7 Enhancement: Advanced network graph with collapsible nodes, enhanced tooltips, and interactive features
 * Built on research-validated force-directed graph visualization with hybrid SVG/Canvas rendering
 */

// Global variables for enhanced graph state
let graphData = { nodes: [], links: [] };
let originalData = { nodes: [], links: [] }; // Store original data for collapse/expand
let simulation;
let svg, canvas, canvasContext;
let transform = d3.zoomIdentity;
let currentRenderMode = 'svg';
let selectedNodes = new Set(); // Support multi-selection
let hoveredNode = null;
let isCanvasMode = false;
let collapsedGroups = new Set(); // Track collapsed node groups
let nodeHierarchy = new Map(); // Track parent-child relationships

// Enhanced tooltip system
let tooltip = null;
let tooltipUpdateTimer = null;

// Performance monitoring
let frameCount = 0;
let lastTime = performance.now();
let fps = 0;

// Enhanced constants based on research findings
const CANVAS_THRESHOLD = 1000;
const NODE_RADIUS = {
    default: 8,
    expanded: 12,
    collapsed: 16,
    selected: 10
};
const LINK_DISTANCE = 50;
const CHARGE_STRENGTH = -300;
const ALPHA_DECAY = 0.028;
const COLLAPSE_THRESHOLD = 5; // Minimum nodes to enable collapse

// Enhanced color schemes with interaction states
const NODE_COLORS = {
    module: '#4CAF50',
    component: '#2196F3', 
    function: '#FF9800',
    metric: '#9C27B0',
    class: '#F44336',
    powershell: '#0078D4',
    collapsed: '#757575',
    selected: '#E91E63',
    highlighted: '#FFC107',
    default: '#666666'
};

// Link styling for relationship strength
const LINK_STYLES = {
    weak: { width: 1, opacity: 0.3, color: '#cccccc' },
    medium: { width: 2, opacity: 0.6, color: '#888888' },
    strong: { width: 3, opacity: 0.9, color: '#333333' },
    critical: { width: 4, opacity: 1.0, color: '#ff0000' }
};

/**
 * Initialize the enhanced graph visualization system
 */
function initializeGraph() {
    console.log('🎨 Initializing Enhanced D3.js Graph Renderer...');
    
    // Get container dimensions
    const container = document.querySelector('.visualization-container');
    const width = container.clientWidth;
    const height = container.clientHeight;
    
    // Initialize enhanced SVG
    initializeEnhancedSVG(width, height);
    
    // Initialize Canvas (hidden by default)
    initializeCanvas(width, height);
    
    // Initialize enhanced tooltip system
    initializeTooltip();
    
    // Set up enhanced zoom behavior
    setupEnhancedZoomBehavior(width, height);
    
    // Set up advanced interaction handlers
    setupAdvancedInteractions();
    
    // Load initial data
    loadGraphData();
    
    // Set up resize handler
    window.addEventListener('resize', handleResize);
    
    // Set up keyboard shortcuts
    setupKeyboardShortcuts();
    
    console.log('✅ Enhanced graph renderer initialized successfully');
}

/**
 * Initialize enhanced SVG rendering system with additional layers
 */
function initializeEnhancedSVG(width, height) {
    svg = d3.select('#graph-svg')
        .attr('width', width)
        .attr('height', height);
    
    // Create organized rendering groups
    svg.append('g').attr('class', 'background-links'); // Background/weak links
    svg.append('g').attr('class', 'links'); // Main links
    svg.append('g').attr('class', 'highlight-links'); // Highlighted relationship paths
    svg.append('g').attr('class', 'nodes'); // Main nodes
    svg.append('g').attr('class', 'node-groups'); // Collapsed node groups
    svg.append('g').attr('class', 'labels'); // Node labels
    svg.append('g').attr('class', 'annotations'); // User annotations
    
    console.log('🖼️ Enhanced SVG renderer initialized');
}

/**
 * Initialize enhanced tooltip system
 */
function initializeTooltip() {
    tooltip = d3.select('body')
        .append('div')
        .attr('class', 'graph-tooltip')
        .style('position', 'absolute')
        .style('visibility', 'hidden')
        .style('background', 'rgba(0, 0, 0, 0.9)')
        .style('color', 'white')
        .style('padding', '12px')
        .style('border-radius', '8px')
        .style('font-size', '12px')
        .style('max-width', '300px')
        .style('z-index', 1000)
        .style('box-shadow', '0 4px 12px rgba(0, 0, 0, 0.3)')
        .style('backdrop-filter', 'blur(4px)');
    
    console.log('💬 Enhanced tooltip system initialized');
}

/**
 * Set up enhanced zoom and pan behavior with constraints
 */
function setupEnhancedZoomBehavior(width, height) {
    const zoom = d3.zoom()
        .scaleExtent([0.1, 20]) // Extended zoom range
        .on('zoom', (event) => {
            transform = event.transform;
            
            if (isCanvasMode) {
                renderCanvas();
            } else {
                // Apply transform to all SVG groups
                svg.selectAll('g').attr('transform', transform);
            }
            
            // Update tooltip position if visible
            if (hoveredNode && tooltip.style('visibility') === 'visible') {
                updateTooltipPosition();
            }
        })
        .on('end', () => {
            // Optimize rendering after zoom ends
            if (!isCanvasMode) {
                optimizeSVGRendering();
            }
        });
    
    svg.call(zoom);
    if (canvas) canvas.call(zoom);
    
    // Add zoom controls
    addZoomControls();
}

/**
 * Set up advanced interaction handlers
 */
function setupAdvancedInteractions() {
    // Multi-selection with Ctrl+Click
    document.addEventListener('keydown', (event) => {
        if (event.ctrlKey) {
            document.body.classList.add('multi-select-mode');
        }
    });
    
    document.addEventListener('keyup', (event) => {
        if (!event.ctrlKey) {
            document.body.classList.remove('multi-select-mode');
        }
    });
    
    // Selection rectangle for area selection
    let selectionStart = null;
    let selectionRect = null;
    
    svg.on('mousedown', (event) => {
        if (event.shiftKey && !event.target.classList.contains('node')) {
            selectionStart = d3.pointer(event);
            selectionRect = svg.append('rect')
                .attr('class', 'selection-rect')
                .attr('x', selectionStart[0])
                .attr('y', selectionStart[1])
                .attr('width', 0)
                .attr('height', 0)
                .style('fill', 'rgba(0, 123, 255, 0.1)')
                .style('stroke', '#007bff')
                .style('stroke-width', 1)
                .style('stroke-dasharray', '3,3');
        }
    });
    
    svg.on('mousemove', (event) => {
        if (selectionRect) {
            const current = d3.pointer(event);
            const x = Math.min(selectionStart[0], current[0]);
            const y = Math.min(selectionStart[1], current[1]);
            const width = Math.abs(current[0] - selectionStart[0]);
            const height = Math.abs(current[1] - selectionStart[1]);
            
            selectionRect
                .attr('x', x)
                .attr('y', y)
                .attr('width', width)
                .attr('height', height);
        }
    });
    
    svg.on('mouseup', (event) => {
        if (selectionRect) {
            // Select nodes within rectangle
            const rectBounds = selectionRect.node().getBoundingClientRect();
            selectNodesInRectangle(rectBounds);
            
            selectionRect.remove();
            selectionRect = null;
            selectionStart = null;
        }
    });
    
    console.log('🖱️ Advanced interaction handlers initialized');
}

/**
 * Load enhanced graph data with hierarchy detection
 */
async function loadGraphData() {
    console.log('📡 Loading enhanced graph data...');
    
    try {
        const response = await fetch('/api/data');
        const data = await response.json();
        
        console.log(`📊 Loaded ${data.nodes.length} nodes and ${data.links.length} links`);
        
        // Store original data
        originalData = JSON.parse(JSON.stringify(data));
        
        // Detect and build node hierarchy
        buildNodeHierarchy(data);
        
        // Update performance indicators
        updatePerformanceUI(data);
        
        // Decide rendering mode based on data size
        const shouldUseCanvas = data.nodes.length > CANVAS_THRESHOLD;
        switchRenderMode(shouldUseCanvas ? 'canvas' : 'svg');
        
        // Update graph data
        updateGraphData(data);
        
    } catch (error) {
        console.error('❌ Failed to load graph data:', error);
        updateErrorUI();
    }
}

/**
 * Build node hierarchy for collapsible functionality
 */
function buildNodeHierarchy(data) {
    console.log('🏗️ Building node hierarchy...');
    
    nodeHierarchy.clear();
    
    // Group nodes by parent/module relationships
    const groups = {};
    data.nodes.forEach(node => {
        const groupKey = node.module || node.group || 'default';
        if (!groups[groupKey]) {
            groups[groupKey] = [];
        }
        groups[groupKey].push(node);
    });
    
    // Create hierarchy map
    Object.entries(groups).forEach(([groupKey, nodes]) => {
        if (nodes.length >= COLLAPSE_THRESHOLD) {
            nodeHierarchy.set(groupKey, {
                nodes: nodes,
                collapsed: false,
                representative: nodes[0] // Use first node as representative
            });
        }
    });
    
    console.log(`📊 Built hierarchy with ${nodeHierarchy.size} collapsible groups`);
}

/**
 * Enhanced graph data update with collapsible node support
 */
function updateGraphData(data) {
    // Apply current collapse states
    graphData = applyCollapseStates(data);
    
    // Prepare node objects with enhanced properties
    graphData.nodes.forEach(node => {
        node.radius = getNodeRadius(node);
        node.color = getNodeColor(node);
        node.isCollapsedGroup = node.type === 'collapsed-group';
        node.childCount = node.isCollapsedGroup ? node.children?.length || 0 : 0;
    });
    
    // Initialize enhanced simulation
    initializeEnhancedSimulation();
    
    // Render based on current mode
    if (isCanvasMode) {
        renderEnhancedCanvas();
    } else {
        renderEnhancedSVG();
    }
    
    console.log('🔄 Enhanced graph data updated');
}

/**
 * Apply collapse states to data
 */
function applyCollapseStates(data) {
    const result = { nodes: [], links: [] };
    const nodeMap = new Map();
    
    // Process nodes with collapse logic
    data.nodes.forEach(node => {
        const groupKey = node.module || node.group || 'default';
        const hierarchyGroup = nodeHierarchy.get(groupKey);
        
        if (hierarchyGroup && collapsedGroups.has(groupKey)) {
            // Create or update collapsed group node
            if (!nodeMap.has(groupKey)) {
                const collapsedNode = {
                    id: `collapsed_${groupKey}`,
                    type: 'collapsed-group',
                    group: groupKey,
                    x: hierarchyGroup.representative.x,
                    y: hierarchyGroup.representative.y,
                    children: hierarchyGroup.nodes,
                    label: `${groupKey} (${hierarchyGroup.nodes.length})`
                };
                result.nodes.push(collapsedNode);
                nodeMap.set(groupKey, collapsedNode);
            }
        } else {
            // Add regular node
            result.nodes.push(node);
            nodeMap.set(node.id, node);
        }
    });
    
    // Process links with collapse consideration
    data.links.forEach(link => {
        const sourceGroup = getNodeGroup(link.source);
        const targetGroup = getNodeGroup(link.target);
        
        if (collapsedGroups.has(sourceGroup) || collapsedGroups.has(targetGroup)) {
            // Create inter-group links
            const sourceId = collapsedGroups.has(sourceGroup) ? `collapsed_${sourceGroup}` : link.source;
            const targetId = collapsedGroups.has(targetGroup) ? `collapsed_${targetGroup}` : link.target;
            
            if (sourceId !== targetId) {
                result.links.push({
                    source: sourceId,
                    target: targetId,
                    type: link.type,
                    strength: link.strength,
                    isCollapsedLink: true
                });
            }
        } else {
            // Add regular link
            result.links.push(link);
        }
    });
    
    return result;
}

/**
 * Initialize enhanced force simulation with advanced features
 */
function initializeEnhancedSimulation() {
    console.log('🔄 Initializing enhanced force simulation...');
    
    if (simulation) {
        simulation.stop();
    }
    
    // Create simulation with enhanced forces
    simulation = d3.forceSimulation(graphData.nodes)
        .force('link', d3.forceLink(graphData.links)
            .id(d => d.id)
            .distance(d => d.isCollapsedLink ? LINK_DISTANCE * 1.5 : LINK_DISTANCE)
            .strength(d => d.strength ? d.strength * 0.1 : 0.1)
        )
        .force('charge', d3.forceManyBody()
            .strength(d => d.isCollapsedGroup ? CHARGE_STRENGTH * 2 : CHARGE_STRENGTH)
        )
        .force('center', d3.forceCenter(
            svg.attr('width') / 2, 
            svg.attr('height') / 2
        ))
        .force('collision', d3.forceCollide()
            .radius(d => d.radius + 2)
        )
        .alphaDecay(ALPHA_DECAY)
        .on('tick', () => {
            if (isCanvasMode) {
                renderEnhancedCanvas();
            } else {
                updateSVGPositions();
            }
            updatePerformanceStats();
        })
        .on('end', () => {
            console.log('✅ Simulation stabilized');
            optimizeRendering();
        });
    
    console.log('🚀 Enhanced simulation started');
}

/**
 * Render enhanced SVG with collapsible nodes and advanced features
 */
function renderEnhancedSVG() {
    console.log('🎨 Rendering enhanced SVG...');
    
    // Render links with enhanced styling
    renderEnhancedLinks();
    
    // Render nodes with collapse/expand functionality
    renderEnhancedNodes();
    
    // Render labels with smart positioning
    renderEnhancedLabels();
    
    console.log('✅ Enhanced SVG rendering complete');
}

/**
 * Render enhanced links with relationship strength visualization
 */
function renderEnhancedLinks() {
    const linkSelection = svg.select('.links')
        .selectAll('.link')
        .data(graphData.links, d => `${d.source.id || d.source}-${d.target.id || d.target}`);
    
    linkSelection.exit().remove();
    
    const linkEnter = linkSelection.enter()
        .append('line')
        .attr('class', 'link')
        .style('stroke-width', d => getLinkWidth(d))
        .style('stroke', d => getLinkColor(d))
        .style('stroke-opacity', d => getLinkOpacity(d))
        .style('stroke-dasharray', d => d.type === 'dependency' ? '5,5' : null);
    
    linkSelection.merge(linkEnter)
        .style('stroke-width', d => getLinkWidth(d))
        .style('stroke', d => getLinkColor(d))
        .style('stroke-opacity', d => getLinkOpacity(d));
}

/**
 * Render enhanced nodes with collapsible functionality
 */
function renderEnhancedNodes() {
    const nodeSelection = svg.select('.nodes')
        .selectAll('.node')
        .data(graphData.nodes, d => d.id);
    
    nodeSelection.exit().remove();
    
    const nodeEnter = nodeSelection.enter()
        .append('g')
        .attr('class', 'node')
        .call(setupNodeInteractions);
    
    // Add circle for node
    nodeEnter.append('circle')
        .attr('r', d => d.radius)
        .attr('fill', d => d.color)
        .attr('stroke', '#ffffff')
        .attr('stroke-width', 2);
    
    // Add collapse/expand indicator for group nodes
    nodeEnter.filter(d => d.isCollapsedGroup)
        .append('text')
        .attr('class', 'collapse-indicator')
        .attr('text-anchor', 'middle')
        .attr('dy', '.35em')
        .style('fill', 'white')
        .style('font-size', '12px')
        .style('font-weight', 'bold')
        .text('+');
    
    // Add count indicator for collapsed groups
    nodeEnter.filter(d => d.isCollapsedGroup)
        .append('text')
        .attr('class', 'count-indicator')
        .attr('text-anchor', 'middle')
        .attr('dy', '20px')
        .style('fill', '#333')
        .style('font-size', '10px')
        .text(d => d.childCount);
    
    // Update existing nodes
    const nodeUpdate = nodeSelection.merge(nodeEnter);
    
    nodeUpdate.select('circle')
        .attr('r', d => d.radius)
        .attr('fill', d => d.color)
        .attr('stroke-width', d => selectedNodes.has(d.id) ? 4 : 2)
        .attr('stroke', d => selectedNodes.has(d.id) ? NODE_COLORS.selected : '#ffffff');
}

/**
 * Set up advanced node interactions
 */
function setupNodeInteractions(selection) {
    selection
        .on('mouseover', handleNodeMouseOver)
        .on('mouseout', handleNodeMouseOut)
        .on('click', handleNodeClick)
        .on('dblclick', handleNodeDoubleClick)
        .call(d3.drag()
            .on('start', handleDragStart)
            .on('drag', handleDrag)
            .on('end', handleDragEnd)
        );
}

/**
 * Handle node mouse over with enhanced tooltip
 */
function handleNodeMouseOver(event, d) {
    hoveredNode = d;
    
    // Clear previous timer
    if (tooltipUpdateTimer) {
        clearTimeout(tooltipUpdateTimer);
    }
    
    // Delay tooltip to avoid flicker
    tooltipUpdateTimer = setTimeout(() => {
        showEnhancedTooltip(event, d);
        highlightNodeRelationships(d);
    }, 100);
}

/**
 * Handle node mouse out
 */
function handleNodeMouseOut(event, d) {
    hoveredNode = null;
    
    if (tooltipUpdateTimer) {
        clearTimeout(tooltipUpdateTimer);
    }
    
    hideTooltip();
    clearHighlights();
}

/**
 * Handle node click with multi-selection support
 */
function handleNodeClick(event, d) {
    event.stopPropagation();
    
    if (event.ctrlKey) {
        // Multi-select mode
        if (selectedNodes.has(d.id)) {
            selectedNodes.delete(d.id);
        } else {
            selectedNodes.add(d.id);
        }
    } else {
        // Single select
        selectedNodes.clear();
        selectedNodes.add(d.id);
    }
    
    updateNodeSelection();
    updateSelectionInfo();
}

/**
 * Handle node double-click for collapse/expand
 */
function handleNodeDoubleClick(event, d) {
    event.stopPropagation();
    
    if (d.isCollapsedGroup) {
        // Expand collapsed group
        expandGroup(d.group);
    } else {
        // Collapse node's group if eligible
        const groupKey = d.module || d.group || 'default';
        if (nodeHierarchy.has(groupKey) && !collapsedGroups.has(groupKey)) {
            collapseGroup(groupKey);
        }
    }
}

/**
 * Show enhanced tooltip with comprehensive information
 */
function showEnhancedTooltip(event, d) {
    const tooltipContent = createTooltipContent(d);
    
    tooltip
        .html(tooltipContent)
        .style('visibility', 'visible')
        .style('left', (event.pageX + 10) + 'px')
        .style('top', (event.pageY - 10) + 'px');
}

/**
 * Create comprehensive tooltip content
 */
function createTooltipContent(d) {
    let content = `<strong>${d.label || d.id}</strong><br>`;
    content += `Type: ${d.type}<br>`;
    
    if (d.isCollapsedGroup) {
        content += `Contains: ${d.childCount} nodes<br>`;
        content += `<em>Double-click to expand</em>`;
    } else {
        if (d.module) content += `Module: ${d.module}<br>`;
        if (d.functions) content += `Functions: ${d.functions}<br>`;
        if (d.dependencies) content += `Dependencies: ${d.dependencies.length}<br>`;
        
        // Show relationships
        const relationships = getNodeRelationships(d);
        if (relationships.incoming > 0 || relationships.outgoing > 0) {
            content += `<br><strong>Relationships:</strong><br>`;
            content += `Incoming: ${relationships.incoming}<br>`;
            content += `Outgoing: ${relationships.outgoing}`;
        }
    }
    
    return content;
}

/**
 * Collapse a group of nodes
 */
function collapseGroup(groupKey) {
    console.log(`📦 Collapsing group: ${groupKey}`);
    
    collapsedGroups.add(groupKey);
    updateGraphData(originalData);
    
    // Emit collapse event
    document.dispatchEvent(new CustomEvent('nodeGroupCollapsed', {
        detail: { groupKey, nodeCount: nodeHierarchy.get(groupKey).nodes.length }
    }));
}

/**
 * Expand a collapsed group
 */
function expandGroup(groupKey) {
    console.log(`📤 Expanding group: ${groupKey}`);
    
    collapsedGroups.delete(groupKey);
    updateGraphData(originalData);
    
    // Emit expand event
    document.dispatchEvent(new CustomEvent('nodeGroupExpanded', {
        detail: { groupKey, nodeCount: nodeHierarchy.get(groupKey).nodes.length }
    }));
}

/**
 * Highlight node relationships
 */
function highlightNodeRelationships(node) {
    // Reset previous highlights
    svg.selectAll('.link').style('stroke-opacity', 0.1);
    svg.selectAll('.node circle').style('opacity', 0.3);
    
    // Highlight connected links
    svg.selectAll('.link')
        .filter(d => d.source.id === node.id || d.target.id === node.id)
        .style('stroke-opacity', 1)
        .style('stroke-width', d => getLinkWidth(d) * 1.5);
    
    // Highlight connected nodes
    const connectedNodeIds = new Set([node.id]);
    graphData.links.forEach(link => {
        if (link.source.id === node.id) connectedNodeIds.add(link.target.id);
        if (link.target.id === node.id) connectedNodeIds.add(link.source.id);
    });
    
    svg.selectAll('.node circle')
        .filter(d => connectedNodeIds.has(d.id))
        .style('opacity', 1);
}

/**
 * Clear all highlights
 */
function clearHighlights() {
    svg.selectAll('.link')
        .style('stroke-opacity', d => getLinkOpacity(d))
        .style('stroke-width', d => getLinkWidth(d));
    
    svg.selectAll('.node circle')
        .style('opacity', 1);
}

/**
 * Helper functions for enhanced rendering
 */
function getNodeRadius(node) {
    if (node.isCollapsedGroup) return NODE_RADIUS.collapsed;
    if (selectedNodes.has(node.id)) return NODE_RADIUS.selected;
    return NODE_RADIUS.default;
}

function getNodeColor(node) {
    if (node.isCollapsedGroup) return NODE_COLORS.collapsed;
    if (selectedNodes.has(node.id)) return NODE_COLORS.selected;
    return NODE_COLORS[node.type] || NODE_COLORS[node.group] || NODE_COLORS.default;
}

function getLinkWidth(link) {
    const strength = link.strength || 1;
    if (strength >= 8) return LINK_STYLES.critical.width;
    if (strength >= 5) return LINK_STYLES.strong.width;
    if (strength >= 2) return LINK_STYLES.medium.width;
    return LINK_STYLES.weak.width;
}

function getLinkColor(link) {
    const strength = link.strength || 1;
    if (strength >= 8) return LINK_STYLES.critical.color;
    if (strength >= 5) return LINK_STYLES.strong.color;
    if (strength >= 2) return LINK_STYLES.medium.color;
    return LINK_STYLES.weak.color;
}

function getLinkOpacity(link) {
    const strength = link.strength || 1;
    if (strength >= 8) return LINK_STYLES.critical.opacity;
    if (strength >= 5) return LINK_STYLES.strong.opacity;
    if (strength >= 2) return LINK_STYLES.medium.opacity;
    return LINK_STYLES.weak.opacity;
}

function getNodeGroup(nodeId) {
    const node = originalData.nodes.find(n => n.id === nodeId);
    return node ? (node.module || node.group || 'default') : 'default';
}

function getNodeRelationships(node) {
    let incoming = 0, outgoing = 0;
    
    graphData.links.forEach(link => {
        if (link.target.id === node.id) incoming++;
        if (link.source.id === node.id) outgoing++;
    });
    
    return { incoming, outgoing };
}

/**
 * Set up keyboard shortcuts for enhanced functionality
 */
function setupKeyboardShortcuts() {
    document.addEventListener('keydown', (event) => {
        switch (event.key) {
            case 'c':
                if (event.ctrlKey) {
                    event.preventDefault();
                    collapseSelectedNodes();
                }
                break;
            case 'e':
                if (event.ctrlKey) {
                    event.preventDefault();
                    expandAllGroups();
                }
                break;
            case 'Escape':
                selectedNodes.clear();
                updateNodeSelection();
                break;
            case 'a':
                if (event.ctrlKey) {
                    event.preventDefault();
                    selectAllNodes();
                }
                break;
        }
    });
}

/**
 * Export enhanced graph functionality
 */
window.GraphRenderer = {
    initialize: initializeGraph,
    updateData: updateGraphData,
    collapseGroup,
    expandGroup,
    selectedNodes,
    graphData
};

// Initialize when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeGraph);
} else {
    initializeGraph();
}