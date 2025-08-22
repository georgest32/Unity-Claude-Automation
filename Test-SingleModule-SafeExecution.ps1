# Test-SingleModule-SafeExecution.ps1
# Test extracted SafeExecution module

Write-Host "Testing SafeExecution Module" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan

try {
    # Import the specific module for testing
    Import-Module "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-AutonomousAgent\Execution\SafeExecution.psm1" -Force
    
    Write-Host "SafeExecution module imported successfully" -ForegroundColor Green
    
    # Test SafeExecution functions
    $safeFunctions = @(
        'New-ConstrainedRunspace',
        'Test-CommandSafety',
        'Test-ParameterSafety', 
        'Test-PathSafety',
        'Invoke-SafeConstrainedCommand',
        'Invoke-SafeRecommendedCommand',
        'Sanitize-ParameterValue'
    )
    
    Write-Host ""
    Write-Host "Checking SafeExecution functions:" -ForegroundColor Yellow
    
    $foundFunctions = 0
    foreach ($func in $safeFunctions) {
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
    Write-Host "  Functions Found: $foundFunctions/$($safeFunctions.Count)" -ForegroundColor Gray
    $percentage = [Math]::Round(($foundFunctions / $safeFunctions.Count) * 100, 1)
    Write-Host "  Success Rate: $percentage%" -ForegroundColor $(if ($percentage -eq 100) { 'Green' } elseif ($percentage -ge 80) { 'Yellow' } else { 'Red' })
    
    # Test basic functions
    if (Get-Command Test-CommandSafety -ErrorAction SilentlyContinue) {
        Write-Host ""
        Write-Host "Testing Test-CommandSafety:" -ForegroundColor Yellow
        
        # Test safe command
        $safeResult = Test-CommandSafety -CommandText "Get-Date"
        Write-Host "  Safe command 'Get-Date': $($safeResult.IsSafe)" -ForegroundColor $(if ($safeResult.IsSafe) { 'Green' } else { 'Red' })
        
        # Test unsafe command
        $unsafeResult = Test-CommandSafety -CommandText "Remove-Item -Recurse"
        Write-Host "  Unsafe command 'Remove-Item': $($unsafeResult.IsSafe)" -ForegroundColor $(if (-not $unsafeResult.IsSafe) { 'Green' } else { 'Red' })
    }
    
    if (Get-Command Sanitize-ParameterValue -ErrorAction SilentlyContinue) {
        Write-Host ""
        Write-Host "Testing Sanitize-ParameterValue:" -ForegroundColor Yellow
        $testValue = "normal_value;dangerous&chars"
        $sanitized = Sanitize-ParameterValue -Value $testValue
        Write-Host "  Original: '$testValue'" -ForegroundColor Gray
        Write-Host "  Sanitized: '$sanitized'" -ForegroundColor Gray
    }
    
    if ($percentage -eq 100) {
        Write-Host ""
        Write-Host "SafeExecution module extraction: SUCCESS" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "SafeExecution module extraction: NEEDS WORK" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "Test failed: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "Test completed at $(Get-Date)" -ForegroundColor Gray
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUynhODKeO0KLW3vfB97HqHkQC
# MtqgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUciZxVwWbe36XQBavCxy8+N+EzJMwDQYJKoZIhvcNAQEBBQAEggEAghcY
# dU6EnD4b8p5qIPcoeGi8Y16+IdzMEdYxGlJK9LxHjmZuEhqH8HFmRvzlq0C/UFdT
# 8qV3+AQT7nmWx9/tMo+BgAM5BmNIl7i3FwWwxXT6Ldcn9fcNyUGP3TSNDfZ7NUjz
# r1bPC6JbGPn2djwGDcARSRQtjUao4iAIiVS1RzkwcbytxIELZSc+npRfu6teHhNU
# HkuLbxpDv7MqTIKvmiw1ZPHuGkJ3t8A/KO4sXoEVkCFMVieWTAfstyrE2Y7/ls5F
# cLEfXxtEHjLC1d4NzmNlPCTGFSHAj/Kosv+zVignMG/jZ84EqEV/3FTG7CrAOACw
# FaiqTPcFySaVGabkwQ==
# SIG # End signature block
