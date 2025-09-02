# Test-DocumentationDrift-Quick.ps1
# Quick test suite for Unity-Claude-DocumentationDrift module
# Created: 2025-08-24
# Phase 5 - Quick System Testing

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$SaveResults,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\DocumentationDrift-QuickTest-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
)

Write-Host "🧪 Starting Unity-Claude-DocumentationDrift Quick Test Suite" -ForegroundColor Cyan
Write-Host "Started: $(Get-Date)" -ForegroundColor Gray

# Initialize test results
$TestResults = @{
    TestSuite = "Unity-Claude-DocumentationDrift-Quick"
    StartTime = Get-Date
    EndTime = $null
    TotalTests = 0
    PassedTests = 0
    FailedTests = 0
    Tests = @()
}

function Test-Function {
    param($Name, $TestFunction)
    
    $TestResults.TotalTests++
    Write-Host "  Testing $Name..." -ForegroundColor Yellow -NoNewline
    
    $testResult = @{
        Name = $Name
        Status = 'Unknown'
        Duration = $null
        Error = $null
        StartTime = Get-Date
    }
    
    try {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $result = & $TestFunction
        $stopwatch.Stop()
        
        $testResult.Duration = $stopwatch.ElapsedMilliseconds
        $testResult.Status = 'Passed'
        $TestResults.PassedTests++
        Write-Host " ✅ PASSED ($($stopwatch.ElapsedMilliseconds)ms)" -ForegroundColor Green
    } catch {
        $testResult.Status = 'Failed'
        $testResult.Error = $_.Exception.Message
        $TestResults.FailedTests++
        Write-Host " ❌ FAILED" -ForegroundColor Red
        Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    $TestResults.Tests += $testResult
}

# Import module
Write-Host "📦 Importing Unity-Claude-DocumentationDrift module..." -ForegroundColor Cyan
try {
    Import-Module "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-DocumentationDrift\Unity-Claude-DocumentationDrift.psd1" -Force
    Write-Host "✅ Module imported successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Module import failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host "`n🔧 Running Configuration Tests:" -ForegroundColor Cyan

Test-Function "Get-DocumentationDriftConfig" {
    $config = Get-DocumentationDriftConfig
    if (-not $config) { throw "Configuration is null or empty" }
    if (-not $config.DriftDetectionSensitivity) { throw "Missing DriftDetectionSensitivity" }
    return $config
}

Test-Function "Set-DocumentationDriftConfig" {
    $originalConfig = Get-DocumentationDriftConfig
    Set-DocumentationDriftConfig -DriftDetectionSensitivity 'High'
    $newConfig = Get-DocumentationDriftConfig
    if ($newConfig.DriftDetectionSensitivity -ne 'High') { 
        throw "Configuration not updated correctly" 
    }
    # Restore original
    Set-DocumentationDriftConfig -DriftDetectionSensitivity $originalConfig.DriftDetectionSensitivity
    return $true
}

Write-Host "`n📊 Running Core Function Tests:" -ForegroundColor Cyan

Test-Function "Clear-DriftCache" {
    Clear-DriftCache
    return $true
}

Test-Function "Get-DocumentationMetrics (empty)" {
    $metrics = Get-DocumentationMetrics
    if (-not $metrics) { throw "Metrics is null" }
    if (-not $metrics.ContainsKey('TotalFiles')) { throw "Missing TotalFiles metric" }
    return $metrics
}

Test-Function "Initialize-DocumentationDrift" {
    Initialize-DocumentationDrift -Force
    $config = Get-DocumentationDriftConfig
    if (-not $config) { throw "Initialization failed - no configuration" }
    return $true
}

Write-Host "`n🔗 Running Analysis Tests:" -ForegroundColor Cyan

Test-Function "Build-CodeToDocMapping (basic)" {
    # Test with a small subset to avoid timeout
    $result = Build-CodeToDocMapping -BasePath "." -IncludePatterns @("*.md") -MaxFiles 5
    if (-not $result) { throw "Mapping result is null" }
    return $result
}

Test-Function "Get-DriftDetectionResults (empty)" {
    $results = Get-DriftDetectionResults
    if ($null -eq $results) { throw "Results should not be null (empty is ok)" }
    return $results
}

Write-Host "`n✅ Running Quality Tests:" -ForegroundColor Cyan

Test-Function "Test-DocumentationQuality (basic)" {
    # Create a simple test markdown file
    $testFile = ".\test-doc-temp.md"
    "# Test Document`n`nThis is a test." | Out-File -FilePath $testFile -Encoding UTF8
    
    try {
        $result = Test-DocumentationQuality -FilePath $testFile
        if (-not $result) { throw "Quality test returned null" }
        return $result
    } finally {
        if (Test-Path $testFile) { Remove-Item $testFile -Force }
    }
}

Test-Function "Validate-DocumentationLinks (basic)" {
    # Create a simple test markdown file with a link
    $testFile = ".\test-links-temp.md"
    "# Test Links`n`n[Test Link](./test-target.md)" | Out-File -FilePath $testFile -Encoding UTF8
    
    try {
        $result = Validate-DocumentationLinks -FilePath $testFile
        if (-not $result) { throw "Link validation returned null" }
        return $result
    } finally {
        if (Test-Path $testFile) { Remove-Item $testFile -Force }
    }
}

# Finalize results
$TestResults.EndTime = Get-Date
$TestResults.Duration = ($TestResults.EndTime - $TestResults.StartTime).TotalSeconds

Write-Host "`n📋 Test Summary:" -ForegroundColor Cyan
Write-Host "  Total Tests: $($TestResults.TotalTests)" -ForegroundColor Gray
Write-Host "  Passed: $($TestResults.PassedTests)" -ForegroundColor Green
Write-Host "  Failed: $($TestResults.FailedTests)" -ForegroundColor $(if($TestResults.FailedTests -gt 0){'Red'}else{'Green'})
Write-Host "  Duration: $([math]::Round($TestResults.Duration, 2)) seconds" -ForegroundColor Gray

if ($TestResults.FailedTests -gt 0) {
    Write-Host "`n❌ Failed Tests:" -ForegroundColor Red
    $TestResults.Tests | Where-Object { $_.Status -eq 'Failed' } | ForEach-Object {
        Write-Host "  - $($_.Name): $($_.Error)" -ForegroundColor Red
    }
}

# Save results if requested
if ($SaveResults) {
    $TestResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "`n💾 Results saved to: $OutputPath" -ForegroundColor Cyan
}

Write-Host "`n✅ Quick test suite completed!" -ForegroundColor Green

# Return exit code based on test results
if ($TestResults.FailedTests -gt 0) {
    exit 1
} else {
    exit 0
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA1OPlz0qAbLwg6
# q/7//lK5/J2W9jIZUVj2cNAILldmxqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEILLpuBScsriSd4QYwfMH33xv
# 00k6SSN3X57I5so7K6/HMA0GCSqGSIb3DQEBAQUABIIBAIIYXX1hSLRcdepfS9eO
# 2T1ktdcBUcg3JH2HYp6MKiJIjmQb2cXywRFHmx/DGEnlaUQMjlsH+aKwXIEKerBZ
# V93VYvi+b+xAYAgTbL1GYSzCdf1zHhMTV6A7K4LnK8Ru8hq6K++kQbgkAP8cOJnp
# fH3K2su+0anf4Ei38WEFTGVcwTP3tOpeBLMgCMcy+lNcEt8Db+taRQwuzr/+6hE5
# HXpZrcyOMECzhIbGrhP4eA29s0Lk+OOoD1MPMbxQAN4Lvj0PWVKu6oDIzvO59ftd
# IzL05Ih0jMY+1J2ItEHn+BjJT9Aq8U13fW6EQWNEkIT1idogYPnwTGWC8aWDkE0t
# S2E=
# SIG # End signature block
