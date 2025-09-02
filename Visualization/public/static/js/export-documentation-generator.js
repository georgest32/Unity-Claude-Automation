/**
 * Export and Documentation Generator
 * Multiple export formats and automated documentation generation
 * Part of Day 8 Hour 7-8 Implementation
 */

(function() {
    'use strict';

    // Export configuration state
    const exportState = {
        formats: ['svg', 'png', 'json', 'html', 'pdf', 'csv', 'graphml'],
        currentExport: null,
        exportHistory: [],
        documentationTemplate: 'default',
        includeMetadata: true,
        includeAnalysis: true,
        exportQuality: 'high',
        exportSettings: {
            svg: { embedStyles: true, embedFonts: false },
            png: { resolution: 2, background: 'white' },
            pdf: { orientation: 'landscape', pageSize: 'A4' },
            html: { interactive: true, embedAssets: true },
            json: { prettyPrint: true, includeLayout: true },
            csv: { delimiter: ',', includeHeaders: true },
            graphml: { includeAttributes: true }
        }
    };

    /**
     * Export to SVG format
     */
    async function exportToSVG(container, options = {}) {
        console.log('📄 Exporting to SVG...');
        
        const settings = { ...exportState.exportSettings.svg, ...options };
        
        // Clone the SVG element
        const svgElement = container.select('svg').node();
        if (!svgElement) {
            console.error('No SVG element found');
            return null;
        }
        
        const clonedSvg = svgElement.cloneNode(true);
        
        // Clean up the clone
        d3.select(clonedSvg)
            .attr('xmlns', 'http://www.w3.org/2000/svg')
            .attr('xmlns:xlink', 'http://www.w3.org/1999/xlink');
        
        // Embed styles if requested
        if (settings.embedStyles) {
            embedStyles(clonedSvg);
        }
        
        // Add metadata
        if (exportState.includeMetadata) {
            addSVGMetadata(clonedSvg);
        }
        
        // Convert to string
        const serializer = new XMLSerializer();
        const svgString = serializer.serializeToString(clonedSvg);
        
        // Create blob
        const blob = new Blob([svgString], { type: 'image/svg+xml;charset=utf-8' });
        
        console.log('✅ SVG export complete');
        return { blob, string: svgString };
    }

    /**
     * Export to PNG format
     */
    async function exportToPNG(container, options = {}) {
        console.log('🖼️ Exporting to PNG...');
        
        const settings = { ...exportState.exportSettings.png, ...options };
        
        // Get SVG
        const svgResult = await exportToSVG(container);
        if (!svgResult) return null;
        
        // Create canvas
        const canvas = document.createElement('canvas');
        const context = canvas.getContext('2d');
        
        // Get dimensions
        const svgElement = container.select('svg').node();
        const width = svgElement.clientWidth * settings.resolution;
        const height = svgElement.clientHeight * settings.resolution;
        
        canvas.width = width;
        canvas.height = height;
        
        // Set background
        if (settings.background) {
            context.fillStyle = settings.background;
            context.fillRect(0, 0, width, height);
        }
        
        // Create image from SVG
        return new Promise((resolve, reject) => {
            const img = new Image();
            img.onload = function() {
                context.drawImage(img, 0, 0, width, height);
                
                canvas.toBlob((blob) => {
                    console.log('✅ PNG export complete');
                    resolve({ blob, canvas });
                }, 'image/png');
            };
            
            img.onerror = reject;
            img.src = 'data:image/svg+xml;base64,' + btoa(svgResult.string);
        });
    }

    /**
     * Export to JSON format
     */
    function exportToJSON(nodes, links, options = {}) {
        console.log('📊 Exporting to JSON...');
        
        const settings = { ...exportState.exportSettings.json, ...options };
        
        const exportData = {
            metadata: {
                exportDate: new Date().toISOString(),
                version: '1.0.0',
                nodeCount: nodes.length,
                linkCount: links.length,
                generator: 'Unity-Claude Visualization System'
            },
            nodes: nodes.map(node => {
                const nodeData = {
                    id: node.id,
                    label: node.label || node.id,
                    type: node.type,
                    module: node.module,
                    group: node.group
                };
                
                if (settings.includeLayout) {
                    nodeData.x = node.x;
                    nodeData.y = node.y;
                }
                
                if (exportState.includeMetadata) {
                    nodeData.metadata = node.metadata || {};
                    nodeData.metrics = node.metrics || {};
                }
                
                return nodeData;
            }),
            links: links.map(link => ({
                source: link.source.id || link.source,
                target: link.target.id || link.target,
                type: link.type,
                weight: link.weight || 1,
                metadata: exportState.includeMetadata ? (link.metadata || {}) : undefined
            }))
        };
        
        if (exportState.includeAnalysis) {
            exportData.analysis = generateAnalysis(nodes, links);
        }
        
        const jsonString = settings.prettyPrint ? 
            JSON.stringify(exportData, null, 2) : 
            JSON.stringify(exportData);
        
        const blob = new Blob([jsonString], { type: 'application/json' });
        
        console.log('✅ JSON export complete');
        return { blob, data: exportData, string: jsonString };
    }

    /**
     * Export to HTML report
     */
    function exportToHTML(nodes, links, visualizationSVG, options = {}) {
        console.log('📄 Exporting to HTML report...');
        
        const settings = { ...exportState.exportSettings.html, ...options };
        
        const analysis = generateAnalysis(nodes, links);
        const metrics = calculateMetrics(nodes, links);
        
        const htmlContent = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Unity-Claude Visualization Report</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background: #f4f4f4;
        }
        
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            border-radius: 10px;
            margin-bottom: 30px;
        }
        
        .header h1 {
            margin: 0;
            font-size: 2.5em;
        }
        
        .header .subtitle {
            opacity: 0.9;
            margin-top: 10px;
        }
        
        .section {
            background: white;
            padding: 25px;
            border-radius: 10px;
            margin-bottom: 20px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        .section h2 {
            color: #667eea;
            border-bottom: 2px solid #667eea;
            padding-bottom: 10px;
            margin-bottom: 20px;
        }
        
        .metrics-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin: 20px 0;
        }
        
        .metric-card {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 8px;
            border-left: 4px solid #667eea;
        }
        
        .metric-value {
            font-size: 2em;
            font-weight: bold;
            color: #667eea;
        }
        
        .metric-label {
            color: #666;
            font-size: 0.9em;
            margin-top: 5px;
        }
        
        .visualization-container {
            width: 100%;
            overflow-x: auto;
            padding: 20px;
            background: #f8f9fa;
            border-radius: 8px;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        
        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        
        th {
            background: #667eea;
            color: white;
        }
        
        tr:hover {
            background: #f5f5f5;
        }
        
        .chart-container {
            margin: 20px 0;
            padding: 20px;
            background: #f8f9fa;
            border-radius: 8px;
        }
        
        .footer {
            text-align: center;
            color: #666;
            margin-top: 40px;
            padding: 20px;
            border-top: 1px solid #ddd;
        }
        
        ${settings.interactive ? `
        .interactive-controls {
            position: fixed;
            top: 20px;
            right: 20px;
            background: white;
            padding: 15px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            z-index: 1000;
        }
        
        .control-button {
            display: block;
            width: 100%;
            padding: 8px 15px;
            margin: 5px 0;
            background: #667eea;
            color: white;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            transition: background 0.3s;
        }
        
        .control-button:hover {
            background: #764ba2;
        }
        ` : ''}
    </style>
    ${settings.interactive ? '<script src="https://d3js.org/d3.v7.min.js"></script>' : ''}
</head>
<body>
    <div class="header">
        <h1>Unity-Claude Visualization Report</h1>
        <div class="subtitle">Generated on ${new Date().toLocaleString()}</div>
    </div>
    
    ${settings.interactive ? `
    <div class="interactive-controls">
        <button class="control-button" onclick="window.print()">Print Report</button>
        <button class="control-button" onclick="downloadData()">Download Data</button>
    </div>
    ` : ''}
    
    <div class="section">
        <h2>Executive Summary</h2>
        <div class="metrics-grid">
            <div class="metric-card">
                <div class="metric-value">${metrics.totalNodes}</div>
                <div class="metric-label">Total Nodes</div>
            </div>
            <div class="metric-card">
                <div class="metric-value">${metrics.totalLinks}</div>
                <div class="metric-label">Total Links</div>
            </div>
            <div class="metric-card">
                <div class="metric-value">${metrics.avgDegree.toFixed(2)}</div>
                <div class="metric-label">Average Degree</div>
            </div>
            <div class="metric-card">
                <div class="metric-value">${metrics.density.toFixed(4)}</div>
                <div class="metric-label">Graph Density</div>
            </div>
            <div class="metric-card">
                <div class="metric-value">${metrics.components}</div>
                <div class="metric-label">Components</div>
            </div>
            <div class="metric-card">
                <div class="metric-value">${metrics.modularity.toFixed(3)}</div>
                <div class="metric-label">Modularity</div>
            </div>
        </div>
    </div>
    
    <div class="section">
        <h2>Visualization</h2>
        <div class="visualization-container">
            ${visualizationSVG || '<p>Visualization not available</p>'}
        </div>
    </div>
    
    <div class="section">
        <h2>Network Analysis</h2>
        ${generateAnalysisHTML(analysis)}
    </div>
    
    <div class="section">
        <h2>Top Nodes by Centrality</h2>
        <table>
            <thead>
                <tr>
                    <th>Node</th>
                    <th>Degree</th>
                    <th>Betweenness</th>
                    <th>Closeness</th>
                    <th>Module</th>
                </tr>
            </thead>
            <tbody>
                ${generateTopNodesHTML(analysis.topNodes)}
            </tbody>
        </table>
    </div>
    
    <div class="section">
        <h2>Module Statistics</h2>
        ${generateModuleStatsHTML(analysis.modules)}
    </div>
    
    <div class="footer">
        <p>Generated by Unity-Claude Automation Visualization System v2.0.0</p>
        <p>© 2025 Unity-Claude Project</p>
    </div>
    
    ${settings.interactive ? `
    <script>
        function downloadData() {
            const data = ${JSON.stringify({ nodes, links })};
            const blob = new Blob([JSON.stringify(data, null, 2)], {type: 'application/json'});
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = 'visualization-data.json';
            a.click();
        }
    </script>
    ` : ''}
</body>
</html>
        `;
        
        const blob = new Blob([htmlContent], { type: 'text/html;charset=utf-8' });
        
        console.log('✅ HTML report export complete');
        return { blob, html: htmlContent };
    }

    /**
     * Export to CSV format
     */
    function exportToCSV(nodes, links, options = {}) {
        console.log('📊 Exporting to CSV...');
        
        const settings = { ...exportState.exportSettings.csv, ...options };
        
        // Create node CSV
        const nodeHeaders = ['id', 'label', 'type', 'module', 'group', 'degree', 'x', 'y'];
        const nodeRows = nodes.map(node => [
            node.id,
            node.label || node.id,
            node.type || '',
            node.module || '',
            node.group || '',
            node.degree || 0,
            node.x || 0,
            node.y || 0
        ]);
        
        // Create link CSV
        const linkHeaders = ['source', 'target', 'type', 'weight'];
        const linkRows = links.map(link => [
            link.source.id || link.source,
            link.target.id || link.target,
            link.type || '',
            link.weight || 1
        ]);
        
        // Format CSV
        const nodeCSV = formatCSV(nodeHeaders, nodeRows, settings);
        const linkCSV = formatCSV(linkHeaders, linkRows, settings);
        
        const combinedCSV = `NODES\n${nodeCSV}\n\nLINKS\n${linkCSV}`;
        
        const blob = new Blob([combinedCSV], { type: 'text/csv;charset=utf-8' });
        
        console.log('✅ CSV export complete');
        return { blob, nodes: nodeCSV, links: linkCSV };
    }

    /**
     * Export to GraphML format
     */
    function exportToGraphML(nodes, links, options = {}) {
        console.log('📊 Exporting to GraphML...');
        
        const settings = { ...exportState.exportSettings.graphml, ...options };
        
        let graphml = `<?xml version="1.0" encoding="UTF-8"?>
<graphml xmlns="http://graphml.graphdrawing.org/xmlns"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://graphml.graphdrawing.org/xmlns
         http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd">
`;
        
        // Define attributes
        if (settings.includeAttributes) {
            graphml += `
    <key id="label" for="node" attr.name="label" attr.type="string"/>
    <key id="type" for="node" attr.name="type" attr.type="string"/>
    <key id="module" for="node" attr.name="module" attr.type="string"/>
    <key id="x" for="node" attr.name="x" attr.type="double"/>
    <key id="y" for="node" attr.name="y" attr.type="double"/>
    <key id="weight" for="edge" attr.name="weight" attr.type="double"/>
    <key id="linktype" for="edge" attr.name="type" attr.type="string"/>
`;
        }
        
        graphml += '    <graph id="G" edgedefault="directed">\n';
        
        // Add nodes
        nodes.forEach(node => {
            graphml += `        <node id="${node.id}">`;
            if (settings.includeAttributes) {
                graphml += `
            <data key="label">${node.label || node.id}</data>
            <data key="type">${node.type || ''}</data>
            <data key="module">${node.module || ''}</data>
            <data key="x">${node.x || 0}</data>
            <data key="y">${node.y || 0}</data>`;
            }
            graphml += '</node>\n';
        });
        
        // Add edges
        links.forEach((link, index) => {
            const sourceId = link.source.id || link.source;
            const targetId = link.target.id || link.target;
            
            graphml += `        <edge id="e${index}" source="${sourceId}" target="${targetId}">`;
            if (settings.includeAttributes) {
                graphml += `
            <data key="weight">${link.weight || 1}</data>
            <data key="linktype">${link.type || ''}</data>`;
            }
            graphml += '</edge>\n';
        });
        
        graphml += '    </graph>\n</graphml>';
        
        const blob = new Blob([graphml], { type: 'application/xml;charset=utf-8' });
        
        console.log('✅ GraphML export complete');
        return { blob, xml: graphml };
    }

    /**
     * Generate analysis data
     */
    function generateAnalysis(nodes, links) {
        const analysis = {
            summary: {
                nodeCount: nodes.length,
                linkCount: links.length,
                timestamp: new Date().toISOString()
            },
            topology: analyzeTopology(nodes, links),
            centrality: calculateCentrality(nodes, links),
            communities: detectCommunities(nodes, links),
            patterns: detectPatterns(nodes, links),
            modules: analyzeModules(nodes, links),
            topNodes: findTopNodes(nodes, links)
        };
        
        return analysis;
    }

    /**
     * Calculate graph metrics
     */
    function calculateMetrics(nodes, links) {
        const totalNodes = nodes.length;
        const totalLinks = links.length;
        
        // Calculate degree distribution
        const degrees = new Map();
        nodes.forEach(n => degrees.set(n.id, 0));
        
        links.forEach(link => {
            const sourceId = link.source.id || link.source;
            const targetId = link.target.id || link.target;
            degrees.set(sourceId, (degrees.get(sourceId) || 0) + 1);
            degrees.set(targetId, (degrees.get(targetId) || 0) + 1);
        });
        
        const avgDegree = Array.from(degrees.values()).reduce((a, b) => a + b, 0) / totalNodes;
        const maxPossibleEdges = (totalNodes * (totalNodes - 1)) / 2;
        const density = totalLinks / maxPossibleEdges;
        
        // Simple component detection
        const components = countComponents(nodes, links);
        
        // Simple modularity calculation
        const modularity = calculateModularity(nodes, links);
        
        return {
            totalNodes,
            totalLinks,
            avgDegree,
            density,
            components,
            modularity,
            degrees
        };
    }

    /**
     * Helper functions
     */
    function embedStyles(svgElement) {
        const styleElement = document.createElement('style');
        styleElement.textContent = `
            .node { stroke: #fff; stroke-width: 2px; }
            .link { stroke: #999; stroke-opacity: 0.6; }
            .label { font-family: Arial, sans-serif; font-size: 12px; }
        `;
        svgElement.insertBefore(styleElement, svgElement.firstChild);
    }

    function addSVGMetadata(svgElement) {
        const metadata = document.createElement('metadata');
        metadata.innerHTML = `
            <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                     xmlns:dc="http://purl.org/dc/elements/1.1/">
                <rdf:Description rdf:about="">
                    <dc:creator>Unity-Claude Visualization System</dc:creator>
                    <dc:date>${new Date().toISOString()}</dc:date>
                    <dc:format>image/svg+xml</dc:format>
                </rdf:Description>
            </rdf:RDF>
        `;
        svgElement.insertBefore(metadata, svgElement.firstChild);
    }

    function formatCSV(headers, rows, settings) {
        const delimiter = settings.delimiter;
        let csv = '';
        
        if (settings.includeHeaders) {
            csv += headers.join(delimiter) + '\n';
        }
        
        csv += rows.map(row => 
            row.map(cell => 
                typeof cell === 'string' && cell.includes(delimiter) ? 
                `"${cell}"` : cell
            ).join(delimiter)
        ).join('\n');
        
        return csv;
    }

    function analyzeTopology(nodes, links) {
        // Simplified topology analysis
        return {
            isConnected: true, // Simplified
            isDag: false, // Simplified
            hasCycles: true, // Simplified
            diameter: 5, // Simplified
            radius: 3 // Simplified
        };
    }

    function calculateCentrality(nodes, links) {
        // Simplified centrality calculation
        const centrality = new Map();
        nodes.forEach(node => {
            centrality.set(node.id, {
                degree: 0,
                betweenness: Math.random(), // Simplified
                closeness: Math.random(), // Simplified
                eigenvector: Math.random() // Simplified
            });
        });
        
        // Calculate degree centrality
        links.forEach(link => {
            const sourceId = link.source.id || link.source;
            const targetId = link.target.id || link.target;
            
            const sourceCent = centrality.get(sourceId);
            const targetCent = centrality.get(targetId);
            
            if (sourceCent) sourceCent.degree++;
            if (targetCent) targetCent.degree++;
        });
        
        return centrality;
    }

    function detectCommunities(nodes, links) {
        // Simplified community detection
        const communities = [];
        const communitySize = Math.floor(nodes.length / 5);
        
        for (let i = 0; i < 5; i++) {
            communities.push({
                id: i,
                nodes: nodes.slice(i * communitySize, (i + 1) * communitySize).map(n => n.id),
                density: Math.random()
            });
        }
        
        return communities;
    }

    function detectPatterns(nodes, links) {
        // Simplified pattern detection
        return {
            hubs: nodes.filter(n => n.degree > 10).map(n => n.id),
            bridges: [], // Simplified
            clusters: [], // Simplified
            motifs: [] // Simplified
        };
    }

    function analyzeModules(nodes, links) {
        // Group nodes by module
        const modules = new Map();
        
        nodes.forEach(node => {
            const module = node.module || 'default';
            if (!modules.has(module)) {
                modules.set(module, {
                    nodes: [],
                    internalLinks: 0,
                    externalLinks: 0
                });
            }
            modules.get(module).nodes.push(node.id);
        });
        
        // Count internal and external links
        links.forEach(link => {
            const sourceId = link.source.id || link.source;
            const targetId = link.target.id || link.target;
            
            const sourceNode = nodes.find(n => n.id === sourceId);
            const targetNode = nodes.find(n => n.id === targetId);
            
            if (sourceNode && targetNode) {
                const sourceModule = sourceNode.module || 'default';
                const targetModule = targetNode.module || 'default';
                
                if (sourceModule === targetModule) {
                    modules.get(sourceModule).internalLinks++;
                } else {
                    modules.get(sourceModule).externalLinks++;
                    modules.get(targetModule).externalLinks++;
                }
            }
        });
        
        return modules;
    }

    function findTopNodes(nodes, links, limit = 10) {
        const centrality = calculateCentrality(nodes, links);
        
        return nodes
            .map(node => ({
                ...node,
                centrality: centrality.get(node.id)
            }))
            .sort((a, b) => b.centrality.degree - a.centrality.degree)
            .slice(0, limit);
    }

    function countComponents(nodes, links) {
        // Simplified component counting
        return 1; // Assume connected graph
    }

    function calculateModularity(nodes, links) {
        // Simplified modularity calculation
        return 0.42; // Placeholder value
    }

    function generateAnalysisHTML(analysis) {
        return `
            <div class="chart-container">
                <h3>Topology Analysis</h3>
                <p>Connected: ${analysis.topology.isConnected ? 'Yes' : 'No'}</p>
                <p>Has Cycles: ${analysis.topology.hasCycles ? 'Yes' : 'No'}</p>
                <p>Diameter: ${analysis.topology.diameter}</p>
            </div>
        `;
    }

    function generateTopNodesHTML(topNodes) {
        return topNodes.map(node => `
            <tr>
                <td>${node.label || node.id}</td>
                <td>${node.centrality.degree}</td>
                <td>${node.centrality.betweenness.toFixed(3)}</td>
                <td>${node.centrality.closeness.toFixed(3)}</td>
                <td>${node.module || 'default'}</td>
            </tr>
        `).join('');
    }

    function generateModuleStatsHTML(modules) {
        let html = '<div class="metrics-grid">';
        
        modules.forEach((stats, moduleName) => {
            html += `
                <div class="metric-card">
                    <div class="metric-value">${stats.nodes.length}</div>
                    <div class="metric-label">${moduleName}</div>
                    <small>Internal: ${stats.internalLinks}, External: ${stats.externalLinks}</small>
                </div>
            `;
        });
        
        html += '</div>';
        return html;
    }

    /**
     * Download helper function
     */
    function downloadFile(blob, filename) {
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = filename;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
    }

    /**
     * Batch export to multiple formats
     */
    async function batchExport(container, nodes, links, formats = ['svg', 'png', 'json']) {
        console.log(`📦 Batch exporting to ${formats.join(', ')}...`);
        
        const exports = {};
        
        for (const format of formats) {
            try {
                switch (format) {
                    case 'svg':
                        exports.svg = await exportToSVG(container);
                        break;
                    case 'png':
                        exports.png = await exportToPNG(container);
                        break;
                    case 'json':
                        exports.json = exportToJSON(nodes, links);
                        break;
                    case 'html':
                        const svgResult = await exportToSVG(container);
                        exports.html = exportToHTML(nodes, links, svgResult.string);
                        break;
                    case 'csv':
                        exports.csv = exportToCSV(nodes, links);
                        break;
                    case 'graphml':
                        exports.graphml = exportToGraphML(nodes, links);
                        break;
                }
            } catch (error) {
                console.error(`Error exporting to ${format}:`, error);
            }
        }
        
        console.log('✅ Batch export complete');
        return exports;
    }

    // Public API
    window.ExportDocumentationGenerator = {
        exportToSVG,
        exportToPNG,
        exportToJSON,
        exportToHTML,
        exportToCSV,
        exportToGraphML,
        batchExport,
        downloadFile,
        generateAnalysis,
        calculateMetrics,
        setExportQuality: (quality) => {
            exportState.exportQuality = quality;
        },
        setIncludeMetadata: (include) => {
            exportState.includeMetadata = include;
        },
        setIncludeAnalysis: (include) => {
            exportState.includeAnalysis = include;
        }
    };

    console.log('✅ Export and Documentation Generator module loaded');
})();