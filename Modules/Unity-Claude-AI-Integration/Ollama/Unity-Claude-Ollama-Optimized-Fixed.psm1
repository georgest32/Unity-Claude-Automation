# Unity-Claude-Ollama PowerShell Module - OPTIMIZED AND FIXED
# Week 1 Day 3 Hour 7-8: Ollama Integration Testing and Optimization - CRITICAL FIXES APPLIED
# Performance-optimized AI-enhanced documentation with batch processing and resource management
# FIXES: Memory division error, parallel module loading optimization

#region Module Variables and Configuration

# OPTIMIZED Module-level configuration
$script:OllamaConfig = @{
    BaseUrl = "http://localhost:11434"
    DefaultModel = "codellama:34b"
    
    # OPTIMIZATION: Dynamic context window sizing based on content
    ContextWindow = @{
        Small = 1024      # Simple documentation (under 500 chars)
        Medium = 4096     # Standard documentation (500-2000 chars)
        Large = 16384     # Complex documentation (2000+ chars)
        Maximum = 32768   # Full context for complex analysis
    }
    
    # OPTIMIZATION: Performance tuning parameters
    MaxRetries = 3        # Reduced from 5 for faster failure
    RetryDelay = 5        # Reduced from 10 seconds
    RequestTimeout = 60   # Optimized for <30s target (with buffer)
    
    # OPTIMIZATION: GPU and parallel processing settings
    NumParallel = 4       # OLLAMA_NUM_PARALLEL for concurrent requests
    MaxQueue = 10         # OLLAMA_MAX_QUEUE for request queuing
    
    StreamingEnabled = $true
    KeepAlive = "30m"     # Keep model loaded for 30 minutes
    ModelPreloaded = $false
    
    # OPTIMIZATION: Batch processing configuration
    BatchSize = 3         # Optimal batch size based on research
    BatchTimeout = 120    # 2 minutes for batch processing
}

# Enhanced performance tracking with detailed metrics
$script:OllamaMetrics = @{
    RequestCount = 0
    SuccessCount = 0
    ErrorCount = 0
    AverageResponseTime = 0
    LastRequestTime = $null
    
    # OPTIMIZATION: Detailed performance metrics
    ContextWindowUsage = @{
        Small = 0
        Medium = 0
        Large = 0
        Maximum = 0
    }
    BatchProcessingStats = @{
        BatchesProcessed = 0
        TotalBatchItems = 0
        AverageBatchTime = 0
        ParallelEfficiency = 0
    }
    MemoryUsage = @{
        PeakMemoryMB = 0
        CurrentMemoryMB = 0
        LastMemoryCheck = $null
    }
}

# OPTIMIZATION: Background job management for parallel processing
$script:OllamaJobManager = @{
    RunningJobs = @()
    CompletedJobs = @()
    FailedJobs = @()
    JobQueue = New-Object System.Collections.Concurrent.ConcurrentQueue[PSObject]
}

# Connection state
$script:OllamaConnection = @{
    IsConnected = $false
    LastHealthCheck = $null
    ServiceStatus = "Unknown"
    GPUDetected = $false
    OptimalConfiguration = @{}
}

Write-Host "[Unity-Claude-Ollama-Optimized-Fixed] Module loading - Performance-optimized AI integration v2.1.0 (FIXED)" -ForegroundColor Green

#endregion

#region OPTIMIZATION: Context Window Management Functions

