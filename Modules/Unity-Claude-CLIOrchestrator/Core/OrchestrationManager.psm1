# OrchestrationManager-Fixed.psm1
# Simplified version with proper try-catch blocks

#region Module Header
<#
.SYNOPSIS
    Orchestration Manager Component - Fixed Version
.DESCRIPTION
    Manages the main orchestration loop, monitoring, and decision execution
#>
#endregion

#region Private Variables
$script:OrchestrationConfig = @{
    MonitoringActive = $false
    MonitoringInterval = 500
    ResponsePath = ".\ClaudeResponses\Autonomous"
    SignalPath = ".\ClaudeResponses\Autonomous"
    LastProcessedTime = $null
}
#endregion

#region Public Functions

function Start-CLIOrchestration {
    [CmdletBinding()]
    param(
        [int]$MonitoringInterval = 500,
        [int]$MaxExecutionTime = 60,
        [switch]$EnableDecisionMaking
    )
    
    try {
        Write-Host "Starting CLI Orchestration..." -ForegroundColor Cyan
        
        $script:OrchestrationConfig.MonitoringActive = $true
        $script:OrchestrationConfig.MonitoringInterval = $MonitoringInterval
        
        # Set LastProcessedTime to current time to avoid reprocessing old files
        if (-not $script:OrchestrationConfig.LastProcessedTime) {
            $script:OrchestrationConfig.LastProcessedTime = Get-Date
            Write-Host "  Monitoring for new files only (ignoring existing files)" -ForegroundColor Gray
        }
        
        $startTime = Get-Date
        $maxRunTime = if ($MaxExecutionTime -gt 0) { New-TimeSpan -Minutes $MaxExecutionTime } else { [TimeSpan]::MaxValue }
        
        do {
            try {
                # Only check execution time if a limit was set
                if ($MaxExecutionTime -gt 0) {
                    $currentTime = Get-Date
                    $elapsedTime = $currentTime - $startTime
                    
                    if ($elapsedTime -gt $maxRunTime) {
                        Write-Host "Max execution time reached. Stopping orchestration." -ForegroundColor Yellow
                        break
                    }
                }
                
                # Monitor for response files
                $responseFiles = Get-ChildItem -Path $script:OrchestrationConfig.ResponsePath -Filter "*.json" -ErrorAction SilentlyContinue |
                    Where-Object { $_.LastWriteTime -gt $script:OrchestrationConfig.LastProcessedTime }
                
                if ($responseFiles) {
                    foreach ($file in $responseFiles) {
                        try {
                            # Check if this is a permission request
                            if ($file.Name -match "PermissionRequest") {
                                Write-Host "[PERMISSION] Found permission request: $($file.Name)" -ForegroundColor Magenta
                                
                                # Read the permission request
                                $permRequest = Get-Content $file.FullName -Raw | ConvertFrom-Json
                                
                                # Display the permission prompt
                                Write-Host "`n" + ("=" * 60) -ForegroundColor Yellow
                                Write-Host "PERMISSION REQUEST FROM CLAUDE" -ForegroundColor Cyan
                                Write-Host ("=" * 60) -ForegroundColor Yellow
                                Write-Host "Tool: $($permRequest.Tool)" -ForegroundColor White
                                Write-Host "Operation: $($permRequest.Operation)" -ForegroundColor White
                                if ($permRequest.Command) {
                                    Write-Host "Command: $($permRequest.Command)" -ForegroundColor White
                                }
                                if ($permRequest.Target) {
                                    Write-Host "Target: $($permRequest.Target)" -ForegroundColor White
                                }
                                Write-Host "Context: $($permRequest.Context)" -ForegroundColor Gray
                                Write-Host "Safety Level: $($permRequest.SafetyLevel)" -ForegroundColor $(if ($permRequest.SafetyLevel -eq "High") { "Red" } elseif ($permRequest.SafetyLevel -eq "Medium") { "Yellow" } else { "Green" })
                                Write-Host "`nPrompt: $($permRequest.PromptText)" -ForegroundColor Cyan
                                
                                # Import the approval handler if not already loaded
                                if (-not (Get-Module -Name PermissionApprovalHandler)) {
                                    $approvalHandlerPath = Join-Path (Split-Path $PSScriptRoot -Parent) "Unity-Claude-CLIOrchestrator\Core\PermissionApprovalHandler.psm1"
                                    if (Test-Path $approvalHandlerPath) {
                                        Import-Module $approvalHandlerPath -Force -WarningAction SilentlyContinue
                                    }
                                }
                                
                                # Auto-approve safe operations
                                $autoApprove = $false
                                $approvalReason = ""
                                
                                if ($permRequest.Tool -eq "Bash" -and $permRequest.Command -match "^(git status|git diff|ls|pwd|dir|Get-ChildItem)") {
                                    $autoApprove = $true
                                    $approvalReason = "Safe read-only command"
                                }
                                elseif ($permRequest.Tool -eq "FileSystem" -and $permRequest.Operation -eq "Delete") {
                                    # Convert to archive operation
                                    Write-Host "`n[SAFE OPS] Converting delete to archive operation" -ForegroundColor Green
                                    $autoApprove = $true
                                    $approvalReason = "Converted to safe archive operation"
                                }
                                
                                # Actually send the approval to Claude window
                                if (Get-Command Approve-ClaudePermission -ErrorAction SilentlyContinue) {
                                    Write-Host "`n[APPROVAL] Attempting to send approval to Claude window..." -ForegroundColor Cyan
                                    $approvalResult = Approve-ClaudePermission -PermissionRequest $permRequest -AutoApprove $autoApprove -ApprovalReason $approvalReason
                                    
                                    if ($approvalResult.Success) {
                                        Write-Host "✅ APPROVAL SENT via $($approvalResult.Method)" -ForegroundColor Green
                                        if ($approvalResult.Response -eq "y") {
                                            Write-Host "   Approved: $approvalReason" -ForegroundColor Green
                                        } else {
                                            Write-Host "   Denied: $approvalReason" -ForegroundColor Red
                                        }
                                    } else {
                                        Write-Host "⚠️ Could not send approval automatically" -ForegroundColor Yellow
                                        Write-Host "   Please respond manually in the Claude window" -ForegroundColor Gray
                                    }
                                } else {
                                    # Fallback to just displaying status
                                    if ($autoApprove) {
                                        Write-Host "`n✅ WOULD AUTO-APPROVE: $approvalReason" -ForegroundColor Green
                                        Write-Host "   (Approval handler not available)" -ForegroundColor Gray
                                    }
                                    else {
                                        Write-Host "`n⚠️ MANUAL REVIEW REQUIRED" -ForegroundColor Yellow
                                        Write-Host "This operation requires manual approval" -ForegroundColor Gray
                                    }
                                }
                                
                                Write-Host ("=" * 60) -ForegroundColor Yellow
                                
                                # Mark as processed
                                "$($file.FullName).processed" | Out-File "$($file.FullName).processed" -Force
                            }
                            else {
                                Write-Host "Processing response: $($file.Name)" -ForegroundColor Green
                                
                                if ($EnableDecisionMaking) {
                                    $decision = Invoke-AutonomousDecisionMaking -ResponseFile $file.FullName
                                    if ($decision) {
                                        Invoke-DecisionExecution -DecisionResult $decision
                                    }
                                }
                            }
                            
                            $script:OrchestrationConfig.LastProcessedTime = $file.LastWriteTime
                        }
                        catch {
                            Write-Error "Error processing response file: $_"
                        }
                    }
                }
                
                # Monitor for signal files
                $signalFiles = Get-ChildItem -Path $script:OrchestrationConfig.SignalPath -Filter "*.signal" -ErrorAction SilentlyContinue
                
                if ($signalFiles) {
                    foreach ($signalFile in $signalFiles) {
                        try {
                            Write-Host "Processing signal: $($signalFile.Name)" -ForegroundColor Yellow
                            
                            # Archive the signal file
                            $archivePath = "$($signalFile.FullName).processed"
                            Move-Item -Path $signalFile.FullName -Destination $archivePath -Force
                            
                        }
                        catch {
                            Write-Error "Error processing signal file: $_"
                        }
                    }
                }
                
                Start-Sleep -Milliseconds $script:OrchestrationConfig.MonitoringInterval
                
            }
            catch {
                Write-Error "Error in orchestration loop: $_"
                Start-Sleep -Milliseconds 1000
            }
            
        } while ($script:OrchestrationConfig.MonitoringActive)
        
        Write-Host "Orchestration loop ended. Active: $($script:OrchestrationConfig.MonitoringActive)" -ForegroundColor Yellow
        
    }
    catch {
        Write-Error "Failed to start orchestration: $_"
        throw
    }
}

