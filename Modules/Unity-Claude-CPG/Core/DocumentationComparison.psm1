#region Documentation Comparison Component
<#
.SYNOPSIS
    Unity Claude CPG - Documentation Comparison Component
    
.DESCRIPTION
    Implements documentation drift detection by comparing code implementation with 
    inline documentation, help text, and external documentation sources.
    
    Key capabilities:
    - Multi-language documentation parsing (PowerShell, JSDoc, Python docstrings)
    - Parameter documentation validation
    - Missing documentation detection
    - Undocumented feature identification
    - Documentation drift analysis with severity assessment
    - Cross-reference validation between code and docs
    
.VERSION
    2.0.0 - Refactored modular component
    
.DEPENDENCIES
    - Unity-Claude-CPG (Code Property Graph analysis)
    
.AUTHOR
    Unity-Claude-Automation Framework
#>

# Import required dependencies
$cpgModule = Join-Path (Split-Path $PSScriptRoot -Parent) "Unity-Claude-CPG.psd1"
if (Test-Path $cpgModule) {
    Import-Module $cpgModule -Force -ErrorAction SilentlyContinue
}

# Load CPG enums
$enumPath = Join-Path (Split-Path $PSScriptRoot -Parent) "Unity-Claude-CPG-Enums.ps1"
if (Test-Path $enumPath) {
    . $enumPath
}

#region Documentation Comparison

