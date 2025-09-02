#!/usr/bin/env python3
"""
Repository Analyst Agent Configuration for AutoGen v0.7.4
Defines the Repo Analyst agent role for code analysis and documentation automation
"""

from typing import Dict, List, Any
from dataclasses import dataclass
from enum import Enum

class AnalysisType(Enum):
    """Types of analysis the Repo Analyst can perform"""
    CODE_STRUCTURE = "code_structure"
    DOCUMENTATION_DRIFT = "documentation_drift"
    DEPENDENCY_ANALYSIS = "dependency_analysis"
    QUALITY_METRICS = "quality_metrics"
    SECURITY_SCAN = "security_scan"
    PERFORMANCE_ANALYSIS = "performance_analysis"

@dataclass
class RepoAnalystCapabilities:
    """Capabilities and tools available to the Repo Analyst agent"""
    
    # Static analysis tools
    powershell_ast: bool = True           # PowerShell AST parsing
    ripgrep_search: bool = True           # Fast code search
    ctags_indexing: bool = True           # Symbol indexing
    eslint_analysis: bool = True          # JavaScript/TypeScript analysis
    pylint_analysis: bool = True          # Python code analysis
    psscriptanalyzer: bool = True         # PowerShell analysis
    
    # Code intelligence features
    code_graph_generation: bool = True    # Generate code relationship graphs
    pattern_recognition: bool = True      # Identify code patterns
    change_impact_analysis: bool = True   # Analyze change impacts
    
    # Documentation features
    doc_drift_detection: bool = True      # Detect documentation drift
    api_doc_generation: bool = True       # Generate API documentation
    markdown_processing: bool = True      # Process markdown files
    
    # Integration capabilities
    mcp_server_access: bool = True        # MCP server integration
    powershell_bridge: bool = True        # PowerShell command execution
    github_api: bool = True               # GitHub API access
    
    def get_available_tools(self) -> List[str]:
        """Get list of available tools"""
        tools = []
        for attr, enabled in self.__dict__.items():
            if enabled:
                tools.append(attr)
        return tools

class RepoAnalystAgent:
    """Repository Analyst Agent configuration and behavior"""
    
    def __init__(self, name: str = "RepoAnalyst"):
        self.name = name
        self.capabilities = RepoAnalystCapabilities()
        self.system_message = self._build_system_message()
        self.description = "Repository analysis and documentation automation specialist"
    
    def _build_system_message(self) -> str:
        """Build system message for the agent"""
        return """You are a Repository Analyst Agent specialized in code analysis and documentation automation.

Your primary responsibilities:
1. **Code Analysis**: Perform comprehensive analysis of PowerShell, Python, JavaScript, and C# codebases
2. **Documentation Maintenance**: Detect documentation drift and maintain up-to-date technical documentation
3. **Quality Assessment**: Evaluate code quality, identify technical debt, and suggest improvements
4. **Pattern Recognition**: Identify recurring patterns, anti-patterns, and architectural issues
5. **Change Impact Analysis**: Analyze how code changes affect other parts of the system

Your tools and capabilities:
- Static analysis tools (PSScriptAnalyzer, ESLint, Pylint)
- Code search and indexing (ripgrep, ctags)
- PowerShell AST parsing for deep code understanding
- Documentation generation (DocFX, TypeDoc, Sphinx, MkDocs)
- MCP server integration for standardized tool access
- GitHub API integration for repository management
- PowerShell bridge for Windows automation integration

Your working approach:
1. **Systematic Analysis**: Always start with deterministic tools before applying LLM reasoning
2. **Evidence-Based**: Provide concrete examples and metrics to support your findings
3. **Incremental Updates**: Focus on manageable, incremental improvements rather than wholesale rewrites
4. **Cross-Language**: Understand relationships between PowerShell, Python, C#, and JavaScript components
5. **Documentation First**: Ensure all analysis results are properly documented for team review

When analyzing repositories:
- Use ripgrep for fast file pattern matching
- Generate code graphs to understand component relationships
- Check for outdated documentation using drift detection
- Identify security and performance issues
- Suggest specific, actionable improvements

Always provide your analysis in structured formats (JSON, Markdown tables) for easy processing by other agents and humans."""
    
    def get_agent_config(self) -> Dict[str, Any]:
        """Get AutoGen agent configuration"""
        return {
            "name": self.name,
            "system_message": self.system_message,
            "description": self.description,
            "capabilities": self.capabilities.get_available_tools(),
            "max_consecutive_auto_reply": 10,
            "human_input_mode": "NEVER",
            "code_execution_config": False,
            "tools": [
                "powershell_bridge",
                "ripgrep_search", 
                "ctags_index",
                "static_analysis",
                "documentation_generation",
                "github_api"
            ]
        }
    
    def get_analysis_prompts(self) -> Dict[AnalysisType, str]:
        """Get analysis prompt templates for different analysis types"""
        return {
            AnalysisType.CODE_STRUCTURE: """
Analyze the code structure of this repository:
1. Identify main modules and their dependencies
2. Generate a component relationship graph
3. Assess architectural patterns and consistency
4. Identify potential refactoring opportunities
5. Document the analysis in structured format
            """.strip(),
            
            AnalysisType.DOCUMENTATION_DRIFT: """
Perform documentation drift analysis:
1. Compare code changes with documentation updates
2. Identify outdated API documentation
3. Find missing documentation for new features
4. Generate list of documentation update requirements
5. Prioritize updates based on impact and usage
            """.strip(),
            
            AnalysisType.DEPENDENCY_ANALYSIS: """
Analyze project dependencies:
1. Map all internal and external dependencies
2. Identify circular dependencies
3. Check for outdated or vulnerable dependencies
4. Assess dependency impact on performance
5. Recommend dependency optimization strategies
            """.strip(),
            
            AnalysisType.QUALITY_METRICS: """
Assess code quality metrics:
1. Run static analysis tools (PSScriptAnalyzer, ESLint, Pylint)
2. Calculate complexity metrics
3. Identify code duplication
4. Assess test coverage gaps
5. Generate quality improvement recommendations
            """.strip(),
            
            AnalysisType.SECURITY_SCAN: """
Perform security analysis:
1. Scan for security vulnerabilities
2. Check for exposed credentials or sensitive data
3. Analyze PowerShell execution policies and constraints
4. Review API security patterns
5. Generate security recommendations
            """.strip(),
            
            AnalysisType.PERFORMANCE_ANALYSIS: """
Analyze performance characteristics:
1. Identify performance bottlenecks in PowerShell scripts
2. Analyze memory usage patterns
3. Review async/parallel processing implementations
4. Assess database query performance
5. Recommend performance optimizations
            """.strip()
        }

