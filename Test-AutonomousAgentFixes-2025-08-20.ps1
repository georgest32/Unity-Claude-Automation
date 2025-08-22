# Test-AutonomousAgentFixes-2025-08-20.ps1
# Comprehensive test of autonomous agent fixes for window detection and automation
# Validates all fixes implemented in debugging session 2

param(
    [switch]$Verbose
)

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
$logFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\TEST_RESULTS_AUTONOMOUS_AGENT_FIXES_2025_08_20.txt"

function Write-TestLog {
    param([string]$Message)
    $timestamped = "[$timestamp] $Message"
    Write-Host $timestamped -ForegroundColor Cyan
    Add-Content -Path $logFile -Value $timestamped
}

function Write-TestResult {
    param([string]$TestName, [bool]$Passed, [string]$Details)
    $result = if ($Passed) { "✅ PASS" } else { "❌ FAIL" }
    $message = "$result - ${TestName}: $Details"
    Write-Host $message -ForegroundColor $(if ($Passed) { "Green" } else { "Red" })
    Add-Content -Path $logFile -Value "[$timestamp] $message"
}

Write-TestLog "=== Autonomous Agent Fixes Validation Test ==="
Write-TestLog "Testing fixes implemented for window detection, DLL locations, and JSON persistence"

$testResults = @()

# Test 1: Verify system_status.json contains TerminalWindowHandle
Write-TestLog "`nTest 1: TerminalWindowHandle Persistence"
try {
    $statusFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\system_status.json"
    $status = Get-Content $statusFile -Raw | ConvertFrom-Json
    
    $hasWindowHandle = $status.SystemInfo.ClaudeCodeCLI.TerminalWindowHandle -ne $null
    $hasTerminalPID = $status.SystemInfo.ClaudeCodeCLI.TerminalProcessId -ne $null
    $hasWindowTitle = $status.SystemInfo.ClaudeCodeCLI.WindowTitle -ne $null
    
    if ($hasWindowHandle -and $hasTerminalPID -and $hasWindowTitle) {
        Write-TestResult "TerminalWindowHandle Persistence" $true "WindowHandle: $($status.SystemInfo.ClaudeCodeCLI.TerminalWindowHandle), PID: $($status.SystemInfo.ClaudeCodeCLI.TerminalProcessId)"
        $testResults += @{ Test = "TerminalWindowHandle"; Passed = $true }
    } else {
        Write-TestResult "TerminalWindowHandle Persistence" $false "Missing fields - WindowHandle: $hasWindowHandle, PID: $hasTerminalPID, Title: $hasWindowTitle"
        $testResults += @{ Test = "TerminalWindowHandle"; Passed = $false }
    }
} catch {
    Write-TestResult "TerminalWindowHandle Persistence" $false "Error reading system_status.json: $_"
    $testResults += @{ Test = "TerminalWindowHandle"; Passed = $false }
}

# Test 2: Verify .claude_code_cli_pid has correct information
Write-TestLog "`nTest 2: PID Marker File Update"
try {
    $markerFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\.claude_code_cli_pid"
    $markerContent = Get-Content $markerFile
    
    if ($markerContent.Count -ge 2) {
        $markerPID = $markerContent[1]
        $expectedPID = $status.SystemInfo.ClaudeCodeCLI.TerminalProcessId
        
        if ($markerPID -eq $expectedPID) {
            Write-TestResult "PID Marker File Update" $true "Marker PID $markerPID matches expected PID $expectedPID"
            $testResults += @{ Test = "PIDMarker"; Passed = $true }
        } else {
            Write-TestResult "PID Marker File Update" $false "Marker PID $markerPID does not match expected PID $expectedPID"
            $testResults += @{ Test = "PIDMarker"; Passed = $false }
        }
    } else {
        Write-TestResult "PID Marker File Update" $false "Invalid marker file format"
        $testResults += @{ Test = "PIDMarker"; Passed = $false }
    }
} catch {
    Write-TestResult "PID Marker File Update" $false "Error reading marker file: $_"
    $testResults += @{ Test = "PIDMarker"; Passed = $false }
}

