# Unity-Claude-Learning.psm1
# Self-improvement and pattern recognition module for Unity-Claude Automation
# Phase 3 Implementation - Pattern Recognition, Self-Patching, Learning System

#region Module Configuration

$script:LearningConfig = @{
    DatabasePath = Join-Path $PSScriptRoot "LearningDatabase.db"
    StoragePath = $PSScriptRoot
    StorageBackend = "Unknown"  # Will be detected: "SQLite" or "JSON"
    MaxPatternAge = 30  # Days before pattern expires
    MinConfidence = 0.7  # Minimum confidence for auto-apply
    EnableAutoFix = $false  # Safety switch for self-patching
}

$script:PatternCache = @{}
$script:SuccessMetrics = @{
    TotalAttempts = 0
    SuccessfulFixes = 0
    FailedFixes = 0
    PatternsLearned = 0
}

#endregion

#region Database Setup

function Initialize-LearningDatabase {
    <#
    .SYNOPSIS
    Initializes the learning database for pattern storage
    
    .DESCRIPTION
    Creates SQLite database with tables for error patterns, fixes, and metrics
    #>
    [CmdletBinding()]
    param(
        [string]$DatabasePath = $script:LearningConfig.DatabasePath
    )
    
    Write-Verbose "Initializing learning database at: $DatabasePath"
    
    # Create database directory if needed
    $dbDir = Split-Path $DatabasePath -Parent
    if (-not (Test-Path $dbDir)) {
        New-Item -Path $dbDir -ItemType Directory -Force | Out-Null
    }
    
    # Initialize SQLite connection
    $connection = New-Object System.Data.SQLite.SQLiteConnection
    $connection.ConnectionString = "Data Source=$DatabasePath;Version=3;"
    
    try {
        $connection.Open()
        
        # Create tables
        $createTables = @"
-- Error patterns table
CREATE TABLE IF NOT EXISTS ErrorPatterns (
    PatternID INTEGER PRIMARY KEY AUTOINCREMENT,
    ErrorSignature TEXT NOT NULL,
    ErrorType TEXT,
    ASTPattern TEXT,
    SuccessRate REAL DEFAULT 0.0,
    UseCount INTEGER DEFAULT 0,
    LastSeen DATETIME DEFAULT CURRENT_TIMESTAMP,
    Created DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Fix patterns table
CREATE TABLE IF NOT EXISTS FixPatterns (
    FixID INTEGER PRIMARY KEY AUTOINCREMENT,
    PatternID INTEGER NOT NULL,
    FixDescription TEXT,
    FixAST TEXT,
    FixCode TEXT,
    SuccessCount INTEGER DEFAULT 0,
    FailureCount INTEGER DEFAULT 0,
    LastUsed DATETIME,
    Created DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (PatternID) REFERENCES ErrorPatterns(PatternID)
);

-- Success metrics table
CREATE TABLE IF NOT EXISTS SuccessMetrics (
    MetricID INTEGER PRIMARY KEY AUTOINCREMENT,
    PatternID INTEGER,
    FixID INTEGER,
    Success BOOLEAN,
    ExecutionTime REAL,
    ErrorBefore TEXT,
    ErrorAfter TEXT,
    Timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (PatternID) REFERENCES ErrorPatterns(PatternID),
    FOREIGN KEY (FixID) REFERENCES FixPatterns(FixID)
);

-- Pattern relationships table
CREATE TABLE IF NOT EXISTS PatternRelationships (
    RelationID INTEGER PRIMARY KEY AUTOINCREMENT,
    ParentPatternID INTEGER,
    ChildPatternID INTEGER,
    RelationType TEXT,
    Confidence REAL,
    FOREIGN KEY (ParentPatternID) REFERENCES ErrorPatterns(PatternID),
    FOREIGN KEY (ChildPatternID) REFERENCES ErrorPatterns(PatternID)
);

-- Pattern similarity table for fuzzy matching
CREATE TABLE IF NOT EXISTS PatternSimilarity (
    SimilarityID INTEGER PRIMARY KEY AUTOINCREMENT,
    SourcePatternID INTEGER NOT NULL,
    TargetPatternID INTEGER NOT NULL,
    SimilarityScore REAL NOT NULL,
    Algorithm TEXT DEFAULT 'Levenshtein',
    Calculated DATETIME DEFAULT CURRENT_TIMESTAMP,
    LastUsed DATETIME,
    UseCount INTEGER DEFAULT 0,
    FOREIGN KEY (SourcePatternID) REFERENCES ErrorPatterns(PatternID),
    FOREIGN KEY (TargetPatternID) REFERENCES ErrorPatterns(PatternID),
    UNIQUE(SourcePatternID, TargetPatternID, Algorithm)
);

-- Confidence scoring cache for performance
CREATE TABLE IF NOT EXISTS ConfidenceScores (
    ScoreID INTEGER PRIMARY KEY AUTOINCREMENT,
    PatternID INTEGER NOT NULL,
    FixID INTEGER,
    BaseConfidence REAL NOT NULL,
    SimilarityBonus REAL DEFAULT 0.0,
    SuccessRateBonus REAL DEFAULT 0.0,
    FinalConfidence REAL NOT NULL,
    Context TEXT,
    Calculated DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (PatternID) REFERENCES ErrorPatterns(PatternID),
    FOREIGN KEY (FixID) REFERENCES FixPatterns(FixID)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_error_signature ON ErrorPatterns(ErrorSignature);
CREATE INDEX IF NOT EXISTS idx_pattern_success ON ErrorPatterns(SuccessRate);
CREATE INDEX IF NOT EXISTS idx_fix_success ON FixPatterns(SuccessCount);
CREATE INDEX IF NOT EXISTS idx_similarity_source ON PatternSimilarity(SourcePatternID);
CREATE INDEX IF NOT EXISTS idx_similarity_score ON PatternSimilarity(SimilarityScore);
CREATE INDEX IF NOT EXISTS idx_confidence_pattern ON ConfidenceScores(PatternID);
CREATE INDEX IF NOT EXISTS idx_confidence_final ON ConfidenceScores(FinalConfidence);
"@
        
        $command = $connection.CreateCommand()
        $command.CommandText = $createTables
        $command.ExecuteNonQuery() | Out-Null
        
        Write-Verbose "Learning database initialized successfully"
        return @{
            Success = $true
            DatabasePath = $DatabasePath
        }
        
    } catch {
        Write-Error "Failed to initialize learning database: $_"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    } finally {
        if ($connection.State -eq 'Open') {
            $connection.Close()
        }
        $connection.Dispose()
    }
}

#endregion

#region String Similarity Functions

function Get-StringSimilarity {
    <#
    .SYNOPSIS
    Calculates string similarity using multiple algorithms
    
    .DESCRIPTION
    Implements Levenshtein distance and normalized similarity scoring
    for error pattern matching with confidence calculation
    
    .PARAMETER String1
    First string to compare
    
    .PARAMETER String2
    Second string to compare
    
    .PARAMETER Algorithm
    Algorithm to use: Levenshtein, JaroWinkler
    
    .EXAMPLE
    Get-StringSimilarity "error CS0246" "error CS0247" -Algorithm Levenshtein
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$String1,
        
        [Parameter(Mandatory=$true)]
        [string]$String2,
        
        [Parameter()]
        [ValidateSet('Levenshtein', 'JaroWinkler')]
        [string]$Algorithm = 'Levenshtein'
    )
    
    Write-Verbose "Calculating $Algorithm similarity between strings"
    
    try {
        switch ($Algorithm) {
            'Levenshtein' {
                $distance = Get-LevenshteinDistance -String1 $String1 -String2 $String2
                $maxLength = [Math]::Max($String1.Length, $String2.Length)
                if ($maxLength -eq 0) { return 1.0 }
                $similarity = 1.0 - ($distance / $maxLength)
                return [Math]::Max(0.0, $similarity)
            }
            'JaroWinkler' {
                # Fallback to Levenshtein if JaroWinkler library not available
                Write-Warning "JaroWinkler not implemented, using Levenshtein"
                return Get-StringSimilarity -String1 $String1 -String2 $String2 -Algorithm 'Levenshtein'
            }
        }
    } catch {
        Write-Error "Failed to calculate string similarity: $_"
        return 0.0
    }
}

function Get-LevenshteinDistance {
    <#
    .SYNOPSIS
    Calculates Levenshtein distance between two strings
    
    .DESCRIPTION
    Pure PowerShell implementation of Levenshtein distance algorithm
    Compatible with PowerShell 5.1
    
    .PARAMETER String1
    First string
    
    .PARAMETER String2
    Second string
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$String1,
        
        [Parameter(Mandatory=$true)]
        [string]$String2
    )
    
    Write-Verbose "Calculating Levenshtein distance"
    
    $len1 = $String1.Length
    $len2 = $String2.Length
    
    # Create matrix
    $matrix = New-Object 'int[,]' ($len1 + 1), ($len2 + 1)
    
    # Initialize first row and column
    for ($i = 0; $i -le $len1; $i++) {
        $matrix[$i, 0] = $i
    }
    for ($j = 0; $j -le $len2; $j++) {
        $matrix[0, $j] = $j
    }
    
    # Calculate distances
    for ($i = 1; $i -le $len1; $i++) {
        for ($j = 1; $j -le $len2; $j++) {
            $cost = if ($String1[$i-1] -eq $String2[$j-1]) { 0 } else { 1 }
            
            $matrix[$i, $j] = [Math]::Min(
                [Math]::Min(
                    ($matrix[($i-1), $j] + 1),      # deletion
                    ($matrix[$i, ($j-1)] + 1)       # insertion
                ),
                ($matrix[($i-1), ($j-1)] + $cost)     # substitution
            )
        }
    }
    
    return $matrix[$len1, $len2]
}

