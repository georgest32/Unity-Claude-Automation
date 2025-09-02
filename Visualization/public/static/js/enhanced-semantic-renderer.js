/**
 * Enhanced Semantic Graph Renderer for Unity-Claude Automation
 * Utilizes hybrid documentation data for rich, interactive visualization
 * 
 * Features:
 * - Semantic clustering by category
 * - AI-enhanced vs pattern-based differentiation
 * - Interactive exploration with detailed tooltips
 * - Performance optimization for large graphs
 * - Real-time filtering and search
 */

class EnhancedSemanticRenderer {
    constructor(containerId = 'graph-svg') {
        this.container = d3.select(`#${containerId}`);
        this.width = window.innerWidth;
        this.height = window.innerHeight - 60; // Account for header
        
        this.data = null;
        this.metadata = null;
        this.categories = null;
        this.simulation = null;
        this.transform = d3.zoomIdentity;
        
        // Visual settings
        this.settings = {
            showLabels: true,
            enableClustering: true,
            highlightAINodes: true,
            linkDistance: 100,
            chargeStrength: -300,
            centerForce: 0.1,
            collisionRadius: 30
        };
        
        this.selectedNodes = new Set();
        this.filteredCategories = new Set();
        
        this.initializeVisualization();
        this.setupEventHandlers();
    }
    
    initializeVisualization() {
        console.log('🎨 Initializing Enhanced Semantic Renderer...');
        
        // Clear any existing content
        this.container.selectAll('*').remove();
        
        // Set up SVG dimensions
        this.svg = this.container
            .attr('width', this.width)
            .attr('height', this.height)
            .style('background', 'linear-gradient(135deg, #1e3c72 0%, #2a5298 100%)');
        
        // Create zoom behavior
        this.zoom = d3.zoom()
            .scaleExtent([0.1, 4])
            .on('zoom', (event) => {
                this.transform = event.transform;
                this.g.attr('transform', this.transform);
            });
        
        this.svg.call(this.zoom);
        
        // Create main group for all elements
        this.g = this.svg.append('g').attr('class', 'main-group');
        
        // Create groups for different layers (order matters for rendering)
        this.linksGroup = this.g.append('g').attr('class', 'links');
        this.nodesGroup = this.g.append('g').attr('class', 'nodes');
        this.labelsGroup = this.g.append('g').attr('class', 'labels');
        
        // Create tooltip
        this.tooltip = d3.select('body')
            .append('div')
            .attr('class', 'enhanced-tooltip')
            .style('opacity', 0)
            .style('position', 'absolute')
            .style('background', 'rgba(0, 0, 0, 0.9)')
            .style('color', 'white')
            .style('padding', '12px')
            .style('border-radius', '8px')
            .style('font-size', '12px')
            .style('max-width', '300px')
            .style('box-shadow', '0 4px 12px rgba(0,0,0,0.3)')
            .style('z-index', '1000')
            .style('pointer-events', 'none');
        
        // Load and render data
        this.loadEnhancedData();
    }
    
    async loadEnhancedData() {
        try {
            console.log('📊 Loading enhanced semantic data...');
            
            // Load all data files in parallel
            const [graphData, categoriesData, metadataData] = await Promise.all([
                fetch('/static/data/enhanced-system-graph.json').then(r => r.json()),
                fetch('/static/data/categories.json').then(r => r.json()),
                fetch('/static/data/graph-metadata.json').then(r => r.json())
            ]);
            
            this.data = graphData;
            this.categories = categoriesData;
            this.metadata = metadataData;
            
            console.log(`✅ Loaded ${this.data.nodes.length} nodes and ${this.data.links.length} links`);
            console.log(`📊 Categories: ${Object.keys(this.categories).length}`);
            console.log(`🤖 AI-enhanced nodes: ${this.data.nodes.filter(n => n.isAIEnhanced).length}`);
            
            // Update UI status
            this.updateDataStatus();
            
            // Render the graph
            this.renderGraph();
            
            // Initialize controls
            this.initializeControls();
            
        } catch (error) {
            console.error('❌ Failed to load enhanced data:', error);
            this.showFallbackVisualization();
        }
    }
    
