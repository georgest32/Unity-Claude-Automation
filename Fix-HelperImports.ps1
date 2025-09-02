# Fix-HelperImports.ps1
# Fix helper import references in all semantic analysis sub-modules

$files = @(
    'C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis-Architecture.psm1',
    'C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis-Quality.psm1', 
    'C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis-Business.psm1',
    'C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis-Metrics.psm1'
)

foreach ($file in $files) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw
        
        # Fix the import pattern
        $oldPattern = '\. \(Join-Path \$PSScriptRoot "Unity-Claude-SemanticAnalysis-Helpers\.ps1"\)'
        $newPattern = 'Import-Module (Join-Path $PSScriptRoot "Unity-Claude-SemanticAnalysis-Helpers.psm1") -Force -Global'
        
        $newContent = $content -replace [regex]::Escape($oldPattern), $newPattern
        
        if ($newContent -ne $content) {
            Set-Content $file $newContent -Encoding UTF8
            Write-Host "Fixed: $(Split-Path $file -Leaf)" -ForegroundColor Green
        } else {
            Write-Host "No changes needed: $(Split-Path $file -Leaf)" -ForegroundColor Yellow
        }
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCDp45jsFJ4vnoL
# cAwTWyE50vqkCIYoJkvdLYtMMqGDdaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIAfTGQx6t9AcWUPVfU6aUy3E
# pQRwcD7fYblbdtBLoO9BMA0GCSqGSIb3DQEBAQUABIIBAB8zU3EdytcbnpDdD+JH
# BtydpX25Pptfd8+9lSgTu14V8CxtcQMpouBy5iShA9NWq/y5m3Q1BLSq8hRE9bNq
# MU5zCGD9yLkMq9VwOR1XAlZ2qC7wtLqtcjQv5FiG9AYVTD1rJmG3WFEWgVt7Tbni
# sSqc8/9E/E67aE4KLQLAPzedxznNx+CuOHFJc6Bk+K81vyDa+HmGXlusDXQzNlD6
# sfyCKQs54Cpdgd7BwME1/2ZkYxKyaNpaQhvbzPeZ3OInxpOz4jCzg03rdQvlB32l
# zutpsELqEEMo7Tl6hX/C2sRZl1k54GROKET/a2CcEUw3DDYekWNHoUxZ2zxRUuS8
# Sj4=
# SIG # End signature block
