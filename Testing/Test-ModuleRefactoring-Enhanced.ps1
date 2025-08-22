# Test-ModuleRefactoring-Enhanced.ps1
# Enhanced test script with extensive debugging for module refactoring
# Date: 2025-08-18

param(
    [switch]$UseRefactored,
    [switch]$Verbose,
    [switch]$DebugMode
)

# Enhanced logging function
function Write-TestLog {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [ConsoleColor]$Color = "Gray"
    )
    
    $timestamp = Get-Date -Format "HH:mm:ss.fff"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    if ($DebugMode) {
        Write-Host $logEntry -ForegroundColor $Color
    }
    
    # Also write to test log file
    $logFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\test_refactoring.log"
    Add-Content -Path $logFile -Value $logEntry -Force
}

Write-Host ""
Write-Host "Enhanced Unity-Claude-AutonomousAgent Module Refactoring Test" -ForegroundColor Cyan
Write-Host "==============================================================" -ForegroundColor Cyan
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
    
    # Check dependent modules for refactored version
    if ($UseRefactored) {
        $dependentModules = @(
            "Core\AgentCore.psm1",
            "Core\AgentLogging.psm1", 
            "Monitoring\FileSystemMonitoring.psm1",
            "ConversationStateManager.psm1",
            "ContextOptimization.psm1"
        )
        
        foreach ($depModule in $dependentModules) {
            $depPath = Join-Path $modulePath $depModule
            if (Test-Path $depPath) {
                Write-TestLog "Found dependent module: $depModule" -Level "DEBUG" -Color Green
            } else {
                Write-TestLog "Missing dependent module: $depModule" -Level "WARNING" -Color Yellow
            }
        }
    }
    
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

# Test 2: Detailed function availability check
Write-Host "Test 2: Detailed function availability check..." -NoNewline
Write-TestLog "Starting function availability check" -Level "INFO" -Color Cyan

$expectedFunctions = @{
    "Core Functions" = @(
        'Initialize-AgentCore',
        'Get-AgentConfig', 
        'Set-AgentConfig',
        'Get-AgentState',
        'Set-AgentState',
        'Reset-AgentState'
    )
    "Logging Functions" = @(
        'Write-AgentLog',
        'Initialize-AgentLogging',
        'Get-AgentLogPath',
        'Get-AgentLogStatistics',
        'Clear-AgentLog'
    )
    "Monitoring Functions" = @(
        'Start-ClaudeResponseMonitoring',
        'Stop-ClaudeResponseMonitoring',
        'Get-MonitoringStatus',
        'Test-FileSystemMonitoring'
    )
    "State Management Functions" = @(
        'Initialize-ConversationState',
        'Set-ConversationState',
        'Get-ConversationState',
        'Add-ConversationHistoryItem',
        'Get-ConversationHistory'
    )
    "Context Functions" = @(
        'Initialize-WorkingMemory',
        'Add-ContextItem',
        'Get-OptimizedContext',
        'New-SessionIdentifier'
    )
}

$allMissing = @()
$categoryResults = @{}

foreach ($category in $expectedFunctions.Keys) {
    Write-TestLog "Checking $category..." -Level "DEBUG" -Color Cyan
    Write-TestLog "  Expected functions in ${category}: $($expectedFunctions[$category].Count)" -Level "DEBUG" -Color Gray
    $missing = @()
    
    foreach ($func in $expectedFunctions[$category]) {
        $command = Get-Command $func -ErrorAction SilentlyContinue
        if ($command) {
            Write-TestLog "  ✓ Found: $func (Module: $($command.ModuleName))" -Level "DEBUG" -Color Green
        } else {
            Write-TestLog "  ✗ Missing: $func" -Level "WARNING" -Color Yellow
            $missing += $func
            $allMissing += $func
        }
    }
    
    Write-TestLog "  Summary for ${category}: Found $($expectedFunctions[$category].Count - $missing.Count)/$($expectedFunctions[$category].Count)" -Level "DEBUG" -Color Cyan
    
    $categoryResults[$category] = @{
        Expected = $expectedFunctions[$category].Count
        Found = $expectedFunctions[$category].Count - $missing.Count
        Missing = $missing
    }
}

if ($allMissing.Count -eq 0) {
    Write-Host " PASS" -ForegroundColor Green
    Write-TestLog "All expected functions found" -Level "SUCCESS" -Color Green
} else {
    Write-Host " PARTIAL" -ForegroundColor Yellow
    Write-TestLog "Missing $($allMissing.Count) functions: $($allMissing -join ', ')" -Level "WARNING" -Color Yellow
}

