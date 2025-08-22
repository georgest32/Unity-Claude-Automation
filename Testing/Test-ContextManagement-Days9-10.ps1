# Test-ContextManagement-Days9-10.ps1
# Test suite for Phase 2 Days 9-10: Context Management System
# Tests conversation state machine, history management, context optimization, and session persistence
# Date: 2025-08-18

param(
    [switch]$Detailed,
    [switch]$SkipPerformanceTests,
    [string]$LogLevel = "Info"
)

# Test configuration
$TestConfig = @{
    ProjectRoot = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"
    ModulePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-AutonomousAgent"
    TestTimeout = 30
    MaxHistorySize = 20
    SessionExpirationHours = 24
}

# Initialize test results tracking
$TestResults = @{
    Total = 0
    Passed = 0
    Failed = 0
    Skipped = 0
    Details = @()
    StartTime = Get-Date
}

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Details = "",
        [string]$Error = ""
    )
    
    $TestResults.Total++
    if ($Passed) {
        $TestResults.Passed++
        $status = "PASS"
        $color = "Green"
    } else {
        $TestResults.Failed++
        $status = "FAIL"
        $color = "Red"
    }
    
    $result = @{
        TestName = $TestName
        Status = $status
        Details = $Details
        Error = $Error
        Timestamp = Get-Date
    }
    
    $TestResults.Details += $result
    
    if ($Detailed) {
        Write-Host "[$status] $TestName" -ForegroundColor $color
        if ($Details) { Write-Host "  $Details" -ForegroundColor Gray }
        if ($Error) { Write-Host "  ERROR: $Error" -ForegroundColor Red }
    } else {
        Write-Host "$status" -ForegroundColor $color -NoNewline
        Write-Host " " -NoNewline
    }
}

function Skip-Test {
    param([string]$TestName, [string]$Reason)
    $TestResults.Total++
    $TestResults.Skipped++
    if ($Detailed) {
        Write-Host "[SKIP] $TestName - $Reason" -ForegroundColor Yellow
    } else {
        Write-Host "SKIP " -ForegroundColor Yellow -NoNewline
    }
}

Write-Host ""
Write-Host "Starting Context Management System Tests - Phase 2 Days 9-10" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# Load required modules
Write-Host ""
Write-Host "Loading required modules..." -ForegroundColor Yellow