function Get-OptimalContextWindow {
    <#
    .SYNOPSIS
    Determines optimal context window size based on content length and type
    
    .DESCRIPTION
    Dynamically calculates the most efficient context window size to minimize processing time
    while maintaining quality. Based on 2025 research on VRAM usage and performance optimization.
    
    .PARAMETER CodeContent
    The code content to analyze for context requirements
    
    .PARAMETER DocumentationType
    Type of documentation generation task
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$CodeContent,
        
        [string]$DocumentationType = "Detailed"
    )
    
    $contentLength = $CodeContent.Length
    $estimatedTokens = [Math]::Ceiling($contentLength / 4) # Rough token estimation
    
    # OPTIMIZATION: Dynamic context window selection based on research
    if ($contentLength -lt 500 -and $DocumentationType -in @("Synopsis", "Comments")) {
        $selectedWindow = $script:OllamaConfig.ContextWindow.Small
        $windowType = "Small"
    }
    elseif ($contentLength -lt 2000 -or $DocumentationType -eq "Detailed") {
        $selectedWindow = $script:OllamaConfig.ContextWindow.Medium
        $windowType = "Medium"
    }
    elseif ($contentLength -lt 8000 -or $DocumentationType -eq "Examples") {
        $selectedWindow = $script:OllamaConfig.ContextWindow.Large
        $windowType = "Large"
    }
    else {
        $selectedWindow = $script:OllamaConfig.ContextWindow.Maximum
        $windowType = "Maximum"
    }
    
    # Update usage statistics
    $script:OllamaMetrics.ContextWindowUsage[$windowType]++
    
    Write-Host "[ContextOptimization] Selected $windowType context window ($selectedWindow tokens) for $contentLength chars" -ForegroundColor Gray
    
    return @{
        ContextWindow = $selectedWindow
        WindowType = $windowType
        ContentLength = $contentLength
        EstimatedTokens = $estimatedTokens
    }
}

function Optimize-OllamaConfiguration {
    <#
    .SYNOPSIS
    Automatically detects and configures optimal Ollama settings - FIXED VERSION
    
    .DESCRIPTION
    Detects GPU availability, memory configuration, and optimal parallel processing settings
    based on system capabilities and 2025 performance research. FIXED array division errors.
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "[ConfigOptimization] Detecting optimal Ollama configuration..." -ForegroundColor Cyan
    
    try {
        # FIX: Detect GPU availability with proper array handling
        $gpuInfo = Get-WmiObject Win32_VideoController | Where-Object { $_.Name -match "NVIDIA|AMD|Intel" }
        if ($gpuInfo) {
            $script:OllamaConnection.GPUDetected = $true
            # Handle both single GPU and array of GPUs properly
            $gpuNames = if ($gpuInfo -is [Array]) { 
                ($gpuInfo | ForEach-Object { $_.Name }) -join ", " 
            } else { 
                $gpuInfo.Name 
            }
            Write-Host "[ConfigOptimization] GPU detected: $gpuNames" -ForegroundColor Green
        }
        
        # FIX: Detect system memory with proper array handling  
        $memoryInfo = Get-WmiObject Win32_ComputerSystem
        # Handle potential array from multiple memory controllers
        $totalMemoryBytes = if ($memoryInfo -is [Array]) { 
            # Sum memory from all controllers
            ($memoryInfo | ForEach-Object { 
                [double]$_.TotalPhysicalMemory 
            } | Measure-Object -Sum).Sum 
        } else { 
            [double]$memoryInfo.TotalPhysicalMemory 
        }
        $totalMemoryGB = [Math]::Round($totalMemoryBytes / 1GB, 2)
        
        # FIX: Calculate optimal parallel processing settings with array handling
        $processorInfo = Get-WmiObject Win32_Processor
        $cpuCores = if ($processorInfo -is [Array]) {
            # Sum cores from all processors
            ($processorInfo | ForEach-Object { 
                [int]$_.NumberOfLogicalProcessors 
            } | Measure-Object -Sum).Sum
        } else {
            [int]$processorInfo.NumberOfLogicalProcessors
        }
        $recommendedParallel = [Math]::Min(4, [Math]::Floor($cpuCores / 2))
        
        # OPTIMIZATION: Adjust configuration based on system capabilities
        $script:OllamaConfig.NumParallel = $recommendedParallel
        $script:OllamaConfig.MaxQueue = $recommendedParallel * 2
        
        # OPTIMIZATION: Set optimal timeout based on hardware
        if ($script:OllamaConnection.GPUDetected) {
            $script:OllamaConfig.RequestTimeout = 30  # GPU acceleration allows faster processing
        } else {
            $script:OllamaConfig.RequestTimeout = 60  # CPU processing needs more time
        }
        
        $optimizedConfig = @{
            GPU = $script:OllamaConnection.GPUDetected
            TotalMemoryGB = $totalMemoryGB
            CPUCores = $cpuCores
            OptimalParallel = $recommendedParallel
            OptimalTimeout = $script:OllamaConfig.RequestTimeout
        }
        
        $script:OllamaConnection.OptimalConfiguration = $optimizedConfig
        
        Write-Host "[ConfigOptimization] Optimal configuration applied:" -ForegroundColor Green
        Write-Host "  GPU Available: $($optimizedConfig.GPU)" -ForegroundColor Gray
        Write-Host "  System Memory: $($optimizedConfig.TotalMemoryGB)GB" -ForegroundColor Gray
        Write-Host "  CPU Cores: $($optimizedConfig.CPUCores)" -ForegroundColor Gray
        Write-Host "  Parallel Requests: $($optimizedConfig.OptimalParallel)" -ForegroundColor Gray
        Write-Host "  Request Timeout: $($optimizedConfig.OptimalTimeout)s" -ForegroundColor Gray
        
        return $optimizedConfig
    }
    catch {
        Write-Warning "[ConfigOptimization] Configuration detection failed: $($_.Exception.Message)"
        return $null
    }
}

