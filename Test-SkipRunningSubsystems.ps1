# Test-SkipRunningSubsystems.ps1
# Tests the fix for skipping already-running subsystems in manifest-based startup

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "TEST: Skip Running Subsystems" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$projectRoot = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"
Set-Location $projectRoot

# Load the SystemStatus module
Write-Host "Loading SystemStatus module..." -ForegroundColor Yellow
Import-Module ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psm1" -Force

# Test the new function
Write-Host "`n1. Testing Test-SubsystemRunning function..." -ForegroundColor Yellow
$testResults = @{
    SystemMonitoring = Test-SubsystemRunning -SubsystemName "SystemMonitoring" -MutexName "Global\UnityClaudeSystemMonitoring"
    AutonomousAgent = Test-SubsystemRunning -SubsystemName "AutonomousAgent" -MutexName "Global\UnityClaudeAutonomousAgent"
    CLISubmission = Test-SubsystemRunning -SubsystemName "CLISubmission" -MutexName "Global\UnityClaudeCLISubmission"
}

Write-Host "  Current subsystem status:" -ForegroundColor White
foreach ($subsystem in $testResults.Keys | Sort-Object) {
    $status = if ($testResults[$subsystem]) { "RUNNING" } else { "NOT RUNNING" }
    $color = if ($testResults[$subsystem]) { "Green" } else { "Gray" }
    Write-Host "    - ${subsystem}: $status" -ForegroundColor $color
}

# Load backward compatibility layer
Write-Host "`n2. Loading backward compatibility layer..." -ForegroundColor Yellow
Import-Module ".\Migration\Legacy-Compatibility.psm1" -Force
Write-Host "  Loaded" -ForegroundColor Green

# Test manifest-based startup with the fix
Write-Host "`n3. Testing manifest-based startup (should skip running subsystems)..." -ForegroundColor Yellow
Write-Host "  This should:" -ForegroundColor Gray
Write-Host "    - Skip SystemMonitoring if already running" -ForegroundColor Gray
Write-Host "    - Skip AutonomousAgent if already running" -ForegroundColor Gray
Write-Host "    - Start any subsystems that aren't running" -ForegroundColor Gray

$result = Invoke-ManifestBasedSystemStartup
if ($result.Success) {
    Write-Host "`n  [SUCCESS] Manifest-based startup completed" -ForegroundColor Green
    Write-Host "  Started subsystems: $($result.StartedSubsystems -join ', ')" -ForegroundColor White
} else {
    Write-Host "`n  [FAILED] Manifest-based startup failed" -ForegroundColor Red
    Write-Host "  Error: $($result.Message)" -ForegroundColor Red
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "TEST COMPLETE" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCNzOCqvBgwHNYX
# GQg+xe3V29K4sEWXixyhy9ogzIcviKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIMj7/uqCcL2iYNg4c8/lR5mu
# 1FIk4CQNNul+4p/z3hStMA0GCSqGSIb3DQEBAQUABIIBAHa2tN45bArx13DnHQYt
# X/Cg5Msj+1Es0WkZfhrZXqNXhIiEH3ClLsut+JGk86ogxKg9SDahbHNZGpU43apc
# q997dLNcGZCwlQup4JdIhpyVk4Fp2C/YUlat0ywv1Dtlzx0aTA5NS8crMzrColoc
# lxQbWc3JhkL3bGmjfrFIA/alGt5oI8/9btlmFyoWwobJuNgncYXWeD7Q9H/X7kOq
# +G0n55XxSodWcHNj2DIb/bN/DgoPGcWlNGhPs63KfDr5Az0SNf4vEBnrN3zf/OXA
# v7I75z073UHp+4ig+BL/UHEMIRRzB49oYbnvIz+iSkpDIo1t/JU2AUFCDT2I+Qv1
# dtI=
# SIG # End signature block
