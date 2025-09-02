# Start-BidirectionalServer-Launcher.ps1
# Launches the bidirectional server in a new elevated PowerShell window

[CmdletBinding()]
param(
    [int]$Port = 5560,
    [switch]$NoElevate
)

$ErrorActionPreference = 'Stop'

Write-Host "=== Unity-Claude Bidirectional Server Launcher ===" -ForegroundColor Cyan

# Path to the actual server script
$serverScript = Join-Path $PSScriptRoot "Start-BidirectionalServer.ps1"

# Build the command to run in the new window
$arguments = @(
    "-NoExit",
    "-ExecutionPolicy", "Bypass",
    "-File", "`"$serverScript`"",
    "-Port", $Port
)

if ($NoElevate) {
    # Start without elevation
    Write-Host "Starting server in new PowerShell window (non-elevated)..." -ForegroundColor Yellow
    Start-Process pwsh.exe -ArgumentList $arguments
} else {
    # Start with elevation (admin)
    Write-Host "Starting server in new elevated PowerShell window..." -ForegroundColor Yellow
    Write-Host "You may see a UAC prompt requesting admin privileges." -ForegroundColor Gray
    Start-Process pwsh.exe -ArgumentList $arguments -Verb RunAs
}

Write-Host ""
Write-Host "Server launching in new window on port $Port" -ForegroundColor Green
Write-Host ""
Write-Host "The server window will remain open and show:" -ForegroundColor Cyan
Write-Host "  - Incoming requests" -ForegroundColor White
Write-Host "  - Command execution status" -ForegroundColor White
Write-Host "  - Any errors that occur" -ForegroundColor White
Write-Host ""
Write-Host "To test the server, run:" -ForegroundColor Yellow
Write-Host '  Invoke-RestMethod -Uri "http://localhost:5560/status" -Method GET' -ForegroundColor White
Write-Host ""

# Wait a moment for the server to start
Start-Sleep -Seconds 2

# Test if the server is running
try {
    $status = Invoke-RestMethod -Uri "http://localhost:$Port/status" -Method GET -ErrorAction SilentlyContinue
    if ($status.status -eq 'running') {
        Write-Host "[OK] Server is running successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "You can now send commands to the server." -ForegroundColor Cyan
    }
} catch {
    Write-Host "Note: Server may still be starting up. Check the server window for status." -ForegroundColor Yellow
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDyGPuJvC0orWyk
# GQfJ+gfVS9HVrbLYpRtQtRNtab2yDqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCSqGSIb3DQEBCwUAMC4xLDAqBgNVBAMMI1VuaXR5LUNsYXVk
# ZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MB4XDTI1MDgyMDIxMTUxN1oXDTI2MDgy
# MDIxMzUxN1owLjEsMCoGA1UEAwwjVW5pdHktQ2xhdWRlLUF1dG9tYXRpb24tRGV2
# ZWxvcG1lbnQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCx4feqKdUQ
# 6GufY4umNzlM1Pi8aHUGR8HlfhIWFjsrRAxCxhieRlWbHe0Hw+pVBeX76X57e5Pu
# 4Kxxzu+MxMry0NJYf3yOLRTfhYskHBcLraXUCtrMwqnhPKvul6Sx6Lu8vilk605W
# ADJNifl3WFuexVCYJJM9G2mfuYIDN+rZ5zmpn0qCXum49bm629h+HyJ205Zrn9aB
# hIrA4i/JlrAh1kosWnCo62psl7ixbNVqFqwWEt+gAqSeIo4ChwkOQl7GHmk78Q5I
# oRneY4JTVlKzhdZEYhJGFXeoZml/5jcmUcox4UNYrKdokE7z8ZTmyowBOUNS+sHI
# G1TY5DZSb8vdAgMBAAGjRjBEMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggr
# BgEFBQcDAzAdBgNVHQ4EFgQUfDms7LrGVboHjmwlSyIjYD/JLQwwDQYJKoZIhvcN
# AQELBQADggEBABRMsfT7DzKy+aFi4HDg0MpxmbjQxOH1lzUzanaECRiyA0sn7+sA
# /4jvis1+qC5NjDGkLKOTCuDzIXnBWLCCBugukXbIO7g392ANqKdHjBHw1WlLvMVk
# 4WSmY096lzpvDd3jJApr/Alcp4KmRGNLnQ3vv+F9Uj58Uo1qjs85vt6fl9xe5lo3
# rFahNHL4ngjgyF8emNm7FItJeNtVe08PhFn0caOX0FTzXrZxGGO6Ov8tzf91j/qK
# QdBifG7Fx3FF7DifNqoBBo55a7q0anz30k8p+V0zllrLkgGXfOzXmA1L37Qmt3QB
# FCdJVigjQMuHcrJsWd8rg857Og0un91tfZIxggH0MIIB8AIBATBCMC4xLDAqBgNV
# BAMMI1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50AhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKA
# AKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIHAPdQtsN0jfAkN7Tp21SU2z
# WJfj7HFMuzOs+2/1KtHjMA0GCSqGSIb3DQEBAQUABIIBAJBXks4lMPDCUlTxcRU1
# 1en0tcgzJ0MKWK5x4yVa/PachpyV0Rbw5ZqbI4DzjUCTVvBiOq9nzlb3ahAcT6Cv
# 2eAyXRVUhEaLlTAjcEiAn8Vw2Uph7voNPmK6LTStQ2OHs6umUgtfmYcfx9kUgxWY
# RVYNciTq8arRLqFj8HxwyxjscLvIdgZdjc1UneLaN74GjWi3aOQbGmNxgHfbeg7e
# scQI2fjiZWZ2wKlBI3pdh6LWJ5BaWoYO72kUgZCtSlQr3KXTAENc0XUjBsWuOM09
# HvOY5TP8VBVuM1XeHaPE+uF5z1VToujUEcLd4mKO9LD1CbRwFHUTIScSqLuDhsdA
# k4I=
# SIG # End signature block
