# Unity-Claude-Learning-Simple.psm1
# Simplified learning module using JSON storage instead of SQLite
# Phase 3 Implementation - Pattern Recognition, Self-Patching, Learning System

#region Module Configuration

$script:LearningConfig = @{
    DataPath = Join-Path $PSScriptRoot "LearningData"
    PatternsFile = Join-Path $PSScriptRoot "LearningData\patterns.json"
    MetricsFile = Join-Path $PSScriptRoot "LearningData\metrics.json"
    LogFile = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "unity_claude_automation.log"
    MaxPatternAge = 30
    MinConfidence = 0.7
    EnableAutoFix = $false
    # Fuzzy Matching Settings
    EnableFuzzyMatching = $true
    MinSimilarity = 0.85  # 85% minimum similarity for fuzzy matches
    MaxCacheSize = 1000   # Maximum entries in Levenshtein cache
    # Logging Settings
    EnableLogging = $true
    LogLevel = "DEBUG"  # DEBUG, INFO, WARN, ERROR
}

$script:Patterns = @{}
$script:Metrics = @{
    TotalAttempts = 0
    SuccessfulFixes = 0
    FailedFixes = 0
    PatternsLearned = 0
    LastUpdated = Get-Date
}

#endregion

#region Logging Functions

function Write-LearningLog {
    <#
    .SYNOPSIS
    Writes to the rolling log file with structured format
    .PARAMETER Message
    The message to log
    .PARAMETER Level
    Log level: DEBUG, INFO, WARN, ERROR
    .PARAMETER Component
    Component or function name for tracking
    #>
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Component = "General"
    )
    
    if (-not $script:LearningConfig.EnableLogging) {
        return
    }
    
    # Check log level
    $levels = @{
        "DEBUG" = 0
        "INFO" = 1
        "WARN" = 2
        "ERROR" = 3
    }
    
    $currentLevel = $levels[$script:LearningConfig.LogLevel]
    $messageLevel = $levels[$Level]
    
    if ($messageLevel -lt $currentLevel) {
        return
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logEntry = "[$timestamp] [$Level] [Learning-$Component] $Message"
    
    # Write to log file
    try {
        $logEntry | Out-File $script:LearningConfig.LogFile -Append -Encoding UTF8
    } catch {
        # If logging fails, don't crash the module
        Write-Verbose "Failed to write to log: $_"
    }
    
    # Also write to verbose stream for debugging
    if ($Level -eq "DEBUG") {
        Write-Verbose $Message
    }
}

#endregion

#region Helper Functions

function ConvertFrom-JsonToHashtable {
    <#
    .SYNOPSIS
    Recursively converts PSCustomObject from JSON to nested hashtables
    .DESCRIPTION
    PowerShell 5.1 doesn't have -AsHashtable parameter for ConvertFrom-Json.
    This function performs deep conversion of PSCustomObjects to hashtables.
    .PARAMETER InputObject
    The PSCustomObject to convert (typically from ConvertFrom-Json)
    #>
    param(
        [Parameter(ValueFromPipeline)]
        $InputObject
    )
    
    if ($null -eq $InputObject) {
        return $null
    }
    
    if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
        $collection = @()
        foreach ($item in $InputObject) {
            $collection += ConvertFrom-JsonToHashtable $item
        }
        return $collection
    } elseif ($InputObject -is [PSCustomObject]) {
        $hash = @{}
        foreach ($property in $InputObject.PSObject.Properties) {
            $hash[$property.Name] = ConvertFrom-JsonToHashtable $property.Value
        }
        return $hash
    } else {
        return $InputObject
    }
}

#endregion

#region Storage Functions

function Initialize-LearningStorage {
    <#
    .SYNOPSIS
    Initializes the JSON-based learning storage
    #>
    [CmdletBinding()]
    param()
    
    Write-LearningLog -Message "Initializing learning storage" -Level "INFO" -Component "Initialize-LearningStorage"
    
    # Create data directory
    if (-not (Test-Path $script:LearningConfig.DataPath)) {
        New-Item -Path $script:LearningConfig.DataPath -ItemType Directory -Force | Out-Null
        Write-LearningLog -Message "Created data directory: $($script:LearningConfig.DataPath)" -Level "DEBUG" -Component "Initialize-LearningStorage"
    }
    
    # Load or create patterns file
    if (Test-Path $script:LearningConfig.PatternsFile) {
        try {
            # PowerShell 5.1 compatibility: ConvertFrom-Json doesn't have -AsHashtable
            $jsonContent = Get-Content $script:LearningConfig.PatternsFile -Raw | ConvertFrom-Json
            
            # Use deep conversion to properly handle nested objects
            $converted = ConvertFrom-JsonToHashtable $jsonContent
            
            if ($converted -and $converted -is [hashtable]) {
                $script:Patterns = $converted
            } else {
                $script:Patterns = @{}
            }
            
            Write-LearningLog -Message "Loaded $($script:Patterns.Count) patterns from storage" -Level "INFO" -Component "Initialize-LearningStorage"
            Write-Verbose "Loaded $($script:Patterns.Count) patterns from storage"
        } catch {
            Write-Warning "Could not load patterns file, starting fresh: $_"
            $script:Patterns = @{}
        }
    } else {
        $script:Patterns = @{}
        $null = Save-Patterns
    }
    
    # Load or create metrics file
    if (Test-Path $script:LearningConfig.MetricsFile) {
        try {
            # PowerShell 5.1 compatibility: ConvertFrom-Json doesn't have -AsHashtable
            $jsonContent = Get-Content $script:LearningConfig.MetricsFile -Raw | ConvertFrom-Json
            
            # Use deep conversion to properly handle nested objects
            $converted = ConvertFrom-JsonToHashtable $jsonContent
            
            if ($converted -and $converted -is [hashtable]) {
                $script:Metrics = $converted
            } else {
                $script:Metrics = @{
                    TotalAttempts = 0
                    SuccessfulFixes = 0
                    FailedFixes = 0
                    PatternsLearned = 0
                    LastUpdated = Get-Date
                }
            }
            
            Write-Verbose "Loaded metrics from storage"
        } catch {
            Write-Warning "Could not load metrics file, starting fresh: $_"
            $script:Metrics = @{
                TotalAttempts = 0
                SuccessfulFixes = 0
                FailedFixes = 0
                PatternsLearned = 0
                LastUpdated = Get-Date
            }
        }
    } else {
        $null = Save-Metrics
    }
    
    return @{
        Success = $true
        PatternsLoaded = $script:Patterns.Count
        DataPath = $script:LearningConfig.DataPath
    }
}

