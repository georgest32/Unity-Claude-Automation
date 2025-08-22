# Test-ModuleRefactoring-Fixed.ps1
# Completely rewritten test script with ASCII-only characters and proper PowerShell syntax
# Date: 2025-08-18

param(
    [switch]$UseRefactored,
    [switch]$Verbose,
    [switch]$DebugMode
)

# Enhanced logging function - ASCII only
function Write-TestLog {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [ConsoleColor]$Color = [ConsoleColor]::Gray
    )
    
    $timestamp = Get-Date -Format "HH:mm:ss.fff"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    if ($DebugMode) {
        Write-Host $logEntry -ForegroundColor $Color
    }
    
    # Write to test log file
    $logFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\test_refactoring_fixed.log"
    Add-Content -Path $logFile -Value $logEntry -Force
}

Write-Host ""
Write-Host "Fixed Unity-Claude-AutonomousAgent Module Refactoring Test" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

$modulePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-AutonomousAgent"

# Choose which module to test
if ($UseRefactored) {
    $moduleFile = Join-Path $modulePath "Unity-Claude-AutonomousAgent-Refactored.psm1"
    Write-Host "Testing REFACTORED module structure..." -ForegroundColor Yellow
    Write-TestLog "Testing refactored module: $moduleFile" -Level "INFO" -Color Green
} else {
    $moduleFile = Join-Path $modulePath "Unity-Claude-AutonomousAgent.psm1"
    Write-Host "Testing ORIGINAL module structure..." -ForegroundColor Yellow
    Write-TestLog "Testing original module: $moduleFile" -Level "INFO" -Color Yellow
}

Write-Host ""

# Test 0: Pre-flight checks
Write-Host "Test 0: Pre-flight checks..." -NoNewline
Write-TestLog "Starting pre-flight checks" -Level "DEBUG" -Color Cyan

try {
    # Check if module file exists
    if (-not (Test-Path $moduleFile)) {
        throw "Module file not found: $moduleFile"
    }
    Write-TestLog "Module file exists: $moduleFile" -Level "DEBUG" -Color Green
    
    Write-Host " PASS" -ForegroundColor Green
    Write-TestLog "Pre-flight checks completed successfully" -Level "SUCCESS" -Color Green
} catch {
    Write-Host " FAIL" -ForegroundColor Red
    Write-TestLog "Pre-flight check failed: $_" -Level "ERROR" -Color Red
    Write-Host "  Error: $_" -ForegroundColor Red
    exit 1
}

# Test 1: Load the module with verbose output
Write-Host "Test 1: Loading module with detailed tracing..." -NoNewline
Write-TestLog "Starting module load test" -Level "INFO" -Color Cyan

try {
    # Clear any existing modules first
    Write-TestLog "Checking for existing modules to remove..." -Level "DEBUG" -Color Gray
    $existingModules = Get-Module Unity-Claude-AutonomousAgent*
    if ($existingModules) {
        Write-TestLog "Found $($existingModules.Count) existing modules to remove" -Level "DEBUG" -Color Yellow
        $existingModules | Remove-Module -Force
        Write-TestLog "Removed existing modules" -Level "DEBUG" -Color Green
    } else {
        Write-TestLog "No existing modules found" -Level "DEBUG" -Color Gray
    }
    
    # Enable verbose output to see module loading details
    if ($Verbose -or $DebugMode) {
        $VerbosePreference = "Continue"
        Write-TestLog "Verbose mode enabled for module loading" -Level "DEBUG" -Color Cyan
    }
    
    Write-TestLog "Importing module: $moduleFile" -Level "DEBUG" -Color Cyan
    Write-TestLog "Module exists: $(Test-Path $moduleFile)" -Level "DEBUG" -Color Gray
    Import-Module $moduleFile -Force -DisableNameChecking -Verbose
    
    Write-TestLog "Module import completed" -Level "DEBUG" -Color Green
    
    # Check if module is loaded
    $loadedModule = Get-Module Unity-Claude-AutonomousAgent*
    if ($loadedModule) {
        Write-TestLog "Module loaded successfully: $($loadedModule.Name)" -Level "SUCCESS" -Color Green
        Write-TestLog "Module version: $($loadedModule.Version)" -Level "DEBUG" -Color Gray
        Write-TestLog "Exported commands: $($loadedModule.ExportedCommands.Count)" -Level "DEBUG" -Color Gray
    } else {
        throw "Module not found in loaded modules"
    }
    
    Write-Host " PASS" -ForegroundColor Green
} catch {
    Write-Host " FAIL" -ForegroundColor Red
    Write-TestLog "Module load failed: $_" -Level "ERROR" -Color Red
    Write-Host "  Error: $_" -ForegroundColor Red
    
    # Try to get more detailed error information
    if ($Error.Count -gt 0) {
        Write-TestLog "Last error details: $($Error[0])" -Level "ERROR" -Color Red
        Write-TestLog "Error category: $($Error[0].CategoryInfo)" -Level "ERROR" -Color Red
    }
    
    exit 1
}

