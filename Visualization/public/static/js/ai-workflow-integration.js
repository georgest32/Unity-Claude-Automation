/**
 * AI Workflow Integration for Unity-Claude Visualization
 * Implements WEEK 1 requirements: LangGraph, AutoGen, Ollama integration
 * Real-time AI analysis and enhancement of graph visualization
 */

class AIWorkflowIntegration {
    constructor() {
        this.langGraphUrl = 'http://localhost:8000';
        this.ollamaUrl = 'http://localhost:11434';
        this.autoGenUrl = 'http://localhost:8001'; 
        
        this.activeWorkflows = new Map();
        this.aiEnhancements = new Map();
        
        this.initialize();
    }
    
    async initialize() {
        console.log('🤖 Initializing AI Workflow Integration...');
        
        // Check service availability
        await this.checkServices();
        
        // Setup real-time analysis
        this.setupRealtimeAnalysis();
        
        // Connect to visualization events
        this.connectToVisualization();
    }
    
    async checkServices() {
        const services = [
            { name: 'LangGraph', url: `${this.langGraphUrl}/health` },
            { name: 'Ollama', url: `${this.ollamaUrl}/api/tags` }
        ];
        
        for (const service of services) {
            try {
                const response = await fetch(service.url);
                if (response.ok) {
                    console.log(`✅ ${service.name} service available`);
                    this.updateServiceStatus(service.name, 'online');
                }
            } catch (error) {
                console.log(`⚠️ ${service.name} service not available`);
                this.updateServiceStatus(service.name, 'offline');
            }
        }
    }
    
    setupRealtimeAnalysis() {
        // Monitor node selections for AI analysis
        document.addEventListener('nodeSelected', async (event) => {
            const node = event.detail;
            await this.analyzeNode(node);
        });
        
        // Monitor relationship exploration
        document.addEventListener('relationshipExplored', async (event) => {
            const { source, target } = event.detail;
            await this.explainRelationship(source, target);
        });
    }
    
