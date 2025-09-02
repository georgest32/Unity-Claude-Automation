# Simple test script for PSScriptAnalyzer
Write-Host "Testing PSScriptAnalyzer on a single file..."

# Check if module is available
if (Get-Module -ListAvailable PSScriptAnalyzer) {
    Write-Host "[OK] PSScriptAnalyzer module is available" -ForegroundColor Green
    
    # Import the module
    Import-Module PSScriptAnalyzer -Force
    Write-Host "[OK] PSScriptAnalyzer module imported" -ForegroundColor Green
    
    # Create a test file
    $testFile = "$PSScriptRoot\test-psa.ps1"
    @'
# Test script with some issues
$unused = "This variable is not used"
Write-Host "Hello World"
if($true) { Write-Host "Missing space after if" }
'@ | Out-File -FilePath $testFile -Encoding UTF8
    
    Write-Host "[INFO] Created test file: $testFile" -ForegroundColor Yellow
    
    # Run analysis on the test file
    try {
        Write-Host "[INFO] Running Invoke-ScriptAnalyzer..." -ForegroundColor Yellow
        $results = Invoke-ScriptAnalyzer -Path $testFile -Severity @('Error', 'Warning', 'Information')
        
        if ($results) {
            Write-Host "[OK] Analysis completed. Found $($results.Count) issues:" -ForegroundColor Green
            foreach ($issue in $results) {
                Write-Host "  - [$($issue.Severity)] $($issue.RuleName): $($issue.Message) at line $($issue.Line)" -ForegroundColor Yellow
            }
        } else {
            Write-Host "[OK] No issues found" -ForegroundColor Green
        }
    } catch {
        Write-Host "[ERROR] Failed to run analysis: $_" -ForegroundColor Red
    } finally {
        # Clean up test file
        if (Test-Path $testFile) {
            Remove-Item $testFile -Force
            Write-Host "[INFO] Cleaned up test file" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "[ERROR] PSScriptAnalyzer module is not available" -ForegroundColor Red
    Write-Host "[INFO] Try installing with: Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser" -ForegroundColor Yellow
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDNuJeAptfOpBbN
# UEdFDr4Yn9bUuRBCfdN6yNbTsM8ZwqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIAKZCmMmOHe4G4/spgSnDPQp
# DHtg3bJb2gl5Whf9ADnvMA0GCSqGSIb3DQEBAQUABIIBAA+5eySKuKHTZn1TdEBI
# OwAz7n+wSeuOQOzKcFaTm6jaTTQC5Xpo96rYoqHf1fkg/J6XOZ3/DZFXpWxsaO9d
# p2dznm0RkpvKAZCloR+LQp1wVa2FKYxxMy29SBg1vOzQQa+rGR7I4sDeXRULATmB
# tqovzNh8SqKNvzUKV3wPN6+WhvT70li7UPhSsKPGyLCOVweI/wj5/TlZUnQHYYfQ
# e1WF4wWAOfoznTCHF6TPCj2YwI6xfW3K9H4FuSCO3fKZ5ySFRrwkJ/e4QG47ZnS+
# mLjrvusrB1t7tTXbh9fN1KLox3OjiB2qbfXfdnsRHZkVgUGqlmcWXh+RjJM0yt+q
# q88=
# SIG # End signature block
