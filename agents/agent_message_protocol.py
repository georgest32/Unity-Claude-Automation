"""
agent_message_protocol.py
Agent communication protocol with message validation and routing
"""

from typing import Dict, Any, Optional, List, Union
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
import json
import uuid
import asyncio
from pydantic import BaseModel, Field, validator
import logging

# Configure logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)


class MessagePriority(Enum):
    """Message priority levels"""
    CRITICAL = 10
    HIGH = 8
    NORMAL = 5
    LOW = 3
    BACKGROUND = 1


class EventType(Enum):
    """Event types for agent communication"""
    # Task events
    TASK_ASSIGNED = "task_assigned"
    TASK_STARTED = "task_started"
    TASK_COMPLETED = "task_completed"
    TASK_FAILED = "task_failed"
    
    # Response events
    RESPONSE_READY = "response_ready"
    RESPONSE_ACKNOWLEDGED = "response_acknowledged"
    
    # State events
    STATE_CHANGED = "state_changed"
    STATE_CHECKPOINT = "state_checkpoint"
    
    # Error events
    ERROR_OCCURRED = "error_occurred"
    ERROR_RECOVERED = "error_recovered"
    
    # Control events
    AGENT_STARTED = "agent_started"
    AGENT_STOPPED = "agent_stopped"
    AGENT_PAUSED = "agent_paused"
    AGENT_RESUMED = "agent_resumed"
    
    # Coordination events
    HANDOFF_REQUEST = "handoff_request"
    HANDOFF_ACCEPTED = "handoff_accepted"
    COLLABORATION_REQUEST = "collaboration_request"


class MessageSchema(BaseModel):
    """Pydantic model for message validation"""
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    event_type: EventType
    sender_id: str
    recipient_id: Optional[str] = None  # None for broadcast
    payload: Dict[str, Any]
    timestamp: datetime = Field(default_factory=datetime.now)
    priority: MessagePriority = MessagePriority.NORMAL
    correlation_id: Optional[str] = None  # For tracking related messages
    requires_response: bool = False
    ttl_seconds: Optional[int] = None  # Time to live
    
    @validator('payload')
    def validate_payload(cls, v, values):
        """Validate payload based on event type"""
        event_type = values.get('event_type')
        
        if event_type in [EventType.TASK_ASSIGNED, EventType.TASK_STARTED]:
            required_fields = ['task_id', 'task_type', 'description']
            for field in required_fields:
                if field not in v:
                    raise ValueError(f"Missing required field '{field}' for {event_type.value}")
                    
        elif event_type == EventType.ERROR_OCCURRED:
            if 'error_message' not in v:
                raise ValueError("Missing 'error_message' in error event")
                
        return v
        
    class Config:
        use_enum_values = True
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }


class MessageRouter:
    """Routes messages between agents based on rules and subscriptions"""
    
    def __init__(self):
        self.subscriptions: Dict[str, List[EventType]] = {}
        self.routing_rules: List[Dict[str, Any]] = []
        self.message_handlers: Dict[str, Any] = {}
        self.message_history: List[MessageSchema] = []
        self.max_history_size = 1000
        
    def subscribe_agent(self, agent_id: str, event_types: List[EventType]):
        """Subscribe agent to specific event types"""
        self.subscriptions[agent_id] = event_types
        logger.info(f"Agent {agent_id} subscribed to {len(event_types)} event types")
        
    def add_routing_rule(self, rule: Dict[str, Any]):
        """Add routing rule for message distribution"""
        # Rule format: {"condition": lambda msg: ..., "targets": [...], "priority": int}
        self.routing_rules.append(rule)
        self.routing_rules.sort(key=lambda x: x.get('priority', 0), reverse=True)
        
    def route_message(self, message: MessageSchema) -> List[str]:
        """Determine target agents for a message"""
        targets = []
        
        # Direct recipient
        if message.recipient_id:
            targets.append(message.recipient_id)
            
        # Subscription-based routing
        for agent_id, event_types in self.subscriptions.items():
            if message.event_type in event_types and agent_id != message.sender_id:
                if agent_id not in targets:
                    targets.append(agent_id)
                    
        # Rule-based routing
        for rule in self.routing_rules:
            condition = rule.get('condition')
            if condition and condition(message):
                rule_targets = rule.get('targets', [])
                for target in rule_targets:
                    if target not in targets and target != message.sender_id:
                        targets.append(target)
                        
        logger.debug(f"Message {message.id} routed to {len(targets)} targets")
        return targets
        
    def add_to_history(self, message: MessageSchema):
        """Add message to history with size limit"""
        self.message_history.append(message)
        if len(self.message_history) > self.max_history_size:
            self.message_history.pop(0)
            
    def get_message_trail(self, correlation_id: str) -> List[MessageSchema]:
        """Get all messages with the same correlation ID"""
        return [msg for msg in self.message_history if msg.correlation_id == correlation_id]


