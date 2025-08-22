# Debug-InstructionDetection-Node.ps1
# Debug why RECOMMENDED text doesn't match InstructionDetection node

Write-Host "Debug InstructionDetection Node" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan

$testText = "RECOMMENDED: TEST - Please run the validation script to check functionality"

Write-Host ""
Write-Host "Test Text: $testText" -ForegroundColor Yellow
Write-Host ""

# Simulate InstructionDetection node testing
$instructionPatterns = @("RECOMMENDED:", "please", "you should", "try", "run", "execute", "install", "create", "update")
$instructionWeights = @(0.9, 0.6, 0.7, 0.5, 0.5, 0.5, 0.4, 0.4, 0.4)
$minConfidence = 0.4

Write-Host "InstructionDetection Node Analysis:" -ForegroundColor Cyan
$totalWeight = 0.0
$matchedWeight = 0.0

for ($i = 0; $i -lt $instructionPatterns.Count; $i++) {
    $pattern = $instructionPatterns[$i]
    $weight = $instructionWeights[$i]
    $totalWeight += $weight
    
    # Test pattern - handle different pattern types
    $matched = $false
    if ($pattern -match ":") {
        # Pattern with colon (like RECOMMENDED:)
        $matched = $testText -match [regex]::Escape($pattern)
    } else {
        # Simple word pattern
        $matched = $testText -match "\b$pattern\b"
    }
    
    if ($matched) {
        $matchedWeight += $weight
        Write-Host "  MATCH: '$pattern' (weight: $weight)" -ForegroundColor Green
    } else {
        Write-Host "  NO MATCH: '$pattern' (weight: $weight)" -ForegroundColor Red
    }
}

$confidence = [Math]::Round($matchedWeight / $totalWeight, 2)

Write-Host ""
Write-Host "Results:" -ForegroundColor Yellow
Write-Host "  Total Weight: $totalWeight" -ForegroundColor Gray
Write-Host "  Matched Weight: $matchedWeight" -ForegroundColor Gray
Write-Host "  Confidence: $confidence" -ForegroundColor Gray
Write-Host "  Min Confidence: $minConfidence" -ForegroundColor Gray
Write-Host "  Passes Threshold: $(if ($confidence -ge $minConfidence) { 'YES' } else { 'NO' })" -ForegroundColor $(if ($confidence -ge $minConfidence) { 'Green' } else { 'Red' })

if ($confidence -ge $minConfidence) {
    Write-Host ""
    Write-Host "SUCCESS: InstructionDetection should classify as 'Instruction'" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "FAILURE: Would default to 'Information'" -ForegroundColor Red
    Write-Host "ISSUE: Need to investigate pattern matching or threshold" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Additional Tests:" -ForegroundColor Cyan

# Test individual patterns manually
Write-Host "Manual Pattern Tests:" -ForegroundColor Yellow
$patterns = @("RECOMMENDED:", "please", "run")
foreach ($testPattern in $patterns) {
    $result1 = $testText -match [regex]::Escape($testPattern)
    $result2 = $testText -match "\b$testPattern\b"
    $result3 = $testText.Contains($testPattern)
    
    Write-Host "  Pattern '$testPattern':" -ForegroundColor Gray
    Write-Host "    Escaped match: $result1" -ForegroundColor Gray
    Write-Host "    Word boundary: $result2" -ForegroundColor Gray
    Write-Host "    Contains: $result3" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Debug complete" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUdlBeX5mb38/TuLBq64VNDVVG
# i5mgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUuD/3FnV3UE0USheXzMzPzUMTpQ0wDQYJKoZIhvcNAQEBBQAEggEAWxH1
# hN0XE4gXctz8a63PfkVhUn4Dvy1QKjlKNCjvInlIUzRqtbNpiVK5TrogH31LbP1g
# gkEDo0UUGOSBx1697HbA9xxEjSLhZeuXGAdqYFOaARWkUhGzQeJ1IHdmyh9QDmA8
# ivGHEOqqNwxOc01hHbNR9d+SnbYpjBkMn4HNnEvmoX1s//OBuEGJH6ct8fPX87Dx
# 3bCHuByWZ3hup2l+5QtB8bBj+lq5jFYOakqH8o/9xEO8h3iQiKb7sLz399EGjhZD
# WOJOsytHKtm8xqhj2P/OGh7sVh08f0tufSD7fi5vkyM1YY2ubRoMe2FndP6FOVs7
# 5O9QjejH8kUMeagurA==
# SIG # End signature block
