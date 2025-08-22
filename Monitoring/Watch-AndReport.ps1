# Watch-AndReport.ps1
# Real-time error monitoring with automatic export capability

[CmdletBinding()]
param(
    [string]$WatchPath = (Join-Path $PSScriptRoot 'AutomationLogs'),
    [switch]$AutoExport,
    [int]$ErrorThreshold = 5,
    [switch]$WatchTests
)

Clear-Host
Write-Host @"
â•"â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—
â•'          Unity-Claude Error Monitor                      â•'
â•'                                                           â•'
â•'  Watching for errors... Press Q to quit                  â•'
â•'  Press E to export current errors                        â•'
â•'  Press C to copy errors to clipboard                     â•'
â•'  Press S to submit errors to Claude                      â•'
â•'  Press A to toggle auto-submit (currently: OFF)          â•'
â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

"@ -ForegroundColor Cyan

$script:ErrorCount = 0
$script:ErrorBuffer = @()
$script:LastExport = $null
$script:AutoSubmit = $false
$script:LastSubmission = $null

# Function to check for new errors
function Check-Errors {
    $logFiles = Get-ChildItem -Path $WatchPath -Filter "*.log" -ErrorAction SilentlyContinue | 
                Sort-Object LastWriteTime -Descending | 
                Select-Object -First 1
    
    if ($logFiles) {
        $content = Get-Content $logFiles.FullName -Tail 50
        $errors = $content | Where-Object { $_ -match '\[ERROR\]|error CS|Exception' }
        
        foreach ($error in $errors) {
            if ($error -notin $script:ErrorBuffer) {
                $script:ErrorBuffer += $error
                $script:ErrorCount++
                
                # Display error
                $timestamp = Get-Date -Format 'HH:mm:ss'
                Write-Host "[$timestamp] ERROR DETECTED:" -ForegroundColor Red
                Write-Host "  $error" -ForegroundColor Yellow
                
                # Auto-export if threshold reached
                if ($AutoExport -and $script:ErrorCount -ge $ErrorThreshold) {
                    Write-Host "`nâš  Error threshold reached! Auto-exporting..." -ForegroundColor Magenta
                    $exportPath = Export-CurrentErrors
                    
                    # Auto-submit to Claude if enabled
                    if ($script:AutoSubmit) {
                        Write-Host "Auto-submitting to Claude..." -ForegroundColor Cyan
                        Submit-ToClaude -ExportPath $exportPath
                    }
                    
                    $script:ErrorCount = 0
                }
            }
        }
    }
}

# Function to export errors
function Export-CurrentErrors {
    Write-Host "`nExporting errors..." -ForegroundColor Yellow
    
    $exportPath = & (Join-Path $PSScriptRoot 'Export-ErrorsForClaude.ps1') `
                    -ErrorType 'Last' `
                    -IncludeConsole `
                    -IncludeTestResults
    
    $script:LastExport = $exportPath
    Write-Host "Exported to: $exportPath" -ForegroundColor Green
    
    # Show quick summary
    if ($script:ErrorBuffer.Count -gt 0) {
        Write-Host "`nError Summary:" -ForegroundColor Cyan
        Write-Host "  Total Errors: $($script:ErrorBuffer.Count)" -ForegroundColor White
        
        $csErrors = ($script:ErrorBuffer | Where-Object { $_ -match 'CS\d{4}' }).Count
        $exceptions = ($script:ErrorBuffer | Where-Object { $_ -match 'Exception' }).Count
        
        if ($csErrors -gt 0) {
            Write-Host "  Compilation Errors: $csErrors" -ForegroundColor Yellow
        }
        if ($exceptions -gt 0) {
            Write-Host "  Exceptions: $exceptions" -ForegroundColor Red
        }
    }
    
    return $exportPath
}

# Function to copy to clipboard
function Copy-ToClipboard {
    if ($script:LastExport -and (Test-Path $script:LastExport)) {
        Get-Content $script:LastExport -Raw | Set-Clipboard
        Write-Host "`nâœ" Copied to clipboard!" -ForegroundColor Green
        Write-Host "  You can now paste directly into Claude" -ForegroundColor Gray
    } elseif ($script:ErrorBuffer.Count -gt 0) {
        Write-Host "`nCopying error buffer to clipboard..." -ForegroundColor Yellow
        
        $clipContent = @"
# Unity-Claude Automation Errors
Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Error Count: $($script:ErrorBuffer.Count)

## Errors:
$($script:ErrorBuffer -join "`n")
"@
        
        $clipContent | Set-Clipboard
        Write-Host "âœ" Copied $($script:ErrorBuffer.Count) errors to clipboard!" -ForegroundColor Green
    } else {
        Write-Host "`nNo errors to copy" -ForegroundColor Yellow
    }
}

# Function to submit to Claude
function Submit-ToClaude {
    param([string]$ExportPath)
    
    Write-Host "`nSubmitting errors to Claude..." -ForegroundColor Cyan
    
    $submitScript = Join-Path $PSScriptRoot 'Submit-ErrorsToClaude-Automated.ps1'
    if (Test-Path $submitScript) {
        if ($ExportPath) {
            & $submitScript -ErrorLogPath $ExportPath
        } else {
            & $submitScript -ErrorType 'Last'
        }
        
        $script:LastSubmission = Get-Date
        Write-Host "Submission complete at $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Green
    } else {
        Write-Host "Submit script not found!" -ForegroundColor Red
    }
}

