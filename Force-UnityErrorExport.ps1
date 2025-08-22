# Force-UnityErrorExport.ps1
# Forces Unity to export current console errors even without new compilation
# Works with existing compilation errors that are blocking further compilation
# Created: 2025-08-17

param(
    [string]$UnityPath = "C:\Program Files\Unity\Hub\Editor\2021.1.14f1\Editor\Unity.exe",
    [string]$ProjectPath = "C:\UnityProjects\Sound-and-Shoal\Dithering",
    [int]$WaitTime = 5000,
    [switch]$Debug
)

$logFile = Join-Path $PSScriptRoot "unity_claude_automation.log"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"

function Write-DebugLog {
    param([string]$Message)
    $logEntry = "$timestamp [FORCE_ERROR_EXPORT] $Message"
    Add-Content -Path $logFile -Value $logEntry -Encoding UTF8
    if ($Debug) {
        Write-Host $logEntry -ForegroundColor Cyan
    }
}

Write-DebugLog "=== Force-UnityErrorExport Started ==="

# Check if Unity is running
$unityProcess = Get-Process -Name "Unity" -ErrorAction SilentlyContinue

if (-not $unityProcess) {
    Write-Host "Unity is not running. Please start Unity with your project first." -ForegroundColor Yellow
    exit 1
}

Write-Host "`nUnity is running. Attempting to trigger error export..." -ForegroundColor Green

# Option 1: Try using Unity menu command via batch mode
Write-Host "`nOption 1: Attempting batch mode execution..." -ForegroundColor Cyan

$unityCommand = @"
using UnityEngine;
using UnityEditor;
using System;

public class ForceErrorExport
{
    [MenuItem("Unity-Claude/Force Error Export Now")]
    public static void ForceExport()
    {
        // Try to find and call the ConsoleErrorExporter
        var exporterType = Type.GetType("UnityClaudeAutomation.ConsoleErrorExporter, Assembly-CSharp-Editor");
        if (exporterType != null)
        {
            var method = exporterType.GetMethod("ForceExport", System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.Static);
            if (method != null)
            {
                method.Invoke(null, null);
                Debug.Log("[ForceErrorExport] Successfully triggered error export");
            }
            else
            {
                Debug.LogError("[ForceErrorExport] Could not find ForceExport method");
            }
        }
        else
        {
            Debug.LogError("[ForceErrorExport] ConsoleErrorExporter not found");
        }
    }
}
"@

# Save temporary script
$tempScript = Join-Path $env:TEMP "ForceErrorExport.cs"
$unityCommand | Out-File -FilePath $tempScript -Encoding UTF8

Write-DebugLog "Created temporary script at: $tempScript"

# Option 2: Use the existing rapid switch to activate Unity and trigger periodic export
Write-Host "`nOption 2: Using rapid switch to ensure Unity has focus..." -ForegroundColor Cyan

# Load rapid switch functionality
$rapidSwitchPath = Join-Path $PSScriptRoot "Invoke-RapidUnitySwitch-v3.ps1"
if (Test-Path $rapidSwitchPath) {
    Write-DebugLog "Found rapid switch script, executing..."
    
    # Run rapid switch with longer wait time to allow periodic export
    & $rapidSwitchPath -WaitMilliseconds $WaitTime -Debug:$Debug
    
    Write-Host "Waited ${WaitTime}ms for ConsoleErrorExporter periodic export" -ForegroundColor Gray
}

# Option 3: Check Editor.log for any updates
$editorLogPath = Join-Path $ProjectPath "Assets\Editor.log"
Write-Host "`nOption 3: Checking Editor.log for updates..." -ForegroundColor Cyan

