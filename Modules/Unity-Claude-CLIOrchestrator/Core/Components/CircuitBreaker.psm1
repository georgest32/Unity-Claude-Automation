# Unity-Claude-CLIOrchestrator - Circuit Breaker Component
# Refactored from ResponseAnalysisEngine.psm1 for better maintainability
# Compatible with PowerShell 5.1 and Claude Code CLI 2025

#region Module Configuration and State

# Import logging functionality
if (Get-Module -Name "AnalysisLogging") {
    # Already loaded, use existing functions
} else {
    # Load from relative path
    $loggingPath = Join-Path $PSScriptRoot "AnalysisLogging.psm1"
    if (Test-Path $loggingPath) {
        Import-Module $loggingPath -Force
    } else {
        # Fallback logging function
        function Write-AnalysisLog {
            param($Message, $Level = "INFO", $Component = "CircuitBreaker")
            Write-Host "[$Level] [$Component] $Message"
        }
    }
}

# Circuit breaker configuration
$script:DefaultCircuitBreakerConfig = @{
    Threshold = 5
    ResetTimeMs = 30000
    MaxRetryAttempts = 3
    RetryDelayMs = @(500, 1000, 2000)
}

# Circuit breaker state
$script:CircuitBreakerState = @{
    FailureCount = 0
    LastFailureTime = $null
    State = "Closed"  # Closed, Open, HalfOpen
}

# Allow external configuration override
$script:CircuitBreakerConfig = $script:DefaultCircuitBreakerConfig.Clone()

#endregion

#region Core Circuit Breaker Functions

function Test-CircuitBreakerState {
    [CmdletBinding()]
    param()
    
    Write-AnalysisLog -Message "Checking circuit breaker state: $($script:CircuitBreakerState.State)" -Level "DEBUG" -Component "CircuitBreaker"
    
    switch ($script:CircuitBreakerState.State) {
        "Closed" {
            return $true
        }
        "Open" {
            $timeSinceFailure = (Get-Date) - $script:CircuitBreakerState.LastFailureTime
            if ($timeSinceFailure.TotalMilliseconds -gt $script:CircuitBreakerConfig.ResetTimeMs) {
                Write-AnalysisLog -Message "Circuit breaker moving to HalfOpen state" -Level "INFO" -Component "CircuitBreaker"
                $script:CircuitBreakerState.State = "HalfOpen"
                return $true
            }
            Write-AnalysisLog -Message "Circuit breaker is OPEN - blocking operation" -Level "WARN" -Component "CircuitBreaker"
            return $false
        }
        "HalfOpen" {
            return $true
        }
    }
    return $false
}

function Update-CircuitBreakerState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [bool]$Success
    )
    
    if ($Success) {
        Write-AnalysisLog -Message "Operation successful - resetting circuit breaker" -Level "DEBUG" -Component "CircuitBreaker"
        $script:CircuitBreakerState.FailureCount = 0
        $script:CircuitBreakerState.State = "Closed"
        $script:CircuitBreakerState.LastFailureTime = $null
    } else {
        $script:CircuitBreakerState.FailureCount++
        $script:CircuitBreakerState.LastFailureTime = Get-Date
        
        Write-AnalysisLog -Message "Operation failed - failure count: $($script:CircuitBreakerState.FailureCount)" -Level "WARN" -Component "CircuitBreaker"
        
        if ($script:CircuitBreakerState.FailureCount -ge $script:CircuitBreakerConfig.Threshold) {
            Write-AnalysisLog -Message "Circuit breaker OPENED due to repeated failures" -Level "ERROR" -Component "CircuitBreaker"
            $script:CircuitBreakerState.State = "Open"
        } elseif ($script:CircuitBreakerState.State -eq "HalfOpen") {
            Write-AnalysisLog -Message "Circuit breaker moving back to OPEN from HalfOpen" -Level "WARN" -Component "CircuitBreaker"
            $script:CircuitBreakerState.State = "Open"
        }
    }
}

function Reset-CircuitBreakerState {
    [CmdletBinding()]
    param()
    
    Write-AnalysisLog -Message "Manually resetting circuit breaker state" -Level "INFO" -Component "CircuitBreaker"
    
    $script:CircuitBreakerState.FailureCount = 0
    $script:CircuitBreakerState.State = "Closed"
    $script:CircuitBreakerState.LastFailureTime = $null
}

function Get-CircuitBreakerState {
    [CmdletBinding()]
    param()
    
    return @{
        State = $script:CircuitBreakerState.State
        FailureCount = $script:CircuitBreakerState.FailureCount
        LastFailureTime = $script:CircuitBreakerState.LastFailureTime
        Configuration = $script:CircuitBreakerConfig
    }
}

function Set-CircuitBreakerConfiguration {
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]$Threshold,
        
        [Parameter()]
        [int]$ResetTimeMs,
        
        [Parameter()]
        [int]$MaxRetryAttempts,
        
        [Parameter()]
        [int[]]$RetryDelayMs
    )
    
    if ($Threshold) { $script:CircuitBreakerConfig.Threshold = $Threshold }
    if ($ResetTimeMs) { $script:CircuitBreakerConfig.ResetTimeMs = $ResetTimeMs }
    if ($MaxRetryAttempts) { $script:CircuitBreakerConfig.MaxRetryAttempts = $MaxRetryAttempts }
    if ($RetryDelayMs) { $script:CircuitBreakerConfig.RetryDelayMs = $RetryDelayMs }
    
    Write-AnalysisLog -Message "Circuit breaker configuration updated" -Level "INFO" -Component "CircuitBreaker"
}

