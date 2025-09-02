#region DePA Algorithm Implementation Component
<#
.SYNOPSIS
    Unity Claude CPG - DePA Algorithm Implementation Component
    
.DESCRIPTION
    Implements the DePA (Dead Program Artifact) algorithm for line-level perplexity analysis
    to identify potentially dead or obsolete code using statistical language modeling and 
    entropy measurements.
    
    Key capabilities:
    - Multi-language perplexity calculation (PowerShell, JavaScript, TypeScript, Python, C#)
    - Context-aware entropy analysis with configurable window sizes
    - Token frequency analysis and probability distributions
    - Reference tracking to identify isolated code sections
    - Categorized scoring system (Normal, Suspicious, HighPerplexity, VeryHighPerplexity)
    
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

#region DePA Algorithm Implementation

function Get-CodePerplexity {
    <#
    .SYNOPSIS
        Implements DePA (Dead Program Artifact) algorithm for line-level perplexity analysis
        
    .DESCRIPTION
        Calculates perplexity scores for code lines to identify potentially dead or obsolete code.
        Based on statistical language modeling and entropy measurements.
        
    .PARAMETER CodeContent
        The code content to analyze
        
    .PARAMETER Language
        Programming language of the code
        
    .PARAMETER WindowSize
        Context window size for perplexity calculation (default: 5 lines)
        
    .OUTPUTS
        System.Collections.Hashtable
        Contains perplexity analysis with scores, categories, and dead code candidates
        
    .EXAMPLE
        $perplexity = Get-CodePerplexity -CodeContent $code -Language "PowerShell"
        Write-Host "Dead code candidates: $($perplexity.DeadCodeCandidates.Count)"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$CodeContent,
        
        [Parameter(Mandatory)]
        [ValidateSet("PowerShell", "JavaScript", "TypeScript", "Python", "CSharp")]
        [string]$Language,
        
        [int]$WindowSize = 5
    )
    
    try {
        Write-Verbose "Calculating code perplexity for $Language code with window size $WindowSize"
        
        # Split code into lines
        $lines = $CodeContent -split "`n"
        $lineCount = $lines.Count
        
        # Initialize perplexity scores
        $perplexityScores = @{}
        
        # Language-specific token patterns
        $tokenPatterns = @{
            PowerShell = @{
                Keywords = @('function', 'param', 'if', 'else', 'foreach', 'while', 'try', 'catch', 'return')
                Operators = @('-eq', '-ne', '-gt', '-lt', '-and', '-or', '-not')
                Special = @('$_', '$?', '$^', '$$')
            }
            JavaScript = @{
                Keywords = @('function', 'const', 'let', 'var', 'if', 'else', 'for', 'while', 'return', 'async', 'await')
                Operators = @('===', '!==', '&&', '||', '=>')
                Special = @('this', 'super', 'new')
            }
            Python = @{
                Keywords = @('def', 'class', 'if', 'else', 'elif', 'for', 'while', 'return', 'import', 'from')
                Operators = @('and', 'or', 'not', 'in', 'is')
                Special = @('self', '__init__', '__name__')
            }
            TypeScript = @{
                Keywords = @('function', 'const', 'let', 'interface', 'type', 'class', 'extends', 'implements')
                Operators = @('===', '!==', '&&', '||', '=>', '?.')
                Special = @('this', 'super', 'new', 'typeof')
            }
            CSharp = @{
                Keywords = @('class', 'interface', 'public', 'private', 'protected', 'static', 'void', 'return')
                Operators = @('==', '!=', '&&', '||', '??', '?.')
                Special = @('this', 'base', 'new', 'typeof')
            }
        }
        
        $patterns = $tokenPatterns[$Language]
        
        # Calculate perplexity for each line
        for ($i = 0; $i -lt $lineCount; $i++) {
            $line = $lines[$i]
            
            # Skip empty lines and comments
            if ([string]::IsNullOrWhiteSpace($line)) {
                $perplexityScores[$i] = @{
                    LineNumber = $i + 1
                    Score = 0
                    Category = "Empty"
                }
                continue
            }
            
            # Check for comment patterns
            $isComment = switch ($Language) {
                "PowerShell" { $line.Trim().StartsWith("#") }
                "JavaScript" { $line.Trim().StartsWith("//") -or $line.Trim().StartsWith("/*") }
                "TypeScript" { $line.Trim().StartsWith("//") -or $line.Trim().StartsWith("/*") }
                "Python" { $line.Trim().StartsWith("#") }
                "CSharp" { $line.Trim().StartsWith("//") -or $line.Trim().StartsWith("/*") }
                default { $false }
            }
            
            if ($isComment) {
                $perplexityScores[$i] = @{
                    LineNumber = $i + 1
                    Score = 0.1
                    Category = "Comment"
                }
                continue
            }
            
            # Calculate context window
            $contextStart = [Math]::Max(0, $i - $WindowSize)
            $contextEnd = [Math]::Min($lineCount - 1, $i + $WindowSize)
            $context = $lines[$contextStart..$contextEnd] -join " "
            
            # Calculate token frequency
            $lineTokens = $line -split '\s+' | Where-Object { $_ -ne "" }
            $contextTokens = $context -split '\s+' | Where-Object { $_ -ne "" }
            
            # Calculate entropy-based perplexity
            $entropy = 0
            $tokenProbabilities = @{}
            
            foreach ($token in $lineTokens) {
                $frequency = @($contextTokens | Where-Object { $_ -eq $token }).Count
                $totalTokens = @($contextTokens).Count
                $probability = if ($totalTokens -gt 0) { 
                    $frequency / $totalTokens 
                } else { 
                    0.001 
                }
                
                if ($probability -gt 0) {
                    $entropy -= $probability * [Math]::Log($probability, 2)
                }
                
                $tokenProbabilities[$token] = $probability
            }
            
            # Calculate perplexity score (2^entropy)
            $perplexity = [Math]::Pow(2, $entropy)
            
            # Adjust for known patterns
            $adjustedScore = $perplexity
            
            # Lower score for lines with common keywords
            $keywordCount = @($patterns.Keywords | Where-Object { $line -match "\b$_\b" }).Count
            if ($keywordCount -gt 0) {
                $adjustedScore *= (1 - 0.1 * $keywordCount)
            }
            
            # Higher score for isolated code (no references in context)
            $hasReferences = $false
            foreach ($token in $lineTokens) {
                if ($token -match '^\$\w+$|^\w+\(\)$|^\w+\.\w+$') {
                    # Check if token appears elsewhere in context
                    $otherOccurrences = @($context -split '\s+' | Where-Object { $_ -eq $token -and $_ -ne $line }).Count
                    if ($otherOccurrences -eq 0) {
                        $adjustedScore *= 1.5
                    } else {
                        $hasReferences = $true
                    }
                }
            }
            
            # Categorize based on score
            $category = switch ($adjustedScore) {
                { $_ -lt 2 } { "Normal" }
                { $_ -ge 2 -and $_ -lt 5 } { "Suspicious" }
                { $_ -ge 5 -and $_ -lt 10 } { "HighPerplexity" }
                { $_ -ge 10 } { "VeryHighPerplexity" }
            }
            
            $perplexityScores[$i] = @{
                LineNumber = $i + 1
                Score = [Math]::Round($adjustedScore, 2)
                Category = $category
                HasReferences = $hasReferences
                Line = $line.Trim()
            }
        }
        
        # Return analysis results
        return @{
            Language = $Language
            TotalLines = $lineCount
            Scores = $perplexityScores
            Summary = @{
                Normal = @($perplexityScores.Values | Where-Object { $_.Category -eq "Normal" }).Count
                Suspicious = @($perplexityScores.Values | Where-Object { $_.Category -eq "Suspicious" }).Count
                HighPerplexity = @($perplexityScores.Values | Where-Object { $_.Category -eq "HighPerplexity" }).Count
                VeryHighPerplexity = @($perplexityScores.Values | Where-Object { $_.Category -eq "VeryHighPerplexity" }).Count
            }
            DeadCodeCandidates = $perplexityScores.Values | 
                Where-Object { $_.Category -in @("HighPerplexity", "VeryHighPerplexity") -and -not $_.HasReferences }
        }
    }
    catch {
        Write-Error "Failed to calculate code perplexity: $_"
        throw
    }
}

