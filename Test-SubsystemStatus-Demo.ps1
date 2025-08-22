# Test-SubsystemStatus-Demo.ps1
# Demonstrates how to test the Test-SubsystemStatus function
# Date: 2025-08-22

param(
    [string]$SubsystemName = "AutonomousAgent",
    [switch]$IncludePerformanceData
)

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "TEST-SUBSYSTEMSTATUS DEMONSTRATION" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

try {
    # Step 1: Import the SystemStatus module
    Write-Host "1. Importing SystemStatus module..." -ForegroundColor Yellow
    Import-Module ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1" -Force
    Write-Host "   Module imported successfully" -ForegroundColor Green
    
    # Step 2: Verify Test-SubsystemStatus function is available
    Write-Host ""
    Write-Host "2. Verifying Test-SubsystemStatus function..." -ForegroundColor Yellow
    $testFunction = Get-Command Test-SubsystemStatus -ErrorAction SilentlyContinue
    if ($testFunction) {
        Write-Host "   ✅ Test-SubsystemStatus function is available" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Test-SubsystemStatus function NOT FOUND" -ForegroundColor Red
        exit 1
    }
    
    # Step 3: Load manifests to get the subsystem manifest
    Write-Host ""
    Write-Host "3. Loading subsystem manifests..." -ForegroundColor Yellow
    $manifests = Get-SubsystemManifests
    Write-Host "   Found $($manifests.Count) manifests" -ForegroundColor Green
    
    # Find the requested subsystem manifest
    $manifestObj = $manifests | Where-Object { $_.Name -eq $SubsystemName }
    if (-not $manifestObj) {
        Write-Host "   ❌ Manifest for '$SubsystemName' not found" -ForegroundColor Red
        Write-Host "   Available subsystems:" -ForegroundColor Gray
        foreach ($m in $manifests) {
            Write-Host "     - $($m.Name)" -ForegroundColor Gray
        }
        exit 1
    }
    
    # Extract the actual manifest data (hashtable) from the wrapper object
    $manifest = $manifestObj.Data
    if (-not $manifest) {
        Write-Host "   ❌ Manifest data not found for '$SubsystemName'" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "   ✅ Found manifest for '$SubsystemName'" -ForegroundColor Green
    Write-Host "     Version: $($manifest.Version)" -ForegroundColor Gray
    Write-Host "     Health Check Function: $($manifest.HealthCheckFunction)" -ForegroundColor Gray
    Write-Host "     Restart Policy: $($manifest.RestartPolicy)" -ForegroundColor Gray
    
    # Step 4: Test the subsystem health
    Write-Host ""
    Write-Host "4. Testing subsystem health..." -ForegroundColor Yellow
    Write-Host "   Subsystem: $SubsystemName" -ForegroundColor Gray
    Write-Host "   Include Performance Data: $IncludePerformanceData" -ForegroundColor Gray
    Write-Host ""
    
    $healthResult = Test-SubsystemStatus -SubsystemName $SubsystemName -Manifest $manifest -IncludePerformanceData:$IncludePerformanceData
    
    # Step 5: Display results
    Write-Host "5. Health Check Results:" -ForegroundColor Yellow
    Write-Host "   ======================================" -ForegroundColor Gray
    Write-Host "   Subsystem Name: $($healthResult.SubsystemName)" -ForegroundColor White
    Write-Host "   Timestamp: $($healthResult.Timestamp)" -ForegroundColor White
    
    if ($healthResult.OverallHealthy) {
        Write-Host "   Overall Healthy: ✅ YES" -ForegroundColor Green
    } else {
        Write-Host "   Overall Healthy: ❌ NO" -ForegroundColor Red
    }
    
    if ($healthResult.ProcessRunning) {
        Write-Host "   Process Running: ✅ YES" -ForegroundColor Green
        Write-Host "   Process ID: $($healthResult.ProcessId)" -ForegroundColor White
    } else {
        Write-Host "   Process Running: ❌ NO" -ForegroundColor Red
        if ($healthResult.ProcessId) {
            Write-Host "   Last Known PID: $($healthResult.ProcessId)" -ForegroundColor Gray
        }
    }
    
    Write-Host "   Health Check Source: $($healthResult.HealthCheckSource)" -ForegroundColor White
    
    # Custom health check results
    if ($healthResult.CustomHealthCheck) {
        Write-Host "   Custom Health Check: Available" -ForegroundColor Cyan
        if ($healthResult.CustomHealthCheck -is [hashtable]) {
            foreach ($key in $healthResult.CustomHealthCheck.Keys) {
                Write-Host "     $key`: $($healthResult.CustomHealthCheck[$key])" -ForegroundColor Gray
            }
        } else {
            Write-Host "     Result: $($healthResult.CustomHealthCheck)" -ForegroundColor Gray
        }
    }
    
    # Performance data
    if ($healthResult.PerformanceData) {
        Write-Host "   Performance Data:" -ForegroundColor Cyan
        Write-Host "     Memory Usage: $($healthResult.PerformanceData.MemoryMB) MB" -ForegroundColor White
        if ($healthResult.PerformanceData.CpuPercent) {
            Write-Host "     CPU Usage: $($healthResult.PerformanceData.CpuPercent)%" -ForegroundColor White
        }
        Write-Host "     Collection Time: $($healthResult.PerformanceData.CollectionTime)" -ForegroundColor Gray
        
        if ($healthResult.PerformanceData.Counters.Count -gt 0) {
            Write-Host "     Additional Counters:" -ForegroundColor Cyan
            foreach ($counter in $healthResult.PerformanceData.Counters.Keys) {
                Write-Host "       $counter`: $($healthResult.PerformanceData.Counters[$counter])" -ForegroundColor Gray
            }
        }
    }
    
    # Error details
    if ($healthResult.ErrorDetails.Count -gt 0) {
        Write-Host "   Error Details:" -ForegroundColor Red
        foreach ($errorDetail in $healthResult.ErrorDetails) {
            Write-Host "     - $errorDetail" -ForegroundColor Red
        }
    }
    
    Write-Host "   ======================================" -ForegroundColor Gray
    Write-Host ""
    
    # Step 6: Test with circuit breaker if available
    if (Get-Command Invoke-CircuitBreakerCheck -ErrorAction SilentlyContinue) {
        Write-Host "6. Testing with Circuit Breaker..." -ForegroundColor Yellow
        
        try {
            $circuitResult = Invoke-CircuitBreakerCheck -SubsystemName $SubsystemName -TestResult $healthResult
            
            Write-Host "   Circuit Breaker Results:" -ForegroundColor Cyan
            Write-Host "     State: $($circuitResult.State)" -ForegroundColor White
            Write-Host "     Failure Count: $($circuitResult.FailureCount)" -ForegroundColor White
            Write-Host "     Is Healthy: $($circuitResult.IsHealthy)" -ForegroundColor White
            Write-Host "     Allow Requests: $($circuitResult.AllowRequests)" -ForegroundColor White
            
            if ($circuitResult.LastFailureTime) {
                Write-Host "     Last Failure: $($circuitResult.LastFailureTime)" -ForegroundColor Gray
            }
            if ($circuitResult.LastSuccessTime) {
                Write-Host "     Last Success: $($circuitResult.LastSuccessTime)" -ForegroundColor Gray
            }
            
        } catch {
            Write-Host "   Circuit breaker test failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "Test completed successfully!" -ForegroundColor Green
    
} catch {
    Write-Host ""
    Write-Host "❌ Error during test: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace:" -ForegroundColor Gray
    Write-Host $_.ScriptStackTrace -ForegroundColor Gray
    exit 1
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "DEMONSTRATION COMPLETE" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUySb4VMn232AJSICT+/20hJpA
# +ZmgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUsAQeJhTlw7oSj8OpPHxx32g5XlAwDQYJKoZIhvcNAQEBBQAEggEAm+47
# jMeQYXSqLzItAGb1kEw4r4sT2ipVnbhpIb09U2LZCslVzkoNI9uO6OftJG1rb8/m
# cyrGfrwLawfUt6Ji13xWMA4wdR8fUr90sMYyyrhGJQjOYUAtJc+NsP6p0k0uaOUL
# KfpiT/RLy/Wg2FoyR9/2R3WECXuplGiVIMz4Nbo0erf1boo1QwRL2q5BinO5q5ct
# 7UE8L3KVWcL0k1jnGBGe6Fvm9mDnZkYwumzRUg2um0QEq0qmDHNahA0cC/1wLGBL
# RsjHMxpF+zQEZnGPlrGbO2rjy3zb4kKNhrjFSvWX9LiUnK6XiRcJjHB435A96w2D
# 16GtJ3MV5F44VkYfFA==
# SIG # End signature block