#endregion

#region OPTIMIZATION: Batch Processing Functions - FIXED VERSION

function Start-OllamaBatchProcessing {
    <#
    .SYNOPSIS
    Processes multiple AI requests in optimized batches with parallel execution - FIXED VERSION
    
    .DESCRIPTION
    Implements advanced batch processing with parallel PowerShell jobs, queue management,
    and resource optimization. FIXED module loading optimization to avoid reimporting entire module.
    
    .PARAMETER RequestBatch
    Array of request objects to process
    
    .PARAMETER BatchSize
    Number of requests to process in parallel (default: optimized based on system)
    
    .PARAMETER ShowProgress
    Display progress bar for batch processing
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Array]$RequestBatch,
        
        [int]$BatchSize = $script:OllamaConfig.BatchSize,
        
        [switch]$ShowProgress
    )
    
    Write-Host "[BatchProcessing] Starting batch processing for $($RequestBatch.Count) requests..." -ForegroundColor Cyan
    
    $batchStartTime = Get-Date
    $results = [System.Collections.Concurrent.ConcurrentBag[PSObject]]::new()
    $processedCount = 0
    $totalRequests = $RequestBatch.Count
    
    try {
        # OPTIMIZATION: Process requests in parallel batches
        for ($i = 0; $i -lt $totalRequests; $i += $BatchSize) {
            $currentBatch = $RequestBatch[$i..([Math]::Min($i + $BatchSize - 1, $totalRequests - 1))]
            
            Write-Host "[BatchProcessing] Processing batch $([Math]::Ceiling(($i + 1) / $BatchSize)) of $([Math]::Ceiling($totalRequests / $BatchSize))" -ForegroundColor Yellow
            
            # FIX: Use optimized parallel processing with embedded functions to avoid module reimporting
            if ($PSVersionTable.PSVersion.Major -ge 7) {
                $currentBatch | ForEach-Object -Parallel {
                    $request = $_
                    $results = $using:results
                    
                    try {
                        # FIX: Define functions inline to avoid module reimporting overhead
                        # This is much faster than Import-Module in each runspace
                        $contextWindowConfig = @{ Small = 1024; Medium = 4096; Large = 16384; Maximum = 32768 }
                        
                        # Inline context window optimization function
                        $contentLength = $request.CodeContent.Length
                        if ($contentLength -lt 500 -and $request.DocumentationType -in @("Synopsis", "Comments")) {
                            $contextWindow = $contextWindowConfig.Small
                            $windowType = "Small"
                        } elseif ($contentLength -lt 2000 -or $request.DocumentationType -eq "Detailed") {
                            $contextWindow = $contextWindowConfig.Medium  
                            $windowType = "Medium"
                        } elseif ($contentLength -lt 8000 -or $request.DocumentationType -eq "Examples") {
                            $contextWindow = $contextWindowConfig.Large
                            $windowType = "Large"
                        } else {
                            $contextWindow = $contextWindowConfig.Maximum
                            $windowType = "Maximum"
                        }
                        
                        $contextInfo = @{
                            ContextWindow = $contextWindow
                            WindowType = $windowType
                            ContentLength = $contentLength
                        }
                        
                        # Inline optimized request function
                        $requestStartTime = Get-Date
                        $prompt = "Generate $($request.DocumentationType) documentation for this PowerShell code:`n`n$($request.CodeContent)"
                        
                        $requestBody = @{
                            model = "codellama:34b"
                            prompt = $prompt
                            stream = $false
                            options = @{
                                num_ctx = $contextInfo.ContextWindow
                                temperature = 0.1  # OPTIMIZATION: Lower temperature for code generation
                                top_p = 0.9       # OPTIMIZATION: Focused sampling
                            }
                        } | ConvertTo-Json -Depth 5
                        
                        # Make optimized API request
                        $response = Invoke-RestMethod -Uri "http://localhost:11434/api/generate" -Method POST -Body $requestBody -ContentType "application/json" -TimeoutSec 60
                        
                        $requestDuration = (Get-Date) - $requestStartTime
                        
                        $optimizedResult = @{
                            Success = $true
                            Documentation = $response.response
                            DocumentationType = $request.DocumentationType
                            ContextWindow = $contextInfo.ContextWindow
                            WindowType = $contextInfo.WindowType
                            ResponseTime = $requestDuration.TotalSeconds
                            Model = "codellama:34b"
                            Timestamp = Get-Date
                            Request = $request
                        }
                        
                        $results.Add($optimizedResult)
                    }
                    catch {
                        $errorResult = @{
                            Success = $false
                            Error = $_.Exception.Message
                            Request = $request
                            Timestamp = Get-Date
                            ResponseTime = 0
                        }
                        $results.Add($errorResult)
                    }
                } -ThrottleLimit $BatchSize
            }
            else {
                # OPTIMIZATION: Fallback to Start-ThreadJob for older PowerShell versions
                $jobs = @()
                
                foreach ($request in $currentBatch) {
                    $job = Start-ThreadJob -ScriptBlock {
                        param($req)
                        
                        # Same inline optimization approach for older PowerShell
                        $contextWindowConfig = @{ Small = 1024; Medium = 4096; Large = 16384; Maximum = 32768 }
                        $contentLength = $req.CodeContent.Length
                        
                        if ($contentLength -lt 500 -and $req.DocumentationType -in @("Synopsis", "Comments")) {
                            $contextWindow = $contextWindowConfig.Small
                            $windowType = "Small"
                        } elseif ($contentLength -lt 2000 -or $req.DocumentationType -eq "Detailed") {
                            $contextWindow = $contextWindowConfig.Medium  
                            $windowType = "Medium"
                        } else {
                            $contextWindow = $contextWindowConfig.Large
                            $windowType = "Large"
                        }
                        
                        try {
                            $requestStartTime = Get-Date
                            $prompt = "Generate $($req.DocumentationType) documentation for this PowerShell code:`n`n$($req.CodeContent)"
                            
                            $requestBody = @{
                                model = "codellama:34b"
                                prompt = $prompt
                                stream = $false
                                options = @{ num_ctx = $contextWindow; temperature = 0.1; top_p = 0.9 }
                            } | ConvertTo-Json -Depth 5
                            
                            $response = Invoke-RestMethod -Uri "http://localhost:11434/api/generate" -Method POST -Body $requestBody -ContentType "application/json" -TimeoutSec 60
                            $requestDuration = (Get-Date) - $requestStartTime
                            
                            return @{
                                Success = $true; Documentation = $response.response; DocumentationType = $req.DocumentationType
                                ContextWindow = $contextWindow; WindowType = $windowType; ResponseTime = $requestDuration.TotalSeconds
                                Model = "codellama:34b"; Timestamp = Get-Date; Request = $req
                            }
                        }
                        catch {
                            return @{ Success = $false; Error = $_.Exception.Message; Request = $req; Timestamp = Get-Date; ResponseTime = 0 }
                        }
                        
                    } -ArgumentList $request
                    
                    $jobs += $job
                }
                
                # Wait for batch completion with timeout
                $batchResults = $jobs | Wait-Job -Timeout $script:OllamaConfig.BatchTimeout | Receive-Job
                
                foreach ($result in $batchResults) {
                    $results.Add($result)
                }
                
                # Cleanup completed jobs
                $jobs | Remove-Job -Force
            }
            
            $processedCount += $currentBatch.Count
            
            # OPTIMIZATION: Progress reporting
            if ($ShowProgress) {
                $percentComplete = [Math]::Round(($processedCount / $totalRequests) * 100, 1)
                Write-Progress -Activity "Batch Processing AI Requests" -Status "$processedCount of $totalRequests processed" -PercentComplete $percentComplete
            }
        }
        
        $batchDuration = (Get-Date) - $batchStartTime
        $averageBatchTime = $batchDuration.TotalSeconds / [Math]::Ceiling($totalRequests / $BatchSize)
        
        # OPTIMIZATION: Update batch processing statistics
        $script:OllamaMetrics.BatchProcessingStats.BatchesProcessed++
        $script:OllamaMetrics.BatchProcessingStats.TotalBatchItems += $totalRequests
        $script:OllamaMetrics.BatchProcessingStats.AverageBatchTime = $averageBatchTime
        
        # Calculate parallel efficiency (target: 90%+)
        $theoreticalTime = $totalRequests * 30 # Assume 30s per request sequentially
        $actualTime = $batchDuration.TotalSeconds
        $efficiency = [Math]::Round((1 - ($actualTime / $theoreticalTime)) * 100, 1)
        $script:OllamaMetrics.BatchProcessingStats.ParallelEfficiency = $efficiency
        
        Write-Host "[BatchProcessing] Batch completed successfully!" -ForegroundColor Green
        Write-Host "  Total Requests: $totalRequests" -ForegroundColor Gray
        Write-Host "  Processing Time: $([Math]::Round($batchDuration.TotalSeconds, 1))s" -ForegroundColor Gray
        Write-Host "  Average per Batch: $([Math]::Round($averageBatchTime, 1))s" -ForegroundColor Gray
        Write-Host "  Parallel Efficiency: $efficiency%" -ForegroundColor Gray
        
        return @{
            Results = $results.ToArray()
            TotalProcessed = $totalRequests
            ProcessingTime = $batchDuration.TotalSeconds
            AverageBatchTime = $averageBatchTime
            ParallelEfficiency = $efficiency
            Success = $true
        }
    }
    catch {
        Write-Error "[BatchProcessing] Batch processing failed: $($_.Exception.Message)"
        return @{
            Results = $results.ToArray()
            Success = $false
            Error = $_.Exception.Message
            ProcessingTime = ((Get-Date) - $batchStartTime).TotalSeconds
        }
    }
    finally {
        if ($ShowProgress) {
            Write-Progress -Activity "Batch Processing AI Requests" -Completed
        }
    }
}