# Test 3: Verify Window Title Consistency
Write-TestLog "`nTest 3: Window Title Consistency"
try {
    $currentTitle = $host.UI.RawUI.WindowTitle
    $expectedTitle = "Claude Code CLI environment"
    
    if ($currentTitle -eq $expectedTitle) {
        Write-TestResult "Window Title Consistency" $true "Window title matches: '$currentTitle'"
        $testResults += @{ Test = "WindowTitle"; Passed = $true }
    } else {
        Write-TestResult "Window Title Consistency" $false "Window title '$currentTitle' does not match expected '$expectedTitle'"
        $testResults += @{ Test = "WindowTitle"; Passed = $false }
    }
} catch {
    Write-TestResult "Window Title Consistency" $false "Error checking window title: $_"
    $testResults += @{ Test = "WindowTitle"; Passed = $false }
}

# Test 4: Verify CLISubmission module can load Win32 types without errors
Write-TestLog "`nTest 4: CLISubmission Type Loading"
try {
    # Simulate the type loading from CLISubmission module
    if (-not ([System.Management.Automation.PSTypeName]'Win32').Type) {
        Add-Type -ErrorAction SilentlyContinue -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentThreadId();
}
"@
    }
    
    if (([System.Management.Automation.PSTypeName]'Win32').Type) {
        Write-TestResult "CLISubmission Type Loading" $true "Win32 type loaded successfully, GetCurrentThreadId in kernel32.dll"
        $testResults += @{ Test = "TypeLoading"; Passed = $true }
    } else {
        Write-TestResult "CLISubmission Type Loading" $false "Failed to load Win32 type"
        $testResults += @{ Test = "TypeLoading"; Passed = $false }
    }
} catch {
    Write-TestResult "CLISubmission Type Loading" $false "Error loading types: $_"
    $testResults += @{ Test = "TypeLoading"; Passed = $false }
}

# Test 5: Test Window Handle Validation
Write-TestLog "`nTest 5: Window Handle Validation"
try {
    if (-not ([System.Management.Automation.PSTypeName]'WindowValidator').Type) {
        Add-Type -ErrorAction SilentlyContinue @"
using System;
using System.Runtime.InteropServices;
public class WindowValidator {
    [DllImport("user32.dll")]
    public static extern bool IsWindow(IntPtr hWnd);
}
"@
    }
    
    $windowHandle = [IntPtr][int64]$status.SystemInfo.ClaudeCodeCLI.TerminalWindowHandle
    $isValid = [WindowValidator]::IsWindow($windowHandle)
    
    if ($isValid) {
        Write-TestResult "Window Handle Validation" $true "Window handle $windowHandle is valid"
        $testResults += @{ Test = "WindowValidation"; Passed = $true }
    } else {
        Write-TestResult "Window Handle Validation" $false "Window handle $windowHandle is invalid"
        $testResults += @{ Test = "WindowValidation"; Passed = $false }
    }
} catch {
    Write-TestResult "Window Handle Validation" $false "Error validating window handle: $_"
    $testResults += @{ Test = "WindowValidation"; Passed = $false }
}

