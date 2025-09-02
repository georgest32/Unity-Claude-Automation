#!/usr/bin/env python3
"""
AutoGen Supervisor Configuration for Multi-Agent Orchestration
Based on v0.4 API patterns and 2025 best practices
"""

from typing import Dict, List, Any, Optional, Callable
from dataclasses import dataclass
from enum import Enum
import os

# AutoGen v0.4 imports
from autogen_agentchat.agents import AssistantAgent
from autogen_agentchat.teams import RoundRobinGroupChat, SelectorGroupChat
from autogen_ext.models.openai import OpenAIChatCompletionClient
# FunctionCall would be imported from autogen_core if needed
# from autogen_core.components import FunctionCall

class SupervisorRole(Enum):
    """Supervisor agent roles for orchestration"""
    MAIN_SUPERVISOR = "main_supervisor"
    ANALYSIS_SUPERVISOR = "analysis_supervisor"
    RESEARCH_SUPERVISOR = "research_supervisor"
    IMPLEMENTATION_SUPERVISOR = "implementation_supervisor"

@dataclass
class SupervisorConfig:
    """Configuration for supervisor agents"""
    name: str
    role: SupervisorRole
    model: str = "gpt-4o"
    temperature: float = 0.1
    max_tokens: int = 4000
    memory_type: str = "buffer"
    memory_max_tokens: int = 2000
    use_docker: bool = True
    max_consecutive_auto_reply: int = 10
    human_input_mode: str = "TERMINATE"

