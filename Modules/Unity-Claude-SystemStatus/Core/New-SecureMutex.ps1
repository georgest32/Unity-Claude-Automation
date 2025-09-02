# Helper function for logging - handles case where Write-SystemStatusLog isn't loaded yet
function Write-SecurityLog {
    param($Message, $Level = 'INFO')
    if (Get-Command Write-SystemStatusLog -ErrorAction SilentlyContinue) {
        Write-SystemStatusLog $Message -Level $Level
    } else {
        # Fallback to Write-Verbose if SystemStatusLog isn't available
        Write-Verbose "[$Level] $Message"
    }
}

function New-SecureMutex {
    <#
    .SYNOPSIS
    Creates a mutex with secure permissions for subsystem singleton enforcement.
    
    .DESCRIPTION
    Creates a System.Threading.Mutex with appropriate security settings to prevent
    privilege escalation and ensure proper access control. Implements defense-in-depth
    security measures.
    
    .PARAMETER MutexName
    The name of the mutex to create. Should follow pattern: Global\Name or Local\Name
    
    .PARAMETER InitialOwner
    Whether the calling thread should initially own the mutex.
    
    .PARAMETER StrictSecurity
    Enable strict security mode with minimal permissions.
    
    .EXAMPLE
    New-SecureMutex -MutexName "Global\UnityClaudeSubsystem" -StrictSecurity
    
    .OUTPUTS
    PSCustomObject containing Mutex object and security metadata
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^(Global\\|Local\\)?[A-Za-z0-9_]+$')]
        [string]$MutexName,
        
        [Parameter()]
        [bool]$InitialOwner = $false,
        
        [Parameter()]
        [switch]$StrictSecurity
    )
    
    Write-SecurityLog "Creating secure mutex: $MutexName" 'DEBUG'
    
    try {
        # Validate mutex name for security
        if ($MutexName -match '[^A-Za-z0-9_\\]') {
            throw "Mutex name contains invalid characters"
        }
        
        # Determine if global or local mutex
        $isGlobal = $MutexName -match '^Global\\'
        $isLocal = $MutexName -match '^Local\\'
        
        if (-not $isGlobal -and -not $isLocal) {
            # Default to Local for security
            $MutexName = "Local\$MutexName"
            $isLocal = $true
            Write-SecurityLog "Defaulting to Local mutex for security" 'TRACE'
        }
        
        # Create mutex security object
        $mutexSecurity = New-Object System.Security.AccessControl.MutexSecurity
        
        # Get current user identity
        $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $currentSid = $currentUser.User
        
        # Define access rules based on security mode
        if ($StrictSecurity) {
            Write-SecurityLog "Applying strict security rules to mutex" 'TRACE'
            
            # Only current user has access
            $userRule = New-Object System.Security.AccessControl.MutexAccessRule(
                $currentSid,
                [System.Security.AccessControl.MutexRights]::FullControl,
                [System.Security.AccessControl.AccessControlType]::Allow
            )
            $mutexSecurity.AddAccessRule($userRule)
            
            # Explicitly deny Everyone group if global
            if ($isGlobal) {
                $everyoneSid = New-Object System.Security.Principal.SecurityIdentifier(
                    [System.Security.Principal.WellKnownSidType]::WorldSid, 
                    $null
                )
                $denyRule = New-Object System.Security.AccessControl.MutexAccessRule(
                    $everyoneSid,
                    [System.Security.AccessControl.MutexRights]::ChangePermissions,
                    [System.Security.AccessControl.AccessControlType]::Deny
                )
                $mutexSecurity.AddAccessRule($denyRule)
            }
        } else {
            Write-SecurityLog "Applying standard security rules to mutex" 'TRACE'
            
            # Current user has full control
            $userRule = New-Object System.Security.AccessControl.MutexAccessRule(
                $currentSid,
                [System.Security.AccessControl.MutexRights]::FullControl,
                [System.Security.AccessControl.AccessControlType]::Allow
            )
            $mutexSecurity.AddAccessRule($userRule)
            
            # Administrators group has full control
            $adminsSid = New-Object System.Security.Principal.SecurityIdentifier(
                [System.Security.Principal.WellKnownSidType]::BuiltinAdministratorsSid,
                $null
            )
            $adminsRule = New-Object System.Security.AccessControl.MutexAccessRule(
                $adminsSid,
                [System.Security.AccessControl.MutexRights]::FullControl,
                [System.Security.AccessControl.AccessControlType]::Allow
            )
            $mutexSecurity.AddAccessRule($adminsRule)
            
            # SYSTEM has full control
            $systemSid = New-Object System.Security.Principal.SecurityIdentifier(
                [System.Security.Principal.WellKnownSidType]::LocalSystemSid,
                $null
            )
            $systemRule = New-Object System.Security.AccessControl.MutexAccessRule(
                $systemSid,
                [System.Security.AccessControl.MutexRights]::FullControl,
                [System.Security.AccessControl.AccessControlType]::Allow
            )
            $mutexSecurity.AddAccessRule($systemRule)
            
            # For global mutex, allow Users group to synchronize only (not modify)
            if ($isGlobal) {
                $usersSid = New-Object System.Security.Principal.SecurityIdentifier(
                    [System.Security.Principal.WellKnownSidType]::BuiltinUsersSid,
                    $null
                )
                $usersRule = New-Object System.Security.AccessControl.MutexAccessRule(
                    $usersSid,
                    [System.Security.AccessControl.MutexRights]::Synchronize,
                    [System.Security.AccessControl.AccessControlType]::Allow
                )
                $mutexSecurity.AddAccessRule($usersRule)
            }
        }
        
        # Set owner to current user
        $mutexSecurity.SetOwner($currentSid)
        
        # Protect from inheritance
        $mutexSecurity.SetAccessRuleProtection($true, $false)
        
        # Create the mutex with security settings
        $createdNew = $false
        $mutex = New-Object System.Threading.Mutex(
            $InitialOwner,
            $MutexName,
            [ref]$createdNew,
            $mutexSecurity
        )
        
        # Log creation status
        if ($createdNew) {
            Write-SecurityLog "Successfully created new secure mutex: $MutexName" 'OK'
        } else {
            Write-SecurityLog "Opened existing mutex: $MutexName" 'DEBUG'
        }
        
        # Create result object with security metadata
        $result = [PSCustomObject]@{
            Mutex = $mutex
            Name = $MutexName
            CreatedNew = $createdNew
            IsGlobal = $isGlobal
            IsLocal = $isLocal
            StrictSecurity = $StrictSecurity.IsPresent
            Owner = $currentUser.Name
            OwnerSid = $currentSid.Value
            CreatedAt = Get-Date
            SecurityDescriptor = $mutexSecurity.GetSecurityDescriptorSddlForm([System.Security.AccessControl.AccessControlSections]::All)
        }
        
        # Validate mutex is working
        try {
            $acquired = $mutex.WaitOne(0)
            if ($acquired -and -not $InitialOwner) {
                $mutex.ReleaseMutex()
            }
            $result | Add-Member -NotePropertyName 'ValidationStatus' -NotePropertyValue 'OK'
        } catch {
            $result | Add-Member -NotePropertyName 'ValidationStatus' -NotePropertyValue "Warning: $_"
            Write-SecurityLog "Mutex validation warning: $_" 'WARN'
        }
        
        return $result
        
    } catch {
        Write-SecurityLog "Failed to create secure mutex: $_" 'ERROR'
        throw
    }
}

