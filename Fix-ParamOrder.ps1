# Fix-ParamOrder.ps1
# Fixes the param block order in scripts with PS7 self-elevation

$scriptsToFix = @(
    "Start-UnifiedSystem-Complete.ps1",
    "Start-UnifiedSystem.ps1", 
    "Start-UnifiedSystem-Final.ps1",
    "Start-UnifiedSystem-Fixed.ps1",
    "Start-SystemStatusMonitoring-Generic.ps1",
    "Start-SystemStatusMonitoring-Window.ps1",
    "Start-SystemStatusMonitoring-Enhanced.ps1",
    "Start-SystemStatusMonitoring-Working.ps1",
    "Start-SystemStatusMonitoring.ps1",
    "Start-AutonomousMonitoring.ps1",
    "Start-AutonomousMonitoring-Fixed.ps1",
    "Start-AutonomousMonitoring-Enhanced.ps1",
    "Start-UnityClaudeAutomation.ps1",
    "Start-BidirectionalServer.ps1",
    "Start-SimpleMonitoring.ps1",
    "Start-EnhancedDashboard.ps1",
    "Start-EnhancedDashboard-Fixed.ps1",
    "Start-EnhancedDashboard-Working.ps1"
)

foreach ($script in $scriptsToFix) {
    $path = Join-Path $PSScriptRoot $script
    if (Test-Path $path) {
        Write-Host "Fixing: $script" -ForegroundColor Yellow
        
        $content = Get-Content $path -Raw
        
        # Extract param block if it exists
        if ($content -match '(?ms)(param\s*\([^)]+\))') {
            $paramBlock = $matches[1]
            
            # Remove param block from current location
            $contentNoParam = $content -replace '(?ms)param\s*\([^)]+\)\s*', ''
            
            # Find where to insert (after initial comments but before code)
            $lines = $contentNoParam -split "`r?`n"
            $insertAt = 0
            
            for ($i = 0; $i -lt $lines.Count; $i++) {
                $line = $lines[$i].Trim()
                if ($line -ne "" -and -not $line.StartsWith("#") -and -not $line.StartsWith("<#")) {
                    $insertAt = $i
                    break
                }
            }
            
            # Rebuild with param first
            $newLines = @()
            if ($insertAt -gt 0) {
                $newLines += $lines[0..($insertAt-1)]
            }
            $newLines += ""
            $newLines += $paramBlock
            $newLines += ""
            $newLines += $lines[$insertAt..($lines.Count-1)]
            
            $newContent = $newLines -join "`r`n"
            Set-Content -Path $path -Value $newContent -Encoding UTF8
            Write-Host "  Fixed param order" -ForegroundColor Green
        } else {
            Write-Host "  No param block found" -ForegroundColor Gray
        }
    }
}

Write-Host "`nParam order fixed in all scripts!" -ForegroundColor Green
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDnyNnvbA6XZyLP
# VqMVPoqE429LaFtGJ68Xih2YplnZTaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIM+7HBtcTptqhvEAuZ9k50uw
# Xp4aFz6b00MTJ9jiPLP/MA0GCSqGSIb3DQEBAQUABIIBAJuLn/y7rZcL8C7lXBn0
# TO8zpWzOdiypd0hr5wHijTZsjrJyCovAWWOjlD25FOnTAPuzg2e7BGsQcuw9SlKZ
# RUom6333mXoyj4QypSLYaC6p30eUmouUsEj1XiYgAiauVLLDruFuP8mPZfWOSz7d
# 6dLfDU2aM4UCZtiaBg8C5CSvKjmGbaVnEd6z0kxoCV8aKZlPRmdCUQlXjhOHBwLW
# MJDXBIXJLeYyjthQnWpHCs6YQdPay/PUOfjH/AHhtgrDBXMQjPVIy2rNH8EOISs5
# xsdCUxG+Qi3oWd4GJmxm9dMlyDC8qhfnDHT7+Tyc1XkCUQiz9NL+CiseCPfq4pfh
# tYk=
# SIG # End signature block
