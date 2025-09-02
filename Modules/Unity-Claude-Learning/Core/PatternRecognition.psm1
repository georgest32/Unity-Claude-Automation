# Unity-Claude-Learning Pattern Recognition Component
# Pattern detection and matching for error resolution
# Part of refactored Learning module

$ErrorActionPreference = "Stop"

# Import dependencies
$CorePath = Join-Path $PSScriptRoot "LearningCore.psm1"
$DatabasePath = Join-Path $PSScriptRoot "DatabaseManagement.psm1"
$StringPath = Join-Path $PSScriptRoot "StringSimilarity.psm1"
$ASTPath = Join-Path $PSScriptRoot "ASTAnalysis.psm1"

Import-Module $CorePath -Force
Import-Module $DatabasePath -Force
Import-Module $StringPath -Force
Import-Module $ASTPath -Force

function Add-ErrorPattern {
    <#
    .SYNOPSIS
    Adds a new error pattern to the learning storage
    .DESCRIPTION
    Learns from error patterns and their fixes
    .PARAMETER ErrorMessage
    The error message to learn from
    .PARAMETER Context
    Code context where error occurred (optional)
    .PARAMETER Fix
    The fix that resolved the error
    .EXAMPLE
    Add-ErrorPattern -ErrorMessage "CS0246: Type not found" -Fix "using System.Collections;"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ErrorMessage,
        
        [object]$Context = $null,
        
        [string]$Fix = ""
    )
    
    Write-Verbose "Adding error pattern: $ErrorMessage"
    
    try {
        # Create error signature
        $errorSignature = Get-ErrorSignature -ErrorText $ErrorMessage
        
        # Determine error type from signature
        $errorType = switch -Regex ($errorSignature) {
            'CS0246' { 'MissingUsing' }
            'CS0103' { 'UndefinedVariable' }
            'CS1061' { 'MissingMethod' }
            'CS0029' { 'TypeMismatch' }
            'null reference' { 'NullReference' }
            default { 'Unknown' }
        }
        
        # Get config
        $config = Get-LearningConfiguration
        
        # Use appropriate storage backend
        switch ($config.StorageBackend) {
            "SQLite" {
                # Use existing SQLite implementation
                if ($Context) {
                    $pattern = Find-CodePattern -AST $Context -ErrorMessage $ErrorMessage
                    return Add-ErrorPatternSQLite -Pattern $pattern -Fix $Fix
                } else {
                    # Create basic pattern without AST
                    $pattern = @{
                        ErrorType = $errorType
                        ErrorMessage = $ErrorMessage
                        PatternHash = [System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($ErrorMessage))).Replace("-","").Substring(0,16)
                    }
                    return Add-ErrorPatternSQLite -Pattern $pattern -Fix $Fix
                }
            }
            
            "JSON" {
                # Use JSON storage
                $patternId = Save-PatternToJSON -ErrorSignature $errorSignature -ErrorType $errorType -Fix $Fix -StoragePath $config.StoragePath
                if ($patternId) {
                    Write-Verbose "Pattern saved to JSON with ID: $patternId"
                    return $patternId
                } else {
                    throw "Failed to save pattern to JSON storage"
                }
            }
            
            default {
                # No storage available, work in memory only
                $patternId = "TEMP_" + [System.Guid]::NewGuid().ToString("N").Substring(0, 8).ToUpper()
                if (-not $script:PatternCache) {
                    $script:PatternCache = @{}
                }
                $script:PatternCache[$patternId] = @{
                    ErrorSignature = $errorSignature
                    ErrorType = $errorType
                    Fix = $Fix
                    Created = Get-Date
                }
                Write-Verbose "Pattern cached in memory with ID: $patternId"
                return $patternId
            }
        }
        
    } catch {
        Write-Error "Failed to add error pattern: $_"
        return $null
    }
}

