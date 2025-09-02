// D3.js v7 Force-Directed Graph Renderer with Canvas

class GraphRenderer {
    constructor(canvasSelector, svgSelector) {
        this.canvas = d3.select(canvasSelector);
        this.svg = d3.select(svgSelector);
        this.context = this.canvas.node().getContext('2d');
        
        // Initialize properties
        this.width = 800;
        this.height = 600;
        this.transform = d3.zoomIdentity;
        this.selectedNodes = new Set();
        this.highlightedPaths = new Map();
        this.nodeQuadtree = null;
        
        // Performance monitoring
        this.frameCount = 0;
        this.lastFrameTime = 0;
        this.fps = 0;
        
        // Initialize simulation
        this.initializeSimulation();
        this.initializeZoom();
        this.initializeEventHandlers();
        
        // Set up rendering loop
        this.isAnimating = false;
        this.animationId = null;
        
        console.log('GraphRenderer initialized');
    }
    
    initializeSimulation() {
        const config = DashboardConfig.graph.simulation;
        
        this.simulation = d3.forceSimulation()
            .alphaDecay(config.alphaDecay)
            .velocityDecay(config.velocityDecay)
            .alphaMin(config.alphaMin)
            .force('link', d3.forceLink()
                .id(d => d.id)
                .distance(config.forces.link.distance)
                .strength(config.forces.link.strength)
                .iterations(config.forces.link.iterations)
            )
            .force('charge', d3.forceManyBody()
                .strength(config.forces.charge.strength)
                .distanceMax(config.forces.charge.distanceMax)
                .distanceMin(config.forces.charge.distanceMin)
            )
            .force('center', d3.forceCenter()
                .strength(config.forces.center.strength)
            )
            .force('collision', d3.forceCollide()
                .radius(d => this.getNodeRadius(d) + 2)
                .strength(config.forces.collision.strength)
                .iterations(config.forces.collision.iterations)
            )
            .on('tick', () => this.ticked())
            .on('end', () => this.simulationEnded());
    }
    
    initializeZoom() {
        const config = DashboardConfig.graph.zoom;
        
        this.zoom = d3.zoom()
            .scaleExtent([config.min, config.max])
            .on('zoom', (event) => {
                this.transform = event.transform;
                this.render();
            });
        
        this.canvas.call(this.zoom);
    }
    
    initializeEventHandlers() {
        // Canvas mouse events
        this.canvas
            .on('mousemove', (event) => this.handleMouseMove(event))
            .on('click', (event) => this.handleClick(event))
            .on('dblclick', (event) => this.handleDoubleClick(event))
            .on('contextmenu', (event) => {
                event.preventDefault();
                this.handleRightClick(event);
            });
        
        // Keyboard events (for accessibility)
        d3.select('body')
            .on('keydown', (event) => this.handleKeyDown(event));
        
        // Resize handler
        window.addEventListener('resize', () => this.handleResize());
    }
    
    setData(nodes, links) {
        console.log(`Loading graph data: ${nodes.length} nodes, ${links.length} links`);
        
        // Process nodes
        this.nodes = nodes.map(node => ({
            ...node,
            x: this.width * (0.3 + Math.random() * 0.4),
            y: this.height * (0.3 + Math.random() * 0.4),
            vx: 0,
            vy: 0
        }));
        
        // Process links
        this.links = links.map(link => ({
            ...link,
            source: typeof link.source === 'string' ? link.source : link.source.id,
            target: typeof link.target === 'string' ? link.target : link.target.id
        }));
        
        // Update simulation
        this.simulation.nodes(this.nodes);
        this.simulation.force('link').links(this.links);
        
        // Build spatial index for efficient node lookup
        this.buildNodeQuadtree();
        
        // Center the simulation
        this.simulation.force('center')
            .x(this.width / 2)
            .y(this.height / 2);
        
        // Restart simulation
        this.simulation.alpha(1).restart();
        
        // Start rendering
        this.startAnimation();
        
        // Trigger metrics update
        this.updatePerformanceMetrics();
    }
    
