# Unity-Claude-RealTimeAnalysis.psm1
# Real-Time Analysis Pipeline Integration Module
# Part of Week 3: Real-Time Intelligence - Day 11, Hour 5-6

using namespace System.Collections.Generic
using namespace System.Collections.Concurrent
using namespace System.Threading
using namespace System.Management.Automation

# Module-level variables for pipeline state
$script:PipelineState = @{
    IsRunning = $false
    ProcessingQueue = [ConcurrentQueue[PSCustomObject]]::new()
    ResultsQueue = [ConcurrentQueue[PSCustomObject]]::new()
    ProcessingThread = $null
    VisualizationThread = $null
    ExistingModules = @{}
    Configuration = @{
        BatchSize = 5
        ProcessingInterval = 1000  # 1 second
        MaxRetries = 3
        EnableLiveVisualization = $true
        EnableAIEnhancement = $false
    }
    Statistics = @{
        FilesProcessed = 0
        AnalysisRequestsGenerated = 0
        VisualizationUpdatesTriggered = 0
        Errors = 0
        AverageProcessingTime = 0
        StartTime = $null
    }
    ConnectedServices = @{
        FileSystemWatcher = $false
        ChangeIntelligence = $false
        SemanticAnalysis = $false
        PredictiveAnalysis = $false
        Visualization = $false
    }
}

# Analysis pipeline stages
enum PipelineStage {
    FileDetection
    ChangeClassification
    SemanticAnalysis
    PredictiveAnalysis
    VisualizationUpdate
    NotificationDispatch
    Completed
    Error
}

# Processing result status
enum ProcessingStatus {
    Pending
    InProgress
    Completed
    Failed
    Skipped
}

function Initialize-RealTimeAnalysisPipeline {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [hashtable]$Configuration = @{},
        
        [Parameter(Mandatory = $false)]
        [switch]$AutoDiscoverModules,
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableAI
    )
    
    Write-Host "Initializing Real-Time Analysis Pipeline..." -ForegroundColor Cyan
    
    # Merge configuration
    foreach ($key in $Configuration.Keys) {
        $script:PipelineState.Configuration[$key] = $Configuration[$key]
    }
    
    if ($EnableAI) {
        $script:PipelineState.Configuration.EnableAIEnhancement = $true
    }
    
    # Auto-discover existing modules if requested
    if ($AutoDiscoverModules) {
        Discover-ExistingModules
    }
    
    # Initialize statistics
    $script:PipelineState.Statistics.StartTime = Get-Date
    
    Write-Host "Real-Time Analysis Pipeline initialized" -ForegroundColor Green
    return $true
}

