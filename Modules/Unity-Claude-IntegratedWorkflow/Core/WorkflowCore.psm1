# Unity-Claude-IntegratedWorkflow Core Component
# Core configuration, logging, and shared state management
# Part of refactored IntegratedWorkflow module

$ErrorActionPreference = "Stop"

# Module-level variables for integrated workflow
$script:IntegratedWorkflowState = @{
    ActiveWorkflows = [hashtable]::Synchronized(@{})
    WorkflowScheduler = [System.Collections.ArrayList]::Synchronized(@())
    CrossStageErrors = [System.Collections.ArrayList]::Synchronized(@())
    PerformanceMetrics = [hashtable]::Synchronized(@{})
    SharedResources = [hashtable]::Synchronized(@{})
}

# Fallback logging function
function Write-FallbackLog {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Component = "IntegratedWorkflow"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logMessage = "[$timestamp] [$Level] [$Component] $Message"
    
    switch ($Level) {
        "ERROR" { Write-Host $logMessage -ForegroundColor Red }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "DEBUG" { Write-Host $logMessage -ForegroundColor Gray }
        default { Write-Host $logMessage -ForegroundColor White }
    }
    
    # Write to centralized log
    Add-Content -Path ".\unity_claude_automation.log" -Value $logMessage -ErrorAction SilentlyContinue
}

# Wrapper function for logging with fallback
function Write-IntegratedWorkflowLog {
    param(
        [string]$Message,
        [string]$Level = "INFO", 
        [string]$Component = "IntegratedWorkflow"
    )
    
    Write-FallbackLog -Message "[$Level] [$Component] $Message" -Level $Level -Component $Component
    
    # Debug logging for troubleshooting
    if ($Level -eq "DEBUG") {
        Write-Verbose "IntegratedWorkflow Debug: $Message" -Verbose
    }
}

# Get module state
function Get-IntegratedWorkflowState {
    return $script:IntegratedWorkflowState
}

# Export functions
Export-ModuleMember -Function @(
    'Write-FallbackLog',
    'Write-IntegratedWorkflowLog',
    'Get-IntegratedWorkflowState'
)

Write-IntegratedWorkflowLog -Message "WorkflowCore component loaded successfully" -Level "DEBUG"

# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAy6GZomfEee05q
# 9plLiRJLRTg16H8uhUIvbOkxg3E6tKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIL5wkRIJlQPGc4Lehuumm4qz
# aZB3yGBuhyUK183X0hLOMA0GCSqGSIb3DQEBAQUABIIBAD1bnEhe5aGiy7887bg4
# 05U/CUveaRZoLc8/30/yzjSV8h6olZHKsTE2RLix6dLTZyuoako90g3CsGqC8w2R
# 0Vds7hicy4zr0wHuQs9n5BFosiHVlOsbcd556h8KDuB4E3KCe1GbCIINNUvY0WO2
# ti0CQ1bB2nr/ndWogJ3SOBFj+iQQ8qawycSQ/Q6+DLMReQFk0OPHgIDpgBWNk6Nl
# b9bL55gQU6oeeFhYDEWxJFBSFqXTieopGimuNsMQbm2rp09lDUrJwFaTRwX4KclK
# Fp8qRSOz2ocPq7cF9IOo8I7BwDrpwd7PMk6jDFwgpmQ7qN7rEGMnJK5+99/QGPal
# 27U=
# SIG # End signature block
