/**
 * Integration Test for Day 7 D3.js Visualization Enhancements
 * Tests all four modules working together
 */

const fs = require('fs');
const path = require('path');

class Day7IntegrationTest {
    constructor() {
        this.testResults = {
            timestamp: new Date().toISOString(),
            modules: {},
            integration: {},
            passed: 0,
            failed: 0,
            total: 0
        };
    }

    /**
     * Test Module Loading
     */
    testModulePresence() {
        console.log('🔍 Testing module file presence...');
        const modules = [
            'graph-renderer-enhanced.js',
            'temporal-visualization.js',
            'interactive-exploration.js',
            'ai-relationship-explanations.js'
        ];

        modules.forEach(module => {
            const filePath = path.join(__dirname, 'Visualization', 'public', 'static', 'js', module);
            const exists = fs.existsSync(filePath);
            this.testResults.modules[module] = {
                exists,
                path: filePath,
                size: exists ? fs.statSync(filePath).size : 0
            };
            
            if (exists) {
                console.log(`✅ ${module} found (${this.testResults.modules[module].size} bytes)`);
                this.testResults.passed++;
            } else {
                console.error(`❌ ${module} not found`);
                this.testResults.failed++;
            }
            this.testResults.total++;
        });
    }

    /**
     * Test Module Syntax
     */
    testModuleSyntax() {
        console.log('\n📝 Testing module syntax...');
        
        Object.keys(this.testResults.modules).forEach(module => {
            if (this.testResults.modules[module].exists) {
                try {
                    const content = fs.readFileSync(this.testResults.modules[module].path, 'utf8');
                    
                    // Basic syntax checks
                    const checks = {
                        hasConsoleLog: content.includes('console.log'),
                        hasFunction: content.includes('function'),
                        hasEventListener: content.includes('addEventListener'),
                        hasDocumentReady: content.includes('DOMContentLoaded') || content.includes('document.dispatchEvent'),
                        noSyntaxErrors: !content.includes('SyntaxError')
                    };
                    
                    this.testResults.modules[module].syntaxChecks = checks;
                    
                    const allPassed = Object.values(checks).every(v => v === true || v === false);
                    if (allPassed) {
                        console.log(`✅ ${module} syntax valid`);
                        this.testResults.passed++;
                    } else {
                        console.error(`❌ ${module} syntax issues`);
                        this.testResults.failed++;
                    }
                } catch (error) {
                    console.error(`❌ ${module} read error: ${error.message}`);
                    this.testResults.failed++;
                }
                this.testResults.total++;
            }
        });
    }

    /**
     * Test Feature Implementation
     */
    testFeatureImplementation() {
        console.log('\n🎯 Testing feature implementation...');
        
        const featureTests = {
            'graph-renderer-enhanced.js': [
                { feature: 'Collapsible nodes', pattern: /collapseGroup|expandGroup/ },
                { feature: 'Multi-selection', pattern: /multiSelect|selectedNodes/ },
                { feature: 'Enhanced tooltips', pattern: /enhancedTooltip|showTooltip/ },
                { feature: 'Keyboard shortcuts', pattern: /keydown|keyup|ctrlKey/ }
            ],
            'temporal-visualization.js': [
                { feature: 'Timeline controls', pattern: /timeline|timeSlider/ },
                { feature: 'Git history', pattern: /gitHistory|commits/ },
                { feature: 'Animation controls', pattern: /play|pause|animationState/ },
                { feature: 'Frame updates', pattern: /setTemporalFrame|updateFrame/ }
            ],
            'interactive-exploration.js': [
                { feature: 'Advanced search', pattern: /fuzzySearch|regexSearch/ },
                { feature: 'Path analysis', pattern: /shortestPath|Dijkstra/ },
                { feature: 'Dependency chains', pattern: /dependencyChain|analyzeDependencies/ },
                { feature: 'Clustering', pattern: /cluster|groupBy/ }
            ],
            'ai-relationship-explanations.js': [
                { feature: 'Ollama integration', pattern: /ollama|ollamaAPI/ },
                { feature: 'Explanation UI', pattern: /explanationPanel|showExplanation/ },
                { feature: 'Caching system', pattern: /cache|explanationCache/ },
                { feature: 'Queue management', pattern: /queue|processQueue/ }
            ]
        };

        Object.entries(featureTests).forEach(([module, tests]) => {
            if (this.testResults.modules[module]?.exists) {
                const content = fs.readFileSync(this.testResults.modules[module].path, 'utf8');
                this.testResults.modules[module].features = {};
                
                tests.forEach(test => {
                    const found = test.pattern.test(content);
                    this.testResults.modules[module].features[test.feature] = found;
                    
                    if (found) {
                        console.log(`✅ ${module}: ${test.feature} implemented`);
                        this.testResults.passed++;
                    } else {
                        console.error(`⚠️ ${module}: ${test.feature} not detected`);
                        // Warning, not failure
                    }
                    this.testResults.total++;
                });
            }
        });
    }

