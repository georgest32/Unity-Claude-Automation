# Unity-Claude-CLIOrchestrator - Pattern Recognition & Classification Engine (Refactored)
# Phase 7 Day 1-2 Hours 5-8: Pattern Recognition & Classification Implementation
# Compatible with PowerShell 5.1 and Claude Code CLI 2025

#region Module Configuration

$script:PatternConfig = @{
    ConfidenceThreshold = 0.75
    PatternCacheSize = 1000
    LearningEnabled = $true
    LoggingEnabled = $true
    PerformanceTracking = $true
}

$script:LogPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log"

# Import nested modules
$moduleBasePath = $PSScriptRoot

try {
    Import-Module "$moduleBasePath\RecommendationPatternEngine.psm1" -Force -Global
    Import-Module "$moduleBasePath\EntityContextEngine.psm1" -Force -Global  
    Import-Module "$moduleBasePath\ResponseClassificationEngine.psm1" -Force -Global
    Import-Module "$moduleBasePath\BayesianConfidenceEngine.psm1" -Force -Global
    
    Write-Host "All pattern recognition sub-modules imported successfully" -ForegroundColor Green
} catch {
    Write-Warning "Failed to import some pattern recognition modules: $($_.Exception.Message)"
}

#endregion

#region Logging Functions

function Write-PatternLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet("INFO", "WARN", "ERROR", "DEBUG", "PERF")]
        [string]$Level = "INFO"
    )
    
    if (-not $script:PatternConfig.LoggingEnabled) {
        return
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logEntry = "[$timestamp] [$Level] [PatternRecognitionEngine] $Message"
    
    try {
        Add-Content -Path $script:LogPath -Value $logEntry -Encoding UTF8 -ErrorAction SilentlyContinue
    } catch {
        # Silently continue if logging fails
    }
    
    # Also write to console for performance and error messages
    if ($Level -in @("ERROR", "PERF")) {
        $color = if ($Level -eq "ERROR") { "Red" } else { "Cyan" }
        Write-Host $logEntry -ForegroundColor $color
    }
}

#endregion

#region Main Pattern Analysis Function

function Invoke-PatternRecognitionAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseContent,
        
        [Parameter()]
        [PSObject]$ParsedJson,
        
        [Parameter()]
        [switch]$IncludeDetails
    )
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    Write-PatternLog -Message "Starting comprehensive pattern recognition analysis" -Level "INFO"
    
    try {
        # Step 1: Recommendation Pattern Recognition
        Write-PatternLog -Message "Step 1: Finding recommendation patterns" -Level "DEBUG"
        $recommendations = Find-RecommendationPatterns -ResponseText $ResponseContent
        
        # Step 2: Context Entity Extraction
        Write-PatternLog -Message "Step 2: Extracting context entities" -Level "DEBUG"
        $entities = Extract-ContextEntities -ResponseContent $ResponseContent
        
        # Step 3: Response Classification
        Write-PatternLog -Message "Step 3: Classifying response type" -Level "DEBUG"
        $classification = Classify-ResponseType -ResponseContent $ResponseContent -Recommendations $recommendations -Entities $entities
        
        # Step 4: Confidence Scoring
        Write-PatternLog -Message "Step 4: Calculating confidence scores" -Level "DEBUG"
        $confidenceAnalysis = Calculate-OverallConfidence -Recommendations $recommendations -Classification $classification -Entities $entities
        
        $stopwatch.Stop()
        
        # Compile results
        $analysisResult = @{
            Recommendations = $recommendations
            Entities = $entities
            Classification = $classification
            ConfidenceAnalysis = $confidenceAnalysis
            ProcessingTimeMs = $stopwatch.ElapsedMilliseconds
            ResponseLength = $ResponseContent.Length
            AnalysisTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
            ProcessingSuccess = $true
        }
        
        # Add detailed information if requested
        if ($IncludeDetails) {
            $analysisResult.Details = @{
                ConfigSettings = $script:PatternConfig
                ModulesLoaded = @(
                    "RecommendationPatternEngine",
                    "EntityContextEngine", 
                    "ResponseClassificationEngine",
                    "BayesianConfidenceEngine"
                )
            }
        }
        
        # Performance logging
        Write-PatternLog -Message "Pattern analysis completed in $($stopwatch.ElapsedMilliseconds)ms" -Level "PERF"
        
        # Log summary
        $summary = "Analysis: $($recommendations.Count) recommendations, $($entities.Count) entities, classified as '$($classification.Type)' (confidence: $($confidenceAnalysis.OverallConfidence.ToString('P1')))"
        Write-PatternLog -Message $summary -Level "INFO"
        
        return $analysisResult
        
    } catch {
        $stopwatch.Stop()
        $errorMessage = "Pattern recognition analysis failed after $($stopwatch.ElapsedMilliseconds)ms: $($_.Exception.Message)"
        Write-PatternLog -Message $errorMessage -Level "ERROR"
        
        # Return error result
        return @{
            Recommendations = @()
            Entities = @()
            Classification = @{ Type = "Error"; Confidence = 0.5; Reasoning = "Analysis failed" }
            ConfidenceAnalysis = @{ OverallConfidence = 0.1; QualityRating = "Low" }
            ProcessingTimeMs = $stopwatch.ElapsedMilliseconds
            ResponseLength = $ResponseContent.Length
            AnalysisTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
            ProcessingSuccess = $false
            Error = $_.Exception.Message
        }
    }
}

