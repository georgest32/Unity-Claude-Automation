# Set-ClaudeCodeCLITitle.ps1
# Sets the window title for the Claude Code CLI window
# This helps the automation system identify the correct window

param(
    [string]$Title = "Claude Code CLI environment"
)

Write-Host "Setting window title to: $Title" -ForegroundColor Cyan

# Set the console window title
$host.UI.RawUI.WindowTitle = $Title

Write-Host "Window title set successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "The automation system will now be able to identify this window correctly." -ForegroundColor Yellow
Write-Host "Make sure to run this script in the Claude Code CLI window." -ForegroundColor Yellow
Write-Host ""
Write-Host "Current window title: $($host.UI.RawUI.WindowTitle)" -ForegroundColor Gray

# Update system_status.json with the window title for reference
$statusFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\system_status.json"
if (Test-Path $statusFile) {
    try {
        $status = Get-Content $statusFile -Raw | ConvertFrom-Json
        if ($status.SystemInfo -and $status.SystemInfo.ClaudeCodeCLI) {
            # Add window title to the ClaudeCodeCLI info
            if ($status.SystemInfo.ClaudeCodeCLI -is [PSCustomObject]) {
                $status.SystemInfo.ClaudeCodeCLI | Add-Member -MemberType NoteProperty -Name "WindowTitle" -Value $Title -Force
            }
            $status | ConvertTo-Json -Depth 10 | Set-Content $statusFile -Encoding UTF8
            Write-Host "Updated system_status.json with window title" -ForegroundColor Green
        }
    } catch {
        Write-Warning "Could not update system_status.json: $_"
    }
}

# Also write to a marker file that this is the Claude Code CLI window
$markerFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\.claude_code_cli_pid"
$PSVersionTable.PSVersion.ToString() + "`n" + $PID + "`n" + $Title | Set-Content $markerFile -Encoding UTF8
Write-Host "Created PID marker file: $markerFile" -ForegroundColor Gray
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDuAK55myzoeRoi
# LViLyhSUU0qVZ69pfwcYUVZBQO8mH6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIAU5xHouw7a1i8nhSlpEfIsJ
# n253YId4j6XJQQgPIIyuMA0GCSqGSIb3DQEBAQUABIIBACvcU4yF3q8q70pHpSsX
# 6nxyhKdZSv90ngzeILM6Zn6IsmpdMrkVqXqSUQ6SaBRHHfFg3cqzxu24jqQvXUCo
# zxJ7Y+1+233OJDKzhEecIlPBJgYy9iHiP7mEjMVwnYdMWDdroIDUWq1b3fBIcLcI
# xA7rE1EWHN2tScFt/6CREbZZonCmfQfFJXI6LbFAz4TKPPAbjiTwDjTZncnTejPx
# 8E9B1gtgqis4wvPmXSYMcWArDPZLwgc+d6PClQacGkDsdHRqi9t92MlS2ASattS8
# pS8QtTAaoGMlodFgTrdB+iVO1JfRjHDbik5C51MpeNKEZgjwXiAadltP/OkjDRJk
# djo=
# SIG # End signature block
