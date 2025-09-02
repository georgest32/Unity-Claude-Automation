# Stop-AllProcesses.ps1
# Stops all Unity-Claude automation processes
# Date: 2025-08-25

Write-Host "Stopping all Unity-Claude processes..." -ForegroundColor Yellow

# Kill all PowerShell processes that were started for monitoring
Get-Process pwsh -ErrorAction SilentlyContinue | 
    Where-Object { 
        $_.MainWindowTitle -like "*monitoring*" -or 
        $_.MainWindowTitle -like "*orchestrat*" -or
        $_.MainWindowTitle -like "*autonomous*" -or
        $_.CommandLine -like "*Start-*Monitoring*.ps1*" -or
        $_.CommandLine -like "*CLIOrchestrator*.ps1*"
    } | Stop-Process -Force -ErrorAction SilentlyContinue

# Clean up the system status file to remove stale entries
$statusFile = ".\system_status.json"
if (Test-Path $statusFile) {
    $status = Get-Content $statusFile | ConvertFrom-Json
    
    # Keep only ClaudeCodeCLI
    $cleanedSubsystems = @{}
    if ($status.subsystems.ClaudeCodeCLI) {
        $cleanedSubsystems["ClaudeCodeCLI"] = $status.subsystems.ClaudeCodeCLI
    }
    
    $status.subsystems = $cleanedSubsystems
    $status | ConvertTo-Json -Depth 10 | Set-Content $statusFile
    Write-Host "Cleaned system status file" -ForegroundColor Green
}

# Remove temp monitoring scripts
Get-ChildItem "$env:TEMP\tmp*.tmp.ps1" -ErrorAction SilentlyContinue | Remove-Item -Force

# Remove stop file if exists
if (Test-Path ".\STOP_MONITORING_WINDOW.txt") {
    Remove-Item ".\STOP_MONITORING_WINDOW.txt" -Force
}

# Clear system mutexes to prevent "already running" issues
Write-Host "Clearing system mutexes..." -ForegroundColor Yellow

$mutexNames = @(
    "Global\UnityClaudeCLIOrchestrator",
    "Global\UnityClaudeSystemMonitoring", 
    "Global\UnityClaudeCLISubmission",
    "Global\UnityClaudeEmailNotifications",
    "Global\UnityClaudeNotificationIntegration",
    "Global\UnityClaudeWebhookNotifications"
)

$clearedCount = 0
foreach ($mutexName in $mutexNames) {
    try {
        $mutex = [System.Threading.Mutex]::OpenExisting($mutexName)
        if ($mutex) {
            try {
                $mutex.ReleaseMutex()
                $mutex.Dispose()
                $clearedCount++
            } catch {
                # Ignore release errors - mutex may have been abandoned
            }
        }
    } catch {
        # Ignore open errors - mutex may not exist
    }
}

if ($clearedCount -gt 0) {
    Write-Host "Cleared $clearedCount mutex locks" -ForegroundColor Green
}

Write-Host "All processes stopped" -ForegroundColor Green
Write-Host ""
Write-Host "To restart the system, run:" -ForegroundColor Cyan
Write-Host "  ./Start-UnifiedSystem-Complete.ps1" -ForegroundColor White
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB7W82hSMMlXtCX
# JG6PPh+5RgKW0S+dd9TG4sBMK4sQNaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBZ/Km7p3cL4d9hTM+Du1cCu
# n9Qqm1ZHQHgU1MkjekLfMA0GCSqGSIb3DQEBAQUABIIBAK8aTcYZN4jOl78oSYZv
# aBdb2YD75izqp9pNGrhun+1k3DAn+Z03U04JERLQvV52yIO0vXLR+bgercPy+J8X
# EDnKOJqTxZTL3oh7IFjv33fTPAVFudNiIFoc2K6YRx4jghzUueKqWhhnDw9lSwNB
# GvV3Xm+HHq2h8ZUNTHdu3eCgCjj6gdZrV8cfcjko5ucIp1uwS7QKBTCYxt860IpL
# ht33vNt/Gg0Md0KSabt5XR2bdIA0jG1OkRbhp2X90DXphb5dF/6IM7JSBf0RGEmM
# qHYrngOuRH6b0N3SNQ/LUIZlNE7E+sh0wBzeo6caMks7XXwCqdjkCHka/3fGtU11
# FYU=
# SIG # End signature block
