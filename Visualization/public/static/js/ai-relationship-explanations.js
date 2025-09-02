/**
 * Unity-Claude Automation - AI-Enhanced Relationship Explanations
 * Day 7 Hour 7-8: Integrate AI-enhanced explanations for relationship patterns
 * Built on Ollama local AI integration and intelligent architecture analysis
 */

// Global AI explanation state
let aiExplanationState = {
    isInitialized: false,
    ollamaEndpoint: '/api/ollama',
    activeExplanations: new Map(),
    explanationCache: new Map(),
    analysisQueue: [],
    isProcessing: false
};

// AI analysis configuration
const AI_CONFIG = {
    maxCacheSize: 100,
    explanationTimeout: 30000, // 30 seconds
    batchSize: 5,
    retryAttempts: 3,
    debounceMs: 500
};

// Explanation templates and prompts
const AI_PROMPTS = {
    relationshipExplanation: `Analyze this PowerShell module relationship and provide a clear technical explanation:

Module A: {sourceModule}
Module B: {targetModule}
Relationship Type: {relationshipType}
Strength: {strength}
Context: {context}

Provide a concise explanation covering:
1. What this relationship means technically
2. Why this dependency exists
3. Potential architectural implications
4. Suggestions for optimization if applicable

Keep response under 200 words and focus on actionable insights.`,

    architectureAnalysis: `Analyze this PowerShell module architecture pattern:

Modules: {moduleList}
Relationships: {relationshipSummary}
Complexity Metrics: {complexityMetrics}

Provide analysis covering:
1. Overall architectural pattern assessment
2. Potential design issues or anti-patterns
3. Recommendations for improvement
4. Scalability considerations

Keep response under 300 words and prioritize practical recommendations.`,

    optimizationSuggestions: `Provide optimization suggestions for this PowerShell module ecosystem:

Current State: {currentState}
Performance Metrics: {performanceMetrics}
Dependency Analysis: {dependencyAnalysis}

Suggest specific optimizations for:
1. Module organization and structure
2. Dependency management
3. Performance improvements
4. Maintainability enhancements

Provide actionable, specific recommendations under 250 words.`
};

/**
 * Initialize AI-enhanced relationship explanation system
 */
function initializeAIRelationshipExplanations() {
    console.log('🤖 Initializing AI-Enhanced Relationship Explanations...');
    
    // Verify Ollama connectivity
    initializeOllamaConnection();
    
    // Set up AI explanation UI
    setupAIExplanationUI();
    
    // Initialize explanation caching
    initializeExplanationCache();
    
    // Set up real-time analysis
    setupRealTimeAnalysis();
    
    // Initialize context-aware explanations
    initializeContextualExplanations();
    
    aiExplanationState.isInitialized = true;
    console.log('✅ AI relationship explanations initialized');
}

/**
 * Initialize Ollama connection and verify functionality
 */
async function initializeOllamaConnection() {
    console.log('🔗 Initializing Ollama AI connection...');
    
    try {
        // Test Ollama connectivity
        const response = await fetch(aiExplanationState.ollamaEndpoint + '/health', {
            method: 'GET',
            timeout: 5000
        });
        
        if (response.ok) {
            console.log('✅ Ollama AI service connected successfully');
            
            // Get available models
            const modelsResponse = await fetch(aiExplanationState.ollamaEndpoint + '/models');
            const modelsData = await modelsResponse.json();
            
            console.log('📊 Available AI models:', modelsData.models?.map(m => m.name) || ['None']);
            
        } else {
            throw new Error(`Ollama service not available: ${response.statusText}`);
        }
        
    } catch (error) {
        console.warn('⚠️ Ollama AI service not available, using mock responses:', error);
        
        // Set up mock AI for development
        setupMockAI();
    }
}

/**
 * Set up AI explanation UI components
 */
