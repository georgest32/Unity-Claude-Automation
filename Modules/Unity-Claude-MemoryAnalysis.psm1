# Unity-Claude-MemoryAnalysis.psm1
# PowerShell module for Unity memory analysis and autonomous cleanup integration
# Monitors memory data exported by Unity MemoryMonitor.cs and integrates with autonomous agent

$ErrorActionPreference = "Stop"

# Module configuration
$script:MemoryConfig = @{
    # File paths for Unity memory data
    MemoryReadingsPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\AutomationLogs\memory_readings.json"
    MemoryEventsPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\AutomationLogs\memory_events.json"
    MemoryStatusPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\AutomationLogs\memory_status.json"
    
    # Monitoring settings
    CheckIntervalSeconds = 30
    MemoryWarningThresholdMB = 500
    MemoryCriticalThresholdMB = 1000
    ObjectCountThreshold = 10000
    
    # Automation integration
    AutonomousResponsePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\ClaudeResponses\Autonomous"
    LogFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log"
}

function Start-UnityMemoryMonitoring {
    <#
    .SYNOPSIS
    Starts monitoring Unity memory usage patterns and integrates with autonomous agent system
    
    .DESCRIPTION
    Monitors memory data files exported by Unity MemoryMonitor.cs and triggers autonomous
    agent responses when memory thresholds are exceeded or cleanup is needed
    
    .PARAMETER ContinuousMode
    Run in continuous monitoring mode with FileSystemWatcher
    
    .EXAMPLE
    Start-UnityMemoryMonitoring -ContinuousMode
    #>
    [CmdletBinding()]
    param(
        [switch]$ContinuousMode
    )
    
    Write-Host "[MemoryAnalysis] Starting Unity memory monitoring integration..." -ForegroundColor Yellow
    Add-Content -Path $script:MemoryConfig.LogFile -Value "[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff'))] [INFO] [MemoryAnalysis] Starting Unity memory monitoring"
    
    # Ensure AutomationLogs directory exists
    $automationLogsDir = Split-Path $script:MemoryConfig.MemoryReadingsPath -Parent
    if (-not (Test-Path $automationLogsDir)) {
        New-Item -ItemType Directory -Path $automationLogsDir -Force | Out-Null
        Write-Host "[MemoryAnalysis] Created AutomationLogs directory: $automationLogsDir" -ForegroundColor Green
    }
    
    if ($ContinuousMode) {
        # Set up FileSystemWatcher for memory data files
        $watcher = New-Object System.IO.FileSystemWatcher
        $watcher.Path = $automationLogsDir
        $watcher.Filter = "memory_*.json"
        $watcher.EnableRaisingEvents = $true
        $watcher.IncludeSubdirectories = $false
        
        # Register event handlers
        Register-ObjectEvent -InputObject $watcher -EventName "Created" -Action {
            try {
                $filePath = $Event.SourceEventArgs.FullPath
                Write-Host "[MemoryAnalysis] Memory data file created: $(Split-Path $filePath -Leaf)" -ForegroundColor Cyan
                
                Start-Sleep -Milliseconds 100  # Brief delay to ensure file is written
                Process-MemoryDataFile -FilePath $filePath
            } catch {
                Add-Content -Path $using:MemoryConfig.LogFile -Value "[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff'))] [ERROR] [MemoryAnalysis] Error processing memory file: $_"
            }
        } | Out-Null
        
        Write-Host "[MemoryAnalysis] FileSystemWatcher monitoring started for $automationLogsDir" -ForegroundColor Green
        return $watcher
    } else {
        # Single check mode
        if (Test-Path $script:MemoryConfig.MemoryStatusPath) {
            Process-MemoryDataFile -FilePath $script:MemoryConfig.MemoryStatusPath
        } else {
            Write-Host "[MemoryAnalysis] No memory status file found - Unity MemoryMonitor may not be active" -ForegroundColor Yellow
        }
    }
}

