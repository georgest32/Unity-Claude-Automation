/**
 * Unity-Claude Automation - Temporal Evolution Visualization
 * Day 7 Hour 3-4: Show how relationships change over time with git history integration
 * Built on d3-network-time patterns and timeline visualization research
 */

// Global temporal state
let temporalData = {};
let timelineSimulation = null;
let currentTimeframe = null;
let animationState = {
    isPlaying: false,
    currentFrame: 0,
    totalFrames: 0,
    playbackSpeed: 1.0
};

// Timeline configuration
const TIMELINE_CONFIG = {
    height: 60,
    margin: { top: 10, right: 30, bottom: 10, left: 30 },
    tickFormat: d3.timeFormat('%Y-%m-%d'),
    animationDuration: 1000,
    defaultTimeStep: 'day'
};

// Git history analysis cache
let gitHistoryCache = new Map();

/**
 * Initialize temporal visualization system
 */
function initializeTemporalVisualization() {
    console.log('🕒 Initializing Temporal Evolution Visualization...');
    
    // Create timeline container
    createTimelineContainer();
    
    // Set up git history integration
    setupGitHistoryIntegration();
    
    // Initialize timeline controls
    initializeTimelineControls();
    
    // Load temporal data
    loadTemporalData();
    
    console.log('✅ Temporal visualization initialized');
}

/**
 * Create timeline container and SVG
 */
function createTimelineContainer() {
    const container = d3.select('.timeline-container');
    
    if (container.empty()) {
        // Create timeline container if it doesn't exist
        const timelineDiv = d3.select('.visualization-container')
            .append('div')
            .attr('class', 'timeline-container')
            .style('position', 'absolute')
            .style('bottom', '20px')
            .style('left', '20px')
            .style('right', '20px')
            .style('height', TIMELINE_CONFIG.height + 'px')
            .style('background', 'rgba(255, 255, 255, 0.9)')
            .style('border-radius', '8px')
            .style('border', '1px solid #ddd')
            .style('padding', '10px');
        
        // Add timeline SVG
        timelineDiv.append('svg')
            .attr('class', 'timeline-svg')
            .attr('width', '100%')
            .attr('height', TIMELINE_CONFIG.height);
        
        // Add controls container
        timelineDiv.append('div')
            .attr('class', 'timeline-controls')
            .style('position', 'absolute')
            .style('top', '5px')
            .style('right', '10px');
    }
    
    console.log('📊 Timeline container created');
}

/**
 * Set up git history integration
 */
function setupGitHistoryIntegration() {
    console.log('🔍 Setting up git history integration...');
    
    // Create git history analysis endpoint
    window.GitHistoryAnalyzer = {
        analyzeRepository: analyzeRepositoryHistory,
        getCommitData: getCommitData,
        getFileChanges: getFileChanges,
        mapChangesToRelationships: mapChangesToRelationships
    };
    
    console.log('✅ Git history integration ready');
}

/**
 * Analyze repository history for temporal visualization
 */
async function analyzeRepositoryHistory(options = {}) {
    console.log('📈 Analyzing repository history...');
    
    const config = {
        maxCommits: options.maxCommits || 100,
        timeRange: options.timeRange || '1 year',
        fileTypes: options.fileTypes || ['.psm1', '.ps1', '.json'],
        ...options
    };
    
    try {
        // Call PowerShell backend for git analysis
        const response = await fetch('/api/git-history', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(config)
        });
        
        if (!response.ok) {
            throw new Error(`Git history analysis failed: ${response.statusText}`);
        }
        
        const historyData = await response.json();
        
        // Process and cache history data
        processGitHistoryData(historyData);
        
        console.log(`📊 Processed ${historyData.commits?.length || 0} commits`);
        return historyData;
        
    } catch (error) {
        console.error('❌ Git history analysis failed:', error);
        
        // Fallback to mock data for development
        return generateMockTemporalData();
    }
}

/**
 * Process git history data for temporal visualization
 */
