# Test-SimpleRegistration.ps1
# Test simple PID registration

$ErrorActionPreference = "Continue"

Write-Host "Testing Simple Registration" -ForegroundColor Cyan

# Load the module
Import-Module ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1" -Force

# Register with a test PID
$testPID = $PID
Write-Host "Registering with PID: $testPID" -ForegroundColor Yellow

$result = Register-Subsystem -SubsystemName "AutonomousAgent" `
    -ModulePath ".\Modules\Unity-Claude-CLIOrchestrator" `
    -ProcessId $testPID

Write-Host "Registration result: $result" -ForegroundColor Gray

# Check if file was created
if (Test-Path ".\system_status.json") {
    Write-Host "[PASS] system_status.json created" -ForegroundColor Green
    
    $content = Get-Content ".\system_status.json" -Raw | ConvertFrom-Json
    if ($content.subsystems.AutonomousAgent.ProcessId -eq $testPID) {
        Write-Host "[PASS] PID $testPID correctly stored" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] PID not stored correctly" -ForegroundColor Red
        Write-Host "Expected: $testPID" -ForegroundColor Red
        Write-Host "Got: $($content.subsystems.AutonomousAgent.ProcessId)" -ForegroundColor Red
    }
} else {
    Write-Host "[FAIL] system_status.json not created" -ForegroundColor Red
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDAWsSYQqi0VsIB
# fcuOv53AMIyyWxjZYw1Jo2iqbn2CFKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIENOAIMleVyErF3+fI3OuukZ
# qTttm1W+apMpxjfrqTGdMA0GCSqGSIb3DQEBAQUABIIBABxEcIfeZVGuSflR8unI
# aPhMAhGP+od/7cTxwD+0PQ5gaIu6mtdWD/djF3hLDiNFaKPvQ+cuiTZeoUvc2q4d
# g7QpWW9HDzpzGTLxb1x4VtQJJP9c6W58VIntICYxEbRJNfggP7g/lRUNUvLSeint
# q5RcwedK4hVGFAEyGakta1jzcTvfvGS+beB852tEnSKM72E80fGfruzMlJ4TTEVH
# rxTSB1Ukf0LOT3+jNIFGyHu5JhoQeAVJC+1ujqSE/Tb8EnOD5TlHttbIWtIvlDvv
# txSaCSXlmpLM4XLGqSiG6pmtnrKUWBJs2wlcDGuRN5h5e6fwIx7dMBpUUnLrlhcb
# P28=
# SIG # End signature block
