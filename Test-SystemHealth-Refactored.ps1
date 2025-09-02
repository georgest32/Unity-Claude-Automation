# Unity-Claude-Automation System Health Check (Refactored)
# Wrapper script for the modular health check system
# Version: 2025-08-25

[CmdletBinding()]
param(
    [ValidateSet('Quick', 'Full', 'Critical', 'Performance')]
    [string]$TestType = 'Quick',
    
    [string]$OutputPath = '.\health-reports',
    [string]$ConfigPath = '.\config',
    
    [switch]$SaveResults,
    [switch]$Detailed,
    [switch]$IncludeMetrics,
    [switch]$GenerateReport,
    [switch]$Parallel,
    [switch]$ShowProgress,
    
    [ValidateSet('Docker', 'PowerShell', 'API', 'FileSystem', 'Performance', 'All')]
    [string[]]$Components = @('All')
)

# Path to the modular health check system
$modularHealthCheckPath = Join-Path $PSScriptRoot "tests\health-checks\Invoke-ModularHealthCheck.ps1"

# Verify the modular system exists
if (-not (Test-Path $modularHealthCheckPath)) {
    Write-Error "Modular health check system not found at: $modularHealthCheckPath"
    Write-Error "Please ensure the refactored components are in place."
    exit 1
}

Write-Host "Unity-Claude-Automation System Health Check (Refactored)" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
Write-Host ""

# Build parameters for the modular system
$modularParams = @{
    TestType = $TestType
    OutputPath = $OutputPath
    Components = $Components
}

if ($SaveResults) { $modularParams.SaveResults = $true }
if ($Detailed) { $modularParams.Detailed = $true }
if ($IncludeMetrics) { $modularParams.IncludeMetrics = $true }
if ($GenerateReport) { $modularParams.GenerateReport = $true }
if ($Parallel) { $modularParams.Parallel = $true }
if ($ShowProgress) { $modularParams.ShowProgress = $true }

# Execute the modular health check system
try {
    & $modularHealthCheckPath @modularParams
    $exitCode = $LASTEXITCODE
} catch {
    Write-Error "Failed to execute modular health check: $($_.Exception.Message)"
    $exitCode = 1
}

Write-Host ""
Write-Host "Health check completed using modular architecture." -ForegroundColor Cyan
Write-Host "Components tested independently for better maintainability." -ForegroundColor Cyan

exit $exitCode
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCHyXdVX9zjqr9a
# oCIm3/1p0ZhkxcIXTD30oa+56/CTyKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIEvffDMCkKzZWLy5gHEESrhV
# 2JOoLrbwfnXBCE6moD1sMA0GCSqGSIb3DQEBAQUABIIBAI4oqRld5lMyiGsu0mwr
# wmDBj6X74sAPw+xOnQt9bpjBEj7kOJtlEsESVO06cYWFBG66AAJb5nVJuOijFTnT
# ReXilHxoj4hm4lQsWOkRZmirUh2eYK+6D1KzT1ceujgH7sKYUwAdwuADzDo4+UKB
# 4H7eHP473ntoEFLsLUfeEXWrjCMLdsP0YxJR6rDiQgLhsQAaj73Ii5jpf3lPBbUg
# nz9CJozOopbnn1hqd6OZwOCuDLKYenSBIkT1y4IsOxk/BsPEXMaS9D6gtYvNqD30
# 459ZI5hprupa9UFGGq/sNaBy10KPVdO0/s+aogQObdxigCuW1pI+JzUTNF797s4m
# S/E=
# SIG # End signature block
