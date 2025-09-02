# PromptConfiguration.psm1
# Configuration and shared collections for intelligent prompt engine
# Refactored component from IntelligentPromptEngine.psm1
# Component: Configuration and thread-safe collections (50 lines)

#region Module Configuration and Collections

# Module configuration settings
$script:ModuleConfig = @{
    ResultAnalysisConfig = @{
        PatternLearningThreshold = 3  # Minimum occurrences for pattern establishment
        ConfidenceThreshold = 0.7     # Minimum confidence for automation decisions
        HistoryRetentionDays = 30     # Days to retain result history
        BaselineWindowSize = 10       # Number of results for baseline establishment
    }
    PromptTypeConfig = @{
        Types = @('Debugging', 'Test Results', 'Continue', 'ARP')
        DefaultType = 'Continue'
        ConfidenceThreshold = 0.8     # Minimum confidence for automatic selection
        FallbackType = 'Continue'     # Fallback when confidence is low
    }
    ConversationStateConfig = @{
        States = @('Idle', 'Processing', 'WaitingForInput', 'Error', 'Learning', 'Autonomous')
        DefaultState = 'Idle'
        TransitionTimeout = 300       # Seconds before state timeout
        ContextRetentionLimit = 50    # Maximum context items to retain
    }
    SeverityConfig = @{
        Levels = @('Critical', 'High', 'Medium', 'Low')
        CriticalThreshold = 0.9       # Confidence threshold for critical classification
        AutomationThresholds = @{     # Minimum confidence for automated handling
            Critical = 0.95
            High = 0.85
            Medium = 0.75
            Low = 0.65
        }
    }
}

# Thread-safe collections for result tracking
$script:ResultHistory = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()
$script:PatternRegistry = [System.Collections.Concurrent.ConcurrentDictionary[string,object]]::new()
$script:ConversationContext = [System.Collections.Concurrent.ConcurrentDictionary[string,object]]::new()

function Get-PromptEngineConfig {
    <#
    .SYNOPSIS
    Get the current prompt engine configuration
    #>
    [CmdletBinding()]
    param()
    
    return $script:ModuleConfig
}

# Export functions
Export-ModuleMember -Function @(
    'Get-PromptEngineConfig'
)

#endregion
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDAAYsX0mzsv/wV
# rCbDjWqMn7w3QTN9WaQIdIhVqlgYu6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIFReGztEmy1v678gC75ssRlM
# YtELtm6eZ7oL0rUV3BcPMA0GCSqGSIb3DQEBAQUABIIBACjYkoGA5nh5KrfXArNY
# YOR8xa9uVnpTxAwhum0dwZ/oGQcibfDXx0HKhZQYFCg0FZOjBOd/RCDt5Zm8XVHS
# hMg1uuUPb5PiLLzIYRMJcSqiWcOV5GQ02veHmCoRrQaQeMIBNhy3c9mdQerD9ItB
# QvJbvHj0EeHo5Dn9dfBgkSEn85M6ZHs+zfDht3YYBybFu0ySsqiPv/vALM6abkfr
# 4PXB8yyhLED/NZ/4Hu3dsLJVY+uvQe5xDeaYLgA7CUNFGZ7U6KBDt8gwn02bxq4T
# k+zllAvBwBO80YLiAPiqaKjcP909u/lbqzbF27C6u9igs0ydP6B8NJRg7KNJG66k
# WDI=
# SIG # End signature block
