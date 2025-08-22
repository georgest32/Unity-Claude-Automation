# Start-UnifiedSystem-WithCompatibility.ps1
# Unified system startup with Bootstrap Orchestrator compatibility layer
# Date: 2025-08-22
# Phase 3 Day 2: Migration and Backward Compatibility - Hour 3-4

param(
    [switch]$SkipAutonomousAgent = $false,
    [switch]$UseLegacyMode = $false,        # NEW: Force legacy mode
    [switch]$UseManifestMode = $false,      # NEW: Force manifest-based mode
    [switch]$RunMigration = $false,         # NEW: Run migration before startup
    [switch]$Debug = $false
)

$ErrorActionPreference = "Continue"

# Change to script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ($scriptDir) {
    Set-Location $scriptDir
}

# Load compatibility layer
try {
    Import-Module ".\Migration\Legacy-Compatibility.psm1" -Force
    $compatibilityLoaded = $true
    Write-Host "Loaded backward compatibility layer" -ForegroundColor Cyan
} catch {
    Write-Warning "Could not load compatibility layer: $($_.Exception.Message)"
    Write-Warning "Falling back to legacy mode only"
    $compatibilityLoaded = $false
    $UseLegacyMode = $true
}

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Unity-Claude Unified System Startup (WITH COMPATIBILITY)" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Starting at: $(Get-Date)" -ForegroundColor Cyan
Write-Host ""

# Show migration status and provide guidance
if ($compatibilityLoaded) {
    Write-Host "=== MIGRATION STATUS ===" -ForegroundColor Yellow
    $migrationStatus = Test-MigrationStatus
    Write-Host "Current Status: $($migrationStatus.Status)" -ForegroundColor White
    
    if ($migrationStatus.Details) {
        $migrationStatus.Details | ForEach-Object {
            Write-Host "  - $_" -ForegroundColor Gray
        }
    }
    
    if ($migrationStatus.RecommendedAction) {
        Write-Host "Recommended Action: $($migrationStatus.RecommendedAction)" -ForegroundColor Cyan
    }
    Write-Host ""
    
    # Offer to run migration if needed
    if ($migrationStatus.Status -eq "Pre-Migration" -and -not $RunMigration -and -not $UseLegacyMode) {
        Write-Host "MIGRATION AVAILABLE:" -ForegroundColor Green
        Write-Host "  You can upgrade to the new manifest-based system." -ForegroundColor White
        Write-Host "  This provides better dependency management and resource control." -ForegroundColor White
        Write-Host "" -ForegroundColor White
        Write-Host "Options:" -ForegroundColor Yellow
        Write-Host "  1. Run migration now: Add -RunMigration parameter" -ForegroundColor White
        Write-Host "  2. Use legacy mode: Add -UseLegacyMode parameter" -ForegroundColor White
        Write-Host "  3. Force manifest mode: Add -UseManifestMode parameter" -ForegroundColor White
        Write-Host ""
        
        if (-not $UseLegacyMode -and -not $UseManifestMode) {
            $choice = Read-Host "Run migration now? (Y/N) [Default: N]"
            if ($choice -eq "Y" -or $choice -eq "y") {
                $RunMigration = $true
            }
        }
    }
}

# Run migration if requested
if ($RunMigration) {
    Write-Host "=== RUNNING MIGRATION ===" -ForegroundColor Green
    
    $migrationScript = ".\Migration\Migrate-ToManifestSystem.ps1"
    if (Test-Path $migrationScript) {
        Write-Host "Executing migration script..." -ForegroundColor Cyan
        
        try {
            $migrationResult = & $migrationScript -Verbose
            
            if ($migrationResult.Success) {
                Write-Host "Migration completed successfully!" -ForegroundColor Green
                Write-Host "Migration Report: $($migrationResult.ReportPath)" -ForegroundColor Cyan
                Write-Host ""
                
                # Update mode selection based on migration results
                if (-not $UseLegacyMode) {
                    $UseManifestMode = $true
                    Write-Host "Switching to manifest-based mode for startup" -ForegroundColor Green
                }
            } else {
                Write-Warning "Migration completed with issues"
                Write-Host "Check migration log: $($migrationResult.LogPath)" -ForegroundColor Yellow
                
                # Ask user what to do
                $choice = Read-Host "Continue with legacy mode? (Y/N) [Default: Y]"
                if ($choice -ne "N" -and $choice -ne "n") {
                    $UseLegacyMode = $true
                } else {
                    Write-Host "Aborting startup" -ForegroundColor Red
                    exit 1
                }
            }
        } catch {
            Write-Error "Migration failed: $($_.Exception.Message)"
            $choice = Read-Host "Continue with legacy mode? (Y/N) [Default: Y]"
            if ($choice -ne "N" -and $choice -ne "n") {
                $UseLegacyMode = $true
            } else {
                Write-Host "Aborting startup" -ForegroundColor Red
                exit 1
            }
        }
    } else {
        Write-Warning "Migration script not found: $migrationScript"
        $UseLegacyMode = $true
    }
    
    Write-Host ""
}

