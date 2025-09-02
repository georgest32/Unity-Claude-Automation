# Unity-Claude-Learning Database Management Component
# Database setup and operations for learning system
# Part of refactored Learning module

$ErrorActionPreference = "Stop"

# Import core component
$CorePath = Join-Path $PSScriptRoot "LearningCore.psm1"
Import-Module $CorePath -Force

function Initialize-LearningDatabase {
    <#
    .SYNOPSIS
    Initializes the learning database for pattern storage
    
    .DESCRIPTION
    Creates SQLite database with tables for error patterns, fixes, and metrics
    #>
    [CmdletBinding()]
    param(
        [string]$DatabasePath = (Get-LearningConfig).DatabasePath
    )
    
    Write-LearningLog -Message "Initializing learning database at: $DatabasePath" -Level "VERBOSE"
    
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
        
        Write-LearningLog -Message "Learning database initialized successfully" -Level "VERBOSE"
        return @{
            Success = $true
            DatabasePath = $DatabasePath
        }
        
    } catch {
        Write-LearningLog -Message "Failed to initialize learning database: $_" -Level "ERROR"
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

# Export functions
Export-ModuleMember -Function @(
    'Initialize-LearningDatabase'
)

Write-LearningLog -Message "DatabaseManagement component loaded successfully" -Level "DEBUG"
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCaD851WYyxLe+H
# HtKfEtKgnkn5IuXAr52SqDRvwvG3+qCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIKfkgxwKRGXPnGKz2QRptnj5
# wMbjAx/538TrdGP/7pjuMA0GCSqGSIb3DQEBAQUABIIBAKbJYnABOiSD5sOtH+WG
# ZVAkpf+Rv+BlOjfBdWqohPaWtLYJAoX39Z9UcEpjKSrZoUMf4n7ZwEMvapZVGUUR
# UDVmQCt6phYRkNOY3ThUM3DwovjgfOgGSw8k+i5x6N9gzsiMZ0kXVN9UB1jjcbLY
# A4rvCNesRZYBWp5OgIxTu3iqc43KlViO1hh3QbZQaEVeZxf8VjTpwAOFgQTzZ22h
# EfhJmRR9LTJr8ETPB/6lGTpPtN6hCV/rTvuDa/L5Cdu8a77dnxDXlR5HldQnCJda
# bKPAhlpVBDUclZeVrlEB0rNj1l8/QvVSAgVeCjOBSEuVQzT886mYtyoCnXXzG+Zo
# g2g=
# SIG # End signature block
