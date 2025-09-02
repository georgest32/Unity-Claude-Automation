/**
 * Advanced Layout Algorithms for D3.js Visualization
 * Implements tree, cluster, radial, and hybrid layouts
 * Part of Day 8 Hour 3-4 Implementation
 */

(function() {
    'use strict';

    // Layout configuration state
    const layoutState = {
        currentLayout: 'force',
        previousLayout: null,
        animationDuration: 750,
        animationEasing: d3.easeCubicInOut,
        layouts: {
            force: null,
            tree: null,
            cluster: null,
            radial: null,
            hierarchical: null,
            circular: null
        },
        nodePositions: new Map(), // Store positions for smooth transitions
        hierarchyRoot: null,
        layoutMetrics: {
            depth: 0,
            breadth: 0,
            nodeCount: 0,
            leafCount: 0
        }
    };

    /**
     * Tree Layout - Hierarchical dependency visualization
     */
    function createTreeLayout(nodes, links, container) {
        console.log('🌳 Creating tree layout...');
        
        // Build hierarchy from flat data
        const hierarchy = buildHierarchy(nodes, links);
        
        // Create D3 tree layout
        const width = container.node().clientWidth;
        const height = container.node().clientHeight;
        
        const treeLayout = d3.tree()
            .size([width - 100, height - 100])
            .separation((a, b) => (a.parent === b.parent ? 1 : 2) / a.depth);
        
        // Apply layout to hierarchy
        const root = d3.hierarchy(hierarchy);
        treeLayout(root);
        
        // Store positions
        root.descendants().forEach(d => {
            const node = nodes.find(n => n.id === d.data.id);
            if (node) {
                layoutState.nodePositions.set(node.id, {
                    x: d.x + 50,
                    y: d.y + 50,
                    depth: d.depth
                });
            }
        });
        
        // Update metrics
        layoutState.layoutMetrics.depth = root.height;
        layoutState.layoutMetrics.breadth = root.leaves().length;
        
        console.log(`✅ Tree layout created: depth=${root.height}, leaves=${root.leaves().length}`);
        return root;
    }

    /**
     * Cluster Layout - Grouped visualization for modules
     */
    function createClusterLayout(nodes, links, container) {
        console.log('🎯 Creating cluster layout...');
        
        // Detect clusters using community detection
        const clusters = detectCommunities(nodes, links);
        
        const width = container.node().clientWidth;
        const height = container.node().clientHeight;
        
        // Create cluster centers
        const clusterCenters = new Map();
        const angleStep = (2 * Math.PI) / clusters.size;
        let angle = 0;
        
        clusters.forEach((cluster, clusterId) => {
            const centerX = width / 2 + Math.cos(angle) * (Math.min(width, height) / 3);
            const centerY = height / 2 + Math.sin(angle) * (Math.min(width, height) / 3);
            
            clusterCenters.set(clusterId, { x: centerX, y: centerY });
            angle += angleStep;
            
            // Position nodes within cluster
            const clusterNodes = Array.from(cluster);
            const clusterAngleStep = (2 * Math.PI) / clusterNodes.length;
            let nodeAngle = 0;
            
            clusterNodes.forEach((nodeId, index) => {
                const node = nodes.find(n => n.id === nodeId);
                if (node) {
                    const radius = 50 + (index % 3) * 20; // Vary radius for better distribution
                    layoutState.nodePositions.set(nodeId, {
                        x: centerX + Math.cos(nodeAngle) * radius,
                        y: centerY + Math.sin(nodeAngle) * radius,
                        cluster: clusterId
                    });
                    nodeAngle += clusterAngleStep;
                }
            });
        });
        
        console.log(`✅ Cluster layout created: ${clusters.size} clusters`);
        return { clusters, centers: clusterCenters };
    }

    /**
     * Radial Layout - Centered hierarchical visualization
     */
    function createRadialLayout(nodes, links, container) {
        console.log('☀️ Creating radial layout...');
        
        const width = container.node().clientWidth;
        const height = container.node().clientHeight;
        const centerX = width / 2;
        const centerY = height / 2;
        
        // Build hierarchy
        const hierarchy = buildHierarchy(nodes, links);
        const root = d3.hierarchy(hierarchy);
        
        // Create radial tree layout
        const radialLayout = d3.tree()
            .size([2 * Math.PI, Math.min(width, height) / 2 - 100])
            .separation((a, b) => (a.parent === b.parent ? 1 : 2) / a.depth);
        
        radialLayout(root);
        
        // Convert to Cartesian coordinates
        root.descendants().forEach(d => {
            const angle = d.x;
            const radius = d.y;
            
            const node = nodes.find(n => n.id === d.data.id);
            if (node) {
                layoutState.nodePositions.set(node.id, {
                    x: centerX + radius * Math.cos(angle - Math.PI / 2),
                    y: centerY + radius * Math.sin(angle - Math.PI / 2),
                    angle: angle,
                    radius: radius,
                    depth: d.depth
                });
            }
        });
        
        console.log(`✅ Radial layout created: ${root.descendants().length} nodes`);
        return root;
    }

    /**
     * Hierarchical Layout - Layered graph drawing (Sugiyama)
     */
    function createHierarchicalLayout(nodes, links, container) {
        console.log('📊 Creating hierarchical layout...');
        
        const width = container.node().clientWidth;
        const height = container.node().clientHeight;
        
        // Assign layers using longest path algorithm
        const layers = assignLayers(nodes, links);
        const maxLayer = Math.max(...layers.values());
        
        // Create layer groups
        const layerGroups = new Map();
        for (let i = 0; i <= maxLayer; i++) {
            layerGroups.set(i, []);
        }
        
        // Group nodes by layer
        nodes.forEach(node => {
            const layer = layers.get(node.id) || 0;
            layerGroups.get(layer).push(node);
        });
        
        // Position nodes
        const layerHeight = height / (maxLayer + 2);
        
        layerGroups.forEach((layerNodes, layer) => {
            const layerWidth = width / (layerNodes.length + 1);
            
            layerNodes.forEach((node, index) => {
                layoutState.nodePositions.set(node.id, {
                    x: layerWidth * (index + 1),
                    y: layerHeight * (layer + 1),
                    layer: layer
                });
            });
        });
        
        // Minimize edge crossings using barycentric method
        for (let iteration = 0; iteration < 10; iteration++) {
            minimizeEdgeCrossings(layerGroups, links);
        }
        
        console.log(`✅ Hierarchical layout created: ${maxLayer + 1} layers`);
        return { layers: layerGroups, maxLayer };
    }

    /**
     * Circular Layout - Nodes arranged in a circle
     */
    function createCircularLayout(nodes, links, container) {
        console.log('⭕ Creating circular layout...');
        
        const width = container.node().clientWidth;
        const height = container.node().clientHeight;
        const centerX = width / 2;
        const centerY = height / 2;
        const radius = Math.min(width, height) / 2 - 50;
        
        // Sort nodes by connectivity for better edge bundling
        const sortedNodes = [...nodes].sort((a, b) => {
            const aConnections = links.filter(l => l.source === a.id || l.target === a.id).length;
            const bConnections = links.filter(l => l.source === b.id || l.target === b.id).length;
            return bConnections - aConnections;
        });
        
        const angleStep = (2 * Math.PI) / nodes.length;
        
        sortedNodes.forEach((node, index) => {
            const angle = index * angleStep;
            layoutState.nodePositions.set(node.id, {
                x: centerX + radius * Math.cos(angle),
                y: centerY + radius * Math.sin(angle),
                angle: angle,
                index: index
            });
        });
        
        console.log(`✅ Circular layout created: ${nodes.length} nodes`);
        return { center: { x: centerX, y: centerY }, radius };
    }

    /**
     * Hybrid Layout - Combine force-directed with hierarchical constraints
     */
    function createHybridLayout(nodes, links, container) {
        console.log('🔄 Creating hybrid layout...');
        
        const width = container.node().clientWidth;
        const height = container.node().clientHeight;
        
        // First apply hierarchical layout for initial positions
        const layers = assignLayers(nodes, links);
        const maxLayer = Math.max(...layers.values());
        const layerHeight = height / (maxLayer + 2);
        
        // Set initial positions based on layers
        nodes.forEach(node => {
            const layer = layers.get(node.id) || 0;
            const layerY = layerHeight * (layer + 1);
            
            // Add some randomness to X position within layer
            const layerX = Math.random() * width;
            
            layoutState.nodePositions.set(node.id, {
                x: layerX,
                y: layerY,
                layer: layer,
                fx: null, // Allow X movement
                fy: layerY // Fix Y to layer
            });
        });
        
        // Create force simulation with layer constraints
        const simulation = d3.forceSimulation(nodes)
            .force('link', d3.forceLink(links).id(d => d.id).distance(50))
            .force('charge', d3.forceManyBody().strength(-100))
            .force('x', d3.forceX(width / 2).strength(0.1))
            .force('layer', function() {
                // Custom force to maintain layer positions
                return alpha => {
                    nodes.forEach(node => {
                        const pos = layoutState.nodePositions.get(node.id);
                        if (pos && pos.fy !== undefined) {
                            node.y += (pos.fy - node.y) * alpha * 0.1;
                        }
                    });
                };
            })
            .stop();
        
        // Run simulation for a fixed number of iterations
        for (let i = 0; i < 100; i++) {
            simulation.tick();
        }
        
        // Update positions after simulation
        nodes.forEach(node => {
            const pos = layoutState.nodePositions.get(node.id);
            if (pos) {
                pos.x = node.x;
                pos.y = node.y;
            }
        });
        
        console.log(`✅ Hybrid layout created: ${maxLayer + 1} layers with force-directed positioning`);
        return { simulation, layers };
    }

    /**
     * Smooth animated transition between layouts
     */
    function transitionToLayout(nodes, targetLayout, duration = 750) {
        console.log(`🎬 Transitioning to ${targetLayout} layout...`);
        
        const startPositions = new Map();
        nodes.forEach(node => {
            startPositions.set(node.id, { x: node.x, y: node.y });
        });
        
        const endPositions = layoutState.nodePositions;
        
        // Create transition
        const t = d3.transition()
            .duration(duration)
            .ease(layoutState.animationEasing);
        
        // Animate nodes
        d3.selectAll('.node')
            .data(nodes, d => d.id)
            .transition(t)
            .attrTween('transform', function(d) {
                const start = startPositions.get(d.id) || { x: 0, y: 0 };
                const end = endPositions.get(d.id) || { x: 0, y: 0 };
                
                const interpolateX = d3.interpolate(start.x, end.x);
                const interpolateY = d3.interpolate(start.y, end.y);
                
                return function(t) {
                    d.x = interpolateX(t);
                    d.y = interpolateY(t);
                    return `translate(${d.x},${d.y})`;
                };
            });
        
        // Animate links
        d3.selectAll('.link')
            .transition(t)
            .attrTween('d', function(d) {
                return function(t) {
                    const source = nodes.find(n => n.id === d.source.id || n.id === d.source);
                    const target = nodes.find(n => n.id === d.target.id || n.id === d.target);
                    
                    if (source && target) {
                        return `M${source.x},${source.y}L${target.x},${target.y}`;
                    }
                    return '';
                };
            });
        
        // Update state
        layoutState.previousLayout = layoutState.currentLayout;
        layoutState.currentLayout = targetLayout;
        
        // Dispatch event
        document.dispatchEvent(new CustomEvent('layoutTransitionComplete', {
            detail: { 
                from: layoutState.previousLayout, 
                to: targetLayout,
                duration: duration
            }
        }));
        
        return t;
    }

    /**
     * Helper: Build hierarchy from flat node/link data
     */
    function buildHierarchy(nodes, links) {
        // Find root nodes (no incoming edges)
        const hasIncoming = new Set(links.map(l => l.target.id || l.target));
        const roots = nodes.filter(n => !hasIncoming.has(n.id));
        
        if (roots.length === 0) {
            // If no clear root, pick node with most outgoing connections
            const outgoingCount = new Map();
            nodes.forEach(n => outgoingCount.set(n.id, 0));
            links.forEach(l => {
                const sourceId = l.source.id || l.source;
                outgoingCount.set(sourceId, (outgoingCount.get(sourceId) || 0) + 1);
            });
            
            const maxOutgoing = Math.max(...outgoingCount.values());
            const root = nodes.find(n => outgoingCount.get(n.id) === maxOutgoing);
            roots.push(root);
        }
        
        // Build tree structure
        function buildSubtree(nodeId, visited = new Set()) {
            if (visited.has(nodeId)) return null;
            visited.add(nodeId);
            
            const node = nodes.find(n => n.id === nodeId);
            if (!node) return null;
            
            const children = links
                .filter(l => (l.source.id || l.source) === nodeId)
                .map(l => l.target.id || l.target)
                .map(childId => buildSubtree(childId, visited))
                .filter(child => child !== null);
            
            return {
                id: node.id,
                name: node.label || node.id,
                value: node.value || 1,
                children: children.length > 0 ? children : undefined
            };
        }
        
        // If multiple roots, create artificial super-root
        if (roots.length === 1) {
            return buildSubtree(roots[0].id);
        } else {
            return {
                id: 'root',
                name: 'Root',
                children: roots.map(r => buildSubtree(r.id))
            };
        }
    }

    /**
     * Helper: Community detection using Louvain algorithm (simplified)
     */
    function detectCommunities(nodes, links) {
        const communities = new Map();
        const nodeCommunity = new Map();
        
        // Initialize: each node in its own community
        nodes.forEach((node, index) => {
            communities.set(index, new Set([node.id]));
            nodeCommunity.set(node.id, index);
        });
        
        // Build adjacency list
        const adjacency = new Map();
        nodes.forEach(n => adjacency.set(n.id, new Set()));
        links.forEach(link => {
            const sourceId = link.source.id || link.source;
            const targetId = link.target.id || link.target;
            adjacency.get(sourceId).add(targetId);
            adjacency.get(targetId).add(sourceId);
        });
        
        // Simple community merging based on edge density
        let changed = true;
        let iterations = 0;
        while (changed && iterations < 10) {
            changed = false;
            iterations++;
            
            nodes.forEach(node => {
                const neighbors = adjacency.get(node.id);
                const currentCommunity = nodeCommunity.get(node.id);
                
                // Count connections to each community
                const communityConnections = new Map();
                neighbors.forEach(neighborId => {
                    const neighborCommunity = nodeCommunity.get(neighborId);
                    communityConnections.set(
                        neighborCommunity,
                        (communityConnections.get(neighborCommunity) || 0) + 1
                    );
                });
                
                // Move to community with most connections
                let maxConnections = 0;
                let bestCommunity = currentCommunity;
                
                communityConnections.forEach((connections, community) => {
                    if (connections > maxConnections) {
                        maxConnections = connections;
                        bestCommunity = community;
                    }
                });
                
                if (bestCommunity !== currentCommunity) {
                    // Move node to new community
                    communities.get(currentCommunity).delete(node.id);
                    communities.get(bestCommunity).add(node.id);
                    nodeCommunity.set(node.id, bestCommunity);
                    changed = true;
                }
            });
        }
        
        // Remove empty communities
        const finalCommunities = new Map();
        let communityId = 0;
        communities.forEach(members => {
            if (members.size > 0) {
                finalCommunities.set(communityId++, members);
            }
        });
        
        return finalCommunities;
    }

    /**
     * Helper: Assign layers for hierarchical layout
     */
    function assignLayers(nodes, links) {
        const layers = new Map();
        const inDegree = new Map();
        
        // Calculate in-degree for each node
        nodes.forEach(n => inDegree.set(n.id, 0));
        links.forEach(link => {
            const targetId = link.target.id || link.target;
            inDegree.set(targetId, (inDegree.get(targetId) || 0) + 1);
        });
        
        // Assign layers using topological sort
        const queue = [];
        nodes.forEach(node => {
            if (inDegree.get(node.id) === 0) {
                queue.push(node.id);
                layers.set(node.id, 0);
            }
        });
        
        while (queue.length > 0) {
            const nodeId = queue.shift();
            const currentLayer = layers.get(nodeId) || 0;
            
            links.forEach(link => {
                const sourceId = link.source.id || link.source;
                const targetId = link.target.id || link.target;
                
                if (sourceId === nodeId) {
                    const newInDegree = inDegree.get(targetId) - 1;
                    inDegree.set(targetId, newInDegree);
                    
                    if (newInDegree === 0) {
                        queue.push(targetId);
                        layers.set(targetId, currentLayer + 1);
                    }
                }
            });
        }
        
        // Handle cycles: assign remaining nodes to last layer + 1
        const maxLayer = Math.max(...layers.values());
        nodes.forEach(node => {
            if (!layers.has(node.id)) {
                layers.set(node.id, maxLayer + 1);
            }
        });
        
        return layers;
    }

    /**
     * Helper: Minimize edge crossings in hierarchical layout
     */
    function minimizeEdgeCrossings(layerGroups, links) {
        layerGroups.forEach((layerNodes, layer) => {
            if (layer === 0) return; // Skip first layer
            
            // Calculate barycentric positions
            const barycenters = new Map();
            
            layerNodes.forEach(node => {
                const connectedNodes = [];
                links.forEach(link => {
                    const sourceId = link.source.id || link.source;
                    const targetId = link.target.id || link.target;
                    
                    if (targetId === node.id) {
                        const sourcePos = layoutState.nodePositions.get(sourceId);
                        if (sourcePos) {
                            connectedNodes.push(sourcePos.x);
                        }
                    }
                });
                
                if (connectedNodes.length > 0) {
                    const avgX = connectedNodes.reduce((sum, x) => sum + x, 0) / connectedNodes.length;
                    barycenters.set(node.id, avgX);
                }
            });
            
            // Sort nodes by barycenter
            layerNodes.sort((a, b) => {
                const aBarycenter = barycenters.get(a.id) || layoutState.nodePositions.get(a.id).x;
                const bBarycenter = barycenters.get(b.id) || layoutState.nodePositions.get(b.id).x;
                return aBarycenter - bBarycenter;
            });
            
            // Update positions
            const width = layerNodes.length > 1 ? 
                (layoutState.nodePositions.get(layerNodes[0].id).x * 2) : 100;
            const spacing = width / (layerNodes.length + 1);
            
            layerNodes.forEach((node, index) => {
                const pos = layoutState.nodePositions.get(node.id);
                if (pos) {
                    pos.x = spacing * (index + 1);
                }
            });
        });
    }

    /**
     * Apply layout to nodes and links
     */
    function applyLayout(layoutType, nodes, links, container) {
        console.log(`📐 Applying ${layoutType} layout...`);
        
        let result = null;
        
        switch (layoutType) {
            case 'tree':
                result = createTreeLayout(nodes, links, container);
                break;
            case 'cluster':
                result = createClusterLayout(nodes, links, container);
                break;
            case 'radial':
                result = createRadialLayout(nodes, links, container);
                break;
            case 'hierarchical':
                result = createHierarchicalLayout(nodes, links, container);
                break;
            case 'circular':
                result = createCircularLayout(nodes, links, container);
                break;
            case 'hybrid':
                result = createHybridLayout(nodes, links, container);
                break;
            default:
                console.warn(`Unknown layout type: ${layoutType}`);
                return null;
        }
        
        // Apply positions to nodes
        nodes.forEach(node => {
            const pos = layoutState.nodePositions.get(node.id);
            if (pos) {
                node.x = pos.x;
                node.y = pos.y;
                
                // Store additional layout-specific data
                Object.keys(pos).forEach(key => {
                    if (key !== 'x' && key !== 'y') {
                        node[`layout_${key}`] = pos[key];
                    }
                });
            }
        });
        
        return result;
    }

    // Public API
    window.AdvancedLayoutAlgorithms = {
        applyLayout,
        transitionToLayout,
        createTreeLayout,
        createClusterLayout,
        createRadialLayout,
        createHierarchicalLayout,
        createCircularLayout,
        createHybridLayout,
        getCurrentLayout: () => layoutState.currentLayout,
        getLayoutMetrics: () => layoutState.layoutMetrics,
        setAnimationDuration: (duration) => {
            layoutState.animationDuration = duration;
        },
        setAnimationEasing: (easing) => {
            layoutState.animationEasing = easing;
        }
    };

    console.log('✅ Advanced Layout Algorithms module loaded');
})();