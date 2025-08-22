# Quick verification test for the DateTime op_Subtraction fix
# Tests the specific functions that were failing before

Write-Host "=== DateTime Fix Verification Test ===" -ForegroundColor Cyan
Write-Host "Testing the specific functions that were failing..." -ForegroundColor Gray

try {
    # Import the fixed module
    Import-Module ".\Modules\Unity-Claude-AutonomousStateTracker-Enhanced.psm1" -Force
    Write-Host "[+] Module imported successfully" -ForegroundColor Green
    
    # Test 1: Initialize state tracking (this uses DateTime operations)
    Write-Host "`nTest 1: Initialize Enhanced State Tracking" -ForegroundColor Yellow
    $testAgentId = "QuickTest-$(Get-Date -Format 'HHmmss')"
    $agentState = Initialize-EnhancedAutonomousStateTracking -AgentId $testAgentId
    if ($agentState) {
        Write-Host "[+] State initialization: SUCCESS" -ForegroundColor Green
    } else {
        Write-Host "[-] State initialization: FAILED" -ForegroundColor Red
    }
    
    # Test 2: Get state with uptime calculation (this was the main failure point)
    Write-Host "`nTest 2: Get Enhanced State (tests DateTime arithmetic)" -ForegroundColor Yellow
    $stateInfo = Get-EnhancedAutonomousState -AgentId $testAgentId -IncludePerformanceMetrics
    if ($stateInfo -and $stateInfo.UptimeMinutes -ge 0) {
        Write-Host "[+] State retrieval with uptime: SUCCESS (Uptime: $($stateInfo.UptimeMinutes) minutes)" -ForegroundColor Green
    } else {
        Write-Host "[-] State retrieval with uptime: FAILED" -ForegroundColor Red
    }
    
    # Test 3: Save and reload state (JSON persistence test)
    Write-Host "`nTest 3: State Persistence" -ForegroundColor Yellow
    try {
        # Get the current agent state directly instead of using checkpoint ID
        $currentState = Get-EnhancedAutonomousState -AgentId $testAgentId
        if ($currentState -and $currentState -is [hashtable]) {
            Save-AgentState -AgentState $currentState
            $reloadedState = Get-AgentState -AgentId $testAgentId
            if ($reloadedState -and $reloadedState.AgentId -eq $testAgentId) {
                Write-Host "[+] State persistence: SUCCESS" -ForegroundColor Green
            } else {
                Write-Host "[-] State persistence: FAILED" -ForegroundColor Red
            }
        } else {
            Write-Host "[-] State persistence: ERROR - Invalid state object" -ForegroundColor Red
        }
    } catch {
        Write-Host "[-] State persistence: ERROR - $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Test 4: Create checkpoint (another DateTime operation)
    Write-Host "`nTest 4: Checkpoint Creation" -ForegroundColor Yellow
    try {
        # Get the current agent state directly for checkpoint
        $stateForCheckpoint = Get-EnhancedAutonomousState -AgentId $testAgentId
        if ($stateForCheckpoint -and $stateForCheckpoint -is [hashtable]) {
            $checkpointId = New-StateCheckpoint -AgentState $stateForCheckpoint -Reason "Verification test"
            if ($checkpointId) {
                Write-Host "[+] Checkpoint creation: SUCCESS (ID: $checkpointId)" -ForegroundColor Green
            } else {
                Write-Host "[-] Checkpoint creation: FAILED" -ForegroundColor Red
            }
        } else {
            Write-Host "[-] Checkpoint creation: ERROR - Invalid state object" -ForegroundColor Red
        }
    } catch {
        Write-Host "[-] Checkpoint creation: ERROR - $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host "`n=== Verification Complete ===" -ForegroundColor Cyan
    Write-Host "If all tests show SUCCESS, the DateTime fix is working correctly." -ForegroundColor Gray
    
} catch {
    Write-Host "[-] ERROR during testing: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkRed
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUG+EVwn6W5TsDM5Oqw2Op59lC
# dGGgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU+GvcmT4wzkZ9Qqvfb7pK7Ul5XZgwDQYJKoZIhvcNAQEBBQAEggEAoY1J
# tnOfEoCvoHGMAYgHQ/swcj2Q2ls6axG3GD5coF1evIBig3/N2gvkKdeQFV1OV0mB
# qBHM1X/5cLhx2vPlCg46LuhlRP9jz4FbR4pxCCDqcQSWqcmdAiBGPL2LyXZB3kXU
# 36peKKVJUXaQAWqu+TyhCoJTtVu3TPbQOGIZoLSZWgU4R8Z402u77+d+BaUbmwNQ
# 2INOHLR9i8UndCbylPXInGhNe0S8y/eNe0Zl3Kz/IkpckFTHvT2XlHQYI12ewrEJ
# Qczf+6t4siIaSIm8HPWAYK1WTZcVLjUpOcgwayzaZt8YvsA/7PVUCpaUye20OmnM
# NvYnFqxko0L7Ul0qvg==
# SIG # End signature block
