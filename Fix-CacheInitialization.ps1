# Fix-CacheInitialization.ps1
# Add cache initialization to all semantic analysis sub-modules

$ErrorActionPreference = 'Stop'

$modules = @(
    'Unity-Claude-SemanticAnalysis-Purpose.psm1',
    'Unity-Claude-SemanticAnalysis-Architecture.psm1', 
    'Unity-Claude-SemanticAnalysis-Quality.psm1',
    'Unity-Claude-SemanticAnalysis-Metrics.psm1',
    'Unity-Claude-SemanticAnalysis-Business.psm1'
)

$basePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CPG"

foreach ($module in $modules) {
    $fullPath = Join-Path $basePath $module
    Write-Host "Processing $module..." -ForegroundColor Yellow
    
    if (Test-Path $fullPath) {
        $content = Get-Content $fullPath -Raw
        
        # Check if cache initialization already exists
        if ($content -notmatch "if \(-not \`$script:UC_SA_Cache\)") {
            # Find the import statement and add cache initialization after it
            $pattern = '(\s+Import-Module \(Join-Path \$PSScriptRoot "Unity-Claude-SemanticAnalysis-Helpers\.psm1"\) -Force -Global\s+\})'
            $replacement = '$1
        
        # Ensure cache is initialized (it''s script-scoped so needs to be in each module)
        if (-not $script:UC_SA_Cache) { 
            $script:UC_SA_Cache = @{} 
        }'
            
            $newContent = $content -replace $pattern, $replacement
            
            if ($newContent -ne $content) {
                Set-Content -Path $fullPath -Value $newContent -Encoding UTF8
                Write-Host "  ✓ Added cache initialization to $module" -ForegroundColor Green
            } else {
                Write-Host "  ! Could not find import pattern in $module" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  ✓ Cache initialization already exists in $module" -ForegroundColor Green
        }
    } else {
        Write-Host "  ✗ File not found: $fullPath" -ForegroundColor Red
    }
}

Write-Host "Cache initialization fix completed!" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBvyn36E9pYA9U1
# a7j5creFkzJEDg7mk2Fa2znRIvRYt6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIEA7vhHQ0sqBY0UQG0DaIX18
# 6QWtloEZwwaBQE8r7ARQMA0GCSqGSIb3DQEBAQUABIIBAAwyLXIkMeqjj9y+KQj/
# Jv+Ey4kf2nJSQ2GdN+nUrbuHBDiMmLHLlli38ltx+WZdMioRWPIn4/kT6LPRViWN
# bNJLsNmso1lylg62qGsbfCnOfq97tRv+Dddt2peGMmHGkTYw1VQgRSuow8DsHS0Q
# Np3pfTVW4vivR/JzdjPyXEj0wcm9kkEe5rICpSGiq4yIo1IrWf4RxjOik/DsdNVc
# DDR3F7SmU1iS90H2lUnyO+aBjKufRu2sYWPk5fkCSUiZCi1zqd8IRbFPE5mY3HjU
# eIk/PdZ++sUPeY0Tj9OsIH5C0/6KObCEGtQG/iZ/M60tjIZEOwNU5jXhYwl6zqAE
# bPo=
# SIG # End signature block
