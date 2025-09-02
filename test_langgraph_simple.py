#!/usr/bin/env python3
"""
Simplified LangGraph test for Phase 4 verification
"""

import os
import tempfile
import sqlite3

def test_imports():
    """Test basic imports"""
    print("Testing LangGraph imports...")
    
    try:
        import langgraph
        print("✅ langgraph imported successfully")
        
        from langgraph.graph import StateGraph
        print("✅ StateGraph imported successfully")
        
        from langgraph.checkpoint.sqlite import SqliteSaver
        print("✅ SqliteSaver imported successfully")
        
        return True
    except ImportError as e:
        print(f"❌ Import failed: {e}")
        return False

def test_sqlite():
    """Test SQLite functionality"""
    print("\nTesting SQLite database creation...")
    
    temp_db = tempfile.mktemp(suffix='.db')
    
    try:
        # Test basic SQLite
        conn = sqlite3.connect(temp_db)
        conn.execute("CREATE TABLE test (id INTEGER, message TEXT)")
        conn.execute("INSERT INTO test VALUES (1, 'Hello World')")
        conn.commit()
        
        cursor = conn.execute("SELECT * FROM test")
        result = cursor.fetchone()
        conn.close()
        
        print(f"✅ SQLite test successful: {result}")
        
        # Test SqliteSaver creation
        from langgraph.checkpoint.sqlite import SqliteSaver
        with SqliteSaver.from_conn_string(f"file:{temp_db}") as saver:
            print(f"✅ SqliteSaver context manager working: {type(saver)}")
            
        return True
        
    except Exception as e:
        print(f"❌ SQLite test failed: {e}")
        return False
    finally:
        if os.path.exists(temp_db):
            os.unlink(temp_db)

def test_basic_graph():
    """Test basic graph without persistence"""
    print("\nTesting basic LangGraph...")
    
    try:
        from typing import TypedDict
        from langgraph.graph import StateGraph, START, END
        
        class SimpleState(TypedDict):
            count: int
        
        def increment_node(state: SimpleState):
            return {"count": state["count"] + 1}
        
        # Create basic graph
        builder = StateGraph(SimpleState)
        builder.add_node("increment", increment_node)
        builder.add_edge(START, "increment")
        builder.add_edge("increment", END)
        
        graph = builder.compile()
        
        # Test execution
        result = graph.invoke({"count": 0})
        print(f"✅ Basic graph execution successful: {result}")
        
        return True
        
    except Exception as e:
        print(f"❌ Basic graph test failed: {e}")
        return False

def main():
    """Run simplified tests"""
    print("=== Phase 4: LangGraph Simplified Tests ===")
    
    tests = [test_imports, test_sqlite, test_basic_graph]
    passed = 0
    
    for test in tests:
        try:
            if test():
                passed += 1
        except Exception as e:
            print(f"❌ Test {test.__name__} failed: {e}")
    
    print(f"\n=== Results: {passed}/{len(tests)} tests passed ===")
    
    if passed == len(tests):
        print("🎉 LangGraph environment ready!")
        return True
    else:
        print("⚠️  Some tests failed")
        return False

if __name__ == "__main__":
    exit(0 if main() else 1)