# Test 2: Check available functions
Write-Host "Test 2: Checking available functions..." -NoNewline
Write-TestLog "Starting function availability check" -Level "INFO" -Color Cyan

# Define expected functions - rewritten to avoid any potential Unicode issues
$coreFunctions = @('Initialize-AgentCore', 'Get-AgentConfig', 'Set-AgentConfig', 'Get-AgentState', 'Set-AgentState', 'Reset-AgentState')
$loggingFunctions = @('Write-AgentLog', 'Initialize-AgentLogging', 'Get-AgentLogPath', 'Get-AgentLogStatistics', 'Clear-AgentLog')
$monitoringFunctions = @('Start-ClaudeResponseMonitoring', 'Stop-ClaudeResponseMonitoring', 'Get-MonitoringStatus', 'Test-FileSystemMonitoring')
$stateFunctions = @('Initialize-ConversationState', 'Set-ConversationState', 'Get-ConversationState', 'Add-ConversationHistoryItem', 'Get-ConversationHistory')
$contextFunctions = @('Initialize-WorkingMemory', 'Add-ContextItem', 'Get-OptimizedContext', 'New-SessionIdentifier')

$allExpectedFunctions = $coreFunctions + $loggingFunctions + $monitoringFunctions + $stateFunctions + $contextFunctions
$foundFunctions = @()
$missingFunctions = @()

Write-TestLog "Checking $($allExpectedFunctions.Count) expected functions..." -Level "DEBUG" -Color Cyan

foreach ($functionName in $allExpectedFunctions) {
    $command = Get-Command $functionName -ErrorAction SilentlyContinue
    if ($command) {
        Write-TestLog "  Found: $functionName (Module: $($command.ModuleName))" -Level "DEBUG" -Color Green
        $foundFunctions += $functionName
    } else {
        Write-TestLog "  Missing: $functionName" -Level "WARNING" -Color Yellow
        $missingFunctions += $functionName
    }
}

$foundCount = $foundFunctions.Count
$totalCount = $allExpectedFunctions.Count
$percentage = [Math]::Round(($foundCount / $totalCount) * 100, 1)

if ($missingFunctions.Count -eq 0) {
    Write-Host " PASS" -ForegroundColor Green
    Write-TestLog "All expected functions found: $foundCount/$totalCount" -Level "SUCCESS" -Color Green
} else {
    Write-Host " PARTIAL" -ForegroundColor Yellow
    Write-TestLog "Functions found: $foundCount/$totalCount ($percentage%)" -Level "WARNING" -Color Yellow
    Write-TestLog "Missing functions: $($missingFunctions -join ', ')" -Level "WARNING" -Color Yellow
}

# Test 3: Function execution test
Write-Host "Test 3: Testing available core functions..." -NoNewline
Write-TestLog "Testing core function execution" -Level "INFO" -Color Cyan

$executionTestsPassed = 0
$executionTestsTotal = 0

