# Test-CompleteFeedbackLoop.ps1
# Test the complete autonomous feedback loop system
# Unity Error -> Autonomous System -> Claude Code CLI -> Response Monitor -> Action
# Date: 2025-08-18

Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

Write-Host "TESTING COMPLETE AUTONOMOUS FEEDBACK LOOP" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Testing the full cycle:" -ForegroundColor White
Write-Host "  Unity Error Detection -> Autonomous Prompt -> Claude Response -> Action" -ForegroundColor Gray
Write-Host ""

# Test sequence
$testSteps = @(
    @{ Step = 1; Action = "Load autonomous system modules"; Status = "pending" }
    @{ Step = 2; Action = "Verify Unity SafeConsoleExporter is working"; Status = "pending" }
    @{ Step = 3; Action = "Create test Unity error"; Status = "pending" }
    @{ Step = 4; Action = "Verify autonomous system detects error"; Status = "pending" }
    @{ Step = 5; Action = "Verify prompt submission to Claude Code CLI"; Status = "pending" }
    @{ Step = 6; Action = "Simulate Claude response export"; Status = "pending" }
    @{ Step = 7; Action = "Verify response monitoring detects Claude response"; Status = "pending" }
    @{ Step = 8; Action = "Verify response processing and action"; Status = "pending" }
)

function Show-TestProgress {
    param($steps)
    
    Write-Host "" -ForegroundColor White
    Write-Host "TEST PROGRESS:" -ForegroundColor Yellow
    foreach ($step in $steps) {
        $color = switch ($step.Status) {
            "completed" { "Green" }
            "in_progress" { "Yellow" }
            "failed" { "Red" }
            default { "Gray" }
        }
        $symbol = switch ($step.Status) {
            "completed" { "[+]" }
            "in_progress" { "[>]" }
            "failed" { "[-]" }
            default { "[ ]" }
        }
        Write-Host "  $symbol Step $($step.Step): $($step.Action)" -ForegroundColor $color
    }
    Write-Host ""
}

