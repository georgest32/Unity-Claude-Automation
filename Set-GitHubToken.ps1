# Set-GitHubToken.ps1
# Configure Git to use GitHub Personal Access Token

param(
    [Parameter(Mandatory=$true)]
    [string]$Token,
    
    [Parameter(Mandatory=$false)]
    [string]$Username = "georgest32"
)

Write-Host "Configuring GitHub authentication..." -ForegroundColor Cyan

# Set the remote URL with the token
$remoteUrl = "https://${Username}:${Token}@github.com/${Username}/Unity-Claude-Automation.git"

# Update the remote URL
git remote set-url origin $remoteUrl

Write-Host "GitHub authentication configured!" -ForegroundColor Green
Write-Host "You can now push to the repository." -ForegroundColor Yellow

# Test the connection
Write-Host "`nTesting connection..." -ForegroundColor Cyan
git ls-remote origin HEAD

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Connection successful!" -ForegroundColor Green
} else {
    Write-Host "✗ Connection failed. Please check your token." -ForegroundColor Red
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBlGyE9UttPT99p
# GCPcuZHCT7W7vX+dC2HBwU7DIGg8GaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBs3YFqaO8K9CtOIoTOrelEm
# QuErs0aPa0Vd4bMRw9HFMA0GCSqGSIb3DQEBAQUABIIBAD3myDmibvu+JnFopEEb
# +gFgwDQrIjgCqKicnTuauwNm2t+gGJspYCjKBTRW23Yjv5poDJDs0XSIATF7EybO
# xL7SA9samxtjSYpsprl3JFv3E0yXD6scEjoDV6Ih/jDg+2XSvH2nyeA2tc1BnQj+
# eO6KL6LOYu8aKOj/5v9q5Xes+Lvx0Bx4M8BxnYGg0Bm2FiX9NFIm6vSPYcaLLkjw
# 2ZYK882uvhoxUAyWJYfaNf0VKOQt+/x9H504A6qCP5ufLbAiJvFlyPuJ/QCx4Eil
# r7R1lnAHcc7xwBt1kaU4G/ESKJpx3gN0CxqBz9T6KyAtr22s5WnZuqh6zhDNH/qi
# bVw=
# SIG # End signature block
