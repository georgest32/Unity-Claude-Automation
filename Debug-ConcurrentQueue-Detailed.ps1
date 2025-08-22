# Debug-ConcurrentQueue-Detailed.ps1
# Detailed debug of New-ConcurrentQueue function

Write-Host "=== Detailed ConcurrentQueue Debug ===" -ForegroundColor Cyan

# Import module
Import-Module ".\Modules\Unity-Claude-ParallelProcessing\Unity-Claude-ConcurrentCollections.psd1" -Force -Verbose
Write-Host "Module imported" -ForegroundColor Green

# Test the function step by step
Write-Host "`nTesting New-ConcurrentQueue function..." -ForegroundColor Yellow

# Add debug output to see what's happening
$VerbosePreference = "Continue"
$DebugPreference = "Continue"

# Call the function and capture all streams
Write-Host "`nCalling New-ConcurrentQueue..." -ForegroundColor Cyan
try {
    $result = New-ConcurrentQueue -Verbose -Debug
    Write-Host "Function call completed" -ForegroundColor Gray
    Write-Host "Result type: $($result.GetType().FullName)" -ForegroundColor Gray
    Write-Host "Result value: $result" -ForegroundColor Gray
    Write-Host "Is result null: $($null -eq $result)" -ForegroundColor Gray
    
    if ($result) {
        Write-Host "SUCCESS: Queue created successfully" -ForegroundColor Green
        
        # Test a basic operation
        $result.Enqueue("test")
        $count = $result.Count
        Write-Host "Test enqueue successful, count: $count" -ForegroundColor Green
    } else {
        Write-Host "FAILED: Function returned null" -ForegroundColor Red
    }
} catch {
    Write-Host "EXCEPTION: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
}

# Reset preferences
$VerbosePreference = "SilentlyContinue"
$DebugPreference = "SilentlyContinue"

Write-Host "`n=== End Detailed Debug ===" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUmgu1STQOQKrQqO/kxwNZDNP4
# yNqgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUJAjTkkYGfUCOfFqYeK4zLg66CycwDQYJKoZIhvcNAQEBBQAEggEAii15
# suDoVesDO8ez6cVj/PNKVTM4fE61EdM30a2c3VdkmfEO7gUM20+F/OVjwR4Wqck6
# KlgB6fo/N/r5NPos6Ag+/Xptxkx5O9QQ0Qz9Eb8RrzFa6Ia7/SpT1PU+LCfy+L83
# e37abJHXaiClNfLGGJsgw26n2FJjqpnh4i8jxcdCZi6xAwtI4oZP5XpXPnb+Z8Fp
# +qDDA1fsrK8VlVaFaDTbN+fR53MoFg3ehKXAk2npHlkMZpiP1Vuxoq0YP856s9DM
# igQ+xDiXiVxI4jqR1jmb2jsfaGMubVswWBjqwR1X1JwxIz+EuAu40Y0yzJAfsOFv
# eUmYJSEao9dbP8BoRQ==
# SIG # End signature block
