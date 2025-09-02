#!/usr/bin/env python3
"""
Repository Analyst Agent Configuration for AutoGen v0.7.4
Updated to use v0.4 API patterns with enhanced security and performance
"""

import os
from typing import Dict, List, Any, Optional, Callable
from dataclasses import dataclass
from enum import Enum

# AutoGen v0.4 imports
from autogen_agentchat.agents import AssistantAgent
from autogen_ext.models.openai import OpenAIChatCompletionClient

class AnalysisType(Enum):
    """Types of analysis the Repo Analyst can perform"""
    CODE_STRUCTURE = "code_structure"
    DOCUMENTATION_DRIFT = "documentation_drift"
    DEPENDENCY_ANALYSIS = "dependency_analysis"
    QUALITY_METRICS = "quality_metrics"
    SECURITY_SCAN = "security_scan"
    PERFORMANCE_ANALYSIS = "performance_analysis"

@dataclass
class RepoAnalystConfig:
    """Configuration for Repo Analyst agent with v0.4 patterns"""
    name: str = "RepoAnalyst"
    model: str = "gpt-4o"
    temperature: float = 0.2
    max_tokens: int = 4000
    memory_type: str = "buffer"
    memory_max_tokens: int = 2000
    max_consecutive_auto_reply: int = 10
    human_input_mode: str = "NEVER"
    enable_code_execution: bool = False  # Analysts should not execute code