function processGitHistoryData(historyData) {
    console.log('🔄 Processing git history for temporal visualization...');
    
    const temporalFrames = [];
    const commitMap = new Map();
    
    // Sort commits by date
    const sortedCommits = historyData.commits.sort((a, b) => 
        new Date(a.timestamp) - new Date(b.timestamp)
    );
    
    // Build cumulative relationship states
    let cumulativeNodes = new Map();
    let cumulativeLinks = new Map();
    
    sortedCommits.forEach((commit, index) => {
        // Process file changes in this commit
        commit.changes.forEach(change => {
            updateRelationshipsFromChange(change, cumulativeNodes, cumulativeLinks);
        });
        
        // Create frame snapshot
        const frame = {
            timestamp: new Date(commit.timestamp),
            commitHash: commit.hash,
            message: commit.message,
            author: commit.author,
            nodes: Array.from(cumulativeNodes.values()),
            links: Array.from(cumulativeLinks.values()),
            changes: commit.changes,
            index: index
        };
        
        temporalFrames.push(frame);
        commitMap.set(commit.hash, frame);
    });
    
    temporalData = {
        frames: temporalFrames,
        commitMap: commitMap,
        timeRange: {
            start: new Date(sortedCommits[0].timestamp),
            end: new Date(sortedCommits[sortedCommits.length - 1].timestamp)
        },
        totalCommits: sortedCommits.length
    };
    
    animationState.totalFrames = temporalFrames.length;
    
    console.log(`✅ Processed ${temporalFrames.length} temporal frames`);
}

/**
 * Update relationships based on file changes
 */
function updateRelationshipsFromChange(change, cumulativeNodes, cumulativeLinks) {
    const filePath = change.path;
    const changeType = change.type; // added, modified, deleted
    
    if (changeType === 'deleted') {
        // Remove nodes and links related to deleted file
        const nodeId = extractNodeIdFromPath(filePath);
        cumulativeNodes.delete(nodeId);
        
        // Remove associated links
        Array.from(cumulativeLinks.keys()).forEach(linkId => {
            const link = cumulativeLinks.get(linkId);
            if (link.source === nodeId || link.target === nodeId) {
                cumulativeLinks.delete(linkId);
            }
        });
    } else {
        // Add or update node for added/modified files
        const nodeId = extractNodeIdFromPath(filePath);
        const node = createNodeFromPath(filePath, change);
        cumulativeNodes.set(nodeId, node);
        
        // Analyze file for new relationships
        if (change.content) {
            const relationships = extractRelationshipsFromContent(change.content, nodeId);
            relationships.forEach(rel => {
                const linkId = `${rel.source}-${rel.target}`;
                cumulativeLinks.set(linkId, rel);
            });
        }
    }
}

/**
 * Initialize timeline controls interface
 */
function initializeTimelineControls() {
    console.log('🎮 Initializing timeline controls...');
    
    const controlsContainer = d3.select('.timeline-controls');
    
    // Play/Pause button
    controlsContainer.append('button')
        .attr('class', 'timeline-btn play-pause-btn')
        .style('margin-right', '5px')
        .html('▶️')
        .on('click', togglePlayback);
    
    // Step backward button
    controlsContainer.append('button')
        .attr('class', 'timeline-btn step-btn')
        .style('margin-right', '5px')
        .html('⏮️')
        .on('click', () => stepAnimation(-1));
    
    // Step forward button
    controlsContainer.append('button')
        .attr('class', 'timeline-btn step-btn')
        .style('margin-right', '10px')
        .html('⏭️')
        .on('click', () => stepAnimation(1));
    
    // Speed control
    const speedControl = controlsContainer.append('label')
        .style('margin-right', '10px')
        .text('Speed: ');
    
    speedControl.append('select')
        .attr('class', 'speed-select')
        .on('change', function() {
            animationState.playbackSpeed = parseFloat(this.value);
        })
        .selectAll('option')
        .data([0.25, 0.5, 1.0, 2.0, 4.0])
        .enter()
        .append('option')
        .attr('value', d => d)
        .text(d => `${d}x`)
        .property('selected', d => d === 1.0);
    
    // Time range selector
    const rangeControl = controlsContainer.append('label')
        .text('Range: ');
    
    rangeControl.append('select')
        .attr('class', 'range-select')
        .on('change', function() {
            filterTemporalData(this.value);
        })
        .selectAll('option')
        .data(['1 day', '1 week', '1 month', '3 months', '1 year', 'all'])
        .enter()
        .append('option')
        .attr('value', d => d)
        .text(d => d)
        .property('selected', d => d === '1 month');
    
    console.log('🎮 Timeline controls initialized');
}

/**
 * Load temporal data and initialize timeline
 */
