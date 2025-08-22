# Migration Troubleshooting Guide
## Unity-Claude-Automation Bootstrap Orchestrator Migration
### Common Issues and Solutions

## Quick Diagnosis

### Check Migration Status
```powershell
# Import compatibility layer
Import-Module .\Migration\Legacy-Compatibility.psm1 -Force

# Get detailed status
$status = Test-MigrationStatus
Write-Host "Migration Status: $($status.Status)"
Write-Host "Legacy Config Exists: $($status.LegacyConfigExists)"
Write-Host "Manifests Exist: $($status.ManifestsExist)"
Write-Host "Manifest Count: $($status.ManifestCount)"
Write-Host "Recommended Action: $($status.RecommendedAction)"
```

### Run Diagnostic Tests
```powershell
# Test compatibility layer
.\Migration\Test-BackwardCompatibility.ps1 -Verbose

# Test manifest system (if manifests exist)
if (Test-Path ".\Manifests\*.manifest.psd1") {
    .\Tests\Test-ManifestSystem.ps1 -Verbose
}
```

## Common Migration Issues

### Issue 1: Migration Script Fails to Start

**Symptoms**:
- Migration script throws immediate errors
- "Module not found" errors
- "Execution policy" errors

**Causes**:
- PowerShell execution policy restrictions
- Missing required modules
- Incorrect working directory
- Insufficient permissions

**Solutions**:

```powershell
# Check and fix execution policy
Get-ExecutionPolicy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Verify working directory
Get-Location
# Should be: C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation

# Check required files exist
Test-Path ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psm1"
Test-Path ".\Start-SystemStatusMonitoring-Enhanced.ps1"

# Run with elevated privileges if needed
# Right-click PowerShell -> "Run as Administrator"
```

### Issue 2: Generated Manifests Are Invalid

**Symptoms**:
- Manifest validation fails
- Syntax errors in manifest files
- Missing required fields

**Causes**:
- PowerShell data file syntax errors
- Missing required manifest properties
- Incorrect data types in configuration

**Solutions**:

```powershell
# Test specific manifest
$manifestPath = ".\Manifests\AutonomousAgent.manifest.psd1"
try {
    $manifest = Import-PowerShellDataFile -Path $manifestPath
    Write-Host "Manifest is valid" -ForegroundColor Green
} catch {
    Write-Host "Manifest error: $($_.Exception.Message)" -ForegroundColor Red
}

# Check required fields
$requiredFields = @('Name', 'Version', 'StartScript', 'Dependencies', 'RestartPolicy', 'MutexName')
$manifest = Import-PowerShellDataFile -Path $manifestPath
$missingFields = $requiredFields | Where-Object { -not $manifest.ContainsKey($_) }
if ($missingFields) {
    Write-Host "Missing fields: $($missingFields -join ', ')" -ForegroundColor Red
}

# Fix common syntax issues
# - Ensure strings are quoted: Name = "AutonomousAgent"
# - Arrays use @(): Dependencies = @("SystemStatus")
# - Booleans are $true/$false: UseMutex = $true
```

### Issue 3: System Falls Back to Legacy Mode

**Symptoms**:
- Auto-detection always chooses legacy mode
- Manifest mode fails to start
- "No manifests found" messages

**Causes**:
- Manifests directory missing or empty
- Invalid manifest syntax
- Manifest discovery failure
- SystemStatus module not loading

**Solutions**:

```powershell
# Check manifests directory
Test-Path ".\Manifests"
Get-ChildItem ".\Manifests" -Filter "*.manifest.psd1"

# Verify SystemStatus module loads
Import-Module ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psm1" -Force
Get-Command -Module "Unity-Claude-SystemStatus" | Where-Object { $_.Name -like "*Manifest*" }

# Test manifest discovery
if (Get-Command "Get-SubsystemManifests" -ErrorAction SilentlyContinue) {
    $manifests = Get-SubsystemManifests -Path ".\Manifests"
    Write-Host "Found $($manifests.Count) manifests"
} else {
    Write-Host "Get-SubsystemManifests function not available" -ForegroundColor Red
}
```

### Issue 4: Subsystem Won't Start in Manifest Mode

**Symptoms**:
- Specific subsystem fails to start
- "StartScript not found" errors
- Mutex acquisition failures
- Dependency resolution errors

**Causes**:
- Incorrect StartScript path
- Missing dependencies
- Mutex conflicts
- Resource limit enforcement

**Solutions**:

