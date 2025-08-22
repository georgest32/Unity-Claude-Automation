# Debug-Classification-Call.ps1
# Debug the exact classification call to trace execution path

Write-Host "Debug Classification Call Test" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan

# Import the module first
try {
    Import-Module "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-AutonomousAgent\Unity-Claude-AutonomousAgent-Refactored.psd1" -Force
    Write-Host "Module imported successfully" -ForegroundColor Green
} catch {
    Write-Host "Module import failed: $_" -ForegroundColor Red
    exit 1
}

# Test the exact same call as the failing test
$testResponse = "CS0246: The type or namespace could not be found. Please check your using statements."

Write-Host ""
Write-Host "Testing with UseAdvancedTree parameter:" -ForegroundColor Yellow
Write-Host "Text: $testResponse" -ForegroundColor Gray
Write-Host ""

try {
    # Enable debug output
    $DebugPreference = "Continue"
    
    Write-Host "Calling Invoke-ResponseClassification..." -ForegroundColor Cyan
    $result = Invoke-ResponseClassification -ResponseText $testResponse -UseAdvancedTree
    
    Write-Host ""
    Write-Host "Results:" -ForegroundColor Yellow
    Write-Host "  Success: $($result.Success)" -ForegroundColor Gray
    Write-Host "  Category: $($result.Classification.Category)" -ForegroundColor Gray
    Write-Host "  Confidence: $($result.Classification.Confidence)" -ForegroundColor Gray
    Write-Host "  Intent: $($result.Classification.Intent)" -ForegroundColor Gray
    Write-Host "  Sentiment: $($result.Classification.Sentiment)" -ForegroundColor Gray
    Write-Host "  Decision Path: $($result.Classification.DecisionPath -join ' -> ')" -ForegroundColor Gray
    
    # Expected result check
    if ($result.Classification.Category -eq "Error") {
        Write-Host ""
        Write-Host "SUCCESS: Correctly classified as Error" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "FAILURE: Expected Error, got $($result.Classification.Category)" -ForegroundColor Red
    }
    
} catch {
    Write-Host "Error during classification: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "Debug test complete" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUR1LTTNgYm0hJIg07fZ8Br+2L
# gfWgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUIwusUA/tS8pd3o9R9O9AMdOwMFMwDQYJKoZIhvcNAQEBBQAEggEAUk54
# Ev0omChJ+ZXtKcmOOEzd3yY648ttsdMChHYgMZ+11YgYNvlyh9yUkMEZRC1MB6jT
# YyoYQ6ls/1reVg1m6afc6YKy//FOSXKj4eCwufXW/c9cKntG9tmfTIyuT1Q77CE2
# iKs4r+JvzJU0zNKhYWK8LTl2IZGLYXMv2KCiu+ymsSeZfPBI9tv8QbFc8Zmla1zj
# 90LhUFR43YIJD2GUvikZiuPhJZN9wCjxsWHS2ViqUvV9ET09pA1sHYB5Ig+uc/3Y
# CwKeIIbzkKEVB9DHbIL2KNn2DoZ8l9MuP79r6EOC4NkQe3Qy4D0d+U1k+69oqkT+
# DpHG/5lhB74B7zkF8A==
# SIG # End signature block
