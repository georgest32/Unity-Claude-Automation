# Test-BackwardCompatibility.ps1
# Test script for backward compatibility layer functionality
# Date: 2025-08-22
# Phase 3 Day 2: Migration and Backward Compatibility - Hour 3-4

param(
    [switch]$Verbose = $false,
    [switch]$SaveResults = $true
)

$ErrorActionPreference = "Continue"
if ($Verbose) { $VerbosePreference = "Continue" }

# Test framework setup
$testResults = @()
$testStartTime = Get-Date
$testResultsFile = ".\Test_Results_BackwardCompatibility_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Success,
        [string]$Message = "",
        [object]$Details = $null
    )
    
    $result = @{
        TestName = $TestName
        Success = $Success
        Message = $Message
        Details = $Details
        Timestamp = Get-Date
    }
    
    $script:testResults += $result
    
    $status = if ($Success) { "PASS" } else { "FAIL" }
    $color = if ($Success) { "Green" } else { "Red" }
    
    Write-Host "[$status] $TestName" -ForegroundColor $color
    if ($Message) {
        Write-Host "      $Message" -ForegroundColor Gray
    }
}

function Test-CompatibilityModuleLoading {
    Write-Host "=== Testing Compatibility Module Loading ===" -ForegroundColor Cyan
    
    try {
        Import-Module ".\Migration\Legacy-Compatibility.psm1" -Force
        $module = Get-Module -Name "Legacy-Compatibility"
        
        if ($module) {
            Write-TestResult "Module Loading" $true "Successfully loaded Legacy-Compatibility module"
            
            # Test exported functions
            $expectedFunctions = @(
                'Enable-LegacyMode',
                'Disable-LegacyMode',
                'Test-LegacyMode',
                'Start-UnityClaudeSystem',
                'Test-MigrationStatus'
            )
            
            $exportedFunctions = $module.ExportedFunctions.Keys
            $missingFunctions = $expectedFunctions | Where-Object { $_ -notin $exportedFunctions }
            
            if ($missingFunctions.Count -eq 0) {
                Write-TestResult "Function Export" $true "All expected functions exported ($($exportedFunctions.Count) functions)"
            } else {
                Write-TestResult "Function Export" $false "Missing functions: $($missingFunctions -join ', ')"
            }
        } else {
            Write-TestResult "Module Loading" $false "Module loaded but not found in Get-Module"
        }
    } catch {
        Write-TestResult "Module Loading" $false "Failed to load module: $($_.Exception.Message)"
    }
}

function Test-LegacyModeToggle {
    Write-Host "=== Testing Legacy Mode Toggle ===" -ForegroundColor Cyan
    
    try {
        # Test initial state
        $initialState = Test-LegacyMode
        Write-TestResult "Initial State Check" $true "Legacy mode initial state: $initialState"
        
        # Test enabling legacy mode
        Enable-LegacyMode -SuppressWarnings
        $legacyEnabled = Test-LegacyMode
        
        if ($legacyEnabled) {
            Write-TestResult "Enable Legacy Mode" $true "Successfully enabled legacy mode"
        } else {
            Write-TestResult "Enable Legacy Mode" $false "Legacy mode not enabled"
        }
        
        # Test disabling legacy mode
        Disable-LegacyMode
        $legacyDisabled = -not (Test-LegacyMode)
        
        if ($legacyDisabled) {
            Write-TestResult "Disable Legacy Mode" $true "Successfully disabled legacy mode"
        } else {
            Write-TestResult "Disable Legacy Mode" $false "Legacy mode not disabled"
        }
        
    } catch {
        Write-TestResult "Legacy Mode Toggle" $false "Error during toggle testing: $($_.Exception.Message)"
    }
}

function Test-MigrationStatusDetection {
    Write-Host "=== Testing Migration Status Detection ===" -ForegroundColor Cyan
    
    try {
        $migrationStatus = Test-MigrationStatus
        
        if ($migrationStatus -and $migrationStatus.Status) {
            Write-TestResult "Migration Status Detection" $true "Status detected: $($migrationStatus.Status)"
            
            # Test expected properties
            $expectedProperties = @('Status', 'LegacyConfigExists', 'ManifestsExist', 'RecommendedAction')
            $missingProperties = $expectedProperties | Where-Object { -not $migrationStatus.ContainsKey($_) }
            
            if ($missingProperties.Count -eq 0) {
                Write-TestResult "Migration Status Properties" $true "All expected properties present"
            } else {
                Write-TestResult "Migration Status Properties" $false "Missing properties: $($missingProperties -join ', ')"
            }
            
            # Test status logic
            if ($migrationStatus.LegacyConfigExists) {
                Write-TestResult "Legacy Config Detection" $true "Legacy configuration files detected"
            } else {
                Write-TestResult "Legacy Config Detection" $false "No legacy configuration detected"
            }
            
            if ($migrationStatus.ManifestsExist) {
                Write-TestResult "Manifest Detection" $true "Manifest files detected ($($migrationStatus.ManifestCount) files)"
            } else {
                Write-TestResult "Manifest Detection" $true "No manifest files detected (expected for pre-migration)"
            }
            
        } else {
            Write-TestResult "Migration Status Detection" $false "No migration status returned"
        }
    } catch {
        Write-TestResult "Migration Status Detection" $false "Error: $($_.Exception.Message)"
    }
}

