# Export-ErrorsForClaude-EventLog.ps1
# Enhanced version with Windows Event Log integration
# Captures and formats error logs for sharing with Claude

[CmdletBinding()]
param(
    [string]$ErrorType = 'Last',  # Last, Today, All, Custom
    [datetime]$StartTime,
    [datetime]$EndTime = (Get-Date),
    [switch]$IncludeConsole,
    [switch]$IncludeEditorLog,
    [switch]$IncludeTestResults,
    [switch]$CopyToClipboard,
    [switch]$OpenInNotepad,
    [switch]$NoEventLog  # Option to disable event logging
)

$ErrorActionPreference = 'Continue'

# Import Event Log module
$eventLogAvailable = $false
if (-not $NoEventLog) {
    try {
        Import-Module "$PSScriptRoot\..\Modules\Unity-Claude-EventLog" -ErrorAction SilentlyContinue
        $eventLogAvailable = $true
        Write-Host "Event logging enabled" -ForegroundColor Green
    }
    catch {
        Write-Warning "Event log module not available. Continuing without event logging."
    }
}

# Generate correlation ID for this export session
$correlationId = [guid]::NewGuid()

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Error Log Export for Claude Analysis" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Correlation ID: $correlationId" -ForegroundColor Gray
Write-Host ""

# Log export start event
if ($eventLogAvailable) {
    Write-UCEventLog -Message "Unity error export started" `
        -EntryType Information `
        -Component Unity `
        -Action "ExportStart" `
        -Details @{
            ErrorType = $ErrorType
            StartTime = if ($StartTime) { $StartTime.ToString() } else { "N/A" }
            EndTime = $EndTime.ToString()
            Options = @{
                IncludeConsole = $IncludeConsole.IsPresent
                IncludeEditorLog = $IncludeEditorLog.IsPresent
                IncludeTestResults = $IncludeTestResults.IsPresent
            }
        } `
        -CorrelationId $correlationId
}

# Collect all relevant logs
$exportContent = @()
$exportContent += "# Unity-Claude Automation Error Report"
$exportContent += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$exportContent += "Machine: $env:COMPUTERNAME"
$exportContent += "User: $env:USERNAME"
$exportContent += "Correlation ID: $correlationId"
$exportContent += ""

#region Automation Logs

Write-Host "Collecting automation logs..." -ForegroundColor Yellow
$automationLogsFound = 0

$logDir = Join-Path $PSScriptRoot 'AutomationLogs'
if (Test-Path $logDir) {
    $logFiles = Get-ChildItem -Path $logDir -Filter "automation_*.log" | Sort-Object LastWriteTime -Descending
    
    switch ($ErrorType) {
        'Last' {
            $targetLogs = $logFiles | Select-Object -First 1
        }
        'Today' {
            $today = Get-Date -Format 'yyyyMMdd'
            $targetLogs = $logFiles | Where-Object { $_.Name -like "*$today*" }
        }
        'All' {
            $targetLogs = $logFiles | Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-7) }
        }
        'Custom' {
            if ($StartTime) {
                $targetLogs = $logFiles | Where-Object { 
                    $_.LastWriteTime -ge $StartTime -and $_.LastWriteTime -le $EndTime 
                }
            }
        }
    }
    
    if ($targetLogs) {
        $exportContent += "## Automation Logs"
        $exportContent += ""
        
        foreach ($log in $targetLogs) {
            Write-Host "  Adding: $($log.Name)" -ForegroundColor Gray
            $automationLogsFound++
            
            $exportContent += "### $($log.Name)"
            $exportContent += "Last Modified: $($log.LastWriteTime)"
            $exportContent += '```'
            $exportContent += Get-Content $log.FullName -ErrorAction SilentlyContinue
            $exportContent += '```'
            $exportContent += ""
        }
        
        Write-Host "  Found $automationLogsFound automation log(s)" -ForegroundColor Green
    }
    else {
        Write-Host "  No automation logs found for specified criteria" -ForegroundColor Yellow
    }
}

#endregion

#region Unity Editor Log

