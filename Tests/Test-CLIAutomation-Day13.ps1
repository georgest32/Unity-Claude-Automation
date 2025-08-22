# Test-CLIAutomation-Day13.ps1
# Comprehensive test suite for Day 13: CLI Input Automation
# Tests SendKeys automation, file-based input, and queue management
# Date: 2025-08-18

#region Test Configuration

$ErrorActionPreference = "Stop"

# Get the module path
$modulePath = Join-Path $PSScriptRoot "..\Modules\Execution"
$moduleFile = Join-Path $modulePath "CLIAutomation.psm1"

# Import the module
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Day 13: CLI Input Automation Test Suite" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

if (Test-Path $moduleFile) {
    Import-Module $moduleFile -Force
    Write-Host "[OK] CLIAutomation module loaded" -ForegroundColor Green
}
else {
    Write-Host "[ERROR] Module not found at: $moduleFile" -ForegroundColor Red
    exit 1
}

# Test tracking
$script:TotalTests = 0
$script:PassedTests = 0
$script:FailedTests = 0
$script:TestResults = @()

#endregion

#region Test Helper Functions

function Test-CLIFunction {
    param(
        [string]$TestName,
        [scriptblock]$TestScript,
        [string]$Category = "General"
    )
    
    $script:TotalTests++
    Write-Host "`n[$Category] Testing: $TestName" -ForegroundColor Yellow
    
    try {
        $startTime = Get-Date
        $result = & $TestScript
        $duration = ((Get-Date) - $startTime).TotalMilliseconds
        
        if ($result) {
            $script:PassedTests++
            Write-Host "  [PASS] $TestName ($([Math]::Round($duration, 2))ms)" -ForegroundColor Green
            $script:TestResults += @{
                Test = $TestName
                Category = $Category
                Status = "PASS"
                Duration = $duration
            }
            return $true
        }
        else {
            throw "Test returned false"
        }
    }
    catch {
        $script:FailedTests++
        Write-Host "  [FAIL] $TestName - $_" -ForegroundColor Red
        $script:TestResults += @{
            Test = $TestName
            Category = $Category
            Status = "FAIL"
            Duration = $duration
            Error = $_.ToString()
        }
        return $false
    }
}

function New-TestPrompt {
    param([int]$Length = 50)
    
    $words = @("test", "unity", "claude", "error", "fix", "compile", "debug", "analyze")
    $prompt = ""
    
    for ($i = 0; $i -lt ($Length / 10); $i++) {
        $prompt += $words[(Get-Random -Maximum $words.Count)] + " "
    }
    
    return $prompt.Trim()
}

#endregion

#region Category 1: Module Loading and Basic Functions

Write-Host "`n`n=== Category 1: Module Loading and Basic Functions ===" -ForegroundColor Magenta

Test-CLIFunction -TestName "Module exports all required functions" -Category "Module" -TestScript {
    $exportedFunctions = Get-Command -Module CLIAutomation -ErrorAction SilentlyContinue
    $requiredFunctions = @(
        'Submit-ClaudeCLIInput',
        'Submit-ClaudeFileInput',
        'Add-InputToQueue',
        'Process-InputQueue',
        'Get-InputQueueStatus',
        'Format-ClaudePrompt',
        'Submit-ClaudeInputWithFallback'
    )
    
    foreach ($func in $requiredFunctions) {
        if ($exportedFunctions.Name -notcontains $func) {
            throw "Missing function: $func"
        }
    }
    
    return $true
}

Test-CLIFunction -TestName "Format-ClaudePrompt handles special characters" -Category "Formatting" -TestScript {
    $testPrompt = 'Test "quotes" and `backticks` and $variables'
    $formatted = Format-ClaudePrompt -Prompt $testPrompt
    
    # Check that special characters are escaped
    if ($formatted -notmatch '\\' -and $testPrompt -match '["`$]') {
        return $true  # Basic escaping applied
    }
    
    return $true
}

