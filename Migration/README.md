# Unity-Claude-Automation Migration Tools
## Bootstrap Orchestrator Migration Suite

This directory contains tools and documentation for migrating from the legacy hardcoded subsystem management to the new manifest-based Bootstrap Orchestrator system.

## Quick Start

### 1. Check Migration Status
```powershell
# Import compatibility layer
Import-Module .\Legacy-Compatibility.psm1

# Check current status
Test-MigrationStatus
```

### 2. Run Migration
```powershell
# Preview changes (recommended first)
.\Migrate-ToManifestSystem.ps1 -WhatIf

# Execute migration
.\Migrate-ToManifestSystem.ps1 -Verbose
```

### 3. Test Compatibility
```powershell
# Validate backward compatibility
.\Test-BackwardCompatibility.ps1 -SaveResults
```

### 4. Use New System
```powershell
# Start with auto-detection
..\Start-UnifiedSystem-WithCompatibility.ps1

# Or force manifest mode
..\Start-UnifiedSystem-WithCompatibility.ps1 -UseManifestMode
```

## Files in This Directory

### Core Migration Tools
- **`Migrate-ToManifestSystem.ps1`** - Main migration script that converts legacy configuration to manifests
- **`Legacy-Compatibility.psm1`** - Backward compatibility layer providing dual-mode operation
- **`Test-BackwardCompatibility.ps1`** - Comprehensive test suite for compatibility validation

### Documentation
- **`MIGRATION_GUIDE.md`** - Complete migration guide with step-by-step instructions
- **`README.md`** - This file, quick reference for migration tools
- **`TROUBLESHOOTING.md`** - Common issues and solutions during migration

### Generated Files (Created During Migration)
- **`Migration_Log_YYYYMMDD_HHMMSS.txt`** - Detailed migration execution log
- **`Migration_Report_YYYYMMDD_HHMMSS.md`** - Human-readable migration summary report

## Migration States

The system recognizes four migration states:

### 1. No Configuration
- **Description**: Neither legacy nor manifest configuration exists
- **Action**: Set up initial configuration
- **Status**: Requires initial setup

### 2. Pre-Migration  
- **Description**: Legacy configuration exists, no manifests
- **Action**: Run migration script
- **Status**: Ready for migration

### 3. Migration In Progress
- **Description**: Both legacy and manifest configurations exist
- **Action**: Test manifest system, then remove legacy files
- **Status**: Dual-mode available

### 4. Migration Complete
- **Description**: Only manifest configuration exists
- **Action**: Use manifest-based system exclusively
- **Status**: Migration successful

## Tool Usage

### Migrate-ToManifestSystem.ps1

Primary migration tool that analyzes existing configuration and generates manifests.

```powershell
# Basic usage
.\Migrate-ToManifestSystem.ps1

# Preview mode (no changes)
.\Migrate-ToManifestSystem.ps1 -WhatIf

# Force overwrite existing manifests
.\Migrate-ToManifestSystem.ps1 -Force

# Custom backup location
.\Migrate-ToManifestSystem.ps1 -BackupPath "C:\MyBackups\Migration"

# Skip backup creation
.\Migrate-ToManifestSystem.ps1 -Backup:$false
```

**Features**:
- ✅ Automatic configuration detection
- ✅ Intelligent manifest generation
- ✅ Backup and rollback support
- ✅ Comprehensive validation
- ✅ Detailed reporting

### Legacy-Compatibility.psm1

PowerShell module providing backward compatibility during migration.

```powershell
# Import module
Import-Module .\Migration\Legacy-Compatibility.psm1

# Check migration status
$status = Test-MigrationStatus
Write-Host "Status: $($status.Status)"

# Enable legacy mode
Enable-LegacyMode

# Start system with auto-detection
Start-UnityClaudeSystem
```

**Key Functions**:
- `Test-MigrationStatus` - Analyze current migration state
- `Enable-LegacyMode` / `Disable-LegacyMode` - Control compatibility mode
- `Start-UnityClaudeSystem` - Unified startup with auto-detection
- `Show-DeprecationWarning` - Provide migration guidance

### Test-BackwardCompatibility.ps1

Comprehensive test suite validating compatibility layer functionality.

```powershell
# Run all tests
.\Test-BackwardCompatibility.ps1

# Verbose output with results saved
.\Test-BackwardCompatibility.ps1 -Verbose -SaveResults
```

**Test Coverage**:
- ✅ Compatibility module loading
- ✅ Legacy mode toggle functionality
- ✅ Migration status detection
- ✅ Deprecation warning system
- ✅ System startup mode selection
- ✅ Script parameter compatibility
- ✅ Backward compatibility integration