    buildNodeQuadtree() {
        if (this.nodes && this.nodes.length > 0) {
            this.nodeQuadtree = d3.quadtree()
                .x(d => d.x)
                .y(d => d.y)
                .addAll(this.nodes);
        }
    }
    
    ticked() {
        this.buildNodeQuadtree();
        
        if (!this.isAnimating) {
            this.startAnimation();
        }
    }
    
    simulationEnded() {
        console.log('Force simulation completed');
        this.stopAnimation();
        this.render(); // Final render
    }
    
    startAnimation() {
        if (!this.isAnimating) {
            this.isAnimating = true;
            this.animationId = requestAnimationFrame(() => this.animate());
        }
    }
    
    stopAnimation() {
        if (this.isAnimating) {
            this.isAnimating = false;
            if (this.animationId) {
                cancelAnimationFrame(this.animationId);
                this.animationId = null;
            }
        }
    }
    
    animate() {
        if (!this.isAnimating) return;
        
        // Calculate FPS
        const now = performance.now();
        this.frameCount++;
        if (now - this.lastFrameTime >= 1000) {
            this.fps = Math.round(this.frameCount * 1000 / (now - this.lastFrameTime));
            this.frameCount = 0;
            this.lastFrameTime = now;
            
            if (DashboardConfig.debug.showFPS) {
                console.log(`FPS: ${this.fps}`);
            }
        }
        
        this.render();
        
        // Continue animation if simulation is running or paths are animating
        if (this.simulation.alpha() > this.simulation.alphaMin() || this.hasAnimatingPaths()) {
            this.animationId = requestAnimationFrame(() => this.animate());
        } else {
            this.isAnimating = false;
        }
    }
    
    render() {
        const ctx = this.context;
        const { width, height, transform } = this;
        
        // Clear canvas
        ctx.clearRect(0, 0, width, height);
        
        // Save context and apply transform
        ctx.save();
        ctx.translate(transform.x, transform.y);
        ctx.scale(transform.k, transform.k);
        
        // Enable high-DPI rendering
        const pixelRatio = window.devicePixelRatio || 1;
        if (pixelRatio !== 1) {
            ctx.scale(pixelRatio, pixelRatio);
        }
        
        // Render links first (so they appear behind nodes)
        this.renderLinks(ctx);
        
        // Render highlighted paths
        this.renderHighlightedPaths(ctx);
        
        // Render nodes
        this.renderNodes(ctx);
        
        // Render labels (only at higher zoom levels)
        if (transform.k >= DashboardConfig.graph.performance.lod.labelMinZoom) {
            this.renderLabels(ctx);
        }
        
        // Restore context
        ctx.restore();
        
        // Render UI overlays (not affected by transform)
        if (DashboardConfig.debug.showPerformanceMetrics) {
            this.renderDebugInfo(ctx);
        }
    }
    
    renderLinks(ctx) {
        if (!this.links) return;
        
        const linkConfig = DashboardConfig.graph.links;
        
        this.links.forEach(link => {
            const source = link.source;
            const target = link.target;
            
            if (!source || !target || !source.x || !target.x) return;
            
            const config = ConfigUtils.getLinkConfig(link.type);
            const state = this.getLinkState(link);
            const stateConfig = linkConfig.states[state];
            
            // Set link appearance
            ctx.globalAlpha = stateConfig.opacity;
            ctx.strokeStyle = config.color;
            ctx.lineWidth = stateConfig.strokeWidth;
            
            // Set dash pattern if specified
            if (config.dashArray) {
                ctx.setLineDash(config.dashArray);
            } else {
                ctx.setLineDash([]);
            }
            
            // Add glow effect for highlighted links
            if (state === 'highlighted' || state === 'path') {
                ctx.shadowColor = config.color;
                ctx.shadowBlur = stateConfig.glowRadius || 0;
            } else {
                ctx.shadowBlur = 0;
            }
            
            // Draw link
            ctx.beginPath();
            ctx.moveTo(source.x, source.y);
            ctx.lineTo(target.x, target.y);
            ctx.stroke();
            
            // Draw arrow for directed links
            if (link.directed !== false) {
                this.drawArrow(ctx, source, target, config.color, stateConfig.strokeWidth);
            }
        });
        
        ctx.globalAlpha = 1;
        ctx.shadowBlur = 0;
        ctx.setLineDash([]);
    }
    
