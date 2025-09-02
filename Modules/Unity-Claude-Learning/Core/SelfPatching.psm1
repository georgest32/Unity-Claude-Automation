# Unity-Claude-Learning Self-Patching Component
# Automated fix application and code correction
# Part of refactored Learning module

$ErrorActionPreference = "Stop"

# Import dependencies with conditional loading and fallback
$CorePath = Join-Path $PSScriptRoot "LearningCore.psm1"
$DatabasePath = Join-Path $PSScriptRoot "DatabaseManagement.psm1"

# Ensure Write-ModuleLog is available - define fallback first
if (-not (Get-Command Write-ModuleLog -ErrorAction SilentlyContinue)) {
    function Write-ModuleLog {
        param([string]$Message, [string]$Level = "INFO")
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "[$timestamp] [SelfPatching] [$Level] $Message"
    }
}

# Check for and load required functions with fallback
try {
    if (-not (Get-Command Get-LearningConfig -ErrorAction SilentlyContinue)) {
        Import-Module $CorePath -Force -ErrorAction SilentlyContinue
    }
    if (-not (Get-Command Get-LearningConfig -ErrorAction SilentlyContinue)) {
        Import-Module $DatabasePath -Force -ErrorAction SilentlyContinue
    }
} catch {
    Write-Host "[SelfPatching] Warning: Could not load dependencies" -ForegroundColor Yellow
}

function Apply-AutoFix {
    <#
    .SYNOPSIS
    Applies automated fixes based on learned patterns
    .DESCRIPTION
    Attempts to automatically fix errors using learned patterns
    .PARAMETER ErrorMessage
    The error message to fix
    .PARAMETER FilePath
    Path to the file to fix
    .PARAMETER DryRun
    Preview changes without applying them
    .EXAMPLE
    Apply-AutoFix -ErrorMessage "CS0246: Type not found" -FilePath "script.cs"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ErrorMessage,
        
        [Parameter(Mandatory)]
        [string]$FilePath,
        
        [switch]$DryRun
    )
    
    Write-Verbose "Attempting auto-fix for: $ErrorMessage"
    
    $config = Get-LearningConfig
    
    if (-not $config.EnableAutoFix -and -not $DryRun) {
        Write-Warning "Auto-fix is disabled in configuration"
        return @{
            Success = $false
            Reason = "Auto-fix disabled"
        }
    }
    
    try {
        # Find similar patterns
        $patterns = Find-SimilarPatterns -ErrorSignature $ErrorMessage -SimilarityThreshold $config.MinConfidence
        
        if ($patterns.Count -eq 0) {
            Write-Verbose "No similar patterns found"
            return @{
                Success = $false
                Reason = "No matching patterns"
            }
        }
        
        # Get the best matching pattern
        $bestPattern = $patterns | Sort-Object Confidence -Descending | Select-Object -First 1
        
        # Get fix for the pattern
        $fix = Get-PatternFix -PatternID $bestPattern.PatternID
        
        if (-not $fix) {
            Write-Verbose "No fix available for pattern"
            return @{
                Success = $false
                Reason = "No fix available"
            }
        }
        
        # Apply the fix
        if ($DryRun) {
            Write-Host "DRY RUN: Would apply fix to $FilePath"
            Write-Host "Fix: $($fix.FixCode)"
            return @{
                Success = $true
                DryRun = $true
                Fix = $fix
                Pattern = $bestPattern
            }
        } else {
            $result = Apply-FixToFile -FilePath $FilePath -Fix $fix.FixCode -ErrorMessage $ErrorMessage
            
            if ($result.Success) {
                # Update success metrics
                Update-PatternSuccess -PatternID $bestPattern.PatternID -Success $true
            }
            
            return $result
        }
        
    } catch {
        Write-Error "Auto-fix failed: $_"
        return @{
            Success = $false
            Reason = $_.Exception.Message
        }
    }
}

