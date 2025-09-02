"""
message_queue_handler.py
Python message handler with Windows named pipes for multi-agent communication
"""

import json
import asyncio
import logging
import time
from typing import Dict, Any, Optional, Callable
from dataclasses import dataclass, asdict
from datetime import datetime
from enum import Enum
import queue
import threading

# Windows-specific imports
try:
    import win32pipe
    import win32file
    import pywintypes
    import win32api
    WINDOWS_AVAILABLE = True
except ImportError:
    WINDOWS_AVAILABLE = False
    print("Warning: pywin32 not available. Named pipe functionality disabled.")

# Configure logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class MessageType(Enum):
    """Message types for agent communication"""
    TASK = "task"
    RESPONSE = "response"
    ERROR = "error"
    STATE = "state"
    HEARTBEAT = "heartbeat"
    CONTROL = "control"


@dataclass
class AgentMessage:
    """Standard message format for agent communication"""
    id: str
    type: MessageType
    sender: str
    recipient: str
    content: Dict[str, Any]
    timestamp: str
    priority: int = 5
    retry_count: int = 0
    
    def to_json(self) -> str:
        """Convert message to JSON string"""
        data = asdict(self)
        data['type'] = self.type.value
        return json.dumps(data)
    
    @classmethod
    def from_json(cls, json_str: str) -> 'AgentMessage':
        """Create message from JSON string"""
        data = json.loads(json_str)
        data['type'] = MessageType(data['type'])
        return cls(**data)


class NamedPipeServer:
    """Windows named pipe server for IPC"""
    
    def __init__(self, pipe_name: str, message_handler: Optional[Callable] = None):
        self.pipe_name = f"\\\\.\\pipe\\{pipe_name}"
        self.message_handler = message_handler or self.default_handler
        self.running = False
        self.pipe_handle = None
        
    def default_handler(self, message: AgentMessage) -> Dict[str, Any]:
        """Default message handler"""
        logger.info(f"Received message: {message.id} from {message.sender}")
        return {
            "status": "received",
            "message_id": message.id,
            "timestamp": datetime.now().isoformat()
        }
    
    def create_pipe(self):
        """Create named pipe"""
        if not WINDOWS_AVAILABLE:
            raise RuntimeError("Windows named pipes not available")
            
        self.pipe_handle = win32pipe.CreateNamedPipe(
            self.pipe_name,
            win32pipe.PIPE_ACCESS_DUPLEX,
            win32pipe.PIPE_TYPE_MESSAGE | win32pipe.PIPE_READMODE_MESSAGE | win32pipe.PIPE_WAIT,
            win32pipe.PIPE_UNLIMITED_INSTANCES,
            65536,
            65536,
            0,
            None
        )
        logger.debug(f"Created named pipe: {self.pipe_name}")
        
    def run(self):
        """Run the pipe server"""
        self.running = True
        self.create_pipe()
        
        while self.running:
            try:
                logger.debug("Waiting for client connection...")
                win32pipe.ConnectNamedPipe(self.pipe_handle, None)
                logger.info("Client connected")
                
                # Read message
                result, data = win32file.ReadFile(self.pipe_handle, 65536)
                if result == 0:  # Success
                    message_str = data.decode('utf-8')
                    logger.debug(f"Received raw message: {message_str}")
                    
                    # Parse message
                    message = AgentMessage.from_json(message_str)
                    
                    # Process message
                    response = self.message_handler(message)
                    
                    # Send response
                    response_str = json.dumps(response)
                    win32file.WriteFile(self.pipe_handle, response_str.encode('utf-8'))
                    logger.debug(f"Sent response: {response_str}")
                    
                # Disconnect client
                win32pipe.DisconnectNamedPipe(self.pipe_handle)
                logger.debug("Client disconnected")
                
            except pywintypes.error as e:
                logger.error(f"Pipe error: {e}")
                if e.args[0] == 232:  # Pipe being closed
                    break
            except Exception as e:
                logger.error(f"Unexpected error: {e}", exc_info=True)
                
    def stop(self):
        """Stop the pipe server"""
        self.running = False
        if self.pipe_handle:
            win32file.CloseHandle(self.pipe_handle)
            logger.info("Pipe server stopped")