    renderNodes(ctx) {
        if (!this.nodes) return;
        
        const nodeConfig = DashboardConfig.graph.nodes;
        
        this.nodes.forEach(node => {
            if (!node.x || !node.y) return;
            
            const config = ConfigUtils.getNodeConfig(node.type);
            const state = this.getNodeState(node);
            const stateConfig = nodeConfig.states[state];
            const radius = this.getNodeRadius(node);
            
            // Set node appearance
            ctx.globalAlpha = stateConfig.opacity;
            
            // Add glow effect for highlighted nodes
            if (state === 'highlighted' || state === 'selected' || state === 'path') {
                ctx.shadowColor = stateConfig.glowColor;
                ctx.shadowBlur = stateConfig.glowRadius;
            } else {
                ctx.shadowBlur = 0;
            }
            
            // Draw node fill
            ctx.fillStyle = config.color;
            ctx.beginPath();
            ctx.arc(node.x, node.y, radius, 0, 2 * Math.PI);
            ctx.fill();
            
            // Draw node stroke
            ctx.strokeStyle = config.strokeColor;
            ctx.lineWidth = stateConfig.strokeWidth;
            ctx.stroke();
            
            // Draw selection indicator
            if (state === 'selected') {
                ctx.strokeStyle = stateConfig.glowColor;
                ctx.lineWidth = 2;
                ctx.beginPath();
                ctx.arc(node.x, node.y, radius + 4, 0, 2 * Math.PI);
                ctx.stroke();
            }
        });
        
        ctx.globalAlpha = 1;
        ctx.shadowBlur = 0;
    }
    
    renderLabels(ctx) {
        if (!this.nodes || this.transform.k < DashboardConfig.graph.performance.lod.labelMinZoom) return;
        
        const maxLabels = DashboardConfig.graph.performance.lod.maxLabelsShown;
        let labelCount = 0;
        
        // Sort nodes by importance (selected > highlighted > larger radius)
        const sortedNodes = [...this.nodes].sort((a, b) => {
            const aSelected = this.selectedNodes.has(a.id) ? 2 : 0;
            const bSelected = this.selectedNodes.has(b.id) ? 2 : 0;
            const aHighlighted = this.getNodeState(a) === 'highlighted' ? 1 : 0;
            const bHighlighted = this.getNodeState(b) === 'highlighted' ? 1 : 0;
            
            const aImportance = aSelected + aHighlighted + (this.getNodeRadius(a) / 20);
            const bImportance = bSelected + bHighlighted + (this.getNodeRadius(b) / 20);
            
            return bImportance - aImportance;
        });
        
        ctx.font = `${Math.max(10, 12 / this.transform.k)}px Inter, sans-serif`;
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        
        sortedNodes.forEach(node => {
            if (labelCount >= maxLabels) return;
            if (!node.x || !node.y || !node.name) return;
            
            const state = this.getNodeState(node);
            if (state === 'dimmed') return;
            
            const radius = this.getNodeRadius(node);
            const y = node.y + radius + 15;
            
            // Draw label background for better readability
            const labelWidth = ctx.measureText(node.name).width;
            const padding = 4;
            
            ctx.fillStyle = 'rgba(255, 255, 255, 0.9)';
            ctx.fillRect(
                node.x - labelWidth/2 - padding,
                y - 8,
                labelWidth + padding * 2,
                16
            );
            
            // Draw label text
            ctx.fillStyle = state === 'selected' ? '#2563eb' : '#1e293b';
            ctx.fillText(node.name, node.x, y);
            
            labelCount++;
        });
    }
    