async function loadTemporalData() {
    console.log('📡 Loading temporal evolution data...');
    
    try {
        // Analyze repository history
        const historyData = await analyzeRepositoryHistory();
        
        if (historyData && temporalData.frames) {
            // Create timeline visualization
            createTimelineVisualization();
            
            // Set initial frame
            setTemporalFrame(0);
            
            console.log('✅ Temporal data loaded successfully');
        }
        
    } catch (error) {
        console.error('❌ Failed to load temporal data:', error);
        
        // Use mock data for testing
        createMockTemporalData();
        createTimelineVisualization();
        setTemporalFrame(0);
    }
}

/**
 * Create timeline visualization with interactive scrubber
 */
function createTimelineVisualization() {
    console.log('📊 Creating timeline visualization...');
    
    const svg = d3.select('.timeline-svg');
    const containerWidth = svg.node().parentElement.clientWidth - 40;
    const height = TIMELINE_CONFIG.height;
    
    // Clear existing timeline
    svg.selectAll('*').remove();
    
    // Create scales
    const xScale = d3.scaleTime()
        .domain([temporalData.timeRange.start, temporalData.timeRange.end])
        .range([TIMELINE_CONFIG.margin.left, containerWidth - TIMELINE_CONFIG.margin.right]);
    
    const yScale = d3.scaleLinear()
        .domain([0, d3.max(temporalData.frames, d => d.nodes.length)])
        .range([height - TIMELINE_CONFIG.margin.bottom, TIMELINE_CONFIG.margin.top]);
    
    // Add axes
    svg.append('g')
        .attr('class', 'timeline-axis')
        .attr('transform', `translate(0, ${height - TIMELINE_CONFIG.margin.bottom})`)
        .call(d3.axisBottom(xScale).tickFormat(TIMELINE_CONFIG.tickFormat));
    
    // Add area chart for relationship evolution
    const area = d3.area()
        .x(d => xScale(d.timestamp))
        .y0(height - TIMELINE_CONFIG.margin.bottom)
        .y1(d => yScale(d.nodes.length))
        .curve(d3.curveMonotoneX);
    
    svg.append('path')
        .datum(temporalData.frames)
        .attr('class', 'evolution-area')
        .attr('d', area)
        .style('fill', 'rgba(76, 175, 80, 0.3)')
        .style('stroke', '#4CAF50')
        .style('stroke-width', 2);
    
    // Add commit points
    svg.selectAll('.commit-point')
        .data(temporalData.frames)
        .enter()
        .append('circle')
        .attr('class', 'commit-point')
        .attr('cx', d => xScale(d.timestamp))
        .attr('cy', d => yScale(d.nodes.length))
        .attr('r', 3)
        .style('fill', '#2196F3')
        .style('stroke', '#ffffff')
        .style('stroke-width', 1)
        .style('cursor', 'pointer')
        .on('click', (event, d) => {
            setTemporalFrame(d.index);
        })
        .on('mouseover', (event, d) => {
            showTimelineTooltip(event, d);
        })
        .on('mouseout', hideTimelineTooltip);
    
    // Add playhead indicator
    const playhead = svg.append('line')
        .attr('class', 'timeline-playhead')
        .attr('y1', TIMELINE_CONFIG.margin.top)
        .attr('y2', height - TIMELINE_CONFIG.margin.bottom)
        .style('stroke', '#E91E63')
        .style('stroke-width', 3)
        .style('stroke-dasharray', '3,3');
    
    // Add interactive scrubber
    setupTimelineScrubber(svg, xScale, height);
    
    console.log('📊 Timeline visualization created');
}

/**
 * Set up interactive timeline scrubber
 */
function setupTimelineScrubber(svg, xScale, height) {
    const scrubber = svg.append('g')
        .attr('class', 'timeline-scrubber');
    
    // Add background track
    scrubber.append('rect')
        .attr('class', 'scrubber-track')
        .attr('x', TIMELINE_CONFIG.margin.left)
        .attr('y', height - TIMELINE_CONFIG.margin.bottom + 5)
        .attr('width', xScale.range()[1] - xScale.range()[0])
        .attr('height', 4)
        .style('fill', '#ddd')
        .style('cursor', 'pointer')
        .on('click', function(event) {
            const x = d3.pointer(event)[0];
            const time = xScale.invert(x);
            jumpToTimestamp(time);
        });
    
    // Add draggable handle
    const handle = scrubber.append('circle')
        .attr('class', 'scrubber-handle')
        .attr('r', 8)
        .attr('cy', height - TIMELINE_CONFIG.margin.bottom + 7)
        .style('fill', '#E91E63')
        .style('stroke', '#ffffff')
        .style('stroke-width', 2)
        .style('cursor', 'grab')
        .call(d3.drag()
            .on('start', function() {
                d3.select(this).style('cursor', 'grabbing');
            })
            .on('drag', function(event) {
                const x = Math.max(TIMELINE_CONFIG.margin.left, 
                    Math.min(xScale.range()[1], event.x));
                d3.select(this).attr('cx', x);
                
                const time = xScale.invert(x);
                jumpToTimestamp(time);
            })
            .on('end', function() {
                d3.select(this).style('cursor', 'grab');
            })
        );
    
    console.log('🎮 Timeline scrubber setup complete');
}

