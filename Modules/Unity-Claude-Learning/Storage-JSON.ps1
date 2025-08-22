# Storage-JSON.ps1
# JSON-based storage backend for Unity-Claude-Learning module
# Provides SQLite-compatible API using JSON persistence
# No external dependencies required

#region JSON Storage Configuration

$script:JSONStorageConfig = @{
    PatternsFile = "patterns.json"
    SimilarityFile = "similarities.json" 
    ConfidenceFile = "confidence.json"
    MetricsFile = "metrics.json"
    BackupRetention = 5  # Keep last 5 backups
}

#endregion

#region Core Storage Functions

function Initialize-JSONStorage {
    <#
    .SYNOPSIS
    Initializes JSON-based storage system
    
    .DESCRIPTION
    Creates necessary JSON files and directory structure
    #>
    [CmdletBinding()]
    param(
        [string]$StoragePath = $PSScriptRoot
    )
    
    Write-Verbose "Initializing JSON storage at: $StoragePath"
    
    try {
        # Ensure storage directory exists
        if (-not (Test-Path $StoragePath)) {
            New-Item -Path $StoragePath -ItemType Directory -Force | Out-Null
        }
        
        # Initialize storage files if they don't exist
        $files = @(
            @{ Name = $script:JSONStorageConfig.PatternsFile; Content = @{} }
            @{ Name = $script:JSONStorageConfig.SimilarityFile; Content = @{} }
            @{ Name = $script:JSONStorageConfig.ConfidenceFile; Content = @{} }
            @{ Name = $script:JSONStorageConfig.MetricsFile; Content = @{
                TotalPatterns = 0
                TotalSimilarities = 0
                TotalConfidenceScores = 0
                LastUpdated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            }}
        )
        
        foreach ($file in $files) {
            $filePath = Join-Path $StoragePath $file.Name
            if (-not (Test-Path $filePath)) {
                $file.Content | ConvertTo-Json -Depth 10 | Set-Content $filePath -Encoding UTF8
                Write-Verbose "Created storage file: $($file.Name)"
            }
        }
        
        Write-Verbose "JSON storage initialized successfully"
        return @{
            Success = $true
            StoragePath = $StoragePath
            Backend = "JSON"
        }
        
    } catch {
        Write-Error "Failed to initialize JSON storage: $_"
        return @{
            Success = $false
            Error = $_.Exception.Message
            Backend = "JSON"
        }
    }
}

function Save-PatternToJSON {
    <#
    .SYNOPSIS
    Saves an error pattern to JSON storage
    
    .DESCRIPTION
    Stores pattern with auto-generated ID and metadata
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ErrorSignature,
        
        [Parameter(Mandatory=$true)]
        [string]$ErrorType,
        
        [string]$Fix = "",
        
        [string]$ASTPattern = "",
        
        [string]$StoragePath = $PSScriptRoot
    )
    
    Write-Verbose "Saving pattern to JSON: $ErrorSignature"
    
    try {
        $patternsFile = Join-Path $StoragePath $script:JSONStorageConfig.PatternsFile
        
        # Load existing patterns (PowerShell 5.1 compatible)
        if (Test-Path $patternsFile) {
            $patternsJson = Get-Content $patternsFile -Raw | ConvertFrom-Json
            # Convert PSCustomObject to hashtable for PS5.1 compatibility
            $patterns = @{}
            if ($patternsJson) {
                $patternsJson.PSObject.Properties | ForEach-Object {
                    $patterns[$_.Name] = $_.Value
                }
            }
        } else {
            $patterns = @{}
        }
        
        # Generate unique pattern ID
        $patternId = "PATTERN_" + [System.Guid]::NewGuid().ToString("N").Substring(0, 8).ToUpper()
        
        # Create pattern object
        $pattern = @{
            PatternID = $patternId
            ErrorSignature = $ErrorSignature
            ErrorType = $ErrorType
            ASTPattern = $ASTPattern
            SuccessRate = 0.0
            UseCount = 0
            Created = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            LastSeen = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            Fixes = @()
        }
        
        # Add fix if provided
        if ($Fix) {
            $fixId = "FIX_" + [System.Guid]::NewGuid().ToString("N").Substring(0, 8).ToUpper()
            $fixObject = @{
                FixID = $fixId
                Description = "Automated fix"
                Code = $Fix
                SuccessCount = 0
                FailureCount = 0
                Created = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            }
            $pattern.Fixes = @($fixObject)
        }
        
        # Store pattern
        $patterns[$patternId] = $pattern
        
        # Save to file with backup
        Backup-JSONFile -FilePath $patternsFile
        $patterns | ConvertTo-Json -Depth 10 | Set-Content $patternsFile -Encoding UTF8
        
        # Update metrics
        Update-JSONMetrics -StoragePath $StoragePath -Operation "PatternAdded"
        
        Write-Verbose "Pattern saved with ID: $patternId"
        return $patternId
        
    } catch {
        Write-Error "Failed to save pattern to JSON: $_"
        return $null
    }
}

