# Unity-Claude Event Log Source Installation Script
# Run this script as Administrator to create the event source
# This only needs to be run once per machine

#Requires -RunAsAdministrator

param(
    [switch]$Force,
    [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'

Write-Host "Unity-Claude Event Log Source Installer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$LogName = 'Unity-Claude-Automation'
$SourceName = 'Unity-Claude-Agent'

try {
    if ($Uninstall) {
        Write-Host "Uninstalling event source..." -ForegroundColor Yellow
        
        if ([System.Diagnostics.EventLog]::SourceExists($SourceName)) {
            [System.Diagnostics.EventLog]::DeleteEventSource($SourceName)
            Write-Host "Event source '$SourceName' removed successfully" -ForegroundColor Green
        }
        else {
            Write-Host "Event source '$SourceName' does not exist" -ForegroundColor Yellow
        }
        
        # Check if log is empty and remove if so
        if ([System.Diagnostics.EventLog]::Exists($LogName)) {
            $log = New-Object System.Diagnostics.EventLog($LogName)
            if ($log.Entries.Count -eq 0) {
                [System.Diagnostics.EventLog]::Delete($LogName)
                Write-Host "Empty log '$LogName' removed" -ForegroundColor Green
            }
            else {
                Write-Host "Log '$LogName' contains entries and was not removed" -ForegroundColor Yellow
            }
            $log.Dispose()
        }
    }
    else {
        Write-Host "Installing event source..." -ForegroundColor Yellow
        Write-Host "Log Name: $LogName" -ForegroundColor Gray
        Write-Host "Source Name: $SourceName" -ForegroundColor Gray
        Write-Host ""
        
        # Check if source exists
        $sourceExists = [System.Diagnostics.EventLog]::SourceExists($SourceName)
        
        if ($sourceExists -and -not $Force) {
            Write-Host "Event source already exists!" -ForegroundColor Green
            
            # Verify it's associated with the correct log
            $currentLog = [System.Diagnostics.EventLog]::LogNameFromSourceName($SourceName, ".")
            if ($currentLog -eq $LogName) {
                Write-Host "Source is correctly associated with log '$LogName'" -ForegroundColor Green
            }
            else {
                Write-Host "WARNING: Source is associated with log '$currentLog' instead of '$LogName'" -ForegroundColor Yellow
                Write-Host "Use -Force parameter to recreate with correct association" -ForegroundColor Yellow
            }
        }
        else {
            if ($sourceExists -and $Force) {
                Write-Host "Removing existing source..." -ForegroundColor Yellow
                [System.Diagnostics.EventLog]::DeleteEventSource($SourceName)
                Start-Sleep -Seconds 1
            }
            
            # Create the event source
            Write-Host "Creating event source..." -ForegroundColor Yellow
            [System.Diagnostics.EventLog]::CreateEventSource($SourceName, $LogName)
            
            # Configure the log
            Write-Host "Configuring event log..." -ForegroundColor Yellow
            $log = New-Object System.Diagnostics.EventLog($LogName)
            $log.MaximumKilobytes = 20480  # 20MB
            $log.ModifyOverflowPolicy([System.Diagnostics.OverflowAction]::OverwriteOlder, 30)
            
            # Write initialization event
            $log.Source = $SourceName
            $log.WriteEntry(
                "Unity-Claude Event Log initialized`nInstalled by: $env:USERNAME`nMachine: $env:COMPUTERNAME`nTimestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
                [System.Diagnostics.EventLogEntryType]::Information,
                1000
            )
            $log.Dispose()
            
            Write-Host "Event source created successfully!" -ForegroundColor Green
            Write-Host ""
            Write-Host "Configuration:" -ForegroundColor Cyan
            Write-Host "  Maximum Size: 20 MB" -ForegroundColor Gray
            Write-Host "  Overflow: Overwrite events older than 30 days" -ForegroundColor Gray
            Write-Host "  Event ID Ranges:" -ForegroundColor Gray
            Write-Host "    1000-1999: Information" -ForegroundColor Gray
            Write-Host "    2000-2999: Warning" -ForegroundColor Gray
            Write-Host "    3000-3999: Error" -ForegroundColor Gray
            Write-Host "    4000-4999: Critical" -ForegroundColor Gray
            Write-Host "    5000-5999: Performance" -ForegroundColor Gray
        }
        
        Write-Host ""
        Write-Host "Installation complete!" -ForegroundColor Green
        Write-Host ""
        Write-Host "You can now use the Unity-Claude-EventLog module to write events." -ForegroundColor Cyan
        Write-Host "Example:" -ForegroundColor Yellow
        Write-Host '  Import-Module Unity-Claude-EventLog' -ForegroundColor White
        Write-Host '  Write-UCEventLog -Message "Test event" -EntryType Information -Component Unity' -ForegroundColor White
    }
}
catch {
    Write-Host ""
    Write-Host "ERROR: $_" -ForegroundColor Red
    Write-Host ""
    
    if ($_.Exception.Message -like "*requested registry access*") {
        Write-Host "This script must be run as Administrator!" -ForegroundColor Yellow
        Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    }
    
    exit 1
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")