    renderGraph() {
        if (!this.data) return;
        
        console.log('🎨 Rendering enhanced semantic graph...');
        
        // Create force simulation
        this.createSimulation();
        
        // Render links
        this.renderLinks();
        
        // Render nodes
        this.renderNodes();
        
        // Render labels (if enabled)
        if (this.settings.showLabels) {
            this.renderLabels();
        }
        
        // Apply initial clustering if enabled
        if (this.settings.enableClustering) {
            this.applyCategoryClustering();
        }
    }
    
    createSimulation() {
        console.log('⚡ Creating physics simulation...');
        
        this.simulation = d3.forceSimulation(this.data.nodes)
            .force('link', d3.forceLink(this.data.links)
                .id(d => d.id)
                .distance(d => d.strength ? this.settings.linkDistance * (1 - d.strength) : this.settings.linkDistance)
                .strength(d => d.strength || 0.5))
            .force('charge', d3.forceManyBody()
                .strength(this.settings.chargeStrength))
            .force('center', d3.forceCenter(this.width / 2, this.height / 2)
                .strength(this.settings.centerForce))
            .force('collision', d3.forceCollide()
                .radius(d => d.size + this.settings.collisionRadius)
                .strength(0.7))
            .alphaDecay(0.02)
            .velocityDecay(0.4);
        
        // Tick handler
        this.simulation.on('tick', () => {
            this.updatePositions();
        });
    }
    
    renderLinks() {
        const linkSelection = this.linksGroup
            .selectAll('.link')
            .data(this.data.links);
        
        const linkEnter = linkSelection
            .enter()
            .append('line')
            .attr('class', 'link')
            .attr('stroke', d => d.color || '#999')
            .attr('stroke-width', d => d.width || 2)
            .attr('stroke-opacity', 0.6)
            .style('cursor', 'pointer');
        
        // Add hover effects to links
        linkEnter
            .on('mouseover', (event, d) => {
                this.showLinkTooltip(event, d);
                d3.select(event.currentTarget)
                    .attr('stroke-opacity', 0.9)
                    .attr('stroke-width', (d.width || 2) + 2);
            })
            .on('mouseout', (event, d) => {
                this.hideTooltip();
                d3.select(event.currentTarget)
                    .attr('stroke-opacity', 0.6)
                    .attr('stroke-width', d.width || 2);
            });
        
        this.links = linkEnter.merge(linkSelection);
    }
    
    renderNodes() {
        const nodeSelection = this.nodesGroup
            .selectAll('.node')
            .data(this.data.nodes);
        
        const nodeEnter = nodeSelection
            .enter()
            .append('circle')
            .attr('class', 'node')
            .attr('r', d => d.size || 15)
            .attr('fill', d => d.color || '#4ECDC4')
            .attr('opacity', d => d.opacity || 0.8)
            .attr('stroke', d => d.isAIEnhanced ? '#FFD700' : '#fff')
            .attr('stroke-width', d => d.isAIEnhanced ? 3 : 2)
            .style('cursor', 'pointer');
        
        // Add special effects for AI-enhanced nodes
        if (this.settings.highlightAINodes) {
            nodeEnter
                .filter(d => d.isAIEnhanced)
                .attr('filter', 'url(#glow)');
            
            // Add glow filter definition
            this.addGlowFilter();
        }
        
        // Node interactions
        nodeEnter
            .on('mouseover', (event, d) => {
                this.showNodeTooltip(event, d);
                this.highlightConnections(d);
            })
            .on('mouseout', (event, d) => {
                this.hideTooltip();
                this.clearHighlights();
            })
            .on('click', (event, d) => {
                this.selectNode(d);
                event.stopPropagation();
            })
            .on('dblclick', (event, d) => {
                this.focusOnNode(d);
                event.stopPropagation();
            })
            .call(d3.drag()
                .on('start', (event, d) => {
                    if (!event.active) this.simulation.alphaTarget(0.3).restart();
                    d.fx = d.x;
                    d.fy = d.y;
                })
                .on('drag', (event, d) => {
                    d.fx = event.x;
                    d.fy = event.y;
                })
                .on('end', (event, d) => {
                    if (!event.active) this.simulation.alphaTarget(0);
                    d.fx = null;
                    d.fy = null;
                }));
        
        this.nodes = nodeEnter.merge(nodeSelection);
    }
    
