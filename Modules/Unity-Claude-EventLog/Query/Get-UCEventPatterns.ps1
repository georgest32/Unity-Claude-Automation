function Get-UCEventPatterns {
    <#
    .SYNOPSIS
    Analyzes event logs to identify patterns and recurring issues
    
    .DESCRIPTION
    Searches for patterns in Unity-Claude event logs such as recurring errors,
    performance degradation, or workflow bottlenecks
    
    .PARAMETER TimeRange
    Time range to analyze (in hours)
    
    .PARAMETER PatternType
    Type of pattern to search for
    
    .PARAMETER MinOccurrences
    Minimum number of occurrences to consider a pattern
    
    .PARAMETER Component
    Filter by specific component
    
    .EXAMPLE
    Get-UCEventPatterns -TimeRange 24 -PatternType RecurringErrors
    
    .EXAMPLE
    Get-UCEventPatterns -PatternType PerformanceDegradation -Component Unity
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]$TimeRange = 24,
        
        [Parameter()]
        [ValidateSet('RecurringErrors', 'PerformanceDegradation', 'WorkflowBottlenecks', 'FailureSequences', 'All')]
        [string]$PatternType = 'All',
        
        [Parameter()]
        [int]$MinOccurrences = 3,
        
        [Parameter()]
        [ValidateSet('Unity', 'Claude', 'Agent', 'Monitor', 'IPC', 'Dashboard', 'All')]
        [string]$Component = 'All'
    )
    
    begin {
        Write-UCDebugLog "Get-UCEventPatterns started - TimeRange: $TimeRange hours, PatternType: $PatternType"
        $patterns = @()
        $startTime = (Get-Date).AddHours(-$TimeRange)
    }
    
    process {
        try {
            # Get events in time range
            $events = Get-UCEventLog -StartTime $startTime -Component $Component -MaxEvents 5000
            
            if ($events.Count -eq 0) {
                Write-UCDebugLog "No events found in specified time range"
                return @()
            }
            
            Write-UCDebugLog "Analyzing $($events.Count) events for patterns"
            
            # Analyze recurring errors
            if ($PatternType -eq 'RecurringErrors' -or $PatternType -eq 'All') {
                Write-UCDebugLog "Analyzing recurring errors..."
                
                $errorEvents = $events | Where-Object { $_.Level -eq 'Error' }
                
                if ($errorEvents.Count -gt 0) {
                    # Group errors by message similarity
                    $errorGroups = @{}
                    
                    foreach ($error in $errorEvents) {
                        # Extract error signature (remove timestamps, IDs, etc.)
                        $signature = $error.Message -replace '\d{4}-\d{2}-\d{2}.*?\d{2}:\d{2}:\d{2}', 'TIMESTAMP'
                        $signature = $signature -replace '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}', 'GUID'
                        $signature = $signature -replace '\d+', 'NUM'
                        
                        # Truncate to first 100 chars for grouping
                        $key = $signature.Substring(0, [Math]::Min(100, $signature.Length))
                        
                        if (-not $errorGroups.ContainsKey($key)) {
                            $errorGroups[$key] = @()
                        }
                        $errorGroups[$key] += $error
                    }
                    
                    # Find patterns with minimum occurrences
                    foreach ($key in $errorGroups.Keys) {
                        if ($errorGroups[$key].Count -ge $MinOccurrences) {
                            $group = $errorGroups[$key]
                            $firstError = $group | Sort-Object TimeCreated | Select-Object -First 1
                            $lastError = $group | Sort-Object TimeCreated -Descending | Select-Object -First 1
                            
                            $pattern = [PSCustomObject]@{
                                Type = 'RecurringError'
                                Pattern = $key
                                Occurrences = $group.Count
                                FirstOccurrence = $firstError.TimeCreated
                                LastOccurrence = $lastError.TimeCreated
                                Frequency = if ($group.Count -gt 1) { 
                                    [math]::Round(($lastError.TimeCreated - $firstError.TimeCreated).TotalHours / ($group.Count - 1), 2)
                                } else { 0 }
                                Components = ($group | ForEach-Object { $_.Component } | Select-Object -Unique) -join ', '
                                SampleMessage = $firstError.Message
                                Events = $group
                            }
                            
                            $patterns += $pattern
                        }
                    }
                }
            }
            
            # Analyze performance degradation
            if ($PatternType -eq 'PerformanceDegradation' -or $PatternType -eq 'All') {
                Write-UCDebugLog "Analyzing performance degradation..."
                
                # Look for events with duration metrics (more flexible pattern)
                $perfEvents = $events | Where-Object { 
                    $_.Message -match 'Duration[:\s]*(\d+(?:\.\d+)?)\s*(ms|milliseconds?|seconds?|s\b)' -or
                    $_.Message -match '(\d+(?:\.\d+)?)\s*(ms|milliseconds?)\s+duration' -or
                    $_.Message -match 'took\s+(\d+(?:\.\d+)?)\s*(ms|milliseconds?|seconds?)' -or
                    $_.Message -match 'completed.*?(\d+(?:\.\d+)?)\s*(ms|milliseconds?|seconds?)'
                }
                
                if ($perfEvents.Count -gt 0) {
                    Write-UCDebugLog "Found $($perfEvents.Count) performance events to analyze"
                    
                    # Group by component and action
                    $perfGroups = @{}
                    
                    foreach ($perf in $perfEvents) {
                        # Use both Component and Action if available, otherwise just Component
                        $action = if ($perf.Action) { $perf.Action } else { "Unknown" }
                        $key = "$($perf.Component)_$action"
                        
                        if (-not $perfGroups.ContainsKey($key)) {
                            $perfGroups[$key] = @()
                        }
                        
                        # Extract duration with multiple patterns
                        $duration = $null
                        $unit = $null
                        
                        if ($perf.Message -match 'Duration[:\s]*(\d+(?:\.\d+)?)\s*(ms|milliseconds?|seconds?|s\b)') {
                            $duration = [double]$Matches[1]
                            $unit = $Matches[2]
                        }
                        elseif ($perf.Message -match '(\d+(?:\.\d+)?)\s*(ms|milliseconds?)\s+duration') {
                            $duration = [double]$Matches[1]
                            $unit = $Matches[2]
                        }
                        elseif ($perf.Message -match 'took\s+(\d+(?:\.\d+)?)\s*(ms|milliseconds?|seconds?)') {
                            $duration = [double]$Matches[1]
                            $unit = $Matches[2]
                        }
                        elseif ($perf.Message -match 'completed.*?(\d+(?:\.\d+)?)\s*(ms|milliseconds?|seconds?)') {
                            $duration = [double]$Matches[1]
                            $unit = $Matches[2]
                        }
                        
                        if ($duration) {
                            # Convert to milliseconds
                            if ($unit -match '^(second|seconds|s)$') {
                                $duration = $duration * 1000
                            }
                            
                            Write-UCDebugLog "Extracted duration: ${duration}ms from key: $key"
                            
                            $perfGroups[$key] += [PSCustomObject]@{
                                Time = $perf.TimeCreated
                                Duration = $duration
                                Event = $perf
                            }
                        }
                    }
                    
                    # Analyze trends
                    Write-UCDebugLog "Analyzing $($perfGroups.Keys.Count) performance groups"
                    
                    foreach ($key in $perfGroups.Keys) {
                        $group = $perfGroups[$key] | Sort-Object Time
                        
                        Write-UCDebugLog "Group '$key' has $($group.Count) events (min required: $MinOccurrences)"
                        
                        if ($group.Count -ge $MinOccurrences) {
                            # Calculate trend
                            $firstHalf = $group | Select-Object -First ([int]($group.Count / 2))
                            $secondHalf = $group | Select-Object -Last ([int]($group.Count / 2))
                            
                            $firstAvg = ($firstHalf | Measure-Object -Property Duration -Average).Average
                            $secondAvg = ($secondHalf | Measure-Object -Property Duration -Average).Average
                            
                            Write-UCDebugLog "First half avg: $([math]::Round($firstAvg, 2))ms, Second half avg: $([math]::Round($secondAvg, 2))ms"
                            
                            # Lower threshold to 15% for better detection
                            if ($secondAvg -gt ($firstAvg * 1.15)) {  # 15% degradation
                                $pattern = [PSCustomObject]@{
                                    Type = 'PerformanceDegradation'
                                    Pattern = $key
                                    Occurrences = $group.Count
                                    FirstOccurrence = $group[0].Time
                                    LastOccurrence = $group[-1].Time
                                    InitialAverage = [math]::Round($firstAvg, 2)
                                    CurrentAverage = [math]::Round($secondAvg, 2)
                                    DegradationPercent = [math]::Round((($secondAvg - $firstAvg) / $firstAvg) * 100, 2)
                                    MinDuration = [math]::Round(($group | Measure-Object -Property Duration -Minimum).Minimum, 2)
                                    MaxDuration = [math]::Round(($group | Measure-Object -Property Duration -Maximum).Maximum, 2)
                                    Events = $group | ForEach-Object { $_.Event }
                                }
                                
                                $patterns += $pattern
                            }
                        }
                    }
                }
            }
            
            # Analyze workflow bottlenecks
            if ($PatternType -eq 'WorkflowBottlenecks' -or $PatternType -eq 'All') {
                Write-UCDebugLog "Analyzing workflow bottlenecks..."
                
                # Look for correlation groups with long durations
                $correlations = Get-UCEventCorrelation -StartTime $startTime -Component $Component
                
                foreach ($corr in $correlations) {
                    if ($corr.Duration -and $corr.EventCount -ge $MinOccurrences) {
                        # Find the longest step in the workflow
                        $stepDurations = @()
                        $sortedEvents = $corr.Events | Sort-Object TimeCreated
                        
                        for ($i = 0; $i -lt ($sortedEvents.Count - 1); $i++) {
                            $stepDuration = ($sortedEvents[$i + 1].TimeCreated - $sortedEvents[$i].TimeCreated).TotalSeconds
                            
                            $stepDurations += [PSCustomObject]@{
                                From = $sortedEvents[$i]
                                To = $sortedEvents[$i + 1]
                                Duration = $stepDuration
                            }
                        }
                        
                        $longestStep = $stepDurations | Sort-Object Duration -Descending | Select-Object -First 1
                        
                        if ($longestStep -and $longestStep.Duration -gt 10) {  # Bottleneck if step takes >10 seconds
                            $pattern = [PSCustomObject]@{
                                Type = 'WorkflowBottleneck'
                                Pattern = "$($longestStep.From.Component) -> $($longestStep.To.Component)"
                                CorrelationId = $corr.CorrelationId
                                TotalDuration = [math]::Round($corr.Duration, 2)
                                BottleneckDuration = [math]::Round($longestStep.Duration, 2)
                                BottleneckPercent = [math]::Round(($longestStep.Duration / $corr.Duration) * 100, 2)
                                FromEvent = $longestStep.From
                                ToEvent = $longestStep.To
                                WorkflowEvents = $corr.Events
                            }
                            
                            $patterns += $pattern
                        }
                    }
                }
            }
            
            # Analyze failure sequences
            if ($PatternType -eq 'FailureSequences' -or $PatternType -eq 'All') {
                Write-UCDebugLog "Analyzing failure sequences..."
                
                # Look for errors followed by more errors
                $errorEvents = $events | Where-Object { $_.Level -in @('Error', 'Critical') } | Sort-Object TimeCreated
                
                $sequences = @()
                $currentSequence = @()
                $lastErrorTime = $null
                
                foreach ($error in $errorEvents) {
                    if ($lastErrorTime -and ($error.TimeCreated - $lastErrorTime).TotalMinutes -le 5) {
                        # Part of the same sequence
                        $currentSequence += $error
                    }
                    else {
                        # New sequence
                        if ($currentSequence.Count -ge $MinOccurrences) {
                            $sequences += @{
                                Events = $currentSequence
                            }
                        }
                        $currentSequence = @($error)
                    }
                    
                    $lastErrorTime = $error.TimeCreated
                }
                
                # Add last sequence
                if ($currentSequence.Count -ge $MinOccurrences) {
                    $sequences += @{
                        Events = $currentSequence
                    }
                }
                
                # Create patterns from sequences
                foreach ($seq in $sequences) {
                    $pattern = [PSCustomObject]@{
                        Type = 'FailureSequence'
                        Pattern = "Cascading failures"
                        ErrorCount = $seq.Events.Count
                        FirstError = $seq.Events[0].TimeCreated
                        LastError = $seq.Events[-1].TimeCreated
                        Duration = [math]::Round(($seq.Events[-1].TimeCreated - $seq.Events[0].TimeCreated).TotalMinutes, 2)
                        Components = ($seq.Events | ForEach-Object { $_.Component } | Select-Object -Unique) -join ', '
                        ErrorTypes = ($seq.Events | ForEach-Object { 
                            if ($_.Message -match '^([^:]+):') { $Matches[1] } else { 'Unknown' }
                        } | Select-Object -Unique) -join ', '
                        Events = $seq.Events
                    }
                    
                    $patterns += $pattern
                }
            }
            
            Write-UCDebugLog "Found $($patterns.Count) patterns"
            
            # Sort patterns by severity/importance
            $patterns = $patterns | Sort-Object -Property @(
                @{Expression = {$_.Type}; Ascending = $true},
                @{Expression = {$_.Occurrences}; Ascending = $false}
            )
            
            return $patterns
        }
        catch {
            Write-UCDebugLog "Get-UCEventPatterns failed: $_" -Level 'ERROR'
            Write-Error $_
            return @()
        }
    }
    
    end {
        Write-UCDebugLog "Get-UCEventPatterns completed"
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA4K5OMTdv/ITD4
# dugWUaGe4iVJ7dQNI4MubM3LqtZS06CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIAGq7IPpv4vjJchtu/lb/ocb
# YMwUFRr0B551WQoH2dzfMA0GCSqGSIb3DQEBAQUABIIBAI2PxurPN6GQ7DPQ61tA
# 8xZ9n6EYKYAbAGHeGngCVhZjisODGuBwkmlAc5vtBA1x9cLASQAnmpTgQmXpB76x
# kk32785urRzP3q3q5TowQ8/zDOA+ZI99cupLu1zbLqYnDQULyK8l939OvayxIjoF
# mHUtAVgl3QBJ+dQx+30jNavz9Sy057uEmsDk94KAaPSXbxRx702QGmlAWS6IBvA4
# pac1PljoiydJUe75E/pIWscb8N6OZ2BqkDCDD+qKqLUeZsOgl1nX2fHLuhuecg+5
# U0mQAIlYjNL9JMbbMvsj5T4EiZgUTNJlQIwtAEYRF3cHG820wZKsDXLSwtPvJjls
# Fqw=
# SIG # End signature block
