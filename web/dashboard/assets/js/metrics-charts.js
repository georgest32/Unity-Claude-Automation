// Metrics Charts - Code health, obsolescence, coverage, and performance visualizations

class MetricsCharts {
    constructor(dataManager, websocketManager) {
        this.dataManager = dataManager;
        this.websocketManager = websocketManager;
        
        // Chart instances
        this.charts = {
            health: null,
            obsolescence: null,
            coverage: null,
            performance: null
        };
        
        // Chart canvases
        this.canvases = {
            health: document.getElementById('healthChart'),
            obsolescence: document.getElementById('obsolescenceChart'),
            coverage: document.getElementById('coverageChart'),
            performance: document.getElementById('performanceChart')
        };
        
        // Stat displays
        this.statElements = {
            healthScore: document.getElementById('healthScore'),
            healthIssues: document.getElementById('healthIssues'),
            deadCodePercent: document.getElementById('deadCodePercent'),
            unusedFunctions: document.getElementById('unusedFunctions'),
            docCoverage: document.getElementById('docCoverage'),
            testCoverage: document.getElementById('testCoverage'),
            nodeCount: document.getElementById('nodeCount'),
            renderTime: document.getElementById('renderTime')
        };
        
        // Data storage
        this.metricsData = {
            health: { score: 0, issues: 0, breakdown: [] },
            obsolescence: { deadCode: 0, unused: 0, trend: [] },
            coverage: { documentation: 0, tests: 0, comments: 0, examples: 0, api: 0 },
            performance: { renderTime: 0, nodeCount: 0, loadTime: 0 }
        };
        
        // Update management
        this.updateInterval = null;
        this.isDestroyed = false;
        
        this.initializeCharts();
        this.setupEventListeners();
        this.startAutoUpdate();
        
        console.log('MetricsCharts initialized');
    }
    
    initializeCharts() {
        // Set Chart.js global defaults
        Chart.defaults.font.family = "'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif";
        Chart.defaults.font.size = 12;
        Chart.defaults.color = '#64748b';
        
        this.initializeHealthChart();
        this.initializeObsolescenceChart();
        this.initializeCoverageChart();
        this.initializePerformanceChart();
    }
    
    initializeHealthChart() {
        if (!this.canvases.health) return;
        
        const config = ConfigUtils.getChartConfig('codeHealth');
        
        this.charts.health = new Chart(this.canvases.health, {
            type: 'doughnut',
            data: {
                labels: ['Healthy', 'Warning', 'Critical'],
                datasets: [{
                    data: [75, 20, 5],
                    backgroundColor: [
                        '#10b981', // Green
                        '#f59e0b', // Orange
                        '#ef4444'  // Red
                    ],
                    borderWidth: 2,
                    borderColor: '#ffffff',
                    hoverBorderWidth: 3
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        position: 'bottom',
                        labels: {
                            padding: 20,
                            usePointStyle: true,
                            font: { size: 11 }
                        }
                    },
                    tooltip: {
                        callbacks: {
                            label: (context) => {
                                const label = context.label || '';
                                const value = context.parsed || 0;
                                return `${label}: ${value}%`;
                            }
                        }
                    }
                },
                animation: {
                    animateRotate: true,
                    duration: 1000
                },
                cutout: '60%'
            }
        });
    }
    