function setupAIExplanationUI() {
    console.log('🎨 Setting up AI explanation UI...');
    
    // Add AI explanation panel to exploration sidebar
    const sidebar = d3.select('.exploration-sidebar');
    
    const aiPanel = sidebar.append('div')
        .attr('class', 'ai-explanation-panel')
        .style('margin-top', '20px')
        .style('border-top', '1px solid #ddd')
        .style('padding-top', '20px');
    
    // Add AI panel header
    aiPanel.append('h3')
        .style('margin', '0 0 15px 0')
        .style('font-size', '16px')
        .style('display', 'flex')
        .style('align-items', 'center')
        .style('gap', '8px')
        .html('🤖 AI Insights');
    
    // Add AI status indicator
    const statusIndicator = aiPanel.append('div')
        .attr('class', 'ai-status-indicator')
        .style('display', 'flex')
        .style('align-items', 'center')
        .style('gap', '8px')
        .style('margin-bottom', '15px')
        .style('padding', '8px')
        .style('background', '#f0f8ff')
        .style('border-radius', '4px')
        .style('font-size', '12px');
    
    statusIndicator.append('div')
        .attr('class', 'status-dot')
        .style('width', '8px')
        .style('height', '8px')
        .style('border-radius', '50%')
        .style('background', '#4CAF50');
    
    statusIndicator.append('span')
        .text('AI Analysis Ready');
    
    // Add explanation container
    aiPanel.append('div')
        .attr('class', 'ai-explanation-content')
        .style('min-height', '100px')
        .style('background', '#f9f9f9')
        .style('border', '1px solid #ddd')
        .style('border-radius', '4px')
        .style('padding', '12px')
        .style('font-size', '12px')
        .style('line-height', '1.4')
        .html('<em>Select nodes or relationships to get AI-powered insights</em>');
    
    // Add AI action buttons
    const aiActions = aiPanel.append('div')
        .attr('class', 'ai-actions')
        .style('margin-top', '10px')
        .style('display', 'flex')
        .style('flex-direction', 'column')
        .style('gap', '5px');
    
    aiActions.append('button')
        .attr('class', 'explain-selection-btn')
        .style('padding', '6px 12px')
        .style('background', '#4CAF50')
        .style('color', 'white')
        .style('border', 'none')
        .style('border-radius', '4px')
        .style('cursor', 'pointer')
        .style('font-size', '12px')
        .text('🤖 Explain Selection')
        .on('click', explainSelectedNodes);
    
    aiActions.append('button')
        .attr('class', 'analyze-architecture-btn')
        .style('padding', '6px 12px')
        .style('background', '#2196F3')
        .style('color', 'white')
        .style('border', 'none')
        .style('border-radius', '4px')
        .style('cursor', 'pointer')
        .style('font-size', '12px')
        .text('📊 Analyze Architecture')
        .on('click', analyzeArchitecture);
    
    aiActions.append('button')
        .attr('class', 'suggest-optimizations-btn')
        .style('padding', '6px 12px')
        .style('background', '#FF9800')
        .style('color', 'white')
        .style('border', 'none')
        .style('border-radius', '4px')
        .style('cursor', 'pointer')
        .style('font-size', '12px')
        .text('⚡ Suggest Optimizations')
        .on('click', suggestOptimizations);
    
    console.log('🎨 AI explanation UI setup complete');
}

/**
 * Initialize explanation caching system
 */
function initializeExplanationCache() {
    console.log('💾 Initializing explanation cache...');
    
    // Set up cache cleanup interval
    setInterval(() => {
        if (aiExplanationState.explanationCache.size > AI_CONFIG.maxCacheSize) {
            // Remove oldest entries
            const entries = Array.from(aiExplanationState.explanationCache.entries());
            const toRemove = entries.slice(0, entries.length - AI_CONFIG.maxCacheSize);
            toRemove.forEach(([key]) => {
                aiExplanationState.explanationCache.delete(key);
            });
            
            console.log(`🧹 Cleaned up ${toRemove.length} cache entries`);
        }
    }, 60000); // Check every minute
    
    console.log('💾 Explanation cache initialized');
}

/**
 * Set up real-time analysis for node interactions
 */
