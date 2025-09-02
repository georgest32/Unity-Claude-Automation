/**
 * Enhanced Controls for Unity-Claude Semantic Visualization
 * Provides advanced filtering, search, and interaction capabilities
 */

class EnhancedControls {
    constructor(renderer) {
        this.renderer = renderer;
        this.initializeControls();
        this.setupEventHandlers();
    }
    
    initializeControls() {
        console.log('🎛️ Initializing enhanced controls...');
        
        // Enhanced search with real-time filtering
        this.setupAdvancedSearch();
        
        // Category filtering
        this.setupCategoryFilters();
        
        // AI Enhancement toggle
        this.setupAIToggle();
        
        // Advanced simulation controls
        this.setupSimulationControls();
        
        // Layout algorithms
        this.setupLayoutControls();
        
        // Export and sharing
        this.setupExportControls();
        
        // Performance monitoring
        this.setupPerformanceMonitor();
    }
    
    setupAdvancedSearch() {
        const searchBox = document.getElementById('search-box');
        if (!searchBox) return;
        
        let searchTimeout;
        
        // Real-time search with debouncing
        searchBox.addEventListener('input', (event) => {
            clearTimeout(searchTimeout);
            searchTimeout = setTimeout(() => {
                const query = event.target.value.trim();
                this.performAdvancedSearch(query);
            }, 300);
        });
        
        // Clear search functionality
        const clearButton = document.getElementById('clear-search');
        if (clearButton) {
            clearButton.addEventListener('click', () => {
                searchBox.value = '';
                this.renderer.searchNodes('');
                this.updateSearchStats(0, this.renderer.data?.nodes.length || 0);
            });
        }
    }
    
    performAdvancedSearch(query) {
        if (!this.renderer.data) return;
        
        if (!query) {
            this.renderer.clearHighlights();
            this.updateSearchStats(0, this.renderer.data.nodes.length);
            return;
        }
        
        const matchingNodes = this.renderer.data.nodes.filter(node => {
            return node.label.toLowerCase().includes(query.toLowerCase()) ||
                   node.fullName?.toLowerCase().includes(query.toLowerCase()) ||
                   node.category.toLowerCase().includes(query.toLowerCase()) ||
                   (node.description && node.description.toLowerCase().includes(query.toLowerCase()));
        });
        
        // Highlight matching nodes and their connections
        this.highlightSearchResults(matchingNodes);
        this.updateSearchStats(matchingNodes.length, this.renderer.data.nodes.length);
        
        // If only one result, focus on it
        if (matchingNodes.length === 1) {
            setTimeout(() => {
                this.renderer.focusOnNode(matchingNodes[0]);
            }, 500);
        }
    }
    
    highlightSearchResults(matchingNodes) {
        const matchingIds = matchingNodes.map(n => n.id);
        
        // Get all connected node IDs
        const connectedIds = new Set(matchingIds);
        this.renderer.data.links.forEach(link => {
            if (matchingIds.includes(link.source.id)) {
                connectedIds.add(link.target.id);
            }
            if (matchingIds.includes(link.target.id)) {
                connectedIds.add(link.source.id);
            }
        });
        
        // Highlight nodes
        this.renderer.nodes
            .attr('opacity', d => {
                if (matchingIds.includes(d.id)) return 1; // Direct matches: full opacity
                if (connectedIds.has(d.id)) return 0.7;   // Connected: medium opacity
                return 0.2; // Others: low opacity
            })
            .attr('stroke-width', d => matchingIds.includes(d.id) ? 4 : 
                                      d.isAIEnhanced ? 3 : 2);
        
        // Highlight links
        this.renderer.links
            .attr('stroke-opacity', d => 
                (matchingIds.includes(d.source.id) || matchingIds.includes(d.target.id)) ? 0.8 : 0.1)
            .attr('stroke-width', d => 
                (matchingIds.includes(d.source.id) || matchingIds.includes(d.target.id)) ? 
                    (d.width || 2) + 1 : (d.width || 2) * 0.5);
    }
    
