# Quick fix to import the legacy compatibility functions
# This bypasses the parser error in the main module file

Import-Module "$PSScriptRoot\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psm1" -Force

function Start-UnityClaudeSystem {
    <#
    .SYNOPSIS
    Starts the Unity-Claude-Automation system
    
    .DESCRIPTION
    Main entry point for starting the system with support for both legacy and manifest modes
    
    .PARAMETER UseLegacyMode
    Force legacy startup mode
    
    .PARAMETER UseManifestMode
    Force manifest-based startup
    
    .PARAMETER WindowedSubsystems
    Array of subsystem names to run in separate PowerShell windows
    
    .PARAMETER WindowTitle
    Title for windowed subsystem windows
    
    .EXAMPLE
    Start-UnityClaudeSystem -UseManifestMode -WindowedSubsystems @('SystemMonitoring', 'CLIOrchestrator')
    #>
    param(
        [switch]$UseLegacyMode,
        [switch]$UseManifestMode,
        [switch]$SkipAutonomousAgent,
        [switch]$Debug,
        [string[]]$WindowedSubsystems = @(),
        [string]$WindowTitle = "Unity-Claude Subsystem"
    )
    
    Write-Host "Unity-Claude-Automation System Startup" -ForegroundColor Cyan
    Write-Host "=======================================" -ForegroundColor Cyan
    
    # Determine startup mode
    $useManifests = $false
    
    if ($UseLegacyMode -and $UseManifestMode) {
        throw "Cannot specify both -UseLegacyMode and -UseManifestMode"
    }
    
    if ($UseManifestMode) {
        $useManifests = $true
    } elseif ($UseLegacyMode) {
        $useManifests = $false
    } else {
        # Auto-detect
        $manifestsExist = (Test-Path ".\Manifests") -and 
                         (Get-ChildItem ".\Manifests" -Filter "*.manifest.psd1" | Measure-Object).Count -gt 0
        $useManifests = $manifestsExist
    }
    
    Write-Host "Mode: $(if ($useManifests) { 'Manifest-based' } else { 'Legacy' })" -ForegroundColor Green
    
    if ($WindowedSubsystems.Count -gt 0) {
        if (-not $useManifests) {
            Write-Warning "Windowed subsystems require manifest mode. Switching to manifest mode."
            $useManifests = $true
        }
        Write-Host "Windowed subsystems: $($WindowedSubsystems -join ', ')" -ForegroundColor Yellow
    }
    
    Write-Host ""
    
    if ($useManifests) {
        return Invoke-ManifestBasedSystemStartup -WindowedSubsystems $WindowedSubsystems -WindowTitle $WindowTitle -Debug:$Debug
    } else {
        return Invoke-LegacySystemStartup -SkipAutonomousAgent:$SkipAutonomousAgent -Debug:$Debug
    }
}

