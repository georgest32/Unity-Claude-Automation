# Test script to validate CLIOrchestrator module syntax
Write-Host "Testing CLIOrchestrator module syntax..." -ForegroundColor Cyan

try {
    # Remove any existing module
    Get-Module Unity-Claude-CLIOrchestrator | Remove-Module -Force -ErrorAction SilentlyContinue
    
    # Try to import the module
    Write-Host "Attempting to import module..." -ForegroundColor Yellow
    Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator.psd1" -Force -Verbose
    
    Write-Host "Module imported successfully!" -ForegroundColor Green
    
    # Check available functions
    $functions = Get-Command -Module Unity-Claude-CLIOrchestrator
    Write-Host "Found $($functions.Count) exported functions:" -ForegroundColor Cyan
    $functions | Select-Object -First 10 Name | Format-Table
    
    # Test if key functions exist
    $keyFunctions = @(
        'Start-CLIOrchestration',
        'New-AutonomousPrompt',
        'Get-ActionResultSummary',
        'Invoke-AutonomousExecutionLoop'
    )
    
    foreach ($func in $keyFunctions) {
        if (Get-Command $func -ErrorAction SilentlyContinue) {
            Write-Host "  [OK] $func" -ForegroundColor Green
        } else {
            Write-Host "  [MISSING] $func" -ForegroundColor Red
        }
    }
    
} catch {
    Write-Host "ERROR: Failed to import module" -ForegroundColor Red
    Write-Host "Error details: $_" -ForegroundColor Yellow
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Gray
    
    # Try to parse the file directly
    Write-Host ""
    Write-Host "Attempting to parse module file directly..." -ForegroundColor Yellow
    
    $modulePath = ".\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator.psm1"
    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $modulePath,
        [ref]$tokens,
        [ref]$errors
    )
    
    if ($errors.Count -gt 0) {
        Write-Host "Found $($errors.Count) syntax errors:" -ForegroundColor Red
        foreach ($error in $errors) {
            Write-Host "  Line $($error.Extent.StartLineNumber): $($error.Message)" -ForegroundColor Yellow
            Write-Host "    $($error.Extent.Text)" -ForegroundColor Gray
        }
    } else {
        Write-Host "No syntax errors found in parsing!" -ForegroundColor Green
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAOORuU/mKI7lWW
# a/6JxoCDuTMRUKs/7uZIFOkSWZ4xUqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIIlS6MIXmWU5zxQfrex+AWFe
# 0hjDiaXJhRw4yN0zRrT1MA0GCSqGSIb3DQEBAQUABIIBAGrpSIXbRwyF2JxCKyLx
# jQBIzGtQ5SIktoCHvr/rVGvwLpkrs5xlVtSnDcn/2K3GgVUpZJTLvuELPc0lMUbR
# l5lSCHbSyegui9FaLYO6rtTe6OBYMUgD1BNRjB7W9JtbSgJ5Yzt/52qwQ+J9WntV
# JkPoyMdUlSDzJ6QnlZA7DTqeml0L54QBySg45wht2ii1vu5qhIkXnUN1G6K0M+AV
# DGoJfqfAxxOJFkNRMlZU+cdiTONEMV031kap8aBE7w85BfrQU1ocCQTLUA9AWST/
# SAaFytcq6EzgW6F+ilDHK4Bl5M1Kw5m8FJ9PgkgnHksKuidgxgvH9yRZLuwIDM1+
# XA8=
# SIG # End signature block
