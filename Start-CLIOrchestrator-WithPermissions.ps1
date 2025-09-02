# Start-CLIOrchestrator-WithPermissions.ps1
# Starts the CLIOrchestrator with integrated permission handling
# This script is designed to be called by Start-UnityClaudeSystem-Windowed.ps1

param(
    [switch]$EnableSafeOperations = $true,
    [switch]$EnableInterceptor = $true,
    [string]$Mode = "Intelligent",
    [switch]$TestMode,
    [switch]$Debug
)

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "STARTING CLI ORCHESTRATOR WITH PERMISSION HANDLING" -ForegroundColor Green
Write-Host "=" * 80 -ForegroundColor Cyan

# Set working directory
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptPath

# Import the main orchestrator module
Write-Host "`nImporting CLIOrchestrator module..." -ForegroundColor Gray
try {
    Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator.psm1" -Force -WarningAction SilentlyContinue
    Write-Host "✅ CLIOrchestrator loaded" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to load CLIOrchestrator: $_" -ForegroundColor Red
    exit 1
}

# Import the integration module
try {
    Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Core\PermissionIntegration.psm1" -Force -WarningAction SilentlyContinue
    Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Core\ClaudePermissionInterceptor.psm1" -Force -WarningAction SilentlyContinue
    Write-Host "✅ Permission modules loaded" -ForegroundColor Green
} catch {
    Write-Warning "Failed to load permission modules: $_"
}

# Initialize Safe Operations Handler
if ($EnableSafeOperations) {
    Write-Host "`nInitializing Safe Operations..." -ForegroundColor Gray
    try {
        $safeOpsResult = Initialize-SafeOperations -GitAutoCommit:$true
        if ($safeOpsResult.Success) {
            Write-Host "✅ Safe Operations enabled" -ForegroundColor Green
            Write-Host "  Archive path: $($safeOpsResult.ArchivePath)" -ForegroundColor Cyan
        } else {
            Write-Warning "Safe Operations initialization returned false"
        }
    } catch {
        Write-Warning "Safe Operations initialization failed: $_"
    }
}

# Initialize Permission Interceptor
if ($EnableInterceptor) {
    Write-Host "`nInitializing Permission Interceptor..." -ForegroundColor Gray
    try {
        # Create a permission handler hashtable for the interceptor
        $permissionHandler = @{
            Handler = {
                param($PromptInfo)
                
                # Simple auto-approve for safe operations
                $safeTools = @('Read', 'Bash', 'Edit', 'Write', 'Grep', 'Glob')
                $safeCommands = @('git status', 'git diff', 'npm test', 'ls', 'pwd')
                
                foreach ($tool in $safeTools) {
                    if ($PromptInfo.OriginalText -match "Allow $tool") {
                        return @{
                            Action = "approve"
                            Response = "y"
                            Reason = "Safe tool: $tool"
                        }
                    }
                }
                
                foreach ($cmd in $safeCommands) {
                    if ($PromptInfo.OriginalText -match [regex]::Escape($cmd)) {
                        return @{
                            Action = "approve"
                            Response = "y"
                            Reason = "Safe command: $cmd"
                        }
                    }
                }
                
                # Default to manual for unknown operations
                return @{
                    Action = "manual"
                    Response = $null
                    Reason = "Unknown operation - requires manual review"
                }
            }
            Mode = $Mode
            Config = @{
                AutoApproveProjectFiles = $true
                BlockSystemOperations = $true
            }
        }
        
        $interceptorResult = Start-ClaudePermissionInterceptor -PermissionHandler $permissionHandler
        $null = $interceptorResult  # Suppress output
        Write-Host "✅ Permission Interceptor started" -ForegroundColor Green
    } catch {
        Write-Warning "Permission Interceptor failed: $_"
    }
}