    updateSearchStats(matches, total) {
        // Update or create search stats display
        let statsElement = document.getElementById('search-stats');
        if (!statsElement) {
            statsElement = document.createElement('div');
            statsElement.id = 'search-stats';
            statsElement.style.cssText = `
                font-size: 0.8em;
                color: #00ff88;
                margin-top: 5px;
                text-align: center;
            `;
            
            const searchBox = document.getElementById('search-box');
            if (searchBox?.parentElement) {
                searchBox.parentElement.appendChild(statsElement);
            }
        }
        
        if (matches === 0 && total > 0) {
            statsElement.textContent = `${matches} / ${total} nodes shown`;
        } else {
            statsElement.textContent = `${matches} matches of ${total} nodes`;
        }
    }
    
    setupCategoryFilters() {
        if (!this.renderer.categories) return;
        
        // Create category filter section
        const controlPanel = document.getElementById('control-panel');
        if (!controlPanel) return;
        
        const filterSection = document.createElement('div');
        filterSection.className = 'control-section';
        filterSection.innerHTML = '<h3>🏷️ Category Filters</h3>';
        
        // Add category toggles
        Object.entries(this.renderer.categories).forEach(([categoryName, categoryData]) => {
            const filterItem = document.createElement('div');
            filterItem.style.cssText = `
                display: flex;
                align-items: center;
                margin: 5px 0;
                padding: 5px;
                border-radius: 3px;
                background: rgba(255,255,255,0.1);
            `;
            
            const checkbox = document.createElement('input');
            checkbox.type = 'checkbox';
            checkbox.checked = true;
            checkbox.id = `filter-${categoryName}`;
            checkbox.style.marginRight = '8px';
            
            const label = document.createElement('label');
            label.htmlFor = checkbox.id;
            label.textContent = categoryName;
            label.style.cssText = `
                flex: 1;
                cursor: pointer;
                font-size: 0.9em;
            `;
            
            const colorIndicator = document.createElement('div');
            colorIndicator.style.cssText = `
                width: 12px;
                height: 12px;
                border-radius: 50%;
                background: ${categoryData.color};
                margin-left: 8px;
            `;
            
            const nodeCount = document.createElement('span');
            nodeCount.textContent = `(${categoryData.moduleCount || 0})`;
            nodeCount.style.cssText = `
                font-size: 0.8em;
                color: #888;
                margin-left: 4px;
            `;
            
            filterItem.appendChild(checkbox);
            filterItem.appendChild(label);
            filterItem.appendChild(nodeCount);
            filterItem.appendChild(colorIndicator);
            
            checkbox.addEventListener('change', () => {
                this.toggleCategoryFilter(categoryName, checkbox.checked);
            });
            
            filterSection.appendChild(filterItem);
        });
        
        // Add "All" and "None" buttons
        const buttonContainer = document.createElement('div');
        buttonContainer.style.cssText = 'margin-top: 10px; text-align: center;';
        
        const allButton = document.createElement('button');
        allButton.className = 'button';
        allButton.textContent = 'All';
        allButton.style.marginRight = '5px';
        allButton.addEventListener('click', () => this.toggleAllCategories(true));
        
        const noneButton = document.createElement('button');
        noneButton.className = 'button';
        noneButton.textContent = 'None';
        noneButton.addEventListener('click', () => this.toggleAllCategories(false));
        
        buttonContainer.appendChild(allButton);
        buttonContainer.appendChild(noneButton);
        filterSection.appendChild(buttonContainer);
        
        controlPanel.appendChild(filterSection);
    }
    
    toggleCategoryFilter(categoryName, isVisible) {
        if (!this.renderer.data) return;
        
        if (isVisible) {
            this.renderer.filteredCategories.delete(categoryName);
        } else {
            this.renderer.filteredCategories.add(categoryName);
        }
        
        this.applyFilters();
    }
    
    toggleAllCategories(showAll) {
        const checkboxes = document.querySelectorAll('[id^="filter-"]');
        checkboxes.forEach(checkbox => {
            checkbox.checked = showAll;
            const categoryName = checkbox.id.replace('filter-', '');
            if (showAll) {
                this.renderer.filteredCategories.delete(categoryName);
            } else {
                this.renderer.filteredCategories.add(categoryName);
            }
        });
        
        this.applyFilters();
    }
    
