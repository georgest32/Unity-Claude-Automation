#!/usr/bin/env python3
"""
Test AutoGen installation for Day 2 Hour 1-2 implementation
"""

def test_autogen_imports():
    """Test AutoGen v0.7.4 imports"""
    print("=== Testing AutoGen v0.7.4 Installation ===")
    
    try:
        # Try different import patterns based on research
        import autogen_agentchat
        print(f"[PASS] autogen_agentchat v{autogen_agentchat.__version__} imported")
    except Exception as e:
        print(f"[FAIL] autogen_agentchat import failed: {e}")
        
    try:
        import autogen_core  
        print(f"[PASS] autogen_core v{autogen_core.__version__} imported")
    except Exception as e:
        print(f"[FAIL] autogen_core import failed: {e}")
        
    try:
        # Try alternative import pattern
        from autogen_agentchat.agents import AssistantAgent
        print("[PASS] AssistantAgent import successful")
    except Exception as e:
        print(f"[FAIL] AssistantAgent import failed: {e}")
        
    try:
        from autogen_agentchat.teams import RoundRobinGroupChat
        print("[PASS] RoundRobinGroupChat import successful")
    except Exception as e:
        print(f"[FAIL] RoundRobinGroupChat import failed: {e}")

def test_powershell_integration():
    """Test PowerShell integration capability"""
    print("\n=== Testing PowerShell Integration ===")
    
    try:
        import subprocess
        result = subprocess.run(['powershell', '-Command', 'Write-Output "AutoGen PowerShell Integration Test"'], 
                              capture_output=True, text=True, timeout=10)
        
        if result.returncode == 0:
            print("[PASS] PowerShell integration working")
            print(f"  Output: {result.stdout.strip()}")
        else:
            print(f"[FAIL] PowerShell command failed: {result.stderr}")
    except Exception as e:
        print(f"[FAIL] PowerShell integration test failed: {e}")

if __name__ == "__main__":
    test_autogen_imports()
    test_powershell_integration()
    print("\n=== Installation Test Complete ===")