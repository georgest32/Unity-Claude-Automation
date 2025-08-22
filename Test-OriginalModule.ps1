Set-Location 'C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation'

Write-Host "=== TESTING ORIGINAL AUTONOMOUS AGENT MODULE ===" -ForegroundColor Cyan

try {
    Import-Module '.\Modules\Unity-Claude-AutonomousAgent\Unity-Claude-AutonomousAgent.psd1' -Force
    Write-Host 'Original module loaded successfully' -ForegroundColor Green
    
    Write-Host 'Starting monitoring with original module...' -ForegroundColor Yellow
    $result = Start-ClaudeResponseMonitoring
    
    Write-Host "Monitoring result: $result" -ForegroundColor Green
    Write-Host "Agent state FileWatcher: $($script:AgentState.FileWatcher)" -ForegroundColor Cyan
    Write-Host "IsMonitoring: $($script:AgentState.IsMonitoring)" -ForegroundColor Cyan
    
    if ($result) {
        Write-Host 'Original module monitoring started. Creating test file...' -ForegroundColor Green
        
        # Wait a moment for watcher to be ready
        Start-Sleep -Seconds 2
        
        # Create test file
        $testFile = "original_test_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
        $testPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\ClaudeResponses\Autonomous\$testFile"
        
        @{
            timestamp = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
            response = "RECOMMENDATION: Test original module FileSystemWatcher"
            type = "test_original"
        } | ConvertTo-Json | Out-File -FilePath $testPath -Encoding UTF8
        
        Write-Host "Created test file: $testFile" -ForegroundColor Green
        
        # Wait and check for processing
        Start-Sleep -Seconds 5
        
        Write-Host "Checking for .pending file..." -ForegroundColor Yellow
        if (Test-Path "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\ClaudeResponses\Autonomous\.pending") {
            Write-Host "SUCCESS: .pending file created!" -ForegroundColor Green
            $pendingContent = Get-Content "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\ClaudeResponses\Autonomous\.pending"
            Write-Host "Pending file contains: $pendingContent" -ForegroundColor Cyan
        } else {
            Write-Host "ISSUE: No .pending file created" -ForegroundColor Red
        }
    }
    
} catch {
    Write-Host "Error testing original module: $($_.Exception.Message)" -ForegroundColor Red
}

Read-Host 'Press Enter to continue'
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUa/efqSZ5T5kpPwbeTUMTg8IZ
# kMugggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUzVIoMqqRrq6oycNHqeB1aXYNkMwwDQYJKoZIhvcNAQEBBQAEggEAC9gY
# nHDi67xLbkuTKnl9xNpylErGlirYzRgAwxu9OMB8O+z33CHbDp3EqvWej+2vtPBg
# FmaRR9SsbN76kKIYtJF+Y91PKfA9i9Zq1+K45NivFgHkkDmOT7QtvJyJ6ZC8dzc3
# S5zyWewZ+InqLeBdvH9ekekGGq8DXhqWLB1AtRBw5k+grM8DMfHDmCo8FySAJLRe
# 4dpTyALcrbhZi30U3JtaVz97iKRxHh1XScByHC+IlHd5lRFUoldX9WxhUqZGeOak
# tsZ+zcKAADREOBTxykhAWfYny3uxWIRr5+WxWCtQvj8J8k6yVPwFXtHcLAA6ZEn4
# q0r2Tregb32Vuv+9qQ==
# SIG # End signature block