function Process-MemoryDataFile {
    <#
    .SYNOPSIS
    Processes memory data files exported by Unity MemoryMonitor.cs
    
    .PARAMETER FilePath
    Path to the memory data JSON file
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    try {
        if (-not (Test-Path $FilePath)) {
            Write-Host "[MemoryAnalysis] Memory file not found: $FilePath" -ForegroundColor Yellow
            return
        }
        
        $memoryData = Get-Content $FilePath -Raw | ConvertFrom-Json
        Add-Content -Path $script:MemoryConfig.LogFile -Value "[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff'))] [DEBUG] [MemoryAnalysis] Processing memory data from $(Split-Path $FilePath -Leaf)"
        
        # Analyze memory data and determine if autonomous action needed
        $analysisResult = Analyze-MemoryData -MemoryData $memoryData
        
        if ($analysisResult.RequiresAction) {
            Write-Host "[MemoryAnalysis] Memory analysis requires action: $($analysisResult.ActionType)" -ForegroundColor Red
            Generate-AutonomousMemoryRecommendation -Analysis $analysisResult
        } else {
            Write-Host "[MemoryAnalysis] Memory status normal - Current: $($memoryData.currentMemoryMB)MB, Objects: $($memoryData.currentObjectCount)" -ForegroundColor Green
        }
    } catch {
        Write-Host "[MemoryAnalysis] Error processing memory data: $_" -ForegroundColor Red
        Add-Content -Path $script:MemoryConfig.LogFile -Value "[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff'))] [ERROR] [MemoryAnalysis] Error processing $FilePath - $_"
    }
}

function Analyze-MemoryData {
    <#
    .SYNOPSIS
    Analyzes Unity memory data and determines if cleanup action is needed
    
    .PARAMETER MemoryData
    Memory data object from Unity MemoryMonitor.cs
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSObject]$MemoryData
    )
    
    $analysis = @{
        RequiresAction = $false
        ActionType = "None"
        Priority = "Normal"
        Details = ""
        Recommendations = @()
    }
    
    # Check current memory usage
    if ($MemoryData.currentMemoryMB -gt $script:MemoryConfig.MemoryCriticalThresholdMB) {
        $analysis.RequiresAction = $true
        $analysis.ActionType = "CRITICAL_MEMORY_CLEANUP"
        $analysis.Priority = "Critical"
        $analysis.Details = "Memory usage $($MemoryData.currentMemoryMB)MB exceeds critical threshold"
        $analysis.Recommendations += "EditorUtility.UnloadUnusedAssetsImmediate()"
        $analysis.Recommendations += "System.GC.Collect()"
    } elseif ($MemoryData.currentMemoryMB -gt $script:MemoryConfig.MemoryWarningThresholdMB) {
        $analysis.RequiresAction = $true
        $analysis.ActionType = "MEMORY_WARNING"
        $analysis.Priority = "Warning"
        $analysis.Details = "Memory usage $($MemoryData.currentMemoryMB)MB exceeds warning threshold"
        $analysis.Recommendations += "Schedule cleanup during next idle period"
    }
    
    # Check object count
    if ($MemoryData.currentObjectCount -gt $script:MemoryConfig.ObjectCountThreshold) {
        $analysis.RequiresAction = $true
        $analysis.ActionType = "HIGH_OBJECT_COUNT"
        $analysis.Priority = "Warning"
        $analysis.Details = "Object count $($MemoryData.currentObjectCount) exceeds threshold"
        $analysis.Recommendations += "Resources.UnloadUnusedAssets()"
    }
    
    # Check memory trend
    if ($MemoryData.memoryTrend -gt 10) {  # Growing by >10MB per reading
        $analysis.RequiresAction = $true
        $analysis.ActionType = "MEMORY_LEAK_SUSPECTED"
        $analysis.Priority = "Warning"
        $analysis.Details = "Memory trend shows growth of $($MemoryData.memoryTrend)MB per reading"
        $analysis.Recommendations += "Investigate memory leak patterns"
        $analysis.Recommendations += "Take Memory Profiler snapshots for comparison"
    }
    
    Add-Content -Path $script:MemoryConfig.LogFile -Value "[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff'))] [DEBUG] [MemoryAnalysis] Analysis complete - Action required: $($analysis.RequiresAction), Type: $($analysis.ActionType)"
    
    return $analysis
}

