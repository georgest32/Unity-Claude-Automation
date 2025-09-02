#Requires -Version 5.1
<#
.SYNOPSIS
    Decision execution and safety validation system for Unity-Claude-MasterOrchestrator.

.DESCRIPTION
    Handles autonomous decision routing, execution, safety validation, and individual
    execution handlers for different action types in the master orchestrator system.

.NOTES
    Part of Unity-Claude-MasterOrchestrator refactored architecture
    Originally from Unity-Claude-MasterOrchestrator.psm1 (lines 783-988)
    Refactoring Date: 2025-08-25
#>

# Import the core orchestrator for logging and configuration
Import-Module "$PSScriptRoot\OrchestratorCore.psm1" -Force

function Invoke-DecisionExecution {
    <#
    .SYNOPSIS
    Executes autonomous decisions with safety validation and appropriate routing.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Decision
    )
    
    Write-OrchestratorLog -Message "Executing autonomous decision: $($Decision.Action)" -Level "INFO"
    
    try {
        # Get current configuration
        $config = Get-OrchestratorConfig
        
        # Safety validation before execution
        if ($config.SafetyValidationEnabled) {
            $safetyCheck = Invoke-SafetyValidation -Decision $Decision
            if (-not $safetyCheck.IsSafe) {
                Write-OrchestratorLog -Message "Decision execution blocked by safety validation: $($safetyCheck.Reason)" -Level "WARN"
                return @{
                    Success = $false
                    Reason = "Safety validation failed: $($safetyCheck.Reason)"
                    Stage = "SafetyValidation"
                }
            }
        }
        
        # Route decision to appropriate execution handler
        $executionResult = switch ($Decision.Action) {
            "EXECUTE_RECOMMENDATION" {
                Invoke-RecommendationExecution -Decision $Decision
            }
            "EXECUTE_TEST" {
                Invoke-TestExecution -Decision $Decision
            }
            "EXECUTE_COMMAND" {
                Invoke-CommandExecution -Decision $Decision
            }
            "VALIDATE_COMMAND" {
                Invoke-CommandValidation -Decision $Decision
            }
            "CONTINUE_CONVERSATION" {
                Invoke-ConversationContinuation -Decision $Decision
            }
            "GENERATE_RESPONSE" {
                Invoke-ResponseGeneration -Decision $Decision
            }
            "ANALYZE_ERROR" {
                Invoke-ErrorAnalysis -Decision $Decision
            }
            "CONTINUE_WORKFLOW" {
                Invoke-WorkflowContinuation -Decision $Decision
            }
            "REQUEST_APPROVAL" {
                Invoke-ApprovalRequest -Decision $Decision
            }
            "CONTINUE_MONITORING" {
                Invoke-MonitoringContinuation -Decision $Decision
            }
            "NO_ACTION" {
                @{
                    Success = $true
                    Action = "NO_ACTION"
                    Reason = "No action required"
                }
            }
            default {
                Write-OrchestratorLog -Message "Unknown decision action: $($Decision.Action)" -Level "WARN"
                @{
                    Success = $false
                    Reason = "Unknown action type: $($Decision.Action)"
                }
            }
        }
        
        Write-OrchestratorLog -Message "Decision execution completed: $($Decision.Action) - Success: $($executionResult.Success)" -Level "INFO"
        
        return $executionResult
    }
    catch {
        Write-OrchestratorLog -Message "Error executing decision: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
            Stage = "Execution"
        }
    }
}

function Invoke-SafetyValidation {
    <#
    .SYNOPSIS
    Performs safety validation on decisions before execution.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Decision
    )
    
    # Basic safety validation logic
    $safetyResult = @{
        IsSafe = $true
        Reason = "Decision passed safety validation"
        Confidence = $Decision.Confidence
    }
    
    # High-risk actions require higher confidence
    $highRiskActions = @("EXECUTE_COMMAND", "VALIDATE_COMMAND", "EXECUTE_RECOMMENDATION")
    if ($Decision.Action -in $highRiskActions -and $Decision.Confidence -lt 0.8) {
        $safetyResult.IsSafe = $false
        $safetyResult.Reason = "High-risk action requires confidence >= 0.8 (current: $($Decision.Confidence))"
    }
    
    # Commands with certain patterns are blocked
    if ($Decision.CommandData -and $Decision.CommandData.Command) {
        $dangerousPatterns = @("rm ", "del ", "format", "shutdown", "restart")
        foreach ($pattern in $dangerousPatterns) {
            if ($Decision.CommandData.Command -like "*$pattern*") {
                $safetyResult.IsSafe = $false
                $safetyResult.Reason = "Command contains dangerous pattern: $pattern"
                break
            }
        }
    }
    
    return $safetyResult
}

function Invoke-RecommendationExecution {
    <#
    .SYNOPSIS
    Executes recommendation-type decisions.
    #>
    [CmdletBinding()]
    param([hashtable]$Decision)
    
    Write-OrchestratorLog -Message "Executing recommendation: $($Decision.RecommendationData.Action)" -Level "DEBUG"
    return @{ Success = $true; Action = "EXECUTE_RECOMMENDATION"; Stage = "RecommendationExecution" }
}

function Invoke-TestExecution {
    <#
    .SYNOPSIS
    Executes test-type decisions.
    #>
    [CmdletBinding()]
    param([hashtable]$Decision)
    
    Write-OrchestratorLog -Message "Executing test: $($Decision.TestData.TestType)" -Level "DEBUG"
    return @{ Success = $true; Action = "EXECUTE_TEST"; Stage = "TestExecution" }
}