function Invoke-OllamaOptimizedRequest {
    <#
    .SYNOPSIS
    Processes a single AI request with optimal configuration
    
    .DESCRIPTION
    Internal function for processing individual requests with context window optimization,
    performance monitoring, and enhanced error handling.
    
    .PARAMETER Request
    Request object containing CodeContent and DocumentationType
    
    .PARAMETER ContextInfo
    Optimal context window information from Get-OptimalContextWindow
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [PSObject]$Request,
        
        [Parameter(Mandatory=$true)]
        [PSObject]$ContextInfo
    )
    
    $requestStartTime = Get-Date
    
    try {
        # OPTIMIZATION: Use optimal context window for request
        $requestBody = @{
            model = $script:OllamaConfig.DefaultModel
            prompt = Format-OptimizedPrompt -CodeContent $Request.CodeContent -DocumentationType $Request.DocumentationType
            stream = $false
            options = @{
                num_ctx = $ContextInfo.ContextWindow
                temperature = 0.1  # OPTIMIZATION: Lower temperature for code generation
                top_p = 0.9       # OPTIMIZATION: Focused sampling
            }
        } | ConvertTo-Json -Depth 5
        
        # Make optimized API request
        $response = Invoke-RestMethod -Uri "$($script:OllamaConfig.BaseUrl)/api/generate" -Method POST -Body $requestBody -ContentType "application/json" -TimeoutSec $script:OllamaConfig.RequestTimeout
        
        $requestDuration = (Get-Date) - $requestStartTime
        
        # Update metrics
        $script:OllamaMetrics.RequestCount++
        $script:OllamaMetrics.SuccessCount++
        
        # Calculate rolling average response time
        if ($script:OllamaMetrics.AverageResponseTime -eq 0) {
            $script:OllamaMetrics.AverageResponseTime = $requestDuration.TotalSeconds
        } else {
            $script:OllamaMetrics.AverageResponseTime = ($script:OllamaMetrics.AverageResponseTime + $requestDuration.TotalSeconds) / 2
        }
        
        return @{
            Success = $true
            Documentation = $response.response
            DocumentationType = $Request.DocumentationType
            ContextWindow = $ContextInfo.ContextWindow
            WindowType = $ContextInfo.WindowType
            ResponseTime = $requestDuration.TotalSeconds
            Model = $script:OllamaConfig.DefaultModel
            Timestamp = Get-Date
            Request = $Request
        }
    }
    catch {
        $requestDuration = (Get-Date) - $requestStartTime
        $script:OllamaMetrics.RequestCount++
        $script:OllamaMetrics.ErrorCount++
        
        return @{
            Success = $false
            Error = $_.Exception.Message
            ResponseTime = $requestDuration.TotalSeconds
            ContextWindow = $ContextInfo.ContextWindow
            WindowType = $ContextInfo.WindowType
            Timestamp = Get-Date
            Request = $Request
        }
    }
}

