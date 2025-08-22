# Force-UnityCompilation.ps1
# Immediate workaround for Unity 2021.1 background compilation issue
# Forces Unity window to foreground to trigger compilation and Editor.log updates
# Date: 2025-08-17

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$WaitForCompilation,
    
    [Parameter()]
    [int]$DelaySeconds = 2
)

Write-Host "=== Unity Compilation Forcer ===" -ForegroundColor Cyan
Write-Host "Forcing Unity to compile and update Editor.log..." -ForegroundColor Yellow

# Add Windows API functions
Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    using System.Diagnostics;
    
    public class Win32Window {
        [DllImport("user32.dll")]
        public static extern bool SetForegroundWindow(IntPtr hWnd);
        
        [DllImport("user32.dll")]
        public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
        
        [DllImport("user32.dll")]
        public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, int dwExtraInfo);
        
        [DllImport("user32.dll")]
        public static extern IntPtr GetForegroundWindow();
        
        [DllImport("user32.dll")]
        public static extern int GetWindowText(IntPtr hWnd, System.Text.StringBuilder text, int count);
        
        public const int SW_RESTORE = 9;
        public const int SW_SHOW = 5;
        public const byte VK_MENU = 0x12; // Alt key
        public const uint KEYEVENTF_KEYUP = 0x2;
        
        public static void UnlockSetForeground() {
            // Simulate Alt key press and release to unlock SetForegroundWindow
            keybd_event(VK_MENU, 0, 0, 0);
            keybd_event(VK_MENU, 0, KEYEVENTF_KEYUP, 0);
        }
    }
"@

# Function to get Unity process
function Get-UnityProcess {
    $unity = Get-Process Unity* -ErrorAction SilentlyContinue | 
             Where-Object { $_.MainWindowTitle -match "Unity" -or $_.ProcessName -eq "Unity" } |
             Select-Object -First 1
    
    if (-not $unity) {
        Write-Host "[ERROR] Unity is not running!" -ForegroundColor Red
        Write-Host "Please start Unity and try again." -ForegroundColor Yellow
        return $null
    }
    
    return $unity
}

# Function to activate Unity window
function Set-UnityForeground {
    param([System.Diagnostics.Process]$UnityProcess)
    
    if (-not $UnityProcess.MainWindowHandle -or $UnityProcess.MainWindowHandle -eq [IntPtr]::Zero) {
        Write-Host "[WARNING] Unity window handle not found" -ForegroundColor Yellow
        return $false
    }
    
    # Store current foreground window
    $currentWindow = [Win32Window]::GetForegroundWindow()
    
    # Unlock SetForegroundWindow restrictions
    [Win32Window]::UnlockSetForeground()
    
    # Show window if minimized
    [Win32Window]::ShowWindow($UnityProcess.MainWindowHandle, [Win32Window]::SW_RESTORE) | Out-Null
    Start-Sleep -Milliseconds 100
    
    # Set Unity as foreground window
    $result = [Win32Window]::SetForegroundWindow($UnityProcess.MainWindowHandle)
    
    if ($result) {
        Write-Host "[OK] Unity window activated" -ForegroundColor Green
        
        # Send a refresh command (Ctrl+R)
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.SendKeys]::SendWait("^r")
        Write-Host "[OK] Sent refresh command (Ctrl+R)" -ForegroundColor Green
    }
    else {
        Write-Host "[WARNING] Could not activate Unity window" -ForegroundColor Yellow
        Write-Host "Try clicking on Unity window manually" -ForegroundColor Yellow
    }
    
    return $result
}

# Function to check Editor.log for recent updates
function Test-EditorLogUpdate {
    $editorLog = Join-Path $env:LOCALAPPDATA 'Unity\Editor\Editor.log'
    
    if (-not (Test-Path $editorLog)) {
        Write-Host "[WARNING] Editor.log not found" -ForegroundColor Yellow
        return $false
    }
    
    $lastWrite = (Get-Item $editorLog).LastWriteTime
    $timeSinceUpdate = (Get-Date) - $lastWrite
    
    if ($timeSinceUpdate.TotalSeconds -lt 10) {
        Write-Host "[OK] Editor.log recently updated ($([Math]::Round($timeSinceUpdate.TotalSeconds, 1))s ago)" -ForegroundColor Green
        return $true
    }
    else {
        Write-Host "[INFO] Editor.log last updated $([Math]::Round($timeSinceUpdate.TotalMinutes, 1)) minutes ago" -ForegroundColor Gray
        return $false
    }
}

