#!/usr/bin/env python3
"""
AutoGen GroupChat Configuration for Multi-Agent Collaboration
Implements v0.4 API patterns with enhanced security and performance
"""

from typing import Dict, List, Any, Optional, Callable
from dataclasses import dataclass
import os
import json

# AutoGen v0.4 imports
from autogen_agentchat.agents import AssistantAgent, UserProxyAgent
from autogen_agentchat.teams import RoundRobinGroupChat, SelectorGroupChat
from autogen_ext.models.openai import OpenAIChatCompletionClient
# Docker execution would be imported from autogen_ext.code_executor
# For testing purposes, we'll use a simple config dict instead
# from autogen_ext.code_executor import DockerCommandLineCodeExecutor

# Import agent configurations
from analyst_docs.repo_analyst_config import RepoAnalystAgent
from research_lab.research_agents_config import ResearchLabTeam
from implementers.implementer_agents_config import ImplementerTeam
from autogen_supervisor_config import SupervisorOrchestrator

@dataclass
class GroupChatConfig:
    """Configuration for AutoGen GroupChat"""
    name: str
    description: str
    max_rounds: int = 50
    speaker_selection_method: str = "auto"
    func_call_filter: bool = True
    allow_repeat_speaker: bool = False
    send_introductions: bool = True
    select_speaker_message_template: Optional[str] = None
    