function Get-PatternsFromJSON {
    <#
    .SYNOPSIS
    Retrieves patterns from JSON storage
    
    .DESCRIPTION
    Gets all patterns or filters by criteria
    #>
    [CmdletBinding()]
    param(
        [string]$ErrorType = "",
        [double]$MinSuccessRate = 0.0,
        [int]$MaxResults = 100,
        [string]$StoragePath = $PSScriptRoot
    )
    
    Write-Verbose "Loading patterns from JSON storage"
    
    try {
        $patternsFile = Join-Path $StoragePath $script:JSONStorageConfig.PatternsFile
        
        if (-not (Test-Path $patternsFile)) {
            Write-Verbose "No patterns file found"
            return @()
        }
        
        # PowerShell 5.1 compatible JSON parsing
        $patternsJson = Get-Content $patternsFile -Raw | ConvertFrom-Json
        $patterns = @{}
        if ($patternsJson) {
            $patternsJson.PSObject.Properties | ForEach-Object {
                $patterns[$_.Name] = $_.Value
            }
        }
        $results = @()
        
        foreach ($patternId in $patterns.Keys) {
            $pattern = $patterns[$patternId]
            
            # Apply filters
            if ($ErrorType -and $pattern.ErrorType -ne $ErrorType) { continue }
            if ($pattern.SuccessRate -lt $MinSuccessRate) { continue }
            
            $results += [PSCustomObject]@{
                PatternID = $pattern.PatternID
                ErrorSignature = $pattern.ErrorSignature
                ErrorType = $pattern.ErrorType
                SuccessRate = $pattern.SuccessRate
                UseCount = $pattern.UseCount
                Fixes = $pattern.Fixes
                Created = $pattern.Created
                LastSeen = $pattern.LastSeen
            }
        }
        
        # Sort by success rate and use count, limit results
        $results = $results | Sort-Object SuccessRate, UseCount -Descending | Select-Object -First $MaxResults
        
        Write-Verbose "Retrieved $($results.Count) patterns from JSON storage"
        return $results
        
    } catch {
        Write-Error "Failed to get patterns from JSON: $_"
        return @()
    }
}

function Save-SimilarityToJSON {
    <#
    .SYNOPSIS
    Caches similarity calculation in JSON storage
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$SourcePatternID,
        
        [Parameter(Mandatory=$true)]
        [string]$TargetPatternID,
        
        [Parameter(Mandatory=$true)]
        [double]$SimilarityScore,
        
        [string]$Algorithm = "Levenshtein",
        [string]$StoragePath = $PSScriptRoot
    )
    
    Write-Verbose "Caching similarity: $SourcePatternID -> $TargetPatternID = $SimilarityScore"
    
    try {
        $similarityFile = Join-Path $StoragePath $script:JSONStorageConfig.SimilarityFile
        
        # Load existing similarities (PowerShell 5.1 compatible)
        if (Test-Path $similarityFile) {
            $similaritiesJson = Get-Content $similarityFile -Raw | ConvertFrom-Json
            $similarities = @{}
            if ($similaritiesJson) {
                $similaritiesJson.PSObject.Properties | ForEach-Object {
                    $similarities[$_.Name] = $_.Value
                }
            }
        } else {
            $similarities = @{}
        }
        
        # Create similarity key
        $key = "$SourcePatternID|$TargetPatternID|$Algorithm"
        
        # Store similarity
        $similarities[$key] = @{
            SourcePatternID = $SourcePatternID
            TargetPatternID = $TargetPatternID
            SimilarityScore = $SimilarityScore
            Algorithm = $Algorithm
            Calculated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            UseCount = 1
        }
        
        # Save to file
        Backup-JSONFile -FilePath $similarityFile
        $similarities | ConvertTo-Json -Depth 10 | Set-Content $similarityFile -Encoding UTF8
        
        # Update metrics
        Update-JSONMetrics -StoragePath $StoragePath -Operation "SimilarityAdded"
        
        Write-Verbose "Similarity cached successfully"
        return $true
        
    } catch {
        Write-Error "Failed to save similarity to JSON: $_"
        return $false
    }
}