    renderLabels() {
        const labelSelection = this.labelsGroup
            .selectAll('.label')
            .data(this.data.nodes);
        
        const labelEnter = labelSelection
            .enter()
            .append('text')
            .attr('class', 'label')
            .attr('text-anchor', 'middle')
            .attr('dy', '0.35em')
            .attr('font-size', d => Math.max(10, d.size * 0.6) + 'px')
            .attr('font-weight', d => d.isAIEnhanced ? 'bold' : 'normal')
            .attr('fill', '#fff')
            .attr('stroke', '#000')
            .attr('stroke-width', '0.5px')
            .attr('paint-order', 'stroke')
            .text(d => d.label.length > 15 ? d.label.substring(0, 12) + '...' : d.label)
            .style('pointer-events', 'none');
        
        this.labels = labelEnter.merge(labelSelection);
    }
    
    updatePositions() {
        if (this.links) {
            this.links
                .attr('x1', d => d.source.x)
                .attr('y1', d => d.source.y)
                .attr('x2', d => d.target.x)
                .attr('y2', d => d.target.y);
        }
        
        if (this.nodes) {
            this.nodes
                .attr('cx', d => d.x)
                .attr('cy', d => d.y);
        }
        
        if (this.labels && this.settings.showLabels) {
            this.labels
                .attr('x', d => d.x)
                .attr('y', d => d.y);
        }
    }
    
    showNodeTooltip(event, node) {
        const tooltip = this.tooltip;
        const connectedNodes = this.getConnectedNodes(node);
        
        let content = `
            <div style="border-bottom: 1px solid #444; padding-bottom: 8px; margin-bottom: 8px;">
                <strong style="color: #FFD700;">${node.fullName || node.label}</strong>
                ${node.isAIEnhanced ? '<span style="color: #00ff88; font-size: 10px;">🤖 AI-ENHANCED</span>' : '<span style="color: #888; font-size: 10px;">📋 PATTERN-BASED</span>'}
            </div>
            <div style="margin-bottom: 8px;">
                <div><strong>Category:</strong> ${node.category}</div>
                <div><strong>Functions:</strong> ${node.functionCount || 'N/A'}</div>
                <div><strong>Connections:</strong> ${connectedNodes.length}</div>
            </div>
        `;
        
        if (node.description) {
            content += `<div style="margin-bottom: 8px; color: #ccc; font-style: italic;">${node.description}</div>`;
        }
        
        if (connectedNodes.length > 0) {
            content += `
                <div style="border-top: 1px solid #444; padding-top: 8px;">
                    <strong>Connected to:</strong><br/>
                    ${connectedNodes.slice(0, 5).map(n => `<span style="color: ${n.color};">• ${n.label}</span>`).join('<br/>')}
                    ${connectedNodes.length > 5 ? `<br/><span style="color: #888;">...and ${connectedNodes.length - 5} more</span>` : ''}
                </div>
            `;
        }
        
        tooltip.html(content)
            .style('left', (event.pageX + 10) + 'px')
            .style('top', (event.pageY - 10) + 'px')
            .transition()
            .duration(200)
            .style('opacity', 1);
    }
    
