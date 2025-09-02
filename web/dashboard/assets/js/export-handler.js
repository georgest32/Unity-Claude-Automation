// Export Handler - PNG/SVG/PDF export functionality for dashboard

class ExportHandler {
    constructor(graphRenderer, metricsCharts, dataManager) {
        this.graphRenderer = graphRenderer;
        this.metricsCharts = metricsCharts;
        this.dataManager = dataManager;
        
        // Export elements
        this.elements = {
            exportBtn: document.getElementById('exportBtn'),
            exportModal: document.getElementById('exportModal'),
            closeModal: document.getElementById('closeModal'),
            confirmExport: document.getElementById('confirmExport'),
            cancelExport: document.getElementById('cancelExport'),
            exportWidth: document.getElementById('exportWidth'),
            exportHeight: document.getElementById('exportHeight'),
            exportQuality: document.getElementById('exportQuality')
        };
        
        // Export settings
        this.exportSettings = {
            format: 'png',
            width: DashboardConfig.export.defaultWidth,
            height: DashboardConfig.export.defaultHeight,
            quality: 0.9,
            includeMetrics: true,
            includeFilters: true,
            backgroundColor: '#ffffff'
        };
        
        // Export queue and status
        this.exportQueue = [];
        this.isExporting = false;
        this.exportProgress = 0;
        
        this.initializeExportHandler();
        this.setupEventListeners();
        
        console.log('ExportHandler initialized');
    }
    
    initializeExportHandler() {
        // Set initial values
        if (this.elements.exportWidth) {
            this.elements.exportWidth.value = this.exportSettings.width;
        }
        if (this.elements.exportHeight) {
            this.elements.exportHeight.value = this.exportSettings.height;
        }
        if (this.elements.exportQuality) {
            this.elements.exportQuality.value = this.exportSettings.quality;
        }
        
        // Check for required libraries
        this.checkExportCapabilities();
    }
    
    checkExportCapabilities() {
        const capabilities = {
            html2canvas: typeof html2canvas !== 'undefined',
            jsPDF: typeof window.jsPDF !== 'undefined' || typeof jsPDF !== 'undefined',
            canvasCapture: typeof CanvasCapture !== 'undefined'
        };
        
        console.log('Export capabilities:', capabilities);
        
        // Warn if libraries are missing
        if (!capabilities.html2canvas) {
            console.warn('html2canvas not available - PNG export may not work');
        }
        if (!capabilities.jsPDF) {
            console.warn('jsPDF not available - PDF export may not work');
        }
        
        return capabilities;
    }
    
