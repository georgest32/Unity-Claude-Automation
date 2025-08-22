# PowerShell Module System - Unity-Claude Automation
*Module architecture, manifests, exports, and PowerShell module best practices*
*Last Updated: 2025-08-19*

## 📋 Module System Learnings

### 4. Module Manifest Requirements (📝 DOCUMENTED)
**Issue**: Confusion about required manifest fields
**Discovery**: Only ModuleVersion is truly required in .psd1
**Evidence**: Modules load without other fields but Gallery publishing needs more
**Resolution**: Include ModuleVersion, GUID, Author, and FunctionsToExport minimum
**Critical Learning**: Start minimal, add fields as needed

### 5. Module State Management (✅ RESOLVED)
**Issue**: Sharing state between modules
**Discovery**: Each module has isolated SessionState
**Evidence**: Global variables don't work; script scope limited to module
**Resolution**: Use module-scoped variables with explicit exports
**Critical Learning**: Design for isolation; use return values not shared state

### 6. Module Reloading Limitations (⚠️ CRITICAL)
**Issue**: No true hot reload in PowerShell
**Discovery**: Import-Module -Force requires manual intervention
**Evidence**: Remove-Module needed before reload; references may persist
**Resolution**: Design for restart; use watchdog pattern for auto-updates
**Critical Learning**: Plan for full restart cycles, not hot swapping

### 19. PowerShell Module Manifest Requirements for Nested Modules (⚠️ CRITICAL)
**Issue**: "The specified module...was not loaded because no valid module file was found" when importing modular architecture
**Discovery**: Must create .psd1 manifest file with NestedModules configuration for multi-module architecture
**Evidence**: Test-EnhancedResponseProcessing-Day11.ps1 failed with 0% success rate, all functions missing
**Resolution**: Create .psd1 manifest with NestedModules array listing all sub-modules and FunctionsToExport
**Critical Learning**: PowerShell requires .psd1 manifest for proper nested module loading and function export
**Error Pattern**: Missing manifest causes "module not found" errors even when .psm1 files exist

### 22. PowerShell Module Import Path Resolution (📝 DOCUMENTED)
**Issue**: "The specified module...was not loaded because no valid module file was found" for relative paths
**Discovery**: Module import paths are relative to current module location, not project root
**Evidence**: ContextExtraction.psm1 importing "Intelligence\ContextOptimization.psm1" but file in root
**Resolution**: Use correct relative path based on actual file location: "ContextOptimization.psm1"
**Critical Learning**: Always verify actual file locations when using relative paths in Import-Module statements
**Error Pattern**: FileNotFoundException for modules that exist but are in different directories

## 🏗️ Module Architecture Best Practices

### Modular Architecture Patterns
**Successful Pattern**: Category-based organization
```
Modules/
├── Core/               # Basic functionality
├── Monitoring/         # File watching, logging
├── Parsing/           # Response processing
├── Execution/         # Safe command execution
├── Commands/          # Unity operations
├── Intelligence/      # AI and analytics
└── Integration/       # External system integration
```

### Module Manifest Template (.psd1)
```powershell
@{
    # Required fields
    ModuleVersion = '1.0.0'
    GUID = 'unique-guid-here'
    Author = 'Your Name'
    
    # Module structure
    RootModule = 'MainModule.psm1'  # For single modules
    NestedModules = @(              # For multi-module architecture
        'Core\AgentCore.psm1',
        'Monitoring\FileSystemMonitoring.psm1',
        'Parsing\ResponseParsing.psm1'
    )
    
    # Exports
    FunctionsToExport = @(
        'Get-AgentState',
        'Set-AgentState',
        'ConvertTo-HashTable'
    )
    
    # Dependencies
    RequiredModules = @()
    RequiredAssemblies = @()
    
    # Compatibility
    PowerShellVersion = '5.1'
    CompatiblePSEditions = @('Desktop')
}
```

### Function Export Best Practices
**Always Export Required Functions**:
```powershell
# At end of .psm1 file
Export-ModuleMember -Function @(
    'Initialize-EnhancedAutonomousStateTracking',
    'Set-EnhancedAutonomousState', 
    'Get-EnhancedAutonomousState',
    'Get-AgentState',
    'ConvertTo-HashTable'
)
```

**Validation Pattern**:
```powershell
# Test function exports
$module = Get-Module ModuleName
$expectedFunctions = @('Function1', 'Function2', 'Function3')
$actualFunctions = $module.ExportedCommands.Keys
$missingFunctions = $expectedFunctions | Where-Object { $_ -notin $actualFunctions }
if ($missingFunctions) {
    Write-Error "Missing functions: $($missingFunctions -join ', ')"
}
```

### Module Loading and Import Patterns
**Proper Module Path Setup**:
```powershell
# Add modules to path
$env:PSModulePath = "$PWD\Modules;$env:PSModulePath"

# Import with error handling
try {
    Import-Module Unity-Claude-AutonomousAgent-Refactored -Force
    Write-Host "Module loaded successfully"
} catch {
    Write-Error "Failed to load module: $($_.Exception.Message)"
}
```

**Individual Module Testing**:
```powershell
# Test each module separately before integration
Import-Module .\Modules\Core\AgentCore.psm1 -Force
$coreTest = Test-ModuleFunctions -ModuleName "AgentCore"

Import-Module .\Modules\Monitoring\FileSystemMonitoring.psm1 -Force  
$monitoringTest = Test-ModuleFunctions -ModuleName "FileSystemMonitoring"
```

## 🔧 Module Development Workflow

### Module Creation Checklist
1. **Create .psm1 file** with functions and proper Export-ModuleMember
2. **Create .psd1 manifest** with required fields and exports
3. **Test module individually** before integration
4. **Validate function exports** using Get-Module
5. **Test module reload** with Remove-Module/Import-Module cycle
6. **Integration testing** with dependent modules

### Module Debugging Patterns
**Function Export Debugging**:
```powershell
# Check what's actually exported
$module = Get-Module ModuleName
$module.ExportedCommands.Keys | Sort-Object

# Check module file path
$module.ModuleBase
$module.Path

# Check nested modules
$module.NestedModules
```

**Module Loading Debugging**:
```powershell
# Verbose import to see loading process
Import-Module ModuleName -Verbose

# Check module search paths
$env:PSModulePath -split ';'

# Manual path verification
Test-Path ".\Modules\ModuleName\ModuleName.psm1"
Test-Path ".\Modules\ModuleName\ModuleName.psd1"
```

### Common Module Pitfalls
1. **Missing Export-ModuleMember** - Functions defined but not exported
2. **Wrong Manifest Path** - RootModule/NestedModules pointing to wrong files
3. **Relative Path Issues** - Import-Module paths relative to wrong location
4. **Function Name Conflicts** - Same function name in multiple modules
5. **State Persistence** - Expecting global variables to work across modules

### Module Performance Considerations
**Lazy Loading Pattern**:
```powershell
# Only import when needed
if (-not (Get-Module ModuleName)) {
    Import-Module ModuleName
}
```

**Function Scope Optimization**:
```powershell
# Use script scope for shared variables within module
$script:SharedConfig = @{}

# Export only public interface
Export-ModuleMember -Function @('Public-Function1', 'Public-Function2')
```

---
*This document covers PowerShell module system specifics.*
*For broader architecture patterns, see IMPLEMENTATION_GUIDE.md*