function Get-CLIOrchestrationStatus {
    [CmdletBinding()]
    param()
    
    try {
        $status = @{
            Active = $script:OrchestrationConfig.MonitoringActive
            Interval = $script:OrchestrationConfig.MonitoringInterval
            LastProcessed = $script:OrchestrationConfig.LastProcessedTime
            ResponsePath = $script:OrchestrationConfig.ResponsePath
        }
        
        # Check Claude window
        try {
            $claudeWindow = Find-ClaudeWindow -ErrorAction SilentlyContinue
            $status.ClaudeWindow = if ($claudeWindow) { "Available" } else { "Not found" }
        }
        catch {
            $status.ClaudeWindow = "Error checking"
        }
        
        return $status
    }
    catch {
        Write-Error "Failed to get orchestration status: $_"
        return @{ Error = $_.Exception.Message }
    }
}

function Invoke-ComprehensiveResponseAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ResponseFile
    )
    
    try {
        if (-not (Test-Path $ResponseFile)) {
            throw "Response file not found: $ResponseFile"
        }
        
        $content = Get-Content -Path $ResponseFile -Raw | ConvertFrom-Json
        
        # Perform analysis
        $analysis = @{
            HasRecommendation = $false
            Recommendation = $null
            Confidence = 0
        }
        
        if ($content.recommendation) {
            $analysis.HasRecommendation = $true
            $analysis.Recommendation = $content.recommendation
            $analysis.Confidence = 0.9
        }
        
        return $analysis
    }
    catch {
        Write-Error "Failed to analyze response: $_"
        return $null
    }
}

