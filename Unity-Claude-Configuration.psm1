# Unity-Claude-Configuration-Fixed.psm1
# Day 19: Configuration Management Module (PowerShell 5.1 Compatible)
# Provides centralized configuration management for autonomous system
# Fixed: Removed -AsHashtable parameter for PowerShell 5.1 compatibility

using namespace System.Collections.Generic
using namespace System.IO

# Configuration cache
$script:ConfigurationCache = @{}
$script:ConfigurationCachePath = Join-Path $PSScriptRoot "config_cache.json"
$script:LastConfigCheck = [DateTime]::MinValue
$script:ConfigCheckInterval = [TimeSpan]::FromMinutes(5)

# Helper function to convert PSCustomObject to Hashtable (PowerShell 5.1 compatibility)
function ConvertTo-HashTable {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        $InputObject
    )
    
    process {
        if ($null -eq $InputObject) {
            Write-Verbose "ConvertTo-HashTable: Input is null, returning empty hashtable"
            return @{}
        }
        
        # If it's already a hashtable, return it
        if ($InputObject -is [hashtable]) {
            Write-Verbose "ConvertTo-HashTable: Input is already a hashtable"
            return $InputObject
        }
        
        # If it's an array, convert each element
        if ($InputObject -is [array]) {
            Write-Verbose "ConvertTo-HashTable: Converting array with $($InputObject.Count) elements"
            return @($InputObject | ForEach-Object { ConvertTo-HashTable -InputObject $_ })
        }
        
        # If it's a PSCustomObject, convert to hashtable
        if ($InputObject -is [PSCustomObject]) {
            Write-Verbose "ConvertTo-HashTable: Converting PSCustomObject to hashtable"
            $hash = @{}
            
            foreach ($property in $InputObject.PSObject.Properties) {
                $propertyName = $property.Name
                $propertyValue = $property.Value
                
                Write-Verbose "  Processing property: $propertyName"
                
                # Recursively convert nested objects
                if ($propertyValue -is [PSCustomObject]) {
                    Write-Verbose "  Property '$propertyName' is nested PSCustomObject, converting recursively"
                    $hash[$propertyName] = ConvertTo-HashTable -InputObject $propertyValue
                }
                elseif ($propertyValue -is [array]) {
                    Write-Verbose "  Property '$propertyName' is array, converting elements"
                    $hash[$propertyName] = @($propertyValue | ForEach-Object { 
                        if ($_ -is [PSCustomObject]) {
                            ConvertTo-HashTable -InputObject $_
                        } else {
                            $_
                        }
                    })
                }
                else {
                    $hash[$propertyName] = $propertyValue
                }
            }
            
            return $hash
        }
        
        # For other types, return as-is
        Write-Verbose "ConvertTo-HashTable: Returning value as-is (type: $($InputObject.GetType().Name))"
        return $InputObject
    }
}

function Get-AutomationConfig {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Section = "",
        
        [Parameter()]
        [ValidateSet("development", "production", "test")]
        [string]$Environment = "development",
        
        [Parameter()]
        [switch]$Force
    )
    
    try {
        Write-Verbose "Get-AutomationConfig: Getting configuration for environment '$Environment', section '$Section'"
        
        # Check if cache needs refresh
        $now = [DateTime]::Now
        if ($Force -or ($now - $script:LastConfigCheck) -gt $script:ConfigCheckInterval) {
            Write-Verbose "Get-AutomationConfig: Cache refresh needed, loading configuration files"
            Load-ConfigurationFiles -Environment $Environment
            $script:LastConfigCheck = $now
        }
        
        # Return full config if no section specified
        if ([string]::IsNullOrWhiteSpace($Section)) {
            Write-Verbose "Get-AutomationConfig: Returning full configuration"
            return $script:ConfigurationCache
        }
        
        # Navigate to specific section
        $parts = $Section -split '\.'
        $current = $script:ConfigurationCache
        
        foreach ($part in $parts) {
            if ($current.ContainsKey($part)) {
                $current = $current[$part]
            } else {
                Write-Warning "Configuration section '$Section' not found"
                return $null
            }
        }
        
        Write-Verbose "Get-AutomationConfig: Returning section '$Section'"
        return $current
    }
    catch {
        Write-Error "Failed to get configuration: $_"
        return $null
    }
}