/**
 * Load temporal data from git history and relationship analysis
 */
async function loadTemporalData() {
    console.log('📡 Loading temporal evolution data...');
    
    try {
        // Load git history data
        const historyData = await fetch('/api/temporal-data').then(r => r.json());
        
        if (historyData.success) {
            temporalData = historyData.data;
            animationState.totalFrames = temporalData.frames.length;
            
            console.log(`📊 Loaded ${temporalData.frames.length} temporal frames`);
        } else {
            throw new Error('No temporal data available');
        }
        
    } catch (error) {
        console.warn('⚠️ Using mock temporal data for development:', error);
        createMockTemporalData();
    }
}

/**
 * Create mock temporal data for development and testing
 */
function createMockTemporalData() {
    console.log('🧪 Creating mock temporal data...');
    
    const now = new Date();
    const frames = [];
    
    // Generate 30 days of mock evolution
    for (let i = 0; i < 30; i++) {
        const timestamp = new Date(now.getTime() - (29 - i) * 24 * 60 * 60 * 1000);
        
        // Simulate growing module ecosystem
        const nodeCount = Math.max(5, Math.floor(Math.random() * (i + 5)));
        const linkCount = Math.max(3, Math.floor(nodeCount * 1.2));
        
        const frame = {
            timestamp: timestamp,
            commitHash: `mock-${i}`,
            message: `Day ${i + 1}: Mock development progress`,
            author: 'Mock Developer',
            nodes: generateMockNodes(nodeCount, i),
            links: generateMockLinks(linkCount, i),
            changes: generateMockChanges(i),
            index: i
        };
        
        frames.push(frame);
    }
    
    temporalData = {
        frames: frames,
        timeRange: {
            start: frames[0].timestamp,
            end: frames[frames.length - 1].timestamp
        },
        totalCommits: frames.length
    };
    
    animationState.totalFrames = frames.length;
    
    console.log('🧪 Mock temporal data created');
}

/**
 * Set temporal frame and update visualization
 */
function setTemporalFrame(frameIndex) {
    if (!temporalData.frames || frameIndex < 0 || frameIndex >= temporalData.frames.length) {
        return;
    }
    
    const frame = temporalData.frames[frameIndex];
    animationState.currentFrame = frameIndex;
    currentTimeframe = frame;
    
    console.log(`🕒 Setting temporal frame ${frameIndex}: ${frame.timestamp.toISOString()}`);
    
    // Update main graph with frame data
    updateMainGraphWithTemporal(frame);
    
    // Update timeline indicators
    updateTimelineIndicators(frameIndex);
    
    // Update frame info display
    updateFrameInfo(frame);
    
    // Emit temporal change event
    document.dispatchEvent(new CustomEvent('temporalFrameChanged', {
        detail: { frame, frameIndex }
    }));
}

/**
 * Update main graph visualization with temporal frame data
 */
function updateMainGraphWithTemporal(frame) {
    console.log(`🎨 Updating graph with temporal frame data...`);
    
    // Add temporal styling to nodes and links
    const temporalGraphData = {
        nodes: frame.nodes.map(node => ({
            ...node,
            isTemporal: true,
            frameIndex: frame.index,
            commitInfo: {
                hash: frame.commitHash,
                message: frame.message,
                author: frame.author,
                timestamp: frame.timestamp
            }
        })),
        links: frame.links.map(link => ({
            ...link,
            isTemporal: true,
            frameIndex: frame.index
        }))
    };
    
    // Update graph using existing renderer with temporal data
    if (window.GraphRenderer && window.GraphRenderer.updateData) {
        window.GraphRenderer.updateData(temporalGraphData);
    }
    
    // Add temporal visual indicators
    addTemporalVisualIndicators(frame);
}

/**
 * Add visual indicators for temporal changes
 */
