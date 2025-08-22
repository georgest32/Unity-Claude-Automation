# Debug Test Framework Issues
# Analyze the specific array conversion problem

Write-Host "=== Debug Test Framework Issues ===" -ForegroundColor Cyan

try {
    # Import module
    Import-Module ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psm1" -Force
    Write-Host "[OK] Module imported" -ForegroundColor Green
    
    # Test individual function returns
    Write-Host "`n=== Testing Individual Function Returns ===" -ForegroundColor Yellow
    
    # Test 1: Initialize-SystemStatusMonitoring
    $initResult = Initialize-SystemStatusMonitoring -EnableCommunication:$false -EnableFileWatcher:$false
    Write-Host "Initialize-SystemStatusMonitoring result: $initResult (Type: $($initResult.GetType().Name))"
    
    if ($initResult) {
        # Test 2: Register-Subsystem
        $testModulePath = "Modules\Unity-Claude-Core\Unity-Claude-Core.psm1"  
        $projectRoot = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"
        $fullTestModulePath = Join-Path $projectRoot $testModulePath
        Write-Host "Testing module path: $fullTestModulePath"
        Write-Host "Module exists: $(Test-Path $fullTestModulePath)"
        if (Test-Path $fullTestModulePath) {
            $registerResult = Register-Subsystem -SubsystemName "DebugTest" -ModulePath $fullTestModulePath
            Write-Host "Register-Subsystem result: $registerResult (Type: $($registerResult.GetType().Name))"
            
            # Test 3: Update-SubsystemProcessInfo  
            $updateResult = Update-SubsystemProcessInfo -SubsystemName "DebugTest"
            Write-Host "Update-SubsystemProcessInfo result: $updateResult (Type: $($updateResult.GetType().Name))"
            
            # Test 4: Send-Heartbeat
            $heartbeatResult = Send-Heartbeat -SubsystemName "DebugTest" -HealthScore 0.9
            Write-Host "Send-Heartbeat result: $heartbeatResult (Type: $($heartbeatResult.GetType().Name))"
            
        } else {
            Write-Host "[WARN] Test module not found: $testModulePath" -ForegroundColor Yellow
        }
    }
    
    # Test the Add-TestResult function pattern
    Write-Host "`n=== Testing Add-TestResult Pattern ===" -ForegroundColor Yellow
    
    function Test-AddTestResult {
        param([string]$TestName, [bool]$Passed, [string]$Details = "")
        Write-Host "Test: $TestName | Passed: $Passed (Type: $($Passed.GetType().Name)) | Details: $Details"
    }
    
    # Test with our actual results
    if ($initResult) {
        Test-AddTestResult "Initialize test" $initResult "Testing boolean conversion"
        if ($registerResult) {
            Test-AddTestResult "Register test" $registerResult "Testing boolean conversion"
        }
    }
    
    Write-Host "`n=== Debug Complete ===" -ForegroundColor Cyan
    
    # Cleanup
    Stop-SystemStatusMonitoring | Out-Null
    
} catch {
    Write-Host "[ERROR] Debug failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Exception Type: $($_.Exception.GetType().Name)" -ForegroundColor Red
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUBBqIVXTHLMogPd0v3KAiEOTo
# o/CgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUiY1OK00ol9Eevf2o33gdTIShgr8wDQYJKoZIhvcNAQEBBQAEggEAXeCs
# RkDdWtIU+BeN3C2zj5dO2+QckKN8aqbEwweRfDrtvGgotjSsm6p7U7XaJ35ntBJN
# Dyr8JnpTJYYiuEMsmnJwvQVVQ6NlFhVFbYSQhtEcoai2knS/51AOosMpwmSOWcT7
# 03JqqYP94dhAVtx8nBGFBTfAhitzPcbmpHEw74ToN8Z3WcuxKP4QwWHBp5TN/Qtx
# 2ajbV7GArkb9g6vNlRHqMcbzG1JaBOr2gdQT+LujgTNj2Zdb1UDMnu762RVlqCUC
# Bn8uAw6jV87dYVE63U64L21pVQs+dDs/EVeQRDX6W5jVoobOeWw+hLYlXNV3ADhA
# EDGRjWSd2dN0aTokQQ==
# SIG # End signature block