    renderHighlightedPaths(ctx) {
        if (this.highlightedPaths.size === 0) return;
        
        const pathConfig = DashboardConfig.paths.visualization;
        
        this.highlightedPaths.forEach((pathData, pathId) => {
            const { path, animated, progress = 1 } = pathData;
            
            ctx.globalAlpha = pathConfig.opacity;
            ctx.strokeStyle = pathConfig.color;
            ctx.lineWidth = pathConfig.strokeWidth;
            ctx.setLineDash(pathConfig.dashArray || []);
            
            // Add glow effect
            ctx.shadowColor = pathConfig.color;
            ctx.shadowBlur = 8;
            
            for (let i = 0; i < path.length - 1; i++) {
                const source = path[i];
                const target = path[i + 1];
                
                if (!source || !target) continue;
                
                // For animated paths, only draw up to current progress
                if (animated && (i + 1) / (path.length - 1) > progress) continue;
                
                ctx.beginPath();
                ctx.moveTo(source.x, source.y);
                ctx.lineTo(target.x, target.y);
                ctx.stroke();
                
                // Draw directional arrow
                this.drawArrow(ctx, source, target, pathConfig.color, pathConfig.strokeWidth);
            }
        });
        
        ctx.globalAlpha = 1;
        ctx.shadowBlur = 0;
        ctx.setLineDash([]);
    }
    
    drawArrow(ctx, source, target, color, lineWidth) {
        const arrowSize = Math.max(6, lineWidth * 2);
        const dx = target.x - source.x;
        const dy = target.y - source.y;
        const angle = Math.atan2(dy, dx);
        
        // Calculate arrow position (at target node edge)
        const targetRadius = this.getNodeRadius(target) || 8;
        const arrowX = target.x - Math.cos(angle) * (targetRadius + 2);
        const arrowY = target.y - Math.sin(angle) * (targetRadius + 2);
        
        ctx.fillStyle = color;
        ctx.beginPath();
        ctx.moveTo(arrowX, arrowY);
        ctx.lineTo(
            arrowX - arrowSize * Math.cos(angle - Math.PI/6),
            arrowY - arrowSize * Math.sin(angle - Math.PI/6)
        );
        ctx.lineTo(
            arrowX - arrowSize * Math.cos(angle + Math.PI/6),
            arrowY - arrowSize * Math.sin(angle + Math.PI/6)
        );
        ctx.closePath();
        ctx.fill();
    }
    
    renderDebugInfo(ctx) {
        const info = [
            `FPS: ${this.fps}`,
            `Nodes: ${this.nodes?.length || 0}`,
            `Links: ${this.links?.length || 0}`,
            `Zoom: ${this.transform.k.toFixed(2)}`,
            `Alpha: ${this.simulation.alpha().toFixed(3)}`
        ];
        
        ctx.fillStyle = 'rgba(0, 0, 0, 0.8)';
        ctx.fillRect(10, 10, 150, info.length * 20 + 10);
        
        ctx.font = '12px monospace';
        ctx.fillStyle = '#ffffff';
        ctx.textAlign = 'left';
        ctx.textBaseline = 'top';
        
        info.forEach((text, i) => {
            ctx.fillText(text, 15, 20 + i * 20);
        });
    }
    
    // Utility methods
    getNodeRadius(node) {
        const config = ConfigUtils.getNodeConfig(node.type);
        const baseRadius = config.radius || DashboardConfig.graph.nodes.defaultRadius;
        
        // Scale radius based on importance metrics
        const importanceScale = 1 + (node.importance || 0) * 0.5;
        const radius = Math.max(
            DashboardConfig.graph.nodes.minRadius,
            Math.min(DashboardConfig.graph.nodes.maxRadius, baseRadius * importanceScale)
        );
        
        return radius;
    }
    
