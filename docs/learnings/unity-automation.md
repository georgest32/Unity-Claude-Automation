# Unity Automation and Integration Learnings

*Unity-specific automation, error handling, and integration patterns*

## Unity Error Detection and Handling

### Critical Unity Paths
- **Unity Editor.log location**: `C:\Users\georg\AppData\Local\Unity\Editor\Editor.log`
  - This file contains Unity compilation errors and runtime logs
  - Used by Unity-Claude-Automation for error detection
  - Check this file when debugging Unity compilation issues

### Unity Project Integration

### Learning #202: Unity Project Mock Integration with Module-Specific Registries (2025-08-21)
**Context**: Week 3 Unity Parallelization testing with mock Unity project integration for development environments
**Issue**: Unity project registration and error detection needed for module testing without requiring actual Unity installation
**Discovery**: Mock integration provides controlled testing environment while maintaining realistic error patterns
**Implementation**: Module-specific Unity project registries with configurable mock data
**Architecture**:
```powershell
# Mock Unity project configuration
$MockUnityProjects = @{
    'TestProject1' = @{
        Path = 'C:\UnityProjects\TestProject1'
        LogPath = 'C:\UnityProjects\TestProject1\Logs\Editor.log'
        MockErrors = @(
            @{ Type = 'Compilation'; Message = 'CS0103: The name does not exist'; Timestamp = Get-Date }
            @{ Type = 'Runtime'; Message = 'NullReferenceException'; Timestamp = Get-Date }
        )
        Status = 'Active'
    }
}

# Registry management functions
function Register-MockUnityProject {
    param([hashtable]$ProjectConfig)
    $MockUnityProjects[$ProjectConfig.Name] = $ProjectConfig
}

function Get-MockUnityErrors {
    param([string]$ProjectName)
    return $MockUnityProjects[$ProjectName].MockErrors
}
```
**Benefits**:
- Testing without Unity installation
- Controllable error scenarios
- Consistent test environment
- Module isolation and independence
**Integration Points**:
- Error monitoring and detection
- Log file parsing and analysis
- Project status tracking
- Automated error reporting
**Critical Learning**: Mock integration enables comprehensive testing of Unity automation modules without requiring full Unity development environment

## Unity Log Processing

### Learning #134: PowerShell 5.1 DateTime ETS Properties JSON Serialization (Phase 3 Day 15 - ✅ RESOLVED)
**Issue**: "Cannot create object of type System.DateTime. The DisplayHint property was not found for the System.DateTime object"
**Discovery**: PowerShell Extended Type System (ETS) adds DisplayHint and DateTime properties to DateTime objects that break JSON serialization
**Evidence**: Get-Date creates DateTime objects with ETS properties that serialize incorrectly and fail during ConvertFrom-Json reconstruction
**Location**: ConvertTo-HashTable function and Get-EnhancedAutonomousState UptimeMinutes calculation
**Root Cause**: PowerShell 5.1's ETS automatically adds extra properties to DateTime objects:
- **DisplayHint Property**: NoteProperty added by Get-Date cmdlet  
- **DateTime Property**: ScriptProperty attached by ETS to all DateTime objects
- **JSON Serialization**: These properties get included in JSON but fail during reconstruction
**Technical Details**:
- PowerShell 5.1 uses JavaScriptSerializer with problematic DateTime handling
- PowerShell 7.2+ fixed this by excluding ETS properties from DateTime serialization
- ConvertFrom-Json tries to recreate objects with missing ETS properties causing errors
**Resolution**: Special DateTime handling in ConvertTo-HashTable function:
```powershell
# Detect DateTime objects
if ($propertyValue -is [DateTime] -or ($propertyValue -and $propertyValue.GetType().Name -eq "DateTime")) {
    # Use BaseObject to get underlying .NET DateTime without ETS properties
    $baseDateTime = if ($propertyValue.PSObject.BaseObject) { $propertyValue.PSObject.BaseObject } else { $propertyValue }
    # Convert to ISO 8601 string for reliable JSON serialization
    $hashtable[$propertyName] = $baseDateTime.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
}
```
**Alternative Solutions**:
- Use .ToString() method to convert DateTime to string before serialization
- Use Get-Date -Format to get string representation directly
- Filter out ETS properties manually before JSON conversion
**Impact**: Fixed Unity log timestamp serialization and autonomous state persistence
**Critical Learning**: Always convert DateTime objects to strings before JSON serialization in PowerShell 5.1 to avoid ETS property conflicts

