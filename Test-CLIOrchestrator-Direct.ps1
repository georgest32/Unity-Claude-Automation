# Direct test of module loading
Write-Host "Direct module syntax test..." -ForegroundColor Cyan

$modulePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator.psm1"

Write-Host "Testing file: $modulePath" -ForegroundColor Yellow

# Parse the file
$tokens = $null
$errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile(
    $modulePath,
    [ref]$tokens,
    [ref]$errors
)

if ($errors.Count -gt 0) {
    Write-Host "Found $($errors.Count) syntax errors:" -ForegroundColor Red
    foreach ($parseError in $errors) {
        Write-Host ""
        Write-Host "  ERROR at Line $($parseError.Extent.StartLineNumber), Column $($parseError.Extent.StartColumnNumber):" -ForegroundColor Red
        Write-Host "  Message: $($parseError.Message)" -ForegroundColor Yellow
        Write-Host "  Problem text: '$($parseError.Extent.Text)'" -ForegroundColor Gray
        Write-Host "  Context (lines $($parseError.Extent.StartLineNumber - 1) to $($parseError.Extent.EndLineNumber + 1)):" -ForegroundColor DarkGray
        
        # Get context lines
        $lines = Get-Content $modulePath
        $startLine = [Math]::Max(0, $parseError.Extent.StartLineNumber - 2)
        $endLine = [Math]::Min($lines.Count - 1, $parseError.Extent.EndLineNumber)
        
        for ($i = $startLine; $i -le $endLine; $i++) {
            $lineNum = $i + 1
            if ($lineNum -eq $parseError.Extent.StartLineNumber) {
                Write-Host "  > Line ${lineNum}: $($lines[$i])" -ForegroundColor Red
            } else {
                Write-Host "    Line ${lineNum}: $($lines[$i])" -ForegroundColor DarkGray
            }
        }
    }
} else {
    Write-Host "No syntax errors found!" -ForegroundColor Green
    Write-Host "Module syntax is valid." -ForegroundColor Green
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBoJBi37DAIelkU
# Eu6c8xFbLDg/h6hinGj/xPJH5IH3KqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEILZXb9A9/te+KMXxJd/z79tJ
# gluBClSljU9wob6UdQ7CMA0GCSqGSIb3DQEBAQUABIIBABT4NjGQf/iFhgjrldYl
# PLhTxErQpKMHgsqWuVLAd6mBfEPT3+uH2/EspUiD23DPb4RruLkZVglE3fXIX1jK
# TdjiEPx5cDGo2dnR5tTYG4fL0zqfsIAJwK5r+tLPghy7pjU2aovPmsxiwdHQ/FJB
# 3A82OVR6w39QWRp04ef1d/jNdRD3Tg2pk4k2ZadRyL2LhIMIJep00Zr2EKhkT3W3
# IrxC7leqiTypiWKGo7QNfwDb6gkzvcavSbxGVPP+0GA0Ua9rbiZrSgNkDcb8jCMx
# iqoA46ys2cSBYfKgXm3Z74x4XZ+Oqvh2jclIX+Qa2ouTYLYsZ/fw+3w/+S2fKjs7
# jdA=
# SIG # End signature block
