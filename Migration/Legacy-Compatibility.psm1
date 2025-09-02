# Legacy-Compatibility.psm1
# Backward compatibility layer for Unity-Claude-Automation Bootstrap Orchestrator migration
# Date: 2025-08-22
# Author: Claude
# Phase 3 Day 2: Migration and Backward Compatibility - Hour 3-4

# Global compatibility settings
$script:LegacyModeEnabled = $false
$script:DeprecationWarningsEnabled = $true
$script:MigrationDetectionEnabled = $true

function Enable-LegacyMode {
    <#
    .SYNOPSIS
    Enables legacy mode for backward compatibility during migration
    
    .DESCRIPTION
    Switches the system to use legacy hardcoded subsystem management instead of
    the new manifest-based Bootstrap Orchestrator system. This is intended as
    a transitional measure during migration.
    
    .PARAMETER SuppressWarnings
    Suppress deprecation warnings for this session
    
    .EXAMPLE
    Enable-LegacyMode
    Enables legacy mode with deprecation warnings
    
    .EXAMPLE
    Enable-LegacyMode -SuppressWarnings
    Enables legacy mode without showing deprecation warnings
    #>
    param(
        [switch]$SuppressWarnings
    )
    
    $script:LegacyModeEnabled = $true
    $script:DeprecationWarningsEnabled = -not $SuppressWarnings
    
    if ($script:DeprecationWarningsEnabled) {
        Write-Warning @"
LEGACY MODE ENABLED - Deprecation Notice

You are running Unity-Claude-Automation in legacy compatibility mode.
This mode is provided for backward compatibility during migration to the
new Bootstrap Orchestrator manifest-based system.

IMPORTANT:
- Legacy mode will be removed in a future version
- New features may not be available in legacy mode
- Please migrate to manifest-based configuration soon

To suppress this warning, use: Enable-LegacyMode -SuppressWarnings
To migrate to the new system, run: .\Migration\Migrate-ToManifestSystem.ps1

For migration guidance, see: .\Migration\MIGRATION_GUIDE.md
"@
    }
    
    Write-Host "Legacy mode enabled - using hardcoded subsystem configuration" -ForegroundColor Yellow
}

function Disable-LegacyMode {
    <#
    .SYNOPSIS
    Disables legacy mode and enables manifest-based Bootstrap Orchestrator
    
    .DESCRIPTION
    Switches the system to use the new manifest-based Bootstrap Orchestrator
    for subsystem management. This is the recommended modern approach.
    
    .EXAMPLE
    Disable-LegacyMode
    Enables manifest-based subsystem management
    #>
    
    $script:LegacyModeEnabled = $false
    Write-Host "Legacy mode disabled - using manifest-based Bootstrap Orchestrator" -ForegroundColor Green
}

function Test-LegacyMode {
    <#
    .SYNOPSIS
    Tests whether legacy mode is currently enabled
    
    .DESCRIPTION
    Returns true if legacy mode is enabled, false if using manifest-based system
    
    .OUTPUTS
    Boolean indicating legacy mode status
    
    .EXAMPLE
    if (Test-LegacyMode) { "Running in legacy mode" }
    #>
    return $script:LegacyModeEnabled
}

function Show-DeprecationWarning {
    <#
    .SYNOPSIS
    Shows a deprecation warning for legacy functionality
    
    .DESCRIPTION
    Displays a deprecation warning when legacy functionality is used,
    helping users understand migration requirements
    
    .PARAMETER FunctionName
    Name of the deprecated function being called
    
    .PARAMETER Replacement
    Recommended replacement for the deprecated functionality
    
    .PARAMETER SuppressWarnings
    Skip showing the warning for this call
    
    .EXAMPLE
    Show-DeprecationWarning -FunctionName "Start-LegacyMonitoring" -Replacement "Start-ManifestBasedMonitoring"
    #>
    param(
        [string]$FunctionName,
        [string]$Replacement = "",
        [switch]$SuppressWarnings
    )
    
    if (-not $script:DeprecationWarningsEnabled -or $SuppressWarnings) {
        return
    }
    
    $message = "DEPRECATION WARNING: $FunctionName is deprecated and will be removed in a future version."
    if ($Replacement) {
        $message += " Please use $Replacement instead."
    }
    $message += " Run migration script to update: .\Migration\Migrate-ToManifestSystem.ps1"
    
    Write-Warning $message
}

