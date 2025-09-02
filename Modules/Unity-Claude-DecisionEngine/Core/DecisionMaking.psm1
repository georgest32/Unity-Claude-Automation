# DecisionMaking.psm1
# Decision Making Engine for Unity-Claude-DecisionEngine
# Part of the refactored Unity-Claude-DecisionEngine module

# Import core module for shared functions
$corePath = Join-Path $PSScriptRoot "DecisionEngineCore.psm1"
if (Test-Path $corePath) {
    Import-Module $corePath -Force -DisableNameChecking
}

#region Autonomous Decision Making

function Invoke-AutonomousDecision {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Analysis,
        
        [Parameter()]
        [hashtable]$Context = @{},
        
        [Parameter()]
        [switch]$AutoExecute
    )
    
    Write-DecisionEngineLog -Message "Making autonomous decision based on analysis" -Level "INFO"
    
    $decision = @{
        Timestamp = Get-Date
        Analysis = $Analysis
        Context = $Context
        Action = "NONE"
        Target = $null
        Confidence = 0.0
        Reasoning = @()
        RequiresConfirmation = $true
        ExecutionPlan = @()
    }
    
    try {
        # Step 1: Decision tree evaluation
        $treeDecision = Invoke-DecisionTree -Analysis $Analysis
        $decision.Action = $treeDecision.Action
        $decision.Target = $treeDecision.Target
        $decision.Confidence = $treeDecision.Confidence
        $decision.Reasoning += $treeDecision.Reasoning
        
        # Step 2: Context-based adjustments
        $decision = Apply-ContextualAdjustments -Decision $decision -Context $Context
        
        # Step 3: Validation
        $validation = Invoke-DecisionValidation -Decision $decision
        if (-not $validation.IsValid) {
            Write-DecisionEngineLog -Message "Decision validation failed: $($validation.Reason)" -Level "WARN"
            $decision.Action = "SEEK_CLARIFICATION"
            $decision.RequiresConfirmation = $true
        }
        
        # Step 4: Determine if confirmation is needed
        if ($decision.Confidence -ge $script:DecisionEngineConfig.ConfidenceThreshold) {
            $decision.RequiresConfirmation = $false
        }
        
        # Step 5: Add to history
        Add-DecisionToHistory -Decision $decision
        
        # Step 6: Auto-execute if enabled and confidence is high
        if ($AutoExecute -and -not $decision.RequiresConfirmation) {
            Write-DecisionEngineLog -Message "Auto-executing decision: $($decision.Action)" -Level "INFO"
            # Execution would happen here if connected to execution engine
        }
        
    } catch {
        Write-DecisionEngineLog -Message "Decision error: $_" -Level "ERROR"
        $decision.Action = "ERROR"
        $decision.Error = $_.Exception.Message
    }
    
    return $decision
}

#endregion

#region Decision Tree