    showLinkTooltip(event, link) {
        const tooltip = this.tooltip;
        
        const content = `
            <div style="border-bottom: 1px solid #444; padding-bottom: 8px; margin-bottom: 8px;">
                <strong style="color: ${link.color};">${link.type.toUpperCase()}</strong>
            </div>
            <div style="margin-bottom: 8px;">
                <div><strong>From:</strong> ${link.source.label}</div>
                <div><strong>To:</strong> ${link.target.label}</div>
                <div><strong>Strength:</strong> ${((link.strength || 0.5) * 100).toFixed(0)}%</div>
            </div>
            ${link.description ? `<div style="color: #ccc; font-style: italic;">${link.description}</div>` : ''}
        `;
        
        tooltip.html(content)
            .style('left', (event.pageX + 10) + 'px')
            .style('top', (event.pageY - 10) + 'px')
            .transition()
            .duration(200)
            .style('opacity', 1);
    }
    
    hideTooltip() {
        this.tooltip
            .transition()
            .duration(200)
            .style('opacity', 0);
    }
    
    highlightConnections(node) {
        // Highlight connected links
        this.links
            .attr('stroke-opacity', d => 
                (d.source.id === node.id || d.target.id === node.id) ? 0.9 : 0.2)
            .attr('stroke-width', d => 
                (d.source.id === node.id || d.target.id === node.id) ? (d.width || 2) + 2 : (d.width || 2) * 0.5);
        
        // Highlight connected nodes
        const connectedIds = this.getConnectedNodes(node).map(n => n.id);
        this.nodes
            .attr('opacity', d => 
                (d.id === node.id || connectedIds.includes(d.id)) ? 1 : 0.3);
    }
    
    clearHighlights() {
        if (this.links) {
            this.links
                .attr('stroke-opacity', 0.6)
                .attr('stroke-width', d => d.width || 2);
        }
        
        if (this.nodes) {
            this.nodes
                .attr('opacity', d => d.opacity || 0.8);
        }
    }
    
    getConnectedNodes(node) {
        const connected = [];
        this.data.links.forEach(link => {
            if (link.source.id === node.id) {
                connected.push(link.target);
            } else if (link.target.id === node.id) {
                connected.push(link.source);
            }
        });
        return connected;
    }
    
    applyCategoryClustering() {
        console.log('🎯 Applying category clustering...');
        
        // Group nodes by category
        const categoryGroups = d3.group(this.data.nodes, d => d.category);
        
        // Create cluster forces for each category
        categoryGroups.forEach((nodes, category) => {
            if (nodes.length > 1) {
                const categoryColor = this.categories[category]?.color || '#94A3B8';
                const clusterCenter = this.getCategoryCenter(category);
                
                this.simulation.force(`cluster_${category}`, 
                    d3.forceCollide()
                        .radius(20)
                        .strength(0.1)
                        .x(clusterCenter.x)
                        .y(clusterCenter.y));
            }
        });
        
        this.simulation.alpha(0.3).restart();
    }
    
    getCategoryCenter(category) {
        const categories = Object.keys(this.categories);
        const index = categories.indexOf(category);
        const angle = (index / categories.length) * 2 * Math.PI;
        const radius = Math.min(this.width, this.height) * 0.3;
        
        return {
            x: this.width / 2 + Math.cos(angle) * radius,
            y: this.height / 2 + Math.sin(angle) * radius
        };
    }
    
    addGlowFilter() {
        const defs = this.svg.append('defs');
        const filter = defs.append('filter')
            .attr('id', 'glow');
        
        filter.append('feGaussianBlur')
            .attr('stdDeviation', '3')
            .attr('result', 'coloredBlur');
        
        const feMerge = filter.append('feMerge');
        feMerge.append('feMergeNode').attr('in', 'coloredBlur');
        feMerge.append('feMergeNode').attr('in', 'SourceGraphic');
    }
    
    selectNode(node) {
        if (this.selectedNodes.has(node.id)) {
            this.selectedNodes.delete(node.id);
        } else {
            this.selectedNodes.add(node.id);
        }
        
        // Update visual selection
        this.nodes
            .attr('stroke', d => this.selectedNodes.has(d.id) ? '#FFFF00' : 
                              d.isAIEnhanced ? '#FFD700' : '#fff')
            .attr('stroke-width', d => this.selectedNodes.has(d.id) ? 4 : 
                                      d.isAIEnhanced ? 3 : 2);
    }
    