function Test-MutexSecurity {
    <#
    .SYNOPSIS
    Tests the security configuration of an existing mutex.
    
    .DESCRIPTION
    Analyzes the security settings of a mutex to identify potential vulnerabilities
    or misconfigurations.
    
    .PARAMETER Mutex
    The mutex object or name to test.
    
    .PARAMETER DetailedReport
    Generate a detailed security report.
    
    .EXAMPLE
    Test-MutexSecurity -Mutex $mutexObject -DetailedReport
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Mutex,
        
        [Parameter()]
        [switch]$DetailedReport
    )
    
    Write-SecurityLog "Testing mutex security" 'DEBUG'
    
    try {
        # Get mutex object if name was provided
        if ($Mutex -is [string]) {
            try {
                $mutexObj = [System.Threading.Mutex]::OpenExisting($Mutex)
            } catch {
                throw "Cannot open mutex '$Mutex': $_"
            }
        } else {
            $mutexObj = $Mutex
        }
        
        # Get mutex security
        $mutexSecurity = $mutexObj.GetAccessControl()
        
        # Initialize report
        $issues = @()
        $warnings = @()
        $info = @()
        
        # Check owner
        $owner = $mutexSecurity.GetOwner([System.Security.Principal.SecurityIdentifier])
        $ownerAccount = $owner.Translate([System.Security.Principal.NTAccount])
        
        if ($ownerAccount.Value -match 'Everyone|Guest') {
            $issues += "Mutex owned by untrusted account: $($ownerAccount.Value)"
        }
        
        # Analyze access rules
        $rules = $mutexSecurity.GetAccessRules($true, $true, [System.Security.Principal.SecurityIdentifier])
        
        foreach ($rule in $rules) {
            try {
                $identity = $rule.IdentityReference.Translate([System.Security.Principal.NTAccount])
            } catch {
                $identity = $rule.IdentityReference
            }
            
            # Check for overly permissive rules
            if ($rule.AccessControlType -eq 'Allow') {
                if ($identity.Value -match 'Everyone' -and 
                    $rule.MutexRights -band [System.Security.AccessControl.MutexRights]::ChangePermissions) {
                    $issues += "Everyone has ChangePermissions rights"
                }
                
                if ($identity.Value -match 'Everyone' -and 
                    $rule.MutexRights -band [System.Security.AccessControl.MutexRights]::TakeOwnership) {
                    $issues += "Everyone has TakeOwnership rights"
                }
                
                if ($identity.Value -match 'Guest' -and 
                    $rule.MutexRights -ne [System.Security.AccessControl.MutexRights]::Synchronize) {
                    $warnings += "Guest account has elevated permissions"
                }
            }
            
            if ($DetailedReport) {
                $info += "$($rule.AccessControlType): $($identity.Value) - $($rule.MutexRights)"
            }
        }
        
        # Check for inheritance
        if (-not $mutexSecurity.AreAccessRulesProtected) {
            $warnings += "Mutex allows permission inheritance"
        }
        
        # Create report
        $report = [PSCustomObject]@{
            IsSecure = ($issues.Count -eq 0)
            Owner = $ownerAccount.Value
            Issues = $issues
            Warnings = $warnings
            Info = if ($DetailedReport) { $info } else { @() }
            RuleCount = $rules.Count
            InheritanceProtected = $mutexSecurity.AreAccessRulesProtected
            Timestamp = Get-Date
        }
        
        # Log results
        if ($report.IsSecure) {
            Write-SecurityLog "Mutex security check PASSED" 'OK'
        } else {
            Write-SecurityLog "Mutex security check FAILED: $($issues -join '; ')" 'WARN'
        }
        
        return $report
        
    } catch {
        Write-SecurityLog "Failed to test mutex security: $_" 'ERROR'
        throw
    } finally {
        if ($mutexObj -and $Mutex -is [string]) {
            # Clean up if we opened the mutex
            $mutexObj.Dispose()
        }
    }
}

# Export the functions
Export-ModuleMember -Function New-SecureMutex, Test-MutexSecurity
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDIUTUn1d8KXVoX
# GQlEOXjajUGzW9NNJ3sQiG67N7rxwKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEILcvLpFGEywAGr0dRCfNKhZz
# AqQD+VQVQekK0Il3fDSrMA0GCSqGSIb3DQEBAQUABIIBAHsij/iy323/5pqsGv5M
# cnQKpgu+rt+Td/KvMlldO5B3SD6RsoXy16Uwa0v0YNTxcDqUy8g8Z4q0NQrcQ/tT
# FlMvoGqMLLfI0WPXcIe6KP9Q4HeRPaCfIpyNAFxShO0JefnVhHCB5k4IeP4/X0uM
# 5AbJBGD5zF5RV858IkdYjJUYbQKrbM776WbsyJp7TgxxFkbfjWKP8QMa3CfcycFA
# ZdWEuCOOadHjo14dVQ0mANP4/c0M0yvEyiL7DSY4SdsEQ+bCfOWSXREJ6UI7clkl
# MOLadIz4sn/OI/ngqGwsHTRJS/tPEeokNxDGv7U47T+jLB1NpJfr7XnyjslfXoeX
# 4EU=
# SIG # End signature block
