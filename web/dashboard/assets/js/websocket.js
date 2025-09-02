// WebSocket Manager - Real-time updates for documentation changes

class WebSocketManager {
    constructor() {
        this.ws = null;
        this.reconnectAttempts = 0;
        this.maxReconnectAttempts = DashboardConfig.websocket.maxReconnectAttempts;
        this.reconnectInterval = DashboardConfig.websocket.reconnectInterval;
        this.isConnecting = false;
        this.isDestroyed = false;
        this.connectionId = null;
        
        // Event listeners
        this.eventListeners = {};
        
        // Message queue for offline messages
        this.messageQueue = [];
        this.queueMaxSize = 100;
        
        // Heartbeat management
        this.heartbeatInterval = null;
        this.lastPongTime = 0;
        this.heartbeatTimeout = 30000; // 30 seconds
        
        // Message handlers
        this.messageHandlers = {
            'graph-update': this.handleGraphUpdate.bind(this),
            'node-update': this.handleNodeUpdate.bind(this),
            'metrics-update': this.handleMetricsUpdate.bind(this),
            'file-change': this.handleFileChange.bind(this),
            'build-status': this.handleBuildStatus.bind(this),
            'error': this.handleError.bind(this),
            'pong': this.handlePong.bind(this),
            'connection-info': this.handleConnectionInfo.bind(this)
        };
        
        // Connection state
        this.connectionState = 'disconnected'; // 'connecting', 'connected', 'disconnected', 'error'
        
        console.log('WebSocketManager initialized');
    }
    
    // Connection management
    connect(url = null) {
        if (this.isDestroyed) {
            console.warn('WebSocketManager is destroyed, cannot connect');
            return;
        }
        
        if (this.isConnecting || this.isConnected()) {
            return;
        }
        
        this.isConnecting = true;
        const wsUrl = url || DashboardConfig.websocket.url;
        
        try {
            console.log(`Connecting to WebSocket: ${wsUrl}`);
            this.setConnectionState('connecting');
            
            this.ws = new WebSocket(wsUrl);
            
            this.ws.onopen = this.handleOpen.bind(this);
            this.ws.onmessage = this.handleMessage.bind(this);
            this.ws.onclose = this.handleClose.bind(this);
            this.ws.onerror = this.handleError.bind(this);
            
        } catch (error) {
            console.error('Failed to create WebSocket connection:', error);
            this.isConnecting = false;
            this.setConnectionState('error');
            this.scheduleReconnect();
        }
    }
    
    disconnect() {
        console.log('Disconnecting WebSocket');
        
        this.stopHeartbeat();
        this.reconnectAttempts = this.maxReconnectAttempts; // Prevent auto-reconnect
        
        if (this.ws) {
            this.ws.close(1000, 'Manual disconnect');
        }
        
        this.setConnectionState('disconnected');
    }
    
    isConnected() {
        return this.ws && this.ws.readyState === WebSocket.OPEN;
    }
    
    setConnectionState(state) {
        if (this.connectionState !== state) {
            const previousState = this.connectionState;
            this.connectionState = state;
            
            console.log(`WebSocket state changed: ${previousState} -> ${state}`);
            
            this.emit('connectionStateChanged', {
                state,
                previousState,
                reconnectAttempts: this.reconnectAttempts,
                isConnected: this.isConnected()
            });
            
            this.updateConnectionIndicator();
        }
    }
    
    updateConnectionIndicator() {
        const indicator = document.getElementById('wsStatus');
        if (!indicator) return;
        
        indicator.className = 'status-indicator';
        
        switch (this.connectionState) {
            case 'connected':
                indicator.classList.add('online');
                indicator.textContent = 'Connected';
                break;
            case 'connecting':
                indicator.classList.add('connecting');
                indicator.textContent = 'Connecting...';
                break;
            case 'error':
                indicator.classList.add('offline');
                indicator.textContent = 'Error';
                break;
            default:
                indicator.classList.add('offline');
                indicator.textContent = 'Disconnected';
        }
    }
    
    // Event handlers
    handleOpen(event) {
        console.log('WebSocket connected');
        this.isConnecting = false;
        this.reconnectAttempts = 0;
        this.setConnectionState('connected');
        
        // Start heartbeat
        this.startHeartbeat();
        
        // Send any queued messages
        this.sendQueuedMessages();
        
        this.emit('connected', {
            connectionId: this.connectionId,
            timestamp: Date.now()
        });
    }
    
    handleMessage(event) {
        try {
            const message = JSON.parse(event.data);
            
            if (DashboardConfig.debug.enabled) {
                console.log('WebSocket message received:', message);
            }
            
            this.processMessage(message);
        } catch (error) {
            console.error('Failed to parse WebSocket message:', error, event.data);
        }
    }
    