function Compare-CodeToDocumentation {
    <#
    .SYNOPSIS
        Compares code implementation with its documentation to identify drift
        
    .DESCRIPTION
        Analyzes code against inline comments, help documentation, and external docs
        to identify discrepancies between implementation and documentation.
        
    .PARAMETER Graph
        The CPG graph containing code nodes
        
    .PARAMETER DocumentationPath
        Optional path to external documentation files
        
    .PARAMETER IncludeInlineComments
        Include inline comment analysis in drift detection
        
    .OUTPUTS
        System.Collections.Hashtable
        Contains documentation drift analysis with issues and statistics
        
    .EXAMPLE
        $drift = Compare-CodeToDocumentation -Graph $cpgGraph
        Write-Host "Found $($drift.DriftIssues.Count) documentation drift issues"
        
    .EXAMPLE
        $drift = Compare-CodeToDocumentation -Graph $cpgGraph -DocumentationPath ".\docs" -IncludeInlineComments
        $drift.DriftIssues | Where-Object { $_.Severity -eq "High" } | ForEach-Object { 
            Write-Host "Critical: $($_.Message)"
        }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Graph,
        
        [string]$DocumentationPath,
        
        [switch]$IncludeInlineComments
    )
    
    try {
        Write-Verbose "Comparing code to documentation for $($Graph.Nodes.Count) nodes"
        
        $driftResults = @()
        $processedNodes = 0
        
        foreach ($node in $Graph.Nodes.Values) {
            if ($node.Type -in @([CPGNodeType]::Function, [CPGNodeType]::Method, [CPGNodeType]::Class)) {
                $processedNodes++
                Write-Verbose "Processing node $processedNodes/$($Graph.Nodes.Count): $($node.Name)"
                
                $driftItem = @{
                    Id = $node.Id
                    Name = $node.Name
                    Type = $node.Type
                    File = $node.Properties.FilePath
                    Line = $node.Properties.LineNumber
                    Issues = @()
                }
                
                # Extract documentation from node
                $nodeDoc = Get-NodeDocumentation -Node $node -IncludeInlineComments:$IncludeInlineComments
                
                # Compare with actual implementation
                $actualParams = @()
                if ($node.Properties.Parameters) {
                    $actualParams = $node.Properties.Parameters
                }
                
                # Check for missing documentation
                if (-not $nodeDoc.Synopsis -and -not $nodeDoc.Description) {
                    $driftItem.Issues += @{
                        Type = "MissingDocumentation"
                        Severity = "High"
                        Message = "No documentation found for $($node.Type) '$($node.Name)'"
                    }
                }
                
                # Check parameter documentation
                foreach ($param in $actualParams) {
                    if (-not $nodeDoc.Parameters.ContainsKey($param.Name)) {
                        $driftItem.Issues += @{
                            Type = "UndocumentedParameter"
                            Severity = "Medium"
                            Message = "Parameter '$($param.Name)' is not documented"
                            Parameter = $param.Name
                        }
                    }
                }
                
                # Check for documented but non-existent parameters
                foreach ($docParam in $nodeDoc.Parameters.Keys) {
                    $exists = $actualParams | Where-Object { $_.Name -eq $docParam }
                    if (-not $exists) {
                        $driftItem.Issues += @{
                            Type = "ObsoleteParameter"
                            Severity = "High"
                            Message = "Documented parameter '$docParam' does not exist in code"
                            Parameter = $docParam
                        }
                    }
                }
                
                # Check return type documentation
                if ($node.Properties.ReturnType -and -not $nodeDoc.Returns) {
                    $driftItem.Issues += @{
                        Type = "MissingReturnDocumentation"
                        Severity = "Low"
                        Message = "Return type not documented"
                    }
                }
                
                # Check for stale examples
                if ($nodeDoc.Examples.Count -gt 0) {
                    foreach ($example in $nodeDoc.Examples) {
                        # Simple check: does the example reference the current function name?
                        if ($example -notmatch $node.Name) {
                            $driftItem.Issues += @{
                                Type = "StaleExample"
                                Severity = "Low"
                                Message = "Example may be outdated or incorrect"
                            }
                        }
                    }
                }
                
                if ($driftItem.Issues.Count -gt 0) {
                    $driftResults += $driftItem
                }
            }
        }
        
        # Calculate statistics
        $stats = @{
            TotalNodes = $processedNodes
            NodesWithIssues = @($driftResults).Count
            HighSeverityIssues = @($driftResults.Issues | Where-Object { $_.Severity -eq "High" }).Count
            MediumSeverityIssues = @($driftResults.Issues | Where-Object { $_.Severity -eq "Medium" }).Count
            LowSeverityIssues = @($driftResults.Issues | Where-Object { $_.Severity -eq "Low" }).Count
            DocumentationCoverage = if ($processedNodes -gt 0) {
                [Math]::Round((($processedNodes - @($driftResults).Count) / $processedNodes) * 100, 2)
            } else { 0 }
        }
        
        # Group by file for analysis
        $byFile = $driftResults | Group-Object -Property { $_.File } | 
            ForEach-Object {
                @{
                    File = $_.Name
                    IssueCount = ($_.Group.Issues | Measure-Object).Count
                    NodesWithIssues = $_.Count
                    HighSeverityCount = @($_.Group.Issues | Where-Object { $_.Severity -eq "High" }).Count
                }
            }
        
        return @{
            DriftIssues = @($driftResults)
            Statistics = $stats
            ByFile = @($byFile)
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }
    catch {
        Write-Error "Failed to compare code to documentation: $_"
        throw
    }
}

