#Requires -Version 5.1
<#
.SYNOPSIS
    Unity log analysis operations for SafeCommandExecution module.

.DESCRIPTION
    Provides Unity Editor.log parsing, error pattern analysis,
    and diagnostic reporting functionality.

.NOTES
    Part of SafeCommandExecution refactored architecture
    Originally from SafeCommandExecution.psm1 (lines 1600-1909)
    Refactoring Date: 2025-08-25
#>

# Import required modules
Import-Module "$PSScriptRoot\SafeCommandCore.psm1" -Force
Import-Module "$PSScriptRoot\ValidationEngine.psm1" -Force

#region Unity Log Analysis

function Invoke-UnityLogAnalysis {
    <#
    .SYNOPSIS
    Analyzes Unity Editor log for errors, warnings, and patterns.
    
    .DESCRIPTION
    Parses Unity log files to extract compilation errors, runtime errors,
    warnings, and other diagnostic information.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Command,
        
        [Parameter()]
        [int]$TimeoutSeconds = 180
    )
    
    Write-SafeLog "Starting Unity log analysis operation" -Level Info
    
    # Set default log path if not provided
    $logPath = $Command.Arguments.LogPath
    if (-not $logPath) {
        # Default Unity Editor.log location for Windows
        $logPath = Join-Path $env:LOCALAPPDATA "Unity\Editor\Editor.log"
        Write-SafeLog "Using default Unity log path: $logPath" -Level Debug
    }
    
    # Validate log path exists and is safe
    if (-not (Test-Path $logPath)) {
        throw "Unity log file not found: $logPath"
    }
    
    if (-not (Test-PathSafety -Path $logPath)) {
        throw "Log path is not safe or accessible: $logPath"
    }
    
    $analysis = @{
        LogPath = $logPath
        ParsedAt = Get-Date
        TotalLines = 0
        Errors = @()
        Warnings = @()
        Info = @()
        ErrorPatterns = @{}
        Summary = @{
            ErrorCount = 0
            WarningCount = 0
            InfoCount = 0
            CompilationErrors = 0
            RuntimeErrors = 0
        }
    }
    
    Write-SafeLog "Analyzing Unity log file: $logPath" -Level Debug
    
    try {
        # Read log file content
        $startTime = Get-Date
        $logContent = Get-Content $logPath -ErrorAction SilentlyContinue
        $analysis.TotalLines = $logContent.Count
        
        Write-SafeLog "Read $($analysis.TotalLines) lines from Unity log" -Level Debug
        
        # Define error patterns for Unity 2021.1.14f1
        $errorPatterns = @{
            'CompilationError' = 'error CS\d+:'
            'CompilationWarning' = 'warning CS\d+:'
            'RuntimeError' = 'Exception|Error:|ArgumentException|NullReferenceException'
            'AssetError' = 'Failed to import|Asset import failed'
            'BuildError' = 'Build failed|BuildPlayerWindow'
        }
        
        # Analyze each line
        foreach ($line in $logContent) {
            $lineAnalysis = @{
                Content = $line
                LineNumber = $logContent.IndexOf($line) + 1
                Timestamp = $null
                Severity = 'Info'
                Category = 'General'
                ErrorCode = $null
                FilePath = $null
            }
            
            # Extract file path and line number if present
            if ($line -match 'Assets/.*\.cs\((\d+),(\d+)\):') {
                $lineAnalysis.FilePath = ($line -split ':')[0]
            }
            
            # Check for compilation errors
            if ($line -match $errorPatterns.CompilationError) {
                $lineAnalysis.Severity = 'Error'
                $lineAnalysis.Category = 'Compilation'
                $analysis.Errors += $lineAnalysis
                $analysis.Summary.CompilationErrors++
                
                # Extract error code
                if ($line -match 'error (CS\d+):') {
                    $lineAnalysis.ErrorCode = $matches[1]
                }
                
                Write-SafeLog "Compilation error detected: $($lineAnalysis.ErrorCode)" -Level Debug
            }
            # Check for compilation warnings
            elseif ($line -match $errorPatterns.CompilationWarning) {
                $lineAnalysis.Severity = 'Warning'
                $lineAnalysis.Category = 'Compilation'
                $analysis.Warnings += $lineAnalysis
                
                Write-SafeLog "Compilation warning detected" -Level Debug
            }
            # Check for runtime errors
            elseif ($line -match $errorPatterns.RuntimeError) {
                $lineAnalysis.Severity = 'Error'
                $lineAnalysis.Category = 'Runtime'
                $analysis.Errors += $lineAnalysis
                $analysis.Summary.RuntimeErrors++
                
                Write-SafeLog "Runtime error detected" -Level Debug
            }
            # Check for asset errors
            elseif ($line -match $errorPatterns.AssetError) {
                $lineAnalysis.Severity = 'Error'
                $lineAnalysis.Category = 'Asset'
                $analysis.Errors += $lineAnalysis
                
                Write-SafeLog "Asset error detected" -Level Debug
            }
            # Check for build errors
            elseif ($line -match $errorPatterns.BuildError) {
                $lineAnalysis.Severity = 'Error'
                $lineAnalysis.Category = 'Build'
                $analysis.Errors += $lineAnalysis
                
                Write-SafeLog "Build error detected" -Level Debug
            }
            else {
                $analysis.Info += $lineAnalysis
            }
        }
        
        # Update summary counts
        $analysis.Summary.ErrorCount = $analysis.Errors.Count
        $analysis.Summary.WarningCount = $analysis.Warnings.Count
        $analysis.Summary.InfoCount = $analysis.Info.Count
        
        $duration = (Get-Date) - $startTime
        
        Write-SafeLog "Unity log analysis completed. Errors: $($analysis.Summary.ErrorCount), Warnings: $($analysis.Summary.WarningCount), Duration: $($duration.TotalSeconds)s" -Level Info
        
        return @{
            Success = $true
            Output = $analysis
            Error = $null
            AnalysisResult = $analysis
            Duration = $duration.TotalSeconds
        }
    }
    catch {
        Write-SafeLog "Unity log analysis failed: $($_.Exception.Message)" -Level Error
        return @{
            Success = $false
            Output = $null
            Error = $_.ToString()
            AnalysisResult = @{
                Status = 'Failed'
                ErrorMessage = $_.ToString()
                Duration = 0
            }
        }
    }
}