function Invoke-ManifestBasedSystemStartup {
    param(
        [string[]]$WindowedSubsystems = @(),
        [string]$WindowTitle = "Unity-Claude Subsystem",
        [switch]$Debug
    )
    
    Write-Host "Starting Unity-Claude-Automation using manifest-based configuration..." -ForegroundColor Green
    
    if (-not (Test-Path ".\Manifests")) {
        throw "Manifest directory not found: .\Manifests"
    }
    
    $manifests = Get-SubsystemManifests -Path ".\Manifests"
    if (-not $manifests -or $manifests.Count -eq 0) {
        throw "No valid manifests found in: .\Manifests"
    }
    
    Write-Host "Found $($manifests.Count) subsystem manifests" -ForegroundColor Cyan
    
    # Start each subsystem
    $startedSubsystems = @()
    $windowedCount = 0
    $backgroundCount = 0
    
    foreach ($manifest in $manifests) {
        try {
            $subsystemName = $manifest.Data.Name
            $useWindow = $subsystemName -in $WindowedSubsystems
            
            Write-Host "Starting $subsystemName $(if ($useWindow) { '(windowed)' } else { '(background)' })..." -ForegroundColor Yellow
            
            if ($manifest.Data.StartScript) {
                $startScriptPath = if ([System.IO.Path]::IsPathRooted($manifest.Data.StartScript)) {
                    $manifest.Data.StartScript
                } else {
                    $testPath = Join-Path $PWD.Path $manifest.Data.StartScript
                    if (Test-Path $testPath) {
                        $testPath
                    } else {
                        Join-Path $manifest.Directory $manifest.Data.StartScript
                    }
                }
                
                if (-not (Test-Path $startScriptPath)) {
                    Write-Host "  Start script not found: $startScriptPath" -ForegroundColor Red
                    continue
                }
                
                if ($useWindow) {
                    # Start in separate window
                    $windowCommand = @"
`$host.UI.RawUI.WindowTitle = '$WindowTitle - $subsystemName'
Set-Location -Path '$PWD'
Write-Host 'Starting $subsystemName...' -ForegroundColor Green
try {
    & '$startScriptPath'
} catch {
    Write-Host 'Error starting ${subsystemName}:' `$_.Exception.Message -ForegroundColor Red
    Read-Host 'Press Enter to close window'
}
"@
                    
                    $startParams = @{
                        FilePath = "C:\Program Files\PowerShell\7\pwsh.exe"
                        ArgumentList = "-ExecutionPolicy Bypass -NoExit -Command `"$windowCommand`""
                        WindowStyle = "Normal"
                        PassThru = $true
                    }
                    
                    $process = Start-Process @startParams
                    Write-Host "  Started in window (PID: $($process.Id))" -ForegroundColor Green
                    $windowedCount++
                    
                } else {
                    # Background process
                    $startParams = @{
                        FilePath = "C:\Program Files\PowerShell\7\pwsh.exe"
                        ArgumentList = "-ExecutionPolicy Bypass -File `"$startScriptPath`""
                        WindowStyle = "Hidden"
                        PassThru = $true
                    }
                    
                    $process = Start-Process @startParams
                    Write-Host "  Started as background process (PID: $($process.Id))" -ForegroundColor Green
                    $backgroundCount++
                }
                
                $startedSubsystems += $subsystemName
            }
            
        } catch {
            Write-Host "  Failed to start $($manifest.Data.Name): $_" -ForegroundColor Red
        }
        
        Start-Sleep -Milliseconds 500
    }
    
    # Summary
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Unity-Claude-Automation Startup Complete" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Total subsystems: $($manifests.Count)" -ForegroundColor White
    Write-Host "Started successfully: $($startedSubsystems.Count)" -ForegroundColor Green
    Write-Host "Windowed processes: $windowedCount" -ForegroundColor Yellow
    Write-Host "Background processes: $backgroundCount" -ForegroundColor Gray
    Write-Host ""
    
    if ($windowedCount -gt 0) {
        Write-Host "IMPORTANT: Windowed subsystems are running in separate PowerShell windows." -ForegroundColor Yellow
        Write-Host "Do not close these windows unless you want to stop those subsystems." -ForegroundColor Yellow
    }
    
    return @{
        Success = $true
        StartedSubsystems = $startedSubsystems
        WindowedCount = $windowedCount
        BackgroundCount = $backgroundCount
        TotalSubsystems = $manifests.Count
    }
}

function Invoke-LegacySystemStartup {
    param(
        [switch]$SkipAutonomousAgent,
        [switch]$Debug
    )
    
    Write-Host "Starting subsystems using legacy hardcoded configuration..." -ForegroundColor Yellow
    Write-Host "WARNING: Legacy mode does not support windowed subsystems" -ForegroundColor Yellow
    
    # Basic legacy startup - just start SystemStatus
    if (Test-Path ".\Start-SystemStatusMonitoring.ps1") {
        Write-Host "Starting SystemStatus monitoring..." -ForegroundColor Cyan
        $process = Start-Process -FilePath "C:\Program Files\PowerShell\7\pwsh.exe" -ArgumentList "-ExecutionPolicy Bypass -File `".\Start-SystemStatusMonitoring.ps1`"" -WindowStyle Hidden -PassThru
        Write-Host "  Started SystemStatus (PID: $($process.Id))" -ForegroundColor Green
    }
    
    return @{
        Success = $true
        Message = "Legacy startup completed"
    }
}