class SupervisorAgent:
    """Supervisor agent with v0.4 configuration patterns"""
    
    def __init__(self, config: SupervisorConfig):
        self.config = config
        self.model_client = self._create_model_client()
        self.system_message = self._build_system_message()
        
    def _create_model_client(self) -> OpenAIChatCompletionClient:
        """Create OpenAI model client with v0.4 pattern"""
        return OpenAIChatCompletionClient(
            model=self.config.model,
            temperature=self.config.temperature,
            api_key=os.getenv("OPENAI_API_KEY"),
            seed=42,  # For reproducibility
            model_info={
                "vision": False,
                "function_calling": True,
                "json_output": True,
                "family": "openai",
                "structured_output": True
            }
        )
    
    def _build_system_message(self) -> str:
        """Build system message for supervisor agent"""
        role_messages = {
            SupervisorRole.MAIN_SUPERVISOR: """You are the Main Supervisor orchestrating a multi-agent system for repository analysis and automation.

Your responsibilities:
1. **Coordination**: Direct agent teams based on task requirements
2. **Task Distribution**: Assign tasks to appropriate sub-supervisors
3. **Quality Control**: Ensure outputs meet quality standards
4. **Decision Making**: Make final decisions on agent recommendations
5. **Human Interface**: Request human input when necessary

Your teams:
- Analysis Team: Code analysis, documentation drift, quality metrics
- Research Team: Alternative approaches, best practices, comparative studies
- Implementation Team: Code changes, optimizations, deployments

Orchestration approach:
1. Analyze incoming requests to determine required teams
2. Delegate to appropriate sub-supervisors
3. Monitor progress and intervene when needed
4. Aggregate results from multiple teams
5. Present final recommendations or outputs

Always prioritize:
- Security (use Docker containers, controlled functions)
- Performance (monitor token usage, optimize workflows)
- Quality (validate outputs, test changes)
- Documentation (keep records of decisions and changes)""",

            SupervisorRole.ANALYSIS_SUPERVISOR: """You are the Analysis Supervisor managing the repository analysis team.

Your responsibilities:
1. **Team Management**: Coordinate Repo Analyst agents
2. **Analysis Planning**: Define analysis scope and priorities
3. **Quality Assurance**: Validate analysis results
4. **Report Generation**: Compile comprehensive analysis reports
5. **Main Supervisor Interface**: Report findings to Main Supervisor

Analysis capabilities:
- Static code analysis (PSScriptAnalyzer, ESLint, Pylint)
- Code structure and dependency analysis
- Documentation drift detection
- Security vulnerability scanning
- Performance bottleneck identification

Workflow management:
1. Receive analysis requests from Main Supervisor
2. Distribute tasks to specialized analysts
3. Coordinate cross-language analysis
4. Aggregate findings into structured reports
5. Recommend actions based on analysis

Output requirements:
- Structured JSON/Markdown reports
- Prioritized issue lists
- Actionable recommendations
- Trend analysis when applicable""",

            SupervisorRole.RESEARCH_SUPERVISOR: """You are the Research Supervisor managing the research lab team.

Your responsibilities:
1. **Research Coordination**: Direct research agents on specific topics
2. **Alternative Exploration**: Investigate multiple approaches
3. **Best Practices**: Research industry standards and patterns
4. **Risk Assessment**: Evaluate implementation risks
5. **Innovation**: Propose innovative solutions

Research domains:
- Architecture patterns and design principles
- Performance optimization strategies
- Security best practices
- Integration approaches
- Testing methodologies

Research methodology:
1. Define research questions based on requirements
2. Assign domain experts to specific areas
3. Coordinate parallel research efforts
4. Synthesize findings across domains
5. Generate evidence-based recommendations

Deliverables:
- Research memos with findings
- Comparative analysis tables
- Risk assessment matrices
- Implementation roadmaps
- Proof-of-concept examples""",

            SupervisorRole.IMPLEMENTATION_SUPERVISOR: """You are the Implementation Supervisor managing the implementation team.

Your responsibilities:
1. **Implementation Planning**: Plan incremental changes
2. **Safety Verification**: Ensure safe execution practices
3. **Testing Coordination**: Manage comprehensive testing
4. **Deployment Management**: Oversee deployment processes
5. **Rollback Planning**: Prepare contingency plans

Implementation safety:
- Always use Docker containers for code execution
- Implement comprehensive error handling
- Create backups before changes
- Validate all inputs and constraints
- Test in isolated environments first

Team coordination:
1. Review implementation requirements
2. Assign tasks to specialized implementers
3. Ensure cross-platform compatibility
4. Monitor implementation progress
5. Validate successful completion

Quality gates:
- Pre-implementation validation
- Unit and integration testing
- Performance impact assessment
- Security validation
- Documentation updates"""
        }
        
        return role_messages.get(self.config.role, "You are a supervisor agent.")
    
    def create_agent(self) -> AssistantAgent:
        """Create the AutoGen AssistantAgent with v0.4 configuration"""
        return AssistantAgent(
            name=self.config.name,
            system_message=self.system_message,
            model_client=self.model_client,
            max_consecutive_auto_reply=self.config.max_consecutive_auto_reply,
            human_input_mode=self.config.human_input_mode,
            code_execution_config={
                "use_docker": self.config.use_docker,
                "work_dir": f"./workdir/{self.config.name}"
            } if self.config.role == SupervisorRole.IMPLEMENTATION_SUPERVISOR else False,
            memory_config={
                "memory_type": self.config.memory_type,
                "max_tokens": self.config.memory_max_tokens
            }
        )

