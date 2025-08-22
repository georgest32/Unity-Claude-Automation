# Test-ReferenceParameterPassing-Fix.ps1
# Research-validated fix for synchronized collection parameter passing in runspaces
# Uses AddArgument([ref]) pattern instead of AddParameters() approach
# Date: 2025-08-21

Write-Host "=== Reference-Based Parameter Passing Fix Test ===" -ForegroundColor Cyan
Write-Host "Testing research-validated AddArgument([ref]) pattern for synchronized collections" -ForegroundColor Yellow

try {
    # Import Unity-Claude-RunspaceManagement module
    Import-Module ".\Modules\Unity-Claude-RunspaceManagement\Unity-Claude-RunspaceManagement.psd1" -Force
    
    Write-Host "`n1. Creating synchronized collections for reference passing..." -ForegroundColor White
    
    # Create synchronized collections (research-validated pattern)
    $unityErrors = [System.Collections.ArrayList]::Synchronized([System.Collections.ArrayList]::new())
    $claudeResponses = [System.Collections.ArrayList]::Synchronized([System.Collections.ArrayList]::new())
    
    Write-Host "    Initial counts - Errors: $($unityErrors.Count), Responses: $($claudeResponses.Count)" -ForegroundColor Gray
    
    Write-Host "`n2. Creating runspace pool with session state..." -ForegroundColor White
    
    # Create session state and pool
    $sessionConfig = New-RunspaceSessionState
    $pool = New-ProductionRunspacePool -SessionStateConfig $sessionConfig -MaxRunspaces 2 -Name "ReferenceTestPool"
    Open-RunspacePool -PoolManager $pool | Out-Null
    
    Write-Host "`n3. Testing direct PowerShell.Create() with AddArgument([ref]) pattern..." -ForegroundColor White
    
    # Create PowerShell instances manually to use AddArgument([ref]) pattern
    $jobs = @()
    
    # Job 1: Unity Error Detection with reference parameter
    $unityErrorScript = {
        param([ref]$UnityErrors, $errorId)
        
        $error = @{
            ErrorId = $errorId
            Type = "CS0246"
            Message = "Test error $errorId"
            Detected = Get-Date
        }
        
        # Use .Value to access the referenced synchronized collection
        $UnityErrors.Value.Add($error)
        
        return "Unity error $errorId added to collection (Count: $($UnityErrors.Value.Count))"
    }
    
    $ps1 = [powershell]::Create()
    $ps1.RunspacePool = $pool.RunspacePool
    $ps1.AddScript($unityErrorScript)
    $ps1.AddArgument([ref]$unityErrors)  # Reference passing
    $ps1.AddArgument(1)                  # Regular parameter
    
    # Job 2: Claude Response with reference parameter
    $claudeResponseScript = {
        param([ref]$ClaudeResponses, $responseId)
        
        $response = @{
            ResponseId = $responseId
            Content = "Test response $responseId"
            Submitted = Get-Date
        }
        
        # Use .Value to access the referenced synchronized collection
        $ClaudeResponses.Value.Add($response)
        
        return "Claude response $responseId added to collection (Count: $($ClaudeResponses.Value.Count))"
    }
    
    $ps2 = [powershell]::Create()
    $ps2.RunspacePool = $pool.RunspacePool
    $ps2.AddScript($claudeResponseScript)
    $ps2.AddArgument([ref]$claudeResponses)  # Reference passing
    $ps2.AddArgument(2)                      # Regular parameter
    
    # Start execution
    $async1 = $ps1.BeginInvoke()
    $async2 = $ps2.BeginInvoke()
    
    $jobs += @{PowerShell = $ps1; AsyncResult = $async1; Name = "UnityError"}
    $jobs += @{PowerShell = $ps2; AsyncResult = $async2; Name = "ClaudeResponse"}
    
    Write-Host "`n4. Waiting for jobs completion..." -ForegroundColor White
    
    # Wait for completion
    while ($jobs | Where-Object { -not $_.AsyncResult.IsCompleted }) {
        Start-Sleep -Milliseconds 100
    }
    
    # Retrieve results
    foreach ($job in $jobs) {
        try {
            $result = $job.PowerShell.EndInvoke($job.AsyncResult)
            Write-Host "    $($job.Name) result: $result" -ForegroundColor Gray
            $job.PowerShell.Dispose()
        } catch {
            Write-Host "    $($job.Name) error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    Write-Host "`n5. Validating synchronized collection updates..." -ForegroundColor White
    
    # Check final counts
    $finalErrorCount = $unityErrors.Count
    $finalResponseCount = $claudeResponses.Count
    
    Write-Host "    Final counts - Errors: $finalErrorCount, Responses: $finalResponseCount" -ForegroundColor Gray
    
    if ($finalErrorCount -eq 1 -and $finalResponseCount -eq 1) {
        Write-Host "    [SUCCESS] Reference parameter passing working correctly!" -ForegroundColor Green
        Write-Host "    Error details: $($unityErrors[0].Type) - $($unityErrors[0].Message)" -ForegroundColor Gray
        Write-Host "    Response details: $($claudeResponses[0].Content)" -ForegroundColor Gray
    } else {
        Write-Host "    [FAIL] Reference parameter passing still not working" -ForegroundColor Red
        Write-Host "    Expected: 1 error, 1 response. Got: $finalErrorCount errors, $finalResponseCount responses" -ForegroundColor Red
    }
    
    # Cleanup
    Close-RunspacePool -PoolManager $pool | Out-Null
    
    Write-Host "`n=== REFERENCE PARAMETER PASSING TEST COMPLETE ===" -ForegroundColor Green
    if ($finalErrorCount -eq 1 -and $finalResponseCount -eq 1) {
        Write-Host "Research-validated AddArgument([ref]) pattern successful" -ForegroundColor Green
    } else {
        Write-Host "Reference parameter passing needs further investigation" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "[FAIL] Reference parameter passing test failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.Exception.ToString() -ForegroundColor Red
}

Write-Host "`nReference parameter passing test completed at $(Get-Date)" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU1i9elHAE+qNF2kgxUnULHt4D
# xAOgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUfgfORTUD7j6KJWgREyPooYDIJ9cwDQYJKoZIhvcNAQEBBQAEggEAnd7P
# UeecFJshwXqu+yKg5DG6HgN6KcEd1JBu4Hy76qmCU4orBsOvg0QyX6wlxG7fpEJZ
# pl6t43fXk+Yk8lqZ7sx/p6C0GXhMNDuO3OoabYtc/gkVDnWbb3LwLqNj51y4BHLx
# NnWzeLQqwOmaWeZcCzOyTrL6cKej2RafbXCu7bmADkNimTpBhBHJdDm2RbgvzzMU
# zy1VONZIOHtC6OLyU+lvngsT6IskgkxN3sThNYgINODRbnXq3WoTiKFjdK5A3bTQ
# p4Yz4jXlrAEBZ0SwmDJwmEho4gWtMBLEOLeWczGLUQDlKku6Kq1VAbUvBE6gRgg6
# JTZ4BonIT5W6Mlxi6g==
# SIG # End signature block