function Invoke-LegacySystemStartup {
    <#
    .SYNOPSIS
    Starts subsystems using legacy hardcoded configuration
    
    .DESCRIPTION
    Implements the original hardcoded subsystem startup logic for backward
    compatibility. This maintains the existing behavior during migration.
    
    .PARAMETER SkipAutonomousAgent
    Skip starting the AutonomousAgent subsystem
    
    .PARAMETER Debug
    Enable debug output
    
    .EXAMPLE
    Invoke-LegacySystemStartup
    Starts all subsystems using legacy configuration
    #>
    param(
        [switch]$SkipAutonomousAgent,
        [switch]$Debug
    )
    
    Show-DeprecationWarning -FunctionName "Invoke-LegacySystemStartup" -Replacement "Start-ManifestBasedSystem"
    
    Write-Host "Starting subsystems using legacy hardcoded configuration..." -ForegroundColor Yellow
    
    try {
        # Step 1: Start SystemStatus monitoring (base subsystem)
        Write-Host "Step 1: Starting SystemStatus monitoring..." -ForegroundColor Cyan
        
        if (Test-Path ".\Start-SystemStatusMonitoring-Enhanced.ps1") {
            $monitoringJob = Start-Job -Name "SystemStatusMonitoring" -ScriptBlock {
                param($ScriptPath)
                & $ScriptPath -EnableHeartbeat -EnableFileWatcher
            } -ArgumentList (Resolve-Path ".\Start-SystemStatusMonitoring-Enhanced.ps1").Path
            
            if ($monitoringJob) {
                Write-Host "  SystemStatus monitoring started (Job ID: $($monitoringJob.Id))" -ForegroundColor Green
            }
        } else {
            Write-Warning "SystemStatus monitoring script not found"
        }
        
        # Step 2: Start AutonomousAgent (if not skipped)
        if (-not $SkipAutonomousAgent) {
            Write-Host "Step 2: Starting AutonomousAgent..." -ForegroundColor Cyan
            
            if (Test-Path ".\Start-AutonomousMonitoring-Fixed.ps1") {
                # Wait a moment for SystemStatus to initialize
                Start-Sleep -Seconds 3
                
                $agentJob = Start-Job -Name "AutonomousAgent" -ScriptBlock {
                    param($ScriptPath)
                    & $ScriptPath
                } -ArgumentList (Resolve-Path ".\Start-AutonomousMonitoring-Fixed.ps1").Path
                
                if ($agentJob) {
                    Write-Host "  AutonomousAgent started (Job ID: $($agentJob.Id))" -ForegroundColor Green
                }
            } else {
                Write-Warning "AutonomousAgent script not found"
            }
        } else {
            Write-Host "Step 2: Skipping AutonomousAgent (as requested)" -ForegroundColor Yellow
        }
        
        # Step 3: Display status
        Write-Host "Step 3: Legacy system startup complete" -ForegroundColor Green
        $jobs = Get-Job | Where-Object { $_.Name -match "SystemStatus|AutonomousAgent" }
        if ($jobs) {
            Write-Host "Active subsystem jobs:" -ForegroundColor Cyan
            $jobs | ForEach-Object {
                Write-Host "  - $($_.Name): $($_.State)" -ForegroundColor White
            }
        }
        
        return @{
            Success = $true
            Message = "Legacy system startup completed successfully"
            Jobs = $jobs
        }
        
    } catch {
        Write-Error "Legacy system startup failed: $($_.Exception.Message)"
        return @{
            Success = $false
            Message = "Legacy system startup failed: $($_.Exception.Message)"
            Jobs = $null
        }
    }
}

