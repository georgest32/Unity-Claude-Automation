# PowerShell Module System Learnings

*Module architecture, dependency management, and best practices*

## Module Loading and Dependencies

### Learning #172: PowerShell Nested Modules Have Completely Isolated Scopes (2025-08-21)
**Context**: Phase 3 Day 18 Autonomous State Management module nested dependency integration
**Issue**: Functions in nested modules not accessible from parent module even when explicitly imported
**Discovery**: PowerShell nested modules run in completely isolated scopes with no automatic function sharing
**Evidence**: Import-Module succeeds but nested module functions unavailable in parent module
**Root Cause**: NestedModules parameter creates isolated execution contexts that don't share function scope
**Resolution**: Use dot-sourcing or RequiredModules instead of NestedModules for function sharing
**Critical Pattern**:
```powershell
# Instead of NestedModules (isolated)
NestedModules = @('Helper.psm1')

# Use dot-sourcing (shared scope)
. "$PSScriptRoot\Helper.psm1"
```
**Best Practices**:
- NestedModules only for completely independent functionality
- Dot-sourcing for shared helper functions
- RequiredModules for external dependencies
- Export-ModuleMember to control function visibility

### Learning #200: PowerShell $using Scope Modifier Limitations (2025-08-21)
**Context**: Phase 3 Day 18 Module Integration Testing
**Issue**: $using:variable syntax fails in module context with "variable cannot be retrieved" error
**Discovery**: $using scope modifier only works in specific PowerShell contexts (runspaces, workflows, remote sessions)
**Evidence**: Module functions cannot access parent scope variables using $using: syntax
**Root Cause**: $using modifier requires execution context that supports cross-scope variable resolution
**Resolution**: Pass variables as parameters instead of relying on $using scope
**Implementation**: 
```powershell
# Wrong approach (fails in modules)
function Test-Function { Write-Host $using:ParentVariable }

# Correct approach (works reliably)
function Test-Function { param($Variable) Write-Host $Variable }
```
**Critical Learning**: Never use $using scope modifier in module contexts - always pass variables as explicit parameters

### Learning #190: PowerShell Module Dependency Fallback Logging Pattern (2025-08-21)
**Context**: Unity-Claude-RunspaceManagement module failed to load Unity-Claude-ParallelProcessing dependency
**Issue**: Module depends on Write-AgentLog function but dependency module not available
**Evidence**: "Failed to import Unity-Claude-ParallelProcessing: module was not loaded because no valid module file was found"
**Discovery**: Module dependencies should have graceful fallback mechanisms for optional functionality
**Solution Applied**: Wrapper function with availability detection and fallback logging
**Implementation**:
```powershell
# Availability detection
$script:WriteAgentLogAvailable = $false
try {
    Import-Module Unity-Claude-ParallelProcessing -Force -ErrorAction Stop
    $script:WriteAgentLogAvailable = $true
} catch {
    Write-Warning "Using Write-Host fallback for logging"
}

# Wrapper function with fallback
function Write-ModuleLog {
    if ($script:WriteAgentLogAvailable) {
        Write-AgentLog -Message $Message -Level $Level -Component $Component
    } else {
        Write-FallbackLog -Message $Message -Level $Level -Component $Component
    }
}
```
**Benefits**: Module works independently even when dependencies unavailable
**Critical Learning**: Always implement fallback mechanisms for optional module dependencies - modules should degrade gracefully rather than fail completely when dependencies missing

## Module Scope and Variable Access

