# Test-FixedPromptGeneration.ps1
# Test the fixed prompt generation (no # symbols that trigger memory commits)
# Date: 2025-08-18

Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

Write-Host "TESTING FIXED PROMPT GENERATION" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

try {
    # Load the fixed CLI submission module
    Import-Module ".\Modules\Unity-Claude-CLISubmission.psm1" -Force
    Write-Host "[+] Loaded fixed CLI submission module" -ForegroundColor Green
    
    # Create test errors
    $testErrors = @(
        "Assets\Scripts\TestError.cs(5,20): error CS1002: ; expected",
        "Assets\Scripts\AnotherTest.cs(10,15): error CS0103: The name 'invalidVar' does not exist"
    )
    
    Write-Host "[+] Generating prompt with fixed format..." -ForegroundColor Yellow
    $promptResult = New-AutonomousPrompt -Errors $testErrors -Context "Testing fixed prompt generation"
    
    if ($promptResult.Success) {
        Write-Host "[+] Prompt generated successfully!" -ForegroundColor Green
        Write-Host "  Error count: $($promptResult.ErrorCount)" -ForegroundColor Gray
        Write-Host "  Prompt length: $($promptResult.Prompt.Length) characters" -ForegroundColor Gray
        
        Write-Host "" -ForegroundColor White
        Write-Host "PROMPT PREVIEW (First 500 characters):" -ForegroundColor Cyan
        Write-Host "======================================" -ForegroundColor Cyan
        $preview = $promptResult.Prompt.Substring(0, [Math]::Min(500, $promptResult.Prompt.Length))
        Write-Host $preview -ForegroundColor White
        Write-Host "..." -ForegroundColor Gray
        
        # Check for problematic # symbols at line start
        $lines = $promptResult.Prompt -split "`n"
        $problematicLines = $lines | Where-Object { $_ -match "^#" }
        
        if ($problematicLines.Count -gt 0) {
            Write-Host "" -ForegroundColor White
            Write-Host "[WARNING] Found lines starting with # (may trigger memory commands):" -ForegroundColor Yellow
            foreach ($line in $problematicLines) {
                Write-Host "  $line" -ForegroundColor Red
            }
        } else {
            Write-Host "" -ForegroundColor White
            Write-Host "[+] No problematic # lines found - prompt should work correctly!" -ForegroundColor Green
        }
        
        # Save prompt to file for inspection
        $promptFile = ".\test_prompt_fixed.txt"
        $promptResult.Prompt | Out-File $promptFile -Encoding UTF8
        Write-Host "[+] Full prompt saved to: $promptFile" -ForegroundColor Green
        
    } else {
        Write-Host "[-] Failed to generate prompt: $($promptResult.Error)" -ForegroundColor Red
    }
    
} catch {
    Write-Host "[-] Error during test: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "" -ForegroundColor White
Write-Host "SUMMARY:" -ForegroundColor Cyan
Write-Host "The autonomous system prompt generation has been fixed to avoid # symbols" -ForegroundColor White
Write-Host "that trigger Claude Code CLI memory commit commands." -ForegroundColor White
Write-Host "" -ForegroundColor White
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Create a new Unity error to test the fixed autonomous system" -ForegroundColor Gray
Write-Host "2. Verify the prompt submits normally (no memory commit dialog)" -ForegroundColor Gray
Write-Host "3. Confirm Claude processes the debugging request properly" -ForegroundColor Gray

Write-Host "" -ForegroundColor White
Write-Host "Press Enter to exit..." -ForegroundColor Gray
Read-Host
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUtCXsYDnYBGfMp1a+KbTNZmZ5
# 20OgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUGwRkHhXH71+MhfctseYHKZwasEIwDQYJKoZIhvcNAQEBBQAEggEAJCPi
# +pA3wv25DYDfnXvI1h15u8kUukQ982SnurJ9c8QdiDlS6kxXUzvsQZBwp9XtG8oQ
# xgP1bsYGRQLSnxiEvelVkkszXTEGAEnEAfnC8djhf1CPrQW+RivKjbrlM8eqDdsF
# J4dWS0QNlYXrkOrHMFGo6j0vljmqCipfwnNAtVE/FOE2QsN5NPKTumCQybz4WgH0
# arF08ObYzc0aeQi1mIq0W17qqLK+gqkt6jtArRJpuuiQQtNwmlJfvJ6z5+8zRvwP
# HuTQfpmICiy4HmoLM+SJ3HvsEeh2om37Js+VRar4X81iOKhyOPInf4B3wtYD0rhH
# sfQT7SoP0YWiWUUaGQ==
# SIG # End signature block