## SendKeys Automation for Unity

### Learning #123: SendKeys Window Focus Requirements (Day 13 - ✅ DOCUMENTED)
**Issue**: SendKeys requires target application to have focus or keystrokes go to wrong window
**Discovery**: Windows security prevents background windows from stealing focus directly
**Evidence**: SetForegroundWindow fails when called from background process
**Resolution**: Multi-method approach:
1. Direct SetForegroundWindow attempt
2. ShowWindow with SW_RESTORE then SetForegroundWindow  
3. AttachThreadInput to bypass security restrictions
**Critical Learning**: Always verify window focus before SendKeys. Implement multiple fallback methods as Windows focus management is unreliable.

### Learning #127: SendKeys Special Character Escaping (Day 13 - ✅ IMPLEMENTED)
**Issue**: SendKeys interprets certain characters as control sequences
**Discovery**: Characters like +, ^, %, ~, (), {} have special meaning in SendKeys
**Evidence**: Unescaped prompts with these characters cause unexpected behavior
**Resolution**: Escape special characters by wrapping in braces: `{+}`, `{^}`, etc.
**Critical Learning**: Always escape SendKeys input. Use regex replacement: `-replace '([+^%~(){}])', '{$1}'`

### Learning #131: SendKeys Target Window Detection Issue (Day 13 - ✅ RESOLVED)
**Issue**: SendKeys typing into PowerShell console instead of Claude window during tests
**Discovery**: Get-ClaudeWindow function searches PowerShell processes and returns PowerShell console
**Evidence**: Word "test" appears in PowerShell input after running tests
**Location**: CLIAutomation.psm1 Get-ClaudeWindow function
**Root Cause**: Function searches for "pwsh", "powershell" processes and accepts any window title containing "claude"
**Resolution**: Remove PowerShell processes from search list and require explicit Claude title match:
```powershell
# Only search Claude-specific processes first
$claudeProcesses = Get-Process -Name "claude" -ErrorAction SilentlyContinue
# For terminals, require explicit "claude" in title
if ($title -match "claude|Claude") { ... }
```
**Critical Learning**: Be very specific with window detection to avoid SendKeys targeting wrong applications

## Unity Build and Compilation Integration

### Unity Test Automation Implementation (Phase 1 Day 4)
**Context**: Unity test automation with compilation error detection and automated retry mechanisms
**Implementation Achievements**:
1. **Automated Build Testing**: Trigger Unity builds programmatically and detect compilation failures
2. **Error Classification**: Categorize Unity errors by type (compilation, runtime, asset pipeline)
3. **Retry Logic**: Implement intelligent retry for transient failures (asset imports, package resolution)
4. **Log Analysis**: Parse Unity Editor logs for structured error information and stack traces
5. **Notification Integration**: Automated alerts for build failures with error context
**Critical Technical Insights**:
- **Unity Command Line**: Use `-batchmode`, `-quit`, `-logFile` parameters for automated builds
- **Error Detection**: Monitor Editor.log for compilation errors, warnings, and exceptions
- **Asset Pipeline**: Handle asset import delays and dependency resolution timing
- **Build Validation**: Verify build artifacts and test execution results
**Performance Considerations**:
- Unity builds can take 2-10 minutes depending on project size
- Asset import delays add 30-120 seconds to build time
- Parallel Unity processes compete for resources
**Integration Patterns**:
```powershell
# Unity build automation
function Start-UnityBuild {
    param(
        [string]$ProjectPath,
        [string]$BuildTarget = "StandaloneWindows64",
        [int]$TimeoutMinutes = 15
    )
    
    $logFile = "$ProjectPath\Logs\build_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    $unityArgs = @(
        '-batchmode'
        '-quit'
        '-projectPath', $ProjectPath
        '-buildTarget', $BuildTarget
        '-logFile', $logFile
    )
    
    $process = Start-Process -FilePath $UnityEditorPath -ArgumentList $unityArgs -Wait -PassThru
    $buildResults = Get-UnityBuildResults -LogFile $logFile
    
    return @{
        ExitCode = $process.ExitCode
        Success = $process.ExitCode -eq 0
        LogFile = $logFile
        Errors = $buildResults.Errors
        Warnings = $buildResults.Warnings
        Duration = $buildResults.Duration
    }
}
```
**Critical Learning**: Unity automation requires careful timing management, comprehensive error detection, and robust retry mechanisms for reliable CI/CD integration