function setupRealTimeAnalysis() {
    console.log('⚡ Setting up real-time AI analysis...');
    
    // Listen for node selection events
    document.addEventListener('nodeSelected', debounce(handleNodeSelection, AI_CONFIG.debounceMs));
    
    // Listen for relationship hover events
    document.addEventListener('relationshipHovered', debounce(handleRelationshipHover, AI_CONFIG.debounceMs));
    
    // Listen for temporal frame changes
    document.addEventListener('temporalFrameChanged', handleTemporalFrameChange);
    
    console.log('⚡ Real-time AI analysis setup complete');
}

/**
 * Initialize contextual explanations
 */
function initializeContextualExplanations() {
    console.log('📋 Initializing contextual explanations...');
    
    // Set up context-aware tooltip enhancements
    document.addEventListener('mouseenter', (event) => {
        if (event.target.classList.contains('node') || event.target.closest('.node')) {
            const nodeElement = event.target.closest('.node') || event.target;
            scheduleContextualExplanation(nodeElement);
        }
    }, true);
    
    // Set up proactive analysis triggers
    setupProactiveAnalysis();
    
    console.log('📋 Contextual explanations initialized');
}

/**
 * Explain selected nodes using AI
 */
async function explainSelectedNodes() {
    const selectedNodes = window.GraphRenderer?.selectedNodes;
    if (!selectedNodes || selectedNodes.size === 0) {
        displayAIMessage('Please select one or more nodes to explain', 'warning');
        return;
    }
    
    console.log(`🤖 Explaining ${selectedNodes.size} selected nodes...`);
    
    displayAIMessage('Analyzing selected nodes...', 'loading');
    
    try {
        const nodeIds = Array.from(selectedNodes);
        const graphData = window.GraphRenderer?.graphData;
        
        // Get node details
        const nodeDetails = nodeIds.map(id => 
            graphData.nodes.find(n => n.id === id)
        ).filter(Boolean);
        
        // Get relationships between selected nodes
        const relationships = getRelationshipsBetweenNodes(nodeIds, graphData);
        
        // Generate AI explanation
        const explanation = await generateNodeExplanation(nodeDetails, relationships);
        
        displayAIExplanation(explanation);
        
    } catch (error) {
        console.error('❌ Failed to explain nodes:', error);
        displayAIMessage('Failed to generate explanation. Please try again.', 'error');
    }
}

/**
 * Analyze overall architecture using AI
 */
async function analyzeArchitecture() {
    console.log('📊 Analyzing architecture with AI...');
    
    displayAIMessage('Analyzing overall architecture...', 'loading');
    
    try {
        const graphData = window.GraphRenderer?.graphData;
        if (!graphData) {
            throw new Error('No graph data available');
        }
        
        // Prepare architecture analysis data
        const architectureData = {
            moduleCount: graphData.nodes.filter(n => n.type === 'module').length,
            functionCount: graphData.nodes.filter(n => n.type === 'function').length,
            totalRelationships: graphData.links.length,
            complexityMetrics: calculateComplexityMetrics(graphData),
            dependencyPatterns: analyzeDependencyPatterns(graphData)
        };
        
        // Generate AI analysis
        const analysis = await generateArchitectureAnalysis(architectureData);
        
        displayAIExplanation(analysis);
        
    } catch (error) {
        console.error('❌ Failed to analyze architecture:', error);
        displayAIMessage('Failed to generate architecture analysis. Please try again.', 'error');
    }
}

/**
 * Suggest optimizations using AI
 */
async function suggestOptimizations() {
    console.log('⚡ Generating optimization suggestions...');
    
    displayAIMessage('Generating optimization suggestions...', 'loading');
    
    try {
        const graphData = window.GraphRenderer?.graphData;
        const performanceMetrics = gatherPerformanceMetrics();
        const dependencyAnalysis = performDependencyAnalysis(graphData);
        
        // Generate AI optimization suggestions
        const suggestions = await generateOptimizationSuggestions({
            graphData,
            performanceMetrics,
            dependencyAnalysis
        });
        
        displayAIExplanation(suggestions);
        
        // Add optimization action buttons
        addOptimizationActions(suggestions);
        
    } catch (error) {
        console.error('❌ Failed to generate optimization suggestions:', error);
        displayAIMessage('Failed to generate optimization suggestions. Please try again.', 'error');
    }
}

/**
 * Generate node explanation using AI
 */
