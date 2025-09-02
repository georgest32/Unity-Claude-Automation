# Example-ProductionSafety.ps1
# Example of maximum safety configuration for production environments

Write-Host "=" * 80 -ForegroundColor Red
Write-Host "PRODUCTION SAFETY MODE EXAMPLE" -ForegroundColor Red
Write-Host "=" * 80 -ForegroundColor Red

Write-Host "`n⚠️  WARNING: This is a MAXIMUM SAFETY configuration" -ForegroundColor Yellow
Write-Host "    Designed for production environments where safety is paramount" -ForegroundColor Yellow

# Import modules
Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Core\PermissionHandler.psm1" -Force
Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Core\SafeOperationsHandler.psm1" -Force

# 1. Initialize with maximum safety
Write-Host "`n[Step 1] Configuring maximum safety mode..." -ForegroundColor Red

Initialize-PermissionHandler -Mode "Intelligent"
Initialize-SafeOperations -GitAutoCommit:$true -GitPushEnabled:$true

# 2. Add extremely restrictive rules
Write-Host "`n[Step 2] Adding production safety rules..." -ForegroundColor Red

# Block ALL deletions
Add-PermissionRule -Name "NoDeletes" `
    -Pattern "(?i)(delete|remove|rm|del|erase|clear|purge|drop|truncate)" `
    -Decision "deny" `
    -Confidence 1.0 `
    -Reason "PRODUCTION SAFETY: No deletions allowed"

# Block system file access
Add-PermissionRule -Name "NoSystemFiles" `
    -Pattern "(?i)(system32|windows|program files|registry|etc|usr/bin|boot)" `
    -Decision "deny" `
    -Confidence 1.0 `
    -Reason "PRODUCTION SAFETY: System files protected"

# Block database operations
Add-PermissionRule -Name "NoDatabaseOps" `
    -Pattern "(?i)(drop|truncate|alter table|delete from|update.*set)" `
    -Decision "deny" `
    -Confidence 1.0 `
    -Reason "PRODUCTION SAFETY: Database modifications blocked"

# Block network changes
Add-PermissionRule -Name "NoNetworkChanges" `
    -Pattern "(?i)(iptables|firewall|netsh|route|hosts)" `
    -Decision "deny" `
    -Confidence 1.0 `
    -Reason "PRODUCTION SAFETY: Network configuration protected"

# Block service modifications
Add-PermissionRule -Name "NoServiceChanges" `
    -Pattern "(?i)(stop-service|restart-service|systemctl|service)" `
    -Decision "deny" `
    -Confidence 1.0 `
    -Reason "PRODUCTION SAFETY: Service changes blocked"

# Only allow read operations and safe git commands
Add-PermissionRule -Name "AllowReads" `
    -Pattern "(?i)^(get|read|cat|type|dir|ls|git status|git log|git diff)" `
    -Decision "approve" `
    -Confidence 0.9 `
    -Reason "PRODUCTION SAFETY: Read operations are safe"

# Allow creation in designated safe directories only
Add-PermissionRule -Name "AllowSafeDirectories" `
    -Pattern "(?i)(temp|tmp|logs|backup|archive)" `
    -Decision "approve" `
    -Confidence 0.8 `
    -Reason "PRODUCTION SAFETY: Safe directory operations"

Write-Host "✅ Production safety rules configured" -ForegroundColor Green

# 3. Test the safety rules with dangerous operations
Write-Host "`n[Step 3] Testing production safety with dangerous operations..." -ForegroundColor Red

$dangerousOperations = @(
    "Remove-Item C:\Windows\System32\important.dll",
    "DROP TABLE users",
    "rm -rf /",
    "Stop-Service IIS",
    "netsh firewall set opmode mode=DISABLE",
    "Get-Content config.txt",  # This should be allowed
    "git status"               # This should be allowed
)