# Main execution
Write-Host ""
Write-Host "Step 1: Finding Unity process..." -ForegroundColor Yellow
$unityProcess = Get-UnityProcess

if (-not $unityProcess) {
    exit 1
}

Write-Host "[OK] Found Unity process (PID: $($unityProcess.Id))" -ForegroundColor Green

Write-Host ""
Write-Host "Step 2: Activating Unity window..." -ForegroundColor Yellow

if ($DelaySeconds -gt 0) {
    Write-Host "Waiting $DelaySeconds seconds before activation..." -ForegroundColor Gray
    Start-Sleep -Seconds $DelaySeconds
}

$activated = Set-UnityForeground -UnityProcess $unityProcess

Write-Host ""
Write-Host "Step 3: Checking Editor.log update..." -ForegroundColor Yellow
Start-Sleep -Seconds 2  # Give Unity time to write to log

$logUpdated = Test-EditorLogUpdate

if ($WaitForCompilation) {
    Write-Host ""
    Write-Host "Step 4: Waiting for compilation to complete..." -ForegroundColor Yellow
    
    $maxWait = 30  # Maximum 30 seconds
    $waited = 0
    
    while ($waited -lt $maxWait) {
        Start-Sleep -Seconds 2
        $waited += 2
        
        # Check if Unity is still compiling (simple heuristic based on CPU usage)
        $unityProcess.Refresh()
        $cpuUsage = $unityProcess.CPU
        
        if ($VerbosePreference -eq 'Continue') {
            Write-Host "  Waiting... ($waited/$maxWait seconds)" -ForegroundColor Gray
        }
        
        # Check if log was updated recently
        if (Test-EditorLogUpdate) {
            Write-Host "[OK] Compilation appears complete" -ForegroundColor Green
            break
        }
    }
}

Write-Host ""
Write-Host "=== Force Compilation Complete ===" -ForegroundColor Green
Write-Host ""

if ($activated) {
    Write-Host "Unity has been activated and should now compile any pending changes." -ForegroundColor Cyan
    Write-Host "The Editor.log should be updated with any compilation errors." -ForegroundColor Cyan
}
else {
    Write-Host "Could not automatically activate Unity window." -ForegroundColor Yellow
    Write-Host "Please manually click on the Unity window to trigger compilation." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Tips:" -ForegroundColor Gray
Write-Host "- Run this script after saving .cs files in your editor" -ForegroundColor Gray
Write-Host "- Use -WaitForCompilation to wait for Unity to finish" -ForegroundColor Gray
Write-Host "- Use -DelaySeconds to add delay before activation" -ForegroundColor Gray
Write-Host "- Check Editor.log at: %LOCALAPPDATA%\Unity\Editor\Editor.log" -ForegroundColor Gray
Write-Host ""

# Return success/failure
exit $(if ($activated) { 0 } else { 1 })
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUF5dNSY6wv90TEtYjcUKSK+fy
# FYegggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUIvKD2ZM3Y4BTckcwy2lXRa1Ci+IwDQYJKoZIhvcNAQEBBQAEggEASab2
# uRax5NR88EHzvQp5LjP703Yw1DsIeA9J/6iQ7g1fraJWp5eVixCcRH2vQjHW8bYi
# 6mVrqkzFQb5dyRjBls4/KwVQiOYIHb5K4YAl5zChy5KKoGmTXq5il/xAAsreudYE
# uJcgUHGrVRybSDSyV5vCoBGB1oZYJw750GpWui4btYzmQkvgVoO95H5HIeatp0n6
# RDmemmRMd3M1Vn32TSSvykLraf459SY0vhOMVUEKXdJRjoatDJ41PmGtJeWit724
# dnKb6fdxPKYX7cG67BbuBfVQLx9pihdGD1Za5+q9Gd15qy3taf+DVEImKuYibOuO
# vnft1nLxKUB8KbNRJQ==
# SIG # End signature block
