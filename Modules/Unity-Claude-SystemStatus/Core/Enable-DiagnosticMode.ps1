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
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBtQE1YDPrSnKlG
# LCqpZ4qdkxCIr+QbP7wWE1T9ABUCt6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCSqGSIb3DQEBCwUAMC4xLDAqBgNVBAMMI1VuaXR5LUNsYXVk
# ZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MB4XDTI1MDgyMDIxMTUxN1oXDTI2MDgy
# MDIxMzUxN1owLjEsMCoGA1UEAwwjVW5pdHktQ2xhdWRlLUF1dG9tYXRpb24tRGV2
# ZWxvcG1lbnQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCx4feqKdUQ
# 6GufY4umNzlM1Pi8aHUGR8HlfhIWFjsrRAxCxhieRlWbHe0Hw+pVBeX76X57e5Pu
# 4Kxxzu+MxMry0NJYf3yOLRTfhYskHBcLraXUCtrMwqnhPKvul6Sx6Lu8vilk605W
# ADJNifl3WFuexVCYJJM9G2mfuYIDN+rZ5zmpn0qCXum49bm629h+HyJ205Zrn9aB
# hIrA4i/JlrAh1kosWnCo62psl7ixbNVqFqwWEt+gAqSeIo4ChwkOQl7GHmk78Q5I
# oRneY4JTVlKzhdZEYhJGFXeoZml/5jcmUcox4UNYrKdokE7z8ZTmyowBOUNS+sHI
# G1TY5DZSb8vdAgMBAAGjRjBEMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggr
# BgEFBQcDAzAdBgNVHQ4EFgQUfDms7LrGVboHjmwlSyIjYD/JLQwwDQYJKoZIhvcN
# AQELBQADggEBABRMsfT7DzKy+aFi4HDg0MpxmbjQxOH1lzUzanaECRiyA0sn7+sA
# /4jvis1+qC5NjDGkLKOTCuDzIXnBWLCCBugukXbIO7g392ANqKdHjBHw1WlLvMVk
# 4WSmY096lzpvDd3jJApr/Alcp4KmRGNLnQ3vv+F9Uj58Uo1qjs85vt6fl9xe5lo3
# rFahNHL4ngjgyF8emNm7FItJeNtVe08PhFn0caOX0FTzXrZxGGO6Ov8tzf91j/qK
# QdBifG7Fx3FF7DifNqoBBo55a7q0anz30k8p+V0zllrLkgGXfOzXmA1L37Qmt3QB
# FCdJVigjQMuHcrJsWd8rg857Og0un91tfZIxggH0MIIB8AIBATBCMC4xLDAqBgNV
# BAMMI1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50AhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKA
# AKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIEWFUIo5CX9v9p9vcannA/g7
# L43L1Bsb8oItT3pJLAYVMA0GCSqGSIb3DQEBAQUABIIBACC6IkrKAz230dvwQJr7
# ArSY5Bh6APiKiLatddJGBLld/A1d492KiXrXFM7cFba25pX95nfimOQBVOS+gXni
# mdPyk7SvRTpjlGQw0lUkidoZp1PYLO7o/VJxCZB0blk2RJPUnnJWY/J2BQLWfiYS
# rzQFncpffEQnWUj23YDRUehwsABL/KR+RpGxOrMG56FkeAvXB5rUEacw9lTc8yut
# /3ErzIMA2/jhW9gT0FxbQ+xeve/N31Bw234/6+FXHkcv9HgQxd8z5q6J0O57Pj2W
# rSDaGPRWV6nRMbTwo02fvPqjiHm6Z42WDGbb50WpGRy06ewhGTlKC5WyKCW52WD7
# 2A8=
# SIG # End signature block
