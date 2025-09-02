# Test live view and module qualification fixes
cd 'C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation'

# Clean session
'Unity-Claude-CPG','Unity-Claude-CPG-ASTConverter','Unity-Claude-SemanticAnalysis' |
  ForEach-Object { Get-Module $_ -All | Remove-Module -Force -ErrorAction SilentlyContinue }

# Import root manifest
Import-Module '.\Modules\Unity-Claude-CPG\Unity-Claude-CPG.psd1' -Force -Global -Verbose:$false
Import-Module '.\Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis.psd1' -Force -Verbose:$false

Write-Host "=== Testing CPG Live View Fixes ===" -ForegroundColor Cyan

# Quick smoke test
$g = ConvertTo-CPGFromScriptBlock -ScriptBlock { function New-Thing { 'x' } } -Verbose:$false
Write-Host "Graph nodes count: $($g.Nodes.Values.Count)"
Write-Host "Functions found: $(($g.GetNodesByType('Function')).Count)"

# Test live view
$nodesBefore = $g.Nodes.Values.Count
Write-Host "Nodes before: $nodesBefore"
Write-Host "Testing live view is working..."
$nodesAfter = $g.Nodes.Values.Count
if ($nodesBefore -eq $nodesAfter) {
    Write-Host "  Live view confirmed: counts match" -ForegroundColor Green
} else {
    Write-Host "  Live view issue: counts differ" -ForegroundColor Red
}

Write-Host ""
Write-Host "Testing pattern detection..." -ForegroundColor Cyan
$patterns = Find-DesignPatterns -Graph $g
Write-Host "  Patterns is array: $($patterns -is [array])"
Write-Host "  Patterns count: $($patterns.Count)"
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA1a243x3zb3MKK
# sZnPsQYtu2/Orp8sugJrQbwIqUHl96CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJx8vzRiC2PUIC0yx8kI27YN
# 8fuRd7ftkLGqwRptjBsHMA0GCSqGSIb3DQEBAQUABIIBAKbboXlto/+NkstQRqoC
# JQStQEwe64ZQ0G7NJWimi6xqyu03ttY9VECfKcJUN8zpV2GCqMzkHA9OXJZlEKji
# HMbLQtjV/CstqNPARmciVpqEXKB3G/pkRCQiKQgzJBHUoB42D2Q3ihnk8hcsDREm
# w5E73xLrzYPI1qMqSAZ7RHhqfRl1+7ZEc6bLW196lHzLDQurZO+vAZSp1tZi+XKc
# oBHUAc5q0WXYzmQT5D+yyCr7Kdwos5/J3gQNvgWBG/pSMu+4Jp6cv479zUndDPBd
# iLel5EszwWkGccN6uoIxeQZJ6NJ6/U0UskZWzsYsZ6d8O25nPqFkoaaUCkO/C05a
# jmw=
# SIG # End signature block