function Save-Patterns {
    <#
    .SYNOPSIS
    Saves patterns to JSON file
    #>
    [CmdletBinding()]
    param()
    
    try {
        # Use -InputObject to preserve single-element arrays
        ConvertTo-Json -InputObject $script:Patterns -Depth 10 | Set-Content $script:LearningConfig.PatternsFile
        Write-Verbose "Saved $($script:Patterns.Count) patterns"
        return $true
    } catch {
        Write-Error "Failed to save patterns: $_"
        return $false
    }
}

function Save-Metrics {
    <#
    .SYNOPSIS
    Saves metrics to JSON file
    #>
    [CmdletBinding()]
    param()
    
    try {
        $script:Metrics.LastUpdated = Get-Date
        $script:Metrics | ConvertTo-Json -Depth 5 | Set-Content $script:LearningConfig.MetricsFile
        Write-Verbose "Saved metrics"
        return $true
    } catch {
        Write-Error "Failed to save metrics: $_"
        return $false
    }
}

#endregion

#region Pattern Recognition

function Add-ErrorPattern {
    <#
    .SYNOPSIS
    Adds a new error pattern to the learning system
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ErrorMessage,
        
        [string]$ErrorType,
        
        [string]$Fix,
        
        [hashtable]$Context
    )
    
    # Generate pattern ID
    $patternId = [System.Guid]::NewGuid().ToString().Substring(0,8)
    
    # Extract error type if not provided
    if (-not $ErrorType) {
        $ErrorType = switch -Regex ($ErrorMessage) {
            'CS0246' { 'MissingUsing' }
            'CS0103' { 'UndefinedVariable' }
            'CS1061' { 'MissingMethod' }
            'CS0029' { 'TypeMismatch' }
            'null reference' { 'NullReference' }
            'compilation error' { 'CompilationError' }
            default { 'Unknown' }
        }
    }
    
    # Create pattern entry
    $pattern = @{
        Id = $patternId
        ErrorMessage = $ErrorMessage
        ErrorType = $ErrorType
        FirstSeen = Get-Date
        LastSeen = Get-Date
        UseCount = 1
        Fixes = @()
        SuccessRate = 0.0
        Context = $Context
    }
    
    # Add fix if provided (ensure Fixes is always an array)
    if ($Fix) {
        $pattern.Fixes = @(
            @{
                Id = [System.Guid]::NewGuid().ToString().Substring(0,8)
                Code = $Fix
                SuccessCount = 0
                FailureCount = 0
                Created = Get-Date
            }
        )
    }
    
    # Check if similar pattern exists
    $existingPattern = $script:Patterns.Values | Where-Object { 
        $_.ErrorType -eq $ErrorType -and 
        $_.ErrorMessage -like "*$($ErrorMessage.Substring(0, [Math]::Min(20, $ErrorMessage.Length)))*" 
    } | Select-Object -First 1
    
    if ($existingPattern) {
        # Update existing pattern
        $existingPattern.UseCount++
        $existingPattern.LastSeen = Get-Date
        
        if ($Fix -and -not ($existingPattern.Fixes | Where-Object { $_.Code -eq $Fix })) {
            $existingPattern.Fixes += @{
                Id = [System.Guid]::NewGuid().ToString().Substring(0,8)
                Code = $Fix
                SuccessCount = 0
                FailureCount = 0
                Created = Get-Date
            }
        }
        
        $patternId = $existingPattern.Id
        Write-Verbose "Updated existing pattern: $patternId"
    } else {
        # Add new pattern
        $script:Patterns[$patternId] = $pattern
        $script:Metrics.PatternsLearned++
        Write-Verbose "Added new pattern: $patternId"
    }
    
    $null = Save-Patterns
    $null = Save-Metrics
    
    return $patternId
}

function Get-SuggestedFixes {
    <#
    .SYNOPSIS
    Gets suggested fixes for an error based on learned patterns
    .DESCRIPTION
    Searches for matching patterns using exact or fuzzy matching and returns suggested fixes
    .PARAMETER ErrorMessage
    The error message to search for
    .PARAMETER MinConfidence
    Minimum confidence level for suggestions (default: 0.5)
    .PARAMETER UseFuzzyMatching
    Override config to enable/disable fuzzy matching
    .PARAMETER MinSimilarity
    Minimum similarity percentage for fuzzy matching (0-100)
    .EXAMPLE
    Get-SuggestedFixes -ErrorMessage "CS0246: GameObject not found"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ErrorMessage,
        
        [double]$MinConfidence = 0.5,
        
        [bool]$UseFuzzyMatching = $script:LearningConfig.EnableFuzzyMatching,
        
        [ValidateRange(0, 100)]
        [double]$MinSimilarity = ($script:LearningConfig.MinSimilarity * 100)
    )
    
    Write-LearningLog -Message "Searching for fixes for: $ErrorMessage" -Level "INFO" -Component "Get-SuggestedFixes"
    Write-LearningLog -Message "Fuzzy matching: $UseFuzzyMatching, Min similarity: $MinSimilarity%" -Level "DEBUG" -Component "Get-SuggestedFixes"
    Write-Verbose "[Get-SuggestedFixes] Searching for fixes for: $ErrorMessage"
    Write-Verbose "[Get-SuggestedFixes] Fuzzy matching: $UseFuzzyMatching, Min similarity: $MinSimilarity%"
    
    $suggestions = @()
    $matchingPatterns = @()
    
    # First, try exact matching
    Write-LearningLog -Message "Starting exact match search" -Level "DEBUG" -Component "Get-SuggestedFixes"
    $exactMatches = $script:Patterns.Values | Where-Object {
        $match1 = $_.ErrorMessage -like "*$($ErrorMessage)*"
        $match2 = $ErrorMessage -like "*$($_.ErrorMessage)*"
        # Don't match on ErrorType "Unknown" - that's not a real error type
        $match3 = ($_.ErrorType -and $_.ErrorType -ne "Unknown" -and $ErrorMessage -match [regex]::Escape($_.ErrorType))
        
        if ($match1 -or $match2 -or $match3) {
            Write-LearningLog -Message "Exact match found: Pattern=$($_.Id), Match1=$match1, Match2=$match2, Match3=$match3, ErrorType=$($_.ErrorType)" -Level "DEBUG" -Component "Get-SuggestedFixes"
        }
        
        $match1 -or $match2
    }
    
    if ($exactMatches) {
        Write-LearningLog -Message "Found $($exactMatches.Count) exact matches" -Level "INFO" -Component "Get-SuggestedFixes"
        Write-Verbose "[Get-SuggestedFixes] Found $($exactMatches.Count) exact matches"
        $matchingPatterns += $exactMatches
    } else {
        Write-LearningLog -Message "No exact matches found" -Level "DEBUG" -Component "Get-SuggestedFixes"
    }
    
    # If fuzzy matching is enabled and we have few/no exact matches, use fuzzy search
    if ($UseFuzzyMatching -and $matchingPatterns.Count -lt 5) {
        Write-Verbose "[Get-SuggestedFixes] Using fuzzy matching to find additional patterns"
        
        $fuzzyMatches = Find-SimilarPatterns -ErrorMessage $ErrorMessage -MinSimilarity $MinSimilarity -MaxResults 10
        
        foreach ($fuzzyMatch in $fuzzyMatches) {
            # Skip if already in exact matches
            if ($matchingPatterns.Id -notcontains $fuzzyMatch.PatternId) {
                # Add pattern with similarity score
                $pattern = $fuzzyMatch.Pattern
                
                # Adjust confidence based on similarity
                $similarityFactor = $fuzzyMatch.Similarity / 100
                
                # Add to matching patterns
                $matchingPatterns += $pattern
                
                Write-LearningLog -Message "Added fuzzy match: $($fuzzyMatch.PatternId) with $($fuzzyMatch.Similarity)% similarity" -Level "DEBUG" -Component "Get-SuggestedFixes"
                Write-Verbose "[Get-SuggestedFixes] Added fuzzy match: $($fuzzyMatch.PatternId) with $($fuzzyMatch.Similarity)% similarity"
            }
        }
    }
    
    # Process all matching patterns
    foreach ($pattern in $matchingPatterns) {
        foreach ($fix in $pattern.Fixes) {
            $totalAttempts = $fix.SuccessCount + $fix.FailureCount
            $successRate = if ($totalAttempts -gt 0) {
                $fix.SuccessCount / $totalAttempts
            } else {
                0.5  # Default confidence for untested fixes
            }
            
            # For fuzzy matches, adjust confidence based on similarity
            if ($UseFuzzyMatching -and $pattern.Similarity) {
                $successRate = $successRate * ($pattern.Similarity / 100)
            }
            
            if ($successRate -ge $MinConfidence) {
                $suggestions += @{
                    PatternId = $pattern.Id
                    FixId = $fix.Id
                    Fix = $fix.Code
                    Confidence = $successRate
                    UseCount = $pattern.UseCount
                    ErrorType = $pattern.ErrorType
                    MatchType = if ($pattern.Similarity) { "Fuzzy" } else { "Exact" }
                    Similarity = $pattern.Similarity
                }
            }
        }
    }
    
    Write-Verbose "[Get-SuggestedFixes] Found $($suggestions.Count) total suggestions"
    
    # Sort by confidence and use count
    $suggestions | Sort-Object -Property @{Expression='Confidence';Descending=$true}, @{Expression='UseCount';Descending=$true}
}