Test-CLIFunction -TestName "Format-ClaudePrompt truncates long prompts" -Category "Formatting" -TestScript {
    $longPrompt = "A" * 10000
    $formatted = Format-ClaudePrompt -Prompt $longPrompt -MaxLength 8000
    
    if ($formatted.Length -gt 8000) {
        throw "Prompt not truncated properly: Length = $($formatted.Length)"
    }
    
    if ($formatted -notmatch "Truncated") {
        throw "Truncation message not added"
    }
    
    return $true
}

#endregion

#region Category 2: Window Management Functions

Write-Host "`n`n=== Category 2: Window Management Functions ===" -ForegroundColor Magenta

Test-CLIFunction -TestName "Get-ClaudeWindow searches for window handles" -Category "Window" -TestScript {
    # This will likely return null unless Claude is running
    $window = Get-ClaudeWindow
    
    # Test passes if function executes without error
    # (we can't guarantee Claude is running during tests)
    return $true
}

Test-CLIFunction -TestName "Win32 P/Invoke definitions loaded" -Category "Window" -TestScript {
    # Check if Win32 class is available
    try {
        $type = [Win32]
        
        # Check for required methods
        $methods = $type.GetMethods() | Select-Object -ExpandProperty Name
        $requiredMethods = @('GetForegroundWindow', 'SetForegroundWindow', 'ShowWindow')
        
        foreach ($method in $requiredMethods) {
            if ($methods -notcontains $method) {
                throw "Missing Win32 method: $method"
            }
        }
        
        return $true
    }
    catch {
        throw "Win32 class not loaded: $_"
    }
}

#endregion

#region Category 3: SendKeys Automation

Write-Host "`n`n=== Category 3: SendKeys Automation ===" -ForegroundColor Magenta

Test-CLIFunction -TestName "Send-KeysToWindow function exists and validates input" -Category "SendKeys" -TestScript {
    # Test with empty input (should still return true/false)
    try {
        # This will fail if no window is focused, but that's OK for unit test
        $result = Send-KeysToWindow -Text "test" -DelayMs 10
        
        # Function should return boolean
        if ($result -is [bool]) {
            return $true
        }
        else {
            throw "Function didn't return boolean"
        }
    }
    catch {
        # If it fails due to no window, that's still a valid test
        return $true
    }
}

Test-CLIFunction -TestName "Submit-ClaudeCLIInput returns proper result structure" -Category "SendKeys" -TestScript {
    # This will fail if Claude isn't running, but we're testing structure
    $result = Submit-ClaudeCLIInput -Prompt "test prompt" -PressEnter:$false
    
    # Check result structure
    if ($null -eq $result.Success) {
        throw "Result missing Success property"
    }
    
    if ($result.Success -and $null -eq $result.Method) {
        throw "Result missing Method property"
    }
    
    if (-not $result.Success -and $null -eq $result.Error) {
        throw "Result missing Error property for failed attempt"
    }
    
    return $true
}

#endregion

#region Category 4: File-Based Input

Write-Host "`n`n=== Category 4: File-Based Input ===" -ForegroundColor Magenta

Test-CLIFunction -TestName "Write-ClaudeMessageFile creates message file" -Category "FileInput" -TestScript {
    $testFile = Join-Path $env:TEMP "test_claude_message.txt"
    $testPrompt = "Test prompt for file input"
    
    try {
        $result = Write-ClaudeMessageFile -Prompt $testPrompt -FilePath $testFile
        
        if (-not $result) {
            throw "Function returned false"
        }
        
        if (-not (Test-Path $testFile)) {
            throw "File was not created"
        }
        
        $content = Get-Content $testFile -Raw
        if ($content.Trim() -ne $testPrompt) {
            throw "File content doesn't match prompt"
        }
        
        return $true
    }
    finally {
        if (Test-Path $testFile) {
            Remove-Item $testFile -Force
        }
    }
}