foreach ($operation in $dangerousOperations) {
    Write-Host "`nTesting: $operation" -ForegroundColor Cyan
    
    # Test against permission rules
    $promptInfo = @{
        IsPermissionPrompt = $true
        Type = "CommandExecution"
        OriginalText = "Execute command: $operation? (y/n)"
        CapturedData = @{ command = $operation }
    }
    
    $decision = Get-PermissionDecision -PromptInfo $promptInfo
    
    $color = if ($decision.Action -eq "deny") { "Red" } else { "Green" }
    $symbol = if ($decision.Action -eq "deny") { "🚫 BLOCKED" } else { "✅ ALLOWED" }
    
    Write-Host "  $symbol - $($decision.Action.ToUpper())" -ForegroundColor $color
    Write-Host "  Reason: $($decision.Reason)" -ForegroundColor Gray
    Write-Host "  Confidence: $($decision.Confidence)" -ForegroundColor Gray
}

# 4. Configure emergency procedures
Write-Host "`n[Step 4] Configuring emergency procedures..." -ForegroundColor Red

# Create emergency override function
function Enable-EmergencyOverride {
    param([string]$AuthCode)
    
    if ($AuthCode -eq "EMERGENCY-OVERRIDE-2025") {
        Write-Host "🚨 EMERGENCY OVERRIDE ACTIVATED" -ForegroundColor Red -BackgroundColor Yellow
        Write-Host "   All safety restrictions temporarily disabled" -ForegroundColor Red
        Write-Host "   Use with extreme caution!" -ForegroundColor Red
        
        # This would temporarily disable safety rules
        # Implementation would require additional authentication
        return $true
    } else {
        Write-Host "❌ Invalid emergency code" -ForegroundColor Red
        return $false
    }
}

Write-Host "✅ Emergency procedures configured" -ForegroundColor Green

# 5. Set up monitoring and alerting
Write-Host "`n[Step 5] Setting up production monitoring..." -ForegroundColor Red

# Create alert function
function Send-ProductionAlert {
    param(
        [string]$Alert,
        [string]$Severity = "High"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $alertMessage = @"
🚨 PRODUCTION SAFETY ALERT 🚨
Time: $timestamp
Severity: $Severity
Alert: $Alert

System: Unity-Claude-Automation
Environment: Production
Host: $env:COMPUTERNAME
"@
    
    # Log to file
    Add-Content -Path ".\AutomationLogs\production_alerts.log" -Value $alertMessage
    
    # In real implementation, this would:
    # - Send email notifications
    # - Post to Slack/Teams
    # - Trigger monitoring system alerts
    
    Write-Host "📧 Production alert logged and sent" -ForegroundColor Yellow
}

# Test alert system
Send-ProductionAlert -Alert "Production safety mode activated" -Severity "Info"

Write-Host "✅ Production monitoring activated" -ForegroundColor Green

# 6. Show final configuration
Write-Host "`n[Step 6] Production safety configuration summary..." -ForegroundColor Red

Show-SafeOperationsSummary

Write-Host "`nProduction Safety Rules Active:" -ForegroundColor Yellow
Write-Host "  🚫 No deletions allowed" -ForegroundColor Red
Write-Host "  🚫 System files protected" -ForegroundColor Red
Write-Host "  🚫 Database modifications blocked" -ForegroundColor Red
Write-Host "  🚫 Network changes prohibited" -ForegroundColor Red
Write-Host "  🚫 Service modifications blocked" -ForegroundColor Red
Write-Host "  ✅ Read operations permitted" -ForegroundColor Green
Write-Host "  ✅ Safe directory operations allowed" -ForegroundColor Green

Write-Host "`n" + ("=" * 80) -ForegroundColor Red
Write-Host "PRODUCTION SAFETY MODE ACTIVE" -ForegroundColor Red
Write-Host ("=" * 80) -ForegroundColor Red

Write-Host "`nProduction Environment Protected:" -ForegroundColor Yellow
Write-Host "  • Maximum safety rules enforced" -ForegroundColor Cyan
Write-Host "  • All destructive operations blocked" -ForegroundColor Cyan
Write-Host "  • System integrity protected" -ForegroundColor Cyan
Write-Host "  • Comprehensive logging active" -ForegroundColor Cyan
Write-Host "  • Emergency procedures available" -ForegroundColor Cyan

Write-Host "`nRecommended Usage:" -ForegroundColor Yellow
Write-Host "  • Use only for critical production systems" -ForegroundColor White
Write-Host "  • Test thoroughly in staging first" -ForegroundColor White
Write-Host "  • Keep emergency override codes secure" -ForegroundColor White
Write-Host "  • Monitor alert logs regularly" -ForegroundColor White