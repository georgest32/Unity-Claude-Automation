# Unity-Claude-Learning Success Tracking Component
# Tracks success metrics and pattern effectiveness
# Part of refactored Learning module

$ErrorActionPreference = "Stop"

# Import core component with fallback logging
$CorePath = Join-Path $PSScriptRoot "LearningCore.psm1"

# Ensure Write-ModuleLog is available - define fallback first
if (-not (Get-Command Write-ModuleLog -ErrorAction SilentlyContinue)) {
    function Write-ModuleLog {
        param([string]$Message, [string]$Level = "INFO")
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "[$timestamp] [SuccessTracking] [$Level] $Message"
    }
}

# Check for and load required functions
try {
    Import-Module $CorePath -Force -ErrorAction SilentlyContinue
} catch {
    Write-Host "[SuccessTracking] Warning: Could not load dependencies" -ForegroundColor Yellow
}

# Initialize success metrics
$script:SuccessMetrics = @{
    TotalAttempts = 0
    SuccessfulFixes = 0
    FailedFixes = 0
    PatternsLearned = 0
    PatternsApplied = 0
    LastUpdateTime = Get-Date
    SessionStartTime = Get-Date
}

function Update-SuccessMetrics {
    <#
    .SYNOPSIS
    Updates success tracking metrics
    .DESCRIPTION
    Records success/failure of pattern applications
    .PARAMETER Success
    Whether the operation was successful
    .PARAMETER Operation
    Type of operation (Fix, Learn, Apply)
    .PARAMETER PatternID
    Associated pattern ID if applicable
    .EXAMPLE
    Update-SuccessMetrics -Success $true -Operation "Fix"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [bool]$Success,
        
        [Parameter(Mandatory)]
        [ValidateSet('Fix', 'Learn', 'Apply', 'Match')]
        [string]$Operation,
        
        [string]$PatternID = ""
    )
    
    $script:SuccessMetrics.TotalAttempts++
    $script:SuccessMetrics.LastUpdateTime = Get-Date
    
    switch ($Operation) {
        'Fix' {
            if ($Success) {
                $script:SuccessMetrics.SuccessfulFixes++
            } else {
                $script:SuccessMetrics.FailedFixes++
            }
        }
        'Learn' {
            if ($Success) {
                $script:SuccessMetrics.PatternsLearned++
            }
        }
        'Apply' {
            if ($Success) {
                $script:SuccessMetrics.PatternsApplied++
            }
        }
    }
    
    # Log the update
    Write-ModuleLog -Message "Success metrics updated: $Operation = $Success" -Level "DEBUG"
    
    # Persist metrics if configured
    $config = Get-LearningConfig
    if ($config.StorageBackend -ne "Memory") {
        Save-SuccessMetrics
    }
}

function Get-SuccessMetrics {
    <#
    .SYNOPSIS
    Retrieves current success metrics
    .DESCRIPTION
    Returns comprehensive success tracking data
    .PARAMETER IncludeRates
    Include calculated success rates
    .EXAMPLE
    Get-SuccessMetrics -IncludeRates
    #>
    [CmdletBinding()]
    param(
        [switch]$IncludeRates
    )
    
    $metrics = $script:SuccessMetrics.Clone()
    
    if ($IncludeRates) {
        # Calculate success rates
        if ($metrics.TotalAttempts -gt 0) {
            $metrics.OverallSuccessRate = ($metrics.SuccessfulFixes / $metrics.TotalAttempts) * 100
        } else {
            $metrics.OverallSuccessRate = 0
        }
        
        $totalFixes = $metrics.SuccessfulFixes + $metrics.FailedFixes
        if ($totalFixes -gt 0) {
            $metrics.FixSuccessRate = ($metrics.SuccessfulFixes / $totalFixes) * 100
        } else {
            $metrics.FixSuccessRate = 0
        }
        
        if ($metrics.PatternsLearned -gt 0) {
            $metrics.PatternUtilizationRate = ($metrics.PatternsApplied / $metrics.PatternsLearned) * 100
        } else {
            $metrics.PatternUtilizationRate = 0
        }
        
        # Session duration
        $metrics.SessionDuration = (Get-Date) - $metrics.SessionStartTime
    }
    
    return $metrics
}

