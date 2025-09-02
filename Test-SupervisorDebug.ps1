# Debug test for supervisor functions

# Import modules
$modulePath = Join-Path $PSScriptRoot "Modules\Unity-Claude-MessageQueue"
Import-Module (Join-Path $modulePath "Unity-Claude-MessageQueue.psm1") -Force
Import-Module (Join-Path $modulePath "Unity-Claude-AgentIntegration.psm1") -Force

Write-Host "Testing function availability:" -ForegroundColor Cyan

# Check if Add-MessageToQueue is available
$addMsg = Get-Command Add-MessageToQueue -ErrorAction SilentlyContinue
if ($addMsg) {
    Write-Host "✓ Add-MessageToQueue found" -ForegroundColor Green
} else {
    Write-Host "✗ Add-MessageToQueue NOT found" -ForegroundColor Red
}

# Check if Send-SupervisorMessage is available
$sendSuper = Get-Command Send-SupervisorMessage -ErrorAction SilentlyContinue
if ($sendSuper) {
    Write-Host "✓ Send-SupervisorMessage found" -ForegroundColor Green
} else {
    Write-Host "✗ Send-SupervisorMessage NOT found" -ForegroundColor Red
}

# Initialize supervisor
Write-Host "`nInitializing supervisor..." -ForegroundColor Cyan
$config = Initialize-SupervisorOrchestration -AgentNames @("TestAgent1", "TestAgent2")
Write-Host "Supervisor initialized: $($config.Name)" -ForegroundColor Green

# Try to send a message directly with Add-MessageToQueue
Write-Host "`nTest 1: Direct Add-MessageToQueue..." -ForegroundColor Yellow
try {
    Add-MessageToQueue -QueueName "TestQueue" -Message @{Test="Direct"} -MessageType "Test" -Priority 5
    Write-Host "✓ Direct Add-MessageToQueue succeeded" -ForegroundColor Green
} catch {
    Write-Host "✗ Direct Add-MessageToQueue failed: $_" -ForegroundColor Red
}

# Try to send a supervisor message
Write-Host "`nTest 2: Send-SupervisorMessage..." -ForegroundColor Yellow
try {
    Send-SupervisorMessage -MessageType "Test" -Content @{Data="TestData"} -Priority 7
    Write-Host "✓ Send-SupervisorMessage succeeded" -ForegroundColor Green
} catch {
    Write-Host "✗ Send-SupervisorMessage failed: $_" -ForegroundColor Red
    Write-Host "Error details: $($_.Exception.GetType().FullName)" -ForegroundColor Red
    Write-Host "Stack trace:" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
}

# Check queue status
Write-Host "`nChecking queue status..." -ForegroundColor Cyan
$status = Get-OrchestrationStatus
Write-Host "Supervisor queue messages: $($status.Supervisor.Queue.Messages.Count)" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCHOoIPDiKGDId5
# UAjRvmMutTD+48NVoTapLyw7kB0XBKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIPbauyC9KokpudjHa0Q6VzyC
# z0SbzO8LbV5VFq6/+jMJMA0GCSqGSIb3DQEBAQUABIIBAFhfxXNe0UhyQCJoeInH
# ypR1bVmvbn7oJEvgTfgsuR58jvVE375RiZUwmQGqdKhML9mlzR03yIqZdEEhPv9A
# zz4kXDRiTc7RgDNmDyvsSNfEEJzgeYDX94iRknQzcXsHRPOlR0Or1MBvKcClOcHh
# pAu60vhhTrqQb/NJLZyxt7iwKVZFDuGzCmHZHyOtEkwK2d14wHetpQ6BPP0ncTZh
# W6aSpvX0TRHQxDvTUkJD35JauRbPqZhfh/6JoV6gbX6X1uqpLNNofZMghpa9qe2q
# KuD3WEpBg+KlYKUp2rnprAhEgGFOyKbGwUehTSb36Yz32I6N7WIjBx40lRa9VZln
# Rp8=
# SIG # End signature block