function Apply-FixToFile {
    <#
    .SYNOPSIS
    Applies a specific fix to a file
    .PARAMETER FilePath
    File to fix
    .PARAMETER Fix
    Fix code to apply
    .PARAMETER ErrorMessage
    Original error message
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,
        
        [Parameter(Mandatory)]
        [string]$Fix,
        
        [string]$ErrorMessage
    )
    
    if (-not (Test-Path $FilePath)) {
        throw "File not found: $FilePath"
    }
    
    # Backup original file
    $backupPath = "$FilePath.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item -Path $FilePath -Destination $backupPath -Force
    Write-Verbose "Created backup: $backupPath"
    
    try {
        $content = Get-Content $FilePath -Raw
        $originalContent = $content
        
        # Apply fix based on error type
        $errorType = Get-ErrorType -ErrorMessage $ErrorMessage
        
        switch ($errorType) {
            'MissingUsing' {
                # Add using statement at the beginning
                if ($Fix -match '^using\s+') {
                    $content = "$Fix`r`n$content"
                }
            }
            'UndefinedVariable' {
                # Replace variable references
                if ($Fix -match '(\$\w+)\s*=') {
                    $varName = $Matches[1]
                    # Add variable declaration
                    $content = "$Fix`r`n$content"
                }
            }
            default {
                # Generic text replacement
                $content = $content -replace [regex]::Escape($ErrorMessage), $Fix
            }
        }
        
        if ($content -eq $originalContent) {
            Write-Warning "No changes made to file"
            return @{
                Success = $false
                Reason = "Fix did not modify content"
            }
        }
        
        # Write fixed content
        Set-Content -Path $FilePath -Value $content -Encoding UTF8
        
        Write-Verbose "Successfully applied fix to $FilePath"
        
        return @{
            Success = $true
            BackupPath = $backupPath
            ChangesApplied = $true
        }
        
    } catch {
        # Restore from backup on error
        if (Test-Path $backupPath) {
            Copy-Item -Path $backupPath -Destination $FilePath -Force
            Write-Warning "Restored original file from backup"
        }
        throw
    }
}

function Get-PatternFix {
    <#
    .SYNOPSIS
    Retrieves fix for a pattern
    .PARAMETER PatternID
    Pattern identifier
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PatternID
    )
    
    $config = Get-LearningConfig
    
    switch ($config.StorageBackend) {
        "SQLite" {
            return Get-PatternFixSQLite -PatternID $PatternID
        }
        "JSON" {
            return Get-PatternFixJSON -PatternID $PatternID
        }
        default {
            # Check memory cache
            if ($script:PatternCache -and $script:PatternCache.ContainsKey($PatternID)) {
                $pattern = $script:PatternCache[$PatternID]
                if ($pattern.Fix) {
                    return @{
                        FixCode = $pattern.Fix
                        Description = "Cached fix"
                    }
                }
            }
            return $null
        }
    }
}

function Get-PatternFixSQLite {
    <#
    .SYNOPSIS
    Gets fix from SQLite database
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PatternID
    )
    
    $config = Get-LearningConfig
    $connection = New-Object System.Data.SQLite.SQLiteConnection
    $connection.ConnectionString = "Data Source=$($config.DatabasePath);Version=3;"
    
    try {
        $connection.Open()
        
        $cmd = $connection.CreateCommand()
        $cmd.CommandText = @"
            SELECT FixCode, FixDescription, SuccessCount 
            FROM FixPatterns 
            WHERE PatternID = @pid 
            ORDER BY SuccessCount DESC 
            LIMIT 1
"@
        $cmd.Parameters.AddWithValue("@pid", $PatternID) | Out-Null
        
        $reader = $cmd.ExecuteReader()
        if ($reader.Read()) {
            return @{
                FixCode = $reader['FixCode']
                Description = $reader['FixDescription']
                SuccessCount = $reader['SuccessCount']
            }
        }
        
        return $null
        
    } finally {
        if ($connection.State -eq 'Open') {
            $connection.Close()
        }
        $connection.Dispose()
    }
}

function Get-ErrorType {
    <#
    .SYNOPSIS
    Determines error type from message
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ErrorMessage
    )
    
    switch -Regex ($ErrorMessage) {
        'CS0246|using|namespace' { return 'MissingUsing' }
        'CS0103|not exist|undefined' { return 'UndefinedVariable' }
        'CS1061|does not contain|missing' { return 'MissingMethod' }
        'CS0029|cannot.*convert|type' { return 'TypeMismatch' }
        'null.*reference|NullReferenceException' { return 'NullReference' }
        default { return 'Unknown' }
    }
}