    getNodeState(node) {
        if (this.selectedNodes.has(node.id)) return 'selected';
        if (this.isNodeInPath(node)) return 'path';
        if (node.highlighted) return 'highlighted';
        if (node.dimmed) return 'dimmed';
        return 'normal';
    }
    
    getLinkState(link) {
        if (this.isLinkInPath(link)) return 'path';
        if (link.highlighted) return 'highlighted';
        if (link.dimmed) return 'dimmed';
        return 'normal';
    }
    
    isNodeInPath(node) {
        for (const [pathId, pathData] of this.highlightedPaths) {
            if (pathData.path.some(pathNode => pathNode.id === node.id)) {
                return true;
            }
        }
        return false;
    }
    
    isLinkInPath(link) {
        // Check if link is part of any highlighted path
        for (const [pathId, pathData] of this.highlightedPaths) {
            const path = pathData.path;
            for (let i = 0; i < path.length - 1; i++) {
                const source = path[i];
                const target = path[i + 1];
                if ((link.source.id === source.id && link.target.id === target.id) ||
                    (link.source.id === target.id && link.target.id === source.id)) {
                    return true;
                }
            }
        }
        return false;
    }
    
    hasAnimatingPaths() {
        for (const [pathId, pathData] of this.highlightedPaths) {
            if (pathData.animated && pathData.progress < 1) {
                return true;
            }
        }
        return false;
    }
    
    // Event handlers
    handleMouseMove(event) {
        const [x, y] = d3.pointer(event, this.canvas.node());
        const [transformedX, transformedY] = this.transform.invert([x, y]);
        
        // Find node under cursor
        const hoveredNode = this.findNodeAt(transformedX, transformedY);
        
        // Update cursor style
        this.canvas.style('cursor', hoveredNode ? 'pointer' : 'grab');
        
        // Update node hover states
        if (this.nodes) {
            this.nodes.forEach(node => {
                node.hovered = (node === hoveredNode);
            });
        }
        
        // Trigger re-render if hover state changed
        if (hoveredNode !== this.lastHoveredNode) {
            this.lastHoveredNode = hoveredNode;
            this.render();
            
            // Emit hover event
            this.emit('nodeHover', hoveredNode);
        }
    }
    
    handleClick(event) {
        const [x, y] = d3.pointer(event, this.canvas.node());
        const [transformedX, transformedY] = this.transform.invert([x, y]);
        
        const clickedNode = this.findNodeAt(transformedX, transformedY);
        
        if (clickedNode) {
            // Toggle node selection
            if (this.selectedNodes.has(clickedNode.id)) {
                this.selectedNodes.delete(clickedNode.id);
            } else {
                if (!event.ctrlKey && !event.metaKey) {
                    this.selectedNodes.clear();
                }
                this.selectedNodes.add(clickedNode.id);
            }
            
            this.render();
            this.emit('nodeClick', clickedNode, Array.from(this.selectedNodes));
        } else {
            // Clear selection if clicking on empty space
            if (!event.ctrlKey && !event.metaKey) {
                this.selectedNodes.clear();
                this.render();
                this.emit('selectionChange', []);
            }
        }
    }
    
    handleDoubleClick(event) {
        const [x, y] = d3.pointer(event, this.canvas.node());
        const [transformedX, transformedY] = this.transform.invert([x, y]);
        
        const clickedNode = this.findNodeAt(transformedX, transformedY);
        
        if (clickedNode) {
            // Zoom to node
            this.focusOnNode(clickedNode);
            this.emit('nodeDoubleClick', clickedNode);
        } else {
            // Reset zoom on empty space double-click
            this.resetZoom();
        }
    }
    
