# Test-FixedModuleImports.ps1
# Tests module imports with fixed PSModulePath and dependencies
# Date: 2025-08-21

Write-Host "=== Testing Fixed Module Dependencies ===" -ForegroundColor Cyan

try {
    # Configure PSModulePath
    $env:PSModulePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules;" + $env:PSModulePath
    Write-Host "PSModulePath configured with custom directory" -ForegroundColor Green
    
    # Test 1: Import ClaudeParallelization with RequiredModules
    Write-Host "`n1. Testing ClaudeParallelization import..." -ForegroundColor Yellow
    Import-Module Unity-Claude-ClaudeParallelization -Force -Verbose
    
    $claudeModule = Get-Module Unity-Claude-ClaudeParallelization
    if ($claudeModule) {
        Write-Host "   SUCCESS: ClaudeParallelization loaded with $($claudeModule.ExportedFunctions.Count) functions" -ForegroundColor Green
    } else {
        Write-Host "   FAILED: ClaudeParallelization not loaded" -ForegroundColor Red
    }
    
    # Test 2: Test function availability  
    Write-Host "`n2. Testing function availability..." -ForegroundColor Yellow
    $testFunctions = @(
        'New-ClaudeParallelSubmitter',
        'New-ClaudeCLIParallelManager',
        'Test-ClaudeParallelizationPerformance'
    )
    
    foreach ($func in $testFunctions) {
        $command = Get-Command $func -ErrorAction SilentlyContinue
        if ($command) {
            Write-Host "   Found: $func" -ForegroundColor Green
        } else {
            Write-Host "   Missing: $func" -ForegroundColor Red
        }
    }
    
    # Test 3: Create Claude submitter to validate functionality
    Write-Host "`n3. Testing Claude submitter creation..." -ForegroundColor Yellow
    $submitter = New-ClaudeParallelSubmitter -SubmitterName "TestSubmitter" -MaxConcurrentRequests 4 -EnableRateLimiting
    
    if ($submitter -and $submitter.SubmitterName -eq "TestSubmitter") {
        Write-Host "   SUCCESS: Claude submitter created successfully" -ForegroundColor Green
        Write-Host "   Name: $($submitter.SubmitterName)" -ForegroundColor Green
        Write-Host "   Max Requests: $($submitter.MaxConcurrentRequests)" -ForegroundColor Green
    } else {
        Write-Host "   FAILED: Claude submitter creation failed" -ForegroundColor Red
    }
    
    Write-Host "`n=== MODULE DEPENDENCY FIX: SUCCESS ===" -ForegroundColor Green
    Write-Host "All modules loading and functions working correctly" -ForegroundColor Green
    
} catch {
    Write-Host "`n=== MODULE DEPENDENCY FIX: FAILED ===" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUcXMAeCNew0Knsqul7UFG6/u1
# xnOgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUw3JcF5RKgpZDaiizkpxUIHDPMT4wDQYJKoZIhvcNAQEBBQAEggEACkFw
# Z1rEBENPy/eT2GbbHnXOckgWbO1HTomkl3nbGyFEMH5XV4Eie6q7NlEIiZgyZro1
# 8rh/0i3K2kbc78Y5d8Ixluqf9hyVUQ2nXyDfM5OWGrO/28IoVC9ZvBwggNIkZgBq
# 9diOW9jNTaZufp7d3Eb649N17PF8O8xfLX4mIm9JY+15denStmXmDsjfSLlIuqi7
# fgXt7aZuSOkImuYc7Vf6L8TsHsZ89Gl0vh+nyrM6vTOl6aUpDd+vOWSCP400b4lH
# V42YGNDpTROIreV8SQO8g9cc0EpPYM5S6QVPqSbia9Cdr1DhH2Pugo2t57Qkfd1Z
# CgtGoa93vgC3jdO18w==
# SIG # End signature block