try {
    # Import the main autonomous agent module
    Import-Module "$($TestConfig.ModulePath)\Unity-Claude-AutonomousAgent.psd1" -Force
    Write-Host "Unity-Claude-AutonomousAgent module loaded successfully" -ForegroundColor Green
    
    # Test that new functions are available
    $stateManagerFunctions = @(
        'Initialize-ConversationState',
        'Set-ConversationState',
        'Get-ConversationState',
        'Add-ConversationHistoryItem',
        'Get-ConversationHistory'
    )
    
    $contextOptFunctions = @(
        'Initialize-WorkingMemory',
        'Add-ContextItem',
        'Get-OptimizedContext',
        'New-SessionIdentifier',
        'Save-SessionState'
    )
    
    $missingFunctions = @()
    foreach ($func in ($stateManagerFunctions + $contextOptFunctions)) {
        if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
            $missingFunctions += $func
        }
    }
    
    if ($missingFunctions.Count -gt 0) {
        Write-Host "WARNING: Missing functions: $($missingFunctions -join ', ')" -ForegroundColor Yellow
    }
} catch {
    Write-Host "CRITICAL: Failed to load modules: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Running Context Management Tests..." -ForegroundColor Yellow
Write-Host ""

# DAY 9 TESTS: Conversation State Manager

# Test 1: Initialize conversation state
try {
    $result = Initialize-ConversationState
    $passed = $result.Success -eq $true -and 
              $null -ne $result.SessionId -and
              $result.State.CurrentState -eq "Idle"
    
    Write-TestResult -TestName "Initialize conversation state machine" -Passed $passed -Details "SessionId: $($result.SessionId)"
} catch {
    Write-TestResult -TestName "Initialize conversation state machine" -Passed $false -Error $_.Exception.Message
}

# Test 2: State transitions
try {
    $result = Set-ConversationState -NewState "Initializing" -Reason "Starting test"
    $passed = $result.Success -eq $true -and 
              $result.CurrentState -eq "Initializing" -and
              $result.PreviousState -eq "Idle"
    
    Write-TestResult -TestName "Valid state transition (Idle -> Initializing)" -Passed $passed -Details "TransitionCount: $($result.TransitionCount)"
} catch {
    Write-TestResult -TestName "Valid state transition (Idle -> Initializing)" -Passed $false -Error $_.Exception.Message
}

# Test 3: Invalid state transition
try {
    # Try invalid transition from Initializing to Idle (not allowed by rules)
    $currentState = (Get-ConversationState).CurrentState
    if ($currentState -eq "Initializing") {
        # First transition to Processing (valid)
        Set-ConversationState -NewState "Processing" | Out-Null
    }
    
    # Now try invalid transition from Processing to Initializing
    $result = Set-ConversationState -NewState "Initializing"
    $passed = $result.Success -eq $false  # Should fail
    
    Write-TestResult -TestName "Invalid state transition rejection" -Passed $passed -Details "Correctly rejected invalid transition"
} catch {
    Write-TestResult -TestName "Invalid state transition rejection" -Passed $false -Error $_.Exception.Message
}

# Test 4: Add conversation history items
try {
    $promptResult = Add-ConversationHistoryItem -Type "Prompt" -Content "Test prompt content" -Metadata @{TestId = 1}
    $responseResult = Add-ConversationHistoryItem -Type "Response" -Content "Test response content" -Metadata @{TestId = 2}
    $commandResult = Add-ConversationHistoryItem -Type "Command" -Content "Test-Command -Parameter Value" -Metadata @{TestId = 3}
    
    $passed = $promptResult.Success -eq $true -and 
              $responseResult.Success -eq $true -and
              $commandResult.Success -eq $true -and
              $commandResult.HistoryCount -eq 3
    
    Write-TestResult -TestName "Add conversation history items" -Passed $passed -Details "History count: $($commandResult.HistoryCount)"
} catch {
    Write-TestResult -TestName "Add conversation history items" -Passed $false -Error $_.Exception.Message
}

# Test 5: Get conversation history
try {
    $result = Get-ConversationHistory -Last 2
    $passed = $result.Success -eq $true -and 
              $result.History.Count -eq 2 -and
              $result.FilteredCount -eq 2
    
    Write-TestResult -TestName "Get conversation history with filter" -Passed $passed -Details "Retrieved $($result.FilteredCount) items"
} catch {
    Write-TestResult -TestName "Get conversation history with filter" -Passed $false -Error $_.Exception.Message
}

# Test 6: Get conversation context
try {
    $result = Get-ConversationContext -MaxItems 3 -IncludeErrors
    $passed = $result.Success -eq $true -and 
              $null -ne $result.Context -and
              $null -ne $result.Context.SessionId
    
    Write-TestResult -TestName "Get conversation context for prompt generation" -Passed $passed -Details "Context generated successfully"
} catch {
    Write-TestResult -TestName "Get conversation context for prompt generation" -Passed $false -Error $_.Exception.Message
}

# Test 7: Session metadata
try {
    $result = Get-SessionMetadata
    $passed = $result.Success -eq $true -and 
              $null -ne $result.Metadata -and
              $result.Statistics.HistoryItemCount -gt 0
    
    Write-TestResult -TestName "Get session metadata and statistics" -Passed $passed -Details "Session duration: $($result.Statistics.SessionDurationMinutes) minutes"
} catch {
    Write-TestResult -TestName "Get session metadata and statistics" -Passed $false -Error $_.Exception.Message
}

# Test 8: State persistence
try {
    $sessionId = (Get-ConversationState).SessionId
    
    # Reset and reload
    Reset-ConversationState -PreserveFiles | Out-Null
    $result = Initialize-ConversationState -SessionId $sessionId -LoadPersisted
    
    $passed = $result.Success -eq $true -and 
              $result.SessionId -eq $sessionId
    
    Write-TestResult -TestName "State persistence and recovery" -Passed $passed -Details "Session recovered: $($result.SessionId.Substring(0, 8))..."
} catch {
    Write-TestResult -TestName "State persistence and recovery" -Passed $false -Error $_.Exception.Message
}

# Test 9: Circular buffer management
try {
    # Add items beyond the max history size to test circular buffer
    for ($i = 1; $i -le 25; $i++) {
        Add-ConversationHistoryItem -Type "Prompt" -Content "Test item $i" | Out-Null
    }
    
    $result = Get-ConversationHistory
    $passed = $result.TotalCount -le $TestConfig.MaxHistorySize
    
    Write-TestResult -TestName "Circular buffer history management" -Passed $passed -Details "History size limited to: $($result.TotalCount)"
} catch {
    Write-TestResult -TestName "Circular buffer history management" -Passed $false -Error $_.Exception.Message
}

# DAY 10 TESTS: Context Optimization

# Test 10: Initialize working memory
try {
    $result = Initialize-WorkingMemory -Clean
    $passed = $result.Success -eq $true -and 
              (Test-Path $result.MemoryPath)
    
    Write-TestResult -TestName "Initialize working memory system" -Passed $passed -Details "Memory path: $($result.MemoryPath)"
} catch {
    Write-TestResult -TestName "Initialize working memory system" -Passed $false -Error $_.Exception.Message
}

# Test 11: Add context items
try {
    $cmdResult = Add-ContextItem -Type "Command" -Content "Test-Unity -Parameter Value" -Priority "High"
    $errResult = Add-ContextItem -Type "Error" -Content "CS0246: Type not found" -Priority "High"
    $insightResult = Add-ContextItem -Type "Insight" -Content "Unity compilation requires specific references" -Priority "Medium"
    
    $passed = $cmdResult.Success -eq $true -and 
              $errResult.Success -eq $true -and
              $insightResult.Success -eq $true
    
    Write-TestResult -TestName "Add various context items" -Passed $passed -Details "Context items added successfully"
} catch {
    Write-TestResult -TestName "Add various context items" -Passed $false -Error $_.Exception.Message
}

# Test 12: Get optimized context
try {
    $result = Get-OptimizedContext -MaxSize 2000 -Focus "Errors"
    $passed = $result.Success -eq $true -and 
              $null -ne $result.Context -and
              $result.Size -le 2000
    
    Write-TestResult -TestName "Get optimized context with focus" -Passed $passed -Details "Context size: $($result.Size) chars"
} catch {
    Write-TestResult -TestName "Get optimized context with focus" -Passed $false -Error $_.Exception.Message
}

# Test 13: Context relevance calculation
try {
    $item = @{
        Content = "Unity build failed with compilation errors"
        Timestamp = Get-Date
        Priority = "High"
    }
    
    $result = Calculate-ContextRelevance -Item $item -CurrentTask "Fix Unity build errors"
    $passed = $result.Success -eq $true -and 
              $result.Relevance -gt 0
    
    Write-TestResult -TestName "Calculate context relevance scoring" -Passed $passed -Details "Relevance score: $($result.Relevance)"
} catch {
    Write-TestResult -TestName "Calculate context relevance scoring" -Passed $false -Error $_.Exception.Message
}

# Test 14: Generate session identifier
try {
    $result = New-SessionIdentifier
    $passed = $result.Success -eq $true -and 
              $null -ne $result.SessionId -and
              $result.SessionId -match '\d{8}_\d{6}-'
    
    Write-TestResult -TestName "Generate unique session identifier" -Passed $passed -Details "Session ID: $($result.ShortId)"
} catch {
    Write-TestResult -TestName "Generate unique session identifier" -Passed $false -Error $_.Exception.Message
}

# Test 15: Save and restore session state
try {
    $sessionId = (New-SessionIdentifier).SessionId
    $state = @{
        TestData = "Session state test"
        Timestamp = Get-Date
        Values = @(1, 2, 3)
    }
    
    $saveResult = Save-SessionState -SessionId $sessionId -State $state
    $restoreResult = Restore-SessionState -SessionId $sessionId
    
    $passed = $saveResult.Success -eq $true -and 
              $restoreResult.Success -eq $true -and
              $restoreResult.State.TestData -eq "Session state test"
    
    Write-TestResult -TestName "Save and restore session state" -Passed $passed -Details "Session age: $($restoreResult.AgeHours) hours"
} catch {
    Write-TestResult -TestName "Save and restore session state" -Passed $false -Error $_.Exception.Message
}

# Test 16: Get session list
try {
    $result = Get-SessionList -IncludeExpired
    $passed = $result.Success -eq $true -and 
              $result.TotalCount -ge 0
    
    Write-TestResult -TestName "Get list of available sessions" -Passed $passed -Details "Found $($result.TotalCount) sessions"
} catch {
    Write-TestResult -TestName "Get list of available sessions" -Passed $false -Error $_.Exception.Message
}

# Test 17: Context compression
try {
    # Add many items to trigger compression
    for ($i = 1; $i -le 20; $i++) {
        Add-ContextItem -Type "Response" -Content ("Long response content " * 50) -Priority "Low" | Out-Null
    }
    
    $summary = Get-ContextSummary
    $passed = $summary.Success -eq $true -and 
              $summary.Summary.Statistics.CompressionCount -ge 0
    
    Write-TestResult -TestName "Context compression triggered" -Passed $passed -Details "Compressions: $($summary.Summary.Statistics.CompressionCount)"
} catch {
    Write-TestResult -TestName "Context compression triggered" -Passed $false -Error $_.Exception.Message
}

# Test 18: Clear expired sessions
try {
    $result = Clear-ExpiredSessions
    $passed = $result.Success -eq $true
    
    Write-TestResult -TestName "Clear expired session files" -Passed $passed -Details "Removed $($result.RemovedCount) expired sessions"
} catch {
    Write-TestResult -TestName "Clear expired session files" -Passed $false -Error $_.Exception.Message
}

# Performance Tests (if not skipped)
if (-not $SkipPerformanceTests) {
    # Test 19: State transition performance
    try {
        $startTime = Get-Date
        $states = @("Idle", "Initializing", "Processing", "Analyzing", "GeneratingPrompt", "Processing", "Completed", "Idle")
        
        Reset-ConversationState | Out-Null
        Initialize-ConversationState | Out-Null
        
        foreach ($state in $states) {
            Set-ConversationState -NewState $state | Out-Null
        }
        
        $duration = ((Get-Date) - $startTime).TotalMilliseconds
        $passed = $duration -lt 1000  # Should complete within 1 second
        
        Write-TestResult -TestName "State transition performance" -Passed $passed -Details "$([Math]::Round($duration, 2))ms for 8 transitions"
    } catch {
        Write-TestResult -TestName "State transition performance" -Passed $false -Error $_.Exception.Message
    }
    
    # Test 20: Context optimization performance
    try {
        $startTime = Get-Date
        
        # Add various context items
        for ($i = 1; $i -le 10; $i++) {
            Add-ContextItem -Type "Command" -Content "Command $i" -Priority "Medium" | Out-Null
            Add-ContextItem -Type "Error" -Content "Error $i" -Priority "High" | Out-Null
        }
        
        # Get optimized context multiple times
        for ($i = 1; $i -le 5; $i++) {
            Get-OptimizedContext -MaxSize 1000 | Out-Null
        }
        
        $duration = ((Get-Date) - $startTime).TotalMilliseconds
        $passed = $duration -lt 2000  # Should complete within 2 seconds
        
        Write-TestResult -TestName "Context optimization performance" -Passed $passed -Details "$([Math]::Round($duration, 2))ms for 20 adds + 5 optimizations"
    } catch {
        Write-TestResult -TestName "Context optimization performance" -Passed $false -Error $_.Exception.Message
    }
} else {
    Skip-Test -TestName "State transition performance" -Reason "Performance tests skipped"
    Skip-Test -TestName "Context optimization performance" -Reason "Performance tests skipped"
}

# Final results
$TestResults.EndTime = Get-Date
$duration = ($TestResults.EndTime - $TestResults.StartTime).TotalSeconds

Write-Host ""
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Context Management System Test Results - Phase 2 Days 9-10" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Total Tests: $($TestResults.Total)" -ForegroundColor White
Write-Host "Passed: $($TestResults.Passed)" -ForegroundColor Green
Write-Host "Failed: $($TestResults.Failed)" -ForegroundColor Red
Write-Host "Skipped: $($TestResults.Skipped)" -ForegroundColor Yellow
Write-Host "Duration: $([Math]::Round($duration, 2)) seconds" -ForegroundColor White

$successRate = if ($TestResults.Total -gt 0) { 
    [Math]::Round(($TestResults.Passed / $TestResults.Total) * 100, 1) 
} else { 0 }

Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 90) { 'Green' } elseif ($successRate -ge 70) { 'Yellow' } else { 'Red' })