#endregion DePA Algorithm Implementation

# Alias functions for backward compatibility
function Get-LinePerplexity {
    <#
    .SYNOPSIS
        Alias for Get-CodePerplexity to maintain backward compatibility
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$CodeLines,
        
        [string]$Language = 'PowerShell',
        
        [int]$WindowSize = 5,
        
        [double]$SuspiciousThreshold = 5.0,
        
        [double]$HighThreshold = 10.0,
        
        [double]$VeryHighThreshold = 20.0
    )
    
    # Call the main function
    Get-CodePerplexity @PSBoundParameters
}

function Test-DeadProgramArtifacts {
    <#
    .SYNOPSIS
        Tests for dead program artifacts using DePA algorithm
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$CodeLines,
        
        [string]$Language = 'PowerShell',
        
        [double]$PerplexityThreshold = 10.0
    )
    
    try {
        # Use Get-CodePerplexity to analyze
        $analysis = Get-CodePerplexity -CodeLines $CodeLines -Language $Language
        
        # Identify dead artifacts based on threshold
        $deadArtifacts = $analysis.Scores.Values | 
            Where-Object { $_.Perplexity -ge $PerplexityThreshold }
        
        return @{
            TotalLines = $analysis.TotalLines
            DeadArtifactsFound = @($deadArtifacts).Count
            DeadArtifacts = $deadArtifacts
            Summary = $analysis.Summary
        }
    }
    catch {
        Write-Error "Failed to test for dead program artifacts: $_"
        throw
    }
}

# Export public functions
Export-ModuleMember -Function @(
    'Get-CodePerplexity',
    'Get-LinePerplexity',
    'Test-DeadProgramArtifacts'
)

#endregion DePA Algorithm Implementation Component
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCJ5KMa8T6BA512
# KF/y71WkkDCb7lACgrCzu3y7hMbny6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIGPMEjEhnCk4c+nu8QGJX20k
# oB/kFgXesx/1sQmbc5WAMA0GCSqGSIb3DQEBAQUABIIBAAqv5BiyVrGsTOv4u6RY
# lZuXQJs1yrpaseEzdk2SALHslK6OsAnpMtGVZvGD+g/hjw5RFIXJITUzfmKPae7g
# IVhhdLpG/CmfQD+7SrygiKvfO4QHUWBsJC8ckrEgP2q3fxjSKo7GeEdumpcFYtx1
# ht6pv1IQddru6o5ghHJuaPLVlfMiAYv3jYjOkzVvWgU1kzzYnIA9t1r31+WnaVFh
# hYk6YD/uHNJO42rY6so8JafWYXJiuh8VD+gdknVGtAY3kbn5vUeE9aEjv3sjC4ol
# R743X0S3mJcfBtXRKG0l1xmcHQII5rK577ztSxIbZblF820sBjwbq1cclyJVUuAl
# 6no=
# SIG # End signature block
