function Get-CLIOrchestrationStatus {
    <#
    .SYNOPSIS
        Gets the current status of CLI orchestration components
        
    .DESCRIPTION
        Returns status information about the orchestration system including
        component health, active sessions, and performance metrics
        
    .OUTPUTS
        PSCustomObject with status information
    #>
    [CmdletBinding()]
    param()
    
    $status = [PSCustomObject]@{
        Timestamp = Get-Date
        ClaudeWindow = $null
        ComponentsLoaded = @()
        ActiveSessions = 0
        ResponseDirectory = ".\ClaudeResponses\Autonomous"
        SystemHealth = "Unknown"
    }
    
    try {
        # Check Claude window
        $status.ClaudeWindow = Find-ClaudeWindow -ErrorAction SilentlyContinue
        
        # Check loaded components
        $loadedModules = Get-Module -Name "*Claude*"
        $status.ComponentsLoaded = $loadedModules | Select-Object Name, Version
        
        # Check response directory
        if (Test-Path $status.ResponseDirectory) {
            $recentFiles = Get-ChildItem -Path $status.ResponseDirectory -Filter "*.json" |
                          Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-1) }
            $status.ActiveSessions = $recentFiles.Count
        }
        
        # Determine overall health
        if ($status.ClaudeWindow -and $status.ComponentsLoaded.Count -gt 0) {
            $status.SystemHealth = "Healthy"
        }
        elseif ($status.ComponentsLoaded.Count -gt 0) {
            $status.SystemHealth = "Partial"
        }
        else {
            $status.SystemHealth = "Critical"
        }
        
        return $status
    }
    catch {
        $status.SystemHealth = "Error"
        return $status
    }
}