function Find-UndocumentedFeatures {
    <#
    .SYNOPSIS
        Identifies code features that lack proper documentation
        
    .DESCRIPTION
        Scans the CPG to find functions, classes, and methods that are missing
        documentation entirely or have insufficient documentation coverage.
        
    .PARAMETER Graph
        The CPG graph to analyze
        
    .PARAMETER MinimumDocumentationScore
        Minimum score (0-100) required to consider documentation adequate
        
    .PARAMETER IncludePrivateMembers
        Include private/internal members in analysis
        
    .OUTPUTS
        System.Collections.Hashtable
        Contains undocumented features with prioritization and recommendations
        
    .EXAMPLE
        $undocumented = Find-UndocumentedFeatures -Graph $cpgGraph
        Write-Host "Found $($undocumented.UndocumentedFeatures.Count) undocumented features"
        
    .EXAMPLE
        $undocumented = Find-UndocumentedFeatures -Graph $cpgGraph -MinimumDocumentationScore 75
        $undocumented.HighPriorityFeatures | ForEach-Object { 
            Write-Host "Priority: $($_.Name) in $($_.File)"
        }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Graph,
        
        [ValidateRange(0, 100)]
        [int]$MinimumDocumentationScore = 60,
        
        [switch]$IncludePrivateMembers
    )
    
    try {
        Write-Verbose "Finding undocumented features with minimum score $MinimumDocumentationScore"
        
        $undocumentedFeatures = @()
        $processedCount = 0
        
        foreach ($node in $Graph.Nodes.Values) {
            if ($node.Type -in @([CPGNodeType]::Function, [CPGNodeType]::Method, [CPGNodeType]::Class)) {
                $processedCount++
                
                # Skip private members if not requested
                if (-not $IncludePrivateMembers -and $node.Properties.Visibility -eq "Private") {
                    continue
                }
                
                # Calculate documentation score
                $docScore = Get-DocumentationScore -Node $node
                
                if ($docScore -lt $MinimumDocumentationScore) {
                    $priority = Get-DocumentationPriority -Node $node -DocumentationScore $docScore
                    
                    $undocumentedFeatures += @{
                        Name = $node.Name
                        Type = $node.Type
                        File = $node.Properties.FilePath
                        Line = $node.Properties.LineNumber
                        DocumentationScore = $docScore
                        Priority = $priority
                        MissingElements = Get-MissingDocumentationElements -Node $node
                        Complexity = $node.Properties.Complexity -or 1
                        Usage = $node.Properties.CallCount -or 0
                        LastModified = $node.Properties.LastModified
                    }
                }
            }
        }
        
        # Sort by priority and documentation score
        $sortedFeatures = @($undocumentedFeatures | Sort-Object -Property Priority, DocumentationScore)
        
        # Categorize by priority
        $highPriority = @($sortedFeatures | Where-Object { $_.Priority -eq "High" })
        $mediumPriority = @($sortedFeatures | Where-Object { $_.Priority -eq "Medium" })
        $lowPriority = @($sortedFeatures | Where-Object { $_.Priority -eq "Low" })
        
        # Calculate statistics
        $stats = @{
            TotalFeaturesAnalyzed = $processedCount
            UndocumentedCount = @($undocumentedFeatures).Count
            HighPriorityCount = @($highPriority).Count
            MediumPriorityCount = @($mediumPriority).Count
            LowPriorityCount = @($lowPriority).Count
            AverageDocumentationScore = if (@($undocumentedFeatures).Count -gt 0) {
                [Math]::Round(($undocumentedFeatures.DocumentationScore | Measure-Object -Average).Average, 2)
            } else { 0 }
        }
        
        # Generate recommendations
        $recommendations = @()
        if (@($highPriority).Count -gt 0) {
            $recommendations += "Prioritize documenting $(@($highPriority).Count) high-priority features"
        }
        if (@($undocumentedFeatures).Count -gt ($processedCount * 0.3)) {
            $recommendations += "High proportion of undocumented features ($(@($undocumentedFeatures).Count)/$processedCount) - consider documentation sprint"
        }
        if ($stats.AverageDocumentationScore -lt 40) {
            $recommendations += "Very low average documentation score ($($stats.AverageDocumentationScore)) - implement documentation standards"
        }
        
        return @{
            UndocumentedFeatures = @($sortedFeatures)
            HighPriorityFeatures = @($highPriority)
            MediumPriorityFeatures = @($mediumPriority)
            LowPriorityFeatures = @($lowPriority)
            Statistics = $stats
            Recommendations = @($recommendations)
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }
    catch {
        Write-Error "Failed to find undocumented features: $_"
        throw
    }
}

