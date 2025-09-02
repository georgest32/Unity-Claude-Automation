<#
.SYNOPSIS
    Critical fixes for CLI Orchestrator issues
    
.DESCRIPTION
    1. Prevents orchestrator from detecting itself as Claude window
    2. Adds JSON file processing markers
    3. Prevents duplicate test execution
#>

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "CRITICAL ORCHESTRATOR FIXES" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. First, update the system_status.json to clear wrong window registration
Write-Host "`n1. Clearing incorrect window registration..." -ForegroundColor Yellow
$statusPath = ".\system_status.json"
if (Test-Path $statusPath) {
    $status = Get-Content $statusPath -Raw | ConvertFrom-Json
    if ($status.SystemInfo.ClaudeCodeCLI) {
        # Check if it's pointing to the orchestrator itself
        if ($status.SystemInfo.ClaudeCodeCLI.WindowTitle -like "*CLIOrchestrator*" -or
            $status.SystemInfo.ClaudeCodeCLI.WindowTitle -like "*Subsystem*") {
            Write-Host "   Found incorrect registration: $($status.SystemInfo.ClaudeCodeCLI.WindowTitle)" -ForegroundColor Red
            Write-Host "   Clearing it..." -ForegroundColor Yellow
            
            # Clear the incorrect registration
            $status.SystemInfo.ClaudeCodeCLI = $null
            $status | ConvertTo-Json -Depth 10 | Set-Content $statusPath -Encoding UTF8
            Write-Host "   ✅ Cleared incorrect registration" -ForegroundColor Green
        }
    }
}

# 2. Mark existing JSON files as processed
Write-Host "`n2. Marking existing JSON files as processed..." -ForegroundColor Yellow
$jsonFiles = Get-ChildItem ".\ClaudeResponses\Autonomous\*.json" -ErrorAction SilentlyContinue
foreach ($file in $jsonFiles) {
    $processedFile = "$($file.FullName).processed"
    if (-not (Test-Path $processedFile)) {
        "Processed by fix script at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Set-Content $processedFile
        Write-Host "   Marked: $($file.Name)" -ForegroundColor Gray
    }
}
Write-Host "   ✅ JSON files marked" -ForegroundColor Green

# 3. Fix the orchestrator's response processing to add processed markers
Write-Host "`n3. Patching orchestrator response processing..." -ForegroundColor Yellow

# Create a patch for Start-CLIOrchestrator-Fixed.ps1
$orchPath = ".\Start-CLIOrchestrator-Fixed.ps1"
if (Test-Path $orchPath) {
    $content = Get-Content $orchPath -Raw
    
    # Check if we've already patched it
    if ($content -notmatch '\.processed') {
        Write-Host "   Patching Start-CLIOrchestrator-Fixed.ps1..." -ForegroundColor Gray
        
        # Add processing marker logic after processing responses
        $patchedContent = $content -replace '(Get-ChildItem.*?-Filter.*?\*.json.*?-ErrorAction.*?SilentlyContinue)', @'
Get-ChildItem -Path $responseDir -Filter "*.json" -ErrorAction SilentlyContinue |
                Where-Object { 
                    $_.LastWriteTime -gt $cycleStartTime -and
                    -not (Test-Path "$($_.FullName).processed")
                }
'@
        
        # Add marker creation after processing
        $patchedContent = $patchedContent -replace '(Write-Host.*?"  Action executed successfully")', @'
$1
                    
                    # Mark JSON file as processed to prevent re-processing
                    $processedMarker = "$($responseFile.FullName).processed"
                    "Processed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Set-Content $processedMarker -Force
                    Write-Host "  JSON marked as processed" -ForegroundColor DarkGray
'@
        
        # Save patched version
        $patchedContent | Set-Content $orchPath -Encoding UTF8
        Write-Host "   ✅ Patched orchestrator script" -ForegroundColor Green
    } else {
        Write-Host "   ℹ️ Already patched" -ForegroundColor Gray
    }
}

# 4. Create a proper window registration script for the user
Write-Host "`n4. Creating proper registration script..." -ForegroundColor Yellow
$regScript = @'
<#
.SYNOPSIS
    Properly registers THIS window as the Claude CLI window
#>

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "CLAUDE CLI WINDOW REGISTRATION" -ForegroundColor Cyan  
Write-Host "========================================" -ForegroundColor Cyan

# Generate unique identifier
$uniqueID = "CLAUDE_CODE_CLI_TERMINAL_$(Get-Date -Format 'HHmmss')"
$host.UI.RawUI.WindowTitle = $uniqueID

Write-Host "`n✅ Window title set to: $uniqueID" -ForegroundColor Green
Write-Host "This window will now be properly detected by the orchestrator" -ForegroundColor Green

# Update system_status.json
$statusPath = ".\system_status.json"
if (Test-Path $statusPath) {
    $status = Get-Content $statusPath -Raw | ConvertFrom-Json -AsHashtable
    if (-not $status) { $status = @{} }
    if (-not $status.SystemInfo) { $status.SystemInfo = @{} }
    
    $status.SystemInfo.ClaudeCodeCLI = @{
        ProcessId = $PID
        WindowHandle = [int64](Get-Process -Id $PID).MainWindowHandle
        WindowTitle = $uniqueID
        UniqueIdentifier = $uniqueID
        ProcessName = (Get-Process -Id $PID).ProcessName
        LastDetected = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        IsClaudeCodeCLI = $true
        DetectionMethod = "UniqueRegistration"
    }
    
    $status | ConvertTo-Json -Depth 10 | Set-Content $statusPath -Encoding UTF8
    Write-Host "✅ Registration saved to system_status.json" -ForegroundColor Green
} else {
    Write-Host "❌ Could not find system_status.json" -ForegroundColor Red
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "REGISTRATION COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
'@

$regScript | Set-Content ".\Register-ThisWindow-As-Claude.ps1" -Encoding UTF8
Write-Host "   ✅ Created: Register-ThisWindow-As-Claude.ps1" -ForegroundColor Green

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "✅ CRITICAL FIXES APPLIED!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host "`n📋 NEXT STEPS:" -ForegroundColor Yellow
Write-Host "1. STOP the current orchestrator (Ctrl+C)" -ForegroundColor White
Write-Host "2. In THIS terminal (Claude CLI), run:" -ForegroundColor White
Write-Host "   .\Register-ThisWindow-As-Claude.ps1" -ForegroundColor Cyan
Write-Host "3. Then restart the orchestrator in a DIFFERENT window:" -ForegroundColor White
Write-Host "   .\Start-CLIOrchestrator-Fixed.ps1" -ForegroundColor Cyan
Write-Host "`nThis ensures the orchestrator finds the correct window!" -ForegroundColor Green