class PriorityMessageQueue:
    """Priority queue for message ordering"""
    
    def __init__(self, max_size: int = 10000):
        self.queue = asyncio.PriorityQueue(maxsize=max_size)
        self.message_map: Dict[str, MessageSchema] = {}
        
    async def enqueue(self, message: MessageSchema):
        """Add message to priority queue"""
        # Convert priority to negative for proper ordering (higher priority = lower number)
        priority_value = -message.priority.value
        
        # Add TTL expiration time if specified
        expiration = None
        if message.ttl_seconds:
            expiration = datetime.now().timestamp() + message.ttl_seconds
            
        queue_item = (priority_value, message.timestamp.timestamp(), expiration, message.id)
        await self.queue.put(queue_item)
        self.message_map[message.id] = message
        
    async def dequeue(self) -> Optional[MessageSchema]:
        """Get next message from queue"""
        while not self.queue.empty():
            try:
                priority, timestamp, expiration, message_id = await self.queue.get()
                
                # Check if message has expired
                if expiration and datetime.now().timestamp() > expiration:
                    logger.debug(f"Message {message_id} expired, skipping")
                    del self.message_map[message_id]
                    continue
                    
                message = self.message_map.pop(message_id, None)
                if message:
                    return message
                    
            except asyncio.QueueEmpty:
                break
                
        return None
        
    def size(self) -> int:
        """Get current queue size"""
        return self.queue.qsize()
        
    def clear_expired(self):
        """Remove expired messages from queue"""
        current_time = datetime.now().timestamp()
        expired_ids = []
        
        for message_id, message in self.message_map.items():
            if message.ttl_seconds:
                expiration = message.timestamp.timestamp() + message.ttl_seconds
                if current_time > expiration:
                    expired_ids.append(message_id)
                    
        for message_id in expired_ids:
            del self.message_map[message_id]
            logger.debug(f"Cleared expired message: {message_id}")


