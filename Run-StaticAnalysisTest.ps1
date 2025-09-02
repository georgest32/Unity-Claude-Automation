# Launcher script that automatically uses PowerShell 7 if available
param(
    [switch]$SaveResults,
    [switch]$Verbose
)

# Check if we're running in PowerShell 7
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "Current PowerShell version: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
    Write-Host "Checking for PowerShell 7..." -ForegroundColor Yellow
    
    # Check if PowerShell 7 is available
    $pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($pwsh) {
        Write-Host "PowerShell 7 found. Relaunching with PowerShell 7..." -ForegroundColor Green
        
        # Build arguments
        $arguments = @(
            "-ExecutionPolicy", "Bypass",
            "-File", "`"$PSScriptRoot\Test-StaticAnalysisIntegration-Final.ps1`""
        )
        
        if ($SaveResults) { $arguments += "-SaveResults" }
        if ($Verbose) { $arguments += "-Verbose" }
        
        # Relaunch with PowerShell 7
        & pwsh $arguments
        exit $LASTEXITCODE
    } else {
        Write-Host "PowerShell 7 not found. Running with current version..." -ForegroundColor Yellow
        Write-Host "Note: Some features may not work correctly in PowerShell 5.1" -ForegroundColor Yellow
        
        # Run the test script directly
        & "$PSScriptRoot\Test-StaticAnalysisIntegration-Final.ps1" @PSBoundParameters
    }
} else {
    Write-Host "Running with PowerShell 7 (version $($PSVersionTable.PSVersion))" -ForegroundColor Green
    
    # Already in PowerShell 7, run the test script directly
    & "$PSScriptRoot\Test-StaticAnalysisIntegration-Final.ps1" @PSBoundParameters
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB2nmkCNuaAUwpM
# smVZAvO8c8zrZz+b1pl5WaBirElleqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIL66l2gR2NyEs6CKFHyqqX4H
# KB4QmGWGLGnQf+RudcfqMA0GCSqGSIb3DQEBAQUABIIBAJ4tzX9o1rNSjhsj4tb3
# Sh5OP34UHtXdbU3ytSxzxuFXw8Q51kaMbyqh1t6ILr3GKr/j84NPkVSraQ5NV+oq
# Ur6FCqHghEHIy7kOzf+JdNNVv98ed+DtNDLF6A06fRcNPn+iqRNbPnIMsgqEPko4
# 5MKxNXSWGAoNS2Lben9HgkBTKMTTxGYVYFLlCA1WVbIzN4sWJHtFjXwV2zrq+00a
# 0RRYce9J6RlS/nFpMvbIwpi6jIoxEnCC9gcZZf2AVmoMZxiAv8+002TjtmMAjdrw
# PGPG5Ywtk13kQwigC7BTA2Bz0TE3Lxg2Rf9iAGnSYRJjkQMlyIxPmTsXVgS8KvFl
# sHw=
# SIG # End signature block