function Generate-AutonomousMemoryRecommendation {
    <#
    .SYNOPSIS
    Generates autonomous agent recommendation based on memory analysis
    
    .PARAMETER Analysis
    Memory analysis result object
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Analysis
    )
    
    try {
        # Create autonomous agent recommendation file
        $recommendationFile = "$($script:MemoryConfig.AutonomousResponsePath)\memory_cleanup_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
        
        # Generate detailed recommendation based on analysis
        $prompt = switch ($Analysis.ActionType) {
            "CRITICAL_MEMORY_CLEANUP" {
                "CRITICAL: Unity memory usage critical ($($Analysis.Details)). Implement immediate memory cleanup using EditorUtility.UnloadUnusedAssetsImmediate() and System.GC.Collect(). Monitor cleanup effectiveness and adjust thresholds if needed."
            }
            "MEMORY_WARNING" {
                "Unity memory usage approaching limits ($($Analysis.Details)). Schedule memory cleanup during next safe opportunity. Review recent asset imports and consider optimizing asset usage patterns."
            }
            "HIGH_OBJECT_COUNT" {
                "High Unity object count detected ($($Analysis.Details)). Implement Resources.UnloadUnusedAssets() to clean up unreferenced objects. Investigate object creation patterns that may indicate memory leaks."
            }
            "MEMORY_LEAK_SUSPECTED" {
                "Potential memory leak detected ($($Analysis.Details)). Take Memory Profiler snapshots for comparison analysis. Investigate growing memory allocations and implement targeted cleanup routines."
            }
            default {
                "Unity memory analysis complete. Current status: $($Analysis.Details). Recommendations: $($Analysis.Recommendations -join ', ')"
            }
        }
        
        $recommendation = @{
            timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff')
            type = "MEMORY_ANALYSIS"
            priority = $Analysis.Priority
            action = $Analysis.ActionType
            details = $Analysis.Details
            recommendations = $Analysis.Recommendations
            response = "RECOMMENDATION: $prompt"
        }
        
        $recommendation | ConvertTo-Json -Depth 5 | Set-Content $recommendationFile -Encoding UTF8
        
        Write-Host "[MemoryAnalysis] Generated autonomous recommendation: $recommendationFile" -ForegroundColor Yellow
        Add-Content -Path $script:MemoryConfig.LogFile -Value "[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff'))] [INFO] [MemoryAnalysis] Generated autonomous recommendation for $($Analysis.ActionType)"
        
    } catch {
        Write-Host "[MemoryAnalysis] Error generating recommendation: $_" -ForegroundColor Red
        Add-Content -Path $script:MemoryConfig.LogFile -Value "[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff'))] [ERROR] [MemoryAnalysis] Failed to generate recommendation: $_"
    }
}

function Get-UnityMemoryStatus {
    <#
    .SYNOPSIS
    Gets current Unity memory status from monitoring data
    
    .DESCRIPTION
    Reads the latest memory status from Unity MemoryMonitor.cs exports
    and returns formatted memory information
    #>
    [CmdletBinding()]
    param()
    
    try {
        if (Test-Path $script:MemoryConfig.MemoryStatusPath) {
            $memoryStatus = Get-Content $script:MemoryConfig.MemoryStatusPath -Raw | ConvertFrom-Json
            
            $status = [PSCustomObject]@{
                Timestamp = $memoryStatus.timestamp
                CurrentMemoryMB = $memoryStatus.currentMemoryMB
                CurrentObjectCount = $memoryStatus.currentObjectCount
                MemoryTrend = $memoryStatus.memoryTrend
                IsHealthy = $memoryStatus.isMemoryHealthy
                LastCleanup = $memoryStatus.lastCleanup
                ReadingsCount = $memoryStatus.readingsCount
            }
            
            return $status
        } else {
            Write-Host "[MemoryAnalysis] No Unity memory status available" -ForegroundColor Yellow
            return $null
        }
    } catch {
        Write-Host "[MemoryAnalysis] Error reading Unity memory status: $_" -ForegroundColor Red
        return $null
    }
}

function Test-MemoryMonitoringSystem {
    <#
    .SYNOPSIS
    Tests the Unity memory monitoring system integration
    
    .DESCRIPTION
    Validates that Unity MemoryMonitor.cs is working and exporting data correctly
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "[MemoryAnalysis] Testing Unity memory monitoring system..." -ForegroundColor Cyan
    
    $results = @{
        MemoryReadingsAvailable = Test-Path $script:MemoryConfig.MemoryReadingsPath
        MemoryEventsAvailable = Test-Path $script:MemoryConfig.MemoryEventsPath
        MemoryStatusAvailable = Test-Path $script:MemoryConfig.MemoryStatusPath
        AutonomousPathExists = Test-Path $script:MemoryConfig.AutonomousResponsePath
    }
    
    $allSystemsReady = $results.Values | Where-Object { $_ -eq $false } | Measure-Object | Select-Object -ExpandProperty Count
    
    if ($allSystemsReady -eq 0) {
        Write-Host "[MemoryAnalysis] ✅ All memory monitoring systems ready" -ForegroundColor Green
        
        # Get current status if available
        $currentStatus = Get-UnityMemoryStatus
        if ($currentStatus) {
            Write-Host "[MemoryAnalysis] Current Memory: $($currentStatus.CurrentMemoryMB)MB, Objects: $($currentStatus.CurrentObjectCount)" -ForegroundColor Gray
        }
    } else {
        Write-Host "[MemoryAnalysis] ❌ Some systems not ready:" -ForegroundColor Red
        foreach ($key in $results.Keys) {
            $status = if ($results[$key]) { "✅" } else { "❌" }
            Write-Host "  $status $key" -ForegroundColor Gray
        }
    }
    
    return $results
}