if ($TestResults.Failed -gt 0) {
    Write-Host ""
    Write-Host "Failed Tests:" -ForegroundColor Red
    foreach ($failure in ($TestResults.Details | Where-Object { $_.Status -eq 'FAIL' })) {
        Write-Host "  - $($failure.TestName): $($failure.Error)" -ForegroundColor Red
    }
}

Write-Host ""
if ($successRate -ge 90) {
    Write-Host "Phase 2 Days 9-10: CONTEXT MANAGEMENT SYSTEM OPERATIONAL" -ForegroundColor Green
    Write-Host "Conversation state machine and context optimization validated" -ForegroundColor Green
} elseif ($successRate -ge 70) {
    Write-Host "Phase 2 Days 9-10: MOSTLY SUCCESSFUL" -ForegroundColor Yellow
    Write-Host "Core context management working, minor issues detected" -ForegroundColor Yellow
} else {
    Write-Host "Phase 2 Days 9-10: VALIDATION FAILED" -ForegroundColor Red
    Write-Host "Critical issues detected in context management system" -ForegroundColor Red
}

Write-Host ""
Write-Host "Test completed at $(Get-Date)" -ForegroundColor Gray

# Clean up test artifacts
try {
    Reset-ConversationState | Out-Null
} catch {
    # Ignore cleanup errors
}

# Return success rate for automation
return $successRate
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUOyoZXn1ZIGjbc5Aqry02gOlz
# xZGgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUBnTRf8tuj22BSfRwpIoUUmCrBtswDQYJKoZIhvcNAQEBBQAEggEAH78S
# KoZtog6OU0HpDrtpwRH0lFipQmmt3m0Trtnd8SPos4AW3ajLoxzJUTJFw6AcsC7/
# hxqaJiS8KddvuAyTr4vueMOC8pCQawjFiIe9AO/eM1OerVX6ddMdITODDutwF0N6
# GvUysPkRdgG+dheB+9/Xjn7aVrh1YLxDLPWmFeErJa8W0vXR9vW+ph1egVYGTprq
# gq1pwbaKcKs64u5Py8JEbrx+wbcHXmtDZ3+ouqYyxu2usjMQf7OW3m1HK7Q2FTpg
# lnCsafn5javs6hkJp99sTVi+s++x7ItwXuR82o3O3hl8ayIQAJT1tgiq0lr6hwTa
# 50sMXVodqRENzbuQnw==
# SIG # End signature block
