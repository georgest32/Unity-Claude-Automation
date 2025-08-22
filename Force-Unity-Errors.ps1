# Force-Unity-Errors.ps1
# Force Unity to generate compilation errors and check if they appear in log
# Date: 2025-08-18

Write-Host "FORCING UNITY COMPILATION ERRORS" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# First, let's check what Unity scripts exist
$unityScriptsPath = "C:\UnityProjects\Sound-and-Shoal\Dithering\Assets\Scripts"
Write-Host "Unity Scripts directory: $unityScriptsPath" -ForegroundColor Yellow

if (Test-Path $unityScriptsPath) {
    $scripts = Get-ChildItem $unityScriptsPath -Filter "*.cs"
    Write-Host "Found $($scripts.Count) C# scripts:" -ForegroundColor Green
    $scripts | ForEach-Object { Write-Host "  $($_.Name)" -ForegroundColor Gray }
} else {
    Write-Host "Scripts directory not found!" -ForegroundColor Red
}

# Check if our test script exists
$testScriptPath = "$unityScriptsPath\AutonomousErrorTest.cs"
Write-Host "" -ForegroundColor White
Write-Host "Checking test script: $testScriptPath" -ForegroundColor Yellow

if (Test-Path $testScriptPath) {
    Write-Host "Test script exists. Content:" -ForegroundColor Green
    $content = Get-Content $testScriptPath
    $content | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
} else {
    Write-Host "Test script missing! Creating it now..." -ForegroundColor Red
    
    $errorScript = @"
using UnityEngine;
using System.Collections.Generic;

// ERROR TEST SCRIPT - This should generate 4 compilation errors
public class AutonomousErrorTest : MonoBehaviour
{
    // Error 1: Missing semicolon
    public string message = "Testing autonomous system"
    
    // Error 2: Unknown type  
    public MysteryType component;
    
    // Error 3: Wrong return type
    public int GetName()
    {
        return gameObject.name; // Should return string
    }
    
    // Error 4: Missing using statement
    void Start()
    {
        List<int> numbers = new List<int> {1, 2, 3};
        var filtered = numbers.Where(x => x > 1).ToList(); // Missing System.Linq
    }
}
"@
    
    $errorScript | Set-Content -Path $testScriptPath -Encoding UTF8
    Write-Host "Created error test script with 4 compilation errors" -ForegroundColor Green
}

# Now check Unity Editor.log for current timestamp
$logPath = "C:\Users\georg\AppData\Local\Unity\Editor\Editor.log"
$logInfo = Get-Item $logPath
Write-Host "" -ForegroundColor White
Write-Host "Unity Editor.log status:" -ForegroundColor Yellow
Write-Host "  Last modified: $($logInfo.LastWriteTime)" -ForegroundColor Gray
Write-Host "  Size: $($logInfo.Length) bytes" -ForegroundColor Gray

# Search for compilation errors specifically
Write-Host "" -ForegroundColor White
Write-Host "Searching for compilation errors in Unity log..." -ForegroundColor Yellow

$logContent = Get-Content $logPath -Raw
$errorPatterns = @("CS0103", "CS0246", "CS1061", "CS0029", "CS1002", "CS0117", "error CS")

$foundAnyErrors = $false
foreach ($pattern in $errorPatterns) {
    if ($logContent -match $pattern) {
        $foundAnyErrors = $true
        Write-Host "  Found pattern: $pattern" -ForegroundColor Green
        
        # Get lines with this error
        $lines = $logContent -split "`n"
        $errorLines = $lines | Where-Object { $_ -match $pattern }
        $errorLines | Select-Object -First 3 | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
    }
}

if (-not $foundAnyErrors) {
    Write-Host "  No compilation errors found in Unity log" -ForegroundColor Red
    Write-Host "  This means Unity hasn't compiled the error script yet" -ForegroundColor Yellow
}

Write-Host "" -ForegroundColor White
Write-Host "NEXT STEPS:" -ForegroundColor Cyan
Write-Host "1. Open Unity Editor" -ForegroundColor White
Write-Host "2. Go to Assets > Refresh (or press Ctrl+R)" -ForegroundColor White
Write-Host "3. Look for red errors in Unity Console" -ForegroundColor White
Write-Host "4. If no errors appear, the script path might be wrong" -ForegroundColor White

Write-Host "" -ForegroundColor White
Write-Host "Press Enter to continue..." -ForegroundColor Yellow
Read-Host
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQURkRFBDQvEz7ZavZ4QsKaBB+V
# cmegggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUrLDVXJFbczzGTzMiFigU8NX+ZtkwDQYJKoZIhvcNAQEBBQAEggEAq54u
# I2Cg2wqex0PEhL7NgURs3sgl0/EdO1EITipWVei48NEiP5IHY8rtB1DCuqQq1GuR
# mz0lkpLFyniB+Mo5i3gNA/rIxHLt2LcqK8Ri1ly8mTfpfdn44/vLy8E7q5ZJBiv6
# +ox3ixdStzOC/ZUtmtbnViyuBVvTo4c1SNn9EMuPB9BD8N3flJYKvX7wPc1NDOmv
# CXSgiiJne9raKnPxqYLxaZkz6OPiBDdLZi1TrzhROhN7GFc+HGycSN0zQKAEK+LP
# E9ZmrW+WxwMYc/Yktq8FyHErnNH2HP5In69X5/4FtloGuHchNaO/JyitgSN85ste
# EpQeUXGcKUedbCL1Jw==
# SIG # End signature block
