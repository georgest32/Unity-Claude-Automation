#Requires -Version 5.1
<#
.SYNOPSIS
    Security validation engine for SafeCommandExecution module.

.DESCRIPTION
    Provides comprehensive validation of commands, paths, and inputs to ensure
    safe execution within security boundaries.

.NOTES
    Part of SafeCommandExecution refactored architecture
    Originally from SafeCommandExecution.psm1 (lines 139-316)
    Refactoring Date: 2025-08-25
#>

# Import core module for logging
Import-Module "$PSScriptRoot\SafeCommandCore.psm1" -Force

#region Command Safety Validation

function Test-CommandSafety {
    <#
    .SYNOPSIS
    Validates command safety by checking for dangerous patterns and command types.
    
    .DESCRIPTION
    Performs comprehensive security checks on commands including pattern matching,
    command type validation, and path traversal detection.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Command
    )
    
    Write-SafeLog "Validating command safety: $($Command.CommandType)" -Level Security
    
    # Check for blocked patterns - separate literal and regex patterns
    $literalPatterns = @(
        'Invoke-Expression',
        'iex',
        'Invoke-Command',
        '`',         # Backtick escape
        '[char]',    # Character code execution (literal)
        'Start-Process cmd',
        'Start-Process powershell'
    )
    
    $regexPatterns = @(
        '\$\(.+\)',  # Subexpression execution
        'Add-Type.*-TypeDefinition',
        'New-Object.*Process',
        '&\s*\{',    # Script block invocation
        '\|.*iex'    # Pipe to invoke-expression
    )
    
    # Robust argument processing for mixed types (arrays, hashtables, etc.)
    $commandString = ""
    
    if ($Command.Arguments -is [array]) {
        # Handle array arguments
        $commandString = $Command.Arguments -join ' '
        Write-SafeLog "Processing array arguments: $commandString" -Level Debug
    }
    elseif ($Command.Arguments -is [hashtable]) {
        # Handle hashtable arguments - extract meaningful values
        $argParts = @()
        foreach ($key in $Command.Arguments.Keys) {
            $value = $Command.Arguments[$key]
            if ($value -is [string]) {
                $argParts += $value
            }
            elseif ($value -is [array]) {
                $argParts += ($value -join ' ')
            }
            else {
                $argParts += $value.ToString()
            }
        }
        $commandString = $argParts -join ' '
        Write-SafeLog "Processing hashtable arguments: $commandString" -Level Debug
    }
    elseif ($Command.Arguments -is [string]) {
        # Handle single string argument
        $commandString = $Command.Arguments
        Write-SafeLog "Processing string argument: $commandString" -Level Debug
    }
    else {
        # Handle other types - convert to string safely
        $commandString = $Command.Arguments.ToString()
        Write-SafeLog "Processing other argument type: $($Command.Arguments.GetType().Name)" -Level Debug
    }
    
    # Add debug logging for the actual command string being processed
    Write-SafeLog "Processing command string for pattern detection: '$commandString'" -Level Debug
    
    # Check literal patterns first (exact string matching)
    foreach ($pattern in $literalPatterns) {
        if ($commandString.Contains($pattern)) {
            Write-SafeLog "BLOCKED: Dangerous literal pattern detected: $pattern in command: $commandString" -Level Security
            return @{
                IsSafe = $false
                Reason = "Dangerous pattern detected: $pattern"
            }
        }
    }
    
    # Check regex patterns (pattern matching)
    foreach ($pattern in $regexPatterns) {
        if ($commandString -match $pattern) {
            Write-SafeLog "BLOCKED: Dangerous regex pattern detected: $pattern in command: $commandString" -Level Security
            return @{
                IsSafe = $false
                Reason = "Dangerous pattern detected: $pattern"
            }
        }
    }
    
    # Validate command type
    $allowedTypes = @('Unity', 'Test', 'Build', 'PowerShell', 'Analysis')
    if ($Command.CommandType -notin $allowedTypes) {
        Write-SafeLog "BLOCKED: Unknown command type: $($Command.CommandType)" -Level Security
        return @{
            IsSafe = $false
            Reason = "Unknown command type: $($Command.CommandType)"
        }
    }
    
    # Check for path traversal
    if ($Command.Arguments -match '\.\.[\\/]') {
        Write-SafeLog "BLOCKED: Path traversal attempt detected" -Level Security
        return @{
            IsSafe = $false
            Reason = "Path traversal attempt detected"
        }
    }
    
    Write-SafeLog "Command validated as SAFE" -Level Security
    return @{
        IsSafe = $true
        Reason = "All safety checks passed"
    }
}

#endregion

#region Path Safety Validation

