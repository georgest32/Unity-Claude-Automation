#!/usr/bin/env python3
"""
Flexible Model Configuration for AutoGen
Easily switch between Claude, OpenAI, and other models
"""

import os
import json
from typing import Dict, Any, Optional, Union
from dataclasses import dataclass
from enum import Enum
from pathlib import Path

# AutoGen imports
from autogen_ext.models.openai import OpenAIChatCompletionClient
from autogen_ext.models.anthropic import AnthropicChatCompletionClient
from autogen_agentchat.agents import AssistantAgent

class ModelProvider(Enum):
    """Supported model providers"""
    OPENAI = "openai"
    ANTHROPIC = "anthropic"
    AZURE_OPENAI = "azure_openai"
    LOCAL = "local"  # For Ollama, LMStudio, etc.

class ModelProfile(Enum):
    """Model selection profiles"""
    OPENAI_ONLY = "openai_only"
    CLAUDE_ONLY = "claude_only"
    HYBRID_OPENAI_CLAUDE = "hybrid_openai_claude"
    HYBRID_CLAUDE_OPENAI = "hybrid_claude_openai"
    COST_OPTIMIZED = "cost_optimized"
    QUALITY_FIRST = "quality_first"
    LOCAL_FIRST = "local_first"

@dataclass
class ModelConfig:
    """Flexible model configuration"""
    provider: ModelProvider
    model_name: str
    temperature: float = 0.2
    max_tokens: int = 4096
    api_key: Optional[str] = None
    additional_params: Dict[str, Any] = None

class FlexibleModelManager:
    """
    Manage model configurations flexibly
    Allows easy switching between providers and models
    """
    
    # Model configurations that can be easily modified
    MODEL_CONFIGS = {
        # OpenAI Models
        "gpt-4o": ModelConfig(ModelProvider.OPENAI, "gpt-4o", temperature=0.2),
        "gpt-4-turbo": ModelConfig(ModelProvider.OPENAI, "gpt-4-turbo-preview", temperature=0.2),
        "gpt-3.5-turbo": ModelConfig(ModelProvider.OPENAI, "gpt-3.5-turbo", temperature=0.3),
        
        # Anthropic Claude Models
        "claude-3.5-sonnet": ModelConfig(ModelProvider.ANTHROPIC, "claude-3-5-sonnet-20240620", temperature=0.2),
        "claude-3.5-haiku": ModelConfig(ModelProvider.ANTHROPIC, "claude-3-5-haiku-20241022", temperature=0.3),
        "claude-3-opus": ModelConfig(ModelProvider.ANTHROPIC, "claude-3-opus-20240229", temperature=0.2),
        
        # Local Models (Ollama example)
        "llama3": ModelConfig(ModelProvider.LOCAL, "llama3:latest", temperature=0.3),
        "mistral": ModelConfig(ModelProvider.LOCAL, "mistral:latest", temperature=0.3),
    }
    
    # Profile configurations - EASILY CHANGEABLE
    PROFILE_CONFIGS = {
        ModelProfile.OPENAI_ONLY: {
            "orchestrator": "gpt-4o",
            "workers": "gpt-4o",
            "simple_tasks": "gpt-3.5-turbo"
        },
        ModelProfile.CLAUDE_ONLY: {
            "orchestrator": "claude-3.5-sonnet",
            "workers": "claude-3.5-sonnet",
            "simple_tasks": "claude-3.5-haiku"
        },
        ModelProfile.HYBRID_OPENAI_CLAUDE: {
            "orchestrator": "gpt-4o",  # OpenAI for orchestration
            "workers": "claude-3.5-sonnet",  # Claude for actual work
            "simple_tasks": "gpt-3.5-turbo"  # OpenAI for simple tasks
        },
        ModelProfile.HYBRID_CLAUDE_OPENAI: {
            "orchestrator": "claude-3.5-sonnet",  # Claude for orchestration
            "workers": "gpt-4o",  # OpenAI for actual work
            "simple_tasks": "claude-3.5-haiku"  # Claude for simple tasks
        },
        ModelProfile.COST_OPTIMIZED: {
            "orchestrator": "gpt-3.5-turbo",
            "workers": "claude-3.5-haiku",  # Cheapest good quality
            "simple_tasks": "gpt-3.5-turbo"
        },
        ModelProfile.QUALITY_FIRST: {
            "orchestrator": "claude-3.5-sonnet",  # Best reasoning
            "workers": "gpt-4o",  # Best code generation
            "simple_tasks": "claude-3.5-sonnet"  # Quality even for simple tasks
        }
    }
    
    def __init__(self, config_file: Optional[str] = None):
        """Initialize with optional config file for persistence"""
        self.config_file = config_file or "model_config.json"
        self.current_profile = ModelProfile.HYBRID_OPENAI_CLAUDE
        self.custom_overrides = {}
        self.load_config()
    
    def load_config(self):
        """Load configuration from file if exists"""
        config_path = Path(self.config_file)
        if config_path.exists():
            with open(config_path, 'r') as f:
                config = json.load(f)
                self.current_profile = ModelProfile(config.get("profile", "hybrid_openai_claude"))
                self.custom_overrides = config.get("overrides", {})
    
    def save_config(self):
        """Save current configuration to file"""
        config = {
            "profile": self.current_profile.value,
            "overrides": self.custom_overrides,
            "timestamp": str(Path.ctime(Path.cwd()))
        }
        with open(self.config_file, 'w') as f:
            json.dump(config, f, indent=2)
    
    def set_profile(self, profile: ModelProfile):
        """Change the active model profile"""
        self.current_profile = profile
        self.save_config()
        print(f"Switched to profile: {profile.value}")
    
    def override_model(self, role: str, model_key: str):
        """Override a specific role's model"""
        if model_key not in self.MODEL_CONFIGS:
            raise ValueError(f"Unknown model: {model_key}")
        
        self.custom_overrides[role] = model_key
        self.save_config()
        print(f"Overridden {role} to use {model_key}")
    
    def get_model_for_role(self, role: str) -> ModelConfig:
        """Get the model configuration for a specific role"""
        # Check for custom override first
        if role in self.custom_overrides:
            model_key = self.custom_overrides[role]
        else:
            # Use profile default
            profile_config = self.PROFILE_CONFIGS[self.current_profile]
            
            # Map role to profile category
            if "supervisor" in role.lower() or "orchestrator" in role.lower():
                model_key = profile_config["orchestrator"]
            elif "simple" in role.lower() or "router" in role.lower():
                model_key = profile_config["simple_tasks"]
            else:
                model_key = profile_config["workers"]
        
        return self.MODEL_CONFIGS[model_key]
    
    def create_model_client(self, role: str) -> Union[OpenAIChatCompletionClient, AnthropicChatCompletionClient]:
        """Create appropriate model client for the role"""
        config = self.get_model_for_role(role)
        
        if config.provider == ModelProvider.OPENAI:
            return OpenAIChatCompletionClient(
                model=config.model_name,
                temperature=config.temperature,
                api_key=config.api_key or os.getenv("OPENAI_API_KEY"),
                max_tokens=config.max_tokens
            )
        elif config.provider == ModelProvider.ANTHROPIC:
            return AnthropicChatCompletionClient(
                model=config.model_name,
                temperature=config.temperature,
                api_key=config.api_key or os.getenv("ANTHROPIC_API_KEY"),
                max_tokens=config.max_tokens
            )
        else:
            raise ValueError(f"Provider {config.provider} not yet implemented")
    
    def create_agent(self, name: str, role: str, system_message: str,
                    code_execution: bool = False) -> AssistantAgent:
        """Create an agent with appropriate model based on role"""
        model_client = self.create_model_client(role)
        
        return AssistantAgent(
            name=name,
            system_message=system_message,
            model_client=model_client,
            max_consecutive_auto_reply=10,
            human_input_mode="NEVER" if not code_execution else "TERMINATE",
            code_execution_config=False if not code_execution else {
                "use_docker": True,
                "timeout": 120,
                "work_dir": f"./workdir/{name}"
            },
            memory_config={
                "memory_type": "buffer",
                "max_tokens": 2000
            }
        )
    
    def list_available_models(self):
        """List all available models"""
        print("Available Models:")
        print("=" * 50)
        for key, config in self.MODEL_CONFIGS.items():
            print(f"  {key}: {config.provider.value} - {config.model_name}")
    
    def list_profiles(self):
        """List all available profiles"""
        print("\nAvailable Profiles:")
        print("=" * 50)
        for profile in ModelProfile:
            config = self.PROFILE_CONFIGS[profile]
            print(f"\n{profile.value}:")
            print(f"  Orchestrator: {config['orchestrator']}")
            print(f"  Workers: {config['workers']}")
            print(f"  Simple Tasks: {config['simple_tasks']}")
    
    def get_current_config(self) -> Dict[str, Any]:
        """Get current configuration details"""
        profile_config = self.PROFILE_CONFIGS[self.current_profile]
        
        return {
            "current_profile": self.current_profile.value,
            "models_in_use": {
                "orchestrator": profile_config["orchestrator"],
                "workers": profile_config["workers"],
                "simple_tasks": profile_config["simple_tasks"]
            },
            "custom_overrides": self.custom_overrides,
            "api_keys_configured": {
                "openai": bool(os.getenv("OPENAI_API_KEY")),
                "anthropic": bool(os.getenv("ANTHROPIC_API_KEY"))
            }
        }