# Determine startup mode
Write-Host "=== STARTUP MODE SELECTION ===" -ForegroundColor Yellow

if ($UseLegacyMode -and $UseManifestMode) {
    Write-Error "Cannot specify both -UseLegacyMode and -UseManifestMode"
    exit 1
}

$useManifestSystem = $false

if ($UseLegacyMode) {
    Write-Host "Mode: Legacy (forced by parameter)" -ForegroundColor Yellow
    $useManifestSystem = $false
} elseif ($UseManifestMode) {
    Write-Host "Mode: Manifest-based (forced by parameter)" -ForegroundColor Green
    $useManifestSystem = $true
} else {
    # Auto-detect best mode
    if ($compatibilityLoaded) {
        $migrationStatus = Test-MigrationStatus
        
        if ($migrationStatus.ManifestsExist) {
            Write-Host "Mode: Manifest-based (auto-detected)" -ForegroundColor Green
            $useManifestSystem = $true
        } else {
            Write-Host "Mode: Legacy (auto-detected - no manifests found)" -ForegroundColor Yellow
            $useManifestSystem = $false
        }
    } else {
        Write-Host "Mode: Legacy (compatibility layer failed to load)" -ForegroundColor Yellow
        $useManifestSystem = $false
    }
}

Write-Host ""

# Execute startup using selected system
if ($useManifestSystem -and $compatibilityLoaded) {
    Write-Host "=== MANIFEST-BASED SYSTEM STARTUP ===" -ForegroundColor Green
    
    try {
        $result = Start-UnityClaudeSystem -UseManifestMode -Debug:$Debug
        
        if ($result.Success) {
            Write-Host "Manifest-based system startup completed successfully!" -ForegroundColor Green
            Write-Host "Started subsystems: $($result.StartedSubsystems -join ', ')" -ForegroundColor Cyan
            Write-Host "Total subsystems: $($result.TotalSubsystems)" -ForegroundColor Cyan
        } else {
            Write-Warning "Manifest-based startup failed: $($result.Message)"
            Write-Host "Falling back to legacy mode..." -ForegroundColor Yellow
            $useManifestSystem = $false
        }
    } catch {
        Write-Error "Manifest-based startup error: $($_.Exception.Message)"
        Write-Host "Falling back to legacy mode..." -ForegroundColor Yellow
        $useManifestSystem = $false
    }
}