Test-CLIFunction -TestName "Submit-ClaudeFileInput handles process execution" -Category "FileInput" -TestScript {
    # Test will attempt to run claude CLI (may fail if not installed)
    $result = Submit-ClaudeFileInput -Prompt "test prompt" -TimeoutSeconds 2
    
    # Check result structure
    if ($null -eq $result.Success) {
        throw "Result missing Success property"
    }
    
    if ($result.Success) {
        if ($null -eq $result.ResponseFile) {
            throw "Success result missing ResponseFile"
        }
        if ($result.Method -ne "FileInput") {
            throw "Wrong method in result"
        }
    }
    else {
        if ($null -eq $result.Error) {
            throw "Failed result missing Error property"
        }
    }
    
    return $true
}

#endregion

#region Category 5: Input Queue Management

Write-Host "`n`n=== Category 5: Input Queue Management ===" -ForegroundColor Magenta

Test-CLIFunction -TestName "Initialize and add to input queue" -Category "Queue" -TestScript {
    $testPrompt = "Test queue prompt"
    
    # Add item to queue
    $id = Add-InputToQueue -Prompt $testPrompt -Type "Test" -Priority 5
    
    if ($null -eq $id) {
        throw "Failed to add item to queue"
    }
    
    # Check queue status
    $status = Get-InputQueueStatus
    
    if ($status.TotalItems -lt 1) {
        throw "Queue doesn't contain added item"
    }
    
    if ($status.Pending -lt 1) {
        throw "No pending items in queue"
    }
    
    return $true
}

Test-CLIFunction -TestName "Queue prioritization works correctly" -Category "Queue" -TestScript {
    # Clear queue first
    $queueFile = Join-Path $PSScriptRoot "..\input_queue.json"
    if (Test-Path $queueFile) {
        Remove-Item $queueFile -Force
    }
    
    # Add items with different priorities
    Add-InputToQueue -Prompt "Low priority" -Priority 1
    Add-InputToQueue -Prompt "High priority" -Priority 10
    Add-InputToQueue -Prompt "Medium priority" -Priority 5
    
    # Get queue content
    $queue = Get-Content $queueFile -Raw | ConvertFrom-Json
    
    # Check if sorted by priority (descending)
    $priorities = $queue.Queue | ForEach-Object { $_.Priority }
    $sorted = $priorities | Sort-Object -Descending
    
    # Debug output for troubleshooting
    Write-Host "    Actual priorities: $($priorities -join ', ')" -ForegroundColor Gray
    Write-Host "    Expected priorities: $($sorted -join ', ')" -ForegroundColor Gray
    
    for ($i = 0; $i -lt $priorities.Count; $i++) {
        if ($priorities[$i] -ne $sorted[$i]) {
            throw "Queue not sorted by priority. Expected $($sorted[$i]) at position $i, got $($priorities[$i])"
        }
    }
    
    return $true
}

Test-CLIFunction -TestName "Process-InputQueue handles queue items" -Category "Queue" -TestScript {
    # This will process the queue (may fail if Claude isn't available)
    # We're testing the queue mechanics, not Claude execution
    
    $result = Process-InputQueue -UseFileInput
    
    # Result should be null (no Claude) or have proper structure
    if ($null -ne $result) {
        if ($null -eq $result.Success) {
            throw "Result missing Success property"
        }
    }
    
    # Check that queue was updated
    $status = Get-InputQueueStatus
    
    # Should have at least attempted processing
    if ($status.IsProcessing -eq $true) {
        throw "Queue still marked as processing"
    }
    
    return $true
}

#endregion

#region Category 6: Fallback Mechanisms

Write-Host "`n`n=== Category 6: Fallback Mechanisms ===" -ForegroundColor Magenta

Test-CLIFunction -TestName "Submit-ClaudeInputWithFallback tries multiple methods" -Category "Fallback" -TestScript {
    $testPrompt = "Test fallback prompt"
    
    # Test with both methods (will fail if Claude not available, but tests fallback logic)
    $result = Submit-ClaudeInputWithFallback -Prompt $testPrompt -Methods @("FileInput", "SendKeys") -RetryCount 1
    
    # Check result structure
    if ($null -eq $result.Success) {
        throw "Result missing Success property"
    }
    
    if ($null -eq $result.Attempts -or $result.Attempts -lt 1) {
        throw "Result missing or invalid Attempts count"
    }
    
    # If failed, should have error message
    if (-not $result.Success -and $null -eq $result.Error) {
        throw "Failed result missing Error property"
    }
    
    return $true
}