function Get-ErrorSignature {
    <#
    .SYNOPSIS
    Creates normalized error signature for pattern matching
    
    .DESCRIPTION
    Normalizes Unity compilation errors for consistent pattern matching
    
    .PARAMETER ErrorText
    Raw error text from Unity compilation
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ErrorText
    )
    
    Write-Verbose "Creating error signature from: $ErrorText"
    
    try {
        # Normalize error text
        $signature = $ErrorText.Trim()
        
        # Extract error code and basic pattern
        if ($signature -match '(?:error )?(?<code>CS\d+):\s*(?<message>.+)') {
            $errorCode = $Matches.code
            $message = $Matches.message
            
            # Normalize file paths to generic pattern
            $message = $message -replace '[\w\\\./]+\.cs\(\d+,\d+\)', 'FILE(LINE,COL)'
            
            # Normalize variable names and identifiers
            $message = $message -replace '\b\w+(?=\s+(could not be found|does not exist))', 'IDENTIFIER'
            
            # Normalize type names
            $message = $message -replace '\bThe type or namespace name\s+''\w+''', 'The type or namespace name ''TYPE'''
            
            $normalizedSignature = "$errorCode`: $message"
            
            Write-Verbose "Normalized signature: $normalizedSignature"
            return $normalizedSignature
        }
        
        # Fallback for non-standard errors
        return $signature
        
    } catch {
        Write-Error "Failed to create error signature: $_"
        return $ErrorText
    }
}

function Find-SimilarPatterns {
    <#
    .SYNOPSIS
    Finds similar error patterns from database using cached similarity scores
    
    .DESCRIPTION
    Searches for patterns with similarity above threshold, using cached calculations for performance
    
    .PARAMETER ErrorSignature
    Error signature to match against
    
    .PARAMETER SimilarityThreshold
    Minimum similarity score (0.0-1.0)
    
    .PARAMETER MaxResults
    Maximum number of results to return
    
    .PARAMETER UseCache
    Whether to use cached similarity scores (default: true)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ErrorSignature,
        
        [Parameter()]
        [double]$SimilarityThreshold = 0.7,
        
        [Parameter()]
        [int]$MaxResults = 10,
        
        [Parameter()]
        [bool]$UseCache = $true
    )
    
    Write-Verbose "Finding similar patterns for signature: $ErrorSignature"
    
    try {
        # Use appropriate storage backend for pattern similarity
        if ($script:LearningConfig.StorageBackend -eq "SQLite") {
            return Find-SimilarPatternsSQLite -ErrorSignature $ErrorSignature -SimilarityThreshold $SimilarityThreshold -MaxResults $MaxResults -UseCache $UseCache
        } elseif ($script:LearningConfig.StorageBackend -eq "JSON") {
            return Find-SimilarPatternsJSON -ErrorSignature $ErrorSignature -SimilarityThreshold $SimilarityThreshold -MaxResults $MaxResults -UseCache $UseCache
        } else {
            # No storage backend, use in-memory cache only
            return Find-SimilarPatternsMemory -ErrorSignature $ErrorSignature -SimilarityThreshold $SimilarityThreshold -MaxResults $MaxResults
        }
    } catch {
        Write-Error "Failed to find similar patterns: $_"
        return @()
    }
}

function Find-SimilarPatterns {
    <#
    .SYNOPSIS
    Finds patterns similar to the given error signature using configured storage backend
    
    .DESCRIPTION
    Searches for patterns with similar error signatures using string similarity algorithms.
    Uses storage abstraction layer with automatic backend detection.
    
    .PARAMETER ErrorSignature
    The error signature to find similarities for
    
    .PARAMETER SimilarityThreshold
    Minimum similarity score (0.0-1.0) to include in results
    
    .PARAMETER MaxResults
    Maximum number of results to return
    
    .PARAMETER UseCache
    Whether to use cached similarity scores
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
    
    # Use storage abstraction layer
    $backend = $script:LearningConfig.StorageBackend
    
    switch ($backend) {
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
            Write-Warning "Unknown storage backend: $backend. Using memory backend."
            return Find-SimilarPatternsMemory -ErrorSignature $ErrorSignature -SimilarityThreshold $SimilarityThreshold -MaxResults $MaxResults -UseCache $UseCache
        }
    }
}

function Find-SimilarPatternsSQLite {
    <#
    .SYNOPSIS
    SQLite-specific implementation of similar patterns search
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ErrorSignature,
        [double]$SimilarityThreshold = 0.7,
        [int]$MaxResults = 10,
        [bool]$UseCache = $true
    )
    
    try {
        $connection = New-Object System.Data.SQLite.SQLiteConnection
        $connection.ConnectionString = "Data Source=$($script:LearningConfig.DatabasePath);Version=3;"
        $connection.Open()
        
        # First, try to find an exact match for this signature
        $exactMatchCmd = $connection.CreateCommand()
        $exactMatchCmd.CommandText = "SELECT PatternID FROM ErrorPatterns WHERE ErrorSignature = @sig"
        $exactMatchCmd.Parameters.AddWithValue("@sig", $ErrorSignature) | Out-Null
        $sourcePatternID = $exactMatchCmd.ExecuteScalar()
        
        $similarPatterns = @()
        
        if ($sourcePatternID -and $UseCache) {
            # Use cached similarity scores if available
            Write-Verbose "Using cached similarity scores for pattern ID: $sourcePatternID"
            
            $cachedCmd = $connection.CreateCommand()
            $cachedCmd.CommandText = @"
SELECT 
    p.PatternID,
    p.ErrorSignature,
    p.ErrorType,
    p.SuccessRate,
    p.UseCount,
    s.SimilarityScore,
    (s.SimilarityScore * p.SuccessRate) as Confidence
FROM ErrorPatterns p
INNER JOIN PatternSimilarity s ON p.PatternID = s.TargetPatternID
WHERE s.SourcePatternID = @sourceID 
  AND s.SimilarityScore >= @threshold
ORDER BY Confidence DESC
LIMIT @maxResults
"@
            $cachedCmd.Parameters.AddWithValue("@sourceID", $sourcePatternID) | Out-Null
            $cachedCmd.Parameters.AddWithValue("@threshold", $SimilarityThreshold) | Out-Null
            $cachedCmd.Parameters.AddWithValue("@maxResults", $MaxResults) | Out-Null
            
            $reader = $cachedCmd.ExecuteReader()
            while ($reader.Read()) {
                $similarPatterns += [PSCustomObject]@{
                    PatternID = $reader['PatternID']
                    ErrorSignature = $reader['ErrorSignature']
                    ErrorType = $reader['ErrorType']
                    SuccessRate = [double]$reader['SuccessRate']
                    UseCount = [int]$reader['UseCount']
                    Similarity = [double]$reader['SimilarityScore']
                    Confidence = [double]$reader['Confidence']
                    Source = "Cached"
                }
            }
            $reader.Close()
            
            # Update usage statistics for cached similarities
            if ($similarPatterns.Count -gt 0) {
                $updateUsageCmd = $connection.CreateCommand()
                $updateUsageCmd.CommandText = @"
UPDATE PatternSimilarity 
SET UseCount = UseCount + 1, LastUsed = CURRENT_TIMESTAMP 
WHERE SourcePatternID = @sourceID AND SimilarityScore >= @threshold
"@
                $updateUsageCmd.Parameters.AddWithValue("@sourceID", $sourcePatternID) | Out-Null
                $updateUsageCmd.Parameters.AddWithValue("@threshold", $SimilarityThreshold) | Out-Null
                $updateUsageCmd.ExecuteNonQuery() | Out-Null
            }
        }
        
        # If no cached results or cache disabled, calculate fresh similarities
        if ($similarPatterns.Count -eq 0 -or -not $UseCache) {
            Write-Verbose "Calculating fresh similarity scores"
            
            # Get all patterns for comparison
            $allPatternsCmd = $connection.CreateCommand()
            $allPatternsCmd.CommandText = @"
SELECT PatternID, ErrorSignature, ErrorType, SuccessRate, UseCount 
FROM ErrorPatterns 
WHERE ErrorSignature != @sig
ORDER BY SuccessRate DESC, UseCount DESC
"@
            $allPatternsCmd.Parameters.AddWithValue("@sig", $ErrorSignature) | Out-Null
            
            $reader = $allPatternsCmd.ExecuteReader()
            $patterns = @()
            
            while ($reader.Read()) {
                $patterns += @{
                    PatternID = $reader['PatternID']
                    ErrorSignature = $reader['ErrorSignature']
                    ErrorType = $reader['ErrorType']
                    SuccessRate = [double]$reader['SuccessRate']
                    UseCount = [int]$reader['UseCount']
                }
            }
            $reader.Close()
            
            # Calculate similarities and cache them
            foreach ($pattern in $patterns) {
                $similarity = Get-StringSimilarity -String1 $ErrorSignature -String2 $pattern.ErrorSignature
                
                if ($similarity -ge $SimilarityThreshold) {
                    $similarPatterns += [PSCustomObject]@{
                        PatternID = $pattern.PatternID
                        ErrorSignature = $pattern.ErrorSignature
                        ErrorType = $pattern.ErrorType
                        SuccessRate = $pattern.SuccessRate
                        UseCount = $pattern.UseCount
                        Similarity = $similarity
                        Confidence = ($similarity * $pattern.SuccessRate)
                        Source = "Calculated"
                    }
                    
                    # Cache the similarity score if we have a source pattern ID
                    if ($sourcePatternID) {
                        try {
                            $cacheCmd = $connection.CreateCommand()
                            $cacheCmd.CommandText = @"
INSERT OR REPLACE INTO PatternSimilarity 
(SourcePatternID, TargetPatternID, SimilarityScore, Algorithm, UseCount) 
VALUES (@sourceID, @targetID, @score, 'Levenshtein', 1)
"@
                            $cacheCmd.Parameters.AddWithValue("@sourceID", $sourcePatternID) | Out-Null
                            $cacheCmd.Parameters.AddWithValue("@targetID", $pattern.PatternID) | Out-Null
                            $cacheCmd.Parameters.AddWithValue("@score", $similarity) | Out-Null
                            $cacheCmd.ExecuteNonQuery() | Out-Null
                        } catch {
                            Write-Verbose "Failed to cache similarity: $_"
                        }
                    }
                }
            }
        }
        
        # Return top results sorted by confidence
        $results = @($similarPatterns | Sort-Object Confidence -Descending | Select-Object -First $MaxResults)
        
        Write-Verbose "Found $($results.Count) similar patterns above threshold $SimilarityThreshold"
        return $results
        
    } catch {
        Write-Error "Failed to find similar patterns in SQLite: $_"
        return @()
    } finally {
        if ($connection -and $connection.State -eq 'Open') {
            $connection.Close()
        }
        if ($connection) {
            $connection.Dispose()
        }
    }
}

