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

function Test-ManifestSecurity {
    <#
    .SYNOPSIS
    Validates manifest security and prevents path traversal and injection attacks.
    
    .DESCRIPTION
    Performs comprehensive security validation on manifest data including:
    - Path traversal prevention
    - Command injection prevention
    - Script block validation
    - Resource limit validation
    - Mutex permission checks
    
    .PARAMETER Manifest
    The manifest hashtable to validate.
    
    .PARAMETER StrictMode
    Enable strict security validation (recommended for production).
    
    .EXAMPLE
    Test-ManifestSecurity -Manifest $manifestData -StrictMode
    
    .OUTPUTS
    PSCustomObject with IsSecure, SecurityIssues, and Recommendations
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Manifest,
        
        [Parameter()]
        [switch]$StrictMode
    )
    
    Write-SecurityLog "Starting security validation for manifest: $($Manifest.Name)" 'DEBUG'
    
    $securityIssues = @()
    $recommendations = @()
    $isSecure = $true
    
    # 1. Path Traversal Prevention
    Write-SecurityLog "Checking for path traversal attempts..." 'TRACE'
    
    $pathFields = @('StartScript', 'HealthCheckScript', 'StopScript', 'ConfigFile', 'LogPath')
    foreach ($field in $pathFields) {
        if ($Manifest.$field) {
            $path = $Manifest.$field
            
            # Check for dangerous patterns
            $dangerousPatterns = @(
                '\.\.\\',           # Parent directory traversal (Windows)
                '\.\.\/',          # Parent directory traversal (Unix)
                '\.\./',           # Parent directory traversal (Unix alternative)
                '\\\\',            # UNC path
                ':',               # Drive specification (except at position 1)
                '\$\(',            # Command substitution
                '`',               # PowerShell escape character
                '|',               # Pipe operator
                ';',               # Command separator
                '&',               # Background execution
                '>',               # Redirect output
                '<',               # Redirect input
                '\*',              # Wildcard (in certain contexts)
                '\?',              # Wildcard (in certain contexts)
                '\[',              # Wildcard pattern
                '\]',              # Wildcard pattern
                '%',               # Environment variable (Windows)
                '\$env:',          # Environment variable (PowerShell)
                '\${',             # Variable expansion
                '~'                # Home directory expansion
            )
            
            foreach ($pattern in $dangerousPatterns) {
                # Special handling for colon (allow only at position 1 for drive letters)
                if ($pattern -eq ':') {
                    if ($path -match ':' -and $path.IndexOf(':') -ne 1) {
                        $securityIssues += "Path traversal risk in $field`: Contains colon not in drive position"
                        $isSecure = $false
                        Write-SecurityLog "SECURITY WARNING: Colon found in non-drive position in $field" 'WARN'
                    }
                } else {
                    if ($path -match [regex]::Escape($pattern)) {
                        $securityIssues += "Path traversal risk in $field`: Contains dangerous pattern '$pattern'"
                        $isSecure = $false
                        Write-SecurityLog "SECURITY WARNING: Dangerous pattern '$pattern' found in $field" 'WARN'
                    }
                }
            }
            
            # Validate absolute vs relative paths
            if ($StrictMode) {
                # In strict mode, require relative paths (safer)
                if ([System.IO.Path]::IsPathRooted($path)) {
                    $recommendations += "Consider using relative path for $field instead of absolute path"
                    Write-SecurityLog "SECURITY NOTE: Absolute path used in $field (consider relative)" 'DEBUG'
                }
            }
            
            # Normalize and validate path
            try {
                # Resolve relative paths from project root, not current directory
                $projectRoot = if ($script:ProjectRootPath) {
                    $script:ProjectRootPath
                } else {
                    # Navigate from SystemStatus module to project root
                    $moduleBase = Split-Path $PSScriptRoot -Parent  # Up from Core to SystemStatus
                    $modulesDir = Split-Path $moduleBase -Parent    # Up to Modules
                    Split-Path $modulesDir -Parent                 # Up to project root
                }
                
                Write-SecurityLog "Project root resolved to: $projectRoot" 'TRACE'
                Write-SecurityLog "Resolving path '$path' from project root" 'TRACE'
                
                # Resolve path relative to project root if it's relative
                if ([System.IO.Path]::IsPathRooted($path)) {
                    $normalizedPath = [System.IO.Path]::GetFullPath($path)
                } else {
                    # Join relative path with project root
                    $combinedPath = Join-Path $projectRoot $path
                    $normalizedPath = [System.IO.Path]::GetFullPath($combinedPath)
                }
                
                Write-SecurityLog "Normalized path: $normalizedPath" 'TRACE'
                
                # Check if normalized path escapes expected boundaries
                if ($StrictMode -and -not $normalizedPath.StartsWith($projectRoot)) {
                    $securityIssues += "Path in $field escapes module boundary: $normalizedPath"
                    $isSecure = $false
                    Write-SecurityLog "SECURITY WARNING: Path escapes module boundary in $field" 'WARN'
                }
            } catch {
                $securityIssues += "Invalid path in $field`: $_"
                $isSecure = $false
                Write-SecurityLog "SECURITY WARNING: Invalid path in $field`: $_" 'WARN'
            }
        }
    }
    
    # 2. Command Injection Prevention
    Write-SecurityLog "Checking for command injection risks..." 'TRACE'
    
    $commandFields = @('StartCommand', 'StopCommand', 'HealthCheckCommand', 'CustomCommands')
    foreach ($field in $commandFields) {
        if ($Manifest.$field) {
            $command = $Manifest.$field
            
            # Check for dangerous command patterns
            if ($command -match '\$\(|\`|Invoke-Expression|iex|Start-Process -ArgumentList|cmd /c|powershell -c') {
                $securityIssues += "Command injection risk in $field"
                $isSecure = $false
                Write-SecurityLog "SECURITY WARNING: Command injection pattern found in $field" 'WARN'
            }
        }
    }
    
    # 3. Script Block Validation
    Write-SecurityLog "Validating script blocks..." 'TRACE'
    
    $scriptFields = @('InitializationScript', 'CleanupScript', 'ValidationScript')
    foreach ($field in $scriptFields) {
        if ($Manifest.$field) {
            if ($Manifest.$field -is [scriptblock]) {
                # Analyze script block for dangerous operations
                $scriptText = $Manifest.$field.ToString()
                
                $dangerousCommands = @(
                    'Invoke-Expression',
                    'iex',
                    'Invoke-WebRequest',
                    'Invoke-RestMethod',
                    'New-Object System.Net.WebClient',
                    'Start-Process',
                    'Stop-Process -Force',
                    'Remove-Item -Recurse -Force',
                    'Set-ExecutionPolicy',
                    'Unblock-File',
                    'Enable-PSRemoting',
                    'Enter-PSSession',
                    'New-PSSession'
                )
                
                foreach ($dangerous in $dangerousCommands) {
                    if ($scriptText -match $dangerous) {
                        if ($StrictMode) {
                            $securityIssues += "Potentially dangerous command '$dangerous' in $field"
                            $isSecure = $false
                            Write-SecurityLog "SECURITY WARNING: Dangerous command '$dangerous' in $field" 'WARN'
                        } else {
                            $recommendations += "Review use of '$dangerous' in $field for security implications"
                            Write-SecurityLog "SECURITY NOTE: Potentially dangerous command '$dangerous' in $field" 'DEBUG'
                        }
                    }
                }
            }
        }
    }
    
    # 4. Resource Limit Validation
    Write-SecurityLog "Validating resource limits..." 'TRACE'
    
    if ($Manifest.MaxMemoryMB) {
        if ($Manifest.MaxMemoryMB -lt 10 -or $Manifest.MaxMemoryMB -gt 8192) {
            $recommendations += "MaxMemoryMB value ($($Manifest.MaxMemoryMB)) seems unusual (expected 10-8192)"
            Write-SecurityLog "Resource limit warning: MaxMemoryMB=$($Manifest.MaxMemoryMB)" 'DEBUG'
        }
    }
    
    if ($Manifest.MaxCpuPercent) {
        if ($Manifest.MaxCpuPercent -lt 1 -or $Manifest.MaxCpuPercent -gt 100) {
            $securityIssues += "Invalid MaxCpuPercent value: $($Manifest.MaxCpuPercent)"
            $isSecure = $false
            Write-SecurityLog "SECURITY WARNING: Invalid MaxCpuPercent value" 'WARN'
        }
    }
    
    # 5. Mutex Permission Validation
    Write-SecurityLog "Checking mutex configuration..." 'TRACE'
    
    if ($Manifest.MutexName) {
        # Ensure mutex name follows secure pattern
        if ($Manifest.MutexName -notmatch '^Global\\[A-Za-z0-9_]+$' -and 
            $Manifest.MutexName -notmatch '^Local\\[A-Za-z0-9_]+$' -and
            $Manifest.MutexName -notmatch '^[A-Za-z0-9_]+$') {
            $securityIssues += "Mutex name contains invalid characters or format"
            $isSecure = $false
            Write-SecurityLog "SECURITY WARNING: Invalid mutex name format" 'WARN'
        }
        
        # Check for overly permissive mutex
        if ($Manifest.MutexName -match '^Global\\' -and -not $StrictMode) {
            $recommendations += "Global mutex detected - ensure this is intentional for cross-session locking"
            Write-SecurityLog "SECURITY NOTE: Global mutex will affect all sessions" 'DEBUG'
        }
    }
    
    # 6. Dependency Validation
    Write-SecurityLog "Validating dependencies..." 'TRACE'
    
    if ($Manifest.Dependencies -or $Manifest.DependsOn) {
        $deps = if ($Manifest.Dependencies) { $Manifest.Dependencies } else { $Manifest.DependsOn }
        
        foreach ($dep in $deps) {
            # Check for suspicious dependency names
            if ($dep -match '[^A-Za-z0-9\-_\.]') {
                $securityIssues += "Dependency name contains suspicious characters: $dep"
                $isSecure = $false
                Write-SecurityLog "SECURITY WARNING: Suspicious dependency name: $dep" 'WARN'
            }
        }
    }
    
    # 7. Execution Policy Check
    Write-SecurityLog "Checking execution policy requirements..." 'TRACE'
    
    $currentPolicy = Get-ExecutionPolicy -Scope Process
    
    if ($StrictMode) {
        if ($currentPolicy -eq 'Unrestricted' -or $currentPolicy -eq 'Bypass') {
            $recommendations += "Current execution policy ($currentPolicy) is very permissive - consider using RemoteSigned or AllSigned"
            Write-SecurityLog "SECURITY NOTE: Permissive execution policy detected: $currentPolicy" 'DEBUG'
        }
    }
    
    # Check if manifest requires specific execution policy
    if ($Manifest.RequiredExecutionPolicy) {
        $requiredPolicy = $Manifest.RequiredExecutionPolicy
        
        if ($requiredPolicy -eq 'Unrestricted' -or $requiredPolicy -eq 'Bypass') {
            if ($StrictMode) {
                $securityIssues += "Manifest requires unsafe execution policy: $requiredPolicy"
                $isSecure = $false
                Write-SecurityLog "SECURITY WARNING: Unsafe execution policy required: $requiredPolicy" 'WARN'
            } else {
                $recommendations += "Manifest requires permissive execution policy: $requiredPolicy"
                Write-SecurityLog "SECURITY NOTE: Permissive execution policy required: $requiredPolicy" 'DEBUG'
            }
        }
    }
    
    # 8. File Permission Checks (if paths are specified)
    Write-SecurityLog "Checking file permissions..." 'TRACE'
    
    if ($Manifest.StartScript -and (Test-Path $Manifest.StartScript)) {
        try {
            $acl = Get-Acl -Path $Manifest.StartScript
            $owner = $acl.Owner
            
            # Check if owned by SYSTEM or Administrators
            if ($owner -notmatch 'SYSTEM|Administrators|$env:USERNAME') {
                $recommendations += "StartScript is not owned by a trusted account: $owner"
                Write-SecurityLog "SECURITY NOTE: Script owned by: $owner" 'DEBUG'
            }
            
            # Check for overly permissive access
            $everyoneAccess = $acl.Access | Where-Object { 
                $_.IdentityReference -match 'Everyone|Users' -and 
                $_.FileSystemRights -match 'Write|FullControl' 
            }
            
            if ($everyoneAccess) {
                $securityIssues += "StartScript has overly permissive access rights (writable by Everyone/Users)"
                $isSecure = $false
                Write-SecurityLog "SECURITY WARNING: Script is writable by Everyone/Users" 'WARN'
            }
        } catch {
            Write-SecurityLog "Could not check file permissions: $_" 'TRACE'
        }
    }
    
    # Compile results
    $result = [PSCustomObject]@{
        IsSecure = $isSecure
        ManifestName = $Manifest.Name
        SecurityIssues = $securityIssues
        Recommendations = $recommendations
        ValidationTime = Get-Date
        StrictMode = $StrictMode.IsPresent
        ExecutionPolicy = $currentPolicy
    }
    
    # Log summary
    if ($isSecure) {
        Write-SecurityLog "Security validation PASSED for manifest: $($Manifest.Name)" 'OK'
    } else {
        Write-SecurityLog "Security validation FAILED for manifest: $($Manifest.Name) - $($securityIssues.Count) issues found" 'ERROR'
        foreach ($issue in $securityIssues) {
            Write-SecurityLog "  - $issue" 'ERROR'
        }
    }
    
    if ($recommendations.Count -gt 0) {
        Write-SecurityLog "Security recommendations for $($Manifest.Name):" 'INFO'
        foreach ($rec in $recommendations) {
            Write-SecurityLog "  - $rec" 'INFO'
        }
    }
    
    return $result
}

# Export the function
Export-ModuleMember -Function Test-ManifestSecurity
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCARzPbL/IZIqORi
# 9IU3PmeJ+bFfGdlDsaHapV3y3rYlGaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIMnbCe11/2B/c/0zX7KUD8Zx
# fpbtQdQW53Yg5+l8/hvxMA0GCSqGSIb3DQEBAQUABIIBAB5jrTwG6FMMEAS2nzHO
# TcfXHDspt3k/OgjXFjmJJyWVI6puEDBJd1ORnaQeyuUO+TVioc0hsTAX53v0ZzDS
# 9NFwij1+Iov/0CKqP2Nn3w2efogMehEGGjscRN7I++B4bL/YJoiq4x/aAnL1zhb9
# 6r8JTBLpoS9ifTrougCXn1tOtz0FYCjbQsI1KU45cOFT6AuUUsDj43H0DCbQRqCT
# xo578DmnMLM4RG5Su2ClK+O003V0LpZ4PLi02Cvgt05ub1moyMZAO19RvSgSB1pQ
# R1D0SiXCaRMgsvauEFIFqM2vpcY2iHBoJQpdcMvJw9xm9KmlO3JQeR7MqmhNbGqx
# WE0=
# SIG # End signature block