#endregion

#region Self-Patching

function Apply-AutoFix {
    <#
    .SYNOPSIS
    Automatically applies a fix based on learned patterns
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ErrorMessage,
        
        [string]$FilePath,
        
        [switch]$DryRun,
        
        [switch]$Force
    )
    
    if (-not $script:LearningConfig.EnableAutoFix -and -not $DryRun -and -not $Force) {
        Write-Warning "Auto-fix is disabled. Enable with Set-LearningConfig -EnableAutoFix or use -Force"
        return @{
            Success = $false
            Reason = "AutoFix disabled"
        }
    }
    
    # Get suggested fixes
    $fixes = Get-SuggestedFixes -ErrorMessage $ErrorMessage -MinConfidence $script:LearningConfig.MinConfidence
    
    if ($fixes.Count -eq 0) {
        Write-Verbose "No fixes found for error pattern"
        return @{
            Success = $false
            Reason = "No matching patterns"
        }
    }
    
    $bestFix = $fixes[0]
    Write-Host "Found fix with $([Math]::Round($bestFix.Confidence * 100, 2))% confidence" -ForegroundColor Yellow
    Write-Host "Fix type: $($bestFix.ErrorType)" -ForegroundColor Gray
    
    if ($DryRun) {
        Write-Host "`nDRY RUN - Would apply fix:" -ForegroundColor Cyan
        Write-Host $bestFix.Fix -ForegroundColor Gray
        return @{
            Success = $true
            DryRun = $true
            Fix = $bestFix
        }
    }
    
    # Create backup if file specified
    $backup = $null
    if ($FilePath -and (Test-Path $FilePath)) {
        $backup = "$FilePath.learning_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Copy-Item $FilePath $backup
        Write-Verbose "Created backup: $backup"
    }
    
    try {
        # Apply the fix
        if ($FilePath) {
            # File-based fix - append fix to file
            Add-Content -Path $FilePath -Value "`n# Auto-fix applied by Unity-Claude-Learning"
            Add-Content -Path $FilePath -Value $bestFix.Fix
        } else {
            # Execute fix directly
            Invoke-Expression $bestFix.Fix
        }
        
        $script:Metrics.TotalAttempts++
        
        Write-Host "Fix applied successfully" -ForegroundColor Green
        
        # Update success count
        Update-FixSuccess -PatternId $bestFix.PatternId -FixId $bestFix.FixId -Success $true
        
        return @{
            Success = $true
            Fix = $bestFix
            Backup = $backup
        }
        
    } catch {
        Write-Error "Failed to apply fix: $_"
        
        # Restore backup if exists
        if ($backup -and (Test-Path $backup)) {
            Copy-Item $backup $FilePath -Force
            Write-Host "Restored from backup" -ForegroundColor Yellow
        }
        
        # Update failure count
        Update-FixSuccess -PatternId $bestFix.PatternId -FixId $bestFix.FixId -Success $false
        
        return @{
            Success = $false
            Error = $_.Exception.Message
            Backup = $backup
        }
    }
}

function Update-FixSuccess {
    <#
    .SYNOPSIS
    Updates success metrics for a fix
    #>
    [CmdletBinding()]
    param(
        [string]$PatternId,
        [string]$FixId,
        [bool]$Success
    )
    
    if ($script:Patterns.ContainsKey($PatternId)) {
        $pattern = $script:Patterns[$PatternId]
        $fix = $pattern.Fixes | Where-Object { $_.Id -eq $FixId } | Select-Object -First 1
        
        if ($fix) {
            if ($Success) {
                $fix.SuccessCount++
                $script:Metrics.SuccessfulFixes++
            } else {
                $fix.FailureCount++
                $script:Metrics.FailedFixes++
            }
            
            # Update pattern success rate
            $totalSuccess = 0
            $totalAttempts = 0
            foreach ($f in $pattern.Fixes) {
                $totalSuccess += $f.SuccessCount
                $totalAttempts += $f.SuccessCount + $f.FailureCount
            }
            
            if ($totalAttempts -gt 0) {
                $pattern.SuccessRate = $totalSuccess / $totalAttempts
            }
            
            $null = Save-Patterns
            $null = Save-Metrics
        }
    }
}