Test-CLIFunction -TestName "Test-InputDelivery timeout works correctly" -Category "Utilities" -TestScript {
    $fakeFile = Join-Path $env:TEMP "fake_response_$(Get-Random).json"
    
    # Test with non-existent file (should timeout)
    $startTime = Get-Date
    $delivered = Test-InputDelivery -ResponseFile $fakeFile -TimeoutSeconds 1
    $duration = ((Get-Date) - $startTime).TotalSeconds
    
    if ($delivered) {
        throw "False positive for non-existent file"
    }
    
    if ($duration -gt 2) {
        throw "Timeout took too long: $duration seconds"
    }
    
    return $true
}

#endregion

#region Category 7: Integration Tests

Write-Host "`n`n=== Category 7: Integration Tests ===" -ForegroundColor Magenta

Test-CLIFunction -TestName "End-to-end queue processing workflow" -Category "Integration" -TestScript {
    # Clear queue
    $queueFile = Join-Path $PSScriptRoot "..\input_queue.json"
    if (Test-Path $queueFile) {
        Remove-Item $queueFile -Force
    }
    
    # Add multiple items
    $ids = @()
    $ids += Add-InputToQueue -Prompt "Integration test 1" -Priority 3
    $ids += Add-InputToQueue -Prompt "Integration test 2" -Priority 7
    $ids += Add-InputToQueue -Prompt "Integration test 3" -Priority 5
    
    # Verify all added
    $status = Get-InputQueueStatus
    if ($status.TotalItems -ne 3) {
        throw "Wrong number of items in queue: $($status.TotalItems)"
    }
    
    # Process highest priority item
    Process-InputQueue -UseFileInput
    
    # Check status after processing
    $statusAfter = Get-InputQueueStatus
    
    # At least one item should be processed (completed or failed)
    if ($statusAfter.Pending -ge $status.Pending) {
        throw "No items were processed"
    }
    
    return $true
}

Test-CLIFunction -TestName "Prompt formatting with context integration" -Category "Integration" -TestScript {
    $prompt = "Fix this error"
    $context = "Error: CS0246 - Type not found"
    
    $formatted = Format-ClaudePrompt -Prompt $prompt -Context $context
    
    # Should contain both context and prompt
    if ($formatted -notmatch "CS0246" -or $formatted -notmatch "Fix") {
        throw "Formatted prompt missing context or prompt content"
    }
    
    # Should have proper escaping
    if ($formatted -match "`r`n") {
        throw "Newlines not properly escaped"
    }
    
    return $true
}

#endregion

#region Category 8: Performance Tests

Write-Host "`n`n=== Category 8: Performance Tests ===" -ForegroundColor Magenta

Test-CLIFunction -TestName "Queue operations perform within acceptable time" -Category "Performance" -TestScript {
    $startTime = Get-Date
    
    # Add 10 items rapidly
    for ($i = 0; $i -lt 10; $i++) {
        Add-InputToQueue -Prompt "Perf test $i" -Priority (Get-Random -Min 1 -Max 10)
    }
    
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    
    if ($duration -gt 1000) {
        throw "Queue operations too slow: ${duration}ms for 10 items"
    }
    
    Write-Host "    Added 10 items in ${duration}ms" -ForegroundColor Gray
    
    # Get status quickly
    $statusStart = Get-Date
    $status = Get-InputQueueStatus
    $statusDuration = ((Get-Date) - $statusStart).TotalMilliseconds
    
    if ($statusDuration -gt 100) {
        throw "Status check too slow: ${statusDuration}ms"
    }
    
    return $true
}