class NamedPipeClient:
    """Windows named pipe client for IPC"""
    
    def __init__(self, pipe_name: str, max_retries: int = 10):
        self.pipe_name = f"\\\\.\\pipe\\{pipe_name}"
        self.max_retries = max_retries
        self.pipe_handle = None
        
    def connect(self) -> bool:
        """Connect to named pipe with retry logic"""
        if not WINDOWS_AVAILABLE:
            raise RuntimeError("Windows named pipes not available")
            
        for attempt in range(self.max_retries):
            try:
                self.pipe_handle = win32file.CreateFile(
                    self.pipe_name,
                    win32file.GENERIC_READ | win32file.GENERIC_WRITE,
                    0,
                    None,
                    win32file.OPEN_EXISTING,
                    0,
                    None
                )
                
                # Set pipe mode
                win32pipe.SetNamedPipeHandleState(
                    self.pipe_handle,
                    win32pipe.PIPE_READMODE_MESSAGE | win32pipe.PIPE_WAIT,
                    None,
                    None
                )
                
                logger.info(f"Connected to pipe: {self.pipe_name}")
                return True
                
            except pywintypes.error as e:
                logger.debug(f"Connection attempt {attempt + 1} failed: {e}")
                time.sleep(1)
                
        logger.error(f"Failed to connect to pipe after {self.max_retries} attempts")
        return False
        
    def send_message(self, message: AgentMessage) -> Optional[Dict[str, Any]]:
        """Send message and receive response"""
        if not self.pipe_handle:
            if not self.connect():
                return None
                
        try:
            # Send message
            message_str = message.to_json()
            win32file.WriteFile(self.pipe_handle, message_str.encode('utf-8'))
            logger.debug(f"Sent message: {message.id}")
            
            # Read response
            result, data = win32file.ReadFile(self.pipe_handle, 65536)
            if result == 0:
                response_str = data.decode('utf-8')
                response = json.loads(response_str)
                logger.debug(f"Received response: {response}")
                return response
                
        except pywintypes.error as e:
            logger.error(f"Communication error: {e}")
            self.disconnect()
            
        return None
        
    def disconnect(self):
        """Disconnect from pipe"""
        if self.pipe_handle:
            win32file.CloseHandle(self.pipe_handle)
            self.pipe_handle = None
            logger.info("Disconnected from pipe")


