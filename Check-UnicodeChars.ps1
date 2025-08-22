# Check-UnicodeChars.ps1
# Simple script to check for Unicode characters in test script

$scriptPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Testing\Test-ModuleRefactoring-Enhanced.ps1"
$lines = Get-Content $scriptPath

Write-Host "Checking for Unicode dash characters..." -ForegroundColor Yellow
$foundIssues = 0

for ($lineNum = 0; $lineNum -lt $lines.Count; $lineNum++) {
    $line = $lines[$lineNum]
    
    # Check for en-dash (U+2013)
    if ($line.Contains([char]0x2013)) {
        Write-Host "Line $($lineNum + 1): Found EN-DASH" -ForegroundColor Red
        Write-Host "  Content: $line" -ForegroundColor Gray
        $foundIssues++
    }
    
    # Check for em-dash (U+2014) 
    if ($line.Contains([char]0x2014)) {
        Write-Host "Line $($lineNum + 1): Found EM-DASH" -ForegroundColor Red
        Write-Host "  Content: $line" -ForegroundColor Gray
        $foundIssues++
    }
    
    # Check for other non-ASCII characters
    if ($line -match '[^\x00-\x7F]') {
        $nonAsciiChars = @()
        for ($i = 0; $i -lt $line.Length; $i++) {
            $char = $line[$i]
            $unicode = [int][char]$char
            if ($unicode -gt 127) {
                $nonAsciiChars += "U+$($unicode.ToString('X4'))"
            }
        }
        if ($nonAsciiChars.Count -gt 0) {
            Write-Host "Line $($lineNum + 1): Non-ASCII chars: $($nonAsciiChars -join ', ')" -ForegroundColor Yellow
            Write-Host "  Content: $line" -ForegroundColor Gray
            $foundIssues++
        }
    }
}

if ($foundIssues -eq 0) {
    Write-Host "No Unicode character issues found" -ForegroundColor Green
} else {
    Write-Host "Found $foundIssues lines with Unicode character issues" -ForegroundColor Red
}

Write-Host "Analysis complete" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU/jchkEQ5wogghOlsi0Ddj3VC
# 2+igggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU/yCqT6K0ALcnASTY4wl7NPW7fY8wDQYJKoZIhvcNAQEBBQAEggEAI0qw
# QHtjGUO8GkV7W+53pJ1ceiQfzCJ15PqCxp2nM6mIW8Nk/D59XSkxnAw52lI/jLAL
# 56gY14xUqeJRnlKSLjYQbQwgmEhD48e7NtYohk+jZZGCnwFirpjbbdt73jpW3lWr
# mNmkCFLs9jwus8YDfW+C5Z8ei0wXhgzh3Kp9V7Hp3wmIveDBS3rHrmOlMaaKZ3k7
# DHs9xhAWAaornw6aYCXG+x7DyjTo0wTbqD9pcWrsUjrc6xQn4tfwSXrp4Vkk3ftn
# hADGA7jZ1/fwHDUaTPmnnRG4+UamzfMl6hVsAnzQqr+8K1t94foJKj/wKu77h0TO
# g4TmxWb6Dhyx1R9ZPg==
# SIG # End signature block
