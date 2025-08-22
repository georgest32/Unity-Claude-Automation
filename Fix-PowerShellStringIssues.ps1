# Fix-PowerShellStringIssues.ps1
# Fixes common PowerShell string interpolation issues that cause parsing errors

param(
    [string]$Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation",
    [switch]$WhatIf
)

Write-Host "Scanning for PowerShell files with potential string issues..." -ForegroundColor Cyan

# Get all PowerShell files
$psFiles = Get-ChildItem -Path $Path -Include "*.ps1", "*.psm1" -Recurse -File

$issuesFound = 0
$filesFixed = 0

foreach ($file in $psFiles) {
    Write-Host "`nChecking: $($file.Name)" -ForegroundColor Yellow
    
    try {
        # Try to parse the file
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $file.FullName,
            [ref]$tokens,
            [ref]$errors
        )
        
        if ($errors.Count -gt 0) {
            Write-Host "  Found $($errors.Count) parsing error(s)" -ForegroundColor Red
            $issuesFound++
            
            foreach ($parseError in $errors) {
                Write-Host "    Line $($parseError.Extent.StartLineNumber): $($parseError.Message)" -ForegroundColor Red
            }
            
            if (-not $WhatIf) {
                # Read the file content
                $content = Get-Content $file.FullName -Raw
                $lines = Get-Content $file.FullName
                
                # Common fixes
                $newContent = $content
                
                # Fix 1: Replace complex string interpolations in Write-Host
                # Instead of: Write-Host "Error: $($_.Error)" -ForegroundColor Yellow
                # Use: $errorMsg = $_.Error; Write-Host "Error: $errorMsg" -ForegroundColor Yellow
                
                # Fix 2: Replace smart quotes with regular quotes
                $newContent = $newContent -replace '[\u201C\u201D]', '"'  # Smart double quotes
                $newContent = $newContent -replace '[\u2018\u2019]', "'"  # Smart single quotes
                
                # Fix 3: Fix check marks and X marks
                $newContent = $newContent -replace '✓', 'PASSED'
                $newContent = $newContent -replace '✗', 'FAILED'
                $newContent = $newContent -replace '✅', '[OK]'
                $newContent = $newContent -replace '❌', '[FAIL]'
                
                # Create backup
                $backupPath = "$($file.FullName).backup"
                Copy-Item $file.FullName $backupPath -Force
                Write-Host "  Created backup: $backupPath" -ForegroundColor Gray
                
                # Write fixed content
                Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8
                Write-Host "  Applied fixes to file" -ForegroundColor Green
                $filesFixed++
                
                # Verify the fix
                $tokens = $null
                $errors = $null
                $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                    $file.FullName,
                    [ref]$tokens,
                    [ref]$errors
                )
                
                if ($errors.Count -eq 0) {
                    Write-Host "  File now parses successfully!" -ForegroundColor Green
                } else {
                    Write-Host "  File still has $($errors.Count) error(s) - manual fix needed" -ForegroundColor Yellow
                    
                    # Log problematic lines for manual review
                    $logPath = "$($file.FullName).fix-needed.txt"
                    $logContent = "File: $($file.FullName)`n"
                    $logContent += "Remaining errors after automated fix:`n"
                    foreach ($parseError in $errors) {
                        $logContent += "  Line $($parseError.Extent.StartLineNumber): $($parseError.Message)`n"
                        if ($parseError.Extent.StartLineNumber -le $lines.Count) {
                            $logContent += "    Content: $($lines[$parseError.Extent.StartLineNumber - 1])`n"
                        }
                    }
                    Set-Content -Path $logPath -Value $logContent
                    Write-Host "  Error details saved to: $logPath" -ForegroundColor Yellow
                }
            }
        } else {
            Write-Host "  No parsing errors found" -ForegroundColor Green
        }
    } catch {
        Write-Host "  Error processing file: $_" -ForegroundColor Red
    }
}

Write-Host "`n=== SUMMARY ===" -ForegroundColor Cyan
Write-Host "Files scanned: $($psFiles.Count)" -ForegroundColor White
Write-Host "Files with issues: $issuesFound" -ForegroundColor Yellow
Write-Host "Files fixed: $filesFixed" -ForegroundColor Green

if ($WhatIf) {
    Write-Host "`nThis was a dry run. Use without -WhatIf to apply fixes." -ForegroundColor Yellow
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUqGo4xpK9tRcDshEx/ep+haxJ
# 8rigggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU1bRVkND6PijI7yMd4ftHM1mtmw0wDQYJKoZIhvcNAQEBBQAEggEAQKml
# U7XTvJcTLLx32xz85J3J1TA9ZBPf16Z0dK6BCzx9x1VQbk/sNmjKCkYH4UdDTXTb
# NgF8bMQaqxgxDxZJQmRIl8LeNhWt9TS8B99uebW0t6Dd+GNOHnIJJ7QDzvPMsgHm
# u8SlOFngcW472iRfTnYXzwYkZiB0pM7YVr7R78j1hon1jgIba6MhmYN1gPQKKDqq
# ZgcLL7xYN0JEeatTEVgi9POkJqYBfD/aJcL1RvsOMcDcOW1J2Dp6gi0LcnMO+Z/Q
# 4XLtAmbwnNyPgdBDB8LxiEN8l+7PXTEoT5u5W4Fj4iuYI7UwC6SQtu0Sja7gbNZl
# ks1UmWI+O5kkuFvqpg==
# SIG # End signature block