    handleClose(event) {
        console.log(`WebSocket closed: ${event.code} - ${event.reason}`);
        
        this.isConnecting = false;
        this.stopHeartbeat();
        
        if (event.code !== 1000 && event.code !== 1001) {
            // Unexpected close, try to reconnect
            this.setConnectionState('error');
            this.scheduleReconnect();
        } else {
            this.setConnectionState('disconnected');
        }
        
        this.emit('disconnected', {
            code: event.code,
            reason: event.reason,
            wasClean: event.wasClean,
            timestamp: Date.now()
        });
    }
    
    handleError(event) {
        console.error('WebSocket error:', event);
        
        this.isConnecting = false;
        this.setConnectionState('error');
        
        this.emit('error', {
            error: event,
            timestamp: Date.now()
        });
        
        // Try to reconnect after error
        this.scheduleReconnect();
    }
    
    // Message processing
    processMessage(message) {
        const { type, data, timestamp = Date.now() } = message;
        
        // Update last activity time
        this.lastPongTime = Date.now();
        
        // Find and execute message handler
        const handler = this.messageHandlers[type];
        if (handler) {
            try {
                handler(data, timestamp);
            } catch (error) {
                console.error(`Error handling message type '${type}':`, error);
            }
        } else {
            console.warn(`Unknown message type: ${type}`);
        }
        
        // Emit generic message event
        this.emit('message', { type, data, timestamp });
    }
    
    // Specific message handlers
    handleGraphUpdate(data, timestamp) {
        console.log('Graph update received:', data);
        
        this.emit('graphUpdate', {
            ...data,
            timestamp,
            updateType: 'full'
        });
    }
    
    handleNodeUpdate(data, timestamp) {
        console.log('Node update received:', data);
        
        this.emit('nodeUpdate', {
            ...data,
            timestamp,
            updateType: 'incremental'
        });
    }
    
    handleMetricsUpdate(data, timestamp) {
        console.log('Metrics update received:', data);
        
        this.emit('metricsUpdate', {
            ...data,
            timestamp
        });
    }
    
    handleFileChange(data, timestamp) {
        console.log('File change detected:', data);
        
        this.emit('fileChange', {
            ...data,
            timestamp
        });
        
        // Request graph update after file changes
        setTimeout(() => {
            this.requestGraphUpdate();
        }, 1000);
    }
    
    handleBuildStatus(data, timestamp) {
        console.log('Build status update:', data);
        
        this.emit('buildStatus', {
            ...data,
            timestamp
        });
    }
    
    handleConnectionInfo(data, timestamp) {
        this.connectionId = data.connectionId;
        console.log('Connection info received:', data);
        
        this.emit('connectionInfo', {
            ...data,
            timestamp
        });
    }
    
    handlePong(data, timestamp) {
        this.lastPongTime = Date.now();
        
        if (DashboardConfig.debug.enabled) {
            console.log('Pong received');
        }
    }
    
    // Heartbeat management
    startHeartbeat() {
        this.stopHeartbeat();
        
        this.heartbeatInterval = setInterval(() => {
            if (this.isConnected()) {
                this.send({
                    type: 'ping',
                    timestamp: Date.now()
                });
                
                // Check if we haven't received a pong in too long
                if (this.lastPongTime > 0 && 
                    Date.now() - this.lastPongTime > this.heartbeatTimeout) {
                    console.warn('WebSocket heartbeat timeout');
                    this.ws.close(1000, 'Heartbeat timeout');
                }
            }
        }, DashboardConfig.websocket.pingInterval);
        
        this.lastPongTime = Date.now();
    }
    
    stopHeartbeat() {
        if (this.heartbeatInterval) {
            clearInterval(this.heartbeatInterval);
            this.heartbeatInterval = null;
        }
    }
    
    // Message sending
    send(message) {
        if (this.isConnected()) {
            try {
                const messageStr = typeof message === 'string' ? message : JSON.stringify(message);
                this.ws.send(messageStr);
                
                if (DashboardConfig.debug.enabled) {
                    console.log('WebSocket message sent:', message);
                }
                
                return true;
            } catch (error) {
                console.error('Failed to send WebSocket message:', error);
                this.queueMessage(message);
                return false;
            }
        } else {
            this.queueMessage(message);
            return false;
        }
    }
    
    queueMessage(message) {
        if (this.messageQueue.length >= this.queueMaxSize) {
            this.messageQueue.shift(); // Remove oldest message
        }
        
        this.messageQueue.push({
            message,
            timestamp: Date.now()
        });
        
        console.log(`Message queued (${this.messageQueue.length}/${this.queueMaxSize})`);
    }
    
