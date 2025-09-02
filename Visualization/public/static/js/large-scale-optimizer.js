/**
 * Large-Scale Visualization Optimizer
 * Optimizes D3.js visualization for 500+ nodes with performance enhancements
 * Part of Day 8 Hour 1-2 Implementation
 */

(function() {
    'use strict';

    // Performance optimization state
    const optimizationState = {
        renderMode: 'auto', // 'svg', 'canvas', 'webgl', 'auto'
        nodeThreshold: 100, // Switch to canvas above this threshold
        webglThreshold: 500, // Switch to WebGL above this threshold
        lodEnabled: true, // Level of Detail rendering
        virtualScrollEnabled: true,
        spatialIndex: null, // Quadtree for spatial indexing
        renderQueue: [],
        frameTime: 16, // Target 60fps
        lastRenderTime: 0,
        visibleNodes: new Set(),
        culledNodes: new Set(),
        nodeCache: new Map(),
        metrics: {
            nodeCount: 0,
            visibleCount: 0,
            culledCount: 0,
            fps: 0,
            renderTime: 0,
            lastUpdate: Date.now()
        }
    };

    /**
     * Initialize Quadtree for spatial indexing
     */
    function initializeQuadtree(nodes, bounds) {
        console.log('🌳 Initializing Quadtree spatial index...');
        
        // Create quadtree with D3
        const quadtree = d3.quadtree()
            .x(d => d.x)
            .y(d => d.y)
            .extent([
                [bounds.minX, bounds.minY],
                [bounds.maxX, bounds.maxY]
            ]);
        
        // Add all nodes to quadtree
        nodes.forEach(node => {
            quadtree.add(node);
        });
        
        optimizationState.spatialIndex = quadtree;
        console.log(`✅ Quadtree initialized with ${nodes.length} nodes`);
        
        return quadtree;
    }

    /**
     * Viewport culling - only render visible nodes
     */
    function performViewportCulling(nodes, viewport) {
        const visible = new Set();
        const culled = new Set();
        
        // Add padding to viewport for smooth scrolling
        const padding = 100;
        const expandedViewport = {
            left: viewport.left - padding,
            right: viewport.right + padding,
            top: viewport.top - padding,
            bottom: viewport.bottom + padding
        };
        
        nodes.forEach(node => {
            if (node.x >= expandedViewport.left && 
                node.x <= expandedViewport.right &&
                node.y >= expandedViewport.top && 
                node.y <= expandedViewport.bottom) {
                visible.add(node.id);
            } else {
                culled.add(node.id);
            }
        });
        
        optimizationState.visibleNodes = visible;
        optimizationState.culledNodes = culled;
        
        // Update metrics
        optimizationState.metrics.visibleCount = visible.size;
        optimizationState.metrics.culledCount = culled.size;
        
        return { visible, culled };
    }

    /**
     * Level of Detail (LOD) rendering
     */
    function applyLevelOfDetail(nodes, zoomLevel) {
        const lodLevels = {
            high: { minZoom: 1.5, showLabels: true, showDetails: true, nodeSize: 1 },
            medium: { minZoom: 0.8, showLabels: true, showDetails: false, nodeSize: 0.8 },
            low: { minZoom: 0.3, showLabels: false, showDetails: false, nodeSize: 0.6 },
            minimal: { minZoom: 0, showLabels: false, showDetails: false, nodeSize: 0.4 }
        };
        
        let currentLOD = 'minimal';
        for (const [level, config] of Object.entries(lodLevels)) {
            if (zoomLevel >= config.minZoom) {
                currentLOD = level;
            }
        }
        
        const lodConfig = lodLevels[currentLOD];
        
        // Apply LOD to nodes
        nodes.forEach(node => {
            node.lodLevel = currentLOD;
            node.showLabel = lodConfig.showLabels;
            node.showDetails = lodConfig.showDetails;
            node.renderSize = node.baseSize * lodConfig.nodeSize;
        });
        
        console.log(`📊 LOD Level: ${currentLOD} (zoom: ${zoomLevel.toFixed(2)})`);
        return currentLOD;
    }

    /**
     * Canvas-based rendering for large datasets
     */
    function setupCanvasRenderer(container, width, height) {
        console.log('🎨 Setting up Canvas renderer for large-scale visualization...');
        
        // Create or get canvas element
        let canvas = container.select('canvas.large-scale-canvas');
        if (canvas.empty()) {
            canvas = container.append('canvas')
                .attr('class', 'large-scale-canvas')
                .style('position', 'absolute')
                .style('top', 0)
                .style('left', 0);
        }
        
        canvas
            .attr('width', width)
            .attr('height', height);
        
        const context = canvas.node().getContext('2d');
        
        // Enable image smoothing for better quality
        context.imageSmoothingEnabled = true;
        context.imageSmoothingQuality = 'high';
        
        return { canvas, context };
    }

    /**
     * WebGL renderer for ultra-large datasets (500+ nodes)
     */
    function setupWebGLRenderer(container, width, height) {
        console.log('🚀 Setting up WebGL renderer for ultra-large scale...');
        
        // Create WebGL canvas
        let glCanvas = container.select('canvas.webgl-canvas');
        if (glCanvas.empty()) {
            glCanvas = container.append('canvas')
                .attr('class', 'webgl-canvas')
                .style('position', 'absolute')
                .style('top', 0)
                .style('left', 0);
        }
        
        glCanvas
            .attr('width', width)
            .attr('height', height);
        
        const gl = glCanvas.node().getContext('webgl2') || glCanvas.node().getContext('webgl');
        
        if (!gl) {
            console.warn('⚠️ WebGL not supported, falling back to Canvas');
            return null;
        }
        
        // Initialize WebGL context
        gl.clearColor(0.0, 0.0, 0.0, 0.0);
        gl.enable(gl.BLEND);
        gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
        
        return { glCanvas, gl };
    }

    /**
     * Render nodes using Canvas API
     */
    function renderNodesCanvas(context, nodes, links, transform) {
        const startTime = performance.now();
        
        // Clear canvas
        context.save();
        context.clearRect(0, 0, context.canvas.width, context.canvas.height);
        
        // Apply zoom transform
        if (transform) {
            context.translate(transform.x, transform.y);
            context.scale(transform.k, transform.k);
        }
        
        // Render links first (lower z-index)
        context.globalAlpha = 0.6;
        links.forEach(link => {
            // Skip if both nodes are culled
            if (optimizationState.culledNodes.has(link.source.id) && 
                optimizationState.culledNodes.has(link.target.id)) {
                return;
            }
            
            context.beginPath();
            context.moveTo(link.source.x, link.source.y);
            context.lineTo(link.target.x, link.target.y);
            context.strokeStyle = '#999';
            context.lineWidth = link.strength || 1;
            context.stroke();
        });
        
        // Render nodes
        context.globalAlpha = 1.0;
        nodes.forEach(node => {
            // Skip culled nodes
            if (optimizationState.culledNodes.has(node.id)) {
                return;
            }
            
            // Draw node circle
            context.beginPath();
            context.arc(node.x, node.y, node.renderSize || 5, 0, 2 * Math.PI);
            context.fillStyle = node.color || '#69b3a2';
            context.fill();
            context.strokeStyle = '#fff';
            context.lineWidth = 1;
            context.stroke();
            
            // Draw label if LOD allows
            if (node.showLabel && transform && transform.k > 0.8) {
                context.fillStyle = '#fff';
                context.font = `${10 / transform.k}px Arial`;
                context.textAlign = 'center';
                context.fillText(node.label || node.id, node.x, node.y - 8);
            }
        });
        
        context.restore();
        
        // Update performance metrics
        const renderTime = performance.now() - startTime;
        optimizationState.metrics.renderTime = renderTime;
        optimizationState.metrics.fps = 1000 / renderTime;
        
        return renderTime;
    }

    /**
     * Progressive loading for large datasets
     */
    async function progressiveLoadData(dataUrl, chunkSize = 50) {
        console.log('📦 Starting progressive data loading...');
        
        const chunks = [];
        let loadedNodes = 0;
        
        try {
            const response = await fetch(dataUrl);
            const data = await response.json();
            
            // Split nodes into chunks
            const nodeChunks = [];
            for (let i = 0; i < data.nodes.length; i += chunkSize) {
                nodeChunks.push(data.nodes.slice(i, i + chunkSize));
            }
            
            // Load chunks progressively
            for (const chunk of nodeChunks) {
                chunks.push(chunk);
                loadedNodes += chunk.length;
                
                // Dispatch progress event
                document.dispatchEvent(new CustomEvent('progressiveLoadProgress', {
                    detail: {
                        loaded: loadedNodes,
                        total: data.nodes.length,
                        percentage: (loadedNodes / data.nodes.length) * 100
                    }
                }));
                
                // Small delay to prevent blocking
                await new Promise(resolve => setTimeout(resolve, 10));
            }
            
            console.log(`✅ Progressive loading complete: ${loadedNodes} nodes`);
            return { nodes: data.nodes, links: data.links, chunks };
            
        } catch (error) {
            console.error('❌ Progressive loading error:', error);
            return null;
        }
    }

    /**
     * Data virtualization for ultra-large datasets
     */
    class VirtualizedDataManager {
        constructor(pageSize = 100) {
            this.pageSize = pageSize;
            this.pages = new Map();
            this.activePages = new Set();
            this.totalNodes = 0;
        }
        
        loadPage(pageIndex, nodes) {
            const start = pageIndex * this.pageSize;
            const end = Math.min(start + this.pageSize, nodes.length);
            const pageNodes = nodes.slice(start, end);
            
            this.pages.set(pageIndex, pageNodes);
            this.activePages.add(pageIndex);
            
            // Evict old pages if memory limit reached (keep max 10 pages)
            if (this.pages.size > 10) {
                const oldestPage = Math.min(...this.activePages);
                this.pages.delete(oldestPage);
                this.activePages.delete(oldestPage);
            }
            
            return pageNodes;
        }
        
        getVisibleNodes(viewport, allNodes) {
            const visibleNodes = [];
            const pagesToLoad = new Set();
            
            // Determine which pages contain visible nodes
            allNodes.forEach((node, index) => {
                if (this.isNodeVisible(node, viewport)) {
                    const pageIndex = Math.floor(index / this.pageSize);
                    pagesToLoad.add(pageIndex);
                }
            });
            
            // Load required pages
            pagesToLoad.forEach(pageIndex => {
                if (!this.pages.has(pageIndex)) {
                    this.loadPage(pageIndex, allNodes);
                }
                const pageNodes = this.pages.get(pageIndex);
                if (pageNodes) {
                    visibleNodes.push(...pageNodes);
                }
            });
            
            return visibleNodes;
        }
        
        isNodeVisible(node, viewport) {
            return node.x >= viewport.left && 
                   node.x <= viewport.right &&
                   node.y >= viewport.top && 
                   node.y <= viewport.bottom;
        }
    }

    /**
     * Auto-detect and switch render mode based on node count
     */
    function autoDetectRenderMode(nodeCount) {
        let mode = 'svg';
        
        if (nodeCount > optimizationState.webglThreshold) {
            mode = 'webgl';
        } else if (nodeCount > optimizationState.nodeThreshold) {
            mode = 'canvas';
        }
        
        if (mode !== optimizationState.renderMode) {
            console.log(`🔄 Switching render mode: ${optimizationState.renderMode} → ${mode} (${nodeCount} nodes)`);
            optimizationState.renderMode = mode;
            
            // Dispatch mode change event
            document.dispatchEvent(new CustomEvent('renderModeChanged', {
                detail: { mode, nodeCount }
            }));
        }
        
        return mode;
    }

    /**
     * Performance monitoring and metrics
     */
    class PerformanceMonitor {
        constructor() {
            this.samples = [];
            this.maxSamples = 60;
            this.warningThreshold = 30; // fps
        }
        
        recordFrame(renderTime) {
            const fps = 1000 / renderTime;
            this.samples.push({
                timestamp: Date.now(),
                renderTime,
                fps
            });
            
            // Keep only recent samples
            if (this.samples.length > this.maxSamples) {
                this.samples.shift();
            }
            
            // Calculate averages
            const avgFps = this.samples.reduce((sum, s) => sum + s.fps, 0) / this.samples.length;
            const avgRenderTime = this.samples.reduce((sum, s) => sum + s.renderTime, 0) / this.samples.length;
            
            // Emit warning if performance is poor
            if (avgFps < this.warningThreshold) {
                console.warn(`⚠️ Performance warning: ${avgFps.toFixed(1)} FPS`);
                document.dispatchEvent(new CustomEvent('performanceWarning', {
                    detail: { avgFps, avgRenderTime }
                }));
            }
            
            return { avgFps, avgRenderTime };
        }
        
        getMetrics() {
            if (this.samples.length === 0) return null;
            
            const recent = this.samples.slice(-10);
            return {
                currentFps: recent[recent.length - 1].fps,
                avgFps: recent.reduce((sum, s) => sum + s.fps, 0) / recent.length,
                minFps: Math.min(...recent.map(s => s.fps)),
                maxFps: Math.max(...recent.map(s => s.fps))
            };
        }
    }

    // Initialize performance monitor
    const perfMonitor = new PerformanceMonitor();

    /**
     * Initialize large-scale optimization
     */
    function initializeLargeScaleOptimization(container, data) {
        console.log('🚀 Initializing large-scale visualization optimization...');
        
        const bounds = {
            minX: d3.min(data.nodes, d => d.x) - 100,
            maxX: d3.max(data.nodes, d => d.x) + 100,
            minY: d3.min(data.nodes, d => d.y) - 100,
            maxY: d3.max(data.nodes, d => d.y) + 100
        };
        
        // Initialize spatial index
        initializeQuadtree(data.nodes, bounds);
        
        // Auto-detect render mode
        const renderMode = autoDetectRenderMode(data.nodes.length);
        
        // Setup appropriate renderer
        const width = container.node().clientWidth;
        const height = container.node().clientHeight;
        
        let renderer = null;
        if (renderMode === 'webgl') {
            renderer = setupWebGLRenderer(container, width, height);
            if (!renderer) {
                // Fallback to canvas if WebGL not available
                renderer = setupCanvasRenderer(container, width, height);
            }
        } else if (renderMode === 'canvas') {
            renderer = setupCanvasRenderer(container, width, height);
        }
        
        // Initialize data virtualization for ultra-large datasets
        const dataManager = new VirtualizedDataManager();
        
        // Setup viewport culling
        const viewport = {
            left: 0,
            right: width,
            top: 0,
            bottom: height
        };
        
        performViewportCulling(data.nodes, viewport);
        
        console.log('✅ Large-scale optimization initialized');
        console.log(`📊 Stats: ${data.nodes.length} nodes, ${optimizationState.visibleNodes.size} visible, ${optimizationState.culledNodes.size} culled`);
        
        return {
            renderer,
            dataManager,
            perfMonitor,
            spatialIndex: optimizationState.spatialIndex
        };
    }

    // Public API
    window.LargeScaleOptimizer = {
        initialize: initializeLargeScaleOptimization,
        performViewportCulling,
        applyLevelOfDetail,
        renderNodesCanvas,
        progressiveLoadData,
        autoDetectRenderMode,
        VirtualizedDataManager,
        PerformanceMonitor,
        getMetrics: () => optimizationState.metrics,
        setThresholds: (nodeThreshold, webglThreshold) => {
            optimizationState.nodeThreshold = nodeThreshold;
            optimizationState.webglThreshold = webglThreshold;
        }
    };

    console.log('✅ Large-Scale Optimizer module loaded');
})();