function Discover-ExistingModules {
    [CmdletBinding()]
    param()
    
    Write-Verbose "Discovering existing analysis modules..."
    
    $moduleBasePath = Join-Path $PSScriptRoot ".."
    
    # Check for Real-Time Monitoring module
    $monitoringPath = Join-Path $moduleBasePath "Unity-Claude-RealTimeMonitoring\Unity-Claude-RealTimeMonitoring.psm1"
    if (Test-Path $monitoringPath) {
        try {
            Import-Module $monitoringPath -Force -Global
            $script:PipelineState.ExistingModules["RealTimeMonitoring"] = $monitoringPath
            $script:PipelineState.ConnectedServices.FileSystemWatcher = $true
            Write-Verbose "Connected: Real-Time Monitoring module"
        }
        catch {
            Write-Warning "Failed to load Real-Time Monitoring module: $_"
        }
    }
    
    # Check for Change Intelligence module
    $intelligencePath = Join-Path $moduleBasePath "Unity-Claude-ChangeIntelligence\Unity-Claude-ChangeIntelligence.psm1"
    if (Test-Path $intelligencePath) {
        try {
            Import-Module $intelligencePath -Force -Global
            $script:PipelineState.ExistingModules["ChangeIntelligence"] = $intelligencePath
            $script:PipelineState.ConnectedServices.ChangeIntelligence = $true
            Write-Verbose "Connected: Change Intelligence module"
        }
        catch {
            Write-Warning "Failed to load Change Intelligence module: $_"
        }
    }
    
    # Check for Semantic Analysis modules
    $semanticPaths = @(
        "Unity-Claude-CPG\CPG-Unified.psm1",
        "Unity-Claude-SemanticAnalysis\Unity-Claude-SemanticAnalysis.psm1"
    )
    
    foreach ($path in $semanticPaths) {
        $fullPath = Join-Path $moduleBasePath $path
        if (Test-Path $fullPath) {
            try {
                Import-Module $fullPath -Force -Global
                $script:PipelineState.ExistingModules["SemanticAnalysis"] = $fullPath
                $script:PipelineState.ConnectedServices.SemanticAnalysis = $true
                Write-Verbose "Connected: Semantic Analysis module ($path)"
                break
            }
            catch {
                Write-Verbose "Could not load semantic analysis module $path : $_"
            }
        }
    }
    
    # Check for Predictive Analysis modules
    $predictivePaths = @(
        "Unity-Claude-PredictiveAnalysis\Predictive-Maintenance.psm1",
        "Unity-Claude-PredictiveAnalysis\Predictive-Evolution.psm1"
    )
    
    foreach ($path in $predictivePaths) {
        $fullPath = Join-Path $moduleBasePath $path
        if (Test-Path $fullPath) {
            try {
                Import-Module $fullPath -Force -Global
                $script:PipelineState.ExistingModules["PredictiveAnalysis"] = $fullPath
                $script:PipelineState.ConnectedServices.PredictiveAnalysis = $true
                Write-Verbose "Connected: Predictive Analysis module ($path)"
                break
            }
            catch {
                Write-Verbose "Could not load predictive analysis module $path : $_"
            }
        }
    }
    
    Write-Host "Module Discovery Complete. Connected services: $($script:PipelineState.ConnectedServices.Values | Where-Object { $_ } | Measure-Object | Select-Object -ExpandProperty Count)" -ForegroundColor Green
}

function Start-RealTimeAnalysisPipeline {
    [CmdletBinding()]
    param()
    
    if ($script:PipelineState.IsRunning) {
        Write-Warning "Pipeline is already running"
        return
    }
    
    Write-Host "Starting Real-Time Analysis Pipeline..." -ForegroundColor Cyan
    
    try {
        # Start the processing thread
        Start-PipelineProcessingThread
        
        # Start file system monitoring if available
        if ($script:PipelineState.ConnectedServices.FileSystemWatcher) {
            Start-FileSystemMonitoringIntegration
        }
        
        # Start visualization thread if enabled
        if ($script:PipelineState.Configuration.EnableLiveVisualization) {
            Start-VisualizationThread
        }
        
        $script:PipelineState.IsRunning = $true
        Write-Host "Real-Time Analysis Pipeline started successfully" -ForegroundColor Green
        
        return @{
            Success = $true
            ConnectedServices = $script:PipelineState.ConnectedServices
        }
    }
    catch {
        Write-Error "Failed to start pipeline: $_"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Start-FileSystemMonitoringIntegration {
    [CmdletBinding()]
    param()
    
    if (-not $script:PipelineState.ConnectedServices.FileSystemWatcher) {
        Write-Warning "FileSystemWatcher module not available"
        return
    }
    
    try {
        # Initialize and start file system monitoring
        Initialize-RealTimeMonitoring -Configuration @{
            ProcessingInterval = $script:PipelineState.Configuration.ProcessingInterval
        } | Out-Null
        
        $monitoringResult = Start-FileSystemMonitoring -IncludeSubdirectories
        
        if ($monitoringResult.Success) {
            Write-Verbose "File system monitoring started with $($monitoringResult.WatcherCount) watchers"
            
            # Register event handler to process file system events
            Register-EngineEvent -SourceIdentifier "FileSystemChange" -Action {
                $event = $Event.SourceEventArgs
                Add-FileChangeToAnalysisQueue -FileEvent $event
            }
        }
    }
    catch {
        Write-Warning "Failed to start file system monitoring integration: $_"
    }
}

function Add-FileChangeToAnalysisQueue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$FileEvent
    )
    
    # Create analysis request
    $analysisRequest = @{
        Id = [Guid]::NewGuid().ToString()
        FileEvent = $FileEvent
        Stage = [PipelineStage]::FileDetection
        Status = [ProcessingStatus]::Pending
        Timestamp = Get-Date
        ProcessingTimes = @{}
        Results = @{}
        Retries = 0
    }
    
    # Add to processing queue
    $script:PipelineState.ProcessingQueue.Enqueue([PSCustomObject]$analysisRequest)
    Write-Verbose "Added file change to analysis queue: $($FileEvent.FullPath)"
}