function Set-AutomationConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Section,
        
        [Parameter(Mandatory = $true, Position = 1)]
        $Value,
        
        [Parameter()]
        [ValidateSet("development", "production", "test")]
        [string]$Environment = "development",
        
        [Parameter()]
        [switch]$Persist
    )
    
    try {
        Write-Verbose "Set-AutomationConfig: Setting '$Section' in environment '$Environment'"
        
        # Ensure config is loaded
        if ($script:ConfigurationCache.Count -eq 0) {
            Write-Verbose "Set-AutomationConfig: Configuration cache empty, loading files"
            Load-ConfigurationFiles -Environment $Environment
        }
        
        # Navigate to section and set value
        $parts = $Section -split '\.'
        $current = $script:ConfigurationCache
        
        for ($i = 0; $i -lt $parts.Count - 1; $i++) {
            $part = $parts[$i]
            if (-not $current.ContainsKey($part)) {
                $current[$part] = @{}
            }
            $current = $current[$part]
        }
        
        $lastPart = $parts[-1]
        $current[$lastPart] = $Value
        
        # Persist to file if requested
        if ($Persist) {
            Save-ConfigurationFile -Environment $Environment
        }
        
        Write-Verbose "Set-AutomationConfig: Configuration '$Section' set to '$Value'"
        return $true
    }
    catch {
        Write-Error "Failed to set configuration: $_"
        return $false
    }
}

function Test-AutomationConfig {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet("development", "production", "test")]
        [string]$Environment = "development"
    )
    
    try {
        Write-Verbose "Test-AutomationConfig: Validating configuration for environment '$Environment'"
        
        # Load configuration
        Load-ConfigurationFiles -Environment $Environment
        
        # Validation rules
        $validationResults = @()
        
        # Check required sections exist
        $requiredSections = @(
            "autonomous_operation",
            "claude_cli",
            "monitoring",
            "dashboard",
            "error_handling"
        )
        
        foreach ($section in $requiredSections) {
            if ($script:ConfigurationCache.ContainsKey($section)) {
                $validationResults += @{
                    Section = $section
                    Valid = $true
                    Message = "Section exists"
                }
            } else {
                $validationResults += @{
                    Section = $section
                    Valid = $false
                    Message = "Missing required section"
                }
            }
        }
        
        # Check specific values
        if ($script:ConfigurationCache.ContainsKey("autonomous_operation")) {
            $autoOp = $script:ConfigurationCache["autonomous_operation"]
            
            # Check conversation rounds
            if ($autoOp.ContainsKey("max_conversation_rounds")) {
                $rounds = $autoOp["max_conversation_rounds"]
                if ($rounds -gt 0 -and $rounds -le 100) {
                    $validationResults += @{
                        Section = "autonomous_operation.max_conversation_rounds"
                        Valid = $true
                        Message = "Value in valid range (1-100)"
                    }
                } else {
                    $validationResults += @{
                        Section = "autonomous_operation.max_conversation_rounds"
                        Valid = $false
                        Message = "Value out of range: $rounds"
                    }
                }
            }
            
            # Check timeout
            if ($autoOp.ContainsKey("response_timeout_ms")) {
                $timeout = $autoOp["response_timeout_ms"]
                if ($timeout -ge 1000 -and $timeout -le 600000) {
                    $validationResults += @{
                        Section = "autonomous_operation.response_timeout_ms"
                        Valid = $true
                        Message = "Timeout in valid range (1-600 seconds)"
                    }
                } else {
                    $validationResults += @{
                        Section = "autonomous_operation.response_timeout_ms"
                        Valid = $false
                        Message = "Timeout out of range: $timeout"
                    }
                }
            }
        }
        
        # Check monitoring thresholds
        if ($script:ConfigurationCache.ContainsKey("monitoring")) {
            $monitoring = $script:ConfigurationCache["monitoring"]
            
            if ($monitoring.ContainsKey("thresholds")) {
                $thresholds = $monitoring["thresholds"]
                
                # Validate memory thresholds
                if ($thresholds.ContainsKey("memory_warning_mb") -and 
                    $thresholds.ContainsKey("memory_critical_mb")) {
                    
                    $warning = $thresholds["memory_warning_mb"]
                    $critical = $thresholds["memory_critical_mb"]
                    
                    if ($warning -lt $critical) {
                        $validationResults += @{
                            Section = "monitoring.thresholds.memory"
                            Valid = $true
                            Message = "Memory thresholds correctly ordered"
                        }
                    } else {
                        $validationResults += @{
                            Section = "monitoring.thresholds.memory"
                            Valid = $false
                            Message = "Warning threshold ($warning) >= Critical ($critical)"
                        }
                    }
                }
            }
        }
        
        # Return validation results
        $allValid = ($validationResults | Where-Object { -not $_.Valid }).Count -eq 0
        
        Write-Verbose "Test-AutomationConfig: Validation complete - Valid: $allValid"
        
        return @{
            Valid = $allValid
            Results = $validationResults
            Environment = $Environment
            Timestamp = [DateTime]::Now
        }
    }
    catch {
        Write-Error "Configuration validation failed: $_"
        return @{
            Valid = $false
            Error = $_.ToString()
            Environment = $Environment
            Timestamp = [DateTime]::Now
        }
    }
}