#endregion

#region Reporting

function Get-LearningReport {
    <#
    .SYNOPSIS
    Generates a learning system performance report
    #>
    [CmdletBinding()]
    param()
    
    $report = @{
        Generated = Get-Date
        Metrics = $script:Metrics
        TotalPatterns = $script:Patterns.Count
        TopPatterns = @()
        RecentPatterns = @()
        SuccessRate = 0
    }
    
    # Calculate success rate
    if ($script:Metrics.TotalAttempts -gt 0) {
        $report.SuccessRate = [Math]::Round(($script:Metrics.SuccessfulFixes / $script:Metrics.TotalAttempts) * 100, 2)
    }
    
    # Get top patterns by success rate
    $report.TopPatterns = $script:Patterns.Values | 
        Where-Object { $_.SuccessRate -gt 0 } |
        Sort-Object -Property SuccessRate -Descending |
        Select-Object -First 5 |
        ForEach-Object {
            @{
                Id = $_.Id
                ErrorType = $_.ErrorType
                SuccessRate = [Math]::Round($_.SuccessRate * 100, 2)
                UseCount = $_.UseCount
                FixCount = $_.Fixes.Count
            }
        }
    
    # Get recent patterns
    $report.RecentPatterns = $script:Patterns.Values |
        Sort-Object -Property LastSeen -Descending |
        Select-Object -First 5 |
        ForEach-Object {
            @{
                Id = $_.Id
                ErrorType = $_.ErrorType
                LastSeen = $_.LastSeen
                UseCount = $_.UseCount
            }
        }
    
    return $report
}

