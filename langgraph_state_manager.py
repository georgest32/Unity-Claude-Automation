#!/usr/bin/env python3
"""
LangGraph State Manager for PowerShell-Python Bridge
Phase 4: Multi-Agent Orchestration - Hour 6: State Management Interface

This module provides advanced state management capabilities for LangGraph workflows,
including state serialization, validation, checkpoint synchronization, and
PowerShell-Python boundary state management.
"""

import json
import sqlite3
import logging
from datetime import datetime
from typing import Dict, Any, List, Optional, Union, TypedDict
from pathlib import Path
from dataclasses import dataclass, asdict
from enum import Enum

# Configure logging
logger = logging.getLogger(__name__)

class StateValidationError(Exception):
    """Raised when state validation fails"""
    pass

class StateSerializationError(Exception):
    """Raised when state serialization/deserialization fails"""
    pass

class StateType(Enum):
    """Types of states supported"""
    BASIC = "basic"
    HITL = "hitl"
    MULTI_AGENT = "multi_agent"
    COMPLEX = "complex"

@dataclass
class StateMetadata:
    """Metadata for state management"""
    state_id: str
    graph_id: str
    thread_id: str
    state_type: StateType
    version: int
    created_at: str
    last_modified: str
    checksum: str
    powershell_origin: bool = True

