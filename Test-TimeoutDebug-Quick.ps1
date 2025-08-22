# Test-TimeoutDebug-Quick.ps1
# Debug investigation for timeout test logic discrepancy
# Date: 2025-08-21

Write-Host "=== Timeout Test Logic Debug Investigation ===" -ForegroundColor Cyan
Write-Host "Investigating why timeout test expects 1 but reports 7 timed out jobs" -ForegroundColor Yellow

try {
    Write-Host "Importing module and creating test setup..." -ForegroundColor White
    Import-Module ".\Modules\Unity-Claude-RunspaceManagement\Unity-Claude-RunspaceManagement.psd1" -Force -ErrorAction Stop
    
    $sessionConfig = New-RunspaceSessionState
    Initialize-SessionStateVariables -SessionStateConfig $sessionConfig | Out-Null
    
    $productionPool = New-ProductionRunspacePool -SessionStateConfig $sessionConfig -MaxRunspaces 2 -Name "TimeoutDebugPool"
    Open-RunspacePool -PoolManager $productionPool | Out-Null
    
    Write-Host "Submitting timeout job..." -ForegroundColor White
    $timeoutScript = { Start-Sleep -Seconds 10; return "Should not reach here" }
    Submit-RunspaceJob -PoolManager $productionPool -ScriptBlock $timeoutScript -JobName "DebugTimeoutJob" -TimeoutSeconds 2 | Out-Null
    
    Write-Host "Waiting for timeout..." -ForegroundColor White
    $waitResult = Wait-RunspaceJobs -PoolManager $productionPool -TimeoutSeconds 5 -ProcessResults
    
    Write-Host "Analyzing results..." -ForegroundColor White
    $results = Get-RunspaceJobResults -PoolManager $productionPool -IncludeFailedJobs
    
    # Debug the actual collection contents
    Write-Host "`nDEBUG - Results Collection Analysis:" -ForegroundColor Magenta
    Write-Host "    Completed jobs count: $($results.CompletedJobs.Count)" -ForegroundColor Gray
    Write-Host "    Failed jobs count: $($results.FailedJobs.Count)" -ForegroundColor Gray
    
    Write-Host "`nDEBUG - Failed Jobs Details:" -ForegroundColor Magenta
    for ($i = 0; $i -lt $results.FailedJobs.Count; $i++) {
        $failedJob = $results.FailedJobs[$i]
        Write-Host "    Failed Job ${i}:" -ForegroundColor Gray
        Write-Host "        JobName: $($failedJob.JobName)" -ForegroundColor Gray
        Write-Host "        Status: $($failedJob.Status)" -ForegroundColor Gray
        Write-Host "        Error: $($failedJob.Error)" -ForegroundColor Gray
    }
    
    # Test the Where-Object filtering
    Write-Host "`nDEBUG - Where-Object Filtering Test:" -ForegroundColor Magenta
    $timedOutJobs = $results.FailedJobs | Where-Object { $_.Status -eq 'TimedOut' }
    Write-Host "    Timed out jobs found: $($timedOutJobs.Count)" -ForegroundColor Gray
    
    # Alternative filtering approaches
    $manualCount = 0
    foreach ($job in $results.FailedJobs) {
        if ($job.Status -eq 'TimedOut') {
            $manualCount++
            Write-Host "    Manual count found TimedOut job: $($job.JobName)" -ForegroundColor Gray
        }
    }
    Write-Host "    Manual iteration count: $manualCount" -ForegroundColor Gray
    
    # Check for collection type issues
    Write-Host "`nDEBUG - Collection Type Analysis:" -ForegroundColor Magenta
    Write-Host "    FailedJobs type: $($results.FailedJobs.GetType().Name)" -ForegroundColor Gray
    Write-Host "    TimedOutJobs type: $($timedOutJobs.GetType().Name)" -ForegroundColor Gray
    
    # Use @() wrapper for safety
    $safeTimedOutJobs = @($results.FailedJobs | Where-Object { $_.Status -eq 'TimedOut' })
    Write-Host "    Safe array count: $($safeTimedOutJobs.Count)" -ForegroundColor Gray
    
    # Cleanup
    Close-RunspacePool -PoolManager $productionPool | Out-Null
    
    Write-Host "`n=== TIMEOUT DEBUG ANALYSIS COMPLETE ===" -ForegroundColor Green
    Write-Host "Expected: 1 timed out job, Various counts above for analysis" -ForegroundColor Green
    
} catch {
    Write-Host "[FAIL] Timeout debug failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.Exception.ToString() -ForegroundColor Red
}

Write-Host "`nTimeout debug completed at $(Get-Date)" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUAKrJoCdY83NSunXH7YAnGd2A
# t52gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUO1HyP6gNDDRa17LPwMwvLmAS5zcwDQYJKoZIhvcNAQEBBQAEggEAVnEK
# UjNynd9HutF26kl3CLKS1900J2ZTbKjeyIIAJ1ItJzwltgWT6ueFQvn5X+mm3c1U
# gRyc/JQ8TP8GwW8W7s8PTcV/1mbyTCri7X2Fgwwt++dYE7u2evxuU8PXdvevi1md
# 3LjFEwIJ8R3a6lrZprg1gz5Nd2ueWPNdnsn6V9eSGv6hdawDvmdNyti4ka6JNzuA
# rRbBeazuR79Zft8MHGWSxBw+V9kMSsB8xNZNDQtVWBVS2zAts2A/YG+8z3tK4ctE
# arBldHdbVJpOMqnujGNQtwgCQ6sFbRjCCq9p5B2UmKAf3gjrxgJIufzRpSO24JGo
# Q4lnAV4H5C/PJ0FEmw==
# SIG # End signature block