function addTemporalVisualIndicators(frame) {
    if (!frame.changes || frame.changes.length === 0) return;
    
    // Highlight nodes that changed in this commit
    svg.selectAll('.node')
        .classed('recently-changed', false)
        .filter(d => {
            return frame.changes.some(change => {
                const nodeId = extractNodeIdFromPath(change.path);
                return nodeId === d.id;
            });
        })
        .classed('recently-changed', true);
    
    // Add change indicators
    svg.selectAll('.change-indicator').remove();
    
    const changedNodes = svg.selectAll('.node.recently-changed');
    changedNodes.append('circle')
        .attr('class', 'change-indicator')
        .attr('r', 4)
        .attr('cx', 12)
        .attr('cy', -12)
        .style('fill', '#FF4444')
        .style('stroke', '#ffffff')
        .style('stroke-width', 1)
        .transition()
        .duration(2000)
        .style('opacity', 0)
        .remove();
}

/**
 * Toggle animation playback
 */
function togglePlayback() {
    if (animationState.isPlaying) {
        pauseAnimation();
    } else {
        startAnimation();
    }
}

/**
 * Start temporal animation
 */
function startAnimation() {
    console.log('▶️ Starting temporal animation...');
    
    animationState.isPlaying = true;
    updatePlayPauseButton();
    
    function animate() {
        if (!animationState.isPlaying) return;
        
        const nextFrame = animationState.currentFrame + 1;
        if (nextFrame < animationState.totalFrames) {
            setTemporalFrame(nextFrame);
            
            // Schedule next frame based on playback speed
            setTimeout(animate, TIMELINE_CONFIG.animationDuration / animationState.playbackSpeed);
        } else {
            // Animation complete
            pauseAnimation();
        }
    }
    
    animate();
}

/**
 * Pause temporal animation
 */
function pauseAnimation() {
    console.log('⏸️ Pausing temporal animation...');
    
    animationState.isPlaying = false;
    updatePlayPauseButton();
}

/**
 * Step animation forward or backward
 */
function stepAnimation(direction) {
    const newFrame = animationState.currentFrame + direction;
    if (newFrame >= 0 && newFrame < animationState.totalFrames) {
        setTemporalFrame(newFrame);
    }
}

/**
 * Jump to specific timestamp
 */
function jumpToTimestamp(timestamp) {
    if (!temporalData.frames) return;
    
    // Find closest frame to timestamp
    let closestFrame = 0;
    let minDiff = Math.abs(temporalData.frames[0].timestamp.getTime() - timestamp.getTime());
    
    temporalData.frames.forEach((frame, index) => {
        const diff = Math.abs(frame.timestamp.getTime() - timestamp.getTime());
        if (diff < minDiff) {
            minDiff = diff;
            closestFrame = index;
        }
    });
    
    setTemporalFrame(closestFrame);
}

/**
 * Filter temporal data by time range
 */
function filterTemporalData(range) {
    console.log(`🔍 Filtering temporal data by range: ${range}`);
    
    const now = new Date();
    let startDate;
    
    switch (range) {
        case '1 day':
            startDate = new Date(now.getTime() - 24 * 60 * 60 * 1000);
            break;
        case '1 week':
            startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
            break;
        case '1 month':
            startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
            break;
        case '3 months':
            startDate = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000);
            break;
        case '1 year':
            startDate = new Date(now.getTime() - 365 * 24 * 60 * 60 * 1000);
            break;
        default:
            startDate = temporalData.timeRange.start;
    }
    
    // Filter frames and update visualization
    const filteredFrames = temporalData.frames.filter(frame => 
        frame.timestamp >= startDate
    );
    
    if (filteredFrames.length > 0) {
        const tempData = { ...temporalData, frames: filteredFrames };
        // Re-create timeline with filtered data
        createTimelineVisualization();
        setTemporalFrame(0);
    }
}

/**
 * Helper functions for temporal visualization
 */
function generateMockNodes(count, dayIndex) {
    const nodes = [];
    const modules = ['Core', 'Analysis', 'UI', 'Testing', 'Integration'];
    
    for (let i = 0; i < count; i++) {
        nodes.push({
            id: `node-${dayIndex}-${i}`,
            type: i < 3 ? 'module' : 'function',
            group: modules[i % modules.length],
            module: modules[i % modules.length],
            label: `${modules[i % modules.length]}-Function-${i}`,
            createdDay: dayIndex
        });
    }
    
    return nodes;
}