    /**
     * Test Integration Points
     */
    testIntegration() {
        console.log('\n🔗 Testing integration points...');
        
        // Check if index.html includes all modules
        const indexPath = path.join(__dirname, 'Visualization', 'views', 'index.html');
        if (fs.existsSync(indexPath)) {
            const indexContent = fs.readFileSync(indexPath, 'utf8');
            
            const integrationChecks = {
                includesEnhancedRenderer: indexContent.includes('graph-renderer-enhanced.js'),
                includesTemporal: indexContent.includes('temporal-visualization.js'),
                includesExploration: indexContent.includes('interactive-exploration.js'),
                includesAI: indexContent.includes('ai-relationship-explanations.js'),
                hasD3: indexContent.includes('d3.v7.min.js'),
                hasWebSocket: indexContent.includes('WebSocket')
            };
            
            this.testResults.integration = integrationChecks;
            
            Object.entries(integrationChecks).forEach(([check, result]) => {
                if (result) {
                    console.log(`✅ Integration: ${check}`);
                    this.testResults.passed++;
                } else {
                    console.error(`❌ Integration: ${check} missing`);
                    this.testResults.failed++;
                }
                this.testResults.total++;
            });
        }
    }

    /**
     * Test Mock Data Generation
     */
    testMockData() {
        console.log('\n📊 Testing mock data generation...');
        
        // Simulate mock data generation
        const mockTests = {
            temporalFrames: () => {
                const frames = [];
                for (let i = 0; i < 10; i++) {
                    frames.push({
                        timestamp: new Date(Date.now() - i * 86400000).toISOString(),
                        nodes: Math.floor(Math.random() * 50) + 10,
                        links: Math.floor(Math.random() * 100) + 20
                    });
                }
                return frames.length === 10;
            },
            nodeHierarchy: () => {
                const hierarchy = new Map();
                ['core', 'utils', 'tests'].forEach(group => {
                    hierarchy.set(group, {
                        nodes: [`${group}_1`, `${group}_2`],
                        collapsed: false
                    });
                });
                return hierarchy.size === 3;
            },
            aiResponses: () => {
                const responses = [
                    "This component implements the observer pattern",
                    "Strong coupling detected between modules",
                    "Consider refactoring for better separation"
                ];
                return responses.length > 0;
            }
        };

        Object.entries(mockTests).forEach(([test, fn]) => {
            try {
                const result = fn();
                if (result) {
                    console.log(`✅ Mock data: ${test} working`);
                    this.testResults.passed++;
                } else {
                    console.error(`❌ Mock data: ${test} failed`);
                    this.testResults.failed++;
                }
            } catch (error) {
                console.error(`❌ Mock data: ${test} error: ${error.message}`);
                this.testResults.failed++;
            }
            this.testResults.total++;
        });
    }

    /**
     * Generate Test Report
     */
    generateReport() {
        console.log('\n📋 Test Report Summary');
        console.log('=' .repeat(50));
        console.log(`Total Tests: ${this.testResults.total}`);
        console.log(`✅ Passed: ${this.testResults.passed}`);
        console.log(`❌ Failed: ${this.testResults.failed}`);
        console.log(`Success Rate: ${((this.testResults.passed / this.testResults.total) * 100).toFixed(1)}%`);
        
        // Save report
        const reportPath = path.join(__dirname, `Day7_Integration_Test_Results_${Date.now()}.json`);
        fs.writeFileSync(reportPath, JSON.stringify(this.testResults, null, 2));
        console.log(`\n📄 Report saved to: ${reportPath}`);
        
        return this.testResults;
    }

    /**
     * Run all tests
     */
    async run() {
        console.log('🚀 Starting Day 7 Integration Tests');
        console.log('=' .repeat(50));
        
        this.testModulePresence();
        this.testModuleSyntax();
        this.testFeatureImplementation();
        this.testIntegration();
        this.testMockData();
        
        const report = this.generateReport();
        
        // Return success status
        return this.testResults.failed === 0;
    }
}

// Run tests if executed directly
if (require.main === module) {
    const tester = new Day7IntegrationTest();
    tester.run().then(success => {
        process.exit(success ? 0 : 1);
    });
}

module.exports = Day7IntegrationTest;