if (Test-Path $editorLogPath) {
    $logInfo = Get-Item $editorLogPath
    $minutesOld = [Math]::Round((Get-Date).Subtract($logInfo.LastWriteTime).TotalMinutes, 1)
    
    Write-Host "Editor.log Information:" -ForegroundColor White
    Write-Host "  Path: $editorLogPath" -ForegroundColor Gray
    Write-Host "  Last Modified: $($logInfo.LastWriteTime) ($minutesOld minutes ago)" -ForegroundColor Gray
    Write-Host "  Size: $([Math]::Round($logInfo.Length / 1MB, 2)) MB" -ForegroundColor Gray
    
    # Read last compilation error section if recent
    if ($minutesOld -lt 5) {
        Write-Host "`nRecent content from Editor.log:" -ForegroundColor Green
        $content = Get-Content $editorLogPath -Raw
        
        # Look for compilation errors pattern
        if ($content -match "COMPILATION ERRORS:(.+?)(?:WARNINGS:|End of export|$)") {
            $errors = $matches[1]
            Write-Host $errors -ForegroundColor Red
        } else {
            Write-Host "No compilation errors section found in log" -ForegroundColor Yellow
        }
    } else {
        Write-Host "`nEditor.log hasn't been updated recently" -ForegroundColor Yellow
        Write-Host "This suggests ConsoleErrorExporter is not running" -ForegroundColor Yellow
    }
} else {
    Write-Host "Editor.log not found at: $editorLogPath" -ForegroundColor Red
}

# Option 4: Direct Unity Editor log reading
Write-Host "`nOption 4: Checking Unity's main Editor.log..." -ForegroundColor Cyan

$unityEditorLog = "$env:LOCALAPPDATA\Unity\Editor\Editor.log"
if (Test-Path $unityEditorLog) {
    Write-Host "Reading Unity Editor.log for compilation errors..." -ForegroundColor Gray
    
    # Get last 100 lines looking for compilation errors
    $recentLog = Get-Content $unityEditorLog -Tail 100
    $errorLines = $recentLog | Where-Object { $_ -match "error CS\d{4}:" }
    
    if ($errorLines) {
        Write-Host "`nFound compilation errors in Unity Editor.log:" -ForegroundColor Red
        $errorLines | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
        
        # Count unique errors
        $errorCodes = $errorLines | ForEach-Object {
            if ($_ -match "error (CS\d{4}):") { $matches[1] }
        } | Sort-Object -Unique
        
        Write-Host "`nError Summary:" -ForegroundColor Yellow
        Write-Host "  Total Error Lines: $($errorLines.Count)" -ForegroundColor Gray
        Write-Host "  Unique Error Codes: $($errorCodes -join ', ')" -ForegroundColor Gray
    } else {
        Write-Host "No compilation errors found in Unity Editor.log" -ForegroundColor Green
    }
}

Write-Host "`n=== Recommendations ===" -ForegroundColor Cyan
Write-Host "1. In Unity, go to menu: Unity-Claude -> Force Error Export" -ForegroundColor White
Write-Host "2. Clear all compilation errors to allow new compilations" -ForegroundColor White
Write-Host "3. Make a small change to any .cs file to trigger recompilation" -ForegroundColor White
Write-Host "4. Check if ConsoleErrorExporter.cs itself has compilation errors" -ForegroundColor White

Write-DebugLog "=== Force-UnityErrorExport Completed ==="
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUMOKM2nDIg2D7cxp0fSw0nmCG
# aECgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUlaR/pBYIziGUqmVhZ0GdBseJrSIwDQYJKoZIhvcNAQEBBQAEggEAU73S
# 3mMd1Rt5UK0x65AHGjfQZizeCQAuZCvzsKODbP9SiCFtq0b0X6eSX97msqqw2UA3
# 09TiL4uNod3FsfrgO8F3XAYdn81az2nKxNFB8Ocs8OPCRhTHdGV1N51ABcRAW55E
# 4JKCu6836lhAnoIpi5tWnvzQGHwPPRMai7EaR5hr5orIU3AWy/yRdKqVXbMV/N/f
# T2Qu4Gyqb5WH7KuXGDy6L/YaIeHLx3rNfr15BaEuT/FLY9XFONJWgCcJbtDbV4Pf
# 8I7SF84ldbD/dUhRT2kZT+v5soztzH/VAuuXb+uR+tMvew4QsJIGeAQeaSIxUXBG
# aqzuqa+looLzD+PpVQ==
# SIG # End signature block