# Display detailed results
if ($DebugMode) {
    Write-Host ""
    Write-Host "Detailed Function Results:" -ForegroundColor Cyan
    foreach ($category in $categoryResults.Keys) {
        $result = $categoryResults[$category]
        $percentage = [Math]::Round(($result.Found / $result.Expected) * 100, 1)
        Write-Host "  ${category}: $($result.Found)/$($result.Expected) $percentage%" -ForegroundColor Gray
        if ($result.Missing.Count -gt 0) {
            Write-Host "    Missing: $($result.Missing -join ', ')" -ForegroundColor Yellow
        }
    }
}

# Test 3: Test available core functions
Write-Host "Test 3: Testing available core functions..." -NoNewline
Write-TestLog "Testing core function execution" -Level "INFO" -Color Cyan

$coreTestsPassed = 0
$coreTestsTotal = 0

# Test Initialize-AgentCore if available
if (Get-Command Initialize-AgentCore -ErrorAction SilentlyContinue) {
    $coreTestsTotal++
    try {
        Write-TestLog "Testing Initialize-AgentCore" -Level "DEBUG" -Color Cyan
        $result = Initialize-AgentCore
        if ($result.Success) {
            Write-TestLog "Initialize-AgentCore succeeded" -Level "DEBUG" -Color Green
            $coreTestsPassed++
        } else {
            Write-TestLog "Initialize-AgentCore failed: $($result.Error)" -Level "WARNING" -Color Yellow
        }
    } catch {
        Write-TestLog "Initialize-AgentCore error: $_" -Level "ERROR" -Color Red
    }
}

# Test Get-AgentConfig if available
if (Get-Command Get-AgentConfig -ErrorAction SilentlyContinue) {
    $coreTestsTotal++
    try {
        Write-TestLog "Testing Get-AgentConfig" -Level "DEBUG" -Color Cyan
        $config = Get-AgentConfig
        if ($config -and $config.Count -gt 0) {
            Write-TestLog "Get-AgentConfig succeeded, returned $($config.Count) settings" -Level "DEBUG" -Color Green
            $coreTestsPassed++
        } else {
            Write-TestLog "Get-AgentConfig returned empty result" -Level "WARNING" -Color Yellow
        }
    } catch {
        Write-TestLog "Get-AgentConfig error: $_" -Level "ERROR" -Color Red
    }
}

# Test Write-AgentLog if available
if (Get-Command Write-AgentLog -ErrorAction SilentlyContinue) {
    $coreTestsTotal++
    try {
        Write-TestLog "Testing Write-AgentLog" -Level "DEBUG" -Color Cyan
        
        # Check if the function has NoConsole parameter
        $logCommand = Get-Command Write-AgentLog
        $hasNoConsole = $logCommand.Parameters.ContainsKey('NoConsole')
        
        if ($hasNoConsole) {
            Write-AgentLog -Message "Test log entry from enhanced refactoring test" -Level "INFO" -Component "RefactoringTest" -NoConsole
        } else {
            Write-AgentLog -Message "Test log entry from enhanced refactoring test" -Level "INFO" -Component "RefactoringTest"
        }
        
        Write-TestLog "Write-AgentLog executed successfully" -Level "DEBUG" -Color Green
        $coreTestsPassed++
    } catch {
        Write-TestLog "Write-AgentLog error: $_" -Level "ERROR" -Color Red
    }
}

if ($coreTestsTotal -eq 0) {
    Write-Host " SKIP" -ForegroundColor Yellow
    Write-TestLog "No core functions available to test" -Level "WARNING" -Color Yellow
} elseif ($coreTestsPassed -eq $coreTestsTotal) {
    Write-Host " PASS" -ForegroundColor Green
    Write-TestLog "All available core functions tested successfully ($coreTestsPassed/$coreTestsTotal)" -Level "SUCCESS" -Color Green
} else {
    Write-Host " PARTIAL" -ForegroundColor Yellow
    Write-TestLog "Core function tests: $coreTestsPassed/$coreTestsTotal passed" -Level "WARNING" -Color Yellow
}

# Test 4: Module status check (refactored only)
if ($UseRefactored) {
    Write-Host "Test 4: Getting refactored module status..." -NoNewline
    Write-TestLog "Testing Get-ModuleStatus function" -Level "INFO" -Color Cyan
    
    try {
        if (Get-Command Get-ModuleStatus -ErrorAction SilentlyContinue) {
            $status = Get-ModuleStatus
            Write-TestLog "Module status retrieved successfully" -Level "DEBUG" -Color Green
            Write-TestLog "  Version: $($status.Version)" -Level "DEBUG" -Color Gray
            Write-TestLog "  Loaded Modules: $($status.LoadedModules.Count)" -Level "DEBUG" -Color Gray
            Write-TestLog "  Total Functions: $($status.TotalFunctions)" -Level "DEBUG" -Color Gray
            Write-Host " PASS" -ForegroundColor Green
        } else {
            Write-Host " SKIP" -ForegroundColor Yellow
            Write-TestLog "Get-ModuleStatus function not available" -Level "WARNING" -Color Yellow
        }
    } catch {
        Write-Host " FAIL" -ForegroundColor Red
        Write-TestLog "Get-ModuleStatus error: $_" -Level "ERROR" -Color Red
    }
}

