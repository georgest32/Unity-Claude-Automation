#!/usr/bin/env python3
"""
AutoGen Configuration with Claude/Anthropic Models
Best practice implementation based on 2025 research
"""

import os
from typing import Dict, Any, Optional
from dataclasses import dataclass
from enum import Enum

# AutoGen imports
from autogen_ext.models.anthropic import AnthropicChatCompletionClient
from autogen_agentchat.agents import AssistantAgent

class ClaudeModel(Enum):
    """Claude model variants for different tasks"""
    # Latest models as of 2025
    OPUS_4 = "claude-4-opus-20250820"  # Most capable, for orchestration
    SONNET_35 = "claude-3-5-sonnet-20240620"  # Balanced, for complex work
    HAIKU_35 = "claude-3-5-haiku-20241022"  # Fast, for simple tasks
    
    # Fallback models
    SONNET_3 = "claude-3-sonnet-20240229"
    HAIKU_3 = "claude-3-haiku-20240307"

@dataclass
class ClaudeAgentConfig:
    """Configuration for Claude-based agents"""
    name: str
    role: str
    model: ClaudeModel
    temperature: float = 0.2
    max_tokens: int = 4096
    use_reasoning: bool = True  # Claude's hybrid reasoning capability
    
class ClaudeModelStrategy:
    """
    Best practice model selection strategy based on Anthropic's research:
    - Complex orchestration: Opus 4
    - Code generation/analysis: Sonnet 3.5
    - Simple tasks/routing: Haiku 3.5
    """
    
    @staticmethod
    def select_model_for_task(task_type: str) -> ClaudeModel:
        """Select optimal Claude model based on task complexity"""
        model_mapping = {
            # Orchestration roles (high complexity)
            "main_supervisor": ClaudeModel.SONNET_35,  # Balance cost/performance
            "analysis_supervisor": ClaudeModel.SONNET_35,
            "research_supervisor": ClaudeModel.SONNET_35,
            "implementation_supervisor": ClaudeModel.SONNET_35,
            
            # Worker agents (task-specific)
            "repo_analyst": ClaudeModel.SONNET_35,  # Code analysis needs reasoning
            "code_generator": ClaudeModel.SONNET_35,  # Code generation
            "documentation": ClaudeModel.SONNET_35,  # Documentation needs quality
            "testing": ClaudeModel.HAIKU_35,  # Test running is simpler
            
            # Research agents (varied complexity)
            "architecture_researcher": ClaudeModel.SONNET_35,
            "performance_researcher": ClaudeModel.HAIKU_35,
            "security_researcher": ClaudeModel.SONNET_35,
            
            # Simple coordination
            "message_router": ClaudeModel.HAIKU_35,
            "status_tracker": ClaudeModel.HAIKU_35,
        }
        
        return model_mapping.get(task_type, ClaudeModel.HAIKU_35)

class ClaudeAgentFactory:
    """Factory for creating Claude-based AutoGen agents"""
    
    def __init__(self, api_key: Optional[str] = None):
        self.api_key = api_key or os.getenv("ANTHROPIC_API_KEY")
        if not self.api_key:
            raise ValueError("ANTHROPIC_API_KEY must be set")
    
    def create_claude_client(self, model: ClaudeModel, 
                            temperature: float = 0.2,
                            max_tokens: int = 4096) -> AnthropicChatCompletionClient:
        """Create Anthropic client with best practices"""
        return AnthropicChatCompletionClient(
            model=model.value,
            api_key=self.api_key,
            temperature=temperature,
            max_tokens=max_tokens,
            # Claude-specific parameters
            top_p=None,  # Don't use both temperature and top_p
            stop_sequences=None,
            metadata={
                "framework": "autogen",
                "version": "0.7.4"
            }
        )
    
    def create_supervisor_agent(self, name: str, role: str,
                               system_message: str) -> AssistantAgent:
        """Create supervisor agent with Claude Sonnet 3.5"""
        model = ClaudeModelStrategy.select_model_for_task(role)
        client = self.create_claude_client(
            model=model,
            temperature=0.1,  # Lower for consistency in orchestration
            max_tokens=4096
        )
        
        return AssistantAgent(
            name=name,
            system_message=system_message,
            model_client=client,
            max_consecutive_auto_reply=15,
            human_input_mode="TERMINATE",
            code_execution_config=False,  # Supervisors don't execute code
            memory_config={
                "memory_type": "buffer",
                "max_tokens": 2000
            }
        )
    
    def create_worker_agent(self, name: str, task_type: str,
                           system_message: str, 
                           enable_code_execution: bool = False) -> AssistantAgent:
        """Create worker agent with appropriate Claude model"""
        model = ClaudeModelStrategy.select_model_for_task(task_type)
        
        # Adjust temperature based on task
        temperature = 0.3 if "research" in task_type else 0.2
        
        client = self.create_claude_client(
            model=model,
            temperature=temperature,
            max_tokens=8192 if "code" in task_type else 4096
        )
        
        code_config = False
        if enable_code_execution:
            code_config = {
                "use_docker": True,
                "docker_image": "python:3.10-slim",
                "timeout": 120,
                "work_dir": f"./workdir/{name}"
            }
        
        return AssistantAgent(
            name=name,
            system_message=system_message,
            model_client=client,
            max_consecutive_auto_reply=10,
            human_input_mode="NEVER" if not enable_code_execution else "TERMINATE",
            code_execution_config=code_config,
            memory_config={
                "memory_type": "buffer" if "analyst" in task_type else "summary",
                "max_tokens": 2500 if "code" in task_type else 1500
            }
        )
    
    def create_multi_agent_team(self, team_type: str) -> Dict[str, AssistantAgent]:
        """
        Create a complete team using Claude models
        Based on Anthropic's research showing 90%+ improvement with multi-agent
        """
        teams = {
            "analysis": {
                "supervisor": ("AnalysisSupervisor", "analysis_supervisor"),
                "workers": [
                    ("RepoAnalyst", "repo_analyst"),
                    ("CodeReviewer", "code_generator"),
                    ("DocAnalyst", "documentation")
                ]
            },
            "research": {
                "supervisor": ("ResearchSupervisor", "research_supervisor"),
                "workers": [
                    ("ArchitectureResearcher", "architecture_researcher"),
                    ("PerformanceResearcher", "performance_researcher"),
                    ("SecurityResearcher", "security_researcher")
                ]
            },
            "implementation": {
                "supervisor": ("ImplementationSupervisor", "implementation_supervisor"),
                "workers": [
                    ("CodeGenerator", "code_generator"),
                    ("TestRunner", "testing"),
                    ("Deployer", "documentation")
                ]
            }
        }
        
        if team_type not in teams:
            raise ValueError(f"Unknown team type: {team_type}")
        
        team_config = teams[team_type]
        agents = {}
        
        # Create supervisor
        sup_name, sup_role = team_config["supervisor"]
        agents[sup_name] = self.create_supervisor_agent(
            name=sup_name,
            role=sup_role,
            system_message=f"You are the {sup_name} coordinating the {team_type} team."
        )
        
        # Create workers
        for worker_name, worker_type in team_config["workers"]:
            agents[worker_name] = self.create_worker_agent(
                name=worker_name,
                task_type=worker_type,
                system_message=f"You are {worker_name} specializing in {worker_type}.",
                enable_code_execution=(worker_type == "code_generator")
            )
        
        return agents