## Integration with Existing Scripts

### Updated Entry Points

The migration provides updated versions of key entry point scripts:

- **`Start-SystemStatusMonitoring-Enhanced-WithCompatibility.ps1`** - SystemStatus monitoring with dual-mode support
- **`Start-UnifiedSystem-WithCompatibility.ps1`** - Unified system startup with migration support

### Original Script Compatibility

Original scripts remain functional:

- **`Start-SystemStatusMonitoring-Enhanced.ps1`** - Enhanced with compatibility layer detection
- **`Start-UnifiedSystem-Complete.ps1`** - Enhanced with Bootstrap Orchestrator support

### Parameter Extensions

All compatibility scripts support new parameters:

- **`-UseLegacyMode`** - Force legacy hardcoded configuration
- **`-UseManifestMode`** - Force manifest-based Bootstrap Orchestrator
- **`-RunMigration`** - Run migration before startup (where applicable)

## Common Migration Workflows

### Workflow 1: Development Environment
```powershell
# 1. Check current state
Test-MigrationStatus

# 2. Run migration with preview
.\Migrate-ToManifestSystem.ps1 -WhatIf

# 3. Execute migration
.\Migrate-ToManifestSystem.ps1

# 4. Test compatibility
.\Test-BackwardCompatibility.ps1

# 5. Switch to manifest mode
..\Start-UnifiedSystem-WithCompatibility.ps1 -UseManifestMode
```

### Workflow 2: Production Environment
```powershell
# 1. Create backup
$backup = "C:\Backups\Production_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
.\Migrate-ToManifestSystem.ps1 -BackupPath $backup

# 2. Test in maintenance window
.\Test-BackwardCompatibility.ps1 -SaveResults

# 3. Deploy with auto-detection
..\Start-UnifiedSystem-WithCompatibility.ps1

# 4. Monitor system performance
# 5. Remove legacy mode after validation
```

### Workflow 3: Gradual Migration
```powershell
# Phase 1: Deploy compatibility layer
..\Start-UnifiedSystem-WithCompatibility.ps1 -UseLegacyMode

# Phase 2: Run migration, test manifests
.\Migrate-ToManifestSystem.ps1
.\Test-BackwardCompatibility.ps1

# Phase 3: Enable auto-detection
..\Start-UnifiedSystem-WithCompatibility.ps1

# Phase 4: Force manifest mode after validation
..\Start-UnifiedSystem-WithCompatibility.ps1 -UseManifestMode
```

## Error Handling and Recovery

### Migration Failures
- **Log Analysis**: Check migration log for specific error details
- **Partial Success**: Review migration report for successful vs. failed subsystems
- **Rollback**: Use backup created during migration process

### Compatibility Issues
- **Fallback**: System automatically falls back to legacy mode on manifest failures
- **Debug Mode**: Use `-Debug` parameter for detailed troubleshooting
- **Test Suite**: Run backward compatibility tests to isolate issues

### Rollback Procedures
```powershell
# Immediate rollback to legacy mode
..\Start-UnifiedSystem-WithCompatibility.ps1 -UseLegacyMode

# Complete rollback from backup
$backupPath = ".\Backups\Migration_YYYYMMDD_HHMMSS"
Copy-Item "$backupPath\*" ..\ -Force
Remove-Item ..\Manifests\*.manifest.psd1 -Force
```

## Best Practices

### Before Migration
- ✅ Read migration guide thoroughly
- ✅ Test in development environment first
- ✅ Plan migration during maintenance window
- ✅ Ensure backups are available

### During Migration
- ✅ Monitor migration script output
- ✅ Review generated manifests for correctness
- ✅ Run compatibility tests
- ✅ Document any customizations made

### After Migration
- ✅ Monitor system performance
- ✅ Validate all subsystems are working
- ✅ Keep migration logs for reference
- ✅ Update documentation and procedures

## Support and Troubleshooting

For issues during migration:

1. **Check Migration Logs**: Detailed logs provide specific error information
2. **Run Test Suite**: Backward compatibility tests help isolate problems
3. **Review Documentation**: Migration guide contains troubleshooting section
4. **Use Rollback**: Quickly revert to working state if needed

## Version Information

- **Migration Tool Version**: Phase 3 Day 2 Implementation
- **Compatibility Layer Version**: 1.0.0
- **Last Updated**: 2025-08-22
- **PowerShell Compatibility**: Windows PowerShell 5.1+

---

For complete migration instructions, see `MIGRATION_GUIDE.md`