#!/usr/bin/env python3
"""
LangGraph REST API Server
Unity-Claude-Automation Multi-Agent System
"""

import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Dict, Any, Optional, List
import json
import sqlite3
from datetime import datetime
import os

# Initialize FastAPI app
app = FastAPI(
    title="LangGraph REST API",
    description="Multi-agent orchestration service for Unity-Claude-Automation",
    version="1.0.0"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Database path from environment
DB_PATH = os.getenv("LANGGRAPH_DB_PATH", "/app/data/langgraph.db")

# Initialize database
def init_db():
    """Initialize SQLite database for state management"""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS agent_states (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id TEXT NOT NULL,
            agent_name TEXT NOT NULL,
            state_data TEXT,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    """)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id TEXT NOT NULL,
            sender TEXT NOT NULL,
            recipient TEXT,
            message TEXT,
            metadata TEXT,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    """)
    conn.commit()
    conn.close()

# Request/Response models
class AgentMessage(BaseModel):
    session_id: str
    sender: str
    recipient: Optional[str] = None
    message: str
    metadata: Optional[Dict[str, Any]] = {}

class StateUpdate(BaseModel):
    session_id: str
    agent_name: str
    state_data: Dict[str, Any]

class WorkflowRequest(BaseModel):
    workflow_name: str
    parameters: Dict[str, Any]
    session_id: Optional[str] = None

# API Endpoints
@app.on_event("startup")
async def startup_event():
    """Initialize database on startup"""
    init_db()

@app.get("/")
def root():
    """Root endpoint"""
    return {
        "service": "LangGraph REST API",
        "status": "running",
        "version": "1.0.0"
    }

@app.get("/health")
def health_check():
    """Health check endpoint"""
    try:
        conn = sqlite3.connect(DB_PATH)
        conn.execute("SELECT 1")
        conn.close()
        return {"status": "healthy", "database": "connected"}
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Database error: {str(e)}")

@app.post("/messages")
async def send_message(message: AgentMessage):
    """Send a message to an agent"""
    try:
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        cursor.execute("""
            INSERT INTO messages (session_id, sender, recipient, message, metadata)
            VALUES (?, ?, ?, ?, ?)
        """, (
            message.session_id,
            message.sender,
            message.recipient,
            message.message,
            json.dumps(message.metadata)
        ))
        conn.commit()
        message_id = cursor.lastrowid
        conn.close()
        
        return {
            "message_id": message_id,
            "status": "sent",
            "timestamp": datetime.now().isoformat()
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/messages/{session_id}")
async def get_messages(session_id: str, limit: int = 100):
    """Get messages for a session"""
    try:
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        cursor.execute("""
            SELECT id, sender, recipient, message, metadata, timestamp
            FROM messages
            WHERE session_id = ?
            ORDER BY timestamp DESC
            LIMIT ?
        """, (session_id, limit))
        
        messages = []
        for row in cursor.fetchall():
            messages.append({
                "id": row[0],
                "sender": row[1],
                "recipient": row[2],
                "message": row[3],
                "metadata": json.loads(row[4]) if row[4] else {},
                "timestamp": row[5]
            })
        
        conn.close()
        return {"session_id": session_id, "messages": messages}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/state")
async def update_state(state: StateUpdate):
    """Update agent state"""
    try:
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        cursor.execute("""
            INSERT INTO agent_states (session_id, agent_name, state_data)
            VALUES (?, ?, ?)
        """, (
            state.session_id,
            state.agent_name,
            json.dumps(state.state_data)
        ))
        conn.commit()
        state_id = cursor.lastrowid
        conn.close()
        
        return {
            "state_id": state_id,
            "status": "updated",
            "timestamp": datetime.now().isoformat()
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/state/{session_id}/{agent_name}")
async def get_state(session_id: str, agent_name: str):
    """Get latest state for an agent"""
    try:
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        cursor.execute("""
            SELECT state_data, timestamp
            FROM agent_states
            WHERE session_id = ? AND agent_name = ?
            ORDER BY timestamp DESC
            LIMIT 1
        """, (session_id, agent_name))
        
        row = cursor.fetchone()
        conn.close()
        
        if row:
            return {
                "session_id": session_id,
                "agent_name": agent_name,
                "state": json.loads(row[0]),
                "timestamp": row[1]
            }
        else:
            raise HTTPException(status_code=404, detail="State not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/workflow")
async def execute_workflow(request: WorkflowRequest):
    """Execute a LangGraph workflow"""
    # Placeholder for workflow execution
    # This would integrate with actual LangGraph workflows
    return {
        "workflow": request.workflow_name,
        "session_id": request.session_id or f"session_{datetime.now().timestamp()}",
        "status": "started",
        "message": "Workflow execution started (placeholder implementation)"
    }

@app.get("/agents")
def list_agents():
    """List available agents"""
    return {
        "agents": [
            {"name": "orchestrator", "type": "supervisor", "status": "active"},
            {"name": "repo_analyst", "type": "analyzer", "status": "active"},
            {"name": "doc_generator", "type": "writer", "status": "active"},
            {"name": "code_reviewer", "type": "reviewer", "status": "active"}
        ]
    }

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)