async function generateNodeExplanation(nodes, relationships) {
    const cacheKey = `nodes_${nodes.map(n => n.id).sort().join('_')}`;
    
    // Check cache first
    if (aiExplanationState.explanationCache.has(cacheKey)) {
        console.log('💾 Using cached explanation');
        return aiExplanationState.explanationCache.get(cacheKey);
    }
    
    // Prepare context for AI analysis
    const context = {
        nodeCount: nodes.length,
        nodeTypes: [...new Set(nodes.map(n => n.type))],
        modules: [...new Set(nodes.map(n => n.module).filter(Boolean))],
        relationships: relationships.map(r => ({
            type: r.type,
            strength: r.strength,
            source: r.source,
            target: r.target
        }))
    };
    
    // Generate AI explanation
    const prompt = formatPrompt(AI_PROMPTS.relationshipExplanation, {
        sourceModule: nodes[0]?.module || 'Unknown',
        targetModule: nodes[1]?.module || 'Multiple',
        relationshipType: relationships[0]?.type || 'Various',
        strength: relationships[0]?.strength || 'N/A',
        context: JSON.stringify(context, null, 2)
    });
    
    const explanation = await callOllamaAPI(prompt);
    
    // Cache the result
    aiExplanationState.explanationCache.set(cacheKey, explanation);
    
    return explanation;
}

/**
 * Generate architecture analysis using AI
 */
async function generateArchitectureAnalysis(architectureData) {
    const cacheKey = `architecture_${JSON.stringify(architectureData).length}`;
    
    if (aiExplanationState.explanationCache.has(cacheKey)) {
        return aiExplanationState.explanationCache.get(cacheKey);
    }
    
    const prompt = formatPrompt(AI_PROMPTS.architectureAnalysis, {
        moduleList: architectureData.moduleCount + ' modules',
        relationshipSummary: `${architectureData.totalRelationships} relationships`,
        complexityMetrics: JSON.stringify(architectureData.complexityMetrics, null, 2)
    });
    
    const analysis = await callOllamaAPI(prompt);
    
    aiExplanationState.explanationCache.set(cacheKey, analysis);
    return analysis;
}

/**
 * Generate optimization suggestions using AI
 */
async function generateOptimizationSuggestions(data) {
    const cacheKey = `optimization_${Date.now().toString().slice(-6)}`;
    
    const prompt = formatPrompt(AI_PROMPTS.optimizationSuggestions, {
        currentState: `${data.graphData.nodes.length} nodes, ${data.graphData.links.length} links`,
        performanceMetrics: JSON.stringify(data.performanceMetrics, null, 2),
        dependencyAnalysis: JSON.stringify(data.dependencyAnalysis, null, 2)
    });
    
    const suggestions = await callOllamaAPI(prompt);
    
    aiExplanationState.explanationCache.set(cacheKey, suggestions);
    return suggestions;
}

/**
 * Call Ollama API with error handling and retries
 */
async function callOllamaAPI(prompt, retryCount = 0) {
    try {
        console.log('🤖 Calling Ollama API for AI analysis...');
        
        const response = await fetch(aiExplanationState.ollamaEndpoint + '/analyze', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                prompt: prompt,
                model: 'codellama',
                options: {
                    temperature: 0.7,
                    max_tokens: 400,
                    timeout: AI_CONFIG.explanationTimeout
                }
            }),
            signal: AbortSignal.timeout(AI_CONFIG.explanationTimeout)
        });
        
        if (!response.ok) {
            throw new Error(`Ollama API error: ${response.statusText}`);
        }
        
        const result = await response.json();
        
        if (result.success && result.explanation) {
            console.log('✅ AI explanation generated successfully');
            return result.explanation;
        } else {
            throw new Error('Invalid response format from Ollama API');
        }
        
    } catch (error) {
        console.error('❌ Ollama API call failed:', error);
        
        if (retryCount < AI_CONFIG.retryAttempts) {
            console.log(`🔄 Retrying API call (attempt ${retryCount + 1}/${AI_CONFIG.retryAttempts})...`);
            await new Promise(resolve => setTimeout(resolve, 1000 * (retryCount + 1)));
            return callOllamaAPI(prompt, retryCount + 1);
        }
        
        // Fallback to mock response
        return generateMockExplanation(prompt);
    }
}

