function Update-CLISessionStats {
    <#
    .SYNOPSIS
        Updates CLI orchestrator session statistics
    .DESCRIPTION
        Updates various session statistics for monitoring and reporting
    .PARAMETER StatType
        Type of statistic to update
    .PARAMETER Increment
        Amount to increment the statistic by (default: 1)
    .EXAMPLE
        Update-CLISessionStats -StatType "PromptsSent"
    #>
    [CmdletBinding()]
    param(
        [ValidateSet("PromptsSent", "ResponsesProcessed", "DecisionsMade", "ActionsExecuted", "ErrorCount")]
        [string]$StatType,
        
        [int]$Increment = 1
    )
    
    try {
        if ($script:CLIOrchestratorConfig.SessionStats.ContainsKey($StatType)) {
            $script:CLIOrchestratorConfig.SessionStats[$StatType] += $Increment
            $script:CLIOrchestratorConfig.LastActivity = Get-Date
            
            Write-Verbose "Updated $StatType by $Increment (new value: $($script:CLIOrchestratorConfig.SessionStats[$StatType]))"
        } else {
            Write-Warning "Unknown statistic type: $StatType"
        }
    } catch {
        Write-Error "Failed to update session statistics: $_"
    }
}