function Reset-SuccessMetrics {
    <#
    .SYNOPSIS
    Resets success metrics to initial state
    .DESCRIPTION
    Clears all tracked metrics and starts fresh
    .PARAMETER Confirm
    Requires confirmation before reset
    .EXAMPLE
    Reset-SuccessMetrics -Confirm
    #>
    [CmdletBinding()]
    param(
        [switch]$Confirm
    )
    
    if ($Confirm) {
        $response = Read-Host "Are you sure you want to reset all success metrics? (Y/N)"
        if ($response -ne 'Y') {
            Write-Host "Reset cancelled"
            return
        }
    }
    
    $script:SuccessMetrics = @{
        TotalAttempts = 0
        SuccessfulFixes = 0
        FailedFixes = 0
        PatternsLearned = 0
        PatternsApplied = 0
        LastUpdateTime = Get-Date
        SessionStartTime = Get-Date
    }
    
    Write-ModuleLog -Message "Success metrics reset" -Level "INFO"
    
    # Clear persisted metrics
    $config = Get-LearningConfig
    if ($config.StorageBackend -ne "Memory") {
        Clear-PersistedMetrics
    }
}

function Save-SuccessMetrics {
    <#
    .SYNOPSIS
    Persists success metrics to storage
    .DESCRIPTION
    Saves current metrics to configured storage backend
    #>
    [CmdletBinding()]
    param()
    
    $config = Get-LearningConfig
    $metricsPath = Join-Path $config.StoragePath "success_metrics.json"
    
    try {
        $script:SuccessMetrics | ConvertTo-Json -Depth 3 | Set-Content -Path $metricsPath -Encoding UTF8
        Write-ModuleLog -Message "Success metrics saved to $metricsPath" -Level "DEBUG"
    } catch {
        Write-ModuleLog -Message "Failed to save success metrics: $_" -Level "WARNING"
    }
}

function Load-SuccessMetrics {
    <#
    .SYNOPSIS
    Loads success metrics from storage
    .DESCRIPTION
    Restores previously saved metrics
    #>
    [CmdletBinding()]
    param()
    
    $config = Get-LearningConfig
    $metricsPath = Join-Path $config.StoragePath "success_metrics.json"
    
    if (Test-Path $metricsPath) {
        try {
            $loaded = Get-Content -Path $metricsPath -Raw | ConvertFrom-Json
            
            # Convert to hashtable
            $script:SuccessMetrics = @{}
            $loaded.PSObject.Properties | ForEach-Object {
                $script:SuccessMetrics[$_.Name] = $_.Value
            }
            
            # Update session start time
            $script:SuccessMetrics.SessionStartTime = Get-Date
            
            Write-ModuleLog -Message "Success metrics loaded from $metricsPath" -Level "DEBUG"
        } catch {
            Write-ModuleLog -Message "Failed to load success metrics: $_" -Level "WARNING"
        }
    }
}

function Clear-PersistedMetrics {
    <#
    .SYNOPSIS
    Clears persisted metrics from storage
    #>
    [CmdletBinding()]
    param()
    
    $config = Get-LearningConfig
    $metricsPath = Join-Path $config.StoragePath "success_metrics.json"
    
    if (Test-Path $metricsPath) {
        Remove-Item -Path $metricsPath -Force
        Write-ModuleLog -Message "Persisted metrics cleared" -Level "DEBUG"
    }
}