function Export-LearningReport {
    <#
    .SYNOPSIS
    Exports learning report to HTML
    #>
    [CmdletBinding()]
    param(
        [string]$Path = (Join-Path $script:LearningConfig.DataPath "learning_report_$(Get-Date -Format 'yyyyMMdd_HHmmss').html")
    )
    
    $report = Get-LearningReport
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Unity-Claude Learning Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        h2 { color: #666; border-bottom: 1px solid #ccc; }
        table { border-collapse: collapse; width: 100%; margin: 20px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .metric { display: inline-block; margin: 10px 20px; }
        .metric-value { font-size: 24px; font-weight: bold; color: #2196F3; }
        .success { color: #4CAF50; }
        .warning { color: #FF9800; }
        .error { color: #F44336; }
    </style>
</head>
<body>
    <h1>Unity-Claude Learning System Report</h1>
    <p>Generated: $($report.Generated)</p>
    
    <h2>Metrics</h2>
    <div class="metric">
        <div class="metric-value">$($report.TotalPatterns)</div>
        <div>Patterns Learned</div>
    </div>
    <div class="metric">
        <div class="metric-value">$($report.SuccessRate)%</div>
        <div>Success Rate</div>
    </div>
    <div class="metric">
        <div class="metric-value">$($report.Metrics.TotalAttempts)</div>
        <div>Total Attempts</div>
    </div>
    
    <h2>Top Performing Patterns</h2>
    <table>
        <tr>
            <th>Error Type</th>
            <th>Success Rate</th>
            <th>Use Count</th>
            <th>Fixes Available</th>
        </tr>
"@
    
    foreach ($pattern in $report.TopPatterns) {
        $html += @"
        <tr>
            <td>$($pattern.ErrorType)</td>
            <td class="success">$($pattern.SuccessRate)%</td>
            <td>$($pattern.UseCount)</td>
            <td>$($pattern.FixCount)</td>
        </tr>
"@
    }
    
    $html += @"
    </table>
    
    <h2>Recent Activity</h2>
    <table>
        <tr>
            <th>Error Type</th>
            <th>Last Seen</th>
            <th>Use Count</th>
        </tr>
"@
    
    foreach ($pattern in $report.RecentPatterns) {
        $html += @"
        <tr>
            <td>$($pattern.ErrorType)</td>
            <td>$($pattern.LastSeen)</td>
            <td>$($pattern.UseCount)</td>
        </tr>
"@
    }
    
    $html += @"
    </table>
</body>
</html>
"@
    
    $html | Set-Content $Path
    Write-Host "Report exported to: $Path" -ForegroundColor Green
    return $Path
}

#endregion

#region Configuration

function Set-LearningConfig {
    <#
    .SYNOPSIS
    Configures the learning system
    .DESCRIPTION
    Sets configuration parameters for the learning system including fuzzy matching settings
    .PARAMETER MaxPatternAge
    Maximum age in days for patterns to be considered
    .PARAMETER MinConfidence
    Minimum confidence level for suggestions (0.0-1.0)
    .PARAMETER EnableAutoFix
    Enable automatic fix application
    .PARAMETER EnableFuzzyMatching
    Enable fuzzy string matching for pattern recognition
    .PARAMETER MinSimilarity
    Minimum similarity for fuzzy matches (0.0-1.0)
    .PARAMETER MaxCacheSize
    Maximum number of entries in Levenshtein cache
    .EXAMPLE
    Set-LearningConfig -EnableFuzzyMatching $true -MinSimilarity 0.85
    #>
    [CmdletBinding()]
    param(
        [int]$MaxPatternAge,
        
        [ValidateRange(0.0, 1.0)]
        [double]$MinConfidence,
        
        [switch]$EnableAutoFix,
        
        [bool]$EnableFuzzyMatching,
        
        [ValidateRange(0.0, 1.0)]
        [double]$MinSimilarity,
        
        [ValidateRange(100, 10000)]
        [int]$MaxCacheSize
    )
    
    if ($PSBoundParameters.ContainsKey('MaxPatternAge')) {
        $script:LearningConfig.MaxPatternAge = $MaxPatternAge
        Write-Verbose "[Set-LearningConfig] MaxPatternAge set to: $MaxPatternAge days"
    }
    
    if ($PSBoundParameters.ContainsKey('MinConfidence')) {
        $script:LearningConfig.MinConfidence = $MinConfidence
        Write-Verbose "[Set-LearningConfig] MinConfidence set to: $MinConfidence"
    }
    
    if ($EnableAutoFix) {
        $script:LearningConfig.EnableAutoFix = $true
        Write-Warning "Auto-fix enabled - system will attempt automatic repairs"
    }
    
    if ($PSBoundParameters.ContainsKey('EnableFuzzyMatching')) {
        $script:LearningConfig.EnableFuzzyMatching = $EnableFuzzyMatching
        Write-Verbose "[Set-LearningConfig] Fuzzy matching: $EnableFuzzyMatching"
    }
    
    if ($PSBoundParameters.ContainsKey('MinSimilarity')) {
        $script:LearningConfig.MinSimilarity = $MinSimilarity
        Write-Verbose "[Set-LearningConfig] MinSimilarity set to: $($MinSimilarity * 100)%"
    }
    
    if ($PSBoundParameters.ContainsKey('MaxCacheSize')) {
        $script:LearningConfig.MaxCacheSize = $MaxCacheSize
        $script:MaxCacheSize = $MaxCacheSize
        Write-Verbose "[Set-LearningConfig] MaxCacheSize set to: $MaxCacheSize entries"
    }
    
    # Save configuration to file
    $configFile = Join-Path $script:LearningConfig.DataPath "config.json"
    try {
        $script:LearningConfig | ConvertTo-Json -Depth 3 | Set-Content $configFile
        Write-Verbose "[Set-LearningConfig] Configuration saved to: $configFile"
    } catch {
        Write-Warning "Failed to save configuration: $_"
    }
    
    return $script:LearningConfig
}

function Get-LearningConfig {
    return $script:LearningConfig
}

#endregion

#region AST Parsing Functions

function Get-CodeAST {
    <#
    .SYNOPSIS
    Parses PowerShell code and returns the Abstract Syntax Tree
    .DESCRIPTION
    Uses native PowerShell AST parsing capabilities to analyze code structure
    .PARAMETER Code
    PowerShell code string to parse
    .PARAMETER FilePath
    Path to PowerShell file to parse
    .PARAMETER Language
    Language type (currently only PowerShell supported)
    #>
    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName='Code')]
        [string]$Code,
        
        [Parameter(ParameterSetName='File')]
        [string]$FilePath,
        
        [string]$Language = 'PowerShell'
    )
    
    Write-Verbose "[Get-CodeAST] Starting AST parsing for $Language"
    
    if ($Language -ne 'PowerShell') {
        Write-Warning "Only PowerShell AST parsing is currently supported"
        return $null
    }
    
    $tokens = $null
    $errors = $null
    $ast = $null
    
    try {
        if ($PSCmdlet.ParameterSetName -eq 'File') {
            Write-Verbose "[Get-CodeAST] Parsing file: $FilePath"
            if (-not (Test-Path $FilePath)) {
                Write-Error "File not found: $FilePath"
                return $null
            }
            
            $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                $FilePath,
                [ref]$tokens,
                [ref]$errors
            )
            Write-Verbose "[Get-CodeAST] Parsed file - Tokens: $($tokens.Count), Errors: $($errors.Count)"
        } else {
            Write-Verbose "[Get-CodeAST] Parsing code string (length: $($Code.Length))"
            $ast = [System.Management.Automation.Language.Parser]::ParseInput(
                $Code,
                [ref]$tokens,
                [ref]$errors
            )
            Write-Verbose "[Get-CodeAST] Parsed code - Tokens: $($tokens.Count), Errors: $($errors.Count)"
        }
        
        return @{
            AST = $ast
            Tokens = $tokens
            Errors = $errors
            HasErrors = $errors.Count -gt 0
            Language = $Language
            Source = if ($FilePath) { $FilePath } else { 'CodeString' }
        }
        
    } catch {
        Write-Error "Failed to parse AST: $_"
        Write-Verbose "[Get-CodeAST] Exception details: $($_.Exception.Message)"
        return $null
    }
}

function Find-CodePattern {
    <#
    .SYNOPSIS
    Searches AST for specific code patterns
    .DESCRIPTION
    Uses AST FindAll method to locate specific code patterns
    .PARAMETER AST
    AST object or result from Get-CodeAST
    .PARAMETER PatternType
    Type of pattern to find (Function, Variable, Command, etc.)
    .PARAMETER Predicate
    Custom predicate scriptblock for pattern matching
    .PARAMETER ErrorMessage
    Error message to match against patterns
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $AST,
        
        [ValidateSet('Function', 'Variable', 'Command', 'Parameter', 'All', 'Custom')]
        [string]$PatternType = 'All',
        
        [scriptblock]$Predicate,
        
        [string]$ErrorMessage
    )
    
    Write-Verbose "[Find-CodePattern] Searching for pattern type: $PatternType"
    
    # Extract AST if passed result object
    $astToSearch = if ($AST.AST) { $AST.AST } else { $AST }
    
    if (-not $astToSearch) {
        Write-Error "Invalid AST object provided"
        return @()
    }
    
    # Build predicate based on pattern type
    if ($Predicate) {
        Write-Verbose "[Find-CodePattern] Using custom predicate"
        $searchPredicate = $Predicate
    } else {
        $searchPredicate = switch ($PatternType) {
            'Function' {
                { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }
            }
            'Variable' {
                { $args[0] -is [System.Management.Automation.Language.VariableExpressionAst] }
            }
            'Command' {
                { $args[0] -is [System.Management.Automation.Language.CommandAst] }
            }
            'Parameter' {
                { $args[0] -is [System.Management.Automation.Language.ParameterAst] }
            }
            'All' {
                { $true }
            }
            default {
                { $true }
            }
        }
    }
    
    try {
        $results = $astToSearch.FindAll($searchPredicate, $true)
        Write-Verbose "[Find-CodePattern] Found $($results.Count) matches"
        
        # If error message provided, try to match patterns
        if ($ErrorMessage -and $results.Count -gt 0) {
            $pattern = Analyze-ErrorPattern -ErrorMessage $ErrorMessage -ASTElements $results
            if ($pattern) {
                Write-Verbose "[Find-CodePattern] Matched error pattern: $($pattern.Type)"
                return @{
                    Matches = $results
                    ErrorType = $pattern.Type
                    SuggestedFix = $pattern.Fix
                }
            }
        }
        
        return $results
        
    } catch {
        Write-Error "Failed to search AST: $_"
        Write-Verbose "[Find-CodePattern] Exception: $($_.Exception.Message)"
        return @()
    }
}

function Get-ASTElements {
    <#
    .SYNOPSIS
    Extracts specific elements from AST
    .DESCRIPTION
    Returns structured information about code elements
    .PARAMETER AST
    AST object to analyze
    .PARAMETER ElementTypes
    Types of elements to extract
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $AST,
        
        [string[]]$ElementTypes = @('Function', 'Variable', 'Command')
    )
    
    Write-Verbose "[Get-ASTElements] Extracting elements: $($ElementTypes -join ', ')"
    
    $astToAnalyze = if ($AST.AST) { $AST.AST } else { $AST }
    
    if (-not $astToAnalyze) {
        Write-Error "Invalid AST object"
        return @{}
    }
    
    $elements = @{}
    
    foreach ($type in $ElementTypes) {
        Write-Verbose "[Get-ASTElements] Processing type: $type"
        
        $elements[$type] = switch ($type) {
            'Function' {
                $astToAnalyze.FindAll({ 
                    $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] 
                }, $true) | ForEach-Object {
                    @{
                        Name = $_.Name
                        Parameters = $_.Parameters.Name
                        Line = $_.Extent.StartLineNumber
                        Text = $_.Extent.Text
                    }
                }
            }
            'Variable' {
                $astToAnalyze.FindAll({ 
                    $args[0] -is [System.Management.Automation.Language.VariableExpressionAst] 
                }, $true) | Select-Object -Unique -Property VariablePath | ForEach-Object {
                    @{
                        Name = $_.VariablePath.UserPath
                        Type = 'Variable'
                    }
                }
            }
            'Command' {
                $astToAnalyze.FindAll({ 
                    $args[0] -is [System.Management.Automation.Language.CommandAst] 
                }, $true) | ForEach-Object {
                    @{
                        Name = $_.GetCommandName()
                        Line = $_.Extent.StartLineNumber
                        CommandElements = $_.CommandElements.Count
                    }
                }
            }
        }
        
        Write-Verbose "[Get-ASTElements] Found $($elements[$type].Count) $type elements"
    }
    
    return $elements
}

