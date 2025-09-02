/**
 * Visualization Filters and Perspectives
 * Multi-criteria filtering and preset visualization perspectives
 * Part of Day 8 Hour 5-6 Implementation
 */

(function() {
    'use strict';

    // Filter and perspective state
    const filterState = {
        activeFilters: new Map(),
        perspectives: new Map(),
        currentPerspective: 'default',
        filterHistory: [],
        maxHistorySize: 20,
        highlightMode: 'none', // 'none', 'dependencies', 'impact', 'module'
        focusedNode: null,
        hiddenNodes: new Set(),
        hiddenLinks: new Set(),
        moduleGroups: new Map(),
        filterMetrics: {
            totalNodes: 0,
            visibleNodes: 0,
            totalLinks: 0,
            visibleLinks: 0
        }
    };

    /**
     * Define preset perspectives
     */
    function initializePerspectives() {
        console.log('🔍 Initializing visualization perspectives...');
        
        // Architecture Overview
        filterState.perspectives.set('architecture', {
            name: 'Architecture Overview',
            description: 'High-level module structure',
            filters: {
                nodeType: ['module', 'package'],
                minConnections: 3,
                showLabels: true,
                groupByModule: true,
                layout: 'hierarchical'
            },
            highlight: 'module',
            zoom: 0.8
        });
        
        // Dependency Analysis
        filterState.perspectives.set('dependencies', {
            name: 'Dependency Analysis',
            description: 'Focus on dependency relationships',
            filters: {
                linkType: ['import', 'require', 'depends'],
                showDirectOnly: false,
                highlightCycles: true,
                layout: 'tree'
            },
            highlight: 'dependencies',
            zoom: 1.0
        });
        
        // Performance Hotspots
        filterState.perspectives.set('performance', {
            name: 'Performance Hotspots',
            description: 'Identify performance-critical paths',
            filters: {
                minComplexity: 5,
                showMetrics: true,
                highlightHotPaths: true,
                layout: 'force'
            },
            highlight: 'impact',
            zoom: 1.2
        });
        
        // Security Analysis
        filterState.perspectives.set('security', {
            name: 'Security Analysis',
            description: 'Security-sensitive components',
            filters: {
                showSensitive: true,
                highlightExternalDeps: true,
                showSecurityMetrics: true,
                layout: 'cluster'
            },
            highlight: 'security',
            zoom: 1.0
        });
        
        // Test Coverage
        filterState.perspectives.set('testing', {
            name: 'Test Coverage',
            description: 'Test coverage and quality metrics',
            filters: {
                showTestNodes: true,
                highlightUntested: true,
                showCoverageMetrics: true,
                layout: 'hierarchical'
            },
            highlight: 'coverage',
            zoom: 0.9
        });
        
        // Change Impact
        filterState.perspectives.set('impact', {
            name: 'Change Impact',
            description: 'Analyze change propagation',
            filters: {
                showImpactRadius: true,
                highlightAffected: true,
                showChangeMetrics: true,
                layout: 'radial'
            },
            highlight: 'impact',
            zoom: 1.1
        });
        
        console.log(`✅ Initialized ${filterState.perspectives.size} perspectives`);
    }

    /**
     * Multi-criteria filter system
     */
    class FilterSystem {
        constructor() {
            this.criteria = new Map();
        }
        
        addCriterion(name, predicate, options = {}) {
            this.criteria.set(name, {
                predicate,
                enabled: options.enabled !== false,
                weight: options.weight || 1.0,
                type: options.type || 'include', // 'include' or 'exclude'
                metadata: options.metadata || {}
            });
        }
        
        removeCriterion(name) {
            this.criteria.delete(name);
        }
        
        toggleCriterion(name) {
            const criterion = this.criteria.get(name);
            if (criterion) {
                criterion.enabled = !criterion.enabled;
            }
        }
        
        applyFilters(nodes, links) {
            const filteredNodes = new Set();
            const filteredLinks = new Set();
            
            // Apply node filters
            nodes.forEach(node => {
                let include = true;
                
                this.criteria.forEach((criterion, name) => {
                    if (!criterion.enabled) return;
                    
                    const result = criterion.predicate(node);
                    
                    if (criterion.type === 'include' && !result) {
                        include = false;
                    } else if (criterion.type === 'exclude' && result) {
                        include = false;
                    }
                });
                
                if (include) {
                    filteredNodes.add(node);
                } else {
                    filterState.hiddenNodes.add(node.id);
                }
            });
            
            // Apply link filters (only show links between visible nodes)
            links.forEach(link => {
                const sourceVisible = Array.from(filteredNodes).some(n => 
                    n.id === (link.source.id || link.source)
                );
                const targetVisible = Array.from(filteredNodes).some(n => 
                    n.id === (link.target.id || link.target)
                );
                
                if (sourceVisible && targetVisible) {
                    filteredLinks.add(link);
                } else {
                    filterState.hiddenLinks.add(link.id || `${link.source}-${link.target}`);
                }
            });
            
            // Update metrics
            filterState.filterMetrics.totalNodes = nodes.length;
            filterState.filterMetrics.visibleNodes = filteredNodes.size;
            filterState.filterMetrics.totalLinks = links.length;
            filterState.filterMetrics.visibleLinks = filteredLinks.size;
            
            return {
                nodes: Array.from(filteredNodes),
                links: Array.from(filteredLinks)
            };
        }
    }

    // Initialize filter system
    const filterSystem = new FilterSystem();

    /**
     * Common filter criteria
     */
    function setupCommonFilters() {
        // Node type filter
        filterSystem.addCriterion('nodeType', (node) => {
            const allowedTypes = filterState.activeFilters.get('nodeType');
            if (!allowedTypes || allowedTypes.length === 0) return true;
            return allowedTypes.includes(node.type);
        });
        
        // Minimum connections filter
        filterSystem.addCriterion('minConnections', (node) => {
            const minConn = filterState.activeFilters.get('minConnections');
            if (!minConn) return true;
            return (node.connections || 0) >= minConn;
        });
        
        // Complexity filter
        filterSystem.addCriterion('complexity', (node) => {
            const minComplexity = filterState.activeFilters.get('minComplexity');
            if (!minComplexity) return true;
            return (node.complexity || 0) >= minComplexity;
        });
        
        // Module filter
        filterSystem.addCriterion('module', (node) => {
            const modules = filterState.activeFilters.get('modules');
            if (!modules || modules.length === 0) return true;
            return modules.includes(node.module);
        });
        
        // Search filter
        filterSystem.addCriterion('search', (node) => {
            const searchTerm = filterState.activeFilters.get('search');
            if (!searchTerm) return true;
            
            const term = searchTerm.toLowerCase();
            return node.id.toLowerCase().includes(term) ||
                   (node.label && node.label.toLowerCase().includes(term)) ||
                   (node.description && node.description.toLowerCase().includes(term));
        });
        
        // Date range filter
        filterSystem.addCriterion('dateRange', (node) => {
            const range = filterState.activeFilters.get('dateRange');
            if (!range) return true;
            
            const nodeDate = new Date(node.lastModified || node.created);
            return nodeDate >= range.start && nodeDate <= range.end;
        });
    }

    /**
     * Apply perspective to visualization
     */
    function applyPerspective(perspectiveName, nodes, links, container) {
        console.log(`🎯 Applying perspective: ${perspectiveName}`);
        
        const perspective = filterState.perspectives.get(perspectiveName);
        if (!perspective) {
            console.warn(`Unknown perspective: ${perspectiveName}`);
            return;
        }
        
        // Clear existing filters
        filterState.activeFilters.clear();
        
        // Apply perspective filters
        Object.entries(perspective.filters).forEach(([key, value]) => {
            filterState.activeFilters.set(key, value);
        });
        
        // Apply highlight mode
        filterState.highlightMode = perspective.highlight;
        
        // Apply layout if specified
        if (perspective.filters.layout && window.AdvancedLayoutAlgorithms) {
            window.AdvancedLayoutAlgorithms.applyLayout(
                perspective.filters.layout,
                nodes,
                links,
                container
            );
        }
        
        // Apply zoom level
        if (perspective.zoom && container) {
            const zoom = d3.zoom();
            const transform = d3.zoomIdentity.scale(perspective.zoom);
            container.transition().duration(750).call(zoom.transform, transform);
        }
        
        // Update current perspective
        filterState.currentPerspective = perspectiveName;
        
        // Dispatch event
        document.dispatchEvent(new CustomEvent('perspectiveChanged', {
            detail: { perspective: perspectiveName, filters: perspective.filters }
        }));
        
        return perspective;
    }

    /**
     * Context-aware highlighting
     */
    function applyHighlighting(nodes, links, focusNode) {
        console.log(`💡 Applying ${filterState.highlightMode} highlighting`);
        
        const highlighted = new Set();
        const dimmed = new Set();
        
        switch (filterState.highlightMode) {
            case 'dependencies':
                highlightDependencies(focusNode, nodes, links, highlighted, dimmed);
                break;
                
            case 'impact':
                highlightImpactRadius(focusNode, nodes, links, highlighted, dimmed);
                break;
                
            case 'module':
                highlightModule(focusNode, nodes, highlighted, dimmed);
                break;
                
            case 'security':
                highlightSecurityPaths(nodes, links, highlighted, dimmed);
                break;
                
            case 'coverage':
                highlightTestCoverage(nodes, highlighted, dimmed);
                break;
                
            default:
                // No highlighting
                nodes.forEach(n => highlighted.add(n.id));
        }
        
        // Apply visual changes
        nodes.forEach(node => {
            if (highlighted.has(node.id)) {
                node.highlighted = true;
                node.dimmed = false;
            } else if (dimmed.has(node.id)) {
                node.highlighted = false;
                node.dimmed = true;
            } else {
                node.highlighted = false;
                node.dimmed = false;
            }
        });
        
        links.forEach(link => {
            const sourceId = link.source.id || link.source;
            const targetId = link.target.id || link.target;
            
            if (highlighted.has(sourceId) && highlighted.has(targetId)) {
                link.highlighted = true;
                link.dimmed = false;
            } else if (dimmed.has(sourceId) || dimmed.has(targetId)) {
                link.highlighted = false;
                link.dimmed = true;
            } else {
                link.highlighted = false;
                link.dimmed = false;
            }
        });
        
        return { highlighted, dimmed };
    }

    /**
     * Highlight dependency chain
     */
    function highlightDependencies(focusNode, nodes, links, highlighted, dimmed) {
        if (!focusNode) return;
        
        highlighted.add(focusNode.id);
        
        // Find all dependencies (upstream)
        const visited = new Set();
        const queue = [focusNode.id];
        
        while (queue.length > 0) {
            const nodeId = queue.shift();
            if (visited.has(nodeId)) continue;
            visited.add(nodeId);
            
            links.forEach(link => {
                const sourceId = link.source.id || link.source;
                const targetId = link.target.id || link.target;
                
                if (targetId === nodeId && !visited.has(sourceId)) {
                    highlighted.add(sourceId);
                    queue.push(sourceId);
                }
            });
        }
        
        // Find all dependents (downstream)
        visited.clear();
        queue.push(focusNode.id);
        
        while (queue.length > 0) {
            const nodeId = queue.shift();
            if (visited.has(nodeId)) continue;
            visited.add(nodeId);
            
            links.forEach(link => {
                const sourceId = link.source.id || link.source;
                const targetId = link.target.id || link.target;
                
                if (sourceId === nodeId && !visited.has(targetId)) {
                    highlighted.add(targetId);
                    queue.push(targetId);
                }
            });
        }
        
        // Dim all others
        nodes.forEach(node => {
            if (!highlighted.has(node.id)) {
                dimmed.add(node.id);
            }
        });
    }

    /**
     * Highlight impact radius
     */
    function highlightImpactRadius(focusNode, nodes, links, highlighted, dimmed, radius = 2) {
        if (!focusNode) return;
        
        const distances = new Map();
        distances.set(focusNode.id, 0);
        highlighted.add(focusNode.id);
        
        // BFS to find nodes within radius
        const queue = [{ id: focusNode.id, distance: 0 }];
        
        while (queue.length > 0) {
            const { id, distance } = queue.shift();
            
            if (distance >= radius) continue;
            
            links.forEach(link => {
                const sourceId = link.source.id || link.source;
                const targetId = link.target.id || link.target;
                
                let neighborId = null;
                if (sourceId === id) neighborId = targetId;
                if (targetId === id) neighborId = sourceId;
                
                if (neighborId && !distances.has(neighborId)) {
                    distances.set(neighborId, distance + 1);
                    highlighted.add(neighborId);
                    queue.push({ id: neighborId, distance: distance + 1 });
                }
            });
        }
        
        // Dim nodes outside radius
        nodes.forEach(node => {
            if (!highlighted.has(node.id)) {
                dimmed.add(node.id);
            }
        });
    }

    /**
     * Highlight module boundaries
     */
    function highlightModule(focusNode, nodes, highlighted, dimmed) {
        const targetModule = focusNode ? focusNode.module : null;
        
        nodes.forEach(node => {
            if (node.module === targetModule) {
                highlighted.add(node.id);
            } else {
                dimmed.add(node.id);
            }
        });
    }

    /**
     * Highlight security-sensitive paths
     */
    function highlightSecurityPaths(nodes, links, highlighted, dimmed) {
        // Highlight nodes with security flags
        nodes.forEach(node => {
            if (node.securitySensitive || node.external || node.untrusted) {
                highlighted.add(node.id);
            }
        });
        
        // Highlight paths between security-sensitive nodes
        const secureNodes = Array.from(highlighted);
        secureNodes.forEach(sourceId => {
            secureNodes.forEach(targetId => {
                if (sourceId === targetId) return;
                
                // Find path between secure nodes (simplified)
                const path = findPath(sourceId, targetId, links);
                if (path) {
                    path.forEach(nodeId => highlighted.add(nodeId));
                }
            });
        });
        
        // Dim all others
        nodes.forEach(node => {
            if (!highlighted.has(node.id)) {
                dimmed.add(node.id);
            }
        });
    }

    /**
     * Highlight test coverage
     */
    function highlightTestCoverage(nodes, highlighted, dimmed) {
        nodes.forEach(node => {
            if (node.coverage !== undefined) {
                if (node.coverage > 0.8) {
                    highlighted.add(node.id);
                } else if (node.coverage < 0.3) {
                    dimmed.add(node.id);
                }
            }
        });
    }

    /**
     * Find path between two nodes (simplified BFS)
     */
    function findPath(startId, endId, links) {
        const adjacency = new Map();
        links.forEach(link => {
            const sourceId = link.source.id || link.source;
            const targetId = link.target.id || link.target;
            
            if (!adjacency.has(sourceId)) adjacency.set(sourceId, []);
            if (!adjacency.has(targetId)) adjacency.set(targetId, []);
            
            adjacency.get(sourceId).push(targetId);
            adjacency.get(targetId).push(sourceId);
        });
        
        const visited = new Set();
        const queue = [{ id: startId, path: [startId] }];
        
        while (queue.length > 0) {
            const { id, path } = queue.shift();
            
            if (id === endId) {
                return path;
            }
            
            if (visited.has(id)) continue;
            visited.add(id);
            
            const neighbors = adjacency.get(id) || [];
            neighbors.forEach(neighborId => {
                if (!visited.has(neighborId)) {
                    queue.push({ id: neighborId, path: [...path, neighborId] });
                }
            });
        }
        
        return null;
    }

    /**
     * Create filter controls UI
     */
    function createFilterControls(container) {
        console.log('🎛️ Creating filter controls...');
        
        const controls = container.append('div')
            .attr('class', 'filter-controls')
            .style('position', 'absolute')
            .style('top', '10px')
            .style('left', '10px')
            .style('background', 'rgba(0, 0, 0, 0.8)')
            .style('padding', '15px')
            .style('border-radius', '5px')
            .style('color', 'white');
        
        // Perspective selector
        const perspectiveSelect = controls.append('div')
            .attr('class', 'perspective-selector');
        
        perspectiveSelect.append('label')
            .text('Perspective: ')
            .style('margin-right', '10px');
        
        const select = perspectiveSelect.append('select')
            .on('change', function() {
                const selected = this.value;
                document.dispatchEvent(new CustomEvent('perspectiveChangeRequest', {
                    detail: { perspective: selected }
                }));
            });
        
        // Add options
        select.append('option').attr('value', 'default').text('Default');
        filterState.perspectives.forEach((perspective, key) => {
            select.append('option')
                .attr('value', key)
                .text(perspective.name);
        });
        
        // Filter stats
        controls.append('div')
            .attr('class', 'filter-stats')
            .style('margin-top', '10px')
            .style('font-size', '12px')
            .html(() => {
                const metrics = filterState.filterMetrics;
                return `Showing ${metrics.visibleNodes}/${metrics.totalNodes} nodes, ${metrics.visibleLinks}/${metrics.totalLinks} links`;
            });
        
        return controls;
    }

    /**
     * Save and restore filter configurations
     */
    function saveFilterConfiguration(name) {
        const config = {
            name,
            timestamp: Date.now(),
            filters: new Map(filterState.activeFilters),
            perspective: filterState.currentPerspective,
            highlightMode: filterState.highlightMode
        };
        
        filterState.filterHistory.push(config);
        
        // Limit history size
        if (filterState.filterHistory.length > filterState.maxHistorySize) {
            filterState.filterHistory.shift();
        }
        
        return config;
    }

    function restoreFilterConfiguration(config) {
        filterState.activeFilters = new Map(config.filters);
        filterState.currentPerspective = config.perspective;
        filterState.highlightMode = config.highlightMode;
        
        document.dispatchEvent(new CustomEvent('filterConfigurationRestored', {
            detail: config
        }));
    }

    // Initialize on load
    initializePerspectives();
    setupCommonFilters();

    // Public API
    window.VisualizationFilters = {
        filterSystem,
        applyPerspective,
        applyHighlighting,
        createFilterControls,
        saveFilterConfiguration,
        restoreFilterConfiguration,
        addFilter: (name, value) => {
            filterState.activeFilters.set(name, value);
        },
        removeFilter: (name) => {
            filterState.activeFilters.delete(name);
        },
        clearFilters: () => {
            filterState.activeFilters.clear();
        },
        getMetrics: () => filterState.filterMetrics,
        getPerspectives: () => filterState.perspectives,
        setFocusNode: (node) => {
            filterState.focusedNode = node;
        }
    };

    console.log('✅ Visualization Filters and Perspectives module loaded');
})();