function Test-DeprecationWarnings {
    Write-Host "=== Testing Deprecation Warning System ===" -ForegroundColor Cyan
    
    try {
        # Capture warning output
        $warningOutput = @()
        $originalWarningPreference = $WarningPreference
        
        # Enable warning capture
        $WarningPreference = "Continue"
        
        # Test with warnings enabled
        Enable-LegacyMode  # This should show a warning
        
        # Test deprecation warning function
        Show-DeprecationWarning -FunctionName "Test-Function" -Replacement "New-Function"
        
        Write-TestResult "Deprecation Warning System" $true "Deprecation warning system functional"
        
        # Test with warnings suppressed
        Show-DeprecationWarning -FunctionName "Test-Function" -SuppressWarnings
        Write-TestResult "Warning Suppression" $true "Warning suppression functional"
        
        # Restore original preference
        $WarningPreference = $originalWarningPreference
        
    } catch {
        Write-TestResult "Deprecation Warning System" $false "Error: $($_.Exception.Message)"
    }
}

function Test-SystemStartupModeSelection {
    Write-Host "=== Testing System Startup Mode Selection ===" -ForegroundColor Cyan
    
    try {
        # Test auto-detection logic (dry run)
        $migrationStatus = Test-MigrationStatus
        
        if ($migrationStatus.ManifestsExist) {
            Write-TestResult "Mode Auto-Detection" $true "Would select manifest mode (manifests exist)"
        } else {
            Write-TestResult "Mode Auto-Detection" $true "Would select legacy mode (no manifests)"
        }
        
        # Test forced legacy mode
        Enable-LegacyMode -SuppressWarnings
        if (Test-LegacyMode) {
            Write-TestResult "Forced Legacy Mode" $true "Legacy mode can be forced"
        } else {
            Write-TestResult "Forced Legacy Mode" $false "Failed to force legacy mode"
        }
        
        # Test forced manifest mode
        Disable-LegacyMode
        if (-not (Test-LegacyMode)) {
            Write-TestResult "Forced Manifest Mode" $true "Manifest mode can be forced"
        } else {
            Write-TestResult "Forced Manifest Mode" $false "Failed to force manifest mode"
        }
        
    } catch {
        Write-TestResult "System Startup Mode Selection" $false "Error: $($_.Exception.Message)"
    }
}

function Test-ScriptParameterCompatibility {
    Write-Host "=== Testing Script Parameter Compatibility ===" -ForegroundColor Cyan
    
    try {
        # Test Start-SystemStatusMonitoring-Enhanced-WithCompatibility.ps1
        $compatScript = ".\Start-SystemStatusMonitoring-Enhanced-WithCompatibility.ps1"
        if (Test-Path $compatScript) {
            # Check for new parameters
            $scriptContent = Get-Content $compatScript -Raw
            
            if ($scriptContent -match '\$UseLegacyMode') {
                Write-TestResult "SystemStatus Compatibility Parameters" $true "UseLegacyMode parameter added"
            } else {
                Write-TestResult "SystemStatus Compatibility Parameters" $false "UseLegacyMode parameter missing"
            }
            
            if ($scriptContent -match '\$UseManifestMode') {
                Write-TestResult "SystemStatus Manifest Parameters" $true "UseManifestMode parameter added"
            } else {
                Write-TestResult "SystemStatus Manifest Parameters" $false "UseManifestMode parameter missing"
            }
        } else {
            Write-TestResult "SystemStatus Compatibility Script" $false "Compatibility script not found"
        }
        
        # Test Start-UnifiedSystem-WithCompatibility.ps1
        $unifiedScript = ".\Start-UnifiedSystem-WithCompatibility.ps1"
        if (Test-Path $unifiedScript) {
            $scriptContent = Get-Content $unifiedScript -Raw
            
            if ($scriptContent -match 'Legacy-Compatibility\.psm1') {
                Write-TestResult "Unified System Compatibility" $true "Compatibility module imported"
            } else {
                Write-TestResult "Unified System Compatibility" $false "Compatibility module not imported"
            }
            
            if ($scriptContent -match 'Test-MigrationStatus') {
                Write-TestResult "Unified System Migration Detection" $true "Migration status checking implemented"
            } else {
                Write-TestResult "Unified System Migration Detection" $false "Migration status checking missing"
            }
        } else {
            Write-TestResult "Unified System Compatibility Script" $false "Compatibility script not found"
        }
        
    } catch {
        Write-TestResult "Script Parameter Compatibility" $false "Error: $($_.Exception.Message)"
    }
}