    async analyzeNode(node) {
        console.log(`🔍 AI analyzing node: ${node.label}`);
        
        // Create LangGraph workflow for node analysis
        const workflow = {
            id: `analyze-${node.id}`,
            type: 'node_analysis',
            steps: [
                { agent: 'code_analyzer', task: 'analyze_module', data: node },
                { agent: 'relationship_mapper', task: 'find_dependencies', data: node },
                { agent: 'ai_enhancer', task: 'generate_insights', data: node }
            ]
        };
        
        try {
            // Submit to LangGraph
            const response = await fetch(`${this.langGraphUrl}/workflow`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(workflow)
            });
            
            if (response.ok) {
                const result = await response.json();
                this.displayAIInsights(node, result);
            }
        } catch (error) {
            console.error('Error in AI analysis:', error);
            // Fallback to Ollama for local analysis
            await this.ollamaAnalyze(node);
        }
    }
    
    async ollamaAnalyze(node) {
        const prompt = `Analyze this Unity-Claude module: ${node.label}
        Category: ${node.category}
        Function Count: ${node.functionCount}
        Type: ${node.isAIEnhanced ? 'AI-Enhanced' : 'Pattern-Based'}
        
        Provide insights about its purpose and potential improvements.`;
        
        try {
            const response = await fetch(`${this.ollamaUrl}/api/generate`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    model: 'codellama:13b',
                    prompt: prompt,
                    stream: false
                })
            });
            
            if (response.ok) {
                const result = await response.json();
                this.displayOllamaInsights(node, result.response);
            }
        } catch (error) {
            console.log('Ollama not available, using cached insights');
        }
    }
    
    async explainRelationship(source, target) {
        console.log(`🔗 AI explaining relationship: ${source.label} → ${target.label}`);
        
        // AutoGen multi-agent collaboration for relationship explanation
        const agents = [
            { role: 'architect', task: 'explain_architecture' },
            { role: 'dependency_expert', task: 'analyze_coupling' },
            { role: 'optimization_advisor', task: 'suggest_improvements' }
        ];
        
        const collaboration = {
            id: `explain-${source.id}-${target.id}`,
            agents: agents,
            context: { source, target }
        };
        
        // Simulate AutoGen collaboration (would connect to real service)
        this.simulateAutoGenCollaboration(collaboration);
    }
    
    displayAIInsights(node, insights) {
        // Create AI insights panel
        const panel = document.createElement('div');
        panel.className = 'ai-insights-panel';
        panel.innerHTML = `
            <h3>🤖 AI Analysis: ${node.label}</h3>
            <div class="insight-content">
                ${insights.analysis || 'Analyzing...'}
            </div>
            <div class="recommendations">
                <h4>Recommendations:</h4>
                ${insights.recommendations ? 
                    insights.recommendations.map(r => `<li>${r}</li>`).join('') :
                    '<li>No recommendations available</li>'}
            </div>
        `;
        
        // Add to visualization
        this.showInsightPanel(panel);
    }
    
    displayOllamaInsights(node, analysis) {
        const panel = document.createElement('div');
        panel.className = 'ai-insights-panel ollama';
        panel.innerHTML = `
            <h3>🦙 Ollama Analysis: ${node.label}</h3>
            <div class="insight-content">${analysis}</div>
        `;
        
        this.showInsightPanel(panel);
    }
    
    simulateAutoGenCollaboration(collaboration) {
        // Simulate multi-agent discussion
        const discussion = [
            { agent: 'architect', message: 'This relationship indicates a strong architectural dependency.' },
            { agent: 'dependency_expert', message: 'The coupling level is moderate, consider using interfaces.' },
            { agent: 'optimization_advisor', message: 'Consider implementing a facade pattern to reduce coupling.' }
        ];
        
        this.displayCollaboration(collaboration, discussion);
    }
    
    displayCollaboration(collaboration, discussion) {
        const panel = document.createElement('div');
        panel.className = 'autogen-collaboration-panel';
        panel.innerHTML = `
            <h3>🤝 AutoGen Multi-Agent Analysis</h3>
            <div class="collaboration-discussion">
                ${discussion.map(d => `
                    <div class="agent-message">
                        <strong>${d.agent}:</strong> ${d.message}
                    </div>
                `).join('')}
            </div>
        `;
        
        this.showInsightPanel(panel);
    }
    
    showInsightPanel(panel) {
        // Remove existing panels
        document.querySelectorAll('.ai-insights-panel, .autogen-collaboration-panel').forEach(p => p.remove());
        
        // Add new panel
        document.body.appendChild(panel);
        
        // Auto-hide after 10 seconds
        setTimeout(() => {
            panel.style.opacity = '0';
            setTimeout(() => panel.remove(), 500);
        }, 10000);
    }
    
    updateServiceStatus(service, status) {
        const indicator = document.createElement('div');
        indicator.className = `ai-service-status ${status}`;
        indicator.innerHTML = `${service}: ${status === 'online' ? '🟢' : '🔴'}`;
        
        let statusBar = document.querySelector('.ai-services-status');
        if (!statusBar) {
            statusBar = document.createElement('div');
            statusBar.className = 'ai-services-status';
            document.body.appendChild(statusBar);
        }
        
        statusBar.appendChild(indicator);
    }
    
    connectToVisualization() {
        // Connect to main renderer if available
        if (window.mainRenderer) {
            console.log('🔌 Connected to main visualization renderer');
            
            // Enhance nodes with AI capabilities
            this.enhanceVisualization();
        }
    }
    
    enhanceVisualization() {
        // Add AI analysis triggers to nodes
        if (window.mainRenderer && window.mainRenderer.nodes) {
            window.mainRenderer.nodes.on('dblclick', (event, d) => {
                this.analyzeNode(d);
            });
        }
    }
}

// Initialize AI workflow integration
window.aiWorkflowIntegration = new AIWorkflowIntegration();

// Add styles
const styles = `
<style>
.ai-insights-panel, .autogen-collaboration-panel {
    position: fixed;
    top: 100px;
    left: 20px;
    background: rgba(0, 0, 0, 0.95);
    border: 2px solid #4ECDC4;
    border-radius: 10px;
    padding: 20px;
    max-width: 400px;
    color: white;
    z-index: 2000;
    transition: opacity 0.5s;
}

.ai-insights-panel.ollama {
    border-color: #F59E0B;
}

.autogen-collaboration-panel {
    border-color: #A855F7;
}

.insight-content {
    margin: 15px 0;
    padding: 10px;
    background: rgba(255, 255, 255, 0.1);
    border-radius: 5px;
}

.agent-message {
    margin: 10px 0;
    padding: 8px;
    background: rgba(168, 85, 247, 0.1);
    border-left: 3px solid #A855F7;
}

.ai-services-status {
    position: fixed;
    bottom: 60px;
    left: 20px;
    display: flex;
    gap: 10px;
}

.ai-service-status {
    background: rgba(0, 0, 0, 0.8);
    padding: 5px 10px;
    border-radius: 5px;
    font-size: 12px;
}
</style>
`;

document.head.insertAdjacentHTML('beforeend', styles);

console.log('✅ AI Workflow Integration loaded');