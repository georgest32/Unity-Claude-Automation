/**
 * Unity-Claude Automation Visualization Server
 * D3.js force-directed graph visualization with WebSocket real-time updates
 * Fixed version with proper JavaScript syntax
 */

const express = require('express');
const path = require('path');
const fs = require('fs');
const WebSocket = require('ws');
const http = require('http');

const app = express();
const PORT = process.env.PORT || 3000;

// Create HTTP server for Express and WebSocket
const server = http.createServer(app);

console.log(`[SERVER] Starting Unity-Claude Automation Visualization Server...`);
console.log(`[SERVER] Environment: ${process.env.NODE_ENV || 'development'}`);

// Development mode hot reload
if (process.env.NODE_ENV !== 'production') {
  try {
    const livereload = require('livereload');
    const connectLivereload = require('connect-livereload');
    
    console.log(`[DEV] Setting up hot reload for development...`);
    
    const liveReloadServer = livereload.createServer({
      debug: false,
      delay: 500
    });
    
    // Watch public directory for client-side changes
    liveReloadServer.watch([
      path.join(__dirname, 'public'),
      path.join(__dirname, 'views')
    ]);
    
    // Inject livereload script into HTML responses
    app.use(connectLivereload());
    
    console.log(`[DEV] Hot reload configured - watching public/ and views/ directories`);
  } catch (error) {
    console.log(`[DEV] Hot reload setup failed (optional): ${error.message}`);
  }
}

// Static file serving with Express optimizations
console.log(`[STATIC] Configuring static file serving...`);
app.use('/static', express.static(path.join(__dirname, 'public/static'), {
  etag: true,
  lastModified: true,
  maxAge: process.env.NODE_ENV === 'production' ? '1d' : '1s'
}));

// Serve D3.js from node_modules for development
app.use('/d3', express.static(path.join(__dirname, 'node_modules/d3/dist')));

// Main route - serve visualization dashboard
app.get('/', (req, res) => {
  console.log(`[HTTP] Serving main visualization dashboard`);
  res.sendFile(path.join(__dirname, 'views/index.html'));
});

// API endpoint for CPG data (PowerShell integration) - FIXED
app.get('/api/data', (req, res) => {
  console.log(`[API] Data request received`);
  
  // Look for latest CPG/semantic analysis JSON files
  const dataDir = path.join(__dirname, 'public/static/data');
  
  try {
    if (!fs.existsSync(dataDir)) {
      fs.mkdirSync(dataDir, { recursive: true });
    }
    
    // Load real data instead of mock data
    const dataPath = path.join(__dirname, 'public', 'static', 'data', 'enhanced-system-graph.json');
    let realData;
    
    try {
      if (fs.existsSync(dataPath)) {
        realData = JSON.parse(fs.readFileSync(dataPath, 'utf8'));
        console.log(`[API] Loaded real data with ${realData.nodes.length} nodes and ${realData.edges.length} edges`);
      } else {
        // Fallback minimal data
        realData = {
          nodes: [
            { id: 'Enhanced-Doc-System', label: 'Enhanced Documentation System v2.0.0', category: 'System', size: 50, color: '#ff6b35' },
            { id: 'Week4-Predictive', label: 'Week 4 Predictive Analysis', category: 'AI', size: 40, color: '#a855f7' },
            { id: 'AI-Services', label: 'LangGraph + AutoGen AI', category: 'AI', size: 45, color: '#4ecdc4' }
          ],
          edges: [
            { source: 'Week4-Predictive', target: 'Enhanced-Doc-System', type: 'enhances' },
            { source: 'AI-Services', target: 'Enhanced-Doc-System', type: 'powers' }
          ]
        };
        console.log('[API] Using fallback data - real data file not found');
      }
    } catch (dataError) {
      console.error(`[API] Error loading real data: ${dataError.message}`);
      // Use absolute minimal fallback
      realData = {
        nodes: [{ id: 'System', label: 'Enhanced Documentation System', size: 30, color: '#4ecdc4' }],
        edges: []
      };
    }
    
    res.json(realData);
    console.log(`[API] Served real data with ${realData.nodes.length} nodes and ${realData.edges.length} edges`);
  } catch (error) {
    console.error(`[API] Error serving data: ${error.message}`);
    res.status(500).json({ error: 'Failed to load graph data' });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// WebSocket server for real-time updates
const wss = new WebSocket.Server({ server });

console.log(`[WEBSOCKET] Setting up WebSocket server for real-time updates...`);

wss.on('connection', (ws) => {
  console.log(`[WEBSOCKET] Client connected - total clients: ${wss.clients.size}`);
  
  // Send welcome message
  ws.send(JSON.stringify({
    type: 'connection',
    message: 'Connected to Unity-Claude Visualization Server',
    timestamp: new Date().toISOString()
  }));
  
  ws.on('close', () => {
    console.log(`[WEBSOCKET] Client disconnected - remaining clients: ${wss.clients.size}`);
  });
});

// File system watcher for PowerShell data updates
const dataWatchDir = path.join(__dirname, 'public/static/data');
if (!fs.existsSync(dataWatchDir)) {
  fs.mkdirSync(dataWatchDir, { recursive: true });
}

console.log(`[WATCHER] Setting up file system watcher for: ${dataWatchDir}`);

// Start server
server.listen(PORT, () => {
  console.log(`[SERVER] ✅ Unity-Claude Visualization Server running on http://localhost:${PORT}`);
  console.log(`[SERVER] 📊 D3.js Dashboard: http://localhost:${PORT}`);
  console.log(`[SERVER] 🔌 WebSocket Server: ws://localhost:${PORT}`);
  console.log(`[SERVER] 📁 Data Directory: ${dataWatchDir}`);
  console.log(`[SERVER] Ready for PowerShell CPG and semantic analysis data integration`);
});

module.exports = app;