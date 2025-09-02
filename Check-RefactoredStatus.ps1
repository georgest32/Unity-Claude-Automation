# Check-RefactoredStatus.ps1
# Check which modules are using refactored versions

$modules = @(
    'Unity-Claude-CPG',
    'Unity-Claude-UnityParallelization', 
    'Unity-Claude-IntegratedWorkflow',
    'Unity-Claude-Learning',
    'Unity-Claude-RunspaceManagement',
    'Unity-Claude-HITL',
    'Unity-Claude-ParallelProcessor',
    'Unity-Claude-PerformanceOptimizer',
    'Unity-Claude-DecisionEngine'
)

Write-Host "Checking refactored module status..." -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

foreach ($module in $modules) {
    $path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\$module\$module.psm1"
    if (Test-Path $path) {
        $content = Get-Content $path -First 15
        $refactored = ($content -join ' ') -like '*refactored*'
        $status = if ($refactored) { 'REFACTORED' } else { 'ORIGINAL' }
        $color = if ($refactored) { 'Green' } else { 'Yellow' }
        Write-Host "${module}: $status" -ForegroundColor $color
    } else {
        Write-Host "${module}: NOT FOUND" -ForegroundColor Red
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAh7gqMDYi8OFdb
# BRLFw6Fs4hif8NRnVNX11EqTJ8uhJaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJP6SeP4lG4WGXolriTY/3YG
# 3G/ikGf0+msXuyNxGhdkMA0GCSqGSIb3DQEBAQUABIIBAHQ3G+ib7VzHTspPCGfW
# kQnbV7LsgPJjn+52dV6Q5Sb2/XODnWcKmozZbdW86za05fsaZyc+FFwQcMOMbiuo
# F5p4/GPYyGUpfr0ijE3wI/0lUNt7sTK8sTZ4YpcvHOSFyUWw9xUOwlYMSPUbHK2k
# +BOWB9JF7stKPB2AVsnV8Ad/2arlIJSGVL6F51JX0nM4h4XIdPJMcJ23Y4OpfmeT
# datJAhEluI7rGer12nbLgpWtKcXxUzPMEBnNPhzTOzssxjKRAYcwCCXmrCSeG10L
# b1dH9f5D8sVTbbBQ6K9vBf0SQaeUprA+A/mZTlkPgyaVepQeibqDO3cf7mkzq4L8
# PVI=
# SIG # End signature block
