# Start-SafeOrchestration.ps1
# Starts Claude CLI with safe operations and automatic git checkpointing

param(
    [string]$ImplementationPlan,
    [string]$StartPhase = "Hour 1",
    [switch]$EnablePush,
    [switch]$TestMode
)

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "CLAUDE SAFE ORCHESTRATION SYSTEM" -ForegroundColor Green
Write-Host "All destructive operations will be converted to safe alternatives" -ForegroundColor Yellow
Write-Host "Git checkpoints will be created after each major phase" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Cyan

# Import required modules
Write-Host "`nLoading safety modules..." -ForegroundColor Gray
Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Core\SafeOperationsHandler.psm1" -Force
Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Core\PermissionHandler.psm1" -Force

# Initialize safe operations
Write-Host "`nInitializing safe operations..." -ForegroundColor Cyan
Initialize-SafeOperations -GitAutoCommit:$true -GitPushEnabled:$EnablePush

# Initialize permission handler with custom rules
Write-Host "Configuring permission handler..." -ForegroundColor Cyan
Initialize-PermissionHandler -Mode "Intelligent"

# Add custom safety rules
Add-PermissionRule -Name "PreventDelete" `
    -Pattern "(?i)(delete|remove|rm|del)\s" `
    -Decision "deny" `
    -Confidence 1.0 `
    -Reason "Destructive operation - will be converted to archive"

Add-PermissionRule -Name "AllowSafeOps" `
    -Pattern "(?i)(archive|backup|copy|move.*archive)" `
    -Decision "approve" `
    -Confidence 0.95 `
    -Reason "Safe archival operation"

# If implementation plan provided, start tracking
if ($ImplementationPlan) {
    Write-Host "`nStarting implementation plan tracking..." -ForegroundColor Green
    
    # Try to find the plan file
    $planFile = Get-ChildItem -Path "." -Filter "*$ImplementationPlan*.md" -Recurse | 
                Select-Object -First 1
    
    if ($planFile) {
        Start-ImplementationPlan -PlanName $ImplementationPlan `
                                -PlanFile $planFile.FullName `
                                -InitialPhase $StartPhase
        
        Write-Host "✅ Tracking plan: $($planFile.Name)" -ForegroundColor Green
    } else {
        Start-ImplementationPlan -PlanName $ImplementationPlan `
                                -InitialPhase $StartPhase
        
        Write-Host "✅ Tracking plan: $ImplementationPlan" -ForegroundColor Green
    }
    
    # Enable automatic checkpoints
    Enable-AutoCheckpoints -Interval "Hourly"
}

# Create initial git checkpoint
Write-Host "`nCreating initial git checkpoint..." -ForegroundColor Cyan
New-GitCheckpoint -Message "🚀 Starting safe orchestration session$(if ($ImplementationPlan) {": $ImplementationPlan"})" -Push:$EnablePush

# Setup command interceptor
Write-Host "`nSetting up command interceptor..." -ForegroundColor Cyan

# Function to intercept and convert commands
function Invoke-SafeCommand {
    param([string]$Command)
    
    # Check if it's a destructive command
    $safeOp = Convert-ToSafeOperation -Command $Command
    
    if ($safeOp.WasConverted) {
        Write-Host "`n⚠️ DESTRUCTIVE OPERATION DETECTED" -ForegroundColor Yellow
        Write-Host "Original: $($safeOp.OriginalCommand)" -ForegroundColor Red
        Write-Host "Safe Alternative: $($safeOp.SafeCommand)" -ForegroundColor Green
        Write-Host $safeOp.Explanation -ForegroundColor Cyan
        
        if (-not $TestMode) {
            Write-Host "`nExecuting safe alternative..." -ForegroundColor Green
            Invoke-Expression $safeOp.SafeCommand
        } else {
            Write-Host "`n[TEST MODE] Would execute: $($safeOp.SafeCommand)" -ForegroundColor Magenta
        }
    } else {
        # Execute original command
        if (-not $TestMode) {
            Invoke-Expression $Command
        } else {
            Write-Host "[TEST MODE] Would execute: $Command" -ForegroundColor Magenta
        }
    }
}

# Example workflow for implementation plans
Write-Host "`n" + ("=" * 80) -ForegroundColor Cyan
Write-Host "SAFE ORCHESTRATION READY" -ForegroundColor Green
Write-Host ("=" * 80) -ForegroundColor Cyan

Write-Host "`nUsage Examples:" -ForegroundColor Yellow
Write-Host "  After completing Hour 1 of implementation:" -ForegroundColor Gray
Write-Host '    Complete-ImplementationPhase -PhaseName "Hour 1" -Summary "Completed core setup" -Push' -ForegroundColor White

Write-Host "`n  To safely handle a delete operation:" -ForegroundColor Gray
Write-Host '    Invoke-SafeCommand "Remove-Item old-config.json"' -ForegroundColor White
Write-Host "    # This will archive the file instead of deleting" -ForegroundColor Green

Write-Host "`n  To create a manual checkpoint:" -ForegroundColor Gray
Write-Host '    New-GitCheckpoint -Message "Feature X implemented" -Push' -ForegroundColor White

Write-Host "`n  To see statistics:" -ForegroundColor Gray
Write-Host '    Show-SafeOperationsSummary' -ForegroundColor White

if ($TestMode) {
    Write-Host "`n🧪 TEST MODE ACTIVE - Commands will be simulated only" -ForegroundColor Magenta
}

# Create helper aliases for common operations
Set-Alias -Name safe -Value Invoke-SafeCommand
Set-Alias -Name checkpoint -Value New-GitCheckpoint
Set-Alias -Name phase-complete -Value Complete-ImplementationPhase
Set-Alias -Name stats -Value Show-SafeOperationsSummary

Write-Host "`nAliases created:" -ForegroundColor Cyan
Write-Host "  safe <command>     - Execute command with safe conversion" -ForegroundColor Gray
Write-Host "  checkpoint         - Create git checkpoint" -ForegroundColor Gray
Write-Host "  phase-complete     - Mark implementation phase complete" -ForegroundColor Gray
Write-Host "  stats             - Show safety statistics" -ForegroundColor Gray

# If running with Claude, provide the directive
if (Get-Process | Where-Object { $_.ProcessName -match "claude" }) {
    Write-Host "`n📋 CLAUDE DIRECTIVE:" -ForegroundColor Yellow
    Write-Host @"
When executing commands during implementation:
1. All Remove-Item, del, rm commands will be automatically converted to Archive operations
2. Git checkpoints are created automatically after each implementation hour
3. Use 'phase-complete' command when finishing each major section
4. All file overwrites are backed up automatically
5. Never use -Force flags as operations are already safe
"@ -ForegroundColor Cyan
}

Write-Host "`n✅ Safe orchestration is active. All destructive operations are protected." -ForegroundColor Green