function Load-ConfigurationFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Environment
    )
    
    try {
        Write-Verbose "Load-ConfigurationFiles: Loading configuration for environment '$Environment'"
        
        # Base configuration file
        $baseConfigPath = Join-Path $PSScriptRoot "autonomous_config.json"
        
        # Environment-specific override
        $envConfigPath = Join-Path $PSScriptRoot "autonomous_config.$Environment.json"
        
        # Load base configuration
        if (Test-Path $baseConfigPath) {
            Write-Verbose "Load-ConfigurationFiles: Loading base configuration from $baseConfigPath"
            $jsonContent = Get-Content $baseConfigPath -Raw
            
            # PowerShell 5.1 compatible conversion
            $baseConfig = $jsonContent | ConvertFrom-Json | ConvertTo-HashTable
            
            $script:ConfigurationCache = $baseConfig
            Write-Verbose "Load-ConfigurationFiles: Base configuration loaded successfully"
        } else {
            Write-Warning "Base configuration file not found: $baseConfigPath"
            $script:ConfigurationCache = @{}
        }
        
        # Merge environment-specific overrides
        if (Test-Path $envConfigPath) {
            Write-Verbose "Load-ConfigurationFiles: Loading environment overrides from $envConfigPath"
            $jsonContent = Get-Content $envConfigPath -Raw
            
            # PowerShell 5.1 compatible conversion
            $envConfig = $jsonContent | ConvertFrom-Json | ConvertTo-HashTable
            
            Merge-Configuration -Base $script:ConfigurationCache -Override $envConfig
            Write-Verbose "Load-ConfigurationFiles: Applied $Environment overrides successfully"
        } else {
            Write-Verbose "No environment-specific config found: $envConfigPath"
        }
        
        # Load cached runtime values if they exist
        if (Test-Path $script:ConfigurationCachePath) {
            try {
                Write-Verbose "Load-ConfigurationFiles: Loading cached runtime values"
                $jsonContent = Get-Content $script:ConfigurationCachePath -Raw
                
                # PowerShell 5.1 compatible conversion
                $cachedValues = $jsonContent | ConvertFrom-Json | ConvertTo-HashTable
                
                Merge-Configuration -Base $script:ConfigurationCache -Override $cachedValues
                Write-Verbose "Load-ConfigurationFiles: Cached runtime values loaded successfully"
            }
            catch {
                Write-Warning "Failed to load cached values: $_"
            }
        }
        
        # Set environment in config
        $script:ConfigurationCache["environment"] = $Environment
        
        Write-Verbose "Load-ConfigurationFiles: Configuration loading complete"
    }
    catch {
        Write-Error "Failed to load configuration files: $_"
        throw
    }
}

