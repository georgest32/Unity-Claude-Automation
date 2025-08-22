# Test-ClaudePiping.ps1
# Test different piping methods with Claude CLI

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Testing Claude CLI Piping" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Test 1: Simple echo test" -ForegroundColor Yellow
Write-Host "Command: echo 'What is 2+2?' | claude -p 'Answer this question'" -ForegroundColor Gray
$result1 = echo "What is 2+2?" | & claude -p "Answer this question" 2>&1
Write-Host "Result: $result1" -ForegroundColor Green
Write-Host ""

Write-Host "Test 2: Direct string piping" -ForegroundColor Yellow
Write-Host "Command: 'What is 3+3?' | claude -p 'Calculate'" -ForegroundColor Gray
$result2 = "What is 3+3?" | & claude -p "Calculate" 2>&1
Write-Host "Result: $result2" -ForegroundColor Green
Write-Host ""

Write-Host "Test 3: Multi-line content" -ForegroundColor Yellow
$multiline = @"
Line 1: Hello
Line 2: World
Line 3: Test
"@
Write-Host "Command: [multiline] | claude -p 'Count the lines'" -ForegroundColor Gray
$result3 = $multiline | & claude -p "Count the lines in this text" 2>&1
Write-Host "Result: $result3" -ForegroundColor Green
Write-Host ""

Write-Host "Test 4: File content piping" -ForegroundColor Yellow
$testFile = Join-Path $PSScriptRoot "test_content.txt"
"This is test content from a file" | Set-Content $testFile
Write-Host "Command: Get-Content test_content.txt | claude -p 'What does this say?'" -ForegroundColor Gray
$result4 = Get-Content $testFile | & claude -p "What does this say?" 2>&1
Write-Host "Result: $result4" -ForegroundColor Green
Remove-Item $testFile -Force
Write-Host ""

Write-Host "Test 5: Error simulation" -ForegroundColor Yellow
$errorText = @"
[ERROR] CS0246: The type or namespace name 'TestClass' could not be found
[ERROR] CS0117: 'GameObject' does not contain a definition for 'TestMethod'
"@
Write-Host "Command: [error text] | claude -p 'Fix these C# errors'" -ForegroundColor Gray
$result5 = $errorText | & claude -p "Fix these C# compilation errors" 2>&1
Write-Host "Result: $result5" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " All Tests Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Check if any test worked
$allResults = @($result1, $result2, $result3, $result4, $result5)
$successCount = ($allResults | Where-Object { $_ -and $_.Length -gt 10 }).Count

Write-Host ""
if ($successCount -gt 0) {
    Write-Host "✅ $successCount/5 tests succeeded!" -ForegroundColor Green
    Write-Host "Claude CLI piping is working!" -ForegroundColor Green
} else {
    Write-Host "❌ No tests succeeded" -ForegroundColor Red
    Write-Host "Claude CLI may not support piping on this system" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Alternative: Use the interactive mode" -ForegroundColor Cyan
    Write-Host "Run: claude chat" -ForegroundColor White
    Write-Host "Then paste your content manually" -ForegroundColor White
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU0YVp5rrzDEVWPksk6j1EaaZM
# KH+gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUQuziutHAQ772ta8yMji9yf3EYb8wDQYJKoZIhvcNAQEBBQAEggEAAxMb
# JRCAFIbDqFgk0ta04jLXnNYycTU3IV/dNsCkDRP4zS+qoMag5k+0Gy3jD1MyrAsT
# ies+Q4aTUSAXgEaJnNT7XgmvckPXV8tZ56HPtg7TXLfYZOaR33zXYefsZqhdoov/
# czp+MHkcJYxSzbJCST8ZCItLTAFEosBJSjO/uTWPzzzkR7DnUrHV9JBxV+Y3EN11
# HT3Bbn38aZdPMY/4mBH/vMmcTekOMo8xF2EP4sPjaPlSJ/i0tS15HKeCSkFfDzvh
# 6Vrjq209ggBxge9vW2QH+LgOTe2XJinzI/PrFe4PJa8QpYJZwD+Y51J39qWWt0N/
# PwNcF0o7Tw+92DJNNQ==
# SIG # End signature block