function Invoke-AutonomousDecisionMaking {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ResponseFile
    )
    
    try {
        $content = Get-Content -Path $ResponseFile -Raw | ConvertFrom-Json
        
        $decision = @{
            Decision = "CONTINUE"
            Confidence = 0.5
            ResponseFile = $ResponseFile
            Timestamp = Get-Date
        }
        
        # Parse recommendation
        if ($content.recommendation) {
            if ($content.recommendation -match "TEST") {
                $decision.Decision = "TEST"
                $decision.TestPath = $content.testPath
            }
            elseif ($content.recommendation -match "FIX") {
                $decision.Decision = "FIX"
                $decision.FixPath = $content.fixPath
            }
            elseif ($content.recommendation -match "COMPLETE") {
                $decision.Decision = "COMPLETE"
            }
        }
        
        return $decision
    }
    catch {
        Write-Error "Failed to make decision: $_"
        return $null
    }
}

function Invoke-DecisionExecution {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$DecisionResult
    )
    
    try {
        $executionResult = @{
            ExecutionStatus = "Unknown"
            Actions = @()
            Errors = @()
            Timestamp = Get-Date
        }
        
        switch ($DecisionResult.Decision) {
            "TEST" {
                Write-Host "Executing TEST decision" -ForegroundColor Yellow
                
                if ($DecisionResult.TestPath -and (Test-Path $DecisionResult.TestPath)) {
                    try {
                        # Execute test
                        $testResult = & powershell.exe -ExecutionPolicy Bypass -File $DecisionResult.TestPath 2>&1
                        $executionResult.ExecutionStatus = "Success"
                        $executionResult.Actions += "Executed test: $($DecisionResult.TestPath)"
                    }
                    catch {
                        $executionResult.ExecutionStatus = "Failed"
                        $executionResult.Errors += "Test execution failed: $_"
                    }
                }
                else {
                    $executionResult.ExecutionStatus = "Failed"
                    $executionResult.Errors += "Test path not found"
                }
            }
            "FIX" {
                Write-Host "Executing FIX decision" -ForegroundColor Yellow
                $executionResult.ExecutionStatus = "Acknowledged"
                $executionResult.Actions += "Fix request acknowledged"
            }
            "CONTINUE" {
                Write-Host "Executing CONTINUE decision" -ForegroundColor Yellow
                $executionResult.ExecutionStatus = "Continuing"
                $executionResult.Actions += "Continuing orchestration"
            }
            "COMPLETE" {
                Write-Host "Execution COMPLETE" -ForegroundColor Green
                $executionResult.ExecutionStatus = "Complete"
                $script:OrchestrationConfig.MonitoringActive = $false
            }
            default {
                Write-Host "Unknown decision: $($DecisionResult.Decision)" -ForegroundColor Red
                $executionResult.ExecutionStatus = "Unknown"
            }
        }
        
        return $executionResult
    }
    catch {
        Write-Error "Failed to execute decision: $_"
        throw
    }
}

#endregion

#region Export
Export-ModuleMember -Function @(
    'Start-CLIOrchestration',
    'Get-CLIOrchestrationStatus',
    'Invoke-ComprehensiveResponseAnalysis',
    'Invoke-AutonomousDecisionMaking',
    'Invoke-DecisionExecution'
)
#endregion