# Test Initialize-AgentLogging if available
if (Get-Command Initialize-AgentLogging -ErrorAction SilentlyContinue) {
    $executionTestsTotal++
    try {
        Write-TestLog "Testing Initialize-AgentLogging" -Level "DEBUG" -Color Cyan
        Initialize-AgentLogging
        Write-TestLog "Initialize-AgentLogging succeeded" -Level "DEBUG" -Color Green
        $executionTestsPassed++
    } catch {
        Write-TestLog "Initialize-AgentLogging error: $_" -Level "ERROR" -Color Red
    }
}

# Test Write-AgentLog if available
if (Get-Command Write-AgentLog -ErrorAction SilentlyContinue) {
    $executionTestsTotal++
    try {
        Write-TestLog "Testing Write-AgentLog" -Level "DEBUG" -Color Cyan
        Write-AgentLog -Message "Test log entry from fixed refactoring test" -Level "INFO" -Component "RefactoringTest"
        Write-TestLog "Write-AgentLog executed successfully" -Level "DEBUG" -Color Green
        $executionTestsPassed++
    } catch {
        Write-TestLog "Write-AgentLog error: $_" -Level "ERROR" -Color Red
    }
}

if ($executionTestsTotal -eq 0) {
    Write-Host " SKIP" -ForegroundColor Yellow
    Write-TestLog "No core functions available to test" -Level "WARNING" -Color Yellow
} elseif ($executionTestsPassed -eq $executionTestsTotal) {
    Write-Host " PASS" -ForegroundColor Green
    Write-TestLog "All available core functions tested successfully ($executionTestsPassed/$executionTestsTotal)" -Level "SUCCESS" -Color Green
} else {
    Write-Host " PARTIAL" -ForegroundColor Yellow
    Write-TestLog "Core function tests: $executionTestsPassed/$executionTestsTotal passed" -Level "WARNING" -Color Yellow
}

# Summary
Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Fixed Test Summary:" -ForegroundColor Cyan
Write-Host "  Module Type: $(if ($UseRefactored) { 'REFACTORED' } else { 'ORIGINAL' })" -ForegroundColor White
Write-Host "  Functions Found: $foundCount/$totalCount ($percentage%)" -ForegroundColor $(if ($percentage -eq 100) { 'Green' } elseif ($percentage -ge 80) { 'Yellow' } else { 'Red' })

if ($DebugMode -and $foundFunctions.Count -gt 0) {
    Write-Host ""
    Write-Host "Available Functions:" -ForegroundColor Yellow
    foreach ($func in ($foundFunctions | Sort-Object)) {
        Write-Host "  $func" -ForegroundColor Gray
    }
}

if ($missingFunctions.Count -gt 0) {
    Write-Host ""
    Write-Host "Missing Functions:" -ForegroundColor Red
    foreach ($func in ($missingFunctions | Sort-Object)) {
        Write-Host "  $func" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Test completed at $(Get-Date)" -ForegroundColor Gray
Write-Host "Log file: test_refactoring_fixed.log" -ForegroundColor Gray
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUHDs4yLnGC8A+ZtF+p3SklVx6
# 0TOgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU4vtBMV8YGFJ7qxmYHtGsQyK5WzYwDQYJKoZIhvcNAQEBBQAEggEAI8Wv
# X28tI4MmcpZEkJDpYVRWVa7BltinZ78jYCuEAE25OcRly12XGHzfbpVLSGeLKFR+
# /AVsLbQ8NhBx7xHjQTHU/UbcLKcXdD1OnhX1wRsdivySvc88vTELWg8tkIL4fGaM
# gFjcaET8MlmcFypvwE1LUsdiv/WdVj6zhIog4GmrjIUQCxQh8HTgCG8sYOfuaYqB
# fhY7jwFLizUXF6eFjC8Rn/iIGTZoUZqfQNT8b4roWrdWr3Y1x9un7A4tc7ecKcDy
# 74JlCs2R9XQd2KnSgEOrGI31ZofoaGbqBxxEf+B4bEyzxHq6lRTagjNXTjFmFumY
# BKXPzL3KwjP2EDKuTg==
# SIG # End signature block
