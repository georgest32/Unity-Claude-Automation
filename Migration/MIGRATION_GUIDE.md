# Unity-Claude-Automation Migration Guide
## From Legacy Configuration to Manifest-Based Bootstrap Orchestrator
### Date: 2025-08-22
### Version: 1.0.0

## Overview

This guide walks you through migrating from the legacy hardcoded subsystem management to the new manifest-based Bootstrap Orchestrator system. The migration provides better dependency management, resource control, and system reliability.

## Benefits of Migration

### Before (Legacy System)
- ❌ Hardcoded subsystem configuration
- ❌ Manual dependency management
- ❌ Limited error recovery
- ❌ No resource limits
- ❌ Difficult to maintain

### After (Manifest-Based System)
- ✅ Declarative configuration files
- ✅ Automatic dependency resolution
- ✅ Advanced error recovery with circuit breakers
- ✅ Resource limit enforcement
- ✅ Easy to maintain and extend

## Migration Process

### Step 1: Backup Your Current Configuration

Before starting migration, create a backup of your current system:

```powershell
# Create backup directory
$backupPath = ".\Backups\Pre-Migration_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $backupPath -Force

# Backup key files
Copy-Item "Start-SystemStatusMonitoring-Enhanced.ps1" $backupPath
Copy-Item "Start-UnifiedSystem-Complete.ps1" $backupPath
Copy-Item "system_status.json" $backupPath -ErrorAction SilentlyContinue
```

### Step 2: Run the Migration Script

Execute the migration script to analyze your current configuration and generate manifests:

```powershell
# Run migration with preview first
.\Migration\Migrate-ToManifestSystem.ps1 -WhatIf

# Review the output, then run actual migration
.\Migration\Migrate-ToManifestSystem.ps1 -Verbose
```

The migration script will:
- Analyze your current subsystem configuration
- Generate manifest files in `.\Manifests\`
- Create a comprehensive migration report
- Backup your existing configuration

### Step 3: Validate Generated Manifests

Review the generated manifests to ensure they match your requirements:

```powershell
# Test manifest validity
.\Tests\Test-ManifestSystem.ps1

# Review generated manifests
Get-ChildItem .\Manifests\*.manifest.psd1 | ForEach-Object {
    Write-Host "=== $($_.Name) ===" -ForegroundColor Cyan
    Get-Content $_.FullPath | Select-Object -First 20
}
```

### Step 4: Test Backward Compatibility

Before switching to the new system, test that backward compatibility works:

```powershell
# Test compatibility layer
.\Migration\Test-BackwardCompatibility.ps1 -Verbose -SaveResults

# Test legacy mode still works
.\Start-UnifiedSystem-WithCompatibility.ps1 -UseLegacyMode

# Test manifest mode
.\Start-UnifiedSystem-WithCompatibility.ps1 -UseManifestMode
```

### Step 5: Switch to Manifest-Based System

Once testing is successful, switch to using the manifest-based system:

```powershell
# Start with new system
.\Start-UnifiedSystem-WithCompatibility.ps1 -UseManifestMode

# Or let the system auto-detect (recommended)
.\Start-UnifiedSystem-WithCompatibility.ps1
```

## Migration Scenarios

### Scenario 1: Basic Migration

For users with standard AutonomousAgent + SystemStatus setup:

1. Run migration script: `.\Migration\Migrate-ToManifestSystem.ps1`
2. Test compatibility: `.\Migration\Test-BackwardCompatibility.ps1`
3. Switch scripts: Use `Start-UnifiedSystem-WithCompatibility.ps1`

**Expected Result**: Seamless transition with improved features

### Scenario 2: Custom Configuration

For users with customized subsystem configurations:

1. Run migration with backup: `.\Migration\Migrate-ToManifestSystem.ps1 -Backup`
2. Review generated manifests in `.\Manifests\`
3. Manually adjust manifests for custom settings
4. Test with: `.\Tests\Test-ManifestSystem.ps1`
5. Switch to manifest mode

**Manual Adjustments Needed**:
- Custom resource limits in manifests
- Modified health check intervals
- Custom dependency relationships

### Scenario 3: Gradual Migration

For production environments requiring gradual migration:

1. **Phase 1**: Deploy compatibility layer, continue using legacy mode
2. **Phase 2**: Run migration script, test manifests in development
3. **Phase 3**: Switch to auto-detection mode (uses manifests if available)
4. **Phase 4**: Remove legacy mode support after validation

## Using the New System

### Basic Commands

```powershell
# Start with auto-detection (recommended)
.\Start-UnifiedSystem-WithCompatibility.ps1

# Force legacy mode (for rollback)
.\Start-UnifiedSystem-WithCompatibility.ps1 -UseLegacyMode

# Force manifest mode
.\Start-UnifiedSystem-WithCompatibility.ps1 -UseManifestMode

# Run migration
.\Migration\Migrate-ToManifestSystem.ps1

