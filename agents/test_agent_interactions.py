#!/usr/bin/env python3
"""
Test Script for AutoGen Agent Team Interactions
Validates v0.4 configurations and team coordination
"""

import asyncio
import json
import sys
import os
from pathlib import Path
from datetime import datetime
from typing import Dict, Any, List

# Add agents directory to path
sys.path.insert(0, str(Path(__file__).parent))

# Import configurations
from autogen_supervisor_config import create_supervisor_orchestration
from autogen_groupchat_config import create_multi_agent_system
from analyst_docs.repo_analyst_config_v04 import create_repo_analyst_agent_v04

class AgentInteractionTester:
    """Test harness for agent interactions"""
    
    def __init__(self):
        self.test_results = {
            "timestamp": datetime.now().isoformat(),
            "tests": [],
            "summary": {}
        }
        self.multi_agent_system = None
        self.supervisor_orchestrator = None
        
    def test_environment_setup(self) -> Dict[str, Any]:
        """Test 1: Verify environment and dependencies"""
        test_result = {
            "test_name": "Environment Setup",
            "status": "PASS",
            "details": {}
        }
        
        try:
            # Check Python version
            import sys
            python_version = f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}"
            test_result["details"]["python_version"] = python_version
            
            # Check AutoGen installation
            import autogen_agentchat
            import autogen_core
            test_result["details"]["autogen_agentchat"] = autogen_agentchat.__version__ if hasattr(autogen_agentchat, '__version__') else "installed"
            test_result["details"]["autogen_core"] = autogen_core.__version__ if hasattr(autogen_core, '__version__') else "installed"
            
            # Check for OpenAI API key
            api_key_set = bool(os.getenv("OPENAI_API_KEY"))
            test_result["details"]["openai_api_key"] = "configured" if api_key_set else "missing"
            
            if not api_key_set:
                test_result["status"] = "FAIL"
                test_result["error"] = "OPENAI_API_KEY not set"
                
        except ImportError as e:
            test_result["status"] = "FAIL"
            test_result["error"] = f"Missing dependency: {str(e)}"
        except Exception as e:
            test_result["status"] = "FAIL"
            test_result["error"] = str(e)
            
        return test_result
    
    def test_supervisor_creation(self) -> Dict[str, Any]:
        """Test 2: Verify supervisor orchestration creation"""
        test_result = {
            "test_name": "Supervisor Creation",
            "status": "PASS",
            "details": {}
        }
        
        try:
            self.supervisor_orchestrator = create_supervisor_orchestration()
            
            # Check all supervisors created
            expected_supervisors = ["main", "analysis", "research", "implementation"]
            created_supervisors = list(self.supervisor_orchestrator.supervisors.keys())
            
            test_result["details"]["expected"] = expected_supervisors
            test_result["details"]["created"] = created_supervisors
            
            for supervisor in expected_supervisors:
                if supervisor not in created_supervisors:
                    test_result["status"] = "FAIL"
                    test_result["error"] = f"Missing supervisor: {supervisor}"
                    break
            
            # Test supervisor agent creation
            if test_result["status"] == "PASS":
                main_agent = self.supervisor_orchestrator.supervisors["main"].create_agent()
                test_result["details"]["main_agent_created"] = main_agent.name == "MainSupervisor"
                
        except Exception as e:
            test_result["status"] = "FAIL"
            test_result["error"] = str(e)
            
        return test_result
    
    def test_repo_analyst_v04(self) -> Dict[str, Any]:
        """Test 3: Verify Repo Analyst v0.4 configuration"""
        test_result = {
            "test_name": "Repo Analyst v0.4",
            "status": "PASS",
            "details": {}
        }
        
        try:
            # Create v0.4 repo analyst
            analyst_agent = create_repo_analyst_agent_v04()
            
            # Verify agent properties
            test_result["details"]["name"] = analyst_agent.name
            test_result["details"]["has_model_client"] = hasattr(analyst_agent, 'model_client')
            test_result["details"]["has_memory_config"] = hasattr(analyst_agent, 'memory_config')
            test_result["details"]["code_execution"] = analyst_agent.code_execution_config == False
            
            # Check for controlled tools
            if hasattr(analyst_agent, 'function_map'):
                test_result["details"]["tools_count"] = len(analyst_agent.function_map)
                test_result["details"]["tools"] = list(analyst_agent.function_map.keys())
            
        except Exception as e:
            test_result["status"] = "FAIL"
            test_result["error"] = str(e)
            
        return test_result
    
    def test_multi_agent_system(self) -> Dict[str, Any]:
        """Test 4: Verify multi-agent system creation"""
        test_result = {
            "test_name": "Multi-Agent System",
            "status": "PASS",
            "details": {}
        }
        
        try:
            self.multi_agent_system = create_multi_agent_system()
            
            # Check components
            test_result["details"]["has_user_proxy"] = self.multi_agent_system.user_proxy is not None
            test_result["details"]["has_repo_analyst"] = self.multi_agent_system.repo_analyst is not None
            test_result["details"]["has_supervisors"] = len(self.multi_agent_system.supervisor_orchestrator.supervisors) > 0
            test_result["details"]["has_research_team"] = self.multi_agent_system.research_team is not None
            test_result["details"]["has_implementer_team"] = self.multi_agent_system.implementer_team is not None
            
            # Check group chat configuration
            config = self.multi_agent_system.group_chat_config
            test_result["details"]["max_rounds"] = config.max_rounds
            test_result["details"]["speaker_selection"] = config.speaker_selection_method
            test_result["details"]["func_call_filter"] = config.func_call_filter
            
        except Exception as e:
            test_result["status"] = "FAIL"
            test_result["error"] = str(e)
            
        return test_result
    
    def test_group_chat_creation(self) -> Dict[str, Any]:
        """Test 5: Verify group chat creation for different task types"""
        test_result = {
            "test_name": "Group Chat Creation",
            "status": "PASS",
            "details": {}
        }
        
        try:
            if not self.multi_agent_system:
                self.multi_agent_system = create_multi_agent_system()
            
            # Test different group chat types
            chat_types = {
                "analysis": self.multi_agent_system.create_analysis_group_chat,
                "research": self.multi_agent_system.create_research_group_chat,
                "implementation": self.multi_agent_system.create_implementation_group_chat,
                "full_system": self.multi_agent_system.create_full_system_group_chat
            }
            
            for chat_type, creator_func in chat_types.items():
                try:
                    group_chat = creator_func()
                    test_result["details"][f"{chat_type}_created"] = True
                    test_result["details"][f"{chat_type}_agents"] = len(group_chat.agents) if hasattr(group_chat, 'agents') else 0
                except Exception as e:
                    test_result["details"][f"{chat_type}_created"] = False
                    test_result["details"][f"{chat_type}_error"] = str(e)
                    test_result["status"] = "PARTIAL"
                    
        except Exception as e:
            test_result["status"] = "FAIL"
            test_result["error"] = str(e)
            
        return test_result
    
    def test_security_configurations(self) -> Dict[str, Any]:
        """Test 6: Verify security configurations"""
        test_result = {
            "test_name": "Security Configurations",
            "status": "PASS",
            "details": {}
        }
        
        try:
            if not self.multi_agent_system:
                self.multi_agent_system = create_multi_agent_system()
            
            # Check Docker configuration for implementers
            test_result["details"]["user_proxy_docker"] = (
                self.multi_agent_system.user_proxy.code_execution_config is not False
            )
            
            # Check repo analyst has no code execution
            test_result["details"]["analyst_no_execution"] = (
                self.multi_agent_system.repo_analyst.code_execution_config == False
            )
            
            # Check controlled functions
            test_result["details"]["analyst_has_function_map"] = (
                hasattr(self.multi_agent_system.repo_analyst, 'function_map')
            )
            
            # Verify no arbitrary code execution in supervisors
            for name, supervisor in self.multi_agent_system.supervisor_orchestrator.supervisors.items():
                agent = supervisor.create_agent()
                if name != "implementation":
                    is_safe = agent.code_execution_config == False
                else:
                    is_safe = agent.code_execution_config.get("use_docker", False) if isinstance(agent.code_execution_config, dict) else False
                
                test_result["details"][f"{name}_supervisor_safe"] = is_safe
                
        except Exception as e:
            test_result["status"] = "FAIL"
            test_result["error"] = str(e)
            
        return test_result
    
    def test_memory_configurations(self) -> Dict[str, Any]:
        """Test 7: Verify memory and token management"""
        test_result = {
            "test_name": "Memory Configurations",
            "status": "PASS",
            "details": {}
        }
        
        try:
            if not self.multi_agent_system:
                self.multi_agent_system = create_multi_agent_system()
            
            # Check memory configurations
            agents_to_check = [
                ("repo_analyst", self.multi_agent_system.repo_analyst),
                ("user_proxy", self.multi_agent_system.user_proxy)
            ]
            
            for agent_name, agent in agents_to_check:
                if hasattr(agent, 'memory_config'):
                    test_result["details"][f"{agent_name}_has_memory"] = True
                    test_result["details"][f"{agent_name}_memory_type"] = agent.memory_config.get("memory_type", "unknown")
                    test_result["details"][f"{agent_name}_max_tokens"] = agent.memory_config.get("max_tokens", 0)
                else:
                    test_result["details"][f"{agent_name}_has_memory"] = False
                    
        except Exception as e:
            test_result["status"] = "FAIL"
            test_result["error"] = str(e)
            
        return test_result
    
    def test_ipc_bridge_components(self) -> Dict[str, Any]:
        """Test 8: Verify IPC bridge components"""
        test_result = {
            "test_name": "IPC Bridge Components",
            "status": "PASS",
            "details": {}
        }
        
        try:
            from powershell_autogen_bridge import PowerShellBridge, NamedPipeServer
            
            # Test PowerShell bridge
            ps_bridge = PowerShellBridge()
            test_result["details"]["powershell_executable"] = ps_bridge.ps_executable
            test_result["details"]["ps7_detected"] = "PowerShell\\7" in ps_bridge.ps_executable
            
            # Test named pipe server
            pipe_server = NamedPipeServer()
            test_result["details"]["pipe_name"] = pipe_server.pipe_name
            test_result["details"]["pipe_format_correct"] = pipe_server.pipe_name.startswith(r"\\.\pipe")
            
        except ImportError as e:
            test_result["status"] = "FAIL"
            test_result["error"] = f"Cannot import bridge components: {str(e)}"
        except Exception as e:
            test_result["status"] = "FAIL"
            test_result["error"] = str(e)
            
        return test_result
    
    def run_all_tests(self):
        """Run all tests and generate report"""
        print("AutoGen Agent Team Interaction Tests")
        print("=" * 50)
        
        tests = [
            self.test_environment_setup,
            self.test_supervisor_creation,
            self.test_repo_analyst_v04,
            self.test_multi_agent_system,
            self.test_group_chat_creation,
            self.test_security_configurations,
            self.test_memory_configurations,
            self.test_ipc_bridge_components
        ]
        
        passed = 0
        failed = 0
        partial = 0
        
        for test_func in tests:
            result = test_func()
            self.test_results["tests"].append(result)
            
            status_symbol = "[PASS]" if result["status"] == "PASS" else "[FAIL]" if result["status"] == "FAIL" else "[WARN]"
            print(f"{status_symbol} {result['test_name']}: {result['status']}")
            
            if result["status"] == "PASS":
                passed += 1
            elif result["status"] == "FAIL":
                failed += 1
                if "error" in result:
                    print(f"   Error: {result['error']}")
            else:
                partial += 1
                
        self.test_results["summary"] = {
            "total": len(tests),
            "passed": passed,
            "failed": failed,
            "partial": partial,
            "success_rate": f"{(passed/len(tests)*100):.1f}%"
        }
        
        print("\n" + "=" * 50)
        print(f"Summary: {passed}/{len(tests)} tests passed ({self.test_results['summary']['success_rate']})")
        
        # Save results
        results_file = Path(__file__).parent / f"test_results_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(results_file, 'w') as f:
            json.dump(self.test_results, f, indent=2, default=str)
        print(f"\nResults saved to: {results_file}")
        
        return self.test_results

def main():
    """Main test execution"""
    tester = AgentInteractionTester()
    results = tester.run_all_tests()
    
    # Return exit code based on results
    if results["summary"]["failed"] > 0:
        sys.exit(1)
    else:
        sys.exit(0)

if __name__ == "__main__":
    main()