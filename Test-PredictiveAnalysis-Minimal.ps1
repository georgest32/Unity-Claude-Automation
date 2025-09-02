# Minimal test for PredictiveAnalysis module core functions
param()

# Setup module path
$env:PSModulePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules;$env:PSModulePath"

Write-Host "PredictiveAnalysis Module - Minimal Test" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# Import modules
Import-Module Unity-Claude-CPG -Force -ErrorAction Stop
Import-Module Unity-Claude-LLM -Force -ErrorAction Stop  
Import-Module Unity-Claude-Cache -Force -ErrorAction Stop
Import-Module Unity-Claude-PredictiveAnalysis -Force -ErrorAction Stop 2>$null

# Test 1: Initialize cache
Write-Host "`nTest 1: Initialize Cache" -ForegroundColor Yellow
$result = Initialize-PredictiveCache
Write-Host "  Result: $result" -ForegroundColor $(if($result) {"Green"} else {"Red"})

# Test 2: Create simple graph structure 
Write-Host "`nTest 2: Create Graph" -ForegroundColor Yellow
$graph = New-CPGraph -Name "TestGraph"

# Create nodes with all required properties
$node1 = New-CPGNode -Type Function -Name "Function1" -Properties @{
    LineCount = 100
    Lines = 100
    File = "test.ps1"
    Path = "test.ps1"
    MethodCount = 5
    PropertyCount = 3
    Complexity = 15
    MemberCount = 8
}

$node2 = New-CPGNode -Type Class -Name "Class1" -Properties @{
    LineCount = 500
    Lines = 500
    File = "test.ps1"
    Path = "test.ps1"
    MethodCount = 20
    PropertyCount = 15
    Complexity = 50
    MemberCount = 35
}

Add-CPGNode -Graph $graph -Node $node1
Add-CPGNode -Graph $graph -Node $node2

Write-Host "  Graph created with $($graph.Nodes.Count) nodes" -ForegroundColor Green

# Test 3: Find Long Methods (should work with graph)
Write-Host "`nTest 3: Find Long Methods" -ForegroundColor Yellow
try {
    $longMethods = Find-LongMethods -Graph $graph -Threshold 50
    Write-Host "  Found: $($longMethods.Count) long methods" -ForegroundColor Green
} catch {
    Write-Host "  Error: $_" -ForegroundColor Red
}

# Test 4: Find God Classes
Write-Host "`nTest 4: Find God Classes" -ForegroundColor Yellow
try {
    $godClasses = Find-GodClasses -Graph $graph -MethodThreshold 15
    Write-Host "  Found: $($godClasses.Count) god classes" -ForegroundColor Green
} catch {
    Write-Host "  Error: $_" -ForegroundColor Red
}

# Test 5: Get Coupling Issues
Write-Host "`nTest 5: Get Coupling Issues" -ForegroundColor Yellow
try {
    $issues = Get-CouplingIssues -Graph $graph -Threshold 5
    Write-Host "  Found: $($issues.Count) coupling issues" -ForegroundColor Green
} catch {
    Write-Host "  Error: $_" -ForegroundColor Red
}

# Test 6: Find Anti-Patterns
Write-Host "`nTest 6: Find Anti-Patterns" -ForegroundColor Yellow
try {
    $antiPatterns = Find-AntiPatterns -Graph $graph
    Write-Host "  Found: $($antiPatterns.Count) anti-patterns" -ForegroundColor Green
} catch {
    Write-Host "  Error: $_" -ForegroundColor Red
}

# Test 7: Get Design Flaws
Write-Host "`nTest 7: Get Design Flaws" -ForegroundColor Yellow
try {
    $flaws = Get-DesignFlaws -Graph $graph
    Write-Host "  Found: $($flaws.Count) design flaws" -ForegroundColor Green
} catch {
    Write-Host "  Error: $_" -ForegroundColor Red
}

# Test 8: Calculate Smell Score
Write-Host "`nTest 8: Calculate Smell Score" -ForegroundColor Yellow
try {
    $score = Calculate-SmellScore -Graph $graph
    Write-Host "  Smell score: $score" -ForegroundColor Green
} catch {
    Write-Host "  Error: $_" -ForegroundColor Red
}

# Summary
Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "Minimal Test Complete" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDOKkqxKheVhTdj
# 9SpfXWvrZZljc7hVp9vHAzIEy4BOAqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEICrROo9R18BP3w7wxdtbxtmf
# Esu31pUIe7PcvlE6NKp2MA0GCSqGSIb3DQEBAQUABIIBAI+MiBUiRoCzv51kyalx
# tPPg6e04rGZqIxGvZfq7v+k/5jc3gwO/Y6a/6/rNK6NHntJQBs7CJ1WzU2Htqrd/
# aNkZOJyaqYX7kb/vassSTVWJ1c6TEkTdN7ZiOQL6Eh0BIMbuBvHgo0VPfbkKBU87
# E+2nylzjBB92kDBi9/ZAfP1G5zChjYv4DzmxbfWXc1q7cTjscODUrpdrH0VcpLEJ
# ZPRvAQKyFYAjkQh2vh9j3Me0URb+KZUq3m9YXvyKZPY1GGCP1PtapJIPFqJjyKpd
# lktxspIXVZDUndLUXzynXcBRTkyP2qZFTmJ9dkrQ3mmugzNsQLIVkuRKi8rFIimv
# ZDk=
# SIG # End signature block