# Module exports
Export-ModuleMember -Function @(
    'Start-UnityMemoryMonitoring',
    'Process-MemoryDataFile', 
    'Analyze-MemoryData',
    'Generate-AutonomousMemoryRecommendation',
    'Get-UnityMemoryStatus',
    'Test-MemoryMonitoringSystem'
)

Write-Host "[MemoryAnalysis] Unity-Claude-MemoryAnalysis module loaded successfully" -ForegroundColor Green
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUBBHvcmn9cRA2cU1dWvH1s2Hx
# OWygggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
# AQsFADAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0b21hdGlvbi1EZXZlbG9w
# bWVudDAeFw0yNTA4MjAyMTE1MTdaFw0yNjA4MjAyMTM1MTdaMC4xLDAqBgNVBAMM
# I1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEAseH3qinVEOhrn2OLpjc5TNT4vGh1BkfB5X4S
# FhY7K0QMQsYYnkZVmx3tB8PqVQXl++l+e3uT7uCscc7vjMTK8tDSWH98ji0U34WL
# JBwXC62l1ArazMKp4Tyr7peksei7vL4pZOtOVgAyTYn5d1hbnsVQmCSTPRtpn7mC
# Azfq2ec5qZ9Kgl7puPW5utvYfh8idtOWa5/WgYSKwOIvyZawIdZKLFpwqOtqbJe4
# sWzVahasFhLfoAKkniKOAocJDkJexh5pO/EOSKEZ3mOCU1ZSs4XWRGISRhV3qGZp
# f+Y3JlHKMeFDWKynaJBO8/GU5sqMATlDUvrByBtU2OQ2Um/L3QIDAQABo0YwRDAO
# BgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFHw5
# rOy6xlW6B45sJUsiI2A/yS0MMA0GCSqGSIb3DQEBCwUAA4IBAQAUTLH0+w8ysvmh
# YuBw4NDKcZm40MTh9Zc1M2p2hAkYsgNLJ+/rAP+I74rNfqguTYwxpCyjkwrg8yF5
# wViwggboLpF2yDu4N/dgDainR4wR8NVpS7zFZOFkpmNPepc6bw3d4yQKa/wJXKeC
# pkRjS50N77/hfVI+fFKNao7POb7en5fcXuZaN6xWoTRy+J4I4MhfHpjZuxSLSXjb
# VXtPD4RZ9HGjl9BU8162cRhjujr/Lc3/dY/6ikHQYnxuxcdxRew4nzaqAQaOeWu6
# tGp899JPKfldM5Zay5IBl3zs15gNS9+0Jrd0ARQnSVYoI0DLh3KybFnfK4POezoN
# Lp/dbX2SMYIB4zCCAd8CAQEwQjAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0
# b21hdGlvbi1EZXZlbG9wbWVudAIQdR0W2SKoK5VE8JId4ZxrRTAJBgUrDgMCGgUA
# oHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYB
# BAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0B
# CQQxFgQUgiWWuiVJ2f3dvCz/BBTK4Vc7oLswDQYJKoZIhvcNAQEBBQAEggEAR7/P
# zdJ3rOnwUjrIsQ4sqCuCZreFJd6sIF0LO6AUentsc13Z/6+oaCvSHBqqZ7W6CwQM
# 7M70mNyHlZ0bFCzPkC62NUGKEnP7WloUXcpLQgRBHc0Rptrd/fL3L/M8wTHMRayB
# 1bH2AUwr0NrF5R6cyTtc/XYzIabT8wU+9ezoaBGJeW2SCj4OiMNh1hnGXmYrNkgb
# yot6uefQdyARcaV0JcXAfqlhGCBZ5RHOheSidArtPyhAXxD2KkKpWgmqa7vYoUMr
# S3ioGJN5jKpZadsORw9RCcL7HB2nXcev02fKNBr2gJhXe12C8jR8Ko6loQOwpaiP
# wsH0zuPlNpuGjB5uVA==
# SIG # End signature block
