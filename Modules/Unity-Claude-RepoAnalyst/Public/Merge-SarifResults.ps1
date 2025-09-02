function Merge-SarifResults {
    <#
    .SYNOPSIS
    Merges multiple SARIF results with deduplication and aggregation
    
    .DESCRIPTION
    Combines SARIF outputs from multiple linters, handles deduplication,
    aggregates statistics, and produces unified SARIF 2.1.0 compatible output
    
    .PARAMETER SarifResults
    Array of SARIF result objects from different linters
    
    .PARAMETER DeduplicateResults
    Enable deduplication of similar findings across tools
    
    .PARAMETER DeduplicationThreshold
    Similarity threshold for deduplication (0.0-1.0)
    
    .PARAMETER IncludeMetrics
    Include aggregated metrics in the output
    
    .PARAMETER OutputPath
    Path to save the merged SARIF results (optional)
    
    .EXAMPLE
    $eslintResults = Invoke-ESLintAnalysis -Path "src/"
    $pylintResults = Invoke-PylintAnalysis -Path "src/"
    $merged = Merge-SarifResults -SarifResults @($eslintResults, $pylintResults)
    
    .EXAMPLE
    $results = @($eslint, $pylint, $psa, $bandit, $semgrep)
    Merge-SarifResults -SarifResults $results -DeduplicateResults -OutputPath "merged-results.sarif"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$SarifResults,
        
        [Parameter()]
        [switch]$DeduplicateResults,
        
        [Parameter()]
        [ValidateRange(0.0, 1.0)]
        [double]$DeduplicationThreshold = 0.8,
        
        [Parameter()]
        [switch]$IncludeMetrics = $true,
        
        [Parameter()]
        [string]$OutputPath
    )
    
    begin {
        Write-Verbose "Starting SARIF results merge for $($SarifResults.Count) result sets"
        
        # SARIF 2.1.0 schema version
        $sarifVersion = '2.1.0'
        $mergeTimestamp = Get-Date
        
        # Initialize aggregation structures
        $allRuns = @()
        $allResults = @()
        $toolStats = @{}
        $severityStats = @{
            error = 0
            warning = 0
            note = 0
        }
        $ruleStats = @{}
        $fileStats = @{}
    }
    
    process {
        try {
            # Process each SARIF result set
            foreach ($sarifResult in $SarifResults) {
                if (-not $sarifResult -or -not $sarifResult.runs) {
                    Write-Warning "Skipping invalid SARIF result"
                    continue
                }
                
                foreach ($run in $sarifResult.runs) {
                    # Collect tool statistics
                    $toolName = $run.tool.driver.name
                    if (-not $toolStats[$toolName]) {
                        $toolStats[$toolName] = @{
                            version = $run.tool.driver.version
                            rulesCount = $run.tool.driver.rules.Count
                            resultsCount = $run.results.Count
                            executionTime = if ($run.properties.executionTimeSeconds) { $run.properties.executionTimeSeconds } else { 0 }
                        }
                    }
                    
                    # Add run to collection
                    $allRuns += $run
                    
                    # Process results
                    foreach ($result in $run.results) {
                        # Add tool context to result
                        $enhancedResult = $result.PSObject.Copy()
                        $enhancedResult | Add-Member -NotePropertyName 'toolName' -NotePropertyValue $toolName -Force
                        
                        # Update statistics
                        $severityStats[$result.level]++
                        
                        # Update rule statistics
                        $ruleId = "$toolName.$($result.ruleId)"
                        if (-not $ruleStats[$ruleId]) {
                            $ruleStats[$ruleId] = 0
                        }
                        $ruleStats[$ruleId]++
                        
                        # Update file statistics
                        if ($result.locations -and $result.locations[0].physicalLocation) {
                            $filePath = $result.locations[0].physicalLocation.artifactLocation.uri
                            if (-not $fileStats[$filePath]) {
                                $fileStats[$filePath] = @{
                                    totalIssues = 0
                                    tools = @{}
                                    severities = @{ error = 0; warning = 0; note = 0 }
                                }
                            }
                            $fileStats[$filePath].totalIssues++
                            $fileStats[$filePath].severities[$result.level]++
                            
                            if (-not $fileStats[$filePath].tools[$toolName]) {
                                $fileStats[$filePath].tools[$toolName] = 0
                            }
                            $fileStats[$filePath].tools[$toolName]++
                        }
                        
                        $allResults += $enhancedResult
                    }
                }
            }
            
            Write-Verbose "Collected $($allResults.Count) results from $($allRuns.Count) tool runs"
            
            # Deduplication if requested
            $finalResults = $allResults
            if ($DeduplicateResults -and $allResults.Count -gt 1) {
                Write-Verbose "Starting deduplication with threshold: $DeduplicationThreshold"
                $finalResults = Remove-DuplicateFindings -Results $allResults -Threshold $DeduplicationThreshold
                Write-Verbose "Deduplication complete: $($allResults.Count) -> $($finalResults.Count) results"
            }
            
            # Create merged SARIF document
            $mergedSarif = [PSCustomObject]@{
                version = $sarifVersion
                runs = @([PSCustomObject]@{
                    tool = [PSCustomObject]@{
                        driver = [PSCustomObject]@{
                            name = 'Unity-Claude-RepoAnalyst'
                            fullName = 'Unity-Claude Repository Analyst - Static Analysis Suite'
                            version = '1.0.0'
                            informationUri = 'https://github.com/unity-claude/repo-analyst'
                            rules = @()  # Rules will be aggregated from individual tools
                        }
                        extensions = @()
                    }
                    results = $finalResults
                    columnKind = 'unicodeCodePoints'
                })
            }
            
            # Aggregate rules from all tools
            $allRules = @{}
            $ruleArray = @()
            
            foreach ($run in $allRuns) {
                if ($run.tool.driver.rules) {
                    foreach ($rule in $run.tool.driver.rules) {
                        $qualifiedRuleId = "$($run.tool.driver.name).$($rule.id)"
                        if (-not $allRules[$qualifiedRuleId]) {
                            $enhancedRule = $rule.PSObject.Copy()
                            $enhancedRule.id = $qualifiedRuleId
                            $enhancedRule | Add-Member -NotePropertyName 'toolOrigin' -NotePropertyValue $run.tool.driver.name -Force
                            
                            $allRules[$qualifiedRuleId] = $enhancedRule
                            $ruleArray += $enhancedRule
                        }
                    }
                }
            }
            
            $mergedSarif.runs[0].tool.driver.rules = $ruleArray
            
            # Add execution metadata
            $mergedSarif.runs[0] | Add-Member -NotePropertyName 'invocations' -NotePropertyValue @([PSCustomObject]@{
                executionSuccessful = $true
                startTimeUtc = $mergeTimestamp.ToUniversalTime().ToString('o')
                endTimeUtc = (Get-Date).ToUniversalTime().ToString('o')
                machine = $env:COMPUTERNAME
                commandLine = 'Merge-SarifResults'
                toolConfiguration = [PSCustomObject]@{
                    deduplicationEnabled = $DeduplicateResults.IsPresent
                    deduplicationThreshold = $DeduplicationThreshold
                    toolsIncluded = ($toolStats.Keys | Sort-Object) -join ', '
                }
            })
            
            # Add comprehensive metrics if requested
            if ($IncludeMetrics) {
                $topFiles = $fileStats.GetEnumerator() | 
                           Sort-Object { $_.Value.totalIssues } -Descending | 
                           Select-Object -First 10
                
                $topRules = $ruleStats.GetEnumerator() | 
                           Sort-Object Value -Descending | 
                           Select-Object -First 15
                
                $mergedSarif.runs[0] | Add-Member -NotePropertyName 'properties' -NotePropertyValue ([PSCustomObject]@{
                    analysisMetrics = [PSCustomObject]@{
                        totalResults = $finalResults.Count
                        originalResults = $allResults.Count
                        deduplicatedCount = if ($DeduplicateResults) { $allResults.Count - $finalResults.Count } else { 0 }
                        toolsUsed = $toolStats.Count
                        rulesTriggered = $ruleStats.Count
                        filesAnalyzed = $fileStats.Count
                        
                        severityDistribution = $severityStats
                        toolDistribution = $toolStats
                        
                        topIssueFiles = @($topFiles | ForEach-Object { 
                            [PSCustomObject]@{
                                file = $_.Key
                                issues = $_.Value.totalIssues
                                tools = ($_.Value.tools.Keys | Sort-Object) -join ', '
                            }
                        })
                        
                        topTriggeredRules = @($topRules | ForEach-Object {
                            [PSCustomObject]@{
                                rule = $_.Key
                                count = $_.Value
                            }
                        })
                        
                        qualityScore = Calculate-QualityScore -Results $finalResults -FileStats $fileStats
                    }
                })
            }
            
            # Save to file if requested
            if ($OutputPath) {
                $jsonOutput = $mergedSarif | ConvertTo-Json -Depth 10 -Compress:$false
                Set-Content -Path $OutputPath -Value $jsonOutput -Encoding UTF8
                Write-Verbose "Merged SARIF results saved to: $OutputPath"
            }
            
            Write-Verbose "SARIF merge complete: $($finalResults.Count) total results from $($toolStats.Count) tools"
            
            return $mergedSarif
            
        } catch {
            Write-Error "SARIF results merge failed: $_"
            throw
        }
    }
    
    end {
        Write-Verbose "SARIF results merge completed"
    }
}