    initializeObsolescenceChart() {
        if (!this.canvases.obsolescence) return;
        
        this.charts.obsolescence = new Chart(this.canvases.obsolescence, {
            type: 'line',
            data: {
                labels: this.generateTimeLabels(24), // Last 24 hours
                datasets: [
                    {
                        label: 'Dead Code %',
                        data: this.generateTrendData(24, 2, 5),
                        borderColor: '#ef4444',
                        backgroundColor: 'rgba(239, 68, 68, 0.1)',
                        borderWidth: 2,
                        fill: true,
                        tension: 0.4
                    },
                    {
                        label: 'Deprecated %',
                        data: this.generateTrendData(24, 1, 3),
                        borderColor: '#f59e0b',
                        backgroundColor: 'rgba(245, 158, 11, 0.1)',
                        borderWidth: 2,
                        fill: true,
                        tension: 0.4
                    }
                ]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        position: 'top',
                        labels: {
                            usePointStyle: true,
                            font: { size: 11 }
                        }
                    },
                    tooltip: {
                        mode: 'index',
                        intersect: false
                    }
                },
                scales: {
                    x: {
                        display: true,
                        title: {
                            display: true,
                            text: 'Time'
                        },
                        grid: {
                            display: false
                        }
                    },
                    y: {
                        display: true,
                        title: {
                            display: true,
                            text: 'Percentage'
                        },
                        beginAtZero: true,
                        max: 10,
                        grid: {
                            color: 'rgba(148, 163, 184, 0.1)'
                        }
                    }
                },
                interaction: {
                    mode: 'nearest',
                    axis: 'x',
                    intersect: false
                },
                animation: {
                    duration: 500,
                    easing: 'easeInOutQuart'
                }
            }
        });
    }
    
    initializeCoverageChart() {
        if (!this.canvases.coverage) return;
        
        this.charts.coverage = new Chart(this.canvases.coverage, {
            type: 'radar',
            data: {
                labels: ['Documentation', 'Tests', 'Comments', 'Examples', 'API Docs'],
                datasets: [{
                    label: 'Coverage %',
                    data: [78, 65, 85, 45, 70],
                    backgroundColor: 'rgba(37, 99, 235, 0.2)',
                    borderColor: '#2563eb',
                    borderWidth: 2,
                    pointBackgroundColor: '#2563eb',
                    pointBorderColor: '#ffffff',
                    pointBorderWidth: 2,
                    pointRadius: 4,
                    pointHoverRadius: 6
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        display: false
                    },
                    tooltip: {
                        callbacks: {
                            label: (context) => {
                                return `${context.label}: ${context.parsed.r}%`;
                            }
                        }
                    }
                },
                scales: {
                    r: {
                        beginAtZero: true,
                        max: 100,
                        ticks: {
                            stepSize: 20,
                            font: { size: 10 }
                        },
                        grid: {
                            color: 'rgba(148, 163, 184, 0.2)'
                        },
                        pointLabels: {
                            font: { size: 11 },
                            color: '#374151'
                        }
                    }
                },
                animation: {
                    duration: 1000,
                    easing: 'easeOutQuart'
                }
            }
        });
    }
    
    initializePerformanceChart() {
        if (!this.canvases.performance) return;
        
        this.charts.performance = new Chart(this.canvases.performance, {
            type: 'bar',
            data: {
                labels: ['Render Time', 'Data Load', 'Analysis'],
                datasets: [{
                    label: 'Time (ms)',
                    data: [32, 145, 89],
                    backgroundColor: [
                        'rgba(8, 145, 178, 0.8)',
                        'rgba(5, 150, 105, 0.8)',
                        'rgba(37, 99, 235, 0.8)'
                    ],
                    borderColor: [
                        '#0891b2',
                        '#059669',
                        '#2563eb'
                    ],
                    borderWidth: 1,
                    borderRadius: 4
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        display: false
                    },
                    tooltip: {
                        callbacks: {
                            label: (context) => {
                                return `${context.label}: ${context.parsed.y}ms`;
                            }
                        }
                    }
                },
                scales: {
                    x: {
                        grid: {
                            display: false
                        }
                    },
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'Time (ms)'
                        },
                        grid: {
                            color: 'rgba(148, 163, 184, 0.1)'
                        }
                    }
                },
                animation: {
                    duration: 800,
                    easing: 'easeInOutCubic'
                }
            }
        });
    }
    
    setupEventListeners() {
        // Data manager events
        this.dataManager.on('metricsUpdated', (metrics) => {
            this.updateMetrics(metrics);
        });
        
        this.dataManager.on('dataProcessed', (data) => {
            this.updatePerformanceMetrics(data);
        });
        
        // WebSocket events
        if (this.websocketManager) {
            this.websocketManager.on('metricsUpdate', (data) => {
                this.updateMetrics(data.metrics);
            });
        }
        
        // Global performance monitoring
        if (window.DashboardMetrics) {
            window.DashboardMetrics.on('update', (metric, value) => {
                this.updatePerformanceMetric(metric, value);
            });
        }
    }
    
    // Data generation utilities (for mock data)
    generateTimeLabels(hours) {
        const labels = [];
        const now = new Date();
        
        for (let i = hours - 1; i >= 0; i--) {
            const time = new Date(now.getTime() - i * 60 * 60 * 1000);
            labels.push(time.getHours().toString().padStart(2, '0') + ':00');
        }
        
        return labels;
    }
    
    generateTrendData(points, baseValue, maxVariation) {
        const data = [];
        let current = baseValue;
        
        for (let i = 0; i < points; i++) {
            // Add some realistic variation
            const change = (Math.random() - 0.5) * (maxVariation * 0.2);
            current = Math.max(0, Math.min(maxVariation * 2, current + change));
            data.push(Math.round(current * 10) / 10);
        }
        
        return data;
    }
    
    // Update methods
    async updateMetrics(metrics = null) {
        if (!metrics) {
            try {
                metrics = await this.dataManager.loadMetrics();
            } catch (error) {
                console.error('Failed to load metrics:', error);
                return;
            }
        }
        
        this.metricsData = { ...this.metricsData, ...metrics };
        
        this.updateHealthChart(metrics.codeHealth);
        this.updateObsolescenceChart(metrics.obsolescence);
        this.updateCoverageChart(metrics.coverage);
        this.updatePerformanceChart(metrics.performance);
        this.updateStatDisplays(metrics);
        
        console.log('Metrics updated');
    }
    
    updateHealthChart(healthData) {
        if (!this.charts.health || !healthData) return;
        
        const score = healthData.score || 0;
        const thresholds = DashboardConfig.metrics.thresholds.codeHealth;
        
        // Calculate distribution based on score
        let healthy, warning, critical;
        
        if (score >= thresholds.excellent) {
            healthy = 80 + Math.random() * 15;
            warning = Math.random() * 10;
            critical = Math.max(0, 100 - healthy - warning);
        } else if (score >= thresholds.good) {
            healthy = 50 + Math.random() * 25;
            warning = 20 + Math.random() * 15;
            critical = Math.max(0, 100 - healthy - warning);
        } else if (score >= thresholds.warning) {
            healthy = 20 + Math.random() * 20;
            warning = 30 + Math.random() * 20;
            critical = Math.max(0, 100 - healthy - warning);
        } else {
            healthy = Math.random() * 20;
            warning = 20 + Math.random() * 20;
            critical = Math.max(30, 100 - healthy - warning);
        }
        
        this.charts.health.data.datasets[0].data = [
            Math.round(healthy),
            Math.round(warning),
            Math.round(critical)
        ];
        
        this.charts.health.update('active');
        
        // Store for later use
        this.metricsData.health = {
            score,
            issues: healthData.issues || 0,
            breakdown: [healthy, warning, critical]
        };
    }
    
    updateObsolescenceChart(obsolescenceData) {
        if (!this.charts.obsolescence || !obsolescenceData) return;
        
        // Update trend data (in a real implementation, this would come from historical data)
        const deadCodeTrend = this.generateTrendData(24, obsolescenceData.deadCodePercentage || 2, 5);
        const deprecatedTrend = this.generateTrendData(24, (obsolescenceData.deadCodePercentage || 2) * 0.6, 3);
        
        this.charts.obsolescence.data.datasets[0].data = deadCodeTrend;
        this.charts.obsolescence.data.datasets[1].data = deprecatedTrend;
        
        this.charts.obsolescence.update('active');
        
        this.metricsData.obsolescence = {
            deadCode: obsolescenceData.deadCodePercentage || 0,
            unused: obsolescenceData.unusedFunctions || 0,
            trend: deadCodeTrend
        };
    }
    
    updateCoverageChart(coverageData) {
        if (!this.charts.coverage || !coverageData) return;
        
        const data = [
            coverageData.documentation || 0,
            coverageData.tests || 0,
            coverageData.comments || 0,
            coverageData.examples || 0,
            coverageData.api || 0
        ];
        
        this.charts.coverage.data.datasets[0].data = data;
        this.charts.coverage.update('active');
        
        this.metricsData.coverage = {
            documentation: coverageData.documentation || 0,
            tests: coverageData.tests || 0,
            comments: coverageData.comments || 0,
            examples: coverageData.examples || 0,
            api: coverageData.api || 0
        };
    }
    
    updatePerformanceChart(performanceData) {
        if (!this.charts.performance) return;
        
        // Use actual performance data if available
        const renderTime = performanceData?.renderTime || this.metricsData.performance.renderTime;
        const loadTime = performanceData?.loadTime || this.metricsData.performance.loadTime;
        const analysisTime = performanceData?.processingTime || 50;
        
        this.charts.performance.data.datasets[0].data = [
            Math.round(renderTime),
            Math.round(loadTime),
            Math.round(analysisTime)
        ];
        
        this.charts.performance.update('active');
        
        this.metricsData.performance = {
            renderTime,
            loadTime,
            analysisTime,
            nodeCount: performanceData?.nodeCount || this.metricsData.performance.nodeCount
        };
    }
    
    updateStatDisplays(metrics) {
        // Health stats
        if (this.statElements.healthScore && metrics.codeHealth) {
            this.updateStatElement(
                this.statElements.healthScore,
                Math.round(metrics.codeHealth.score || 0) + '%'
            );
        }
        
        if (this.statElements.healthIssues && metrics.codeHealth) {
            this.updateStatElement(
                this.statElements.healthIssues,
                metrics.codeHealth.issues || 0
            );
        }
        
        // Obsolescence stats
        if (this.statElements.deadCodePercent && metrics.obsolescence) {
            this.updateStatElement(
                this.statElements.deadCodePercent,
                (metrics.obsolescence.deadCodePercentage || 0).toFixed(1) + '%'
            );
        }
        
        if (this.statElements.unusedFunctions && metrics.obsolescence) {
            this.updateStatElement(
                this.statElements.unusedFunctions,
                metrics.obsolescence.unusedFunctions || 0
            );
        }
        
        // Coverage stats
        if (this.statElements.docCoverage && metrics.coverage) {
            this.updateStatElement(
                this.statElements.docCoverage,
                Math.round(metrics.coverage.documentation || 0) + '%'
            );
        }
        
        if (this.statElements.testCoverage && metrics.coverage) {
            this.updateStatElement(
                this.statElements.testCoverage,
                Math.round(metrics.coverage.tests || 0) + '%'
            );
        }
        
        // Performance stats
        if (this.statElements.nodeCount && metrics.performance) {
            this.updateStatElement(
                this.statElements.nodeCount,
                (metrics.performance.nodeCount || 0).toLocaleString()
            );
        }
        
        if (this.statElements.renderTime && metrics.performance) {
            this.updateStatElement(
                this.statElements.renderTime,
                Math.round(metrics.performance.renderTime || 0) + 'ms'
            );
        }
    }
    
    updateStatElement(element, value) {
        if (!element) return;
        
        const currentValue = element.textContent;
        if (currentValue !== value.toString()) {
            element.textContent = value;
            
            // Add update animation
            element.style.transform = 'scale(1.05)';
            element.style.transition = 'transform 0.2s ease';
            
            setTimeout(() => {
                element.style.transform = 'scale(1)';
            }, 200);
        }
    }
    
    updatePerformanceMetric(metric, value) {
        switch (metric) {
            case 'nodeCount':
                if (this.statElements.nodeCount) {
                    this.updateStatElement(this.statElements.nodeCount, value.toLocaleString());
                }
                this.metricsData.performance.nodeCount = value;
                break;
                
            case 'renderTime':
                if (this.statElements.renderTime) {
                    this.updateStatElement(this.statElements.renderTime, Math.round(value) + 'ms');
                }
                this.metricsData.performance.renderTime = value;
                break;
        }
    }
    
    // Auto-update management
    startAutoUpdate() {
        if (this.updateInterval) return;
        
        const interval = DashboardConfig.metrics.updateInterval;
        
        this.updateInterval = setInterval(() => {
            if (!this.isDestroyed) {
                this.updateMetrics();
            }
        }, interval);
        
        console.log(`Started metrics auto-update (${interval}ms interval)`);
    }
    
    stopAutoUpdate() {
        if (this.updateInterval) {
            clearInterval(this.updateInterval);
            this.updateInterval = null;
            console.log('Stopped metrics auto-update');
        }
    }
    
    // Chart interaction methods
    highlightMetric(chartType, dataIndex) {
        const chart = this.charts[chartType];
        if (!chart) return;
        
        // Highlight specific data point
        chart.setActiveElements([{ datasetIndex: 0, index: dataIndex }]);
        chart.update('none');
        
        setTimeout(() => {
            chart.setActiveElements([]);
            chart.update('none');
        }, 2000);
    }
    
    // Data export methods
    getMetricsData() {
        return {
            ...this.metricsData,
            timestamp: Date.now(),
            charts: {
                health: this.charts.health?.data,
                obsolescence: this.charts.obsolescence?.data,
                coverage: this.charts.coverage?.data,
                performance: this.charts.performance?.data
            }
        };
    }
    
    exportChartAsImage(chartType, format = 'png') {
        const chart = this.charts[chartType];
        if (!chart) {
            console.error(`Chart '${chartType}' not found`);
            return null;
        }
        
        const canvas = chart.canvas;
        const url = canvas.toDataURL(`image/${format}`, 0.9);
        
        // Create download link
        const link = document.createElement('a');
        link.download = `${chartType}-chart.${format}`;
        link.href = url;
        link.click();
        
        return url;
    }
    
    // Threshold management
    updateThresholds(newThresholds) {
        Object.assign(DashboardConfig.metrics.thresholds, newThresholds);
        
        // Re-evaluate current metrics with new thresholds
        this.updateMetrics(this.metricsData);
        
        console.log('Thresholds updated:', newThresholds);
    }
    
    getThresholdStatus(metricType, value) {
        return ConfigUtils.getThresholdLevel(metricType, value);
    }
    
    // Chart customization
    setChartTheme(theme) {
        const isDark = theme === 'dark';
        const textColor = isDark ? '#f1f5f9' : '#374151';
        const gridColor = isDark ? 'rgba(241, 245, 249, 0.1)' : 'rgba(148, 163, 184, 0.1)';
        
        Object.values(this.charts).forEach(chart => {
            if (chart) {
                chart.options.plugins.legend.labels.color = textColor;
                if (chart.options.scales) {
                    Object.values(chart.options.scales).forEach(scale => {
                        if (scale.title) scale.title.color = textColor;
                        if (scale.ticks) scale.ticks.color = textColor;
                        if (scale.grid) scale.grid.color = gridColor;
                        if (scale.pointLabels) scale.pointLabels.color = textColor;
                    });
                }
                chart.update('none');
            }
        });
        
        console.log(`Chart theme updated to: ${theme}`);
    }
    
    // Resize handling
    handleResize() {
        Object.values(this.charts).forEach(chart => {
            if (chart) {
                chart.resize();
            }
        });
    }
    
    // Cleanup
    destroy() {
        console.log('Destroying MetricsCharts');
        
        this.isDestroyed = true;
        this.stopAutoUpdate();
        
        // Destroy all chart instances
        Object.values(this.charts).forEach(chart => {
            if (chart) {
                chart.destroy();
            }
        });
        
        this.charts = {};
        this.metricsData = {};
        
        console.log('MetricsCharts destroyed');
    }
}

