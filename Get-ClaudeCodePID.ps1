# Get-ClaudeCodePID.ps1
# Finds and reports the Claude Code CLI process ID
# Date: 2025-08-20

function Get-ClaudeCodeProcessInfo {
    <#
    .SYNOPSIS
    Finds the Claude Code CLI process and returns its information
    
    .DESCRIPTION
    Searches for Claude Code CLI processes by looking for:
    - Windows Terminal instances with Claude Code in the title
    - PowerShell processes running claude code
    - Node.js processes running claude
    
    .OUTPUTS
    Hashtable with process information or null if not found
    #>
    
    $results = @{
        Found = $false
        ProcessId = $null
        ProcessName = $null
        WindowTitle = $null
        CommandLine = $null
        Method = $null
        Timestamp = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')
    }
    
    Write-Host "Searching for Claude Code CLI process..." -ForegroundColor Yellow
    
    # Method 1: Look for Windows Terminal with Claude Code title
    try {
        Write-Host "  Method 1: Checking Windows Terminal instances..." -ForegroundColor Gray
        
        $windowsTerminals = Get-Process WindowsTerminal -ErrorAction SilentlyContinue
        foreach ($terminal in $windowsTerminals) {
            if ($terminal.MainWindowTitle -like "*Claude Code*") {
                $results.Found = $true
                $results.ProcessId = $terminal.Id
                $results.ProcessName = $terminal.ProcessName
                $results.WindowTitle = $terminal.MainWindowTitle
                $results.Method = "WindowsTerminal"
                
                Write-Host "  [+] Found via Windows Terminal: PID $($terminal.Id)" -ForegroundColor Green
                Write-Host "      Title: $($terminal.MainWindowTitle)" -ForegroundColor Gray
                return $results
            }
        }
    } catch {
        Write-Host "  [-] Error checking Windows Terminal: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Method 2: Look for PowerShell processes with claude in command line
    try {
        Write-Host "  Method 2: Checking PowerShell processes..." -ForegroundColor Gray
        
        $wmiProcesses = Get-WmiObject Win32_Process -Filter "Name='powershell.exe' OR Name='pwsh.exe'" | 
            Where-Object { $_.CommandLine -like "*claude*code*" -or $_.CommandLine -like "*Claude Code CLI*" }
        
        foreach ($proc in $wmiProcesses) {
            $results.Found = $true
            $results.ProcessId = $proc.ProcessId
            $results.ProcessName = $proc.Name
            $results.CommandLine = $proc.CommandLine
            $results.Method = "PowerShell"
            
            # Try to get window title
            try {
                $psProcess = Get-Process -Id $proc.ProcessId -ErrorAction Stop
                $results.WindowTitle = $psProcess.MainWindowTitle
            } catch {
                $results.WindowTitle = "N/A"
            }
            
            Write-Host "  [+] Found via PowerShell: PID $($proc.ProcessId)" -ForegroundColor Green
            Write-Host "      Command: $($proc.CommandLine.Substring(0, [Math]::Min(100, $proc.CommandLine.Length)))..." -ForegroundColor Gray
            return $results
        }
    } catch {
        Write-Host "  [-] Error checking PowerShell processes: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Method 3: Look for Node.js processes running claude
    try {
        Write-Host "  Method 3: Checking Node.js processes..." -ForegroundColor Gray
        
        $nodeProcesses = Get-WmiObject Win32_Process -Filter "Name='node.exe'" | 
            Where-Object { $_.CommandLine -like "*claude*" }
        
        foreach ($proc in $nodeProcesses) {
            $results.Found = $true
            $results.ProcessId = $proc.ProcessId
            $results.ProcessName = $proc.Name
            $results.CommandLine = $proc.CommandLine
            $results.Method = "Node.js"
            
            Write-Host "  [+] Found via Node.js: PID $($proc.ProcessId)" -ForegroundColor Green
            Write-Host "      Command: $($proc.CommandLine.Substring(0, [Math]::Min(100, $proc.CommandLine.Length)))..." -ForegroundColor Gray
            return $results
        }
    } catch {
        Write-Host "  [-] Error checking Node.js processes: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Method 4: Look for any window with "Claude Code" in the title
    try {
        Write-Host "  Method 4: Checking all windows for Claude Code title..." -ForegroundColor Gray
        
        Add-Type @"
            using System;
            using System.Text;
            using System.Runtime.InteropServices;
            
            public class WindowHelper {
                [DllImport("user32.dll")]
                public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
                
                [DllImport("user32.dll")]
                public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
                
                [DllImport("user32.dll")]
                public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
                
                public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
                
                public static System.Collections.Generic.List<Tuple<IntPtr, string, uint>> GetAllWindows() {
                    var windows = new System.Collections.Generic.List<Tuple<IntPtr, string, uint>>();
                    
                    EnumWindows((hWnd, lParam) => {
                        StringBuilder title = new StringBuilder(256);
                        GetWindowText(hWnd, title, 256);
                        uint processId;
                        GetWindowThreadProcessId(hWnd, out processId);
                        
                        if (title.Length > 0) {
                            windows.Add(Tuple.Create(hWnd, title.ToString(), processId));
                        }
                        return true;
                    }, IntPtr.Zero);
                    
                    return windows;
                }
            }
"@ -ErrorAction SilentlyContinue
        
        $allWindows = [WindowHelper]::GetAllWindows()
        foreach ($window in $allWindows) {
            if ($window.Item2 -like "*Claude Code*") {
                $results.Found = $true
                $results.ProcessId = $window.Item3
                $results.WindowTitle = $window.Item2
                $results.Method = "WindowTitle"
                
                try {
                    $proc = Get-Process -Id $window.Item3 -ErrorAction Stop
                    $results.ProcessName = $proc.ProcessName
                } catch {
                    $results.ProcessName = "Unknown"
                }
                
                Write-Host "  [+] Found via window title: PID $($window.Item3)" -ForegroundColor Green
                Write-Host "      Title: $($window.Item2)" -ForegroundColor Gray
                return $results
            }
        }
    } catch {
        Write-Host "  [-] Error checking window titles: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host "  [-] Claude Code CLI process not found" -ForegroundColor Yellow
    return $results
}

function Register-ClaudeCodeWithSystemStatus {
    <#
    .SYNOPSIS
    Registers the Claude Code CLI process with SystemStatus monitoring
    
    .PARAMETER ProcessId
    The process ID of Claude Code CLI
    
    .OUTPUTS
    Boolean indicating success
    #>
    param(
        [Parameter(Mandatory=$true)]
        [int]$ProcessId
    )
    
    try {
        # Load SystemStatus module if not loaded
        if (-not (Get-Module -Name "Unity-Claude-SystemStatus")) {
            $modulePath = ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1"
            if (Test-Path $modulePath) {
                Import-Module $modulePath -Force -Global
            } else {
                Write-Host "SystemStatus module not found" -ForegroundColor Red
                return $false
            }
        }
        
        # Read current status
        $statusData = Read-SystemStatus
        if (-not $statusData) {
            $statusData = @{
                systemInfo = @{
                    lastUpdate = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
                }
                subsystems = @{}
                alerts = @()
            }
        }
        
        # Add or update Claude Code CLI entry
        $statusData.subsystems["ClaudeCodeCLI"] = @{
            ProcessId = $ProcessId
            Status = "Running"
            LastHeartbeat = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')
            Type = "External"
        }
        
        # Write updated status
        Write-SystemStatus -StatusData $statusData
        
        Write-Host "  [+] Registered Claude Code CLI (PID: $ProcessId) with SystemStatus" -ForegroundColor Green
        return $true
        
    } catch {
        Write-Host "  [-] Failed to register with SystemStatus: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Main execution
if ($MyInvocation.InvocationName -ne '.') {
    Write-Host "=================================================" -ForegroundColor Cyan
    Write-Host "Claude Code CLI Process Finder" -ForegroundColor Cyan
    Write-Host "=================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $claudeInfo = Get-ClaudeCodeProcessInfo
    
    Write-Host ""
    Write-Host "Results:" -ForegroundColor Yellow
    Write-Host "--------" -ForegroundColor Yellow
    
    if ($claudeInfo.Found) {
        Write-Host "Claude Code CLI Found!" -ForegroundColor Green
        Write-Host "  Process ID: $($claudeInfo.ProcessId)" -ForegroundColor White
        Write-Host "  Process Name: $($claudeInfo.ProcessName)" -ForegroundColor White
        Write-Host "  Window Title: $($claudeInfo.WindowTitle)" -ForegroundColor White
        Write-Host "  Detection Method: $($claudeInfo.Method)" -ForegroundColor White
        
        if ($claudeInfo.CommandLine) {
            Write-Host "  Command Line: $($claudeInfo.CommandLine.Substring(0, [Math]::Min(150, $claudeInfo.CommandLine.Length)))..." -ForegroundColor Gray
        }
        
        Write-Host ""
        Write-Host "Registering with SystemStatus..." -ForegroundColor Yellow
        $registered = Register-ClaudeCodeWithSystemStatus -ProcessId $claudeInfo.ProcessId
        
        if ($registered) {
            Write-Host "Successfully registered Claude Code CLI with SystemStatus monitoring" -ForegroundColor Green
        }
        
        # Return the PID for use by other scripts
        return $claudeInfo.ProcessId
        
    } else {
        Write-Host "Claude Code CLI Not Found" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please ensure Claude Code CLI is running." -ForegroundColor Yellow
        Write-Host "You can start it by:" -ForegroundColor Yellow
        Write-Host "  1. Opening a new terminal window" -ForegroundColor Gray
        Write-Host "  2. Running: claude code" -ForegroundColor Gray
        Write-Host "  3. Renaming the window to 'Claude Code CLI environment'" -ForegroundColor Gray
        
        return $null
    }
}

# Export functions if being dot-sourced
Export-ModuleMember -Function Get-ClaudeCodeProcessInfo, Register-ClaudeCodeWithSystemStatus -ErrorAction SilentlyContinue
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUNU2qjYE8vAHYylsBsLfPioIn
# Hx+gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
# AQsFADAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0b21hdGlvbi1EZXZlbG9w
# bWVudDAeFw0yNTA4MjAyMTE1MTdaFw0yNjA4MjAyMTM1MTdaMC4xLDAqBgNVBAMM
# I1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEAseH3qinVEOhrn2OLpjc5TNT4vGh1BkfB5X4S
# FhY7K0QMQsYYnkZVmx3tB8PqVQXl++l+e3uT7uCscc7vjMTK8tDSWH98ji0U34WL
# JBwXC62l1ArazMKp4Tyr7peksei7vL4pZOtOVgAyTYn5d1hbnsVQmCSTPRtpn7mC
# Azfq2ec5qZ9Kgl7puPW5utvYfh8idtOWa5/WgYSKwOIvyZawIdZKLFpwqOtqbJe4
# sWzVahasFhLfoAKkniKOAocJDkJexh5pO/EOSKEZ3mOCU1ZSs4XWRGISRhV3qGZp
# f+Y3JlHKMeFDWKynaJBO8/GU5sqMATlDUvrByBtU2OQ2Um/L3QIDAQABo0YwRDAO
# BgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFHw5
# rOy6xlW6B45sJUsiI2A/yS0MMA0GCSqGSIb3DQEBCwUAA4IBAQAUTLH0+w8ysvmh
# YuBw4NDKcZm40MTh9Zc1M2p2hAkYsgNLJ+/rAP+I74rNfqguTYwxpCyjkwrg8yF5
# wViwggboLpF2yDu4N/dgDainR4wR8NVpS7zFZOFkpmNPepc6bw3d4yQKa/wJXKeC
# pkRjS50N77/hfVI+fFKNao7POb7en5fcXuZaN6xWoTRy+J4I4MhfHpjZuxSLSXjb
# VXtPD4RZ9HGjl9BU8162cRhjujr/Lc3/dY/6ikHQYnxuxcdxRew4nzaqAQaOeWu6
# tGp899JPKfldM5Zay5IBl3zs15gNS9+0Jrd0ARQnSVYoI0DLh3KybFnfK4POezoN
# Lp/dbX2SMYIB4zCCAd8CAQEwQjAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0
# b21hdGlvbi1EZXZlbG9wbWVudAIQdR0W2SKoK5VE8JId4ZxrRTAJBgUrDgMCGgUA
# oHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYB
# BAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0B
# CQQxFgQUQWzW8c2dzx4yg7C8HDXqpYdx+RQwDQYJKoZIhvcNAQEBBQAEggEAFBYc
# 5Dj6Q7dLvvaVhqv/cVTHyN7EensApz1BRVXq17akXndWnXhcXMIqU6wHcpSTo+pk
# udeZR6JFsc+B/xW9BBh3FNj/mPmJ/r7VDqhtKMI78GzBig21jpOm4LocHMwI5E5n
# XqvwoboumwuE1g5fMQubVwSddyRfNctk4EY5kPRmpxkWzJj4kUNCrmf8xWC1c1jL
# dWy+i+fC9+xDIaEAZbYFdRrafLtD4fZnIV3JYeirE53LYBIECybHdKegaLPDOUs0
# DCPkT8lSfdosJTFUehhYQgxJ81KFWkaloGbWYdkpyvpWF69yx9RgGeJPYv31ncGi
# oWsrIkS8pBjp7dJthg==
# SIG # End signature block
