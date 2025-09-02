# ConfigurationLogging.psm1
# Core configuration and logging for DecisionEngine
# Part of Unity-Claude-CLIOrchestrator refactored architecture
# Date: 2025-08-25

#region Module Configuration and Logging

# Core configuration for decision engine
$script:DecisionConfig = @{
    # Rule-based decision matrix
    DecisionMatrix = @{
        "CONTINUE" = @{
            Priority = 1
            ActionType = "Continuation"
            SafetyLevel = "Low"
            RequiresValidation = $false
            MaxRetryAttempts = 1
            TimeoutSeconds = 30
        }
        "TEST" = @{
            Priority = 2
            ActionType = "TestExecution"
            SafetyLevel = "Medium"
            RequiresValidation = $true
            MaxRetryAttempts = 2
            TimeoutSeconds = 300
        }
        "FIX" = @{
            Priority = 3
            ActionType = "FileModification"
            SafetyLevel = "High"
            RequiresValidation = $true
            MaxRetryAttempts = 1
            TimeoutSeconds = 120
        }
        "COMPILE" = @{
            Priority = 4
            ActionType = "BuildOperation"
            SafetyLevel = "Medium"
            RequiresValidation = $true
            MaxRetryAttempts = 2
            TimeoutSeconds = 180
        }
        "RESTART" = @{
            Priority = 5
            ActionType = "ServiceRestart"
            SafetyLevel = "High"
            RequiresValidation = $true
            MaxRetryAttempts = 1
            TimeoutSeconds = 60
        }
        "COMPLETE" = @{
            Priority = 6
            ActionType = "TaskCompletion"
            SafetyLevel = "Low"
            RequiresValidation = $false
            MaxRetryAttempts = 1
            TimeoutSeconds = 30
        }
        "ERROR" = @{
            Priority = 7
            ActionType = "ErrorHandling"
            SafetyLevel = "Low"
            RequiresValidation = $false
            MaxRetryAttempts = 3
            TimeoutSeconds = 60
        }
    }
    
    # Safety validation thresholds
    SafetyThresholds = @{
        MinimumConfidence = 0.7
        MaxFileSize = 10MB
        AllowedFileExtensions = @('.ps1', '.psm1', '.psd1', '.json', '.txt', '.md', '.yml', '.yaml')
        BlockedPaths = @('C:\Windows', 'C:\Program Files', 'C:\Program Files (x86)')
        MaxConcurrentActions = 3
    }
    
    # Performance targets
    PerformanceTargets = @{
        DecisionTimeMs = 100
        ValidationTimeMs = 50
        QueueProcessingTimeMs = 25
    }
    
    # Action queue configuration
    ActionQueue = @{
        MaxQueueSize = 10
        PriorityLevels = 7
        DefaultTimeout = 300
    }
}

# Get decision engine configuration
function Get-DecisionEngineConfiguration {
    [CmdletBinding()]
    param()
    
    return $script:DecisionConfig
}

# Update decision engine configuration
function Set-DecisionEngineConfiguration {
    [CmdletBinding()]
    param(
        [Parameter()]
        [hashtable]$Configuration
    )
    
    if ($Configuration) {
        $script:DecisionConfig = $Configuration
        Write-DecisionLog "Decision engine configuration updated" "INFO"
    }
}

# Logging function with millisecond precision
function Write-DecisionLog {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Component = "DecisionEngine"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logEntry = "[$timestamp] [$Level] [$Component] $Message"
    Write-Host $logEntry -ForegroundColor $(
        switch ($Level) {
            "ERROR" { "Red" }
            "WARN" { "Yellow" }
            "SUCCESS" { "Green" }
            "DEBUG" { "Gray" }
            default { "White" }
        }
    )
}

# Export functions
Export-ModuleMember -Function @(
    'Get-DecisionEngineConfiguration',
    'Set-DecisionEngineConfiguration', 
    'Write-DecisionLog'
)

#endregion
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA6b62gjFHRUEby
# c918L08ywDzY1Vhi0rFYtNoflQP26aCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIMbaoHpfZ0IIimSdQPInK5aA
# BDVFrhRq1OUPASaLpVdJMA0GCSqGSIb3DQEBAQUABIIBAFS5q3ONsKsvTjknVhHq
# juJ9V+vn4Br69bE5TTrKX1hVGH0H43HnVVHzIrJhEJzNgnHQGi/EBf176Y8LfM/M
# 18np04SF/RbY8mGC2g6IaBdvmtJd2Kj0Yq2meXy1Y15YJlaFf7HebGH7QSj/6jWh
# I3+zuBpcHhvkYKoJ75YADIn1alSIRxEWzyW/sx+wCWbdBudN9qG9Mp1Rvso2JC6D
# YOPxM/T33ddu/woA5SFUF4SVuvdQAxRYf6hH7sBZ1AGPdTBas/QpyWkZQ4C0Etzz
# P/KbZcsVZITHZ8PskoHtfDt90yLhl10pwdpI2wermrimNMFoDyIcvr3C3LStv6Y1
# McA=
# SIG # End signature block