function Remove-DuplicateFindings {
    <#
    .SYNOPSIS
    Removes duplicate findings using similarity analysis
    #>
    [CmdletBinding()]
    param(
        [array]$Results,
        [double]$Threshold = 0.8
    )
    
    $uniqueResults = @()
    $processedResults = @()
    
    foreach ($result in $Results) {
        $isDuplicate = $false
        
        foreach ($processed in $processedResults) {
            $similarity = Calculate-ResultSimilarity -Result1 $result -Result2 $processed
            if ($similarity -ge $Threshold) {
                $isDuplicate = $true
                # Enhance the existing result with additional tool information
                if (-not $processed.duplicateTools) {
                    $processed | Add-Member -NotePropertyName 'duplicateTools' -NotePropertyValue @()
                }
                $processed.duplicateTools += $result.toolName
                break
            }
        }
        
        if (-not $isDuplicate) {
            $processedResults += $result
            $uniqueResults += $result
        }
    }
    
    return $uniqueResults
}

function Calculate-ResultSimilarity {
    <#
    .SYNOPSIS
    Calculates similarity between two SARIF results
    #>
    [CmdletBinding()]
    param(
        $Result1,
        $Result2
    )
    
    $similarity = 0.0
    $factors = 0
    
    # File path similarity (30% weight)
    if ($Result1.locations -and $Result2.locations) {
        $file1 = $Result1.locations[0].physicalLocation.artifactLocation.uri
        $file2 = $Result2.locations[0].physicalLocation.artifactLocation.uri
        
        if ($file1 -eq $file2) {
            $similarity += 0.3
        }
        $factors++
    }
    
    # Line number proximity (25% weight)
    if ($Result1.locations -and $Result2.locations) {
        $line1 = $Result1.locations[0].physicalLocation.region.startLine
        $line2 = $Result2.locations[0].physicalLocation.region.startLine
        
        $lineDiff = [Math]::Abs($line1 - $line2)
        if ($lineDiff -eq 0) {
            $similarity += 0.25
        } elseif ($lineDiff -le 2) {
            $similarity += 0.15
        } elseif ($lineDiff -le 5) {
            $similarity += 0.05
        }
        $factors++
    }
    
    # Message similarity (25% weight)
    if ($Result1.message.text -and $Result2.message.text) {
        $msgSimilarity = Calculate-StringSimilarity -String1 $Result1.message.text -String2 $Result2.message.text
        $similarity += ($msgSimilarity * 0.25)
        $factors++
    }
    
    # Rule category similarity (20% weight)
    if ($Result1.ruleId -and $Result2.ruleId) {
        # Extract base rule names (remove tool prefixes)
        $rule1 = ($Result1.ruleId -split '\.')[-1]
        $rule2 = ($Result2.ruleId -split '\.')[-1]
        
        if ($rule1 -eq $rule2) {
            $similarity += 0.2
        } elseif ($rule1 -like "*$rule2*" -or $rule2 -like "*$rule1*") {
            $similarity += 0.1
        }
        $factors++
    }
    
    return if ($factors -gt 0) { $similarity } else { 0.0 }
}

