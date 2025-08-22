# Debug-Simple-Function-Call.ps1
# Isolate the exact issue with New-ConcurrentQueue returning null

Write-Host "=== Simple Function Call Debug ===" -ForegroundColor Cyan

# Test 1: Import and call function
Write-Host "`nTest 1: Import module and call function" -ForegroundColor Yellow
try {
    Import-Module ".\Modules\Unity-Claude-ParallelProcessing\Unity-Claude-ConcurrentCollections.psd1" -Force
    Write-Host "Module imported successfully" -ForegroundColor Green
    
    # Call function and capture result
    Write-Host "Calling New-ConcurrentQueue..." -ForegroundColor Gray
    $result = New-ConcurrentQueue
    Write-Host "Function call completed" -ForegroundColor Gray
    
    # Analyze result
    Write-Host "Result analysis:" -ForegroundColor Yellow
    Write-Host "  Result: '$result'" -ForegroundColor Gray
    Write-Host "  Is null: $($null -eq $result)" -ForegroundColor Gray
    Write-Host "  Is empty string: $($result -eq '')" -ForegroundColor Gray
    Write-Host "  Type: $($result.GetType().FullName)" -ForegroundColor Gray
    
    if ($result) {
        Write-Host "SUCCESS: Function returned valid object" -ForegroundColor Green
        # Test basic operation
        $result.Enqueue("test")
        Write-Host "  Enqueue test: SUCCESS" -ForegroundColor Green
    } else {
        Write-Host "FAILED: Function returned null or empty" -ForegroundColor Red
    }
} catch {
    Write-Host "EXCEPTION: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== End Simple Debug ===" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUKpuUyADKfDbz7O9/82D8uDJM
# J66gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUGG4vFddMNp5g2lRfIk9F3OKDUZ4wDQYJKoZIhvcNAQEBBQAEggEADzNk
# 5gDVFIHTUUwXyz9AYpcXfsdfl4L7Tn8RAa497ONWi/McmQ5C0lV88YfMMPXhigx8
# AQj8R+2ACEJYb43rxWMBO4yeus4qmWGTG9E15iTBE0xz/hxm6xKjrd4tVSc/JASl
# 2shUTlo7z9UWnB+UefqbkoB97j/1sJeT+cK3iJVmcb14y4q0kCU+IRmIovAqtfza
# mnf1bSabAGo4JRu8Jx5oQFP0NVHr+0SnBmaXUF1xNFF2yye0Sy+k3aYs7b/kWLeY
# co79A3D3Gior3bOogocwgvWbpavLJeE5gUzyHSsRD5cD+Yqf8pDfCq/H7h9ydDv/
# UMw+Mk2yuZCpoylBQw==
# SIG # End signature block
