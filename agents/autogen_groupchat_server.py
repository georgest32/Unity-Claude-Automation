#!/usr/bin/env python3
"""
AutoGen GroupChat REST API Server
Provides REST endpoints for multi-agent orchestration using AutoGen
"""

import asyncio
import json
import logging
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Any
from uuid import uuid4

from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.responses import JSONResponse
from pydantic import BaseModel
import uvicorn

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# FastAPI app
app = FastAPI(
    title="AutoGen GroupChat REST API",
    description="Multi-agent orchestration service using AutoGen for Unity-Claude-Automation",
    version="1.0.0"
)

# Request/Response models
class GroupChatRequest(BaseModel):
    """Request model for group chat initiation"""
    task: str
    agents: List[str]
    max_rounds: int = 10
    session_id: Optional[str] = None
    config: Optional[Dict[str, Any]] = None

class AgentMessage(BaseModel):
    """Agent message model"""
    agent: str
    content: str
    timestamp: Optional[datetime] = None
    metadata: Optional[Dict[str, Any]] = None

class ChatResponse(BaseModel):
    """Response model for chat operations"""
    session_id: str
    status: str
    messages: List[Dict[str, Any]]
    metadata: Optional[Dict[str, Any]] = None

# In-memory session storage (replace with database in production)
sessions = {}

@app.get("/")
def root():
    """Root endpoint"""
    return {
        "service": "AutoGen GroupChat API",
        "version": "1.0.0",
        "status": "running",
        "timestamp": datetime.now().isoformat()
    }

@app.get("/health")
def health_check():
    """Health check endpoint"""
    try:
        # Check AutoGen availability - import the actual package
        from autogen_agentchat.agents import AssistantAgent
        import pyautogen
        # Get version from autogen_agentchat or pyautogen
        try:
            import autogen_agentchat
            autogen_version = getattr(autogen_agentchat, '__version__', '0.7.4')
        except:
            autogen_version = "0.10.0"
        
        return {
            "status": "healthy",
            "autogen_version": autogen_version,
            "active_sessions": len(sessions),
            "timestamp": datetime.now().isoformat()
        }
    except ImportError:
        return JSONResponse(
            status_code=503,
            content={
                "status": "unhealthy",
                "error": "AutoGen not available",
                "timestamp": datetime.now().isoformat()
            }
        )

@app.post("/groupchat")
async def create_group_chat(request: GroupChatRequest, background_tasks: BackgroundTasks):
    """Create a new group chat session"""
    try:
        # Generate session ID if not provided
        session_id = request.session_id or f"session_{uuid4().hex[:8]}"
        
        # Create session
        session = {
            "id": session_id,
            "task": request.task,
            "agents": request.agents,
            "max_rounds": request.max_rounds,
            "config": request.config or {},
            "status": "initializing",
            "messages": [],
            "created_at": datetime.now().isoformat()
        }
        
        sessions[session_id] = session
        
        # Start group chat in background
        background_tasks.add_task(run_group_chat, session_id)
        
        return ChatResponse(
            session_id=session_id,
            status="started",
            messages=[],
            metadata={
                "task": request.task,
                "agents": request.agents,
                "max_rounds": request.max_rounds
            }
        )
        
    except Exception as e:
        logger.error(f"Error creating group chat: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

async def run_group_chat(session_id: str):
    """Run group chat in background"""
    try:
        session = sessions.get(session_id)
        if not session:
            logger.error(f"Session {session_id} not found")
            return
        
        # Update status
        session["status"] = "running"
        
        # Import AutoGen components
        try:
            from test_multi_agent_system import create_multi_agent_system
            
            # Create multi-agent system
            mas = create_multi_agent_system()
            
            # Determine which group chat to use based on task
            task = session["task"].lower()
            if "analysis" in task or "analyze" in task:
                group_chat = mas.create_analysis_group_chat()
            elif "research" in task:
                group_chat = mas.create_research_group_chat()
            elif "implement" in task or "code" in task:
                group_chat = mas.create_implementation_group_chat()
            else:
                group_chat = mas.create_full_system_group_chat()
            
            # Run the chat
            result = mas.user_proxy.initiate_chat(
                group_chat.manager,
                message=session["task"],
                max_rounds=session["max_rounds"]
            )
            
            # Store results
            session["messages"] = [
                {
                    "agent": msg.get("name", "unknown"),
                    "content": msg.get("content", ""),
                    "timestamp": datetime.now().isoformat()
                }
                for msg in result.messages if isinstance(result, dict) and "messages" in result
            ]
            session["status"] = "completed"
            
        except ImportError as e:
            logger.error(f"Error importing AutoGen components: {str(e)}")
            session["status"] = "error"
            session["error"] = f"AutoGen components not available: {str(e)}"
            
    except Exception as e:
        logger.error(f"Error running group chat {session_id}: {str(e)}")
        if session_id in sessions:
            sessions[session_id]["status"] = "error"
            sessions[session_id]["error"] = str(e)

@app.get("/groupchat/{session_id}")
async def get_group_chat_status(session_id: str):
    """Get status of a group chat session"""
    session = sessions.get(session_id)
    if not session:
        raise HTTPException(status_code=404, detail=f"Session {session_id} not found")
    
    return ChatResponse(
        session_id=session_id,
        status=session["status"],
        messages=session["messages"],
        metadata={
            "created_at": session["created_at"],
            "task": session["task"],
            "agents": session["agents"]
        }
    )

@app.delete("/groupchat/{session_id}")
async def delete_group_chat(session_id: str):
    """Delete a group chat session"""
    if session_id not in sessions:
        raise HTTPException(status_code=404, detail=f"Session {session_id} not found")
    
    del sessions[session_id]
    return {"message": f"Session {session_id} deleted"}

@app.get("/sessions")
def list_sessions():
    """List all active sessions"""
    return {
        "sessions": [
            {
                "id": sid,
                "status": session["status"],
                "task": session["task"],
                "created_at": session["created_at"]
            }
            for sid, session in sessions.items()
        ],
        "total": len(sessions)
    }

@app.post("/agent/message")
async def send_agent_message(message: AgentMessage):
    """Send a message to an agent (placeholder for future implementation)"""
    return {
        "status": "received",
        "agent": message.agent,
        "content": message.content,
        "timestamp": message.timestamp or datetime.now().isoformat()
    }

@app.get("/agents")
def list_available_agents():
    """List available agents"""
    return {
        "agents": [
            {"name": "user_proxy", "type": "user_proxy", "capabilities": ["code_execution", "human_input"]},
            {"name": "repo_analyst", "type": "assistant", "capabilities": ["code_analysis", "documentation"]},
            {"name": "supervisor_analysis", "type": "supervisor", "capabilities": ["task_routing", "coordination"]},
            {"name": "supervisor_research", "type": "supervisor", "capabilities": ["research", "investigation"]},
            {"name": "supervisor_implementation", "type": "supervisor", "capabilities": ["coding", "testing"]},
            {"name": "doc_generator", "type": "assistant", "capabilities": ["documentation", "writing"]},
            {"name": "code_reviewer", "type": "assistant", "capabilities": ["review", "quality_assurance"]}
        ]
    }

if __name__ == "__main__":
    # Run with proper host binding for Docker
    uvicorn.run(
        app, 
        host="0.0.0.0",  # Bind to all interfaces
        port=8001,
        reload=True,
        access_log=True,
        log_level="info"
    )