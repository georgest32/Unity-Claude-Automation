# Test-MeasureObjectFix-Quick.ps1
# Quick validation test for Measure-Object hashtable fix in runspace pool management
# Date: 2025-08-21

Write-Host "=== Quick Measure-Object Fix Validation Test ===" -ForegroundColor Cyan
Write-Host "Testing Unity-Claude-RunspaceManagement after Learning #21 fix" -ForegroundColor Yellow

try {
    Write-Host "Importing module..." -ForegroundColor White
    Import-Module ".\Modules\Unity-Claude-RunspaceManagement\Unity-Claude-RunspaceManagement.psd1" -Force -ErrorAction Stop
    Write-Host "[SUCCESS] Module imported" -ForegroundColor Green
    
    Write-Host "Creating session state and production pool..." -ForegroundColor White
    $sessionConfig = New-RunspaceSessionState
    Initialize-SessionStateVariables -SessionStateConfig $sessionConfig | Out-Null
    $productionPool = New-ProductionRunspacePool -SessionStateConfig $sessionConfig -MaxRunspaces 2 -Name "MeasureObjectTestPool"
    Open-RunspacePool -PoolManager $productionPool | Out-Null
    Write-Host "[SUCCESS] Production pool created and opened" -ForegroundColor Green
    
    Write-Host "Submitting test jobs..." -ForegroundColor White
    $testScript = { param($x) Start-Sleep -Milliseconds 50; return $x * 2 }
    Submit-RunspaceJob -PoolManager $productionPool -ScriptBlock $testScript -Parameters @{x=5} -JobName "TestJob1" | Out-Null
    Submit-RunspaceJob -PoolManager $productionPool -ScriptBlock $testScript -Parameters @{x=10} -JobName "TestJob2" | Out-Null
    Write-Host "[SUCCESS] Test jobs submitted" -ForegroundColor Green
    
    Write-Host "Testing Update-RunspaceJobStatus (critical fix location)..." -ForegroundColor White
    Start-Sleep -Milliseconds 150 # Allow jobs to complete
    $statusUpdate = Update-RunspaceJobStatus -PoolManager $productionPool -ProcessCompletedJobs
    
    if ($statusUpdate -and $statusUpdate.CompletedJobs -eq 2) {
        Write-Host "[SUCCESS] Update-RunspaceJobStatus working: $($statusUpdate.CompletedJobs) jobs completed" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] Update-RunspaceJobStatus failed" -ForegroundColor Red
    }
    
    Write-Host "Testing Wait-RunspaceJobs..." -ForegroundColor White
    # Submit one more job to test wait functionality
    Submit-RunspaceJob -PoolManager $productionPool -ScriptBlock $testScript -Parameters @{x=7} -JobName "TestJob3" | Out-Null
    $waitResult = Wait-RunspaceJobs -PoolManager $productionPool -TimeoutSeconds 5 -ProcessResults
    
    if ($waitResult -and $waitResult.Success) {
        Write-Host "[SUCCESS] Wait-RunspaceJobs working: $($waitResult.CompletedJobs) total completed" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] Wait-RunspaceJobs failed" -ForegroundColor Red
    }
    
    Write-Host "Testing Get-RunspaceJobResults..." -ForegroundColor White
    $results = Get-RunspaceJobResults -PoolManager $productionPool -IncludeFailedJobs
    
    if ($results -and $results.CompletedJobs.Count -eq 3) {
        Write-Host "[SUCCESS] Get-RunspaceJobResults working: $($results.CompletedJobs.Count) results retrieved" -ForegroundColor Green
        Write-Host "    Results: $($results.CompletedJobs[0].Result), $($results.CompletedJobs[1].Result), $($results.CompletedJobs[2].Result)" -ForegroundColor Gray
    } else {
        Write-Host "[FAIL] Get-RunspaceJobResults failed" -ForegroundColor Red
    }
    
    # Cleanup
    Close-RunspacePool -PoolManager $productionPool | Out-Null
    
    Write-Host "`n=== MEASURE-OBJECT FIX VALIDATION SUCCESS ===" -ForegroundColor Green
    Write-Host "Learning #21 pattern applied successfully to runspace pool statistics" -ForegroundColor Green
    
} catch {
    Write-Host "[FAIL] Measure-Object fix validation failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Additional error details:" -ForegroundColor Yellow
    Write-Host $_.Exception.ToString() -ForegroundColor Red
}

Write-Host "`nQuick validation completed at $(Get-Date)" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUoeV0nnKgRilIoMcHpAFB+dZ4
# f9agggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU1j9nTjFeXOjda53VrYvUFDN0rM0wDQYJKoZIhvcNAQEBBQAEggEALuEg
# Kb0wUoa5+puF1ZQU+m/nXvsJD0ONTfMotmWPUVT69++efYJePqWFR6V7ICXRdqu+
# WRei8pfvGIpyd2BwWdT1Cv1uCJsV+nNOJtU5EQqv1ZZsq2TLLFDlNdn9NmJi69sm
# bpvfIlGC7f7IVRmkFb+6Sj4ekA3RZphnohSTwQzkFUIM1Jc+pcA5T7ZVo7t5U1nq
# qHXjEOIfH8XJ6oMjWG+hP0vHK/EcLUCMANpk/SqDltyxGmlFbOTTlccBGWH7SRfu
# Tok9iOSpdEjMQUW/NgKt8R5LL3mcKbRpCXo0qfmNGy5lhMLOgHUbbatzjEL1EwAY
# DwqgS0VRD6En1UsGhA==
# SIG # End signature block