function Test-PathSafety {
    <#
    .SYNOPSIS
    Validates that paths are within allowed boundaries.
    
    .DESCRIPTION
    Ensures file system operations remain within project boundaries
    to prevent unauthorized access to system files.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [Parameter()]
        [string[]]$AllowedPaths = @(
            $PSScriptRoot, 
            $env:TEMP,
            "$env:LOCALAPPDATA\Unity\Editor",
            "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation",
            "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Testing",
            "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Testing\TestData"
        )
    )
    
    try {
        $fullPath = [System.IO.Path]::GetFullPath($Path)
        
        foreach ($allowed in $AllowedPaths) {
            $allowedFull = [System.IO.Path]::GetFullPath($allowed)
            if ($fullPath.StartsWith($allowedFull)) {
                Write-SafeLog "Path validated within boundaries: $Path" -Level Debug
                return $true
            }
        }
        
        Write-SafeLog "BLOCKED: Path outside allowed boundaries: $Path" -Level Security
        return $false
    }
    catch {
        Write-SafeLog "Path validation failed: $($_.Exception.Message)" -Level Error
        return $false
    }
}

#endregion

#region Input Sanitization

function Remove-DangerousCharacters {
    <#
    .SYNOPSIS
    Removes or escapes dangerous characters from input strings.
    
    .DESCRIPTION
    Sanitizes input by removing characters that could be used for
    command injection or other security exploits.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Input
    )
    
    # Remove or escape dangerous characters
    $cleaned = $Input -replace '[;&|`$]', ''
    $cleaned = $cleaned -replace '<', ''
    $cleaned = $cleaned -replace '>', ''
    $cleaned = $cleaned -replace '\$\(', ''
    $cleaned = $cleaned -replace '\)', ''
    
    if ($cleaned -ne $Input) {
        Write-SafeLog "Sanitized input: removed dangerous characters" -Level Security
    }
    
    return $cleaned
}

function Test-InputValidity {
    <#
    .SYNOPSIS
    Comprehensive input validation for various data types.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        $Input,
        
        [Parameter()]
        [ValidateSet('String', 'Path', 'Command', 'Script')]
        [string]$InputType = 'String'
    )
    
    $isValid = $true
    $issues = @()
    
    switch ($InputType) {
        'Path' {
            if (-not (Test-PathSafety -Path $Input)) {
                $isValid = $false
                $issues += "Path is outside allowed boundaries"
            }
        }
        'Command' {
            $safetyCheck = Test-CommandSafety -Command @{CommandType='PowerShell'; Arguments=$Input}
            if (-not $safetyCheck.IsSafe) {
                $isValid = $false
                $issues += $safetyCheck.Reason
            }
        }
        'Script' {
            if ($Input -match 'Invoke-Expression|iex|\$\(.+\)') {
                $isValid = $false
                $issues += "Script contains dangerous patterns"
            }
        }
        default {
            # Basic string validation
            if ($Input.Length -gt 10000) {
                $isValid = $false
                $issues += "Input exceeds maximum length"
            }
        }
    }
    
    return @{
        IsValid = $isValid
        Issues = $issues
        SanitizedInput = if (-not $isValid -and $InputType -eq 'String') { 
            Remove-DangerousCharacters -Input $Input 
        } else { 
            $Input 
        }
    }
}

#endregion

#region Module Exports

Export-ModuleMember -Function @(
    'Test-CommandSafety',
    'Test-PathSafety',
    'Remove-DangerousCharacters',
    'Test-InputValidity'
)

#endregion

# REFACTORING MARKER: This module was refactored from SafeCommandExecution.psm1 on 2025-08-25
# Original file size: 2860 lines
# This component: Security validation engine (lines 139-316)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA1BPhn7gft6myA
# BDWWq0lZfqQ6b2b+9CzB3TAw1iKZr6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEILXyJXEeL82T19vY+ljQFZYs
# fw6kofNH0YjUORPHl4ChMA0GCSqGSIb3DQEBAQUABIIBAK5uZnmPzg02PQUP16dS
# iNSBAJ/zMA5wDMLyZ+NONBQZsPeZJ/CW9g9Xh1tS1W9hRdiN6j3iw2l823BicGiz
# CK2t8Il/zGfoiL6U/Gsr4JLRsYKdPhdQ1uXmbND5lez0Gh9kjBejqH4lw5bcWW+H
# 9IvpEmB0yiYJWOrSyc3EDa4N+QISoVSheJ5LBcUpYou3cTSZFMmxpC9skI3cGyzo
# KSJtclRVwjtb8I6kwQHZGGEGpFctAgRjPuOatE4D+uWe+jqKO+UdXNodkIzQ0n9b
# 1vxyq1CVvBQbtoMtjhAo3Gakc3bC8dTshuU2uD8VZHSkBDo2wN2AcPFPVz3l2VOm
# xGQ=
# SIG # End signature block
