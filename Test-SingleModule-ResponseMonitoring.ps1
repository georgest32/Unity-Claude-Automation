# Test-SingleModule-ResponseMonitoring.ps1
# Test extracted ResponseMonitoring module

Write-Host "Testing ResponseMonitoring Module" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

try {
    # Import the refactored module to get ResponseMonitoring functions
    Import-Module "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-AutonomousAgent\Unity-Claude-AutonomousAgent-Refactored.psd1" -Force
    
    Write-Host "Module imported successfully" -ForegroundColor Green
    
    # Test ResponseMonitoring functions
    $responseFunctions = @(
        'Invoke-ProcessClaudeResponse',
        'Find-ClaudeRecommendations', 
        'Add-RecommendationToQueue',
        'Invoke-ProcessCommandQueue',
        'Submit-PromptToClaude'
    )
    
    Write-Host ""
    Write-Host "Checking ResponseMonitoring functions:" -ForegroundColor Yellow
    
    $foundFunctions = 0
    foreach ($func in $responseFunctions) {
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
    Write-Host "  Functions Found: $foundFunctions/$($responseFunctions.Count)" -ForegroundColor Gray
    $percentage = [Math]::Round(($foundFunctions / $responseFunctions.Count) * 100, 1)
    Write-Host "  Success Rate: $percentage%" -ForegroundColor $(if ($percentage -eq 100) { 'Green' } elseif ($percentage -ge 80) { 'Yellow' } else { 'Red' })
    
    # Test a simple function call
    if (Get-Command Find-ClaudeRecommendations -ErrorAction SilentlyContinue) {
        Write-Host ""
        Write-Host "Testing Find-ClaudeRecommendations:" -ForegroundColor Yellow
        $testText = "RECOMMENDED: TEST - Run the validation script"
        $result = Find-ClaudeRecommendations -ResponseText $testText
        Write-Host "  Found $($result.Count) recommendations" -ForegroundColor Gray
        if ($result.Count -gt 0) {
            Write-Host "  First rec: $($result[0].Type) - $($result[0].Command)" -ForegroundColor Gray
        }
    }
    
    if ($percentage -eq 100) {
        Write-Host ""
        Write-Host "ResponseMonitoring module extraction: SUCCESS" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "ResponseMonitoring module extraction: NEEDS WORK" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "Test failed: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "Test completed at $(Get-Date)" -ForegroundColor Gray
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU8XdfxkLZCY7rdnVFqPMQ3B3M
# TV2gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUYjaB2uJhMfQLNjr352R65c4vZ98wDQYJKoZIhvcNAQEBBQAEggEATS6i
# GawAtAd88W1xmbSY2A5mRXttaOUn+LzGRgXFyoT17/x8UyI/lzlFqMh+MXRUqQv/
# BjfUq7vW5h9QxU2PtlT43T0Btq8pvmJCvbLAEzozOSfKvX6Whm44C44CtZh/q1ov
# mzo1Jq9HXOyGcyWyTGcivG7v0a1jlvtEH3mPhNxnFpk1txmNpctDOpisL5BxipaK
# 0YpmX5nQVWHvh+v/AcinPWk8iAQA5QKjrZA5r/E6zy8nloEdvoLSYVQw9dnI2LUd
# T5nQe4RurOyONxS5aH1Zae3ACtWZsK/4anR2dykq11oxLlSS8mgR7Rn+TzZikprg
# mM9e6S+mbE3Abs/8SQ==
# SIG # End signature block