function Invoke-WithCircuitBreaker {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ScriptBlock]$ScriptBlock,
        
        [Parameter()]
        [string]$OperationName = "Unknown"
    )
    
    if (-not (Test-CircuitBreakerState)) {
        $exception = New-Object System.InvalidOperationException("Circuit breaker is OPEN - operation '$OperationName' blocked")
        throw $exception
    }
    
    try {
        Write-AnalysisLog -Message "Executing operation '$OperationName' with circuit breaker protection" -Level "DEBUG" -Component "CircuitBreaker"
        $result = & $ScriptBlock
        Update-CircuitBreakerState -Success $true
        return $result
    } catch {
        Write-AnalysisLog -Message "Operation '$OperationName' failed: $($_.Exception.Message)" -Level "ERROR" -Component "CircuitBreaker"
        Update-CircuitBreakerState -Success $false
        throw
    }
}

function Test-CircuitBreakerComponent {
    [CmdletBinding()]
    param()
    
    $testResults = @()
    
    try {
        # Reset to clean state
        Reset-CircuitBreakerState
        
        # Test initial state
        $isHealthy = Test-CircuitBreakerState
        if ($isHealthy -and (Get-CircuitBreakerState).State -eq "Closed") {
            $testResults += @{
                Name = "Initial State Test"
                Status = "Passed"
                Details = "Circuit breaker initialized in Closed state"
            }
        } else {
            $testResults += @{
                Name = "Initial State Test"
                Status = "Failed"
                Details = "Circuit breaker not in expected Closed state"
            }
        }
        
        # Test failure handling
        for ($i = 1; $i -le 6; $i++) {
            Update-CircuitBreakerState -Success $false
        }
        
        $state = Get-CircuitBreakerState
        if ($state.State -eq "Open" -and $state.FailureCount -eq 6) {
            $testResults += @{
                Name = "Failure Threshold Test"
                Status = "Passed"
                Details = "Circuit breaker opened after reaching failure threshold"
            }
        } else {
            $testResults += @{
                Name = "Failure Threshold Test"
                Status = "Failed"
                Details = "Circuit breaker state: $($state.State), FailureCount: $($state.FailureCount)"
            }
        }
        
        # Test circuit breaker blocking
        if (-not (Test-CircuitBreakerState)) {
            $testResults += @{
                Name = "Blocking Test"
                Status = "Passed"
                Details = "Circuit breaker correctly blocks operations when Open"
            }
        } else {
            $testResults += @{
                Name = "Blocking Test"
                Status = "Failed"
                Details = "Circuit breaker should block operations when Open"
            }
        }
        
        # Test configuration
        Set-CircuitBreakerConfiguration -Threshold 10 -ResetTimeMs 60000
        $config = (Get-CircuitBreakerState).Configuration
        if ($config.Threshold -eq 10 -and $config.ResetTimeMs -eq 60000) {
            $testResults += @{
                Name = "Configuration Test"
                Status = "Passed"
                Details = "Circuit breaker configuration updated successfully"
            }
        } else {
            $testResults += @{
                Name = "Configuration Test"
                Status = "Failed"
                Details = "Configuration not updated correctly"
            }
        }
        
    } catch {
        $testResults += @{
            Name = "Circuit Breaker Component Test"
            Status = "Failed"
            Error = $_.Exception.Message
        }
    } finally {
        # Reset to clean state
        Reset-CircuitBreakerState
    }
    
    return $testResults
}

#endregion

#region Module Exports

Export-ModuleMember -Function @(
    'Test-CircuitBreakerState',
    'Update-CircuitBreakerState',
    'Reset-CircuitBreakerState',
    'Get-CircuitBreakerState',
    'Set-CircuitBreakerConfiguration',
    'Invoke-WithCircuitBreaker',
    'Test-CircuitBreakerComponent'
)

#endregion
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDToLzRmZ0Dk6s8
# zLcgSqN9Qtqj9b7WFZD/A173REiqpKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEICB5pbihOw6GmGgnUvu+YnEI
# wjSlrcwQHU0WACPIXpiGMA0GCSqGSIb3DQEBAQUABIIBABJdNeaKz3sqLRvnZzf9
# j5JFCCbHKwLNSnJXpHYHDpupB27+RhKAgkl3XuJcpR0WQ5Dms0wtfks5TT/0xZby
# DUplgWGg/rcSP7NgVTa4Zx1ioLu13LbBRdTMUMkzMt3j4i4MmY5Ct2vXCGA/RqW2
# fm9ctwH0VPkopCq8MUYSNAsy4w/syWQE3fYgCHdosEVSisWYgOX1eyxDgqaTwurk
# +53wgcTGtHEjfFJZM45CJgyDcfehCIcQW8Fs5oxbRKgNDAlyIaIT0GjOPQpkjfC/
# +CdQjwgpIytdjYeaQ+5jQiROl9HhqPemNRaHPE1Yooex644BjDC25dZn6+O0xvAn
# adg=
# SIG # End signature block
