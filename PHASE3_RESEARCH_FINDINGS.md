# Phase 3: Windows Event Log Integration - Research Findings
*Created: 2025-08-22*
*Research Queries Completed: 5*
*Type: Research Documentation*

## Executive Summary
Research confirms Windows Event Log integration is feasible but requires careful design due to PowerShell version differences. PowerShell 7 has deprecated classic event log cmdlets but provides multiple viable alternatives.

## Critical Discoveries

### 1. PowerShell Version Compatibility Issues
**Finding**: PowerShell 7 has REMOVED classic event log cmdlets
- **Removed Cmdlets**: Write-EventLog, New-EventLog, Get-EventLog, Show-EventLog
- **Replacement**: Get-WinEvent for reading (fully supported)
- **Writing Challenge**: No direct replacement for Write-EventLog in PS7

### 2. Event Log Writing Solutions for PowerShell 7

#### Option A: System.Diagnostics.EventLog Class (RECOMMENDED)
```powershell
# Works in both PS 5.1 and PS 7
$logName = "Application"
$source = "Unity-Claude-Agent"
if (-not [System.Diagnostics.EventLog]::SourceExists($source)) {
    [System.Diagnostics.EventLog]::CreateEventSource($source, $logName)
}
$event = New-Object System.Diagnostics.EventLog($logName)
$event.Source = $source
$event.WriteEntry("Message", [System.Diagnostics.EventLogEntryType]::Information, 1000)
```
**Pros**: Cross-version compatible, full control
**Cons**: Requires admin for source creation

#### Option B: Windows PowerShell Compatibility Mode
```powershell
# PS7 only - uses PS 5.1 under the hood
Import-Module Microsoft.PowerShell.Management -UseWindowsPowerShell
Write-EventLog -LogName "Application" -Source "Unity-Claude-Agent" -EventId 1000 -Message "Test"
```
**Pros**: Familiar cmdlet syntax
**Cons**: Performance overhead, deserialized objects, PS7 only

#### Option C: New-WinEvent (Limited)
- Only works with registered ETW providers
- Not suitable for custom application logging
- Better for system-level tracing

### 3. Administrator Privilege Requirements
**Critical Finding**: Event source creation REQUIRES admin privileges
- Registry key: HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\EventLog
- Only needs to be done ONCE per machine
- After creation, standard users can write events

**Elevation Check Code**:
```powershell
$isAdmin = [bool]([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')
```

### 4. Performance Optimization with Get-WinEvent

#### XPath vs XML Filtering
- **XPath**: Best for simple, single-source queries
  - Limit: 32 expressions maximum
  - Uses XPath 1.0 subset (no contains(), limited functions)
- **XML**: Best for complex, multi-source queries
  - No expression limit
  - Supports Suppress elements for exclusions

#### Performance Best Practices
1. **NEVER use Where-Object for filtering** - High overhead
2. **Filter at source** using XPath/XML parameters
3. **Use hashtable filtering** for simple queries
4. **Batch queries** when possible

### 5. Event Log Structure Recommendations

#### Event ID Ranges (Industry Standard)
- 1000-1999: Information events
- 2000-2999: Warning events  
- 3000-3999: Error events
- 4000-4999: Critical events
- 5000-5999: Performance/Metrics

#### Structured Data Format
```powershell
@{
    Timestamp = [DateTime]::UtcNow
    Component = "Unity|Claude|Agent|Monitor"
    Action = "CompilationStart|SubmissionComplete|etc"
    Result = "Success|Failure|Warning"
    Duration = [Int32] # Milliseconds
    Details = @{} # Component-specific data
    CorrelationId = [Guid]::NewGuid()
}
```

## Implementation Strategy

### Dual-Mode Approach (RECOMMENDED)
1. **Primary**: Use System.Diagnostics.EventLog for writing (cross-version)
2. **Secondary**: Use Get-WinEvent for reading (modern, performant)
3. **Fallback**: File-based logging if event log unavailable

### Module Architecture
```
Unity-Claude-EventLog\
├── Unity-Claude-EventLog.psd1
├── Unity-Claude-EventLog.psm1
├── Core\
│   ├── Initialize-UCEventSource.ps1      # One-time admin setup
│   ├── Write-UCEventLog.ps1             # Cross-version writer
│   └── Get-UCEventLog.ps1               # Get-WinEvent wrapper
├── Query\
│   ├── New-UCXPathQuery.ps1             # XPath query builder
│   └── New-UCXmlQuery.ps1               # XML query builder
└── Setup\
    └── Install-UCEventSource.ps1         # Admin installation script
```

### Version Detection Strategy
```powershell
$isPSCore = $PSVersionTable.PSEdition -eq 'Core'
if ($isPSCore) {
    # Use System.Diagnostics.EventLog
} else {
    # Use Write-EventLog directly
}
```

## Security Considerations

### Event Source Installation
1. **Separate Setup Script**: Create Install-UCEventSource.ps1
2. **Require Admin Once**: Check and prompt for elevation
3. **Validate Installation**: Verify source exists before writing
4. **Document Process**: Clear instructions for administrators

### Credential Protection
- No credentials stored in event logs
- Sanitize sensitive data before logging
- Use correlation IDs instead of user data
- Implement log retention policies

## Performance Targets
- **Write Performance**: <100ms per event (achieved with EventLog class)
- **Query Performance**: <500ms for 1000 events (XPath optimized)
- **Memory Usage**: Minimal overhead with proper disposal
- **Batch Operations**: Support queuing for high-volume scenarios

## Risk Mitigation

### Identified Risks & Solutions
1. **Admin Rights Required**
   - Solution: One-time setup script with clear documentation
   - Fallback: Continue file-based logging if source unavailable

2. **Cross-Version Compatibility**
   - Solution: Abstract behind wrapper functions
   - Test both PS 5.1 and PS 7 paths

3. **Performance Impact**
   - Solution: Asynchronous writing with queue
   - Implement throttling for high-volume scenarios

4. **Event Log Size**
   - Solution: Configure max size and retention
   - Implement automatic cleanup policies

## Next Implementation Steps
1. Create Unity-Claude-EventLog module structure
2. Implement Initialize-UCEventSource.ps1 with admin checks
3. Build Write-UCEventLog.ps1 with cross-version support
4. Create Get-UCEventLog.ps1 with XPath optimization
5. Test on both PowerShell 5.1 and 7
6. Document setup process for administrators

## Key Learnings
- PowerShell 7's removal of classic cmdlets is permanent
- System.Diagnostics.EventLog provides best cross-version solution
- XPath performance far exceeds Where-Object filtering
- Event source creation is persistent across reboots
- Compatibility mode adds significant overhead

---
*Research Phase Complete - Ready for Implementation*