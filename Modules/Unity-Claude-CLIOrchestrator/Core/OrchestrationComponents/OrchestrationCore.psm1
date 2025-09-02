# OrchestrationCore.psm1
# Core orchestration initialization and startup functions

function Start-CLIOrchestration {
    <#
    .SYNOPSIS
        Starts the main CLI orchestration system with autonomous capabilities
        
    .DESCRIPTION
        Initializes and runs the complete CLI orchestration system including
        autonomous monitoring, decision making, and response processing
    #>
    [CmdletBinding()]
    param(
        [switch]$AutonomousMode,
        [int]$MonitoringInterval = 30,
        [int]$MaxExecutionTime = 60,
        [switch]$EnableResponseAnalysis,
        [switch]$EnableDecisionMaking
    )
    
    try {
        Write-Host ""
        Write-Host "=====================================================================" -ForegroundColor Cyan
        Write-Host "         Unity-Claude CLI Orchestration System v2.0" -ForegroundColor Cyan
        Write-Host "=====================================================================" -ForegroundColor Cyan
        Write-Host ""
        
        Write-Host "CONFIGURATION:" -ForegroundColor Yellow
        Write-Host "  Autonomous Mode: $AutonomousMode" -ForegroundColor Gray
        Write-Host "  Monitoring Interval: $MonitoringInterval seconds" -ForegroundColor Gray
        Write-Host "  Max Execution Time: $MaxExecutionTime minutes" -ForegroundColor Gray
        Write-Host "  Response Analysis: $EnableResponseAnalysis" -ForegroundColor Gray
        Write-Host "  Decision Making: $EnableDecisionMaking" -ForegroundColor Gray
        Write-Host ""
        
        $orchestrationResults = [PSCustomObject]@{
            StartTime = Get-Date
            EndTime = $null
            Mode = if ($AutonomousMode) { "Autonomous" } else { "Manual" }
            TotalRunTime = 0
            MonitoringCycles = 0
            ResponsesAnalyzed = 0
            DecisionsMade = 0
            ActionsExecuted = 0
            Errors = @()
            Status = "Running"
        }
        
        # Initialize components
        Write-Host "Initializing orchestration components..." -ForegroundColor Cyan
        
        # Verify Claude window is available
        $claudeWindow = Find-ClaudeWindow
        if (-not $claudeWindow) {
            throw "Claude Code CLI window not found. Please ensure Claude CLI is open and visible."
        }
        Write-Host "  Claude CLI window detected successfully" -ForegroundColor Green
        
        # Initialize response directory
        $responseDir = ".\ClaudeResponses\Autonomous"
        if (-not (Test-Path $responseDir)) {
            New-Item -ItemType Directory -Path $responseDir -Force | Out-Null
        }
        Write-Host "  Response directory initialized" -ForegroundColor Green
        
        # Start monitoring loop
        if ($AutonomousMode) {
            Write-Host ""
            Write-Host "Starting autonomous monitoring loop..." -ForegroundColor Cyan
            $orchestrationResults = Start-MonitoringLoop `
                -OrchestrationResults $orchestrationResults `
                -MonitoringInterval $MonitoringInterval `
                -MaxExecutionTime $MaxExecutionTime `
                -EnableResponseAnalysis $EnableResponseAnalysis `
                -EnableDecisionMaking $EnableDecisionMaking
        }
        else {
            Write-Host "Manual mode - performing single execution cycle..." -ForegroundColor Yellow
            $orchestrationResults = Invoke-SingleExecutionCycle `
                -OrchestrationResults $orchestrationResults `
                -EnableResponseAnalysis $EnableResponseAnalysis `
                -EnableDecisionMaking $EnableDecisionMaking
        }
        
        # Finalize results
        $orchestrationResults.EndTime = Get-Date
        $orchestrationResults.TotalRunTime = [Math]::Round(($orchestrationResults.EndTime - $orchestrationResults.StartTime).TotalMinutes, 2)
        $orchestrationResults.Status = "Completed"
        
        # Display summary
        Write-Host ""
        Write-Host "=====================================================================" -ForegroundColor Cyan
        Write-Host "                    ORCHESTRATION COMPLETE" -ForegroundColor Green
        Write-Host "=====================================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "SUMMARY:" -ForegroundColor Yellow
        Write-Host "  Total Runtime: $($orchestrationResults.TotalRunTime) minutes" -ForegroundColor Gray
        Write-Host "  Monitoring Cycles: $($orchestrationResults.MonitoringCycles)" -ForegroundColor Gray
        Write-Host "  Responses Analyzed: $($orchestrationResults.ResponsesAnalyzed)" -ForegroundColor Gray
        Write-Host "  Decisions Made: $($orchestrationResults.DecisionsMade)" -ForegroundColor Gray
        Write-Host "  Actions Executed: $($orchestrationResults.ActionsExecuted)" -ForegroundColor Gray
        Write-Host "  Errors Encountered: $($orchestrationResults.Errors.Count)" -ForegroundColor $(if ($orchestrationResults.Errors.Count -gt 0) { 'Red' } else { 'Gray' })
        Write-Host ""
        
        return $orchestrationResults
    }
    catch {
        Write-Host "ERROR in Start-CLIOrchestration: $_" -ForegroundColor Red
        throw
    }
}

