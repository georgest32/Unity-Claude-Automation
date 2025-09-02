function Search-SystemStatusLogs {
    <#
    .SYNOPSIS
    Performs efficient searching and analysis of SystemStatus log files
    
    .DESCRIPTION
    Advanced log search capabilities following 2025 best practices:
    - High-performance text searching with regex support
    - Time-based filtering with multiple date formats
    - Log level filtering and pattern matching
    - PowerShell 5.1 compatible implementation
    - Structured output with context preservation
    - Memory-efficient processing for large log files
    
    .PARAMETER Pattern
    Search pattern (supports regex)
    
    .PARAMETER LogPath
    Path to log file (default: current SystemStatus log)
    
    .PARAMETER StartTime
    Start time for filtering results
    
    .PARAMETER EndTime
    End time for filtering results
    
    .PARAMETER LogLevels
    Log levels to include in search
    
    .PARAMETER MaxResults
    Maximum number of results to return
    
    .PARAMETER Context
    Number of context lines to include before and after matches
    
    .PARAMETER OutputFormat
    Output format: Object, JSON, CSV, Text
    
    .EXAMPLE
    Search-SystemStatusLogs -Pattern "ERROR|WARN" -MaxResults 50
    
    .EXAMPLE
    Search-SystemStatusLogs -Pattern "Subsystem.*failed" -StartTime (Get-Date).AddHours(-1) -Context 2
    
    .EXAMPLE
    Search-SystemStatusLogs -LogLevels @('ERROR') -StartTime (Get-Date).AddDays(-1) -OutputFormat JSON
    #>
    [CmdletBinding()]
    param(
        [string]$Pattern,
        
        [string]$LogPath,
        
        [DateTime]$StartTime = [DateTime]::MinValue,
        
        [DateTime]$EndTime = [DateTime]::MaxValue,
        
        [string[]]$LogLevels = @('ERROR', 'WARN', 'WARNING'),
        
        [int]$MaxResults = 100,
        
        [int]$Context = 0,
        
        [ValidateSet('Object', 'JSON', 'CSV', 'Text')]
        [string]$OutputFormat = 'Object'
    )
    
    $searchTimer = [System.Diagnostics.Stopwatch]::StartNew()
    
    Write-TraceLog -Message "Starting log search" -Operation "Search-SystemStatusLogs" -Context @{
        Pattern = $Pattern
        LogLevels = $LogLevels -join ','
        MaxResults = $MaxResults
        HasTimeFilter = ($StartTime -or $EndTime)
    }
    
    try {
        # Determine log file path
        if (-not $LogPath) {
            if ($script:SystemStatusConfig) {
                $LogPath = Join-Path (Split-Path $script:SystemStatusConfig.SystemStatusFile -Parent) $script:SystemStatusConfig.LogFile
            } else {
                $LogPath = ".\unity_claude_automation.log"
            }
        }
        
        if (-not (Test-Path $LogPath)) {
            throw "Log file not found: $LogPath"
        }
        
        $logFile = Get-Item $LogPath
        $logSizeMB = [math]::Round($logFile.Length / 1MB, 2)
        
        Write-SystemStatusLog "Searching log file: $($logFile.Name) ($logSizeMB MB)" -Level 'INFO' -Source 'LogSearch'
        
        # Build search criteria
        $searchCriteria = Build-LogSearchCriteria -Pattern $Pattern -LogLevels $LogLevels -StartTime $StartTime -EndTime $EndTime
        
        # Perform the search
        $searchResults = if ($logSizeMB -gt 50) {
            # Use streaming approach for large files
            Search-LargeLogFile -LogPath $LogPath -SearchCriteria $searchCriteria -MaxResults $MaxResults -Context $Context
        } else {
            # Use in-memory approach for smaller files
            Search-SmallLogFile -LogPath $LogPath -SearchCriteria $searchCriteria -MaxResults $MaxResults -Context $Context
        }
        
        $searchTimer.Stop()
        
        Write-SystemStatusLog "Log search completed: $($searchResults.Results.Count) matches in $($searchTimer.ElapsedMilliseconds)ms" -Level 'OK' -Source 'LogSearch'
        
        # Format output
        $formattedOutput = Format-LogSearchResults -SearchResults $searchResults -OutputFormat $OutputFormat -SearchInfo @{
            Pattern = $Pattern
            LogPath = $LogPath
            LogLevels = $LogLevels
            StartTime = $StartTime
            EndTime = $EndTime
            MaxResults = $MaxResults
            Context = $Context
            Duration = $searchTimer.Elapsed
        }
        
        Write-TraceLog -Message "Log search completed successfully" -Operation "Search-SystemStatusLogs" -Timer $searchTimer -Context @{
            ResultsFound = $searchResults.Results.Count
            LogSizeMB = $logSizeMB
            SearchMethod = if ($logSizeMB -gt 50) { 'Streaming' } else { 'InMemory' }
        }
        
        return $formattedOutput
        
    } catch {
        $searchTimer.Stop()
        Write-SystemStatusLog "Log search failed: $($_.Exception.Message)" -Level 'ERROR' -Source 'LogSearch'
        Write-TraceLog -Message "Log search failed" -Operation "Search-SystemStatusLogs" -Timer $searchTimer -Context @{
            Error = $_.Exception.Message
        }
        
        throw
    }
}

