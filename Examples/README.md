# Permission Handling Examples

This directory contains example scripts demonstrating how to use the Claude CLI Permission Handling System.

## Available Examples

### 1. Example-SafeDevelopment.ps1
**Purpose:** Demonstrates safe development workflow with intelligent permission handling.

**Features:**
- Intelligent permission decisions based on context
- Automatic git checkpointing for rollback capability  
- Custom rules for test files vs production files
- Safe operation conversion (archives instead of deletes)
- Development phase tracking

**Usage:**
```powershell
.\Examples\Example-SafeDevelopment.ps1
```

**Best for:** Daily development work, feature implementation, testing

### 2. Example-ProductionSafety.ps1
**Purpose:** Maximum safety configuration for production environments.

**Features:**
- Extremely restrictive permission rules
- Blocks all destructive operations
- System file protection
- Database operation blocking
- Emergency override procedures
- Production alerting system

**Usage:**
```powershell
.\Examples\Example-ProductionSafety.ps1
```

**Best for:** Production systems, critical infrastructure, high-risk environments

## Quick Start Guide

1. **Choose your safety level:**
   - Development: Use Example-SafeDevelopment.ps1
   - Production: Use Example-ProductionSafety.ps1

2. **Run the example:**
   ```powershell
   # For development
   .\Examples\Example-SafeDevelopment.ps1
   
   # For production
   .\Examples\Example-ProductionSafety.ps1
   ```

3. **Customize for your needs:**
   - Modify the permission rules
   - Adjust safety levels
   - Configure git settings
   - Set up alerts

## Common Use Cases

### Development Workflow
```powershell
# Start safe development session
Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Core\PermissionHandler.psm1"
Initialize-PermissionHandler -Mode "Intelligent"

# Add custom rules for your project
Add-PermissionRule -Name "AllowMyTests" `
    -Pattern "test.*\.ps1" `
    -Decision "approve" `
    -Reason "Test scripts are safe"

# Start implementation with checkpoints
Start-ImplementationPlan -PlanName "My Feature" -InitialPhase "Setup"
```

### Production Monitoring
```powershell
# Maximum safety mode
Initialize-PermissionHandler -Mode "Intelligent"

# Block everything dangerous
Add-PermissionRule -Name "ProductionLockdown" `
    -Pattern "(?i)(delete|remove|drop|truncate)" `
    -Decision "deny" `
    -Confidence 1.0 `
    -Reason "Production protection"
```

### Testing Permission Rules
```powershell
# Test your rules
.\Test-PermissionHandling.ps1 -TestType "All"
```

## Permission Rule Examples

### Allow Operations
```powershell
# Allow read operations
Add-PermissionRule -Name "SafeReads" `
    -Pattern "(?i)(get|read|cat|type|ls)" `
    -Decision "approve" `
    -Confidence 0.9

# Allow git status commands  
Add-PermissionRule -Name "GitStatus" `
    -Pattern "git (status|log|diff)" `
    -Decision "approve" `
    -Confidence 0.95
```

### Deny Operations
```powershell
# Block system files
Add-PermissionRule -Name "SystemFiles" `
    -Pattern "(?i)(system32|windows|program files)" `
    -Decision "deny" `
    -Confidence 1.0

# Block database drops
Add-PermissionRule -Name "NoDrop" `
    -Pattern "(?i)drop (table|database)" `
    -Decision "deny" `
    -Confidence 1.0
```

## Integration with Claude CLI

### Basic Usage
```powershell
# Start permission handling
.\Start-ClaudeWithPermissionHandling.ps1 -Mode "Intelligent"

# In another terminal, start Claude
claude

# Permissions will be handled automatically based on your rules
```

### Advanced Usage
```powershell
# With safe operations and git checkpoints
.\Start-ClaudeWithPermissionHandling.ps1 `
    -Mode "Intelligent" `
    -EnableSafeOps `
    -EnableGitCheckpoints `
    -ImplementationPlan "MyProject"
```

## File Structure

```
Examples/
├── Example-SafeDevelopment.ps1    # Development workflow example
├── Example-ProductionSafety.ps1   # Production safety example
└── README.md                      # This file
```

## Related Files

- `Test-PermissionHandling.ps1` - Comprehensive test suite
- `Start-ClaudeWithPermissionHandling.ps1` - Main launcher script
- `Modules/Unity-Claude-CLIOrchestrator/Core/` - Core permission modules
  - `PermissionHandler.psm1` - Permission decision engine
  - `SafeOperationsHandler.psm1` - Safe operation conversion
  - `ClaudePermissionInterceptor.psm1` - Real-time interception

## Tips and Best Practices

1. **Start Conservative:** Begin with stricter rules and relax as needed
2. **Test First:** Always test permission rules before production use
3. **Monitor Logs:** Review permission logs regularly
4. **Backup Everything:** Use git checkpointing for easy rollback
5. **Emergency Plan:** Have override procedures for critical situations
6. **Document Rules:** Keep track of custom rules and their purposes

## Troubleshooting

### Common Issues
- **Rules not working:** Check pattern syntax with Test-PermissionHandling.ps1
- **Too restrictive:** Adjust confidence levels or add allow rules
- **Missing responses:** Verify Claude window focus and timing
- **Permission denied:** Check if pattern matches are working correctly

### Debug Commands
```powershell
# Test pattern detection
Test-ClaudePermissionDetection

# Check statistics  
Get-PermissionStatistics

# View logs
Get-Content ".\AutomationLogs\permission*.log"
```

## Support

For issues or questions about permission handling:
1. Check the test results: `.\Test-PermissionHandling.ps1`
2. Review logs in `.\AutomationLogs\`
3. Examine the core modules for implementation details
4. Modify examples for your specific use case