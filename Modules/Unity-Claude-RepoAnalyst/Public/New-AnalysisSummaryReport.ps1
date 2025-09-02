function New-AnalysisSummaryReport {
    <#
    .SYNOPSIS
    Generates human-readable summary reports from SARIF analysis results
    
    .DESCRIPTION
    Converts SARIF static analysis results into comprehensive, human-readable
    reports with actionable insights, prioritized issues, and recommendations
    
    .PARAMETER SarifResults
    SARIF analysis results object or path to SARIF file
    
    .PARAMETER OutputFormat
    Output format: Console, Markdown, HTML, or PDF
    
    .PARAMETER IncludePriorities
    Include prioritized action items based on severity
    
    .PARAMETER IncludeRecommendations
    Generate fix recommendations for common issues
    
    .PARAMETER TopIssues
    Number of top issues to highlight (default 10)
    
    .EXAMPLE
    $results = Invoke-StaticAnalysis -Path "."
    New-AnalysisSummaryReport -SarifResults $results -OutputFormat Markdown
    
    .EXAMPLE
    New-AnalysisSummaryReport -SarifResults "analysis.sarif" -OutputFormat HTML -IncludeRecommendations
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $SarifResults,
        
        [Parameter()]
        [ValidateSet('Console', 'Markdown', 'HTML', 'PDF')]
        [string]$OutputFormat = 'Console',
        
        [Parameter()]
        [switch]$IncludePriorities = $true,
        
        [Parameter()]
        [switch]$IncludeRecommendations = $true,
        
        [Parameter()]
        [int]$TopIssues = 10,
        
        [Parameter()]
        [string]$OutputPath,
        
        [Parameter()]
        [string]$ProjectName = (Split-Path -Leaf (Get-Location))
    )
    
    begin {
        Write-Verbose "Generating analysis summary report"
        
        # Load SARIF data if file path provided
        if ($SarifResults -is [string]) {
            if (Test-Path $SarifResults) {
                $SarifResults = Get-Content $SarifResults -Raw | ConvertFrom-Json
            } else {
                throw "SARIF file not found: $SarifResults"
            }
        }
        
        # Initialize report structure
        $report = @{
            ProjectName = $ProjectName
            Timestamp = Get-Date
            Summary = @{
                TotalIssues = 0
                BySeverity = @{
                    Error = 0
                    Warning = 0
                    Note = 0
                }
                ByTool = @{}
                ByCategory = @{}
                FilesAnalyzed = @()
                TopRules = @()
            }
            Details = @{
                CriticalIssues = @()
                HighPriorityFiles = @()
                CommonPatterns = @{}
            }
            Recommendations = @()
            ActionItems = @()
        }
    }
    
    process {
        # Process SARIF results
        foreach ($run in $SarifResults.runs) {
            $toolName = $run.tool.driver.name
            if (-not $report.Summary.ByTool.ContainsKey($toolName)) {
                $report.Summary.ByTool[$toolName] = @{
                    Total = 0
                    Errors = 0
                    Warnings = 0
                    Notes = 0
                    Rules = @{}
                }
            }
            
            # Process each result
            foreach ($result in $run.results) {
                $report.Summary.TotalIssues++
                $report.Summary.ByTool[$toolName].Total++
                
                # Count by severity
                switch ($result.level) {
                    'error' { 
                        $report.Summary.BySeverity.Error++
                        $report.Summary.ByTool[$toolName].Errors++
                        
                        # Add to critical issues
                        $report.Details.CriticalIssues += @{
                            Rule = $result.ruleId
                            Message = $result.message.text
                            Location = if ($result.locations) {
                                $loc = $result.locations[0].physicalLocation
                                "$($loc.artifactLocation.uri):$($loc.region.startLine)"
                            } else { "Unknown" }
                            Tool = $toolName
                        }
                    }
                    'warning' { 
                        $report.Summary.BySeverity.Warning++
                        $report.Summary.ByTool[$toolName].Warnings++
                    }
                    'note' { 
                        $report.Summary.BySeverity.Note++
                        $report.Summary.ByTool[$toolName].Notes++
                    }
                }
                
                # Track rules
                $ruleId = $result.ruleId
                if (-not $report.Summary.ByTool[$toolName].Rules.ContainsKey($ruleId)) {
                    $report.Summary.ByTool[$toolName].Rules[$ruleId] = 0
                }
                $report.Summary.ByTool[$toolName].Rules[$ruleId]++
                
                # Track files
                if ($result.locations -and $result.locations[0].physicalLocation) {
                    $filePath = $result.locations[0].physicalLocation.artifactLocation.uri
                    if ($filePath -and $report.Summary.FilesAnalyzed -notcontains $filePath) {
                        $report.Summary.FilesAnalyzed += $filePath
                    }
                }
            }
        }
        
        # Calculate top rules across all tools
        $allRules = @{}
        foreach ($tool in $report.Summary.ByTool.Values) {
            foreach ($rule in $tool.Rules.GetEnumerator()) {
                if (-not $allRules.ContainsKey($rule.Key)) {
                    $allRules[$rule.Key] = 0
                }
                $allRules[$rule.Key] += $rule.Value
            }
        }
        
        $report.Summary.TopRules = $allRules.GetEnumerator() | 
            Sort-Object Value -Descending | 
            Select-Object -First $TopIssues
        
        # Identify high-priority files (files with most issues)
        $fileIssues = @{}
        foreach ($run in $SarifResults.runs) {
            foreach ($result in $run.results) {
                if ($result.locations -and $result.locations[0].physicalLocation) {
                    $filePath = $result.locations[0].physicalLocation.artifactLocation.uri
                    if (-not $fileIssues.ContainsKey($filePath)) {
                        $fileIssues[$filePath] = @{
                            Count = 0
                            Errors = 0
                            Warnings = 0
                        }
                    }
                    $fileIssues[$filePath].Count++
                    if ($result.level -eq 'error') { $fileIssues[$filePath].Errors++ }
                    if ($result.level -eq 'warning') { $fileIssues[$filePath].Warnings++ }
                }
            }
        }
        
        $report.Details.HighPriorityFiles = $fileIssues.GetEnumerator() | 
            Sort-Object { $_.Value.Errors * 10 + $_.Value.Warnings * 3 + $_.Value.Count } -Descending | 
            Select-Object -First 10
        
        # Generate recommendations if requested
        if ($IncludeRecommendations) {
            # PowerShell specific recommendations
            if ($allRules['PSUseDeclaredVarsMoreThanAssignments'] -gt 0) {
                $report.Recommendations += "Remove unused variables to improve code clarity and performance"
            }
            if ($allRules['PSAvoidUsingWriteHost'] -gt 0) {
                $report.Recommendations += "Replace Write-Host with Write-Output or Write-Information for better stream handling"
            }
            
            # JavaScript/TypeScript recommendations
            if ($allRules['no-unused-vars'] -gt 0) {
                $report.Recommendations += "Remove unused variables and imports in JavaScript/TypeScript files"
            }
            if ($allRules['no-console'] -gt 0) {
                $report.Recommendations += "Remove or replace console.log statements with proper logging"
            }
            
            # Python recommendations
            if ($allRules['unused-variable'] -gt 0) {
                $report.Recommendations += "Clean up unused Python variables and imports"
            }
            
            # General recommendations based on severity
            if ($report.Summary.BySeverity.Error -gt 0) {
                $report.Recommendations += "Priority: Fix all $($report.Summary.BySeverity.Error) errors before addressing warnings"
            }
            if ($report.Summary.BySeverity.Warning -gt 50) {
                $report.Recommendations += "Consider setting up pre-commit hooks to catch issues earlier"
            }
        }
        
        # Generate prioritized action items
        if ($IncludePriorities) {
            # Critical: All errors
            if ($report.Summary.BySeverity.Error -gt 0) {
                $report.ActionItems += @{
                    Priority = "Critical"
                    Action = "Fix $($report.Summary.BySeverity.Error) error(s)"
                    Details = $report.Details.CriticalIssues | Select-Object -First 5
                }
            }
            
            # High: Files with multiple issues
            $problematicFiles = $report.Details.HighPriorityFiles | Where-Object { $_.Value.Count -gt 10 }
            if ($problematicFiles) {
                $report.ActionItems += @{
                    Priority = "High"
                    Action = "Refactor files with excessive issues"
                    Details = $problematicFiles | Select-Object -First 3 | ForEach-Object { "$($_.Key): $($_.Value.Count) issues" }
                }
            }
            
            # Medium: Common patterns
            foreach ($rule in $report.Summary.TopRules | Select-Object -First 3) {
                if ($rule.Value -gt 5) {
                    $report.ActionItems += @{
                        Priority = "Medium"
                        Action = "Address pattern: $($rule.Name)"
                        Details = "$($rule.Value) occurrences across codebase"
                    }
                }
            }
        }
    }
    
    end {
        # Generate output based on format
        switch ($OutputFormat) {
            'Console' {
                Write-Host "`n" ("=" * 70) -ForegroundColor Cyan
                Write-Host " Static Analysis Summary Report" -ForegroundColor Cyan
                Write-Host ("=" * 70) -ForegroundColor Cyan
                
                Write-Host "`nProject: $($report.ProjectName)" -ForegroundColor White
                Write-Host "Generated: $($report.Timestamp.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
                Write-Host "Files Analyzed: $($report.Summary.FilesAnalyzed.Count)" -ForegroundColor Gray
                
                # Executive Summary
                Write-Host "`n[EXECUTIVE SUMMARY]" -ForegroundColor Yellow
                Write-Host "Total Issues: $($report.Summary.TotalIssues)" -ForegroundColor White
                
                # Severity breakdown with color coding
                Write-Host "`nBy Severity:" -ForegroundColor Gray
                Write-Host ("  Errors:   {0,5} " -f $report.Summary.BySeverity.Error) -NoNewline
                Write-Host ("█" * [Math]::Min(20, $report.Summary.BySeverity.Error)) -ForegroundColor Red
                Write-Host ("  Warnings: {0,5} " -f $report.Summary.BySeverity.Warning) -NoNewline
                Write-Host ("█" * [Math]::Min(20, $report.Summary.BySeverity.Warning / 2)) -ForegroundColor Yellow
                Write-Host ("  Notes:    {0,5} " -f $report.Summary.BySeverity.Note) -NoNewline
                Write-Host ("█" * [Math]::Min(20, $report.Summary.BySeverity.Note / 3)) -ForegroundColor Gray
                
                # Tool breakdown
                Write-Host "`nBy Tool:" -ForegroundColor Gray
                foreach ($tool in $report.Summary.ByTool.GetEnumerator()) {
                    Write-Host "  $($tool.Key): $($tool.Value.Total) issues" -ForegroundColor White
                }
                
                # Critical issues
                if ($report.Details.CriticalIssues.Count -gt 0) {
                    Write-Host "`n[CRITICAL ISSUES] ⚠️" -ForegroundColor Red
                    foreach ($issue in $report.Details.CriticalIssues | Select-Object -First 5) {
                        Write-Host "  • [$($issue.Tool)] $($issue.Rule)" -ForegroundColor Red
                        Write-Host "    $($issue.Location): $($issue.Message.Substring(0, [Math]::Min(80, $issue.Message.Length)))" -ForegroundColor Gray
                    }
                    if ($report.Details.CriticalIssues.Count -gt 5) {
                        Write-Host "  ... and $($report.Details.CriticalIssues.Count - 5) more" -ForegroundColor Gray
                    }
                }
                
                # Top issues
                Write-Host "`n[TOP ISSUES]" -ForegroundColor Yellow
                foreach ($rule in $report.Summary.TopRules | Select-Object -First 5) {
                    $barLength = [Math]::Min(30, $rule.Value)
                    Write-Host ("  {0,-40} [{1,3}] " -f $rule.Name, $rule.Value) -NoNewline
                    Write-Host ("▓" * $barLength) -ForegroundColor DarkCyan
                }
                
                # High-priority files
                if ($report.Details.HighPriorityFiles.Count -gt 0) {
                    Write-Host "`n[FILES NEEDING ATTENTION]" -ForegroundColor Yellow
                    foreach ($file in $report.Details.HighPriorityFiles | Select-Object -First 5) {
                        $fileName = Split-Path -Leaf $file.Key
                        Write-Host ("  {0,-30} Issues: {1,3} (E:{2} W:{3})" -f 
                            $fileName, 
                            $file.Value.Count, 
                            $file.Value.Errors, 
                            $file.Value.Warnings) -ForegroundColor White
                    }
                }
                
                # Recommendations
                if ($report.Recommendations.Count -gt 0) {
                    Write-Host "`n[RECOMMENDATIONS]" -ForegroundColor Green
                    foreach ($rec in $report.Recommendations) {
                        Write-Host "  ✓ $rec" -ForegroundColor Green
                    }
                }
                
                # Action items
                if ($report.ActionItems.Count -gt 0) {
                    Write-Host "`n[PRIORITIZED ACTION ITEMS]" -ForegroundColor Magenta
                    foreach ($item in $report.ActionItems | Sort-Object { 
                        switch($_.Priority) { 'Critical' {1} 'High' {2} 'Medium' {3} default {4} }
                    }) {
                        $priorityColor = switch($item.Priority) {
                            'Critical' { 'Red' }
                            'High' { 'Yellow' }
                            'Medium' { 'Cyan' }
                            default { 'Gray' }
                        }
                        Write-Host "  [$($item.Priority)]" -ForegroundColor $priorityColor -NoNewline
                        Write-Host " $($item.Action)" -ForegroundColor White
                        if ($item.Details) {
                            if ($item.Details -is [array]) {
                                foreach ($detail in $item.Details) {
                                    if ($detail -is [string]) {
                                        Write-Host "    - $detail" -ForegroundColor Gray
                                    } else {
                                        Write-Host "    - $($detail.Rule): $($detail.Location)" -ForegroundColor Gray
                                    }
                                }
                            } else {
                                Write-Host "    - $($item.Details)" -ForegroundColor Gray
                            }
                        }
                    }
                }
                
                # Summary footer
                Write-Host "`n" ("=" * 70) -ForegroundColor Cyan
                $qualityScore = [Math]::Max(0, 100 - ($report.Summary.BySeverity.Error * 10) - ($report.Summary.BySeverity.Warning * 2))
                $qualityGrade = switch ($qualityScore) {
                    {$_ -ge 90} { "A" }
                    {$_ -ge 80} { "B" }
                    {$_ -ge 70} { "C" }
                    {$_ -ge 60} { "D" }
                    default { "F" }
                }
                Write-Host "Code Quality Score: $qualityScore/100 (Grade: $qualityGrade)" -ForegroundColor $(
                    switch ($qualityGrade) {
                        'A' { 'Green' }
                        'B' { 'DarkGreen' }
                        'C' { 'Yellow' }
                        'D' { 'DarkYellow' }
                        'F' { 'Red' }
                    }
                )
            }
            
            'Markdown' {
                $markdown = @"
# Static Analysis Summary Report

**Project**: $($report.ProjectName)  
**Generated**: $($report.Timestamp.ToString('yyyy-MM-dd HH:mm:ss'))  
**Files Analyzed**: $($report.Summary.FilesAnalyzed.Count)

## Executive Summary

**Total Issues**: $($report.Summary.TotalIssues)

### Severity Breakdown

| Severity | Count | Visual |
|----------|-------|--------|
| 🔴 Errors | $($report.Summary.BySeverity.Error) | $("█" * [Math]::Min(20, $report.Summary.BySeverity.Error)) |
| 🟡 Warnings | $($report.Summary.BySeverity.Warning) | $("█" * [Math]::Min(20, $report.Summary.BySeverity.Warning / 2)) |
| 🔵 Notes | $($report.Summary.BySeverity.Note) | $("█" * [Math]::Min(20, $report.Summary.BySeverity.Note / 3)) |

### Analysis Tools

| Tool | Total | Errors | Warnings | Notes |
|------|-------|--------|----------|-------|
"@
                foreach ($tool in $report.Summary.ByTool.GetEnumerator()) {
                    $markdown += "| $($tool.Key) | $($tool.Value.Total) | $($tool.Value.Errors) | $($tool.Value.Warnings) | $($tool.Value.Notes) |`n"
                }
                
                if ($report.Details.CriticalIssues.Count -gt 0) {
                    $markdown += @"

## ⚠️ Critical Issues

| Tool | Rule | Location | Message |
|------|------|----------|---------|
"@
                    foreach ($issue in $report.Details.CriticalIssues | Select-Object -First 10) {
                        $message = $issue.Message.Replace("|", "\|")
                        if ($message.Length -gt 60) { $message = $message.Substring(0, 57) + "..." }
                        $markdown += "| $($issue.Tool) | $($issue.Rule) | $($issue.Location) | $message |`n"
                    }
                }
                
                $markdown += @"

## Top Issues

| Rule | Occurrences |
|------|-------------|
"@
                foreach ($rule in $report.Summary.TopRules | Select-Object -First 10) {
                    $markdown += "| ``$($rule.Name)`` | $($rule.Value) |`n"
                }
                
                if ($report.Details.HighPriorityFiles.Count -gt 0) {
                    $markdown += @"

## Files Needing Attention

| File | Total Issues | Errors | Warnings |
|------|--------------|--------|----------|
"@
                    foreach ($file in $report.Details.HighPriorityFiles | Select-Object -First 10) {
                        $fileName = Split-Path -Leaf $file.Key
                        $markdown += "| $fileName | $($file.Value.Count) | $($file.Value.Errors) | $($file.Value.Warnings) |`n"
                    }
                }
                
                if ($report.Recommendations.Count -gt 0) {
                    $markdown += "`n## 📋 Recommendations`n`n"
                    foreach ($rec in $report.Recommendations) {
                        $markdown += "- ✅ $rec`n"
                    }
                }
                
                if ($report.ActionItems.Count -gt 0) {
                    $markdown += "`n## 🎯 Prioritized Action Items`n`n"
                    foreach ($item in $report.ActionItems | Sort-Object { 
                        switch($_.Priority) { 'Critical' {1} 'High' {2} 'Medium' {3} default {4} }
                    }) {
                        $emoji = switch($item.Priority) {
                            'Critical' { '🔴' }
                            'High' { '🟠' }
                            'Medium' { '🟡' }
                            default { '⚪' }
                        }
                        $markdown += "`n### $emoji [$($item.Priority)] $($item.Action)`n`n"
                        if ($item.Details) {
                            if ($item.Details -is [array]) {
                                foreach ($detail in $item.Details) {
                                    if ($detail -is [string]) {
                                        $markdown += "- $detail`n"
                                    } else {
                                        $markdown += "- **$($detail.Rule)**: $($detail.Location)`n"
                                    }
                                }
                            } else {
                                $markdown += "$($item.Details)`n"
                            }
                        }
                    }
                }
                
                # Quality score
                $qualityScore = [Math]::Max(0, 100 - ($report.Summary.BySeverity.Error * 10) - ($report.Summary.BySeverity.Warning * 2))
                $qualityGrade = switch ($qualityScore) {
                    {$_ -ge 90} { "A" }
                    {$_ -ge 80} { "B" }
                    {$_ -ge 70} { "C" }
                    {$_ -ge 60} { "D" }
                    default { "F" }
                }
                
                $markdown += @"

---

## Code Quality Score

**Score**: $qualityScore/100  
**Grade**: $qualityGrade

"@
                
                if ($OutputPath) {
                    $markdown | Out-File -FilePath $OutputPath -Encoding UTF8
                    Write-Host "Markdown report saved to: $OutputPath" -ForegroundColor Green
                } else {
                    Write-Output $markdown
                }
            }
            
            'HTML' {
                # HTML output similar to trend report but focused on current state
                # Implementation would be similar to the HTML section in New-AnalysisTrendReport
                Write-Warning "HTML output format not fully implemented. Use Markdown or Console for now."
            }
            
            'PDF' {
                Write-Warning "PDF output requires additional dependencies. Use Markdown and convert with pandoc."
            }
        }
        
        return $report
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBhYey7H5pEHRJY
# X4SLbTlWu9nkBm2SJaaqZ2Om6CUrmaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIFgZwymALWhxG7ZENwJIl52L
# YgLW4Ez3UO51qrGs1ZqhMA0GCSqGSIb3DQEBAQUABIIBAGBDL0EGDdRBsI9RCL9b
# e1NLCM4YPqROVfjBAKiT8KSRTPXhoBTC4AXV1GTmpM2xb8yWI//ge6DsWWzvUpT6
# Y7WN0wL7h5bnQZBwmG/mQLlXIARVbPhS1mSav2ktSGU0CjyhlaFW8nqINorwp8v+
# aMX7ASry0Wh/e1Vw+1z54dBZRsGALTLtZKxPXk79Xy+SPQ02sFkjLee+qzuZas0M
# 2VX93mF5SHYxIamtVm3kh//t4OUyRwgtPxI4Tui1PpqO5r7ptbJ2caUneIGPxFaL
# gQH59NgEEISW9rFqQQAYy4ItaEKpIpK82wh5N36/oEEbb5TeYuLT1jnZDGYdHpKw
# 6yE=
# SIG # End signature block