function Add-ErrorPatternSQLite {
    <#
    .SYNOPSIS
    SQLite-specific implementation of pattern storage
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Pattern,
        
        [string]$Fix = ""
    )
    
    $config = Get-LearningConfiguration
    $connection = New-Object System.Data.SQLite.SQLiteConnection
    $connection.ConnectionString = "Data Source=$($config.DatabasePath);Version=3;"
    
    try {
        $connection.Open()
        
        # Check if pattern exists
        $checkCmd = $connection.CreateCommand()
        $checkCmd.CommandText = "SELECT PatternID FROM ErrorPatterns WHERE ErrorSignature = @sig"
        $checkCmd.Parameters.AddWithValue("@sig", $Pattern.PatternHash) | Out-Null
        
        $existingID = $checkCmd.ExecuteScalar()
        
        if ($existingID) {
            # Update existing pattern
            $updateCmd = $connection.CreateCommand()
            $updateCmd.CommandText = @"
                UPDATE ErrorPatterns 
                SET UseCount = UseCount + 1, 
                    LastSeen = CURRENT_TIMESTAMP 
                WHERE PatternID = @id
"@
            $updateCmd.Parameters.AddWithValue("@id", $existingID) | Out-Null
            $updateCmd.ExecuteNonQuery() | Out-Null
            
            $patternID = $existingID
        } else {
            # Insert new pattern
            $insertCmd = $connection.CreateCommand()
            $insertCmd.CommandText = @"
                INSERT INTO ErrorPatterns (ErrorSignature, ErrorType, ASTPattern) 
                VALUES (@sig, @type, @ast)
"@
            $insertCmd.Parameters.AddWithValue("@sig", $Pattern.PatternHash) | Out-Null
            $insertCmd.Parameters.AddWithValue("@type", $Pattern.ErrorType) | Out-Null
            $insertCmd.Parameters.AddWithValue("@ast", ($Pattern | ConvertTo-Json -Compress)) | Out-Null
            $insertCmd.ExecuteNonQuery() | Out-Null
            
            $patternID = $connection.LastInsertRowId
        }
        
        # Add fix if provided
        if ($Fix) {
            $fixCmd = $connection.CreateCommand()
            $fixCmd.CommandText = @"
                INSERT INTO FixPatterns (PatternID, FixDescription, FixCode) 
                VALUES (@pid, @desc, @code)
"@
            $fixCmd.Parameters.AddWithValue("@pid", $patternID) | Out-Null
            $fixCmd.Parameters.AddWithValue("@desc", "Automated fix") | Out-Null
            $fixCmd.Parameters.AddWithValue("@code", $Fix) | Out-Null
            $fixCmd.ExecuteNonQuery() | Out-Null
        }
        
        Write-Verbose "Added/updated SQLite pattern: $($Pattern.PatternHash)"
        return $patternID
        
    } catch {
        throw "SQLite pattern storage failed: $_"
    } finally {
        if ($connection.State -eq 'Open') {
            $connection.Close()
        }
        $connection.Dispose()
    }
}

function Find-SimilarPatterns {
    <#
    .SYNOPSIS
    Finds patterns similar to the given error signature
    .DESCRIPTION
    Searches for patterns with similar error signatures using string similarity algorithms
    .PARAMETER ErrorSignature
    The error signature to find similarities for
    .PARAMETER SimilarityThreshold
    Minimum similarity score (0.0-1.0) to include in results
    .PARAMETER MaxResults
    Maximum number of results to return
    .PARAMETER UseCache
    Whether to use cached similarity scores
    .EXAMPLE
    Find-SimilarPatterns -ErrorSignature "CS0246: Type not found" -SimilarityThreshold 0.7
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ErrorSignature,
        [double]$SimilarityThreshold = 0.7,
        [int]$MaxResults = 10,
        [bool]$UseCache = $true
    )
    
    Write-Verbose "Finding similar patterns for: $ErrorSignature (threshold: $SimilarityThreshold)"
    
    $config = Get-LearningConfiguration
    
    switch ($config.StorageBackend) {
        "SQLite" {
            return Find-SimilarPatternsSQLite -ErrorSignature $ErrorSignature -SimilarityThreshold $SimilarityThreshold -MaxResults $MaxResults -UseCache $UseCache
        }
        "JSON" {
            return Find-SimilarPatternsJSON -ErrorSignature $ErrorSignature -SimilarityThreshold $SimilarityThreshold -MaxResults $MaxResults -UseCache $UseCache
        }
        "Memory" {
            return Find-SimilarPatternsMemory -ErrorSignature $ErrorSignature -SimilarityThreshold $SimilarityThreshold -MaxResults $MaxResults -UseCache $UseCache
        }
        default {
            Write-Warning "Unknown storage backend: $($config.StorageBackend). Using memory backend."
            return Find-SimilarPatternsMemory -ErrorSignature $ErrorSignature -SimilarityThreshold $SimilarityThreshold -MaxResults $MaxResults -UseCache $UseCache
        }
    }
}