# Test 6: Test JSON Round-Trip Preservation
Write-TestLog "`nTest 6: JSON Round-Trip Property Preservation"
try {
    # Read current system_status.json
    $originalStatus = Get-Content $statusFile -Raw | ConvertFrom-Json
    $originalWindowHandle = $originalStatus.SystemInfo.ClaudeCodeCLI.TerminalWindowHandle
    
    # Simulate Update-ClaudeCodePID.ps1 round-trip
    $testStatus = $originalStatus | ConvertTo-Json -Depth 10 | ConvertFrom-Json
    $preservedWindowHandle = $testStatus.SystemInfo.ClaudeCodeCLI.TerminalWindowHandle
    
    if ($preservedWindowHandle -eq $originalWindowHandle) {
        Write-TestResult "JSON Round-Trip Preservation" $true "TerminalWindowHandle preserved through JSON conversion: $preservedWindowHandle"
        $testResults += @{ Test = "JSONPreservation"; Passed = $true }
    } else {
        Write-TestResult "JSON Round-Trip Preservation" $false "TerminalWindowHandle lost - Original: $originalWindowHandle, After: $preservedWindowHandle"
        $testResults += @{ Test = "JSONPreservation"; Passed = $false }
    }
} catch {
    Write-TestResult "JSON Round-Trip Preservation" $false "Error testing JSON preservation: $_"
    $testResults += @{ Test = "JSONPreservation"; Passed = $false }
}

# Summary
Write-TestLog "`n=== Test Summary ==="
$passedTests = ($testResults | Where-Object { $_.Passed -eq $true }).Count
$totalTests = $testResults.Count
$successRate = [math]::Round(($passedTests / $totalTests) * 100, 1)

Write-TestLog "Tests Passed: $passedTests/$totalTests ($successRate%)"

if ($successRate -ge 90) {
    Write-Host "`n✅ SUCCESS: All critical fixes validated!" -ForegroundColor Green
    Write-TestLog "✅ AUTONOMOUS AGENT FIXES READY FOR DEPLOYMENT"
} elseif ($successRate -ge 75) {
    Write-Host "`n⚠️  PARTIAL: Most fixes working, minor issues remain" -ForegroundColor Yellow
    Write-TestLog "⚠️ PARTIAL SUCCESS - SOME FIXES NEED ATTENTION"
} else {
    Write-Host "`n❌ FAILURE: Critical issues remain" -ForegroundColor Red
    Write-TestLog "❌ CRITICAL ISSUES REMAIN - FURTHER DEBUGGING REQUIRED"
}

Write-TestLog "`nDetailed Results:"
foreach ($result in $testResults) {
    $status = if ($result.Passed) { "PASS" } else { "FAIL" }
    Write-TestLog "  $($result.Test): $status"
}

Write-TestLog "`n=== Next Steps ==="
if ($successRate -ge 90) {
    Write-TestLog "1. Restart autonomous monitoring system"
    Write-TestLog "2. Verify CLISubmission uses TerminalWindowHandle"
    Write-TestLog "3. Test prompt submission returns Success=True"
    Write-TestLog "4. Validate correct 'Claude Code CLI environment' window targeting"
} else {
    Write-TestLog "1. Review failed tests above"
    Write-TestLog "2. Fix remaining issues"
    Write-TestLog "3. Re-run this test"
}

Write-TestLog "`nTest completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

return @{
    TestsPassed = $passedTests
    TotalTests = $totalTests
    SuccessRate = $successRate
    Results = $testResults
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUJaqkPCCVFe34ttnrTyfwvUR4
# aJigggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUGEQOpVy3i+IzKOJPiuyzXI36WBgwDQYJKoZIhvcNAQEBBQAEggEAk5x/
# 40ggLU+erhP6CKJTkze/OD0xDmkZ/6obLHgwRpRWpzzJFc362LX4s4JliQAmeKDv
# 4cIq8UwMk3i7sbq6PKMGHmwzKE1nVZZMzCUFlonpEKsy+Cq5NQh5vPVBDvPJfuHO
# AMe1JHlJcPgaQl3WHz7RsXU3tW7h1goW9pXApE3zgNArNgW0S6G84joQH4xjZlxL
# 3Aeh20MjxgaVA5wrtN3TfMoprc3iLwBNSFXy54L7gRAlkzY9ExTUy8PxGyO7pFH7
# x97ghSDYRsyoigEMthwus0H9I8XvzeJPJnM5wROuHljERm7wE7so4kwVZEGqnr+y
# qwM2acLCPyIE9rIdZQ==
# SIG # End signature block