    handleRightClick(event) {
        const [x, y] = d3.pointer(event, this.canvas.node());
        const [transformedX, transformedY] = this.transform.invert([x, y]);
        
        const clickedNode = this.findNodeAt(transformedX, transformedY);
        
        if (clickedNode) {
            this.emit('nodeContextMenu', clickedNode, { x, y });
        } else {
            this.emit('canvasContextMenu', { x: transformedX, y: transformedY }, { x, y });
        }
    }
    
    handleKeyDown(event) {
        if (!ConfigUtils.isFeatureEnabled('keyboardShortcuts')) return;
        
        const shortcuts = DashboardConfig.accessibility.shortcuts;
        
        switch (event.code) {
            case shortcuts.zoomIn:
                event.preventDefault();
                this.zoomIn();
                break;
            case shortcuts.zoomOut:
                event.preventDefault();
                this.zoomOut();
                break;
            case shortcuts.resetZoom:
                event.preventDefault();
                this.resetZoom();
                break;
            case shortcuts.fitToScreen:
                event.preventDefault();
                this.fitToScreen();
                break;
        }
    }
    
    handleResize() {
        const container = this.canvas.node().parentElement;
        const rect = container.getBoundingClientRect();
        
        this.width = rect.width;
        this.height = rect.height;
        
        // Update canvas size
        this.canvas
            .attr('width', this.width * (window.devicePixelRatio || 1))
            .attr('height', this.height * (window.devicePixelRatio || 1))
            .style('width', `${this.width}px`)
            .style('height', `${this.height}px`);
        
        // Update SVG overlay
        this.svg
            .attr('width', this.width)
            .attr('height', this.height);
        
        // Scale context for high-DPI
        const pixelRatio = window.devicePixelRatio || 1;
        if (pixelRatio !== 1) {
            this.context.scale(pixelRatio, pixelRatio);
        }
        
        // Update simulation center
        this.simulation.force('center')
            .x(this.width / 2)
            .y(this.height / 2);
        
        this.render();
    }
    
    findNodeAt(x, y) {
        if (!this.nodeQuadtree) return null;
        
        const searchRadius = 20; // pixels
        const found = this.nodeQuadtree.find(x, y, searchRadius);
        
        if (found) {
            const dx = found.x - x;
            const dy = found.y - y;
            const distance = Math.sqrt(dx * dx + dy * dy);
            const radius = this.getNodeRadius(found);
            
            return distance <= radius ? found : null;
        }
        
        return null;
    }
    
    // Public API methods
    zoomIn() {
        const newScale = Math.min(this.transform.k * 1.2, DashboardConfig.graph.zoom.max);
        this.zoomToScale(newScale);
    }
    
    zoomOut() {
        const newScale = Math.max(this.transform.k / 1.2, DashboardConfig.graph.zoom.min);
        this.zoomToScale(newScale);
    }
    
    zoomToScale(scale) {
        this.canvas.transition()
            .duration(300)
            .call(this.zoom.scaleTo, scale);
    }
    
    resetZoom() {
        this.canvas.transition()
            .duration(500)
            .call(this.zoom.transform, d3.zoomIdentity);
    }
    
    fitToScreen() {
        if (!this.nodes || this.nodes.length === 0) return;
        
        // Calculate bounds
        const padding = 50;
        const xExtent = d3.extent(this.nodes, d => d.x);
        const yExtent = d3.extent(this.nodes, d => d.y);
        
        const width = xExtent[1] - xExtent[0];
        const height = yExtent[1] - yExtent[0];
        const centerX = (xExtent[0] + xExtent[1]) / 2;
        const centerY = (yExtent[0] + yExtent[1]) / 2;
        
        // Calculate scale to fit
        const scale = Math.min(
            (this.width - padding * 2) / width,
            (this.height - padding * 2) / height,
            DashboardConfig.graph.zoom.max
        );
        
        const transform = d3.zoomIdentity
            .translate(this.width / 2, this.height / 2)
            .scale(scale)
            .translate(-centerX, -centerY);
        
        this.canvas.transition()
            .duration(750)
            .call(this.zoom.transform, transform);
    }
    
