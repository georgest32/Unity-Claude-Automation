# Unity-Claude-Learning Configuration Management Component  
# Configuration and settings management
# Part of refactored Learning module

$ErrorActionPreference = "Stop"

# Import core component with conditional loading and fallback
$CorePath = Join-Path $PSScriptRoot "LearningCore.psm1"

# Ensure Write-ModuleLog is available - define fallback first
if (-not (Get-Command Write-ModuleLog -ErrorAction SilentlyContinue)) {
    function Write-ModuleLog {
        param([string]$Message, [string]$Level = "INFO")
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "[$timestamp] [ConfigurationManagement] [$Level] $Message"
    }
}

# Check for and load required functions
try {
    Import-Module $CorePath -Force -ErrorAction SilentlyContinue
} catch {
    Write-Host "[ConfigurationManagement] Warning: Could not load dependencies" -ForegroundColor Yellow
}

function Save-LearningConfiguration {
    <#
    .SYNOPSIS
    Saves learning configuration to file
    .DESCRIPTION
    Persists current configuration settings
    .PARAMETER Path
    Configuration file path (optional)
    .EXAMPLE
    Save-LearningConfiguration
    #>
    [CmdletBinding()]
    param(
        [string]$Path = ""
    )
    
    $config = Get-LearningConfig
    
    if (-not $Path) {
        $Path = Join-Path $config.StoragePath "learning_config.json"
    }
    
    try {
        $config | ConvertTo-Json -Depth 3 | Set-Content -Path $Path -Encoding UTF8
        Write-ModuleLog -Message "Configuration saved to: $Path" -Level "INFO"
        return $true
    } catch {
        Write-Error "Failed to save configuration: $_"
        return $false
    }
}

function Load-LearningConfiguration {
    <#
    .SYNOPSIS
    Loads learning configuration from file
    .DESCRIPTION
    Restores saved configuration settings
    .PARAMETER Path
    Configuration file path (optional)
    .EXAMPLE
    Load-LearningConfiguration
    #>
    [CmdletBinding()]
    param(
        [string]$Path = ""
    )
    
    if (-not $Path) {
        $config = Get-LearningConfig
        $Path = Join-Path $config.StoragePath "learning_config.json"
    }
    
    if (-not (Test-Path $Path)) {
        Write-Warning "Configuration file not found: $Path"
        return $false
    }
    
    try {
        $loaded = Get-Content -Path $Path -Raw | ConvertFrom-Json
        
        # Update configuration
        Set-LearningConfiguration -DatabasePath $loaded.DatabasePath `
                                  -StoragePath $loaded.StoragePath `
                                  -MaxPatternAge $loaded.MaxPatternAge `
                                  -MinConfidence $loaded.MinConfidence `
                                  -EnableAutoFix $loaded.EnableAutoFix
        
        Write-ModuleLog -Message "Configuration loaded from: $Path" -Level "INFO"
        return $true
        
    } catch {
        Write-Error "Failed to load configuration: $_"
        return $false
    }
}

function Test-LearningConfiguration {
    <#
    .SYNOPSIS
    Tests learning configuration validity
    .DESCRIPTION
    Validates configuration settings and storage backends
    .EXAMPLE
    Test-LearningConfiguration
    #>
    [CmdletBinding()]
    param()
    
    $config = Get-LearningConfig
    $issues = @()
    
    # Test storage path
    if (-not (Test-Path $config.StoragePath)) {
        $issues += "Storage path does not exist: $($config.StoragePath)"
    }
    
    # Test database if SQLite backend
    if ($config.StorageBackend -eq "SQLite") {
        if (-not (Test-Path $config.DatabasePath)) {
            $issues += "Database file not found: $($config.DatabasePath)"
        } else {
            # Test database connection
            try {
                $connection = New-Object System.Data.SQLite.SQLiteConnection
                $connection.ConnectionString = "Data Source=$($config.DatabasePath);Version=3;"
                $connection.Open()
                $connection.Close()
            } catch {
                $issues += "Cannot connect to database: $_"
            }
        }
    }
    
    # Test confidence threshold
    if ($config.MinConfidence -lt 0 -or $config.MinConfidence -gt 1) {
        $issues += "MinConfidence must be between 0 and 1"
    }
    
    # Test pattern age
    if ($config.MaxPatternAge -lt 0) {
        $issues += "MaxPatternAge must be positive"
    }
    
    $result = @{
        Valid = ($issues.Count -eq 0)
        Issues = $issues
        Configuration = $config
    }
    
    if ($result.Valid) {
        Write-Host "Configuration is valid" -ForegroundColor Green
    } else {
        Write-Warning "Configuration has issues:"
        $issues | ForEach-Object { Write-Warning "  - $_" }
    }
    
    return $result
}