/**
 * Display AI explanation in the UI
 */
function displayAIExplanation(explanation) {
    const contentPanel = d3.select('.ai-explanation-content');
    
    contentPanel
        .style('background', '#f0f8ff')
        .style('border-color', '#4CAF50')
        .html(formatExplanationHTML(explanation));
    
    // Add copy button
    contentPanel.append('button')
        .style('margin-top', '10px')
        .style('padding', '4px 8px')
        .style('background', '#607D8B')
        .style('color', 'white')
        .style('border', 'none')
        .style('border-radius', '3px')
        .style('cursor', 'pointer')
        .style('font-size', '11px')
        .text('📋 Copy')
        .on('click', () => {
            navigator.clipboard.writeText(explanation);
            d3.select(event.target).text('✅ Copied!');
            setTimeout(() => d3.select(event.target).text('📋 Copy'), 2000);
        });
}

/**
 * Display AI status/loading message
 */
function displayAIMessage(message, type = 'info') {
    const contentPanel = d3.select('.ai-explanation-content');
    
    const colors = {
        info: { bg: '#f0f8ff', border: '#2196F3' },
        loading: { bg: '#fff3e0', border: '#FF9800' },
        warning: { bg: '#fff8e1', border: '#FFC107' },
        error: { bg: '#ffebee', border: '#F44336' }
    };
    
    const color = colors[type] || colors.info;
    
    contentPanel
        .style('background', color.bg)
        .style('border-color', color.border)
        .html(`<em>${message}</em>`);
    
    if (type === 'loading') {
        // Add loading animation
        contentPanel.append('div')
            .style('margin-top', '10px')
            .style('text-align', 'center')
            .html('🤖 <span class="loading-dots">Thinking...</span>');
        
        // Animate loading dots
        let dotCount = 0;
        const loadingInterval = setInterval(() => {
            const dots = '.'.repeat((dotCount % 3) + 1);
            const loadingElement = contentPanel.select('.loading-dots');
            if (!loadingElement.empty()) {
                loadingElement.text(`Thinking${dots}`);
                dotCount++;
            } else {
                clearInterval(loadingInterval);
            }
        }, 500);
    }
}

/**
 * Handle node selection for AI analysis
 */
function handleNodeSelection(event) {
    const selectedNodes = event.detail?.selectedNodes || window.GraphRenderer?.selectedNodes;
    
    if (selectedNodes && selectedNodes.size > 0) {
        console.log(`🎯 Node selection changed: ${selectedNodes.size} nodes selected`);
        
        // Update selection info
        updateSelectionInfo(selectedNodes);
        
        // Queue AI analysis if enabled
        if (document.querySelector('.auto-explain-cb')?.checked) {
            queueAIAnalysis('node-selection', { nodeIds: Array.from(selectedNodes) });
        }
    }
}

/**
 * Handle relationship hover for contextual explanations
 */
function handleRelationshipHover(event) {
    const relationship = event.detail?.relationship;
    
    if (relationship) {
        console.log(`🔗 Relationship hovered: ${relationship.source} → ${relationship.target}`);
        
        // Show quick relationship info
        showQuickRelationshipInfo(relationship);
        
        // Queue AI analysis for detailed explanation
        queueAIAnalysis('relationship-hover', { relationship });
    }
}

/**
 * Handle temporal frame changes for evolution analysis
 */
function handleTemporalFrameChange(event) {
    const frame = event.detail?.frame;
    
    if (frame) {
        console.log(`🕒 Temporal frame changed: ${frame.timestamp}`);
        
        // Analyze changes in this frame
        if (frame.changes && frame.changes.length > 0) {
            queueAIAnalysis('temporal-change', { frame });
        }
    }
}

/**
 * Queue AI analysis task
 */
function queueAIAnalysis(type, data) {
    const task = {
        id: `${type}_${Date.now()}`,
        type: type,
        data: data,
        timestamp: Date.now()
    };
    
    aiExplanationState.analysisQueue.push(task);
    
    if (!aiExplanationState.isProcessing) {
        processAIAnalysisQueue();
    }
}