function Test-CodeSyntax {
    <#
    .SYNOPSIS
    Validates PowerShell code syntax
    .DESCRIPTION
    Uses AST parser to check for syntax errors
    .PARAMETER Code
    Code string to validate
    .PARAMETER FilePath
    File path to validate
    #>
    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName='Code')]
        [string]$Code,
        
        [Parameter(ParameterSetName='File')]
        [string]$FilePath
    )
    
    Write-Verbose "[Test-CodeSyntax] Starting syntax validation"
    
    $parseParams = @{}
    if ($Code) { $parseParams['Code'] = $Code }
    if ($FilePath) { $parseParams['FilePath'] = $FilePath }
    
    $result = Get-CodeAST @parseParams
    
    if (-not $result) {
        Write-Verbose "[Test-CodeSyntax] Failed to parse code"
        return @{
            Valid = $false
            Errors = @("Failed to parse code")
        }
    }
    
    $isValid = -not $result.HasErrors
    Write-Verbose "[Test-CodeSyntax] Syntax valid: $isValid, Errors: $($result.Errors.Count)"
    
    return @{
        Valid = $isValid
        Errors = $result.Errors | ForEach-Object {
            @{
                Message = $_.Message
                Line = $_.Extent.StartLineNumber
                Column = $_.Extent.StartColumnNumber
                ErrorId = $_.ErrorId
            }
        }
        ErrorCount = $result.Errors.Count
    }
}

function Analyze-ErrorPattern {
    <#
    .SYNOPSIS
    Internal function to analyze error patterns
    .DESCRIPTION
    Maps error messages to known patterns and fixes
    #>
    [CmdletBinding()]
    param(
        [string]$ErrorMessage,
        $ASTElements
    )
    
    Write-Verbose "[Analyze-ErrorPattern] Analyzing: $ErrorMessage"
    
    # Check against Unity error patterns
    foreach ($key in $script:UnityErrorPatterns.Keys) {
        if ($ErrorMessage -match $key) {
            Write-Verbose "[Analyze-ErrorPattern] Matched Unity pattern: $key"
            return $script:UnityErrorPatterns[$key]
        }
    }
    
    # Check for PowerShell patterns
    if ($ErrorMessage -match 'cannot be found|does not exist') {
        return @{
            Type = 'MissingReference'
            Fix = 'Check variable/function definitions and scope'
        }
    }
    
    if ($ErrorMessage -match 'null|NullReference') {
        return @{
            Type = 'NullReference'
            Fix = 'Add null checks before accessing object'
        }
    }
    
    return $null
}

#endregion

#region Unity Error Patterns

# Initialize Unity error patterns database
$script:UnityErrorPatterns = @{
    'CS0246' = @{
        Type = 'MissingUsing'
        Pattern = 'The type or namespace .* could not be found'
        Fixes = @(
            'using UnityEngine;',
            'using UnityEngine.UI;',
            'using System.Collections.Generic;',
            'using System.Linq;',
            'using System;'
        )
        Description = 'Missing using directive or assembly reference'
    }
    'CS0103' = @{
        Type = 'UndefinedVariable'
        Pattern = 'The name .* does not exist in the current context'
        Fixes = @(
            'Define the variable before use',
            'Check variable scope (block-level vs class-level)',
            'Verify spelling and capitalization'
        )
        Description = 'Variable or method not defined in current scope'
    }
    'CS1061' = @{
        Type = 'MissingMethod'
        Pattern = 'does not contain a definition for .* and no extension method'
        Fixes = @(
            'Verify method name spelling',
            'Check object type has the method',
            'Add extension method if needed',
            'Ensure correct using directives'
        )
        Description = 'Method or property does not exist on type'
    }
    'CS0029' = @{
        Type = 'TypeMismatch'
        Pattern = 'Cannot implicitly convert type'
        Fixes = @(
            'Use explicit casting',
            'Change variable type',
            'Use conversion methods (ToString(), Parse(), etc.)',
            'Check == vs = operator usage'
        )
        Description = 'Type conversion error'
    }
}

function Get-UnityErrorPattern {
    <#
    .SYNOPSIS
    Gets Unity-specific error patterns
    .DESCRIPTION
    Returns known Unity C# compilation error patterns and fixes
    #>
    [CmdletBinding()]
    param(
        [string]$ErrorCode
    )
    
    if ($ErrorCode) {
        return $script:UnityErrorPatterns[$ErrorCode]
    }
    
    return $script:UnityErrorPatterns
}

#endregion

#region Fuzzy Matching - Levenshtein Distance

# Cache for Levenshtein distance calculations
$script:LevenshteinCache = @{}
$script:MaxCacheSize = 1000