function Get-SimilarityFromJSON {
    <#
    .SYNOPSIS
    Retrieves cached similarity scores from JSON storage
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$SourcePatternID,
        
        [double]$MinSimilarity = 0.0,
        [string]$Algorithm = "Levenshtein",
        [string]$StoragePath = $PSScriptRoot
    )
    
    Write-Verbose "Loading similarities for pattern: $SourcePatternID"
    
    try {
        $similarityFile = Join-Path $StoragePath $script:JSONStorageConfig.SimilarityFile
        
        if (-not (Test-Path $similarityFile)) {
            Write-Verbose "No similarity cache found"
            return @()
        }
        
        # PowerShell 5.1 compatible JSON parsing
        $similaritiesJson = Get-Content $similarityFile -Raw | ConvertFrom-Json
        $similarities = @{}
        if ($similaritiesJson) {
            $similaritiesJson.PSObject.Properties | ForEach-Object {
                $similarities[$_.Name] = $_.Value
            }
        }
        $results = @()
        
        foreach ($key in $similarities.Keys) {
            $similarity = $similarities[$key]
            
            # Filter by source pattern and algorithm
            if ($similarity.SourcePatternID -eq $SourcePatternID -and 
                $similarity.Algorithm -eq $Algorithm -and
                $similarity.SimilarityScore -ge $MinSimilarity) {
                
                $results += [PSCustomObject]@{
                    SourcePatternID = $similarity.SourcePatternID
                    TargetPatternID = $similarity.TargetPatternID
                    SimilarityScore = $similarity.SimilarityScore
                    Algorithm = $similarity.Algorithm
                    UseCount = $similarity.UseCount
                    Calculated = $similarity.Calculated
                }
                
                # Update use count
                $similarities[$key].UseCount++
            }
        }
        
        # Save updated use counts
        if ($results.Count -gt 0) {
            $similarities | ConvertTo-Json -Depth 10 | Set-Content $similarityFile -Encoding UTF8
        }
        
        Write-Verbose "Found $($results.Count) cached similarities"
        return $results
        
    } catch {
        Write-Error "Failed to get similarities from JSON: $_"
        return @()
    }
}

function Save-ConfidenceToJSON {
    <#
    .SYNOPSIS
    Saves confidence score calculation to JSON storage
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$PatternID,
        
        [Parameter(Mandatory=$true)]
        [double]$FinalConfidence,
        
        [hashtable]$Components = @{},
        [string]$Context = "General",
        [string]$StoragePath = $PSScriptRoot
    )
    
    Write-Verbose "Saving confidence score for pattern: $PatternID"
    
    try {
        $confidenceFile = Join-Path $StoragePath $script:JSONStorageConfig.ConfidenceFile
        
        # Load existing confidence scores (PowerShell 5.1 compatible)
        if (Test-Path $confidenceFile) {
            $confidenceJson = Get-Content $confidenceFile -Raw | ConvertFrom-Json
            $confidenceScores = @{}
            if ($confidenceJson) {
                $confidenceJson.PSObject.Properties | ForEach-Object {
                    $confidenceScores[$_.Name] = $_.Value
                }
            }
        } else {
            $confidenceScores = @{}
        }
        
        # Create confidence record
        $confidenceId = "CONF_" + [System.Guid]::NewGuid().ToString("N").Substring(0, 8).ToUpper()
        
        $confidenceScores[$confidenceId] = @{
            ConfidenceID = $confidenceId
            PatternID = $PatternID
            FinalConfidence = $FinalConfidence
            Components = $Components
            Context = $Context
            Calculated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        }
        
        # Save to file
        Backup-JSONFile -FilePath $confidenceFile
        $confidenceScores | ConvertTo-Json -Depth 10 | Set-Content $confidenceFile -Encoding UTF8
        
        # Update metrics
        Update-JSONMetrics -StoragePath $StoragePath -Operation "ConfidenceAdded"
        
        Write-Verbose "Confidence score saved successfully"
        return $confidenceId
        
    } catch {
        Write-Error "Failed to save confidence to JSON: $_"
        return $null
    }
}

#endregion

#region Utility Functions