function Format-OptimizedPrompt {
    <#
    .SYNOPSIS
    Creates optimized prompts for different documentation types
    
    .DESCRIPTION
    Generates optimized prompts based on 2025 CodeLlama prompt engineering research
    for improved performance and quality.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$CodeContent,
        
        [string]$DocumentationType = "Detailed"
    )
    
    # OPTIMIZATION: Streamlined prompts for faster processing
    $basePrompts = @{
        Synopsis = "Generate a concise function synopsis for this PowerShell code. Focus on purpose and key parameters only:`n`n$CodeContent"
        
        Detailed = "Generate comprehensive documentation for this PowerShell code. Include purpose, parameters, examples, and notes:`n`n$CodeContent"
        
        Comments = "Add inline comments to this PowerShell code to explain key logic and functionality:`n`n$CodeContent"
        
        Examples = "Generate usage examples for this PowerShell code with different parameter scenarios:`n`n$CodeContent"
    }
    
    return $basePrompts[$DocumentationType]
}

#endregion

#region OPTIMIZATION: Enhanced Performance Monitoring - FIXED VERSION

function Get-OllamaPerformanceReport {
    <#
    .SYNOPSIS
    Generates comprehensive performance report with optimization recommendations - FIXED VERSION
    
    .DESCRIPTION
    Provides detailed performance analytics including context window usage, batch processing
    efficiency, memory utilization, and optimization recommendations. FIXED array division errors.
    #>
    [CmdletBinding()]
    param(
        [switch]$Detailed,
        [switch]$ExportToFile,
        [string]$OutputPath = ".\OllamaPerformanceReport.json"
    )
    
    Write-Host "[PerformanceReport] Generating comprehensive performance report..." -ForegroundColor Cyan
    
    # FIX: Memory usage monitoring with proper array and null handling
    try {
        $processes = Get-Process -Name "ollama" -ErrorAction SilentlyContinue
        if ($processes) {
            # Handle both single process and array of processes
            $currentMemoryMB = if ($processes -is [Array]) {
                # Sum memory from all ollama processes
                $totalMemory = ($processes | ForEach-Object { 
                    [double]$_.WorkingSet64 
                } | Measure-Object -Sum).Sum
                [Math]::Round($totalMemory / 1MB, 2)
            } else {
                [Math]::Round([double]$processes.WorkingSet64 / 1MB, 2)
            }
        } else {
            $currentMemoryMB = 0
        }
        
        if ($currentMemoryMB -gt $script:OllamaMetrics.MemoryUsage.PeakMemoryMB) {
            $script:OllamaMetrics.MemoryUsage.PeakMemoryMB = $currentMemoryMB
        }
        $script:OllamaMetrics.MemoryUsage.CurrentMemoryMB = $currentMemoryMB
        $script:OllamaMetrics.MemoryUsage.LastMemoryCheck = Get-Date
    }
    catch {
        Write-Warning "[PerformanceReport] Memory monitoring failed: $($_.Exception.Message)"
        $script:OllamaMetrics.MemoryUsage.CurrentMemoryMB = 0
        $script:OllamaMetrics.MemoryUsage.LastMemoryCheck = Get-Date
    }
    
    # Calculate success rate
    $successRate = if ($script:OllamaMetrics.RequestCount -gt 0) {
        [Math]::Round(($script:OllamaMetrics.SuccessCount / $script:OllamaMetrics.RequestCount) * 100, 1)
    } else { 0 }
    
    # Context window efficiency analysis
    $contextUsage = $script:OllamaMetrics.ContextWindowUsage
    $totalContextRequests = ($contextUsage.Values | Measure-Object -Sum).Sum
    $contextEfficiency = if ($totalContextRequests -gt 0) {
        @{
            SmallUsage = [Math]::Round(($contextUsage.Small / $totalContextRequests) * 100, 1)
            MediumUsage = [Math]::Round(($contextUsage.Medium / $totalContextRequests) * 100, 1)
            LargeUsage = [Math]::Round(($contextUsage.Large / $totalContextRequests) * 100, 1)
            MaximumUsage = [Math]::Round(($contextUsage.Maximum / $totalContextRequests) * 100, 1)
        }
    } else {
        @{ SmallUsage = 0; MediumUsage = 0; LargeUsage = 0; MaximumUsage = 0 }
    }
    
    # Performance recommendations
    $recommendations = @()
    
    if ($script:OllamaMetrics.AverageResponseTime -gt 30) {
        $recommendations += "CRITICAL: Average response time ($([Math]::Round($script:OllamaMetrics.AverageResponseTime, 1))s) exceeds target (<30s). Consider GPU acceleration or model optimization."
    }
    
    if ($contextEfficiency.MaximumUsage -gt 50) {
        $recommendations += "OPTIMIZATION: High maximum context usage ($($contextEfficiency.MaximumUsage)%). Consider breaking large requests into smaller chunks."
    }
    
    if ($script:OllamaMetrics.BatchProcessingStats.ParallelEfficiency -lt 70 -and $script:OllamaMetrics.BatchProcessingStats.BatchesProcessed -gt 0) {
        $recommendations += "PERFORMANCE: Parallel efficiency ($($script:OllamaMetrics.BatchProcessingStats.ParallelEfficiency)%) below optimal. Consider reducing batch size or increasing hardware resources."
    }
    
    if ($script:OllamaMetrics.ErrorCount -gt ($script:OllamaMetrics.RequestCount * 0.1)) {
        $recommendations += "RELIABILITY: Error rate above 10%. Check network connectivity and model availability."
    }
    
    $report = @{
        GeneratedAt = Get-Date
        OverallMetrics = @{
            TotalRequests = $script:OllamaMetrics.RequestCount
            SuccessfulRequests = $script:OllamaMetrics.SuccessCount
            FailedRequests = $script:OllamaMetrics.ErrorCount
            SuccessRate = "$successRate%"
            AverageResponseTime = "$([Math]::Round($script:OllamaMetrics.AverageResponseTime, 2))s"
        }
        ContextWindowAnalysis = @{
            Usage = $contextEfficiency
            TotalRequests = $totalContextRequests
            OptimizationEffective = ($contextEfficiency.SmallUsage + $contextEfficiency.MediumUsage) -gt 60
        }
        BatchProcessingMetrics = $script:OllamaMetrics.BatchProcessingStats
        MemoryUsage = $script:OllamaMetrics.MemoryUsage
        SystemConfiguration = $script:OllamaConnection.OptimalConfiguration
        PerformanceRecommendations = $recommendations
        OptimizationStatus = if ($recommendations.Count -eq 0) { "Optimal" } elseif ($recommendations.Count -le 2) { "Good" } else { "Needs Optimization" }
    }
    
    if ($Detailed) {
        Write-Host "[PerformanceReport] === OLLAMA PERFORMANCE REPORT ===" -ForegroundColor Cyan
        Write-Host "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
        Write-Host ""
        Write-Host "OVERALL PERFORMANCE:" -ForegroundColor Yellow
        Write-Host "  Total Requests: $($report.OverallMetrics.TotalRequests)" -ForegroundColor White
        Write-Host "  Success Rate: $($report.OverallMetrics.SuccessRate)" -ForegroundColor $(if($successRate -gt 90) {"Green"} elseif($successRate -gt 75) {"Yellow"} else {"Red"})
        Write-Host "  Average Response: $($report.OverallMetrics.AverageResponseTime)" -ForegroundColor $(if($script:OllamaMetrics.AverageResponseTime -lt 30) {"Green"} elseif($script:OllamaMetrics.AverageResponseTime -lt 60) {"Yellow"} else {"Red"})
        Write-Host ""
        Write-Host "CONTEXT WINDOW OPTIMIZATION:" -ForegroundColor Yellow
        Write-Host "  Small Context: $($contextEfficiency.SmallUsage)%" -ForegroundColor Gray
        Write-Host "  Medium Context: $($contextEfficiency.MediumUsage)%" -ForegroundColor Gray
        Write-Host "  Large Context: $($contextEfficiency.LargeUsage)%" -ForegroundColor Gray
        Write-Host "  Maximum Context: $($contextEfficiency.MaximumUsage)%" -ForegroundColor Gray
        Write-Host ""
        if ($script:OllamaMetrics.BatchProcessingStats.BatchesProcessed -gt 0) {
            Write-Host "BATCH PROCESSING:" -ForegroundColor Yellow
            Write-Host "  Batches Processed: $($script:OllamaMetrics.BatchProcessingStats.BatchesProcessed)" -ForegroundColor Gray
            Write-Host "  Parallel Efficiency: $($script:OllamaMetrics.BatchProcessingStats.ParallelEfficiency)%" -ForegroundColor $(if($script:OllamaMetrics.BatchProcessingStats.ParallelEfficiency -gt 80) {"Green"} elseif($script:OllamaMetrics.BatchProcessingStats.ParallelEfficiency -gt 60) {"Yellow"} else {"Red"})
        }
        Write-Host ""
        Write-Host "MEMORY USAGE:" -ForegroundColor Yellow
        Write-Host "  Current: $($report.MemoryUsage.CurrentMemoryMB)MB" -ForegroundColor Gray
        Write-Host "  Peak: $($report.MemoryUsage.PeakMemoryMB)MB" -ForegroundColor Gray
        
        if ($recommendations.Count -gt 0) {
            Write-Host ""
            Write-Host "RECOMMENDATIONS:" -ForegroundColor Yellow
            foreach ($rec in $recommendations) {
                Write-Host "  • $rec" -ForegroundColor White
            }
        }
    }
    
    if ($ExportToFile) {
        $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Host "[PerformanceReport] Report exported to: $OutputPath" -ForegroundColor Green
    }
    
    return $report
}