function Invoke-DecisionTree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Analysis
    )
    
    Write-DecisionEngineLog -Message "Evaluating decision tree" -Level "DEBUG"
    
    $decision = @{
        Action = "NONE"
        Target = $null
        Confidence = 0.0
        Reasoning = @()
    }
    
    # Decision tree based on intent and confidence
    switch ($Analysis.Intent) {
        "ERROR" {
            $decision.Action = "DIAGNOSE_AND_FIX"
            $decision.Reasoning += "Error detected in response"
            $decision.Confidence = $Analysis.Confidence
            
            # Check for specific error entities
            if ($Analysis.Entities.ContainsKey("FilePath")) {
                $decision.Target = $Analysis.Entities.FilePath[0]
                $decision.Reasoning += "Target file identified: $($decision.Target)"
                $decision.Confidence *= 1.2
            }
        }
        
        "RECOMMENDATION" {
            $decision.Action = "EVALUATE_RECOMMENDATION"
            $decision.Reasoning += "Recommendation received"
            $decision.Confidence = $Analysis.Confidence * 0.8  # Be cautious with recommendations
            
            # Check for specific actions in the recommendation
            if ($Analysis.Actions.Count -gt 0) {
                $decision.Target = $Analysis.Actions[0].Target
                $decision.Reasoning += "Recommended action: $($Analysis.Actions[0].Type)"
                $decision.Confidence *= 1.1
            }
        }
        
        "SUCCESS" {
            $decision.Action = "CONTINUE"
            $decision.Reasoning += "Success reported"
            $decision.Confidence = $Analysis.Confidence
            
            # Check if there are follow-up actions
            if ($Analysis.Actions.Count -gt 0) {
                $decision.Action = "EXECUTE_NEXT"
                $decision.Reasoning += "Follow-up actions available"
            }
        }
        
        "EXECUTE" {
            $decision.Action = "EXECUTE_COMMAND"
            $decision.Reasoning += "Execution request detected"
            $decision.Confidence = $Analysis.Confidence
            
            # Check for command target
            if ($Analysis.Actions.Count -gt 0) {
                $decision.Target = $Analysis.Actions[0].Target
                $decision.Reasoning += "Command target: $($decision.Target)"
                $decision.Confidence *= 1.15
            }
        }
        
        "CLARIFICATION" {
            $decision.Action = "PROVIDE_CLARIFICATION"
            $decision.Reasoning += "Clarification requested"
            $decision.Confidence = 0.9  # High confidence for clarification requests
            
            # Check what needs clarification
            if ($Analysis.SemanticContext.Domain -ne "Unknown") {
                $decision.Target = $Analysis.SemanticContext.Domain
                $decision.Reasoning += "Domain context: $($decision.Target)"
            }
        }
        
        default {
            $decision.Action = "SEEK_CLARIFICATION"
            $decision.Reasoning += "Intent unclear"
            $decision.Confidence = 0.3
        }
    }
    
    # Apply confidence cap
    $decision.Confidence = [Math]::Min($decision.Confidence, 1.0)
    
    Write-DecisionEngineLog -Message "Decision tree result: $($decision.Action) (confidence: $($decision.Confidence))" -Level "DEBUG"
    
    return $decision
}

#endregion

#region Context and Validation

function Apply-ContextualAdjustments {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Decision,
        
        [Parameter()]
        [hashtable]$Context = @{}
    )
    
    Write-DecisionEngineLog -Message "Applying contextual adjustments" -Level "DEBUG"
    
    # Adjust confidence based on context
    if ($Context.ContainsKey("UserPreference")) {
        switch ($Context.UserPreference) {
            "Conservative" {
                $Decision.Confidence *= 0.8
                $Decision.RequiresConfirmation = $true
                $Decision.Reasoning += "Conservative mode: reduced confidence"
            }
            "Aggressive" {
                $Decision.Confidence *= 1.2
                $Decision.Reasoning += "Aggressive mode: increased confidence"
            }
        }
    }
    
    # Check for recent failures
    $recentFailures = $script:DecisionHistory | Where-Object {
        $_.Action -eq "ERROR" -and
        (Get-Date) - $_.Timestamp -lt [TimeSpan]::FromMinutes(5)
    }
    
    if ($recentFailures.Count -gt 2) {
        $Decision.Confidence *= 0.7
        $Decision.Reasoning += "Recent failures detected: reduced confidence"
        Write-DecisionEngineLog -Message "Reducing confidence due to recent failures" -Level "WARN"
    }
    
    # Check for urgency in semantic context
    if ($Decision.Analysis.SemanticContext.Urgency -eq "High") {
        $Decision.Confidence *= 1.1
        $Decision.Reasoning += "High urgency: increased confidence"
    }
    
    # Check for complexity
    if ($Decision.Analysis.SemanticContext.Complexity -eq "High") {
        $Decision.RequiresConfirmation = $true
        $Decision.Reasoning += "High complexity: confirmation required"
    }
    
    # Learning-based adjustments
    if ($script:DecisionEngineConfig.LearningEnabled) {
        $similarPastDecisions = $script:DecisionHistory | Where-Object {
            $_.Analysis.Intent -eq $Decision.Analysis.Intent
        }
        
        if ($similarPastDecisions.Count -gt 0) {
            $successRate = ($similarPastDecisions | Where-Object { $_.Outcome -eq "Success" }).Count / $similarPastDecisions.Count
            
            if ($successRate -gt 0.8) {
                $Decision.Confidence *= 1.15
                $Decision.Reasoning += "High success rate for similar decisions"
            } elseif ($successRate -lt 0.5) {
                $Decision.Confidence *= 0.85
                $Decision.Reasoning += "Low success rate for similar decisions"
            }
        }
    }
    
    # Cap confidence
    $Decision.Confidence = [Math]::Min($Decision.Confidence, 1.0)
    
    return $Decision
}