class AgentCommunicationProtocol:
    """Main protocol handler for agent communication"""
    
    def __init__(self, agent_id: str):
        self.agent_id = agent_id
        self.router = MessageRouter()
        self.priority_queue = PriorityMessageQueue()
        self.response_callbacks: Dict[str, Any] = {}
        self.running = False
        
    async def send_message(
        self,
        event_type: EventType,
        recipient_id: Optional[str],
        payload: Dict[str, Any],
        priority: MessagePriority = MessagePriority.NORMAL,
        requires_response: bool = False,
        correlation_id: Optional[str] = None,
        ttl_seconds: Optional[int] = None
    ) -> str:
        """Send a message to other agents"""
        
        message = MessageSchema(
            event_type=event_type,
            sender_id=self.agent_id,
            recipient_id=recipient_id,
            payload=payload,
            priority=priority,
            correlation_id=correlation_id or str(uuid.uuid4()),
            requires_response=requires_response,
            ttl_seconds=ttl_seconds
        )
        
        # Route message
        targets = self.router.route_message(message)
        
        # Add to history
        self.router.add_to_history(message)
        
        # Queue for processing
        await self.priority_queue.enqueue(message)
        
        logger.info(f"Sent {event_type.value} message {message.id} to {len(targets)} targets")
        
        # If response required, register callback
        if requires_response:
            self.response_callbacks[message.id] = asyncio.Future()
            
        return message.id
        
    async def wait_for_response(self, message_id: str, timeout: int = 30) -> Optional[MessageSchema]:
        """Wait for response to a specific message"""
        if message_id not in self.response_callbacks:
            return None
            
        future = self.response_callbacks[message_id]
        
        try:
            response = await asyncio.wait_for(future, timeout=timeout)
            del self.response_callbacks[message_id]
            return response
        except asyncio.TimeoutError:
            logger.warning(f"Timeout waiting for response to message {message_id}")
            del self.response_callbacks[message_id]
            return None
            
    async def handle_incoming_message(self, message: MessageSchema):
        """Handle incoming message from another agent"""
        logger.debug(f"Handling incoming message {message.id} from {message.sender_id}")
        
        # Check if this is a response to a previous message
        if message.correlation_id in self.response_callbacks:
            future = self.response_callbacks[message.correlation_id]
            if not future.done():
                future.set_result(message)
                
        # Add to priority queue for processing
        await self.priority_queue.enqueue(message)
        
    async def process_messages(self, handler: Any):
        """Process messages from priority queue"""
        self.running = True
        
        while self.running:
            # Clear expired messages periodically
            self.priority_queue.clear_expired()
            
            # Get next message
            message = await self.priority_queue.dequeue()
            
            if message:
                try:
                    logger.debug(f"Processing message {message.id}")
                    
                    # Call handler
                    if asyncio.iscoroutinefunction(handler):
                        result = await handler(message)
                    else:
                        result = handler(message)
                        
                    # Send response if required
                    if message.requires_response and result:
                        await self.send_message(
                            event_type=EventType.RESPONSE_READY,
                            recipient_id=message.sender_id,
                            payload=result,
                            correlation_id=message.id,
                            priority=message.priority
                        )
                        
                except Exception as e:
                    logger.error(f"Error processing message {message.id}: {e}", exc_info=True)
                    
                    # Send error response if required
                    if message.requires_response:
                        await self.send_message(
                            event_type=EventType.ERROR_OCCURRED,
                            recipient_id=message.sender_id,
                            payload={"error_message": str(e)},
                            correlation_id=message.id,
                            priority=MessagePriority.HIGH
                        )
            else:
                # No messages, wait briefly
                await asyncio.sleep(0.1)
                
    def stop(self):
        """Stop processing messages"""
        self.running = False
        logger.info(f"Agent {self.agent_id} communication protocol stopped")


# Example usage
if __name__ == "__main__":
    async def example_message_handler(message: MessageSchema):
        """Example handler for incoming messages"""
        print(f"Received {message.event_type} from {message.sender_id}")
        print(f"Payload: {message.payload}")
        
        if message.requires_response:
            return {"status": "processed", "result": "success"}
            
    async def main():
        # Create protocol for agent
        protocol = AgentCommunicationProtocol("Agent1")
        
        # Subscribe to events
        protocol.router.subscribe_agent("Agent1", [
            EventType.TASK_ASSIGNED,
            EventType.COLLABORATION_REQUEST
        ])
        
        # Add routing rule
        protocol.router.add_routing_rule({
            "condition": lambda msg: msg.priority == MessagePriority.CRITICAL,
            "targets": ["SupervisorAgent"],
            "priority": 10
        })
        
        # Send a message
        message_id = await protocol.send_message(
            event_type=EventType.TASK_ASSIGNED,
            recipient_id="Agent2",
            payload={
                "task_id": "task_001",
                "task_type": "code_analysis",
                "description": "Analyze Python code for quality"
            },
            priority=MessagePriority.HIGH,
            requires_response=True
        )
        
        print(f"Sent message: {message_id}")
        
        # Start processing in background
        process_task = asyncio.create_task(
            protocol.process_messages(example_message_handler)
        )
        
        # Wait for response
        response = await protocol.wait_for_response(message_id, timeout=5)
        if response:
            print(f"Received response: {response.payload}")
        else:
            print("No response received")
            
        # Stop processing
        protocol.stop()
        await process_task
        
    # Run example
    asyncio.run(main())