class ClaudeCostOptimizer:
    """Optimize costs while maintaining quality"""
    
    # Approximate costs per 1M tokens (as of 2025)
    COSTS = {
        ClaudeModel.OPUS_4: {"input": 15.0, "output": 75.0},
        ClaudeModel.SONNET_35: {"input": 3.0, "output": 15.0},
        ClaudeModel.HAIKU_35: {"input": 0.25, "output": 1.25}
    }
    
    @classmethod
    def estimate_cost(cls, model: ClaudeModel, 
                     input_tokens: int, output_tokens: int) -> float:
        """Estimate cost for a given model and token usage"""
        if model not in cls.COSTS:
            return 0.0
        
        costs = cls.COSTS[model]
        input_cost = (input_tokens / 1_000_000) * costs["input"]
        output_cost = (output_tokens / 1_000_000) * costs["output"]
        
        return input_cost + output_cost
    
    @classmethod
    def recommend_model(cls, task_complexity: str, 
                       budget_conscious: bool = True) -> ClaudeModel:
        """Recommend model based on task and budget"""
        if not budget_conscious:
            # Use best model for everything
            return ClaudeModel.SONNET_35
        
        # Cost-optimized selection
        complexity_map = {
            "high": ClaudeModel.SONNET_35,
            "medium": ClaudeModel.SONNET_35,  # Still use Sonnet for quality
            "low": ClaudeModel.HAIKU_35
        }
        
        return complexity_map.get(task_complexity, ClaudeModel.HAIKU_35)

# Best Practice Configuration Examples
BEST_PRACTICE_CONFIGS = {
    "high_quality": {
        "description": "Maximum quality, higher cost",
        "orchestrator": ClaudeModel.SONNET_35,
        "workers": ClaudeModel.SONNET_35,
        "simple_tasks": ClaudeModel.SONNET_35
    },
    "balanced": {
        "description": "Balance quality and cost (RECOMMENDED)",
        "orchestrator": ClaudeModel.SONNET_35,
        "workers": ClaudeModel.SONNET_35,
        "simple_tasks": ClaudeModel.HAIKU_35
    },
    "cost_optimized": {
        "description": "Minimize costs, acceptable quality",
        "orchestrator": ClaudeModel.HAIKU_35,
        "workers": ClaudeModel.SONNET_35,  # Keep quality for actual work
        "simple_tasks": ClaudeModel.HAIKU_35
    }
}

def get_recommended_configuration() -> Dict[str, Any]:
    """Get the recommended configuration based on best practices"""
    return {
        "profile": "balanced",
        "models": BEST_PRACTICE_CONFIGS["balanced"],
        "reasoning": """
        Based on Anthropic's research:
        1. Multi-agent Claude systems outperform single agents by 90%+
        2. Claude Sonnet 3.5 provides best balance of quality/cost
        3. Use Haiku for simple routing/coordination tasks
        4. Keep code generation/analysis on Sonnet for quality
        """,
        "implementation_notes": [
            "Set ANTHROPIC_API_KEY environment variable",
            "Use Docker for code execution security",
            "Monitor token usage with print_usage_summary()",
            "Implement caching for repeated queries",
            "Use Claude's hybrid reasoning for complex tasks"
        ]
    }

if __name__ == "__main__":
    print("Claude-AutoGen Integration Best Practices")
    print("=" * 50)
    
    config = get_recommended_configuration()
    print(f"Recommended Profile: {config['profile']}")
    print(f"Models: {config['models']}")
    print(f"\nReasoning: {config['reasoning']}")
    print("\nImplementation Notes:")
    for note in config['implementation_notes']:
        print(f"  - {note}")
    
    print("\n✅ Claude configuration ready for AutoGen integration!")