#endregion

#region Error Pattern Analysis

function Invoke-UnityErrorPatternAnalysis {
    <#
    .SYNOPSIS
    Analyzes Unity log for specific error patterns and provides solutions.
    
    .DESCRIPTION
    Identifies common Unity error patterns, tracks their frequency,
    and provides recommendations for resolution.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Command,
        
        [Parameter()]
        [int]$TimeoutSeconds = 180
    )
    
    Write-SafeLog "Starting Unity error pattern analysis" -Level Info
    
    # Get log path from command or use default
    $logPath = $Command.Arguments.LogPath
    if (-not $logPath) {
        $logPath = Join-Path $env:LOCALAPPDATA "Unity\Editor\Editor.log"
    }
    
    # Validate log path
    if (-not (Test-Path $logPath)) {
        throw "Unity log file not found: $logPath"
    }
    
    $patternAnalysis = @{
        LogPath = $logPath
        AnalyzedAt = Get-Date
        ErrorPatterns = @{}
        TrendAnalysis = @{}
        FrequencyAnalysis = @{}
        Recommendations = @()
    }
    
    Write-SafeLog "Analyzing error patterns in Unity log: $logPath" -Level Debug
    
    try {
        # Read log content
        $logContent = Get-Content $logPath -ErrorAction SilentlyContinue
        
        # Define specific Unity error patterns with solutions
        $knownPatterns = @{
            'CS0246' = @{
                Pattern = 'error CS0246:.*could not be found'
                Description = 'Type or namespace not found'
                Category = 'Missing Reference'
                Solution = 'Add missing using statement or assembly reference'
                Frequency = 0
            }
            'CS0103' = @{
                Pattern = 'error CS0103:.*does not exist'
                Description = 'Name does not exist in current context'
                Category = 'Scope Issue'
                Solution = 'Check variable declaration and scope'
                Frequency = 0
            }
            'CS1061' = @{
                Pattern = 'error CS1061:.*does not contain a definition'
                Description = 'Member not found on type'
                Category = 'API Issue'
                Solution = 'Check API documentation or add extension method'
                Frequency = 0
            }
            'CS0029' = @{
                Pattern = 'error CS0029:.*Cannot implicitly convert'
                Description = 'Type conversion error'
                Category = 'Type Mismatch'
                Solution = 'Add explicit cast or change variable type'
                Frequency = 0
            }
        }
        
        # Analyze patterns in log
        foreach ($line in $logContent) {
            foreach ($patternName in $knownPatterns.Keys) {
                $pattern = $knownPatterns[$patternName]
                if ($line -match $pattern.Pattern) {
                    $pattern.Frequency++
                    
                    Write-SafeLog "Found error pattern $patternName in log" -Level Debug
                }
            }
        }
        
        # Update pattern analysis
        $patternAnalysis.ErrorPatterns = $knownPatterns
        
        # Generate frequency analysis (PowerShell 5.1 compatible)
        $frequencyValues = @()
        foreach ($pattern in $knownPatterns.Values) {
            $frequencyValues += $pattern.Frequency
        }
        $totalErrors = ($frequencyValues | Measure-Object -Sum).Sum
        foreach ($patternName in $knownPatterns.Keys) {
            $frequency = $knownPatterns[$patternName].Frequency
            $percentage = if ($totalErrors -gt 0) { [math]::Round(($frequency / $totalErrors) * 100, 2) } else { 0 }
            
            $patternAnalysis.FrequencyAnalysis[$patternName] = @{
                Count = $frequency
                Percentage = $percentage
                Description = $knownPatterns[$patternName].Description
            }
        }
        
        # Generate recommendations based on most frequent errors
        $topErrors = $knownPatterns.GetEnumerator() | 
                    Where-Object { $_.Value.Frequency -gt 0 } |
                    Sort-Object { $_.Value.Frequency } -Descending |
                    Select-Object -First 3
        
        foreach ($error in $topErrors) {
            $patternAnalysis.Recommendations += @{
                ErrorType = $error.Key
                Priority = switch ($error.Value.Frequency) {
                    { $_ -ge 10 } { 'High' }
                    { $_ -ge 5 } { 'Medium' }
                    default { 'Low' }
                }
                Description = $error.Value.Description
                Solution = $error.Value.Solution
                Frequency = $error.Value.Frequency
            }
        }
        
        Write-SafeLog "Error pattern analysis completed. Found $totalErrors total errors across $($knownPatterns.Count) pattern types" -Level Info
        
        return @{
            Success = $true
            Output = $patternAnalysis
            Error = $null
            PatternAnalysis = $patternAnalysis
        }
    }
    catch {
        Write-SafeLog "Error pattern analysis failed: $($_.Exception.Message)" -Level Error
        return @{
            Success = $false
            Output = $null
            Error = $_.ToString()
            PatternAnalysis = @{
                Status = 'Failed'
                ErrorMessage = $_.ToString()
            }
        }
    }
}