function Find-SimilarPatternsJSON {
    <#
    .SYNOPSIS
    JSON-specific implementation of similar patterns search
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ErrorSignature,
        [double]$SimilarityThreshold = 0.7,
        [int]$MaxResults = 10,
        [bool]$UseCache = $true
    )
    
    Write-Verbose "Finding similar patterns in JSON backend"
    
    try {
        # Get all patterns from JSON storage
        $patterns = Get-PatternsFromJSON -StoragePath $script:LearningConfig.StoragePath
        
        if ($patterns.Count -eq 0) {
            Write-Verbose "No patterns found in JSON storage"
            return @()
        }
        
        $similarPatterns = @()
        
        # Calculate similarities for each pattern
        foreach ($pattern in $patterns) {
            if ($pattern.ErrorSignature -eq $ErrorSignature) {
                continue  # Skip exact same signature
            }
            
            $similarity = Get-StringSimilarity -String1 $ErrorSignature -String2 $pattern.ErrorSignature
            
            if ($similarity -ge $SimilarityThreshold) {
                # Calculate confidence score
                $confidence = $similarity * ($pattern.SuccessRate -as [double])
                
                $similarPatterns += [PSCustomObject]@{
                    PatternID = $pattern.PatternID
                    ErrorSignature = $pattern.ErrorSignature
                    ErrorType = $pattern.ErrorType
                    SuccessRate = ($pattern.SuccessRate -as [double])
                    UseCount = ($pattern.UseCount -as [int])
                    Similarity = $similarity
                    Confidence = $confidence
                    Source = "JSON"
                }
                
                # Cache similarity if enabled
                if ($UseCache) {
                    $null = Save-SimilarityToJSON -SourcePatternID $ErrorSignature -TargetPatternID $pattern.PatternID -SimilarityScore $similarity -StoragePath $script:LearningConfig.StoragePath
                }
            }
        }
        
        # Return top results sorted by confidence
        $results = @($similarPatterns | Sort-Object Confidence -Descending | Select-Object -First $MaxResults)
        
        Write-Verbose "Found $($results.Count) similar patterns above threshold $SimilarityThreshold"
        return $results
        
    } catch {
        Write-Error "Failed to find similar patterns in JSON: $_"
        return @()
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
        if (-not $script:MemoryPatterns) {
            Write-Verbose "No patterns found in memory storage"
            return @()
        }
        
        $similarPatterns = @()
        
        # Calculate similarities for each pattern
        foreach ($patternId in $script:MemoryPatterns.Keys) {
            $pattern = $script:MemoryPatterns[$patternId]
            
            if ($pattern.ErrorSignature -eq $ErrorSignature) {
                continue  # Skip exact same signature
            }
            
            $similarity = Get-StringSimilarity -String1 $ErrorSignature -String2 $pattern.ErrorSignature
            
            if ($similarity -ge $SimilarityThreshold) {
                # Calculate confidence score
                $confidence = $similarity * $pattern.SuccessRate
                
                $similarPatterns += [PSCustomObject]@{
                    PatternID = $pattern.PatternID
                    ErrorSignature = $pattern.ErrorSignature
                    ErrorType = $pattern.ErrorType
                    SuccessRate = $pattern.SuccessRate
                    UseCount = $pattern.UseCount
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
    Calculates confidence score for pattern matching with similarity and success rate factors
    
    .DESCRIPTION
    Combines similarity score, success rate, and usage patterns to generate confidence
    
    .PARAMETER PatternID
    The pattern to calculate confidence for
    
    .PARAMETER SimilarityScore
    Similarity score from pattern matching (0.0-1.0)
    
    .PARAMETER Context
    Context information for scoring
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [int]$PatternID,
        
        [Parameter(Mandatory=$true)]
        [double]$SimilarityScore,
        
        [Parameter()]
        [string]$Context = "General"
    )
    
    Write-Verbose "Calculating confidence score for Pattern:$PatternID, Similarity:$SimilarityScore"
    
    try {
        $connection = New-Object System.Data.SQLite.SQLiteConnection
        $connection.ConnectionString = "Data Source=$($script:LearningConfig.DatabasePath);Version=3;"
        $connection.Open()
        
        # Get pattern details
        $patternCmd = $connection.CreateCommand()
        $patternCmd.CommandText = @"
SELECT 
    p.SuccessRate,
    p.UseCount,
    p.ErrorType,
    AVG(f.SuccessCount * 1.0 / NULLIF(f.SuccessCount + f.FailureCount, 0)) as AvgFixSuccess,
    COUNT(f.FixID) as FixCount
FROM ErrorPatterns p
LEFT JOIN FixPatterns f ON p.PatternID = f.PatternID
WHERE p.PatternID = @patternID
GROUP BY p.PatternID
"@
        $patternCmd.Parameters.AddWithValue("@patternID", $PatternID) | Out-Null
        
        $reader = $patternCmd.ExecuteReader()
        if ($reader.Read()) {
            $successRate = if ($reader["SuccessRate"] -ne [DBNull]::Value) { [double]$reader["SuccessRate"] } else { 0.0 }
            $useCount = if ($reader["UseCount"] -ne [DBNull]::Value) { [int]$reader["UseCount"] } else { 0 }
            $errorType = if ($reader["ErrorType"] -ne [DBNull]::Value) { $reader["ErrorType"] } else { "Unknown" }
            $avgFixSuccess = if ($reader["AvgFixSuccess"] -ne [DBNull]::Value) { [double]$reader["AvgFixSuccess"] } else { 0.0 }
            $fixCount = if ($reader["FixCount"] -ne [DBNull]::Value) { [int]$reader["FixCount"] } else { 0 }
        } else {
            throw "Pattern $PatternID not found"
        }
        $reader.Close()
        
        # Calculate confidence components
        $baseConfidence = $SimilarityScore * 0.4  # 40% weight to similarity
        $successRateBonus = $successRate * 0.3    # 30% weight to historical success
        $fixSuccessBonus = $avgFixSuccess * 0.2   # 20% weight to fix success rate
        
        # Usage and recency bonus (10% weight)
        $usageBonus = [Math]::Min($useCount / 10.0, 1.0) * 0.05  # Usage frequency
        $fixAvailabilityBonus = if ($fixCount -gt 0) { 0.05 } else { 0.0 }  # Has fixes available
        
        # Calculate final confidence
        $finalConfidence = $baseConfidence + $successRateBonus + $fixSuccessBonus + $usageBonus + $fixAvailabilityBonus
        $finalConfidence = [Math]::Max(0.0, [Math]::Min(1.0, $finalConfidence))  # Clamp to 0-1
        
        # Cache the confidence score
        $cacheCmd = $connection.CreateCommand()
        $cacheCmd.CommandText = @"
INSERT OR REPLACE INTO ConfidenceScores 
(PatternID, BaseConfidence, SimilarityBonus, SuccessRateBonus, FinalConfidence, Context) 
VALUES (@patternID, @base, @simBonus, @successBonus, @final, @context)
"@
        $cacheCmd.Parameters.AddWithValue("@patternID", $PatternID) | Out-Null
        $cacheCmd.Parameters.AddWithValue("@base", $baseConfidence) | Out-Null
        $cacheCmd.Parameters.AddWithValue("@simBonus", $SimilarityScore) | Out-Null
        $cacheCmd.Parameters.AddWithValue("@successBonus", $successRateBonus) | Out-Null
        $cacheCmd.Parameters.AddWithValue("@final", $finalConfidence) | Out-Null
        $cacheCmd.Parameters.AddWithValue("@context", $Context) | Out-Null
        $cacheCmd.ExecuteNonQuery() | Out-Null
        
        $connection.Close()
        
        $result = @{
            PatternID = $PatternID
            BaseConfidence = $baseConfidence
            SimilarityScore = $SimilarityScore
            SuccessRateBonus = $successRateBonus
            FixSuccessBonus = $fixSuccessBonus
            UsageBonus = $usageBonus
            FixAvailabilityBonus = $fixAvailabilityBonus
            FinalConfidence = $finalConfidence
            Components = @{
                Similarity = @{ Weight = 0.4; Score = $SimilarityScore; Contribution = $baseConfidence }
                SuccessRate = @{ Weight = 0.3; Score = $successRate; Contribution = $successRateBonus }
                FixSuccess = @{ Weight = 0.2; Score = $avgFixSuccess; Contribution = $fixSuccessBonus }
                Usage = @{ Weight = 0.05; Score = $useCount; Contribution = $usageBonus }
                FixAvailability = @{ Weight = 0.05; Score = $fixCount; Contribution = $fixAvailabilityBonus }
            }
        }
        
        Write-Verbose "Confidence calculated: $([Math]::Round($finalConfidence * 100, 1))%"
        return $result
        
    } catch {
        Write-Error "Failed to calculate confidence score: $_"
        return @{
            PatternID = $PatternID
            FinalConfidence = 0.0
            Error = $_.Exception.Message
        }
    } finally {
        if ($connection -and $connection.State -eq 'Open') {
            $connection.Close()
        }
        if ($connection) {
            $connection.Dispose()
        }
    }
}

#endregion

#region AST Analysis

function Get-CodeAST {
    <#
    .SYNOPSIS
    Parses code file into Abstract Syntax Tree
    
    .DESCRIPTION
    Supports PowerShell and C# code parsing for pattern analysis
    
    .PARAMETER FilePath
    Path to the code file
    
    .PARAMETER Language
    Programming language (PowerShell or CSharp)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,
        
        [ValidateSet('PowerShell','CSharp')]
        [string]$Language = 'PowerShell'
    )
    
    if (-not (Test-Path $FilePath)) {
        Write-Error "File not found: $FilePath"
        return $null
    }
    
    $content = Get-Content $FilePath -Raw
    
    switch ($Language) {
        'PowerShell' {
            try {
                $tokens = $null
                $errors = $null
                $ast = [System.Management.Automation.Language.Parser]::ParseInput(
                    $content, 
                    [ref]$tokens, 
                    [ref]$errors
                )
                
                return @{
                    AST = $ast
                    Tokens = $tokens
                    Errors = $errors
                    Language = 'PowerShell'
                }
            } catch {
                Write-Error "Failed to parse PowerShell AST: $_"
                return $null
            }
        }
        
        'CSharp' {
            # For C#, we'll use Roslyn if available, or regex patterns as fallback
            Write-Warning "C# AST parsing requires Roslyn - using pattern matching instead"
            
            # Extract basic structure using regex
            $patterns = @{
                Classes = [regex]::Matches($content, 'class\s+(\w+)')
                Methods = [regex]::Matches($content, '(public|private|protected|internal)\s+\w+\s+(\w+)\s*\(')
                Properties = [regex]::Matches($content, '(public|private|protected|internal)\s+\w+\s+(\w+)\s*{')
                Usings = [regex]::Matches($content, 'using\s+([\w.]+);')
            }
            
            return @{
                AST = $null  # Placeholder for Roslyn AST
                Patterns = $patterns
                Language = 'CSharp'
                Content = $content
            }
        }
    }
}

function Find-CodePattern {
    <#
    .SYNOPSIS
    Finds patterns in code AST that match error signatures
    
    .PARAMETER AST
    Abstract Syntax Tree to analyze
    
    .PARAMETER ErrorMessage
    Error message to match against
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$AST,
        
        [Parameter(Mandatory)]
        [string]$ErrorMessage
    )
    
    $patterns = @()
    
    # Extract error type from message
    $errorType = switch -Regex ($ErrorMessage) {
        'CS0246' { 'MissingUsing' }
        'CS0103' { 'UndefinedVariable' }
        'CS1061' { 'MissingMethod' }
        'CS0029' { 'TypeMismatch' }
        'null reference' { 'NullReference' }
        default { 'Unknown' }
    }
    
    # Build pattern signature
    $signature = @{
        ErrorType = $errorType
        ErrorMessage = $ErrorMessage
        Timestamp = Get-Date
    }
    
    # PowerShell AST analysis
    if ($AST.Language -eq 'PowerShell' -and $AST.AST) {
        # Find all variable assignments
        $variables = $AST.AST.FindAll({$args[0] -is [System.Management.Automation.Language.VariableExpressionAst]}, $true)
        
        # Find all function calls
        $functions = $AST.AST.FindAll({$args[0] -is [System.Management.Automation.Language.CommandAst]}, $true)
        
        # Find all pipeline operations
        $pipelines = $AST.AST.FindAll({$args[0] -is [System.Management.Automation.Language.PipelineAst]}, $true)
        
        $signature.Variables = $variables.Count
        $signature.Functions = $functions.Count
        $signature.Pipelines = $pipelines.Count
    }
    
    # Generate pattern hash for matching
    $patternHash = [System.BitConverter]::ToString(
        [System.Security.Cryptography.SHA256]::Create().ComputeHash(
            [System.Text.Encoding]::UTF8.GetBytes($ErrorMessage)
        )
    ).Replace("-","").Substring(0,16)
    
    $signature.PatternHash = $patternHash
    
    return $signature
}

