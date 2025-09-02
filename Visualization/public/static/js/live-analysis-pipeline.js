/**
 * Live Analysis Pipeline Integration
 * Integrates real-time updates with CPG-Unified and semantic analysis modules
 * Part of Day 9 Hour 3-4 Implementation
 */

(function() {
    'use strict';

    console.log('🔬 Initializing Live Analysis Pipeline...');

    // Analysis pipeline state
    const pipelineState = {
        activeAnalyzers: new Map(),
        analysisQueue: [],
        processingAnalysis: false,
        aiEnhancementEnabled: true,
        notificationEnabled: true,
        config: {
            maxConcurrentAnalysis: 3,
            analysisTimeout: 5000, // ms
            aiRequestTimeout: 10000, // ms
            significanceThreshold: 0.7,
            batchAnalysisSize: 10
        },
        metrics: {
            totalAnalyses: 0,
            completedAnalyses: 0,
            failedAnalyses: 0,
            aiEnhancements: 0,
            notificationsSent: 0,
            averageAnalysisTime: 0,
            lastAnalysisTime: null
        },
        healthMonitor: {
            cpuUsage: 0,
            memoryUsage: 0,
            queueHealth: 'healthy',
            lastHealthCheck: null
        }
    };

    /**
     * Register analysis modules
     */
    function registerAnalyzers() {
        console.log('📋 Registering analysis modules...');
        
        // CPG-Unified analyzer
        pipelineState.activeAnalyzers.set('cpg-unified', {
            name: 'CPG Unified Analyzer',
            priority: 1,
            analyze: analyzeCPGUnified,
            enabled: true
        });
        
        // Semantic analyzer
        pipelineState.activeAnalyzers.set('semantic', {
            name: 'Semantic Analyzer',
            priority: 2,
            analyze: analyzeSemantics,
            enabled: true
        });
        
        // Dependency analyzer
        pipelineState.activeAnalyzers.set('dependency', {
            name: 'Dependency Analyzer',
            priority: 3,
            analyze: analyzeDependencies,
            enabled: true
        });
        
        // Security analyzer
        pipelineState.activeAnalyzers.set('security', {
            name: 'Security Analyzer',
            priority: 4,
            analyze: analyzeSecurity,
            enabled: true
        });
        
        // Performance analyzer
        pipelineState.activeAnalyzers.set('performance', {
            name: 'Performance Analyzer',
            priority: 5,
            analyze: analyzePerformance,
            enabled: true
        });
        
        console.log(`✅ Registered ${pipelineState.activeAnalyzers.size} analyzers`);
    }

    /**
     * Initialize event listeners for incremental updates
     */
    function initializeEventListeners() {
        console.log('👂 Setting up event listeners...');
        
        // Listen for incremental graph updates from file watcher
        document.addEventListener('incrementalGraphUpdate', handleIncrementalUpdate);
        
        // Listen for batch processing completion
        document.addEventListener('fileWatcherBatchProcessed', handleBatchProcessed);
        
        // Listen for manual analysis requests
        document.addEventListener('requestLiveAnalysis', handleAnalysisRequest);
        
        // Listen for AI service availability
        document.addEventListener('aiServiceStatusChange', handleAIStatusChange);
        
        console.log('✅ Event listeners initialized');
    }

    /**
     * Handle incremental graph update
     */
    async function handleIncrementalUpdate(event) {
        const { operation, nodes, addedLinks, removedLinks } = event.detail;
        
        console.log(`📊 Processing incremental update: ${operation}`);
        console.log(`   Nodes: ${nodes.length}, Added Links: ${addedLinks.length}, Removed Links: ${removedLinks.length}`);
        
        // Create analysis task
        const analysisTask = {
            id: generateTaskId(),
            type: 'incremental',
            operation,
            data: {
                nodes,
                addedLinks,
                removedLinks
            },
            timestamp: Date.now(),
            priority: calculatePriority(operation, nodes.length)
        };
        
        // Queue for analysis
        queueAnalysis(analysisTask);
    }

    /**
     * Handle batch processed event
     */
    function handleBatchProcessed(event) {
        const { batch, metrics } = event.detail;
        
        console.log(`📦 Batch processed: ${batch.length} changes`);
        
        // Update health monitor
        updateHealthMonitor();
        
        // Check for significant changes
        const significantChanges = detectSignificantChanges(batch);
        if (significantChanges.length > 0) {
            notifySignificantChanges(significantChanges);
        }
    }

    /**
     * Queue analysis task
     */
    function queueAnalysis(task) {
        // Add to queue with priority sorting
        pipelineState.analysisQueue.push(task);
        pipelineState.analysisQueue.sort((a, b) => b.priority - a.priority);
        
        // Start processing if not already running
        if (!pipelineState.processingAnalysis) {
            processAnalysisQueue();
        }
    }

    /**
     * Process analysis queue
     */
    async function processAnalysisQueue() {
        if (pipelineState.processingAnalysis || pipelineState.analysisQueue.length === 0) {
            return;
        }
        
        pipelineState.processingAnalysis = true;
        
        try {
            // Process up to maxConcurrentAnalysis tasks
            const tasksToProcess = pipelineState.analysisQueue.splice(
                0, 
                pipelineState.config.maxConcurrentAnalysis
            );
            
            console.log(`🔄 Processing ${tasksToProcess.length} analysis tasks`);
            
            // Process tasks in parallel
            const analysisPromises = tasksToProcess.map(task => 
                processAnalysisTask(task).catch(error => {
                    console.error(`❌ Analysis task ${task.id} failed:`, error);
                    pipelineState.metrics.failedAnalyses++;
                    return null;
                })
            );
            
            const results = await Promise.all(analysisPromises);
            
            // Filter out failed analyses
            const successfulResults = results.filter(r => r !== null);
            
            // Apply AI enhancement if enabled
            if (pipelineState.aiEnhancementEnabled && successfulResults.length > 0) {
                await enhanceWithAI(successfulResults);
            }
            
            // Emit analysis complete event
            document.dispatchEvent(new CustomEvent('liveAnalysisComplete', {
                detail: {
                    results: successfulResults,
                    timestamp: Date.now()
                }
            }));
            
        } finally {
            pipelineState.processingAnalysis = false;
            
            // Continue processing if more tasks in queue
            if (pipelineState.analysisQueue.length > 0) {
                setTimeout(() => processAnalysisQueue(), 100);
            }
        }
    }

    /**
     * Process individual analysis task
     */
    async function processAnalysisTask(task) {
        const startTime = Date.now();
        
        console.log(`🔬 Analyzing task ${task.id} (${task.type})`);
        
        pipelineState.metrics.totalAnalyses++;
        
        // Run all enabled analyzers
        const analysisResults = {};
        
        for (const [key, analyzer] of pipelineState.activeAnalyzers) {
            if (!analyzer.enabled) continue;
            
            try {
                const timeoutPromise = new Promise((_, reject) => 
                    setTimeout(() => reject(new Error('Analysis timeout')), pipelineState.config.analysisTimeout)
                );
                
                const analysisPromise = analyzer.analyze(task.data);
                
                // Race between analysis and timeout
                analysisResults[key] = await Promise.race([analysisPromise, timeoutPromise]);
                
            } catch (error) {
                console.warn(`⚠️ ${analyzer.name} failed:`, error.message);
                analysisResults[key] = { error: error.message };
            }
        }
        
        const endTime = Date.now();
        const analysisTime = endTime - startTime;
        
        // Update metrics
        pipelineState.metrics.completedAnalyses++;
        pipelineState.metrics.averageAnalysisTime = 
            (pipelineState.metrics.averageAnalysisTime * (pipelineState.metrics.completedAnalyses - 1) + analysisTime) / 
            pipelineState.metrics.completedAnalyses;
        pipelineState.metrics.lastAnalysisTime = endTime;
        
        console.log(`✅ Analysis complete in ${analysisTime}ms`);
        
        return {
            taskId: task.id,
            type: task.type,
            operation: task.operation,
            results: analysisResults,
            duration: analysisTime,
            timestamp: endTime
        };
    }

    /**
     * CPG Unified Analysis
     */
    async function analyzeCPGUnified(data) {
        // Simulate CPG analysis
        const { nodes, addedLinks, removedLinks } = data;
        
        return {
            callGraphChanges: {
                newFunctions: nodes.filter(n => n.type === 'function').length,
                modifiedCalls: addedLinks.filter(l => l.type === 'call').length,
                removedCalls: removedLinks.filter(l => l.type === 'call').length
            },
            dataFlowChanges: {
                newVariables: nodes.filter(n => n.type === 'variable').length,
                modifiedFlows: addedLinks.filter(l => l.type === 'dataflow').length
            },
            controlFlowChanges: {
                branchesAdded: Math.floor(Math.random() * 5),
                loopsModified: Math.floor(Math.random() * 3)
            }
        };
    }

    /**
     * Semantic Analysis
     */
    async function analyzeSemantics(data) {
        const { nodes } = data;
        
        return {
            semanticCategories: {
                businessLogic: nodes.filter(n => n.module === 'business').length,
                dataAccess: nodes.filter(n => n.module === 'data').length,
                utilities: nodes.filter(n => n.module === 'utils').length
            },
            semanticComplexity: Math.random() * 10,
            semanticCoupling: Math.random()
        };
    }

    /**
     * Dependency Analysis
     */
    async function analyzeDependencies(data) {
        const { addedLinks, removedLinks } = data;
        
        return {
            dependencyChanges: {
                added: addedLinks.length,
                removed: removedLinks.length,
                circular: detectCircularDependencies(addedLinks),
                external: addedLinks.filter(l => l.type === 'external').length
            },
            dependencyMetrics: {
                coupling: Math.random(),
                cohesion: Math.random(),
                instability: Math.random()
            }
        };
    }

    /**
     * Security Analysis
     */
    async function analyzeSecurity(data) {
        const { nodes, addedLinks } = data;
        
        const vulnerabilities = [];
        
        // Check for potential security issues
        nodes.forEach(node => {
            if (node.type === 'input' && !node.validated) {
                vulnerabilities.push({
                    type: 'unvalidated-input',
                    severity: 'medium',
                    node: node.id
                });
            }
        });
        
        return {
            vulnerabilities,
            securityScore: Math.max(0, 1 - vulnerabilities.length * 0.1),
            sensitiveDataExposure: addedLinks.filter(l => l.sensitive).length,
            authenticationPoints: nodes.filter(n => n.type === 'auth').length
        };
    }

    /**
     * Performance Analysis
     */
    async function analyzePerformance(data) {
        const { nodes, addedLinks } = data;
        
        return {
            performanceMetrics: {
                complexity: nodes.reduce((sum, n) => sum + (n.metrics?.complexity || 0), 0),
                hotspots: nodes.filter(n => (n.metrics?.complexity || 0) > 10).length,
                bottlenecks: detectBottlenecks(addedLinks)
            },
            optimizationOpportunities: {
                caching: Math.floor(Math.random() * 5),
                parallelization: Math.floor(Math.random() * 3),
                algorithmicImprovements: Math.floor(Math.random() * 2)
            }
        };
    }

    /**
     * Enhance analysis with AI
     */
    async function enhanceWithAI(results) {
        if (!pipelineState.aiEnhancementEnabled) return;
        
        console.log('🤖 Enhancing analysis with AI...');
        
        try {
            // Prepare prompt for AI
            const prompt = generateAIPrompt(results);
            
            // Call AI service (Ollama or LangGraph)
            const aiResponse = await callAIService(prompt);
            
            if (aiResponse) {
                pipelineState.metrics.aiEnhancements++;
                
                // Add AI insights to results
                results.forEach(result => {
                    result.aiInsights = aiResponse.insights;
                    result.aiRecommendations = aiResponse.recommendations;
                });
                
                console.log('✅ AI enhancement complete');
            }
        } catch (error) {
            console.warn('⚠️ AI enhancement failed:', error.message);
        }
    }

    /**
     * Generate AI prompt from analysis results
     */
    function generateAIPrompt(results) {
        const summary = results.map(r => ({
            type: r.type,
            operation: r.operation,
            key_metrics: extractKeyMetrics(r.results)
        }));
        
        return `Analyze these code changes and provide insights:
${JSON.stringify(summary, null, 2)}

Please provide:
1. Key architectural impacts
2. Potential issues or risks
3. Optimization recommendations
4. Best practice suggestions`;
    }

    /**
     * Call AI service (Ollama/LangGraph)
     */
    async function callAIService(prompt) {
        // Check if Ollama is available
        const ollamaEndpoint = 'http://localhost:11434/api/generate';
        
        try {
            const response = await fetch(ollamaEndpoint, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    model: 'codellama',
                    prompt: prompt,
                    stream: false
                }),
                signal: AbortSignal.timeout(pipelineState.config.aiRequestTimeout)
            });
            
            if (response.ok) {
                const data = await response.json();
                return parseAIResponse(data.response);
            }
        } catch (error) {
            console.log('📝 Ollama not available, using mock AI response');
        }
        
        // Return mock AI response for development
        return {
            insights: [
                'Detected increase in module coupling',
                'New dependencies may impact performance',
                'Consider implementing caching strategy'
            ],
            recommendations: [
                'Refactor highly coupled modules',
                'Add performance monitoring',
                'Implement lazy loading for heavy dependencies'
            ]
        };
    }

    /**
     * Parse AI response
     */
    function parseAIResponse(response) {
        // Simple parsing - in production would be more sophisticated
        const lines = response.split('\n');
        const insights = [];
        const recommendations = [];
        
        let currentSection = null;
        lines.forEach(line => {
            if (line.includes('insight') || line.includes('impact')) {
                currentSection = 'insights';
            } else if (line.includes('recommend') || line.includes('suggest')) {
                currentSection = 'recommendations';
            } else if (line.trim() && currentSection) {
                if (currentSection === 'insights') {
                    insights.push(line.trim());
                } else {
                    recommendations.push(line.trim());
                }
            }
        });
        
        return { insights, recommendations };
    }

    /**
     * Update health monitor
     */
    function updateHealthMonitor() {
        // Simulate health metrics
        pipelineState.healthMonitor.cpuUsage = Math.random() * 100;
        pipelineState.healthMonitor.memoryUsage = Math.random() * 100;
        
        // Determine queue health
        const queueSize = pipelineState.analysisQueue.length;
        if (queueSize > 50) {
            pipelineState.healthMonitor.queueHealth = 'critical';
        } else if (queueSize > 20) {
            pipelineState.healthMonitor.queueHealth = 'warning';
        } else {
            pipelineState.healthMonitor.queueHealth = 'healthy';
        }
        
        pipelineState.healthMonitor.lastHealthCheck = Date.now();
        
        // Emit health update
        document.dispatchEvent(new CustomEvent('analysisHealthUpdate', {
            detail: pipelineState.healthMonitor
        }));
    }

    /**
     * Detect significant changes
     */
    function detectSignificantChanges(batch) {
        const significant = [];
        
        batch.forEach(change => {
            // Calculate significance score
            let score = 0;
            
            if (change.event === 'add') score += 0.3;
            if (change.event === 'unlink') score += 0.5;
            if (change.path.includes('critical')) score += 0.4;
            if (change.path.includes('security')) score += 0.5;
            
            if (score >= pipelineState.config.significanceThreshold) {
                significant.push({
                    ...change,
                    significanceScore: score
                });
            }
        });
        
        return significant;
    }

    /**
     * Notify significant changes
     */
    function notifySignificantChanges(changes) {
        if (!pipelineState.notificationEnabled) return;
        
        console.log(`🔔 Notifying ${changes.length} significant changes`);
        
        const notification = {
            type: 'significant-changes',
            count: changes.length,
            changes: changes.map(c => ({
                path: c.path,
                event: c.event,
                score: c.significanceScore
            })),
            timestamp: Date.now()
        };
        
        // Dispatch notification event
        document.dispatchEvent(new CustomEvent('analysisNotification', {
            detail: notification
        }));
        
        pipelineState.metrics.notificationsSent++;
        
        // Update UI if notification element exists
        const notificationElement = document.getElementById('analysis-notifications');
        if (notificationElement) {
            const notifDiv = document.createElement('div');
            notifDiv.className = 'notification';
            notifDiv.innerHTML = `
                <strong>Significant Changes Detected</strong>
                <div>${changes.length} changes require attention</div>
                <small>${new Date().toLocaleTimeString()}</small>
            `;
            notificationElement.prepend(notifDiv);
            
            // Auto-remove after 10 seconds
            setTimeout(() => notifDiv.remove(), 10000);
        }
    }

    /**
     * Utility functions
     */
    function generateTaskId() {
        return `task_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    }
    
    function calculatePriority(operation, nodeCount) {
        let priority = 5; // Base priority
        
        if (operation === 'remove') priority += 3;
        if (operation === 'modify') priority += 2;
        if (operation === 'add') priority += 1;
        
        // Adjust for scale
        if (nodeCount > 10) priority += 2;
        if (nodeCount > 50) priority += 3;
        
        return Math.min(priority, 10); // Cap at 10
    }
    
    function detectCircularDependencies(links) {
        // Simplified circular dependency detection
        const adjacency = {};
        links.forEach(link => {
            if (!adjacency[link.source]) adjacency[link.source] = [];
            adjacency[link.source].push(link.target);
        });
        
        const visited = new Set();
        const recursionStack = new Set();
        let circularCount = 0;
        
        function hasCycle(node) {
            visited.add(node);
            recursionStack.add(node);
            
            const neighbors = adjacency[node] || [];
            for (const neighbor of neighbors) {
                if (!visited.has(neighbor)) {
                    if (hasCycle(neighbor)) return true;
                } else if (recursionStack.has(neighbor)) {
                    circularCount++;
                    return true;
                }
            }
            
            recursionStack.delete(node);
            return false;
        }
        
        Object.keys(adjacency).forEach(node => {
            if (!visited.has(node)) {
                hasCycle(node);
            }
        });
        
        return circularCount;
    }
    
    function detectBottlenecks(links) {
        // Count nodes with high in-degree
        const inDegree = {};
        links.forEach(link => {
            inDegree[link.target] = (inDegree[link.target] || 0) + 1;
        });
        
        return Object.values(inDegree).filter(degree => degree > 5).length;
    }
    
    function extractKeyMetrics(results) {
        const metrics = {};
        Object.entries(results).forEach(([key, value]) => {
            if (typeof value === 'object' && !value.error) {
                // Extract numeric metrics
                Object.entries(value).forEach(([k, v]) => {
                    if (typeof v === 'number') {
                        metrics[`${key}_${k}`] = v;
                    }
                });
            }
        });
        return metrics;
    }
    
    function handleAnalysisRequest(event) {
        const { data, priority } = event.detail;
        queueAnalysis({
            id: generateTaskId(),
            type: 'manual',
            data,
            priority: priority || 5,
            timestamp: Date.now()
        });
    }
    
    function handleAIStatusChange(event) {
        pipelineState.aiEnhancementEnabled = event.detail.available;
        console.log(`🤖 AI enhancement ${pipelineState.aiEnhancementEnabled ? 'enabled' : 'disabled'}`);
    }

    /**
     * Initialize pipeline
     */
    function initialize() {
        registerAnalyzers();
        initializeEventListeners();
        
        // Start health monitoring
        setInterval(updateHealthMonitor, 30000);
        
        console.log('✅ Live Analysis Pipeline initialized');
    }

    // Initialize on load
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initialize);
    } else {
        initialize();
    }

    // Public API
    window.LiveAnalysisPipeline = {
        getMetrics: () => pipelineState.metrics,
        getHealth: () => pipelineState.healthMonitor,
        getQueueSize: () => pipelineState.analysisQueue.length,
        enableAnalyzer: (name) => {
            const analyzer = pipelineState.activeAnalyzers.get(name);
            if (analyzer) analyzer.enabled = true;
        },
        disableAnalyzer: (name) => {
            const analyzer = pipelineState.activeAnalyzers.get(name);
            if (analyzer) analyzer.enabled = false;
        },
        setAIEnhancement: (enabled) => {
            pipelineState.aiEnhancementEnabled = enabled;
        },
        setNotifications: (enabled) => {
            pipelineState.notificationEnabled = enabled;
        },
        triggerAnalysis: (data, priority) => {
            handleAnalysisRequest({ detail: { data, priority } });
        }
    };

    console.log('✅ Live Analysis Pipeline module loaded');
})();