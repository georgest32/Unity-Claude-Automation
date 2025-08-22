# Test-ManualCallback.ps1
# Manually test the autonomous callback system
# Date: 2025-08-18

Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

Write-Host "TESTING MANUAL AUTONOMOUS CALLBACK" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan

# Read current Unity errors
$unityErrorPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_errors_safe.json"

if (Test-Path $unityErrorPath) {
    try {
        $content = Get-Content $unityErrorPath -Raw -Encoding UTF8
        # Remove BOM if present
        if ($content[0] -eq [char]0xFEFF) {
            $content = $content.Substring(1)
        }
        
        $errorData = $content | ConvertFrom-Json
        Write-Host "Found $($errorData.totalErrors) errors in JSON file" -ForegroundColor Yellow
        
        # Use PSObject to avoid $Error variable conflict
        $errorList = $errorData.PSObject.Properties['errors'].Value
        if ($errorList -and $errorList.Count -gt 0) {
            # Extract error messages
            $errorMessages = @()
            foreach ($errorItem in $errorList) {
                if ($errorItem.message) {
                    $errorMessages += $errorItem.message
                    Write-Host "  ERROR: $($errorItem.message)" -ForegroundColor Red
                }
            }
            
            Write-Host "" -ForegroundColor White
            Write-Host "Testing enhanced prompt generation..." -ForegroundColor Yellow
            
            # Load the CLISubmission module
            Import-Module ".\Modules\Unity-Claude-CLISubmission.psm1" -Force
            
            # Generate enhanced prompt
            $promptResult = New-AutonomousPrompt -Errors $errorMessages -Context "Manual callback test"
            
            if ($promptResult.Success) {
                Write-Host "[+] Enhanced prompt generated successfully!" -ForegroundColor Green
                Write-Host "    Prompt length: $($promptResult.Prompt.Length) characters" -ForegroundColor Gray
                Write-Host "    Error count: $($promptResult.ErrorCount)" -ForegroundColor Gray
                Write-Host "    Prompt type: $($promptResult.PromptType)" -ForegroundColor Gray
                
                Write-Host "" -ForegroundColor White
                Write-Host "ENHANCED PROMPT PREVIEW:" -ForegroundColor Cyan
                Write-Host "========================" -ForegroundColor Cyan
                
                # Show first 500 characters of prompt
                $previewLength = [Math]::Min(500, $promptResult.Prompt.Length)
                $preview = $promptResult.Prompt.Substring(0, $previewLength)
                Write-Host $preview -ForegroundColor White
                
                if ($promptResult.Prompt.Length -gt 500) {
                    Write-Host "..." -ForegroundColor Gray
                    Write-Host "[Prompt truncated for preview - full prompt is $($promptResult.Prompt.Length) characters]" -ForegroundColor Gray
                }
                
                Write-Host "" -ForegroundColor White
                Write-Host "TEST MANUAL SUBMISSION? (y/n)" -ForegroundColor Yellow
                $response = Read-Host
                
                if ($response -eq 'y' -or $response -eq 'Y') {
                    Write-Host "Testing Claude Code CLI submission..." -ForegroundColor Yellow
                    $submissionResult = Submit-PromptToClaudeCode -Prompt $promptResult.Prompt
                    
                    if ($submissionResult.Success) {
                        Write-Host "[+] SUCCESS! Prompt submitted to Claude Code CLI!" -ForegroundColor Green
                        Write-Host "    Target: $($submissionResult.TargetWindow)" -ForegroundColor Gray
                        Write-Host "    Length: $($submissionResult.PromptLength) characters" -ForegroundColor Gray
                        Write-Host "    Time: $($submissionResult.SubmissionTime)" -ForegroundColor Gray
                    } else {
                        Write-Host "[-] Submission failed: $($submissionResult.Error)" -ForegroundColor Red
                    }
                }
                
            } else {
                Write-Host "[-] Failed to generate prompt: $($promptResult.Error)" -ForegroundColor Red
            }
            
        } else {
            Write-Host "No errors found in JSON file" -ForegroundColor Green
        }
        
    } catch {
        Write-Host "ERROR reading JSON: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "Unity error file not found: $unityErrorPath" -ForegroundColor Red
}

Write-Host "" -ForegroundColor White
Write-Host "Manual test complete. Press Enter to exit..." -ForegroundColor Yellow
Read-Host
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU2l5CbYyz+IDfNAb0lEUg6zhh
# ukWgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU+F/Qbul7oVFPRBaBKmHEsiQTyXwwDQYJKoZIhvcNAQEBBQAEggEAdRsV
# VTZcV6uV66Iq9sTrS32NvEDbqWec0H7D9YHb2pTkMtVSQUROiTHavHpSdJa08c+L
# KU+4C9C3zwCPryg/Hn0yBb3l8VrttmUzxtr4Lhylnb1d1HUrI2Wfs2Bzv4oxtd4c
# O5rFUSw/rRsKpRSr6591bgAdHGxvpHE0r4BZ+WNYjaIfQNWlmoA55VFmahzrAntb
# RR8vc/oQIfQkuzIvWmDyqkHmAhVmrXffnIYyrzemPFTAv3SIlMclZ540BCZKfnwe
# rgSCxWtu2Aoqc/3Zp70YJ6pnYF2/VPW+yzDYBQ76ZO85bdhSmuOGNyq1bVbT22Pq
# glfSMA9VBYMvAo4+pw==
# SIG # End signature block