# Summary
Write-Host ""
Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host "Enhanced Test Summary:" -ForegroundColor Cyan
Write-Host "  Module Type: $(if ($UseRefactored) { 'REFACTORED' } else { 'ORIGINAL' })" -ForegroundColor White
Write-Host "  Module File: $(Split-Path $moduleFile -Leaf)" -ForegroundColor White

$overallSuccess = $true

foreach ($category in $categoryResults.Keys) {
    $result = $categoryResults[$category]
    $percentage = [Math]::Round(($result.Found / $result.Expected) * 100, 1)
    $color = if ($percentage -eq 100) { "Green" } elseif ($percentage -ge 80) { "Yellow" } else { "Red" }
    Write-Host "  ${category}: $percentage% ($($result.Found)/$($result.Expected))" -ForegroundColor $color
    
    if ($percentage -lt 100) {
        $overallSuccess = $false
    }
}

Write-TestLog "Test summary completed" -Level "INFO" -Color Cyan
Write-TestLog "Overall success: $overallSuccess" -Level "INFO" -Color $(if ($overallSuccess) { "Green" } else { "Red" })

Write-Host ""
if ($overallSuccess) {
    Write-Host "✓ Module refactoring test PASSED" -ForegroundColor Green
    Write-TestLog "All tests passed successfully" -Level "SUCCESS" -Color Green
} else {
    Write-Host "⚠ Module refactoring test had ISSUES" -ForegroundColor Yellow
    Write-TestLog "Some tests failed or incomplete" -Level "WARNING" -Color Yellow
}

if ($UseRefactored) {
    Write-Host ""
    Write-Host "Next steps for refactoring:" -ForegroundColor Cyan
    Write-Host "  • Extract remaining functions from original module" -ForegroundColor Gray
    Write-Host "  • Update module manifest (.psd1) for nested modules" -ForegroundColor Gray
    Write-Host "  • Test full functionality with real scenarios" -ForegroundColor Gray
}

if ($DebugMode) {
    Write-Host ""
    Write-Host "Debug Information:" -ForegroundColor Cyan
    Write-Host "=================" -ForegroundColor Cyan
    
    # Show all loaded modules
    $allModules = Get-Module
    Write-Host "All Loaded Modules:" -ForegroundColor Yellow
    foreach ($mod in $allModules) {
        $funcCount = if ($mod.ExportedCommands) { $mod.ExportedCommands.Count } else { 0 }
        Write-Host "  $($mod.Name) v$($mod.Version) ($funcCount functions)" -ForegroundColor Gray
    }
    
    # Show Unity-Claude modules specifically
    $unityClaudeModules = Get-Module *Unity-Claude*
    if ($unityClaudeModules) {
        Write-Host ""
        Write-Host "Unity-Claude Modules:" -ForegroundColor Yellow
        foreach ($mod in $unityClaudeModules) {
            Write-Host "  Module: $($mod.Name)" -ForegroundColor Green
            Write-Host "    Path: $($mod.Path)" -ForegroundColor Gray
            Write-Host "    Functions: $($mod.ExportedCommands.Count)" -ForegroundColor Gray
            if ($mod.ExportedCommands.Count -gt 0 -and $mod.ExportedCommands.Count -lt 20) {
                $functions = $mod.ExportedCommands.Keys | Sort-Object
                Write-Host "    Exported: $($functions -join ', ')" -ForegroundColor Cyan
            }
        }
    }
}

Write-Host ""
Write-Host "Log file: test_refactoring.log" -ForegroundColor Gray
Write-Host "Test completed at $(Get-Date)" -ForegroundColor Gray
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUM+I8UUUaRCMWrLyfFYyxgZYe
# J8SgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUBpLPAl7PuOUW6sP4wK+t/qw2pZEwDQYJKoZIhvcNAQEBBQAEggEAA8Mx
# uzO28GslFyqVd8YMNFP35hv0Cv96ZyP7mgzXRe4T4SCcEC0+2ZdhVRq7RVBnCCXB
# VuYUMBvKoW0YKzXno1r+ATGfgUIFbuKn5DDglHgRn0kdbZvY5uZaFMbVUQgsCM/Z
# BZFwadd1udf7NEywKZqdDX6cPqe9F6Y+vkcoSbpkeHugRKvuKUkloEG5eBPoHA1a
# jcT4sBs8NOUmTXfdpEaCsu2WwKmKN2Pl+hiDFYLtz9fz3rMmdMoPTn2nffSBQctf
# K6f4FVLOAs/uaPxIGCbKoLkEMoqROD0bqAGTAAiHFYPa/rh9QcpGpG3lAKNtpPhP
# 8+9qb6Mu7uDsDeYHVw==
# SIG # End signature block