function Build-LogSearchCriteria {
    <#
    .SYNOPSIS
    Builds optimized search criteria for log filtering
    #>
    param(
        [string]$Pattern,
        [string[]]$LogLevels,
        [DateTime]$StartTime,
        [DateTime]$EndTime
    )
    
    $criteria = @{
        HasPattern = [bool]$Pattern
        PatternRegex = $null
        LogLevelFilter = $LogLevels
        HasTimeFilter = ($StartTime -ne [DateTime]::MinValue) -or ($EndTime -ne [DateTime]::MaxValue)
        StartTime = $StartTime
        EndTime = $EndTime
        LogLevelRegex = $null
    }
    
    # Compile pattern regex for performance
    if ($Pattern) {
        try {
            $criteria.PatternRegex = [regex]::new($Pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Compiled)
        } catch {
            throw "Invalid regex pattern: $Pattern - $($_.Exception.Message)"
        }
    }
    
    # Build log level regex
    if ($LogLevels -and $LogLevels.Count -gt 0) {
        $levelPattern = '^\[.*?\] \[(' + ($LogLevels -join '|') + ')\]'
        $criteria.LogLevelRegex = [regex]::new($levelPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Compiled)
    }
    
    Write-TraceLog -Message "Search criteria built" -Operation "BuildSearchCriteria" -Context $criteria -TraceLevel 'Detail'
    
    return $criteria
}

function Search-SmallLogFile {
    <#
    .SYNOPSIS
    Searches smaller log files using in-memory processing
    #>
    param(
        [string]$LogPath,
        [hashtable]$SearchCriteria,
        [int]$MaxResults,
        [int]$Context
    )
    
    $lines = Get-Content $LogPath -ErrorAction Stop
    $results = @()
    $lineNumber = 0
    $matchCount = 0
    
    Write-TraceLog -Message "Processing $($lines.Count) lines in memory" -Operation "SearchSmallFile"
    
    foreach ($line in $lines) {
        $lineNumber++
        
        if ($matchCount -ge $MaxResults) {
            break
        }
        
        $match = Test-LogLineMatch -Line $line -SearchCriteria $SearchCriteria -LineNumber $lineNumber
        
        if ($match.IsMatch) {
            $result = @{
                LineNumber = $lineNumber
                Line = $line
                ParsedEntry = $match.ParsedEntry
                MatchType = $match.MatchType
            }
            
            # Add context lines if requested
            if ($Context -gt 0) {
                $result.ContextBefore = Get-ContextLines -Lines $lines -StartIndex ([math]::Max(0, $lineNumber - $Context - 1)) -Count $Context
                $result.ContextAfter = Get-ContextLines -Lines $lines -StartIndex $lineNumber -Count $Context
            }
            
            $results += $result
            $matchCount++
        }
    }
    
    return @{
        Results = $results
        TotalLines = $lines.Count
        SearchMethod = 'InMemory'
    }
}

