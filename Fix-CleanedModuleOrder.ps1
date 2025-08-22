# Fix-CleanedModuleOrder.ps1
# Fixes function ordering in the cleaned SystemStatus module
# Date: 2025-08-20
# Purpose: Move initialization code after function definitions

param(
    [string]$InputPath = ".\Unity-Claude-SystemStatus.cleaned.psm1",
    [string]$OutputPath = ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psm1"
)

Write-Host "=== Fixing Function Order in Cleaned Module ===" -ForegroundColor Cyan
Write-Host "Input: $InputPath" -ForegroundColor Gray
Write-Host "Output: $OutputPath" -ForegroundColor Gray

# Read the content
$content = Get-Content $InputPath

# Find the initialization code that uses Write-SystemStatusLog (lines 65-71)
$initCodeStart = 65
$initCodeEnd = 71

# Find where functions start being defined
$functionDefStart = 150  # Just before Write-SystemStatusLog

# Extract sections
$beforeInit = $content[0..($initCodeStart - 2)]  # Before the problematic init code
$initCode = $content[($initCodeStart - 1)..($initCodeEnd - 1)]  # The init code to move
$afterInitBeforeFunctions = $content[$initCodeEnd..($functionDefStart - 1)]  # Between init and functions
$functionsAndRest = $content[($functionDefStart)..$($content.Count - 1)]  # All functions and rest

# Rebuild in correct order
$fixedContent = @()
$fixedContent += $beforeInit
$fixedContent += $afterInitBeforeFunctions  # Skip the init code for now
$fixedContent += ""
$fixedContent += "#region Function Definitions"
$fixedContent += ""
$fixedContent += $functionsAndRest[0..200]  # Include Write-SystemStatusLog and other early functions
$fixedContent += ""
$fixedContent += "#region Module Initialization"
$fixedContent += $initCode  # Now add the init code after functions are defined
$fixedContent += "#endregion"
$fixedContent += ""
$fixedContent += $functionsAndRest[201..$($functionsAndRest.Count - 1)]  # Rest of the functions

Write-Host "`nWriting fixed module..." -ForegroundColor Yellow
$fixedContent | Set-Content $OutputPath -Encoding UTF8

Write-Host "Fixed module saved to: $OutputPath" -ForegroundColor Cyan

# Test the fixed module
Write-Host "`nTesting fixed module..." -ForegroundColor Yellow
try {
    Import-Module $OutputPath -Force -ErrorAction Stop
    Write-Host "Module imported successfully!" -ForegroundColor Green
    
    # Test basic functionality
    $functions = Get-Command -Module (Split-Path -Leaf $OutputPath) -ErrorAction SilentlyContinue
    if ($functions) {
        Write-Host "Module exports $($functions.Count) functions" -ForegroundColor Green
    }
} catch {
    Write-Warning "Module import test failed: $_"
    Write-Host "You may need to manually adjust the function ordering" -ForegroundColor Yellow
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUCjv4CC45n28xFAbMw9SKkYFB
# NRugggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUxWoWV1Uk6SYcSu/HoZ3Y8IyfVLkwDQYJKoZIhvcNAQEBBQAEggEAFrc7
# 7G3UfhsO4aPBVGIOx3jsm7x8lO7EYwwtHkxdnj1+Oqz3mS2cTHVIJQ2erln31XNG
# d5wdRtBTvyz9f7SbreRnxN32Qwpyg6hfj1JWfghg6EePA+ReDCUQE4i9alyaYXeH
# 3w6QEbDCig6Tb85LWfuG7/fJysEOC9F2HV2tx3kH6L10OYH+t8ZxoUUWRcfA/AUo
# N8iK6GBGznYMshocf6AkLLkyOR+zbOfKQHcUfj+TElL9Oyk16z/w552d2YMMxFD5
# I0cTuGfC5G/TxwVLyE1LaygQaOqxMEVKpsz/Rfrbhn+0moFcNlSeYlEw3+i4G6bL
# EE4Sz08arVv0JwHBTw==
# SIG # End signature block