function Update-PatternSuccess {
    <#
    .SYNOPSIS
    Updates pattern success metrics
    .PARAMETER PatternID
    Pattern identifier
    .PARAMETER Success
    Whether the fix was successful
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PatternID,
        
        [Parameter(Mandatory)]
        [bool]$Success
    )
    
    $config = Get-LearningConfig
    
    switch ($config.StorageBackend) {
        "SQLite" {
            Update-PatternSuccessSQLite -PatternID $PatternID -Success $Success
        }
        "JSON" {
            # Update JSON storage
            Write-Verbose "Updating JSON pattern success for $PatternID"
        }
        default {
            # Update memory cache
            if ($script:PatternCache -and $script:PatternCache.ContainsKey($PatternID)) {
                if ($Success) {
                    $script:PatternCache[$PatternID].SuccessCount++
                } else {
                    $script:PatternCache[$PatternID].FailureCount++
                }
            }
        }
    }
}

function Update-PatternSuccessSQLite {
    <#
    .SYNOPSIS
    Updates success metrics in SQLite
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PatternID,
        
        [Parameter(Mandatory)]
        [bool]$Success
    )
    
    $config = Get-LearningConfig
    $connection = New-Object System.Data.SQLite.SQLiteConnection
    $connection.ConnectionString = "Data Source=$($config.DatabasePath);Version=3;"
    
    try {
        $connection.Open()
        
        if ($Success) {
            $cmd = $connection.CreateCommand()
            $cmd.CommandText = @"
                UPDATE ErrorPatterns 
                SET SuccessCount = SuccessCount + 1,
                    SuccessRate = CAST(SuccessCount + 1 AS REAL) / (SuccessCount + FailureCount + 1)
                WHERE PatternID = @pid
"@
            $cmd.Parameters.AddWithValue("@pid", $PatternID) | Out-Null
            $cmd.ExecuteNonQuery() | Out-Null
        } else {
            $cmd = $connection.CreateCommand()
            $cmd.CommandText = @"
                UPDATE ErrorPatterns 
                SET FailureCount = FailureCount + 1,
                    SuccessRate = CAST(SuccessCount AS REAL) / (SuccessCount + FailureCount + 1)
                WHERE PatternID = @pid
"@
            $cmd.Parameters.AddWithValue("@pid", $PatternID) | Out-Null
            $cmd.ExecuteNonQuery() | Out-Null
        }
        
    } finally {
        if ($connection.State -eq 'Open') {
            $connection.Close()
        }
        $connection.Dispose()
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Apply-AutoFix',
    'Apply-FixToFile',
    'Get-PatternFix',
    'Get-PatternFixSQLite',
    'Get-ErrorType',
    'Update-PatternSuccess',
    'Update-PatternSuccessSQLite'
)

Write-ModuleLog -Message "SelfPatching component loaded successfully" -Level "DEBUG"
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAe9d9tK6HL6Ayu
# 2or4KNEYNEmmNNuZPqyARuTjfKNpqKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIA0S4gxc3S6fAZQNwj9IClLu
# 2mHfcgmq+oRHLx8BY213MA0GCSqGSIb3DQEBAQUABIIBAK4AUuDE3qvnplNhUz89
# 03eI+yNYVLOzlkfkQ2hPZ6E5F5bGoZDuQmvTJYZ37dVRp5K99EKpZtbTEXQsoAHE
# tl2Rc25SbnlFRlYTQPnVwS6Tak0F6/H3GdR+d1xHgpvkROMKDl+C30/kO3rSJ3U+
# ojrvXfDxHgBQSe8kk5d+9DoFwjOkFnyGI40WERmWxbUJN4iVuMNSDPyngt8Rbyz8
# cJit4IjsZhcVHfII6XfJ5qj9SUEu+meDwkvVf8mk1JVVgA7C/MxHglFON27x9Ktt
# gWEsoSfOVo4b7+uHzR13iaEuAPJ22OQPFFqPeMNcifQ1uPBoGGTCVgoC95EH78Km
# Rj0=
# SIG # End signature block
