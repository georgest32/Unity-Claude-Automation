/**
 * Unity-Claude Automation - D3.js Graph Renderer
 * Research-validated force-directed graph visualization with hybrid SVG/Canvas rendering
 * Optimized for CPG and semantic analysis data visualization
 */

// Global variables for graph state
let graphData = { nodes: [], links: [] };
let simulation;
let svg, canvas, canvasContext;
let transform = d3.zoomIdentity;
let currentRenderMode = 'svg';
let selectedNode = null;
let isCanvasMode = false;

// Performance monitoring
let frameCount = 0;
let lastTime = performance.now();
let fps = 0;

// Constants based on research findings
const CANVAS_THRESHOLD = 1000; // Switch to Canvas when nodes > 1000
const NODE_RADIUS = 8;
const LINK_DISTANCE = 50;
const CHARGE_STRENGTH = -300;
const ALPHA_DECAY = 0.028;

// Color schemes for different node types
const NODE_COLORS = {
    module: '#4CAF50',
    component: '#2196F3', 
    function: '#FF9800',
    metric: '#9C27B0',
    class: '#F44336',
    powershell: '#0078D4',
    default: '#666666'
};

/**
 * Initialize the graph visualization system - Enhanced Version
 */
function initializeGraph() {
    console.log('🎨 Initializing Enhanced D3.js Graph Renderer...');
    
    // Check if we should use the enhanced renderer
    if (typeof EnhancedSemanticRenderer !== 'undefined') {
        console.log('🚀 Using Enhanced Semantic Renderer...');
        window.mainRenderer = new EnhancedSemanticRenderer('graph-svg');
        return;
    }
    
    // Fallback to original renderer
    console.log('⚠️ Enhanced renderer not available, using fallback...');
    
    // Get container dimensions
    const container = document.querySelector('.visualization-container');
    const width = container.clientWidth;
    const height = container.clientHeight;
    
    // Initialize SVG
    initializeSVG(width, height);
    
    // Initialize Canvas (hidden by default)
    initializeCanvas(width, height);
    
    // Set up zoom behavior
    setupZoomBehavior(width, height);
    
    // Load initial data
    loadGraphData();
    
    // Set up resize handler
    window.addEventListener('resize', handleResize);
    
    console.log('✅ Graph renderer initialized successfully');
}

/**
 * Initialize SVG rendering system
 */
function initializeSVG(width, height) {
    svg = d3.select('#graph-svg')
        .attr('width', width)
        .attr('height', height);
    
    // Create groups for organized rendering
    svg.append('g').attr('class', 'links');
    svg.append('g').attr('class', 'nodes');
    svg.append('g').attr('class', 'labels');
    
    console.log('🖼️ SVG renderer initialized');
}

/**
 * Initialize Canvas rendering system for performance
 */
function initializeCanvas(width, height) {
    canvas = d3.select('#graph-canvas')
        .attr('width', width)
        .attr('height', height)
        .style('display', 'none');
    
    canvasContext = canvas.node().getContext('2d');
    
    // Set up high DPI rendering
    const devicePixelRatio = window.devicePixelRatio || 1;
    canvas
        .attr('width', width * devicePixelRatio)
        .attr('height', height * devicePixelRatio)
        .style('width', width + 'px')
        .style('height', height + 'px');
    
    canvasContext.scale(devicePixelRatio, devicePixelRatio);
    
    console.log('⚡ Canvas renderer initialized');
}

/**
 * Set up zoom and pan behavior
 */
function setupZoomBehavior(width, height) {
    const zoom = d3.zoom()
        .scaleExtent([0.1, 10])
        .on('zoom', (event) => {
            transform = event.transform;
            
            if (isCanvasMode) {
                // Canvas mode - trigger redraw
                renderCanvas();
            } else {
                // SVG mode - apply transform
                svg.select('.links').attr('transform', transform);
                svg.select('.nodes').attr('transform', transform);
                svg.select('.labels').attr('transform', transform);
            }
        });
    
    svg.call(zoom);
    canvas.call(zoom);
}

/**
 * Load graph data from API endpoint
 */
async function loadGraphData() {
    console.log('📡 Loading graph data...');
    
    try {
        const response = await fetch('/api/data');
        const data = await response.json();
        
        console.log(`📊 Loaded ${data.nodes.length} nodes and ${data.links.length} links`);
        
        // Update performance indicators
        document.getElementById('node-count').textContent = data.nodes.length;
        document.getElementById('data-status').innerHTML = '📊 Loaded';
        document.getElementById('data-status').style.background = 'rgba(0, 255, 0, 0.2)';
        
        // Decide rendering mode based on data size
        const shouldUseCanvas = data.nodes.length > CANVAS_THRESHOLD;
        switchRenderMode(shouldUseCanvas ? 'canvas' : 'svg');
        
        // Update graph data
        updateGraphData(data);
        
    } catch (error) {
        console.error('❌ Failed to load graph data:', error);
        document.getElementById('data-status').innerHTML = '📊 Error';
        document.getElementById('data-status').style.background = 'rgba(255, 0, 0, 0.2)';
    }
}