#endregion

#region Pattern Recognition

function Add-ErrorPattern {
    <#
    .SYNOPSIS
    Adds a new error pattern to the learning storage
    
    .PARAMETER ErrorMessage
    The error message to learn from
    
    .PARAMETER Context
    Code context where error occurred (optional)
    
    .PARAMETER Fix
    The fix that resolved the error
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
        
        # Use appropriate storage backend
        switch ($script:LearningConfig.StorageBackend) {
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
                $patternId = Save-PatternToJSON -ErrorSignature $errorSignature -ErrorType $errorType -Fix $Fix -StoragePath $script:LearningConfig.StoragePath
                if ($patternId) {
                    $script:SuccessMetrics.PatternsLearned++
                    Write-Verbose "Pattern saved to JSON with ID: $patternId"
                    return $patternId
                } else {
                    throw "Failed to save pattern to JSON storage"
                }
            }
            
            default {
                # No storage available, work in memory only
                $patternId = "TEMP_" + [System.Guid]::NewGuid().ToString("N").Substring(0, 8).ToUpper()
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
    
    $connection = New-Object System.Data.SQLite.SQLiteConnection
    $connection.ConnectionString = "Data Source=$($script:LearningConfig.DatabasePath);Version=3;"
    
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

function Get-SuggestedFixes {
    <#
    .SYNOPSIS
    Gets suggested fixes for an error based on learned patterns
    
    .PARAMETER ErrorMessage
    The error message to find fixes for
    
    .PARAMETER MinConfidence
    Minimum confidence score for suggestions
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ErrorMessage,
        
        [double]$MinConfidence = 0.5
    )
    
    # Generate pattern hash
    $patternHash = [System.BitConverter]::ToString(
        [System.Security.Cryptography.SHA256]::Create().ComputeHash(
            [System.Text.Encoding]::UTF8.GetBytes($ErrorMessage)
        )
    ).Replace("-","").Substring(0,16)
    
    $connection = New-Object System.Data.SQLite.SQLiteConnection
    $connection.ConnectionString = "Data Source=$($script:LearningConfig.DatabasePath);Version=3;"
    
    try {
        $connection.Open()
        
        $query = @"
            SELECT 
                f.FixID,
                f.FixDescription,
                f.FixCode,
                e.SuccessRate,
                (f.SuccessCount * 1.0) / NULLIF(f.SuccessCount + f.FailureCount, 0) as FixSuccessRate
            FROM ErrorPatterns e
            JOIN FixPatterns f ON e.PatternID = f.PatternID
            WHERE e.ErrorSignature = @sig
                AND e.SuccessRate >= @minconf
            ORDER BY FixSuccessRate DESC, f.SuccessCount DESC
            LIMIT 5
"@
        
        $cmd = $connection.CreateCommand()
        $cmd.CommandText = $query
        $cmd.Parameters.AddWithValue("@sig", $patternHash) | Out-Null
        $cmd.Parameters.AddWithValue("@minconf", $MinConfidence) | Out-Null
        
        $reader = $cmd.ExecuteReader()
        $fixes = @()
        
        while ($reader.Read()) {
            $fixes += @{
                FixID = $reader["FixID"]
                Description = $reader["FixDescription"]
                Code = $reader["FixCode"]
                PatternSuccess = $reader["SuccessRate"]
                FixSuccess = $reader["FixSuccessRate"]
                Confidence = ($reader["SuccessRate"] + $reader["FixSuccessRate"]) / 2
            }
        }
        
        $reader.Close()
        
        return $fixes
        
    } catch {
        Write-Error "Failed to get suggested fixes: $_"
        return @()
    } finally {
        if ($connection.State -eq 'Open') {
            $connection.Close()
        }
        $connection.Dispose()
    }
}

#endregion

#region Self-Patching

function Apply-AutoFix {
    <#
    .SYNOPSIS
    Automatically applies a fix based on learned patterns
    
    .PARAMETER ErrorMessage
    The error to fix
    
    .PARAMETER FilePath
    File containing the error
    
    .PARAMETER DryRun
    If specified, shows what would be done without applying
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ErrorMessage,
        
        [string]$FilePath,
        
        [switch]$DryRun
    )
    
    if (-not $script:LearningConfig.EnableAutoFix -and -not $DryRun) {
        Write-Warning "Auto-fix is disabled. Enable with Set-LearningConfig -EnableAutoFix"
        return $false
    }
    
    # Get suggested fixes
    $fixes = Get-SuggestedFixes -ErrorMessage $ErrorMessage -MinConfidence $script:LearningConfig.MinConfidence
    
    if ($fixes.Count -eq 0) {
        Write-Verbose "No fixes found for error pattern"
        return $false
    }
    
    $bestFix = $fixes[0]
    Write-Host "Found fix with $([Math]::Round($bestFix.Confidence * 100, 2))% confidence" -ForegroundColor Yellow
    
    if ($DryRun) {
        Write-Host "DRY RUN - Would apply fix:" -ForegroundColor Cyan
        Write-Host $bestFix.Code -ForegroundColor Gray
        return $true
    }
    
    # Create backup
    if ($FilePath -and (Test-Path $FilePath)) {
        $backup = "$FilePath.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Copy-Item $FilePath $backup
        Write-Verbose "Created backup: $backup"
    }
    
    try {
        # Apply the fix
        if ($FilePath) {
            # File-based fix
            $content = Get-Content $FilePath -Raw
            $newContent = $content + "`n" + $bestFix.Code
            Set-Content $FilePath $newContent
        } else {
            # Execute fix directly
            Invoke-Expression $bestFix.Code
        }
        
        $script:SuccessMetrics.TotalAttempts++
        
        Write-Host "Fix applied successfully" -ForegroundColor Green
        return $true
        
    } catch {
        Write-Error "Failed to apply fix: $_"
        
        # Restore backup if exists
        if ($backup -and (Test-Path $backup)) {
            Copy-Item $backup $FilePath -Force
            Write-Host "Restored from backup" -ForegroundColor Yellow
        }
        
        return $false
    }
}

