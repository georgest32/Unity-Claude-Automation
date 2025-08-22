# Unity-Claude-Errors.psm1
# Error handling and pattern recognition module

# Import required modules
Import-Module Unity-Claude-Core -ErrorAction Stop
Import-Module PSSQLite -ErrorAction SilentlyContinue

# Module-scoped variables
$script:ErrorDatabase = $null
$script:DatabasePath = ''

#region Database Management

function Initialize-ErrorDatabase {
    [CmdletBinding()]
    param(
        [string]$DatabasePath = (Join-Path $env:LOCALAPPDATA 'Unity-Claude\errors.db'),
        [switch]$Force
    )
    
    $script:DatabasePath = $DatabasePath
    
    # Create directory if needed
    $dbDir = Split-Path $DatabasePath -Parent
    New-Item -ItemType Directory -Force -Path $dbDir | Out-Null
    
    Write-Log "Initializing error database at: $DatabasePath" -Level 'INFO'
    
    # Create tables if they don't exist
    $createTables = @"
CREATE TABLE IF NOT EXISTS error_patterns (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    error_code TEXT NOT NULL,
    error_type TEXT NOT NULL,
    pattern TEXT NOT NULL,
    file_path TEXT,
    line_number INTEGER,
    description TEXT,
    first_seen DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_seen DATETIME DEFAULT CURRENT_TIMESTAMP,
    occurrence_count INTEGER DEFAULT 1,
    UNIQUE(error_code, pattern)
);

CREATE TABLE IF NOT EXISTS error_solutions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pattern_id INTEGER,
    solution TEXT NOT NULL,
    success_count INTEGER DEFAULT 0,
    failure_count INTEGER DEFAULT 0,
    average_fix_time INTEGER,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_used DATETIME,
    FOREIGN KEY(pattern_id) REFERENCES error_patterns(id)
);

CREATE TABLE IF NOT EXISTS error_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pattern_id INTEGER,
    solution_id INTEGER,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    success BOOLEAN,
    fix_duration INTEGER,
    unity_version TEXT,
    project_name TEXT,
    additional_context TEXT,
    FOREIGN KEY(pattern_id) REFERENCES error_patterns(id),
    FOREIGN KEY(solution_id) REFERENCES error_solutions(id)
);

CREATE INDEX IF NOT EXISTS idx_error_code ON error_patterns(error_code);
CREATE INDEX IF NOT EXISTS idx_pattern ON error_patterns(pattern);
CREATE INDEX IF NOT EXISTS idx_success_rate ON error_solutions(success_count, failure_count);
"@
    
    try {
        if (Get-Module -Name PSSQLite) {
            Invoke-SqliteQuery -DataSource $DatabasePath -Query $createTables
            Write-Log "Error database initialized successfully" -Level 'OK'
            $script:ErrorDatabase = $DatabasePath
            return $true
        } else {
            Write-Log "PSSQLite module not available, using in-memory storage" -Level 'WARN'
            $script:ErrorDatabase = @{
                Patterns = @{}
                Solutions = @{}
                History = @()
            }
            return $true
        }
    } catch {
        Write-Log "Failed to initialize database: $($_.Exception.Message)" -Level 'ERROR'
        return $false
    }
}

#endregion

#region Error Pattern Management

function Add-ErrorPattern {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ErrorCode,
        
        [Parameter(Mandatory)]
        [string]$Pattern,
        
        [string]$ErrorType = 'Compilation',
        [string]$FilePath,
        [int]$LineNumber,
        [string]$Description
    )
    
    if ($script:ErrorDatabase -is [string]) {
        # SQLite database
        $query = @"
INSERT INTO error_patterns (error_code, error_type, pattern, file_path, line_number, description)
VALUES (@ErrorCode, @ErrorType, @Pattern, @FilePath, @LineNumber, @Description)
ON CONFLICT(error_code, pattern) DO UPDATE SET
    last_seen = CURRENT_TIMESTAMP,
    occurrence_count = occurrence_count + 1
"@
        
        try {
            Invoke-SqliteQuery -DataSource $script:ErrorDatabase -Query $query -SqlParameters @{
                ErrorCode = $ErrorCode
                ErrorType = $ErrorType
                Pattern = $Pattern
                FilePath = $FilePath
                LineNumber = $LineNumber
                Description = $Description
            }
            
            Write-Log "Added error pattern: $ErrorCode" -Level 'DEBUG'
            return $true
        } catch {
            Write-Log "Failed to add error pattern: $($_.Exception.Message)" -Level 'ERROR'
            return $false
        }
    } else {
        # In-memory storage
        $key = "$ErrorCode|$Pattern"
        if (-not $script:ErrorDatabase.Patterns.ContainsKey($key)) {
            $script:ErrorDatabase.Patterns[$key] = @{
                ErrorCode = $ErrorCode
                ErrorType = $ErrorType
                Pattern = $Pattern
                FilePath = $FilePath
                LineNumber = $LineNumber
                Description = $Description
                FirstSeen = Get-Date
                LastSeen = Get-Date
                OccurrenceCount = 1
            }
        } else {
            $script:ErrorDatabase.Patterns[$key].LastSeen = Get-Date
            $script:ErrorDatabase.Patterns[$key].OccurrenceCount++
        }
        return $true
    }
}