/**
 * Update graph data and restart simulation
 */
function updateGraphData(data) {
    graphData = data;
    
    // Prepare node objects with computed properties
    graphData.nodes.forEach(node => {
        node.radius = NODE_RADIUS;
        node.color = NODE_COLORS[node.type] || NODE_COLORS[node.group] || NODE_COLORS.default;
    });
    
    // Initialize force simulation
    initializeSimulation();
    
    // Render based on current mode
    if (isCanvasMode) {
        renderCanvas();
    } else {
        renderSVG();
    }
}

/**
 * Initialize D3 force simulation
 */
function initializeSimulation() {
    console.log('🔄 Initializing force simulation...');
    
    // Stop existing simulation
    if (simulation) {
        simulation.stop();
    }
    
    // Create new simulation
    simulation = d3.forceSimulation(graphData.nodes)
        .force('link', d3.forceLink(graphData.links)
            .id(d => d.id)
            .distance(LINK_DISTANCE)
            .strength(d => d.strength || 0.5))
        .force('charge', d3.forceManyBody()
            .strength(CHARGE_STRENGTH))
        .force('center', d3.forceCenter(
            document.querySelector('.visualization-container').clientWidth / 2,
            document.querySelector('.visualization-container').clientHeight / 2))
        .force('collision', d3.forceCollide()
            .radius(d => d.radius + 2))
        .alphaDecay(ALPHA_DECAY)
        .on('tick', () => {
            if (isCanvasMode) {
                renderCanvas();
            } else {
                updateSVGPositions();
            }
            updateFPS();
        });
    
    console.log('✅ Force simulation ready');
}

/**
 * Render graph using SVG (for smaller datasets)
 */
function renderSVG() {
    console.log('🖼️ Rendering SVG graph...');
    
    // Render links
    const links = svg.select('.links')
        .selectAll('.link')
        .data(graphData.links);
    
    links.enter()
        .append('line')
        .attr('class', 'link')
        .merge(links)
        .attr('stroke-width', d => Math.sqrt(d.strength * 4) || 2);
    
    links.exit().remove();
    
    // Render nodes
    const nodes = svg.select('.nodes')
        .selectAll('.node')
        .data(graphData.nodes);
    
    const nodeEnter = nodes.enter()
        .append('circle')
        .attr('class', 'node')
        .attr('r', d => d.radius)
        .attr('fill', d => d.color)
        .call(d3.drag()
            .on('start', dragStarted)
            .on('drag', dragged)
            .on('end', dragEnded))
        .on('click', handleNodeClick)
        .on('mouseover', handleNodeHover)
        .on('mouseout', hideTooltip);
    
    nodeEnter.merge(nodes);
    nodes.exit().remove();
    
    // Render labels (optional, can be toggled)
    const labels = svg.select('.labels')
        .selectAll('.label')
        .data(graphData.nodes);
    
    labels.enter()
        .append('text')
        .attr('class', 'label')
        .attr('text-anchor', 'middle')
        .attr('dy', '.35em')
        .style('fill', 'white')
        .style('font-size', '10px')
        .style('pointer-events', 'none')
        .text(d => d.id.length > 15 ? d.id.substring(0, 12) + '...' : d.id);
    
    labels.exit().remove();
}

/**
 * Update SVG element positions (called on simulation tick)
 */
function updateSVGPositions() {
    svg.select('.links')
        .selectAll('.link')
        .attr('x1', d => d.source.x)
        .attr('y1', d => d.source.y)
        .attr('x2', d => d.target.x)
        .attr('y2', d => d.target.y);
    
    svg.select('.nodes')
        .selectAll('.node')
        .attr('cx', d => d.x)
        .attr('cy', d => d.y);
    
    svg.select('.labels')
        .selectAll('.label')
        .attr('x', d => d.x)
        .attr('y', d => d.y);
}

/**
 * Render graph using Canvas (for large datasets)
 */
function renderCanvas() {
    if (!canvasContext) return;
    
    const width = canvas.node().width;
    const height = canvas.node().height;
    
    // Clear canvas
    canvasContext.save();
    canvasContext.clearRect(0, 0, width, height);
    canvasContext.translate(transform.x, transform.y);
    canvasContext.scale(transform.k, transform.k);
    
    // Draw links
    canvasContext.strokeStyle = 'rgba(153, 153, 153, 0.6)';
    canvasContext.lineWidth = 2;
    canvasContext.beginPath();
    
    graphData.links.forEach(link => {
        canvasContext.moveTo(link.source.x, link.source.y);
        canvasContext.lineTo(link.target.x, link.target.y);
    });
    
    canvasContext.stroke();
    
    // Draw nodes
    graphData.nodes.forEach(node => {
        canvasContext.beginPath();
        canvasContext.arc(node.x, node.y, node.radius, 0, 2 * Math.PI);
        canvasContext.fillStyle = node.color;
        canvasContext.fill();
        canvasContext.strokeStyle = 'white';
        canvasContext.lineWidth = 2;
        canvasContext.stroke();
    });
    
    canvasContext.restore();
}

