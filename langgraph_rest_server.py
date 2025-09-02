#!/usr/bin/env python3
"""
LangGraph REST API Server for PowerShell Integration
Phase 4: Multi-Agent Orchestration - Hours 5-8: PowerShell-LangGraph Bridge

This server provides HTTP endpoints for PowerShell to interact with LangGraph workflows,
including graph creation, execution, state management, and HITL interrupts.
"""

import os
import sys
import json
import uuid
import asyncio
import logging
from datetime import datetime
from typing import Dict, Any, List, Optional, TypedDict, Annotated
from contextlib import asynccontextmanager

import uvicorn
from fastapi import FastAPI, HTTPException, BackgroundTasks, Depends
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field

# LangGraph imports
from langgraph.graph import StateGraph, START, END
from langgraph.graph.message import add_messages
from langgraph.checkpoint.sqlite import SqliteSaver
from langgraph.types import Command, interrupt
from langchain_core.messages import BaseMessage

# Import state manager for advanced state handling
from langgraph_state_manager import (
    LangGraphStateManager, StateType, StateMetadata,
    create_state_manager, validate_powershell_state
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('langgraph_server.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Global variables for server state
server_state = {
    'graphs': {},
    'checkpointers': {},
    'active_threads': {},
    'interrupt_queue': {},
    'startup_time': None,
    'state_manager': None
}

# SQLite database path
DB_PATH = "langgraph_bridge.db"

# Pydantic models for API requests/responses
class GraphState(TypedDict):
    """Basic graph state structure"""
    messages: Annotated[List[BaseMessage], add_messages]
    counter: int
    user_input: Optional[str]
    approval_needed: Optional[bool]
    approved: Optional[bool]
    result: Optional[str]

class CreateGraphRequest(BaseModel):
    """Request model for creating a new graph"""
    graph_id: str = Field(..., description="Unique identifier for the graph")
    graph_type: str = Field(default="basic", description="Type of graph to create")
    config: Optional[Dict[str, Any]] = Field(default={}, description="Graph configuration")

class ExecuteGraphRequest(BaseModel):
    """Request model for executing a graph"""
    graph_id: str = Field(..., description="Graph identifier to execute")
    initial_state: Optional[Dict[str, Any]] = Field(default={}, description="Initial state")
    thread_id: Optional[str] = Field(default=None, description="Thread ID for persistence")
    interrupt_points: Optional[List[str]] = Field(default=[], description="Nodes where interrupts are allowed")

class ResumeGraphRequest(BaseModel):
    """Request model for resuming an interrupted graph"""
    graph_id: str = Field(..., description="Graph identifier")
    thread_id: str = Field(..., description="Thread ID to resume")
    resume_value: Any = Field(..., description="Value to resume with")

class InterruptResponse(BaseModel):
    """Response model for interrupt requests"""
    thread_id: str
    interrupt_data: Dict[str, Any]
    timestamp: str

class ApprovalRequest(BaseModel):
    """Request model for approval workflow"""
    workflow_id: str = Field(..., description="Workflow identifier")
    title: str = Field(..., description="Approval request title")
    description: str = Field(..., description="Detailed description")
    changes_summary: Optional[str] = Field(default="", description="Summary of changes")
    impact_analysis: Optional[str] = Field(default="", description="Impact analysis")
    urgency_level: str = Field(default="medium", description="Urgency level: low, medium, high, critical")
    request_type: str = Field(default="documentation", description="Type of approval request")
    metadata: Optional[Dict[str, Any]] = Field(default={}, description="Additional metadata")

class ApprovalResponse(BaseModel):
    """Response model for approval decisions"""
    approval_id: str
    approved: bool
    approved_by: str
    comments: Optional[str] = Field(default="")
    timestamp: str

# FastAPI application
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application startup and shutdown handlers"""
    logger.info("Starting LangGraph REST API Server for PowerShell Bridge")
    server_state['startup_time'] = datetime.now().isoformat()
    
    # Initialize SQLite checkpointer
    try:
        with SqliteSaver.from_conn_string(f"file:{DB_PATH}") as checkpointer:
            server_state['default_checkpointer'] = checkpointer
            logger.info(f"Initialized SQLite checkpointer: {DB_PATH}")
    except Exception as e:
        logger.error(f"Failed to initialize SQLite checkpointer: {e}")
    
    # Initialize state manager
    try:
        server_state['state_manager'] = create_state_manager(DB_PATH)
        logger.info("LangGraph State Manager initialized")
    except Exception as e:
        logger.error(f"Failed to initialize state manager: {e}")
    
    yield
    
    logger.info("Shutting down LangGraph REST API Server")

app = FastAPI(
    title="LangGraph PowerShell Bridge API",
    description="REST API for PowerShell-LangGraph integration",
    version="1.0.0",
    lifespan=lifespan
)

# Node functions for different graph types
def chatbot_node(state: GraphState):
    """Basic chatbot node for testing"""
    logger.info(f"Chatbot node processing: counter={state.get('counter', 0)}")
    return {
        "messages": [{"role": "assistant", "content": f"Hello! Counter is at {state.get('counter', 0)}"}],
        "counter": state.get("counter", 0) + 1,
        "result": f"Processed at {datetime.now().isoformat()}"
    }

# Enhanced HITL Nodes (Hour 7: HITL Interrupt Handling)

def simple_approval_node(state: GraphState):
    """Basic approval node - approve/reject only"""
    logger.info("Simple approval node - requesting human approval")
    logger.debug(f"Current state for approval: counter={state.get('counter', 0)}")
    
    # Prepare interrupt data for human review
    approval_data = {
        "interrupt_type": "approval",
        "message": "Do you want to proceed with this action?",
        "current_state": {
            "counter": state.get("counter", 0),
            "last_message": state.get("messages", [])[-1] if state.get("messages") else None
        },
        "options": ["approve", "reject"],
        "timestamp": datetime.now().isoformat()
    }
    
    logger.info("Triggering interrupt for human approval")
    # This will pause the graph and wait for human input
    approval = interrupt(approval_data)
    logger.info(f"Received approval response: {approval}")
    
    # Process the approval response
    approved = approval.get("approved", True) if approval else True
    logger.debug(f"Final approval decision: {approved}")
    
    return {
        "approved": approved,
        "approval_type": "simple",
        "approval_timestamp": datetime.now().isoformat(),
        "approval_response": approval
    }

def detailed_approval_node(state: GraphState):
    """Detailed approval node with multiple options"""
    logger.info("Detailed approval node - requesting detailed human review")
    logger.debug(f"Detailed approval state: counter={state.get('counter', 0)}, messages_count={len(state.get('messages', []))}")
    
    approval_data = {
        "interrupt_type": "detailed_approval", 
        "message": "Please review this action and choose how to proceed:",
        "action_details": {
            "operation": "process_data",
            "current_counter": state.get("counter", 0),
            "proposed_changes": f"Increment counter to {state.get('counter', 0) + 1}",
            "impact": "low"
        },
        "options": ["approve", "reject", "modify", "retry"],
        "timestamp": datetime.now().isoformat()
    }
    
    logger.info("Triggering detailed approval interrupt")
    approval = interrupt(approval_data)
    logger.info(f"Received detailed approval response: {approval}")
    
    # Process the detailed approval response
    approved = approval.get("action") in ["approve", "modify"] if approval else True
    action = approval.get("action", "approve") if approval else "approve"
    logger.debug(f"Detailed approval decision: approved={approved}, action={action}")
    
    return {
        "approved": approved,
        "approval_action": action,
        "approval_details": approval.get("details", {}) if approval else {},
        "approval_type": "detailed",
        "approval_timestamp": datetime.now().isoformat(),
        "approval_response": approval
    }

def state_review_node(state: GraphState):
    """Node that allows state review and modification"""
    logger.info("State review node - requesting human state review")
    logger.debug(f"State to review: {dict(state)}")
    
    review_data = {
        "interrupt_type": "state_review",
        "message": "Please review the current state and make any necessary changes:",
        "current_state": {
            "counter": state.get("counter", 0),
            "messages": state.get("messages", []),
            "result": state.get("result"),
            "user_input": state.get("user_input")
        },
        "editable_fields": ["counter", "user_input"],
        "timestamp": datetime.now().isoformat()
    }
    
    logger.info("Triggering state review interrupt")
    review = interrupt(review_data)
    logger.info(f"Received state review response: {review}")
    
    # Apply any state modifications
    updated_state = dict(state)
    if review and review.get("modifications"):
        logger.debug(f"Applying state modifications: {review['modifications']}")
        updated_state.update(review["modifications"])
    
    updated_state.update({
        "reviewed": True,
        "review_timestamp": datetime.now().isoformat(),
        "review_applied": review.get("modifications", {}) if review else {},
        "review_response": review
    })
    
    logger.debug(f"Final updated state: {updated_state}")
    return updated_state

def conditional_interrupt_node(state: GraphState):
    """Node that conditionally interrupts based on state"""
    current_counter = state.get("counter", 0)
    logger.info(f"Conditional interrupt node - evaluating counter: {current_counter}")
    
    # Only interrupt if counter reaches certain thresholds
    if current_counter >= 5:
        logger.info(f"Conditional interrupt triggered - counter at {current_counter}")
        
        interrupt_data = {
            "interrupt_type": "conditional",
            "message": f"Counter has reached {current_counter}. This requires attention.",
            "trigger_condition": f"counter >= 5",
            "current_state": {"counter": current_counter},
            "urgency": "high" if current_counter >= 10 else "medium",
            "options": ["continue", "modify", "abort"],
            "timestamp": datetime.now().isoformat()
        }
        
        logger.info("Triggering conditional interrupt")
        decision = interrupt(interrupt_data)
        logger.info(f"Received conditional interrupt response: {decision}")
        
        action = decision.get("action", "continue") if decision else "continue"
        logger.debug(f"Conditional interrupt decision: {action}")
        
        return {
            "interrupt_triggered": True,
            "decision": action,
            "counter": current_counter,
            "decision_response": decision
        }
    else:
        logger.info(f"No interrupt needed - counter at {current_counter}, incrementing to {current_counter + 1}")
        return {
            "interrupt_triggered": False,
            "counter": current_counter + 1,
            "message": "Counter below threshold - proceeding normally"
        }

def approval_node(state: GraphState):
    """Enhanced approval node with multiple patterns"""
    logger.info("Enhanced approval node - requesting human input")
    
    # Use LangGraph interrupt for HITL
    approval_data = {
        "interrupt_type": "enhanced_approval",
        "message": "Enhanced approval required for next action",
        "current_state": {
            "counter": state.get("counter", 0),
            "last_message": state.get("messages", [])[-1] if state.get("messages") else None
        },
        "options": ["approve", "reject", "modify", "skip"],
        "metadata": {
            "node": "approval_node",
            "urgency": "medium",
            "auto_timeout": 300  # 5 minutes
        },
        "timestamp": datetime.now().isoformat()
    }
    
    # This will pause execution and wait for human input
    approval = interrupt(approval_data)
    
    logger.info(f"Enhanced approval received: {approval}")
    return {
        "approved": approval.get("approved", False),
        "approval_action": approval.get("action", "approve"),
        "approval_timestamp": datetime.now().isoformat()
    }

def processing_node(state: GraphState):
    """Enhanced processing node that handles multiple approval types"""
    approval_action = state.get("approval_action", "approve")
    
    if state.get("approved", False) or approval_action == "approve":
        logger.info("Processing node - approval granted")
        return {
            "messages": [{"role": "assistant", "content": "Processing approved action..."}],
            "result": "Action completed successfully",
            "counter": state.get("counter", 0) + 1
        }
    elif approval_action == "modify":
        logger.info("Processing node - modifications requested")
        return {
            "messages": [{"role": "assistant", "content": "Action modified per user request"}],
            "result": "Action modified and completed",
            "counter": state.get("counter", 0) + 1,
            "modified": True
        }
    elif approval_action == "skip":
        logger.info("Processing node - action skipped")
        return {
            "messages": [{"role": "assistant", "content": "Action skipped per user request"}],
            "result": "Action skipped",
            "counter": state.get("counter", 0),
            "skipped": True
        }
    else:
        logger.info("Processing node - approval denied")
        return {
            "messages": [{"role": "assistant", "content": "Action was not approved"}],
            "result": "Action cancelled by user",
            "counter": state.get("counter", 0)
        }

# Graph creation functions
def create_basic_graph() -> StateGraph:
    """Create a basic test graph"""
    logger.info("Creating basic graph")
    
    graph_builder = StateGraph(GraphState)
    graph_builder.add_node("chatbot", chatbot_node)
    graph_builder.add_edge(START, "chatbot")
    graph_builder.add_edge("chatbot", END)
    
    return graph_builder

def create_hitl_graph() -> StateGraph:
    """Create a graph with enhanced human-in-the-loop capabilities"""
    logger.info("Creating enhanced HITL graph")
    
    graph_builder = StateGraph(GraphState)
    graph_builder.add_node("initial", chatbot_node)
    graph_builder.add_node("approval", approval_node)
    graph_builder.add_node("processing", processing_node)
    
    graph_builder.add_edge(START, "initial")
    graph_builder.add_edge("initial", "approval")
    graph_builder.add_edge("approval", "processing")
    graph_builder.add_edge("processing", END)
    
    return graph_builder

def create_simple_approval_graph() -> StateGraph:
    """Create a graph with simple approval workflow"""
    logger.info("Creating simple approval graph")
    
    graph_builder = StateGraph(GraphState)
    graph_builder.add_node("start", chatbot_node)
    graph_builder.add_node("simple_approval", simple_approval_node)
    graph_builder.add_node("execute", processing_node)
    
    graph_builder.add_edge(START, "start")
    graph_builder.add_edge("start", "simple_approval")
    graph_builder.add_edge("simple_approval", "execute")
    graph_builder.add_edge("execute", END)
    
    return graph_builder

def create_detailed_approval_graph() -> StateGraph:
    """Create a graph with detailed approval options"""
    logger.info("Creating detailed approval graph")
    
    graph_builder = StateGraph(GraphState)
    graph_builder.add_node("prepare", chatbot_node)
    graph_builder.add_node("detailed_approval", detailed_approval_node)
    graph_builder.add_node("execute", processing_node)
    
    graph_builder.add_edge(START, "prepare")
    graph_builder.add_edge("prepare", "detailed_approval")
    graph_builder.add_edge("detailed_approval", "execute")
    graph_builder.add_edge("execute", END)
    
    return graph_builder

def create_state_review_graph() -> StateGraph:
    """Create a graph with state review capabilities"""
    logger.info("Creating state review graph")
    
    graph_builder = StateGraph(GraphState)
    graph_builder.add_node("initialize", chatbot_node)
    graph_builder.add_node("review_state", state_review_node)
    graph_builder.add_node("finalize", processing_node)
    
    graph_builder.add_edge(START, "initialize")
    graph_builder.add_edge("initialize", "review_state")
    graph_builder.add_edge("review_state", "finalize")
    graph_builder.add_edge("finalize", END)
    
    return graph_builder

def create_conditional_interrupt_graph() -> StateGraph:
    """Create a graph with conditional interrupts"""
    logger.info("Creating conditional interrupt graph")
    
    graph_builder = StateGraph(GraphState)
    graph_builder.add_node("setup", chatbot_node)
    graph_builder.add_node("conditional_check", conditional_interrupt_node)
    graph_builder.add_node("complete", processing_node)
    
    graph_builder.add_edge(START, "setup")
    graph_builder.add_edge("setup", "conditional_check")
    graph_builder.add_edge("conditional_check", "complete")
    graph_builder.add_edge("complete", END)
    
    return graph_builder

# API Endpoints

@app.get("/")
async def root():
    """Root endpoint with server information"""
    return {
        "service": "LangGraph PowerShell Bridge API",
        "version": "1.0.0",
        "status": "running",
        "startup_time": server_state.get('startup_time'),
        "active_graphs": len(server_state['graphs']),
        "active_threads": len(server_state['active_threads'])
    }

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    try:
        # Test SQLite connection by trying to create and use a checkpointer
        checkpointer_cm = SqliteSaver.from_conn_string(f"file:{DB_PATH}")
        with checkpointer_cm as checkpointer:
            # Just test that we can access the checkpointer
            health_status = "healthy"
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        health_status = "unhealthy"
        
    return {
        "status": health_status,
        "timestamp": datetime.now().isoformat(),
        "database": "connected" if health_status == "healthy" else "error"
    }

@app.post("/graphs")
async def create_graph(request: CreateGraphRequest):
    """Create a new LangGraph instance"""
    try:
        logger.info(f"Creating graph: {request.graph_id} (type: {request.graph_type})")
        
        # Check if graph already exists
        if request.graph_id in server_state['graphs']:
            raise HTTPException(status_code=400, detail=f"Graph {request.graph_id} already exists")
        
        # Create graph based on type
        if request.graph_type == "basic":
            graph_builder = create_basic_graph()
        elif request.graph_type == "hitl":
            graph_builder = create_hitl_graph()
        elif request.graph_type == "simple_approval":
            graph_builder = create_simple_approval_graph()
        elif request.graph_type == "detailed_approval":
            graph_builder = create_detailed_approval_graph()
        elif request.graph_type == "state_review":
            graph_builder = create_state_review_graph()
        elif request.graph_type == "conditional_interrupt":
            graph_builder = create_conditional_interrupt_graph()
        else:
            raise HTTPException(status_code=400, detail=f"Unknown graph type: {request.graph_type}")
        
        # Create a checkpointer for this graph
        # Note: We don't use context manager here because we need the checkpointer to stay alive
        import sqlite3
        conn = sqlite3.connect(DB_PATH, check_same_thread=False)
        checkpointer = SqliteSaver(conn=conn)
        compiled_graph = graph_builder.compile(checkpointer=checkpointer)
        
        # Store graph in server state
        server_state['graphs'][request.graph_id] = {
            'graph': compiled_graph,
            'checkpointer': checkpointer,
            'type': request.graph_type,
            'config': request.config,
            'created_at': datetime.now().isoformat()
        }
        
        logger.info(f"Graph {request.graph_id} created successfully")
        return {
            "graph_id": request.graph_id,
            "type": request.graph_type,
            "status": "created",
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Error creating graph {request.graph_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/graphs/{graph_id}/execute")
async def execute_graph(graph_id: str, request: ExecuteGraphRequest):
    """Execute a graph with given initial state"""
    try:
        logger.info(f"Executing graph: {graph_id}")
        
        # Check if graph exists
        if graph_id not in server_state['graphs']:
            raise HTTPException(status_code=404, detail=f"Graph {graph_id} not found")
        
        graph_info = server_state['graphs'][graph_id]
        graph = graph_info['graph']
        
        # Generate thread ID if not provided
        thread_id = request.thread_id or str(uuid.uuid4())
        config = {"configurable": {"thread_id": thread_id}}
        
        # Prepare initial state
        initial_state = {
            "messages": request.initial_state.get("messages", []),
            "counter": request.initial_state.get("counter", 0),
            "user_input": request.initial_state.get("user_input"),
            "approval_needed": False,
            "approved": None,
            "result": None
        }
        
        logger.info(f"Starting graph execution for thread {thread_id}")
        
        try:
            # Use streaming execution with updates mode to detect interrupts
            logger.debug(f"Starting graph stream execution with config: {config}")
            result = None
            final_state = None
            chunks_processed = 0
            interrupted = False
            
            # Stream with updates mode to catch interrupts
            for chunk in graph.stream(initial_state, config, stream_mode="updates"):
                chunks_processed += 1
                logger.debug(f"Processing chunk {chunks_processed}: {chunk}")
                final_state = chunk
                result = chunk
            
            logger.debug(f"Stream completed. Processed {chunks_processed} chunks.")
            
            # Check if the graph was interrupted by examining the final state
            # Get the current snapshot to check for interrupts
            try:
                snapshot = graph.get_state(config)
                logger.debug(f"Final state snapshot: next={snapshot.next}, tasks={len(snapshot.tasks) if snapshot.tasks else 0}")
                
                # If there are pending tasks or next nodes, it might be interrupted
                if snapshot.next or (snapshot.tasks and len(snapshot.tasks) > 0):
                    logger.info(f"Graph {graph_id} appears to be interrupted - has pending tasks or next nodes")
                    interrupted = True
                    
                    # Store interrupt information
                    server_state['active_threads'][thread_id] = {
                        'graph_id': graph_id,
                        'status': 'interrupted',
                        'last_update': datetime.now().isoformat(),
                        'snapshot': {
                            'next': snapshot.next,
                            'tasks': len(snapshot.tasks) if snapshot.tasks else 0
                        }
                    }
                    
                    return {
                        "graph_id": graph_id,
                        "thread_id": thread_id,
                        "status": "interrupted",
                        "message": "Graph paused for human input",
                        "next_nodes": snapshot.next,
                        "pending_tasks": len(snapshot.tasks) if snapshot.tasks else 0,
                        "timestamp": datetime.now().isoformat()
                    }
                    
            except Exception as snapshot_error:
                logger.warning(f"Could not get state snapshot: {snapshot_error}")
            
            # If we get here without interruption, execution completed
            server_state['active_threads'][thread_id] = {
                'graph_id': graph_id,
                'status': 'completed',
                'last_update': datetime.now().isoformat(),
                'result': result
            }
            
            logger.info(f"Graph {graph_id} execution completed for thread {thread_id}")
            return {
                "graph_id": graph_id,
                "thread_id": thread_id,
                "status": "completed",
                "result": result,
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as exec_error:
            # Check if this is an interrupt (expected for HITL graphs)
            if "interrupt" in str(exec_error).lower():
                logger.info(f"Graph {graph_id} interrupted for HITL - thread {thread_id}")
                
                # Store interrupt information
                server_state['active_threads'][thread_id] = {
                    'graph_id': graph_id,
                    'status': 'interrupted',
                    'last_update': datetime.now().isoformat()
                }
                
                return {
                    "graph_id": graph_id,
                    "thread_id": thread_id,
                    "status": "interrupted",
                    "message": "Graph paused for human input",
                    "timestamp": datetime.now().isoformat()
                }
            else:
                raise exec_error
                
    except Exception as e:
        logger.error(f"Error executing graph {graph_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/graphs/{graph_id}/resume")
async def resume_graph(graph_id: str, request: ResumeGraphRequest):
    """Resume an interrupted graph execution"""
    try:
        logger.info(f"Resuming graph: {graph_id}, thread: {request.thread_id}")
        
        # Check if graph exists
        if graph_id not in server_state['graphs']:
            raise HTTPException(status_code=404, detail=f"Graph {graph_id} not found")
        
        # Check if thread exists and is interrupted
        if request.thread_id not in server_state['active_threads']:
            raise HTTPException(status_code=404, detail=f"Thread {request.thread_id} not found")
        
        thread_info = server_state['active_threads'][request.thread_id]
        if thread_info['status'] != 'interrupted':
            raise HTTPException(status_code=400, detail=f"Thread {request.thread_id} is not interrupted")
        
        graph_info = server_state['graphs'][graph_id]
        graph = graph_info['graph']
        
        config = {"configurable": {"thread_id": request.thread_id}}
        
        # Resume with provided value
        resume_command = Command(resume=request.resume_value)
        result = graph.invoke(resume_command, config)
        
        # Update thread status
        server_state['active_threads'][request.thread_id] = {
            'graph_id': graph_id,
            'status': 'completed',
            'last_update': datetime.now().isoformat(),
            'result': result
        }
        
        logger.info(f"Graph {graph_id} resumed and completed for thread {request.thread_id}")
        return {
            "graph_id": graph_id,
            "thread_id": request.thread_id,
            "status": "completed",
            "result": result,
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Error resuming graph {graph_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/graphs")
async def list_graphs():
    """List all available graphs"""
    graphs_info = {}
    for graph_id, info in server_state['graphs'].items():
        graphs_info[graph_id] = {
            'type': info['type'],
            'created_at': info['created_at'],
            'config': info['config']
        }
    
    return {
        "graphs": graphs_info,
        "total": len(graphs_info),
        "timestamp": datetime.now().isoformat()
    }

@app.get("/graphs/{graph_id}")
async def get_graph(graph_id: str):
    """Get information about a specific graph"""
    try:
        logger.info(f"Getting information for graph: {graph_id}")
        
        if graph_id not in server_state['graphs']:
            raise HTTPException(status_code=404, detail=f"Graph {graph_id} not found")
        
        info = server_state['graphs'][graph_id]
        return {
            "graph_id": graph_id,
            "type": info['type'],
            "created_at": info['created_at'],
            "config": info['config'],
            "status": "active",
            "timestamp": datetime.now().isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting graph {graph_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/threads")
async def list_threads():
    """List all active threads"""
    return {
        "threads": server_state['active_threads'],
        "total": len(server_state['active_threads']),
        "timestamp": datetime.now().isoformat()
    }

@app.get("/threads/{thread_id}")
async def get_thread_status(thread_id: str):
    """Get status of a specific thread"""
    if thread_id not in server_state['active_threads']:
        raise HTTPException(status_code=404, detail=f"Thread {thread_id} not found")
    
    return {
        "thread_id": thread_id,
        "info": server_state['active_threads'][thread_id],
        "timestamp": datetime.now().isoformat()
    }

# Additional utility endpoints
@app.delete("/graphs/{graph_id}")
async def delete_graph(graph_id: str):
    """Delete a graph"""
    if graph_id not in server_state['graphs']:
        raise HTTPException(status_code=404, detail=f"Graph {graph_id} not found")
    
    del server_state['graphs'][graph_id]
    logger.info(f"Deleted graph: {graph_id}")
    
    return {
        "graph_id": graph_id,
        "status": "deleted",
        "timestamp": datetime.now().isoformat()
    }

# State Management Endpoints (Hour 6: State Management Interface)

class StateProcessRequest(BaseModel):
    """Request model for processing PowerShell state"""
    state_data: Dict[str, Any] = Field(..., description="State data from PowerShell")
    state_type: str = Field(..., description="Type of state (basic, hitl, multi_agent, complex)")
    graph_id: str = Field(..., description="Graph ID for context")
    thread_id: Optional[str] = Field(default=None, description="Thread ID for context")

class StateSyncRequest(BaseModel):
    """Request model for state synchronization"""
    graph_id: str = Field(..., description="Graph identifier")
    thread_id: str = Field(..., description="Thread identifier")
    current_state: Dict[str, Any] = Field(..., description="Current state to synchronize")

@app.post("/state/validate")
async def validate_state(request: StateProcessRequest):
    """Validate PowerShell state data"""
    try:
        logger.info(f"Validating state type: {request.state_type}")
        
        # Validate state using the state manager
        is_valid = validate_powershell_state(request.state_data, request.state_type)
        
        return {
            "valid": is_valid,
            "state_type": request.state_type,
            "validation_timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        logger.error(f"State validation error: {e}")
        raise HTTPException(status_code=400, detail=f"Validation failed: {str(e)}")

@app.post("/state/process")
async def process_powershell_state(request: StateProcessRequest):
    """Process state data from PowerShell"""
    try:
        logger.info(f"Processing PowerShell state for graph: {request.graph_id}")
        
        if not server_state['state_manager']:
            raise HTTPException(status_code=503, detail="State manager not initialized")
        
        # Convert state type string to enum
        try:
            state_type_enum = StateType(request.state_type)
        except ValueError:
            raise HTTPException(status_code=400, detail=f"Invalid state type: {request.state_type}")
        
        # Process the PowerShell state
        processed_state = server_state['state_manager'].process_powershell_state(
            request.state_data, 
            state_type_enum, 
            request.graph_id,
            request.thread_id
        )
        
        return {
            "processed_state": processed_state,
            "graph_id": request.graph_id,
            "thread_id": request.thread_id,
            "state_type": request.state_type,
            "processing_timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        logger.error(f"State processing error: {e}")
        raise HTTPException(status_code=500, detail=f"Processing failed: {str(e)}")

@app.post("/state/synchronize")
async def synchronize_state(request: StateSyncRequest):
    """Synchronize state with checkpoint storage"""
    try:
        logger.info(f"Synchronizing state for {request.graph_id}/{request.thread_id}")
        
        if not server_state['state_manager']:
            raise HTTPException(status_code=503, detail="State manager not initialized")
        
        # Synchronize with checkpoint
        synchronized_state = server_state['state_manager'].synchronize_checkpoint(
            request.graph_id,
            request.thread_id, 
            request.current_state
        )
        
        return {
            "synchronized_state": synchronized_state,
            "graph_id": request.graph_id,
            "thread_id": request.thread_id,
            "synchronization_timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        logger.error(f"State synchronization error: {e}")
        raise HTTPException(status_code=500, detail=f"Synchronization failed: {str(e)}")

@app.get("/state/snapshots")
async def list_state_snapshots(graph_id: Optional[str] = None, thread_id: Optional[str] = None):
    """List available state snapshots"""
    try:
        logger.info(f"Listing state snapshots - graph: {graph_id}, thread: {thread_id}")
        
        if not server_state['state_manager']:
            raise HTTPException(status_code=503, detail="State manager not initialized")
        
        snapshots = server_state['state_manager'].checkpoint_manager.list_snapshots(graph_id, thread_id)
        
        return {
            "snapshots": snapshots,
            "total": len(snapshots),
            "filters": {
                "graph_id": graph_id,
                "thread_id": thread_id
            },
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Failed to list snapshots: {e}")
        raise HTTPException(status_code=500, detail=f"Snapshot listing failed: {str(e)}")

@app.get("/state/snapshots/{snapshot_id}")
async def get_state_snapshot(snapshot_id: str):
    """Get a specific state snapshot"""
    try:
        logger.info(f"Getting state snapshot: {snapshot_id}")
        
        if not server_state['state_manager']:
            raise HTTPException(status_code=503, detail="State manager not initialized")
        
        snapshot_data = server_state['state_manager'].checkpoint_manager.load_state_snapshot(snapshot_id)
        
        if not snapshot_data:
            raise HTTPException(status_code=404, detail=f"Snapshot {snapshot_id} not found")
        
        return {
            "snapshot_id": snapshot_id,
            "state_data": snapshot_data['state'],
            "metadata": snapshot_data['metadata'],
            "retrieval_timestamp": datetime.now().isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get snapshot: {e}")
        raise HTTPException(status_code=500, detail=f"Snapshot retrieval failed: {str(e)}")

@app.get("/state/statistics")
async def get_state_statistics():
    """Get state management statistics"""
    try:
        logger.info("Getting state management statistics")
        
        if not server_state['state_manager']:
            raise HTTPException(status_code=503, detail="State manager not initialized")
        
        stats = server_state['state_manager'].get_state_statistics()
        
        return {
            "statistics": stats,
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Failed to get statistics: {e}")
        raise HTTPException(status_code=500, detail=f"Statistics retrieval failed: {str(e)}")

@app.post("/state/prepare-for-powershell")
async def prepare_state_for_powershell(state_data: Dict[str, Any], include_metadata: bool = False):
    """Prepare Python state for PowerShell consumption"""
    try:
        logger.info("Preparing state for PowerShell")
        
        if not server_state['state_manager']:
            raise HTTPException(status_code=503, detail="State manager not initialized")
        
        ps_ready_state = server_state['state_manager'].prepare_for_powershell(state_data, include_metadata)
        
        return {
            "powershell_state": ps_ready_state,
            "include_metadata": include_metadata,
            "preparation_timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Failed to prepare state for PowerShell: {e}")
        raise HTTPException(status_code=500, detail=f"PowerShell preparation failed: {str(e)}")

@app.delete("/threads/{thread_id}")
async def delete_thread(thread_id: str):
    """Delete a thread"""
    if thread_id not in server_state['active_threads']:
        raise HTTPException(status_code=404, detail=f"Thread {thread_id} not found")
    
    del server_state['active_threads'][thread_id]
    logger.info(f"Deleted thread: {thread_id}")
    
    return {
        "thread_id": thread_id,
        "status": "deleted",
        "timestamp": datetime.now().isoformat()
    }

# HITL Approval Workflow Endpoints

@app.post("/approval/request")
async def create_approval_request(request: ApprovalRequest):
    """Create a new approval request with HITL integration"""
    try:
        # Generate unique approval ID
        approval_id = str(uuid.uuid4())
        thread_id = str(uuid.uuid4())
        
        # Create approval request data
        approval_data = {
            "approval_id": approval_id,
            "thread_id": thread_id,
            "workflow_id": request.workflow_id,
            "title": request.title,
            "description": request.description,
            "changes_summary": request.changes_summary,
            "impact_analysis": request.impact_analysis,
            "urgency_level": request.urgency_level,
            "request_type": request.request_type,
            "metadata": request.metadata,
            "status": "pending",
            "created_at": datetime.now().isoformat(),
            "expires_at": None,  # Would be calculated based on urgency
            "escalation_level": 0
        }
        
        # Store in interrupt queue for processing
        server_state['interrupt_queue'][approval_id] = approval_data
        
        logger.info(f"Created approval request: {approval_id} for workflow: {request.workflow_id}")
        
        return {
            "approval_id": approval_id,
            "thread_id": thread_id,
            "status": "created",
            "timestamp": datetime.now().isoformat(),
            "approval_data": approval_data
        }
        
    except Exception as e:
        logger.error(f"Failed to create approval request: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to create approval request: {str(e)}")

@app.post("/approval/{approval_id}/respond")
async def respond_to_approval(approval_id: str, response: ApprovalResponse):
    """Process approval response and resume workflow"""
    try:
        if approval_id not in server_state['interrupt_queue']:
            raise HTTPException(status_code=404, detail=f"Approval request {approval_id} not found")
        
        approval_data = server_state['interrupt_queue'][approval_id]
        thread_id = approval_data.get('thread_id')
        
        # Update approval status
        approval_data.update({
            "status": "approved" if response.approved else "rejected",
            "approved_by": response.approved_by,
            "approved_at": response.timestamp,
            "comments": response.comments,
            "decision": response.approved
        })
        
        # Resume workflow with approval decision
        resume_data = {
            "approved": response.approved,
            "approved_by": response.approved_by,
            "approval_timestamp": response.timestamp,
            "comments": response.comments,
            "approval_id": approval_id
        }
        
        # If there's an active thread, resume it
        if thread_id in server_state['active_threads']:
            # This would integrate with actual LangGraph resumption
            logger.info(f"Resuming workflow thread {thread_id} with approval decision: {response.approved}")
        
        logger.info(f"Processed approval response for {approval_id}: {response.approved}")
        
        return {
            "approval_id": approval_id,
            "thread_id": thread_id,
            "status": "processed",
            "decision": response.approved,
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Failed to process approval response: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to process approval response: {str(e)}")

@app.get("/approval/{approval_id}")
async def get_approval_status(approval_id: str):
    """Get the current status of an approval request"""
    try:
        if approval_id not in server_state['interrupt_queue']:
            raise HTTPException(status_code=404, detail=f"Approval request {approval_id} not found")
        
        approval_data = server_state['interrupt_queue'][approval_id]
        
        return {
            "approval_id": approval_id,
            "status": approval_data.get("status", "pending"),
            "workflow_id": approval_data.get("workflow_id"),
            "title": approval_data.get("title"),
            "created_at": approval_data.get("created_at"),
            "approved_by": approval_data.get("approved_by"),
            "approved_at": approval_data.get("approved_at"),
            "comments": approval_data.get("comments"),
            "escalation_level": approval_data.get("escalation_level", 0)
        }
        
    except Exception as e:
        logger.error(f"Failed to get approval status: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get approval status: {str(e)}")

@app.get("/approval/pending")
async def get_pending_approvals():
    """Get all pending approval requests"""
    try:
        pending = []
        for approval_id, data in server_state['interrupt_queue'].items():
            if data.get("status") == "pending":
                pending.append({
                    "approval_id": approval_id,
                    "workflow_id": data.get("workflow_id"),
                    "title": data.get("title"),
                    "urgency_level": data.get("urgency_level"),
                    "created_at": data.get("created_at"),
                    "request_type": data.get("request_type")
                })
        
        return {
            "pending_approvals": pending,
            "count": len(pending),
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Failed to get pending approvals: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get pending approvals: {str(e)}")

@app.post("/approval/{approval_id}/escalate")
async def escalate_approval(approval_id: str):
    """Escalate an approval request to the next level"""
    try:
        if approval_id not in server_state['interrupt_queue']:
            raise HTTPException(status_code=404, detail=f"Approval request {approval_id} not found")
        
        approval_data = server_state['interrupt_queue'][approval_id]
        current_level = approval_data.get('escalation_level', 0)
        
        # Increment escalation level
        approval_data['escalation_level'] = current_level + 1
        approval_data['escalated_at'] = datetime.now().isoformat()
        
        logger.info(f"Escalated approval {approval_id} to level {current_level + 1}")
        
        return {
            "approval_id": approval_id,
            "escalation_level": current_level + 1,
            "status": "escalated",
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Failed to escalate approval: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to escalate approval: {str(e)}")

@app.post("/workflow/{workflow_id}/interrupt")
async def interrupt_workflow_for_approval(workflow_id: str, request: ApprovalRequest):
    """Interrupt an active workflow and request approval"""
    try:
        # Create approval request
        approval_response = await create_approval_request(request)
        approval_id = approval_response["approval_id"]
        thread_id = approval_response["thread_id"]
        
        # Find active graph for this workflow
        active_graph = None
        for graph_id, graph_data in server_state['graphs'].items():
            if graph_data.get('workflow_id') == workflow_id:
                active_graph = graph_id
                break
        
        if active_graph:
            # Create interrupt data for LangGraph
            interrupt_data = {
                "interrupt_type": "approval_required",
                "approval_id": approval_id,
                "workflow_id": workflow_id,
                "title": request.title,
                "description": request.description,
                "urgency_level": request.urgency_level,
                "requires_action": True,
                "timestamp": datetime.now().isoformat()
            }
            
            logger.info(f"Interrupting workflow {workflow_id} for approval {approval_id}")
            
            return {
                "workflow_id": workflow_id,
                "approval_id": approval_id,
                "thread_id": thread_id,
                "status": "interrupted",
                "interrupt_data": interrupt_data,
                "timestamp": datetime.now().isoformat()
            }
        else:
            # No active graph found, just create the approval request
            logger.warning(f"No active graph found for workflow {workflow_id}, created approval request only")
            return approval_response
        
    except Exception as e:
        logger.error(f"Failed to interrupt workflow for approval: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to interrupt workflow: {str(e)}")

# Main server startup
def main():
    """Start the FastAPI server"""
    port = int(os.environ.get("PORT", 8000))
    host = os.environ.get("HOST", "127.0.0.1")
    
    logger.info(f"Starting LangGraph REST server on {host}:{port}")
    
    uvicorn.run(
        app,
        host=host,
        port=port,
        log_level="info",
        reload=False  # Disable reload for production stability
    )

if __name__ == "__main__":
    main()