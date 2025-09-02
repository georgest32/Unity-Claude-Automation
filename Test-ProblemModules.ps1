# Quick test of problem modules
$modules = @(
    'Unity-Claude-PredictiveAnalysis',
    'Unity-Claude-ObsolescenceDetection', 
    'Unity-Claude-AutonomousStateTracker-Enhanced',
    'IntelligentPromptEngine',
    'Unity-Claude-DocumentationAutomation',
    'Unity-Claude-ScalabilityEnhancements',
    'DecisionEngine-Bayesian'
)

foreach ($mod in $modules) {
    Write-Host "Testing: $mod" -ForegroundColor Cyan
    
    # Remove any existing module
    Get-Module $mod -All | Remove-Module -Force -ErrorAction SilentlyContinue
    
    # Try to import
    try {
        if ($mod -eq 'Unity-Claude-ObsolescenceDetection') {
            Import-Module '.\Modules\Unity-Claude-CPG\Unity-Claude-ObsolescenceDetection-Refactored.psd1' -Force -Global
        } elseif ($mod -eq 'IntelligentPromptEngine') {
            Import-Module '.\Modules\Unity-Claude-AutonomousAgent\IntelligentPromptEngine-Refactored.psd1' -Force -Global
        } elseif ($mod -eq 'DecisionEngine-Bayesian') {
            Import-Module '.\Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine-Bayesian\Unity-Claude-DecisionEngine-Bayesian.psd1' -Force -Global
        } else {
            Import-Module ".\Modules\$mod\$mod.psd1" -Force -Global
        }
        
        # Check if visible
        $check = Get-Module $mod
        if ($check) {
            Write-Host "  SUCCESS: Module visible in session" -ForegroundColor Green
        } else {
            Write-Host "  ISSUE: Module imported but not visible" -ForegroundColor Yellow
            
            # Try alternate name check
            $altCheck = Get-Module "*$mod*"
            if ($altCheck) {
                Write-Host "  Found as: $($altCheck.Name)" -ForegroundColor Cyan
            }
        }
    } catch {
        Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
    }
    Write-Host ""
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBm4ttfZjmBmTLm
# aHcXX5ZT1Sv1E/0Eo+WzKr517w8VT6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIGljs5y0wahcVaGHKTMPSEr4
# NjhnyVNy2/WDt+30UyMLMA0GCSqGSIb3DQEBAQUABIIBAGkz4FwoZf0VvuUKC+c9
# mF37/618EwFebNy1Ralh87uKTtkkF7fNEXHZdIDu+GxrFZqtGfVq7xOSi/n9ps6D
# 6CR4mw5oF3c7At3m6pt8fj2C7yTSIHkd/xg2Y5RmVv5cwDGxYVhb6Y/NsOcW3Dli
# PvUZpPIttZJ7/6Kyymby6Wv7UYwMfKjpfhfkmoCpj9tOJqNuEe31Q/4wk/FOsSdq
# b/19BLHwvPJfX9+eOaaGPB9FwWwsq22PIx2Td1LpbMyvj0USuDGlxzPlhlK4HQp2
# Vgk903IEOd+XaMFcFBpDByvk40YKL1A3xLhYyIjuTSDa/h7YsRKu1YoWsdCWKUxW
# 1z4=
# SIG # End signature block