/**
 * Process AI analysis queue
 */
async function processAIAnalysisQueue() {
    if (aiExplanationState.isProcessing || aiExplanationState.analysisQueue.length === 0) {
        return;
    }
    
    aiExplanationState.isProcessing = true;
    
    while (aiExplanationState.analysisQueue.length > 0) {
        const task = aiExplanationState.analysisQueue.shift();
        
        try {
            await processAIAnalysisTask(task);
        } catch (error) {
            console.error('❌ AI analysis task failed:', error);
        }
        
        // Small delay between tasks
        await new Promise(resolve => setTimeout(resolve, 100));
    }
    
    aiExplanationState.isProcessing = false;
}

/**
 * Process individual AI analysis task
 */
async function processAIAnalysisTask(task) {
    switch (task.type) {
        case 'node-selection':
            await handleNodeSelectionAnalysis(task.data);
            break;
        case 'relationship-hover':
            await handleRelationshipHoverAnalysis(task.data);
            break;
        case 'temporal-change':
            await handleTemporalChangeAnalysis(task.data);
            break;
        default:
            console.warn('Unknown AI analysis task type:', task.type);
    }
}

/**
 * Setup mock AI for development/testing
 */
function setupMockAI() {
    console.log('🧪 Setting up mock AI for development...');
    
    window.MockAI = {
        generateExplanation: (prompt) => {
            return `Mock AI Analysis:\n\nThis is a simulated AI explanation for the selected PowerShell modules and their relationships. The analysis would normally cover:\n\n1. Technical relationship details\n2. Architectural implications\n3. Optimization opportunities\n4. Best practices recommendations\n\nIn production, this would be powered by Ollama local AI models with CodeLlama for technical analysis.`;
        }
    };
    
    console.log('🧪 Mock AI setup complete');
}

/**
 * Generate mock explanation for development
 */
function generateMockExplanation(prompt) {
    const explanations = [
        "This PowerShell module relationship represents a strong dependency pattern commonly found in automation systems. The high coupling suggests shared functionality that could benefit from refactoring into a common utility module.",
        "The relationship pattern indicates a well-structured modular design with clear separation of concerns. The dependency strength suggests optimal cohesion without excessive coupling.",
        "This architecture shows signs of circular dependencies that may impact maintainability. Consider implementing dependency injection or event-driven patterns to reduce tight coupling.",
        "The module interaction pattern demonstrates good architectural principles with clear data flow and minimal cross-cutting concerns. Performance appears optimal for the current complexity level."
    ];
    
    return explanations[Math.floor(Math.random() * explanations.length)];
}

/**
 * Helper functions for AI analysis
 */
function formatPrompt(template, variables) {
    return template.replace(/\{(\w+)\}/g, (match, key) => {
        return variables[key] || match;
    });
}

function formatExplanationHTML(explanation) {
    // Convert plain text explanation to formatted HTML
    return explanation
        .replace(/\n\n/g, '</p><p>')
        .replace(/\n/g, '<br>')
        .replace(/^/, '<p>')
        .replace(/$/, '</p>')
        .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
        .replace(/\*(.*?)\*/g, '<em>$1</em>');
}

function getRelationshipsBetweenNodes(nodeIds, graphData) {
    return graphData.links.filter(link => {
        const sourceId = link.source.id || link.source;
        const targetId = link.target.id || link.target;
        return nodeIds.includes(sourceId) || nodeIds.includes(targetId);
    });
}

function calculateComplexityMetrics(graphData) {
    return {
        averageConnections: graphData.links.length / graphData.nodes.length,
        maxConnections: Math.max(...graphData.nodes.map(n => 
            graphData.links.filter(l => 
                (l.source.id || l.source) === n.id || 
                (l.target.id || l.target) === n.id
            ).length
        )),
        networkDensity: (2 * graphData.links.length) / (graphData.nodes.length * (graphData.nodes.length - 1))
    };
}

