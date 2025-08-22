# Test-WeightedClassification.ps1
# Test the weighted pattern classification logic

Write-Host "Testing Weighted Classification Logic" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# Test case: CS0246 error text
$testText = "CS0246: The type or namespace could not be found. Please check your using statements."

Write-Host ""
Write-Host "Test Text: $testText" -ForegroundColor Yellow
Write-Host ""

# Simulate ErrorDetection node testing
$errorPatterns = @("error", "exception", "failed", "failure", "CS\d{4}", "issue", "problem")
$errorWeights = @(0.3, 0.3, 0.4, 0.4, 0.9, 0.3, 0.3)

Write-Host "ErrorDetection Node Analysis:" -ForegroundColor Cyan
$totalWeight = 0.0
$matchedWeight = 0.0

for ($i = 0; $i -lt $errorPatterns.Count; $i++) {
    $pattern = $errorPatterns[$i]
    $weight = $errorWeights[$i]
    $totalWeight += $weight
    
    # Test pattern
    $matched = $false
    if ($pattern -match "\\d") {
        # Regex pattern (like CS\d{4})
        $matched = $testText -match $pattern
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
$minConfidence = 0.25

Write-Host ""
Write-Host "Results:" -ForegroundColor Yellow
Write-Host "  Total Weight: $totalWeight" -ForegroundColor Gray
Write-Host "  Matched Weight: $matchedWeight" -ForegroundColor Gray
Write-Host "  Confidence: $confidence" -ForegroundColor Gray
Write-Host "  Min Confidence: $minConfidence" -ForegroundColor Gray
Write-Host "  Passes Threshold: $(if ($confidence -ge $minConfidence) { 'YES' } else { 'NO' })" -ForegroundColor $(if ($confidence -ge $minConfidence) { 'Green' } else { 'Red' })

if ($confidence -ge $minConfidence) {
    Write-Host ""
    Write-Host "SUCCESS: ErrorDetection should classify as 'Error'" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "FAILURE: Would default to 'Information'" -ForegroundColor Red
}

Write-Host ""
Write-Host "Test complete" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU7yQAXUwCyALj9s3UUDi16o2w
# /NmgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUhFU+P3pDuidMOlIZ+S2pguvSRgEwDQYJKoZIhvcNAQEBBQAEggEATjJF
# 3I3KEFwtBX/dErMr/3/SrY/QSbZvfGZUQyhRmhK3r1HJTmSN+n7PnvxtO7qTj+OY
# CDul0QcpzLMdpzZG8zTtL0aY3CvEocb6SrNo37m6py4inXFhEqXcxa0E7sGmbp43
# GBcIFLYYFBO9K/+WEI+0N3hnJsCrvPcvChLqivLQ2YVaaJXyPulToRJKUH7RDuyA
# 6ZDG2JnRGiZi4FPWsfCUVbU5krX4uswn4LFhKYxmAFCVuE2L6PbpqvWuCcKZ8P2c
# 9p46kShBsZkjib5JuIVua6fA/cnDlmIaPptDhmfKCSKbOZHU+UrV3k0NvBe2G9yW
# /wcsZkmuS4nBS0CH3Q==
# SIG # End signature block
