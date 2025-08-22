# Test-AutonomousResponses.ps1
# Script to test the autonomous agent's response processing

param(
    [Parameter()]
    [ValidateSet("continue", "test", "simple", "unknown", "all")]
    [string]$ResponseType = "all"
)

$responsePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\ClaudeResponses\Autonomous"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Autonomous Agent Response Testing" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Define test files
$testFiles = @{
    "continue" = "test_response_continue.json"
    "test" = "test_response_test.json"
    "simple" = "test_response_simple.json"
    "unknown" = "test_response_unknown.json"
}

function Trigger-Response {
    param(
        [string]$FileName,
        [string]$Type
    )
    
    $sourcePath = Join-Path $responsePath $FileName
    
    if (-not (Test-Path $sourcePath)) {
        Write-Host "  Test file not found: $FileName" -ForegroundColor Red
        return
    }
    
    Write-Host "Testing $Type response:" -ForegroundColor Yellow
    Write-Host "  File: $FileName" -ForegroundColor Gray
    
    # Read and display the response content
    $content = Get-Content $sourcePath | ConvertFrom-Json
    Write-Host "  Response: $($content.response)" -ForegroundColor Cyan
    
    # Create a timestamped copy to trigger the file watcher
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $triggerFile = "triggered_${Type}_${timestamp}.json"
    $triggerPath = Join-Path $responsePath $triggerFile
    
    # Copy the file with updated timestamp
    $content.timestamp = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
    $content | ConvertTo-Json -Depth 10 | Set-Content $triggerPath -Encoding UTF8
    
    Write-Host "  Created trigger file: $triggerFile" -ForegroundColor Green
    Write-Host "  Waiting for agent to process..." -ForegroundColor Gray
    
    # Wait a bit for processing
    Start-Sleep -Seconds 5
    
    # Check if the .pending file was created (indicates queuing)
    $pendingFile = Join-Path $responsePath ".pending"
    if (Test-Path $pendingFile) {
        Write-Host "  File was queued for processing" -ForegroundColor Green
        $pendingContent = Get-Content $pendingFile
        Write-Host "  Pending: $pendingContent" -ForegroundColor Gray
    }
    
    Write-Host ""
}

# Process based on selected type
if ($ResponseType -eq "all") {
    foreach ($type in $testFiles.Keys) {
        Trigger-Response -FileName $testFiles[$type] -Type $type
        
        if ($type -ne ($testFiles.Keys | Select-Object -Last 1)) {
            Write-Host "Waiting 10 seconds before next test..." -ForegroundColor DarkGray
            Start-Sleep -Seconds 10
        }
    }
} else {
    if ($testFiles.ContainsKey($ResponseType)) {
        Trigger-Response -FileName $testFiles[$ResponseType] -Type $ResponseType
    } else {
        Write-Host "Invalid response type: $ResponseType" -ForegroundColor Red
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing Complete" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Check the autonomous agent window for processing results" -ForegroundColor Yellow
Write-Host "Log file: unity_claude_automation.log" -ForegroundColor Gray
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUfjfJHX2FUuwQA3/GCVg62rRE
# fLGgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUrZUiIrQKjZzrf79IILM8pD0N8FwwDQYJKoZIhvcNAQEBBQAEggEAHtg8
# f3vRYpCvgtQEkn4lKKr/Dup4EyuTIHfKU339gF/azO9paFd0OxJV+gg+ZfY0n6y4
# rlLpfNaymPgGRYg4Obke0nvAX8ML6lDGznbnJf83y43fTcAEnfG+WT62XadJD/So
# ZLPwYFcSNZA30jypUd/ZfBnXAyzvIPynHU7Shz0ARPQGFiOu+a/Qa36+shvtiGYN
# uHrco3/a9VUvxI/cALtJGu8aHV3IvnNm4nl78CypjwMUUH5I3ceqVAsBX+5DrpUk
# QGnCwmg5nAdhvg8YkP3TJEpAQRk91C8HesskiyUD/d76a8Y6yQOQ16lHIXv1N+2k
# 32YO+UN+stlIDV035w==
# SIG # End signature block