#endregion

#region Module Exports

Export-ModuleMember -Function @(
    'Invoke-UnityLogAnalysis',
    'Invoke-UnityErrorPatternAnalysis'
)

#endregion

# REFACTORING MARKER: This module was refactored from SafeCommandExecution.psm1 on 2025-08-25
# Original file size: 2860 lines
# This component: Unity log analysis operations (lines 1600-1909, ~310 lines)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD+BWbi4bbRgoq7
# XTVMg4qjhVpRyMcII0jdqdWfTIuPb6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIDXMNpjWDqd/2Zr2LgyOOG6n
# TDZWxquuvpSx11ypu3qzMA0GCSqGSIb3DQEBAQUABIIBAGQBKCQD9I5hmhA1/feO
# bnzsu9HUXO1iSPY6V9xsoO2LqChMApDA9aMO7jsZSr1X240XLA+4eD/Qr6vFhDx2
# 1750ygnPX1ELrqsNjGl3RBYI0MS8xN+lMM4i6qzjQ6f6G1386tSsTlJDlY46JMtk
# ranlzvQiRELnc1uBaOQGm0GTXyTtGP8cIxl4eES+FyHIzvCuewXDx0JDJ2JyNTv7
# fSh+0SY7hjCa9sLKHBnCEVp1ZlEtQNCSHTvIeXPgkTcdhwJM5e4FdjdsO+5+lTn1
# a8snpIsrZcOLus8vc1yTiXSZYsovydfsBgNMDRzNj77WLR0Qh3tI1Yqm5/3p39Zn
# 3kE=
# SIG # End signature block
