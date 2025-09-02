function Get-UCEventCorrelation {
    <#
    .SYNOPSIS
    Correlates events across the Unity-Claude workflow
    
    .DESCRIPTION
    Finds all events with the same correlation ID or related to a specific workflow,
    providing a complete view of an operation across components
    
    .PARAMETER CorrelationId
    The correlation ID to search for
    
    .PARAMETER StartTime
    Start time for correlation search
    
    .PARAMETER EndTime
    End time for correlation search
    
    .PARAMETER Component
    Filter by specific component
    
    .PARAMETER IncludeRelated
    Include events that might be related but don't have the same correlation ID
    
    .EXAMPLE
    Get-UCEventCorrelation -CorrelationId $guid
    
    .EXAMPLE
    Get-UCEventCorrelation -StartTime (Get-Date).AddHours(-1) -Component Unity
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'ByCorrelationId')]
        [guid]$CorrelationId,
        
        [Parameter(ParameterSetName = 'ByTime')]
        [datetime]$StartTime,
        
        [Parameter(ParameterSetName = 'ByTime')]
        [datetime]$EndTime = (Get-Date),
        
        [Parameter()]
        [ValidateSet('Unity', 'Claude', 'Agent', 'Monitor', 'IPC', 'Dashboard', 'All')]
        [string]$Component = 'All',
        
        [Parameter()]
        [switch]$IncludeRelated
    )
    
    begin {
        Write-UCDebugLog "Get-UCEventCorrelation started - ParameterSet: $($PSCmdlet.ParameterSetName)"
    }
    
    process {
        try {
            $correlatedEvents = @()
            
            if ($PSCmdlet.ParameterSetName -eq 'ByCorrelationId') {
                # Search for events with matching correlation ID
                Write-UCDebugLog "Searching for events with CorrelationId: $CorrelationId"
                
                # Get all events and filter by correlation ID in message
                $allEvents = Get-UCEventLog -MaxEvents 1000 -Component $Component
                
                foreach ($event in $allEvents) {
                    if ($event.Message -match "Correlation ID:\s*$CorrelationId") {
                        $correlatedEvents += $event
                    }
                }
                
                Write-UCDebugLog "Found $($correlatedEvents.Count) events with correlation ID"
                
                if ($IncludeRelated -and $correlatedEvents.Count -gt 0) {
                    # Find related events based on time window
                    $firstEvent = $correlatedEvents | Sort-Object TimeCreated | Select-Object -First 1
                    $lastEvent = $correlatedEvents | Sort-Object TimeCreated -Descending | Select-Object -First 1
                    
                    $relatedStart = $firstEvent.TimeCreated.AddSeconds(-30)
                    $relatedEnd = $lastEvent.TimeCreated.AddSeconds(30)
                    
                    Write-UCDebugLog "Searching for related events between $relatedStart and $relatedEnd"
                    
                    $relatedEvents = Get-UCEventLog -StartTime $relatedStart -EndTime $relatedEnd -Component $Component
                    
                    foreach ($relEvent in $relatedEvents) {
                        if ($relEvent.Message -notmatch "Correlation ID:\s*$CorrelationId") {
                            # Add a property to indicate it's related but not directly correlated
                            $relEvent | Add-Member -NotePropertyName 'RelationType' -NotePropertyValue 'TimeProximity' -Force
                            $correlatedEvents += $relEvent
                        }
                    }
                }
            }
            else {
                # Search by time range
                Write-UCDebugLog "Searching for correlated events by time range"
                
                if (-not $StartTime) {
                    $StartTime = (Get-Date).AddHours(-1)
                }
                
                # Get events in time range
                $timeEvents = Get-UCEventLog -StartTime $StartTime -EndTime $EndTime -Component $Component
                
                # Group by correlation ID
                $correlationGroups = @{}
                $noCorrelation = @()
                
                foreach ($event in $timeEvents) {
                    if ($event.Message -match "Correlation ID:\s*([\w-]+)") {
                        $corrId = $Matches[1]
                        if (-not $correlationGroups.ContainsKey($corrId)) {
                            $correlationGroups[$corrId] = @()
                        }
                        $correlationGroups[$corrId] += $event
                    }
                    else {
                        $noCorrelation += $event
                    }
                }
                
                Write-UCDebugLog "Found $($correlationGroups.Count) correlation groups"
                
                # Return grouped events
                foreach ($corrId in $correlationGroups.Keys) {
                    $group = $correlationGroups[$corrId]
                    
                    # Create a correlation summary
                    $summary = [PSCustomObject]@{
                        CorrelationId = $corrId
                        EventCount = $group.Count
                        StartTime = ($group | Sort-Object TimeCreated | Select-Object -First 1).TimeCreated
                        EndTime = ($group | Sort-Object TimeCreated -Descending | Select-Object -First 1).TimeCreated
                        Duration = $null
                        Components = ($group | ForEach-Object { $_.Component } | Select-Object -Unique) -join ', '
                        Events = $group | Sort-Object TimeCreated
                    }
                    
                    $summary.Duration = ($summary.EndTime - $summary.StartTime).TotalSeconds
                    
                    $correlatedEvents += $summary
                }
                
                # Add uncorrelated events if requested
                if ($IncludeRelated -and $noCorrelation.Count -gt 0) {
                    $uncorrelatedSummary = [PSCustomObject]@{
                        CorrelationId = 'None'
                        EventCount = $noCorrelation.Count
                        StartTime = ($noCorrelation | Sort-Object TimeCreated | Select-Object -First 1).TimeCreated
                        EndTime = ($noCorrelation | Sort-Object TimeCreated -Descending | Select-Object -First 1).TimeCreated
                        Duration = $null
                        Components = ($noCorrelation | ForEach-Object { $_.Component } | Select-Object -Unique) -join ', '
                        Events = $noCorrelation | Sort-Object TimeCreated
                    }
                    
                    $uncorrelatedSummary.Duration = ($uncorrelatedSummary.EndTime - $uncorrelatedSummary.StartTime).TotalSeconds
                    
                    $correlatedEvents += $uncorrelatedSummary
                }
            }
            
            Write-UCDebugLog "Returning $($correlatedEvents.Count) correlated event groups"
            return $correlatedEvents
        }
        catch {
            Write-UCDebugLog "Get-UCEventCorrelation failed: $_" -Level 'ERROR'
            Write-Error $_
            return @()
        }
    }
    
    end {
        Write-UCDebugLog "Get-UCEventCorrelation completed"
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDvEjYvm+y+UisP
# 6htarCINPMKIpn7Yn4jomabmOUZYaaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIKfRldMxEx675BH59FmssD2e
# PTlsBy33/wahH6eCfeGVMA0GCSqGSIb3DQEBAQUABIIBAEUmSCX8CETb7jXdcQzz
# W3YlIBEi4k+yppCAaXWdB2ZuVk4dpocCWLGRGazqPhfsNlqrkgwKC0/11i45BSSR
# tCEf9nu9dyvcu3Chzc9cGZZpCq6qlB3xuyaPVC5lYYH3rxojD0ecrnIaBtoKalIg
# oewJJv+R7ZOX4zOiTObyPU5KKSuNjWo5lqdIKsiHpoUY+jH9q/5CJUOC2Unh8tl7
# 3gnlKL5SnVu/FKA+lYqLFWqwhyFupMAHsKB631JN7vnGOXSIFSwmFVTsUKuY5N6Y
# EPfxzT23IsWFXeYOAyJ8vZ/WUeSfWxQIGs29CU7b9KMUreKamPg4nMtamwfOSneV
# PrY=
# SIG # End signature block
