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
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUlCjProUNzo/zKkDzJk2r1nKi
# AvigggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
# AQsFADAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0b21hdGlvbi1EZXZlbG9w
# bWVudDAeFw0yNTA4MjAyMTE1MTdaFw0yNjA4MjAyMTM1MTdaMC4xLDAqBgNVBAMM
# I1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEAseH3qinVEOhrn2OLpjc5TNT4vGh1BkfB5X4S
# FhY7K0QMQsYYnkZVmx3tB8PqVQXl++l+e3uT7uCscc7vjMTK8tDSWH98ji0U34WL
# JBwXC62l1ArazMKp4Tyr7peksei7vL4pZOtOVgAyTYn5d1hbnsVQmCSTPRtpn7mC
# Azfq2ec5qZ9Kgl7puPW5utvYfh8idtOWa5/WgYSKwOIvyZawIdZKLFpwqOtqbJe4
# sWzVahasFhLfoAKkniKOAocJDkJexh5pO/EOSKEZ3mOCU1ZSs4XWRGISRhV3qGZp
# f+Y3JlHKMeFDWKynaJBO8/GU5sqMATlDUvrByBtU2OQ2Um/L3QIDAQABo0YwRDAO
# BgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFHw5
# rOy6xlW6B45sJUsiI2A/yS0MMA0GCSqGSIb3DQEBCwUAA4IBAQAUTLH0+w8ysvmh
# YuBw4NDKcZm40MTh9Zc1M2p2hAkYsgNLJ+/rAP+I74rNfqguTYwxpCyjkwrg8yF5
# wViwggboLpF2yDu4N/dgDainR4wR8NVpS7zFZOFkpmNPepc6bw3d4yQKa/wJXKeC
# pkRjS50N77/hfVI+fFKNao7POb7en5fcXuZaN6xWoTRy+J4I4MhfHpjZuxSLSXjb
# VXtPD4RZ9HGjl9BU8162cRhjujr/Lc3/dY/6ikHQYnxuxcdxRew4nzaqAQaOeWu6
# tGp899JPKfldM5Zay5IBl3zs15gNS9+0Jrd0ARQnSVYoI0DLh3KybFnfK4POezoN
# Lp/dbX2SMYIB4zCCAd8CAQEwQjAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0
# b21hdGlvbi1EZXZlbG9wbWVudAIQdR0W2SKoK5VE8JId4ZxrRTAJBgUrDgMCGgUA
# oHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYB
# BAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0B
# CQQxFgQUuzT6BM9o9nzwWWgDLK15j+iSjsIwDQYJKoZIhvcNAQEBBQAEggEAMCb9
# URRdjCmWo8c1P/8gjKrs5OsQ3iRAuOWknJ55Tvk8R+aQXTZWXaOT3mEv8NfRRnVt
# UI1pJXz1uDemH7XfMLRQS5dVbtzQRxWuFXDifVl6HSN3THOxN2+pKXyqva3aHofH
# uQE4q/zJ+pruVaXNfKjU/XHtGFyGrVPqH+y0+BJZ/wmb17IiDsvRx0/JMYRPrFqB
# wV8SkgsmuF6I82xefbOJoUStdJ68GZHgincNer6085689S2IN3YIPQDBi8qo9Pyb
# 1YxB2KqrZTpXYZJf3ReeNoyR0Wuk6zRLCyMrMo4KM5XgTazp8SR8fuPHmO+csXuU
# ZRaMIYqrJiq3LAz+tw==
# SIG # End signature block
