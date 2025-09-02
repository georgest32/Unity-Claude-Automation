Write-Host 'Testing module import and function availability...' -ForegroundColor Cyan

# Clean all modules
Get-Module Unity-Claude* | Remove-Module -Force -ErrorAction SilentlyContinue

# Import the main module
Write-Host 'Importing Unity-Claude-CPG...' -ForegroundColor Yellow
Import-Module 'C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CPG\Unity-Claude-CPG.psd1' -Force -Global

Write-Host ''
Write-Host 'Testing Convert-ASTtoCPG availability...' -ForegroundColor Yellow
$cmd = Get-Command Convert-ASTtoCPG -ErrorAction SilentlyContinue
if ($cmd) {
    Write-Host "  Convert-ASTtoCPG found in module: $($cmd.Module.Name)" -ForegroundColor Green
    Write-Host "  Source: $($cmd.Source)" -ForegroundColor Cyan
} else {
    Write-Host '  Convert-ASTtoCPG NOT FOUND' -ForegroundColor Red
}

Write-Host ''
Write-Host 'Testing ConvertTo-CPGFromScriptBlock...' -ForegroundColor Yellow
$testCmd = Get-Command ConvertTo-CPGFromScriptBlock -ErrorAction SilentlyContinue
if ($testCmd) {
    Write-Host "  ConvertTo-CPGFromScriptBlock found" -ForegroundColor Green
    Write-Host "  Module: $($testCmd.Module.Name)" -ForegroundColor Cyan
    Write-Host "  Definition first 100 chars: $($testCmd.Definition.Substring(0, [Math]::Min(100, $testCmd.Definition.Length)))" -ForegroundColor Gray
}

Write-Host ''
Write-Host 'Testing simple script block conversion...' -ForegroundColor Yellow
try {
    $sb = { 1+1 }
    $g = ConvertTo-CPGFromScriptBlock -ScriptBlock $sb -Verbose
    Write-Host "  Success! Graph created" -ForegroundColor Green
    if ($g.Nodes) {
        Write-Host "  Nodes: $($g.Nodes.Count)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "  Failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  Stack trace:" -ForegroundColor Yellow
    Write-Host $_.ScriptStackTrace
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBTNsi1/xsyRuLT
# Aj+wz/b4/c62H/BCziRSy11Qh51JiaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIMeDf2yPqA9uKAWPjFyE0A8x
# eIPGZzwmh94cDPFId6Y9MA0GCSqGSIb3DQEBAQUABIIBAKwq5q0qF6Dv1XbvsSmJ
# o0T45kmcZkTUjvOnJI6OzQvBS7EYVcfIrvkbyGcD2dSBFd8j2M1ssRinC5DLR4K/
# iZPeBSRKd89HZP6clQRrPhQwNu1VccSc++D1bMf+FMahWy6BMHOW4J1Nlr81jcMc
# vXWX58MdUM/4OBnjv2MnFpUnxcow8q7Y4WMz2tMmRpfArDBlzQdor+/wqcfytzuy
# B2a2L2Hii6wvGYrdMcZwWHauv9sgHLR77npsqRRMmbCCgWrANmZ6yi6gDPUnCjVs
# Ske3Ba0qqgnOfZLuXsMf48JlhIs3uxaeWmq/E2ockWqms/CEfKGy7BSddKSAUXow
# HcY=
# SIG # End signature block