function Search-LargeLogFile {
    <#
    .SYNOPSIS
    Searches larger log files using streaming approach
    #>
    param(
        [string]$LogPath,
        [hashtable]$SearchCriteria,
        [int]$MaxResults,
        [int]$Context
    )
    
    $results = @()
    $lineNumber = 0
    $matchCount = 0
    $contextBuffer = @()
    
    Write-TraceLog -Message "Processing large file with streaming" -Operation "SearchLargeFile"
    
    try {
        $reader = [System.IO.StreamReader]::new($LogPath)
        
        while (-not $reader.EndOfStream -and $matchCount -lt $MaxResults) {
            $line = $reader.ReadLine()
            $lineNumber++
            
            # Maintain context buffer
            if ($Context -gt 0) {
                $contextBuffer += @{ LineNumber = $lineNumber; Line = $line }
                if ($contextBuffer.Count -gt ($Context * 2 + 1)) {
                    $contextBuffer = $contextBuffer | Select-Object -Last ($Context * 2 + 1)
                }
            }
            
            $match = Test-LogLineMatch -Line $line -SearchCriteria $SearchCriteria -LineNumber $lineNumber
            
            if ($match.IsMatch) {
                $result = @{
                    LineNumber = $lineNumber
                    Line = $line
                    ParsedEntry = $match.ParsedEntry
                    MatchType = $match.MatchType
                }
                
                # Add context from buffer if requested
                if ($Context -gt 0 -and $contextBuffer.Count -gt 0) {
                    $currentIndex = $contextBuffer.Count - 1
                    $result.ContextBefore = $contextBuffer | Select-Object -First $Context | ForEach-Object { $_.Line }
                    $result.ContextAfter = @() # Will be populated as we read ahead
                }
                
                $results += $result
                $matchCount++
            }
        }
        
        $reader.Close()
        
    } catch {
        if ($reader) { $reader.Close() }
        throw
    }
    
    return @{
        Results = $results
        TotalLines = $lineNumber
        SearchMethod = 'Streaming'
    }
}

function Test-LogLineMatch {
    <#
    .SYNOPSIS
    Tests if a log line matches the search criteria
    #>
    param(
        [string]$Line,
        [hashtable]$SearchCriteria,
        [int]$LineNumber
    )
    
    $result = @{
        IsMatch = $false
        MatchType = 'None'
        ParsedEntry = $null
    }
    
    # Parse log entry
    $parsedEntry = Parse-LogEntry -Line $Line -LineNumber $LineNumber
    $result.ParsedEntry = $parsedEntry
    
    # Test log level filter
    if ($SearchCriteria.LogLevelRegex) {
        if (-not $SearchCriteria.LogLevelRegex.IsMatch($Line)) {
            return $result
        }
    }
    
    # Test time filter
    if ($SearchCriteria.HasTimeFilter -and $parsedEntry.Timestamp) {
        if ($SearchCriteria.StartTime -ne [DateTime]::MinValue -and $parsedEntry.Timestamp -lt $SearchCriteria.StartTime) {
            return $result
        }
        if ($SearchCriteria.EndTime -ne [DateTime]::MaxValue -and $parsedEntry.Timestamp -gt $SearchCriteria.EndTime) {
            return $result
        }
    }
    
    # Test pattern match
    if ($SearchCriteria.HasPattern) {
        if ($SearchCriteria.PatternRegex.IsMatch($Line)) {
            $result.IsMatch = $true
            $result.MatchType = 'Pattern'
            return $result
        }
    } else {
        # No pattern specified, match based on log level only
        $result.IsMatch = $true
        $result.MatchType = 'LogLevel'
        return $result
    }
    
    return $result
}

function Parse-LogEntry {
    <#
    .SYNOPSIS
    Parses a log entry into structured components
    #>
    param(
        [string]$Line,
        [int]$LineNumber
    )
    
    $entry = @{
        LineNumber = $LineNumber
        RawLine = $Line
        Timestamp = $null
        Level = $null
        Source = $null
        Message = $null
        IsStructured = $false
    }
    
    # Try to parse standard log format: [timestamp] [level] [source] message
    if ($Line -match '^\[([^\]]+)\] \[([^\]]+)\] \[([^\]]+)\] (.*)$') {
        try {
            $entry.Timestamp = [DateTime]::ParseExact($Matches[1], 'yyyy-MM-dd HH:mm:ss.fff', $null)
            $entry.Level = $Matches[2]
            $entry.Source = $Matches[3]
            $entry.Message = $Matches[4]
        } catch {
            $entry.Message = $Line
        }
    } elseif ($Line -match '^\[([^\]]+)\] \[([^\]]+)\] (.*)$') {
        # Fallback format: [timestamp] [level] message
        try {
            $entry.Timestamp = [DateTime]::ParseExact($Matches[1], 'yyyy-MM-dd HH:mm:ss.fff', $null)
            $entry.Level = $Matches[2]
            $entry.Message = $Matches[3]
        } catch {
            $entry.Message = $Line
        }
    } else {
        # Try to parse JSON structured log
        try {
            $jsonData = ConvertFrom-Json $Line
            $entry.IsStructured = $true
            $entry.Timestamp = [DateTime]$jsonData.Timestamp
            $entry.Level = $jsonData.Level
            $entry.Source = $jsonData.Source
            $entry.Message = $jsonData.Message
        } catch {
            $entry.Message = $Line
        }
    }
    
    return $entry
}

