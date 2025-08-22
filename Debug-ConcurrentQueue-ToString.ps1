# Debug-ConcurrentQueue-ToString.ps1
# Test ConcurrentQueue ToString behavior

Write-Host "=== ConcurrentQueue ToString Debug ===" -ForegroundColor Cyan

# Create ConcurrentQueue directly
$queue = New-Object 'System.Collections.Concurrent.ConcurrentQueue[object]'

Write-Host "`nDirect object analysis:" -ForegroundColor Yellow
Write-Host "  Object: $queue" -ForegroundColor Gray
Write-Host "  Type: $($queue.GetType().FullName)" -ForegroundColor Gray
Write-Host "  ToString(): '$($queue.ToString())'" -ForegroundColor Gray
Write-Host "  ToString() Length: $($queue.ToString().Length)" -ForegroundColor Gray
Write-Host "  Is ToString() empty: $($queue.ToString() -eq '')" -ForegroundColor Gray

# Test serialization behavior
Write-Host "`nSerialization tests:" -ForegroundColor Yellow
try {
    $serialized = $queue | ConvertTo-Json
    Write-Host "  JSON serialization: $serialized" -ForegroundColor Gray
} catch {
    Write-Host "  JSON serialization failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test string conversion
Write-Host "`nString conversion tests:" -ForegroundColor Yellow
$asString = [string]$queue
Write-Host "  [string] cast: '$asString'" -ForegroundColor Gray
Write-Host "  [string] length: $($asString.Length)" -ForegroundColor Gray

# Test function return with explicit type
function Test-TypedReturn {
    [CmdletBinding()]
    [OutputType([System.Collections.Concurrent.ConcurrentQueue[object]])]
    param()
    
    $q = New-Object 'System.Collections.Concurrent.ConcurrentQueue[object]'
    return $q
}

Write-Host "`nTyped function test:" -ForegroundColor Yellow
$typedResult = Test-TypedReturn
Write-Host "  Typed result: '$typedResult'" -ForegroundColor Gray
Write-Host "  Typed is null: $($null -eq $typedResult)" -ForegroundColor Gray

Write-Host "`n=== End ToString Debug ===" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUtvslf7DyHZYxRSqNr7Mrc0QZ
# XSqgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUVKPiTAe8I7lkJRK/vYPGNDOzeV0wDQYJKoZIhvcNAQEBBQAEggEAaX08
# TSCpv/Ci78DjIVlpOZAW4oURs368mMCJ2Ss1DhzNWX7qhCt1/IrdHmpB0fXTz701
# WSkkk+XWEw4I8DZfjhwS+KPUmhwyCx5mfKi+N7JgmX0mPU6chN7tmBIkLeATgp6f
# DZowZQAWxHozd06KhxAMg3tx1KIpcK9Sq2BGTy/IrI8vdmnqng3K35hOjBJDlnqW
# oymNljWg1qSsICmPVlHQJUwsz937+zEJYWXnKuwmV/V6gucqI7mbE2Nu2v2toqP5
# +inyc7lZldAKNSpDMH1/7XegPN1uXA6PayhFE1JGdSGwNcVniYEK5LzTbIzFXMg8
# xhlVU8WwLjOJydwaVQ==
# SIG # End signature block
