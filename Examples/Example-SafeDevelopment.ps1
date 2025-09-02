# Example-SafeDevelopment.ps1
# Example of using permission handling for safe development workflow

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "SAFE DEVELOPMENT WORKFLOW EXAMPLE" -ForegroundColor Green
Write-Host "=" * 80 -ForegroundColor Cyan

# This example shows how to use the permission handling system
# for a typical development workflow with maximum safety

# 1. Initialize the safe development environment
Write-Host "`n[Step 1] Initializing safe development environment..." -ForegroundColor Yellow

# Import modules
Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Core\PermissionHandler.psm1" -Force
Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Core\SafeOperationsHandler.psm1" -Force

# Initialize with maximum safety
Initialize-PermissionHandler -Mode "Intelligent"
Initialize-SafeOperations -GitAutoCommit:$true -GitPushEnabled:$false

# Add custom safety rules for development
Add-PermissionRule -Name "AllowTestFiles" `
    -Pattern "(?i)(test|spec|example|sample|demo)" `
    -Decision "approve" `
    -Confidence 0.9 `
    -Reason "Test files are safe to modify"

Add-PermissionRule -Name "DenyProductionFiles" `
    -Pattern "(?i)(production|prod|live|master\.)" `
    -Decision "deny" `
    -Confidence 1.0 `
    -Reason "Production files require manual review"

Write-Host "✅ Development environment configured with safety rules" -ForegroundColor Green

# 2. Start an implementation plan with checkpoints
Write-Host "`n[Step 2] Starting implementation plan with git checkpoints..." -ForegroundColor Yellow

Start-ImplementationPlan -PlanName "Example Feature Development" -InitialPhase "Setup"

Write-Host "✅ Implementation plan started with automatic git checkpoints" -ForegroundColor Green

# 3. Simulate development activities with safety
Write-Host "`n[Step 3] Simulating safe development activities..." -ForegroundColor Yellow

# Safe operation examples
$safeOperations = @(
    "# Reading files (always safe)",
    'Get-Content "README.md"',
    "",
    "# Writing to test files (approved by rule)",
    'Set-Content "test-example.txt" "Test content"',
    "",
    "# Deleting files (converted to archive)",
    'Remove-Item "old-config.json"',  # This will be archived instead
    "",
    "# Git operations (safe commands approved)",
    'git status',
    'git add .',
    'git commit -m "Safe development checkpoint"'
)

foreach ($operation in $safeOperations) {
    if ($operation.StartsWith("#") -or [string]::IsNullOrWhiteSpace($operation)) {
        Write-Host $operation -ForegroundColor Gray
        continue
    }
    
    Write-Host "Executing: $operation" -ForegroundColor Cyan
    
    # Check if it's a destructive operation
    $safeOp = Convert-ToSafeOperation -Command $operation
    
    if ($safeOp.WasConverted) {
        Write-Host "  ⚠️ Converted to safe operation: $($safeOp.SafeCommand)" -ForegroundColor Yellow
        Write-Host "  Reason: $($safeOp.Explanation)" -ForegroundColor Gray
    } else {
        Write-Host "  ✅ Operation is already safe" -ForegroundColor Green
    }
    
    Start-Sleep -Milliseconds 500  # Simulate execution time
}

# 4. Complete a development phase
Write-Host "`n[Step 4] Completing development phase..." -ForegroundColor Yellow

Complete-ImplementationPhase -PhaseName "Setup Phase" `
    -Summary "Configured development environment and implemented basic features"

Write-Host "✅ Development phase completed with git checkpoint" -ForegroundColor Green

# 5. Show safety statistics
Write-Host "`n[Step 5] Development safety statistics..." -ForegroundColor Yellow

Show-SafeOperationsSummary
$permStats = Get-PermissionStatistics

Write-Host "`nPermission Statistics:" -ForegroundColor Cyan
Write-Host "  Rules Added: 2" -ForegroundColor White
Write-Host "  Safety Mode: Active" -ForegroundColor White

Write-Host "`n" + ("=" * 80) -ForegroundColor Cyan
Write-Host "SAFE DEVELOPMENT WORKFLOW COMPLETE" -ForegroundColor Green
Write-Host ("=" * 80) -ForegroundColor Cyan

Write-Host "`nWhat was accomplished:" -ForegroundColor Yellow
Write-Host "  ✅ Configured intelligent permission handling" -ForegroundColor Green
Write-Host "  ✅ Set up automatic git checkpointing" -ForegroundColor Green
Write-Host "  ✅ Added custom safety rules for development" -ForegroundColor Green
Write-Host "  ✅ Simulated safe operations with conversion" -ForegroundColor Green
Write-Host "  ✅ Completed development phase with checkpoint" -ForegroundColor Green

Write-Host "`nKey Safety Features Demonstrated:" -ForegroundColor Yellow
Write-Host "  • Destructive operations converted to safe alternatives" -ForegroundColor Cyan
Write-Host "  • Custom rules for different file types" -ForegroundColor Cyan
Write-Host "  • Automatic git checkpointing for rollback capability" -ForegroundColor Cyan
Write-Host "  • Real-time safety statistics and monitoring" -ForegroundColor Cyan

Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "  • Use with actual Claude CLI for real development" -ForegroundColor White
Write-Host "  • Customize rules for your specific project needs" -ForegroundColor White
Write-Host "  • Enable git push for remote backup if desired" -ForegroundColor White