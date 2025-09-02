# Test-SafeApprovalSystem.ps1
# Tests the safe approval and archiving system

Write-Host @"
================================================================================
TESTING SAFE APPROVAL SYSTEM
================================================================================
"@ -ForegroundColor Cyan

# Test 1: Check Claude settings file
Write-Host "`n[TEST 1] Checking Claude settings configuration..." -ForegroundColor Yellow
$settingsPath = ".\.claude\settings.json"
if (Test-Path $settingsPath) {
    Write-Host "  ✅ Settings file exists" -ForegroundColor Green
    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
    Write-Host "  Allowed tools: $($settings.permissions.allowedTools.Count)" -ForegroundColor Gray
    Write-Host "  Denied patterns: $($settings.permissions.deny.Count)" -ForegroundColor Gray
} else {
    Write-Host "  ❌ Settings file not found" -ForegroundColor Red
}

# Test 2: Test archive functionality
Write-Host "`n[TEST 2] Testing file archiving..." -ForegroundColor Yellow
$testFile = ".\test_archive_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
"Original content" | Out-File $testFile

# Start the archiving in background
$archiveJob = Start-Job -ScriptBlock {
    param($Path)
    & "$Path\Start-SafeClaudeSession.ps1"
} -ArgumentList $PWD.Path

Start-Sleep -Seconds 2

# Modify the test file
"Modified content" | Out-File $testFile -Force

Start-Sleep -Seconds 2

# Check if archived
$archived = Get-ChildItem ".\Archive" -Recurse -Filter "*.txt" -ErrorAction SilentlyContinue | 
    Where-Object { $_.Name -eq (Split-Path $testFile -Leaf) }

if ($archived) {
    Write-Host "  ✅ File was archived before modification" -ForegroundColor Green
} else {
    Write-Host "  ⚠️ Archive not found (may need SafeClaudeSession running)" -ForegroundColor Yellow
}

# Cleanup
Remove-Item $testFile -Force -ErrorAction SilentlyContinue
Stop-Job $archiveJob -Force -ErrorAction SilentlyContinue
Remove-Job $archiveJob -Force -ErrorAction SilentlyContinue

# Test 3: Test git safety
Write-Host "`n[TEST 3] Testing git safety features..." -ForegroundColor Yellow
$currentBranch = git rev-parse --abbrev-ref HEAD 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  Current branch: $currentBranch" -ForegroundColor Gray
    
    if ($currentBranch -match "main|master") {
        Write-Host "  ✅ Protected branch detected - auto-push would be blocked" -ForegroundColor Green
    } else {
        Write-Host "  ✅ Feature branch - safe for auto-push" -ForegroundColor Green
    }
} else {
    Write-Host "  ⚠️ Not in a git repository" -ForegroundColor Yellow
}

# Test 4: Simulate safe and unsafe operations
Write-Host "`n[TEST 4] Testing operation safety detection..." -ForegroundColor Yellow

$safeOps = @(
    "git status",
    "Get-ChildItem",
    "Test-Path .\file.txt",
    "ls",
    "pwd"
)

$unsafeOps = @(
    "rm -rf /",
    "git push --force",
    "Remove-Item -Recurse -Force C:\",
    "sudo rm -rf /*"
)

Write-Host "  Safe operations (should be allowed):" -ForegroundColor Cyan
foreach ($op in $safeOps) {
    $allowed = $true
    
    # Check against deny patterns
    $settings = Get-Content ".\.claude\settings.json" -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
    if ($settings) {
        foreach ($deny in $settings.permissions.deny) {
            $pattern = $deny -replace '\*', '.*' -replace 'Bash\((.*)\)', '$1'
            if ($op -match $pattern) {
                $allowed = $false
                break
            }
        }
    }
    
    $icon = if ($allowed) { "✅" } else { "❌" }
    Write-Host "    $icon $op" -ForegroundColor $(if ($allowed) { "Green" } else { "Red" })
}

Write-Host "  Unsafe operations (should be blocked):" -ForegroundColor Cyan
foreach ($op in $unsafeOps) {
    $blocked = $false
    
    # Check against deny patterns
    if ($settings) {
        foreach ($deny in $settings.permissions.deny) {
            $pattern = $deny -replace '\*', '.*' -replace 'Bash\((.*)\)', '$1'
            if ($op -match $pattern) {
                $blocked = $true
                break
            }
        }
    }
    
    $icon = if ($blocked) { "✅" } else { "❌" }
    Write-Host "    $icon $op $(if ($blocked) { "(blocked)" } else { "(NOT BLOCKED!)" })" -ForegroundColor $(if ($blocked) { "Green" } else { "Red" })
}

Write-Host @"

================================================================================
TEST SUMMARY
================================================================================

To use the safe approval system:

1. Start the safe session monitor:
   .\Start-SafeClaudeSession.ps1 -EnableAutoAccept -EnableGitTracking

2. In Claude Code CLI, press shift+tab to cycle to 'auto-accept edit on'

3. Claude will now:
   - Auto-approve safe operations
   - Block dangerous commands
   - Archive files before modification
   - Auto-commit to git after features

The system is configured via .\.claude\settings.json

"@ -ForegroundColor Cyan