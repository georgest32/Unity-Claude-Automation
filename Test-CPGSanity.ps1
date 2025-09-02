# CPG Module Sanity Checks
cd 'C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation'

Write-Host '=== CPG Module Sanity Checks ===' -ForegroundColor Cyan

# Clean reload
Write-Host 'Cleaning loaded modules...' -ForegroundColor Yellow
'Unity-Claude-CPG','Unity-Claude-CPG-ASTConverter','Unity-Claude-SemanticAnalysis' |
  ForEach-Object { Get-Module $_ -All | Remove-Module -Force -ErrorAction SilentlyContinue }

Write-Host 'Importing modules...' -ForegroundColor Yellow
Import-Module '.\Modules\Unity-Claude-CPG\Unity-Claude-CPG.psd1' -Force -Global
Import-Module '.\Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis.psd1' -Force

# Minimal graph
Write-Host 'Creating test graph...' -ForegroundColor Yellow
$g = ConvertTo-CPGFromScriptBlock -ScriptBlock { function f { $x=1; if($x){$x=2} } } -Verbose:$false
Write-Host '  Graph created successfully' -ForegroundColor Green

# Test that functions return arrays, not null
Write-Host 'Testing analysis functions return arrays...' -ForegroundColor Yellow
$tests = @()

$result = Find-DesignPatterns -Graph $g
$tests += @{ Name='Find-DesignPatterns'; IsArray=($result -is [array]); Result=$result }

$result = Get-CodePurpose -Graph $g
$tests += @{ Name='Get-CodePurpose'; IsArray=($result -is [array]); Result=$result }

$result = Get-CohesionMetrics -Graph $g
$tests += @{ Name='Get-CohesionMetrics'; IsArray=($result -is [array]); Result=$result }

$result = Extract-BusinessLogic -Graph $g
$tests += @{ Name='Extract-BusinessLogic'; IsArray=($result -is [array]); Result=$result }

$result = Recover-Architecture -Graph $g
$tests += @{ Name='Recover-Architecture'; IsArray=($result -is [array]); Result=$result }

Write-Host ''
Write-Host 'Array Return Test Results:' -ForegroundColor Cyan
foreach ($test in $tests) {
    $status = if ($test.IsArray) { '[OK]' } else { '[FAIL]' }
    $color = if ($test.IsArray) { 'Green' } else { 'Red' }
    Write-Host "  $status $($test.Name) returns array: $($test.IsArray)" -ForegroundColor $color
}

# Test OutputFormat
Write-Host ''
Write-Host 'Testing New-QualityReport OutputFormat...' -ForegroundColor Yellow
try {
    if (-not (Test-Path '.\test-reports')) {
        New-Item -Path '.\test-reports' -ItemType Directory -Force | Out-Null
    }
    
    $mdReport = New-QualityReport -Graph $g -OutputPath '.\test-reports' -OutputFormat Markdown -Format @('HTML')
    $mdOk = ($mdReport -is [string] -and $mdReport -like '*# Code Quality Report*')
    Write-Host "  Markdown format: $(if ($mdOk) { '[OK]' } else { '[FAIL]' })" -ForegroundColor $(if ($mdOk) { 'Green' } else { 'Red' })
    
    $jsonReport = New-QualityReport -Graph $g -OutputPath '.\test-reports' -OutputFormat Json -Format @('HTML')
    $jsonOk = ($jsonReport -is [string] -and $jsonReport -like '*{*}*')
    Write-Host "  JSON format: $(if ($jsonOk) { '[OK]' } else { '[FAIL]' })" -ForegroundColor $(if ($jsonOk) { 'Green' } else { 'Red' })
} catch {
    Write-Host "  OutputFormat test failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ''
Write-Host '=== All Sanity Checks Complete ===' -ForegroundColor Green
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAqVPU5vk/PSsLh
# Ku9PWCb7RJG4DWPKX3bWnb6IkqUsS6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEICEdwdyGCGIrPhKAhuiAdowb
# G2ea1MTFiM5suJ/Zmo7/MA0GCSqGSIb3DQEBAQUABIIBAF3JpqG7Kg0HGSPbtXx/
# smhP0JBGOP4TLwJiyaqF7nijYmn7hEx0qu1669tJL6Kv4i5ed8Wjg3Ej87qk9y6p
# 6lKiAJGystUp+sWs0NR4e/0JEMam2pqfi8V54HvmTIJmrLj51q3PXkdmAU2agHjh
# MitGoCzXP9NAEqJ8wQhONiymx44Hw+pBGuipyNPf7BFu93CWe23G+RE+o5FiZt/i
# Oq8iRcd30zg9cU+nJJMBg168KavT+bUtuIzUpVD8IS/UNUDTxIbP8n1Wk42UIGnh
# Rww8vCGvJfOfEua6qPkHmiP5rUr4DV8PCgr+/HG8Z+yZIVSEZkGI7j2cnYCssds4
# 1d8=
# SIG # End signature block
