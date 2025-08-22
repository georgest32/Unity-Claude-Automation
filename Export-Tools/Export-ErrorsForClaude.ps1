# Export-ErrorsForClaude.ps1
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
    [switch]$OpenInNotepad
)

$ErrorActionPreference = 'Continue'

Write-Host "`nâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•" -ForegroundColor Cyan
Write-Host " Error Log Export for Claude Analysis" -ForegroundColor Cyan
Write-Host "â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•`n" -ForegroundColor Cyan

# Collect all relevant logs
$exportContent = @()
$exportContent += "# Unity-Claude Automation Error Report"
$exportContent += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$exportContent += "Machine: $env:COMPUTERNAME"
$exportContent += "User: $env:USERNAME"
$exportContent += ""

#region Automation Logs

Write-Host "Collecting automation logs..." -ForegroundColor Yellow

$logDir = Join-Path $PSScriptRoot 'AutomationLogs'
if (Test-Path $logDir) {
    $logFiles = Get-ChildItem -Path $logDir -Filter "automation_*.log" | Sort-Object LastWriteTime -Descending
    
    switch ($ErrorType) {
        'Last' {
            # Get most recent log file
            $targetLogs = $logFiles | Select-Object -First 1
        }
        'Today' {
            # Get today's logs
            $today = Get-Date -Format 'yyyyMMdd'
            $targetLogs = $logFiles | Where-Object { $_.Name -like "*$today*" }
        }
        'All' {
            # Get all logs from last 7 days
            $targetLogs = $logFiles | Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-7) }
        }
        'Custom' {
            # Get logs in date range
            if (-not $StartTime) { $StartTime = (Get-Date).AddHours(-1) }
            $targetLogs = $logFiles | Where-Object { 
                $_.LastWriteTime -ge $StartTime -and $_.LastWriteTime -le $EndTime 
            }
        }
    }
    
    if ($targetLogs) {
        $exportContent += "## Automation Logs"
        $exportContent += "```"
        
        foreach ($log in $targetLogs) {
            Write-Host "  Reading: $($log.Name)" -ForegroundColor Gray
            $content = Get-Content $log.FullName -Tail 100
            
            # Filter for errors and warnings
            $relevantLines = $content | Where-Object { 
                $_ -match '\[ERROR\]|\[WARN\]|error CS|Exception|failed|Failed'
            }
            
            if ($relevantLines) {
                $exportContent += "--- File: $($log.Name) ---"
                $exportContent += $relevantLines
                $exportContent += ""
            }
        }
        
        $exportContent += "```"
        $exportContent += ""
    } else {
        Write-Host "  No automation logs found for period: $ErrorType" -ForegroundColor Yellow
    }
} else {
    Write-Host "  No AutomationLogs directory found" -ForegroundColor Yellow
}

#endregion

#region Test Results

if ($IncludeTestResults) {
    Write-Host "Collecting test results..." -ForegroundColor Yellow
    
    $testReports = Get-ChildItem -Path $PSScriptRoot -Filter "TestReport_*.html" -ErrorAction SilentlyContinue | 
                   Sort-Object LastWriteTime -Descending | 
                   Select-Object -First 1
    
    if ($testReports) {
        Write-Host "  Found test report: $($testReports.Name)" -ForegroundColor Gray
        
        # Parse HTML for failed tests
        $html = Get-Content $testReports.FullName -Raw
        if ($html -match '<div class="number">(\d+)</div>\s*<div>Failed</div>') {
            $failedCount = $matches[1]
            
            if ([int]$failedCount -gt 0) {
                $exportContent += "## Test Results"
                $exportContent += "Failed Tests: $failedCount"
                $exportContent += ""
                
                # Extract failed test details
                if ($html -match '<table>(.*?)</table>') {
                    $tableContent = $matches[1]
                    $failedTests = [regex]::Matches($tableContent, '<td>(.*?)</td>\s*<td class="failed">Failed</td>\s*<td>(.*?)</td>')
                    
                    $exportContent += "```"
                    foreach ($test in $failedTests) {
                        $exportContent += "FAILED: $($test.Groups[1].Value)"
                        $exportContent += "  Error: $($test.Groups[2].Value)"
                    }
                    $exportContent += "```"
                    $exportContent += ""
                }
            }
        }
    } else {
        Write-Host "  No test reports found" -ForegroundColor Gray
    }
}

#endregion

#region Unity Console Logs

if ($IncludeConsole) {
    Write-Host "Collecting Unity console logs..." -ForegroundColor Yellow
    
    $consolePath = Join-Path $PSScriptRoot 'ConsoleLogs.txt'
    if (Test-Path $consolePath) {
        $consoleContent = Get-Content $consolePath -Tail 200
        
        # Filter for errors
        $errorLines = $consoleContent | Where-Object { 
            $_ -match 'error CS|Exception|Error:|ERROR|Failed'
        }
        
        if ($errorLines) {
            $exportContent += "## Unity Console Errors"
            $exportContent += "```"
            $exportContent += $errorLines | Select-Object -Last 50
            $exportContent += "```"
            $exportContent += ""
            Write-Host "  Found $($errorLines.Count) error lines" -ForegroundColor Gray
        }
    } else {
        Write-Host "  No console log found" -ForegroundColor Gray
    }
}

