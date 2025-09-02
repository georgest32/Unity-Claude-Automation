function Test-SubsystemManifest {
    <#
    .SYNOPSIS
    Validates a subsystem manifest file against the schema.
    
    .DESCRIPTION
    Tests a subsystem manifest (.psd1) file to ensure it contains all required fields
    and validates the values according to the schema definition.
    
    .PARAMETER Path
    Path to the manifest file to validate.
    
    .PARAMETER Manifest
    A hashtable containing the manifest data (if already loaded).
    
    .EXAMPLE
    Test-SubsystemManifest -Path ".\AutonomousAgent.manifest.psd1"
    
    .EXAMPLE
    $manifest = Import-PowerShellDataFile ".\manifest.psd1"
    Test-SubsystemManifest -Manifest $manifest
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'Path')]
        [string]$Path,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'Manifest')]
        [hashtable]$Manifest
    )
    
    Write-SystemStatusLog "Validating subsystem manifest" -Level 'DEBUG'
    
    # Load manifest if path provided
    if ($PSCmdlet.ParameterSetName -eq 'Path') {
        if (-not (Test-Path $Path)) {
            Write-SystemStatusLog "Manifest file not found: $Path" -Level 'ERROR'
            return @{
                IsValid = $false
                Errors = @("Manifest file not found: $Path")
            }
        }
        
        try {
            Write-SystemStatusLog "Loading manifest from: $Path" -Level 'TRACE'
            $Manifest = Import-PowerShellDataFile -Path $Path
        } catch {
            Write-SystemStatusLog "Failed to load manifest: $_" -Level 'ERROR'
            return @{
                IsValid = $false
                Errors = @("Failed to load manifest: $_")
            }
        }
    }
    
    # Initialize validation result
    $errors = @()
    $warnings = @()
    
    # Define required fields
    $requiredFields = @(
        'Name',
        'Version',
        'Description',
        'StartScript'
    )
    
    # Define field types and valid values
    $fieldValidation = @{
        Name = @{
            Type = 'String'
            Pattern = '^[A-Za-z0-9_-]+$'
        }
        Version = @{
            Type = 'String'
            Pattern = '^\d+\.\d+\.\d+$'
        }
        RestartPolicy = @{
            Type = 'String'
            ValidValues = @('OnFailure', 'Always', 'Never')
        }
        Priority = @{
            Type = 'String'
            ValidValues = @('Normal', 'BelowNormal', 'AboveNormal', 'High', 'RealTime')
        }
        WindowStyle = @{
            Type = 'String'
            ValidValues = @('Normal', 'Hidden', 'Minimized', 'Maximized')
        }
        MaxRestarts = @{
            Type = 'Int'
            Min = 0
            Max = 100
        }
        RestartDelay = @{
            Type = 'Int'
            Min = 0
            Max = 3600
        }
        HealthCheckInterval = @{
            Type = 'Int'
            Min = 5
            Max = 3600
        }
        MaxMemoryMB = @{
            Type = 'Int'
            Min = 0
        }
        MaxCpuPercent = @{
            Type = 'Int'
            Min = 0
            Max = 100
        }
    }
    
    # Check required fields
    foreach ($field in $requiredFields) {
        if (-not $Manifest.ContainsKey($field) -or [string]::IsNullOrWhiteSpace($Manifest[$field])) {
            $errors += "Required field missing or empty: $field"
            Write-SystemStatusLog "Required field missing: $field" -Level 'WARN'
        }
    }
    
    # Validate field types and values
    foreach ($field in $Manifest.Keys) {
        if ($fieldValidation.ContainsKey($field)) {
            $validation = $fieldValidation[$field]
            $value = $Manifest[$field]
            
            # Skip validation if value is null or empty (unless required)
            if ($null -eq $value -or $value -eq '') {
                continue
            }
            
            # Type validation
            if ($validation.Type) {
                $actualType = $value.GetType().Name
                $expectedType = $validation.Type
                
                switch ($expectedType) {
                    'String' {
                        if ($actualType -ne 'String') {
                            $errors += "$field must be a string, got: $actualType"
                        }
                    }
                    'Int' {
                        if ($actualType -notmatch 'Int32|Int64|Int16') {
                            $errors += "$field must be an integer, got: $actualType"
                        }
                    }
                    'Bool' {
                        if ($actualType -ne 'Boolean') {
                            $errors += "$field must be a boolean, got: $actualType"
                        }
                    }
                }
            }
            
            # Pattern validation
            if ($validation.Pattern -and $value -is [string]) {
                if ($value -notmatch $validation.Pattern) {
                    $errors += "$field value '$value' does not match required pattern: $($validation.Pattern)"
                }
            }
            
            # Valid values validation
            if ($validation.ValidValues) {
                if ($value -notin $validation.ValidValues) {
                    $errors += "$field value '$value' is not valid. Must be one of: $($validation.ValidValues -join ', ')"
                }
            }
            
            # Numeric range validation
            if ($validation.Min -and $value -lt $validation.Min) {
                $errors += "$field value $value is below minimum: $($validation.Min)"
            }
            if ($validation.Max -and $value -gt $validation.Max) {
                $errors += "$field value $value is above maximum: $($validation.Max)"
            }
        }
    }
    
    # Validate StartScript exists if it's a relative path
    if ($Manifest.StartScript -and $PSCmdlet.ParameterSetName -eq 'Path') {
        $manifestDir = Split-Path $Path -Parent
        
        # Try resolving from project root first
        $projectRoot = Split-Path $manifestDir -Parent
        $startScriptPath = Join-Path $projectRoot $Manifest.StartScript
        
        # If not found at project root, try manifest directory
        if (-not (Test-Path $startScriptPath)) {
            $startScriptPath = Join-Path $manifestDir $Manifest.StartScript
        }
        
        if ($Manifest.StartScript -notmatch '^\$' -and -not (Test-Path $startScriptPath)) {
            $warnings += "StartScript not found: $startScriptPath"
            Write-SystemStatusLog "StartScript not found: $startScriptPath" -Level 'WARN'
        }
    }
    
    # Validate dependencies
    if ($Manifest.RequiredModules) {
        foreach ($module in $Manifest.RequiredModules) {
            if (-not (Get-Module -ListAvailable -Name $module)) {
                $warnings += "Required module not available: $module"
                Write-SystemStatusLog "Required module not available: $module" -Level 'WARN'
            }
        }
    }
    
    # Validate mutex name format
    if ($Manifest.MutexName -and $Manifest.MutexName -notmatch '^Global\\') {
        $warnings += "MutexName should start with 'Global\' for system-wide enforcement"
    }
    
    # Build result
    $result = @{
        IsValid = $errors.Count -eq 0
        Errors = $errors
        Warnings = $warnings
        ManifestData = $Manifest
    }
    
    # Log result
    if ($result.IsValid) {
        Write-SystemStatusLog "Manifest validation successful" -Level 'OK'
    } else {
        Write-SystemStatusLog "Manifest validation failed with $($errors.Count) errors" -Level 'ERROR'
        foreach ($error in $errors) {
            Write-SystemStatusLog "  - $error" -Level 'ERROR'
        }
    }
    
    if ($warnings.Count -gt 0) {
        Write-SystemStatusLog "Manifest validation warnings:" -Level 'WARN'
        foreach ($warning in $warnings) {
            Write-SystemStatusLog "  - $warning" -Level 'WARN'
        }
    }
    
    return $result
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAwE2H9cKycQDv2
# +NpfiriO8W6Qak3kNDPwo8KdA8YZb6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBMmBgY9rz7ATRI9sjGblL7J
# zR7nb4f0gv/5oYY4Gg9HMA0GCSqGSIb3DQEBAQUABIIBADDmIjS66uBXyLchgVoa
# 5lN7KJU3D1lxFYN9MliyGQLJMKhuqyXLYWC3QPfrx3yC5Il5f6+KemqlUUZDbjKV
# Ghv7w3sMSOAYfuBBAsBdwgvbjp6nw52/fS/MmUmTjsdfY57/FOkLygNy9rUHMedG
# FErB72Cta6tLJVn+lJNvi2+CVHhDg1sNwdKKVONjRhNFn4Y8wdjcHcOdatOROxdg
# xzKa+8uWXR75lecC+FVosP4k4JN6UiHxle6g40VMuMhkIVuAZ/IfWszF4j0gznbP
# nqYoQssT2UQqDwl12B4wnuNtVgv7yAHrhlqQdYJdg4c6jwcuqTggto1HhdhZXsKg
# KsA=
# SIG # End signature block
