# Input Locking Setup and Troubleshooting Guide
**Date**: 2025-08-21  
**Version**: 1.0  
**Purpose**: Setup guide for keyboard/mouse input locking during Claude Code CLI responses

## Overview

The input locking system prevents accidental keyboard and mouse input during Claude Code CLI response generation. This is critical for autonomous operation where unintended user input could interrupt or corrupt the response process.

## Architecture

### Components
1. **Lock-InputForResponse.ps1** - Core input blocking utility
2. **Submit-WithInputLock.ps1** - Integrated submission wrapper
3. **Unity-Claude-NotificationConfiguration** - Configuration management
4. **Unity-Claude-CLISubmission-Enhanced** - Enhanced CLI submission with auto-locking

### How It Works
1. User initiates Claude Code CLI submission
2. System checks configuration for auto-lock setting
3. If enabled and admin privileges available, input is blocked
4. Claude response proceeds without interruption
5. Input is automatically restored when response completes or times out

## Prerequisites

### 1. Administrator Privileges
Input locking requires Administrator privileges to use the Windows `BlockInput` API.

**Check if running as Administrator:**
```powershell
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
Write-Host "Running as Administrator: $isAdmin"
```

**To run PowerShell as Administrator:**
1. Right-click PowerShell icon
2. Select "Run as Administrator"
3. Navigate to Unity-Claude-Automation directory

### 2. Windows Version Compatibility
- Windows 10/11 (tested)
- Windows Server 2016+ (should work)
- PowerShell 5.1+ required

## Installation and Setup

### Step 1: Initialize Configuration
```powershell
# Navigate to Unity-Claude-Automation directory
cd C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation

# Import notification configuration module
Import-Module .\Modules\Unity-Claude-NotificationConfiguration\Unity-Claude-NotificationConfiguration.psm1

# Initialize configuration
Initialize-NotificationConfiguration
```

### Step 2: Enable Input Locking
```powershell
# Enable input locking with 5-minute timeout
Enable-InputLockIntegration -TimeoutSeconds 300

# Or configure manually
Set-InputLockConfiguration -Enabled $true -AutoLockOnSubmission $true -TimeoutSeconds 300
```

### Step 3: Verify Setup
```powershell
# Check input lock configuration
$config = Get-InputLockConfiguration
Write-Host "Input Lock Enabled: $($config.Configuration.Enabled)"
Write-Host "Auto-lock on Submission: $($config.Configuration.AutoLockOnSubmission)"
Write-Host "Has Admin Privileges: $($config.RuntimeStatus.HasAdminPrivileges)"
Write-Host "Can Use Input Lock: $($config.RuntimeStatus.CanUseInputLock)"
```

## Usage

### Basic Usage
```powershell
# Submit with automatic input locking
.\CLI-Automation\Submit-WithInputLock.ps1 -ErrorContent "Fix Unity compilation errors"

# Submit without input locking
.\CLI-Automation\Submit-WithInputLock.ps1 -ErrorContent "Fix Unity compilation errors" -AutoLock:$false
```

### Manual Input Locking
```powershell
# Lock input for 180 seconds
.\CLI-Automation\Lock-InputForResponse.ps1 -Lock -TimeoutSeconds 180

# Unlock input immediately
.\CLI-Automation\Lock-InputForResponse.ps1 -Unlock
```

### Enhanced CLI Submission
```powershell
# Import enhanced CLI submission module
Import-Module .\Modules\Unity-Claude-CLISubmission-Enhanced.psm1

# Submit with integrated input locking
Submit-ToClaudeWithInputLock -Content "Fix compilation errors" -Context "Unity 2021.1.14f1"
```

## Configuration Options

### Input Lock Settings
| Setting | Description | Default | Notes |
|---------|-------------|---------|-------|
| `Enabled` | Enable/disable input locking | `false` | Requires admin privileges |
| `AutoLockOnSubmission` | Auto-lock during submissions | `true` | When enabled |
| `TimeoutSeconds` | Maximum lock duration | `300` | 5 minutes default |
| `RequireAdminPrivileges` | Enforce admin requirement | `true` | Security measure |
| `ShowWarningMessages` | Display lock/unlock messages | `true` | User feedback |
| `WindowTitlePattern` | Claude window pattern | `"Claude Code CLI*"` | For monitoring |
| `EmergencyUnlockFile` | Emergency unlock filename | `"unlock_claude_input.txt"` | Create this file to unlock |

### Update Configuration
```powershell
# Change timeout to 10 minutes
Set-InputLockConfiguration -TimeoutSeconds 600

# Disable auto-lock but keep manual locking available
Set-InputLockConfiguration -AutoLockOnSubmission $false

# Disable input locking completely
Disable-InputLockIntegration
```

## Safety Features

### 1. Emergency Unlock Methods
- **Ctrl+Alt+Del**: Always works (Windows feature)
- **Emergency File**: Create `unlock_claude_input.txt` in root directory
- **Timeout**: Automatic unlock after configured timeout
- **Thread Safety**: Auto-unlock if PowerShell process exits