function Get-ErrorPattern {
    [CmdletBinding()]
    param(
        [string]$ErrorCode,
        [string]$Pattern
    )
    
    if ($script:ErrorDatabase -is [string]) {
        $query = "SELECT * FROM error_patterns WHERE 1=1"
        $parameters = @{}
        
        if ($ErrorCode) {
            $query += " AND error_code = @ErrorCode"
            $parameters.ErrorCode = $ErrorCode
        }
        
        if ($Pattern) {
            $query += " AND pattern LIKE @Pattern"
            $parameters.Pattern = "%$Pattern%"
        }
        
        $query += " ORDER BY occurrence_count DESC"
        
        return Invoke-SqliteQuery -DataSource $script:ErrorDatabase -Query $query -SqlParameters $parameters
    } else {
        # In-memory storage
        $results = @()
        foreach ($key in $script:ErrorDatabase.Patterns.Keys) {
            $pattern = $script:ErrorDatabase.Patterns[$key]
            $match = $true
            
            if ($ErrorCode -and $pattern.ErrorCode -ne $ErrorCode) {
                $match = $false
            }
            
            if ($Pattern -and $pattern.Pattern -notlike "*$Pattern*") {
                $match = $false
            }
            
            if ($match) {
                $results += $pattern
            }
        }
        
        return $results | Sort-Object -Property OccurrenceCount -Descending
    }
}

function Find-SimilarErrors {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ErrorMessage,
        
        [int]$MaxResults = 5
    )
    
    # Extract key components from error message
    $errorCode = if ($ErrorMessage -match '(CS\d{4})') { $matches[1] } else { '' }
    $keywords = @()
    
    # Extract type/namespace names
    if ($ErrorMessage -match "type or namespace name '([^']+)'") {
        $keywords += $matches[1]
    }
    
    # Extract member names
    if ($ErrorMessage -match "does not contain a definition for '([^']+)'") {
        $keywords += $matches[1]
    }
    
    # Search for similar patterns
    $patterns = Get-ErrorPattern -ErrorCode $errorCode
    
    # Score patterns by similarity
    $scored = foreach ($pattern in $patterns) {
        $score = 0
        
        # Exact error code match
        if ($pattern.ErrorCode -eq $errorCode) {
            $score += 10
        }
        
        # Keyword matches
        foreach ($keyword in $keywords) {
            if ($pattern.Pattern -like "*$keyword*" -or $pattern.Description -like "*$keyword*") {
                $score += 5
            }
        }
        
        if ($score -gt 0) {
            [PSCustomObject]@{
                Pattern = $pattern
                Score = $score
            }
        }
    }
    
    return $scored | Sort-Object -Property Score -Descending | Select-Object -First $MaxResults
}

#endregion

#region Solution Management