# Test system
.\Tests\Test-ManifestSystem.ps1
```

### Manifest Configuration

Manifests are located in `.\Manifests\` and use PowerShell data file format:

```powershell
# Example: AutonomousAgent.manifest.psd1
@{
    Name = "AutonomousAgent"
    Version = "1.0.0"
    StartScript = ".\Start-AutonomousMonitoring-Fixed.ps1"
    Dependencies = @("SystemStatus")
    HealthCheckFunction = "Test-AutonomousAgentStatus"
    HealthCheckInterval = 30
    RestartPolicy = "OnFailure"
    MaxRestarts = 3
    RestartDelay = 5
    MutexName = "Global\UnityClaudeAutonomousAgent"
}
```

### Customizing Manifests

You can customize manifests for your specific needs:

#### Resource Limits
```powershell
MaxMemoryMB = 500        # Maximum memory in MB
MaxCpuPercent = 25       # Maximum CPU percentage
```

#### Health Monitoring
```powershell
HealthCheckFunction = "Test-MyCustomHealth"    # Custom health check
HealthCheckInterval = 60                       # Check every 60 seconds
HealthCheckTimeout = 5000                      # 5 second timeout
```

#### Restart Policy
```powershell
RestartPolicy = "Always"     # Always, OnFailure, Never
MaxRestarts = 10             # Maximum restart attempts
RestartDelay = 5             # Delay between restarts
```

#### Dependencies
```powershell
Dependencies = @(
    "SystemStatus",
    "CLISubmission",
    "CustomSubsystem"
)
```

## Troubleshooting

### Common Issues

#### Issue: Migration Script Fails
**Symptoms**: Migration script throws errors
**Solution**: 
1. Check PowerShell execution policy: `Get-ExecutionPolicy`
2. Ensure you're in the correct directory
3. Run with elevated privileges if needed
4. Check migration log for specific errors

#### Issue: Manifests Not Found
**Symptoms**: System falls back to legacy mode
**Solution**:
1. Verify manifests exist: `Get-ChildItem .\Manifests\*.manifest.psd1`
2. Check manifest syntax: `.\Tests\Test-ManifestSystem.ps1`
3. Ensure manifest directory is in correct location

#### Issue: Subsystem Won't Start
**Symptoms**: Subsystem fails to start in manifest mode
**Solution**:
1. Check manifest configuration for errors
2. Verify StartScript path is correct
3. Check dependencies are available
4. Review mutex configuration

#### Issue: Performance Degradation
**Symptoms**: System runs slower after migration
**Solution**:
1. Check resource limits in manifests
2. Verify dependency resolution isn't causing delays
3. Review health check intervals
4. Monitor system with: `.\Tests\Test-ManifestSystem.ps1`

### Debug Commands

```powershell
# Check migration status
Test-MigrationStatus

# Verify compatibility layer
Get-Module Legacy-Compatibility

# Test manifest validation
.\Tests\Test-ManifestSystem.ps1 -Verbose

# Check subsystem status
Get-SubsystemManifests -Path .\Manifests
```

### Getting Help

1. **Check Logs**: Review migration and startup logs for detailed error information
2. **Test Framework**: Use test scripts to isolate issues
3. **Rollback**: Use `-UseLegacyMode` to quickly rollback if needed
4. **Documentation**: Review `IMPORTANT_LEARNINGS.md` for known issues

## Rollback Procedure

If you need to rollback to the legacy system:

### Immediate Rollback
```powershell
# Stop current system
Stop-Process -Name "powershell" -Force -ErrorAction SilentlyContinue

# Start with legacy mode
.\Start-UnifiedSystem-WithCompatibility.ps1 -UseLegacyMode
```

### Complete Rollback
```powershell
# Restore from backup
$backupPath = ".\Backups\Pre-Migration_YYYYMMDD_HHMMSS"  # Use your backup path
Copy-Item "$backupPath\*" .\ -Force

# Remove manifests
Remove-Item .\Manifests\*.manifest.psd1 -Force

# Use original scripts
.\Start-UnifiedSystem-Complete.ps1
```

## Advanced Configuration

### Custom Subsystems

To add new subsystems to the manifest system:

1. **Create Manifest**: Copy template from `.\Modules\Unity-Claude-SystemStatus\Templates\`
2. **Configure Dependencies**: Set proper dependency order
3. **Test Integration**: Use `.\Tests\Test-ManifestSystem.ps1`
4. **Deploy**: Place in `.\Manifests\` directory

### Environment-Specific Configuration

You can create environment-specific manifests:

```powershell
# Development
Copy-Item .\Manifests\AutonomousAgent.manifest.psd1 .\Manifests\AutonomousAgent.development.manifest.psd1

# Production  
Copy-Item .\Manifests\AutonomousAgent.manifest.psd1 .\Manifests\AutonomousAgent.production.manifest.psd1
```

Then modify each for environment-specific settings.

### Integration with External Systems

The manifest system supports integration with external monitoring:

```powershell
# Custom health check function
function Test-MyCustomHealth {
    # Your custom health logic
    return @{ Status = "Healthy"; Details = "All systems operational" }
}
```

## Best Practices

### Manifest Management
- ✅ Keep manifests in version control
- ✅ Use meaningful version numbers
- ✅ Test changes in development first
- ✅ Document custom configurations

### Migration Strategy
- ✅ Always backup before migration
- ✅ Test compatibility layer thoroughly
- ✅ Migrate during maintenance windows
- ✅ Have rollback plan ready

### Ongoing Maintenance
- ✅ Monitor system performance after migration
- ✅ Update manifests when changing configurations
- ✅ Regularly test backup and restore procedures
- ✅ Keep documentation updated

## Conclusion

The migration to manifest-based Bootstrap Orchestrator provides significant improvements in system reliability, maintainability, and functionality. The backward compatibility layer ensures a smooth transition while providing the flexibility to migrate at your own pace.

For additional support or questions, review the comprehensive test suites and documentation provided with the system.

---

**Last Updated**: 2025-08-22  
**Version**: 1.0.0  
**Migration Tool Version**: Phase 3 Day 2 Implementation