    applyFilters() {
        if (!this.renderer.nodes || !this.renderer.links) return;
        
        // Filter nodes
        this.renderer.nodes
            .style('display', d => 
                this.renderer.filteredCategories.has(d.category) ? 'none' : 'block')
            .attr('opacity', d => 
                this.renderer.filteredCategories.has(d.category) ? 0 : (d.opacity || 0.8));
        
        // Filter links based on visible nodes
        this.renderer.links
            .style('display', d => 
                (this.renderer.filteredCategories.has(d.source.category) || 
                 this.renderer.filteredCategories.has(d.target.category)) ? 'none' : 'block')
            .attr('stroke-opacity', d => 
                (this.renderer.filteredCategories.has(d.source.category) || 
                 this.renderer.filteredCategories.has(d.target.category)) ? 0 : 0.6);
        
        // Update labels if visible
        if (this.renderer.labels) {
            this.renderer.labels
                .style('display', d => 
                    this.renderer.filteredCategories.has(d.category) ? 'none' : 'block');
        }
        
        // Update visible node count
        const visibleNodes = this.renderer.data.nodes.filter(n => 
            !this.renderer.filteredCategories.has(n.category));
        
        const nodeCountElement = document.getElementById('node-count');
        if (nodeCountElement) {
            nodeCountElement.textContent = `${visibleNodes.length}/${this.renderer.data.nodes.length}`;
        }
    }
    
    setupAIToggle() {
        const controlPanel = document.getElementById('control-panel');
        if (!controlPanel) return;
        
        const aiSection = document.createElement('div');
        aiSection.className = 'control-section';
        aiSection.innerHTML = '<h3>🤖 AI Enhancement</h3>';
        
        const toggleButton = document.createElement('button');
        toggleButton.className = 'button';
        toggleButton.innerHTML = '🤖 Toggle AI Highlight';
        toggleButton.addEventListener('click', () => {
            this.renderer.settings.highlightAINodes = !this.renderer.settings.highlightAINodes;
            this.updateAIHighlighting();
        });
        
        const aiStatsDiv = document.createElement('div');
        aiStatsDiv.style.cssText = `
            margin-top: 10px;
            font-size: 0.9em;
            color: #00ff88;
        `;
        
        if (this.renderer.data) {
            const aiCount = this.renderer.data.nodes.filter(n => n.isAIEnhanced).length;
            const patternCount = this.renderer.data.nodes.length - aiCount;
            aiStatsDiv.innerHTML = `
                🤖 AI-Enhanced: ${aiCount}<br/>
                📋 Pattern-Based: ${patternCount}
            `;
        }
        
        aiSection.appendChild(toggleButton);
        aiSection.appendChild(aiStatsDiv);
        controlPanel.appendChild(aiSection);
    }
    
    updateAIHighlighting() {
        if (!this.renderer.nodes) return;
        
        this.renderer.nodes
            .attr('stroke', d => {
                if (this.renderer.selectedNodes.has(d.id)) return '#FFFF00';
                if (this.renderer.settings.highlightAINodes && d.isAIEnhanced) return '#FFD700';
                return '#fff';
            })
            .attr('stroke-width', d => {
                if (this.renderer.selectedNodes.has(d.id)) return 4;
                if (this.renderer.settings.highlightAINodes && d.isAIEnhanced) return 3;
                return 2;
            })
            .attr('filter', d => 
                (this.renderer.settings.highlightAINodes && d.isAIEnhanced) ? 
                'url(#glow)' : null);
    }
    
    setupSimulationControls() {
        // Enhanced simulation controls are already handled by the existing controls
        // This could be extended with presets for different force configurations
        
        const controlPanel = document.getElementById('control-panel');
        if (!controlPanel) return;
        
        const presetsSection = document.createElement('div');
        presetsSection.className = 'control-section';
        presetsSection.innerHTML = '<h3>📐 Layout Presets</h3>';
        
        const presets = [
            { name: 'Clustered', forces: { charge: -200, link: 80 } },
            { name: 'Spread Out', forces: { charge: -500, link: 120 } },
            { name: 'Tight', forces: { charge: -100, link: 50 } }
        ];
        
        presets.forEach(preset => {
            const button = document.createElement('button');
            button.className = 'button';
            button.textContent = preset.name;
            button.style.margin = '2px';
            button.addEventListener('click', () => {
                this.applyLayoutPreset(preset.forces);
            });
            presetsSection.appendChild(button);
        });
        
        controlPanel.appendChild(presetsSection);
    }
    
