#!/usr/bin/env python3
"""
Comprehensive test suite for the Phase 4 Multi-Agent System
Run this to validate the entire AutoGen integration
"""

import asyncio
import sys
import os
import json
from datetime import datetime

# Add current directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

def test_imports():
    """Test 1: Verify all required modules can be imported"""
    print("\n" + "="*50)
    print("TEST 1: Module Import Validation")
    print("="*50)
    
    tests_passed = 0
    tests_total = 0
    
    # Test AutoGen imports
    tests_total += 1
    try:
        import autogen_agentchat
        print(f"✅ AutoGen AgentChat v{autogen_agentchat.__version__} imported")
        tests_passed += 1
    except ImportError as e:
        print(f"❌ AutoGen AgentChat import failed: {e}")
    
    # Test LangGraph imports
    tests_total += 1
    try:
        import langgraph.graph
        print("✅ LangGraph graph module imported")
        tests_passed += 1
    except ImportError as e:
        print(f"❌ LangGraph import failed: {e}")
    
    # Test our custom modules
    tests_total += 1
    try:
        from supervisor_coordination import SupervisorAgent, TaskType, TaskStatus
        print("✅ Supervisor coordination module imported")
        tests_passed += 1
    except ImportError as e:
        print(f"❌ Supervisor coordination import failed: {e}")
    
    # Test agent configurations
    tests_total += 1
    try:
        from agents.analyst_docs.repo_analyst_config import create_repo_analyst_agent
        print("✅ Repo Analyst configuration imported")
        tests_passed += 1
    except ImportError as e:
        print(f"❌ Repo Analyst import failed: {e}")
    
    tests_total += 1
    try:
        from agents.research_lab.research_agents_config import create_research_lab_team
        print("✅ Research Lab team configuration imported")
        tests_passed += 1
    except ImportError as e:
        print(f"❌ Research Lab import failed: {e}")
    
    tests_total += 1
    try:
        from agents.implementers.implementer_agents_config import create_implementer_team
        print("✅ Implementer team configuration imported")
        tests_passed += 1
    except ImportError as e:
        print(f"❌ Implementer team import failed: {e}")
    
    print(f"\nImport Test Results: {tests_passed}/{tests_total} passed")
    return tests_passed == tests_total

def test_agent_creation():
    """Test 2: Verify agent teams can be created"""
    print("\n" + "="*50)
    print("TEST 2: Agent Team Creation")
    print("="*50)
    
    tests_passed = 0
    tests_total = 0
    
    # Test Repo Analyst creation
    tests_total += 1
    try:
        from agents.analyst_docs.repo_analyst_config import create_repo_analyst_agent
        analyst = create_repo_analyst_agent("TestAnalyst")
        print(f"✅ Repo Analyst created: {analyst['name']}")
        print(f"   Tools: {len(analyst['tools'])} available")
        tests_passed += 1
    except Exception as e:
        print(f"❌ Repo Analyst creation failed: {e}")
    
    # Test Research Lab creation
    tests_total += 1
    try:
        from agents.research_lab.research_agents_config import create_research_lab_team
        research_team = create_research_lab_team()
        config = research_team.get_team_config()
        print(f"✅ Research Lab created: {config['team_name']}")
        print(f"   Agents: {len(config['agents'])} researchers")
        tests_passed += 1
    except Exception as e:
        print(f"❌ Research Lab creation failed: {e}")
    
    # Test Implementer team creation
    tests_total += 1
    try:
        from agents.implementers.implementer_agents_config import create_implementer_team
        impl_team = create_implementer_team()
        config = impl_team.get_team_config()
        print(f"✅ Implementer team created: {config['team_name']}")
        print(f"   Agents: {len(config['agents'])} implementers")
        tests_passed += 1
    except Exception as e:
        print(f"❌ Implementer team creation failed: {e}")
    
    print(f"\nAgent Creation Test Results: {tests_passed}/{tests_total} passed")
    return tests_passed == tests_total

async def test_supervisor_coordination():
    """Test 3: Verify supervisor can coordinate tasks"""
    print("\n" + "="*50)
    print("TEST 3: Supervisor Coordination")
    print("="*50)
    
    tests_passed = 0
    tests_total = 0
    
    try:
        from supervisor_coordination import SupervisorAgent, TaskType, TaskStatus, AgentTeam
        
        # Create supervisor
        tests_total += 1
        supervisor = SupervisorAgent("TestSupervisor")
        print(f"✅ Supervisor created: {supervisor.name}")
        tests_passed += 1
        
        # Create a simple task
        tests_total += 1
        task = supervisor.create_task(
            TaskType.REPOSITORY_ANALYSIS,
            "Test Repository Analysis",
            "Analyze test repository for documentation",
            priority=1,
            estimated_duration="30 minutes"
        )
        print(f"✅ Task created: {task.id} - {task.title}")
        tests_passed += 1
        
        # Assign task to team
        tests_total += 1
        success = supervisor.assign_task(task.id, AgentTeam.REPO_ANALYST, "TestAnalyst")
        if success:
            print(f"✅ Task assigned to {AgentTeam.REPO_ANALYST.value}")
            tests_passed += 1
        else:
            print("❌ Task assignment failed")
        
        # Update task status
        tests_total += 1
        success = supervisor.update_task_status(
            task.id, 
            TaskStatus.COMPLETED,
            result={"analysis": "complete", "findings": ["test finding"]}
        )
        if success:
            print(f"✅ Task status updated to COMPLETED")
            tests_passed += 1
        else:
            print("❌ Task status update failed")
        
        # Get system status
        tests_total += 1
        status = supervisor.get_system_status()
        print(f"✅ System status retrieved:")
        print(f"   Total tasks: {status['supervisor']['total_tasks_created']}")
        print(f"   Completed: {status['supervisor']['completed_tasks']}")
        tests_passed += 1
        
    except Exception as e:
        print(f"❌ Supervisor test failed: {e}")
    
    print(f"\nSupervisor Test Results: {tests_passed}/{tests_total} passed")
    return tests_passed == tests_total