### Learning #195: PowerShell Runspace Session State Variable Access Limitation (2025-08-21)
**Context**: Week 2 Day 5 workflow simulation testing showing empty collections despite successful job completion
**Issue**: Session state variables not accessible in runspace scriptblock context even when properly configured
**Evidence**: "Jobs: 5, Unity: 0, Claude: 0, Actions: 0" - jobs complete but shared collections remain empty
**Discovery**: Research confirmed "session state and scopes can't be accessed across runspace instances"
**Root Cause**: Session state variables require explicit parameter passing or SessionStateProxy.SetVariable() for runspace access
**Solution Applied**: Pass synchronized collections as parameters to scriptblocks using AddParameters()
**Implementation**:
```powershell
# Before (session state access - FAILS)
$workflowScript = { $WorkflowState.UnityErrors.Add($error) }

# After (parameter passing - WORKS)
$workflowScript = { param($UnityErrors) $UnityErrors.Add($error) }
Submit-RunspaceJob -Parameters @{UnityErrors=$workflowState.UnityErrors}
```
**Impact**: Workflow simulation now properly updates shared collections
**Critical Learning**: Always pass synchronized collections as explicit parameters to runspace scriptblocks - session state variable access is not reliable in runspace contexts

### Learning #198: PowerShell Module Availability Detection Discrepancy (2025-08-21)
**Context**: Week 3 Unity Parallelization testing showing dependency check failure despite modules being available
**Issue**: Internal module import tracking inconsistent with actual module availability in PowerShell session
**Evidence**: Get-Module shows "RunspageManagement module: Available" but internal tracking shows "RunspaceManagement availability: False"
**Discovery**: Module import attempts in module initialization can fail even when modules are available from previous session imports
**Root Cause**: Dependency checking using import success tracking instead of actual module availability
**Solution Applied**: Hybrid module availability detection using both import tracking and Get-Module fallback
**Implementation**:
```powershell
# Hybrid module availability checking
$runspaceModuleAvailable = $false
if ($script:RequiredModulesAvailable.ContainsKey('RunspaceManagement') -and $script:RequiredModulesAvailable['RunspaceManagement']) {
    $runspaceModuleAvailable = $true  # Import tracking success
} else {
    $actualModule = Get-Module -Name Unity-Claude-RunspaceManagement -ErrorAction SilentlyContinue
    if ($actualModule) {
        $runspaceModuleAvailable = $true  # Get-Module fallback success
    }
}
```
**Critical Learning**: Always use hybrid module availability detection - modules may be available in session even when import attempts fail in module initialization

## Module Export and Function Visibility

### Learning #208: PowerShell 5.1 Export-ModuleMember Module Structure Fix (2025-08-22)
**Context**: Week 2 PowerShell Universal Dashboard implementation with notification integration modules
**Issue**: Functions not available after module import despite explicit Export-ModuleMember declarations
**Discovery**: PowerShell 5.1 requires Export-ModuleMember to be called at module root level, not within functions or conditionals
**Evidence**: Module loads but Get-Command shows no exported functions from the module
**Root Cause**: Export-ModuleMember calls inside functions or conditional blocks are ignored in PowerShell 5.1
**Resolution**: Move all Export-ModuleMember statements to module root level
**Implementation**:
```powershell
# Wrong (inside function - FAILS)
function Initialize-Module {
    # module logic
    Export-ModuleMember -Function Get-NotificationConfig
}

# Correct (at module root - WORKS)
function Get-NotificationConfig { }
Export-ModuleMember -Function Get-NotificationConfig
```
**Critical Learning**: Always place Export-ModuleMember statements at module root level in PowerShell 5.1 - they are ignored when called from within functions or conditional blocks

### Learning #180: PowerShell NestedModules Function Export Scope Issues (2025-08-20)
**Context**: Phase 3 Day 15 High-Performance Concurrent Logging implementation
**Issue**: Functions defined in nested modules not accessible from parent module scope
**Discovery**: NestedModules creates isolated execution contexts that don't automatically export functions
**Evidence**: Import-Module succeeds but nested module functions unavailable in parent
**Root Cause**: NestedModules parameter doesn't merge function scopes - creates separate execution contexts
**Resolution**: Use dot-sourcing pattern for shared functions or explicit function re-export
**Implementation**:
```powershell
# Instead of NestedModules
# NestedModules = @('Logging.psm1')

# Use dot-sourcing for shared scope
. "$PSScriptRoot\Logging.psm1"
Export-ModuleMember -Function * # Re-export nested functions
```
**Alternative**: Import nested module and re-export specific functions
**Critical Learning**: PowerShell NestedModules don't share function scopes - use dot-sourcing or explicit re-export for function availability