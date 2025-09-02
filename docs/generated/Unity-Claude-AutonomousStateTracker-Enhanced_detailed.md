# Module: Unity-Claude-AutonomousStateTracker-Enhanced

**Version:** 0.0  
**Path:** `C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-AutonomousStateTracker-Enhanced.psm1`  
**Last Modified:** 08/20/2025 17:25:22  
**Total Functions:** 19  

## Description


## Exported Commands
- `Approve-AgentIntervention`
- `ConvertTo-HashTable`
- `Deny-AgentIntervention`
- `Get-AgentState`
- `Get-EnhancedAutonomousState`
- `Get-SafeDateTime`
- `Get-SystemPerformanceMetrics`
- `Get-UptimeMinutes`
- `Initialize-EnhancedAutonomousStateTracking`
- `New-StateCheckpoint`
- `Request-HumanIntervention`
- `Restore-AgentStateFromCheckpoint`
- `Save-AgentState`
- `Set-EnhancedAutonomousState`
- `Start-EnhancedHealthMonitoring`
- `Stop-EnhancedHealthMonitoring`
- `Test-SystemHealthThresholds`
- `Write-EnhancedStateLog`


## Functions


### ConvertTo-HashTable
**Lines:** 216 - 283

**Synopsis:** PowerShell 5.1 compatible function to convert PSCustomObject to Hashtable

**Description:** Replaces the -AsHashtable parameter which is not available in PowerShell 5.1.
Handles nested objects and provides recursive conversion capabilities.


**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    <#
    .SYNOPSIS
    PowerShell 5.1 compatible function to convert PSCustomObject to Hashtable
    .DESCRIPTION
    Replaces the -AsHashtable parameter which is not available in PowerShell 5.1.
    Handles nested objects and provides recursive conversion capabilities.
    .PARAMETER Object
    The PSCustomObject to convert to a hashtable
    .PARAMETER Recurse
``` 
### Get-SafeDateTime
**Lines:** 285 - 381

**Synopsis:** Safely extract DateTime value from various PowerShell object types (PSObject, String, DateTime)

**Description:** Handles PowerShell ETS DateTime objects, ISO strings, and direct DateTime objects consistently


**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    <#
    .SYNOPSIS
    Safely extract DateTime value from various PowerShell object types (PSObject, String, DateTime)
    .DESCRIPTION
    Handles PowerShell ETS DateTime objects, ISO strings, and direct DateTime objects consistently
    .PARAMETER DateTimeObject
    The object to extract DateTime value from
    .NOTES
    Created to resolve PowerShell 5.1 ETS property issues with DateTime objects
``` 
### Get-UptimeMinutes
**Lines:** 383 - 435

**Synopsis:** Safely calculates uptime minutes from StartTime to current time

**Description:** Completely avoids DateTime subtraction to prevent op_Subtraction ambiguity errors


**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    <#
    .SYNOPSIS
    Safely calculates uptime minutes from StartTime to current time
    .DESCRIPTION
    Completely avoids DateTime subtraction to prevent op_Subtraction ambiguity errors
    .PARAMETER StartTime
    The start time (can be DateTime, string, or hashtable)
    .NOTES
    Uses only ticks arithmetic to avoid PowerShell 5.1 ETS DateTime op_Subtraction issues
``` 
### Write-EnhancedStateLog
**Lines:** 437 - 494

**Synopsis:** Enhanced logging with multiple output methods and performance tracking



**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    <#
    .SYNOPSIS
    Enhanced logging with multiple output methods and performance tracking
    #>
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARNING", "ERROR", "DEBUG", "PERFORMANCE", "INTERVENTION")]
        [string]$Level = "INFO",
        [string]$Component = "Enhanced-StateTracker",
``` 
### Get-SystemPerformanceMetrics
**Lines:** 496 - 561

**Synopsis:** Collect comprehensive system performance metrics using Get-Counter



