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