function Get-PatternEffectiveness {
    <#
    .SYNOPSIS
    Analyzes pattern effectiveness over time
    .DESCRIPTION
    Provides detailed analysis of pattern success rates
    .PARAMETER MinUseCount
    Minimum usage count to include in analysis
    .EXAMPLE
    Get-PatternEffectiveness -MinUseCount 5
    #>
    [CmdletBinding()]
    param(
        [int]$MinUseCount = 1
    )
    
    $config = Get-LearningConfig
    
    switch ($config.StorageBackend) {
        "SQLite" {
            return Get-PatternEffectivenessSQLite -MinUseCount $MinUseCount
        }
        "JSON" {
            return Get-PatternEffectivenessJSON -MinUseCount $MinUseCount
        }
        default {
            Write-Warning "Pattern effectiveness requires database storage"
            return @()
        }
    }
}

function Get-PatternEffectivenessSQLite {
    <#
    .SYNOPSIS
    Gets pattern effectiveness from SQLite
    #>
    [CmdletBinding()]
    param(
        [int]$MinUseCount = 1
    )
    
    $config = Get-LearningConfig
    $connection = New-Object System.Data.SQLite.SQLiteConnection
    $connection.ConnectionString = "Data Source=$($config.DatabasePath);Version=3;"
    
    try {
        $connection.Open()
        
        $cmd = $connection.CreateCommand()
        $cmd.CommandText = @"
            SELECT 
                PatternID,
                ErrorType,
                UseCount,
                SuccessCount,
                FailureCount,
                SuccessRate,
                LastUsed
            FROM ErrorPatterns
            WHERE UseCount >= @minCount
            ORDER BY SuccessRate DESC, UseCount DESC
"@
        $cmd.Parameters.AddWithValue("@minCount", $MinUseCount) | Out-Null
        
        $patterns = @()
        $reader = $cmd.ExecuteReader()
        
        while ($reader.Read()) {
            $patterns += [PSCustomObject]@{
                PatternID = $reader['PatternID']
                ErrorType = $reader['ErrorType']
                UseCount = $reader['UseCount']
                SuccessCount = $reader['SuccessCount']
                FailureCount = $reader['FailureCount']
                SuccessRate = [double]$reader['SuccessRate']
                LastUsed = $reader['LastUsed']
                Effectiveness = if ($reader['UseCount'] -gt 0) {
                    ($reader['SuccessCount'] / $reader['UseCount']) * 100
                } else { 0 }
            }
        }
        
        return $patterns
        
    } finally {
        if ($connection.State -eq 'Open') {
            $connection.Close()
        }
        $connection.Dispose()
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Update-SuccessMetrics',
    'Get-SuccessMetrics',
    'Reset-SuccessMetrics',
    'Save-SuccessMetrics',
    'Load-SuccessMetrics',
    'Clear-PersistedMetrics',
    'Get-PatternEffectiveness',
    'Get-PatternEffectivenessSQLite'
)

# Load existing metrics on module import
Load-SuccessMetrics

Write-ModuleLog -Message "SuccessTracking component loaded successfully" -Level "DEBUG"
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAJO+v1KySLo+WG
# hoxBPkoKtIW+y9z4DearNdvMVkatXaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJjoPiKeFQkIW/LTeVgJDzbu
# Sckfdd6rLuK4QZp2GZXUMA0GCSqGSIb3DQEBAQUABIIBALBQl5mH8ajFORApyIPF
# U+PXzs6IkAyJ61eYCTOp6ibB0nR5gy+ZTRgLEuAY2WmZGfKTbqzb2x5Dh8BBDJvt
# QkkImw8Kq/dcdTLQ9ZnVoXQ18wJPVNGHBUffVDWCDiCGZ7UbVMFeQHNBTmJ15tUX
# yLsaP/mE2CnAe1lceQ4XrCrpM4EUhTooxICcI5VilQ+u/sIZObS9acOl/TApXn3K
# gNhzRgc6Mx8vhb31BHZ1TtMpmqd9LSAegFNnwzB1R77ilToWyDIlMB53ZlaCGGXx
# 6uVRrZ0TIKGnWAALp6p9zvD5hjszebPRk35QnCn8hJaLPzo84ZW6GJXhkZkNqAJl
# Y/A=
# SIG # End signature block