function Invoke-DecisionValidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Decision
    )
    
    Write-DecisionEngineLog -Message "Validating decision" -Level "DEBUG"
    
    $validation = @{
        IsValid = $true
        Reason = "Validation passed"
        Checks = @()
    }
    
    # Check 1: Action validity
    $validActions = @(
        "NONE", "DIAGNOSE_AND_FIX", "EVALUATE_RECOMMENDATION", 
        "CONTINUE", "EXECUTE_NEXT", "EXECUTE_COMMAND", 
        "PROVIDE_CLARIFICATION", "SEEK_CLARIFICATION", "ERROR"
    )
    
    if ($Decision.Action -notin $validActions) {
        $validation.IsValid = $false
        $validation.Reason = "Invalid action: $($Decision.Action)"
        $validation.Checks += "Action validation failed"
    } else {
        $validation.Checks += "Action validation passed"
    }
    
    # Check 2: Confidence threshold
    if ($Decision.Confidence -lt 0.3) {
        $validation.IsValid = $false
        $validation.Reason = "Confidence too low: $($Decision.Confidence)"
        $validation.Checks += "Confidence validation failed"
    } else {
        $validation.Checks += "Confidence validation passed"
    }
    
    # Check 3: Target requirement
    $targetRequiredActions = @("EXECUTE_COMMAND", "DIAGNOSE_AND_FIX")
    if ($Decision.Action -in $targetRequiredActions -and -not $Decision.Target) {
        $validation.IsValid = $false
        $validation.Reason = "Target required but not specified"
        $validation.Checks += "Target validation failed"
    } else {
        $validation.Checks += "Target validation passed"
    }
    
    # Check 4: Safety check for execution
    if ($Decision.Action -eq "EXECUTE_COMMAND") {
        # Check for potentially dangerous commands
        $dangerousPatterns = @("Remove-Item", "Format-", "Clear-", "Stop-Service", "Restart-Computer")
        foreach ($pattern in $dangerousPatterns) {
            if ($Decision.Target -match $pattern) {
                $validation.IsValid = $false
                $validation.Reason = "Potentially dangerous command detected"
                $validation.Checks += "Safety validation failed"
                break
            }
        }
        
        if ($validation.IsValid) {
            $validation.Checks += "Safety validation passed"
        }
    }
    
    # Check 5: Reasoning completeness
    if ($Decision.Reasoning.Count -eq 0) {
        $validation.IsValid = $false
        $validation.Reason = "No reasoning provided"
        $validation.Checks += "Reasoning validation failed"
    } else {
        $validation.Checks += "Reasoning validation passed"
    }
    
    Write-DecisionEngineLog -Message "Validation result: $($validation.IsValid) - $($validation.Reason)" -Level "DEBUG"
    
    return $validation
}

#endregion

# Export module members
Export-ModuleMember -Function @(
    'Invoke-AutonomousDecision',
    'Invoke-DecisionTree',
    'Apply-ContextualAdjustments',
    'Invoke-DecisionValidation'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDmWGgLaB30zWId
# +B5oiPlGMKrsQe/zXQsW3DrPHO2+MqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIEjRYngPemeJX8QDI8sFs6PB
# jpCItb8Fk3JtQcNySdL1MA0GCSqGSIb3DQEBAQUABIIBAIVZezIImxh1xxf8EfbP
# y4qBZQ+MRfITQkLU0uWcW7P2Su+rpQe9MNTMXHIHIkseEB/Y6tB7Yb4kt2sSlEnB
# uT0LncOEJHZiVFtBEe34dbN1DQK/OQnZ4QGwTJVqndsVjL50xOSt8ODgeWKgFqVD
# S1bhLbnew+kausEnAOtoQbnHgiwrd+ONPQk1oJ60CEqqHiHn+9PoD3g1nQEwE1nC
# TwqmNjNthkzSa3biqzED7JrOmgjheiCX+FxPqt873Pj3c2PnQ0hee/e0F15mjemH
# guMWVOJM+QUoq/AgOhZ8WWpLCZRcIMwTz6RHn0ceQxPYXsSqIcKJKg0c5qudtSke
# pMs=
# SIG # End signature block