function analyzeDependencyPatterns(graphData) {
    const patterns = {
        fanOut: 0, // Nodes with many outgoing connections
        fanIn: 0,  // Nodes with many incoming connections
        isolation: 0, // Nodes with few connections
        hubs: [] // High-connectivity nodes
    };
    
    graphData.nodes.forEach(node => {
        const outgoing = graphData.links.filter(l => (l.source.id || l.source) === node.id).length;
        const incoming = graphData.links.filter(l => (l.target.id || l.target) === node.id).length;
        const total = outgoing + incoming;
        
        if (outgoing > 5) patterns.fanOut++;
        if (incoming > 5) patterns.fanIn++;
        if (total < 2) patterns.isolation++;
        if (total > 10) patterns.hubs.push({ id: node.id, connections: total });
    });
    
    return patterns;
}

function gatherPerformanceMetrics() {
    return {
        renderTime: window.performance?.measure ? 'Available' : 'Not measured',
        frameRate: window.fps || 0,
        nodeCount: window.GraphRenderer?.graphData?.nodes?.length || 0,
        linkCount: window.GraphRenderer?.graphData?.links?.length || 0,
        memoryUsage: 'Not available in browser context'
    };
}

function performDependencyAnalysis(graphData) {
    if (!graphData) return {};
    
    const analysis = {
        totalDependencies: graphData.links.length,
        strongDependencies: graphData.links.filter(l => (l.strength || 0) > 5).length,
        weakDependencies: graphData.links.filter(l => (l.strength || 0) <= 2).length,
        moduleGroups: [...new Set(graphData.nodes.map(n => n.module).filter(Boolean))].length
    };
    
    return analysis;
}

function updateSelectionInfo(selectedNodes) {
    const selectionDetails = d3.select('.selection-details');
    
    if (selectedNodes.size === 0) {
        selectionDetails.text('No nodes selected');
        return;
    }
    
    const graphData = window.GraphRenderer?.graphData;
    const nodeDetails = Array.from(selectedNodes).map(id => 
        graphData.nodes.find(n => n.id === id)
    ).filter(Boolean);
    
    const summary = `
        Selected: ${selectedNodes.size} nodes
        Types: ${[...new Set(nodeDetails.map(n => n.type))].join(', ')}
        Modules: ${[...new Set(nodeDetails.map(n => n.module).filter(Boolean))].join(', ') || 'None'}
    `;
    
    selectionDetails.html(summary.replace(/\n\s+/g, '<br>'));
}

/**
 * Setup proactive analysis triggers
 */
function setupProactiveAnalysis() {
    // Analyze when significant changes occur
    document.addEventListener('nodeGroupCollapsed', (event) => {
        const detail = event.detail;
        displayAIMessage(`Analyzing impact of collapsing ${detail.groupKey} (${detail.nodeCount} nodes)...`, 'loading');
        
        setTimeout(() => {
            const mockAnalysis = `Collapsing ${detail.groupKey} simplifies the view while maintaining ${detail.nodeCount} internal relationships. This abstraction level is helpful for high-level architectural overview.`;
            displayAIExplanation(mockAnalysis);
        }, 1500);
    });
    
    document.addEventListener('nodeGroupExpanded', (event) => {
        const detail = event.detail;
        displayAIMessage(`Analyzing expanded ${detail.groupKey} structure...`, 'loading');
        
        setTimeout(() => {
            const mockAnalysis = `Expanding ${detail.groupKey} reveals ${detail.nodeCount} detailed components. This level of detail is useful for understanding internal module architecture and optimization opportunities.`;
            displayAIExplanation(mockAnalysis);
        }, 1500);
    });
}

/**
 * Export AI relationship explanations functionality
 */
window.AIRelationshipExplanations = {
    initialize: initializeAIRelationshipExplanations,
    explainNodes: explainSelectedNodes,
    analyzeArchitecture: analyzeArchitecture,
    suggestOptimizations: suggestOptimizations,
    explanationState: () => aiExplanationState,
    generateExplanation: generateNodeExplanation
};

// Initialize when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeAIRelationshipExplanations);
} else {
    // Delay to ensure other components are initialized first
    setTimeout(initializeAIRelationshipExplanations, 300);
}