function Backup-JSONFile {
    <#
    .SYNOPSIS
    Creates backup of JSON file before modification
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath
    )
    
    if (Test-Path $FilePath) {
        $backupDir = Join-Path (Split-Path $FilePath -Parent) "Backups"
        if (-not (Test-Path $backupDir)) {
            New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
        }
        
        $fileName = Split-Path $FilePath -Leaf
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupPath = Join-Path $backupDir "${fileName}_${timestamp}.backup"
        
        Copy-Item $FilePath $backupPath
        
        # Clean old backups (keep last 5)
        $backups = Get-ChildItem $backupDir -Filter "${fileName}_*.backup" | Sort-Object LastWriteTime -Descending
        if ($backups.Count -gt $script:JSONStorageConfig.BackupRetention) {
            $backups | Select-Object -Skip $script:JSONStorageConfig.BackupRetention | Remove-Item -Force
        }
    }
}

function Update-JSONMetrics {
    <#
    .SYNOPSIS
    Updates storage metrics
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$StoragePath,
        
        [Parameter(Mandatory=$true)]
        [string]$Operation
    )
    
    try {
        $metricsFile = Join-Path $StoragePath $script:JSONStorageConfig.MetricsFile
        
        if (Test-Path $metricsFile) {
            $metricsJson = Get-Content $metricsFile -Raw | ConvertFrom-Json
            $metrics = @{}
            if ($metricsJson) {
                $metricsJson.PSObject.Properties | ForEach-Object {
                    $metrics[$_.Name] = $_.Value
                }
            }
        } else {
            $metrics = @{}
        }
        
        # Update based on operation
        switch ($Operation) {
            "PatternAdded" { $metrics.TotalPatterns = ($metrics.TotalPatterns -as [int]) + 1 }
            "SimilarityAdded" { $metrics.TotalSimilarities = ($metrics.TotalSimilarities -as [int]) + 1 }
            "ConfidenceAdded" { $metrics.TotalConfidenceScores = ($metrics.TotalConfidenceScores -as [int]) + 1 }
        }
        
        $metrics.LastUpdated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        
        # Save updated metrics
        $metrics | ConvertTo-Json -Depth 5 | Set-Content $metricsFile -Encoding UTF8
        
    } catch {
        Write-Verbose "Failed to update metrics: $_"
    }
}

function Get-JSONStorageStats {
    <#
    .SYNOPSIS
    Gets statistics about JSON storage
    #>
    [CmdletBinding()]
    param(
        [string]$StoragePath = $PSScriptRoot
    )
    
    try {
        $metricsFile = Join-Path $StoragePath $script:JSONStorageConfig.MetricsFile
        
        if (Test-Path $metricsFile) {
            $metrics = Get-Content $metricsFile -Raw | ConvertFrom-Json
            return $metrics
        } else {
            return @{
                TotalPatterns = 0
                TotalSimilarities = 0
                TotalConfidenceScores = 0
                LastUpdated = "Never"
                Backend = "JSON"
            }
        }
        
    } catch {
        Write-Error "Failed to get JSON storage stats: $_"
        return @{ Error = $_.Exception.Message }
    }
}

#endregion

# Export functions for module use
Export-ModuleMember -Function @(
    'Initialize-JSONStorage',
    'Save-PatternToJSON',
    'Get-PatternsFromJSON', 
    'Save-SimilarityToJSON',
    'Get-SimilarityFromJSON',
    'Save-ConfidenceToJSON',
    'Get-JSONStorageStats'
)
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUFx3TtGyC/FhDhpuh7McT9JU8
# 2n2gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUYPalrwlbnfJjL0qy28a2/+oThF0wDQYJKoZIhvcNAQEBBQAEggEADPIV
# 2U7+z3epRbrrC857IMGzcXLM/+f3A6vRKKipER8JPDClq6IaTTkgSWaJ3TP6G/MJ
# TvrBOvHX237mIBTUyDnG57uyvm+fcKOQzJhwrf/plmDrdxQ9z86lHp2jFOaidnr/
# ys2vSO3ZIZGNy9SeGrPzMUVicjIWPpHEiufe4FI7zjaryunMTtQT73YRB0QDhbmK
# vEWKH1pmQcDHPJtzk3hLY91n2Al47aDe+O2dtej3tcUOwsGAmsfa50KD9X1M2ptJ
# eK7s1/LqIWvQjXjtaIarGO2ZLyD+au3TZLOCtEKhURV5BkyvmDjHH5w7tSbI9hQO
# f9YZqmvLXtXlUtB1Kg==
# SIG # End signature block
