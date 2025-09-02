# Quick debug test for specific functions
Import-Module "$PSScriptRoot\Modules\Unity-Claude-FileMonitor\Unity-Claude-FileMonitor.psd1" -Force

# Test 1: File Classification
Write-Host "Testing File Classification:" -ForegroundColor Yellow
$testFiles = @("test.ps1", "config.json", "README.md", "Test-Module.ps1", "project.csproj")
foreach ($file in $testFiles) {
    $result = Test-FileChangeClassification -FilePath $file
    Write-Host "  $file -> Type: $($result.FileType), Priority: $($result.Priority)"
}

# Test 2: Get-FileType function directly (if accessible)
Write-Host "`nTesting FileType patterns:" -ForegroundColor Yellow
$patterns = @{
    Code = @('*.ps1', '*.psm1', '*.psd1', '*.cs', '*.js', '*.ts', '*.py')
    Config = @('*.json', '*.xml', '*.yaml', '*.yml', '*.config', '*.ini')
    Documentation = @('*.md', '*.txt', '*.rst', '*.adoc')
    Test = @('*test*.ps1', '*test*.cs', '*spec*.js', '*test*.py')
    Build = @('*.csproj', '*.sln', 'package.json', 'requirements.txt', '*.gradle')
}

foreach ($type in $patterns.Keys) {
    Write-Host "  $type patterns: $($patterns[$type] -join ', ')"
}

Remove-Module -Name 'Unity-Claude-FileMonitor' -Force
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAaRBAsujcDKrut
# QShR9+Pde5zK+UYXBFEhfmuwcRokXqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIHQ12o2Di7md4T3FKRcN8EDG
# 8eqY7bgOqtYd32oO1Z3eMA0GCSqGSIb3DQEBAQUABIIBAEJDgjvqiDMUpHpPJ0kS
# 7p/VT6rUFCsuvH30S0AwB0e1xN4fer+1Vpc9ILb1T0b5CxRnmlptRupbKcPUFbk8
# p3i/BHRv+GLUncPjHjSTd2vTSoVtKcBehd7lD7DE8F8Tt3/SOKWKjnpfyxV+KWv8
# kzAnF/ynivmTIcHujYcrdNypZcghlGLcFraoMXieSaC3or8X5NAmDlV9kxbpvNE3
# 1WPltikTXuRm2wSN1GF/YNzVsVNBpm3zlYL4G3IMMbbqKpI0hIi4THIhE5cRQtfT
# SX7LyJausl7ujGLCvro1XY3fHj7mEFam2IFXEydJvybSFvt10xHxEP32vmhDi10g
# IUY=
# SIG # End signature block
