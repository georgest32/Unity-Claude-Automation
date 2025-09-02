function Find-ClaudeWindow {
    <#
    .SYNOPSIS
        Finds the Claude Code CLI window using multiple detection methods
        
    .DESCRIPTION
        Uses multiple strategies to locate the Claude CLI window:
        1. Check system_status.json for previously detected window info
        2. Search by window title patterns with comprehensive pattern matching
        
    .OUTPUTS
        IntPtr - The window handle if found, $null if not found
        
    .EXAMPLE
        $windowHandle = Find-ClaudeWindow
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "  Searching for Claude Code CLI window..." -ForegroundColor Gray
    
    # Method 1: Check system_status.json for comprehensive window info
    $systemStatusPath = ".\system_status.json"
    if (Test-Path $systemStatusPath) {
        try {
            $systemStatus = Get-Content $systemStatusPath -Raw | ConvertFrom-Json
            $claudeInfo = $systemStatus.SystemInfo.ClaudeCodeCLI
            
            if ($claudeInfo) {
                Write-Host "    Found Claude info in system_status.json" -ForegroundColor Gray
                
                # Try PID first
                if ($claudeInfo.ProcessId) {
                    $claudePID = $claudeInfo.ProcessId
                    Write-Host "    Checking registered PID: $claudePID" -ForegroundColor Gray
                    
                    $claudeProcess = Get-Process -Id $claudePID -ErrorAction SilentlyContinue
                    if ($claudeProcess -and $claudeProcess.MainWindowHandle -ne 0) {
                        # Verify the window title matches what we expect
                        if ($claudeInfo.WindowTitle -and $claudeProcess.MainWindowTitle -eq $claudeInfo.WindowTitle) {
                            Write-Host "    SUCCESS: Found Claude window from registered PID with matching title!" -ForegroundColor Green
                            Write-Host "    PID: $claudePID, Title: '$($claudeProcess.MainWindowTitle)'" -ForegroundColor Gray
                            return $claudeProcess.MainWindowHandle
                        } else {
                            Write-Host "    Warning: Window title changed (expected: '$($claudeInfo.WindowTitle)', actual: '$($claudeProcess.MainWindowTitle)')" -ForegroundColor Yellow
                        }
                    }
                }
                
                # Try window handle if available
                if ($claudeInfo.WindowHandle) {
                    Write-Host "    Trying stored window handle: $($claudeInfo.WindowHandle)" -ForegroundColor Gray
                    $processes = Get-Process | Where-Object { $_.MainWindowHandle -eq $claudeInfo.WindowHandle }
                    if ($processes) {
                        $proc = $processes[0]
                        Write-Host "    SUCCESS: Found window using stored handle!" -ForegroundColor Green
                        Write-Host "    Process: $($proc.ProcessName) (PID: $($proc.Id)), Title: '$($proc.MainWindowTitle)'" -ForegroundColor Gray
                        return $proc.MainWindowHandle
                    }
                }
            }
        } catch {
            Write-Host "    Could not read system_status.json: $_" -ForegroundColor Yellow
        }
    }
    
    # Method 2: Search by window title patterns - PRIORITIZE POWERSHELL PROCESSES
    Write-Host "    Searching for PowerShell processes with Claude title..." -ForegroundColor Gray
    
    # First, look for PowerShell processes with Claude title
    $psProcessNames = @('pwsh', 'powershell', 'powershell_ise', 'WindowsTerminal')
    $psProcesses = Get-Process -Name $psProcessNames -ErrorAction SilentlyContinue | Where-Object { 
        $_.MainWindowHandle -ne 0 
    }
    
    if ($psProcesses) {
        Write-Host "    Found $($psProcesses.Count) PowerShell/Terminal processes with windows" -ForegroundColor Gray
        
        # Check PowerShell windows for Claude title
        $claudeTitlePatterns = @(
            "Claude Code CLI environment",       # Exact match
            "*Claude Code CLI*",                 # Contains Claude Code CLI
            "*claude*code*cli*",                # Flexible case
            "*claude*"                          # Any claude mention
        )
        
        foreach ($pattern in $claudeTitlePatterns) {
            foreach ($proc in $psProcesses) {
                if ($proc.MainWindowTitle -like $pattern) {
                    Write-Host "    SUCCESS: Found PowerShell window with Claude title!" -ForegroundColor Green
                    Write-Host "    Process: $($proc.ProcessName) (PID: $($proc.Id))" -ForegroundColor Gray
                    Write-Host "    Title: '$($proc.MainWindowTitle)'" -ForegroundColor Gray
                    Write-Host "    Handle: $($proc.MainWindowHandle)" -ForegroundColor Gray
                    
                    # Update system_status.json with found window info
                    Update-ClaudeWindowInfo -WindowHandle $proc.MainWindowHandle -ProcessId $proc.Id -WindowTitle $proc.MainWindowTitle -ProcessName $proc.ProcessName
                    
                    return $proc.MainWindowHandle
                }
            }
        }
        
        # If no PowerShell window has Claude title, use first available PowerShell window
        Write-Host "    WARNING: No PowerShell window has Claude title" -ForegroundColor Yellow
        Write-Host "    Using first available PowerShell window as fallback" -ForegroundColor Yellow
        
        $fallbackProc = $psProcesses | Select-Object -First 1
        Write-Host "    Using: $($fallbackProc.ProcessName) (PID: $($fallbackProc.Id))" -ForegroundColor Yellow
        Write-Host "    Title: '$($fallbackProc.MainWindowTitle)'" -ForegroundColor Yellow
        
        # Update system_status.json with found window info
        Update-ClaudeWindowInfo -WindowHandle $fallbackProc.MainWindowHandle -ProcessId $fallbackProc.Id -WindowTitle $fallbackProc.MainWindowTitle -ProcessName $fallbackProc.ProcessName
        
        return $fallbackProc.MainWindowHandle
    }
    
    # Fallback: Search ALL processes (but warn about non-PowerShell)
    Write-Host "    WARNING: No PowerShell processes found, searching all windows..." -ForegroundColor Yellow
    
    $allProcesses = Get-Process | Where-Object { $_.MainWindowHandle -ne 0 }
    Write-Host "    Found $($allProcesses.Count) total processes with windows" -ForegroundColor Gray
    
    $titlePatterns = @(
        "Claude Code CLI environment",           # Exact match first
        "*Claude Code CLI*",                     # Contains Claude Code CLI
        "*claude*code*cli*",                     # Flexible case
        "*Windows PowerShell*",                  # Any PowerShell window
        "*PowerShell 7*",                        # PowerShell 7
        "*pwsh*",                                # PowerShell 7 process
        "*Windows Terminal*"                     # Windows Terminal
    )
    
    foreach ($pattern in $titlePatterns) {
        $processes = $allProcesses | Where-Object { 
            $_.MainWindowTitle -like $pattern
        }
        
        if ($processes) {
            # Filter out Chrome and other browsers
            $nonBrowserProcesses = $processes | Where-Object {
                $_.ProcessName -notin @('chrome', 'firefox', 'msedge', 'iexplore', 'opera', 'brave')
            }
            
            if ($nonBrowserProcesses) {
                $claudeProcess = $nonBrowserProcesses[0]
                Write-Host "    Found window matching pattern: $pattern (NON-BROWSER)" -ForegroundColor Yellow
            } else {
                Write-Host "    WARNING: Only browser windows match '$pattern' - skipping" -ForegroundColor Red
                continue
            }
            
            Write-Host "    Process: $($claudeProcess.ProcessName) (PID: $($claudeProcess.Id))" -ForegroundColor Gray
            Write-Host "    Title: '$($claudeProcess.MainWindowTitle)'" -ForegroundColor Gray
            Write-Host "    Handle: $($claudeProcess.MainWindowHandle)" -ForegroundColor Gray
            
            # Warn if not PowerShell
            if ($claudeProcess.ProcessName -notin $psProcessNames) {
                Write-Host "    WARNING: This is NOT a PowerShell process!" -ForegroundColor Red
            }
            
            # Update system_status.json with found window info
            Update-ClaudeWindowInfo -WindowHandle $claudeProcess.MainWindowHandle -ProcessId $claudeProcess.Id -WindowTitle $claudeProcess.MainWindowTitle -ProcessName $claudeProcess.ProcessName
            
            return $claudeProcess.MainWindowHandle
        }
    }
    
    Write-Host "    CRITICAL: No suitable windows found!" -ForegroundColor Red
    Write-Host "    Please ensure the Claude Code CLI window is open and visible" -ForegroundColor Yellow
    
    # Debug: List all available windows for troubleshooting
    Write-Host "    DEBUG: Available windows:" -ForegroundColor Cyan
    if ($allProcesses.Count -gt 0) {
        $allProcesses | ForEach-Object {
            Write-Host "      Process: $($_.ProcessName) (PID: $($_.Id)), Title: '$($_.MainWindowTitle)'" -ForegroundColor DarkGray
        }
    } else {
        Write-Host "      No processes with windows found" -ForegroundColor DarkGray
    }
    
    # Provide helpful guidance
    Write-Host "    GUIDANCE:" -ForegroundColor Yellow
    Write-Host "      1. Rename your PowerShell window title to 'Claude Code CLI environment'" -ForegroundColor Yellow
    Write-Host "      2. Or run: .\Set-ClaudeCodeCLITitle.ps1" -ForegroundColor Yellow
    Write-Host "      3. Ensure the window is not minimized" -ForegroundColor Yellow
    
    return $null
}