<#
.SYNOPSIS
    Starts the CLIOrchestrator with NUGGETRON window detection
#>

[CmdletBinding()]
param(
    [int]$MaxExecutionTimeMinutes = 60,
    [int]$MonitorIntervalSeconds = 5
)

$ErrorActionPreference = 'Continue'

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "CLI ORCHESTRATOR - NUGGETRON MODE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Load the regular orchestrator module
Write-Host "`nLoading orchestration module..." -ForegroundColor Yellow
Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator-FullFeatured.psd1" -Force

# Override the window detection to ONLY look for NUGGETRON
Write-Host "`nConfiguring NUGGETRON detection..." -ForegroundColor Yellow

# Create simplified window detection function
function Global:Get-ClaudeWindowInfo {
    Write-Host "  Searching for NUGGETRON window..." -ForegroundColor Cyan
    
    # Check protected registration first
    $protectedRegPath = ".\.nuggetron_registration.json"
    if (Test-Path $protectedRegPath) {
        $reg = Get-Content $protectedRegPath -Raw | ConvertFrom-Json
        if ($reg.ProcessId) {
            $proc = Get-Process -Id $reg.ProcessId -ErrorAction SilentlyContinue
            if ($proc -and $proc.MainWindowTitle -eq '**NUGGETRON**') {
                Write-Host "    [OK] Found NUGGETRON via protected registration!" -ForegroundColor Green
                Write-Host "    PID: $($proc.Id), Title: '$($proc.MainWindowTitle)'" -ForegroundColor Gray
                return @{
                    ProcessId = $proc.Id
                    WindowHandle = $proc.MainWindowHandle
                    WindowTitle = $proc.MainWindowTitle
                    ProcessName = $proc.ProcessName
                }
            }
        }
    }
    
    # Direct search for NUGGETRON
    $nuggetron = Get-Process | Where-Object {
        $_.ProcessName -match 'pwsh|powershell' -and
        $_.MainWindowTitle -eq '**NUGGETRON**' -and
        $_.MainWindowHandle -ne 0
    } | Select-Object -First 1
    
    if ($nuggetron) {
        Write-Host "    [OK] Found NUGGETRON!" -ForegroundColor Green
        Write-Host "    PID: $($nuggetron.Id), Title: '$($nuggetron.MainWindowTitle)'" -ForegroundColor Gray
        
        # Save to protected registration
        @{
            ProcessId = $nuggetron.Id
            WindowHandle = [int64]$nuggetron.MainWindowHandle
            WindowTitle = '**NUGGETRON**'
            UniqueIdentifier = '**NUGGETRON**'
            ProcessName = $nuggetron.ProcessName
            RegisteredAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Protected = $true
        } | ConvertTo-Json | Set-Content $protectedRegPath -Force
        
        return @{
            ProcessId = $nuggetron.Id
            WindowHandle = $nuggetron.MainWindowHandle
            WindowTitle = $nuggetron.MainWindowTitle
            ProcessName = $nuggetron.ProcessName
        }
    }
    
    Write-Host "    [ERROR] NUGGETRON not found!" -ForegroundColor Red
    Write-Host "    Available PowerShell windows:" -ForegroundColor Yellow
    Get-Process | Where-Object {
        $_.ProcessName -match 'pwsh|powershell' -and
        $_.MainWindowHandle -ne 0
    } | ForEach-Object {
        Write-Host "      - PID $($_.Id): '$($_.MainWindowTitle)'" -ForegroundColor Gray
    }
    
    return $null
}

# Override Find-ClaudeWindow to use our function
function Global:Find-ClaudeWindow {
    return Get-ClaudeWindowInfo
}

Write-Host "`nStarting orchestration..." -ForegroundColor Cyan
Write-Host "Configuration:" -ForegroundColor Gray
Write-Host "  - Max execution time: $MaxExecutionTimeMinutes minutes" -ForegroundColor Gray
Write-Host "  - Monitor interval: $MonitorIntervalSeconds seconds" -ForegroundColor Gray
Write-Host "  - Response directory: .\ClaudeResponses\Autonomous" -ForegroundColor Gray
Write-Host "  - Looking for window: **NUGGETRON**" -ForegroundColor Magenta

