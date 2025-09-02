# Module: Unity-Claude-ResourceOptimizer

**Version:** 0.0  
**Path:** `C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-ResourceOptimizer.psm1`  
**Last Modified:** 08/20/2025 17:25:22  
**Total Functions:** 12  

## Description


## Exported Commands
- `ConvertTo-HumanReadableSize`
- `Get-MemoryUsage`
- `Invoke-ComprehensiveResourceCheck`
- `Invoke-EmergencyCleanup`
- `Invoke-GarbageCollection`
- `Invoke-LogRotation`
- `Invoke-MemoryMonitoring`
- `Invoke-ResourceAlert`
- `Invoke-SessionCleanup`
- `Start-AutomaticResourceOptimization`
- `Write-ResourceLog`


## Functions


### Write-ResourceLog
**Lines:** 91 - 121

**Synopsis:** 
Write-ResourceLog [[-Message] <string>] [[-Level] <string>] [[-Component] <string>]




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARNING", "ERROR", "DEBUG")]
        [string]$Level = "INFO",
        [string]$Component = "ResourceOptimizer"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logEntry = "[$timestamp] [$Level] [$Component] $Message"
``` 
### Get-ResourceTimestamp
**Lines:** 123 - 125




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    return Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
}
``` 
### ConvertTo-HumanReadableSize
**Lines:** 127 - 140

**Synopsis:** 
ConvertTo-HumanReadableSize [[-Bytes] <long>]




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    param([long]$Bytes)
    
    $sizes = @("B", "KB", "MB", "GB", "TB")
    $index = 0
    $size = $Bytes
    
    while ($size -gt 1024 -and $index -lt ($sizes.Length - 1)) {
        $size = $size / 1024
        $index++
``` 
### Get-MemoryUsage
**Lines:** 146 - 185

**Synopsis:** 
Get-MemoryUsage [-Detailed]




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    param([switch]$Detailed)
    
    try {
        $process = Get-Process -Id $PID
        $workingSetMB = [Math]::Round($process.WorkingSet64 / 1MB, 2)
        $privateMemoryMB = [Math]::Round($process.PrivateMemorySize64 / 1MB, 2)
        $virtualMemoryMB = [Math]::Round($process.VirtualMemorySize64 / 1MB, 2)
        
        $gcMemoryMB = [Math]::Round([GC]::GetTotalMemory($false) / 1MB, 2)
``` 
### Invoke-MemoryMonitoring
**Lines:** 187 - 263

**Synopsis:** 
Invoke-MemoryMonitoring 




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    $timeSinceLastCheck = ((Get-Date) - $script:ResourceMetrics.LastMemoryCheck).TotalMinutes
    
    if ($timeSinceLastCheck -lt $script:ResourceConfig.MemoryCheckIntervalMinutes) {
        return @{ Success = $true; Message = "Memory check not needed yet" }
    }
    
    Write-ResourceLog "Performing memory monitoring check" -Level "DEBUG"
    
    try {
``` 
### Invoke-GarbageCollection
**Lines:** 265 - 317

**Synopsis:** 
Invoke-GarbageCollection [-Aggressive] [-Force]




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    param(
        [switch]$Aggressive,
        [switch]$Force
    )
    
    $timeSinceLastGC = ((Get-Date) - $script:ResourceMetrics.LastGarbageCollection).TotalMinutes
    
    # Don't run GC too frequently unless forced
    if (-not $Force -and $timeSinceLastGC -lt 1) {
``` 
### Invoke-LogRotation
**Lines:** 323 - 443

**Synopsis:** 
Invoke-LogRotation [[-LogPath] <string>] [-Force]




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    param(
        [string]$LogPath = $null,
        [switch]$Force
    )
    
    if (-not $LogPath) {
        $LogPath = $script:ResourceConfig.LogPath
    }
``` 
### Invoke-SessionCleanup
**Lines:** 449 - 558

**Synopsis:** 
Invoke-SessionCleanup [-Force] [-IncludeTempFiles] [-IncludeCaches]




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    param(
        [switch]$Force,
        [switch]$IncludeTempFiles,
        [switch]$IncludeCaches
    )
    
    $timeSinceLastCleanup = ((Get-Date) - $script:ResourceMetrics.LastCleanup).TotalHours
    
    if (-not $Force -and $timeSinceLastCleanup -lt $script:ResourceConfig.CleanupIntervalHours) {
``` 
### Invoke-EmergencyCleanup
**Lines:** 560 - 611

**Synopsis:** 
Invoke-EmergencyCleanup [[-Reason] <string>]




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    param(
        [string]$Reason = "Emergency cleanup requested"
    )
    
    Write-ResourceLog "Starting emergency cleanup: $Reason" -Level "WARNING"
    
    try {
        $results = @{}
``` 
### Invoke-ResourceAlert
**Lines:** 617 - 672

**Synopsis:** 
Invoke-ResourceAlert [[-Type] <string>] [[-Value] <double>] [[-Threshold] <double>] [[-AdditionalData] <hashtable>]




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    param(
        [string]$Type,
        [double]$Value,
        [double]$Threshold,
        [hashtable]$AdditionalData = @{}
    )
    
    if (-not $script:ResourceConfig.AlertingEnabled) {
        return
``` 
### Invoke-ComprehensiveResourceCheck
**Lines:** 678 - 783

**Synopsis:** 
Invoke-ComprehensiveResourceCheck [-IncludeRecommendations]




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    param([switch]$IncludeRecommendations)
    
    Write-ResourceLog "Starting comprehensive resource check" -Level "INFO"
    
    try {
        $resourceReport = @{
            Timestamp = Get-ResourceTimestamp
            Memory = @{}
            Disk = @{}
``` 
### Start-AutomaticResourceOptimization
**Lines:** 785 - 837

**Synopsis:** 
Start-AutomaticResourceOptimization [-RunOnce]




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    param([switch]$RunOnce)
    
    Write-ResourceLog "Starting automatic resource optimization" -Level "INFO"
    
    try {
        $results = @{
            MemoryMonitoring = $null
            LogRotation = $null
            SessionCleanup = $null
```

---
*Generated by Unity-Claude Documentation System*