class PowerShellStateConverter:
    """Converts between PowerShell and Python state formats"""
    
    @staticmethod
    def from_powershell(ps_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Convert PowerShell state format to Python format
        
        Args:
            ps_data: Data from PowerShell (via JSON conversion)
            
        Returns:
            Python-compatible state dictionary
        """
        logger.debug(f"Converting PowerShell data: {type(ps_data)}")
        
        if not isinstance(ps_data, dict):
            raise StateSerializationError(f"Expected dict, got {type(ps_data)}")
        
        converted = {}
        
        for key, value in ps_data.items():
            # Convert PowerShell-specific formats
            if isinstance(value, dict):
                # Handle nested dictionaries recursively
                converted[key] = PowerShellStateConverter.from_powershell(value)
            elif isinstance(value, list):
                # Handle arrays
                converted[key] = [
                    PowerShellStateConverter.from_powershell(item) if isinstance(item, dict) else item
                    for item in value
                ]
            elif isinstance(value, str):
                # Handle PowerShell datetime strings
                if PowerShellStateConverter._is_datetime_string(value):
                    converted[key] = value  # Keep as ISO string for JSON compatibility
                else:
                    converted[key] = value
            elif value is None:
                converted[key] = None
            else:
                # Handle primitives (int, float, bool)
                converted[key] = value
        
        logger.debug(f"Converted to Python format: {len(converted)} keys")
        return converted
    
    @staticmethod
    def to_powershell(python_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Convert Python state format to PowerShell-friendly format
        
        Args:
            python_data: Python state dictionary
            
        Returns:
            PowerShell-compatible state dictionary
        """
        logger.debug(f"Converting Python data to PowerShell format: {type(python_data)}")
        
        if not isinstance(python_data, dict):
            raise StateSerializationError(f"Expected dict, got {type(python_data)}")
        
        converted = {}
        
        for key, value in python_data.items():
            if isinstance(value, dict):
                # Handle nested dictionaries
                converted[key] = PowerShellStateConverter.to_powershell(value)
            elif isinstance(value, list):
                # Handle arrays
                converted[key] = [
                    PowerShellStateConverter.to_powershell(item) if isinstance(item, dict) else item
                    for item in value
                ]
            elif isinstance(value, datetime):
                # Convert datetime to ISO string
                converted[key] = value.isoformat()
            elif value is None:
                converted[key] = None
            else:
                # Handle primitives
                converted[key] = value
        
        logger.debug(f"Converted to PowerShell format: {len(converted)} keys")
        return converted
    
    @staticmethod
    def _is_datetime_string(value: str) -> bool:
        """Check if string looks like a datetime"""
        if not isinstance(value, str):
            return False
        
        # Check for ISO 8601 format patterns
        datetime_patterns = [
            'T',  # ISO 8601 separator
            'Z',  # UTC indicator
            '+',  # Timezone offset
            '-'   # Date separator or timezone offset
        ]
        
        return any(pattern in value for pattern in datetime_patterns) and len(value) > 10

class StateValidator:
    """Validates state data according to different schemas"""
    
    BASIC_SCHEMA = {
        "required": ["messages", "counter"],
        "optional": ["user_input", "result", "timestamp"]
    }
    
    HITL_SCHEMA = {
        "required": ["messages", "counter", "approval_needed"],
        "optional": ["approved", "user_input", "result", "timestamp", "approval_timestamp"]
    }
    
    MULTI_AGENT_SCHEMA = {
        "required": ["messages", "agents", "current_agent"],
        "optional": ["workflow_state", "coordination_data", "timestamp"]
    }
    
    @classmethod
    def validate_state(cls, state_data: Dict[str, Any], state_type: StateType) -> bool:
        """
        Validate state data against schema
        
        Args:
            state_data: State dictionary to validate
            state_type: Type of state validation to perform
            
        Returns:
            True if valid
            
        Raises:
            StateValidationError: If validation fails
        """
        logger.debug(f"Validating state type: {state_type.value}")
        
        if state_type == StateType.BASIC:
            schema = cls.BASIC_SCHEMA
        elif state_type == StateType.HITL:
            schema = cls.HITL_SCHEMA
        elif state_type == StateType.MULTI_AGENT:
            schema = cls.MULTI_AGENT_SCHEMA
        else:
            # Complex states have no fixed schema
            logger.debug("Complex state type - skipping schema validation")
            return True
        
        # Check required fields
        missing_required = []
        for field in schema["required"]:
            if field not in state_data:
                missing_required.append(field)
        
        if missing_required:
            raise StateValidationError(f"Missing required fields: {missing_required}")
        
        # Validate field types for known fields
        cls._validate_field_types(state_data)
        
        logger.debug("State validation passed")
        return True
    
    @classmethod
    def _validate_field_types(cls, state_data: Dict[str, Any]):
        """Validate basic field type constraints"""
        
        # Messages should be a list
        if "messages" in state_data and not isinstance(state_data["messages"], list):
            raise StateValidationError("'messages' field must be a list")
        
        # Counter should be numeric
        if "counter" in state_data and not isinstance(state_data["counter"], (int, float)):
            raise StateValidationError("'counter' field must be numeric")
        
        # Approval fields validation
        if "approval_needed" in state_data and not isinstance(state_data["approval_needed"], bool):
            raise StateValidationError("'approval_needed' field must be boolean")
        
        if "approved" in state_data and state_data["approved"] is not None:
            if not isinstance(state_data["approved"], bool):
                raise StateValidationError("'approved' field must be boolean or null")

class StateCheckpointManager:
    """Manages state checkpoints and persistence"""
    
    def __init__(self, db_path: str):
        self.db_path = Path(db_path)
        self._ensure_tables()
    
    def _ensure_tables(self):
        """Ensure state management tables exist"""
        conn = sqlite3.connect(self.db_path)
        try:
            conn.execute("""
                CREATE TABLE IF NOT EXISTS state_snapshots (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    state_id TEXT UNIQUE,
                    graph_id TEXT,
                    thread_id TEXT,
                    state_type TEXT,
                    version INTEGER,
                    state_data TEXT,
                    metadata TEXT,
                    created_at TEXT,
                    last_modified TEXT
                )
            """)
            
            conn.execute("""
                CREATE INDEX IF NOT EXISTS idx_state_graph_thread 
                ON state_snapshots(graph_id, thread_id)
            """)
            
            conn.execute("""
                CREATE INDEX IF NOT EXISTS idx_state_modified
                ON state_snapshots(last_modified)
            """)
            
            conn.commit()
            logger.debug("State management tables ready")
        finally:
            conn.close()
    
    def save_state_snapshot(self, 
                           state_data: Dict[str, Any], 
                           metadata: StateMetadata) -> str:
        """
        Save a state snapshot
        
        Args:
            state_data: State dictionary to save
            metadata: State metadata
            
        Returns:
            Snapshot ID
        """
        logger.info(f"Saving state snapshot: {metadata.state_id}")
        
        conn = sqlite3.connect(self.db_path)
        try:
            # Serialize state data
            state_json = json.dumps(state_data, ensure_ascii=False, indent=None)
            
            # Convert metadata to dict and handle enum serialization
            metadata_dict = asdict(metadata)
            metadata_dict['state_type'] = metadata_dict['state_type'].value  # Convert StateType enum to string
            metadata_json = json.dumps(metadata_dict, ensure_ascii=False)
            
            conn.execute("""
                INSERT OR REPLACE INTO state_snapshots 
                (state_id, graph_id, thread_id, state_type, version, 
                 state_data, metadata, created_at, last_modified)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                metadata.state_id,
                metadata.graph_id,
                metadata.thread_id,
                metadata.state_type.value,
                metadata.version,
                state_json,
                metadata_json,
                metadata.created_at,
                metadata.last_modified
            ))
            
            conn.commit()
            logger.info(f"State snapshot saved successfully: {metadata.state_id}")
            return metadata.state_id
            
        except Exception as e:
            logger.error(f"Failed to save state snapshot: {e}")
            raise
        finally:
            conn.close()
    
    def load_state_snapshot(self, state_id: str) -> Optional[Dict[str, Any]]:
        """
        Load a state snapshot
        
        Args:
            state_id: ID of snapshot to load
            
        Returns:
            State data or None if not found
        """
        logger.debug(f"Loading state snapshot: {state_id}")
        
        conn = sqlite3.connect(self.db_path)
        try:
            cursor = conn.execute("""
                SELECT state_data, metadata FROM state_snapshots 
                WHERE state_id = ?
            """, (state_id,))
            
            row = cursor.fetchone()
            if row:
                state_data = json.loads(row[0])
                metadata = json.loads(row[1])
                logger.debug(f"Loaded state snapshot: {len(state_data)} fields")
                return {
                    "state": state_data,
                    "metadata": metadata
                }
            else:
                logger.warning(f"State snapshot not found: {state_id}")
                return None
                
        except Exception as e:
            logger.error(f"Failed to load state snapshot: {e}")
            raise
        finally:
            conn.close()
    
    def list_snapshots(self, 
                      graph_id: Optional[str] = None, 
                      thread_id: Optional[str] = None) -> List[Dict[str, Any]]:
        """
        List available state snapshots
        
        Args:
            graph_id: Filter by graph ID
            thread_id: Filter by thread ID
            
        Returns:
            List of snapshot metadata
        """
        logger.debug(f"Listing snapshots - graph: {graph_id}, thread: {thread_id}")
        
        conn = sqlite3.connect(self.db_path)
        try:
            query = "SELECT state_id, graph_id, thread_id, state_type, version, created_at, last_modified FROM state_snapshots"
            params = []
            
            conditions = []
            if graph_id:
                conditions.append("graph_id = ?")
                params.append(graph_id)
            if thread_id:
                conditions.append("thread_id = ?")
                params.append(thread_id)
                
            if conditions:
                query += " WHERE " + " AND ".join(conditions)
            
            query += " ORDER BY last_modified DESC"
            
            cursor = conn.execute(query, params)
            snapshots = []
            
            for row in cursor.fetchall():
                snapshots.append({
                    "state_id": row[0],
                    "graph_id": row[1],
                    "thread_id": row[2],
                    "state_type": row[3],
                    "version": row[4],
                    "created_at": row[5],
                    "last_modified": row[6]
                })
            
            logger.debug(f"Found {len(snapshots)} snapshots")
            return snapshots
            
        except Exception as e:
            logger.error(f"Failed to list snapshots: {e}")
            raise
        finally:
            conn.close()

class LangGraphStateManager:
    """Main state management interface for LangGraph-PowerShell bridge"""
    
    def __init__(self, db_path: str = "langgraph_bridge.db"):
        self.converter = PowerShellStateConverter()
        self.validator = StateValidator()
        self.checkpoint_manager = StateCheckpointManager(db_path)
        
        logger.info("LangGraph State Manager initialized")
    
    def process_powershell_state(self, 
                                ps_state: Dict[str, Any], 
                                state_type: StateType,
                                graph_id: str,
                                thread_id: Optional[str] = None) -> Dict[str, Any]:
        """
        Process state data from PowerShell
        
        Args:
            ps_state: State data from PowerShell
            state_type: Type of state processing
            graph_id: Graph ID for context
            thread_id: Thread ID for context
            
        Returns:
            Processed and validated state
        """
        logger.info(f"Processing PowerShell state: {state_type.value}")
        
        try:
            # Convert from PowerShell format
            python_state = self.converter.from_powershell(ps_state)
            
            # Validate state
            self.validator.validate_state(python_state, state_type)
            
            # Create snapshot if thread_id provided
            if thread_id:
                metadata = StateMetadata(
                    state_id=f"{graph_id}_{thread_id}_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
                    graph_id=graph_id,
                    thread_id=thread_id,
                    state_type=state_type,
                    version=1,
                    created_at=datetime.now().isoformat(),
                    last_modified=datetime.now().isoformat(),
                    checksum=self._calculate_checksum(python_state),
                    powershell_origin=True
                )
                
                self.checkpoint_manager.save_state_snapshot(python_state, metadata)
            
            logger.info("PowerShell state processed successfully")
            return python_state
            
        except Exception as e:
            logger.error(f"Failed to process PowerShell state: {e}")
            raise StateSerializationError(f"State processing failed: {e}")
    
    def prepare_for_powershell(self, 
                              python_state: Dict[str, Any],
                              include_metadata: bool = False) -> Dict[str, Any]:
        """
        Prepare state data for PowerShell consumption
        
        Args:
            python_state: Python state dictionary
            include_metadata: Whether to include processing metadata
            
        Returns:
            PowerShell-compatible state
        """
        logger.debug("Preparing state for PowerShell")
        
        try:
            ps_state = self.converter.to_powershell(python_state)
            
            if include_metadata:
                ps_state["__metadata"] = {
                    "processed_at": datetime.now().isoformat(),
                    "format_version": "1.0",
                    "powershell_optimized": True
                }
            
            logger.debug("State prepared for PowerShell successfully")
            return ps_state
            
        except Exception as e:
            logger.error(f"Failed to prepare state for PowerShell: {e}")
            raise StateSerializationError(f"PowerShell preparation failed: {e}")
    
    def synchronize_checkpoint(self, 
                              graph_id: str, 
                              thread_id: str,
                              current_state: Dict[str, Any]) -> Dict[str, Any]:
        """
        Synchronize state with checkpoint storage
        
        Args:
            graph_id: Graph identifier
            thread_id: Thread identifier  
            current_state: Current state to synchronize
            
        Returns:
            Synchronized state with checkpoint information
        """
        logger.info(f"Synchronizing checkpoint: {graph_id}/{thread_id}")
        
        try:
            # Get latest snapshots for this thread
            snapshots = self.checkpoint_manager.list_snapshots(graph_id, thread_id)
            
            if snapshots:
                latest_snapshot = snapshots[0]  # Most recent
                logger.debug(f"Found latest snapshot: {latest_snapshot['state_id']}")
                
                # Load the snapshot data
                snapshot_data = self.checkpoint_manager.load_state_snapshot(latest_snapshot['state_id'])
                
                if snapshot_data:
                    # Merge with current state (current takes precedence)
                    merged_state = {**snapshot_data['state'], **current_state}
                    
                    # Add checkpoint metadata
                    merged_state["__checkpoint_info"] = {
                        "last_snapshot_id": latest_snapshot['state_id'],
                        "last_snapshot_time": latest_snapshot['last_modified'],
                        "synchronized_at": datetime.now().isoformat()
                    }
                    
                    logger.info("State synchronized with checkpoint")
                    return merged_state
            
            # No checkpoint found, return current state
            current_state["__checkpoint_info"] = {
                "synchronized_at": datetime.now().isoformat(),
                "notes": "No previous checkpoint found"
            }
            
            return current_state
            
        except Exception as e:
            logger.error(f"Checkpoint synchronization failed: {e}")
            # Return current state with error info
            current_state["__checkpoint_error"] = str(e)
            return current_state
    
    def _calculate_checksum(self, state_data: Dict[str, Any]) -> str:
        """Calculate checksum for state data"""
        import hashlib
        
        # Create deterministic JSON representation
        state_json = json.dumps(state_data, sort_keys=True, separators=(',', ':'))
        
        # Calculate SHA-256 hash
        return hashlib.sha256(state_json.encode('utf-8')).hexdigest()[:16]
    
    def get_state_statistics(self) -> Dict[str, Any]:
        """Get statistics about managed states"""
        try:
            snapshots = self.checkpoint_manager.list_snapshots()
            
            stats = {
                "total_snapshots": len(snapshots),
                "unique_graphs": len(set(s["graph_id"] for s in snapshots)),
                "unique_threads": len(set(s["thread_id"] for s in snapshots)),
                "state_types": {},
                "last_activity": None
            }
            
            # Count by state type
            for snapshot in snapshots:
                state_type = snapshot["state_type"]
                stats["state_types"][state_type] = stats["state_types"].get(state_type, 0) + 1
            
            # Get last activity
            if snapshots:
                stats["last_activity"] = snapshots[0]["last_modified"]
            
            return stats
            
        except Exception as e:
            logger.error(f"Failed to get state statistics: {e}")
            return {"error": str(e)}

# Main interface functions for REST API integration
def create_state_manager(db_path: str = "langgraph_bridge.db") -> LangGraphStateManager:
    """Create a state manager instance"""
    return LangGraphStateManager(db_path)

def validate_powershell_state(state_data: Dict[str, Any], state_type: str) -> bool:
    """Validate PowerShell state data"""
    try:
        validator = StateValidator()
        state_type_enum = StateType(state_type)
        return validator.validate_state(state_data, state_type_enum)
    except Exception as e:
        logger.error(f"State validation failed: {e}")
        return False