#endregion

#region Success Tracking

function Update-PatternSuccess {
    <#
    .SYNOPSIS
    Updates the success metrics for a pattern and fix
    
    .PARAMETER PatternID
    The pattern that was used
    
    .PARAMETER FixID
    The fix that was applied
    
    .PARAMETER Success
    Whether the fix was successful
    #>
    [CmdletBinding()]
    param(
        [int]$PatternID,
        [int]$FixID,
        [bool]$Success
    )
    
    $connection = New-Object System.Data.SQLite.SQLiteConnection
    $connection.ConnectionString = "Data Source=$($script:LearningConfig.DatabasePath);Version=3;"
    
    try {
        $connection.Open()
        
        # Update fix statistics
        $fixUpdate = $connection.CreateCommand()
        if ($Success) {
            $fixUpdate.CommandText = @"
                UPDATE FixPatterns 
                SET SuccessCount = SuccessCount + 1, 
                    LastUsed = CURRENT_TIMESTAMP 
                WHERE FixID = @fid
"@
            $script:SuccessMetrics.SuccessfulFixes++
        } else {
            $fixUpdate.CommandText = @"
                UPDATE FixPatterns 
                SET FailureCount = FailureCount + 1, 
                    LastUsed = CURRENT_TIMESTAMP 
                WHERE FixID = @fid
"@
            $script:SuccessMetrics.FailedFixes++
        }
        $fixUpdate.Parameters.AddWithValue("@fid", $FixID) | Out-Null
        $fixUpdate.ExecuteNonQuery() | Out-Null
        
        # Update pattern success rate
        $patternUpdate = $connection.CreateCommand()
        $patternUpdate.CommandText = @"
            UPDATE ErrorPatterns 
            SET SuccessRate = (
                SELECT AVG(CAST(SuccessCount AS REAL) / NULLIF(SuccessCount + FailureCount, 0))
                FROM FixPatterns 
                WHERE PatternID = @pid
            )
            WHERE PatternID = @pid
"@
        $patternUpdate.Parameters.AddWithValue("@pid", $PatternID) | Out-Null
        $patternUpdate.ExecuteNonQuery() | Out-Null
        
        # Log metric
        $metricInsert = $connection.CreateCommand()
        $metricInsert.CommandText = @"
            INSERT INTO SuccessMetrics (PatternID, FixID, Success) 
            VALUES (@pid, @fid, @success)
"@
        $metricInsert.Parameters.AddWithValue("@pid", $PatternID) | Out-Null
        $metricInsert.Parameters.AddWithValue("@fid", $FixID) | Out-Null
        $metricInsert.Parameters.AddWithValue("@success", $Success) | Out-Null
        $metricInsert.ExecuteNonQuery() | Out-Null
        
        Write-Verbose "Updated success metrics for Pattern:$PatternID Fix:$FixID Success:$Success"
        
    } catch {
        Write-Error "Failed to update pattern success: $_"
    } finally {
        if ($connection.State -eq 'Open') {
            $connection.Close()
        }
        $connection.Dispose()
    }
}

function Get-LearningReport {
    <#
    .SYNOPSIS
    Generates a report of learning system performance
    #>
    [CmdletBinding()]
    param()
    
    $report = @{
        Generated = Get-Date
        Metrics = $script:SuccessMetrics
        TopPatterns = @()
        RecentFixes = @()
        SuccessRate = 0
    }
    
    # Calculate overall success rate
    if ($script:SuccessMetrics.TotalAttempts -gt 0) {
        $report.SuccessRate = $script:SuccessMetrics.SuccessfulFixes / $script:SuccessMetrics.TotalAttempts
    }
    
    $connection = New-Object System.Data.SQLite.SQLiteConnection
    $connection.ConnectionString = "Data Source=$($script:LearningConfig.DatabasePath);Version=3;"
    
    try {
        $connection.Open()
        
        # Get top patterns
        $topCmd = $connection.CreateCommand()
        $topCmd.CommandText = @"
            SELECT ErrorType, SuccessRate, UseCount 
            FROM ErrorPatterns 
            ORDER BY SuccessRate DESC, UseCount DESC 
            LIMIT 10
"@
        
        $reader = $topCmd.ExecuteReader()
        while ($reader.Read()) {
            $report.TopPatterns += @{
                Type = $reader["ErrorType"]
                SuccessRate = $reader["SuccessRate"]
                UseCount = $reader["UseCount"]
            }
        }
        $reader.Close()
        
        # Get recent successful fixes
        $recentCmd = $connection.CreateCommand()
        $recentCmd.CommandText = @"
            SELECT f.FixDescription, m.Timestamp, m.Success
            FROM SuccessMetrics m
            JOIN FixPatterns f ON m.FixID = f.FixID
            ORDER BY m.Timestamp DESC
            LIMIT 10
"@
        
        $reader = $recentCmd.ExecuteReader()
        while ($reader.Read()) {
            $report.RecentFixes += @{
                Description = $reader["FixDescription"]
                Timestamp = $reader["Timestamp"]
                Success = $reader["Success"]
            }
        }
        $reader.Close()
        
    } catch {
        Write-Error "Failed to generate learning report: $_"
    } finally {
        if ($connection.State -eq 'Open') {
            $connection.Close()
        }
        $connection.Dispose()
    }
    
    return $report
}