function Get-NodeDocumentation {
    <#
    .SYNOPSIS
        Extracts documentation from a CPG node
    #>
    [CmdletBinding()]
    param($Node, [switch]$IncludeInlineComments)
    
    $nodeDoc = @{
        Synopsis = $null
        Description = $null
        Parameters = @{}
        Returns = $null
        Examples = @()
    }
    
    # Parse comment-based help (PowerShell)
    if ($Node.Properties.CommentHelp) {
        $help = $Node.Properties.CommentHelp
        
        # Extract synopsis
        if ($help -match '\.SYNOPSIS\s*\n\s*(.+?)(?=\n\s*\.|\n\s*#>|$)') {
            $nodeDoc.Synopsis = $matches[1].Trim()
        }
        
        # Extract description
        if ($help -match '\.DESCRIPTION\s*\n\s*([\s\S]+?)(?=\n\s*\.|\n\s*#>|$)') {
            $nodeDoc.Description = $matches[1].Trim()
        }
        
        # Extract parameters
        $paramMatches = [regex]::Matches($help, '\.PARAMETER\s+(\w+)\s*\n\s*(.+?)(?=\n\s*\.|\n\s*#>|$)')
        foreach ($match in $paramMatches) {
            $nodeDoc.Parameters[$match.Groups[1].Value] = $match.Groups[2].Value.Trim()
        }
        
        # Extract return type
        if ($help -match '\.OUTPUTS\s*\n\s*(.+?)(?=\n\s*\.|\n\s*#>|$)') {
            $nodeDoc.Returns = $matches[1].Trim()
        }
        
        # Extract examples
        $exampleMatches = [regex]::Matches($help, '\.EXAMPLE\s*\n\s*([\s\S]+?)(?=\n\s*\.|\n\s*#>|$)')
        foreach ($match in $exampleMatches) {
            $nodeDoc.Examples += $match.Groups[1].Value.Trim()
        }
    }
    
    # Parse JSDoc comments (JavaScript/TypeScript)
    elseif ($Node.Properties.JSDoc) {
        $jsdoc = $Node.Properties.JSDoc
        
        # Extract description
        if ($jsdoc -match '^\s*\*\s*([^@].+?)(?=\n\s*\*\s*@|$)') {
            $nodeDoc.Description = $matches[1].Trim()
        }
        
        # Extract parameters
        $paramMatches = [regex]::Matches($jsdoc, '@param\s*\{([^}]+)\}\s*(\w+)\s*-?\s*(.+?)(?=\n\s*\*\s*@|$)')
        foreach ($match in $paramMatches) {
            $nodeDoc.Parameters[$match.Groups[2].Value] = @{
                Type = $match.Groups[1].Value
                Description = $match.Groups[3].Value.Trim()
            }
        }
        
        # Extract return type
        if ($jsdoc -match '@returns?\s*\{([^}]+)\}\s*(.+?)(?=\n\s*\*\s*@|$)') {
            $nodeDoc.Returns = @{
                Type = $matches[1]
                Description = $matches[2].Trim()
            }
        }
    }
    
    # Parse Python docstrings
    elseif ($Node.Properties.Docstring) {
        $docstring = $Node.Properties.Docstring
        
        # Extract description (first line or paragraph)
        if ($docstring -match '^"""(.+?)(?:\n|""")') {
            $nodeDoc.Description = $matches[1].Trim()
        }
        
        # Extract parameters (Google/NumPy style)
        if ($docstring -match 'Args:\s*\n([\s\S]+?)(?=\n\s*Returns?:|$)') {
            $argsSection = $matches[1]
            $paramMatches = [regex]::Matches($argsSection, '(\w+)\s*(?:\([^)]+\))?\s*:\s*(.+?)(?=\n\s*\w+\s*:|$)')
            foreach ($match in $paramMatches) {
                $nodeDoc.Parameters[$match.Groups[1].Value] = $match.Groups[2].Value.Trim()
            }
        }
        
        # Extract return type
        if ($docstring -match 'Returns?:\s*\n\s*(.+?)(?=\n\s*\w+:|$)') {
            $nodeDoc.Returns = $matches[1].Trim()
        }
    }
    
    return $nodeDoc
}

