# Test just dequeue part

# Enable verbose output
$VerbosePreference = "Continue"

# Import module
$modulePath = Join-Path $PSScriptRoot "Modules\Unity-Claude-MessageQueue"
Import-Module (Join-Path $modulePath "Unity-Claude-MessageQueue.psm1") -Force

# Add messages
$iterations = 10
Write-Host "Adding $iterations messages..." -ForegroundColor Cyan
for ($i = 1; $i -le $iterations; $i++) {
    $null = Add-MessageToQueue -QueueName "BenchmarkQueue" -Message @{
        Index = $i
        Timestamp = Get-Date
    } -MessageType "Benchmark" -Priority 5
}

# Exact same retrieval code as the test
Write-Host "`nRetrieving messages (same as test)..." -ForegroundColor Yellow
$retrieved = 0

for ($i = 1; $i -le $iterations; $i++) {
    $msg = Get-MessageFromQueue -QueueName "BenchmarkQueue" -TimeoutSeconds 0.1
    if ($msg) { 
        $retrieved++ 
        Write-Host "  Got message $($msg.Content.Index)" -ForegroundColor Green
    } else {
        Write-Host "  No message at iteration $i" -ForegroundColor Red
    }
}

Write-Host "`nRetrieved: $retrieved/$iterations" -ForegroundColor $(if ($retrieved -eq $iterations) { "Green" } else { "Red" })
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBpDW7O5+I7KAGY
# vn+RXgClMeeyZ3q6tl6lhg0fIMkFRaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIO78/ohBJX3GYRW76AZppwiE
# AnTH0mbsh7wvDzQygCcfMA0GCSqGSIb3DQEBAQUABIIBAAoU2X5cpxa9N+nJOnoa
# pv4np/K6HWPzKSMsy1mTIyQSGf7FxNy8SXQJuIsOykC5DfiwENvwcPX6Sp0l4Xaa
# +C37P378jeF3qc+U9S38VrpBu8335ng+PmtSIueeqmxBCQ0yERDuQQgQzxUqLNcm
# t7EGitl3f9oMHspL5FRO8IrlYYvYsRlLdZAohsqxmXKGdOVvYWWinNbSfe7NuYvE
# HGTkmd7I03w2jZXP3CTcAzfkWpOS8s6uUn339Q08NSS4x21zWXE3rb45WQyOKG1a
# n5Aurw1SaQlqrK+Qgwhe/uDTnPBNd4QLU77K8GgSyqWN9NGXrHnO0ukTS50JSGPl
# fb4=
# SIG # End signature block