// Global metrics tracking utility
class DashboardMetrics {
    constructor() {
        this.metrics = new Map();
        this.listeners = new Map();
    }
    
    update(metric, value) {
        this.metrics.set(metric, {
            value,
            timestamp: Date.now()
        });
        
        // Notify listeners
        const listeners = this.listeners.get(metric) || [];
        listeners.forEach(callback => {
            try {
                callback(value, metric);
            } catch (error) {
                console.error(`Error in metrics listener for ${metric}:`, error);
            }
        });
    }
    
    get(metric) {
        const data = this.metrics.get(metric);
        return data ? data.value : null;
    }
    
    on(metric, callback) {
        if (!this.listeners.has(metric)) {
            this.listeners.set(metric, []);
        }
        this.listeners.get(metric).push(callback);
        
        return () => {
            const listeners = this.listeners.get(metric);
            if (listeners) {
                const index = listeners.indexOf(callback);
                if (index > -1) {
                    listeners.splice(index, 1);
                }
            }
        };
    }
    
    getAllMetrics() {
        const result = {};
        this.metrics.forEach((data, metric) => {
            result[metric] = data;
        });
        return result;
    }
}

// Initialize global metrics tracker
if (!window.DashboardMetrics) {
    window.DashboardMetrics = new DashboardMetrics();
}

// Export for module systems
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { MetricsCharts, DashboardMetrics };
}

// Global availability
window.MetricsCharts = MetricsCharts;