#!/usr/bin/env python3
"""
Basic LangGraph test to verify installation and SQLite persistence
Phase 4: Multi-Agent Orchestration - Hours 3-4: Persistence Layer & Basic Graph Testing
"""

import sqlite3
from typing import Annotated, TypedDict
from langgraph.graph import StateGraph, START, END
from langgraph.graph.message import add_messages
from langgraph.checkpoint.sqlite import SqliteSaver
from langchain_core.messages import BaseMessage
import tempfile
import os

class State(TypedDict):
    messages: Annotated[list[BaseMessage], add_messages]
    counter: int

def chatbot_node(state: State):
    """Simple chatbot node for testing"""
    return {
        "messages": [{"role": "assistant", "content": f"Hello! Counter is at {state.get('counter', 0)}"}],
        "counter": state.get("counter", 0) + 1
    }

def test_basic_graph_creation():
    """Test basic graph creation without persistence"""
    print("Testing basic LangGraph creation...")
    
    # Create a basic graph
    graph_builder = StateGraph(State)
    graph_builder.add_node("chatbot", chatbot_node)
    graph_builder.add_edge(START, "chatbot")
    graph_builder.add_edge("chatbot", END)
    
    graph = graph_builder.compile()
    
    # Test execution
    result = graph.invoke({
        "messages": [{"role": "user", "content": "Hello"}],
        "counter": 0
    })
    
    print(f"✅ Basic graph execution successful!")
    print(f"   Result: {result}")
    return True

def test_sqlite_persistence():
    """Test SQLite checkpointer persistence"""
    print("\nTesting SQLite persistence layer...")
    
    # Create temporary SQLite database
    temp_db = tempfile.mktemp(suffix='.db')
    
    try:
        # Create SQLite checkpointer using context manager
        with SqliteSaver.from_conn_string(f"file:{temp_db}") as memory:
            # Create graph with checkpointer
            graph_builder = StateGraph(State)
            graph_builder.add_node("chatbot", chatbot_node)
            graph_builder.add_edge(START, "chatbot")
            graph_builder.add_edge("chatbot", END)
            
            graph = graph_builder.compile(checkpointer=memory)
            
            # Test execution with thread ID for persistence
            config = {"configurable": {"thread_id": "test-thread-1"}}
            
            # First execution
            result1 = graph.invoke({
                "messages": [{"role": "user", "content": "Hello"}],
                "counter": 0
            }, config)
            
            print(f"✅ First execution with persistence successful!")
            print(f"   Counter: {result1['counter']}")
            
            # Second execution (should resume state)
            result2 = graph.invoke({
                "messages": [{"role": "user", "content": "Hello again"}],
                "counter": result1["counter"]
            }, config)
            
            print(f"✅ Second execution with state persistence successful!")
            print(f"   Counter: {result2['counter']}")
        
        # Verify SQLite database was created and has data
        if os.path.exists(temp_db):
            conn = sqlite3.connect(temp_db)
            cursor = conn.cursor()
            
            # Check tables
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
            tables = cursor.fetchall()
            print(f"✅ SQLite database created with tables: {[t[0] for t in tables]}")
            
            # Check checkpoint data
            cursor.execute("SELECT COUNT(*) FROM checkpoints;")
            count = cursor.fetchone()[0]
            print(f"✅ Found {count} checkpoint records")
            
            conn.close()
        
        return True
        
    except Exception as e:
        print(f"❌ SQLite persistence test failed: {e}")
        return False
    finally:
        # Cleanup
        if os.path.exists(temp_db):
            os.unlink(temp_db)

def test_development_server():
    """Test langgraph dev command availability"""
    print("\nTesting LangGraph development server availability...")
    
    import subprocess
    try:
        result = subprocess.run([
            './langgraph-env/bin/python', '-m', 'langgraph_cli', '--help'
        ], capture_output=True, text=True, cwd='.')
        
        if result.returncode == 0:
            print("✅ LangGraph CLI available!")
            print(f"   CLI help output: {result.stdout[:200]}...")
            return True
        else:
            print(f"❌ LangGraph CLI test failed: {result.stderr}")
            return False
            
    except Exception as e:
        print(f"❌ Development server test failed: {e}")
        return False

def main():
    """Run all LangGraph tests"""
    print("=== Phase 4: LangGraph Installation and Persistence Tests ===")
    print(f"Python version: {__import__('sys').version}")
    
    # Import version checks
    try:
        import langgraph
        # Try to get version, fallback if __version__ not available
        try:
            version = langgraph.__version__
        except AttributeError:
            version = "installed (version not accessible)"
        print(f"✅ LangGraph: {version}")
    except ImportError as e:
        print(f"❌ LangGraph import failed: {e}")
        return False
    
    try:
        from langgraph.checkpoint.sqlite import SqliteSaver
        print("✅ SQLite checkpointer import successful")
    except ImportError as e:
        print(f"❌ SQLite checkpointer import failed: {e}")
        return False
    
    # Run tests
    tests = [
        test_basic_graph_creation,
        test_sqlite_persistence,
        test_development_server
    ]
    
    passed = 0
    for test in tests:
        try:
            if test():
                passed += 1
        except Exception as e:
            print(f"❌ Test {test.__name__} failed with exception: {e}")
    
    print(f"\n=== Test Summary: {passed}/{len(tests)} tests passed ===")
    
    if passed == len(tests):
        print("🎉 All Phase 4 LangGraph tests successful!")
        print("✅ Ready for Hours 5-8: PowerShell-LangGraph Bridge implementation")
        return True
    else:
        print("⚠️ Some tests failed - review issues before proceeding")
        return False

if __name__ == "__main__":
    exit(0 if main() else 1)