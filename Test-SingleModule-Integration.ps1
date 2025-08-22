# Test-SingleModule-Integration.ps1
# Test extracted Integration modules

Write-Host "Testing Integration Modules" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan

try {
    # Import the specific modules for testing
    Import-Module "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-AutonomousAgent\Integration\ClaudeIntegration.psm1" -Force
    Import-Module "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-AutonomousAgent\Integration\UnityIntegration.psm1" -Force
    
    Write-Host "Integration modules imported successfully" -ForegroundColor Green
    
    # Test Integration functions
    $integrationFunctions = @(
        # ClaudeIntegration functions
        'Submit-PromptToClaude',
        'New-FollowUpPrompt',
        'Submit-ToClaude',
        'Get-ClaudeResponseStatus',
        
        # UnityIntegration functions
        'Get-PatternConfidence',
        'Convert-TypeToStandard',
        'Convert-ActionToType',
        'Normalize-RecommendationType',
        'Remove-DuplicateRecommendations',
        'Get-StringSimilarity'
    )
    
    Write-Host ""
    Write-Host "Checking Integration functions:" -ForegroundColor Yellow
    
    $foundFunctions = 0
    foreach ($func in $integrationFunctions) {
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
    Write-Host "  Functions Found: $foundFunctions/$($integrationFunctions.Count)" -ForegroundColor Gray
    $percentage = [Math]::Round(($foundFunctions / $integrationFunctions.Count) * 100, 1)
    Write-Host "  Success Rate: $percentage%" -ForegroundColor $(if ($percentage -eq 100) { 'Green' } elseif ($percentage -ge 80) { 'Yellow' } else { 'Red' })
    
    # Test basic functions
    if (Get-Command Convert-TypeToStandard -ErrorAction SilentlyContinue) {
        Write-Host ""
        Write-Host "Testing Convert-TypeToStandard:" -ForegroundColor Yellow
        $result1 = Convert-TypeToStandard -Type "TESTING"
        $result2 = Convert-TypeToStandard -Type "COMPILATION"
        Write-Host "  'TESTING' -> '$result1'" -ForegroundColor Gray
        Write-Host "  'COMPILATION' -> '$result2'" -ForegroundColor Gray
    }
    
    if (Get-Command Get-StringSimilarity -ErrorAction SilentlyContinue) {
        Write-Host ""
        Write-Host "Testing Get-StringSimilarity:" -ForegroundColor Yellow
        $similarity = Get-StringSimilarity -String1 "test command" -String2 "test command"
        Write-Host "  Identical strings similarity: $similarity" -ForegroundColor Gray
    }
    
    if (Get-Command Get-PatternConfidence -ErrorAction SilentlyContinue) {
        Write-Host ""
        Write-Host "Testing Get-PatternConfidence:" -ForegroundColor Yellow
        $confidence = Get-PatternConfidence -Pattern "CS\\d{4}" -MatchText "CS0246"
        Write-Host "  CS error pattern confidence: $confidence" -ForegroundColor Gray
    }
    
    if ($percentage -eq 100) {
        Write-Host ""
        Write-Host "Integration modules extraction: SUCCESS" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "Integration modules extraction: NEEDS WORK" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "Test failed: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "Test completed at $(Get-Date)" -ForegroundColor Gray
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUBboxmSQzDYU6bcHtTHkfYl34
# uRCgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUm3pGOC956WSwQFGW9ATc0pye6jYwDQYJKoZIhvcNAQEBBQAEggEArvYX
# zHS0q1+YqZuxtdmJz7MnuxZjQ71II2Vk1kJDFQDjYZyHyM8lrqSPo7WhElYre9gK
# yg+Gvj5aOvmgisxrgWN7AadqFG5GJ0mNaBK/Zq9thexRGE4idLLxNGe5FsUEyFNR
# IxzGYQQL2Y+rkOIchHgH9f0aA2wvWEwYJERFgNRelHVDiUAZ3fF1/fi6z4BL44u0
# 4/dg9zl8lEXhTmyj29rjm7Hbe/15JXAn9RiPQvI1kH1rzymiEY4U/e7QvU+roajA
# wNBRCW/JD1P3uZh5Zkwd7RPG5X4Amd7OI9fxbj13j5trjoumO+eJaj00Y+SJe0YB
# Se+lP2jc8lBX/Zov4w==
# SIG # End signature block