#endregion

#region Week 2: Metrics Collection System

function Record-PatternApplicationMetric {
    <#
    .SYNOPSIS
    Records metrics for pattern application attempts with execution time and outcome
    
    .DESCRIPTION
    Tracks success/failure, confidence scores, execution time, and outcomes for learning analytics
    
    .PARAMETER PatternID
    ID of the pattern that was applied
    
    .PARAMETER ConfidenceScore
    Confidence score (0.0-1.0) when pattern was applied
    
    .PARAMETER Success
    Whether the pattern application was successful
    
    .PARAMETER ExecutionTimeMs
    Execution time in milliseconds
    
    .PARAMETER ErrorMessage
    Error message if application failed
    
    .PARAMETER Context
    Additional context information
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$PatternID,
        
        [Parameter(Mandatory=$true)]
        [double]$ConfidenceScore,
        
        [Parameter(Mandatory=$true)]
        [bool]$Success,
        
        [Parameter(Mandatory=$true)]
        [int]$ExecutionTimeMs,
        
        [string]$ErrorMessage = "",
        [string]$Context = "PatternApplication"
    )
    
    Write-Verbose "Recording pattern application metric: PatternID=$PatternID, Success=$Success, Confidence=$ConfidenceScore, Time=${ExecutionTimeMs}ms"
    
    try {
        # Create metric record
        $metricId = "METRIC_" + [System.Guid]::NewGuid().ToString("N").Substring(0, 8).ToUpper()
        $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        
        $metric = @{
            MetricID = $metricId
            PatternID = $PatternID
            ConfidenceScore = $ConfidenceScore
            Success = $Success
            ExecutionTimeMs = $ExecutionTimeMs
            ErrorMessage = $ErrorMessage
            Context = $Context
            Timestamp = $timestamp
        }
        
        # Save to JSON storage
        $backend = $script:LearningConfig.StorageBackend
        switch ($backend) {
            "JSON" {
                $null = Save-MetricToJSON -Metric $metric -StoragePath $script:LearningConfig.StoragePath
            }
            "SQLite" {
                $null = Save-MetricToSQLite -Metric $metric
            }
            default {
                Write-Warning "No storage backend available, metric recorded to memory only"
                if (-not $script:MemoryMetrics) { $script:MemoryMetrics = @{} }
                $script:MemoryMetrics[$metricId] = $metric
            }
        }
        
        # Update success metrics cache
        $script:SuccessMetrics.TotalAttempts++
        if ($Success) {
            $script:SuccessMetrics.SuccessfulFixes++
        } else {
            $script:SuccessMetrics.FailedFixes++
        }
        
        Write-Verbose "Pattern application metric recorded successfully: $metricId"
        return $metricId
        
    } catch {
        Write-Error "Failed to record pattern application metric: $_"
        return $null
    }
}

function Save-MetricToJSON {
    <#
    .SYNOPSIS
    Saves metric data to JSON storage backend
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Metric,
        
        [string]$StoragePath = $PSScriptRoot
    )
    
    try {
        $metricsFile = Join-Path $StoragePath "metrics.json"
        
        # Load existing metrics (PowerShell 5.1 compatible)
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
        
        # Add new metric
        $metrics[$Metric.MetricID] = $Metric
        
        # Save to file with backup
        Backup-JSONFile -FilePath $metricsFile
        $metrics | ConvertTo-Json -Depth 10 | Set-Content $metricsFile -Encoding UTF8
        
        Write-Verbose "Metric saved to JSON: $($Metric.MetricID)"
        return $true
        
    } catch {
        Write-Error "Failed to save metric to JSON: $_"
        return $false
    }
}

function Get-LearningMetrics {
    <#
    .SYNOPSIS
    Retrieves learning metrics for analytics and reporting
    
    .DESCRIPTION
    Gets success rates, confidence calibration, execution times, and usage patterns
    
    .PARAMETER TimeRange
    Time range for metrics: Last24Hours, LastWeek, LastMonth, All
    
    .PARAMETER PatternID
    Optional pattern ID to filter metrics
    #>
    [CmdletBinding()]
    param(
        [ValidateSet("Last24Hours", "LastWeek", "LastMonth", "All")]
        [string]$TimeRange = "All",
        
        [string]$PatternID = ""
    )
    
    Write-Verbose "Retrieving learning metrics for time range: $TimeRange"
    
    try {
        $backend = $script:LearningConfig.StorageBackend
        $metrics = @()
        
        switch ($backend) {
            "JSON" {
                $metrics = Get-MetricsFromJSON -StoragePath $script:LearningConfig.StoragePath -TimeRange $TimeRange -PatternID $PatternID
            }
            "SQLite" {
                $metrics = Get-MetricsFromSQLite -TimeRange $TimeRange -PatternID $PatternID
            }
            default {
                if ($script:MemoryMetrics) {
                    $metrics = $script:MemoryMetrics.Values | Where-Object { 
                        (-not $PatternID -or $_.PatternID -eq $PatternID) 
                    }
                }
            }
        }
        
        # Calculate analytics
        if ($metrics.Count -gt 0) {
            $analytics = @{
                TotalApplications = $metrics.Count
                SuccessfulApplications = ($metrics | Where-Object { $_.Success }).Count
                FailedApplications = ($metrics | Where-Object { -not $_.Success }).Count
                SuccessRate = 0.0
                AverageConfidence = 0.0
                AverageExecutionTime = 0.0
                ConfidenceCalibration = @{}
                TimeRange = $TimeRange
            }
            
            if ($analytics.TotalApplications -gt 0) {
                $analytics.SuccessRate = [math]::Round($analytics.SuccessfulApplications / $analytics.TotalApplications, 4)
                $analytics.AverageConfidence = [math]::Round(($metrics | Measure-Object -Property ConfidenceScore -Average).Average, 4)
                $analytics.AverageExecutionTime = [math]::Round(($metrics | Measure-Object -Property ExecutionTimeMs -Average).Average, 2)
                
                # Confidence calibration analysis with explicit integer types
                $confidenceBuckets = @{
                    "0.0-0.1" = @{ Total = [int]0; Successful = [int]0 }
                    "0.1-0.2" = @{ Total = [int]0; Successful = [int]0 }
                    "0.2-0.3" = @{ Total = [int]0; Successful = [int]0 }
                    "0.3-0.4" = @{ Total = [int]0; Successful = [int]0 }
                    "0.4-0.5" = @{ Total = [int]0; Successful = [int]0 }
                    "0.5-0.6" = @{ Total = [int]0; Successful = [int]0 }
                    "0.6-0.7" = @{ Total = [int]0; Successful = [int]0 }
                    "0.7-0.8" = @{ Total = [int]0; Successful = [int]0 }
                    "0.8-0.9" = @{ Total = [int]0; Successful = [int]0 }
                    "0.9-1.0" = @{ Total = [int]0; Successful = [int]0 }
                }
                
                foreach ($metric in $metrics) {
                    # Ensure we have a valid confidence score
                    $confidence = if ($metric.ConfidenceScore) { [double]$metric.ConfidenceScore } else { 0.0 }
                    $bucket = switch ($confidence) {
                        { $_ -lt 0.1 } { "0.0-0.1" }
                        { $_ -lt 0.2 } { "0.1-0.2" }
                        { $_ -lt 0.3 } { "0.2-0.3" }
                        { $_ -lt 0.4 } { "0.3-0.4" }
                        { $_ -lt 0.5 } { "0.4-0.5" }
                        { $_ -lt 0.6 } { "0.5-0.6" }
                        { $_ -lt 0.7 } { "0.6-0.7" }
                        { $_ -lt 0.8 } { "0.7-0.8" }
                        { $_ -lt 0.9 } { "0.8-0.9" }
                        default { "0.9-1.0" }
                    }
                    
                    # Safely increment counters using intermediate variables to avoid array issues
                    # Research showed nested hashtable property access can return arrays in PS v3+
                    if ($confidenceBuckets.ContainsKey($bucket)) {
                        $bucketData = $confidenceBuckets[$bucket]
                        
                        # Get current values safely
                        $currentTotal = 0
                        if ($bucketData -and $bucketData.ContainsKey('Total')) {
                            $totalValue = $bucketData['Total']
                            if ($totalValue -ne $null -and $totalValue -isnot [System.Array]) {
                                $currentTotal = [int]$totalValue
                            }
                        }
                        
                        $currentSuccessful = 0
                        if ($bucketData -and $bucketData.ContainsKey('Successful')) {
                            $successValue = $bucketData['Successful']
                            if ($successValue -ne $null -and $successValue -isnot [System.Array]) {
                                $currentSuccessful = [int]$successValue
                            }
                        }
                        
                        # Update values
                        $bucketData['Total'] = $currentTotal + 1
                        if ($metric.Success -eq $true) {
                            $bucketData['Successful'] = $currentSuccessful + 1
                        }
                        
                        # Write back to main hashtable
                        $confidenceBuckets[$bucket] = $bucketData
                    }
                }
                
                # Calculate actual success rates per confidence bucket
                foreach ($bucket in $confidenceBuckets.Keys) {
                    if ($confidenceBuckets[$bucket].Total -gt 0) {
                        $actualSuccessRate = $confidenceBuckets[$bucket].Successful / $confidenceBuckets[$bucket].Total
                        $analytics.ConfidenceCalibration[$bucket] = @{
                            Total = $confidenceBuckets[$bucket].Total
                            Successful = $confidenceBuckets[$bucket].Successful
                            ActualSuccessRate = [math]::Round($actualSuccessRate, 4)
                        }
                    }
                }
            }
            
            Write-Verbose "Learning metrics retrieved: $($analytics.TotalApplications) applications, $($analytics.SuccessRate * 100)% success rate"
            return $analytics
            
        } else {
            Write-Verbose "No metrics found for specified criteria"
            return @{
                TotalApplications = 0
                SuccessfulApplications = 0
                FailedApplications = 0
                SuccessRate = 0.0
                AverageConfidence = 0.0
                AverageExecutionTime = 0.0
                ConfidenceCalibration = @{}
                TimeRange = $TimeRange
            }
        }
        
    } catch {
        Write-Error "Failed to retrieve learning metrics: $_"
        return $null
    }
}