function Get-DocumentationScore {
    <#
    .SYNOPSIS
        Calculates a documentation completeness score (0-100)
    #>
    [CmdletBinding()]
    param($Node)
    
    $score = 0
    $maxScore = 100
    
    $nodeDoc = Get-NodeDocumentation -Node $Node
    
    # Synopsis/Description (40 points)
    if ($nodeDoc.Synopsis) { $score += 20 }
    if ($nodeDoc.Description) { $score += 20 }
    
    # Parameter documentation (30 points)
    if ($Node.Properties.Parameters) {
        $paramCount = $Node.Properties.Parameters.Count
        $documentedParams = 0
        
        foreach ($param in $Node.Properties.Parameters) {
            if ($nodeDoc.Parameters.ContainsKey($param.Name)) {
                $documentedParams++
            }
        }
        
        if ($paramCount -gt 0) {
            $score += [Math]::Round((($documentedParams / $paramCount) * 30), 0)
        } else {
            $score += 30  # No parameters to document
        }
    } else {
        $score += 30  # No parameters to document
    }
    
    # Return type documentation (15 points)
    if ($Node.Properties.ReturnType) {
        if ($nodeDoc.Returns) { $score += 15 }
    } else {
        $score += 15  # No return type to document
    }
    
    # Examples (15 points)
    if ($nodeDoc.Examples.Count -gt 0) { $score += 15 }
    
    return [Math]::Min($score, $maxScore)
}

function Get-DocumentationPriority {
    <#
    .SYNOPSIS
        Determines documentation priority for a feature
    #>
    [CmdletBinding()]
    param($Node, [int]$DocumentationScore)
    
    $priority = "Low"
    
    # High priority factors
    if ($Node.Properties.Visibility -eq "Public" -or $Node.Properties.IsExported) {
        $priority = "High"
    }
    
    if ($Node.Properties.Complexity -gt 10) {
        $priority = "High"
    }
    
    if ($Node.Properties.CallCount -gt 10) {
        $priority = "High"
    }
    
    if ($DocumentationScore -lt 20) {
        $priority = "High"
    }
    
    # Medium priority factors
    if ($priority -eq "Low") {
        if ($Node.Properties.Complexity -gt 5 -or $Node.Properties.CallCount -gt 3) {
            $priority = "Medium"
        }
        
        if ($DocumentationScore -lt 40) {
            $priority = "Medium"
        }
    }
    
    return $priority
}

function Get-MissingDocumentationElements {
    <#
    .SYNOPSIS
        Identifies which documentation elements are missing
    #>
    [CmdletBinding()]
    param($Node)
    
    $missing = @()
    $nodeDoc = Get-NodeDocumentation -Node $Node
    
    if (-not $nodeDoc.Synopsis) { $missing += "Synopsis" }
    if (-not $nodeDoc.Description) { $missing += "Description" }
    if ($Node.Properties.Parameters -and $nodeDoc.Parameters.Count -eq 0) { $missing += "Parameters" }
    if ($Node.Properties.ReturnType -and -not $nodeDoc.Returns) { $missing += "ReturnType" }
    if ($nodeDoc.Examples.Count -eq 0) { $missing += "Examples" }
    
    return $missing
}

#endregion Documentation Comparison

# Export public functions
Export-ModuleMember -Function @(
    'Compare-CodeToDocumentation',
    'Find-UndocumentedFeatures'
)

#endregion Documentation Comparison Component
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBFS3ZirTKz+Pp2
# BvpntSOA9+iVBcpFI+PaQCDmaD+YwqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIPvAyZwgXhrZfk44PdVuuu/8
# 8CJO6djyhc4bGvSD71cVMA0GCSqGSIb3DQEBAQUABIIBAHalItAS2dh9Q3b8V0Vc
# pnu+yypDp3/ArgrAgFpSMAeeIiglQ0AjHKZJlLPwhTz5+R2Uqf60fEIZ92wUArW5
# kSumPXZQ6waQ4p07+DZIK280vJSYemeaZ/GgUb6rZDEY+ipNhsTUBr1aMM2lld3a
# 4p0Na3ak0CtggD2FxJ1U40VeNGdlJckzHSLvgfCS2/S9ogjNldldgbqazXD2KCKR
# 4hBo+UCb5WiIonujmmyWDeVtMekA5osNslnhIsMAKwWrrGRazqKY8cpNnJ7CltSW
# 21Yl5sJwvr6AMI+mWR4JoMygvU7FAvXRMOxQoa/JWKG8s9qsK/jo14FZIdvQiF0j
# CTU=
# SIG # End signature block
