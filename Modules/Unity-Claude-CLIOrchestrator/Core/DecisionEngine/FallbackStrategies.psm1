# FallbackStrategies.psm1
# Conflict resolution and graceful degradation for DecisionEngine
# Part of Unity-Claude-CLIOrchestrator refactored architecture
# Date: 2025-08-25

#region Fallback Strategies

# Handle ambiguous or conflicting recommendations
function Resolve-ConflictingRecommendations {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$ConflictingRecommendations,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$ConfidenceAnalysis
    )
    
    Write-DecisionLog "Resolving conflicts between $($ConflictingRecommendations.Count) recommendations" "WARN"
    
    # Get configuration
    $decisionConfig = Get-DecisionEngineConfiguration
    
    # Strategy 1: Use priority matrix
    $prioritized = $ConflictingRecommendations | ForEach-Object {
        $matrixEntry = $decisionConfig.DecisionMatrix[$_.Type]
        $_ | Add-Member -NotePropertyName 'MatrixPriority' -NotePropertyValue ($matrixEntry?.Priority ?? 10) -PassThru
    } | Sort-Object MatrixPriority, @{Expression = {$_.Confidence}; Descending = $true}
    
    # Strategy 2: If priorities are equal, use confidence
    $selected = $prioritized[0]
    
    # Strategy 3: If confidence is low, default to safe action
    if ($selected.Confidence -lt 0.6) {
        Write-DecisionLog "Low confidence in conflict resolution - defaulting to CONTINUE" "WARN"
        return @{
            RecommendationType = "CONTINUE"
            Action = "Continue due to conflict resolution uncertainty"
            Priority = 1
            SafetyLevel = "Low"
            Reason = "Conflict resolution with low confidence - defaulting to safe action"
            ConflictResolutionStrategy = "SafeDefault"
        }
    }
    
    Write-DecisionLog "Conflict resolved: Selected $($selected.Type) with confidence $($selected.Confidence)" "INFO"
    
    return @{
        RecommendationType = $selected.Type
        Action = $selected.Action
        Priority = $selected.MatrixPriority
        SafetyLevel = $decisionConfig.DecisionMatrix[$selected.Type]?.SafetyLevel ?? "Unknown"
        Confidence = $selected.Confidence
        Reason = "Conflict resolved using priority matrix and confidence scoring"
        ConflictResolutionStrategy = "PriorityMatrix"
        AlternativeRecommendations = if ($prioritized.Count -gt 1) { 
            $alternatives = @()
            for ($i = 1; $i -lt $prioritized.Count; $i++) { $alternatives += $prioritized[$i] }
            $alternatives
        } else { @() }
    }
}

# Graceful degradation for low-confidence scenarios
function Invoke-GracefulDegradation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$AnalysisResult,
        
        [Parameter()]
        [string]$DegradationReason = "Low confidence analysis"
    )
    
    Write-DecisionLog "Invoking graceful degradation: $DegradationReason" "WARN"
    
    # Analyze what we can safely do
    $safeActions = @("CONTINUE", "COMPLETE", "ERROR")
    $confidence = $AnalysisResult.ConfidenceAnalysis?.OverallConfidence ?? 0.0
    
    # Select safest action based on context
    $degradedAction = if ($confidence -lt 0.3) {
        @{
            RecommendationType = "ERROR"
            Action = "Request clarification due to low confidence analysis"
            Priority = 7
            SafetyLevel = "Low"
            Reason = "Confidence too low for autonomous decision-making ($confidence)"
        }
    } elseif ($AnalysisResult.Classification?.Category -eq "Complete") {
        @{
            RecommendationType = "COMPLETE"
            Action = "Mark task as complete based on context analysis"
            Priority = 6
            SafetyLevel = "Low"
            Reason = "Task appears complete despite analysis uncertainty"
        }
    } else {
        @{
            RecommendationType = "CONTINUE"
            Action = "Continue processing with manual review recommendation"
            Priority = 1
            SafetyLevel = "Low"
            Reason = "Safe continuation while seeking human guidance"
        }
    }
    
    $degradedAction.DegradationApplied = $true
    $degradedAction.OriginalAnalysis = $AnalysisResult
    $degradedAction.DegradationReason = $DegradationReason
    
    Write-DecisionLog "Graceful degradation applied: $($degradedAction.RecommendationType)" "INFO"
    
    return $degradedAction
}