class RepoAnalystAgentV04:
    """Repository Analyst Agent with v0.4 API implementation"""
    
    def __init__(self, config: Optional[RepoAnalystConfig] = None):
        self.config = config or RepoAnalystConfig()
        self.model_client = self._create_model_client()
        self.system_message = self._build_system_message()
        self.tools = self._define_tools()
        
    def _create_model_client(self) -> OpenAIChatCompletionClient:
        """Create OpenAI model client with v0.4 pattern"""
        return OpenAIChatCompletionClient(
            model=self.config.model,
            temperature=self.config.temperature,
            api_key=os.getenv("OPENAI_API_KEY"),
            seed=42,
            max_tokens=self.config.max_tokens,
            response_format={"type": "json_object"},  # Structured output
            model_capabilities={
                "vision": False,
                "function_calling": True,
                "json_output": True,
                "structured_output": True
            }
        )
    
    def _build_system_message(self) -> str:
        """Build enhanced system message based on research findings"""
        return """You are a Repository Analyst Agent specialized in code analysis and documentation automation using v0.4 AutoGen patterns.

CRITICAL SECURITY REQUIREMENTS:
- Never execute arbitrary code
- Use only controlled, pre-defined functions
- Validate all inputs before processing
- Report security issues immediately

Your enhanced capabilities:
1. **Deterministic Analysis First**: Always use ripgrep, ctags, AST parsing before LLM reasoning
2. **Memory Management**: Maintain context with buffer memory (2000 token limit)
3. **Performance Optimization**: Monitor token usage, use caching when possible
4. **Structured Output**: Generate JSON/Markdown reports in standardized formats
5. **Evidence-Based**: Provide concrete examples and metrics for all findings

Your analysis tools (via controlled functions):
- analyze_with_ripgrep: Fast pattern-based code search
- analyze_with_ctags: Symbol indexing and navigation
- analyze_with_ast: PowerShell/Python AST parsing
- run_static_analysis: PSScriptAnalyzer, ESLint, Pylint
- detect_drift: Documentation vs code comparison
- generate_metrics: Code quality and complexity metrics

Analysis workflow:
1. Start with deterministic tools for accuracy
2. Build code graph and dependency map
3. Run static analysis for quality issues
4. Check documentation alignment
5. Synthesize findings with LLM reasoning
6. Generate structured reports

Output requirements:
- JSON format for programmatic processing
- Include confidence scores for findings
- Provide actionable recommendations
- Track analysis performance metrics
- Generate trend analysis when historical data available

Token optimization:
- Summarize large findings incrementally
- Use references instead of full content when possible
- Cache repeated analysis results
- Monitor usage with print_usage_summary()"""
    
    def _define_tools(self) -> Dict[str, Callable]:
        """Define controlled tools for the agent"""
        return {
            "analyze_with_ripgrep": self._analyze_with_ripgrep,
            "analyze_with_ctags": self._analyze_with_ctags,
            "analyze_with_ast": self._analyze_with_ast,
            "run_static_analysis": self._run_static_analysis,
            "detect_drift": self._detect_documentation_drift,
            "generate_metrics": self._generate_code_metrics
        }
    
    def create_agent(self) -> AssistantAgent:
        """Create the AutoGen AssistantAgent with v0.4 configuration"""
        return AssistantAgent(
            name=self.config.name,
            system_message=self.system_message,
            model_client=self.model_client,
            max_consecutive_auto_reply=self.config.max_consecutive_auto_reply,
            human_input_mode=self.config.human_input_mode,
            code_execution_config=False,  # No code execution for security
            memory_config={
                "memory_type": self.config.memory_type,
                "max_tokens": self.config.memory_max_tokens
            },
            function_map=self.tools
        )
    
    # Controlled tool implementations
    def _analyze_with_ripgrep(self, pattern: str, file_type: Optional[str] = None, 
                              path: str = ".", context_lines: int = 2) -> Dict[str, Any]:
        """Controlled ripgrep analysis (would call actual ripgrep via subprocess)"""
        return {
            "tool": "ripgrep",
            "pattern": pattern,
            "file_type": file_type,
            "matches": [],
            "file_count": 0,
            "match_count": 0
        }
    
    def _analyze_with_ctags(self, path: str = ".", languages: List[str] = None) -> Dict[str, Any]:
        """Controlled ctags analysis"""
        return {
            "tool": "ctags",
            "path": path,
            "symbols": {},
            "total_symbols": 0,
            "languages_detected": languages or []
        }
    
    def _analyze_with_ast(self, file_path: str, language: str = "python") -> Dict[str, Any]:
        """Controlled AST analysis"""
        return {
            "tool": "ast",
            "file": file_path,
            "language": language,
            "functions": [],
            "classes": [],
            "imports": [],
            "complexity": 0
        }
    
    def _run_static_analysis(self, path: str, analyzer: str) -> Dict[str, Any]:
        """Controlled static analysis"""
        analyzers = {
            "psscriptanalyzer": "PowerShell",
            "eslint": "JavaScript/TypeScript", 
            "pylint": "Python"
        }
        
        return {
            "tool": analyzer,
            "language": analyzers.get(analyzer, "Unknown"),
            "path": path,
            "issues": {
                "error": 0,
                "warning": 0,
                "info": 0
            },
            "sarif_output": None
        }
    
    def _detect_documentation_drift(self, code_path: str, doc_path: str) -> Dict[str, Any]:
        """Controlled documentation drift detection"""
        return {
            "tool": "drift_detection",
            "code_path": code_path,
            "doc_path": doc_path,
            "drift_score": 0.0,
            "outdated_sections": [],
            "missing_documentation": [],
            "recommendations": []
        }
    
    def _generate_code_metrics(self, path: str) -> Dict[str, Any]:
        """Generate code quality metrics"""
        return {
            "tool": "metrics",
            "path": path,
            "metrics": {
                "lines_of_code": 0,
                "cyclomatic_complexity": 0,
                "maintainability_index": 0,
                "technical_debt_ratio": 0.0,
                "test_coverage": 0.0
            },
            "trends": {}
        }
    
    def get_analysis_prompts(self) -> Dict[AnalysisType, str]:
        """Get optimized analysis prompts based on research"""
        return {
            AnalysisType.CODE_STRUCTURE: """
Analyze repository structure using deterministic tools first:
1. Use ripgrep to map file patterns and organization
2. Use ctags to index all symbols and dependencies
3. Parse AST for detailed function/class analysis
4. Generate component relationship graph
5. Identify architectural patterns and consistency
6. Calculate complexity metrics
7. Output structured JSON report with confidence scores
""".strip(),
            
            AnalysisType.DOCUMENTATION_DRIFT: """
Detect documentation drift systematically:
1. Extract code signatures using AST parsing
2. Parse documentation for API references
3. Compare timestamps of code vs documentation changes
4. Calculate drift score based on discrepancies
5. Identify missing or outdated documentation
6. Generate prioritized update list
7. Track token usage throughout analysis
""".strip(),
            
            AnalysisType.SECURITY_SCAN: """
Perform security analysis with controlled tools:
1. Use static analyzers for language-specific issues
2. Search for security patterns with ripgrep
3. Check for exposed credentials (controlled regex only)
4. Analyze permission and access patterns
5. Review input validation locations
6. Generate SARIF format security report
7. Never execute code, only analyze
""".strip()
        }

def create_repo_analyst_agent_v04(config: Optional[RepoAnalystConfig] = None) -> AssistantAgent:
    """Factory function to create v0.4 Repo Analyst agent"""
    analyst = RepoAnalystAgentV04(config)
    return analyst.create_agent()

if __name__ == "__main__":
    # Test the v0.4 configuration
    print("Repository Analyst Agent v0.4 Configuration")
    print("=" * 50)
    
    config = RepoAnalystConfig()
    analyst = RepoAnalystAgentV04(config)
    agent = analyst.create_agent()
    
    print(f"Agent Name: {agent.name}")
    print(f"Model Client: {analyst.model_client.model}")
    print(f"Memory Type: {config.memory_type}")
    print(f"Max Tokens: {config.memory_max_tokens}")
    print(f"Tools Available: {len(analyst.tools)}")
    for tool_name in analyst.tools.keys():
        print(f"  - {tool_name}")
    
    print("\n✅ Repo Analyst v0.4 agent configuration ready!")
    print("✅ Security: Code execution disabled")
    print("✅ Performance: Memory and token management configured")
    print("✅ Tools: Controlled functions only")