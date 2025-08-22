# Test-Direct-Monitoring.ps1
# Test Unity error monitoring directly without background jobs
# Date: 2025-08-18

Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

Write-Host "TESTING DIRECT UNITY ERROR MONITORING" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

# Load modules
Import-Module ".\Modules\Unity-Claude-CLISubmission.psm1" -Force

# Get current Unity log size
$logPath = "C:\Users\georg\AppData\Local\Unity\Editor\Editor.log"
$initialInfo = Get-Item $logPath
$initialSize = $initialInfo.Length

Write-Host "Starting direct monitoring test..." -ForegroundColor Yellow
Write-Host "Initial log size: $initialSize bytes" -ForegroundColor Gray
Write-Host "Monitoring for changes..." -ForegroundColor Gray

# Monitor for 30 seconds
$startTime = Get-Date
$timeout = 30

while ((Get-Date) -lt $startTime.AddSeconds($timeout)) {
    Start-Sleep 2
    
    # Check if log file changed
    $currentInfo = Get-Item $logPath
    $currentSize = $currentInfo.Length
    
    if ($currentSize -ne $initialSize) {
        Write-Host "Log file changed! New size: $currentSize bytes" -ForegroundColor Green
        
        # Get new content
        $newBytes = $currentSize - $initialSize
        Write-Host "New content ($newBytes bytes):" -ForegroundColor Cyan
        
        # Read the new content
        $allContent = Get-Content $logPath -Raw
        $newContent = $allContent.Substring($initialSize)
        
        # Check for errors in new content
        $errorPatterns = @("CS0103:", "CS0246:", "CS1061:", "CS0029:", "CS1002:")
        $foundErrors = @()
        
        foreach ($pattern in $errorPatterns) {
            if ($newContent -match $pattern) {
                $lines = $newContent -split "`n"
                $errorLines = $lines | Where-Object { $_ -match $pattern }
                $foundErrors += $errorLines
            }
        }
        
        if ($foundErrors.Count -gt 0) {
            Write-Host "FOUND NEW COMPILATION ERRORS!" -ForegroundColor Red
            foreach ($error in $foundErrors) {
                Write-Host "  $error" -ForegroundColor Red
            }
            
            # Test prompt generation and submission
            Write-Host "Testing prompt generation..." -ForegroundColor Yellow
            $promptResult = New-AutonomousPrompt -Errors $foundErrors
            
            if ($promptResult.Success) {
                Write-Host "Prompt generated successfully!" -ForegroundColor Green
                Write-Host "Testing Claude Code CLI submission..." -ForegroundColor Yellow
                
                # Try to submit
                $submissionResult = Submit-PromptToClaudeCode -Prompt $promptResult.Prompt
                
                if ($submissionResult.Success) {
                    Write-Host "SUCCESS! Prompt submitted to Claude Code CLI!" -ForegroundColor Green
                    Write-Host "Check Claude Code CLI window for the autonomous prompt!" -ForegroundColor Cyan
                    break
                } else {
                    Write-Host "Failed to submit: $($submissionResult.Error)" -ForegroundColor Red
                }
            }
        } else {
            Write-Host "Log changed but no compilation errors found" -ForegroundColor Yellow
            Write-Host "New content preview:" -ForegroundColor Gray
            $preview = $newContent.Substring(0, [Math]::Min(200, $newContent.Length))
            Write-Host "  $preview..." -ForegroundColor DarkGray
        }
        
        $initialSize = $currentSize
    }
    
    Write-Host "." -NoNewline -ForegroundColor Gray
}

Write-Host "" -ForegroundColor White
Write-Host "Monitoring timeout reached" -ForegroundColor Yellow
Write-Host "" -ForegroundColor White
Write-Host "TO TRIGGER NEW ERRORS:" -ForegroundColor Cyan
Write-Host "1. Open Unity" -ForegroundColor White
Write-Host "2. Open any C# script" -ForegroundColor White
Write-Host "3. Add a syntax error (missing semicolon)" -ForegroundColor White
Write-Host "4. Save the file" -ForegroundColor White
Write-Host "5. Watch this window for detection" -ForegroundColor White

Write-Host "" -ForegroundColor White
Write-Host "Press Enter to exit..." -ForegroundColor Yellow
Read-Host
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUyOj3Iq/edeD8n+viPFe0I9ut
# hx2gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUueCYcMGviJsdTnGAESsY0fLDr80wDQYJKoZIhvcNAQEBBQAEggEAckvl
# VavLV0Hsi4qQQ6nTrQ0dl6gXixd7pKeMjJ+exlW/OEArnIL0lY223h9UGp0+JrEw
# d4rwmRGQ/OCiIbikceu0v52NbKpP8ZxlOP+pF2JCyajyuRV7lClxoEjb7BaCjewR
# BPC6+Zij5HNCO0M2H7PtZ64cxU0usNyimykc9FJz1yH1j+/Az6DnR4QxsTM2yFJT
# qicmKzchzdR2qDbnNzRD9ScpgCrsHrhOyUOUYlJYv9hkVGjC48hihFKvtFM2HlPy
# sxi75s468FoFMv6IOC1Ea+nBokvOWLIV5D8lpBUOe6wnwStTjvnvrCNWZrAlZw2Y
# yNA2F1/JV2OFAfS/TQ==
# SIG # End signature block
