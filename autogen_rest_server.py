#!/usr/bin/env python3
"""
AutoGen REST API Server for PowerShell Integration
Week 1 Day 2: AutoGen Multi-Agent Framework Integration

This server provides HTTP endpoints for PowerShell to interact with AutoGen agents,
including multi-agent conversations, code review, and technical debt analysis.
"""

import os
import sys
import json
import uuid
import asyncio
import logging
from datetime import datetime
from typing import Dict, Any, List, Optional

import uvicorn
from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field

# AutoGen imports
import autogen
from autogen import AssistantAgent, UserProxyAgent, ConversableAgent
from autogen import GroupChat, GroupChatManager
from autogen.code_utils import extract_code

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('autogen_server.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Global variables for server state
server_state = {
    "agents": {},
    "conversations": {},
    "group_chats": {},
    "results": {},
    "start_time": datetime.now().isoformat()
}

# Configuration for AutoGen
config_list = [
    {
        "model": "codellama:13b",
        "base_url": "http://localhost:11434/v1",
        "api_key": "ollama"
    }
]

llm_config = {
    "config_list": config_list,
    "temperature": 0.7,
    "max_tokens": 2000,
    "timeout": 300
}

# FastAPI app with lifespan management
app = FastAPI(
    title="AutoGen REST Server",
    description="REST API for PowerShell-AutoGen integration",
    version="1.0.0"
)

# Pydantic models for request/response
class AgentConfig(BaseModel):
    name: str
    system_message: str
    agent_type: str = "assistant"  # assistant, user_proxy, conversable
    llm_config: Optional[Dict] = None
    code_execution_config: Optional[Dict] = None
    human_input_mode: str = "NEVER"
    max_consecutive_auto_reply: int = 10

class ConversationRequest(BaseModel):
    agent1_name: str
    agent2_name: str
    initial_message: str
    max_turns: int = 10

class GroupChatRequest(BaseModel):
    agent_names: List[str]
    initial_message: str
    max_round: int = 10
    speaker_selection_method: str = "auto"

class CodeReviewRequest(BaseModel):
    code: str
    language: str = "python"
    review_type: str = "comprehensive"  # comprehensive, security, performance, style

class TechnicalDebtRequest(BaseModel):
    file_path: str
    analysis_depth: str = "medium"  # light, medium, deep

# API Endpoints

@app.get("/")
async def root():
    """Root endpoint showing server status"""
    return {
        "service": "AutoGen REST Server",
        "status": "running",
        "version": "1.0.0",
        "uptime": server_state["start_time"],
        "agents": len(server_state["agents"]),
        "conversations": len(server_state["conversations"])
    }

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    try:
        # Test AutoGen availability
        test_agent = AssistantAgent("test", llm_config=llm_config)
        return {
            "status": "healthy",
            "autogen_version": autogen.__version__,
            "server_time": datetime.now().isoformat()
        }
    except Exception as e:
        return JSONResponse(
            status_code=503,
            content={"status": "unhealthy", "error": str(e)}
        )

@app.post("/agents")
async def create_agent(config: AgentConfig):
    """Create a new AutoGen agent"""
    try:
        agent_id = str(uuid.uuid4())
        
        # Use provided llm_config or default
        agent_llm_config = config.llm_config or llm_config
        
        # Create appropriate agent type
        if config.agent_type == "assistant":
            agent = AssistantAgent(
                name=config.name,
                system_message=config.system_message,
                llm_config=agent_llm_config,
                max_consecutive_auto_reply=config.max_consecutive_auto_reply
            )
        elif config.agent_type == "user_proxy":
            agent = UserProxyAgent(
                name=config.name,
                system_message=config.system_message,
                code_execution_config=config.code_execution_config or False,
                human_input_mode=config.human_input_mode,
                max_consecutive_auto_reply=config.max_consecutive_auto_reply
            )
        else:
            agent = ConversableAgent(
                name=config.name,
                system_message=config.system_message,
                llm_config=agent_llm_config,
                human_input_mode=config.human_input_mode
            )
        
        server_state["agents"][agent_id] = {
            "agent": agent,
            "config": config.dict(),
            "created": datetime.now().isoformat()
        }
        
        logger.info(f"Created agent {config.name} with ID {agent_id}")
        
        return {
            "agent_id": agent_id,
            "name": config.name,
            "type": config.agent_type,
            "status": "created"
        }
    except Exception as e:
        logger.error(f"Failed to create agent: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/agents")
async def list_agents():
    """List all available agents"""
    agents = []
    for agent_id, agent_data in server_state["agents"].items():
        agents.append({
            "id": agent_id,
            "name": agent_data["config"]["name"],
            "type": agent_data["config"]["agent_type"],
            "created": agent_data["created"]
        })
    return {"agents": agents}

@app.post("/conversations")
async def start_conversation(request: ConversationRequest):
    """Start a conversation between two agents"""
    try:
        # Find agents
        agent1 = None
        agent2 = None
        
        for agent_id, agent_data in server_state["agents"].items():
            if agent_data["config"]["name"] == request.agent1_name:
                agent1 = agent_data["agent"]
            if agent_data["config"]["name"] == request.agent2_name:
                agent2 = agent_data["agent"]
        
        if not agent1 or not agent2:
            raise HTTPException(status_code=404, detail="One or both agents not found")
        
        conversation_id = str(uuid.uuid4())
        
        # Start conversation in background
        async def run_conversation():
            try:
                # Initiate chat
                result = agent1.initiate_chat(
                    agent2,
                    message=request.initial_message,
                    max_turns=request.max_turns
                )
                
                # Store result
                server_state["results"][conversation_id] = {
                    "status": "completed",
                    "result": result,
                    "completed": datetime.now().isoformat()
                }
            except Exception as e:
                server_state["results"][conversation_id] = {
                    "status": "failed",
                    "error": str(e),
                    "completed": datetime.now().isoformat()
                }
        
        # Run in background
        asyncio.create_task(run_conversation())
        
        server_state["conversations"][conversation_id] = {
            "agent1": request.agent1_name,
            "agent2": request.agent2_name,
            "started": datetime.now().isoformat(),
            "status": "running"
        }
        
        return {
            "conversation_id": conversation_id,
            "status": "started",
            "agents": [request.agent1_name, request.agent2_name]
        }
    except Exception as e:
        logger.error(f"Failed to start conversation: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/group_chat")
async def create_group_chat(request: GroupChatRequest):
    """Create a group chat with multiple agents"""
    try:
        # Find agents
        agents = []
        for agent_name in request.agent_names:
            for agent_id, agent_data in server_state["agents"].items():
                if agent_data["config"]["name"] == agent_name:
                    agents.append(agent_data["agent"])
                    break
        
        if len(agents) != len(request.agent_names):
            raise HTTPException(status_code=404, detail="Some agents not found")
        
        # Create group chat
        group_chat = GroupChat(
            agents=agents,
            messages=[],
            max_round=request.max_round,
            speaker_selection_method=request.speaker_selection_method
        )
        
        # Create manager
        manager = GroupChatManager(
            groupchat=group_chat,
            llm_config=llm_config
        )
        
        chat_id = str(uuid.uuid4())
        
        # Start group chat in background
        async def run_group_chat():
            try:
                result = agents[0].initiate_chat(
                    manager,
                    message=request.initial_message,
                    clear_history=True
                )
                
                server_state["results"][chat_id] = {
                    "status": "completed",
                    "result": result,
                    "completed": datetime.now().isoformat()
                }
            except Exception as e:
                server_state["results"][chat_id] = {
                    "status": "failed",
                    "error": str(e),
                    "completed": datetime.now().isoformat()
                }
        
        asyncio.create_task(run_group_chat())
        
        server_state["group_chats"][chat_id] = {
            "agents": request.agent_names,
            "started": datetime.now().isoformat(),
            "status": "running"
        }
        
        return {
            "chat_id": chat_id,
            "status": "started",
            "agents": request.agent_names
        }
    except Exception as e:
        logger.error(f"Failed to create group chat: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/code_review")
async def review_code(request: CodeReviewRequest):
    """Perform code review using specialized agents"""
    try:
        review_id = str(uuid.uuid4())
        
        # Create specialized review agents
        reviewer = AssistantAgent(
            name="CodeReviewer",
            system_message=f"""You are an expert code reviewer specializing in {request.review_type} review.
            Analyze the provided {request.language} code and provide detailed feedback on:
            - Code quality and best practices
            - Potential bugs and issues
            - Performance considerations
            - Security vulnerabilities if applicable
            - Suggestions for improvement""",
            llm_config=llm_config
        )
        
        user_proxy = UserProxyAgent(
            name="Developer",
            system_message="You are a developer seeking code review feedback.",
            human_input_mode="NEVER",
            code_execution_config=False
        )
        
        # Start review
        async def perform_review():
            try:
                result = reviewer.initiate_chat(
                    user_proxy,
                    message=f"Please review this {request.language} code:\n\n{request.code}",
                    max_turns=1
                )
                
                server_state["results"][review_id] = {
                    "status": "completed",
                    "review": result.chat_history[-1]["content"] if result.chat_history else "No review generated",
                    "completed": datetime.now().isoformat()
                }
            except Exception as e:
                server_state["results"][review_id] = {
                    "status": "failed",
                    "error": str(e),
                    "completed": datetime.now().isoformat()
                }
        
        asyncio.create_task(perform_review())
        
        return {
            "review_id": review_id,
            "status": "started",
            "review_type": request.review_type
        }
    except Exception as e:
        logger.error(f"Failed to start code review: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/results/{result_id}")
async def get_result(result_id: str):
    """Get the result of an async operation"""
    if result_id not in server_state["results"]:
        # Check if still running
        if result_id in server_state["conversations"] or result_id in server_state["group_chats"]:
            return {"status": "running", "result_id": result_id}
        raise HTTPException(status_code=404, detail="Result not found")
    
    return server_state["results"][result_id]

@app.delete("/agents/{agent_id}")
async def delete_agent(agent_id: str):
    """Delete an agent"""
    if agent_id not in server_state["agents"]:
        raise HTTPException(status_code=404, detail="Agent not found")
    
    agent_name = server_state["agents"][agent_id]["config"]["name"]
    del server_state["agents"][agent_id]
    
    return {"message": f"Agent {agent_name} deleted", "agent_id": agent_id}

if __name__ == "__main__":
    logger.info("Starting AutoGen REST Server on port 8001...")
    uvicorn.run(app, host="0.0.0.0", port=8001, reload=False)