#endregion

#region Performance Utilities

function Test-PatternRecognitionPerformance {
    [CmdletBinding()]
    param(
        [Parameter()]
        [array]$TestCases = @(),
        
        [Parameter()]
        [int]$Iterations = 3
    )
    
    if ($TestCases.Count -eq 0) {
        $TestCases = @(
            @{ Name = "Simple"; Content = "RECOMMENDATION: TEST - C:\Test.ps1" },
            @{ Name = "Medium"; Content = "RECOMMENDATION: FIX - C:\Project\Script.ps1`r`nERROR: Compilation failed in line 23" },
            @{ Name = "Complex"; Content = "RECOMMENDATION: COMPILE - C:\Large\Project.sln`r`nERROR: Multiple issues detected`r`nFiles affected: Script1.cs, Script2.cs, Script3.cs" }
        )
    }
    
    Write-Host "Testing Pattern Recognition Performance" -ForegroundColor Cyan
    
    foreach ($testCase in $TestCases) {
        Write-Host "  Testing: $($testCase.Name)" -ForegroundColor Yellow
        
        $times = @()
        for ($i = 1; $i -le $Iterations; $i++) {
            $result = Invoke-PatternRecognitionAnalysis -ResponseContent $testCase.Content
            $times += $result.ProcessingTimeMs
        }
        
        $avgTime = [Math]::Round(($times | Measure-Object -Average).Average, 2)
        $minTime = ($times | Measure-Object -Minimum).Minimum
        $maxTime = ($times | Measure-Object -Maximum).Maximum
        
        Write-Host "    Average: ${avgTime}ms (Range: ${minTime}-${maxTime}ms)" -ForegroundColor Gray
    }
}

function Get-PatternRecognitionStatus {
    [CmdletBinding()]
    param()
    
    $status = @{
        ModulesLoaded = @()
        ConfigSettings = $script:PatternConfig
        LogPath = $script:LogPath
        LastLogEntry = $null
    }
    
    # Check which modules are available
    $moduleCommands = @(
        @{ Module = "RecommendationPatternEngine"; Command = "Find-RecommendationPatterns" },
        @{ Module = "EntityContextEngine"; Command = "Extract-ContextEntities" },
        @{ Module = "ResponseClassificationEngine"; Command = "Classify-ResponseType" },
        @{ Module = "BayesianConfidenceEngine"; Command = "Calculate-OverallConfidence" }
    )
    
    foreach ($moduleInfo in $moduleCommands) {
        $available = $null -ne (Get-Command $moduleInfo.Command -ErrorAction SilentlyContinue)
        $status.ModulesLoaded += @{
            Name = $moduleInfo.Module
            Command = $moduleInfo.Command
            Available = $available
        }
    }
    
    # Get last log entry if log file exists
    if (Test-Path $script:LogPath) {
        try {
            $lastLine = Get-Content $script:LogPath -Tail 1 -ErrorAction SilentlyContinue
            $status.LastLogEntry = $lastLine
        } catch {
            $status.LastLogEntry = "Could not read log file"
        }
    }
    
    return $status
}

#endregion

# Export main functions
Export-ModuleMember -Function @(
    'Invoke-PatternRecognitionAnalysis',
    'Test-PatternRecognitionPerformance',
    'Get-PatternRecognitionStatus'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCa3th9qoLr+mAY
# WLAgcl8TE0MwQCcQgNjwi2yXZ4vQA6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIPxabN8iIzCVrUD2KWXhgBRF
# +4AgW5O7qYCx0L/m7mZSMA0GCSqGSIb3DQEBAQUABIIBAEWdqp3R0UuCooGdjzay
# /LnMOzbws6za+D93VTylGh5/HuoZTMm+UL3LZuLnr8GIbG9yUHBawu83LMpSp4LP
# bjEGOeOsNDQe/KG14f4IS00EHxMyLNWAldcty1IbzVfwaMpoQO6FKatdaKkOV1KF
# 9sNyhTdg3wgHRZG0uvvaftfmTl0TqOOMZmWifh20IGgPDtaBZrhiTGVPXPpImuD2
# J86Ydx8WCnviFDoAsCC3fMbhzpg5F+g+KE4X9uhmaeeAcWXvhWQa5wmiFqk6Bzfc
# Lcr0vUxWYRiA8GW0WzPmaJRyYxGQ1Adq9yEyoEs4NMkBwR1keduvV1z7Cmsae+jp
# PlI=
# SIG # End signature block
