# Test-WithLogging.ps1
# Test script with comprehensive logging to debug Test 3 failure
# Date: 2025-08-17

[CmdletBinding()]
param()

Write-Host "`n=== TEST WITH COMPREHENSIVE LOGGING ===`n" -ForegroundColor Cyan

# Initialize logging
$logFile = & (Join-Path $PSScriptRoot "Initialize-Logging.ps1") -Clear

Write-Host "Log file initialized: $logFile" -ForegroundColor Green
Write-Host "You can monitor this file in real-time with: Get-Content -Path '$logFile' -Wait -Tail 50`n" -ForegroundColor Gray

# Setup module path
$modulePath = Join-Path $PSScriptRoot 'Modules'
$env:PSModulePath = "$modulePath;$env:PSModulePath"

# Load module
Write-Host "Loading Unity-Claude-Learning-Simple module..." -ForegroundColor Gray
Import-Module Unity-Claude-Learning-Simple -Force
Write-Host "  Module loaded successfully`n" -ForegroundColor Green

# Initialize storage
Write-Host "Initializing learning storage..." -ForegroundColor Gray
Initialize-LearningStorage | Out-Null
Write-Host "  Storage initialized`n" -ForegroundColor Green

# Check current patterns
$config = Get-LearningConfig
$patternCount = 0
if (Test-Path $config.PatternsFile) {
    $jsonContent = Get-Content $config.PatternsFile -Raw | ConvertFrom-Json
    $patternCount = ($jsonContent | Get-Member -MemberType NoteProperty).Count
}
Write-Host "Patterns available: $patternCount`n" -ForegroundColor Gray

# Display all pattern IDs and their error messages
Write-Host "=== CURRENT PATTERNS ===" -ForegroundColor Yellow
$patterns = Get-Content $config.PatternsFile -Raw | ConvertFrom-Json
$patterns | Get-Member -MemberType NoteProperty | ForEach-Object {
    $patternId = $_.Name
    $pattern = $patterns.$patternId
    Write-Host "  ID: $patternId" -ForegroundColor Gray
    Write-Host "    Error: $($pattern.ErrorMessage)" -ForegroundColor DarkGray
    Write-Host "    Type: $($pattern.ErrorType)" -ForegroundColor DarkGray
}
Write-Host ""

# Now run the problematic Test 3
Write-Host "=== RUNNING TEST 3: Unknown Error Handling ===" -ForegroundColor Cyan
Write-Host "Testing with error: 'CS9999: Completely unknown error'" -ForegroundColor Yellow

# Add a separator in the log for clarity
"" | Out-File $logFile -Append
"="*80 | Out-File $logFile -Append
"TEST 3 EXECUTION - CS9999: Completely unknown error" | Out-File $logFile -Append
"="*80 | Out-File $logFile -Append

$fixes = Get-SuggestedFixes -ErrorMessage "CS9999: Completely unknown error" -MinSimilarity 65

Write-Host "`nTest Results:" -ForegroundColor Yellow
if ($fixes) {
    Write-Host "  ❌ UNEXPECTED - Found $($fixes.Count) pattern(s) for unknown error" -ForegroundColor Red
    Write-Host "`n  Matched patterns:" -ForegroundColor Red
    foreach ($fix in $fixes) {
        Write-Host "    Pattern ID: $($fix.PatternId)" -ForegroundColor Gray
        Write-Host "    Fix: $($fix.Fix)" -ForegroundColor Gray
        Write-Host "    Confidence: $($fix.Confidence)" -ForegroundColor Gray
    }
} else {
    Write-Host "  ✅ PASS - No patterns found (correct behavior)" -ForegroundColor Green
}

Write-Host "`n=== CHECKING LOG OUTPUT ===" -ForegroundColor Cyan
Write-Host "Last 20 log entries:" -ForegroundColor Yellow

# Display last 20 lines of the log
$logLines = Get-Content $logFile | Select-Object -Last 20
foreach ($line in $logLines) {
    if ($line -match "\[ERROR\]") {
        Write-Host $line -ForegroundColor Red
    } elseif ($line -match "\[WARN\]") {
        Write-Host $line -ForegroundColor Yellow
    } elseif ($line -match "\[INFO\]") {
        Write-Host $line -ForegroundColor Cyan
    } elseif ($line -match "\[DEBUG\]") {
        Write-Host $line -ForegroundColor Gray
    } else {
        Write-Host $line
    }
}

Write-Host "`n=== ANALYSIS ===" -ForegroundColor Cyan
Write-Host "The log file contains detailed trace information about the matching process." -ForegroundColor Gray
Write-Host "Review the log file to understand why CS9999 might be matching patterns:" -ForegroundColor Gray
Write-Host "  $logFile" -ForegroundColor Green
Write-Host ""
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUaCHq9mXQE/DTQca+l/5egPy5
# iBCgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUB9pNfOlrmOP7V+b7ZYQAccAa2fAwDQYJKoZIhvcNAQEBBQAEggEAA/a9
# 2pqy63W4MBHudfFDkm66PmSGGVQgmPSL3RS0mK+YDnt/6mPmnIKVl75/HtAlmmRE
# e4XcgQrtxj4kHX9/aLFiquKz3LZ+pUQjp5jZ8X4pI99iZ3Q7N8hhFG0F46r4IIOh
# cwsw9o1+hzz4pWawj9z5kWjGRT6mPLbLpD3K+7hYmsWyQIcDeeVOlqkWMgTjw8dn
# 6UmUHFKx9IxzEpTsfjwDMUs8XNYrWkuxXwpm/WpHaUvB0wp8xOLQBNcJOg0EWyhC
# pm7qHI5TUtpAUvWRhsfFy7mXiLpuvM3a94BOlm/3rfA6OFTYi6hJVmaphfRXC7Gv
# ZRazerPyIOLfSXbrLw==
# SIG # End signature block