    sendQueuedMessages() {
        if (this.messageQueue.length === 0) return;
        
        console.log(`Sending ${this.messageQueue.length} queued messages`);
        
        const messages = [...this.messageQueue];
        this.messageQueue = [];
        
        messages.forEach(({ message, timestamp }) => {
            // Add original timestamp to message
            const messageWithTimestamp = {
                ...message,
                originalTimestamp: timestamp,
                queuedMessage: true
            };
            
            this.send(messageWithTimestamp);
        });
    }
    
    // API methods
    requestGraphUpdate(options = {}) {
        this.send({
            type: 'request-graph-update',
            data: options,
            timestamp: Date.now()
        });
    }
    
    requestMetricsUpdate() {
        this.send({
            type: 'request-metrics-update',
            timestamp: Date.now()
        });
    }
    
    subscribeToFileChanges(patterns = []) {
        this.send({
            type: 'subscribe-file-changes',
            data: { patterns },
            timestamp: Date.now()
        });
    }
    
    unsubscribeFromFileChanges() {
        this.send({
            type: 'unsubscribe-file-changes',
            timestamp: Date.now()
        });
    }
    
    requestNodeDetails(nodeId) {
        this.send({
            type: 'request-node-details',
            data: { nodeId },
            timestamp: Date.now()
        });
    }
    
    // Reconnection logic
    scheduleReconnect() {
        if (this.isDestroyed || this.reconnectAttempts >= this.maxReconnectAttempts) {
            console.log('Max reconnection attempts reached or manager destroyed');
            return;
        }
        
        this.reconnectAttempts++;
        const delay = Math.min(
            this.reconnectInterval * Math.pow(1.5, this.reconnectAttempts - 1),
            30000 // Max 30 seconds
        );
        
        console.log(`Scheduling reconnect attempt ${this.reconnectAttempts}/${this.maxReconnectAttempts} in ${delay}ms`);
        
        setTimeout(() => {
            if (!this.isDestroyed && !this.isConnected()) {
                this.connect();
            }
        }, delay);
    }
    
    // Statistics and monitoring
    getConnectionStats() {
        return {
            state: this.connectionState,
            isConnected: this.isConnected(),
            connectionId: this.connectionId,
            reconnectAttempts: this.reconnectAttempts,
            maxReconnectAttempts: this.maxReconnectAttempts,
            queueSize: this.messageQueue.length,
            queueMaxSize: this.queueMaxSize,
            lastPongTime: this.lastPongTime,
            heartbeatActive: this.heartbeatInterval !== null
        };
    }
    
    // Event system
    on(eventName, callback) {
        if (!this.eventListeners[eventName]) {
            this.eventListeners[eventName] = [];
        }
        this.eventListeners[eventName].push(callback);
        
        return () => {
            const index = this.eventListeners[eventName].indexOf(callback);
            if (index > -1) {
                this.eventListeners[eventName].splice(index, 1);
            }
        };
    }
    
    emit(eventName, data) {
        if (this.eventListeners[eventName]) {
            this.eventListeners[eventName].forEach(callback => {
                try {
                    callback(data);
                } catch (error) {
                    console.error(`Error in ${eventName} event handler:`, error);
                }
            });
        }
        
        // Also emit as custom DOM event
        const event = new CustomEvent(`websocket-${eventName}`, { 
            detail: data 
        });
        document.dispatchEvent(event);
    }
    
    // Cleanup
    destroy() {
        console.log('Destroying WebSocketManager');
        
        this.isDestroyed = true;
        this.disconnect();
        this.stopHeartbeat();
        
        this.messageQueue = [];
        this.eventListeners = {};
        
        if (this.ws) {
            this.ws.onopen = null;
            this.ws.onmessage = null;
            this.ws.onclose = null;
            this.ws.onerror = null;
            this.ws = null;
        }
    }
}

// WebSocket Message Types (for reference)
const MESSAGE_TYPES = {
    // Client -> Server
    PING: 'ping',
    REQUEST_GRAPH_UPDATE: 'request-graph-update',
    REQUEST_METRICS_UPDATE: 'request-metrics-update',
    REQUEST_NODE_DETAILS: 'request-node-details',
    SUBSCRIBE_FILE_CHANGES: 'subscribe-file-changes',
    UNSUBSCRIBE_FILE_CHANGES: 'unsubscribe-file-changes',
    
    // Server -> Client
    PONG: 'pong',
    GRAPH_UPDATE: 'graph-update',
    NODE_UPDATE: 'node-update',
    METRICS_UPDATE: 'metrics-update',
    FILE_CHANGE: 'file-change',
    BUILD_STATUS: 'build-status',
    CONNECTION_INFO: 'connection-info',
    ERROR: 'error'
};

// Export for module systems
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { WebSocketManager, MESSAGE_TYPES };
}

// Global availability
window.WebSocketManager = WebSocketManager;
window.MESSAGE_TYPES = MESSAGE_TYPES;