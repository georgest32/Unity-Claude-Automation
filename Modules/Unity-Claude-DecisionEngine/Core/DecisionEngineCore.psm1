# DecisionEngineCore.psm1
# Core configuration, logging, and utilities for Decision Engine
# Part of the refactored Unity-Claude-DecisionEngine module

# Module-level variables
$script:DecisionEngineConfig = @{
    EnableDebugLogging = $true
    ConfidenceThreshold = 0.7
    MaxDecisionRetries = 3
    DecisionTimeoutMs = 5000
    EnableAIEnhancement = $true
    ContextWindowSize = 10
    LearningEnabled = $true
}

$script:LogPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log"

# Decision state tracking
$script:DecisionHistory = [System.Collections.Generic.List[hashtable]]::new()
$script:ContextBuffer = [System.Collections.Queue]::new()
$script:ActiveDecisions = @{}

#region Logging and Utilities

function Write-DecisionEngineLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet("INFO", "WARN", "ERROR", "DEBUG")]
        [string]$Level = "INFO"
    )
    
    if (-not $script:DecisionEngineConfig.EnableDebugLogging -and $Level -eq "DEBUG") {
        return
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] [DecisionEngine] $Message"
    
    try {
        Add-Content -Path $script:LogPath -Value $logEntry -Encoding UTF8 -ErrorAction SilentlyContinue
    } catch {
        # Silently continue if logging fails
    }
    
    if ($Level -eq "ERROR") {
        Write-Error $Message
    } elseif ($Level -eq "WARN") {
        Write-Warning $Message
    } elseif ($script:DecisionEngineConfig.EnableDebugLogging) {
        Write-Host "[$Level] $Message" -ForegroundColor $(
            switch ($Level) {
                "INFO" { "Green" }
                "DEBUG" { "Gray" }
                default { "White" }
            }
        )
    }
}

function Test-RequiredModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName
    )
    
    $module = Get-Module -Name $ModuleName -ErrorAction SilentlyContinue
    if (-not $module) {
        Write-DecisionEngineLog -Message "Required module '$ModuleName' not loaded" -Level "WARN"
        return $false
    }
    return $true
}

#endregion

#region Configuration Management

function Get-DecisionEngineConfig {
    [CmdletBinding()]
    param()
    
    Write-DecisionEngineLog -Message "Retrieving Decision Engine configuration" -Level "DEBUG"
    return $script:DecisionEngineConfig.Clone()
}

function Set-DecisionEngineConfig {
    [CmdletBinding()]
    param(
        [Parameter()]
        [hashtable]$Configuration
    )
    
    if ($Configuration) {
        foreach ($key in $Configuration.Keys) {
            if ($script:DecisionEngineConfig.ContainsKey($key)) {
                $script:DecisionEngineConfig[$key] = $Configuration[$key]
                Write-DecisionEngineLog -Message "Updated configuration: $key = $($Configuration[$key])" -Level "DEBUG"
            } else {
                Write-DecisionEngineLog -Message "Unknown configuration key: $key" -Level "WARN"
            }
        }
    }
    
    return $script:DecisionEngineConfig
}

#endregion

#region State Management

function Get-DecisionHistory {
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]$Limit = 10
    )
    
    Write-DecisionEngineLog -Message "Retrieving decision history (limit: $Limit)" -Level "DEBUG"
    
    $history = $script:DecisionHistory
    if ($Limit -gt 0 -and $history.Count -gt $Limit) {
        $history = $history[-$Limit..-1]
    }
    
    return $history
}

function Clear-DecisionHistory {
    [CmdletBinding()]
    param()
    
    Write-DecisionEngineLog -Message "Clearing decision history" -Level "INFO"
    $script:DecisionHistory.Clear()
    $script:ContextBuffer.Clear()
    $script:ActiveDecisions = @{}
}

function Add-DecisionToHistory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Decision
    )
    
    $Decision.Timestamp = Get-Date
    $script:DecisionHistory.Add($Decision)
    
    # Limit history size
    if ($script:DecisionHistory.Count -gt 100) {
        $script:DecisionHistory.RemoveAt(0)
    }
    
    Write-DecisionEngineLog -Message "Added decision to history: $($Decision.Action)" -Level "DEBUG"
}

#endregion

# Export module members
Export-ModuleMember -Function @(
    'Write-DecisionEngineLog',
    'Test-RequiredModule',
    'Get-DecisionEngineConfig',
    'Set-DecisionEngineConfig',
    'Get-DecisionHistory',
    'Clear-DecisionHistory',
    'Add-DecisionToHistory'
) -Variable @(
    'DecisionEngineConfig',
    'LogPath',
    'DecisionHistory',
    'ContextBuffer',
    'ActiveDecisions'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDPYJx3Fa68kKGd
# 16UjcB8DeKj472gX8KHIhnaMdX4V6qCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIEp4O/1a2UXG4KrumvZ3QpTO
# ebAmeiZn8iPIFoasCnbZMA0GCSqGSIb3DQEBAQUABIIBAHR28G5BZ4xglhTctMFU
# 2fe0o/ECa0Wv3uc3dcPSIx8Yjx7rt065+svbWn/11t2mTCDjK9nEFRPmhVbSd4NZ
# f2C1I7zYUkjtq5N/imzRD/5ea6bK2R9d5uIRjCOBaPOKJ1JRqYwR6YQJ2OMcQR5c
# qiIwYGkPi/n8Ln3Wl+vROf338BkZQTN6jNGZZ2f/vbCbgU1HRofNwOp2BXK2oYU1
# a/gvZhufHpneUVz81ZtgrY1shSGz1a+BccDf35L229iObiWN7WVh/TdIEtO0r3do
# SVNoMjrQNMKyyEs8uWXtPLUUkP+sw/C2rdutck8/j32PS1TNQwJeLZd49g46ur/a
# GZs=
# SIG # End signature block
