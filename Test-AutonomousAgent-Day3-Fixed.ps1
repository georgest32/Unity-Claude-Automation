# Test-AutonomousAgent-Day3-Fixed.ps1
# Day 3 testing for Claude Code CLI Autonomous Agent safe command execution framework
# Tests: Constrained runspace, command validation, parameter sanitization, path safety

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host "=== Unity-Claude Autonomous Agent Day 3 Testing ===" -ForegroundColor Yellow
Write-Host "Testing constrained runspace, command validation, and safe execution framework" -ForegroundColor Cyan

# Import the autonomous agent module
try {
    $ModulePath = Join-Path $PSScriptRoot "Modules\Unity-Claude-AutonomousAgent\Unity-Claude-AutonomousAgent.psd1"
    Import-Module $ModulePath -Force -DisableNameChecking
    Initialize-AgentLogging
    
    $exportedFunctions = Get-Command -Module Unity-Claude-AutonomousAgent
    Write-Host "Module loaded with $($exportedFunctions.Count) functions" -ForegroundColor Green
}
catch {
    Write-Error "Failed to load autonomous agent module: $_"
    exit 1
}

# Test 1: Constrained Runspace Creation
Write-Host ""
Write-Host "Test 1: Constrained Runspace Creation" -ForegroundColor Yellow
try {
    $runspaceInfo = New-ConstrainedRunspace -TimeoutMs 60000
    
    if ($runspaceInfo -and $runspaceInfo.Runspace) {
        Write-Host "Constrained runspace created successfully" -ForegroundColor Green
        Write-Host "  - Cmdlets loaded: $($runspaceInfo.CmdletCount)" -ForegroundColor Gray
        Write-Host "  - Timeout: $($runspaceInfo.TimeoutMs) ms" -ForegroundColor Gray
        Write-Host "  - Created: $($runspaceInfo.Created)" -ForegroundColor Gray
        
        # Cleanup
        $runspaceInfo.Runspace.Close()
        $runspaceInfo.Runspace.Dispose()
    }
    else {
        Write-Host "Failed to create constrained runspace" -ForegroundColor Red
    }
}
catch {
    Write-Host "Constrained runspace creation test failed: $_" -ForegroundColor Red
}

# Test 2: Command Safety Validation
Write-Host ""
Write-Host "Test 2: Command Safety Validation" -ForegroundColor Yellow
try {
    # Test safe commands
    $safeCommands = @("Get-Content", "Test-Path", "Measure-Command")
    foreach ($cmd in $safeCommands) {
        $testPath = "C:\test.txt"
        $safety = Test-CommandSafety -CommandName $cmd -Parameters @($testPath)
        $color = if ($safety.IsSafe) { "Green" } else { "Red" }
        Write-Host "  Safe command $cmd is safe: $($safety.IsSafe) (Risk: $($safety.RiskLevel))" -ForegroundColor $color
    }
    
    # Test dangerous commands
    $dangerousCommands = @("Invoke-Expression", "Add-Type", "Set-ExecutionPolicy")
    foreach ($cmd in $dangerousCommands) {
        $safety = Test-CommandSafety -CommandName $cmd
        $isBlocked = -not $safety.IsSafe
        $color = if ($isBlocked) { "Green" } else { "Red" }
        Write-Host "  Dangerous command $cmd is blocked: $isBlocked (Risk: $($safety.RiskLevel))" -ForegroundColor $color
    }
}
catch {
    Write-Host "Command safety validation test failed: $_" -ForegroundColor Red
}

# Test 3: Parameter Sanitization
Write-Host ""
Write-Host "Test 3: Parameter Sanitization" -ForegroundColor Yellow
try {
    # Create test values with special characters using ASCII codes to avoid parsing issues
    $backtickChar = [char]96
    $semicolonChar = [char]59
    $pipeChar = [char]124
    $ampersandChar = [char]38
    
    $testValues = @(
        "normal_text",
        "text_with_backtick" + $backtickChar,
        "text" + $semicolonChar + "with" + $semicolonChar + "semicolon",
        "text" + $pipeChar + "with" + $pipeChar + "pipe",
        "text" + $ampersandChar + "with" + $ampersandChar + "ampersand"
    )
    
    foreach ($value in $testValues) {
        $sanitized = Sanitize-ParameterValue -Value $value
        $wasSanitized = $sanitized -ne $value
        $color = if ($wasSanitized) { "Yellow" } else { "Green" }
        Write-Host "  Original: '$value'" -ForegroundColor Gray
        Write-Host "  Sanitized: '$sanitized' (Changed: $wasSanitized)" -ForegroundColor $color
    }
}
catch {
    Write-Host "Parameter sanitization test failed: $_" -ForegroundColor Red
}