class MessageQueueHandler:
    """Async message queue handler with priority and retry logic"""
    
    def __init__(self, max_queue_size: int = 1000):
        self.message_queue = asyncio.PriorityQueue(maxsize=max_queue_size)
        self.handlers: Dict[MessageType, Callable] = {}
        self.running = False
        self.statistics = {
            "total_received": 0,
            "total_processed": 0,
            "total_errors": 0,
            "started_at": datetime.now().isoformat()
        }
        
    def register_handler(self, message_type: MessageType, handler: Callable):
        """Register a handler for a specific message type"""
        self.handlers[message_type] = handler
        logger.info(f"Registered handler for {message_type.value}")
        
    async def add_message(self, message: AgentMessage):
        """Add message to queue"""
        # Priority queue expects (priority, item) where lower priority = higher priority
        await self.message_queue.put((-message.priority, message))
        self.statistics["total_received"] += 1
        logger.debug(f"Added message {message.id} to queue")
        
    async def process_messages(self):
        """Process messages from queue"""
        self.running = True
        
        while self.running:
            try:
                # Get message with timeout
                priority, message = await asyncio.wait_for(
                    self.message_queue.get(),
                    timeout=1.0
                )
                
                # Get handler for message type
                handler = self.handlers.get(message.type)
                if handler:
                    try:
                        logger.debug(f"Processing message {message.id}")
                        await handler(message) if asyncio.iscoroutinefunction(handler) else handler(message)
                        self.statistics["total_processed"] += 1
                        
                    except Exception as e:
                        logger.error(f"Error processing message {message.id}: {e}")
                        self.statistics["total_errors"] += 1
                        
                        # Retry logic
                        if message.retry_count < 3:
                            message.retry_count += 1
                            message.priority -= 1  # Lower priority for retry
                            await self.add_message(message)
                            logger.info(f"Requeued message {message.id} for retry {message.retry_count}")
                else:
                    logger.warning(f"No handler for message type: {message.type.value}")
                    
            except asyncio.TimeoutError:
                continue  # No messages, continue loop
            except Exception as e:
                logger.error(f"Unexpected error in message processor: {e}", exc_info=True)
                
    def stop(self):
        """Stop processing messages"""
        self.running = False
        logger.info("Message queue handler stopped")
        
    def get_statistics(self) -> Dict[str, Any]:
        """Get queue statistics"""
        return {
            **self.statistics,
            "queue_size": self.message_queue.qsize()
        }


class MessageBridge:
    """Bridge between PowerShell and Python message systems"""
    
    def __init__(self, pipe_name: str = "UnityClaudeMessageQueue"):
        self.pipe_name = pipe_name
        self.queue_handler = MessageQueueHandler()
        self.pipe_server = None
        self.pipe_client = None
        
    def setup_server(self):
        """Setup named pipe server"""
        def handle_pipe_message(message: AgentMessage) -> Dict[str, Any]:
            # Add to async queue
            asyncio.create_task(self.queue_handler.add_message(message))
            return {
                "status": "queued",
                "message_id": message.id,
                "queue_size": self.queue_handler.message_queue.qsize()
            }
            
        self.pipe_server = NamedPipeServer(self.pipe_name, handle_pipe_message)
        
    def setup_client(self):
        """Setup named pipe client"""
        self.pipe_client = NamedPipeClient(self.pipe_name)
        
    async def start(self):
        """Start the message bridge"""
        # Start pipe server in thread
        if self.pipe_server:
            server_thread = threading.Thread(target=self.pipe_server.run)
            server_thread.daemon = True
            server_thread.start()
            logger.info("Named pipe server started")
            
        # Start message processor
        await self.queue_handler.process_messages()
        
    def send_to_powershell(self, message: AgentMessage) -> Optional[Dict[str, Any]]:
        """Send message to PowerShell via named pipe"""
        if not self.pipe_client:
            self.setup_client()
            
        return self.pipe_client.send_message(message)


# Example usage and testing
if __name__ == "__main__":
    import uuid
    
    # Example message handler
    def example_handler(message: AgentMessage):
        print(f"Handling {message.type.value} message from {message.sender}: {message.content}")
        
    # Create and configure bridge
    bridge = MessageBridge()
    bridge.setup_server()
    
    # Register handlers
    bridge.queue_handler.register_handler(MessageType.TASK, example_handler)
    bridge.queue_handler.register_handler(MessageType.RESPONSE, example_handler)
    
    # Create example message
    test_message = AgentMessage(
        id=str(uuid.uuid4()),
        type=MessageType.TASK,
        sender="TestAgent",
        recipient="ProcessorAgent",
        content={"task": "analyze_code", "file": "example.py"},
        timestamp=datetime.now().isoformat(),
        priority=8
    )
    
    print(f"Message JSON: {test_message.to_json()}")
    print("Starting message bridge...")
    
    try:
        # Run async event loop
        asyncio.run(bridge.start())
    except KeyboardInterrupt:
        print("\nShutting down...")
        bridge.queue_handler.stop()
        if bridge.pipe_server:
            bridge.pipe_server.stop()