function Export-LearningConfiguration {
    <#
    .SYNOPSIS
    Exports configuration for backup or sharing
    .DESCRIPTION
    Creates a portable configuration export
    .PARAMETER Path
    Export file path
    .PARAMETER IncludeData
    Include pattern data in export
    .EXAMPLE
    Export-LearningConfiguration -Path "backup.json"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [switch]$IncludeData
    )
    
    $export = @{
        Configuration = Get-LearningConfig
        ExportDate = Get-Date
        Version = "2.0.0"
    }
    
    if ($IncludeData) {
        # Include patterns if requested
        $config = Get-LearningConfig
        
        if ($config.StorageBackend -eq "SQLite" -and (Test-Path $config.DatabasePath)) {
            # Export database content
            $export.Data = Export-DatabaseContent
        } elseif ($config.StorageBackend -eq "JSON") {
            # Export JSON patterns
            $export.Data = Export-JSONPatterns
        }
    }
    
    try {
        $export | ConvertTo-Json -Depth 10 | Set-Content -Path $Path -Encoding UTF8
        Write-Host "Configuration exported to: $Path" -ForegroundColor Green
        return $true
    } catch {
        Write-Error "Failed to export configuration: $_"
        return $false
    }
}

function Import-LearningConfiguration {
    <#
    .SYNOPSIS
    Imports configuration from export file
    .DESCRIPTION
    Restores configuration from backup
    .PARAMETER Path
    Import file path
    .PARAMETER ImportData
    Also import pattern data
    .EXAMPLE
    Import-LearningConfiguration -Path "backup.json" -ImportData
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [switch]$ImportData
    )
    
    if (-not (Test-Path $Path)) {
        Write-Error "Import file not found: $Path"
        return $false
    }
    
    try {
        $import = Get-Content -Path $Path -Raw | ConvertFrom-Json
        
        # Import configuration
        Set-LearningConfiguration -DatabasePath $import.Configuration.DatabasePath `
                                  -StoragePath $import.Configuration.StoragePath `
                                  -MaxPatternAge $import.Configuration.MaxPatternAge `
                                  -MinConfidence $import.Configuration.MinConfidence `
                                  -EnableAutoFix $import.Configuration.EnableAutoFix
        
        if ($ImportData -and $import.Data) {
            # Import pattern data
            Write-Host "Importing pattern data..." -ForegroundColor Cyan
            Import-PatternData -Data $import.Data
        }
        
        Write-Host "Configuration imported successfully" -ForegroundColor Green
        return $true
        
    } catch {
        Write-Error "Failed to import configuration: $_"
        return $false
    }
}

# Helper functions
function Export-DatabaseContent {
    # Simplified export - would need full implementation
    return @{ PatternCount = 0 }
}

function Export-JSONPatterns {
    # Simplified export - would need full implementation
    return @{ PatternCount = 0 }
}

function Import-PatternData {
    param($Data)
    # Simplified import - would need full implementation
    Write-Verbose "Pattern data import not fully implemented"
}

# Export functions
Export-ModuleMember -Function @(
    'Save-LearningConfiguration',
    'Load-LearningConfiguration',
    'Test-LearningConfiguration',
    'Export-LearningConfiguration',
    'Import-LearningConfiguration'
)

Write-ModuleLog -Message "ConfigurationManagement component loaded successfully" -Level "DEBUG"
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA9Qna1Vf+b1+64
# MV3Tu00TrNtBDTGyZeq0YwKdXVI0ZqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEICtCI2FbAZMCqdQDcw7GI/Bn
# klvSno82RkEyfgNGbri8MA0GCSqGSIb3DQEBAQUABIIBAK4TZo+yWJXkBv/AJ1JM
# Xxc8svMNcAcX+YotuywfM1yUBTOIxTtKPzhRINH2LmEnORfJOijrmvjPETr1axIj
# PzuDZdfncitoUN1qMRU/dBzunHQ0KZ9DuxlrzohERYW0nWKzMptD1haEURa3J3tp
# 3qTV+YT9g20DeODiHyGCajX+G4Ea/AXQzLeX1FFuW9lVxnmToewYuClUl6KkvIde
# 2MtMnt+NhqORABY2I0CJ21VPSegyjvjXzjdORTIyFeuktzX0A0MBo2n+/rv3Ju4O
# jh+VPUpjb2ILZLsQyCzAaFkcRUZCd8M3NYJfIQMvbANCzqmbRi3OLk0apgK+2Qk3
# xjc=
# SIG # End signature block