function Update-ErrorSolution {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$PatternId,
        
        [Parameter(Mandatory)]
        [string]$Solution,
        
        [Parameter(Mandatory)]
        [bool]$Success,
        
        [int]$FixDuration
    )
    
    if ($script:ErrorDatabase -is [string]) {
        # First, check if solution exists
        $existingQuery = @"
SELECT id FROM error_solutions 
WHERE pattern_id = @PatternId AND solution = @Solution
"@
        
        $existing = Invoke-SqliteQuery -DataSource $script:ErrorDatabase `
                                       -Query $existingQuery `
                                       -SqlParameters @{PatternId = $PatternId; Solution = $Solution}
        
        if ($existing) {
            # Update existing solution
            $updateQuery = @"
UPDATE error_solutions 
SET $(if ($Success) { 'success_count = success_count + 1' } else { 'failure_count = failure_count + 1' }),
    last_used = CURRENT_TIMESTAMP,
    average_fix_time = CASE 
        WHEN average_fix_time IS NULL THEN @FixDuration
        ELSE (average_fix_time + @FixDuration) / 2
    END
WHERE id = @Id
"@
            
            Invoke-SqliteQuery -DataSource $script:ErrorDatabase `
                              -Query $updateQuery `
                              -SqlParameters @{Id = $existing.id; FixDuration = $FixDuration}
            
            $solutionId = $existing.id
        } else {
            # Insert new solution
            $insertQuery = @"
INSERT INTO error_solutions (pattern_id, solution, success_count, failure_count, average_fix_time, last_used)
VALUES (@PatternId, @Solution, @SuccessCount, @FailureCount, @FixDuration, CURRENT_TIMESTAMP)
"@
            
            Invoke-SqliteQuery -DataSource $script:ErrorDatabase `
                              -Query $insertQuery `
                              -SqlParameters @{
                                  PatternId = $PatternId
                                  Solution = $Solution
                                  SuccessCount = if ($Success) { 1 } else { 0 }
                                  FailureCount = if ($Success) { 0 } else { 1 }
                                  FixDuration = $FixDuration
                              }
            
            $solutionId = (Invoke-SqliteQuery -DataSource $script:ErrorDatabase `
                                              -Query "SELECT last_insert_rowid() as id").id
        }
        
        # Add to history
        $historyQuery = @"
INSERT INTO error_history (pattern_id, solution_id, success, fix_duration, unity_version, project_name)
VALUES (@PatternId, @SolutionId, @Success, @FixDuration, @UnityVersion, @ProjectName)
"@
        
        Invoke-SqliteQuery -DataSource $script:ErrorDatabase `
                          -Query $historyQuery `
                          -SqlParameters @{
                              PatternId = $PatternId
                              SolutionId = $solutionId
                              Success = $Success
                              FixDuration = $FixDuration
                              UnityVersion = '2021.1.14f1'
                              ProjectName = 'Sound-and-Shoal'
                          }
        
        Write-Log "Updated solution for pattern $PatternId (Success: $Success)" -Level 'DEBUG'
        return $true
        
    } else {
        # In-memory storage - simplified version
        $key = "$PatternId|$Solution"
        if (-not $script:ErrorDatabase.Solutions.ContainsKey($key)) {
            $script:ErrorDatabase.Solutions[$key] = @{
                PatternId = $PatternId
                Solution = $Solution
                SuccessCount = 0
                FailureCount = 0
                AverageFixTime = $FixDuration
            }
        }
        
        if ($Success) {
            $script:ErrorDatabase.Solutions[$key].SuccessCount++
        } else {
            $script:ErrorDatabase.Solutions[$key].FailureCount++
        }
        
        # Update average fix time
        $current = $script:ErrorDatabase.Solutions[$key].AverageFixTime
        if ($current -and $FixDuration) {
            $script:ErrorDatabase.Solutions[$key].AverageFixTime = ($current + $FixDuration) / 2
        }
        
        # Add to history
        $script:ErrorDatabase.History += @{
            PatternId = $PatternId
            Solution = $Solution
            Success = $Success
            FixDuration = $FixDuration
            Timestamp = Get-Date
        }
        
        return $true
    }
}

#endregion

#region Error Analysis

function Parse-UnityError {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ErrorLine
    )
    
    $parsed = @{
        RawError = $ErrorLine
        ErrorCode = ''
        FilePath = ''
        LineNumber = 0
        ColumnNumber = 0
        Message = ''
        Type = 'Unknown'
    }
    
    # CS errors (C# compilation errors)
    if ($ErrorLine -match '(.+?)\((\d+),(\d+)\):\s+error\s+(CS\d{4}):\s+(.+)') {
        $parsed.FilePath = $matches[1]
        $parsed.LineNumber = [int]$matches[2]
        $parsed.ColumnNumber = [int]$matches[3]
        $parsed.ErrorCode = $matches[4]
        $parsed.Message = $matches[5]
        $parsed.Type = 'Compilation'
    }
    # Exception patterns
    elseif ($ErrorLine -match '(\w+Exception):\s+(.+)') {
        $parsed.ErrorCode = $matches[1]
        $parsed.Message = $matches[2]
        $parsed.Type = 'Runtime'
    }
    # Unity-specific errors
    elseif ($ErrorLine -match 'error:\s+(.+)') {
        $parsed.Message = $matches[1]
        $parsed.Type = 'Unity'
    }
    
    return [PSCustomObject]$parsed
}

function Get-ErrorSeverity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ErrorCode
    )
    
    # Define severity levels for different error types
    $severityMap = @{
        # Critical compilation errors
        'CS0246' = 'Critical'  # Type or namespace not found
        'CS0234' = 'Critical'  # Type or namespace does not exist
        'CS0103' = 'High'      # Name does not exist in current context
        'CS0117' = 'High'      # Type does not contain definition
        'CS1061' = 'High'      # Type does not contain member
        
        # Syntax errors
        'CS1002' = 'Medium'    # ; expected
        'CS1003' = 'Medium'    # Syntax error
        'CS1519' = 'Medium'    # Invalid token
        
        # Warnings that might be errors
        'CS0168' = 'Low'       # Variable declared but never used
        'CS0219' = 'Low'       # Variable assigned but never used
        
        # Runtime exceptions
        'NullReferenceException' = 'Critical'
        'IndexOutOfRangeException' = 'High'
        'ArgumentException' = 'Medium'
        'InvalidOperationException' = 'Medium'
        'NotImplementedException' = 'High'
    }
    
    if ($severityMap.ContainsKey($ErrorCode)) {
        return $severityMap[$ErrorCode]
    }
    
    # Default severity based on error code range
    if ($ErrorCode -match '^CS0[0-2]') {
        return 'Critical'
    } elseif ($ErrorCode -match '^CS[0-4]') {
        return 'High'
    } elseif ($ErrorCode -match '^CS[5-7]') {
        return 'Medium'
    } else {
        return 'Low'
    }
}

#endregion

#region Reporting

function Get-ErrorStatistics {
    [CmdletBinding()]
    param(
        [datetime]$StartDate,
        [datetime]$EndDate = (Get-Date)
    )
    
    if ($script:ErrorDatabase -is [string]) {
        $stats = @{}
        
        # Most common errors
        $commonQuery = @"
SELECT error_code, error_type, COUNT(*) as count, SUM(occurrence_count) as total_occurrences
FROM error_patterns
WHERE last_seen BETWEEN @StartDate AND @EndDate
GROUP BY error_code, error_type
ORDER BY total_occurrences DESC
LIMIT 10
"@
        
        $stats.MostCommon = Invoke-SqliteQuery -DataSource $script:ErrorDatabase `
                                               -Query $commonQuery `
                                               -SqlParameters @{
                                                   StartDate = $StartDate
                                                   EndDate = $EndDate
                                               }
        
        # Success rate by solution
        $successQuery = @"
SELECT s.solution, s.success_count, s.failure_count,
       CAST(s.success_count AS REAL) / (s.success_count + s.failure_count) * 100 as success_rate,
       s.average_fix_time
FROM error_solutions s
WHERE s.last_used BETWEEN @StartDate AND @EndDate
  AND (s.success_count + s.failure_count) > 0
ORDER BY success_rate DESC
LIMIT 10
"@
        
        $stats.BestSolutions = Invoke-SqliteQuery -DataSource $script:ErrorDatabase `
                                                  -Query $successQuery `
                                                  -SqlParameters @{
                                                      StartDate = $StartDate
                                                      EndDate = $EndDate
                                                  }
        
        # Trend over time
        $trendQuery = @"
SELECT DATE(timestamp) as date, COUNT(*) as error_count, 
       SUM(CASE WHEN success = 1 THEN 1 ELSE 0 END) as success_count
FROM error_history
WHERE timestamp BETWEEN @StartDate AND @EndDate
GROUP BY DATE(timestamp)
ORDER BY date
"@
        
        $stats.Trend = Invoke-SqliteQuery -DataSource $script:ErrorDatabase `
                                          -Query $trendQuery `
                                          -SqlParameters @{
                                              StartDate = $StartDate
                                              EndDate = $EndDate
                                          }
        
        return $stats
    } else {
        # In-memory statistics
        $stats = @{
            MostCommon = $script:ErrorDatabase.Patterns.Values | 
                         Group-Object -Property ErrorCode | 
                         Sort-Object -Property Count -Descending |
                         Select-Object -First 10
            
            BestSolutions = $script:ErrorDatabase.Solutions.Values |
                           Where-Object { ($_.SuccessCount + $_.FailureCount) -gt 0 } |
                           ForEach-Object {
                               $total = $_.SuccessCount + $_.FailureCount
                               [PSCustomObject]@{
                                   Solution = $_.Solution
                                   SuccessRate = ($_.SuccessCount / $total) * 100
                                   TotalUses = $total
                               }
                           } |
                           Sort-Object -Property SuccessRate -Descending |
                           Select-Object -First 10
            
            TotalErrors = $script:ErrorDatabase.History.Count
        }
        
        return $stats
    }
}

function Export-ErrorReport {
    [CmdletBinding()]
    param(
        [string]$OutputPath,
        [datetime]$StartDate = (Get-Date).AddDays(-7),
        [datetime]$EndDate = (Get-Date)
    )
    
    if (-not $OutputPath) {
        $OutputPath = Join-Path $env:TEMP "Unity-Claude-ErrorReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
    }
    
    Write-Log "Generating error report: $OutputPath" -Level 'INFO'
    
    $stats = Get-ErrorStatistics -StartDate $StartDate -EndDate $EndDate
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Unity-Claude Error Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #2c3e50; }
        h2 { color: #34495e; border-bottom: 2px solid #ecf0f1; padding-bottom: 5px; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th { background-color: #3498db; color: white; text-align: left; padding: 10px; }
        td { border: 1px solid #ddd; padding: 8px; }
        tr:nth-child(even) { background-color: #f2f2f2; }
        .success { color: #27ae60; font-weight: bold; }
        .failure { color: #e74c3c; font-weight: bold; }
        .warning { color: #f39c12; font-weight: bold; }
    </style>
</head>
<body>
    <h1>Unity-Claude Error Analysis Report</h1>
    <p>Report Period: $($StartDate.ToString('yyyy-MM-dd')) to $($EndDate.ToString('yyyy-MM-dd'))</p>
    
    <h2>Most Common Errors</h2>
    <table>
        <tr>
            <th>Error Code</th>
            <th>Type</th>
            <th>Occurrences</th>
        </tr>
"@
    
    foreach ($error in $stats.MostCommon) {
        $html += @"
        <tr>
            <td>$($error.error_code)</td>
            <td>$($error.error_type)</td>
            <td>$($error.total_occurrences)</td>
        </tr>
"@
    }
    
    $html += @"
    </table>
    
    <h2>Most Effective Solutions</h2>
    <table>
        <tr>
            <th>Solution</th>
            <th>Success Rate</th>
            <th>Average Fix Time</th>
        </tr>
"@
    
    foreach ($solution in $stats.BestSolutions) {
        $rateClass = if ($solution.success_rate -ge 80) { 'success' } `
                     elseif ($solution.success_rate -ge 50) { 'warning' } `
                     else { 'failure' }
        
        $html += @"
        <tr>
            <td>$($solution.solution.Substring(0, [Math]::Min(100, $solution.solution.Length)))...</td>
            <td class="$rateClass">$([Math]::Round($solution.success_rate, 1))%</td>
            <td>$($solution.average_fix_time)s</td>
        </tr>
"@
    }
    
    $html += @"
    </table>
    
    <p><em>Generated on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</em></p>
</body>
</html>
"@
    
    Set-Content -Path $OutputPath -Value $html
    Write-Log "Error report generated: $OutputPath" -Level 'OK'
    
    return $OutputPath
}

#endregion

# Export module members
Export-ModuleMember -Function @(
    'Initialize-ErrorDatabase',
    'Add-ErrorPattern',
    'Get-ErrorPattern',
    'Find-SimilarErrors',
    'Update-ErrorSolution',
    'Get-ErrorStatistics',
    'Export-ErrorReport',
    'Parse-UnityError',
    'Get-ErrorSeverity'
)
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUKifVL2EBHiv8dSMK/NAaK0Ro
# vv2gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUEXnzxs6Xge2lKh32g3KBTT5pvsswDQYJKoZIhvcNAQEBBQAEggEASkKb
# bNWVVI4H7csDmDAqW7JKYCUiKzUZd3CxCY7yEyEAvunv4XPlKcYYCzysJo7+wGna
# Ij8NgaGRvCwSKITSWPIL1tysmOQaV/ZgdOPdPfZjXKSSbdX/NfVLhO5WoEeCisTQ
# UNUtGsX/2tWwkuOYmlIv7p1uEZPvtkxbJExNdljK8ELSX8fgv85Kgi0b5b+4mJQF
# CvWnmpJf3I/mpLAtYwC56hRVSW4fFS1Tegep+kzZAACXr4KIFIeVXOhzWo0e+hQX
# uuSdH29zuJ4jraYCN6yLCMMwzuS+mOj0tut8hpwS3YsSZanF7Ai647bLJ0fA1Qt6
# 3NcTQkJ4U/j6sA7g1A==
# SIG # End signature block
