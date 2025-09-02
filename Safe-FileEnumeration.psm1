#Requires -Version 5.1

<#
.SYNOPSIS
Safe-FileEnumeration - CLR Fatal Error prevention utility

.DESCRIPTION
Provides safe file system enumeration patterns to prevent CLR Fatal Error 0x80131506
caused by unbounded List<T> growth and symlink loops.

.NOTES
Author: Unity-Claude-Automation System
Version: 1.0.0
Critical Fix: Prevents CLR crashes from Get-ChildItem -Recurse operations
#>

function Get-SafeChildItems {
    <#
    .SYNOPSIS
    Safe replacement for Get-ChildItem -Recurse to prevent CLR crashes
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter()]
        [string]$Filter = "*.*",
        
        [Parameter()]
        [int]$MaxDepth = 5,
        
        [Parameter()]
        [switch]$FilesOnly
    )
    
    # Safe exclude pattern to prevent symlink loops
    $excludePattern = '\\(Library|Temp|node_modules|\.git|Packages|Logs|obj|bin|ClaudeResponses\\Autonomous)(\\|$)'
    
    try {
        Get-ChildItem -LiteralPath $Path -Filter $Filter -Force -ErrorAction SilentlyContinue -Attributes !ReparsePoint -Depth $MaxDepth |
          Where-Object { $_.FullName -notmatch $excludePattern -and $_.Length -lt 50MB } |
          ForEach-Object {
            if ($FilesOnly -and $_.PSIsContainer) { return }
            [pscustomobject]@{
                FullName = $_.FullName
                Name = $_.Name
                Length = if ($_.PSIsContainer) { 0 } else { $_.Length }
                LastWriteTime = $_.LastWriteTime
                IsContainer = $_.PSIsContainer
            }
          }
    }
    catch {
        Write-Warning "Safe enumeration failed for $Path`: $($_.Exception.Message)"
        return @()
    }
}

Export-ModuleMember -Function 'Get-SafeChildItems'

Write-Host "[Safe-FileEnumeration] CLR error prevention utility loaded" -ForegroundColor Green