# Watch for test results if requested
if ($WatchTests) {
    $testWatcher = New-Object System.IO.FileSystemWatcher
    $testWatcher.Path = $PSScriptRoot
    $testWatcher.Filter = "TestReport_*.html"
    $testWatcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite
    
    Register-ObjectEvent -InputObject $testWatcher -EventName "Created" -Action {
        Write-Host "`nðŸ"Š New test report generated!" -ForegroundColor Cyan
        Write-Host "   Run Export-ErrorsForClaude.ps1 -IncludeTestResults to include" -ForegroundColor Gray
    } | Out-Null
}

# Main monitoring loop
Write-Host "Monitoring started at $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Green
Write-Host "Watching: $WatchPath" -ForegroundColor Gray
Write-Host ""

$timer = New-Object System.Timers.Timer
$timer.Interval = 2000  # Check every 2 seconds
$timer.AutoReset = $true
$timer.add_Elapsed({ Check-Errors })
$timer.Start()

# Handle keyboard input
while ($true) {
    if ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)
        
        switch ($key.Key) {
            'Q' {
                Write-Host "`nStopping monitor..." -ForegroundColor Yellow
                $timer.Stop()
                
                if ($script:ErrorBuffer.Count -gt 0) {
                    Write-Host "`nFound $($script:ErrorBuffer.Count) errors during session" -ForegroundColor White
                    Write-Host "Export before quitting? (Y/N): " -NoNewline -ForegroundColor Yellow
                    $response = Read-Host
                    if ($response -eq 'Y') {
                        Export-CurrentErrors
                    }
                }
                
                Write-Host "Monitor stopped." -ForegroundColor Green
                exit
            }
            
            'E' {
                Export-CurrentErrors
            }
            
            'C' {
                Copy-ToClipboard
            }
            
            'S' {
                # Submit to Claude
                Submit-ToClaude -ExportPath $script:LastExport
            }
            
            'A' {
                # Toggle auto-submit
                $script:AutoSubmit = -not $script:AutoSubmit
                $status = if ($script:AutoSubmit) { 'ON' } else { 'OFF' }
                $color = if ($script:AutoSubmit) { 'Green' } else { 'Yellow' }
                Write-Host "`nAuto-submit to Claude: $status" -ForegroundColor $color
                
                # Update header
                Clear-Host
                Write-Host @"
â•"â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—
â•'          Unity-Claude Error Monitor                      â•'
â•'                                                           â•'
â•'  Watching for errors... Press Q to quit                  â•'
â•'  Press E to export current errors                        â•'
â•'  Press C to copy errors to clipboard                     â•'
â•'  Press S to submit errors to Claude                      â•'
â•'  Press A to toggle auto-submit (currently: $status)          â•'
â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

"@ -ForegroundColor Cyan
            }
            
            'T' {
                # Show status (moved from S)
                Write-Host "`nâ•â•â• Current Status â•â•â•" -ForegroundColor Cyan
                Write-Host "Errors Detected: $($script:ErrorBuffer.Count)" -ForegroundColor White
                Write-Host "Last Export: $(if ($script:LastExport) { Split-Path $script:LastExport -Leaf } else { 'None' })" -ForegroundColor White
                Write-Host "Last Submission: $(if ($script:LastSubmission) { $script:LastSubmission.ToString('HH:mm:ss') } else { 'None' })" -ForegroundColor White
                Write-Host "Auto-Submit: $(if ($script:AutoSubmit) { 'ON' } else { 'OFF' })" -ForegroundColor White
                Write-Host "Monitoring: $WatchPath" -ForegroundColor Gray
                Write-Host ""
            }
            
            'H' {
                # Show help
                Write-Host "`nâ•â•â• Keyboard Shortcuts â•â•â•" -ForegroundColor Cyan
                Write-Host "Q - Quit monitoring" -ForegroundColor White
                Write-Host "E - Export errors to file" -ForegroundColor White
                Write-Host "C - Copy to clipboard" -ForegroundColor White
                Write-Host "S - Submit to Claude" -ForegroundColor White
                Write-Host "A - Toggle auto-submit" -ForegroundColor White
                Write-Host "T - Show status" -ForegroundColor White
                Write-Host "H - Show this help" -ForegroundColor White
                Write-Host ""
            }
        }
    }
    
    Start-Sleep -Milliseconds 100
}

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU3WFq6i5t78sJLBKnBklig/FB
# UwqgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU5cxEg4gb44YteM5mOURt98Q9dxwwDQYJKoZIhvcNAQEBBQAEggEAm36/
# yE1hih4xe+2G4wzmXGhHrTum+DRqmV/RwPGA7rf1AW+qmzcihl5w4dWD65aAczGm
# muGnGT/j6vaNDREmYXyu4iypYPez3ToB2UYi3Q8bgMMq8Q2Mrex6/PUIvYPgwTN9
# AA7Iwy5WeNL67t2VaT7oFBUfJ/2LbjNrdhaCJQsoMjU6hn1JxnYK5Jr0UKHoJa2x
# eEwKxChrV8QjpdzDBi8WGPMwy/as2KugRKX6ZTeR6gC8p3s2v+KCQRq1DT3RX3m3
# EAKExpPutZJKFww9CZNkcKpuIR995vu/w/T4pEMpEiOfN68yRb6UHe4ULffKLCSB
# 0BnbhnpVOorWC5F6vA==
# SIG # End signature block
