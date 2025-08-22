# Debug-PowerShellReturn.ps1
# Diagnose PowerShell 5.1 function return behavior with .NET objects

$ErrorActionPreference = "Continue"

Write-Host "=== PowerShell Return Behavior Analysis ===" -ForegroundColor Cyan

# Test 1: Direct object creation and assignment
Write-Host "`nTest 1: Direct object creation" -ForegroundColor Yellow
$directQueue = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()
Write-Host "Direct creation result: $($directQueue -ne $null)"
Write-Host "Direct type: $($directQueue.GetType().Name)"

# Test 2: Function with just return
Write-Host "`nTest 2: Function with simple return" -ForegroundColor Yellow
function Test-SimpleReturn {
    $queue = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()
    return $queue
}
$simpleReturn = Test-SimpleReturn
Write-Host "Simple return result: $($simpleReturn -ne $null)"
Write-Host "Simple return type: $($simpleReturn.GetType().Name if $simpleReturn)"

# Test 3: Function with output contamination
Write-Host "`nTest 3: Function with potential output contamination" -ForegroundColor Yellow
function Test-OutputContamination {
    Write-Host "Creating queue..." -ForegroundColor Gray
    $queue = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()
    Write-Host "Queue created" -ForegroundColor Gray
    return $queue
}
$contaminatedReturn = Test-OutputContamination
Write-Host "Contaminated return result: $($contaminatedReturn -ne $null)"
Write-Host "Contaminated return type: $($contaminatedReturn.GetType().Name if $contaminatedReturn)"

# Test 4: Function with proper output management
Write-Host "`nTest 4: Function with proper output management" -ForegroundColor Yellow
function Test-CleanReturn {
    Write-Host "Creating queue..." -ForegroundColor Gray | Out-Null
    $queue = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()
    Write-Host "Queue created" -ForegroundColor Gray | Out-Null
    return $queue
}
$cleanReturn = Test-CleanReturn
Write-Host "Clean return result: $($cleanReturn -ne $null)"
Write-Host "Clean return type: $($cleanReturn.GetType().Name if $cleanReturn)"

# Test 5: Check what's actually being returned
Write-Host "`nTest 5: Detailed return analysis" -ForegroundColor Yellow
function Test-ReturnAnalysis {
    $queue = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()
    Write-Host "About to return. Queue is null: $($queue -eq $null)"
    Write-Host "Queue type: $($queue.GetType().FullName)"
    return $queue
}
$analysisReturn = Test-ReturnAnalysis
Write-Host "Analysis return is null: $($analysisReturn -eq $null)"
Write-Host "Analysis return count: $($analysisReturn.Count if $analysisReturn -is [array])"
Write-Host "Analysis return items: $($analysisReturn | ForEach-Object { $_.GetType().Name })"

Write-Host "`n=== Analysis Complete ===" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU5ujoPZ/1KSwectHayOClvMqs
# 3HigggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU1/HtNV24uPswoN/pxY2JbG0GVh8wDQYJKoZIhvcNAQEBBQAEggEATD4b
# R70/4ikZFzwW1sWVQU/++tdhgJh8s0fnaegesFgDaMN5p0sEmA8Q18zZXnDMAf6j
# sCeM7RTkh3+JlXHJ2wDdbGiFfX04VSQCo80zlJNxddPu6/2bngU58tR44ZGpPKxZ
# NP9G9QTTNnjOPmjGdqw25oYfWFTdkQEiKTX1WyWYHzxFn1XCulN4rl+HrAhFcXYS
# 7e21W/hQ56DfF/MNi3Ry9jgnXHaoG8j5xII/1SUPGLpAowDNMn8tnnHNWMbL1f3n
# WHraPt5hrXDlHA3MHfDGQC+79bAnZTRnZPsKrcP5/6EJFd/DJA5e92eLobDH7vlY
# xRZWRQ1vQREeFji/0A==
# SIG # End signature block