/**
 * Switch between SVG and Canvas rendering modes
 */
function switchRenderMode(mode) {
    console.log(`🔄 Switching to ${mode.toUpperCase()} render mode`);
    
    isCanvasMode = (mode === 'canvas');
    currentRenderMode = mode;
    
    if (isCanvasMode) {
        svg.style('display', 'none');
        canvas.style('display', 'block');
        renderCanvas();
    } else {
        canvas.style('display', 'none');
        svg.style('display', 'block');
        renderSVG();
    }
    
    document.getElementById('render-mode').textContent = mode.toUpperCase();
}

/**
 * Handle node drag start
 */
function dragStarted(event, d) {
    if (!event.active) simulation.alphaTarget(0.3).restart();
    d.fx = d.x;
    d.fy = d.y;
}

/**
 * Handle node drag
 */
function dragged(event, d) {
    d.fx = event.x;
    d.fy = event.y;
}

/**
 * Handle node drag end
 */
function dragEnded(event, d) {
    if (!event.active) simulation.alphaTarget(0);
    d.fx = null;
    d.fy = null;
}

/**
 * Handle node click selection
 */
function handleNodeClick(event, d) {
    // Clear previous selection
    if (selectedNode) {
        selectedNode.selected = false;
    }
    
    // Select new node
    selectedNode = d;
    d.selected = true;
    
    // Update visual state
    if (!isCanvasMode) {
        svg.selectAll('.node')
            .classed('selected', node => node.selected);
        
        // Highlight connected links
        svg.selectAll('.link')
            .classed('highlighted', link => 
                link.source === d || link.target === d);
    }
    
    console.log('🎯 Selected node:', d.id);
}

/**
 * Handle node hover with tooltip
 */
function handleNodeHover(event, d) {
    const tooltip = document.getElementById('tooltip');
    
    tooltip.innerHTML = `
        <strong>${d.id}</strong><br/>
        Type: ${d.type || d.group}<br/>
        Group: ${d.group}<br/>
        ${d.description ? `<br/>${d.description}` : ''}
    `;
    
    tooltip.style.left = (event.pageX + 10) + 'px';
    tooltip.style.top = (event.pageY + 10) + 'px';
    tooltip.style.opacity = '1';
}

/**
 * Hide tooltip
 */
function hideTooltip() {
    document.getElementById('tooltip').style.opacity = '0';
}

/**
 * Update FPS counter
 */
function updateFPS() {
    frameCount++;
    const currentTime = performance.now();
    
    if (currentTime - lastTime >= 1000) {
        fps = Math.round((frameCount * 1000) / (currentTime - lastTime));
        document.getElementById('fps-counter').textContent = fps;
        frameCount = 0;
        lastTime = currentTime;
    }
}

/**
 * Handle window resize
 */
function handleResize() {
    const container = document.querySelector('.visualization-container');
    const width = container.clientWidth;
    const height = container.clientHeight;
    
    // Resize SVG
    svg.attr('width', width).attr('height', height);
    
    // Resize Canvas
    const devicePixelRatio = window.devicePixelRatio || 1;
    canvas
        .attr('width', width * devicePixelRatio)
        .attr('height', height * devicePixelRatio)
        .style('width', width + 'px')
        .style('height', height + 'px');
    
    if (canvasContext) {
        canvasContext.scale(devicePixelRatio, devicePixelRatio);
    }
    
    // Update force center
    if (simulation) {
        simulation.force('center', d3.forceCenter(width / 2, height / 2));
        simulation.alpha(0.3).restart();
    }
}

/**
 * Refresh graph data (called from WebSocket updates)
 */
function refreshGraphData() {
    console.log('🔄 Refreshing graph data...');
    loadGraphData();
}

/**
 * Center the graph view
 */
function centerGraph() {
    const container = document.querySelector('.visualization-container');
    const width = container.clientWidth;
    const height = container.clientHeight;
    
    const centerTransform = d3.zoomIdentity.translate(width / 2, height / 2).scale(1);
    
    if (isCanvasMode) {
        canvas.transition().duration(750).call(
            d3.zoom().transform,
            centerTransform
        );
    } else {
        svg.transition().duration(750).call(
            d3.zoom().transform,
            centerTransform
        );
    }
}

// Export functions for use in other modules
window.initializeGraph = initializeGraph;
window.refreshGraphData = refreshGraphData;
window.switchRenderMode = switchRenderMode;
window.centerGraph = centerGraph;