function Start-PipelineProcessingThread {
    [CmdletBinding()]
    param()
    
    $processingScript = {
        param($PipelineState, $BatchSize)
        
        while ($PipelineState.IsRunning) {
            try {
                $processedCount = 0
                $batch = @()
                
                # Collect batch of requests
                while ($processedCount -lt $BatchSize) {
                    $request = $null
                    if ($PipelineState.ProcessingQueue.TryDequeue([ref]$request)) {
                        $batch += $request
                        $processedCount++
                    }
                    else {
                        break
                    }
                }
                
                # Process batch if we have requests
                if ($batch.Count -gt 0) {
                    foreach ($request in $batch) {
                        try {
                            Process-AnalysisRequest -Request $request
                            $PipelineState.Statistics.FilesProcessed++
                        }
                        catch {
                            $PipelineState.Statistics.Errors++
                            Write-Error "Failed to process analysis request $($request.Id): $_"
                        }
                    }
                }
                else {
                    # No requests, sleep briefly
                    Start-Sleep -Milliseconds 100
                }
            }
            catch {
                $PipelineState.Statistics.Errors++
                Write-Error "Error in processing thread: $_"
            }
        }
    }
    
    # Create and start the processing thread
    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.Open()
    $runspace.SessionStateProxy.SetVariable("PipelineState", $script:PipelineState)
    
    $powershell = [powershell]::Create()
    $powershell.Runspace = $runspace
    [void]$powershell.AddScript($processingScript)
    [void]$powershell.AddArgument($script:PipelineState)
    [void]$powershell.AddArgument($script:PipelineState.Configuration.BatchSize)
    
    $script:PipelineState.ProcessingThread = $powershell.BeginInvoke()
    
    Write-Verbose "Pipeline processing thread started"
}

function Process-AnalysisRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Request
    )
    
    $startTime = Get-Date
    $Request.Status = [ProcessingStatus]::InProgress
    
    Write-Verbose "Processing analysis request: $($Request.Id) - $($Request.FileEvent.FullPath)"
    
    try {
        # Stage 1: Change Classification
        if ($script:PipelineState.ConnectedServices.ChangeIntelligence) {
            $classificationStart = Get-Date
            $classification = Get-ChangeClassification -FileEvent $Request.FileEvent -UseAI:$script:PipelineState.Configuration.EnableAIEnhancement
            $Request.Results["Classification"] = $classification
            $Request.ProcessingTimes["Classification"] = ((Get-Date) - $classificationStart).TotalMilliseconds
            $Request.Stage = [PipelineStage]::ChangeClassification
        }
        
        # Stage 2: Semantic Analysis (if applicable and available)
        if ($script:PipelineState.ConnectedServices.SemanticAnalysis -and 
            $Request.FileEvent.FullPath -match '\.ps1$|\.psm1$') {
            
            $semanticStart = Get-Date
            try {
                # Try to use semantic analysis functions
                if (Get-Command "Get-SemanticAnalysis" -ErrorAction SilentlyContinue) {
                    $semanticResults = Get-SemanticAnalysis -Path $Request.FileEvent.FullPath
                    $Request.Results["Semantic"] = $semanticResults
                }
                elseif (Get-Command "Get-CodeDependencies" -ErrorAction SilentlyContinue) {
                    $dependencies = Get-CodeDependencies -Path $Request.FileEvent.FullPath
                    $Request.Results["Dependencies"] = $dependencies
                }
            }
            catch {
                Write-Verbose "Semantic analysis failed: $_"
            }
            $Request.ProcessingTimes["Semantic"] = ((Get-Date) - $semanticStart).TotalMilliseconds
            $Request.Stage = [PipelineStage]::SemanticAnalysis
        }
        
        # Stage 3: Predictive Analysis (if available)
        if ($script:PipelineState.ConnectedServices.PredictiveAnalysis) {
            $predictiveStart = Get-Date
            try {
                if (Get-Command "Get-PredictiveMaintenance" -ErrorAction SilentlyContinue) {
                    $maintenance = Get-PredictiveMaintenance -Path $Request.FileEvent.FullPath
                    $Request.Results["Maintenance"] = $maintenance
                }
            }
            catch {
                Write-Verbose "Predictive analysis failed: $_"
            }
            $Request.ProcessingTimes["Predictive"] = ((Get-Date) - $predictiveStart).TotalMilliseconds
            $Request.Stage = [PipelineStage]::PredictiveAnalysis
        }
        
        # Stage 4: Add to visualization queue
        if ($script:PipelineState.Configuration.EnableLiveVisualization) {
            $Request.Stage = [PipelineStage]::VisualizationUpdate
            $script:PipelineState.ResultsQueue.Enqueue($Request)
        }
        
        $Request.Status = [ProcessingStatus]::Completed
        $Request.Stage = [PipelineStage]::Completed
        
        # Update statistics
        $totalTime = ((Get-Date) - $startTime).TotalMilliseconds
        $script:PipelineState.Statistics.AverageProcessingTime = 
            ($script:PipelineState.Statistics.AverageProcessingTime + $totalTime) / 2
        
        Write-Verbose "Completed analysis request: $($Request.Id) in $([math]::Round($totalTime, 2))ms"
    }
    catch {
        $Request.Status = [ProcessingStatus]::Failed
        $Request.Stage = [PipelineStage]::Error
        $Request.Retries++
        
        # Retry if under limit
        if ($Request.Retries -lt $script:PipelineState.Configuration.MaxRetries) {
            $script:PipelineState.ProcessingQueue.Enqueue($Request)
        }
        
        throw
    }
}