function Get-CLIOrchestrationStatus {
    <#
    .SYNOPSIS
        Gets the current status of CLI orchestration system
        
    .DESCRIPTION
        Retrieves comprehensive status information about the running orchestration system
    #>
    [CmdletBinding()]
    param()
    
    try {
        $status = [PSCustomObject]@{
            Timestamp = Get-Date
            ClaudeWindow = $null
            ResponseDirectory = $null
            PendingSignals = @()
            ProcessedResponses = @()
            ActiveDecisions = @()
            SystemHealth = "Unknown"
        }
        
        # Check Claude window
        $claudeWindow = Find-ClaudeWindow
        $status.ClaudeWindow = if ($claudeWindow) { "Active" } else { "Not Found" }
        
        # Check response directory
        $responseDir = ".\ClaudeResponses\Autonomous"
        if (Test-Path $responseDir) {
            $status.ResponseDirectory = "Available"
            
            # Check for signal files
            $signalFiles = Get-ChildItem -Path $responseDir -Filter "*.signal" -ErrorAction SilentlyContinue
            $status.PendingSignals = $signalFiles | ForEach-Object { $_.Name }
            
            # Check for processed responses
            $processedFiles = Get-ChildItem -Path $responseDir -Filter "*.processed" -ErrorAction SilentlyContinue
            $status.ProcessedResponses = $processedFiles | Select-Object -Last 5 | ForEach-Object { $_.Name }
        }
        else {
            $status.ResponseDirectory = "Not Available"
        }
        
        # Determine system health
        if ($status.ClaudeWindow -eq "Active" -and $status.ResponseDirectory -eq "Available") {
            $status.SystemHealth = "Healthy"
        }
        elseif ($status.ClaudeWindow -eq "Active" -or $status.ResponseDirectory -eq "Available") {
            $status.SystemHealth = "Degraded"
        }
        else {
            $status.SystemHealth = "Critical"
        }
        
        return $status
    }
    catch {
        Write-Host "ERROR in Get-CLIOrchestrationStatus: $_" -ForegroundColor Red
        return $null
    }
}

function Initialize-OrchestrationEnvironment {
    <#
    .SYNOPSIS
        Initializes the orchestration environment
    #>
    [CmdletBinding()]
    param()
    
    try {
        Write-Host "Initializing orchestration environment..." -ForegroundColor Cyan
        
        # Create necessary directories
        $directories = @(
            ".\ClaudeResponses\Autonomous",
            ".\Logs\CLIOrchestrator",
            ".\Config\CLIOrchestrator"
        )
        
        foreach ($dir in $directories) {
            if (-not (Test-Path $dir)) {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
                Write-Host "  Created directory: $dir" -ForegroundColor Green
            }
        }
        
        # Initialize configuration
        $configFile = ".\Config\CLIOrchestrator\orchestration.config"
        if (-not (Test-Path $configFile)) {
            $defaultConfig = @{
                MonitoringInterval = 30
                MaxExecutionTime = 60
                EnableResponseAnalysis = $true
                EnableDecisionMaking = $true
                SafetyMode = "High"
                LogLevel = "Information"
            }
            $defaultConfig | ConvertTo-Json | Set-Content -Path $configFile
            Write-Host "  Created default configuration" -ForegroundColor Green
        }
        
        Write-Host "Environment initialization complete" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "ERROR in Initialize-OrchestrationEnvironment: $_" -ForegroundColor Red
        return $false
    }
}

# Functions are available directly when dot-sourced
# No Export-ModuleMember needed for dot-sourcing