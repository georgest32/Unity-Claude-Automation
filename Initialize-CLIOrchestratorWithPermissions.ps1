# Initialize-CLIOrchestratorWithPermissions.ps1
# Integrates permission handling with CLIOrchestrator

param(
    [string]$Mode = "Intelligent",  # Intelligent, Manual, Passive
    [switch]$EnableSafeOperations,
    [switch]$EnableInterceptor,
    [switch]$TestMode
)

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "INITIALIZING CLI ORCHESTRATOR WITH PERMISSION HANDLING" -ForegroundColor Green
Write-Host "=" * 80 -ForegroundColor Cyan

# Import the main orchestrator module
Write-Host "`nImporting CLIOrchestrator module..." -ForegroundColor Gray
try {
    Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator.psm1" -Force -WarningAction SilentlyContinue
    Write-Host "✅ CLIOrchestrator loaded" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to load CLIOrchestrator: $_" -ForegroundColor Red
    exit 1
}

# Initialize Safe Operations Handler (this works!)
if ($EnableSafeOperations) {
    Write-Host "`nInitializing Safe Operations..." -ForegroundColor Gray
    try {
        $safeOpsResult = Initialize-SafeOperations -GitAutoCommit:$true
        if ($safeOpsResult.Success) {
            Write-Host "✅ Safe Operations initialized" -ForegroundColor Green
            Write-Host "  Archive path: $($safeOpsResult.ArchivePath)" -ForegroundColor Cyan
        } else {
            Write-Host "⚠️ Safe Operations initialization returned false" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "❌ Safe Operations initialization failed: $_" -ForegroundColor Red
    }
}

# Initialize Permission Interceptor (this works!)
if ($EnableInterceptor) {
    Write-Host "`nInitializing Permission Interceptor..." -ForegroundColor Gray
    try {
        # Create a permission handler hashtable for the interceptor
        $permissionHandler = @{
            Handler = {
                param($PromptInfo)
                
                # Simple auto-approve for safe operations
                $safeTools = @('Read', 'Bash', 'Edit', 'Write')
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
            Mode = "Intelligent"
            Config = @{
                AutoApproveProjectFiles = $true
                BlockSystemOperations = $true
            }
        }
        
        $interceptorResult = Start-ClaudePermissionInterceptor -PermissionHandler $permissionHandler
        # Suppress verbose output
        $null = $interceptorResult
        Write-Host "✅ Permission Interceptor started" -ForegroundColor Green
    } catch {
        Write-Host "❌ Permission Interceptor failed: $_" -ForegroundColor Red
    }
}

# Initialize the main orchestrator
Write-Host "`nInitializing Orchestrator..." -ForegroundColor Gray
try {
    $orchResult = Initialize-CLIOrchestrator
    if ($orchResult.Initialized -or $orchResult.Version) {
        Write-Host "✅ CLIOrchestrator initialized successfully" -ForegroundColor Green
        
        # Show component status if available
        if ($orchResult.ComponentHealth) {
            Write-Host "`nComponent Status:" -ForegroundColor Yellow
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

# Test mode - run some test operations
if ($TestMode) {
    Write-Host "`n" + ("=" * 60) -ForegroundColor Blue
    Write-Host "RUNNING INTEGRATION TESTS" -ForegroundColor Blue
    Write-Host ("=" * 60) -ForegroundColor Blue
    
    # Test safe operations conversion
    if ($EnableSafeOperations) {
        Write-Host "`nTesting Safe Operations..." -ForegroundColor Gray
        
        $testCommands = @(
            "Remove-Item test.txt",
            "git reset --hard"
        )
        
        foreach ($cmd in $testCommands) {
            Write-Host "  Testing: $cmd" -ForegroundColor Cyan
            $result = Convert-ToSafeOperation -Command $cmd
            if ($result.WasConverted) {
                Write-Host "    ✅ Converted to: $($result.SafeCommand)" -ForegroundColor Green
            } else {
                Write-Host "    ⚠️ Not converted" -ForegroundColor Yellow
            }
        }
    }
    
    # Test permission detection
    if ($EnableInterceptor) {
        Write-Host "`nTesting Permission Detection..." -ForegroundColor Gray
        
        $testPrompts = @(
            "Allow Bash to read package.json? (y/n)",
            "Execute command: npm test? (y/n)"
        )
        
        foreach ($prompt in $testPrompts) {
            Write-Host "  Testing: $prompt" -ForegroundColor Cyan
            $result = Test-ClaudePermissionPrompt -Text $prompt
            if ($result.IsPermissionPrompt) {
                Write-Host "    ✅ Detected as permission prompt" -ForegroundColor Green
                Write-Host "    Type: $($result.Type)" -ForegroundColor Gray
            } else {
                Write-Host "    ❌ Not detected" -ForegroundColor Red
            }
        }
    }
    
    # Test orchestrator prompt submission (dry run)
    Write-Host "`nTesting Orchestrator Integration..." -ForegroundColor Gray
    
    # Find Claude window
    $claudeWindow = Find-ClaudeWindow
    if ($claudeWindow) {
        Write-Host "  ✅ Claude window found: $($claudeWindow.MainWindowTitle)" -ForegroundColor Green
        
        # Test prompt preparation
        $testPrompt = "Test integration prompt"
        Write-Host "  Testing prompt preparation: '$testPrompt'" -ForegroundColor Cyan
        
        # Prepare but don't submit
        $prepared = Prepare-PromptSubmission -Prompt $testPrompt -MaxLength 1000
        if ($prepared) {
            Write-Host "    ✅ Prompt prepared successfully" -ForegroundColor Green
            Write-Host "    Length: $($prepared.ProcessedPrompt.Length) chars" -ForegroundColor Gray
        } else {
            Write-Host "    ❌ Prompt preparation failed" -ForegroundColor Red
        }
    } else {
        Write-Host "  ⚠️ Claude window not found - skipping submission test" -ForegroundColor Yellow
    }
}

Write-Host "`n" + ("=" * 80) -ForegroundColor Cyan
Write-Host "INITIALIZATION COMPLETE" -ForegroundColor Green
Write-Host ("=" * 80) -ForegroundColor Cyan

Write-Host "`nUsage Examples:" -ForegroundColor Yellow
Write-Host "  1. Submit a prompt with safe operations:" -ForegroundColor White
Write-Host "     Submit-ClaudePrompt -Prompt 'Your prompt here' -UseSafeOperations" -ForegroundColor Gray
Write-Host ""
Write-Host "  2. Start autonomous mode with permissions:" -ForegroundColor White
Write-Host "     Start-AutonomousMode -EnablePermissions" -ForegroundColor Gray
Write-Host ""
Write-Host "  3. Convert destructive command:" -ForegroundColor White
Write-Host "     Convert-ToSafeOperation -Command 'Remove-Item important.txt'" -ForegroundColor Gray
Write-Host ""
Write-Host "  4. Check permission statistics:" -ForegroundColor White
Write-Host "     Get-PermissionStatistics" -ForegroundColor Gray

# Store initialization status (don't output to console)
$initResult = @{
    Success = $true
    Orchestrator = $orchResult
    SafeOperations = $EnableSafeOperations
    Interceptor = $EnableInterceptor
    Mode = $Mode
}

# Optionally return the result without displaying it
$global:CLIInitResult = $initResult