function Get-MetricsFromJSON {
    <#
    .SYNOPSIS
    Retrieves metrics from JSON storage with time filtering
    #>
    [CmdletBinding()]
    param(
        [string]$StoragePath = $PSScriptRoot,
        [string]$TimeRange = "All",
        [string]$PatternID = ""
    )
    
    try {
        $metricsFile = Join-Path $StoragePath "metrics.json"
        
        if (-not (Test-Path $metricsFile)) {
            Write-Verbose "No metrics file found"
            return @()
        }
        
        # Load metrics (PowerShell 5.1 compatible)
        $metricsJson = Get-Content $metricsFile -Raw | ConvertFrom-Json
        $allMetrics = @()
        
        if ($metricsJson) {
            # Handle both array format (from direct save) and object format (from Save-MetricToJSON)
            if ($metricsJson -is [array]) {
                # Array format - metrics are directly in the array
                foreach ($metricObj in $metricsJson) {
                    # Ensure timestamp has a value for proper filtering
                    $timestampValue = if ($metricObj.Timestamp -and $metricObj.Timestamp -ne "") { 
                        [string]$metricObj.Timestamp 
                    } else { 
                        (Get-Date).ToString("yyyy-MM-dd HH:mm:ss") 
                    }
                    $metric = [PSCustomObject]@{
                        MetricID = [string]$metricObj.MetricID
                        PatternID = [string]$metricObj.PatternID
                        ConfidenceScore = [double]$metricObj.ConfidenceScore
                        Success = [bool]$metricObj.Success
                        ExecutionTimeMs = [int]$metricObj.ExecutionTimeMs
                        ErrorMessage = if ($metricObj.ErrorMessage) { [string]$metricObj.ErrorMessage } else { "" }
                        Context = if ($metricObj.Context) { [string]$metricObj.Context } else { "" }
                        Timestamp = $timestampValue
                    }
                    $allMetrics += $metric
                }
            } else {
                # Object format - metrics are properties of the object
                $metricsJson.PSObject.Properties | ForEach-Object {
                    # Convert to PSCustomObject with proper types for Measure-Object compatibility
                    $metricObj = $_.Value
                    # Ensure timestamp has a value for proper filtering
                    $timestampValue = if ($metricObj.Timestamp -and $metricObj.Timestamp -ne "") { 
                        [string]$metricObj.Timestamp 
                    } else { 
                        (Get-Date).ToString("yyyy-MM-dd HH:mm:ss") 
                    }
                    $metric = [PSCustomObject]@{
                        MetricID = [string]$metricObj.MetricID
                        PatternID = [string]$metricObj.PatternID
                        ConfidenceScore = [double]$metricObj.ConfidenceScore
                        Success = [bool]$metricObj.Success
                        ExecutionTimeMs = [int]$metricObj.ExecutionTimeMs
                        ErrorMessage = if ($metricObj.ErrorMessage) { [string]$metricObj.ErrorMessage } else { "" }
                        Context = if ($metricObj.Context) { [string]$metricObj.Context } else { "" }
                        Timestamp = $timestampValue
                    }
                    $allMetrics += $metric
                }
            }
        }
        
        # Apply time range filter
        $cutoffDate = switch ($TimeRange) {
            "Last24Hours" { (Get-Date).AddHours(-24) }
            "LastWeek" { (Get-Date).AddDays(-7) }
            "LastMonth" { (Get-Date).AddDays(-30) }
            default { [DateTime]::MinValue }
        }
        
        $filteredMetrics = $allMetrics | Where-Object {
            # Parse timestamp with explicit format for consistency
            try {
                # Try parsing with the exact format we use when saving
                $metricDate = [DateTime]::ParseExact($_.Timestamp, "yyyy-MM-dd HH:mm:ss", [System.Globalization.CultureInfo]::InvariantCulture)
            } catch {
                # Fallback to general parse if format doesn't match
                try {
                    $metricDate = [DateTime]::Parse($_.Timestamp)
                } catch {
                    Write-Verbose "Failed to parse timestamp: $($_.Timestamp), using current date"
                    $metricDate = Get-Date
                }
            }
            $metricDate -ge $cutoffDate -and
            (-not $PatternID -or $_.PatternID -eq $PatternID)
        }
        
        Write-Verbose "Retrieved $($filteredMetrics.Count) metrics from JSON storage"
        return $filteredMetrics
        
    } catch {
        Write-Error "Failed to retrieve metrics from JSON: $_"
        return @()
    }
}

