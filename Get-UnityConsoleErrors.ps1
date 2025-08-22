# Get-UnityConsoleErrors.ps1
# Reads current Unity console errors from the ConsoleErrorExporter output
# Date: 2025-08-17

[CmdletBinding()]
param(
    [Parameter()]
    [string]$ProjectPath = "C:\UnityProjects\Sound-and-Shoal\Dithering",
    
    [Parameter()]
    [switch]$ShowWarnings,
    
    [Parameter()]
    [switch]$Raw
)

Write-Host "=== Unity Console Error Reader ===" -ForegroundColor Cyan

# Path to the exported console log
$consoleExport = Join-Path $ProjectPath "Assets\Editor.log"

if (-not (Test-Path $consoleExport)) {
    Write-Host "[WARNING] Console export not found at: $consoleExport" -ForegroundColor Yellow
    Write-Host "Make sure ConsoleErrorExporter.cs is compiled and running in Unity" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Falling back to system Editor.log..." -ForegroundColor Gray
    
    # Fall back to system Editor.log
    $consoleExport = Join-Path $env:LOCALAPPDATA "Unity\Editor\Editor.log"
}

if (-not (Test-Path $consoleExport)) {
    Write-Host "[ERROR] No log file found" -ForegroundColor Red
    exit 1
}

# Get file info
$fileInfo = Get-Item $consoleExport
$age = (Get-Date) - $fileInfo.LastWriteTime

Write-Host "Reading from: $consoleExport" -ForegroundColor Gray
Write-Host "Last updated: $([Math]::Round($age.TotalSeconds, 1)) seconds ago" -ForegroundColor Gray
Write-Host ""

if ($Raw) {
    # Output raw file contents
    Get-Content $consoleExport
    exit 0
}

# Parse the export file
$content = Get-Content $consoleExport -Raw

# Extract the most recent export section
if ($content -match '(?s)Unity Console Export - ([^\n]+).*?SUMMARY:.*?Errors: (\d+).*?Warnings: (\d+).*?Status: ([^\n]+)') {
    $timestamp = $Matches[1]
    $errorCount = [int]$Matches[2]
    $warningCount = [int]$Matches[3]
    $status = $Matches[4]
    
    Write-Host "Console Status at $timestamp" -ForegroundColor White
    Write-Host "  Errors: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { 'Red' } else { 'Green' })
    Write-Host "  Warnings: $warningCount" -ForegroundColor $(if ($warningCount -gt 0) { 'Yellow' } else { 'Gray' })
    Write-Host "  Status: $status" -ForegroundColor $(if ($errorCount -gt 0) { 'Red' } else { 'Green' })
    Write-Host ""
}

# Extract compilation errors
if ($content -match '(?s)COMPILATION ERRORS:.*?^-+\s*$(.*?)(?=^[A-Z]+:|^=+|$)') {
    $errorSection = $Matches[1].Trim()
    
    if ($errorSection) {
        Write-Host "Compilation Errors:" -ForegroundColor Red
        Write-Host (New-Object string('-', 80)) -ForegroundColor DarkGray
        
        $errors = $errorSection -split "`n" | Where-Object { $_.Trim() }
        foreach ($error in $errors) {
            if ($error -match '^(.+?)\((\d+),(\d+)\): error (CS\d+): (.+)$') {
                $file = $Matches[1]
                $line = $Matches[2]
                $col = $Matches[3]
                $code = $Matches[4]
                $msg = $Matches[5]
                
                Write-Host "  $code" -ForegroundColor Red -NoNewline
                Write-Host ": $msg" -ForegroundColor White
                Write-Host "    at $file" -ForegroundColor Gray -NoNewline
                Write-Host ":$line" -ForegroundColor Cyan -NoNewline
                Write-Host ",$col" -ForegroundColor Cyan
            }
            else {
                Write-Host "  $error" -ForegroundColor Red
            }
        }
        Write-Host ""
    }
}

# Extract warnings if requested
if ($ShowWarnings -and $content -match '(?s)WARNINGS.*?^-+\s*$(.*?)(?=^[A-Z]+:|^=+|$)') {
    $warningSection = $Matches[1].Trim()
    
    if ($warningSection) {
        Write-Host "Warnings:" -ForegroundColor Yellow
        Write-Host (New-Object string('-', 80)) -ForegroundColor DarkGray
        
        $warnings = $warningSection -split "`n" | Where-Object { $_.Trim() }
        foreach ($warning in $warnings | Select-Object -First 5) {
            Write-Host "  $warning" -ForegroundColor Yellow
        }
        Write-Host ""
    }
}

# Check for compilation status
if ($content -match '\[COMPILATION\] (STARTED|FINISHED): (.+)') {
    Write-Host "Last Compilation Event:" -ForegroundColor Cyan
    Write-Host "  $($Matches[1]): $($Matches[2])" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "=== End of Console Errors ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Tips:" -ForegroundColor Gray
Write-Host "- Use -ShowWarnings to include warnings" -ForegroundColor Gray
Write-Host "- Use -Raw to see the raw export file" -ForegroundColor Gray
Write-Host "- The export updates every 2 seconds while Unity is running" -ForegroundColor Gray
Write-Host ""

exit $(if ($errorCount -gt 0) { 1 } else { 0 })
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUzLWvtERGUaeeVuKU1JKg/dPW
# QaqgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU0H0o5rSMLkzAF3L2viRar2tHzocwDQYJKoZIhvcNAQEBBQAEggEAFuX6
# 7jF1NaRQ75UdJXQqIQNAfYctYpKzSB85qtpuMZOWktQ4INyk7DSUvbqRZR223R/T
# jb/ZUyGCMzlNavei2YZP/RD+a/0oBTcxKYM0l195RpVZtJxCT+qRSMBtkPoNfRoF
# nU+bHo2w9Q7uezRg7oKcOvIMCWJlavNFpk1WUfMUGf4ekfwUWwZCjZuDFrQMGDDC
# FFmlZ3o3wdaRBnKmwnX68i+Q8NBbrWdeL2gYotbl/aL6XBsX9zJZ8HlOGW7ais75
# H27+5/BKLbmGq1/CvZN5o2gzHgC6F0rItv3yC9t07Q87PfgZv/GRo7kVS2nxZWxy
# 5Go4Ansmg4EXMnzUHw==
# SIG # End signature block