function Get-LevenshteinDistance {
    <#
    .SYNOPSIS
    Calculates the Levenshtein distance between two strings
    .DESCRIPTION
    Uses dynamic programming with two-row optimization for O(n) space complexity.
    The Levenshtein distance is the minimum number of single-character edits
    (insertions, deletions, or substitutions) required to transform one string into another.
    .PARAMETER String1
    First string to compare
    .PARAMETER String2
    Second string to compare
    .PARAMETER CaseSensitive
    Whether to perform case-sensitive comparison (default: false)
    .PARAMETER UseCache
    Whether to use result caching (default: true)
    .EXAMPLE
    Get-LevenshteinDistance "kitten" "sitting"
    # Returns: 3
    .EXAMPLE
    Get-LevenshteinDistance "hello" "HELLO" -CaseSensitive
    # Returns: 5
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$String1,
        
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$String2,
        
        [switch]$CaseSensitive,
        
        [bool]$UseCache = $true
    )
    
    Write-Verbose "[Get-LevenshteinDistance] Comparing '$String1' to '$String2'"
    
    # Handle case sensitivity
    if (-not $CaseSensitive) {
        $String1 = $String1.ToLower()
        $String2 = $String2.ToLower()
    }
    
    # Early exit for identical strings
    # Use appropriate comparison based on case sensitivity
    $areIdentical = if ($CaseSensitive) {
        $String1 -ceq $String2
    } else {
        $String1 -eq $String2
    }
    
    if ($areIdentical) {
        Write-Verbose "[Get-LevenshteinDistance] Strings are identical, distance = 0"
        return 0
    }
    
    # Check cache
    if ($UseCache) {
        # Create cache key (sort to ensure consistency)
        $cacheKey = if ($String1 -le $String2) {
            "$String1|$String2"
        } else {
            "$String2|$String1"
        }
        
        if ($script:LevenshteinCache.ContainsKey($cacheKey)) {
            Write-Verbose "[Get-LevenshteinDistance] Cache hit for key: $cacheKey"
            return $script:LevenshteinCache[$cacheKey]
        }
    }
    
    # Swap strings if needed to minimize space (use shorter string as columns)
    if ($String1.Length -gt $String2.Length) {
        $temp = $String1
        $String1 = $String2
        $String2 = $temp
    }
    
    $len1 = $String1.Length
    $len2 = $String2.Length
    
    # Handle empty strings
    if ($len1 -eq 0) { return $len2 }
    if ($len2 -eq 0) { return $len1 }
    
    # Two-row optimization: only need current and previous row
    $previousRow = New-Object 'int[]' ($len1 + 1)
    $currentRow = New-Object 'int[]' ($len1 + 1)
    
    # Initialize first row
    for ($i = 0; $i -le $len1; $i++) {
        $previousRow[$i] = $i
    }
    
    Write-Verbose "[Get-LevenshteinDistance] Starting matrix calculation ($len2 x $len1)"
    
    # Calculate distance using dynamic programming
    for ($j = 1; $j -le $len2; $j++) {
        $currentRow[0] = $j
        $char2 = $String2[$j - 1]
        
        for ($i = 1; $i -le $len1; $i++) {
            $char1 = $String1[$i - 1]
            
            # Cost of substitution (0 if characters match)
            # Use case-sensitive comparison if specified
            $cost = if ($CaseSensitive) {
                if ($char1 -ceq $char2) { 0 } else { 1 }
            } else {
                if ($char1 -eq $char2) { 0 } else { 1 }
            }
            
            # Calculate minimum of three operations
            $deletion = $previousRow[$i] + 1
            $insertion = $currentRow[$i - 1] + 1
            $substitution = $previousRow[$i - 1] + $cost
            
            $currentRow[$i] = [Math]::Min([Math]::Min($deletion, $insertion), $substitution)
        }
        
        # Swap rows for next iteration
        $temp = $previousRow
        $previousRow = $currentRow
        $currentRow = $temp
    }
    
    $distance = $previousRow[$len1]
    Write-Verbose "[Get-LevenshteinDistance] Distance calculated: $distance"
    
    # Cache result
    if ($UseCache) {
        # Maintain cache size limit
        if ($script:LevenshteinCache.Count -ge $script:MaxCacheSize) {
            Write-Verbose "[Get-LevenshteinDistance] Cache full, clearing oldest entries"
            # Remove oldest 20% of cache entries
            $keysToRemove = $script:LevenshteinCache.Keys | Select-Object -First ([int]($script:MaxCacheSize * 0.2))
            foreach ($key in $keysToRemove) {
                $script:LevenshteinCache.Remove($key)
            }
        }
        
        $script:LevenshteinCache[$cacheKey] = $distance
        Write-Verbose "[Get-LevenshteinDistance] Result cached with key: $cacheKey"
    }
    
    return $distance
}

function Get-StringSimilarity {
    <#
    .SYNOPSIS
    Calculates similarity percentage between two strings
    .DESCRIPTION
    Uses Levenshtein distance to calculate a normalized similarity score
    between 0 (completely different) and 100 (identical)
    .PARAMETER String1
    First string to compare
    .PARAMETER String2
    Second string to compare
    .PARAMETER CaseSensitive
    Whether to perform case-sensitive comparison
    .EXAMPLE
    Get-StringSimilarity "kitten" "sitting"
    # Returns: 57.14 (57.14% similar)
    .EXAMPLE
    Get-StringSimilarity "hello" "hello"
    # Returns: 100.00 (100% similar)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$String1,
        
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$String2,
        
        [switch]$CaseSensitive
    )
    
    Write-Verbose "[Get-StringSimilarity] Calculating similarity between '$String1' and '$String2'"
    
    # Handle empty strings
    if ([string]::IsNullOrEmpty($String1) -and [string]::IsNullOrEmpty($String2)) {
        return 100.0
    }
    if ([string]::IsNullOrEmpty($String1) -or [string]::IsNullOrEmpty($String2)) {
        return 0.0
    }
    
    # Get Levenshtein distance
    $distance = Get-LevenshteinDistance -String1 $String1 -String2 $String2 -CaseSensitive:$CaseSensitive
    
    # Calculate maximum possible distance
    $maxLength = [Math]::Max($String1.Length, $String2.Length)
    
    # Calculate similarity percentage
    $similarity = (1 - ($distance / $maxLength)) * 100
    $similarity = [Math]::Round($similarity, 2)
    
    Write-Verbose "[Get-StringSimilarity] Distance: $distance, Max Length: $maxLength, Similarity: $similarity%"
    
    return $similarity
}

function Test-FuzzyMatch {
    <#
    .SYNOPSIS
    Tests if two strings match within a similarity threshold
    .DESCRIPTION
    Returns true if the similarity between two strings exceeds the specified threshold
    .PARAMETER String1
    First string to compare
    .PARAMETER String2
    Second string to compare
    .PARAMETER MinSimilarity
    Minimum similarity percentage required for a match (0-100, default: 85)
    .PARAMETER CaseSensitive
    Whether to perform case-sensitive comparison
    .EXAMPLE
    Test-FuzzyMatch "CS0246: GameObject not found" "CS0246: The type GameObject could not be found" -MinSimilarity 70
    # Returns: True
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$String1,
        
        [Parameter(Mandatory)]
        [string]$String2,
        
        [ValidateRange(0, 100)]
        [double]$MinSimilarity = 85,
        
        [switch]$CaseSensitive
    )
    
    Write-Verbose "[Test-FuzzyMatch] Testing match with threshold: $MinSimilarity%"
    
    $similarity = Get-StringSimilarity -String1 $String1 -String2 $String2 -CaseSensitive:$CaseSensitive
    $matches = $similarity -ge $MinSimilarity
    
    Write-Verbose "[Test-FuzzyMatch] Similarity: $similarity%, Matches: $matches"
    
    return $matches
}

