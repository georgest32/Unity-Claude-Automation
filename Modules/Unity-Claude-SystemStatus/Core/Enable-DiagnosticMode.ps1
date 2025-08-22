function Enable-DiagnosticMode {
    <#
    .SYNOPSIS
    Enables diagnostic mode for comprehensive system troubleshooting
    
    .DESCRIPTION
    Configures enhanced diagnostic capabilities including:
    - Trace logging for execution flow analysis
    - Performance counter monitoring
    - Detailed debug output
    - PowerShell execution tracing
    - Structured logging with context preservation
    
    .PARAMETER Level
    Diagnostic level: Basic (standard debugging), Advanced (detailed tracing), Performance (metrics focus)
    
    .PARAMETER TraceFile
    Optional file to capture trace output (in addition to standard logging)
    
    .PARAMETER IncludePerformanceCounters
    Enable performance counter collection during diagnostic session
    
    .PARAMETER Duration
    Automatic timeout for diagnostic mode (default: no timeout)
    
    .EXAMPLE
    Enable-DiagnosticMode -Level Basic
    
    .EXAMPLE
    Enable-DiagnosticMode -Level Advanced -TraceFile ".\diagnostic_trace.log" -IncludePerformanceCounters
    
    .EXAMPLE
    Enable-DiagnosticMode -Level Performance -Duration (New-TimeSpan -Minutes 30)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Basic', 'Advanced', 'Performance')]
        [string]$Level,
        
        [string]$TraceFile,
        
        [switch]$IncludePerformanceCounters,
        
        [TimeSpan]$Duration
    )
    
    try {
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        
        Write-SystemStatusLog "Enabling diagnostic mode: $Level" -Level 'INFO' -Source 'DiagnosticMode'
        
        # Set script-scoped diagnostic variables
        $script:DiagnosticModeEnabled = $true
        $script:DiagnosticLevel = $Level
        $script:DiagnosticStartTime = Get-Date
        
        # Configure PowerShell preferences based on level
        switch ($Level) {
            'Basic' {
                $script:OriginalVerbosePreference = $VerbosePreference
                $script:OriginalDebugPreference = $DebugPreference
                $global:VerbosePreference = 'Continue'
                $global:DebugPreference = 'Continue'
                
                Write-SystemStatusLog "Basic diagnostic mode: Verbose and Debug output enabled" -Level 'DEBUG' -Source 'DiagnosticMode'
            }
            
            'Advanced' {
                $script:OriginalVerbosePreference = $VerbosePreference
                $script:OriginalDebugPreference = $DebugPreference
                $script:OriginalInformationPreference = $InformationPreference
                $global:VerbosePreference = 'Continue'
                $global:DebugPreference = 'Continue'
                $global:InformationPreference = 'Continue'
                
                # Enable PowerShell execution tracing
                $script:OriginalTraceLevel = $null
                try {
                    Set-PSDebug -Trace 1
                    Write-SystemStatusLog "Advanced diagnostic mode: PowerShell execution tracing enabled" -Level 'DEBUG' -Source 'DiagnosticMode'
                } catch {
                    Write-SystemStatusLog "Could not enable PowerShell tracing: $($_.Exception.Message)" -Level 'WARN' -Source 'DiagnosticMode'
                }
            }
            
            'Performance' {
                $script:OriginalVerbosePreference = $VerbosePreference
                $global:VerbosePreference = 'Continue'
                
                # Initialize performance monitoring
                $script:DiagnosticPerformanceCounters = @()
                $script:DiagnosticPerformanceData = @()
                
                Write-SystemStatusLog "Performance diagnostic mode: Metrics collection enabled" -Level 'DEBUG' -Source 'DiagnosticMode'
            }
        }
        
        # Setup trace file if specified
        if ($TraceFile) {
            try {
                $traceDir = Split-Path $TraceFile -Parent
                if ($traceDir -and -not (Test-Path $traceDir)) {
                    New-Item $traceDir -ItemType Directory -Force | Out-Null
                }
                
                $script:DiagnosticTraceFile = $TraceFile
                $script:DiagnosticTraceStream = [System.IO.StreamWriter]::new($TraceFile, $true)
                
                $script:DiagnosticTraceStream.WriteLine("# Diagnostic Trace Session Started: $(Get-Date)")
                $script:DiagnosticTraceStream.WriteLine("# Level: $Level")
                $script:DiagnosticTraceStream.Flush()
                
                Write-SystemStatusLog "Trace file initialized: $TraceFile" -Level 'DEBUG' -Source 'DiagnosticMode'
            } catch {
                Write-SystemStatusLog "Failed to initialize trace file: $($_.Exception.Message)" -Level 'ERROR' -Source 'DiagnosticMode'
                $script:DiagnosticTraceFile = $null
                $script:DiagnosticTraceStream = $null
            }
        }
        
        # Setup performance counter monitoring
        if ($IncludePerformanceCounters -or $Level -eq 'Performance') {
            try {
                Initialize-DiagnosticPerformanceMonitoring
                Write-SystemStatusLog "Performance counter monitoring initialized" -Level 'DEBUG' -Source 'DiagnosticMode'
            } catch {
                Write-SystemStatusLog "Failed to initialize performance monitoring: $($_.Exception.Message)" -Level 'WARN' -Source 'DiagnosticMode'
            }
        }
        
        # Setup automatic timeout if specified
        if ($Duration) {
            $script:DiagnosticTimeout = (Get-Date).Add($Duration)
            Write-SystemStatusLog "Diagnostic mode will timeout after $($Duration.TotalMinutes) minutes" -Level 'INFO' -Source 'DiagnosticMode'
            
            # Register a timer to disable diagnostic mode automatically
            Register-DiagnosticTimeout -Duration $Duration
        }
        
        # Store original configuration for restoration
        $script:DiagnosticConfiguration = @{
            Level = $Level
            TraceFile = $TraceFile
            IncludePerformanceCounters = $IncludePerformanceCounters
            StartTime = $script:DiagnosticStartTime
            Timeout = $script:DiagnosticTimeout
        }
        
        Write-SystemStatusLog "Diagnostic mode enabled successfully" -Level 'OK' -Source 'DiagnosticMode'
        
        # Write initial diagnostic information
        Write-DiagnosticSystemInfo
        
        return @{
            Success = $true
            Level = $Level
            StartTime = $script:DiagnosticStartTime
            TraceFile = $script:DiagnosticTraceFile
            PerformanceMonitoring = ($IncludePerformanceCounters -or $Level -eq 'Performance')
        }
        
    } catch {
        Write-SystemStatusLog "Failed to enable diagnostic mode: $($_.Exception.Message)" -Level 'ERROR' -Source 'DiagnosticMode'
        
        # Cleanup on failure
        try {
            Disable-DiagnosticMode -Force
        } catch {
            # Ignore cleanup errors
        }
        
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Disable-DiagnosticMode {
    <#
    .SYNOPSIS
    Disables diagnostic mode and restores normal operation
    
    .PARAMETER Force
    Force disable even if there are errors during cleanup
    
    .PARAMETER GenerateReport
    Generate a diagnostic report before disabling
    #>
    [CmdletBinding()]
    param(
        [switch]$Force,
        [switch]$GenerateReport
    )
    
    try {
        if (-not $script:DiagnosticModeEnabled) {
            Write-SystemStatusLog "Diagnostic mode is not currently enabled" -Level 'WARN' -Source 'DiagnosticMode'
            return
        }
        
        Write-SystemStatusLog "Disabling diagnostic mode" -Level 'INFO' -Source 'DiagnosticMode'
        
        $diagDuration = (Get-Date) - $script:DiagnosticStartTime
        
        # Generate report if requested
        if ($GenerateReport) {
            try {
                $reportPath = ".\SystemStatus_Diagnostic_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
                New-DiagnosticReport -OutputPath $reportPath
                Write-SystemStatusLog "Diagnostic report generated: $reportPath" -Level 'INFO' -Source 'DiagnosticMode'
            } catch {
                Write-SystemStatusLog "Failed to generate diagnostic report: $($_.Exception.Message)" -Level 'ERROR' -Source 'DiagnosticMode'
                if (-not $Force) { throw }
            }
        }
        
        # Restore PowerShell preferences
        try {
            if ($script:OriginalVerbosePreference) { $global:VerbosePreference = $script:OriginalVerbosePreference }
            if ($script:OriginalDebugPreference) { $global:DebugPreference = $script:OriginalDebugPreference }
            if ($script:OriginalInformationPreference) { $global:InformationPreference = $script:OriginalInformationPreference }
            
            # Disable PowerShell tracing if it was enabled
            if ($script:DiagnosticLevel -eq 'Advanced') {
                Set-PSDebug -Trace 0
            }
        } catch {
            Write-SystemStatusLog "Error restoring PowerShell preferences: $($_.Exception.Message)" -Level 'WARN' -Source 'DiagnosticMode'
            if (-not $Force) { throw }
        }
        
        # Close trace file
        if ($script:DiagnosticTraceStream) {
            try {
                $script:DiagnosticTraceStream.WriteLine("# Diagnostic Trace Session Ended: $(Get-Date)")
                $script:DiagnosticTraceStream.WriteLine("# Duration: $($diagDuration.TotalMinutes) minutes")
                $script:DiagnosticTraceStream.Close()
                $script:DiagnosticTraceStream.Dispose()
            } catch {
                Write-SystemStatusLog "Error closing trace file: $($_.Exception.Message)" -Level 'WARN' -Source 'DiagnosticMode'
                if (-not $Force) { throw }
            }
        }
        
        # Cleanup performance monitoring
        if ($script:DiagnosticPerformanceCounters) {
            try {
                Stop-DiagnosticPerformanceMonitoring
            } catch {
                Write-SystemStatusLog "Error stopping performance monitoring: $($_.Exception.Message)" -Level 'WARN' -Source 'DiagnosticMode'
                if (-not $Force) { throw }
            }
        }
        
        # Reset diagnostic variables
        $script:DiagnosticModeEnabled = $false
        $script:DiagnosticLevel = $null
        $script:DiagnosticStartTime = $null
        $script:DiagnosticTimeout = $null
        $script:DiagnosticTraceFile = $null
        $script:DiagnosticTraceStream = $null
        $script:DiagnosticConfiguration = $null
        
        Write-SystemStatusLog "Diagnostic mode disabled (duration: $([math]::Round($diagDuration.TotalMinutes, 1)) minutes)" -Level 'OK' -Source 'DiagnosticMode'
        
        return @{
            Success = $true
            Duration = $diagDuration
        }
        
    } catch {
        Write-SystemStatusLog "Failed to disable diagnostic mode: $($_.Exception.Message)" -Level 'ERROR' -Source 'DiagnosticMode'
        
        if ($Force) {
            Write-SystemStatusLog "Force disabling diagnostic mode" -Level 'WARN' -Source 'DiagnosticMode'
            $script:DiagnosticModeEnabled = $false
            return @{ Success = $true; Forced = $true }
        }
        
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Test-DiagnosticMode {
    <#
    .SYNOPSIS
    Checks if diagnostic mode is currently enabled and returns status
    #>
    [CmdletBinding()]
    param()
    
    $result = @{
        Enabled = [bool]$script:DiagnosticModeEnabled
        Level = $script:DiagnosticLevel
        StartTime = $script:DiagnosticStartTime
        Duration = $null
        TraceFile = $script:DiagnosticTraceFile
        TimeoutAt = $script:DiagnosticTimeout
        Configuration = $script:DiagnosticConfiguration
    }
    
    if ($script:DiagnosticStartTime) {
        $result.Duration = (Get-Date) - $script:DiagnosticStartTime
    }
    
    # Check for timeout
    if ($script:DiagnosticTimeout -and (Get-Date) -gt $script:DiagnosticTimeout) {
        Write-SystemStatusLog "Diagnostic mode timeout reached, disabling automatically" -Level 'INFO' -Source 'DiagnosticMode'
        Disable-DiagnosticMode
        $result.Enabled = $false
        $result.TimedOut = $true
    }
    
    return $result
}

function Write-DiagnosticSystemInfo {
    <#
    .SYNOPSIS
    Writes comprehensive system information to diagnostic logs
    #>
    [CmdletBinding()]
    param()
    
    try {
        $systemInfo = @{
            PowerShellVersion = $PSVersionTable.PSVersion.ToString()
            PowerShellEdition = $PSVersionTable.PSEdition
            OSVersion = [System.Environment]::OSVersion.ToString()
            MachineName = $env:COMPUTERNAME
            UserName = $env:USERNAME
            WorkingDirectory = (Get-Location).Path
            ProcessId = $PID
            SessionId = $Host.InstanceId
            MemoryUsage = [math]::Round((Get-Process -Id $PID).WorkingSet64 / 1MB, 1)
        }
        
        Write-SystemStatusLog "System Information" -Level 'INFO' -Source 'DiagnosticMode' -Context $systemInfo -StructuredLogging
        
        if ($script:DiagnosticTraceStream) {
            $script:DiagnosticTraceStream.WriteLine("# System Information:")
            foreach ($key in $systemInfo.Keys) {
                $script:DiagnosticTraceStream.WriteLine("# $key : $($systemInfo[$key])")
            }
            $script:DiagnosticTraceStream.Flush()
        }
        
    } catch {
        Write-SystemStatusLog "Failed to write system information: $($_.Exception.Message)" -Level 'WARN' -Source 'DiagnosticMode'
    }
}