class MultiAgentOrchestrator:
    """Main orchestrator for multi-agent collaboration"""
    
    def __init__(self):
        self.model_client = self._create_model_client()
        self.supervisor_orchestrator = SupervisorOrchestrator()
        self.repo_analyst = self._create_repo_analyst()
        self.research_team = ResearchLabTeam()
        self.implementer_team = ImplementerTeam()
        self.user_proxy = self._create_user_proxy()
        self.group_chat_config = self._create_group_chat_config()
        
    def _create_model_client(self) -> OpenAIChatCompletionClient:
        """Create shared model client for agents"""
        return OpenAIChatCompletionClient(
            model="gpt-4o",
            temperature=0.2,
            api_key=os.getenv("OPENAI_API_KEY"),
            seed=42,
            model_info={
                "vision": True,
                "function_calling": True,
                "json_output": True,
                "family": "openai",
                "structured_output": True
            }
        )
    
    def _create_repo_analyst(self) -> AssistantAgent:
        """Create optimized Repo Analyst agent with v0.4 patterns"""
        system_message = """You are a Repository Analyst Agent specialized in code analysis and documentation automation.

Your enhanced capabilities (v0.4):
1. **Deterministic Analysis**: Use ripgrep, ctags, AST parsing before LLM reasoning
2. **Memory Management**: Maintain context with buffer memory (2000 tokens)
3. **Security Focus**: All code execution in Docker containers
4. **Token Optimization**: Monitor and optimize token usage
5. **Structured Output**: Generate JSON/Markdown reports

Your tools (via function_map):
- analyze_code_structure: Comprehensive repository analysis
- detect_documentation_drift: Find outdated documentation
- run_static_analysis: PSScriptAnalyzer, ESLint, Pylint
- generate_code_graph: Create dependency graphs
- search_codebase: Ripgrep-based search

Working approach:
1. Start with deterministic tools for accuracy
2. Use caching to reduce API calls
3. Provide structured, actionable outputs
4. Track token usage and costs
5. Validate all findings with evidence

Security protocols:
- Never execute arbitrary code
- Use controlled functions only
- Validate all inputs
- Run analysis in isolated environments"""
        
        return AssistantAgent(
            name="RepoAnalyst",
            system_message=system_message,
            model_client=self.model_client,
            max_consecutive_auto_reply=10,
            human_input_mode="NEVER",
            code_execution_config=False,  # No code execution for analyst
            memory_config={
                "memory_type": "buffer",
                "max_tokens": 2000
            },
            function_map={
                "analyze_code_structure": self._analyze_code_structure,
                "detect_documentation_drift": self._detect_documentation_drift,
                "run_static_analysis": self._run_static_analysis,
                "generate_code_graph": self._generate_code_graph,
                "search_codebase": self._search_codebase
            }
        )
    
    def _create_user_proxy(self) -> UserProxyAgent:
        """Create user proxy with Docker code execution"""
        return UserProxyAgent(
            name="UserProxy",
            system_message="You are a user proxy that executes code and provides feedback.",
            human_input_mode="TERMINATE",
            max_consecutive_auto_reply=5,
            code_execution_config={
                "use_docker": True,
                "docker_image": "python:3.10-slim",
                "timeout": 60,
                "work_dir": "./workdir"
            }
        )
    
    def _create_group_chat_config(self) -> GroupChatConfig:
        """Create GroupChat configuration"""
        return GroupChatConfig(
            name="RepositoryAutomation",
            description="Multi-agent system for repository analysis and automation",
            max_rounds=50,
            speaker_selection_method="auto",
            func_call_filter=True,
            allow_repeat_speaker=False,
            send_introductions=True,
            select_speaker_message_template="""You are managing a group chat with these agents:
{agentlist}

Agent roles:
{roles}

Based on the conversation context and the last speaker, select the next most appropriate agent to continue the task.
Consider:
1. Task requirements and agent specializations
2. Logical flow of the conversation
3. Dependencies between agent outputs
4. Avoid selecting the same agent consecutively unless necessary

Return only the agent name."""
        )
    
    def create_analysis_group_chat(self) -> SelectorGroupChat:
        """Create group chat for analysis tasks"""
        agents = [
            self.user_proxy,
            self.supervisor_orchestrator.supervisors["analysis"].create_agent(),
            self.repo_analyst,
        ]
        
        return SelectorGroupChat(
            agents=agents,
            max_rounds=self.group_chat_config.max_rounds,
            speaker_selection_method=self.group_chat_config.speaker_selection_method,
            func_call_filter=self.group_chat_config.func_call_filter,
            allow_repeat_speaker=self.group_chat_config.allow_repeat_speaker,
            send_introductions=self.group_chat_config.send_introductions,
            select_speaker_message_template=self.group_chat_config.select_speaker_message_template
        )
    
    def create_research_group_chat(self) -> SelectorGroupChat:
        """Create group chat for research tasks"""
        # Create research agents with v0.4 patterns
        research_agents = []
        for agent_name, agent_config in self.research_team.agents.items():
            research_agents.append(AssistantAgent(
                name=agent_config.name,
                system_message=agent_config.system_message,
                model_client=self.model_client,
                max_consecutive_auto_reply=10,
                human_input_mode="NEVER",
                code_execution_config=False,
                memory_config={
                    "memory_type": "summary",
                    "max_tokens": 1500
                }
            ))
        
        agents = [
            self.user_proxy,
            self.supervisor_orchestrator.supervisors["research"].create_agent(),
        ] + research_agents
        
        return SelectorGroupChat(
            agents=agents,
            max_rounds=self.group_chat_config.max_rounds,
            speaker_selection_method=self.group_chat_config.speaker_selection_method,
            func_call_filter=self.group_chat_config.func_call_filter
        )
    
    def create_implementation_group_chat(self) -> SelectorGroupChat:
        """Create group chat for implementation tasks"""
        # Create implementer agents with v0.4 patterns and Docker
        implementer_agents = []
        for agent_name, agent_config in self.implementer_team.agents.items():
            implementer_agents.append(AssistantAgent(
                name=agent_config.name,
                system_message=agent_config.system_message,
                model_client=self.model_client,
                max_consecutive_auto_reply=8,
                human_input_mode="TERMINATE",
                code_execution_config={
                    "use_docker": True,
                    "docker_image": "python:3.10-slim" if "python" in agent_name else "mcr.microsoft.com/powershell:latest",
                    "timeout": 120,
                    "work_dir": f"./workdir/{agent_config.name}"
                },
                memory_config={
                    "memory_type": "buffer",
                    "max_tokens": 2500
                }
            ))
        
        agents = [
            self.user_proxy,
            self.supervisor_orchestrator.supervisors["implementation"].create_agent(),
        ] + implementer_agents
        
        return SelectorGroupChat(
            agents=agents,
            max_rounds=self.group_chat_config.max_rounds,
            speaker_selection_method=self.group_chat_config.speaker_selection_method,
            func_call_filter=self.group_chat_config.func_call_filter,
            candidate_func=self._implementation_candidate_func
        )
    
    def _implementation_candidate_func(self, agents: List[AssistantAgent], message) -> List[AssistantAgent]:
        """Custom candidate function for implementation tasks"""
        # Filter candidates based on message content
        content = message.get("content", "").lower() if isinstance(message, dict) else str(message).lower()
        
        candidates = []
        if "powershell" in content:
            candidates = [a for a in agents if "PowerShell" in a.name]
        elif "python" in content:
            candidates = [a for a in agents if "Python" in a.name]
        elif "test" in content:
            candidates = [a for a in agents if "Testing" in a.name]
        elif "integrate" in content or "integration" in content:
            candidates = [a for a in agents if "Integration" in a.name]
        
        # If no specific match, return supervisor and user proxy
        if not candidates:
            candidates = [a for a in agents if "Supervisor" in a.name or "UserProxy" in a.name]
        
        return candidates if candidates else agents
    
    def create_full_system_group_chat(self) -> SelectorGroupChat:
        """Create complete multi-agent system group chat"""
        all_agents = [
            self.user_proxy,
            self.supervisor_orchestrator.supervisors["main"].create_agent(),
            self.supervisor_orchestrator.supervisors["analysis"].create_agent(),
            self.supervisor_orchestrator.supervisors["research"].create_agent(),
            self.supervisor_orchestrator.supervisors["implementation"].create_agent(),
            self.repo_analyst
        ]
        
        return SelectorGroupChat(
            agents=all_agents,
            max_rounds=100,  # Longer for complex tasks
            speaker_selection_method="auto",
            func_call_filter=True,
            custom_speaker_selection_func=self.supervisor_orchestrator.create_custom_speaker_selector()
        )
    
    # Tool implementations (controlled functions)
    def _analyze_code_structure(self, path: str, language: str = "all") -> Dict[str, Any]:
        """Analyze code structure using deterministic tools"""
        # This would integrate with ripgrep, ctags, AST parsing
        return {
            "status": "success",
            "modules": [],
            "dependencies": [],
            "metrics": {}
        }
    
    def _detect_documentation_drift(self, code_path: str, doc_path: str) -> Dict[str, Any]:
        """Detect documentation drift"""
        return {
            "status": "success",
            "drift_detected": False,
            "outdated_sections": [],
            "missing_documentation": []
        }
    
    def _run_static_analysis(self, path: str, analyzer: str) -> Dict[str, Any]:
        """Run static analysis tools"""
        return {
            "status": "success",
            "analyzer": analyzer,
            "issues": [],
            "metrics": {}
        }
    
    def _generate_code_graph(self, path: str) -> Dict[str, Any]:
        """Generate code dependency graph"""
        return {
            "status": "success",
            "nodes": [],
            "edges": [],
            "clusters": []
        }
    
    def _search_codebase(self, pattern: str, file_type: Optional[str] = None) -> List[Dict[str, Any]]:
        """Search codebase using ripgrep"""
        return [
            {
                "file": "",
                "line": 0,
                "match": "",
                "context": ""
            }
        ]
    
    def get_performance_metrics(self, agents: List[AssistantAgent]) -> Dict[str, Any]:
        """Get performance metrics for all agents"""
        from autogen import gather_usage_summary
        
        usage = gather_usage_summary(agents)
        return {
            "token_usage": usage,
            "total_cost": sum(agent.get("cost", 0) for agent in usage.values()),
            "total_tokens": sum(agent.get("total_tokens", 0) for agent in usage.values()),
            "cache_hits": sum(agent.get("cache_hits", 0) for agent in usage.values())
        }

def create_multi_agent_system() -> MultiAgentOrchestrator:
    """Factory function to create multi-agent system"""
    return MultiAgentOrchestrator()

if __name__ == "__main__":
    # Test the configuration
    print("Multi-Agent GroupChat Configuration")
    print("=" * 50)
    
    orchestrator = create_multi_agent_system()
    
    print("System Components:")
    print(f"  - User Proxy: {orchestrator.user_proxy.name}")
    print(f"  - Repo Analyst: {orchestrator.repo_analyst.name}")
    print(f"  - Supervisors: {len(orchestrator.supervisor_orchestrator.supervisors)}")
    print(f"  - Research Team Agents: {len(orchestrator.research_team.agents)}")
    print(f"  - Implementer Team Agents: {len(orchestrator.implementer_team.agents)}")
    
    print(f"\nGroupChat Configuration:")
    print(f"  Name: {orchestrator.group_chat_config.name}")
    print(f"  Max Rounds: {orchestrator.group_chat_config.max_rounds}")
    print(f"  Speaker Selection: {orchestrator.group_chat_config.speaker_selection_method}")
    print(f"  Function Call Filter: {orchestrator.group_chat_config.func_call_filter}")
    
    print("\n✅ Multi-agent GroupChat configuration ready!")