function Start-SubsystemInWindow {
    <#
    .SYNOPSIS
    Starts a subsystem in a separate PowerShell window
    
    .PARAMETER SubsystemName
    Name of the subsystem
    
    .PARAMETER StartScriptPath
    Path to the startup script
    
    .PARAMETER WorkingDirectory
    Working directory for the subsystem
    
    .PARAMETER WindowTitle
    Title for the PowerShell window
    #>
    param(
        [string]$SubsystemName,
        [string]$StartScriptPath,
        [string]$WorkingDirectory = $PWD.Path,
        [string]$WindowTitle = "Unity-Claude Subsystem"
    )
    
    Write-Host "  Starting $SubsystemName in separate PowerShell window..." -ForegroundColor Cyan
    
    # Create the command to run in the new window
    $windowCommand = @"
`$host.UI.RawUI.WindowTitle = "$WindowTitle - $SubsystemName"
Set-Location -Path "$WorkingDirectory"
`$env:PSModulePath = "$WorkingDirectory\Modules;" + `$env:PSModulePath
Write-Host '============================================' -ForegroundColor Cyan
Write-Host "Unity-Claude-Automation: $SubsystemName" -ForegroundColor Green
Write-Host '============================================' -ForegroundColor Cyan
Write-Host 'Working Directory:' `$PWD.Path -ForegroundColor Yellow
Write-Host "Script Path: $StartScriptPath" -ForegroundColor Yellow
Write-Host 'Starting...' -ForegroundColor Green
Write-Host ''
try {
    & "$StartScriptPath"
} catch {
    Write-Host ''
    Write-Host "ERROR starting ${SubsystemName}:" -ForegroundColor Red
    Write-Host `$_.Exception.Message -ForegroundColor Red
    Write-Host ''
    Read-Host 'Press Enter to close window'
}
"@
    
    # Start new PowerShell window
    $startParams = @{
        FilePath = "C:\Program Files\PowerShell\7\pwsh.exe"
        ArgumentList = "-ExecutionPolicy Bypass -NoExit -Command `"$windowCommand`""
        WindowStyle = "Normal"
        PassThru = $true
    }
    
    $process = Start-Process @startParams
    Write-Host "    Started in window (PID: $($process.Id))" -ForegroundColor Green
    
    return $process
}