#endregion

#region Unity Editor Log

if ($IncludeEditorLog) {
    Write-Host "Collecting Unity Editor log..." -ForegroundColor Yellow
    
    $editorLogPath = Join-Path $env:LOCALAPPDATA 'Unity\Editor\Editor.log'
    if (Test-Path $editorLogPath) {
        $editorContent = Get-Content $editorLogPath -Tail 500
        
        # Filter for compilation errors
        $compilationErrors = $editorContent | Where-Object { 
            $_ -match 'Compilation failed|error CS|Scripts have compiler errors'
        }
        
        if ($compilationErrors) {
            $exportContent += "## Unity Editor Log"
            $exportContent += "```"
            $exportContent += $compilationErrors | Select-Object -Last 30
            $exportContent += "```"
            $exportContent += ""
            Write-Host "  Found compilation errors in Editor log" -ForegroundColor Gray
        }
    } else {
        Write-Host "  No Editor log found" -ForegroundColor Gray
    }
}

#endregion

#region System Information

$exportContent += "## System Information"
$exportContent += "```"
$exportContent += "PowerShell Version: $($PSVersionTable.PSVersion)"
$exportContent += "Unity Path: $(if (Test-Path 'C:\Program Files\Unity\Hub\Editor\2021.1.14f1\Editor\Unity.exe') { 'Found' } else { 'Not Found' })"
$exportContent += "Project Path: $PSScriptRoot"
$exportContent += "Modules Available: $(Get-Module -ListAvailable Unity-Claude* | Measure-Object | Select-Object -ExpandProperty Count)"
$exportContent += "```"
$exportContent += ""

#endregion

#region Recent Commands

Write-Host "Collecting recent PowerShell history..." -ForegroundColor Yellow

$historyItems = Get-History | Select-Object -Last 20
if ($historyItems) {
    $exportContent += "## Recent Commands"
    $exportContent += "```powershell"
    foreach ($item in $historyItems) {
        $exportContent += "$($item.Id): $($item.CommandLine)"
    }
    $exportContent += "```"
    $exportContent += ""
}

#endregion

# Save to file
$exportPath = Join-Path $PSScriptRoot "ErrorExport_$(Get-Date -Format 'yyyyMMdd_HHmmss').md"
$exportContent | Out-String | Set-Content -Path $exportPath

Write-Host "`nâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•" -ForegroundColor Green
Write-Host " Export Complete!" -ForegroundColor Green
Write-Host "â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•`n" -ForegroundColor Green

Write-Host "Saved to: $exportPath" -ForegroundColor Cyan
Write-Host "Size: $([Math]::Round((Get-Item $exportPath).Length / 1KB, 1)) KB" -ForegroundColor Gray

# Copy to clipboard if requested
if ($CopyToClipboard) {
    $exportContent | Out-String | Set-Clipboard
    Write-Host "`nâœ" Copied to clipboard!" -ForegroundColor Green
    Write-Host "  You can now paste this directly to Claude" -ForegroundColor Gray
}

# Open in notepad if requested
if ($OpenInNotepad) {
    Start-Process notepad.exe -ArgumentList $exportPath
}

# Show instructions
Write-Host "`n" + ("=" * 50) -ForegroundColor DarkGray
Write-Host "TO SHARE WITH CLAUDE:" -ForegroundColor Yellow
Write-Host "1. Copy the contents of the file above" -ForegroundColor White
Write-Host "2. Paste into your Claude conversation" -ForegroundColor White
Write-Host "3. Ask: 'Here are my Unity-Claude automation errors, please help diagnose'" -ForegroundColor White
Write-Host "`nOr use -CopyToClipboard to copy automatically" -ForegroundColor Gray
Write-Host ("=" * 50) -ForegroundColor DarkGray

return $exportPath

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUUJUnNOfJFoe8kMDkjfv4p9kY
# ZjGgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUPGOUnKBjSN65JZdXnW6GzbyOpFowDQYJKoZIhvcNAQEBBQAEggEALuCp
# XrvPkSPzew+8ofv4YB1/wkLj6x8yT8yEJS7W+fh3wY59b/2J9BEP1clYPIYGVY98
# IQjr8tgiSqSrx0mqVU0D82f4JYLTyf/KGhgk3ZpUdFW92nq7coFc6kR28cM+O3Tg
# umyaO6dH9PyxyYjRngB2INs/SUttSNbNIoW+SL7nJsQiizZj4cRLOMrL8Uj+Qv4x
# oTV4HdYEibnuNS68PzllwM/rsnRpCTE+j94nlbwZoZIPj//OaPZMnyLxNtsMMa3W
# RcY8QRfaog223M1V6M0xmHKBIHFUL/QY0+ACzZGJ3wBCLWGOzk5Cj+/z9cVXyyZb
# cXo20Ufirl2lhW7Hlw==
# SIG # End signature block
