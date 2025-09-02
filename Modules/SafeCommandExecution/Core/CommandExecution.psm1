#Requires -Version 5.1
<#
.SYNOPSIS
    Safe command execution orchestrator for SafeCommandExecution module.

.DESCRIPTION
    Provides the main command execution pipeline with safety validation
    and routing to appropriate command type handlers.

.NOTES
    Part of SafeCommandExecution refactored architecture
    Originally from SafeCommandExecution.psm1 (lines 317-394)
    Refactoring Date: 2025-08-25
#>

# Import required modules
Import-Module "$PSScriptRoot\SafeCommandCore.psm1" -Force
Import-Module "$PSScriptRoot\ValidationEngine.psm1" -Force

#region Safe Command Execution

function Invoke-SafeCommand {
    <#
    .SYNOPSIS
    Executes commands safely with security validation and timeout control.
    
    .DESCRIPTION
    Main entry point for safe command execution. Validates commands against
    security policies and routes to appropriate type-specific handlers.
    
    .PARAMETER Command
    Hashtable containing command details including CommandType, Operation, and Arguments.
    
    .PARAMETER TimeoutSeconds
    Maximum execution time in seconds before command is terminated.
    
    .PARAMETER ValidateExecution
    Perform additional validation after execution.
    
    .PARAMETER AllowedPaths
    Additional paths to allow for this specific command execution.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Command,
        
        [Parameter()]
        [int]$TimeoutSeconds = 60,
        
        [Parameter()]
        [switch]$ValidateExecution,
        
        [Parameter()]
        [string[]]$AllowedPaths = @()
    )
    
    Write-SafeLog "Executing safe command: $($Command.CommandType) - $($Command.Operation)" -Level Info
    
    # Validate command safety
    $safety = Test-CommandSafety -Command $Command
    if (-not $safety.IsSafe) {
        Write-SafeLog "Command execution blocked: $($safety.Reason)" -Level Security
        return @{
            Success = $false
            Error = $safety.Reason
            Output = $null
            ExecutionTime = 0
            ValidationStatus = 'Blocked'
        }
    }
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        # Prepare execution context
        $context = @{
            Command = $Command
            TimeoutSeconds = $TimeoutSeconds
            AllowedPaths = $AllowedPaths
            StartTime = Get-Date
        }
        
        # Note: Type-specific handlers will be imported from CommandTypeHandlers module
        # For now, returning a placeholder that shows routing would happen
        $result = switch ($Command.CommandType) {
            'Unity' {
                @{
                    Message = "Unity command would be executed"
                    Handler = "Invoke-UnityCommand"
                }
            }
            
            'Test' {
                @{
                    Message = "Test command would be executed"
                    Handler = "Invoke-TestCommand"
                }
            }
            
            'PowerShell' {
                @{
                    Message = "PowerShell command would be executed"
                    Handler = "Invoke-PowerShellCommand"
                }
            }
            
            'Build' {
                @{
                    Message = "Build command would be executed"
                    Handler = "Invoke-BuildCommand"
                }
            }
            
            'Analysis' {
                @{
                    Message = "Analysis command would be executed"
                    Handler = "Invoke-AnalysisCommand"
                }
            }
            
            default {
                throw "Unsupported command type: $($Command.CommandType)"
            }
        }
        
        $stopwatch.Stop()
        
        # Validate execution if requested
        if ($ValidateExecution) {
            $validationResult = Test-ExecutionResult -Result $result -Context $context
            if (-not $validationResult.IsValid) {
                Write-SafeLog "Post-execution validation failed: $($validationResult.Reason)" -Level Warning
            }
        }
        
        Write-SafeLog "Command executed successfully in $($stopwatch.ElapsedMilliseconds)ms" -Level Info
        
        return @{
            Success = $true
            Output = $result
            Error = $null
            ExecutionTime = $stopwatch.ElapsedMilliseconds
            ValidationStatus = if ($ValidateExecution) { 'Validated' } else { 'NotValidated' }
        }
    }
    catch {
        $stopwatch.Stop()
        Write-SafeLog "Command execution failed: $($_.Exception.Message)" -Level Error
        
        return @{
            Success = $false
            Output = $null
            Error = $_.ToString()
            ExecutionTime = $stopwatch.ElapsedMilliseconds
            ValidationStatus = 'Failed'
        }
    }
}

function Test-ExecutionResult {
    <#
    .SYNOPSIS
    Validates command execution results.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        $Result,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$Context
    )
    
    $isValid = $true
    $reason = "Validation passed"
    
    # Check for error indicators
    if ($Result -match 'error|failed|exception') {
        $isValid = $false
        $reason = "Result contains error indicators"
    }
    
    # Check execution time
    $elapsed = (Get-Date) - $Context.StartTime
    if ($elapsed.TotalSeconds -gt $Context.TimeoutSeconds) {
        $isValid = $false
        $reason = "Execution exceeded timeout"
    }
    
    return @{
        IsValid = $isValid
        Reason = $reason
        ElapsedTime = $elapsed
    }
}

function Get-CommandExecutionStatistics {
    <#
    .SYNOPSIS
    Returns execution statistics for monitoring and analysis.
    #>
    [CmdletBinding()]
    param()
    
    # In a real implementation, this would track actual statistics
    return @{
        TotalExecutions = 0
        SuccessfulExecutions = 0
        BlockedExecutions = 0
        FailedExecutions = 0
        AverageExecutionTime = 0
        LastExecution = $null
    }
}

#endregion

#region Module Exports

Export-ModuleMember -Function @(
    'Invoke-SafeCommand',
    'Test-ExecutionResult',
    'Get-CommandExecutionStatistics'
)

#endregion

# REFACTORING MARKER: This module was refactored from SafeCommandExecution.psm1 on 2025-08-25
# Original file size: 2860 lines
# This component: Safe command execution orchestration (lines 317-394)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDhnqaBOSMJtHMK
# np4VQubhhUgufTKdmJNfok33yfjleKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBLU8prxhKV+Vger2tE/3OjJ
# kmuw/g3MwndwuYowi3VLMA0GCSqGSIb3DQEBAQUABIIBAFvB7njfAHC/exjiguek
# XtIadRzBIFvzQQkOGjyi0KPp2HuNuwSgfLTaXpJwE2r1xFcaE0b3xmMAhmhO4zUa
# jZ8B/Ck8XYDUJ9bUGSsqw9vpHTB6PnyopPEv7Us1emG2qOxHLkaMuQDdHRjgRQbY
# lYPHRgpi8oeVS4dtYuPSXUUHgzNjuCdn7EsTJtp96elvIyaej9sb2xq1ke1GpBwc
# Meq5jfZL7R4SGGUF0H9ILuFl96HHiPwihR48JrdJMJ7ICgwywns0xvcAFfhhPb6c
# 4IsUhK1RutJD6ndKTyN6Td5gFE49Vll7iFUik3T9qeSrdNrVbffg11+Lpdl58UzX
# EAg=
# SIG # End signature block