function Merge-Configuration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Base,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Override
    )
    
    Write-Verbose "Merge-Configuration: Merging configuration overrides"
    
    foreach ($key in $Override.Keys) {
        if ($Base.ContainsKey($key)) {
            # If both are hashtables, merge recursively
            if ($Base[$key] -is [hashtable] -and $Override[$key] -is [hashtable]) {
                Write-Verbose "Merge-Configuration: Recursively merging section '$key'"
                Merge-Configuration -Base $Base[$key] -Override $Override[$key]
            } else {
                # Override the value
                Write-Verbose "Merge-Configuration: Overriding value for '$key'"
                $Base[$key] = $Override[$key]
            }
        } else {
            # Add new key
            Write-Verbose "Merge-Configuration: Adding new key '$key'"
            $Base[$key] = $Override[$key]
        }
    }
}

function Save-ConfigurationFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Environment
    )
    
    try {
        Write-Verbose "Save-ConfigurationFile: Saving configuration for environment '$Environment'"
        
        # Determine which values have changed from defaults
        $baseConfigPath = Join-Path $PSScriptRoot "autonomous_config.json"
        $jsonContent = Get-Content $baseConfigPath -Raw
        $baseConfig = $jsonContent | ConvertFrom-Json | ConvertTo-HashTable
        
        # Find differences
        $changes = Find-ConfigurationDifferences -Base $baseConfig -Current $script:ConfigurationCache
        
        if ($changes.Count -gt 0) {
            # Save changes to cache file
            $changes | ConvertTo-Json -Depth 10 | Set-Content $script:ConfigurationCachePath
            Write-Verbose "Save-ConfigurationFile: Configuration changes saved to cache"
        }
        
        return $true
    }
    catch {
        Write-Error "Failed to save configuration: $_"
        return $false
    }
}

function Find-ConfigurationDifferences {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Base,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Current,
        
        [Parameter()]
        [string]$Path = ""
    )
    
    $differences = @{}
    
    foreach ($key in $Current.Keys) {
        $currentPath = if ($Path) { "$Path.$key" } else { $key }
        
        if (-not $Base.ContainsKey($key)) {
            # New key
            $differences[$key] = $Current[$key]
        }
        elseif ($Base[$key] -is [hashtable] -and $Current[$key] -is [hashtable]) {
            # Recursively check nested objects
            $nestedDiff = Find-ConfigurationDifferences -Base $Base[$key] -Current $Current[$key] -Path $currentPath
            if ($nestedDiff.Count -gt 0) {
                $differences[$key] = $nestedDiff
            }
        }
        elseif ($Base[$key] -ne $Current[$key]) {
            # Value changed
            $differences[$key] = $Current[$key]
        }
    }
    
    return $differences
}