    applyLayoutPreset(forces) {
        if (!this.renderer.simulation) return;
        
        this.renderer.simulation
            .force('charge').strength(forces.charge);
        
        if (this.renderer.simulation.force('link')) {
            this.renderer.simulation
                .force('link').distance(forces.link);
        }
        
        this.renderer.simulation.alpha(0.3).restart();
        
        // Update sliders if they exist
        const chargeSlider = document.getElementById('charge-strength');
        const forceSlider = document.getElementById('force-strength');
        
        if (chargeSlider) {
            chargeSlider.value = forces.charge;
            const chargeValue = document.getElementById('charge-value');
            if (chargeValue) chargeValue.textContent = forces.charge;
        }
        
        if (forceSlider) {
            forceSlider.value = forces.link;
            const forceValue = document.getElementById('force-value');
            if (forceValue) forceValue.textContent = forces.link;
        }
    }
    
    setupLayoutControls() {
        // Additional layout algorithms could be implemented here
        // For now, we focus on the clustering toggle
        const existingControls = document.querySelector('#toggle-labels')?.parentElement;
        if (!existingControls) return;
        
        const clusterButton = document.createElement('button');
        clusterButton.className = 'button';
        clusterButton.innerHTML = '🎯 Toggle Clusters';
        clusterButton.addEventListener('click', () => {
            this.renderer.toggleClustering();
        });
        
        existingControls.appendChild(clusterButton);
    }
    
    setupExportControls() {
        const exportButton = document.getElementById('export-data');
        if (!exportButton) return;
        
        exportButton.addEventListener('click', () => {
            this.exportVisualizationData();
        });
    }
    
    exportVisualizationData() {
        if (!this.renderer.data) return;
        
        const exportData = {
            metadata: {
                title: 'Unity-Claude Automation System Graph',
                exported: new Date().toISOString(),
                nodeCount: this.renderer.data.nodes.length,
                linkCount: this.renderer.data.links.length
            },
            graph: this.renderer.data,
            settings: this.renderer.settings
        };
        
        const blob = new Blob([JSON.stringify(exportData, null, 2)], 
                             { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        
        const a = document.createElement('a');
        a.href = url;
        a.download = `unity-claude-graph-${new Date().toISOString().slice(0, 10)}.json`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
        
        console.log('📄 Graph data exported successfully');
    }
    
    setupPerformanceMonitor() {
        let frameCount = 0;
        let lastTime = performance.now();
        
        const updateFPS = () => {
            frameCount++;
            const currentTime = performance.now();
            
            if (currentTime - lastTime >= 1000) {
                const fps = Math.round((frameCount * 1000) / (currentTime - lastTime));
                const fpsElement = document.getElementById('fps-counter');
                
                if (fpsElement) {
                    fpsElement.textContent = fps;
                    
                    // Color code performance
                    const perfIndicator = document.getElementById('perf-indicator');
                    if (perfIndicator) {
                        if (fps >= 50) {
                            perfIndicator.style.color = '#00ff88';
                        } else if (fps >= 30) {
                            perfIndicator.style.color = '#ffaa00';
                        } else {
                            perfIndicator.style.color = '#ff4444';
                        }
                    }
                }
                
                frameCount = 0;
                lastTime = currentTime;
            }
            
            requestAnimationFrame(updateFPS);
        };
        
        updateFPS();
    }
    
    setupEventHandlers() {
        // Keyboard shortcuts
        document.addEventListener('keydown', (event) => {
            if (event.key === 'Escape') {
                // Clear selection and highlights
                this.renderer.selectedNodes.clear();
                this.renderer.clearHighlights();
                this.updateAIHighlighting();
            } else if (event.key === 'r' && event.ctrlKey) {
                // Restart simulation
                event.preventDefault();
                this.renderer.restartSimulation();
            } else if (event.key === 'c' && event.ctrlKey) {
                // Center graph
                event.preventDefault();
                this.renderer.centerGraph();
            }
        });
    }
}

// Setup function to be called by the main renderer
function setupEnhancedControls(renderer) {
    console.log('🎛️ Setting up enhanced controls...');
    window.enhancedControls = new EnhancedControls(renderer);
}

console.log('✅ Enhanced Controls loaded');