function Get-ContextLines {
    <#
    .SYNOPSIS
    Gets context lines around a match
    #>
    param(
        [string[]]$Lines,
        [int]$StartIndex,
        [int]$Count
    )
    
    $endIndex = [math]::Min($StartIndex + $Count - 1, $Lines.Count - 1)
    
    if ($StartIndex -ge 0 -and $StartIndex -lt $Lines.Count) {
        return $Lines[$StartIndex..$endIndex]
    }
    
    return @()
}

function Format-LogSearchResults {
    <#
    .SYNOPSIS
    Formats search results in the requested output format
    #>
    param(
        [hashtable]$SearchResults,
        [string]$OutputFormat,
        [hashtable]$SearchInfo
    )
    
    $output = @{
        SearchInfo = $SearchInfo
        Results = $SearchResults.Results
        Summary = @{
            TotalMatches = $SearchResults.Results.Count
            TotalLines = $SearchResults.TotalLines
            SearchMethod = $SearchResults.SearchMethod
        }
    }
    
    switch ($OutputFormat) {
        'Object' {
            return $output
        }
        
        'JSON' {
            return ConvertTo-Json $output -Depth 5 -Compress
        }
        
        'CSV' {
            $csvData = $SearchResults.Results | ForEach-Object {
                [PSCustomObject]@{
                    LineNumber = $_.LineNumber
                    Timestamp = $_.ParsedEntry.Timestamp
                    Level = $_.ParsedEntry.Level
                    Source = $_.ParsedEntry.Source
                    Message = $_.ParsedEntry.Message
                    MatchType = $_.MatchType
                }
            }
            return $csvData | ConvertTo-Csv -NoTypeInformation
        }
        
        'Text' {
            $textOutput = @()
            $textOutput += "=== Log Search Results ==="
            $textOutput += "Pattern: $($SearchInfo.Pattern)"
            $textOutput += "Results: $($output.Summary.TotalMatches) of $($output.Summary.TotalLines) lines"
            $textOutput += "Duration: $($SearchInfo.Duration.TotalMilliseconds)ms"
            $textOutput += ""
            
            foreach ($result in $SearchResults.Results) {
                $textOutput += "Line $($result.LineNumber): $($result.Line)"
                if ($result.ContextBefore) {
                    $textOutput += "  Context Before:"
                    foreach ($contextLine in $result.ContextBefore) {
                        $textOutput += "    $contextLine"
                    }
                }
                if ($result.ContextAfter) {
                    $textOutput += "  Context After:"
                    foreach ($contextLine in $result.ContextAfter) {
                        $textOutput += "    $contextLine"
                    }
                }
                $textOutput += ""
            }
            
            return $textOutput -join "`n"
        }
        
        default {
            return $output
        }
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC17CPNo+924WHM
# T6uEGOHZu4tKW1vwO+yKDypMLc0zf6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIB4z1f8s18vz5oeZVzlQtdFE
# MQCZQq+HPewQ5T2h2z0SMA0GCSqGSIb3DQEBAQUABIIBAB1lJ0aNlZN7KvtNegyf
# xFAYTqs4XS0YZT5e11zXceTWrCTQxg60Mc1xiX5eiX68CmPSs3FOr5LFwY6tQW59
# KwFtLHTpudjlVBoyZUMGPTsND667nGxUZrcjem1tmrx2BmJQJb9Aq1CGeeDsChP9
# UmNvhWWkyTDJfyx+XuwkN4EiiFNY+qiyQB6X7GImvwN3fqn/GRxkg6IS+Lhsw6XO
# 3Qw57P9u45C2R/YhtNJZAHF41Sv8YfCGsOdZ7SYbs6DyDeSf8+H9t+uiXOS2Bnjt
# R82I4rH6SivK32m/yfQwInDZiqCqwwNd64gRkI4I3GTutOhnz02oNK+JzVU95e6A
# 1Hk=
# SIG # End signature block