function Start-VisualizationThread {
    [CmdletBinding()]
    param()
    
    $visualizationScript = {
        param($PipelineState)
        
        while ($PipelineState.IsRunning) {
            try {
                $result = $null
                if ($PipelineState.ResultsQueue.TryDequeue([ref]$result)) {
                    # Process visualization update
                    $visualizationData = Create-VisualizationData -AnalysisResult $result
                    
                    # Trigger visualization update (placeholder for actual visualization integration)
                    Write-Verbose "Visualization update triggered for: $($result.FileEvent.FullPath)"
                    $PipelineState.Statistics.VisualizationUpdatesTriggered++
                }
                else {
                    Start-Sleep -Milliseconds 500
                }
            }
            catch {
                $PipelineState.Statistics.Errors++
                Write-Error "Error in visualization thread: $_"
            }
        }
    }
    
    # Create and start visualization thread
    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.Open()
    $runspace.SessionStateProxy.SetVariable("PipelineState", $script:PipelineState)
    
    $powershell = [powershell]::Create()
    $powershell.Runspace = $runspace
    [void]$powershell.AddScript($visualizationScript)
    [void]$powershell.AddArgument($script:PipelineState)
    
    $script:PipelineState.VisualizationThread = $powershell.BeginInvoke()
    
    Write-Verbose "Visualization thread started"
}

function Create-VisualizationData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$AnalysisResult
    )
    
    return @{
        Id = $AnalysisResult.Id
        File = $AnalysisResult.FileEvent.FullPath
        FileName = $AnalysisResult.FileEvent.Name
        ChangeType = $AnalysisResult.Results.Classification.ChangeType
        ImpactSeverity = $AnalysisResult.Results.Classification.ImpactSeverity
        RiskLevel = $AnalysisResult.Results.Classification.RiskLevel
        ProcessingTime = $AnalysisResult.ProcessingTimes | ConvertTo-Json -Compress
        Timestamp = $AnalysisResult.Timestamp
        Results = $AnalysisResult.Results
    }
}