function generateMockLinks(count, dayIndex) {
    const links = [];
    
    for (let i = 0; i < count; i++) {
        links.push({
            source: `node-${dayIndex}-${i}`,
            target: `node-${dayIndex}-${(i + 1) % count}`,
            type: 'dependency',
            strength: Math.floor(Math.random() * 10) + 1,
            createdDay: dayIndex
        });
    }
    
    return links;
}

function generateMockChanges(dayIndex) {
    return [
        {
            path: `Modules/Module${dayIndex % 5 + 1}.psm1`,
            type: dayIndex === 0 ? 'added' : 'modified'
        }
    ];
}

function extractNodeIdFromPath(filePath) {
    // Extract module name from file path
    const fileName = filePath.split('/').pop().replace(/\.[^/.]+$/, '');
    return fileName;
}

function createNodeFromPath(filePath, change) {
    const nodeId = extractNodeIdFromPath(filePath);
    return {
        id: nodeId,
        type: filePath.endsWith('.psm1') ? 'module' : 'file',
        group: filePath.split('/')[1] || 'default',
        label: nodeId,
        filePath: filePath,
        changeType: change.type
    };
}

function extractRelationshipsFromContent(content, nodeId) {
    // Simplified relationship extraction
    // In production, this would use AST analysis
    const relationships = [];
    const importMatches = content.match(/Import-Module\s+([^\s]+)/g);
    
    if (importMatches) {
        importMatches.forEach(match => {
            const moduleName = match.split(' ')[1];
            relationships.push({
                source: nodeId,
                target: moduleName,
                type: 'import',
                strength: 5
            });
        });
    }
    
    return relationships;
}

function updateTimelineIndicators(frameIndex) {
    if (!temporalData.frames) return;
    
    const frame = temporalData.frames[frameIndex];
    const svg = d3.select('.timeline-svg');
    const containerWidth = svg.node().parentElement.clientWidth - 40;
    
    const xScale = d3.scaleTime()
        .domain([temporalData.timeRange.start, temporalData.timeRange.end])
        .range([TIMELINE_CONFIG.margin.left, containerWidth - TIMELINE_CONFIG.margin.right]);
    
    // Update playhead position
    svg.select('.timeline-playhead')
        .attr('x1', xScale(frame.timestamp))
        .attr('x2', xScale(frame.timestamp));
    
    // Update scrubber handle position
    svg.select('.scrubber-handle')
        .attr('cx', xScale(frame.timestamp));
}

function updateFrameInfo(frame) {
    // Update frame information display
    const info = document.querySelector('.frame-info');
    if (info) {
        info.innerHTML = `
            <strong>Frame ${frame.index + 1}/${animationState.totalFrames}</strong><br>
            Date: ${frame.timestamp.toLocaleDateString()}<br>
            Commit: ${frame.commitHash}<br>
            Author: ${frame.author}<br>
            Nodes: ${frame.nodes.length}<br>
            Links: ${frame.links.length}<br>
            Message: ${frame.message}
        `;
    }
}

function updatePlayPauseButton() {
    const button = document.querySelector('.play-pause-btn');
    if (button) {
        button.innerHTML = animationState.isPlaying ? '⏸️' : '▶️';
    }
}

function showTimelineTooltip(event, d) {
    if (!tooltip) return;
    
    const content = `
        <strong>${d.timestamp.toLocaleDateString()}</strong><br>
        Commit: ${d.commitHash}<br>
        Author: ${d.author}<br>
        Nodes: ${d.nodes.length}<br>
        Links: ${d.links.length}<br>
        <em>${d.message}</em>
    `;
    
    tooltip
        .html(content)
        .style('visibility', 'visible')
        .style('left', (event.pageX + 10) + 'px')
        .style('top', (event.pageY - 10) + 'px');
}

function hideTimelineTooltip() {
    if (tooltip) {
        tooltip.style('visibility', 'hidden');
    }
}

/**
 * Export temporal visualization functionality
 */
window.TemporalVisualization = {
    initialize: initializeTemporalVisualization,
    setFrame: setTemporalFrame,
    play: startAnimation,
    pause: pauseAnimation,
    step: stepAnimation,
    jumpTo: jumpToTimestamp,
    getCurrentFrame: () => currentTimeframe,
    getAnimationState: () => animationState,
    temporalData: () => temporalData
};

// Initialize when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeTemporalVisualization);
} else {
    // Delay to ensure graph renderer is initialized first
    setTimeout(initializeTemporalVisualization, 100);
}