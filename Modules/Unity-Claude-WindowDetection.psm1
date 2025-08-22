# Unity-Claude-WindowDetection.psm1
# Advanced window detection for Claude Code CLI and PowerShell environments
# Implements intelligent window targeting to avoid automation mistakes
# Date: 2025-08-18

#region Module Initialization
$ErrorActionPreference = "Stop"

Write-Host "[WindowDetection] Loading advanced window detection module..." -ForegroundColor Cyan

# Module configuration
$script:WindowDetectionConfig = @{
    # Claude Code CLI patterns  
    ClaudeCodePatterns = @(
        "*Claude Code CLI*",
        "*claude code*",
        "*Working directory*",
        "*Unity-Claude-Automation*",
        "*Sound-and-Shoal*"
    )
    
    # Additional PowerShell indicators for Claude Code CLI
    ClaudeCodeIndicators = @(
        "WindowsTerminal",
        "PowerShell"
    )
    
    # PowerShell window exclusions (to avoid targeting wrong windows)
    ExclusionPatterns = @(
        "*Debug*",
        "*Test*",
        "*Diagnose*",
        "*Trigger*",
        "*Server*",
        "*Monitor*"
    )
    
    # Search timeout
    SearchTimeoutMs = 5000
    MaxRetryAttempts = 3
}

Write-Host "[WindowDetection] Advanced window detection module loaded successfully" -ForegroundColor Green

#endregion

#region Window Information Functions

function Get-DetailedWindowInfo {
    <#
    .SYNOPSIS
    Gets detailed information about all windows with titles
    #>
    [CmdletBinding()]
    param()
    
    try {
        $windows = Get-Process | Where-Object { 
            $_.MainWindowTitle -and 
            $_.MainWindowTitle.Trim() -ne "" 
        } | ForEach-Object {
            $startTime = try { $_.StartTime } catch { [DateTime]::MinValue }
            $commandLine = try { 
                $processId = $_.Id
                (Get-WmiObject Win32_Process -Filter "ProcessId = $processId").CommandLine 
            } catch { "Unknown" }
            
            @{
                ProcessId = $_.Id
                ProcessName = $_.ProcessName
                WindowTitle = $_.MainWindowTitle
                WindowHandle = $_.MainWindowHandle
                StartTime = $startTime
                CommandLine = $commandLine
            }
        }
        
        return $windows | Sort-Object StartTime -Descending
        
    } catch {
        Write-Host "[WindowDetection] Error getting window information: $($_.Exception.Message)" -ForegroundColor Red
        return @()
    }
}

function Test-ClaudeCodeWindow {
    <#
    .SYNOPSIS
    Tests if a window is likely to be Claude Code CLI
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$WindowInfo
    )
    
    $score = 0
    $reasons = @()
    
    # Test for Claude Code patterns with higher scoring for specific patterns
    foreach ($pattern in $script:WindowDetectionConfig.ClaudeCodePatterns) {
        if ($WindowInfo.WindowTitle -like $pattern -or 
            $WindowInfo.CommandLine -like $pattern) {
            
            # Higher score for exact Claude Code CLI pattern
            if ($pattern -like "*Claude Code CLI*") {
                $score += 50
                $reasons += "Exact Claude Code CLI pattern match: $pattern"
            } else {
                $score += 20
                $reasons += "Matches Claude pattern: $pattern"
            }
        }
    }
    
    # Test for working directory indicators
    if ($WindowInfo.WindowTitle -like "*Unity-Claude-Automation*" -or
        $WindowInfo.CommandLine -like "*Unity-Claude-Automation*") {
        $score += 30
        $reasons += "Working in Unity-Claude-Automation directory"
    }
    
    # Test for WSL indicators (Claude Code runs in WSL)
    if ($WindowInfo.CommandLine -like "*wsl*" -or
        $WindowInfo.WindowTitle -like "*Ubuntu*" -or
        $WindowInfo.WindowTitle -like "*WSL*") {
        $score += 15
        $reasons += "WSL environment detected"
    }
    
    # Test for PowerShell with long-running session
    if ($WindowInfo.ProcessName -eq "WindowsTerminal" -and
        $WindowInfo.WindowTitle -like "*PowerShell*") {
        $timeDiff = (Get-Date) - $WindowInfo.StartTime
        if ($timeDiff.TotalMinutes -gt 5) {
            $score += 15
            $reasons += "Long-running PowerShell session (likely interactive)"
        }
        
        # Extra points for WindowsTerminal with PowerShell (Claude Code CLI environment)
        $score += 20
        $reasons += "WindowsTerminal PowerShell environment (Claude Code CLI likely)"
    }
    
    # Special case: if this is the only WindowsTerminal PowerShell and in project directory
    $currentDir = Get-Location
    if ($currentDir.Path -like "*Unity-Claude-Automation*" -and 
        $WindowInfo.ProcessName -eq "WindowsTerminal" -and
        $WindowInfo.WindowTitle -like "*PowerShell*") {
        $score += 25
        $reasons += "WindowsTerminal in Unity-Claude-Automation directory (high Claude Code CLI likelihood)"
    }
    
    # Penalize excluded patterns (debug/test windows)
    foreach ($exclusion in $script:WindowDetectionConfig.ExclusionPatterns) {
        if ($WindowInfo.WindowTitle -like $exclusion) {
            $score -= 50
            $reasons += "Matches exclusion pattern: $exclusion"
        }
    }
    
    # Bonus for active/foreground window
    $currentWindow = Get-ForegroundWindow
    if ($currentWindow -and $currentWindow.WindowHandle -eq $WindowInfo.WindowHandle) {
        $score += 5
        $reasons += "Currently active window"
    }
    
    return @{
        Score = $score
        IsLikelyClaudeCode = $score -ge 25
        Reasons = $reasons
        Confidence = [Math]::Min(100, [Math]::Max(0, $score))
    }
}

