# Test-SingleModule-UnityCommands.ps1
# Test extracted UnityCommands module

Write-Host "Testing UnityCommands Module" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan

try {
    # Import the specific module for testing
    Import-Module "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-AutonomousAgent\Commands\UnityCommands.psm1" -Force
    
    Write-Host "UnityCommands module imported successfully" -ForegroundColor Green
    
    # Test UnityCommands functions
    $unityFunctions = @(
        'Invoke-TestCommand',
        'Invoke-UnityTests',
        'Invoke-CompilationTest',
        'Invoke-PowerShellTests',
        'Invoke-BuildCommand',
        'Invoke-AnalyzeCommand',
        'Find-UnityExecutable'
    )
    
    Write-Host ""
    Write-Host "Checking UnityCommands functions:" -ForegroundColor Yellow
    
    $foundFunctions = 0
    foreach ($func in $unityFunctions) {
        $command = Get-Command $func -ErrorAction SilentlyContinue
        if ($command) {
            Write-Host "  Found: $func" -ForegroundColor Green
            $foundFunctions++
        } else {
            Write-Host "  Missing: $func" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "Results:" -ForegroundColor Cyan
    Write-Host "  Functions Found: $foundFunctions/$($unityFunctions.Count)" -ForegroundColor Gray
    $percentage = [Math]::Round(($foundFunctions / $unityFunctions.Count) * 100, 1)
    Write-Host "  Success Rate: $percentage%" -ForegroundColor $(if ($percentage -eq 100) { 'Green' } elseif ($percentage -ge 80) { 'Yellow' } else { 'Red' })
    
    # Test basic functions
    if (Get-Command Invoke-TestCommand -ErrorAction SilentlyContinue) {
        Write-Host ""
        Write-Host "Testing Invoke-TestCommand:" -ForegroundColor Yellow
        $result = Invoke-TestCommand -Details "Validation test"
        Write-Host "  Success: $($result.Success)" -ForegroundColor $(if ($result.Success) { 'Green' } else { 'Red' })
        if ($result.Success) {
            Write-Host "  Test Results: $($result.TestResults.Passed)/$($result.TestResults.Total) passed" -ForegroundColor Gray
        }
    }
    
    if (Get-Command Find-UnityExecutable -ErrorAction SilentlyContinue) {
        Write-Host ""
        Write-Host "Testing Find-UnityExecutable:" -ForegroundColor Yellow
        $result = Find-UnityExecutable -UnityVersion "2021.1.14f1"
        Write-Host "  Unity Found: $($result.Success)" -ForegroundColor $(if ($result.Success) { 'Green' } else { 'Yellow' })
        if ($result.Success) {
            Write-Host "  Unity Path: $($result.UnityPath)" -ForegroundColor Gray
        }
    }
    
    if (Get-Command Invoke-BuildCommand -ErrorAction SilentlyContinue) {
        Write-Host ""
        Write-Host "Testing Invoke-BuildCommand:" -ForegroundColor Yellow
        $result = Invoke-BuildCommand -BuildTarget "Windows"
        Write-Host "  Build Success: $($result.Success)" -ForegroundColor $(if ($result.Success) { 'Green' } else { 'Red' })
        if ($result.Success) {
            Write-Host "  Build Time: $($result.BuildTime)" -ForegroundColor Gray
        }
    }
    
    if ($percentage -eq 100) {
        Write-Host ""
        Write-Host "UnityCommands module extraction: SUCCESS" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "UnityCommands module extraction: NEEDS WORK" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "Test failed: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "Test completed at $(Get-Date)" -ForegroundColor Gray
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUx8E8aCds6aVTET/DIsK9bpYa
# z6WgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUWi+jpQR92T9X9uGsfva3Y3AkRD0wDQYJKoZIhvcNAQEBBQAEggEApmSM
# iz9vqgAW16mmXB/fQYPU6MhM6sxRXGhz3ka1OIoNX49ZLYXaw/S03Ol5PI3fLcPO
# 9T9e5KsoEuchMUHLZ6IiV6bVJn84zWTLY8ALV1y7MUM6MnkTdvcNu3I3MooGEYYm
# wFS2T6nlI3X45ol5Wj8rYoEpnJ9IWWqJKJEqUNu9uhCinwgduAg2OJZtM2kQlZA9
# 1KyKGcRjrWL/0O5MbmBkg7X1xfhGB9NcXHwlTStxVWqrA3mpiK5dgexJ85fwBJPi
# /CFQcKJIgWBj3UlxtYETHPVPVFK7iysU3i3Gr3WcQ6QadLgEhDWYPHTsIYtfoOvM
# 34EtZMU5JsbiyDYAvw==
# SIG # End signature block