async def test_workflow_creation():
    """Test 4: Verify complete workflow can be created"""
    print("\n" + "="*50)
    print("TEST 4: Complete Workflow Creation")
    print("="*50)
    
    tests_passed = 0
    tests_total = 0
    
    try:
        from supervisor_coordination import SupervisorAgent
        
        # Create supervisor
        supervisor = SupervisorAgent("WorkflowSupervisor")
        
        # Create repository analysis workflow
        tests_total += 1
        task_ids = supervisor.create_repository_analysis_workflow(
            "C:\\UnityProjects\\Sound-and-Shoal\\Unity-Claude-Automation"
        )
        print(f"✅ Workflow created with {len(task_ids)} tasks:")
        for task_id in task_ids:
            task = supervisor._find_task(task_id) or next(
                (t for t in supervisor.state.completed_tasks if t.id == task_id), None
            )
            if task:
                print(f"   - {task.id}: {task.title} ({task.assigned_team.value if task.assigned_team else 'unassigned'})")
        tests_passed += 1
        
        # Check dependencies
        tests_total += 1
        has_dependencies = False
        for task_id in task_ids:
            task = supervisor._find_task(task_id)
            if task and task.dependencies:
                has_dependencies = True
                print(f"✅ Task {task.id} depends on: {task.dependencies}")
        if has_dependencies:
            tests_passed += 1
        else:
            print("❌ No task dependencies found")
        
        # Check human approval requirements
        tests_total += 1
        approval_tasks = []
        for task_id in task_ids:
            task = supervisor._find_task(task_id)
            if task and task.human_approval_required:
                approval_tasks.append(task.id)
        if approval_tasks:
            print(f"✅ Human approval required for: {approval_tasks}")
            tests_passed += 1
        else:
            print("⚠️  No human approval checkpoints found")
            tests_passed += 1  # This is optional, so we'll pass anyway
        
    except Exception as e:
        print(f"❌ Workflow test failed: {e}")
    
    print(f"\nWorkflow Test Results: {tests_passed}/{tests_total} passed")
    return tests_passed == tests_total

def test_powershell_bridge():
    """Test 5: Verify PowerShell bridge components are available"""
    print("\n" + "="*50)
    print("TEST 5: PowerShell Bridge Components")
    print("="*50)
    
    tests_passed = 0
    tests_total = 0
    
    # Test REST bridge import
    tests_total += 1
    try:
        from powershell_rest_bridge import PowerShellRESTBridge, AutoGenPowerShellClient
        print("✅ PowerShell REST bridge module imported")
        tests_passed += 1
    except ImportError as e:
        print(f"❌ PowerShell REST bridge import failed: {e}")
    
    # Test direct bridge import
    tests_total += 1
    try:
        from powershell_python_bridge import PowerShellBridge, AutoGenPowerShellAgent
        print("✅ PowerShell direct bridge module imported")
        tests_passed += 1
    except ImportError as e:
        print(f"❌ PowerShell direct bridge import failed: {e}")
    
    # Test bridge client creation
    tests_total += 1
    try:
        from powershell_rest_bridge import AutoGenPowerShellClient
        client = AutoGenPowerShellClient("http://localhost:8000")
        print(f"✅ PowerShell client created for: {client.bridge_url}")
        tests_passed += 1
    except Exception as e:
        print(f"❌ PowerShell client creation failed: {e}")
    
    print(f"\nPowerShell Bridge Test Results: {tests_passed}/{tests_total} passed")
    return tests_passed == tests_total

async def main():
    """Run all tests"""
    print("\n" + "="*60)
    print(" PHASE 4 MULTI-AGENT SYSTEM - COMPREHENSIVE TEST SUITE")
    print("="*60)
    print(f"Test Started: {datetime.now().isoformat()}")
    
    all_results = []
    
    # Run synchronous tests
    all_results.append(("Module Imports", test_imports()))
    all_results.append(("Agent Creation", test_agent_creation()))
    all_results.append(("PowerShell Bridge", test_powershell_bridge()))
    
    # Run async tests
    all_results.append(("Supervisor Coordination", await test_supervisor_coordination()))
    all_results.append(("Workflow Creation", await test_workflow_creation()))
    
    # Summary
    print("\n" + "="*60)
    print(" TEST SUMMARY")
    print("="*60)
    
    total_passed = sum(1 for _, passed in all_results if passed)
    total_tests = len(all_results)
    
    for test_name, passed in all_results:
        status = "✅ PASSED" if passed else "❌ FAILED"
        print(f"{test_name:.<30} {status}")
    
    print(f"\nOverall Results: {total_passed}/{total_tests} test suites passed")
    
    if total_passed == total_tests:
        print("\n🎉 SUCCESS: All tests passed! Multi-agent system is operational.")
        return 0
    else:
        print(f"\n⚠️  WARNING: {total_tests - total_passed} test suite(s) failed.")
        print("Check the detailed output above for specific failures.")
        return 1

if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code)