# Find NUGGETRON before starting
$window = Get-ClaudeWindowInfo
if (-not $window) {
    Write-Host "`n[ERROR] Cannot start without NUGGETRON window!" -ForegroundColor Red
    Write-Host "Please run .\Register-NUGGETRON-Protected.ps1 in your Claude terminal" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n[OK] NUGGETRON detected, starting monitoring..." -ForegroundColor Green

# Start the orchestration loop
$startTime = Get-Date
$endTime = $startTime.AddMinutes($MaxExecutionTimeMinutes)
$responseDir = ".\ClaudeResponses\Autonomous"
$cycleCount = 0
$stats = @{
    Responses = 0
    Decisions = 0
    Actions = 0
}

while ((Get-Date) -lt $endTime) {
    $cycleCount++
    $runtime = [math]::Round(((Get-Date) - $startTime).TotalSeconds)
    
    Write-Host "`n--- Monitoring Cycle $cycleCount ---" -ForegroundColor Cyan
    Write-Host "Runtime: $('{0:mm\:ss}' -f ([timespan]::FromSeconds($runtime)))" -ForegroundColor Gray
    
    # Look for new JSON files
    $newFiles = Get-ChildItem -Path $responseDir -Filter "*.json" -ErrorAction SilentlyContinue |
                Where-Object { 
                    $_.LastWriteTime -gt $startTime -and
                    -not (Test-Path "$($_.FullName).processed")
                }
    
    if ($newFiles) {
        Write-Host "Found $($newFiles.Count) new response file(s)" -ForegroundColor Yellow
        
        foreach ($file in $newFiles) {
            Write-Host "  Processing: $($file.Name)" -ForegroundColor Gray
            
            try {
                # Mark as processed immediately
                "Processed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | 
                    Set-Content "$($file.FullName).processed" -Force
                
                # Read and process the JSON
                $content = Get-Content $file.FullName -Raw | ConvertFrom-Json
                
                if ($content.prompt_type -eq 'Testing' -and $content.RESPONSE -match 'TEST') {
                    Write-Host "    [ACTION] Test execution requested" -ForegroundColor Green
                    $stats.Responses++
                    $stats.Decisions++
                    $stats.Actions++
                    
                    # Execute the test
                    if ($content.details -or ($content.RESPONSE -match '\.ps1')) {
                        $testScript = if ($content.details) { $content.details } 
                                     else { ($content.RESPONSE -match '([\w\-]+\.ps1)')[0] }
                        
                        Write-Host "    Executing test: $testScript" -ForegroundColor Cyan
                        
                        if (Test-Path $testScript) {
                            $testProc = Start-Process powershell -ArgumentList "-NoProfile -File $testScript" `
                                                    -WindowStyle Normal -PassThru
                            Write-Host "    Test launched (PID: $($testProc.Id))" -ForegroundColor Green
                        } else {
                            Write-Host "    [ERROR] Test script not found: $testScript" -ForegroundColor Red
                        }
                    }
                }
            }
            catch {
                Write-Host "    [ERROR] Failed to process: $_" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "No new responses to process" -ForegroundColor Gray
    }
    
    Write-Host "Status: Responses: $($stats.Responses), Decisions: $($stats.Decisions), Actions: $($stats.Actions)" -ForegroundColor Gray
    
    # Check if NUGGETRON is still available
    if ($cycleCount % 10 -eq 0) {
        $window = Get-ClaudeWindowInfo
        if (-not $window) {
            Write-Host "[WARN] NUGGETRON window lost!" -ForegroundColor Yellow
        }
    }
    
    Start-Sleep -Seconds $MonitorIntervalSeconds
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Orchestration completed" -ForegroundColor Cyan
Write-Host "Total runtime: $('{0:mm\:ss}' -f ($endTime - $startTime))" -ForegroundColor Gray
Write-Host "Final stats:" -ForegroundColor Gray
Write-Host "  - Responses: $($stats.Responses)" -ForegroundColor Gray
Write-Host "  - Decisions: $($stats.Decisions)" -ForegroundColor Gray
Write-Host "  - Actions: $($stats.Actions)" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan