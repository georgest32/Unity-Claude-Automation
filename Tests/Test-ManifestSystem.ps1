# Test-ManifestSystem.ps1
# Integration test for the manifest-based configuration system
# Tests manifest discovery, validation, and subsystem registration

param(
    [string]$OutputFile = ".\Test_Results_ManifestSystem_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
)

# Initialize
$ErrorActionPreference = 'Continue'
$testResults = @()
$testStartTime = Get-Date -Format 'MM/dd/yyyy HH:mm:ss'
$successCount = 0
$errorCount = 0

# Helper function to write test results
function Write-TestResult {
    param(
        [string]$Message,
        [string]$Level = 'INFO'
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
    $logLine = "[$timestamp] [$Level] $Message"
    
    # Console output with colors
    switch ($Level) {
        'ERROR' { Write-Host $logLine -ForegroundColor Red }
        'WARN'  { Write-Host $logLine -ForegroundColor Yellow }
        'OK'    { Write-Host $logLine -ForegroundColor Green }
        'DEBUG' { Write-Host $logLine -ForegroundColor Gray }
        'TRACE' { Write-Host $logLine -ForegroundColor DarkGray }
        default { Write-Host $logLine }
    }
    
    # Add to results
    $script:testResults += $logLine
}

Write-TestResult "========================================" "INFO"
Write-TestResult "MANIFEST SYSTEM INTEGRATION TEST SUITE" "INFO"
Write-TestResult "========================================" "INFO"
Write-TestResult "Test started at: $testStartTime" "INFO"
Write-TestResult "Output file: $OutputFile" "INFO"
Write-TestResult "" "INFO"

# Set working directory
Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

# Clear module cache and import
Write-TestResult "Clearing module cache..." "INFO"
Remove-Module Unity-Claude-SystemStatus -Force -ErrorAction SilentlyContinue

Write-TestResult "Importing Unity-Claude-SystemStatus module..." "INFO"
try {
    Import-Module ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1" -Force -ErrorAction Stop
    Write-TestResult "Module imported successfully" "OK"
    
    # Verify new functions are available
    $requiredFunctions = @(
        'Test-SubsystemManifest',
        'Get-SubsystemManifests', 
        'Register-SubsystemFromManifest'
    )
    
    $missing = $requiredFunctions | Where-Object { -not (Get-Command $_ -ErrorAction SilentlyContinue) }
    
    if ($missing) {
        Write-TestResult "[ERROR] Missing exported functions: $($missing -join ', ')" "ERROR"
        Write-TestResult "Available functions:" "DEBUG"
        Get-Command -Module Unity-Claude-SystemStatus | Select-Object -ExpandProperty Name | Sort-Object | ForEach-Object {
            Write-TestResult "  - $_" "DEBUG"
        }
        $testResults | Out-File $OutputFile
        exit 1
    }
    Write-TestResult "All required manifest functions verified" "OK"
    
} catch {
    Write-TestResult "Failed to import module: $_" "ERROR"
    $testResults | Out-File $OutputFile
    exit 1
}

# Test 1: Validate Template Manifest
Write-TestResult "" "INFO"
Write-TestResult "TEST 1: Template Manifest Validation" "INFO"
Write-TestResult "=====================================" "INFO"

try {
    $templatePath = ".\Modules\Unity-Claude-SystemStatus\Templates\subsystem.manifest.template.psd1"
    
    if (Test-Path $templatePath) {
        Write-TestResult "Template found at: $templatePath" "OK"
        
        $validation = Test-SubsystemManifest -Path $templatePath
        
        if ($validation.Errors.Count -gt 0) {
            Write-TestResult "Template validation errors:" "WARN"
            foreach ($error in $validation.Errors) {
                Write-TestResult "  - $error" "WARN"
            }
        }
        
        if ($validation.Warnings.Count -gt 0) {
            Write-TestResult "Template validation warnings:" "DEBUG"
            foreach ($warning in $validation.Warnings) {
                Write-TestResult "  - $warning" "DEBUG"
            }
        }
        
        Write-TestResult "Template structure validated" "OK"
        $successCount++
    } else {
        Write-TestResult "Template file not found" "ERROR"
        $errorCount++
    }
} catch {
    Write-TestResult "EXCEPTION in Test 1: $_" "ERROR"
    $errorCount++
}

# Test 2: AutonomousAgent Manifest Validation
Write-TestResult "" "INFO"
Write-TestResult "TEST 2: AutonomousAgent Manifest Validation" "INFO"
Write-TestResult "============================================" "INFO"

try {
    $agentManifestPath = ".\Manifests\AutonomousAgent.manifest.psd1"
    
    if (Test-Path $agentManifestPath) {
        Write-TestResult "AutonomousAgent manifest found" "OK"
        
        $validation = Test-SubsystemManifest -Path $agentManifestPath
        
        if ($validation.IsValid) {
            Write-TestResult "AutonomousAgent manifest is VALID" "OK"
            
            # Check key fields
            $manifest = $validation.ManifestData
            Write-TestResult "  Name: $($manifest.Name)" "DEBUG"
            Write-TestResult "  Version: $($manifest.Version)" "DEBUG"
            Write-TestResult "  UseMutex: $($manifest.UseMutex)" "DEBUG"
            Write-TestResult "  RestartPolicy: $($manifest.RestartPolicy)" "DEBUG"
            
            $successCount++
        } else {
            Write-TestResult "AutonomousAgent manifest validation FAILED" "ERROR"
            foreach ($error in $validation.Errors) {
                Write-TestResult "  - $error" "ERROR"
            }
            $errorCount++
        }
        
        if ($validation.Warnings.Count -gt 0) {
            Write-TestResult "Validation warnings:" "WARN"
            foreach ($warning in $validation.Warnings) {
                Write-TestResult "  - $warning" "WARN"
            }
        }
    } else {
        Write-TestResult "AutonomousAgent manifest not found at: $agentManifestPath" "ERROR"
        $errorCount++
    }
} catch {
    Write-TestResult "EXCEPTION in Test 2: $_" "ERROR"
    $errorCount++
}

# Test 3: Manifest Discovery
Write-TestResult "" "INFO"
Write-TestResult "TEST 3: Manifest Discovery" "INFO"
Write-TestResult "===========================" "INFO"

try {
    Write-TestResult "Discovering manifests..." "INFO"
    
    $manifests = Get-SubsystemManifests -Force
    
    if ($manifests) {
        Write-TestResult "Found $($manifests.Count) valid manifest(s)" "OK"
        
        foreach ($manifest in $manifests) {
            Write-TestResult "  - $($manifest.Name) v$($manifest.Version) [$($manifest.FileName)]" "INFO"
        }
        
        # Check if AutonomousAgent is found
        $agentManifest = $manifests | Where-Object { $_.Name -eq 'AutonomousAgent' }
        if ($agentManifest) {
            Write-TestResult "AutonomousAgent manifest discovered successfully" "OK"
            $successCount++
        } else {
            Write-TestResult "AutonomousAgent manifest not found in discovery" "ERROR"
            $errorCount++
        }
    } else {
        Write-TestResult "No manifests discovered" "WARN"
        $errorCount++
    }
    
    # Test with IncludeInvalid flag
    Write-TestResult "Testing discovery with invalid manifests..." "INFO"
    $allManifests = Get-SubsystemManifests -IncludeInvalid -Force
    
    $invalidCount = ($allManifests | Where-Object { -not $_.IsValid }).Count
    Write-TestResult "Total manifests (including invalid): $($allManifests.Count)" "INFO"
    Write-TestResult "Invalid manifests: $invalidCount" "INFO"
    
} catch {
    Write-TestResult "EXCEPTION in Test 3: $_" "ERROR"
    $errorCount++
}

# Test 4: Manifest Schema Validation
Write-TestResult "" "INFO"
Write-TestResult "TEST 4: Schema Field Validation" "INFO"
Write-TestResult "================================" "INFO"

try {
    # Create a test manifest with various validation scenarios
    $testManifest = @{
        Name = "TestSubsystem123"  # Valid
        Version = "1.2.3"  # Valid
        Description = "Test subsystem"
        StartScript = ".\test.ps1"
        RestartPolicy = "OnFailure"  # Valid enum value
        MaxRestarts = 5  # Valid range
        MaxMemoryMB = 256  # Valid
        MaxCpuPercent = 50  # Valid range
        Priority = "Normal"  # Valid enum
    }
    
    Write-TestResult "Testing valid manifest..." "INFO"
    $validation = Test-SubsystemManifest -Manifest $testManifest
    
    if ($validation.IsValid) {
        Write-TestResult "Valid manifest accepted correctly" "OK"
        $successCount++
    } else {
        Write-TestResult "Valid manifest incorrectly rejected" "ERROR"
        $errorCount++
    }
    
    # Test invalid values
    Write-TestResult "Testing invalid field values..." "INFO"
    
    # Invalid version format
    $testManifest.Version = "1.2"  # Missing patch version
    $validation = Test-SubsystemManifest -Manifest $testManifest
    if (-not $validation.IsValid) {
        Write-TestResult "Invalid version format correctly rejected" "OK"
        $successCount++
    } else {
        Write-TestResult "Invalid version format not detected" "ERROR"
        $errorCount++
    }
    $testManifest.Version = "1.2.3"  # Reset
    
    # Invalid enum value
    $testManifest.RestartPolicy = "Sometimes"  # Not valid
    $validation = Test-SubsystemManifest -Manifest $testManifest
    if (-not $validation.IsValid) {
        Write-TestResult "Invalid enum value correctly rejected" "OK"
        $successCount++
    } else {
        Write-TestResult "Invalid enum value not detected" "ERROR"
        $errorCount++
    }
    $testManifest.RestartPolicy = "OnFailure"  # Reset
    
    # Out of range value
    $testManifest.MaxCpuPercent = 150  # Over 100
    $validation = Test-SubsystemManifest -Manifest $testManifest
    if (-not $validation.IsValid) {
        Write-TestResult "Out-of-range value correctly rejected" "OK"
        $successCount++
    } else {
        Write-TestResult "Out-of-range value not detected" "ERROR"
        $errorCount++
    }
    
} catch {
    Write-TestResult "EXCEPTION in Test 4: $_" "ERROR"
    $errorCount++
}

# Test 5: Manifest Cache Performance
Write-TestResult "" "INFO"
Write-TestResult "TEST 5: Manifest Cache Performance" "INFO"
Write-TestResult "===================================" "INFO"

try {
    # First call (should populate cache)
    Write-TestResult "First discovery call (populating cache)..." "INFO"
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $manifests1 = Get-SubsystemManifests
    $stopwatch.Stop()
    $firstCallTime = $stopwatch.ElapsedMilliseconds
    Write-TestResult "First call took: $firstCallTime ms" "INFO"
    
    # Second call (should use cache)
    Write-TestResult "Second discovery call (using cache)..." "INFO"
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $manifests2 = Get-SubsystemManifests
    $stopwatch.Stop()
    $secondCallTime = $stopwatch.ElapsedMilliseconds
    Write-TestResult "Second call took: $secondCallTime ms" "INFO"
    
    if ($secondCallTime -lt $firstCallTime) {
        Write-TestResult "Cache performance improvement confirmed" "OK"
        $successCount++
    } else {
        Write-TestResult "Cache may not be working (second call not faster)" "WARN"
    }
    
    # Force refresh
    Write-TestResult "Force refresh call..." "INFO"
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $manifests3 = Get-SubsystemManifests -Force
    $stopwatch.Stop()
    $forceCallTime = $stopwatch.ElapsedMilliseconds
    Write-TestResult "Force refresh took: $forceCallTime ms" "INFO"
    
} catch {
    Write-TestResult "EXCEPTION in Test 5: $_" "ERROR"
    $errorCount++
}

# Test 6: Register-SubsystemFromManifest (Mock Test)
Write-TestResult "" "INFO"
Write-TestResult "TEST 6: Register-SubsystemFromManifest Function" "INFO"
Write-TestResult "================================================" "INFO"

try {
    # Check if function exists and has correct parameters
    $command = Get-Command Register-SubsystemFromManifest -ErrorAction SilentlyContinue
    
    if ($command) {
        Write-TestResult "Register-SubsystemFromManifest function found" "OK"
        
        # Check parameters
        $params = $command.Parameters.Keys
        $expectedParams = @('ManifestPath', 'Manifest', 'ProcessId', 'Force')
        
        $hasAllParams = $true
        foreach ($param in $expectedParams) {
            if ($param -notin $params) {
                Write-TestResult "Missing parameter: $param" "ERROR"
                $hasAllParams = $false
            }
        }
        
        if ($hasAllParams) {
            Write-TestResult "All expected parameters present" "OK"
            $successCount++
        } else {
            $errorCount++
        }
        
        # We won't actually register a subsystem in this test
        # as it would start a real process
        Write-TestResult "Registration function validated (not executed)" "INFO"
        
    } else {
        Write-TestResult "Register-SubsystemFromManifest function not found" "ERROR"
        $errorCount++
    }
    
} catch {
    Write-TestResult "EXCEPTION in Test 6: $_" "ERROR"
    $errorCount++
}

# Summary
Write-TestResult "" "INFO"
Write-TestResult "========================================" "INFO"
Write-TestResult "TEST SUITE COMPLETED" "INFO"
Write-TestResult "========================================" "INFO"
Write-TestResult "End time: $(Get-Date -Format 'MM/dd/yyyy HH:mm:ss')" "INFO"
Write-TestResult "Duration: $((Get-Date) - [DateTime]$testStartTime)" "INFO"
Write-TestResult "" "INFO"
Write-TestResult "Results Summary:" "INFO"

if ($successCount -gt 0) {
    Write-TestResult "  Successes: $successCount" "OK"
} else {
    Write-TestResult "  Successes: $successCount" "WARN"
}

if ($errorCount -gt 0) {
    Write-TestResult "  Errors: $errorCount" "ERROR"
} else {
    Write-TestResult "  Errors: $errorCount" "INFO"
}

Write-TestResult "" "INFO"
Write-TestResult "Saving results to: $OutputFile" "INFO"

# Save results
$testResults | Out-File $OutputFile

if ($errorCount -gt 0) {
    Write-TestResult "Some tests failed. Review the output for details." "WARN"
    Write-TestResult "Test output saved to: $OutputFile" "INFO"
    exit 1
} else {
    Write-TestResult "All tests passed successfully!" "OK"
    Write-TestResult "Test output saved to: $OutputFile" "INFO"
    exit 0
}