# Convenience functions for easy model switching
def switch_to_openai():
    """Quick switch to OpenAI only"""
    manager = FlexibleModelManager()
    manager.set_profile(ModelProfile.OPENAI_ONLY)
    return manager

def switch_to_claude():
    """Quick switch to Claude only"""
    manager = FlexibleModelManager()
    manager.set_profile(ModelProfile.CLAUDE_ONLY)
    return manager

def switch_to_hybrid(prefer_claude: bool = False):
    """Quick switch to hybrid mode"""
    manager = FlexibleModelManager()
    profile = ModelProfile.HYBRID_CLAUDE_OPENAI if prefer_claude else ModelProfile.HYBRID_OPENAI_CLAUDE
    manager.set_profile(profile)
    return manager

def switch_to_cost_optimized():
    """Quick switch to cost-optimized mode"""
    manager = FlexibleModelManager()
    manager.set_profile(ModelProfile.COST_OPTIMIZED)
    return manager

# Example usage script
if __name__ == "__main__":
    print("Flexible Model Configuration System")
    print("=" * 50)
    
    # Create manager
    manager = FlexibleModelManager()
    
    # Show current configuration
    print("\nCurrent Configuration:")
    current = manager.get_current_config()
    print(f"Profile: {current['current_profile']}")
    print(f"Models: {current['models_in_use']}")
    
    # List available options
    manager.list_available_models()
    manager.list_profiles()
    
    print("\n" + "=" * 50)
    print("To switch models, use:")
    print("  manager.set_profile(ModelProfile.OPENAI_ONLY)")
    print("  manager.set_profile(ModelProfile.CLAUDE_ONLY)")
    print("  manager.override_model('repo_analyst', 'gpt-4o')")
    print("\nOr use convenience functions:")
    print("  switch_to_openai()")
    print("  switch_to_claude()")
    print("  switch_to_hybrid()")
    print("  switch_to_cost_optimized()")
    
    print("\n✅ Flexible model configuration ready!")