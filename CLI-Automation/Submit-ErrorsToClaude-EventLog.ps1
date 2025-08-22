# Submit-ErrorsToClaude-EventLog.ps1
# Enhanced Claude submission script with Windows Event Log integration

[CmdletBinding()]
param(
    [string]$ErrorExportPath,
    [string]$ClaudeWindowTitle = "*Claude*",
    [int]$DelayBetweenKeys = 50,
    [switch]$AutoSubmit,
    [switch]$NoEventLog,
    [guid]$ParentCorrelationId = [guid]::Empty
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

# Generate or use correlation ID
$correlationId = if ($ParentCorrelationId -ne [guid]::Empty) { 
    $ParentCorrelationId 
} else { 
    [guid]::NewGuid() 
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host " Submit Errors to Claude (Event Log)" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Correlation ID: $correlationId" -ForegroundColor Gray
Write-Host ""

# Log submission start
if ($eventLogAvailable) {
    Write-UCEventLog -Message "Claude submission process started" `
        -EntryType Information `
        -Component Claude `
        -Action "SubmissionStart" `
        -Details @{
            Method = "SendKeys"
            AutoSubmit = $AutoSubmit.IsPresent
            WindowTitle = $ClaudeWindowTitle
        } `
        -CorrelationId $correlationId
}

# Find or use error export
if (-not $ErrorExportPath) {
    Write-Host "Looking for recent error export..." -ForegroundColor Yellow
    $exportDir = Join-Path (Split-Path $PSScriptRoot) "Export-Tools"
    $recentExport = Get-ChildItem -Path $exportDir -Filter "ErrorExport_*.md" |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    
    if ($recentExport) {
        $ErrorExportPath = $recentExport.FullName
        Write-Host "Found: $($recentExport.Name)" -ForegroundColor Green
    }
    else {
        Write-Error "No error export found. Run Export-ErrorsForClaude-EventLog.ps1 first."
        
        if ($eventLogAvailable) {
            Write-UCEventLog -Message "Claude submission failed - no export found" `
                -EntryType Error `
                -Component Claude `
                -Action "SubmissionFailed" `
                -Details @{
                    Reason = "No error export file found"
                    SearchPath = $exportDir
                } `
                -CorrelationId $correlationId
        }
        return
    }
}

# Load content
try {
    $content = Get-Content -Path $ErrorExportPath -Raw -ErrorAction Stop
    $contentLines = ($content -split "`n").Count
    Write-Host "Loaded $contentLines lines from export" -ForegroundColor Green
    
    if ($eventLogAvailable) {
        Write-UCEventLog -Message "Error export loaded successfully" `
            -EntryType Information `
            -Component Claude `
            -Action "ExportLoaded" `
            -Details @{
                FilePath = $ErrorExportPath
                FileSize = (Get-Item $ErrorExportPath).Length
                Lines = $contentLines
            } `
            -CorrelationId $correlationId
    }
}
catch {
    Write-Error "Failed to load error export: $_"
    
    if ($eventLogAvailable) {
        Write-UCEventLog -Message "Failed to load error export" `
            -EntryType Error `
            -Component Claude `
            -Action "LoadFailed" `
            -Details @{
                FilePath = $ErrorExportPath
                Error = $_.Exception.Message
            } `
            -CorrelationId $correlationId
    }
    return
}

# Find Claude window
Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    using System.Text;
    
    public class Win32 {
        [DllImport("user32.dll")]
        public static extern IntPtr GetForegroundWindow();
        
        [DllImport("user32.dll")]
        public static extern bool SetForegroundWindow(IntPtr hWnd);
        
        [DllImport("user32.dll")]
        public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);
        
        [DllImport("user32.dll")]
        public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
        
        [DllImport("user32.dll")]
        public static extern bool EnumWindows(EnumWindowsProc enumProc, IntPtr lParam);
        
        public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    }
"@ -ErrorAction SilentlyContinue

