# Quick test of Decision Engine functionality
# Test core functions after module import

Write-Host "Testing Decision Engine Core Functions:" -ForegroundColor Cyan

# Import module
Get-Module Unity-Claude-CLIOrchestrator | Remove-Module -Force -ErrorAction SilentlyContinue
Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator.psd1" -Force -Global

# Test function availability
Write-Host "  Function Availability Check:" -ForegroundColor Yellow
$functions = @('Invoke-RuleBasedDecision', 'Test-SafetyValidation', 'Test-SafeFilePath', 'Test-SafeCommand')
foreach ($func in $functions) {
    $cmd = Get-Command $func -ErrorAction SilentlyContinue
    if ($cmd) {
        Write-Host "    ${func}: Available" -ForegroundColor Green
    } else {
        Write-Host "    ${func}: NOT AVAILABLE" -ForegroundColor Red
    }
}

# Create test data
$testAnalysisResult = @{
    Recommendations = @(
        @{ 
            Type = "CONTINUE"
            Action = "Continue processing" 
            Confidence = 0.90
            Priority = 1 
        }
    )
    ConfidenceAnalysis = @{
        OverallConfidence = 0.85
        QualityRating = "High"
    }
    Entities = @{
        FilePaths = @()
        PowerShellCommands = @()
    }
    ProcessingSuccess = $true
    TotalProcessingTimeMs = 250
}

Write-Host ""
Write-Host "  Functional Tests:" -ForegroundColor Yellow

# Test 1: Rule-Based Decision
Write-Host "    Test 1: Rule-Based Decision" -ForegroundColor Cyan
try {
    $decision = Invoke-RuleBasedDecision -AnalysisResult $testAnalysisResult -DryRun
    Write-Host "      Success: Decision = $($decision.Decision)" -ForegroundColor Green
} catch {
    Write-Host "      Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Safety Validation
Write-Host "    Test 2: Safety Validation" -ForegroundColor Cyan
try {
    $safety = Test-SafetyValidation -AnalysisResult $testAnalysisResult
    Write-Host "      Success: IsSafe = $($safety.IsSafe)" -ForegroundColor Green
} catch {
    Write-Host "      Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: File Path Safety
Write-Host "    Test 3: File Path Safety" -ForegroundColor Cyan
try {
    $pathSafety = Test-SafeFilePath -FilePath "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Test.ps1"
    Write-Host "      Success: Safe path = $($pathSafety.IsSafe)" -ForegroundColor Green
} catch {
    Write-Host "      Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: Unsafe Path Detection
Write-Host "    Test 4: Unsafe Path Detection" -ForegroundColor Cyan
try {
    $unsafePath = Test-SafeFilePath -FilePath "C:\Windows\System32\cmd.exe"
    Write-Host "      Success: Unsafe path detected = $(-not $unsafePath.IsSafe)" -ForegroundColor Green
} catch {
    Write-Host "      Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Quick Decision Engine test completed!" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAseFmwfo+K/XZe
# QLUYp7eZlhnFoLcYYNEmSkONG78v8aCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIClKgxI+HNSy6DnYQB0oKNe4
# 1H73+YJ9OvDlJEyW9p5PMA0GCSqGSIb3DQEBAQUABIIBAGAUlQPQ/H6J6QLIlIfp
# eLrOzxPDJt2dn6A/QcExTry+N+nx76PYSHXDD6dXi9gEK8oxD8c/pDJMi1N+YyNO
# xtLx0uDS8aeqRC9QcE7x8cM+cVfoc6kocXZuO675l3p82NlfuLrXKMAQPLtr7TDO
# 8ncN1zrGy3dTQXVPZB0lreMn8Igc0ZXkz80ThkA72xizD8Sni11lPEzIH9y0GipY
# 9QOxn6rmQIFFM1FMqxKg0qRmW2HOi8+hCMgJIfed13VnKaE6mHcrQJCTb80QzI41
# 56mrE2S43GkmTNCtCJY9XyJO2KqKNrxZGwBqUwZeHw1Pqmds/8t7CUVqRYXMO9LR
# sDY=
# SIG # End signature block