function Get-ForegroundWindow {
    <#
    .SYNOPSIS
    Gets the currently active foreground window
    #>
    [CmdletBinding()]
    param()
    
    try {
        # Add Windows API types if not already added
        if (-not ([System.Management.Automation.PSTypeName]'Win32.User32').Type) {
            Add-Type @"
            using System;
            using System.Runtime.InteropServices;
            using System.Text;
            
            namespace Win32 {
                public class User32 {
                    [DllImport("user32.dll", SetLastError = true)]
                    public static extern IntPtr GetForegroundWindow();
                    
                    [DllImport("user32.dll", SetLastError = true)]
                    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);
                    
                    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
                    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
                }
            }
"@
        }
        
        $foregroundHandle = [Win32.User32]::GetForegroundWindow()
        
        if ($foregroundHandle -eq [IntPtr]::Zero) {
            return $null
        }
        
        # Get process ID
        $processId = 0
        [Win32.User32]::GetWindowThreadProcessId($foregroundHandle, [ref]$processId) | Out-Null
        
        # Get window title
        $titleBuilder = New-Object System.Text.StringBuilder 256
        $titleLength = [Win32.User32]::GetWindowText($foregroundHandle, $titleBuilder, $titleBuilder.Capacity)
        $title = $titleBuilder.ToString()
        
        return @{
            WindowHandle = $foregroundHandle
            ProcessId = $processId
            WindowTitle = $title
        }
        
    } catch {
        Write-Host "[WindowDetection] Error getting foreground window: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

#endregion

#region Claude Code CLI Detection

function Find-ClaudeCodeCLIWindow {
    <#
    .SYNOPSIS
    Intelligently finds the Claude Code CLI window
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$Detailed
    )
    
    Write-Host "[WindowDetection] Searching for Claude Code CLI window..." -ForegroundColor Yellow
    
    try {
        # Get all windows with detailed information
        $allWindows = Get-DetailedWindowInfo
        
        if ($allWindows.Count -eq 0) {
            Write-Host "[WindowDetection] No windows with titles found" -ForegroundColor Red
            return $null
        }
        
        Write-Host "[WindowDetection] Analyzing $($allWindows.Count) windows..." -ForegroundColor Gray
        
        # Score each window
        $scoredWindows = @()
        foreach ($window in $allWindows) {
            $analysis = Test-ClaudeCodeWindow -WindowInfo $window
            
            $scoredWindows += @{
                WindowInfo = $window
                Analysis = $analysis
            }
            
            if ($Detailed) {
                Write-Host "  Window: $($window.WindowTitle)" -ForegroundColor Gray
                Write-Host "    Process: $($window.ProcessName) (PID: $($window.ProcessId))" -ForegroundColor DarkGray
                Write-Host "    Score: $($analysis.Score) (Confidence: $($analysis.Confidence)%)" -ForegroundColor DarkGray
                Write-Host "    Likely Claude Code: $($analysis.IsLikelyClaudeCode)" -ForegroundColor DarkGray
                if ($analysis.Reasons.Count -gt 0) {
                    Write-Host "    Reasons: $($analysis.Reasons -join '; ')" -ForegroundColor DarkGray
                }
                Write-Host "" -ForegroundColor DarkGray
            }
        }
        
        # Find best candidate
        $bestCandidate = $scoredWindows | 
            Where-Object { $_.Analysis.IsLikelyClaudeCode } | 
            Sort-Object { $_.Analysis.Score } -Descending | 
            Select-Object -First 1
        
        if ($bestCandidate) {
            $window = $bestCandidate.WindowInfo
            $analysis = $bestCandidate.Analysis
            
            Write-Host "[WindowDetection] [+] Found Claude Code CLI window!" -ForegroundColor Green
            Write-Host "  Title: $($window.WindowTitle)" -ForegroundColor Gray
            Write-Host "  Process: $($window.ProcessName) (PID: $($window.ProcessId))" -ForegroundColor Gray
            Write-Host "  Confidence: $($analysis.Confidence)%" -ForegroundColor Gray
            Write-Host "  Score: $($analysis.Score)" -ForegroundColor Gray
            
            return @{
                Success = $true
                WindowInfo = $window
                Analysis = $analysis
                ProcessId = $window.ProcessId
                ProcessName = $window.ProcessName
                WindowTitle = $window.WindowTitle
                WindowHandle = $window.WindowHandle
                Confidence = $analysis.Confidence
            }
        } else {
            Write-Host "[WindowDetection] [-] No Claude Code CLI window found" -ForegroundColor Red
            Write-Host "Available windows:" -ForegroundColor Yellow
            foreach ($scored in $scoredWindows | Sort-Object { $_.Analysis.Score } -Descending | Select-Object -First 5) {
                $w = $scored.WindowInfo
                $a = $scored.Analysis
                Write-Host "  - $($w.WindowTitle) (Score: $($a.Score), Process: $($w.ProcessName))" -ForegroundColor Gray
            }
            
            return @{
                Success = $false
                Error = "No Claude Code CLI window found"
                AvailableWindows = $scoredWindows
            }
        }
        
    } catch {
        Write-Host "[WindowDetection] Error finding Claude Code CLI window: $($_.Exception.Message)" -ForegroundColor Red
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Test-WindowDetection {
    <#
    .SYNOPSIS
    Tests the window detection system
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "WINDOW DETECTION TEST" -ForegroundColor Cyan
    Write-Host "=====================" -ForegroundColor Cyan
    
    # Show all windows
    Write-Host "" -ForegroundColor White
    Write-Host "All Windows with Titles:" -ForegroundColor Yellow
    $windows = Get-DetailedWindowInfo
    foreach ($window in $windows | Select-Object -First 10) {
        Write-Host "  - $($window.WindowTitle)" -ForegroundColor Gray
        Write-Host "    Process: $($window.ProcessName) (PID: $($window.ProcessId))" -ForegroundColor DarkGray
    }
    
    # Test Claude Code detection
    Write-Host "" -ForegroundColor White
    Write-Host "Claude Code CLI Detection Test:" -ForegroundColor Yellow
    $result = Find-ClaudeCodeCLIWindow -Detailed
    
    if ($result.Success) {
        Write-Host "[SUCCESS] Claude Code CLI window detected!" -ForegroundColor Green
    } else {
        Write-Host "[FAILED] Could not detect Claude Code CLI window" -ForegroundColor Red
        Write-Host "Error: $($result.Error)" -ForegroundColor Red
    }
}

#endregion

#region Module Exports

Export-ModuleMember -Function @(
    'Find-ClaudeCodeCLIWindow',
    'Get-DetailedWindowInfo', 
    'Test-ClaudeCodeWindow',
    'Get-ForegroundWindow',
    'Test-WindowDetection'
)

#endregion
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUXHi8YgAkvDD6e0P+/pRHXCz7
# ENugggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUpsW1O1qyGb6V35eq50hQ/TKbht4wDQYJKoZIhvcNAQEBBQAEggEAIxVO
# RixbM3QwLuTtQd+9vfo5WoixhBZf1qnakqRDWwq7aEZE8PO9sLM5Qi7d+WRd/KvN
# ets+d/Dqxe6BlGdp9zpTxA2Ut6aRnJ7DDMhOV261/nXJ7ApeE/MeUkLKg/UIAAO4
# flfprpsQF5AUQi/xZw0tQDOFE8lysNk5/M+cGnLpeUSfl8jYqThXzwEfDyOGYvuu
# p0BWd7oltLHhPOq7UAt0PAjIus2a3EXrgJ5b8X0ILVIlFsdBBX7CQ6980+L1rjUn
# WwMwcUJTgVwv2xK+p+V2Il1o0WwBbANBX0T2cH58icMhVHv+Fis9dZQuxBDUOI84
# cjMMPDu8V/BZNjOjqg==
# SIG # End signature block