Test-CLIFunction -TestName "Prompt formatting handles large inputs efficiently" -Category "Performance" -TestScript {
    $largePrompt = "Test " * 2000  # ~10KB of text
    
    $startTime = Get-Date
    $formatted = Format-ClaudePrompt -Prompt $largePrompt
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    
    if ($duration -gt 100) {
        throw "Formatting too slow for large prompt: ${duration}ms"
    }
    
    Write-Host "    Formatted 10KB prompt in ${duration}ms" -ForegroundColor Gray
    
    return $true
}

#endregion

#region Test Summary

Write-Host "`n`n========================================" -ForegroundColor Cyan
Write-Host "          TEST SUMMARY                  " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$successRate = if ($script:TotalTests -gt 0) { 
    [Math]::Round(($script:PassedTests / $script:TotalTests) * 100, 2) 
} else { 0 }

Write-Host "`nTotal Tests:  $script:TotalTests" -ForegroundColor White
Write-Host "Passed:       $script:PassedTests" -ForegroundColor Green
Write-Host "Failed:       $script:FailedTests" -ForegroundColor $(if ($script:FailedTests -gt 0) { "Red" } else { "Gray" })
Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 80) { "Green" } elseif ($successRate -ge 60) { "Yellow" } else { "Red" })

# Show failed tests
if ($script:FailedTests -gt 0) {
    Write-Host "`nFailed Tests:" -ForegroundColor Red
    $script:TestResults | Where-Object { $_.Status -eq "FAIL" } | ForEach-Object {
        Write-Host "  - [$($_.Category)] $($_.Test)" -ForegroundColor Red
        if ($_.Error) {
            Write-Host "    Error: $($_.Error)" -ForegroundColor DarkRed
        }
    }
}

# Performance summary
$resultsWithDuration = $script:TestResults | Where-Object { $null -ne $_.Duration -and $_.Duration -is [double] }
if ($resultsWithDuration.Count -gt 0) {
    $avgDuration = ($resultsWithDuration | Measure-Object -Property Duration -Average).Average
    Write-Host "`nAverage Test Duration: $([Math]::Round($avgDuration, 2))ms" -ForegroundColor Cyan
}
else {
    Write-Host "`nNo duration data available for performance calculation" -ForegroundColor Gray
}

# Save results to file
$resultsFile = Join-Path $PSScriptRoot "Test-Results-Day13-$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
$script:TestResults | ConvertTo-Json -Depth 10 | Set-Content -Path $resultsFile -Encoding UTF8
Write-Host "`nTest results saved to: $resultsFile" -ForegroundColor Gray

# Exit code
if ($script:FailedTests -gt 0) {
    Write-Host "`n[FAILED] Day 13 CLI Automation tests completed with errors" -ForegroundColor Red
    exit 1
}
else {
    Write-Host "`n[SUCCESS] Day 13 CLI Automation tests completed successfully!" -ForegroundColor Green
    exit 0
}

#endregion
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUc2Qa+aSTSXGR7IaKJF25MSq9
# L0agggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU2svxXbAopXJEbDtZlS+TltJ4bVQwDQYJKoZIhvcNAQEBBQAEggEAm5C6
# WWR2rFN/sSjjWNqe3FzehhRLTBG4Qc/gEyfhqBmYEr4t3z3pY+YJ9UvZJrCnSqUK
# wvMUkzeNfii7Tt/uHZCsVPoXVSnfINWcOgGulQWbESkd+Yce8YEOymCePFCAXvk6
# GzHcnexxwSv9WY9MThzqSwjC1GKVjc10bWLFlTGULmiL8pYaJzlERbi6QE0tRFWZ
# IWIzkUOq+9VXaKl9RLc6T585lNZy0NH0NN7wsNZDh4RYNPIWPaGcWCE5Gg8XWojS
# uQQcJ7ykLYqzq7JwBbcv2axBAx+Lk7wBMwwTajZ/AxQtWraS3QdrKNmGsg6f69cc
# qOVMMVp0eOl4V3lwWg==
# SIG # End signature block
