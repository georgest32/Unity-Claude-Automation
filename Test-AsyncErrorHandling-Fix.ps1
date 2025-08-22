# Test-AsyncErrorHandling-Fix.ps1
# Quick test to validate the PipelineResultTypes fix

Write-Host "=== Async Error Handling Fix Test ===" -ForegroundColor Cyan

try {
    # Import modules
    Import-Module ".\Modules\Unity-Claude-ParallelProcessing\Unity-Claude-ParallelProcessing.psd1" -Force
    Import-Module ".\Modules\Unity-Claude-ParallelProcessing\Unity-Claude-ErrorHandling.psd1" -Force
    Write-Host "Modules imported successfully" -ForegroundColor Green
    
    # Test 1: Simple successful operation
    Write-Host "`nTest 1: Simple successful operation" -ForegroundColor Yellow
    $ps1 = [PowerShell]::Create()
    $ps1.AddScript({ Write-Output "Success test"; return "OK" }) | Out-Null
    
    $result1 = Invoke-AsyncWithErrorHandling -PowerShellInstance $ps1 -TimeoutMs 5000
    Write-Host "  Result: Success=$($result1.Success), Duration=$($result1.Duration)ms, Output='$($result1.Output)'" -ForegroundColor Gray
    
    if ($result1.Success) {
        Write-Host "  Simple operation: PASS" -ForegroundColor Green
    } else {
        Write-Host "  Simple operation: FAIL" -ForegroundColor Red
    }
    
    # Test 2: Operation with error
    Write-Host "`nTest 2: Operation with error" -ForegroundColor Yellow
    $ps2 = [PowerShell]::Create()
    $ps2.AddScript({ Write-Error "Test error"; Write-Output "After error" }) | Out-Null
    
    $result2 = Invoke-AsyncWithErrorHandling -PowerShellInstance $ps2 -TimeoutMs 5000
    Write-Host "  Result: Success=$($result2.Success), Duration=$($result2.Duration)ms, Errors=$($result2.Errors.Count)" -ForegroundColor Gray
    
    if ($result2.Errors.Count -gt 0) {
        Write-Host "  Error detection: PASS (errors captured)" -ForegroundColor Green
    } else {
        Write-Host "  Error detection: FAIL (no errors captured)" -ForegroundColor Red
    }
    
    # Test 3: Operation with exception
    Write-Host "`nTest 3: Operation with exception" -ForegroundColor Yellow
    $ps3 = [PowerShell]::Create()
    $ps3.AddScript({ throw "Test exception" }) | Out-Null
    
    $result3 = Invoke-AsyncWithErrorHandling -PowerShellInstance $ps3 -TimeoutMs 5000
    Write-Host "  Result: Success=$($result3.Success), Duration=$($result3.Duration)ms" -ForegroundColor Gray
    
    if (-not $result3.Success) {
        Write-Host "  Exception handling: PASS (operation marked as failed)" -ForegroundColor Green
    } else {
        Write-Host "  Exception handling: FAIL (should have failed)" -ForegroundColor Red
    }
    
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== End Fix Test ===" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUGc7JP8n3R6GyyyWoEXzKXmwk
# wqSgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUk4Nf1P7Nb1AVp/Gip6OmBdVPWzgwDQYJKoZIhvcNAQEBBQAEggEAM+p/
# xtN4JsPNOP+gS+JHqLnWqxTnbJcUkKImPjV/0HpRknA2CrQdOPeM0HfB7d3BYPKA
# BoS6AjwWB6rHnWKyIk03GO8udAMpDFK3DWihzq92xchdlBhIx0JOTLI3UR8xayNT
# Sjc9gZ+uuEABWiXFmbIJHU0bIWIwlzQMWX/qh9WSH4z/dki+YMWF2Jd2VpDSqbgH
# +x+sUwW3QDzrqo8YWXc4x/8IFP7hnx0qGRD/s0oJVqvik+4cKMnT4+PHC9aGPMkH
# wgFWeYeEtZUT24tSptbwHOQobYDqBcwr7k9EUevvsOIrlOj3J6G7J3nyL+Le3HMU
# M2oP8q4lyTmO7yentw==
# SIG # End signature block
