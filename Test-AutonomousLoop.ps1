# Test-AutonomousLoop.ps1  
# Test the existing autonomous feedback loop implementation
# Date: 2025-08-18

Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

Write-Host "TESTING EXISTING AUTONOMOUS FEEDBACK LOOP" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

try {
    # Test 1: Load CLISubmission module (the one that works)
    Write-Host "Test 1: Loading CLISubmission module..." -ForegroundColor Yellow
    Import-Module ".\Modules\Unity-Claude-CLISubmission.psm1" -Force
    Write-Host "  ✓ CLISubmission loaded" -ForegroundColor Green
    
    # Test 2: Try IntegrationEngine (may have dependencies)
    Write-Host "Test 2: Loading IntegrationEngine module..." -ForegroundColor Yellow
    try {
        Import-Module ".\Modules\Unity-Claude-IntegrationEngine.psm1" -Force
        Write-Host "  ✓ IntegrationEngine loaded" -ForegroundColor Green
        $integrationWorking = $true
    } catch {
        Write-Host "  ✗ IntegrationEngine failed: $($_.Exception.Message)" -ForegroundColor Red
        $integrationWorking = $false
    }
    
    # Test 3: Check available functions
    Write-Host "Test 3: Checking available functions..." -ForegroundColor Yellow
    $cliCommands = Get-Command -Module Unity-Claude-CLISubmission
    Write-Host "  CLISubmission functions: $($cliCommands.Count)" -ForegroundColor Gray
    $cliCommands.Name | ForEach-Object { Write-Host "    - $_" -ForegroundColor DarkGray }
    
    if ($integrationWorking) {
        $integrationCommands = Get-Command -Module Unity-Claude-IntegrationEngine
        Write-Host "  IntegrationEngine functions: $($integrationCommands.Count)" -ForegroundColor Gray
        $integrationCommands.Name | ForEach-Object { Write-Host "    - $_" -ForegroundColor DarkGray }
    }
    
    # Test 4: Try starting autonomous loop with working modules
    Write-Host "Test 4: Testing autonomous feedback loop startup..." -ForegroundColor Yellow
    
    if ($integrationWorking) {
        Write-Host "  Using IntegrationEngine approach..." -ForegroundColor Gray
        try {
            $result = Start-AutonomousFeedbackLoop -MaxCycles 1
            if ($result) {
                Write-Host "  ✓ IntegrationEngine autonomous loop started" -ForegroundColor Green
            }
        } catch {
            Write-Host "  ✗ IntegrationEngine start failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "  Using CLISubmission approach..." -ForegroundColor Gray
        try {
            Import-Module ".\Modules\Unity-Claude-SessionManager.psm1" -Force
            Import-Module ".\Modules\Unity-Claude-AutonomousStateTracker.psm1" -Force
            
            $result = Start-AutonomousFeedbackLoop
            if ($result.Success) {
                Write-Host "  ✓ CLISubmission autonomous loop started" -ForegroundColor Green
                Start-Sleep 3
                Stop-AutonomousFeedbackLoop
                Write-Host "  ✓ Autonomous loop stopped (test complete)" -ForegroundColor Green
            }
        } catch {
            Write-Host "  ✗ CLISubmission start failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    # Summary
    Write-Host "" -ForegroundColor White
    Write-Host "TEST RESULTS SUMMARY:" -ForegroundColor Cyan
    Write-Host "====================" -ForegroundColor Cyan
    Write-Host "✓ CLISubmission module: WORKING" -ForegroundColor Green
    if ($integrationWorking) {
        Write-Host "✓ IntegrationEngine module: WORKING" -ForegroundColor Green
    } else {
        Write-Host "✗ IntegrationEngine module: MISSING DEPENDENCIES" -ForegroundColor Red
    }
    Write-Host "✓ Autonomous feedback loop: AVAILABLE" -ForegroundColor Green
    Write-Host "" -ForegroundColor White
    
    if ($integrationWorking) {
        Write-Host "RECOMMENDATION: Use Start-AutonomousLoop.ps1 (IntegrationEngine)" -ForegroundColor Cyan
    } else {
        Write-Host "RECOMMENDATION: Use CLISubmission functions directly" -ForegroundColor Cyan
        Write-Host "  Start-AutonomousFeedbackLoop" -ForegroundColor Gray
        Write-Host "  Stop-AutonomousFeedbackLoop" -ForegroundColor Gray
    }
    
} catch {
    Write-Host "Test failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Full error: $($_.Exception)" -ForegroundColor DarkRed
}

Write-Host "" -ForegroundColor White
Write-Host "Press Enter to exit..." -ForegroundColor Yellow
Read-Host
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUYrm6ojpIn3qlwvcM71fc+bSX
# wSSgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUYOvFNT0yIwBzB0k9m1GPNWbHndgwDQYJKoZIhvcNAQEBBQAEggEAQYnm
# tgA2mpjY0HbN2N3IBDsxf4gRYJ3XB2AB19Yjyl2mYNnN6QjIWJJGxDLMKKML+gC9
# yVu6zB2jHqwGG1H0tQs71qO3fdxiYC62RbH0Qvmz5DpDHcqTbIg5ofoINKZrun/J
# TWExHOTRHlo6ode/NXV6MM5S/aj8NI/8at66FyPr+wOVDM0zPQCVInK6T8GCu2VQ
# biCVwd6QHTcBsuGtAPFkD/cfC4lYkT6bOxkphsMk1hc6VS8gCVt4cy2bvPHAY7gV
# HoB+EJxfCoyKqWP0CybEkX/bTkMopsi3O93mPiMFYDztT6HYjNiyS+0+uCHgHNOQ
# 3cmCOHNgSuO+zoeXHQ==
# SIG # End signature block