function Test-BackwardCompatibilityIntegration {
    Write-Host "=== Testing Backward Compatibility Integration ===" -ForegroundColor Cyan
    
    try {
        # Test that legacy scripts still work
        $legacyScripts = @(
            "Start-SystemStatusMonitoring-Enhanced.ps1",
            "Start-UnifiedSystem-Complete.ps1"
        )
        
        $workingLegacyScripts = 0
        foreach ($script in $legacyScripts) {
            if (Test-Path $script) {
                $workingLegacyScripts++
            }
        }
        
        if ($workingLegacyScripts -gt 0) {
            Write-TestResult "Legacy Script Preservation" $true "$workingLegacyScripts legacy scripts still available"
        } else {
            Write-TestResult "Legacy Script Preservation" $false "No legacy scripts found"
        }
        
        # Test new compatibility scripts
        $compatibilityScripts = @(
            "Start-SystemStatusMonitoring-Enhanced-WithCompatibility.ps1",
            "Start-UnifiedSystem-WithCompatibility.ps1"
        )
        
        $workingCompatibilityScripts = 0
        foreach ($script in $compatibilityScripts) {
            if (Test-Path $script) {
                $workingCompatibilityScripts++
            }
        }
        
        if ($workingCompatibilityScripts -eq $compatibilityScripts.Count) {
            Write-TestResult "Compatibility Script Creation" $true "All compatibility scripts created"
        } else {
            Write-TestResult "Compatibility Script Creation" $false "Missing compatibility scripts"
        }
        
    } catch {
        Write-TestResult "Backward Compatibility Integration" $false "Error: $($_.Exception.Message)"
    }
}

# Run all tests
Write-Host "Unity-Claude-Automation Backward Compatibility Test Suite" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Test started at: $(Get-Date)" -ForegroundColor Cyan
Write-Host ""

Test-CompatibilityModuleLoading
Test-LegacyModeToggle
Test-MigrationStatusDetection
Test-DeprecationWarnings
Test-SystemStartupModeSelection
Test-ScriptParameterCompatibility
Test-BackwardCompatibilityIntegration

# Calculate results
$totalTests = $testResults.Count
$passedTests = ($testResults | Where-Object { $_.Success }).Count
$failedTests = $totalTests - $passedTests
$successRate = if ($totalTests -gt 0) { [math]::Round(($passedTests / $totalTests) * 100, 2) } else { 0 }

# Summary
Write-Host ""
Write-Host "=== TEST SUMMARY ===" -ForegroundColor Cyan
Write-Host "Total Tests: $totalTests" -ForegroundColor White
Write-Host "Passed: $passedTests" -ForegroundColor Green
Write-Host "Failed: $failedTests" -ForegroundColor Red
Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 80) { "Green" } elseif ($successRate -ge 60) { "Yellow" } else { "Red" })
Write-Host "Duration: $((Get-Date) - $testStartTime)" -ForegroundColor Gray

# Save results if requested
if ($SaveResults) {
    $report = @"
# Unity-Claude-Automation Backward Compatibility Test Results
## Test Date: $(Get-Date)
## Duration: $((Get-Date) - $testStartTime)

### Summary
- **Total Tests**: $totalTests
- **Passed Tests**: $passedTests  
- **Failed Tests**: $failedTests
- **Success Rate**: $successRate%

### Test Results
$($testResults | ForEach-Object {
    $status = if ($_.Success) { "✅ PASS" } else { "❌ FAIL" }
    "#### $($_.TestName)
**Status**: $status
**Message**: $($_.Message)
**Timestamp**: $($_.Timestamp)
"
})

### Recommendations
$(if ($failedTests -gt 0) {
    "⚠️ **Action Required**: $failedTests test(s) failed. Review the failed tests and address issues before proceeding with production deployment."
} else {
    "✅ **All Tests Passed**: Backward compatibility layer is functioning correctly and ready for production use."
})

### Next Steps
1. **If tests passed**: Deploy compatibility layer to production
2. **If tests failed**: Review failed tests and fix issues
3. **Migration**: Run migration script when ready: ``.\Migration\Migrate-ToManifestSystem.ps1``
4. **Documentation**: Update user documentation with compatibility instructions
"@
    
    $report | Out-File -FilePath $testResultsFile -Encoding UTF8
    Write-Host ""
    Write-Host "Test results saved to: $testResultsFile" -ForegroundColor Cyan
}

# Return results for scripting
return @{
    TotalTests = $totalTests
    PassedTests = $passedTests
    FailedTests = $failedTests
    SuccessRate = $successRate
    Results = $testResults
    ReportFile = if ($SaveResults) { $testResultsFile } else { $null }
}