function Measure-ExecutionTime {
    <#
    .SYNOPSIS
    Measures execution time of a script block with high precision
    
    .DESCRIPTION
    Uses System.Diagnostics.Stopwatch for precise timing measurement
    
    .PARAMETER ScriptBlock
    Script block to execute and measure
    
    .PARAMETER Description
    Description of the operation being measured
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock]$ScriptBlock,
        
        [string]$Description = "Operation"
    )
    
    Write-Verbose "Starting execution time measurement for: $Description"
    
    try {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $result = & $ScriptBlock
        $stopwatch.Stop()
        
        $executionTimeMs = $stopwatch.ElapsedMilliseconds
        Write-Verbose "$Description completed in ${executionTimeMs}ms"
        
        return @{
            Result = $result
            ExecutionTimeMs = $executionTimeMs
            Success = $true
            Error = $null
        }
        
    } catch {
        if ($stopwatch) { $stopwatch.Stop() }
        $executionTimeMs = if ($stopwatch) { $stopwatch.ElapsedMilliseconds } else { 0 }
        
        Write-Verbose "$Description failed after ${executionTimeMs}ms: $_"
        
        return @{
            Result = $null
            ExecutionTimeMs = $executionTimeMs
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Get-PatternUsageAnalytics {
    <#
    .SYNOPSIS
    Analyzes pattern usage frequency and effectiveness
    
    .DESCRIPTION
    Provides insights into which patterns are most used and most effective
    #>
    [CmdletBinding()]
    param(
        [int]$TopCount = 10
    )
    
    Write-Verbose "Analyzing pattern usage analytics (top $TopCount patterns)"
    
    try {
        $metrics = Get-LearningMetrics -TimeRange "All"
        
        if (-not $metrics -or $metrics.TotalApplications -eq 0) {
            Write-Verbose "No usage data available for analytics"
            return @{
                TopPatternsByUsage = @()
                TopPatternsBySuccessRate = @()
                TopPatternsByEffectiveness = @()
                Summary = "No usage data available"
            }
        }
        
        # Get detailed metrics per pattern
        $backend = $script:LearningConfig.StorageBackend
        $allMetrics = @()
        
        switch ($backend) {
            "JSON" {
                $allMetrics = Get-MetricsFromJSON -StoragePath $script:LearningConfig.StoragePath
            }
            default {
                if ($script:MemoryMetrics) {
                    $allMetrics = $script:MemoryMetrics.Values
                }
            }
        }
        
        # Group by pattern and calculate analytics
        $patternStats = @{}
        foreach ($metric in $allMetrics) {
            $patternId = if ($metric.PatternID) { [string]$metric.PatternID } else { "UNKNOWN" }
            if (-not $patternStats[$patternId]) {
                $patternStats[$patternId] = @{
                    PatternID = $patternId
                    UsageCount = [int]0
                    SuccessCount = [int]0
                    TotalExecutionTime = [int]0
                    AverageConfidence = [double]0.0
                    ConfidenceSum = [double]0.0
                }
            }
            
            # Safely increment counters using intermediate variables
            $statsData = $patternStats[$patternId]
            
            # Increment usage count
            $currentUsage = if ($statsData['UsageCount'] -ne $null -and $statsData['UsageCount'] -isnot [System.Array]) { 
                [int]$statsData['UsageCount'] 
            } else { 0 }
            $statsData['UsageCount'] = $currentUsage + 1
            
            # Increment success count if applicable
            if ($metric.Success -eq $true) {
                $currentSuccess = if ($statsData['SuccessCount'] -ne $null -and $statsData['SuccessCount'] -isnot [System.Array]) { 
                    [int]$statsData['SuccessCount'] 
                } else { 0 }
                $statsData['SuccessCount'] = $currentSuccess + 1
            }
            
            # Add execution time
            $execTime = if ($metric.ExecutionTimeMs -and $metric.ExecutionTimeMs -isnot [System.Array]) { 
                [int]$metric.ExecutionTimeMs 
            } else { 0 }
            $currentExecTime = if ($statsData['TotalExecutionTime'] -ne $null -and $statsData['TotalExecutionTime'] -isnot [System.Array]) { 
                [int]$statsData['TotalExecutionTime'] 
            } else { 0 }
            $statsData['TotalExecutionTime'] = $currentExecTime + $execTime
            
            # Add confidence score
            $confScore = if ($metric.ConfidenceScore -and $metric.ConfidenceScore -isnot [System.Array]) { 
                [double]$metric.ConfidenceScore 
            } else { 0.0 }
            $currentConfSum = if ($statsData['ConfidenceSum'] -ne $null -and $statsData['ConfidenceSum'] -isnot [System.Array]) { 
                [double]$statsData['ConfidenceSum'] 
            } else { 0.0 }
            $statsData['ConfidenceSum'] = $currentConfSum + $confScore
            
            # Write back to main hashtable
            $patternStats[$patternId] = $statsData
        }
        
        # Calculate derived metrics
        foreach ($patternId in $patternStats.Keys) {
            $stats = $patternStats[$patternId]
            $stats.SuccessRate = if ($stats.UsageCount -gt 0) { [math]::Round($stats.SuccessCount / $stats.UsageCount, 4) } else { 0 }
            $stats.AverageExecutionTime = if ($stats.UsageCount -gt 0) { [math]::Round($stats.TotalExecutionTime / $stats.UsageCount, 2) } else { 0 }
            $stats.AverageConfidence = if ($stats.UsageCount -gt 0) { [math]::Round($stats.ConfidenceSum / $stats.UsageCount, 4) } else { 0 }
            $stats.Effectiveness = [math]::Round($stats.SuccessRate * $stats.AverageConfidence, 4)
        }
        
        # Create top lists
        $topByUsage = $patternStats.Values | Sort-Object UsageCount -Descending | Select-Object -First $TopCount
        $topBySuccessRate = $patternStats.Values | Where-Object { $_.UsageCount -ge 3 } | Sort-Object SuccessRate -Descending | Select-Object -First $TopCount
        $topByEffectiveness = $patternStats.Values | Where-Object { $_.UsageCount -ge 3 } | Sort-Object Effectiveness -Descending | Select-Object -First $TopCount
        
        Write-Verbose "Pattern usage analytics completed: $($patternStats.Count) patterns analyzed"
        
        return @{
            TopPatternsByUsage = $topByUsage
            TopPatternsBySuccessRate = $topBySuccessRate
            TopPatternsByEffectiveness = $topByEffectiveness
            Summary = "Analyzed $($patternStats.Count) patterns with $($allMetrics.Count) total applications"
            TotalPatterns = $patternStats.Count
            TotalApplications = $allMetrics.Count
        }
        
    } catch {
        Write-Error "Failed to analyze pattern usage: $_"
        return $null
    }
}

#endregion

#region Configuration

function Set-LearningConfig {
    <#
    .SYNOPSIS
    Configures the learning system settings
    #>
    [CmdletBinding()]
    param(
        [int]$MaxPatternAge,
        [double]$MinConfidence,
        [switch]$EnableAutoFix
    )
    
    if ($PSBoundParameters.ContainsKey('MaxPatternAge')) {
        $script:LearningConfig.MaxPatternAge = $MaxPatternAge
    }
    
    if ($PSBoundParameters.ContainsKey('MinConfidence')) {
        $script:LearningConfig.MinConfidence = $MinConfidence
    }
    
    if ($EnableAutoFix) {
        $script:LearningConfig.EnableAutoFix = $true
        Write-Warning "Auto-fix enabled - system will attempt automatic repairs"
    }
    
    Write-Host "Learning configuration updated" -ForegroundColor Green
    return $script:LearningConfig
}

function Get-LearningConfig {
    <#
    .SYNOPSIS
    Gets the current learning system configuration
    #>
    [CmdletBinding()]
    param()
    
    return $script:LearningConfig
}

#endregion

#region Module Exports

Export-ModuleMember -Function @(
    # Database
    'Initialize-LearningDatabase',
    
    # String Similarity
    'Get-StringSimilarity',
    'Get-LevenshteinDistance',
    'Get-ErrorSignature',
    'Find-SimilarPatterns',
    'Find-SimilarPatternsSQLite',
    'Find-SimilarPatternsJSON',
    'Find-SimilarPatternsMemory',
    'Calculate-ConfidenceScore',
    
    # AST Analysis
    'Get-CodeAST',
    'Find-CodePattern',
    
    # Pattern Recognition
    'Add-ErrorPattern',
    'Add-ErrorPatternSQLite',
    'Get-SuggestedFixes',
    
    # Self-Patching
    'Apply-AutoFix',
    
    # Success Tracking
    'Update-PatternSuccess',
    'Get-LearningReport',
    
    # Week 2: Metrics Collection System
    'Record-PatternApplicationMetric',
    'Save-MetricToJSON',
    'Get-LearningMetrics',
    'Get-MetricsFromJSON',
    'Measure-ExecutionTime',
    'Get-PatternUsageAnalytics',
    
    # Configuration
    'Set-LearningConfig',
    'Get-LearningConfig'
)

#endregion

# Initialize storage backend on module load
try {
    # Load JSON storage module
    . (Join-Path $PSScriptRoot "Storage-JSON.ps1")
    
    # Try SQLite first, fallback to JSON
    try {
        $sqliteResult = Initialize-LearningDatabase
        if ($sqliteResult.Success) {
            $script:LearningConfig.StorageBackend = "SQLite"
            Write-Verbose "SQLite backend initialized successfully"
        } else {
            throw "SQLite initialization failed"
        }
    } catch {
        Write-Verbose "SQLite unavailable, using JSON backend: $_"
        $jsonResult = Initialize-JSONStorage -StoragePath $script:LearningConfig.StoragePath
        if ($jsonResult.Success) {
            $script:LearningConfig.StorageBackend = "JSON"
            Write-Verbose "JSON backend initialized successfully"
        } else {
            throw "Both SQLite and JSON initialization failed"
        }
    }
    
    Write-Host "Storage backend: $($script:LearningConfig.StorageBackend)" -ForegroundColor Green
    
} catch {
    Write-Warning "Storage initialization failed: $_. String similarity functions will work without persistence."
    $script:LearningConfig.StorageBackend = "None"
}

Write-Host "Unity-Claude-Learning module loaded - Phase 3 Self-Improvement System" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUFend0wqM2vSRBHFGiAoAjm9L
# IvWgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU8UO5nKnnWef7hnnrZauxvsls/S4wDQYJKoZIhvcNAQEBBQAEggEAq6HW
# 5pliJ4BnDcKQ4q0IIlIFdbwC+3ciH+8+jsG/LQnJwzc1OlrBe805M2X3D4k5xakf
# emJHfAjGb4UWoQDhhBVCVKziv7BujnPaL+X/LiobEevQ+zHa3HiNCKAjWjRt0FNe
# Hif97lcFG4e/I0WKPTQeEtvq1EHvVZ+45tNkJsrm0q9ULXfAyDXHYhR5NS53Tg+L
# 60SvMINSeDv9vz7ey3IZvKuMK8hFivi8oNeGYUYoz8zid/kjvih6CbKzDLiH2C4K
# wDAT9eF6FcR6cR9FI4ixNT3w5EiuNm1XxgAUmpivk5wnFarWuSlZJZXtQIPIT31V
# PiJSyrxFG2/dqwlqUg==
# SIG # End signature block