Write-Host "Looking for Claude window..." -ForegroundColor Yellow

$claudeWindow = $null
$windows = @()

[Win32]::EnumWindows({
    param($hWnd, $lParam)
    $title = New-Object System.Text.StringBuilder 256
    [Win32]::GetWindowText($hWnd, $title, 256) | Out-Null
    $titleStr = $title.ToString()
    
    if ($titleStr -like $ClaudeWindowTitle) {
        $script:claudeWindow = $hWnd
        Write-Host "  Found: $titleStr" -ForegroundColor Green
        return $false
    }
    return $true
}, [IntPtr]::Zero)

if (-not $claudeWindow) {
    Write-Error "Claude window not found. Please open Claude first."
    
    if ($eventLogAvailable) {
        Write-UCEventLog -Message "Claude window not found" `
            -EntryType Error `
            -Component Claude `
            -Action "WindowNotFound" `
            -Details @{
                SearchPattern = $ClaudeWindowTitle
            } `
            -CorrelationId $correlationId
    }
    return
}

# Activate Claude window
Write-Host "Activating Claude window..." -ForegroundColor Yellow
[Win32]::SetForegroundWindow($claudeWindow) | Out-Null
Start-Sleep -Milliseconds 500

# Send content
Write-Host "Sending content to Claude..." -ForegroundColor Yellow
Write-Host "  This may take a moment for large exports..." -ForegroundColor Gray

$startTime = Get-Date

Add-Type -AssemblyName System.Windows.Forms

# Clear any existing content (Ctrl+A, Delete)
[System.Windows.Forms.SendKeys]::SendWait("^a")
Start-Sleep -Milliseconds 100
[System.Windows.Forms.SendKeys]::SendWait("{DEL}")
Start-Sleep -Milliseconds 200

# Copy content to clipboard and paste
Set-Clipboard -Value $content
Start-Sleep -Milliseconds 200
[System.Windows.Forms.SendKeys]::SendWait("^v")
Start-Sleep -Milliseconds 500

$duration = ((Get-Date) - $startTime).TotalSeconds

Write-Host "Content sent successfully!" -ForegroundColor Green
Write-Host "  Duration: $([math]::Round($duration, 2)) seconds" -ForegroundColor Gray

if ($eventLogAvailable) {
    Write-UCEventLog -Message "Content sent to Claude successfully" `
        -EntryType Information `
        -Component Claude `
        -Action "ContentSent" `
        -Details @{
            Duration = $duration
            ContentSize = $content.Length
            Method = "Clipboard"
        } `
        -CorrelationId $correlationId
}

# Auto-submit if requested
if ($AutoSubmit) {
    Write-Host "Auto-submitting in 2 seconds..." -ForegroundColor Yellow
    Start-Sleep -Seconds 2
    
    Write-Host "Submitting to Claude..." -ForegroundColor Yellow
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    
    if ($eventLogAvailable) {
        Write-UCEventLog -Message "Auto-submitted to Claude" `
            -EntryType Information `
            -Component Claude `
            -Action "AutoSubmitted" `
            -CorrelationId $correlationId
    }
    
    Write-Host "Submitted!" -ForegroundColor Green
}
else {
    Write-Host ""
    Write-Host "Content is ready in Claude window." -ForegroundColor Green
    Write-Host "Press Enter in Claude to submit when ready." -ForegroundColor Yellow
}

# Log completion
if ($eventLogAvailable) {
    Write-UCEventLog -Message "Claude submission process completed" `
        -EntryType Information `
        -Component Claude `
        -Action "SubmissionComplete" `
        -Details @{
            TotalDuration = ((Get-Date) - $startTime).TotalSeconds
            Success = $true
        } `
        -CorrelationId $correlationId
}

Write-Host ""
Write-Host "Submission process complete!" -ForegroundColor Cyan
Write-Host "Correlation ID: $correlationId" -ForegroundColor Gray