class SupervisorOrchestrator:
    """Orchestrator for multi-level supervisor hierarchy"""
    
    def __init__(self):
        self.supervisors = self._create_supervisors()
        self.team_config = self._create_team_config()
        
    def _create_supervisors(self) -> Dict[str, SupervisorAgent]:
        """Create all supervisor agents"""
        return {
            "main": SupervisorAgent(SupervisorConfig(
                name="MainSupervisor",
                role=SupervisorRole.MAIN_SUPERVISOR,
                model="gpt-4o",
                temperature=0.1,
                max_consecutive_auto_reply=20
            )),
            "analysis": SupervisorAgent(SupervisorConfig(
                name="AnalysisSupervisor",
                role=SupervisorRole.ANALYSIS_SUPERVISOR,
                model="gpt-4o",
                temperature=0.2,
                max_consecutive_auto_reply=15
            )),
            "research": SupervisorAgent(SupervisorConfig(
                name="ResearchSupervisor",
                role=SupervisorRole.RESEARCH_SUPERVISOR,
                model="gpt-4o",
                temperature=0.3,
                max_consecutive_auto_reply=15
            )),
            "implementation": SupervisorAgent(SupervisorConfig(
                name="ImplementationSupervisor",
                role=SupervisorRole.IMPLEMENTATION_SUPERVISOR,
                model="gpt-4o",
                temperature=0.1,
                max_consecutive_auto_reply=10,
                use_docker=True
            ))
        }
    
    def _create_team_config(self) -> Dict[str, Any]:
        """Create team configuration for group chat"""
        return {
            "supervisor_hierarchy": {
                "main": ["analysis", "research", "implementation"],
                "analysis": ["repo_analyst"],
                "research": ["architecture", "performance", "security"],
                "implementation": ["powershell", "python", "integration", "testing"]
            },
            "speaker_selection_method": "auto",
            "max_rounds": 50,
            "func_call_filter": True,
            "termination_conditions": {
                "max_messages": 100,
                "timeout_seconds": 3600,
                "termination_keywords": ["TERMINATE", "COMPLETE", "FAILED"]
            }
        }
    
    def create_selector_group_chat(self, agents: List[AssistantAgent]) -> SelectorGroupChat:
        """Create a SelectorGroupChat for dynamic speaker selection"""
        return SelectorGroupChat(
            agents=agents,
            max_rounds=self.team_config["max_rounds"],
            speaker_selection_method=self.team_config["speaker_selection_method"],
            func_call_filter=self.team_config["func_call_filter"]
        )
    
    def create_custom_speaker_selector(self) -> Callable:
        """Create custom speaker selection function"""
        def custom_selector(last_speaker: AssistantAgent, groupchat) -> Optional[AssistantAgent]:
            """Custom logic for speaker selection based on context"""
            # Main supervisor always speaks after sub-supervisors report
            if last_speaker.name in ["AnalysisSupervisor", "ResearchSupervisor", "ImplementationSupervisor"]:
                return next((a for a in groupchat.agents if a.name == "MainSupervisor"), None)
            
            # Route to appropriate supervisor based on message content
            last_message = groupchat.messages[-1] if groupchat.messages else None
            if last_message:
                content = last_message.get("content", "").lower()
                if "analyze" in content or "analysis" in content:
                    return next((a for a in groupchat.agents if a.name == "AnalysisSupervisor"), None)
                elif "research" in content or "investigate" in content:
                    return next((a for a in groupchat.agents if a.name == "ResearchSupervisor"), None)
                elif "implement" in content or "deploy" in content:
                    return next((a for a in groupchat.agents if a.name == "ImplementationSupervisor"), None)
            
            # Default to main supervisor
            return next((a for a in groupchat.agents if a.name == "MainSupervisor"), None)
        
        return custom_selector
    
    def get_usage_summary(self, agents: List[AssistantAgent]) -> Dict[str, Any]:
        """Get token usage summary for all agents"""
        from autogen import gather_usage_summary
        return gather_usage_summary(agents)

def create_supervisor_orchestration() -> SupervisorOrchestrator:
    """Factory function to create supervisor orchestration"""
    return SupervisorOrchestrator()

if __name__ == "__main__":
    # Test the configuration
    print("Supervisor Orchestration Configuration")
    print("=" * 50)
    
    orchestrator = create_supervisor_orchestration()
    
    print("Supervisors created:")
    for name, supervisor in orchestrator.supervisors.items():
        print(f"  - {supervisor.config.name} ({supervisor.config.role.value})")
        print(f"    Model: {supervisor.config.model}")
        print(f"    Max replies: {supervisor.config.max_consecutive_auto_reply}")
    
    print(f"\nTeam hierarchy:")
    for supervisor, teams in orchestrator.team_config["supervisor_hierarchy"].items():
        print(f"  {supervisor}: {', '.join(teams)}")
    
    print("\n✅ Supervisor orchestration configuration ready!")