    focusOnNode(node) {
        const scale = Math.min(2.0, DashboardConfig.graph.zoom.max);
        const transform = d3.zoomIdentity
            .translate(this.width / 2, this.height / 2)
            .scale(scale)
            .translate(-node.x, -node.y);
        
        this.canvas.transition()
            .duration(500)
            .call(this.zoom.transform, transform);
    }
    
    highlightPath(path, options = {}) {
        const pathId = options.id || `path-${Date.now()}`;
        const animated = options.animated !== false;
        
        this.highlightedPaths.set(pathId, {
            path,
            animated,
            progress: 0,
            startTime: performance.now()
        });
        
        if (animated) {
            this.animatePath(pathId, options.duration || 2000);
        } else {
            this.highlightedPaths.get(pathId).progress = 1;
            this.render();
        }
        
        return pathId;
    }
    
    animatePath(pathId, duration) {
        const pathData = this.highlightedPaths.get(pathId);
        if (!pathData) return;
        
        const startTime = performance.now();
        
        const animate = (currentTime) => {
            const elapsed = currentTime - startTime;
            const progress = Math.min(elapsed / duration, 1);
            
            pathData.progress = progress;
            
            if (!this.isAnimating) {
                this.render();
            }
            
            if (progress < 1) {
                requestAnimationFrame(animate);
            } else {
                this.emit('pathAnimationComplete', pathId);
            }
        };
        
        requestAnimationFrame(animate);
    }
    
    clearPaths() {
        this.highlightedPaths.clear();
        this.render();
    }
    
    updateSettings(settings) {
        // Update force simulation parameters
        if (settings.linkDistance !== undefined) {
            this.simulation.force('link').distance(settings.linkDistance);
        }
        if (settings.chargeStrength !== undefined) {
            this.simulation.force('charge').strength(settings.chargeStrength);
        }
        if (settings.nodeRadius !== undefined) {
            DashboardConfig.graph.nodes.defaultRadius = settings.nodeRadius;
        }
        
        // Restart simulation if needed
        if (settings.linkDistance !== undefined || settings.chargeStrength !== undefined) {
            this.simulation.alpha(0.3).restart();
        }
        
        this.render();
    }
    
    updatePerformanceMetrics() {
        if (window.DashboardMetrics) {
            window.DashboardMetrics.update('nodeCount', this.nodes?.length || 0);
            window.DashboardMetrics.update('renderTime', this.lastRenderTime || 0);
        }
    }
    
    // Event emitter methods
    emit(eventName, ...args) {
        if (this.eventListeners && this.eventListeners[eventName]) {
            this.eventListeners[eventName].forEach(callback => {
                try {
                    callback(...args);
                } catch (error) {
                    console.error(`Error in ${eventName} event handler:`, error);
                }
            });
        }
        
        // Also emit as custom DOM event
        const event = new CustomEvent(`graph-${eventName}`, { 
            detail: args.length === 1 ? args[0] : args 
        });
        document.dispatchEvent(event);
    }
    
    on(eventName, callback) {
        if (!this.eventListeners) {
            this.eventListeners = {};
        }
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
    
    destroy() {
        this.stopAnimation();
        
        if (this.simulation) {
            this.simulation.stop();
        }
        
        // Clean up event listeners
        this.canvas.on('.zoom', null);
        this.canvas.on('mousemove', null);
        this.canvas.on('click', null);
        this.canvas.on('dblclick', null);
        this.canvas.on('contextmenu', null);
        
        window.removeEventListener('resize', this.handleResize);
        
        console.log('GraphRenderer destroyed');
    }
}

// Export for module systems
if (typeof module !== 'undefined' && module.exports) {
    module.exports = GraphRenderer;
}

// Global availability
window.GraphRenderer = GraphRenderer;