function Invoke-CommandExecution {
    <#
    .SYNOPSIS
    Executes command-type decisions.
    #>
    [CmdletBinding()]
    param([hashtable]$Decision)
    
    $commandPreview = $Decision.CommandData.Command.Substring(0, [Math]::Min(50, $Decision.CommandData.Command.Length))
    Write-OrchestratorLog -Message "Executing command: $commandPreview" -Level "DEBUG"
    return @{ Success = $true; Action = "EXECUTE_COMMAND"; Stage = "CommandExecution" }
}

function Invoke-CommandValidation {
    <#
    .SYNOPSIS
    Validates commands without executing them.
    #>
    [CmdletBinding()]
    param([hashtable]$Decision)
    
    $commandPreview = $Decision.CommandData.Command.Substring(0, [Math]::Min(50, $Decision.CommandData.Command.Length))
    Write-OrchestratorLog -Message "Validating command: $commandPreview" -Level "DEBUG"
    return @{ Success = $true; Action = "VALIDATE_COMMAND"; Stage = "CommandValidation" }
}

function Invoke-ConversationContinuation {
    <#
    .SYNOPSIS
    Handles conversation continuation decisions.
    #>
    [CmdletBinding()]
    param([hashtable]$Decision)
    
    Write-OrchestratorLog -Message "Continuing conversation: $($Decision.ContinuationData.Request)" -Level "DEBUG"
    
    # Update conversation round counter in configuration
    $config = Get-OrchestratorConfig
    $config.ConversationRounds++
    Set-OrchestratorConfig -Config $config
    
    return @{ 
        Success = $true
        Action = "CONTINUE_CONVERSATION"
        Stage = "ConversationContinuation"
        Round = $config.ConversationRounds
    }
}

function Invoke-ResponseGeneration {
    <#
    .SYNOPSIS
    Handles response generation decisions.
    #>
    [CmdletBinding()]
    param([hashtable]$Decision)
    
    Write-OrchestratorLog -Message "Generating response for question: $($Decision.QuestionData.Question)" -Level "DEBUG"
    return @{ Success = $true; Action = "GENERATE_RESPONSE"; Stage = "ResponseGeneration" }
}

function Invoke-ErrorAnalysis {
    <#
    .SYNOPSIS
    Handles error analysis decisions.
    #>
    [CmdletBinding()]
    param([hashtable]$Decision)
    
    Write-OrchestratorLog -Message "Analyzing error: $($Decision.ErrorData.ErrorDescription)" -Level "DEBUG"
    return @{ Success = $true; Action = "ANALYZE_ERROR"; Stage = "ErrorAnalysis" }
}

function Invoke-WorkflowContinuation {
    <#
    .SYNOPSIS
    Handles workflow continuation decisions.
    #>
    [CmdletBinding()]
    param([hashtable]$Decision)
    
    Write-OrchestratorLog -Message "Continuing workflow: $($Decision.SuccessData.SuccessDescription)" -Level "DEBUG"
    return @{ Success = $true; Action = "CONTINUE_WORKFLOW"; Stage = "WorkflowContinuation" }
}

function Invoke-ApprovalRequest {
    <#
    .SYNOPSIS
    Handles approval request decisions.
    #>
    [CmdletBinding()]
    param([hashtable]$Decision)
    
    Write-OrchestratorLog -Message "Requesting approval for: $($Decision.OriginalAction)" -Level "INFO"
    return @{ 
        Success = $true
        Action = "REQUEST_APPROVAL"
        Stage = "ApprovalRequest"
        RequiresHumanApproval = $true
    }
}

function Invoke-MonitoringContinuation {
    <#
    .SYNOPSIS
    Handles monitoring continuation decisions.
    #>
    [CmdletBinding()]
    param([hashtable]$Decision)
    
    Write-OrchestratorLog -Message "Continuing monitoring operations" -Level "DEBUG"
    return @{ Success = $true; Action = "CONTINUE_MONITORING"; Stage = "MonitoringContinuation" }
}

Export-ModuleMember -Function @(
    'Invoke-DecisionExecution',
    'Invoke-SafetyValidation',
    'Invoke-RecommendationExecution',
    'Invoke-TestExecution',
    'Invoke-CommandExecution',
    'Invoke-CommandValidation',
    'Invoke-ConversationContinuation',
    'Invoke-ResponseGeneration',
    'Invoke-ErrorAnalysis',
    'Invoke-WorkflowContinuation',
    'Invoke-ApprovalRequest',
    'Invoke-MonitoringContinuation'
)

# REFACTORING MARKER: This module was refactored from Unity-Claude-MasterOrchestrator.psm1 on 2025-08-25
# Original file size: 1276 lines
# This component: Decision execution and safety validation system (lines 783-988)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDqNJvf6j9RY1sw
# QG43qFJuIUTqjDb+fk9QUYqbBCcfSqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIGN1Sr942GUQ6rYnoUzQKo24
# fGHEzFY11mciQzNCiodFMA0GCSqGSIb3DQEBAQUABIIBAEN8uaZchT6N3SqfxCE9
# cjSIOnAO8oirjqzfdtbEnebamdhCLAIqAMyW+VavkUXUL8/oTLqmuM65iSIijT0Y
# VYk07VH/cRVzcWO9WCShBo4KDlTtx//nW3mfxvrk9bhU5GdPPxXXz1u+R98BXkW9
# TF0ZoLcNglXr3C3TtAGSbWPyihzfcV0zI68k9UDA6VnuPHj6IWXl4iiNsYFYCrHC
# kk1jYSeXU6uxs1foNa4scvRurS1eoEgcVKgMosP6P8ruNuTibdvI+HmBGAUnibIL
# cTiZ3SvqjlFmeR+ftASTkHhdWhsPWT9cT7WZyzCN9zk3/tMl8QKMgYV6yrsnR7Zr
# i1w=
# SIG # End signature block
