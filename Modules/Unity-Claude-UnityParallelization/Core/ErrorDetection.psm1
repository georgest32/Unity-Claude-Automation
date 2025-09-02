#Requires -Version 5.1
<#
.SYNOPSIS
    Unity error detection and classification for UnityParallelization module.

.DESCRIPTION
    Provides concurrent Unity error detection, classification, aggregation,
    and deduplication using FileSystemWatcher and runspace pools.

.NOTES
    Part of Unity-Claude-UnityParallelization refactored architecture
    Originally from Unity-Claude-UnityParallelization.psm1 (lines 1098-1677)
    Refactoring Date: 2025-08-25
#>

# Import required modules
Import-Module "$PSScriptRoot\ParallelizationCore.psm1" -Force
Import-Module "$PSScriptRoot\ProjectConfiguration.psm1" -Force

#region Concurrent Error Detection and Classification

function Start-ConcurrentErrorDetection {
    <#
    .SYNOPSIS
    Starts concurrent error detection across multiple Unity projects
    .DESCRIPTION
    Implements concurrent Unity error detection using FileSystemWatcher and log parsing with runspace pools
    .PARAMETER Monitor
    Unity monitor object
    .PARAMETER ErrorDetectionMode
    Type of error detection (RealTime, Batch, Both)
    .PARAMETER LatencyTargetMs
    Target latency for error detection in milliseconds
    .EXAMPLE
    Start-ConcurrentErrorDetection -Monitor $monitor -ErrorDetectionMode "RealTime" -LatencyTargetMs 500
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Monitor,
        [ValidateSet('RealTime', 'Batch', 'Both')]
        [string]$ErrorDetectionMode = 'RealTime',
        [int]$LatencyTargetMs = 500
    )
    
    $monitorName = $Monitor.MonitorName
    Write-UnityParallelLog -Message "Starting concurrent error detection for '$monitorName' in $ErrorDetectionMode mode..." -Level "INFO"
    
    try {
        foreach ($projectName in $Monitor.ProjectNames) {
            $projectConfig = Get-UnityProjectConfiguration -ProjectName $projectName
            
            # Real-time error detection using FileSystemWatcher
            if ($ErrorDetectionMode -eq 'RealTime' -or $ErrorDetectionMode -eq 'Both') {
                $realTimeDetectionScript = {
                    param([ref]$MonitoringState, $ProjectName, $ProjectPath, $LogPath, $ErrorPatterns, $LatencyTarget)
                    
                    try {
                        # Create FileSystemWatcher for C# files (research-validated pattern)
                        $watcher = New-Object System.IO.FileSystemWatcher
                        $watcher.Path = $ProjectPath
                        $watcher.Filter = "*.cs"
                        $watcher.IncludeSubdirectories = $true
                        $watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite
                        
                        $changeDetected = $false
                        $lastChangeTime = Get-Date
                        
                        # Register event handler (research: use flag-based approach for Unity thread safety)
                        $action = {
                            $global:changeDetected = $true
                            $global:lastChangeTime = Get-Date
                        }
                        
                        Register-ObjectEvent -InputObject $watcher -EventName "Changed" -Action $action | Out-Null
                        $watcher.EnableRaisingEvents = $true
                        
                        $startTime = Get-Date
                        $timeout = (Get-Date).AddMinutes(10) # 10 minute monitoring window
                        $errorsDetected = 0
                        
                        while ((Get-Date) -lt $timeout) {
                            # Check for file changes
                            if ($changeDetected) {
                                # Reset flag
                                $changeDetected = $false
                                
                                # Wait for file write completion
                                Start-Sleep -Milliseconds $LatencyTarget
                                
                                # Check Unity log for new errors
                                if (Test-Path $LogPath) {
                                    $logContent = Get-Content $LogPath -Tail 20 -ErrorAction SilentlyContinue
                                    
                                    if ($logContent) {
                                        foreach ($line in $logContent) {
                                            # Check against error patterns
                                            foreach ($patternName in $ErrorPatterns.Keys) {
                                                if ($line -match $ErrorPatterns[$patternName]) {
                                                    $errorEvent = @{
                                                        ProjectName = $ProjectName
                                                        ErrorType = $patternName
                                                        ErrorText = $line
                                                        Timestamp = Get-Date
                                                        DetectionLatency = [math]::Round(((Get-Date) - $lastChangeTime).TotalMilliseconds, 2)
                                                        SourceFile = "Unknown"
                                                    }
                                                    
                                                    $MonitoringState.Value.DetectedErrors.Add($errorEvent)
                                                    $errorsDetected++
                                                    break
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                            Start-Sleep -Milliseconds 100 # Fast polling for real-time detection
                        }
                        
                        # Cleanup
                        $watcher.EnableRaisingEvents = $false
                        $watcher.Dispose()
                        
                        return "Real-time error detection completed for $ProjectName : $errorsDetected errors detected"
                        
                    } catch {
                        return "Real-time error detection error for $ProjectName : $($_.Exception.Message)"
                    }
                }
                
                # Submit real-time detection job using reference parameter passing
                $ps = [powershell]::Create()
                $ps.RunspacePool = $Monitor.RunspacePool.RunspacePool
                $ps.AddScript($realTimeDetectionScript)
                $ps.AddArgument([ref]$Monitor.MonitoringState)
                $ps.AddArgument($projectName)
                $ps.AddArgument($projectConfig.Path)
                $ps.AddArgument($projectConfig.LogPath)
                $ps.AddArgument((Get-UnityParallelizationConfig).ErrorPatterns)
                $ps.AddArgument($LatencyTargetMs)
                
                $asyncResult = $ps.BeginInvoke()
                
                $detectionJob = @{
                    JobType = "RealTimeErrorDetection"
                    ProjectName = $projectName
                    PowerShell = $ps
                    AsyncResult = $asyncResult
                    StartTime = Get-Date
                    LatencyTarget = $LatencyTargetMs
                }
                
                $Monitor.ErrorDetectionJobs += $detectionJob
                
                Write-UnityParallelLog -Message "Started real-time error detection for project: $projectName (Target: ${LatencyTargetMs}ms)" -Level "DEBUG"
            }
        }
        
        Write-UnityParallelLog -Message "Concurrent error detection started for '$monitorName' - $($Monitor.ProjectNames.Count) projects" -Level "INFO"
        
        return @{
            Success = $true
            ErrorDetectionJobs = $Monitor.ErrorDetectionJobs.Count
            ProjectsMonitored = $Monitor.ProjectNames.Count
            LatencyTarget = $LatencyTargetMs
        }
        
    } catch {
        Write-UnityParallelLog -Message "Failed to start concurrent error detection for '$monitorName': $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Classify-UnityCompilationError {
    <#
    .SYNOPSIS
    Classifies Unity compilation errors using existing patterns
    .DESCRIPTION
    Classifies Unity errors using research-validated error patterns and existing database
    .PARAMETER ErrorText
    Unity error text to classify
    .PARAMETER ProjectName
    Name of the Unity project where error occurred
    .EXAMPLE
    $classification = Classify-UnityCompilationError -ErrorText "CS0246: The type or namespace name 'TestClass' could not be found" -ProjectName "MyGame"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ErrorText,
        [Parameter(Mandatory)]
        [string]$ProjectName
    )
    
    try {
        $classification = @{
            ErrorText = $ErrorText
            ProjectName = $ProjectName
            ErrorType = "Unknown"
            ErrorCode = ""
            Severity = "Unknown"
            Category = "Unknown"
            Confidence = 0.0
            ClassifiedTime = Get-Date
        }
        
        # Classify using existing error patterns
        $errorPatterns = (Get-UnityParallelizationConfig).ErrorPatterns
        
        foreach ($patternName in $errorPatterns.Keys) {
            if ($ErrorText -match $errorPatterns[$patternName]) {
                $classification.ErrorType = $patternName
                $classification.Confidence = 0.9
                
                # Extract error code if present
                if ($ErrorText -match '(CS\d{4})') {
                    $classification.ErrorCode = $matches[1]
                }
                
                # Determine severity and category based on error type
                switch ($patternName) {
                    "CS0246" {
                        $classification.Severity = "High"
                        $classification.Category = "MissingReference"
                    }
                    "CS0103" {
                        $classification.Severity = "High" 
                        $classification.Category = "UndefinedVariable"
                    }
                    "CS1061" {
                        $classification.Severity = "Medium"
                        $classification.Category = "MissingMember"
                    }
                    "CS0029" {
                        $classification.Severity = "Medium"
                        $classification.Category = "TypeConversion"
                    }
                    "CompilationError" {
                        $classification.Severity = "High"
                        $classification.Category = "Compilation"
                    }
                    default {
                        $classification.Severity = "Unknown"
                        $classification.Category = "General"
                    }
                }
                
                break
            }
        }
        
        Write-UnityParallelLog -Message "Unity error classified: $($classification.ErrorType) ($($classification.ErrorCode)) - Confidence: $($classification.Confidence)" -Level "DEBUG"
        
        return $classification
        
    } catch {
        Write-UnityParallelLog -Message "Failed to classify Unity error: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Aggregate-UnityErrors {
    <#
    .SYNOPSIS
    Aggregates Unity errors from multiple projects
    .DESCRIPTION
    Aggregates and consolidates Unity errors from concurrent monitoring across projects
    .PARAMETER Monitor
    Unity monitor object containing detected errors
    .PARAMETER AggregationMode
    Type of aggregation (ByProject, ByErrorType, ByTime, All)
    .EXAMPLE
    $aggregatedErrors = Aggregate-UnityErrors -Monitor $monitor -AggregationMode "ByErrorType"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Monitor,
        [ValidateSet('ByProject', 'ByErrorType', 'ByTime', 'All')]
        [string]$AggregationMode = 'All'
    )
    
    $monitorName = $Monitor.MonitorName
    Write-UnityParallelLog -Message "Aggregating Unity errors for '$monitorName' using $AggregationMode mode..." -Level "INFO"
    
    try {
        $detectedErrors = $Monitor.MonitoringState.DetectedErrors
        
        if ($detectedErrors.Count -eq 0) {
            Write-UnityParallelLog -Message "No errors detected to aggregate" -Level "DEBUG"
            return @{
                TotalErrors = 0
                AggregationMode = $AggregationMode
                Aggregations = @{}
                ProcessedTime = Get-Date
            }
        }
        
        $aggregationResults = @{
            TotalErrors = $detectedErrors.Count
            AggregationMode = $AggregationMode
            Aggregations = @{}
            ProcessedTime = Get-Date
        }
        
        # Perform aggregation based on mode
        switch ($AggregationMode) {
            "ByProject" {
                $projectGroups = @{}
                foreach ($error in $detectedErrors) {
                    $projectName = $error.ProjectName
                    if (-not $projectGroups.ContainsKey($projectName)) {
                        $projectGroups[$projectName] = @()
                    }
                    $projectGroups[$projectName] += $error
                }
                $aggregationResults.Aggregations = $projectGroups
            }
            
            "ByErrorType" {
                $typeGroups = @{}
                foreach ($error in $detectedErrors) {
                    $classification = Classify-UnityCompilationError -ErrorText $error.ErrorText -ProjectName $error.ProjectName
                    $errorType = $classification.ErrorType
                    
                    if (-not $typeGroups.ContainsKey($errorType)) {
                        $typeGroups[$errorType] = @()
                    }
                    $typeGroups[$errorType] += $error
                }
                $aggregationResults.Aggregations = $typeGroups
            }
            
            "ByTime" {
                # Group by hour
                $timeGroups = @{}
                foreach ($error in $detectedErrors) {
                    $hourKey = $error.Timestamp.ToString("yyyy-MM-dd HH:00")
                    if (-not $timeGroups.ContainsKey($hourKey)) {
                        $timeGroups[$hourKey] = @()
                    }
                    $timeGroups[$hourKey] += $error
                }
                $aggregationResults.Aggregations = $timeGroups
            }
            
            "All" {
                # Include all aggregation types
                $aggregationResults.Aggregations = @{
                    ByProject = @{}
                    ByErrorType = @{}
                    ByTime = @{}
                }
                
                # Project aggregation
                foreach ($error in $detectedErrors) {
                    $projectName = $error.ProjectName
                    if (-not $aggregationResults.Aggregations.ByProject.ContainsKey($projectName)) {
                        $aggregationResults.Aggregations.ByProject[$projectName] = @()
                    }
                    $aggregationResults.Aggregations.ByProject[$projectName] += $error
                }
                
                # Error type aggregation
                foreach ($error in $detectedErrors) {
                    $classification = Classify-UnityCompilationError -ErrorText $error.ErrorText -ProjectName $error.ProjectName
                    $errorType = $classification.ErrorType
                    
                    if (-not $aggregationResults.Aggregations.ByErrorType.ContainsKey($errorType)) {
                        $aggregationResults.Aggregations.ByErrorType[$errorType] = @()
                    }
                    $aggregationResults.Aggregations.ByErrorType[$errorType] += $error
                }
            }
        }
        
        Write-UnityParallelLog -Message "Unity error aggregation completed: $($detectedErrors.Count) errors aggregated using $AggregationMode mode" -Level "INFO"
        
        return $aggregationResults
        
    } catch {
        Write-UnityParallelLog -Message "Failed to aggregate Unity errors for '$monitorName': $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Deduplicate-UnityErrors {
    <#
    .SYNOPSIS
    Deduplicates Unity errors across projects
    .DESCRIPTION
    Removes duplicate Unity errors based on error text, type, and timing patterns
    .PARAMETER AggregatedErrors
    Aggregated errors from Aggregate-UnityErrors
    .PARAMETER DeduplicationMode
    Type of deduplication (Exact, Similar, Time)
    .PARAMETER SimilarityThreshold
    Threshold for similar error detection (0.0-1.0)
    .EXAMPLE
    $deduplicated = Deduplicate-UnityErrors -AggregatedErrors $aggregated -DeduplicationMode "Similar" -SimilarityThreshold 0.8
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$AggregatedErrors,
        [ValidateSet('Exact', 'Similar', 'Time')]
        [string]$DeduplicationMode = 'Similar',
        [double]$SimilarityThreshold = 0.8
    )
    
    Write-UnityParallelLog -Message "Deduplicating Unity errors using $DeduplicationMode mode..." -Level "INFO"
    
    try {
        $allErrors = @()
        
        # Extract all errors from aggregation
        if ($AggregatedErrors.Aggregations -is [hashtable]) {
            foreach ($groupKey in $AggregatedErrors.Aggregations.Keys) {
                $group = $AggregatedErrors.Aggregations[$groupKey]
                if ($group -is [array]) {
                    $allErrors += $group
                } elseif ($group -is [hashtable]) {
                    foreach ($subGroupKey in $group.Keys) {
                        $allErrors += $group[$subGroupKey]
                    }
                }
            }
        }
        
        Write-UnityParallelLog -Message "Processing $($allErrors.Count) errors for deduplication..." -Level "DEBUG"
        
        $uniqueErrors = @()
        $duplicatesRemoved = 0
        
        foreach ($error in $allErrors) {
            $isDuplicate = $false
            
            switch ($DeduplicationMode) {
                "Exact" {
                    # Exact text match
                    $isDuplicate = $uniqueErrors | Where-Object { $_.ErrorText -eq $error.ErrorText }
                }
                "Similar" {
                    # Similar text match (simple approach)
                    foreach ($existingError in $uniqueErrors) {
                        $similarity = Get-StringSimilarity -String1 $error.ErrorText -String2 $existingError.ErrorText
                        if ($similarity -ge $SimilarityThreshold) {
                            $isDuplicate = $true
                            break
                        }
                    }
                }
                "Time" {
                    # Same error within 30 seconds
                    $isDuplicate = $uniqueErrors | Where-Object { 
                        $_.ErrorText -eq $error.ErrorText -and 
                        [math]::Abs(($_.Timestamp - $error.Timestamp).TotalSeconds) -lt 30 
                    }
                }
            }
            
            if (-not $isDuplicate) {
                $uniqueErrors += $error
            } else {
                $duplicatesRemoved++
            }
        }
        
        $deduplicationResults = @{
            OriginalCount = $allErrors.Count
            UniqueCount = $uniqueErrors.Count
            DuplicatesRemoved = $duplicatesRemoved
            DeduplicationMode = $DeduplicationMode
            SimilarityThreshold = $SimilarityThreshold
            UniqueErrors = $uniqueErrors
            ProcessedTime = Get-Date
        }
        
        Write-UnityParallelLog -Message "Unity error deduplication completed: $($allErrors.Count) -> $($uniqueErrors.Count) errors ($duplicatesRemoved duplicates removed)" -Level "INFO"
        
        return $deduplicationResults
        
    } catch {
        Write-UnityParallelLog -Message "Failed to deduplicate Unity errors: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Get-UnityErrorStatistics {
    <#
    .SYNOPSIS
    Gets Unity error statistics from monitoring
    .DESCRIPTION
    Provides statistical analysis of detected Unity errors across projects
    .PARAMETER Monitor
    Unity monitor object
    .PARAMETER IncludeBreakdown
    Include detailed breakdown by project and error type
    .EXAMPLE
    $stats = Get-UnityErrorStatistics -Monitor $monitor -IncludeBreakdown
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Monitor,
        [switch]$IncludeBreakdown
    )
    
    $monitorName = $Monitor.MonitorName
    
    try {
        $detectedErrors = $Monitor.MonitoringState.DetectedErrors
        
        $statistics = @{
            MonitorName = $monitorName
            TotalErrors = $detectedErrors.Count
            ProjectsMonitored = $Monitor.ProjectNames.Count
            MonitoringDuration = 0
            ErrorsPerProject = @{}
            ErrorsByType = @{}
            AverageDetectionLatency = 0
            GeneratedTime = Get-Date
        }
        
        # Calculate monitoring duration
        if ($Monitor.StartTime) {
            $statistics.MonitoringDuration = [math]::Round(((Get-Date) - $Monitor.StartTime).TotalMinutes, 2)
        }
        
        # Process errors for statistics
        if ($detectedErrors.Count -gt 0) {
            # Errors per project
            foreach ($error in $detectedErrors) {
                $projectName = $error.ProjectName
                if (-not $statistics.ErrorsPerProject.ContainsKey($projectName)) {
                    $statistics.ErrorsPerProject[$projectName] = 0
                }
                $statistics.ErrorsPerProject[$projectName]++
            }
            
            # Errors by type
            foreach ($error in $detectedErrors) {
                $classification = Classify-UnityCompilationError -ErrorText $error.ErrorText -ProjectName $error.ProjectName
                $errorType = $classification.ErrorType
                
                if (-not $statistics.ErrorsByType.ContainsKey($errorType)) {
                    $statistics.ErrorsByType[$errorType] = 0
                }
                $statistics.ErrorsByType[$errorType]++
            }
            
            # Average detection latency
            $latencies = $detectedErrors | Where-Object { $_.DetectionLatency -ne $null } | ForEach-Object { $_.DetectionLatency }
            if ($latencies.Count -gt 0) {
                $totalLatency = 0
                foreach ($latency in $latencies) {
                    $totalLatency += $latency
                }
                $statistics.AverageDetectionLatency = [math]::Round($totalLatency / $latencies.Count, 2)
            }
        }
        
        # Include detailed breakdown if requested
        if ($IncludeBreakdown) {
            $statistics.DetailedBreakdown = @{
                ErrorsByProject = @{}
                ErrorsByTypePerProject = @{}
            }
            
            foreach ($projectName in $Monitor.ProjectNames) {
                $projectErrors = $detectedErrors | Where-Object { $_.ProjectName -eq $projectName }
                $statistics.DetailedBreakdown.ErrorsByProject[$projectName] = $projectErrors
                
                $statistics.DetailedBreakdown.ErrorsByTypePerProject[$projectName] = @{}
                foreach ($error in $projectErrors) {
                    $classification = Classify-UnityCompilationError -ErrorText $error.ErrorText -ProjectName $error.ProjectName
                    $errorType = $classification.ErrorType
                    
                    if (-not $statistics.DetailedBreakdown.ErrorsByTypePerProject[$projectName].ContainsKey($errorType)) {
                        $statistics.DetailedBreakdown.ErrorsByTypePerProject[$projectName][$errorType] = 0
                    }
                    $statistics.DetailedBreakdown.ErrorsByTypePerProject[$projectName][$errorType]++
                }
            }
        }
        
        Write-UnityParallelLog -Message "Unity error statistics generated: $($statistics.TotalErrors) errors across $($statistics.ProjectsMonitored) projects" -Level "INFO"
        
        return $statistics
        
    } catch {
        Write-UnityParallelLog -Message "Failed to get Unity error statistics for '$monitorName': $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

# Helper function for string similarity
function Get-StringSimilarity {
    param(
        [string]$String1,
        [string]$String2
    )
    
    # Simple character match ratio
    if ($String1.Length -eq 0 -or $String2.Length -eq 0) {
        return 0.0
    }
    
    $matches = 0
    $minLength = [math]::Min($String1.Length, $String2.Length)
    $maxLength = [math]::Max($String1.Length, $String2.Length)
    
    for ($i = 0; $i -lt $minLength; $i++) {
        if ($String1[$i] -eq $String2[$i]) {
            $matches++
        }
    }
    
    return [double]($matches / $maxLength)
}

#endregion

#region Module Exports

Export-ModuleMember -Function @(
    'Start-ConcurrentErrorDetection',
    'Classify-UnityCompilationError',
    'Aggregate-UnityErrors',
    'Deduplicate-UnityErrors',
    'Get-UnityErrorStatistics',
    'Get-StringSimilarity'
)

#endregion

# REFACTORING MARKER: This module was refactored from Unity-Claude-UnityParallelization.psm1 on 2025-08-25
# Original file size: 2084 lines
# This component: Unity error detection and classification (lines 1098-1677, ~580 lines)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAO9xWVyyCfB6Rw
# pRh1Oy4Cjt8NBPl1EG/txoOE1oIdUKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIL+VwFjdHjRFEOalmS8QK2Lx
# cCIfcQs6Ny3tmVnEZVZ9MA0GCSqGSIb3DQEBAQUABIIBAATnL+4d7YvUxKaf82Zm
# VZHH2j7u8nRXOLZVFUSE6n5VM01SozVS+/gI+ba4NpdCimz86JwSFuh1dxhJfC33
# YVCjAUk/8PM3w4nEZEncmKPSOIWGb8G4Zj+aOadYQgnbRKZrTSzNWEuIRzjSyFsC
# lBkieMztsHt2ijJyVBTMiSa2rcREgT9/tc7xqonwJIiVuwJzmX57n4OMVE9afHA2
# kMAUG/JZz5YI3uKOE/rSgIAMje+p+f+CX2nT1vfb/eSrFmd/WZSuhvyEuvhZauml
# SdFct0kK8H3A2spTKjt/7EY/nLvSpxn1jityNSFLof248B4EE0UEnG1W4MwJzLvM
# BcE=
# SIG # End signature block