function Stop-RealTimeAnalysisPipeline {
    [CmdletBinding()]
    param()
    
    Write-Host "Stopping Real-Time Analysis Pipeline..." -ForegroundColor Yellow
    
    # Stop the pipeline
    $script:PipelineState.IsRunning = $false
    
    # Stop file system monitoring if running
    if ($script:PipelineState.ConnectedServices.FileSystemWatcher -and 
        (Get-Command "Stop-FileSystemMonitoring" -ErrorAction SilentlyContinue)) {
        try {
            Stop-FileSystemMonitoring | Out-Null
        }
        catch {
            Write-Verbose "Error stopping file system monitoring: $_"
        }
    }
    
    # Clear queues
    while ($script:PipelineState.ProcessingQueue.Count -gt 0) {
        $discarded = $null
        [void]$script:PipelineState.ProcessingQueue.TryDequeue([ref]$discarded)
    }
    
    while ($script:PipelineState.ResultsQueue.Count -gt 0) {
        $discarded = $null
        [void]$script:PipelineState.ResultsQueue.TryDequeue([ref]$discarded)
    }
    
    Write-Host "Real-Time Analysis Pipeline stopped" -ForegroundColor Yellow
    
    return Get-RealTimeAnalysisStatistics
}

function Get-RealTimeAnalysisStatistics {
    [CmdletBinding()]
    param()
    
    $stats = $script:PipelineState.Statistics.Clone()
    
    if ($stats.StartTime) {
        $stats.Runtime = (Get-Date) - $stats.StartTime
    }
    
    $stats.ProcessingQueueLength = $script:PipelineState.ProcessingQueue.Count
    $stats.ResultsQueueLength = $script:PipelineState.ResultsQueue.Count
    $stats.IsRunning = $script:PipelineState.IsRunning
    $stats.ConnectedServices = $script:PipelineState.ConnectedServices.Clone()
    
    return [PSCustomObject]$stats
}

function Get-PipelineConfiguration {
    [CmdletBinding()]
    param()
    
    return $script:PipelineState.Configuration.Clone()
}

function Set-PipelineConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Configuration
    )
    
    if ($script:PipelineState.IsRunning) {
        Write-Warning "Cannot change configuration while pipeline is running. Stop pipeline first."
        return $false
    }
    
    foreach ($key in $Configuration.Keys) {
        $script:PipelineState.Configuration[$key] = $Configuration[$key]
    }
    
    Write-Verbose "Pipeline configuration updated"
    return $true
}

function Test-PipelineHealth {
    [CmdletBinding()]
    param()
    
    $health = @{
        IsHealthy = $true
        Issues = @()
        Services = @{}
    }
    
    # Check if pipeline is running
    if (-not $script:PipelineState.IsRunning) {
        $health.IsHealthy = $false
        $health.Issues += "Pipeline is not running"
    }
    
    # Check connected services
    foreach ($serviceName in $script:PipelineState.ConnectedServices.Keys) {
        $connected = $script:PipelineState.ConnectedServices[$serviceName]
        $health.Services[$serviceName] = $connected
        
        if (-not $connected) {
            $health.Issues += "Service not connected: $serviceName"
        }
    }
    
    # Check queue sizes
    $stats = Get-RealTimeAnalysisStatistics
    if ($stats.ProcessingQueueLength -gt 100) {
        $health.IsHealthy = $false
        $health.Issues += "Processing queue overloaded: $($stats.ProcessingQueueLength) items"
    }
    
    # Check error rate
    if ($stats.FilesProcessed -gt 0) {
        $errorRate = $stats.Errors / $stats.FilesProcessed
        if ($errorRate -gt 0.05) {  # 5% error threshold
            $health.IsHealthy = $false
            $health.Issues += "High error rate: $([math]::Round($errorRate * 100, 2))%"
        }
    }
    
    return [PSCustomObject]$health
}

# Simulation function for testing without actual file changes
function Submit-TestAnalysisRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [string]$ChangeType = "Modified"
    )
    
    $testEvent = [PSCustomObject]@{
        Type = $ChangeType
        FullPath = $FilePath
        Name = Split-Path $FilePath -Leaf
        TimeStamp = Get-Date
    }
    
    Add-FileChangeToAnalysisQueue -FileEvent $testEvent
    Write-Host "Test analysis request submitted for: $FilePath" -ForegroundColor Green
}

# Export module functions
Export-ModuleMember -Function @(
    'Initialize-RealTimeAnalysisPipeline',
    'Start-RealTimeAnalysisPipeline',
    'Stop-RealTimeAnalysisPipeline',
    'Get-RealTimeAnalysisStatistics',
    'Get-PipelineConfiguration',
    'Set-PipelineConfiguration',
    'Test-PipelineHealth',
    'Submit-TestAnalysisRequest'
)