function Invoke-ManifestBasedSystemStartup {
    <#
    .SYNOPSIS
    Starts subsystems using manifest-based Bootstrap Orchestrator
    
    .DESCRIPTION
    Uses the new manifest-based configuration system to start subsystems
    with proper dependency resolution and resource management
    
    .PARAMETER ManifestPath
    Path to directory containing subsystem manifests
    
    .PARAMETER Debug
    Enable debug output
    
    .PARAMETER WindowedSubsystems
    Array of subsystem names to run in separate PowerShell windows
    
    .PARAMETER WindowTitle
    Base title for windowed subsystem windows
    
    .EXAMPLE
    Invoke-ManifestBasedSystemStartup
    Starts subsystems using manifest-based configuration
    
    .EXAMPLE
    Invoke-ManifestBasedSystemStartup -WindowedSubsystems @('SystemMonitoring', 'CLIOrchestrator')
    Start with specific subsystems in windows
    #>
    param(
        [string]$ManifestPath = ".\Manifests",
        [switch]$Debug,
        [string[]]$WindowedSubsystems = @(),
        [string]$WindowTitle = "Unity-Claude Subsystem"
    )
    
    Write-Host "Starting subsystems using manifest-based Bootstrap Orchestrator..." -ForegroundColor Green
    
    try {
        # Import the SystemStatus module for manifest functionality
        $systemStatusModule = ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psm1"
        if (Test-Path $systemStatusModule) {
            Import-Module $systemStatusModule -Force
            Write-Host "Loaded SystemStatus module with manifest support" -ForegroundColor Cyan
        } else {
            throw "SystemStatus module not found: $systemStatusModule"
        }
        
        # Discover manifests
        if (-not (Test-Path $ManifestPath)) {
            throw "Manifest directory not found: $ManifestPath"
        }
        
        $manifests = Get-SubsystemManifests -Path $ManifestPath
        if (-not $manifests -or $manifests.Count -eq 0) {
            throw "No valid manifests found in: $ManifestPath"
        }
        
        Write-Host "Found $($manifests.Count) subsystem manifests" -ForegroundColor Cyan
        
        # Get startup order with dependency resolution
        $startupOrderResult = Get-SubsystemStartupOrder -Manifests $manifests
        Write-Host "Calculated dependency-resolved startup order" -ForegroundColor Cyan
        
        # Start subsystems in order
        $startedSubsystems = @()
        
        foreach ($subsystemName in $startupOrderResult.StartupOrder) {
            Write-Host "Starting subsystem: $subsystemName" -ForegroundColor Yellow
            
            # Find the corresponding manifest
            $manifest = $manifests | Where-Object { $_.Name -eq $subsystemName } | Select-Object -First 1
            
            if ($manifest) {
                # Check if already running (if Test-SubsystemRunning is available)
                if (Get-Command Test-SubsystemRunning -ErrorAction SilentlyContinue) {
                    $mutexName = if ($manifest.Data.MutexName) { $manifest.Data.MutexName } else { $null }
                    if (Test-SubsystemRunning -SubsystemName $subsystemName -MutexName $mutexName) {
                        Write-Host "  ${subsystemName}: Already running (detected)" -ForegroundColor Yellow
                        $startedSubsystems += $subsystemName
                        continue
                    }
                }
                
                # Check if this subsystem should run in a window
                $useWindow = $subsystemName -in $WindowedSubsystems
                if ($useWindow) {
                    Write-Host "  ${subsystemName}: Will run in separate window" -ForegroundColor Cyan
                }
                
                # Use custom registration for windowed subsystems
                if ($useWindow -and $manifest.Data.StartScript) {
                    try {
                        # Handle mutex if configured
                        $mutexAcquired = $false
                        if ($manifest.Data.UseMutex -or $manifest.Data.MutexName) {
                            $mutexName = if ($manifest.Data.MutexName) { 
                                $manifest.Data.MutexName 
                            } else { 
                                "Global\UnityClaudeSubsystem_$subsystemName" 
                            }
                            
                            $mutexResult = New-SubsystemMutex -SubsystemName $subsystemName -MutexName $mutexName -TimeoutMs 5000
                            
                            if ($mutexResult.Acquired) {
                                $mutexAcquired = $true
                                if (-not $script:SubsystemMutexes) {
                                    $script:SubsystemMutexes = @{}
                                }
                                $script:SubsystemMutexes[$subsystemName] = $mutexResult.Mutex
                            } else {
                                Write-Host "  ${subsystemName}: Already running (skipped)" -ForegroundColor Yellow
                                $startedSubsystems += $subsystemName
                                continue
                            }
                        }
                        
                        # Get script path
                        $startScriptPath = if ([System.IO.Path]::IsPathRooted($manifest.Data.StartScript)) {
                            $manifest.Data.StartScript
                        } else {
                            $projectRoot = Split-Path $manifest.Directory -Parent
                            $testPath = Join-Path $projectRoot $manifest.Data.StartScript
                            if (Test-Path $testPath) {
                                $testPath
                            } else {
                                Join-Path $manifest.Directory $manifest.Data.StartScript
                            }
                        }
                        
                        if (-not (Test-Path $startScriptPath)) {
                            throw "Start script not found: $startScriptPath"
                        }
                        
                        # Start in window
                        $workingDir = if ($manifest.Data.WorkingDirectory) { 
                            $manifest.Data.WorkingDirectory 
                        } else { 
                            $PWD.Path 
                        }
                        
                        $process = Start-SubsystemInWindow -SubsystemName $subsystemName -StartScriptPath $startScriptPath -WorkingDirectory $workingDir -WindowTitle $WindowTitle
                        
                        # Register with system
                        $modulePath = if ($manifest.Data.StartScript) {
                            $manifest.Data.StartScript
                        } else {
                            ".\Modules\Unity-Claude-$subsystemName\Unity-Claude-$subsystemName.psm1"
                        }
                        
                        Register-Subsystem -SubsystemName $subsystemName -ModulePath $modulePath -ProcessId $process.Id
                        
                        $startedSubsystems += $subsystemName
                        Write-Host "  ${subsystemName}: Started in window successfully" -ForegroundColor Green
                        
                    } catch {
                        Write-Warning "  ${subsystemName}: Failed to start in window - $($_.Exception.Message)"
                        
                        # Clean up mutex if acquired
                        if ($mutexAcquired) {
                            Remove-SubsystemMutex -SubsystemName $subsystemName
                        }
                    }
                } else {
                    # Use standard registration
                    $result = Register-SubsystemFromManifest -ManifestPath $manifest.Path -Force
                    if ($result) {
                        if ($result.Success) {
                            $startedSubsystems += $subsystemName
                            Write-Host "  ${subsystemName}: Started successfully" -ForegroundColor Green
                        } elseif ($result.Skipped) {
                            Write-Host "  ${subsystemName}: Already running (skipped)" -ForegroundColor Yellow
                            $startedSubsystems += $subsystemName
                        } else {
                            Write-Warning "  ${subsystemName}: Failed to start - $($result.Message)"
                        }
                    } else {
                        Write-Warning "  ${subsystemName}: Failed to start"
                    }
                }
            } else {
                Write-Warning "  ${subsystemName}: Manifest not found"
            }
        }
        
        # Count windowed vs background subsystems
        $windowedCount = ($WindowedSubsystems | Where-Object { $_ -in $startedSubsystems }).Count
        $backgroundCount = $startedSubsystems.Count - $windowedCount
        
        # Display summary
        if ($WindowedSubsystems.Count -gt 0) {
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Cyan
            Write-Host "Unity-Claude-Automation Startup Summary" -ForegroundColor Green
            Write-Host "========================================" -ForegroundColor Cyan
            Write-Host "Total subsystems started: $($startedSubsystems.Count)/$($manifests.Count)" -ForegroundColor White
            Write-Host "Windowed processes: $windowedCount" -ForegroundColor Yellow
            Write-Host "Background processes: $backgroundCount" -ForegroundColor Gray
            
            if ($windowedCount -gt 0) {
                Write-Host ""
                Write-Host "WINDOWED SUBSYSTEMS:" -ForegroundColor Yellow
                foreach ($subsystem in $WindowedSubsystems) {
                    if ($subsystem -in $startedSubsystems) {
                        Write-Host "  - $subsystem (running in separate window)" -ForegroundColor Green
                    }
                }
                Write-Host ""
                Write-Host "IMPORTANT: Do not close the PowerShell windows unless you want" -ForegroundColor Yellow
                Write-Host "to stop those subsystems. Each window runs independently." -ForegroundColor Yellow
            }
            Write-Host ""
        }
        
        return @{
            Success = $true
            Message = if ($WindowedSubsystems.Count -gt 0) { 
                "Manifest-based system startup completed with $windowedCount windowed subsystems" 
            } else { 
                "Manifest-based system startup completed" 
            }
            StartedSubsystems = $startedSubsystems
            TotalSubsystems = $manifests.Count
            WindowedSubsystems = ($WindowedSubsystems | Where-Object { $_ -in $startedSubsystems })
            BackgroundSubsystems = ($startedSubsystems | Where-Object { $_ -notin $WindowedSubsystems })
        }
        
    } catch {
        Write-Error "Manifest-based system startup failed: $($_.Exception.Message)"
        return @{
            Success = $false
            Message = "Manifest-based system startup failed: $($_.Exception.Message)"
            StartedSubsystems = @()
            TotalSubsystems = 0
        }
    }
}

