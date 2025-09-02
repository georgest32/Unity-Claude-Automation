# NUGGETRON-specific Window Manager
# This version ONLY looks for windows titled **NUGGETRON**

Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue

function Get-ClaudeWindowInfo {
    [CmdletBinding()]
    param()
    
    Write-Host "  Searching for NUGGETRON window..." -ForegroundColor Cyan
    
    # Simple and direct - find NUGGETRON
    $nuggetron = Get-Process | Where-Object {
        $_.ProcessName -match 'pwsh|powershell' -and
        $_.MainWindowTitle -eq '**NUGGETRON**' -and
        $_.MainWindowHandle -ne 0
    } | Select-Object -First 1
    
    if ($nuggetron) {
        Write-Host "    ✅ FOUND NUGGETRON!" -ForegroundColor Green
        Write-Host "    Process: $($nuggetron.ProcessName) (PID: $($nuggetron.Id))" -ForegroundColor Gray
        Write-Host "    Title: '$($nuggetron.MainWindowTitle)'" -ForegroundColor Gray
        Write-Host "    Handle: $($nuggetron.MainWindowHandle)" -ForegroundColor Gray
        
        # Update system_status.json
        Update-ClaudeWindowInfo -WindowHandle $nuggetron.MainWindowHandle `
                              -ProcessId $nuggetron.Id `
                              -WindowTitle $nuggetron.MainWindowTitle `
                              -ProcessName $nuggetron.ProcessName
        
        return @{
            ProcessId = $nuggetron.Id
            WindowHandle = $nuggetron.MainWindowHandle
            WindowTitle = $nuggetron.MainWindowTitle
            ProcessName = $nuggetron.ProcessName
        }
    }
    
    Write-Host "    ❌ NUGGETRON window not found!" -ForegroundColor Red
    Write-Host "    Searched all PowerShell windows:" -ForegroundColor Yellow
    Get-Process | Where-Object {
        $_.ProcessName -match 'pwsh|powershell' -and
        $_.MainWindowHandle -ne 0
    } | ForEach-Object {
        Write-Host "      - PID $($_.Id): '$($_.MainWindowTitle)'" -ForegroundColor Gray
    }
    
    return $null
}

function Update-ClaudeWindowInfo {
    [CmdletBinding()]
    param(
        [IntPtr]$WindowHandle,
        [int]$ProcessId,
        [string]$WindowTitle,
        [string]$ProcessName
    )
    
    Write-Host "    Updating NUGGETRON info in system_status.json..." -ForegroundColor Gray
    
    try {
        $systemStatusPath = ".\system_status.json"
        $systemStatus = @{}
        
        if (Test-Path $systemStatusPath) {
            $systemStatus = Get-Content $systemStatusPath -Raw | ConvertFrom-Json -AsHashtable
        }
        
        if (-not $systemStatus.SystemInfo) { $systemStatus.SystemInfo = @{} }
        
        $systemStatus.SystemInfo.ClaudeCodeCLI = @{
            ProcessId = $ProcessId
            WindowHandle = [int64]$WindowHandle
            WindowTitle = $WindowTitle
            UniqueIdentifier = '**NUGGETRON**'
            ProcessName = $ProcessName
            LastDetected = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            IsClaudeCodeCLI = $true
            IsNuggetron = $true
            DetectionMethod = "NUGGETRON_DIRECT"
        }
        
        $systemStatus | ConvertTo-Json -Depth 10 | Set-Content $systemStatusPath -Encoding UTF8
        Write-Host "    ✅ NUGGETRON info updated successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "    ❌ Failed to update: $_" -ForegroundColor Red
    }
}

function Switch-ToClaudeWindow {
    [CmdletBinding()]
    param(
        [hashtable]$WindowInfo
    )
    
    if (-not $WindowInfo -or -not $WindowInfo.WindowHandle) {
        Write-Host "  ❌ No NUGGETRON window info provided" -ForegroundColor Red
        return $false
    }
    
    Write-Host "  Switching to NUGGETRON window..." -ForegroundColor Cyan
    
    try {
        Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
"@ -ErrorAction SilentlyContinue
        
        $handle = [IntPtr]$WindowInfo.WindowHandle
        [Win32]::ShowWindow($handle, 9) | Out-Null  # SW_RESTORE
        [Win32]::SetForegroundWindow($handle) | Out-Null
        
        Start-Sleep -Milliseconds 500
        Write-Host "  ✅ Switched to NUGGETRON successfully" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "  ❌ Failed to switch: $_" -ForegroundColor Red
        return $false
    }
}

function Submit-ToClaudeWindow {
    [CmdletBinding()]
    param(
        [string]$Text
    )
    
    Write-Host "[SUBMISSION] Preparing to submit to NUGGETRON..." -ForegroundColor Cyan
    
    # Find NUGGETRON
    $windowInfo = Get-ClaudeWindowInfo
    if (-not $windowInfo) {
        Write-Host "❌ Cannot find NUGGETRON window" -ForegroundColor Red
        return $false
    }
    
    # Switch to window
    if (-not (Switch-ToClaudeWindow -WindowInfo $windowInfo)) {
        Write-Host "❌ Failed to switch to NUGGETRON" -ForegroundColor Red
        return $false
    }
    
    Write-Host "  Typing text into NUGGETRON..." -ForegroundColor Cyan
    
    try {
        # Clear any existing content
        [System.Windows.Forms.SendKeys]::SendWait("^a")
        Start-Sleep -Milliseconds 100
        [System.Windows.Forms.SendKeys]::SendWait("{DEL}")
        Start-Sleep -Milliseconds 100
        
        # Type the text
        # Escape special characters
        $escapedText = $Text -replace '([+^%~(){}])', '{$1}'
        
        # Send in chunks to avoid issues
        $chunkSize = 100
        for ($i = 0; $i -lt $escapedText.Length; $i += $chunkSize) {
            $chunk = $escapedText.Substring($i, [Math]::Min($chunkSize, $escapedText.Length - $i))
            [System.Windows.Forms.SendKeys]::SendWait($chunk)
            Start-Sleep -Milliseconds 50
        }
        
        Write-Host "  ✅ Text submitted to NUGGETRON" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "  ❌ Error submitting: $_" -ForegroundColor Red
        return $false
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Get-ClaudeWindowInfo',
    'Update-ClaudeWindowInfo',
    'Switch-ToClaudeWindow',
    'Submit-ToClaudeWindow'
)