#Requires -Version 7.0

<#
.SYNOPSIS
Quick test for LangGraph Bridge functionality

.DESCRIPTION  
Simple test to verify PowerShell-LangGraph communication is working
#>

# Import module
Import-Module "$PSScriptRoot\Unity-Claude-LangGraphBridge.psm1" -Force

Write-Host "=== Quick LangGraph Bridge Test ===" -ForegroundColor Cyan

# Test 1: Server connectivity
Write-Host "1. Testing server connectivity..." -NoNewline
$serverHealthy = Test-LangGraphServer
if ($serverHealthy) {
    Write-Host " ✅ PASSED" -ForegroundColor Green
} else {
    Write-Host " ❌ FAILED" -ForegroundColor Red
    exit 1
}

# Test 2: Create basic graph
Write-Host "2. Creating basic graph..." -NoNewline
$graphId = "quicktest-$(Get-Date -Format 'yyyyMMddHHmmss')"
try {
    $createResult = New-LangGraph -GraphId $graphId -GraphType "basic"
    if ($createResult.status -eq "created") {
        Write-Host " ✅ PASSED" -ForegroundColor Green
    } else {
        Write-Host " ❌ FAILED" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host " ❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 3: Execute graph
Write-Host "3. Executing graph..." -NoNewline
try {
    $execution = Start-LangGraphExecution -GraphId $graphId -InitialState @{ counter = 0 }
    if ($execution.status -eq "completed") {
        Write-Host " ✅ PASSED" -ForegroundColor Green
    } else {
        Write-Host " ❌ FAILED: Status was $($execution.status)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host " ❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 4: Cleanup
Write-Host "4. Cleaning up..." -NoNewline
try {
    $deleteResult = Remove-LangGraph -GraphId $graphId -Confirm:$false
    if ($deleteResult.status -eq "deleted") {
        Write-Host " ✅ PASSED" -ForegroundColor Green
    } else {
        Write-Host " ❌ FAILED" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host " ❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n🎉 All quick tests passed! LangGraph Bridge is working." -ForegroundColor Green
exit 0
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDe6Q5j8ogTBacc
# Yv8eDJFlbL0oPYbdsB0lIFQ1lEhbL6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIK/xTJkUn6EXpNv1dk5dvb/r
# zcssghu/TGzJqxb2R14dMA0GCSqGSIb3DQEBAQUABIIBAKTWI6NbwnhlyUUlnuN3
# XLHEGTmD/MciowiDtHofhLxvqKcTEeCHpbuHi33N9UFtyQchCZSgxb+t0ScnHoz3
# H0M5TVX9JU1KBrPSwSTWxxm6iJv08C+GlROdlidf9Bwujp/kwW0giDmOy84EPKW3
# llZq6NQUB+EauX2pApWsAmtz5ZlIbGZcj4AZTSrHZN+2T3L2ZDoGXZQPITjmJaHo
# TrUmHEZbV6okKsCBHaW7u9HbSsjYmlsxZK+ao+iqc1j/9y0R25JvOcb5S/kIespU
# n9H+jtNF//nJNUwjoFseYH5eR3VKUmyZ7f6X0fwTwusqkeyn8oaNceqRhh+qXz3a
# kFo=
# SIG # End signature block