function Find-SimilarPatterns {
    <#
    .SYNOPSIS
    Finds patterns similar to the given error message
    .DESCRIPTION
    Searches all stored patterns and returns those within the similarity threshold
    .PARAMETER ErrorMessage
    Error message to search for
    .PARAMETER MinSimilarity
    Minimum similarity percentage (default: 85)
    .PARAMETER MaxResults
    Maximum number of results to return (default: 10)
    .EXAMPLE
    Find-SimilarPatterns -ErrorMessage "CS0246: GameObject not found"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ErrorMessage,
        
        [ValidateRange(0, 100)]
        [double]$MinSimilarity = 85,
        
        [int]$MaxResults = 10
    )
    
    Write-Verbose "[Find-SimilarPatterns] Searching for patterns similar to: $ErrorMessage"
    Write-Verbose "[Find-SimilarPatterns] Minimum similarity: $MinSimilarity%"
    Write-Verbose "[Find-SimilarPatterns] Total patterns in memory: $($script:Patterns.Count)"
    
    $similarPatterns = @()
    
    # Debug: Check if patterns is actually a hashtable
    if ($script:Patterns -isnot [hashtable]) {
        Write-Warning "[Find-SimilarPatterns] Patterns is not a hashtable! Type: $($script:Patterns.GetType().Name)"
    }
    
    foreach ($patternId in $script:Patterns.Keys) {
        $pattern = $script:Patterns[$patternId]
        
        Write-Verbose "[Find-SimilarPatterns] Comparing with pattern $patternId : '$($pattern.ErrorMessage)'"
        
        # Calculate similarity
        $similarity = Get-StringSimilarity -String1 $ErrorMessage -String2 $pattern.ErrorMessage
        
        Write-Verbose "[Find-SimilarPatterns] Similarity: $similarity%"
        
        if ($similarity -ge $MinSimilarity) {
            Write-Verbose "[Find-SimilarPatterns] Found match: Pattern $patternId with $similarity% similarity"
            
            $matchObject = [PSCustomObject]@{
                PatternId = $patternId
                Pattern = $pattern
                Similarity = $similarity
                ErrorMessage = $pattern.ErrorMessage
                Fixes = $pattern.Fixes
                SuccessRate = $pattern.SuccessRate
            }
            
            $similarPatterns += $matchObject
            Write-Verbose "[Find-SimilarPatterns] Added match to array. Current count: $($similarPatterns.Count)"
        }
    }
    
    Write-Verbose "[Find-SimilarPatterns] similarPatterns array has $($similarPatterns.Count) items before pipeline"
    
    if ($null -eq $similarPatterns) {
        Write-Verbose "[Find-SimilarPatterns] similarPatterns is null"
        $results = @()
    } elseif ($similarPatterns.Count -eq 0) {
        Write-Verbose "[Find-SimilarPatterns] similarPatterns is empty array"
        $results = @()
    } else {
        Write-Verbose "[Find-SimilarPatterns] Processing $($similarPatterns.Count) patterns through pipeline"
        # Sort by similarity (highest first) and return top results
        # Wrap in @() to ensure array is preserved through pipeline
        $results = @($similarPatterns | 
            Sort-Object -Property Similarity -Descending |
            Select-Object -First $MaxResults)
    }
    
    Write-Verbose "[Find-SimilarPatterns] results array has $($results.Count) items after pipeline"
    Write-Verbose "[Find-SimilarPatterns] Found $($results.Count) similar patterns"
    
    # Use comma operator to preserve array structure (prevents PowerShell from unrolling single-element arrays)
    return ,$results
}

function Clear-LevenshteinCache {
    <#
    .SYNOPSIS
    Clears the Levenshtein distance cache
    .DESCRIPTION
    Removes all cached distance calculations to free memory
    .EXAMPLE
    Clear-LevenshteinCache
    #>
    [CmdletBinding()]
    param()
    
    $count = $script:LevenshteinCache.Count
    $script:LevenshteinCache.Clear()
    
    Write-Verbose "[Clear-LevenshteinCache] Cleared $count cached entries"
}

function Get-LevenshteinCacheInfo {
    <#
    .SYNOPSIS
    Gets information about the Levenshtein cache
    .DESCRIPTION
    Returns statistics about the current cache state
    .EXAMPLE
    Get-LevenshteinCacheInfo
    #>
    [CmdletBinding()]
    param()
    
    return @{
        Count = $script:LevenshteinCache.Count
        MaxSize = $script:MaxCacheSize
        PercentFull = [Math]::Round(($script:LevenshteinCache.Count / $script:MaxCacheSize) * 100, 2)
        Keys = $script:LevenshteinCache.Keys
    }
}

#endregion

#region Module Exports

Export-ModuleMember -Function @(
    'Initialize-LearningStorage',
    'Add-ErrorPattern',
    'Get-SuggestedFixes',
    'Apply-AutoFix',
    'Get-LearningReport',
    'Export-LearningReport',
    'Set-LearningConfig',
    'Get-LearningConfig',
    'Update-FixSuccess',
    # AST Functions
    'Get-CodeAST',
    'Find-CodePattern',
    'Get-ASTElements',
    'Test-CodeSyntax',
    'Get-UnityErrorPattern',
    # Fuzzy Matching Functions
    'Get-LevenshteinDistance',
    'Get-StringSimilarity',
    'Test-FuzzyMatch',
    'Find-SimilarPatterns',
    'Clear-LevenshteinCache',
    'Get-LevenshteinCacheInfo'
)

#endregion

# Initialize on load
Initialize-LearningStorage | Out-Null

Write-Host "Unity-Claude-Learning (Simple) loaded - Phase 3 Self-Improvement" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUpsQ9xeY9IsyXCK2YfpfRMJld
# PvqgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUmcsrX6wzf2TJPpLegznASyfm0kcwDQYJKoZIhvcNAQEBBQAEggEAGqZY
# 6nY8tJnGlDvX37Ob7ArCPJvs5YJrdbAR2scG/FLuvPLBc2S4rexRyRqRfBCXnqA/
# crSuOiWPjGsWK82Qix0vgglN62zRSWKjJBg+RYIU9etDQSQYsNok5ldMpumT0QjM
# HvBWaoLsVDJswl23WqPS6oT0UM3NnOFQd85FAl+1EHBoBHIc4r8iOVABdwLrXBuO
# 2cdV82W8e+loyZyxeqhPrcP9Omq3oHBS8IHEVbR6Sr/sODZbvC5CvyqIhU71S+Uz
# jD94l7/kp5HEr/K4mSZqwdyKJFlhKuFwfM77JmFzK9RVvRaOnTptR3KKvQGvyUsB
# 46Ro0QA1J5s90vzehg==
# SIG # End signature block