function Calculate-StringSimilarity {
    <#
    .SYNOPSIS
    Calculates Levenshtein distance-based similarity between strings
    #>
    [CmdletBinding()]
    param(
        [string]$String1,
        [string]$String2
    )
    
    if (-not $String1 -or -not $String2) { return 0.0 }
    if ($String1 -eq $String2) { return 1.0 }
    
    $len1 = $String1.Length
    $len2 = $String2.Length
    $maxLen = [Math]::Max($len1, $len2)
    
    if ($maxLen -eq 0) { return 1.0 }
    
    # Simple similarity for performance
    $commonWords = 0
    $words1 = $String1.ToLower() -split '\W+' | Where-Object { $_.Length -gt 2 }
    $words2 = $String2.ToLower() -split '\W+' | Where-Object { $_.Length -gt 2 }
    
    foreach ($word1 in $words1) {
        if ($words2 -contains $word1) {
            $commonWords++
        }
    }
    
    $totalWords = [Math]::Max($words1.Count, $words2.Count)
    return if ($totalWords -gt 0) { $commonWords / $totalWords } else { 0.0 }
}

function Calculate-QualityScore {
    <#
    .SYNOPSIS
    Calculates a code quality score based on analysis results
    #>
    [CmdletBinding()]
    param(
        [array]$Results,
        [hashtable]$FileStats
    )
    
    if ($Results.Count -eq 0) { return 100.0 }
    
    # Base score
    $score = 100.0
    
    # Deduct points for issues
    $errorWeight = 10.0
    $warningWeight = 5.0
    $noteWeight = 1.0
    
    foreach ($result in $Results) {
        switch ($result.level) {
            'error' { $score -= $errorWeight }
            'warning' { $score -= $warningWeight }
            'note' { $score -= $noteWeight }
        }
    }
    
    # Normalize by file count
    $fileCount = [Math]::Max($FileStats.Count, 1)
    $score = $score / [Math]::Sqrt($fileCount) * 100
    
    return [Math]::Max([Math]::Round($score, 1), 0.0)
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCEqkiyNUrSKLxj
# QruKyicytugrI+VYjSxEW7vBAthF6qCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIAGFOmtu4rAOS1Ny+h0rFF+Q
# 1R8xYWSzTgvHj+aXhKk6MA0GCSqGSIb3DQEBAQUABIIBACLZ0oi0yfr9GEk0O4Vg
# 31TqaYxJKTRCIO0d3Ja/N3Bzn7HLRNHBRlR6ImXOZ6+PDFBlMbW4oU711HMTA3t3
# SjnaWFF/o+lfD1yZRwkhO08fp7btk8TxSf0ytSa4celqIkZg9vL/3CldyoyOoojX
# Mllp3X0Asr8WL0w4kYlWuDgP7nXydoL5dNK8+7RdcG2n+Uz0ftGFD+DJMxoHIeg6
# L8E/dWES9JiY82kreTb3jsudux/x1QI7VoCrKHBGU62TxmJNLdD+Ht4VbaOkCJc7
# ghNY5q+xm5E9Sb/k5ZgLw731Lk4dqGjRyBGi2aKwfi/hzTxb1r2NsFbapO5cGJAv
# CUQ=
# SIG # End signature block
