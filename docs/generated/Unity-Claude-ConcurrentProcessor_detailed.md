# Module: Unity-Claude-ConcurrentProcessor

**Version:** 0.0  
**Path:** `C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-ConcurrentProcessor.psm1`  
**Last Modified:** 08/20/2025 17:25:22  
**Total Functions:** 17  

## Description


## Exported Commands
- `Get-ConcurrentJobStatus`
- `Get-ConcurrentProcessingReport`
- `Get-ProcessMutex`
- `Get-SharedData`
- `Invoke-JobCleanup`
- `Invoke-ParallelDataProcessing`
- `Invoke-ParallelFileProcessing`
- `Invoke-WithMutex`
- `Start-ConcurrentJob`
- `Stop-ConcurrentJob`
- `Test-ResourceAvailability`
- `Update-ResourceMonitoring`
- `Update-SharedData`
- `Wait-ConcurrentJob`
- `Write-ConcurrentLog`


## Functions


### Write-ConcurrentLog
**Lines:** 103 - 141

**Synopsis:** 
Write-ConcurrentLog [[-Message] <string>] [[-Level] <string>] [[-JobId] <string>]




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARNING", "ERROR", "DEBUG")]
        [string]$Level = "INFO",
        [string]$JobId = "SYSTEM"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logEntry = "[$timestamp] [$Level] [Job:$JobId] $Message"
``` 
### New-JobId
**Lines:** 143 - 145




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    return [System.Guid]::NewGuid().ToString("N").Substring(0, 8)
}
``` 
### Get-ConcurrentTimestamp
**Lines:** 147 - 149




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    return Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
}
``` 
### Get-ProcessMutex
**Lines:** 155 - 173

**Synopsis:** 
Get-ProcessMutex [[-MutexName] <string>]




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    param([string]$MutexName)
    
    if (-not $script:ConcurrentConfig.UseMutexes) {
        return $null
    }
    
    if (-not $script:Mutexes.ContainsKey($MutexName)) {
        try {
            $mutex = [System.Threading.Mutex]::new($false, $MutexName)
``` 
### Invoke-WithMutex
**Lines:** 175 - 201

