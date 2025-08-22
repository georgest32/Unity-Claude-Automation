# Fix-SystemStatusTryCatch.ps1
# Fixes missing catch blocks in deduplicated module
# Date: 2025-08-20
# Purpose: Add missing catch blocks to try statements

param(
    [string]$InputPath = ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus-Deduplicated.psm1",
    [string]$OutputPath = ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus-Fixed.psm1"
)

Write-Host "=== Fixing Try-Catch Blocks ===" -ForegroundColor Cyan
Write-Host "Input: $InputPath" -ForegroundColor Gray

# Read the file
$content = Get-Content $InputPath
$fixedContent = @()
$inTryBlock = $false
$tryBraceCount = 0
$fixesApplied = 0

for ($i = 0; $i -lt $content.Count; $i++) {
    $line = $content[$i]
    $fixedContent += $line
    
    # Track try blocks
    if ($line -match '\btry\s*\{') {
        $inTryBlock = $true
        $tryBraceCount = 1
        Write-Host "Found try block at line $($i + 1)" -ForegroundColor Gray
    } elseif ($inTryBlock) {
        # Count braces
        $openBraces = ([regex]::Matches($line, '\{')).Count
        $closeBraces = ([regex]::Matches($line, '\}')).Count
        $tryBraceCount += $openBraces - $closeBraces
        
        # Check if try block is ending
        if ($tryBraceCount -eq 0) {
            $inTryBlock = $false
            
            # Check if next line is catch
            $nextLine = if ($i + 1 -lt $content.Count) { $content[$i + 1] } else { "" }
            if ($nextLine -notmatch '\s*catch' -and $nextLine -notmatch '\s*finally') {
                # Add a generic catch block
                $fixedContent += "    catch {"
                $fixedContent += "        Write-Error `"Error in function: `$_`""
                $fixedContent += "        throw"
                $fixedContent += "    }"
                $fixesApplied++
                Write-Host "  Added catch block after line $($i + 1)" -ForegroundColor Yellow
            }
        }
    }
}

Write-Host "`nApplied $fixesApplied fixes" -ForegroundColor Green

# Write the fixed content
$fixedContent | Set-Content $OutputPath -Encoding UTF8

Write-Host "Fixed module saved to: $OutputPath" -ForegroundColor Cyan

# Test the fixed module
Write-Host "`nTesting fixed module..." -ForegroundColor Yellow
try {
    Import-Module $OutputPath -Force -ErrorAction Stop
    Write-Host "Module imported successfully!" -ForegroundColor Green
    
    # Get exported functions
    $exportedFunctions = Get-Command -Module (Split-Path -Leaf $OutputPath)
    Write-Host "Exported functions: $($exportedFunctions.Count)" -ForegroundColor Green
} catch {
    Write-Error "Failed to import module: $_"
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUb+fOp9oCVMtapt0rqLp0EL+V
# c++gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU/zy5iwLLk+73mkbwFWv7xfh0SjkwDQYJKoZIhvcNAQEBBQAEggEADcFS
# 9VWOdOYhUO2bNPRQnWGKOVfC8Z+jlT1itzOse7AlxI7SzUWQSWO4rXBQR8hquSDe
# 4UsX0IKN0JFGbpYOvFM261A3NNSOTCsag21+3/Sr/wRG+7AL2wnU/UHq1KFrCWbF
# 4qSpdIj+mYPFv43fauXl0WFTLywRBlOdb9bP+i00HKlvqflyvwBU3EC6lEf663yv
# Esnuavxta60jsyn0IgHq5NFcxGLPJ8w+bMTINrftwZd4iQkxaGGIF6ZkDeSyKxYh
# E+Xjo8XFs44sYh78uxADbH7kL8QUOQWxt5dGGw9f8YkX7nqXrN1T7igGPAAs63aj
# HW/MERTeOVKwk3oraA==
# SIG # End signature block