function Get-ConfigurationSummary {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet("development", "production", "test")]
        [string]$Environment = "development"
    )
    
    try {
        Write-Verbose "Get-ConfigurationSummary: Generating summary for environment '$Environment'"
        
        # Ensure config is loaded
        if ($script:ConfigurationCache.Count -eq 0) {
            Load-ConfigurationFiles -Environment $Environment
        }
        
        $summary = @{
            Environment = $script:ConfigurationCache["environment"]
            Timestamp = [DateTime]::Now
            Statistics = @{
                TotalSettings = 0
                EnabledFeatures = @()
                DisabledFeatures = @()
                CriticalSettings = @{}
            }
        }
        
        # Count total settings
        $summary.Statistics.TotalSettings = (Get-ConfigurationKeys -Config $script:ConfigurationCache).Count
        
        # Check feature states
        if ($script:ConfigurationCache.ContainsKey("autonomous_operation")) {
            $autoOp = $script:ConfigurationCache["autonomous_operation"]
            if ($autoOp["enabled"]) {
                $summary.Statistics.EnabledFeatures += "Autonomous Operation"
            } else {
                $summary.Statistics.DisabledFeatures += "Autonomous Operation"
            }
        }
        
        if ($script:ConfigurationCache.ContainsKey("dashboard")) {
            $dashboard = $script:ConfigurationCache["dashboard"]
            if ($dashboard["enabled"]) {
                $summary.Statistics.EnabledFeatures += "Real-Time Dashboard"
            } else {
                $summary.Statistics.DisabledFeatures += "Real-Time Dashboard"
            }
        }
        
        # Extract critical settings
        if ($script:ConfigurationCache.ContainsKey("monitoring")) {
            $monitoring = $script:ConfigurationCache["monitoring"]
            if ($monitoring.ContainsKey("thresholds")) {
                $summary.Statistics.CriticalSettings["MemoryWarning"] = "$($monitoring.thresholds.memory_warning_mb) MB"
                $summary.Statistics.CriticalSettings["MemoryCritical"] = "$($monitoring.thresholds.memory_critical_mb) MB"
            }
        }
        
        if ($script:ConfigurationCache.ContainsKey("autonomous_operation")) {
            $autoOp = $script:ConfigurationCache["autonomous_operation"]
            $summary.Statistics.CriticalSettings["MaxConversationRounds"] = $autoOp["max_conversation_rounds"]
            $summary.Statistics.CriticalSettings["ResponseTimeout"] = "$($autoOp.response_timeout_ms / 1000) seconds"
        }
        
        Write-Verbose "Get-ConfigurationSummary: Summary generated successfully"
        return $summary
    }
    catch {
        Write-Error "Failed to generate configuration summary: $_"
        return $null
    }
}

function Get-ConfigurationKeys {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config,
        
        [Parameter()]
        [string]$Prefix = ""
    )
    
    $keys = @()
    
    foreach ($key in $Config.Keys) {
        $fullKey = if ($Prefix) { "$Prefix.$key" } else { $key }
        $keys += $fullKey
        
        if ($Config[$key] -is [hashtable]) {
            $keys += Get-ConfigurationKeys -Config $Config[$key] -Prefix $fullKey
        }
    }
    
    return $keys
}

# Export module functions
Export-ModuleMember -Function @(
    'Get-AutomationConfig',
    'Set-AutomationConfig',
    'Test-AutomationConfig',
    'Get-ConfigurationSummary'
)

Write-Verbose "Unity-Claude-Configuration module loaded (PowerShell 5.1 compatible)"
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUqyJnFAIIQHdsswWd9XFJsBYQ
# ZXWgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU/qwbSTPf9exbN2MCBZw80aQT/bQwDQYJKoZIhvcNAQEBBQAEggEAAz2Q
# qL0uQvNeeQcQrA1eKuU0MszHO8tACIwqLrNKuACypxkqcTYIu/aqpDB5zaae8+/i
# weZzSxcmMEBqczxn064YmLeRK85r/EGAsi771dBBTukgf4/IbXzYrgmLeZT0iIgs
# n3PkntVxO5umBsKy+VEsyBAC9yOG+qWYPp9fMZyh+BY47z3wwoRVZV8ATP5x36GM
# NxFN6bfhR/SYglraRjMnSCh1gst2Rj9cZ3xgepC7A9qpiG2DbpibVJtym/Vc8+zZ
# oKHTe4la+konitV+/SlNflhMyjE5Zu4PhDl0TsOi56Ou6Eg5vUPB3pxTSCsV9vM+
# rSmx/XlvN/2yDu0q8g==
# SIG # End signature block
