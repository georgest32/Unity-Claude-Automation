#Requires -Version 5.1
<#
.SYNOPSIS
    Core configuration and logging infrastructure for SafeCommandExecution module.

.DESCRIPTION
    Provides centralized configuration management, thread-safe logging, and
    core security settings for the safe command execution framework.

.NOTES
    Part of SafeCommandExecution refactored architecture
    Originally from SafeCommandExecution.psm1 (lines 1-68)
    Refactoring Date: 2025-08-25
#>

#region Module Configuration

# Script-level configuration
$script:SafeCommandConfig = @{
    MaxExecutionTime = 300  # Maximum seconds for command execution
    AllowedPaths = @()      # Project boundaries
    BlockedCommands = @(    # Dangerous commands to block
        'Invoke-Expression',
        'iex',
        'Invoke-Command',
        'Add-Type',
        'New-Object System.Diagnostics.Process',
        'Start-Process cmd',
        'Start-Process powershell'
    )
}

# Thread-safe logging
$script:LogMutex = New-Object System.Threading.Mutex($false, "UnityClaudeAutomation")

#endregion

#region Logging Infrastructure

function Write-SafeLog {
    <#
    .SYNOPSIS
    Thread-safe logging function for safe command execution operations.
    
    .DESCRIPTION
    Provides synchronized logging to prevent file access conflicts in
    multi-threaded scenarios while maintaining console output.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet('Info', 'Warning', 'Error', 'Debug', 'Security')]
        [string]$Level = 'Info'
    )
    
    $logFile = Join-Path $PSScriptRoot "..\..\..\unity_claude_automation.log"
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
    $logEntry = "[$timestamp] [SafeCommand] [$Level] $Message"
    
    try {
        $acquired = $script:LogMutex.WaitOne(1000)
        if ($acquired) {
            Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
        }
    }
    finally {
        if ($acquired) {
            $script:LogMutex.ReleaseMutex()
        }
    }
    
    # Also output to console based on level
    switch ($Level) {
        'Error' { Write-Error $Message }
        'Warning' { Write-Warning $Message }
        'Debug' { Write-Debug $Message }
        'Security' { Write-Host "[SECURITY] $Message" -ForegroundColor Magenta }
        default { Write-Verbose $Message }
    }
}

#endregion

#region Configuration Management

function Get-SafeCommandConfig {
    <#
    .SYNOPSIS
    Returns the current safe command configuration.
    #>
    [CmdletBinding()]
    param()
    
    return $script:SafeCommandConfig.Clone()
}

function Set-SafeCommandConfig {
    <#
    .SYNOPSIS
    Updates the safe command configuration settings.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]$MaxExecutionTime,
        
        [Parameter()]
        [string[]]$AllowedPaths,
        
        [Parameter()]
        [string[]]$BlockedCommands
    )
    
    if ($PSBoundParameters.ContainsKey('MaxExecutionTime')) {
        $script:SafeCommandConfig.MaxExecutionTime = $MaxExecutionTime
        Write-SafeLog -Message "Updated MaxExecutionTime to $MaxExecutionTime seconds" -Level 'Info'
    }
    
    if ($PSBoundParameters.ContainsKey('AllowedPaths')) {
        $script:SafeCommandConfig.AllowedPaths = $AllowedPaths
        Write-SafeLog -Message "Updated AllowedPaths: $($AllowedPaths -join ', ')" -Level 'Info'
    }
    
    if ($PSBoundParameters.ContainsKey('BlockedCommands')) {
        $script:SafeCommandConfig.BlockedCommands = $BlockedCommands
        Write-SafeLog -Message "Updated BlockedCommands count: $($BlockedCommands.Count)" -Level 'Security'
    }
}

function Test-SafeCommandInitialization {
    <#
    .SYNOPSIS
    Tests if the safe command core is properly initialized.
    #>
    [CmdletBinding()]
    param()
    
    $isInitialized = $true
    $issues = @()
    
    # Check configuration
    if (-not $script:SafeCommandConfig) {
        $isInitialized = $false
        $issues += "Configuration not initialized"
    }
    
    # Check mutex
    if (-not $script:LogMutex) {
        $isInitialized = $false
        $issues += "Log mutex not initialized"
    }
    
    # Check log file accessibility
    $logFile = Join-Path $PSScriptRoot "..\..\..\unity_claude_automation.log"
    $logDir = Split-Path $logFile -Parent
    if (-not (Test-Path $logDir)) {
        $issues += "Log directory does not exist: $logDir"
    }
    
    return @{
        IsInitialized = $isInitialized
        Issues = $issues
        Configuration = if ($script:SafeCommandConfig) { $script:SafeCommandConfig } else { $null }
    }
}

#endregion

#region Module Exports

Export-ModuleMember -Function @(
    'Write-SafeLog',
    'Get-SafeCommandConfig',
    'Set-SafeCommandConfig',
    'Test-SafeCommandInitialization'
) -Variable @(
    'SafeCommandConfig',
    'LogMutex'
)

#endregion

# REFACTORING MARKER: This module was refactored from SafeCommandExecution.psm1 on 2025-08-25
# Original file size: 2860 lines
# This component: Core configuration and logging (lines 1-68)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCALNa8yEEQ/b5qa
# P1Vlo0NWkJhbgOJ0ryd5YMYZDt4UDqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIGy3sJOdKH/dH51GAlTOCsd7
# L0fz/XddmwzOi1jWuRJ3MA0GCSqGSIb3DQEBAQUABIIBABtQj0ytf+hY0RngOpp9
# s7JqrUQYlu0BBNfTDFx3DzQFRlM2b+OGloHPi6QBhI2Lof2FIxXdJd8m7x4rweF5
# lXaM5SNTiv/snMbH2Y37W/qrBKUlQdNE/ZfXMjbgtxUoOenhIZxCUjJIcyCJ9wU9
# lMwsMn7emmPierFbotW7zKlOl/cJ6l3vGaDSWqWzxT3CnC6NiKGHfpkbEFTcDzY4
# 5oN1aNjIMNGi/LSuSc8J7QUcQLi4Rf6m3wCEq9/RJLhf8zlLYGpKr4QCt0I4LXnn
# ADpA88xJ9+OGYpYhK7hjpaRvq30WgJ61M79uRF5pzjLInkHicW8ya+VtzXm88Q1m
# 09A=
# SIG # End signature block
