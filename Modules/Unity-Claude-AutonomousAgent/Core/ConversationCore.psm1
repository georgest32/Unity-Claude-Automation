# ConversationCore.psm1
# Core configuration, logging, and state variables for ConversationStateManager

# Module-level variables for state management
$script:ConversationState = $null
$script:StateHistory = @()
$script:ConversationHistory = @()
$script:SessionMetadata = @{}
$script:MaxHistorySize = 20
$script:StatePersistencePath = Join-Path (Split-Path $PSScriptRoot -Parent) "ConversationState.json"
$script:HistoryPersistencePath = Join-Path (Split-Path $PSScriptRoot -Parent) "ConversationHistory.json"

# Day 16 Enhancement: Advanced Conversation Management Variables
$script:ConversationGoals = @()
$script:RoleAwareHistory = @()
$script:DialoguePatterns = @{}
$script:ConversationEffectiveness = @{}
$script:GoalsPersistencePath = Join-Path (Split-Path $PSScriptRoot -Parent) "ConversationGoals.json"
$script:EffectivenessPersistencePath = Join-Path (Split-Path $PSScriptRoot -Parent) "ConversationEffectiveness.json"
$script:MaxRoleHistorySize = 50

# Logging configuration
$script:LogPath = Join-Path (Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent) "unity_claude_automation.log"
$script:LogMutex = [System.Threading.Mutex]::new($false, "UnityClaudeAutomationLogMutex")

function Write-StateLog {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Component = "ConversationStateManager"
    )
    
    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        $logEntry = "[$timestamp] [$Level] [$Component] $Message"
        
        # Thread-safe file writing
        $acquired = $script:LogMutex.WaitOne(1000)
        if ($acquired) {
            try {
                Add-Content -Path $script:LogPath -Value $logEntry -ErrorAction SilentlyContinue
            }
            finally {
                $script:LogMutex.ReleaseMutex()
            }
        }
    }
    catch {
        Write-Verbose "Failed to write log: $_"
    }
}

# Export core variables and functions for other components
Export-ModuleMember -Variable * -Function Write-StateLog
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAYflMolAskBl/1
# x+qXwvQ1Xv35wYnynOoChdUkNsVIK6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIIB2kEvwy8Mv8KoMQIj04wEk
# qFSINuZk+D3i+zNOr6t2MA0GCSqGSIb3DQEBAQUABIIBADJovniFPGG1ec36fDxZ
# JOJZPWyRcjKN0hlJQmlpRDLWf5jlzBZacMRZmQJG2v+hqNhhF4PgnmSPdrHT1GZL
# NE11aG+ucvWXom+sxcbhfDu9ay3vQU1Eh1fE0M51etJDxRpxBV2HRyhYjUrg/pFO
# 1P/DdCA1cb70qXbIIiCHepWvinc4TMe0hZidVh8IKfuJWUrXzJIw6pOtHFt3yszy
# oU2EDUs7oZlJSDvM399iBHLG6p3P8xVfo6PTwUmtAnQWgHGrjlKMaUNlKG1bTTgs
# l7Mo1jmwWyc8npRM3cSXjbgpKZQl8fCHn9XKGFYd5IzigvA3r79NNyO1zmvE0XMv
# cf4=
# SIG # End signature block
