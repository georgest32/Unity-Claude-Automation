# Test-LearningSystem.ps1
# Manual test of the learning system with a known Unity error
# Date: 2025-08-17

[CmdletBinding()]
param()

Write-Host "=== Testing Unity-Claude Learning System ===" -ForegroundColor Cyan
Write-Host ""

# Load the learning module
$modulePath = Join-Path $PSScriptRoot 'Modules'
if ($env:PSModulePath -notlike "*$modulePath*") {
    $env:PSModulePath = "$modulePath;$env:PSModulePath"
}

Import-Module Unity-Claude-Learning-Simple -Force

# Initialize learning system
Initialize-LearningStorage | Out-Null

# Define our test error
$testError = @{
    ErrorType = "CS0029"
    Message = "Cannot implicitly convert type 'UnityEngine.GameObject' to 'UnityEngine.Transform'"
    FilePath = "Assets/Scripts/TestLearningSimple.cs"
    Line = 8
}

Write-Host "Test Error:" -ForegroundColor Yellow
Write-Host "  Type: $($testError.ErrorType)" -ForegroundColor Gray
Write-Host "  Message: $($testError.Message)" -ForegroundColor Gray
Write-Host "  File: $($testError.FilePath)" -ForegroundColor Gray
Write-Host "  Line: $($testError.Line)" -ForegroundColor Gray
Write-Host ""

# Step 1: Check if pattern exists
Write-Host "Step 1: Checking for existing patterns..." -ForegroundColor Yellow
$suggestions = Get-SuggestedFixes -ErrorMessage $testError.Message -MinSimilarity 60

if ($suggestions -and $suggestions.Count -gt 0) {
    Write-Host "  [OK] Found $($suggestions.Count) pattern match(es)!" -ForegroundColor Green
    foreach ($suggestion in $suggestions | Select-Object -First 3) {
        Write-Host "    Pattern: $($suggestion.PatternId)" -ForegroundColor DarkGray
        Write-Host "    Similarity: $([Math]::Round($suggestion.Similarity, 2))%" -ForegroundColor DarkGray
        Write-Host "    Fix: $($suggestion.Fix)" -ForegroundColor Cyan
        Write-Host ""
    }
}
else {
    Write-Host "  [X] No pattern matches found" -ForegroundColor DarkYellow
    Write-Host ""
    
    # Step 2: Add a new pattern
    Write-Host "Step 2: Learning from this error..." -ForegroundColor Yellow
    
    $fix = "Add .transform to GameObject.Find() or change variable type to GameObject"
    $patternId = Add-ErrorPattern `
        -ErrorMessage $testError.Message `
        -ErrorType $testError.ErrorType `
        -Fix $fix `
        -Context @{Source = "Manual test"; File = $testError.FilePath}
    
    if ($patternId) {
        Write-Host "  [OK] Pattern learned! ID: $patternId" -ForegroundColor Green
        Write-Host "    Fix stored: $fix" -ForegroundColor DarkGreen
    }
    else {
        Write-Host "  [X] Failed to learn pattern" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Step 3: Testing pattern recall..." -ForegroundColor Yellow

# Test with a slightly different error message
$similarError = "Cannot implicitly convert type 'UnityEngine.GameObject' to 'UnityEngine.Transform'"
$newSuggestions = Get-SuggestedFixes -ErrorMessage $similarError -MinSimilarity 50

if ($newSuggestions -and $newSuggestions.Count -gt 0) {
    Write-Host "  [OK] Pattern matching works!" -ForegroundColor Green
    $best = $newSuggestions | Select-Object -First 1
    Write-Host "    Best match: $([Math]::Round($best.Similarity, 2))% similarity" -ForegroundColor DarkGreen
    Write-Host "    Suggested fix: $($best.Fix)" -ForegroundColor Cyan
}
else {
    Write-Host "  [X] Pattern recall failed" -ForegroundColor Red
}

Write-Host ""
Write-Host "Step 4: Checking learning metrics..." -ForegroundColor Yellow

$config = Get-LearningConfig
if (Test-Path $config.PatternsFile) {
    $patterns = Get-Content $config.PatternsFile -Raw | ConvertFrom-Json
    $patternCount = ($patterns | Get-Member -MemberType NoteProperty).Count
    Write-Host "  Total patterns in database: $patternCount" -ForegroundColor Green
    
    # Show recent patterns
    Write-Host "  Recent patterns:" -ForegroundColor Gray
    $patterns | Get-Member -MemberType NoteProperty | Select-Object -Last 3 | ForEach-Object {
        $pattern = $patterns.$($_.Name)
        Write-Host "    - $($pattern.ErrorType): $($pattern.ErrorMessage.Substring(0, [Math]::Min(50, $pattern.ErrorMessage.Length)))..." -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "=== Learning System Test Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Fix the error in TestLearningSimple.cs" -ForegroundColor White
Write-Host "2. Run this test again to see if it suggests the fix" -ForegroundColor White
Write-Host "3. Mark the fix as successful to improve pattern confidence" -ForegroundColor White
Write-Host ""
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUKnDDWOokJfXiDx14yXbk3EL6
# MJygggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUspgHEQAqYy+qnCL2QZhBzKFgd+QwDQYJKoZIhvcNAQEBBQAEggEAlaTf
# VcbrzRIZ3FsVOQDheFnjxocw7ExWYZ/oJ8jCU1WkOeKLCLhhNOzI+6JYANNU5f0g
# +FV33sC4d6BsMbfY0Sqy8GuOCyvpiYuMzaiHxBPwtu3jGNK1Bc6N6wvflhlv8xN/
# sNr9nd46beLIcIrs7m82qqZlpgLSymILKFb/jhMgS7RbW4yCOtV+jR2jUvKXE3tt
# I8BcwIEgBEHtm+pvfUqjDS1BefCIBlGT52r7Dpig9YwWGiYl0Ivt+BeWUQAL424V
# 2UeDnpkPiMKgcBZocC08936jaJPEa3GG9c33LhcWMtos7QVA0NPBbGBeY/wcu04L
# hSxhtLv0QITJSNd1pw==
# SIG # End signature block
