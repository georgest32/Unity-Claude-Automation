# Verify Fuzzy Matching Functions Export Correctly
# This script verifies that the Levenshtein distance functions are properly exported from the module

Write-Host "`n=== Verifying Module Exports ===" -ForegroundColor Cyan

# First, remove the module if already loaded
Write-Host "Removing existing module if loaded..." -ForegroundColor Yellow
Remove-Module Unity-Claude-Learning-Simple -Force -ErrorAction SilentlyContinue

# Test the manifest syntax
Write-Host "`nTesting module manifest syntax..." -ForegroundColor Yellow
$manifestPath = "$PSScriptRoot\..\Modules\Unity-Claude-Learning-Simple\Unity-Claude-Learning-Simple.psd1"
try {
    $manifest = Test-ModuleManifest -Path $manifestPath -ErrorAction Stop
    Write-Host "[PASSED] Manifest syntax is valid" -ForegroundColor Green
    Write-Host "Module Version: $($manifest.Version)" -ForegroundColor Gray
} catch {
    Write-Host "[FAILED] Manifest syntax error: $_" -ForegroundColor Red
    exit 1
}

# Import the module
Write-Host "`nImporting module..." -ForegroundColor Yellow
try {
    Import-Module $manifestPath -Force -ErrorAction Stop
    Write-Host "[PASSED] Module imported successfully" -ForegroundColor Green
} catch {
    Write-Host "[FAILED] Failed to import module: $_" -ForegroundColor Red
    exit 1
}

# Check exported commands
Write-Host "`nChecking exported commands..." -ForegroundColor Yellow
$module = Get-Module Unity-Claude-Learning-Simple
$exportedCommands = $module.ExportedCommands.Keys

# Define expected fuzzy matching functions
$expectedFunctions = @(
    'Get-LevenshteinDistance',
    'Get-StringSimilarity',
    'Test-FuzzyMatch',
    'Find-SimilarPatterns',
    'Clear-LevenshteinCache',
    'Get-LevenshteinCacheInfo'
)

# Check each function
$allFound = $true
Write-Host "`nFuzzy Matching Functions Status:" -ForegroundColor Cyan
foreach ($func in $expectedFunctions) {
    if ($exportedCommands -contains $func) {
        Write-Host "  [✓] $func - Exported" -ForegroundColor Green
    } else {
        Write-Host "  [✗] $func - NOT FOUND" -ForegroundColor Red
        $allFound = $false
    }
}

# Additional exported functions check
Write-Host "`nOther Exported Functions:" -ForegroundColor Cyan
$otherFunctions = @(
    'Initialize-LearningStorage',
    'Add-ErrorPattern',
    'Get-SuggestedFixes',
    'Apply-AutoFix',
    'Get-LearningReport',
    'Export-LearningReport',
    'Set-LearningConfig',
    'Get-LearningConfig',
    'Update-FixSuccess',
    'Get-CodeAST',
    'Find-CodePattern',
    'Get-ASTElements',
    'Test-CodeSyntax',
    'Get-UnityErrorPattern'
)

foreach ($func in $otherFunctions) {
    if ($exportedCommands -contains $func) {
        Write-Host "  [✓] $func" -ForegroundColor DarkGray
    } else {
        Write-Host "  [✗] $func - Missing" -ForegroundColor DarkRed
    }
}

# Test actual function calls
Write-Host "`n=== Testing Function Calls ===" -ForegroundColor Cyan

# Test Get-LevenshteinDistance
Write-Host "`nTesting Get-LevenshteinDistance..." -ForegroundColor Yellow
try {
    $distance = Get-LevenshteinDistance -String1 "kitten" -String2 "sitting"
    if ($distance -eq 3) {
        Write-Host "[PASSED] Get-LevenshteinDistance works correctly (distance = $distance)" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] Get-LevenshteinDistance returned unexpected value: $distance (expected 3)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "[FAILED] Get-LevenshteinDistance error: $_" -ForegroundColor Red
}

# Test Get-StringSimilarity
Write-Host "`nTesting Get-StringSimilarity..." -ForegroundColor Yellow
try {
    $similarity = Get-StringSimilarity -String1 "hello" -String2 "hello"
    if ($similarity -eq 100) {
        Write-Host "[PASSED] Get-StringSimilarity works correctly (similarity = $similarity%)" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] Get-StringSimilarity returned unexpected value: $similarity% (expected 100)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "[FAILED] Get-StringSimilarity error: $_" -ForegroundColor Red
}

# Test Test-FuzzyMatch
Write-Host "`nTesting Test-FuzzyMatch..." -ForegroundColor Yellow
try {
    $match = Test-FuzzyMatch -String1 "GameObject" -String2 "GameObect" -MinSimilarity 80
    if ($match) {
        Write-Host "[PASSED] Test-FuzzyMatch works correctly (match = $match)" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] Test-FuzzyMatch returned false for similar strings" -ForegroundColor Yellow
    }
} catch {
    Write-Host "[FAILED] Test-FuzzyMatch error: $_" -ForegroundColor Red
}

# Summary
Write-Host "`n=== VERIFICATION SUMMARY ===" -ForegroundColor Cyan
if ($allFound) {
    Write-Host "[SUCCESS] All fuzzy matching functions are properly exported!" -ForegroundColor Green
    Write-Host "Total exported commands: $($exportedCommands.Count)" -ForegroundColor Gray
    Write-Host "`nYou can now run the full test suite: .\Testing\Test-FuzzyMatching.ps1" -ForegroundColor Yellow
} else {
    Write-Host "[FAILURE] Some functions are not exported. Check the manifest file." -ForegroundColor Red
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUnWnVUDjhBjZIs8vQJNnDCXLI
# 7HWgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQULlV0ahPQox0IBFCSeyLCv/7IcyswDQYJKoZIhvcNAQEBBQAEggEAOMcu
# WUMi0fOLUb1dP3d6eVskMMqi74cMFdHwC/UgxiB3jcIp9zztuTRDoI2Xf9oExFQv
# ZNTXbIqlRjHk6QFHvoJ1D3A+KzktRrdBrhOae15sGzYoymWbMsfUlOOHiu9MItAM
# MKEDFyog87IY5l6bcnMVaGXP5P5P9EhmCgBjXI9LsHxQRSHfmU0GgNFE8+tVr7an
# iBGtoV+WJ0H5V8qWWd1oy9SJXOJFkhwVEYrF1/XL/1NquoG8XBbXf1TF97ENQDPk
# ZoKJXtYPuSHN40W0S3saRvxEQDfCV0M281pygEMtQCYfBPgHmvaxpUDZ7HLpQtGK
# XdxqLlRqyWRfvQsT/w==
# SIG # End signature block
