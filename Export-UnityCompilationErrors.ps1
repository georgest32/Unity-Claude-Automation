# Export-UnityCompilationErrors.ps1
# Enhanced Unity compilation error export that searches multiple patterns
# Date: 2025-08-17

[CmdletBinding()]
param(
    [string]$OutputFile = ".\Logs\unity_errors_latest.txt"
)

Write-Host "=== Unity Compilation Error Export ===" -ForegroundColor Cyan
Write-Host "Searching for Unity compilation errors..." -ForegroundColor Yellow

# Ensure Logs directory exists
$logsDir = Split-Path $OutputFile -Parent
if (-not (Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
}

# Unity Editor.log path
$editorLog = Join-Path $env:LOCALAPPDATA 'Unity\Editor\Editor.log'

if (-not (Test-Path $editorLog)) {
    Write-Host "[ERROR] Unity Editor.log not found at: $editorLog" -ForegroundColor Red
    exit 1
}

Write-Host "Reading Editor.log from: $editorLog" -ForegroundColor Gray

# Read entire log file (not just tail)
$logContent = Get-Content $editorLog -Raw

# Multiple patterns to catch different error formats
$patterns = @(
    # Standard Unity compilation error format
    '(?m)^(.+\.cs)\((\d+),(\d+)\): (error )?(CS\d{4}): (.+)$',
    # Alternative format without "error" prefix
    '(?m)^(.+\.cs)\((\d+),(\d+)\): (CS\d{4}): (.+)$',
    # Simplified error format
    '(?m)^Assets[\\\/].+\.cs.*error CS\d{4}.*$',
    # Generic CS error pattern
    '(?m).*error CS\d{4}.*',
    # Any line with compilation error indicators
    '(?m).*compilation error.*',
    '(?m).*compiler error.*'
)

$foundErrors = @()
$uniqueErrors = @{}

Write-Host "Searching with multiple patterns..." -ForegroundColor Gray

foreach ($pattern in $patterns) {
    $matches = [regex]::Matches($logContent, $pattern)
    
    if ($matches.Count -gt 0) {
        Write-Host "  Found $($matches.Count) matches with pattern: $pattern" -ForegroundColor Green
        
        foreach ($match in $matches) {
            $errorLine = $match.Value.Trim()
            
            # Skip duplicates
            if (-not $uniqueErrors.ContainsKey($errorLine)) {
                $uniqueErrors[$errorLine] = $true
                
                # Try to parse structured error
                if ($errorLine -match '(.+\.cs)\((\d+),(\d+)\): (?:error )?(CS\d{4}): (.+)') {
                    $foundErrors += [PSCustomObject]@{
                        Type = 'Structured'
                        FilePath = $Matches[1]
                        Line = [int]$Matches[2]
                        Column = [int]$Matches[3]
                        ErrorCode = $Matches[4]
                        Message = $Matches[5]
                        FullLine = $errorLine
                    }
                }
                else {
                    # Store as raw error
                    $foundErrors += [PSCustomObject]@{
                        Type = 'Raw'
                        FullLine = $errorLine
                    }
                }
            }
        }
    }
}

# Also check for compilation-related messages
Write-Host "Checking for compilation status messages..." -ForegroundColor Gray
$compilationMessages = $logContent | Select-String -Pattern "Compilation|compile|CS\d{4}" | Select-Object -Last 20

if ($foundErrors.Count -eq 0) {
    Write-Host "[WARNING] No compilation errors found in Editor.log" -ForegroundColor Yellow
    Write-Host "This could mean:" -ForegroundColor Yellow
    Write-Host "  1. Unity hasn't written errors to log yet (try triggering recompile)" -ForegroundColor Gray
    Write-Host "  2. Errors are in console but not in log (Unity timing issue)" -ForegroundColor Gray
    Write-Host "  3. Log was cleared after errors occurred" -ForegroundColor Gray
    
    Write-Host "`nLast compilation-related messages:" -ForegroundColor Yellow
    $compilationMessages | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
}
else {
    Write-Host "`nFound $($foundErrors.Count) unique errors:" -ForegroundColor Green
    
    # Export to file
    $output = @()
    foreach ($errorItem in $foundErrors) {
        if ($errorItem.Type -eq 'Structured') {
            $output += "$($errorItem.ErrorCode): $($errorItem.Message)"
            Write-Host "  $($errorItem.ErrorCode): $($errorItem.Message)" -ForegroundColor Red
            if ($VerbosePreference -eq 'Continue') {
                Write-Host "    File: $($errorItem.FilePath)" -ForegroundColor DarkGray
                Write-Host "    Location: Line $($errorItem.Line), Column $($errorItem.Column)" -ForegroundColor DarkGray
            }
        }
        else {
            $output += $errorItem.FullLine
            Write-Host "  $($errorItem.FullLine)" -ForegroundColor Red
        }
    }
    
    $output | Out-File $OutputFile -Encoding UTF8
    Write-Host "`nErrors exported to: $OutputFile" -ForegroundColor Green
}

# Provide manual entry option
Write-Host "`nIf errors are visible in Unity Console but not detected here:" -ForegroundColor Yellow
Write-Host "You can manually create $OutputFile with format:" -ForegroundColor Gray
Write-Host '  CS1529: A using clause must precede all other elements' -ForegroundColor DarkGray
Write-Host '  CS0246: The type or namespace name could not be found' -ForegroundColor DarkGray

Write-Host "`nExport complete." -ForegroundColor Green
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUtvuT4VI4T0GxLqkQmDp/g3mV
# xWKgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUn8MHPnYVzP2o0CL5NUhimdvoSs0wDQYJKoZIhvcNAQEBBQAEggEAXgPP
# Q9XjCELyWYnTBAaX84+b49ieKUkXjTOq2MWmPgWUmd6haUJPFjbRNFbTw77M0Mty
# grzdlnd0R17+/7aNDOdsUreSS8meYNj0TzWdQmg8QNdw/8sfSJqJotTS2XNST/MD
# S6IuwuhGjZ7Svduywpx1zg8sWrWsDlRqTqa2DBNqM5FG/51D639C8netS1YfRRZp
# YCorW+oTwmAmpwxJiplIXVhErM5/KKKqwBs0uHlnDx1RzTtAT6Z7sVX6RmtFWUrA
# 1yHQClYKv+ymVKxSPotQp1j37AgOcHUZVY/Y4Xhq9vrKVSJJiuSL5eWKDi9SglbC
# WHi8Osy7MnEVH1gSqg==
# SIG # End signature block