if (-not $useManifestSystem) {
    Write-Host "=== LEGACY SYSTEM STARTUP ===" -ForegroundColor Yellow
    
    # Show deprecation warning for legacy mode
    if ($compatibilityLoaded) {
        Show-DeprecationWarning -FunctionName "Legacy System Startup" -Replacement "Manifest-based Bootstrap Orchestrator"
    }
    
    # Original legacy startup logic (simplified)
    try {
        Write-Host "Step 1: Finding Claude Code CLI..." -ForegroundColor Yellow
        
        $claudePID = $null
        try {
            if (Test-Path ".\Get-ClaudeCodePID.ps1") {
                $claudePID = & ".\Get-ClaudeCodePID.ps1"
                if ($claudePID) {
                    Write-Host "  Claude Code CLI found: PID $claudePID" -ForegroundColor Green
                } else {
                    Write-Host "  Claude Code CLI not found (will continue anyway)" -ForegroundColor Yellow
                }
            }
        } catch {
            Write-Host "  Error finding Claude Code CLI: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        
        Write-Host ""
        Write-Host "Step 2: Starting SystemStatus monitoring..." -ForegroundColor Yellow
        
        # Option to sign scripts first
        $signScripts = Read-Host "Sign all scripts to avoid execution policy issues? (Y/N) [Default: N]"
        if ($signScripts -eq "Y") {
            Write-Host "  Signing all PowerShell scripts..." -ForegroundColor Cyan
            if (Test-Path ".\Sign-PowerShellScripts.ps1") {
                & .\Sign-PowerShellScripts.ps1
                Write-Host "  Scripts signed successfully" -ForegroundColor Green
            }
        }
        
        # Use compatibility-enhanced monitoring script if available
        $monitoringScript = ".\Start-SystemStatusMonitoring-Enhanced-WithCompatibility.ps1"
        if (-not (Test-Path $monitoringScript)) {
            $monitoringScript = ".\Start-SystemStatusMonitoring-Enhanced.ps1"
        }
        
        if (Test-Path $monitoringScript) {
            Write-Host "  Starting monitoring using: $monitoringScript" -ForegroundColor Cyan
            
            $monitoringJob = Start-Job -Name "SystemStatusMonitoring" -ScriptBlock {
                param($ScriptPath, $UseLegacy)
                if ($UseLegacy) {
                    & $ScriptPath -UseLegacyMode -EnableHeartbeat -EnableFileWatcher
                } else {
                    & $ScriptPath -EnableHeartbeat -EnableFileWatcher
                }
            } -ArgumentList $monitoringScript, $UseLegacyMode
            
            if ($monitoringJob) {
                Write-Host "  SystemStatus monitoring started (Job ID: $($monitoringJob.Id))" -ForegroundColor Green
            }
        } else {
            Write-Warning "SystemStatus monitoring script not found"
        }
        
        # Start AutonomousAgent if not skipped
        if (-not $SkipAutonomousAgent) {
            Write-Host ""
            Write-Host "Step 3: Starting AutonomousAgent..." -ForegroundColor Yellow
            
            # Wait for SystemStatus to initialize
            Start-Sleep -Seconds 3
            
            $agentScript = ".\Start-AutonomousMonitoring-Fixed.ps1"
            if (Test-Path $agentScript) {
                $agentJob = Start-Job -Name "AutonomousAgent" -ScriptBlock {
                    param($ScriptPath)
                    & $ScriptPath
                } -ArgumentList $agentScript
                
                if ($agentJob) {
                    Write-Host "  AutonomousAgent started (Job ID: $($agentJob.Id))" -ForegroundColor Green
                }
            } else {
                Write-Warning "AutonomousAgent script not found: $agentScript"
            }
        } else {
            Write-Host ""
            Write-Host "Step 3: Skipping AutonomousAgent (as requested)" -ForegroundColor Yellow
        }
        
        # Display final status
        Write-Host ""
        Write-Host "=== LEGACY STARTUP COMPLETE ===" -ForegroundColor Green
        
        $jobs = Get-Job | Where-Object { $_.Name -match "SystemStatus|AutonomousAgent" }
        if ($jobs) {
            Write-Host "Active subsystem jobs:" -ForegroundColor Cyan
            $jobs | ForEach-Object {
                $status = switch ($_.State) {
                    "Running" { "[RUNNING]" }
                    "Completed" { "[COMPLETED]" }
                    "Failed" { "[FAILED]" }
                    default { "[$($_.State)]" }
                }
                Write-Host "  - $($_.Name): $status" -ForegroundColor White
            }
        }
        
    } catch {
        Write-Error "Legacy startup failed: $($_.Exception.Message)"
        exit 1
    }
}

# Final status and recommendations
Write-Host ""
Write-Host "=== SYSTEM STARTUP COMPLETE ===" -ForegroundColor Green
Write-Host "Mode Used: $(if ($useManifestSystem) { 'Manifest-based Bootstrap Orchestrator' } else { 'Legacy Hardcoded Configuration' })" -ForegroundColor Cyan
Write-Host "Startup Time: $(Get-Date)" -ForegroundColor Cyan

if (-not $useManifestSystem -and $compatibilityLoaded) {
    Write-Host ""
    Write-Host "FUTURE UPGRADE AVAILABLE:" -ForegroundColor Yellow
    Write-Host "Consider upgrading to manifest-based system for:" -ForegroundColor White
    Write-Host "  - Better dependency management" -ForegroundColor White
    Write-Host "  - Resource limit enforcement" -ForegroundColor White
    Write-Host "  - Improved error recovery" -ForegroundColor White
    Write-Host "  - Centralized configuration" -ForegroundColor White
    Write-Host ""
    Write-Host "To upgrade: .\Migration\Migrate-ToManifestSystem.ps1" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "System is now running. Press Ctrl+C to stop or close this window." -ForegroundColor Gray

# Keep script running to monitor jobs
try {
    while ($true) {
        Start-Sleep -Seconds 30
        
        # Check job health in legacy mode
        if (-not $useManifestSystem) {
            $jobs = Get-Job | Where-Object { $_.Name -match "SystemStatus|AutonomousAgent" }
            $failedJobs = $jobs | Where-Object { $_.State -eq "Failed" }
            
            if ($failedJobs) {
                Write-Host "[$(Get-Date)] WARNING: Failed jobs detected:" -ForegroundColor Red
                $failedJobs | ForEach-Object {
                    Write-Host "  - $($_.Name): $($_.State)" -ForegroundColor Red
                }
            }
        }
    }
} catch {
    Write-Host "System monitoring stopped: $($_.Exception.Message)" -ForegroundColor Yellow
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUt/6yz9SVOIfj5h4qHXdldzG7
# T46gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
# AQsFADAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0b21hdGlvbi1EZXZlbG9w
# bWVudDAeFw0yNTA4MjAyMTE1MTdaFw0yNjA4MjAyMTM1MTdaMC4xLDAqBgNVBAMM
# I1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEAseH3qinVEOhrn2OLpjc5TNT4vGh1BkfB5X4S
# FhY7K0QMQsYYnkZVmx3tB8PqVQXl++l+e3uT7uCscc7vjMTK8tDSWH98ji0U34WL
# JBwXC62l1ArazMKp4Tyr7peksei7vL4pZOtOVgAyTYn5d1hbnsVQmCSTPRtpn7mC
# Azfq2ec5qZ9Kgl7puPW5utvYfh8idtOWa5/WgYSKwOIvyZawIdZKLFpwqOtqbJe4
# sWzVahasFhLfoAKkniKOAocJDkJexh5pO/EOSKEZ3mOCU1ZSs4XWRGISRhV3qGZp
# f+Y3JlHKMeFDWKynaJBO8/GU5sqMATlDUvrByBtU2OQ2Um/L3QIDAQABo0YwRDAO
# BgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFHw5
# rOy6xlW6B45sJUsiI2A/yS0MMA0GCSqGSIb3DQEBCwUAA4IBAQAUTLH0+w8ysvmh
# YuBw4NDKcZm40MTh9Zc1M2p2hAkYsgNLJ+/rAP+I74rNfqguTYwxpCyjkwrg8yF5
# wViwggboLpF2yDu4N/dgDainR4wR8NVpS7zFZOFkpmNPepc6bw3d4yQKa/wJXKeC
# pkRjS50N77/hfVI+fFKNao7POb7en5fcXuZaN6xWoTRy+J4I4MhfHpjZuxSLSXjb
# VXtPD4RZ9HGjl9BU8162cRhjujr/Lc3/dY/6ikHQYnxuxcdxRew4nzaqAQaOeWu6
# tGp899JPKfldM5Zay5IBl3zs15gNS9+0Jrd0ARQnSVYoI0DLh3KybFnfK4POezoN
# Lp/dbX2SMYIB4zCCAd8CAQEwQjAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0
# b21hdGlvbi1EZXZlbG9wbWVudAIQdR0W2SKoK5VE8JId4ZxrRTAJBgUrDgMCGgUA
# oHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYB
# BAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0B
# CQQxFgQUvJD6LN1i1x/Oj6C1SJx/jTNhGTwwDQYJKoZIhvcNAQEBBQAEggEAfKdL
# GifJR9b2oF5mXsalpKk3j1eF1l3Z3QgodQKhNfg+HcS2zbCmPS34i4SA8y8iV7D7
# xegJsZKUD/FltCvkq/Wheh5QCC0jbUXDQe3v8HvQs40f8II1fMSvFCNIX9/xx3oD
# K0EWyNEQX6QMNFvAhYCBetIbkC7mIbCOQgbABF6NSDdIhKXjCcH7mrkgP34c9SvF
# bEdQFQdcAQAVTM9QOHUryj0j4fc3Alzb1cMlslMrOGv5CKZtIDxyNMLjk08/a2GV
# OEjERMQG9Azd75pxrEFrtaQ0cytqco8Dlvm8EHL3pku/cBNoDckBIwNYoXfKX0jG
# gV8OuJStceZrykzjrg==
# SIG # End signature block
