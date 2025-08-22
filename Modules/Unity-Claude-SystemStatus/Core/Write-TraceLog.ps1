function Write-TraceLog {
    <#
    .SYNOPSIS
    Writes detailed trace logging for execution flow analysis
    
    .DESCRIPTION
    Provides comprehensive trace logging following 2025 best practices:
    - Execution flow tracing with operation context
    - Performance timing measurement
    - Context preservation for debugging
    - Structured logging support
    - Call stack analysis
    - Thread-safe operation
    
    .PARAMETER Message
    Trace message describing the operation or state
    
    .PARAMETER Operation
    Name of the operation being traced
    
    .PARAMETER Context
    Additional context information as hashtable
    
    .PARAMETER Timer
    Stopwatch object for performance measurement
    
    .PARAMETER TraceLevel
    Trace detail level: Flow (basic flow), Detail (detailed info), Performance (timing focus)
    
    .PARAMETER CallDepth
    Call stack depth for indentation (auto-calculated if not specified)
    
    .EXAMPLE
    Write-TraceLog -Message "Starting subsystem registration" -Operation "Register-Subsystem"
    
    .EXAMPLE
    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    # ... operation ...
    Write-TraceLog -Message "Subsystem registered successfully" -Operation "Register-Subsystem" -Timer $timer
    
    .EXAMPLE
    Write-TraceLog -Message "Processing manifest" -Context @{ManifestPath=".\test.psd1"; SubsystemCount=3}
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [string]$Operation,
        
        [hashtable]$Context = @{},
        
        [System.Diagnostics.Stopwatch]$Timer,
        
        [ValidateSet('Flow', 'Detail', 'Performance')]
        [string]$TraceLevel = 'Flow',
        
        [int]$CallDepth = -1
    )
    
    # Only proceed if trace logging is enabled
    if (-not $script:DiagnosticModeEnabled -and -not $script:TraceLoggingEnabled) {
        return
    }
    
    try {
        # Auto-calculate call depth if not specified
        if ($CallDepth -eq -1) {
            $callStack = Get-PSCallStack
            $CallDepth = $callStack.Count - 2 # Exclude Write-TraceLog and the caller
            if ($CallDepth -lt 0) { $CallDepth = 0 }
        }
        
        # Create indentation based on call depth
        $indent = "  " * $CallDepth
        
        # Build enhanced context
        $enhancedContext = $Context.Clone()
        $enhancedContext.TraceLevel = $TraceLevel
        $enhancedContext.CallDepth = $CallDepth
        $enhancedContext.ThreadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
        
        # Add caller information for detailed tracing
        if ($TraceLevel -eq 'Detail' -or $script:DiagnosticLevel -eq 'Advanced') {
            try {
                $caller = Get-PSCallStack | Select-Object -Skip 1 -First 1
                if ($caller) {
                    $enhancedContext.CallerFunction = $caller.FunctionName
                    $enhancedContext.CallerFile = Split-Path $caller.ScriptName -Leaf
                    $enhancedContext.CallerLine = $caller.ScriptLineNumber
                }
            } catch {
                # Ignore call stack errors
            }
        }
        
        # Add performance information
        if ($Timer) {
            $enhancedContext.ElapsedMs = $Timer.ElapsedMilliseconds
            $enhancedContext.ElapsedTicks = $Timer.ElapsedTicks
        }
        
        # Format the trace message
        $traceMessage = "$indent$Message"
        if ($Operation) {
            $traceMessage = "$indent[$Operation] $Message"
        }
        
        # Add timing information to message for performance tracing
        if ($TraceLevel -eq 'Performance' -and $Timer) {
            $traceMessage += " ($($Timer.ElapsedMilliseconds)ms)"
        }
        
        # Write to standard logging with TRACE level
        Write-SystemStatusLog -Message $traceMessage -Level 'TRACE' -Source 'Trace' -Operation $Operation -Context $enhancedContext -Timer $Timer
        
        # Write to dedicated trace file if available
        if ($script:DiagnosticTraceStream) {
            Write-ToTraceFile -Message $traceMessage -Context $enhancedContext -Timer $Timer
        }
        
        # Collect performance data if performance monitoring is enabled
        if ($script:DiagnosticLevel -eq 'Performance' -and $Timer) {
            Collect-TracePerformanceData -Operation $Operation -Timer $Timer -Context $enhancedContext
        }
        
    } catch {
        # Fail silently to avoid disrupting traced operations
        try {
            Write-SystemStatusLog "Trace logging error: $($_.Exception.Message)" -Level 'ERROR' -Source 'Trace'
        } catch {
            # Ultimate fallback - ignore all errors to prevent trace logging from breaking traced code
        }
    }
}

function Start-TraceOperation {
    <#
    .SYNOPSIS
    Starts tracing an operation and returns a trace context object
    
    .DESCRIPTION
    Convenience function for tracing operations with automatic timing and context management
    
    .PARAMETER Operation
    Name of the operation to trace
    
    .PARAMETER Context
    Initial context for the operation
    
    .EXAMPLE
    $trace = Start-TraceOperation -Operation "ProcessManifest" -Context @{ManifestPath=".\test.psd1"}
    # ... operation code ...
    Stop-TraceOperation -TraceContext $trace -Message "Processing completed"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Operation,
        
        [hashtable]$Context = @{}
    )
    
    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    $traceId = [System.Guid]::NewGuid().ToString("N").Substring(0, 8)
    
    $traceContext = @{
        Operation = $Operation
        TraceId = $traceId
        Timer = $timer
        StartTime = Get-Date
        Context = $Context
    }
    
    $enhancedContext = $Context.Clone()
    $enhancedContext.TraceId = $traceId
    
    Write-TraceLog -Message "Operation started" -Operation $Operation -Context $enhancedContext -Timer $timer
    
    return $traceContext
}