function Start-UnityClaudeSystem {
    <#
    .SYNOPSIS
    Main entry point that chooses between legacy and manifest-based startup
    
    .DESCRIPTION
    Automatically detects whether to use legacy mode or manifest-based mode
    based on configuration and available manifests
    
    .PARAMETER UseLegacyMode
    Force use of legacy hardcoded configuration
    
    .PARAMETER UseManifestMode
    Force use of manifest-based Bootstrap Orchestrator
    
    .PARAMETER SkipAutonomousAgent
    Skip starting the AutonomousAgent subsystem (legacy mode only)
    
    .PARAMETER Debug
    Enable debug output
    
    .PARAMETER WindowedSubsystems
    Array of subsystem names to run in separate PowerShell windows instead of background processes
    
    .PARAMETER WindowTitle
    Base title for windowed subsystem windows
    
    .EXAMPLE
    Start-UnityClaudeSystem
    Automatically choose best startup mode
    
    .EXAMPLE
    Start-UnityClaudeSystem -UseLegacyMode
    Force legacy mode startup
    
    .EXAMPLE
    Start-UnityClaudeSystem -UseManifestMode
    Force manifest-based startup
    
    .EXAMPLE
    Start-UnityClaudeSystem -UseManifestMode -WindowedSubsystems @('SystemMonitoring', 'CLIOrchestrator')
    Start with SystemMonitoring and CLIOrchestrator in separate windows
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
    
    if ($UseLegacyMode) {
        Enable-LegacyMode
        $useManifests = $false
        Write-Host "Mode: Legacy (forced by parameter)" -ForegroundColor Yellow
    } elseif ($UseManifestMode) {
        Disable-LegacyMode
        $useManifests = $true
        Write-Host "Mode: Manifest-based (forced by parameter)" -ForegroundColor Green
    } else {
        # Auto-detect best mode
        $manifestsExist = (Test-Path ".\Manifests") -and 
                         (Get-ChildItem ".\Manifests" -Filter "*.manifest.psd1" | Measure-Object).Count -gt 0
        
        if ($manifestsExist) {
            # Migration has been completed, use manifest mode
            Disable-LegacyMode
            $useManifests = $true
            Write-Host "Mode: Manifest-based (auto-detected)" -ForegroundColor Green
        } else {
            # No manifests found, use legacy mode
            Enable-LegacyMode
            $useManifests = $false
            Write-Host "Mode: Legacy (auto-detected - no manifests found)" -ForegroundColor Yellow
            
            if ($script:MigrationDetectionEnabled) {
                Write-Host ""
                Write-Host "MIGRATION RECOMMENDATION:" -ForegroundColor Cyan
                Write-Host "No manifests detected. To upgrade to the manifest-based system:" -ForegroundColor White
                Write-Host "  1. Run: .\Migration\Migrate-ToManifestSystem.ps1" -ForegroundColor White
                Write-Host "  2. Test: .\Tests\Test-ManifestSystem.ps1" -ForegroundColor White
                Write-Host "  3. Restart with: Start-UnityClaudeSystem -UseManifestMode" -ForegroundColor White
                Write-Host ""
            }
        }
    }
    
    # Execute startup based on selected mode
    if ($useManifests) {
        if ($WindowedSubsystems.Count -gt 0) {
            return Invoke-ManifestBasedSystemStartup -Debug:$Debug -WindowedSubsystems $WindowedSubsystems -WindowTitle $WindowTitle
        } else {
            return Invoke-ManifestBasedSystemStartup -Debug:$Debug
        }
    } else {
        if ($WindowedSubsystems.Count -gt 0) {
            Write-Warning "Windowed subsystems are not supported in legacy mode. Use -UseManifestMode for windowed functionality."
        }
        return Invoke-LegacySystemStartup -SkipAutonomousAgent:$SkipAutonomousAgent -Debug:$Debug
    }
}