    focusOnNode(node) {
        const scale = 2;
        const x = -node.x * scale + this.width / 2;
        const y = -node.y * scale + this.height / 2;
        
        this.svg
            .transition()
            .duration(750)
            .call(this.zoom.transform,
                  d3.zoomIdentity.translate(x, y).scale(scale));
    }
    
    updateDataStatus() {
        const statusElement = document.getElementById('data-status');
        if (statusElement) {
            statusElement.innerHTML = `📊 ${this.data.nodes.length} nodes loaded`;
            statusElement.style.background = 'rgba(0, 255, 0, 0.2)';
        }
        
        const nodeCountElement = document.getElementById('node-count');
        if (nodeCountElement) {
            nodeCountElement.textContent = this.data.nodes.length;
        }
    }
    
    initializeControls() {
        // Initialize UI controls (will be implemented by graph-controls.js)
        if (typeof setupEnhancedControls === 'function') {
            setupEnhancedControls(this);
        }
    }
    
    setupEventHandlers() {
        // Handle window resize
        window.addEventListener('resize', () => {
            this.width = window.innerWidth;
            this.height = window.innerHeight - 60;
            
            this.svg
                .attr('width', this.width)
                .attr('height', this.height);
            
            if (this.simulation) {
                this.simulation
                    .force('center', d3.forceCenter(this.width / 2, this.height / 2));
                this.simulation.alpha(0.3).restart();
            }
        });
        
        // Handle clicks outside nodes (deselect all)
        this.svg.on('click', () => {
            this.selectedNodes.clear();
            this.clearHighlights();
            if (this.nodes) {
                this.nodes
                    .attr('stroke', d => d.isAIEnhanced ? '#FFD700' : '#fff')
                    .attr('stroke-width', d => d.isAIEnhanced ? 3 : 2);
            }
        });
    }
    
    showFallbackVisualization() {
        console.log('🔄 Showing fallback visualization...');
        // Implement a simple fallback graph here if needed
    }
    
    // Public API methods for controls
    toggleLabels() {
        this.settings.showLabels = !this.settings.showLabels;
        if (this.settings.showLabels) {
            this.renderLabels();
        } else if (this.labels) {
            this.labels.remove();
            this.labels = null;
        }
    }
    
    toggleClustering() {
        this.settings.enableClustering = !this.settings.enableClustering;
        if (this.settings.enableClustering) {
            this.applyCategoryClustering();
        } else {
            // Remove cluster forces
            Object.keys(this.categories).forEach(category => {
                this.simulation.force(`cluster_${category}`, null);
            });
            this.simulation.alpha(0.3).restart();
        }
    }
    
    restartSimulation() {
        if (this.simulation) {
            this.simulation.alpha(1).restart();
        }
    }
    
    centerGraph() {
        this.svg
            .transition()
            .duration(750)
            .call(this.zoom.transform, d3.zoomIdentity);
    }
    
    searchNodes(query) {
        if (!query) {
            this.clearHighlights();
            return;
        }
        
        const matchingNodes = this.data.nodes.filter(node => 
            node.label.toLowerCase().includes(query.toLowerCase()) ||
            node.fullName?.toLowerCase().includes(query.toLowerCase()) ||
            node.category.toLowerCase().includes(query.toLowerCase())
        );
        
        if (matchingNodes.length > 0) {
            const matchingIds = matchingNodes.map(n => n.id);
            
            this.nodes
                .attr('opacity', d => matchingIds.includes(d.id) ? 1 : 0.2);
            
            this.links
                .attr('stroke-opacity', d => 
                    matchingIds.includes(d.source.id) || matchingIds.includes(d.target.id) ? 0.6 : 0.1);
        }
    }
}

// Global reference for other modules
window.EnhancedSemanticRenderer = EnhancedSemanticRenderer;

console.log('✅ Enhanced Semantic Renderer loaded');