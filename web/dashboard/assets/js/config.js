// Unity-Claude Documentation Dashboard Configuration

const DashboardConfig = {
    // WebSocket Configuration
    websocket: {
        url: 'ws://localhost:8080/documentation-updates',
        reconnectInterval: 5000,
        maxReconnectAttempts: 10,
        pingInterval: 30000
    },
    
    // API Endpoints
    api: {
        baseUrl: '/api',
        endpoints: {
            graphData: '/graph/data',
            metrics: '/metrics',
            search: '/search',
            nodeDetails: '/nodes/{id}',
            pathAnalysis: '/paths',
            export: '/export'
        }
    },
    
    // Graph Visualization Settings
    graph: {
        // Canvas settings
        canvas: {
            backgroundColor: '#fafbfc',
            width: 800,
            height: 600,
            devicePixelRatio: window.devicePixelRatio || 1
        },
        
        // Force simulation parameters
        simulation: {
            alphaDecay: 0.02,
            velocityDecay: 0.3,
            alphaMin: 0.001,
            
            // Forces
            forces: {
                link: {
                    distance: 100,
                    strength: 0.1,
                    iterations: 1
                },
                charge: {
                    strength: -200,
                    distanceMax: 800,
                    distanceMin: 1
                },
                center: {
                    strength: 0.1
                },
                collision: {
                    radius: 15,
                    strength: 0.7,
                    iterations: 1
                }
            }
        },
        
        // Node appearance
        nodes: {
            defaultRadius: 8,
            minRadius: 4,
            maxRadius: 20,
            strokeWidth: 2,
            
            // Node types and colors
            types: {
                function: {
                    color: '#2563eb',
                    strokeColor: '#1d4ed8',
                    radius: 8,
                    label: 'Function'
                },
                class: {
                    color: '#dc2626',
                    strokeColor: '#b91c1c',
                    radius: 12,
                    label: 'Class'
                },
                module: {
                    color: '#059669',
                    strokeColor: '#047857',
                    radius: 16,
                    label: 'Module'
                },
                variable: {
                    color: '#7c3aed',
                    strokeColor: '#6d28d9',
                    radius: 6,
                    label: 'Variable'
                },
                interface: {
                    color: '#ea580c',
                    strokeColor: '#c2410c',
                    radius: 10,
                    label: 'Interface'
                },
                method: {
                    color: '#0891b2',
                    strokeColor: '#0e7490',
                    radius: 7,
                    label: 'Method'
                }
            },
            
            // Selection states
            states: {
                normal: {
                    opacity: 1.0,
                    strokeWidth: 2
                },
                highlighted: {
                    opacity: 1.0,
                    strokeWidth: 3,
                    glowRadius: 10,
                    glowColor: '#fbbf24'
                },
                selected: {
                    opacity: 1.0,
                    strokeWidth: 4,
                    glowRadius: 15,
                    glowColor: '#2563eb'
                },
                dimmed: {
                    opacity: 0.3,
                    strokeWidth: 1
                },
                path: {
                    opacity: 1.0,
                    strokeWidth: 3,
                    glowRadius: 8,
                    glowColor: '#10b981'
                }
            }
        },
        
        // Link appearance
        links: {
            defaultStrokeWidth: 1.5,
            strokeColor: '#94a3b8',
            
            // Link types
            types: {
                calls: {
                    color: '#2563eb',
                    strokeWidth: 2,
                    dashArray: null,
                    label: 'Calls'
                },
                imports: {
                    color: '#059669',
                    strokeWidth: 1.5,
                    dashArray: [5, 5],
                    label: 'Imports'
                },
                inherits: {
                    color: '#dc2626',
                    strokeWidth: 2.5,
                    dashArray: [10, 2],
                    label: 'Inherits'
                },
                references: {
                    color: '#7c3aed',
                    strokeWidth: 1,
                    dashArray: [3, 3],
                    label: 'References'
                },
                contains: {
                    color: '#ea580c',
                    strokeWidth: 1.5,
                    dashArray: null,
                    label: 'Contains'
                }
            },
            
            // Selection states
            states: {
                normal: {
                    opacity: 0.6,
                    strokeWidth: 1.5
                },
                highlighted: {
                    opacity: 1.0,
                    strokeWidth: 3,
                    glowRadius: 5
                },
                dimmed: {
                    opacity: 0.1,
                    strokeWidth: 1
                },
                path: {
                    opacity: 1.0,
                    strokeWidth: 4,
                    glowRadius: 8,
                    animated: true,
                    animationSpeed: 2000
                }
            }
        },
        
        // Zoom and pan settings
        zoom: {
            min: 0.1,
            max: 10.0,
            step: 0.1,
            wheelSensitivity: 0.002,
            panSensitivity: 1.0,
            doubleTapZoom: 2.0
        },
        
        // Performance settings
        performance: {
            maxNodes: 5000,
            maxLinks: 10000,
            renderThrottle: 16, // ~60fps
            animationDuration: 300,
            
            // Level of detail thresholds
            lod: {
                labelMinZoom: 0.8,
                detailMinZoom: 1.5,
                maxLabelsShown: 200
            }
        }
    },
    
    // Metrics Configuration
    metrics: {
        updateInterval: 5000, // 5 seconds
        historyLength: 100,
        
        // Chart configurations
        charts: {
            codeHealth: {
                type: 'doughnut',
                colors: ['#10b981', '#f59e0b', '#ef4444'],
                labels: ['Healthy', 'Warning', 'Critical'],
                animation: {
                    animateRotate: true,
                    duration: 1000
                }
            },
            obsolescence: {
                type: 'line',
                colors: ['#ef4444', '#f59e0b', '#10b981'],
                labels: ['Dead Code', 'Deprecated', 'Active'],
                timeRange: '24h',
                animation: {
                    duration: 500,
                    easing: 'easeInOutQuart'
                }
            },
            coverage: {
                type: 'radar',
                colors: ['#2563eb', '#059669', '#7c3aed'],
                labels: ['Documentation', 'Tests', 'Comments', 'Examples', 'API Docs'],
                animation: {
                    duration: 1000,
                    easing: 'easeOutQuart'
                }
            },
            performance: {
                type: 'bar',
                colors: ['#0891b2', '#059669', '#2563eb'],
                labels: ['Render Time', 'Data Load', 'Analysis'],
                animation: {
                    duration: 800,
                    easing: 'easeInOutCubic'
                }
            }
        },
        
        // Threshold values
        thresholds: {
            codeHealth: {
                excellent: 90,
                good: 75,
                warning: 60,
                critical: 40
            },
            obsolescence: {
                low: 2,
                medium: 5,
                high: 10,
                critical: 20
            },
            coverage: {
                excellent: 90,
                good: 75,
                acceptable: 60,
                poor: 40
            }
        }
    },
    
    // Filter and Search Settings
    filters: {
        debounceDelay: 300,
        minSearchLength: 2,
        maxResults: 500,
        caseSensitive: false,
        
        // Default filter states
        defaults: {
            nodeTypes: ['function', 'class', 'module', 'variable'],
            fileExtensions: ['ps1', 'psm1', 'py', 'js', 'cs'],
            showConnected: true,
            showIsolated: false
        }
    },
    
    // Export Settings
    export: {
        formats: {
            png: {
                quality: 0.9,
                backgroundColor: '#ffffff',
                pixelRatio: 2
            },
            svg: {
                includeStyles: true,
                backgroundColor: '#ffffff'
            },
            pdf: {
                format: 'a4',
                orientation: 'landscape',
                quality: 0.95
            },
            json: {
                includePositions: true,
                includeMetrics: true,
                prettyPrint: true
            }
        },
        
        // Default export settings
        defaultWidth: 1920,
        defaultHeight: 1080,
        maxSize: 4096
    },
    
    // Path Analysis Settings
    paths: {
        maxDepth: 10,
        maxPaths: 100,
        algorithm: 'dijkstra', // 'dijkstra', 'bfs', 'dfs'
        
        // Animation settings for path highlighting
        animation: {
            duration: 2000,
            easing: 'ease-in-out',
            delay: 100, // delay between path segments
            repeat: false
        },
        
        // Path visualization
        visualization: {
            strokeWidth: 4,
            color: '#10b981',
            opacity: 0.8,
            dashArray: [5, 5],
            arrowSize: 8
        }
    },
    
    // Development and Debug Settings
    debug: {
        enabled: false,
        logLevel: 'info', // 'debug', 'info', 'warn', 'error'
        showPerformanceMetrics: false,
        showFPS: false,
        mockData: false
    },
    
    // Accessibility Settings
    accessibility: {
        keyboardNavigation: true,
        focusVisible: true,
        announceChanges: true,
        
        // Keyboard shortcuts
        shortcuts: {
            zoomIn: 'Equal',
            zoomOut: 'Minus',
            resetZoom: 'Digit0',
            fitToScreen: 'KeyF',
            search: 'KeyS',
            export: 'KeyE',
            refresh: 'KeyR'
        }
    },
    
    // Feature flags
    features: {
        realtimeUpdates: true,
        pathHighlighting: true,
        metricsCharts: true,
        exportFunctionality: true,
        keyboardShortcuts: true,
        touchGestures: true,
        contextMenu: true,
        tooltips: true
    }
};