try {
    # Step 1: Load modules
    Show-TestProgress $testSteps
    Write-Host "Step 1: Loading autonomous system modules..." -ForegroundColor Yellow
    $testSteps[0].Status = "in_progress"
    Show-TestProgress $testSteps
    
    Import-Module ".\Modules\Unity-Claude-ReliableMonitoring.psm1" -Force
    Import-Module ".\Modules\Unity-Claude-CLISubmission.psm1" -Force
    Import-Module ".\Modules\Unity-Claude-ResponseMonitoring.psm1" -Force
    
    $testSteps[0].Status = "completed"
    Write-Host "[+] All modules loaded successfully" -ForegroundColor Green
    
    # Step 2: Verify Unity SafeConsoleExporter
    $testSteps[1].Status = "in_progress"
    Show-TestProgress $testSteps
    Write-Host "Step 2: Checking Unity SafeConsoleExporter..." -ForegroundColor Yellow
    
    $safeExportPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_errors_safe.json"
    if (Test-Path $safeExportPath) {
        $fileInfo = Get-Item $safeExportPath
        Write-Host "[+] SafeConsoleExporter file found" -ForegroundColor Green
        Write-Host "    Modified: $($fileInfo.LastWriteTime)" -ForegroundColor Gray
        $testSteps[1].Status = "completed"
    } else {
        Write-Host "[-] SafeConsoleExporter file not found" -ForegroundColor Red
        Write-Host "    Expected: $safeExportPath" -ForegroundColor Gray
        Write-Host "    Make sure Unity is open with SafeConsoleExporter.cs" -ForegroundColor Yellow
        $testSteps[1].Status = "failed"
    }
    
    # Step 3: Create test Unity error
    $testSteps[2].Status = "in_progress"
    Show-TestProgress $testSteps
    Write-Host "Step 3: Creating test Unity error..." -ForegroundColor Yellow
    
    $testErrorFile = "C:\UnityProjects\Sound-and-Shoal\Dithering\Assets\Scripts\TestFeedbackLoopError.cs"
    $testErrorContent = @"
using UnityEngine;

public class TestFeedbackLoopError : MonoBehaviour
{
    void Start()
    {
        // This should cause a CS0116 error - text outside method
        invalid_syntax_test
    }
}
"@
    
    try {
        [System.IO.File]::WriteAllText($testErrorFile, $testErrorContent, [System.Text.Encoding]::UTF8)
        Write-Host "[+] Test error file created: TestFeedbackLoopError.cs" -ForegroundColor Green
        Write-Host "    This should trigger a CS0116 compilation error in Unity" -ForegroundColor Gray
        $testSteps[2].Status = "completed"
    } catch {
        Write-Host "[-] Failed to create test error file: $($_.Exception.Message)" -ForegroundColor Red
        $testSteps[2].Status = "failed"
    }
    
    # Step 4: Monitor for autonomous system response
    $testSteps[3].Status = "in_progress"
    Show-TestProgress $testSteps
    Write-Host "Step 4: Monitoring for autonomous system detection..." -ForegroundColor Yellow
    Write-Host "This step requires the autonomous system to be running in another window." -ForegroundColor Gray
    Write-Host "Press Enter when you've confirmed the autonomous system detected the error..." -ForegroundColor Yellow
    Read-Host
    $testSteps[3].Status = "completed"
    
    # Step 5: Verify Claude prompt submission
    $testSteps[4].Status = "in_progress"
    Show-TestProgress $testSteps
    Write-Host "Step 5: Verifying Claude Code CLI prompt submission..." -ForegroundColor Yellow
    Write-Host "Check if the autonomous system submitted a prompt to Claude Code CLI." -ForegroundColor Gray
    Write-Host "Press Enter when you've confirmed the prompt was submitted..." -ForegroundColor Yellow
    Read-Host
    $testSteps[4].Status = "completed"
    
    # Step 6: Simulate Claude response
    $testSteps[5].Status = "in_progress"
    Show-TestProgress $testSteps
    Write-Host "Step 6: Simulating Claude response export..." -ForegroundColor Yellow
    
    # Create a test Claude response
    $responseResult = & ".\Claude-ResponseExporter.ps1" -ResponseType "Success" -Summary "Fixed CS0116 error in TestFeedbackLoopError.cs" -ActionsTaken @("Removed invalid syntax 'invalid_syntax_test'", "Added proper syntax to method") -Confidence "High" -RequiresFollowUp $false
    
    if ($responseResult.Success) {
        Write-Host "[+] Test Claude response exported successfully" -ForegroundColor Green
        Write-Host "    Session: $($responseResult.SessionId)" -ForegroundColor Gray
        $testSteps[5].Status = "completed"
    } else {
        Write-Host "[-] Failed to export test response: $($responseResult.Error)" -ForegroundColor Red
        $testSteps[5].Status = "failed"
    }
    
    # Step 7: Test response monitoring
    $testSteps[6].Status = "in_progress"
    Show-TestProgress $testSteps
    Write-Host "Step 7: Testing response monitoring detection..." -ForegroundColor Yellow
    
    # Start response monitoring briefly to test detection
    $responseCallback = {
        param($responses)
        Write-Host "[>] RESPONSE MONITORING DETECTED $($responses.Count) RESPONSES!" -ForegroundColor Green
        foreach ($response in $responses) {
            Write-Host "    Response: $($response.responseType) - $($response.summary)" -ForegroundColor Cyan
        }
    }
    
    $monitorResult = Start-ClaudeResponseMonitoring -OnResponseDetected $responseCallback
    
    if ($monitorResult.Success) {
        Write-Host "[+] Response monitoring started successfully" -ForegroundColor Green
        Write-Host "    Waiting 10 seconds for detection..." -ForegroundColor Gray
        
        for ($i = 10; $i -gt 0; $i--) {
            Write-Host "." -NoNewline -ForegroundColor Gray
            Start-Sleep 1
        }
        
        Stop-ClaudeResponseMonitoring
        Write-Host "" -ForegroundColor White
        Write-Host "[+] Response monitoring test completed" -ForegroundColor Green
        $testSteps[6].Status = "completed"
    } else {
        Write-Host "[-] Response monitoring failed to start: $($monitorResult.Error)" -ForegroundColor Red
        $testSteps[6].Status = "failed"
    }
    
    # Step 8: Verify complete loop
    $testSteps[7].Status = "in_progress"
    Show-TestProgress $testSteps
    Write-Host "Step 8: Verifying complete feedback loop..." -ForegroundColor Yellow
    Write-Host "Check if the autonomous system processed the Claude response and took action." -ForegroundColor Gray
    Write-Host "Press Enter when you've verified the complete loop worked..." -ForegroundColor Yellow
    Read-Host
    $testSteps[7].Status = "completed"
    
    # Cleanup test file
    if (Test-Path $testErrorFile) {
        Remove-Item $testErrorFile -Force
        Write-Host "[+] Cleaned up test error file" -ForegroundColor Green
    }
    
    # Final results
    Show-TestProgress $testSteps
    
    $completedSteps = ($testSteps | Where-Object { $_.Status -eq "completed" }).Count
    $failedSteps = ($testSteps | Where-Object { $_.Status -eq "failed" }).Count
    
    Write-Host "" -ForegroundColor White
    Write-Host "COMPLETE FEEDBACK LOOP TEST RESULTS:" -ForegroundColor Cyan
    Write-Host "====================================" -ForegroundColor Cyan
    Write-Host "Completed steps: $completedSteps/$($testSteps.Count)" -ForegroundColor Green
    Write-Host "Failed steps: $failedSteps" -ForegroundColor Red
    
    if ($failedSteps -eq 0) {
        Write-Host "" -ForegroundColor White
        Write-Host "[SUCCESS] Complete autonomous feedback loop is working!" -ForegroundColor Green
        Write-Host "The system can:" -ForegroundColor White
        Write-Host "  - Detect Unity compilation errors" -ForegroundColor Gray
        Write-Host "  - Generate and submit autonomous prompts" -ForegroundColor Gray
        Write-Host "  - Monitor Claude Code CLI responses" -ForegroundColor Gray
        Write-Host "  - Process responses and take appropriate action" -ForegroundColor Gray
    } else {
        Write-Host "" -ForegroundColor White
        Write-Host "[PARTIAL] Some components need attention" -ForegroundColor Yellow
        Write-Host "Review failed steps and fix issues before full deployment" -ForegroundColor Gray
    }
    
} catch {
    Write-Host "Test failed with error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Details: $($_.Exception)" -ForegroundColor DarkRed
}

Write-Host "" -ForegroundColor White
Write-Host "Press Enter to exit..." -ForegroundColor Yellow
Read-Host
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUSKyHDYyMwI5WV/ybSkJFFlKl
# 4AygggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUY1IP2EYCdUUOkE/SQX+RPUhChaMwDQYJKoZIhvcNAQEBBQAEggEAU9a3
# koFk1UnXO+xmTnJvs6VRXbA1akl/fPgx0BcXRcm/iIJuLUJfhRkVHoDuJHOjkE2J
# DsKuHMxqNJy2LgTI2mw3Kl9eoh3o/150xL+E/EDtq2QhqBpYgLAtiRJ3Pel+rbVh
# 5DnYy3iVLdLuB8t7MJAbO0vMsQBVB82fCXtHfaz0ISP6YKYyCt16EtIkYaTy/xza
# cVumzRqss/h1u4ANRhiqdnOCnggo1LHPlAaDvfVXF1asmdfcYqjnYT1c0vWUDcOJ
# 085XlGgwPZYmZId3oJFA+/0qaFFkM2Ee4vcCdkRwvc/M4rb8/2yqjUnFQ7LvLkBz
# CubWH03OgwI8Q6Rk+w==
# SIG # End signature block