# Test 4: Path Safety Validation
Write-Host ""
Write-Host "Test 4: Path Safety Validation" -ForegroundColor Yellow
try {
    $pathTests = @(
        @{ path = "C:\UnityProjects\Sound-and-Shoal\Dithering\Assets\test.cs"; expected = $true },
        @{ path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\test.ps1"; expected = $true },
        @{ path = "C:\Windows\System32\cmd.exe"; expected = $false },
        @{ path = "C:\UnityProjects\Sound-and-Shoal\test.txt"; expected = $true }
    )
    
    foreach ($test in $pathTests) {
        $validation = Test-PathSafety -Path $test.path
        $isCorrect = $validation.IsSafe -eq $test.expected
        $color = if ($isCorrect) { "Green" } else { "Red" }
        Write-Host "  Path: $($test.path)" -ForegroundColor Gray
        Write-Host "    Expected: $($test.expected), Got: $($validation.IsSafe), Correct: $isCorrect" -ForegroundColor $color
        if (-not $validation.IsSafe) {
            Write-Host "    Reason: $($validation.Reason)" -ForegroundColor Gray
        }
    }
}
catch {
    Write-Host "Path safety validation test failed: $_" -ForegroundColor Red
}

# Test 5: Safe Constrained Command Execution
Write-Host ""
Write-Host "Test 5: Safe Constrained Command Execution" -ForegroundColor Yellow
try {
    # Test safe command execution
    Write-Host "Testing Get-Date execution in constrained runspace..." -ForegroundColor Cyan
    $dateParams = @{ Format = "yyyy-MM-dd HH:mm:ss" }
    $result = Invoke-SafeConstrainedCommand -CommandName "Get-Date" -Parameters $dateParams -TimeoutMs 10000
    
    if ($result.Success) {
        Write-Host "Safe command executed successfully:" -ForegroundColor Green
        Write-Host "  Output: $($result.Output)" -ForegroundColor Gray
        Write-Host "  Execution time: $($result.ExecutionTime) ms" -ForegroundColor Gray
    }
    else {
        Write-Host "Safe command execution failed: $($result.ErrorMessage)" -ForegroundColor Red
    }
    
    # Test blocked command execution
    Write-Host "Testing blocked command rejection..." -ForegroundColor Cyan
    $blockedParams = @{ Command = "Get-Process" }
    $blockedResult = Invoke-SafeConstrainedCommand -CommandName "Invoke-Expression" -Parameters $blockedParams
    
    if (-not $blockedResult.Success) {
        Write-Host "Blocked command correctly rejected:" -ForegroundColor Green
        Write-Host "  Error: $($blockedResult.ErrorMessage)" -ForegroundColor Gray
    }
    else {
        Write-Host "ERROR: Blocked command was not rejected!" -ForegroundColor Red
    }
}
catch {
    Write-Host "Safe constrained command execution test failed: $_" -ForegroundColor Red
}

# Test 6: Dry Run Mode
Write-Host ""
Write-Host "Test 6: Dry Run Mode Validation" -ForegroundColor Yellow
try {
    $testPath = "C:\UnityProjects\Sound-and-Shoal\test.txt"
    $pathParams = @{ Path = $testPath }
    $dryRunResult = Invoke-SafeConstrainedCommand -CommandName "Get-Content" -Parameters $pathParams -DryRun
    
    if ($dryRunResult.Success -and $dryRunResult.Output -like "*DRY RUN*") {
        Write-Host "Dry run mode working correctly" -ForegroundColor Green
        Write-Host "  Output: $($dryRunResult.Output)" -ForegroundColor Gray
    }
    else {
        Write-Host "Dry run mode test failed" -ForegroundColor Red
    }
}
catch {
    Write-Host "Dry run mode test failed: $_" -ForegroundColor Red
}

# Test Summary
Write-Host ""
Write-Host "=== Day 3 Testing Summary ===" -ForegroundColor Yellow
Write-Host "Safe command execution framework components tested:" -ForegroundColor Cyan
Write-Host "Constrained runspace creation with whitelisted cmdlets" -ForegroundColor Green
Write-Host "Command safety validation with blocked command detection" -ForegroundColor Green
Write-Host "Parameter sanitization for injection prevention" -ForegroundColor Green
Write-Host "Path safety validation with project boundary enforcement" -ForegroundColor Green
Write-Host "Safe constrained command execution with timeout protection" -ForegroundColor Green
Write-Host "Dry run mode for testing and validation" -ForegroundColor Green

Write-Host ""
Write-Host "Day 3 Safe Command Execution Framework implementation completed!" -ForegroundColor Green
Write-Host "Ready for Day 4: Unity Test Automation with enhanced security" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUbLh6Y+Fcew+weTzaLSLtAcTy
# vh2gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU9JaHI2chmlC3JKQd4OsJhCtvOQEwDQYJKoZIhvcNAQEBBQAEggEAB0Dc
# dm1JBKsL7IB34OhRqIb2nuyjnHeJAw34Igg1BiIyDTR2old4twHil9aEBHnRPxLv
# 9ZoLA3T6p2QTMjE61JTpyytvJlFB5XIeCOPSz1fZJD6yDGA/yfFNxEcWwCiE92Yt
# tZZ9wAXompJgSKlYkjOk9yQX8yFEDd8Ie+t1LrnQYKJ7VEuHVXmUNK5MtGf3oo6V
# rXOB3AfAI71+F6acI+a4AZ2igUAd7g9qlmCV3z+Of/9gpJ15JMSDA3FQ6PxStv0p
# BluAp4zAyXWdmY79dItS9ctpzfqTeaBw2oFg7S6P86xiGi5Q0TLPnTA6e27nyKWg
# 28jrj1h7SXCo/pEgMg==
# SIG # End signature block