**Synopsis:** 
Invoke-WithMutex [[-MutexName] <string>] [[-ScriptBlock] <scriptblock>] [[-TimeoutMs] <int>]




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    param(
        [string]$MutexName,
        [scriptblock]$ScriptBlock,
        [int]$TimeoutMs = 5000
    )
    
    $mutex = Get-ProcessMutex -MutexName $MutexName
    if ($null -eq $mutex) {
        # No mutex available, execute directly
``` 
### Update-SharedData
**Lines:** 203 - 220

**Synopsis:** 
Update-SharedData [[-DataKey] <string>] [[-Data] <Object>] [[-MutexName] <string>]




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    param(
        [string]$DataKey,
        [object]$Data,
        [string]$MutexName = $null
    )
    
    $operation = {
        $sharedFile = Join-Path $script:ConcurrentConfig.SharedDataPath "$DataKey.json"
        $Data | ConvertTo-Json -Depth 10 | Set-Content -Path $sharedFile -Encoding UTF8
``` 
### Get-SharedData
**Lines:** 222 - 242

**Synopsis:** 
Get-SharedData [[-DataKey] <string>] [[-MutexName] <string>]




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    param(
        [string]$DataKey,
        [string]$MutexName = $null
    )
    
    $operation = {
        $sharedFile = Join-Path $script:ConcurrentConfig.SharedDataPath "$DataKey.json"
        if (Test-Path $sharedFile) {
            $content = Get-Content -Path $sharedFile -Raw
``` 
### Update-ResourceMonitoring
**Lines:** 248 - 283

**Synopsis:** 
Update-ResourceMonitoring 




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    try {
        # Get CPU usage
        $cpuUsage = Get-CimInstance -ClassName Win32_Processor | Measure-Object -Property LoadPercentage -Average | Select-Object -ExpandProperty Average
        
        # Get memory usage
        $process = Get-Process -Id $PID
        $memoryUsage = [Math]::Round($process.WorkingSet64 / 1MB, 2)
        
        # Update monitors
``` 
### Test-ResourceAvailability
**Lines:** 285 - 326

**Synopsis:** 
Test-ResourceAvailability [[-OperationType] <string>]




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    param(
        [string]$OperationType = "General"
    )
    
    # Update resource monitoring if stale
    $timeSinceLastCheck = ((Get-Date) - $script:ResourceMonitors.LastResourceCheck).TotalSeconds
    if ($timeSinceLastCheck -gt $script:ConcurrentConfig.ThrottleCheckIntervalSeconds) {
        Update-ResourceMonitoring
    }
``` 
### Start-ConcurrentJob
**Lines:** 332 - 407

**Synopsis:** 
Start-ConcurrentJob [[-JobName] <string>] [[-ScriptBlock] <scriptblock>] [[-ArgumentList] <hashtable>] [[-OperationType] <string>] [[-TimeoutSeconds] <int>] [[-JobMetadata] <hashtable>]




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    param(
        [string]$JobName,
        [scriptblock]$ScriptBlock,
        [hashtable]$ArgumentList = @{},
        [string]$OperationType = "General",
        [int]$TimeoutSeconds = $null,
        [hashtable]$JobMetadata = @{}
    )
``` 
### Wait-ConcurrentJob
**Lines:** 409 - 494

**Synopsis:** 
Wait-ConcurrentJob [[-JobId] <string>] [[-TimeoutSeconds] <int>]




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    param(
        [string]$JobId,
        [int]$TimeoutSeconds = $null
    )
    
    if (-not $script:JobRegistry.ActiveJobs.ContainsKey($JobId)) {
        return @{
            Success = $false
            Error = "Job not found: $JobId"
``` 
### Get-ConcurrentJobStatus
**Lines:** 496 - 537

**Synopsis:** 
Get-ConcurrentJobStatus [[-JobId] <string>]




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    param(
        [string]$JobId = $null
    )
    
    if ($JobId) {
        # Get specific job status
        foreach ($registry in @($script:JobRegistry.ActiveJobs, $script:JobRegistry.CompletedJobs, $script:JobRegistry.FailedJobs)) {
            if ($registry.ContainsKey($JobId)) {
                $jobEntry = $registry[$JobId]
``` 
### Stop-ConcurrentJob
**Lines:** 539 - 577

**Synopsis:** 
Stop-ConcurrentJob [[-JobId] <string>] [[-Reason] <string>]




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    param(
        [string]$JobId,
        [string]$Reason = "Manual stop"
    )
    
    if (-not $script:JobRegistry.ActiveJobs.ContainsKey($JobId)) {
        return @{
            Success = $false
            Error = "Active job not found: $JobId"
``` 
### Invoke-ParallelFileProcessing
**Lines:** 583 - 678

**Synopsis:** 
Invoke-ParallelFileProcessing [[-FilePaths] <array>] [[-ProcessingFunction] <scriptblock>] [[-MaxConcurrency] <int>] [[-SharedContext] <hashtable>]




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    param(
        [array]$FilePaths,
        [scriptblock]$ProcessingFunction,
        [int]$MaxConcurrency = $null,
        [hashtable]$SharedContext = @{}
    )
    
    if (-not $MaxConcurrency) {
        $MaxConcurrency = $script:ConcurrentConfig.MaxConcurrentFileOperations
``` 
### Invoke-ParallelDataProcessing
**Lines:** 680 - 803

**Synopsis:** 
Invoke-ParallelDataProcessing [[-DataItems] <array>] [[-ProcessingFunction] <scriptblock>] [[-MaxConcurrency] <int>] [[-OperationName] <string>]




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    param(
        [array]$DataItems,
        [scriptblock]$ProcessingFunction,
        [int]$MaxConcurrency = $null,
        [string]$OperationName = "DataProcessing"
    )
    
    if (-not $MaxConcurrency) {
        $MaxConcurrency = $script:ConcurrentConfig.MaxConcurrentProcessingJobs
``` 
### Invoke-JobCleanup
**Lines:** 809 - 886

**Synopsis:** 
Invoke-JobCleanup [-ForceCleanup]




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    param(
        [switch]$ForceCleanup
    )
    
    $timeSinceLastCleanup = ((Get-Date) - $script:JobRegistry.LastCleanup).TotalMinutes
    
    if (-not $ForceCleanup -and $timeSinceLastCleanup -lt $script:ConcurrentConfig.JobCleanupIntervalMinutes) {
        return @{ Success = $true; Message = "Cleanup not needed yet" }
    }
``` 
### Get-ConcurrentProcessingReport
**Lines:** 888 - 928

**Synopsis:** 
Get-ConcurrentProcessingReport [-IncludeJobDetails] [-IncludeResourceMetrics]




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    param(
        [switch]$IncludeJobDetails,
        [switch]$IncludeResourceMetrics
    )
    
    # Update resource monitoring
    Update-ResourceMonitoring
    
    $report = @{
```

---
*Generated by Unity-Claude Documentation System*