```powershell
# Check StartScript path
$manifest = Import-PowerShellDataFile -Path ".\Manifests\AutonomousAgent.manifest.psd1"
$startScript = $manifest.StartScript
Write-Host "StartScript: $startScript"
Test-Path $startScript

# Verify dependencies exist
$manifest.Dependencies | ForEach-Object {
    $depManifest = ".\Manifests\$_.manifest.psd1"
    if (Test-Path $depManifest) {
        Write-Host "Dependency $_ found" -ForegroundColor Green
    } else {
        Write-Host "Dependency $_ missing" -ForegroundColor Red
    }
}

# Check for mutex conflicts
$mutexName = $manifest.MutexName
Write-Host "Checking mutex: $mutexName"
# Note: Mutex conflicts usually resolve automatically with timeout

# Review resource limits
Write-Host "Resource Limits:"
Write-Host "  MaxMemoryMB: $($manifest.MaxMemoryMB)"
Write-Host "  MaxCpuPercent: $($manifest.MaxCpuPercent)"
```

### Issue 5: Performance Degradation After Migration

**Symptoms**:
- System runs slower than before
- High CPU or memory usage
- Delayed subsystem startup
- Timeout errors

**Causes**:
- Aggressive health checking
- Resource limit enforcement
- Dependency resolution overhead
- Multiple subsystem restarts

**Solutions**:

```powershell
# Review health check intervals
$manifests = Get-ChildItem ".\Manifests\*.manifest.psd1"
$manifests | ForEach-Object {
    $manifest = Import-PowerShellDataFile -Path $_.FullName
    Write-Host "$($manifest.Name): HealthCheckInterval = $($manifest.HealthCheckInterval)s"
}

# Adjust intervals if too aggressive (recommended: 30-60 seconds)
# Edit manifest files to increase HealthCheckInterval

# Check resource usage
Get-Process | Where-Object { $_.ProcessName -eq "powershell" } | Select-Object Id, CPU, WorkingSet

# Review restart patterns
# Check logs for excessive restart messages
```

## Compatibility Layer Issues

### Issue 6: Compatibility Module Won't Load

**Symptoms**:
- "Module not found" when importing Legacy-Compatibility.psm1
- Functions like Test-MigrationStatus not available
- Scripts fall back to legacy mode only

**Solutions**:

```powershell
# Check module file exists
Test-Path ".\Migration\Legacy-Compatibility.psm1"

# Try manual import with error details
Import-Module ".\Migration\Legacy-Compatibility.psm1" -Force -Verbose

# Check exported functions
Get-Module "Legacy-Compatibility" | Select-Object -ExpandProperty ExportedFunctions

# Verify PowerShell version compatibility
$PSVersionTable.PSVersion  # Should be 5.1 or later
```

### Issue 7: Deprecation Warnings Don't Appear

**Symptoms**:
- No deprecation warnings shown when using legacy mode
- Users not aware they're using deprecated functionality

**Solutions**:

```powershell
# Check warning preference
$WarningPreference  # Should be "Continue"

# Enable warnings if disabled
$WarningPreference = "Continue"

# Test deprecation warning system
Show-DeprecationWarning -FunctionName "Test-Function" -Replacement "New-Function"

# Check if warnings are being suppressed
Enable-LegacyMode  # Should show warning unless -SuppressWarnings used
```

## Bootstrap Orchestrator Issues

### Issue 8: Dependency Resolution Fails

**Symptoms**:
- "Circular dependency detected" errors
- Subsystems start in wrong order
- Dependency-related startup failures

**Solutions**:

```powershell
# Test dependency resolution
$manifests = Get-SubsystemManifests -Path ".\Manifests"
try {
    $startupOrder = Get-SubsystemStartupOrder -Manifests $manifests
    Write-Host "Startup order calculated successfully"
    $startupOrder | ForEach-Object { Write-Host "  $($_.Name)" }
} catch {
    Write-Host "Dependency resolution failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Check for circular dependencies manually
$manifests | ForEach-Object {
    Write-Host "$($_.Name) depends on: $($_.Dependencies -join ', ')"
}

# Fix circular dependencies by removing unnecessary dependencies
# or restructuring subsystem relationships
```

### Issue 9: Mutex Singleton Enforcement Failures

**Symptoms**:
- Multiple instances of same subsystem running
- "Mutex acquisition timeout" errors
- Subsystem registration conflicts

**Solutions**:

```powershell
# Test mutex system
.\Tests\Test-MutexSingleton.ps1 -Verbose

# Check for abandoned mutexes
# Note: System should automatically handle abandoned mutexes

# Verify Global\ prefix is used
$manifests = Get-ChildItem ".\Manifests\*.manifest.psd1"
$manifests | ForEach-Object {
    $manifest = Import-PowerShellDataFile -Path $_.FullName
    $mutexName = $manifest.MutexName
    if ($mutexName -like "Global\*") {
        Write-Host "$($manifest.Name): Mutex OK ($mutexName)" -ForegroundColor Green
    } else {
        Write-Host "$($manifest.Name): Mutex ISSUE ($mutexName)" -ForegroundColor Red
    }
}
```

## Rollback and Recovery

### Emergency Rollback

If migration causes critical issues:

```powershell
# Immediate rollback - stop all systems and use legacy mode
Stop-Process -Name "powershell" -Force -ErrorAction SilentlyContinue
.\Start-UnifiedSystem-WithCompatibility.ps1 -UseLegacyMode
```

### Complete System Restore

To fully restore pre-migration state:

```powershell
# Find your backup
$backups = Get-ChildItem ".\Backups" | Where-Object { $_.Name -like "*Migration*" }
$latestBackup = $backups | Sort-Object CreationTime -Descending | Select-Object -First 1
Write-Host "Latest backup: $($latestBackup.FullName)"

# Restore files
Copy-Item "$($latestBackup.FullName)\*" .\ -Force -Recurse

# Remove manifests
Remove-Item ".\Manifests\*.manifest.psd1" -Force -ErrorAction SilentlyContinue

# Restart with original scripts
.\Start-UnifiedSystem-Complete.ps1
```

### Partial Recovery

To fix specific subsystem issues:

```powershell
# Disable specific subsystem in manifest mode
$manifest = ".\Manifests\ProblematicSubsystem.manifest.psd1"
Rename-Item $manifest "$manifest.disabled"

# Or edit manifest to fix issues
# Then restart system
```

## Prevention Strategies

### Pre-Migration Validation

```powershell
# Always test migration in development first
.\Migration\Migrate-ToManifestSystem.ps1 -WhatIf

# Validate environment
Test-Path ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psm1"
Get-ExecutionPolicy
$PSVersionTable.PSVersion

# Create multiple backups
$backup1 = ".\Backups\Manual_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$backup2 = "C:\Backups\Unity-Claude-Migration_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
```

### Post-Migration Monitoring

```powershell
# Regular system health checks
.\Tests\Test-ManifestSystem.ps1 -Verbose

# Monitor performance
Get-Process | Where-Object { $_.ProcessName -eq "powershell" }

# Validate all subsystems
$manifests = Get-SubsystemManifests -Path ".\Manifests"
$manifests | ForEach-Object {
    Write-Host "Checking $($_.Name)..."
    # Add your subsystem-specific health checks here
}
```

## Getting Additional Help

### Log Analysis

Migration and system logs contain detailed information:

```powershell
# Find latest migration log
$migrationLogs = Get-ChildItem "Migration_Log_*.txt" | Sort-Object CreationTime -Descending
$latestLog = $migrationLogs | Select-Object -First 1
Get-Content $latestLog.FullName | Select-Object -Last 50

# Find system monitoring logs
$systemLogs = Get-ChildItem "SystemStatusMonitoring_*.log" | Sort-Object CreationTime -Descending
$latestSystemLog = $systemLogs | Select-Object -First 1
Get-Content $latestSystemLog.FullName | Select-Object -Last 50
```

### Debug Mode Operation

For detailed troubleshooting, run systems in debug mode:

```powershell
# Migration with debug output
.\Migration\Migrate-ToManifestSystem.ps1 -Debug -Verbose

# System startup with debug
.\Start-UnifiedSystem-WithCompatibility.ps1 -Debug

# Test suites with verbose output
.\Migration\Test-BackwardCompatibility.ps1 -Verbose
.\Tests\Test-ManifestSystem.ps1 -Verbose
```

### Environment Information

Collect environment information for support:

```powershell
# PowerShell environment
$PSVersionTable

# Execution policy
Get-ExecutionPolicy -List

# Module status
Get-Module | Where-Object { $_.Name -like "*Unity-Claude*" }

# File system permissions
Get-Acl ".\Migration\Legacy-Compatibility.psm1"

# Current directory and paths
Get-Location
$env:PSModulePath -split ';'
```

---

**Last Updated**: 2025-08-22  
**Version**: 1.0.0  
**For additional support**: Review migration logs and test results for specific error details