#endregion

#region Module Initialization and Export

# OPTIMIZATION: Initialize optimal configuration on module load
Write-Host "[OptimizedOllamaFixed] Initializing performance optimization..." -ForegroundColor Yellow
$configResult = Optimize-OllamaConfiguration
if ($configResult) {
    Write-Host "[OptimizedOllamaFixed] Configuration optimization completed successfully" -ForegroundColor Green
} else {
    Write-Warning "[OptimizedOllamaFixed] Configuration optimization had issues, using defaults"
}

# Import base functions from original module (if needed for compatibility)
$originalModulePath = "$PSScriptRoot\Unity-Claude-Ollama.psm1"
if (Test-Path $originalModulePath) {
    Write-Host "[OptimizedOllamaFixed] Loading base functions for compatibility..." -ForegroundColor Gray
    try {
        # Import specific functions we need from the original module
        . $originalModulePath
        Write-Host "[OptimizedOllamaFixed] Base functions loaded successfully" -ForegroundColor Green
    }
    catch {
        Write-Warning "[OptimizedOllamaFixed] Base function loading had issues: $($_.Exception.Message)"
    }
} else {
    Write-Warning "[OptimizedOllamaFixed] Original module not found at $originalModulePath"
}

# Export optimized functions
Export-ModuleMember -Function @(
    # Original functions (maintained for compatibility)
    'Test-OllamaConnectivity',
    'Set-OllamaConfiguration', 
    'Get-OllamaModelInfo',
    'Start-ModelPreloading',
    
    # OPTIMIZATION: New optimized and fixed functions
    'Get-OptimalContextWindow',
    'Optimize-OllamaConfiguration',
    'Start-OllamaBatchProcessing',
    'Invoke-OllamaOptimizedRequest',
    'Get-OllamaPerformanceReport',
    'Format-OptimizedPrompt'
)

Write-Host "[Unity-Claude-Ollama-Optimized-Fixed] Performance optimization module loaded successfully v2.1.0" -ForegroundColor Green
Write-Host "  Context Window Optimization: ENABLED" -ForegroundColor Gray  
Write-Host "  Batch Processing: ENABLED (Fixed module loading)" -ForegroundColor Gray
Write-Host "  Performance Monitoring: ENHANCED (Fixed array handling)" -ForegroundColor Gray
Write-Host "  Parallel Processing: CONFIGURED" -ForegroundColor Gray
Write-Host "  Critical Fixes Applied: Memory division, module loading optimization" -ForegroundColor Green

#endregion