function Test-MigrationStatus {
    <#
    .SYNOPSIS
    Tests the current migration status of the system
    
    .DESCRIPTION
    Analyzes the current state of the system to determine migration progress
    and provide recommendations
    
    .OUTPUTS
    Hashtable with migration status information
    
    .EXAMPLE
    $status = Test-MigrationStatus
    Write-Host "Migration Status: $($status.Status)"
    #>
    
    $status = @{
        Status = "Unknown"
        LegacyConfigExists = $false
        ManifestsExist = $false
        ManifestCount = 0
        RecommendedAction = ""
        Details = @()
    }
    
    # Check for legacy configuration
    $legacyFiles = @(
        "Start-SystemStatusMonitoring-Enhanced.ps1",
        "Start-UnifiedSystem-Complete.ps1",
        "Start-AutonomousMonitoring-Fixed.ps1"
    )
    
    $existingLegacyFiles = $legacyFiles | Where-Object { Test-Path $_ }
    $status.LegacyConfigExists = $existingLegacyFiles.Count -gt 0
    
    if ($status.LegacyConfigExists) {
        $status.Details += "Found $($existingLegacyFiles.Count) legacy configuration files"
    }
    
    # Check for manifests
    if (Test-Path ".\Manifests") {
        $manifestFiles = Get-ChildItem ".\Manifests" -Filter "*.manifest.psd1"
        $status.ManifestsExist = $manifestFiles.Count -gt 0
        $status.ManifestCount = $manifestFiles.Count
        
        if ($status.ManifestsExist) {
            $status.Details += "Found $($status.ManifestCount) manifest files"
        }
    }
    
    # Determine status and recommendations
    if (-not $status.LegacyConfigExists -and -not $status.ManifestsExist) {
        $status.Status = "No Configuration"
        $status.RecommendedAction = "Set up initial configuration"
    } elseif ($status.LegacyConfigExists -and -not $status.ManifestsExist) {
        $status.Status = "Pre-Migration"
        $status.RecommendedAction = "Run migration script: .\Migration\Migrate-ToManifestSystem.ps1"
    } elseif ($status.LegacyConfigExists -and $status.ManifestsExist) {
        $status.Status = "Migration In Progress"
        $status.RecommendedAction = "Test manifest system, then remove legacy files"
    } elseif (-not $status.LegacyConfigExists -and $status.ManifestsExist) {
        $status.Status = "Migration Complete"
        $status.RecommendedAction = "Use manifest-based system exclusively"
    }
    
    return $status
}

# Export functions for use by other scripts
Export-ModuleMember -Function @(
    'Enable-LegacyMode',
    'Disable-LegacyMode', 
    'Test-LegacyMode',
    'Show-DeprecationWarning',
    'Invoke-LegacySystemStartup',
    'Invoke-ManifestBasedSystemStartup', 
    'Start-UnityClaudeSystem',
    'Test-MigrationStatus'
)