# Initialize the main orchestrator
Write-Host "`nInitializing Orchestrator..." -ForegroundColor Gray
try {
    $orchResult = Initialize-CLIOrchestrator -ValidateComponents -SetupDirectories
    if ($orchResult.Initialized -or $orchResult.Version) {
        Write-Host "✅ CLIOrchestrator initialized successfully" -ForegroundColor Green
        Write-Host "  Version: $($orchResult.Version)" -ForegroundColor Gray
        
        # Show component status if available
        if ($orchResult.ComponentHealth) {
            Write-Host "`nComponent Health:" -ForegroundColor Yellow
            foreach ($comp in $orchResult.ComponentHealth.Components) {
                $icon = if ($comp.Status -eq "Healthy") { "✅" } else { "⚠️" }
                Write-Host "  $icon $($comp.Name): $($comp.Status)" -ForegroundColor White
            }
        }
    } else {
        Write-Host "✅ CLIOrchestrator initialized" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ CLIOrchestrator initialization failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host "`n" + ("=" * 80) -ForegroundColor Cyan
Write-Host "CLI ORCHESTRATOR WITH PERMISSIONS READY" -ForegroundColor Green
Write-Host ("=" * 80) -ForegroundColor Cyan

Write-Host "`nSystem Status:" -ForegroundColor Yellow
Write-Host "  ✅ CLIOrchestrator: Active" -ForegroundColor Green
if ($EnableSafeOperations) {
    Write-Host "  ✅ Safe Operations: Enabled" -ForegroundColor Green
}
if ($EnableInterceptor) {
    Write-Host "  ✅ Permission Interceptor: Running" -ForegroundColor Green
}
Write-Host "  ✅ Mode: $Mode" -ForegroundColor Green

Write-Host "`nThe orchestrator is now monitoring for:" -ForegroundColor Yellow
Write-Host "  • Claude CLI permission prompts" -ForegroundColor White
Write-Host "  • Response files from Claude" -ForegroundColor White
Write-Host "  • Test execution signals" -ForegroundColor White
Write-Host "  • Destructive operations (will be converted to safe)" -ForegroundColor White

# Keep the script running
Write-Host "`nPress Ctrl+C to stop the orchestrator..." -ForegroundColor Gray

# Start the orchestration loop (always start unless explicitly in test mode)
if (-not $TestMode) {
    Write-Host "`n🚀 Starting orchestration monitoring loop..." -ForegroundColor Green
    Write-Host "Monitoring path: .\ClaudeResponses\Autonomous" -ForegroundColor Yellow
    Write-Host "The orchestrator will now monitor for:" -ForegroundColor Yellow
    Write-Host "  • Permission requests (PermissionRequest*.json)" -ForegroundColor White
    Write-Host "  • Claude responses (*.json)" -ForegroundColor White  
    Write-Host "  • Test signals (*.signal)" -ForegroundColor White
    Write-Host "`nPress Ctrl+C to stop monitoring" -ForegroundColor Gray
    
    try {
        # Start the monitoring loop directly (0 = unlimited time)
        Start-CLIOrchestration -MonitoringInterval 500 -MaxExecutionTime 0 -EnableDecisionMaking
    } catch {
        Write-Host "❌ Orchestration monitoring stopped: $_" -ForegroundColor Red
        Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Yellow
        
        # Try to restart once
        Write-Host "`nAttempting to restart monitoring..." -ForegroundColor Yellow
        Start-Sleep -Seconds 2
        try {
            Start-CLIOrchestration -MonitoringInterval 500 -MaxExecutionTime 14400 -EnableDecisionMaking
        } catch {
            Write-Host "❌ Failed to restart: $_" -ForegroundColor Red
        }
    }
} else {
    Write-Host "`nTest mode - orchestrator initialized but not starting monitoring loop" -ForegroundColor Yellow
    Write-Host "To enable monitoring, restart without -TestMode parameter" -ForegroundColor Gray
}

# This code won't normally be reached unless monitoring stops
Write-Host "`n⚠️ Monitoring has stopped. Keeping window open for diagnostics." -ForegroundColor Yellow
Write-Host "Press Ctrl+C to close this window." -ForegroundColor Gray

# Keep window open with status updates
while ($true) {
    Start-Sleep -Seconds 30
    
    # Status check
    $status = Get-CLIOrchestrationStatus
    $statusColor = if ($status.Active) { "Green" } else { "Red" }
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Status - Active: $($status.Active) | Claude Window: $($status.ClaudeWindow)" -ForegroundColor $statusColor
    
    # Check for unprocessed permission requests
    $responsePath = ".\ClaudeResponses\Autonomous"
    if (Test-Path $responsePath) {
        $unprocessedRequests = Get-ChildItem -Path $responsePath -Filter "PermissionRequest*.json" -ErrorAction SilentlyContinue | 
            Where-Object { -not (Test-Path "$($_.FullName).processed") }
        
        if ($unprocessedRequests) {
            Write-Host "  ⚠️ Found $($unprocessedRequests.Count) unprocessed permission requests!" -ForegroundColor Yellow
            $unprocessedRequests | ForEach-Object {
                Write-Host "    - $($_.Name)" -ForegroundColor Gray
            }
        }
    }
}