function Find-SimilarPatternsMemory {
    <#
    .SYNOPSIS
    Memory-specific implementation of similar patterns search
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ErrorSignature,
        [double]$SimilarityThreshold = 0.7,
        [int]$MaxResults = 10,
        [bool]$UseCache = $true
    )
    
    Write-Verbose "Finding similar patterns in memory backend"
    
    try {
        # Get patterns from memory cache
        if (-not $script:PatternCache) {
            Write-Verbose "No patterns found in memory storage"
            return @()
        }
        
        $similarPatterns = @()
        
        # Calculate similarities for each pattern
        foreach ($patternId in $script:PatternCache.Keys) {
            $pattern = $script:PatternCache[$patternId]
            
            if ($pattern.ErrorSignature -eq $ErrorSignature) {
                continue  # Skip exact same signature
            }
            
            $similarity = Get-StringSimilarity -String1 $ErrorSignature -String2 $pattern.ErrorSignature
            
            if ($similarity -ge $SimilarityThreshold) {
                # Calculate confidence score
                $confidence = $similarity * 0.8  # Basic confidence calculation
                
                $similarPatterns += [PSCustomObject]@{
                    PatternID = $patternId
                    ErrorSignature = $pattern.ErrorSignature
                    ErrorType = $pattern.ErrorType
                    SuccessRate = 0.8
                    UseCount = 1
                    Similarity = $similarity
                    Confidence = $confidence
                    Source = "Memory"
                }
            }
        }
        
        # Return top results sorted by confidence
        $results = @($similarPatterns | Sort-Object Confidence -Descending | Select-Object -First $MaxResults)
        
        Write-Verbose "Found $($results.Count) similar patterns above threshold $SimilarityThreshold"
        return $results
        
    } catch {
        Write-Error "Failed to find similar patterns in memory: $_"
        return @()
    }
}

function Calculate-ConfidenceScore {
    <#
    .SYNOPSIS
    Calculates confidence score for pattern matching
    .DESCRIPTION
    Combines similarity score, success rate, and usage patterns
    .PARAMETER PatternID
    The pattern to calculate confidence for
    .PARAMETER SimilarityScore
    Similarity score from pattern matching (0.0-1.0)
    .PARAMETER Context
    Context information for scoring
    .EXAMPLE
    Calculate-ConfidenceScore -PatternID 1 -SimilarityScore 0.85
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$PatternID,
        
        [Parameter(Mandatory=$true)]
        [double]$SimilarityScore,
        
        [Parameter()]
        [string]$Context = "General"
    )
    
    Write-Verbose "Calculating confidence score for Pattern:$PatternID, Similarity:$SimilarityScore"
    
    # Simple confidence calculation for refactored version
    $baseConfidence = $SimilarityScore * 0.6  # 60% weight to similarity
    $contextBonus = if ($Context -eq "General") { 0.2 } else { 0.3 }
    
    $finalConfidence = [Math]::Min(1.0, $baseConfidence + $contextBonus)
    
    return @{
        PatternID = $PatternID
        BaseConfidence = $baseConfidence
        SimilarityScore = $SimilarityScore
        ContextBonus = $contextBonus
        FinalConfidence = $finalConfidence
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Add-ErrorPattern',
    'Add-ErrorPatternSQLite',
    'Find-SimilarPatterns',
    'Find-SimilarPatternsMemory',
    'Calculate-ConfidenceScore'
)

if (Get-Command Write-ModuleLog -ErrorAction SilentlyContinue) {
    Write-ModuleLog -Message "PatternRecognition component loaded successfully" -Level "DEBUG"
} else {
    Write-Verbose "[PatternRecognition] Component loaded successfully"
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCARZzaf5pspK2gk
# 9EuMGHfVHW71yLwpDHeeObUXGqFTb6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIGMKABWewdKUpwawzEYu0NK+
# uDJDtOyIeml1W73JYqH5MA0GCSqGSIb3DQEBAQUABIIBAIBk4POB75yjB7/GpRn9
# MVoj68kf4lepzcRtnUCQMfU9FcAXAxsbF9PTqa7o9y7tFJENhQpQtmt4IhCYad6P
# u5mL6d8OAMg5MtSZ286lAfrwUDbFKXFUniKm8lXJhHzGhaslIfem6nCT9tx4P6zx
# lZ0cd8OY5bkYx2HwPetCzpIXoWCbiIob8bVRA6Jr60REIIhNkme1GbFX0H8+2y4V
# ti5CEYKlnJUpXN5585nMviia1VZq6npwQMo1LB/fZxWGw9RV+pd+LfwLUPNfl0BD
# XzEQ3wS0aYBzyj794HNkqWEsIPR3sxgZeT+AnSll+QTdBWC3utiOOCFqux00HRfh
# Pv0=
# SIG # End signature block
