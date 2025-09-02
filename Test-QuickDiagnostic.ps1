Import-Module 'C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CPG\Unity-Claude-CPG.psd1' -Force
Import-Module 'C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis.psd1' -Force

# Create test graph
$sb = { 
    function Get-UserData { }
    function New-Item { }
    class Singleton {
        static [Singleton] $instance
        hidden Singleton() { }
        static [Singleton] GetInstance() {
            if (-not [Singleton]::instance) {
                [Singleton]::instance = [Singleton]::new()
            }
            return [Singleton]::instance
        }
    }
}
$g = ConvertTo-CPGFromScriptBlock -ScriptBlock $sb

Write-Host "=== Testing Get-CodePurpose ===" -ForegroundColor Cyan
$purposes = Get-CodePurpose -Graph $g
Write-Host "Purpose count: $($purposes.Count)"
if ($purposes -and $purposes.Count -gt 0) {
    $first = $purposes[0]
    Write-Host "First result:"
    Write-Host "  Type: $($first.GetType().Name)"
    Write-Host "  Purpose: $($first.Purpose)"
    Write-Host "  Confidence: $($first.Confidence)"
    Write-Host "  Evidence: $($first.Evidence -join ', ')"
}

Write-Host "`n=== Testing Find-DesignPatterns ===" -ForegroundColor Cyan
$patterns = Find-DesignPatterns -Graph $g
Write-Host "Pattern count: $($patterns.Count)"
if ($patterns -and $patterns.Count -gt 0) {
    $first = $patterns[0]
    Write-Host "First pattern:"
    Write-Host "  Type: $($first.Type)"
    Write-Host "  Confidence: $($first.Confidence)"
    Write-Host "  Evidence: $($first.Evidence -join ', ')"
}

Write-Host "`n=== Testing Get-CohesionMetrics ===" -ForegroundColor Cyan
$cohesion = Get-CohesionMetrics -Graph $g
Write-Host "Cohesion results count: $($cohesion.Count)"
if ($cohesion -and $cohesion.Count -gt 0) {
    $first = $cohesion[0]
    Write-Host "First result:"
    Write-Host "  CHM: $($first.CHM)"
    Write-Host "  CHD: $($first.CHD)"
    Write-Host "  OverallCohesion: $($first.OverallCohesion)"
}

Write-Host "`n=== Testing Extract-BusinessLogic ===" -ForegroundColor Cyan
# Add discount function
$sb2 = { 
    function Apply-DiscountCode {
        param($price, $code)
        if ($code -eq "SAVE20") { return $price * 0.8 }
        return $price
    }
}
$g2 = ConvertTo-CPGFromScriptBlock -ScriptBlock $sb2
$business = Extract-BusinessLogic -Graph $g2 -ExtractFromComments -ExtractFromConditionals
Write-Host "Business rules count: $($business.Count)"
if ($business -and $business.Count -gt 0) {
    $first = $business[0]
    Write-Host "First rule:"
    Write-Host "  Type: $($first.Type)"
    Write-Host "  Confidence: $($first.Confidence)"
    Write-Host "  Evidence: $($first.Evidence -join ', ')"
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDchNQLhlhxaXop
# +g3D+B1Z5wSO/IwYa3V1R6y6XZXJUaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIOJOz3QiLDaPSSWyZGzSMNH1
# Et2YCdZolLSDw7ryGHSWMA0GCSqGSIb3DQEBAQUABIIBAJD6SmKblaxZtf+gUl4v
# cjJgdg3oD3Dio/Vy0y8kyc4at9TnfHudPJVWcI7A6OzvLTKhQW75X+W7u14qMHpA
# /CEm5aYHrGb9JjvE6wDcQEViqfbyG9Ed1B6hrRcaq4HqfdkDomoE2LetkQZuAE4l
# tB38VBYnQbdHu9eRZ1KIkNsD1UNSXIHtCvyuUejH10cgL75BjyRipGh0zecYjG7o
# PUFQZ6UlZdMnr3gTEL0cZXEhwxFEpntGFNhPQlSdG0dSoAz49neIjsQQs65Mnl0W
# PD7IlDvej+BBmKPQ5wempvk1XF0yraJJ6e9q6Nhk0fOvuvbPdq6EnNTpTFJxDxf+
# pLs=
# SIG # End signature block