// Utility functions for configuration
const ConfigUtils = {
    /**
     * Get node configuration by type
     * @param {string} type - Node type
     * @returns {object} Node configuration
     */
    getNodeConfig(type) {
        return DashboardConfig.graph.nodes.types[type] || DashboardConfig.graph.nodes.types.function;
    },
    
    /**
     * Get link configuration by type
     * @param {string} type - Link type
     * @returns {object} Link configuration
     */
    getLinkConfig(type) {
        return DashboardConfig.graph.links.types[type] || DashboardConfig.graph.links.types.calls;
    },
    
    /**
     * Get chart configuration by type
     * @param {string} type - Chart type
     * @returns {object} Chart configuration
     */
    getChartConfig(type) {
        return DashboardConfig.metrics.charts[type];
    },
    
    /**
     * Get API endpoint URL
     * @param {string} endpoint - Endpoint name
     * @param {object} params - URL parameters
     * @returns {string} Full URL
     */
    getApiUrl(endpoint, params = {}) {
        let url = DashboardConfig.api.baseUrl + DashboardConfig.api.endpoints[endpoint];
        
        // Replace URL parameters
        Object.keys(params).forEach(key => {
            url = url.replace(`{${key}}`, params[key]);
        });
        
        return url;
    },
    
    /**
     * Check if feature is enabled
     * @param {string} feature - Feature name
     * @returns {boolean} Feature enabled state
     */
    isFeatureEnabled(feature) {
        return DashboardConfig.features[feature] !== false;
    },
    
    /**
     * Get threshold level for a metric value
     * @param {string} metricType - Type of metric
     * @param {number} value - Metric value
     * @returns {string} Threshold level
     */
    getThresholdLevel(metricType, value) {
        const thresholds = DashboardConfig.metrics.thresholds[metricType];
        if (!thresholds) return 'unknown';
        
        if (value >= thresholds.excellent) return 'excellent';
        if (value >= thresholds.good) return 'good';
        if (metricType === 'obsolescence') {
            if (value <= thresholds.low) return 'excellent';
            if (value <= thresholds.medium) return 'good';
            if (value <= thresholds.high) return 'warning';
            return 'critical';
        } else {
            if (value >= thresholds.acceptable || value >= thresholds.warning) return 'warning';
            return 'critical';
        }
    }
};

// Export configuration (for modules)
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { DashboardConfig, ConfigUtils };
}

// Global availability
window.DashboardConfig = DashboardConfig;
window.ConfigUtils = ConfigUtils;