def create_repo_analyst_agent(name: str = "RepoAnalyst") -> Dict[str, Any]:
    """Factory function to create Repo Analyst agent configuration"""
    agent = RepoAnalystAgent(name)
    return agent.get_agent_config()

def get_analysis_workflow() -> Dict[str, Any]:
    """Get the standard analysis workflow for the Repo Analyst"""
    return {
        "workflow_name": "Repository Analysis Pipeline",
        "stages": [
            {
                "name": "Initial Scan",
                "analysis_types": [AnalysisType.CODE_STRUCTURE.value],
                "tools": ["ripgrep_search", "ctags_index"],
                "duration_estimate": "2-5 minutes"
            },
            {
                "name": "Static Analysis",
                "analysis_types": [AnalysisType.QUALITY_METRICS.value, AnalysisType.SECURITY_SCAN.value],
                "tools": ["static_analysis", "powershell_bridge"],
                "duration_estimate": "5-15 minutes"
            },
            {
                "name": "Documentation Review",
                "analysis_types": [AnalysisType.DOCUMENTATION_DRIFT.value],
                "tools": ["documentation_generation", "github_api"],
                "duration_estimate": "3-10 minutes"
            },
            {
                "name": "Dependency Analysis",
                "analysis_types": [AnalysisType.DEPENDENCY_ANALYSIS.value, AnalysisType.PERFORMANCE_ANALYSIS.value],
                "tools": ["powershell_bridge", "static_analysis"],
                "duration_estimate": "5-20 minutes"
            }
        ],
        "total_duration_estimate": "15-50 minutes",
        "output_formats": ["JSON", "Markdown", "HTML", "PDF"]
    }

if __name__ == "__main__":
    # Test the configuration
    print("Repository Analyst Agent Configuration")
    print("=" * 50)
    
    agent_config = create_repo_analyst_agent()
    print(f"Agent Name: {agent_config['name']}")
    print(f"Tools: {', '.join(agent_config['tools'])}")
    print(f"Capabilities: {len(agent_config['capabilities'])} available")
    
    workflow = get_analysis_workflow()
    print(f"Workflow Stages: {len(workflow['stages'])}")
    print(f"Estimated Duration: {workflow['total_duration_estimate']}")
    
    print("\n✅ Repo Analyst agent configuration ready!")