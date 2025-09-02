# Temporary script to create CODEOWNERS file
Import-Module "$PSScriptRoot\Modules\Unity-Claude-GitHub\Unity-Claude-GitHub.psd1" -Force

$rules = @{
    '*.ps1' = @('@unity-claude/powershell-team')
    '*.psm1' = @('@unity-claude/powershell-team') 
    '*.psd1' = @('@unity-claude/powershell-team')
    '*.md' = @('@unity-claude/docs-team')
    '/.github/' = @('@unity-claude/devops-team')
    '/Modules/' = @('@unity-claude/dev-team')
    '/docs/' = @('@unity-claude/docs-team')
    '*test*' = @('@unity-claude/qa-team')
    '*.json' = @('@unity-claude/config-team')
    '/agents/' = @('@unity-claude/ai-team')
    '/scripts/' = @('@unity-claude/automation-team')
}

Write-Host "Creating CODEOWNERS file with governance rules..."
$result = New-GitHubCodeOwnersFile -RepositoryPath $PSScriptRoot -OwnershipRules $rules -DefaultOwners @('@unity-claude/admin') -IncludeComments

Write-Host "CODEOWNERS Creation Result:"
$result | ConvertTo-Json -Depth 3 | Write-Host

if ($result.Success) {
    Write-Host "CODEOWNERS file created successfully at: $($result.OutputPath)" -ForegroundColor Green
    Write-Host "Rules count: $($result.RulesCount)" -ForegroundColor Green
    
    # Show first 20 lines of the created file
    Write-Host "`nFirst 20 lines of CODEOWNERS file:" -ForegroundColor Cyan
    Get-Content $result.OutputPath | Select-Object -First 20 | ForEach-Object { Write-Host $_ }
} else {
    Write-Host "Failed to create CODEOWNERS file: $($result.Error)" -ForegroundColor Red
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA8xnRLN/yf2xEY
# 6ei6onYpckcnTqdZFmm1Q7CqR0Z4iqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIIzKJydfCGx15YblH30HpXCS
# St0zpdhqo7B6MXxymn/WMA0GCSqGSIb3DQEBAQUABIIBAAOa7SEMOwUoXIGV7KM4
# 2hr6PaxqSVRSrIQ92V0oVi+Bo9m+DpHmhlsbEEBDpM8YT672KitWcEJsypD6O9d6
# Fh35Wnb+RoqGFuxpDLvKTsu9I08qlpLInkmOuxDZu6ybkHvXF1xgZpvV48AB4RDD
# xGltXie4NYSwV4tXcX1hkAkN2mfj2JS6Q+VHS6dHvJCv5W5gb2+IXJdNj8wBxKl1
# z2eqhXi1oLj7nGS+Osp0mBRFihUXkTv8DBO5eN5kCgJWlnN07xeKC9P3bM8uWMir
# 6SlQiDh//0CKB7zCHL/2q08x9mm0VU+A62NbETRTnxh+wGMkRTOxsKqIOOVFyBUW
# 3MU=
# SIG # End signature block