    setupEventListeners() {
        // Export button
        if (this.elements.exportBtn) {
            this.elements.exportBtn.addEventListener('click', () => {
                this.showExportModal();
            });
        }
        
        // Modal controls
        if (this.elements.closeModal) {
            this.elements.closeModal.addEventListener('click', () => {
                this.hideExportModal();
            });
        }
        
        if (this.elements.cancelExport) {
            this.elements.cancelExport.addEventListener('click', () => {
                this.hideExportModal();
            });
        }
        
        if (this.elements.confirmExport) {
            this.elements.confirmExport.addEventListener('click', () => {
                this.performExport();
            });
        }
        
        // Format selection
        const formatRadios = document.querySelectorAll('input[name="exportType"]');
        formatRadios.forEach(radio => {
            radio.addEventListener('change', (e) => {
                this.exportSettings.format = e.target.value;
                this.updateExportPreview();
            });
        });
        
        // Settings inputs
        if (this.elements.exportWidth) {
            this.elements.exportWidth.addEventListener('input', (e) => {
                this.exportSettings.width = Math.min(parseInt(e.target.value) || 1920, DashboardConfig.export.maxSize);
            });
        }
        
        if (this.elements.exportHeight) {
            this.elements.exportHeight.addEventListener('input', (e) => {
                this.exportSettings.height = Math.min(parseInt(e.target.value) || 1080, DashboardConfig.export.maxSize);
            });
        }
        
        if (this.elements.exportQuality) {
            this.elements.exportQuality.addEventListener('input', (e) => {
                this.exportSettings.quality = parseFloat(e.target.value);
            });
        }
        
        // Keyboard shortcuts
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && this.isModalVisible()) {
                this.hideExportModal();
            }
        });
        
        // Click outside modal to close
        if (this.elements.exportModal) {
            this.elements.exportModal.addEventListener('click', (e) => {
                if (e.target === this.elements.exportModal) {
                    this.hideExportModal();
                }
            });
        }
    }
    
    // Modal management
    showExportModal() {
        if (this.elements.exportModal) {
            this.elements.exportModal.classList.remove('hidden');
            this.updateExportPreview();
        }
    }
    
    hideExportModal() {
        if (this.elements.exportModal) {
            this.elements.exportModal.classList.add('hidden');
        }
    }
    
    isModalVisible() {
        return this.elements.exportModal && !this.elements.exportModal.classList.contains('hidden');
    }
    
    updateExportPreview() {
        // Update preview information based on current settings
        const format = this.exportSettings.format;
        const config = DashboardConfig.export.formats[format];
        
        if (config) {
            console.log(`Export format: ${format}`, config);
        }
    }
    
    // Export methods
    async performExport() {
        if (this.isExporting) {
            console.warn('Export already in progress');
            return;
        }
        
        this.isExporting = true;
        this.hideExportModal();
        this.showExportProgress();
        
        try {
            switch (this.exportSettings.format) {
                case 'png':
                    await this.exportToPNG();
                    break;
                case 'svg':
                    await this.exportToSVG();
                    break;
                case 'pdf':
                    await this.exportToPDF();
                    break;
                case 'json':
                    await this.exportToJSON();
                    break;
                default:
                    throw new Error(`Unsupported export format: ${this.exportSettings.format}`);
            }
            
            this.showExportSuccess();
        } catch (error) {
            console.error('Export failed:', error);
            this.showExportError(error.message);
        } finally {
            this.isExporting = false;
            this.hideExportProgress();
        }
    }
    
    async exportToPNG() {
        if (typeof html2canvas === 'undefined') {
            throw new Error('html2canvas library is required for PNG export');
        }
        
        this.updateProgress(10);
        
        // Get the dashboard container
        const dashboard = document.getElementById('app');
        if (!dashboard) {
            throw new Error('Dashboard container not found');
        }
        
        this.updateProgress(20);
        
        // Configure html2canvas options
        const options = {
            width: this.exportSettings.width,
            height: this.exportSettings.height,
            backgroundColor: this.exportSettings.backgroundColor,
            scale: window.devicePixelRatio || 1,
            useCORS: true,
            allowTaint: true,
            scrollX: 0,
            scrollY: 0,
            windowWidth: this.exportSettings.width,
            windowHeight: this.exportSettings.height
        };
        
        this.updateProgress(40);
        
        // Capture the dashboard
        const canvas = await html2canvas(dashboard, options);
        
        this.updateProgress(70);
        
        // Convert to blob and download
        canvas.toBlob((blob) => {
            const url = URL.createObjectURL(blob);
            this.downloadFile(url, `dashboard-export-${this.getTimestamp()}.png`);
            URL.revokeObjectURL(url);
            this.updateProgress(100);
        }, 'image/png', this.exportSettings.quality);
    }
    
    async exportToSVG() {
        this.updateProgress(10);
        
        // Create SVG container
        const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
        svg.setAttribute('width', this.exportSettings.width);
        svg.setAttribute('height', this.exportSettings.height);
        svg.setAttribute('xmlns', 'http://www.w3.org/2000/svg');
        
        this.updateProgress(30);
        
        // Export graph as SVG
        const graphSVG = await this.createGraphSVG();
        if (graphSVG) {
            svg.appendChild(graphSVG);
        }
        
        this.updateProgress(50);
        
        // Export metrics as SVG elements
        const metricsSVG = await this.createMetricsSVG();
        if (metricsSVG) {
            svg.appendChild(metricsSVG);
        }
        
        this.updateProgress(80);
        
        // Convert to string and download
        const serializer = new XMLSerializer();
        const svgString = serializer.serializeToString(svg);
        const blob = new Blob([svgString], { type: 'image/svg+xml' });
        const url = URL.createObjectURL(blob);
        
        this.downloadFile(url, `dashboard-export-${this.getTimestamp()}.svg`);
        URL.revokeObjectURL(url);
        
        this.updateProgress(100);
    }
    
    async exportToPDF() {
        const jsPDF = window.jsPDF || window.jspdf?.jsPDF;
        if (!jsPDF) {
            throw new Error('jsPDF library is required for PDF export');
        }
        
        this.updateProgress(10);
        
        const format = DashboardConfig.export.formats.pdf.format;
        const orientation = DashboardConfig.export.formats.pdf.orientation;
        
        const doc = new jsPDF({
            orientation,
            unit: 'px',
            format: format === 'a4' ? [595, 842] : [this.exportSettings.width, this.exportSettings.height]
        });
        
        this.updateProgress(20);
        
        // Add title
        doc.setFontSize(20);
        doc.text('Unity-Claude Documentation Dashboard', 20, 40);
        
        doc.setFontSize(12);
        doc.text(`Generated: ${new Date().toLocaleString()}`, 20, 60);
        
        this.updateProgress(30);
        
        // Capture dashboard as image and add to PDF
        if (typeof html2canvas !== 'undefined') {
            const dashboard = document.getElementById('app');
            if (dashboard) {
                const canvas = await html2canvas(dashboard, {
                    backgroundColor: '#ffffff',
                    scale: 0.5, // Lower scale for PDF
                    useCORS: true
                });
                
                this.updateProgress(60);
                
                const imgData = canvas.toDataURL('image/jpeg', 0.8);
                const imgWidth = doc.internal.pageSize.getWidth() - 40;
                const imgHeight = (canvas.height * imgWidth) / canvas.width;
                
                doc.addImage(imgData, 'JPEG', 20, 80, imgWidth, imgHeight);
            }
        }
        
        this.updateProgress(80);
        
        // Add metadata
        doc.setProperties({
            title: 'Unity-Claude Documentation Dashboard',
            subject: 'Code Analysis and Documentation Dashboard',
            author: 'Unity-Claude Automation',
            creator: 'Unity-Claude Dashboard Export'
        });
        
        this.updateProgress(90);
        
        // Save the PDF
        doc.save(`dashboard-export-${this.getTimestamp()}.pdf`);
        
        this.updateProgress(100);
    }
    
    async exportToJSON() {
        this.updateProgress(20);
        
        // Collect all dashboard data
        const exportData = {
            metadata: {
                version: '1.0',
                timestamp: Date.now(),
                generatedBy: 'Unity-Claude Documentation Dashboard'
            },
            settings: {
                export: this.exportSettings,
                filters: this.dataManager.activeFilters
            }
        };
        
        this.updateProgress(40);
        
        // Add graph data
        if (this.dataManager.processedData) {
            exportData.graph = {
                nodes: this.dataManager.processedData.nodes,
                links: this.dataManager.processedData.links,
                processingTime: this.dataManager.processedData.processingTime
            };
        }
        
        this.updateProgress(60);
        
        // Add metrics data
        if (this.metricsCharts) {
            exportData.metrics = this.metricsCharts.getMetricsData();
        }
        
        this.updateProgress(80);
        
        // Convert to JSON and download
        const jsonString = JSON.stringify(exportData, null, 2);
        const blob = new Blob([jsonString], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        
        this.downloadFile(url, `dashboard-data-${this.getTimestamp()}.json`);
        URL.revokeObjectURL(url);
        
        this.updateProgress(100);
    }
    
    // SVG creation helpers
    async createGraphSVG() {
        // Create SVG representation of the graph
        const graphGroup = document.createElementNS('http://www.w3.org/2000/svg', 'g');
        graphGroup.setAttribute('id', 'graph-export');
        
        if (!this.graphRenderer.nodes || !this.graphRenderer.links) {
            return graphGroup;
        }
        
        // Add links
        this.graphRenderer.links.forEach(link => {
            const line = document.createElementNS('http://www.w3.org/2000/svg', 'line');
            line.setAttribute('x1', link.source.x || 0);
            line.setAttribute('y1', link.source.y || 0);
            line.setAttribute('x2', link.target.x || 0);
            line.setAttribute('y2', link.target.y || 0);
            line.setAttribute('stroke', '#94a3b8');
            line.setAttribute('stroke-width', '1.5');
            graphGroup.appendChild(line);
        });
        
        // Add nodes
        this.graphRenderer.nodes.forEach(node => {
            const circle = document.createElementNS('http://www.w3.org/2000/svg', 'circle');
            const config = ConfigUtils.getNodeConfig(node.type);
            const radius = this.graphRenderer.getNodeRadius(node);
            
            circle.setAttribute('cx', node.x || 0);
            circle.setAttribute('cy', node.y || 0);
            circle.setAttribute('r', radius);
            circle.setAttribute('fill', config.color);
            circle.setAttribute('stroke', config.strokeColor);
            circle.setAttribute('stroke-width', '2');
            
            graphGroup.appendChild(circle);
            
            // Add node label
            if (node.name) {
                const text = document.createElementNS('http://www.w3.org/2000/svg', 'text');
                text.setAttribute('x', node.x || 0);
                text.setAttribute('y', (node.y || 0) + radius + 15);
                text.setAttribute('text-anchor', 'middle');
                text.setAttribute('font-family', 'Inter, sans-serif');
                text.setAttribute('font-size', '10');
                text.setAttribute('fill', '#374151');
                text.textContent = node.name;
                graphGroup.appendChild(text);
            }
        });
        
        return graphGroup;
    }
    
    async createMetricsSVG() {
        // Create SVG representation of metrics
        const metricsGroup = document.createElementNS('http://www.w3.org/2000/svg', 'g');
        metricsGroup.setAttribute('id', 'metrics-export');
        
        // Add metrics summary text
        if (this.metricsCharts && this.metricsCharts.metricsData) {
            const data = this.metricsCharts.metricsData;
            let y = this.exportSettings.height - 100;
            
            const title = document.createElementNS('http://www.w3.org/2000/svg', 'text');
            title.setAttribute('x', '20');
            title.setAttribute('y', y);
            title.setAttribute('font-family', 'Inter, sans-serif');
            title.setAttribute('font-size', '14');
            title.setAttribute('font-weight', 'bold');
            title.setAttribute('fill', '#374151');
            title.textContent = 'Metrics Summary';
            metricsGroup.appendChild(title);
            
            y += 20;
            
            // Add key metrics
            const metrics = [
                `Code Health: ${Math.round(data.health?.score || 0)}%`,
                `Dead Code: ${(data.obsolescence?.deadCode || 0).toFixed(1)}%`,
                `Doc Coverage: ${Math.round(data.coverage?.documentation || 0)}%`,
                `Nodes: ${(data.performance?.nodeCount || 0).toLocaleString()}`
            ];
            
            metrics.forEach(metric => {
                const text = document.createElementNS('http://www.w3.org/2000/svg', 'text');
                text.setAttribute('x', '20');
                text.setAttribute('y', y);
                text.setAttribute('font-family', 'Inter, sans-serif');
                text.setAttribute('font-size', '12');
                text.setAttribute('fill', '#64748b');
                text.textContent = metric;
                metricsGroup.appendChild(text);
                y += 16;
            });
        }
        
        return metricsGroup;
    }
    
    // Progress management
    showExportProgress() {
        const overlay = this.createProgressOverlay();
        document.body.appendChild(overlay);
    }
    
    hideExportProgress() {
        const overlay = document.getElementById('export-progress-overlay');
        if (overlay) {
            document.body.removeChild(overlay);
        }
    }
    
    updateProgress(percentage) {
        this.exportProgress = percentage;
        
        const progressBar = document.querySelector('#export-progress-overlay .progress-bar');
        const progressText = document.querySelector('#export-progress-overlay .progress-text');
        
        if (progressBar) {
            progressBar.style.width = `${percentage}%`;
        }
        
        if (progressText) {
            progressText.textContent = `Exporting... ${percentage}%`;
        }
    }
    
    createProgressOverlay() {
        const overlay = document.createElement('div');
        overlay.id = 'export-progress-overlay';
        overlay.style.cssText = `
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(255, 255, 255, 0.95);
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            z-index: 2000;
        `;
        
        overlay.innerHTML = `
            <div style="text-align: center;">
                <div style="width: 300px; height: 4px; background: #e2e8f0; border-radius: 2px; margin-bottom: 20px;">
                    <div class="progress-bar" style="width: 0%; height: 100%; background: #2563eb; border-radius: 2px; transition: width 0.3s ease;"></div>
                </div>
                <p class="progress-text" style="font-size: 0.875rem; color: #64748b;">Exporting... 0%</p>
            </div>
        `;
        
        return overlay;
    }
    
    // Feedback methods
    showExportSuccess() {
        this.showExportFeedback('Export completed successfully!', 'success');
    }
    
    showExportError(message) {
        this.showExportFeedback(`Export failed: ${message}`, 'error');
    }
    
    showExportFeedback(message, type = 'success') {
        const color = type === 'error' ? '#ef4444' : '#10b981';
        
        const feedback = document.createElement('div');
        feedback.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            background: ${color};
            color: white;
            padding: 12px 20px;
            border-radius: 6px;
            font-size: 0.875rem;
            z-index: 1000;
            animation: slideInRight 0.3s ease, fadeOut 0.3s ease 2.7s;
            box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1);
        `;
        
        feedback.textContent = message;
        document.body.appendChild(feedback);
        
        setTimeout(() => {
            if (document.body.contains(feedback)) {
                document.body.removeChild(feedback);
            }
        }, 3000);
    }
    
    // Utility methods
    downloadFile(url, filename) {
        const link = document.createElement('a');
        link.href = url;
        link.download = filename;
        link.style.display = 'none';
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        
        console.log(`Downloaded: ${filename}`);
    }
    
    getTimestamp() {
        const now = new Date();
        return now.toISOString().replace(/[:.]/g, '-').replace('T', '_').split('.')[0];
    }
    
    // Batch export methods
    async exportAll() {
        const formats = ['png', 'svg', 'pdf', 'json'];
        const results = [];
        
        this.showExportProgress();
        
        for (let i = 0; i < formats.length; i++) {
            const format = formats[i];
            
            try {
                this.exportSettings.format = format;
                this.updateProgress((i / formats.length) * 80);
                
                await this.performExport();
                results.push({ format, success: true });
            } catch (error) {
                console.error(`Failed to export ${format}:`, error);
                results.push({ format, success: false, error: error.message });
            }
        }
        
        this.updateProgress(100);
        this.hideExportProgress();
        
        const successful = results.filter(r => r.success).length;
        this.showExportFeedback(`Batch export completed: ${successful}/${formats.length} formats exported`);
        
        return results;
    }
    
    // Settings management
    updateExportSettings(newSettings) {
        Object.assign(this.exportSettings, newSettings);
        console.log('Export settings updated:', this.exportSettings);
    }
    
    resetExportSettings() {
        this.exportSettings = {
            format: 'png',
            width: DashboardConfig.export.defaultWidth,
            height: DashboardConfig.export.defaultHeight,
            quality: 0.9,
            includeMetrics: true,
            includeFilters: true,
            backgroundColor: '#ffffff'
        };
        
        // Update UI
        if (this.elements.exportWidth) {
            this.elements.exportWidth.value = this.exportSettings.width;
        }
        if (this.elements.exportHeight) {
            this.elements.exportHeight.value = this.exportSettings.height;
        }
        if (this.elements.exportQuality) {
            this.elements.exportQuality.value = this.exportSettings.quality;
        }
    }
    
    // API methods for programmatic export
    async exportGraph(format = 'png', options = {}) {
        const originalSettings = { ...this.exportSettings };
        
        try {
            this.updateExportSettings({ format, ...options });
            await this.performExport();
        } finally {
            this.updateExportSettings(originalSettings);
        }
    }
    
    // Cleanup
    destroy() {
        // Clean up any ongoing exports
        this.isExporting = false;
        this.exportQueue = [];
        
        // Remove event listeners
        Object.values(this.elements).forEach(element => {
            if (element && element.removeEventListener) {
                // Note: This is a simplified cleanup
                // In practice, you'd need to store references to the specific listeners
            }
        });
        
        this.hideExportModal();
        this.hideExportProgress();
        
        console.log('ExportHandler destroyed');
    }
}

// Add CSS animations if not already present
if (!document.getElementById('export-animations')) {
    const style = document.createElement('style');
    style.id = 'export-animations';
    style.textContent = `
        @keyframes slideInRight {
            from { transform: translateX(100%); opacity: 0; }
            to { transform: translateX(0); opacity: 1; }
        }
        
        @keyframes fadeOut {
            from { opacity: 1; }
            to { opacity: 0; }
        }
    `;
    document.head.appendChild(style);
}

// Export for module systems
if (typeof module !== 'undefined' && module.exports) {
    module.exports = ExportHandler;
}

// Global availability
window.ExportHandler = ExportHandler;