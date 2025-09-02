#Requires -Version 5.1
<#
.SYNOPSIS
    Constrained runspace creation and management for SafeCommandExecution module.

.DESCRIPTION
    Provides secure runspace creation with constrained language mode and
    limited command access for safe execution of potentially untrusted code.

.NOTES
    Part of SafeCommandExecution refactored architecture
    Originally from SafeCommandExecution.psm1 (lines 69-138)
    Refactoring Date: 2025-08-25
#>

# Import core module for logging
Import-Module "$PSScriptRoot\SafeCommandCore.psm1" -Force

#region Constrained Runspace Creation

function New-ConstrainedRunspace {
    <#
    .SYNOPSIS
    Creates a constrained runspace with limited command access.
    
    .DESCRIPTION
    Creates a PowerShell runspace with constrained language mode and
    only specified commands available for secure code execution.
    
    .PARAMETER AllowedCommands
    List of commands that will be available in the constrained runspace.
    
    .PARAMETER Variables
    Variables to pre-populate in the runspace.
    
    .PARAMETER Modules
    Modules to import into the runspace.
    #>
    [CmdletBinding()]
    param (
        [Parameter()]
        [string[]]$AllowedCommands = @(
            'Get-Content', 'Set-Content', 'Add-Content',
            'Test-Path', 'Get-ChildItem', 'Join-Path',
            'Split-Path', 'Resolve-Path', 'Get-Item',
            'Get-Date', 'Measure-Command', 'Select-Object',
            'Where-Object', 'ForEach-Object', 'Sort-Object',
            'ConvertTo-Json', 'ConvertFrom-Json',
            'Write-Output', 'Write-Host', 'Out-String'
        ),
        
        [Parameter()]
        [hashtable]$Variables = @{},
        
        [Parameter()]
        [string[]]$Modules = @()
    )
    
    Write-SafeLog "Creating constrained runspace with $($AllowedCommands.Count) allowed commands" -Level Debug
    
    try {
        # Create initial session state
        $iss = [System.Management.Automation.Runspaces.InitialSessionState]::Create()
        $iss.LanguageMode = [System.Management.Automation.PSLanguageMode]::ConstrainedLanguage
        
        # Add only allowed commands
        foreach ($cmd in $AllowedCommands) {
            $cmdlet = Get-Command $cmd -ErrorAction SilentlyContinue
            if ($cmdlet) {
                $entry = New-Object System.Management.Automation.Runspaces.SessionStateCmdletEntry(
                    $cmd, 
                    $cmdlet.ImplementingType,
                    $null
                )
                $iss.Commands.Add($entry)
                Write-SafeLog "Added allowed command: $cmd" -Level Debug
            }
        }
        
        # Add variables
        foreach ($var in $Variables.GetEnumerator()) {
            $entry = New-Object System.Management.Automation.Runspaces.SessionStateVariableEntry(
                $var.Key,
                $var.Value,
                $null
            )
            $iss.Variables.Add($entry)
            Write-SafeLog "Added variable: $($var.Key)" -Level Debug
        }
        
        # Create runspace
        $runspace = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace($iss)
        $runspace.Open()
        
        Write-SafeLog "Constrained runspace created successfully" -Level Info
        return $runspace
    }
    catch {
        Write-SafeLog "Failed to create constrained runspace: $($_.Exception.Message)" -Level Error
        throw
    }
}

function Remove-ConstrainedRunspace {
    <#
    .SYNOPSIS
    Safely disposes of a constrained runspace.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.Runspaces.Runspace]$Runspace
    )
    
    try {
        if ($Runspace -and $Runspace.RunspaceStateInfo.State -ne 'Closed') {
            $Runspace.Close()
            $Runspace.Dispose()
            Write-SafeLog "Constrained runspace disposed successfully" -Level Debug
        }
    }
    catch {
        Write-SafeLog "Error disposing runspace: $($_.Exception.Message)" -Level Warning
    }
}

function Test-RunspaceHealth {
    <#
    .SYNOPSIS
    Tests if a runspace is healthy and available for use.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.Runspaces.Runspace]$Runspace
    )
    
    if (-not $Runspace) {
        return $false
    }
    
    $state = $Runspace.RunspaceStateInfo.State
    return $state -eq 'Opened'
}

#endregion

#region Module Exports

Export-ModuleMember -Function @(
    'New-ConstrainedRunspace',
    'Remove-ConstrainedRunspace',
    'Test-RunspaceHealth'
)

#endregion

# REFACTORING MARKER: This module was refactored from SafeCommandExecution.psm1 on 2025-08-25
# Original file size: 2860 lines
# This component: Constrained runspace management (lines 69-138)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDt4PMdttlwSs79
# KuWPLy/6YvFYa+PiLWU+NpWTBa6aaaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEINsJ8OeEOQDtBmVk+I5wpMkp
# 2D5kWqYNV7eRwgUwawI/MA0GCSqGSIb3DQEBAQUABIIBADUCDcgUqK0JBigdjosf
# PkAe5LEjyuo3xzw8IbDfU9TQZtJIMQNpVx4UDxVjx8NBzbcGdB1mespOyzQT8cUx
# UPfG3RaDQAARlVwLhMcQNrW/dVx1g4Yr4F09f2bRcnsCKj+SS6TxoGd2Tu+XFsu/
# lqm353wmdKSYt/BMz0Dn7jiizUWFAZQUgMe8/U5FKHna6AcbHTQeh6vmUznOJ/rq
# 9k+PlbpgnemgEUI9abctO7tUPNnhXoUArwdfgpegs7pVKU0C2p+a8XBpzKm1BgqI
# dZXPhI3GUc3LZ7Ka7Hsi+uYCCGxKPKjhxKCK+2iqbHtpPhByBJ6chTMuSa5qIJLz
# B4Q=
# SIG # End signature block