if ($IncludeEditorLog) {
    Write-Host "Collecting Unity Editor log..." -ForegroundColor Yellow
    
    $editorLogPath = "$env:LOCALAPPDATA\Unity\Editor\Editor.log"
    if (Test-Path $editorLogPath) {
        $editorLogInfo = Get-Item $editorLogPath
        $exportContent += "## Unity Editor Log"
        $exportContent += "Path: $editorLogPath"
        $exportContent += "Size: $([math]::Round($editorLogInfo.Length / 1MB, 2)) MB"
        $exportContent += "Last Modified: $($editorLogInfo.LastWriteTime)"
        $exportContent += ""
        
        # Get compilation errors specifically
        $editorContent = Get-Content $editorLogPath -ErrorAction SilentlyContinue
        $errorLines = $editorContent | Select-String -Pattern "error CS\d+|Error:|Failed to compile|Compilation failed"
        
        if ($errorLines) {
            $exportContent += "### Compilation Errors Found"
            $exportContent += '```'
            $exportContent += $errorLines -join "`n"
            $exportContent += '```'
            
            # Log compilation errors detected
            if ($eventLogAvailable) {
                Write-UCEventLog -Message "Unity compilation errors detected" `
                    -EntryType Warning `
                    -Component Unity `
                    -Action "ErrorsDetected" `
                    -Details @{
                        ErrorCount = $errorLines.Count
                        FirstError = if ($errorLines[0]) { $errorLines[0].ToString() } else { "N/A" }
                        LogSize = "$([math]::Round($editorLogInfo.Length / 1MB, 2)) MB"
                    } `
                    -CorrelationId $correlationId
            }
            
            Write-Host "  Found $($errorLines.Count) compilation error(s)" -ForegroundColor Red
        }
        else {
            $exportContent += "*No compilation errors found in Editor log*"
            Write-Host "  No compilation errors found" -ForegroundColor Green
        }
        
        # Add last 100 lines for context
        $exportContent += ""
        $exportContent += "### Last 100 Lines of Editor Log"
        $exportContent += '```'
        $exportContent += $editorContent | Select-Object -Last 100
        $exportContent += '```'
    }
    else {
        Write-Host "  Unity Editor log not found" -ForegroundColor Yellow
        $exportContent += "## Unity Editor Log"
        $exportContent += "*Editor log not found at: $editorLogPath*"
    }
    $exportContent += ""
}

#endregion

#region Console Output

if ($IncludeConsole) {
    Write-Host "Collecting console output..." -ForegroundColor Yellow
    
    $consoleLogPath = Join-Path $PSScriptRoot "ConsoleOutput.log"
    if (Test-Path $consoleLogPath) {
        $exportContent += "## Console Output"
        $exportContent += '```'
        $exportContent += Get-Content $consoleLogPath -ErrorAction SilentlyContinue | Select-Object -Last 200
        $exportContent += '```'
        $exportContent += ""
        Write-Host "  Console output included" -ForegroundColor Green
    }
    else {
        Write-Host "  No console output log found" -ForegroundColor Yellow
    }
}

#endregion

#region Test Results

if ($IncludeTestResults) {
    Write-Host "Collecting test results..." -ForegroundColor Yellow
    
    $testResultsPath = Join-Path (Split-Path $PSScriptRoot) "Testing"
    if (Test-Path $testResultsPath) {
        $recentTests = Get-ChildItem -Path $testResultsPath -Filter "*Results*.txt" | 
            Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-1) } |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 3
        
        if ($recentTests) {
            $exportContent += "## Recent Test Results"
            foreach ($test in $recentTests) {
                Write-Host "  Adding: $($test.Name)" -ForegroundColor Gray
                $exportContent += "### $($test.Name)"
                $exportContent += '```'
                $exportContent += Get-Content $test.FullName -ErrorAction SilentlyContinue | Select-Object -First 100
                $exportContent += '```'
                $exportContent += ""
            }
            Write-Host "  Found $($recentTests.Count) recent test result(s)" -ForegroundColor Green
        }
    }
}

#endregion

#region Export and Save

# Save to file
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$exportFileName = "ErrorExport_$timestamp.md"
$exportPath = Join-Path $PSScriptRoot $exportFileName

try {
    $exportContent | Out-String | Set-Content -Path $exportPath -Encoding UTF8
    Write-Host ""
    Write-Host "Export saved to: $exportPath" -ForegroundColor Green
    
    # Log successful export
    if ($eventLogAvailable) {
        Write-UCEventLog -Message "Unity error export completed successfully" `
            -EntryType Information `
            -Component Unity `
            -Action "ExportComplete" `
            -Details @{
                FileName = $exportFileName
                FilePath = $exportPath
                FileSize = (Get-Item $exportPath).Length
                LinesExported = $exportContent.Count
                AutomationLogs = $automationLogsFound
                Duration = ((Get-Date) - $correlationId.CreationTime).TotalSeconds
            } `
            -CorrelationId $correlationId
    }
}
catch {
    Write-Error "Failed to save export: $_"
    
    # Log export failure
    if ($eventLogAvailable) {
        Write-UCEventLog -Message "Unity error export failed" `
            -EntryType Error `
            -Component Unity `
            -Action "ExportFailed" `
            -Details @{
                Error = $_.Exception.Message
                FilePath = $exportPath
            } `
            -CorrelationId $correlationId
    }
}

#endregion

#region Post-Processing

if ($CopyToClipboard) {
    try {
        $exportContent | Out-String | Set-Clipboard
        Write-Host "Content copied to clipboard" -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to copy to clipboard: $_"
    }
}

if ($OpenInNotepad) {
    Start-Process notepad.exe -ArgumentList $exportPath
}

Write-Host ""
Write-Host "Export complete!" -ForegroundColor Cyan
Write-Host "Correlation ID: $correlationId" -ForegroundColor Gray

#endregion