function Stop-TraceOperation {
    <#
    .SYNOPSIS
    Stops tracing an operation and logs the completion
    
    .PARAMETER TraceContext
    Trace context object returned by Start-TraceOperation
    
    .PARAMETER Message
    Completion message (default: "Operation completed")
    
    .PARAMETER Success
    Whether the operation completed successfully
    
    .PARAMETER Error
    Error information if the operation failed
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$TraceContext,
        
        [string]$Message = "Operation completed",
        
        [bool]$Success = $true,
        
        [string]$Error
    )
    
    if (-not $TraceContext -or -not $TraceContext.Timer) {
        Write-SystemStatusLog "Invalid trace context provided to Stop-TraceOperation" -Level 'WARN' -Source 'Trace'
        return
    }
    
    $TraceContext.Timer.Stop()
    
    $enhancedContext = $TraceContext.Context.Clone()
    $enhancedContext.TraceId = $TraceContext.TraceId
    $enhancedContext.Success = $Success
    $enhancedContext.TotalElapsedMs = $TraceContext.Timer.ElapsedMilliseconds
    
    if ($Error) {
        $enhancedContext.Error = $Error
    }
    
    $finalMessage = $Message
    if (-not $Success) {
        $finalMessage = "$Message (FAILED)"
        if ($Error) {
            $finalMessage += ": $Error"
        }
    }
    
    Write-TraceLog -Message $finalMessage -Operation $TraceContext.Operation -Context $enhancedContext -Timer $TraceContext.Timer -TraceLevel 'Performance'
}

function Write-ToTraceFile {
    <#
    .SYNOPSIS
    Writes trace information to the dedicated trace file
    #>
    param(
        [string]$Message,
        [hashtable]$Context,
        [System.Diagnostics.Stopwatch]$Timer
    )
    
    try {
        if (-not $script:DiagnosticTraceStream) {
            return
        }
        
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
        $traceEntry = "[$timestamp] $Message"
        
        # Add context information
        if ($Context.Count -gt 0) {
            $contextItems = @()
            foreach ($key in $Context.Keys) {
                if ($Context[$key] -ne $null) {
                    $contextItems += "$key=$($Context[$key])"
                }
            }
            if ($contextItems.Count -gt 0) {
                $traceEntry += " {$($contextItems -join '; ')}"
            }
        }
        
        $script:DiagnosticTraceStream.WriteLine($traceEntry)
        $script:DiagnosticTraceStream.Flush()
        
    } catch {
        # Ignore trace file errors to avoid disrupting operations
    }
}

function Collect-TracePerformanceData {
    <#
    .SYNOPSIS
    Collects performance data from trace operations
    #>
    param(
        [string]$Operation,
        [System.Diagnostics.Stopwatch]$Timer,
        [hashtable]$Context
    )
    
    try {
        if (-not $script:DiagnosticPerformanceData) {
            $script:DiagnosticPerformanceData = @()
        }
        
        $performanceData = @{
            Operation = $Operation
            Timestamp = Get-Date
            ElapsedMs = $Timer.ElapsedMilliseconds
            ElapsedTicks = $Timer.ElapsedTicks
            ThreadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
            Context = $Context
        }
        
        $script:DiagnosticPerformanceData += $performanceData
        
        # Limit performance data collection to prevent memory issues
        if ($script:DiagnosticPerformanceData.Count -gt 10000) {
            $script:DiagnosticPerformanceData = $script:DiagnosticPerformanceData | Select-Object -Last 5000
        }
        
    } catch {
        # Ignore performance data collection errors
    }
}

function Enable-TraceLogging {
    <#
    .SYNOPSIS
    Enables trace logging outside of diagnostic mode
    
    .PARAMETER TraceFile
    Optional dedicated trace file
    
    .PARAMETER Level
    Trace level to enable
    #>
    [CmdletBinding()]
    param(
        [string]$TraceFile,
        
        [ValidateSet('Flow', 'Detail', 'Performance')]
        [string]$Level = 'Flow'
    )
    
    $script:TraceLoggingEnabled = $true
    $script:TraceLoggingLevel = $Level
    
    if ($TraceFile) {
        try {
            $script:DiagnosticTraceFile = $TraceFile
            $script:DiagnosticTraceStream = [System.IO.StreamWriter]::new($TraceFile, $true)
            $script:DiagnosticTraceStream.WriteLine("# Trace Logging Session Started: $(Get-Date)")
            $script:DiagnosticTraceStream.Flush()
        } catch {
            Write-SystemStatusLog "Failed to initialize trace file: $($_.Exception.Message)" -Level 'ERROR' -Source 'Trace'
        }
    }
    
    Write-SystemStatusLog "Trace logging enabled (level: $Level)" -Level 'INFO' -Source 'Trace'
}

function Disable-TraceLogging {
    <#
    .SYNOPSIS
    Disables trace logging
    #>
    [CmdletBinding()]
    param()
    
    $script:TraceLoggingEnabled = $false
    $script:TraceLoggingLevel = $null
    
    if ($script:DiagnosticTraceStream) {
        try {
            $script:DiagnosticTraceStream.WriteLine("# Trace Logging Session Ended: $(Get-Date)")
            $script:DiagnosticTraceStream.Close()
            $script:DiagnosticTraceStream.Dispose()
            $script:DiagnosticTraceStream = $null
        } catch {
            # Ignore cleanup errors
        }
    }
    
    Write-SystemStatusLog "Trace logging disabled" -Level 'INFO' -Source 'Trace'
}