**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    <#
    .SYNOPSIS
    Collect comprehensive system performance metrics using Get-Counter
    #>
    [CmdletBinding()]
    param()
    
    try {
        $metrics = @{}
``` 
### Test-SystemHealthThresholds
**Lines:** 563 - 593

**Synopsis:** Test system health against configured thresholds and trigger interventions if needed



**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    <#
    .SYNOPSIS
    Test system health against configured thresholds and trigger interventions if needed
    #>
    [CmdletBinding()]
    param(
        [hashtable]$PerformanceMetrics
    )
``` 
### Initialize-EnhancedAutonomousStateTracking
**Lines:** 599 - 670

**Synopsis:** Initialize enhanced autonomous state tracking with persistence and recovery



**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    <#
    .SYNOPSIS
    Initialize enhanced autonomous state tracking with persistence and recovery
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AgentId,
``` 
### Set-EnhancedAutonomousState
**Lines:** 672 - 784

**Synopsis:** Set autonomous agent state with enhanced validation and persistence



**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    <#
    .SYNOPSIS
    Set autonomous agent state with enhanced validation and persistence
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AgentId,
``` 
### Get-EnhancedAutonomousState
**Lines:** 786 - 857

**Synopsis:** Get current autonomous agent state with enhanced information



**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    <#
    .SYNOPSIS
    Get current autonomous agent state with enhanced information
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AgentId,
``` 
### Save-AgentState
**Lines:** 863 - 893

**Synopsis:** Save agent state to JSON with backup rotation



**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    <#
    .SYNOPSIS
    Save agent state to JSON with backup rotation
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$AgentState
    )
``` 
### Get-AgentState
**Lines:** 895 - 922

**Synopsis:** Load agent state from JSON



**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    <#
    .SYNOPSIS
    Load agent state from JSON
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AgentId
    )
``` 
### New-StateCheckpoint
**Lines:** 924 - 982

**Synopsis:** Create a state checkpoint for recovery purposes (based on research findings)



**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    <#
    .SYNOPSIS
    Create a state checkpoint for recovery purposes (based on research findings)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$AgentState,
``` 
### Restore-AgentStateFromCheckpoint
**Lines:** 984 - 1039

**Synopsis:** Restore agent state from the most recent checkpoint



**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    <#
    .SYNOPSIS
    Restore agent state from the most recent checkpoint
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AgentId,
``` 
### Request-HumanIntervention
**Lines:** 1045 - 1136

**Synopsis:** Request human intervention with multiple notification methods



**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    <#
    .SYNOPSIS
    Request human intervention with multiple notification methods
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AgentId,
``` 
### Approve-AgentIntervention
**Lines:** 1138 - 1190

**Synopsis:** Approve a pending human intervention request



**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    <#
    .SYNOPSIS
    Approve a pending human intervention request
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InterventionId,
``` 
### Deny-AgentIntervention
**Lines:** 1192 - 1233

**Synopsis:** Deny a pending human intervention request



**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    <#
    .SYNOPSIS
    Deny a pending human intervention request
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InterventionId,
``` 
### Update-InterventionStatus
**Lines:** 1235 - 1275




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    <#
    .SYNOPSIS
    Update intervention status in persistent storage
    #>
    [CmdletBinding()]
    param(
        [string]$InterventionId,
        [string]$Status,
        [string]$Response
``` 
### Start-EnhancedHealthMonitoring
**Lines:** 1281 - 1366

**Synopsis:** Start enhanced health monitoring with performance counters and thresholds



**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    <#
    .SYNOPSIS
    Start enhanced health monitoring with performance counters and thresholds
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AgentId
    )
``` 
### Stop-EnhancedHealthMonitoring
**Lines:** 1368 - 1392

**Synopsis:** Stop enhanced health monitoring jobs



**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    <#
    .SYNOPSIS
    Stop enhanced health monitoring jobs
    #>
    [CmdletBinding()]
    param(
        [string]$AgentId
    )
```

---
*Generated by Unity-Claude Documentation System*