# Advanced decision conflict analysis
function Get-ConflictAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Recommendations
    )
    
    if ($Recommendations.Count -lt 2) {
        return @{
            HasConflicts = $false
            ConflictCount = 0
            Reason = "Insufficient recommendations for conflict analysis"
        }
    }
    
    # Get configuration
    $decisionConfig = Get-DecisionEngineConfiguration
    
    # Analyze for conflicts
    $priorities = @()
    $safetyLevels = @()
    $actionTypes = @()
    
    foreach ($rec in $Recommendations) {
        $matrixEntry = $decisionConfig.DecisionMatrix[$rec.Type]
        if ($matrixEntry) {
            $priorities += $matrixEntry.Priority
            $safetyLevels += $matrixEntry.SafetyLevel
            $actionTypes += $matrixEntry.ActionType
        }
    }
    
    # Check for conflicts
    $uniquePriorities = $priorities | Select-Object -Unique
    $uniqueSafetyLevels = $safetyLevels | Select-Object -Unique
    $uniqueActionTypes = $actionTypes | Select-Object -Unique
    
    $hasConflicts = $uniquePriorities.Count -gt 1 -or 
                    $uniqueSafetyLevels.Count -gt 1 -or 
                    $uniqueActionTypes.Count -gt 1
    
    return @{
        HasConflicts = $hasConflicts
        ConflictCount = if ($hasConflicts) { $Recommendations.Count } else { 0 }
        PriorityConflict = $uniquePriorities.Count -gt 1
        SafetyLevelConflict = $uniqueSafetyLevels.Count -gt 1
        ActionTypeConflict = $uniqueActionTypes.Count -gt 1
        RecommendationTypes = @($Recommendations | ForEach-Object { $_.Type })
        Priorities = $priorities
        SafetyLevels = $safetyLevels
        ActionTypes = $actionTypes
    }
}

# Emergency fallback decision
function Get-EmergencyFallback {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Reason = "Emergency fallback triggered"
    )
    
    Write-DecisionLog "Emergency fallback activated: $Reason" "ERROR"
    
    return @{
        RecommendationType = "ERROR"
        Action = "Emergency stop - manual intervention required"
        Priority = 7
        SafetyLevel = "Critical"
        Reason = $Reason
        EmergencyFallback = $true
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Resolve-ConflictingRecommendations',
    'Invoke-GracefulDegradation',
    'Get-ConflictAnalysis',
    'Get-EmergencyFallback'
)

#endregion
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAhxYHCB44QXx46
# +WkdF7gq1QbQtS4DfB1TYiA3dh31+6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIAPGDsOczJD1dRvMtvKfRF8i
# hojeCB7+3e+IJ2ZTt3m2MA0GCSqGSIb3DQEBAQUABIIBAIPeyg4382sHFvv/XjYb
# 3xfivBE9A9jhdGb06T7vTGGzn39DXjbLlsMqFAL7yAv5xTC/BQ4C662snIhfX73h
# ZAWD6oI1M7KFxxgOkXk33COlLPTFayAjrF3OpEjT/CCYoomQNLjcNqKqofJL3JP2
# gCn4/EjljjJHmfTTr24LD7XA5BfZDFiXHS6Vh3qnNJvVmHWOwNcj38p93vXAMA5R
# 3+RJqZR09VXsuTj01v8gaodX+GbBNVGR7usOyel8fuGWpqNN1a1i6tzrgR4Eimzz
# Z9XQPCwbyAXieJqZVFQM/MX0QcEZsrytPmLz8a1AcSoXxWPcgDqC2bup/wxbz4G3
# a/E=
# SIG # End signature block