### 2. Visual Indicators
When input is locked, you'll see:
```
===== INPUT LOCKED FOR CLAUDE RESPONSE =====
Do NOT type or click until unlocked!
Emergency: Ctrl+Alt+Del always works
=============================================
```

When input is restored:
```
===== INPUT UNLOCKED - SAFE TO USE =====
Keyboard and mouse restored
=====================================
```

### 3. Graceful Degradation
- If admin privileges unavailable: Warning shown, continues without locking
- If lock script missing: Warning shown, continues normally
- If configuration invalid: Falls back to safe defaults

## Troubleshooting

### Problem: "Administrator privileges required" error
**Cause**: PowerShell not running as Administrator  
**Solution**: 
1. Close PowerShell
2. Right-click PowerShell icon
3. Select "Run as Administrator"
4. Re-run your command

### Problem: Input remains locked after script completion
**Cause**: Script error or unexpected termination  
**Solutions**:
1. Press **Ctrl+Alt+Del** (always works)
2. Create emergency unlock file:
   ```powershell
   New-Item "unlock_claude_input.txt" -ItemType File
   ```
3. Manual unlock:
   ```powershell
   .\CLI-Automation\Lock-InputForResponse.ps1 -Unlock
   ```

### Problem: "Lock script not found" warning
**Cause**: Input lock script missing  
**Solution**: Verify script exists at expected location:
```powershell
$config = Get-InputLockConfiguration
Test-Path $config.RuntimeStatus.LockScriptPath
```

### Problem: Input locking not working despite configuration
**Diagnosis Steps**:
1. Check admin privileges:
   ```powershell
   $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
   ```
2. Check configuration:
   ```powershell
   Get-InputLockConfiguration | ConvertTo-Json -Depth 3
   ```
3. Test manual lock:
   ```powershell
   .\CLI-Automation\Lock-InputForResponse.ps1 -Lock
   ```

### Problem: False "Configuration validation failed" warnings
**Cause**: Missing or incomplete notification configuration  
**Solution**: Reinitialize configuration:
```powershell
Reset-NotificationConfiguration -Backup
Initialize-NotificationConfiguration -Force
```

## Advanced Configuration

### Custom Window Title Pattern
If using a different Claude Code CLI window title:
```powershell
Set-InputLockConfiguration -WindowTitlePattern "My Claude CLI*"
```

### Integration with Existing Scripts
Add input locking to existing scripts:
```powershell
# At start of script
$lockJob = $null
if ((Get-InputLockConfiguration).RuntimeStatus.CanUseInputLock) {
    Import-Module .\Modules\Unity-Claude-CLISubmission-Enhanced.psm1
    $lockJob = Start-InputLockProtection
}

# Your existing Claude submission code here

# At end of script (in finally block)
if ($lockJob) {
    Stop-InputLockProtection -LockJob $lockJob
}
```

### Configuration Backup and Restore
```powershell
# Backup current configuration
Export-NotificationConfiguration -Path "config_backup.json" -IncludeSecrets

# Restore from backup
Import-NotificationConfiguration -Path "config_backup.json" -Backup
```

## Security Considerations

### Privileges Required
- Administrator privileges needed for `BlockInput` API
- Scripts should check privileges before attempting to lock
- Graceful degradation when privileges unavailable

### Emergency Access
- Ctrl+Alt+Del cannot be overridden (Windows security feature)
- Emergency unlock file provides alternative access
- Timeout prevents indefinite locking

### Process Safety
- Input automatically unlocked if PowerShell process exits
- Error handlers ensure cleanup
- Multiple fallback mechanisms

## Performance Impact

### System Resources
- Minimal CPU usage
- No memory leaks (automatic cleanup)
- Background job overhead negligible

### User Experience
- Visual feedback during lock/unlock
- Clear warning messages
- Timeout prevents user frustration

## Logging and Monitoring

### Log Files
Input locking events are logged to:
- `unity_claude_automation.log` (main log)
- PowerShell console output
- Background job logs

### Monitoring Status
```powershell
# Check if input currently locked
Get-Job | Where-Object { $_.Name -like "*InputLock*" }

# View recent log entries
Get-Content "unity_claude_automation.log" | Select-Object -Last 20
```

## Best Practices

### Development
1. Always test with admin privileges
2. Use timeout values appropriate for your use case
3. Include emergency unlock in error handling
4. Provide clear user feedback

### Production
1. Document input locking behavior for users
2. Set reasonable timeout values (5-10 minutes)
3. Monitor for stuck locks
4. Regular configuration validation

### Debugging
1. Enable debug logging when troubleshooting
2. Test manual lock/unlock before automated use
3. Verify Windows version compatibility
4. Check for conflicting software

## Version History

### v1.0 (2025-08-21)
- Initial implementation
- Administrator privilege requirement
- Emergency unlock mechanisms
- Configuration management integration
- Enhanced CLI submission integration