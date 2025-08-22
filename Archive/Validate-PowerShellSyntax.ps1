# Validate-PowerShellSyntax.ps1
# Script to validate PowerShell syntax using built-in parser

param(
    [string]$ScriptPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Testing\Test-ModuleRefactoring-Enhanced.ps1"
)

Write-Host "Validating PowerShell syntax for: $ScriptPath" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan

# Check if file exists
if (-not (Test-Path $ScriptPath)) {
    Write-Host "Error: Script file not found" -ForegroundColor Red
    exit 1
}

# Read script content
$scriptContent = Get-Content $ScriptPath -Raw

Write-Host "Script length: $($scriptContent.Length) characters" -ForegroundColor Gray
Write-Host "Validating syntax..." -ForegroundColor Yellow

# Use PowerShell parser to validate syntax
$errors = @()
$warnings = @()
$tokens = @()

try {
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($scriptContent, [ref]$tokens, [ref]$errors)
    
    Write-Host ""
    Write-Host "Parser Results:" -ForegroundColor Cyan
    Write-Host "  Tokens found: $($tokens.Count)" -ForegroundColor Gray
    Write-Host "  Errors found: $($errors.Count)" -ForegroundColor $(if ($errors.Count -eq 0) { 'Green' } else { 'Red' })
    
    if ($errors.Count -gt 0) {
        Write-Host ""
        Write-Host "Syntax Errors:" -ForegroundColor Red
        foreach ($error in $errors) {
            Write-Host "  Line $($error.Extent.StartLineNumber): $($error.Message)" -ForegroundColor Red
            Write-Host "    Position: Column $($error.Extent.StartColumnNumber)-$($error.Extent.EndColumnNumber)" -ForegroundColor Gray
            
            # Show the problematic line
            $lines = $scriptContent -split "`n"
            if ($error.Extent.StartLineNumber -le $lines.Count) {
                $problemLine = $lines[$error.Extent.StartLineNumber - 1]
                Write-Host "    Code: $problemLine" -ForegroundColor Yellow
            }
        }
        
        Write-Host ""
        Write-Host "VALIDATION FAILED: Script has syntax errors" -ForegroundColor Red
    } else {
        Write-Host ""
        Write-Host "VALIDATION PASSED: No syntax errors found" -ForegroundColor Green
    }
    
    # Count braces manually
    $openBraces = ($scriptContent -split '' | Where-Object { $_ -eq '{' }).Count
    $closeBraces = ($scriptContent -split '' | Where-Object { $_ -eq '}' }).Count
    
    Write-Host ""
    Write-Host "Brace Count Analysis:" -ForegroundColor Cyan
    Write-Host "  Opening braces: $openBraces" -ForegroundColor Gray
    Write-Host "  Closing braces: $closeBraces" -ForegroundColor Gray
    Write-Host "  Balance: $(if ($openBraces -eq $closeBraces) { 'MATCHED' } else { 'UNMATCHED' })" -ForegroundColor $(if ($openBraces -eq $closeBraces) { 'Green' } else { 'Red' })
    
    if ($openBraces -ne $closeBraces) {
        $difference = $openBraces - $closeBraces
        if ($difference -gt 0) {
            Write-Host "  Missing $difference closing brace(s)" -ForegroundColor Red
        } else {
            Write-Host "  Extra $([Math]::Abs($difference)) closing brace(s)" -ForegroundColor Red
        }
    }
    
} catch {
    Write-Host "Parser error: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "Validation complete" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUPSWrefC58i+nqTIf3oHpCAng
# xPygggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
# AQsFADAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0b21hdGlvbi1EZXZlbG9w
# bWVudDAeFw0yNTA4MjAyMTE1MTdaFw0yNjA4MjAyMTM1MTdaMC4xLDAqBgNVBAMM
# I1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEAseH3qinVEOhrn2OLpjc5TNT4vGh1BkfB5X4S
# FhY7K0QMQsYYnkZVmx3tB8PqVQXl++l+e3uT7uCscc7vjMTK8tDSWH98ji0U34WL
# JBwXC62l1ArazMKp4Tyr7peksei7vL4pZOtOVgAyTYn5d1hbnsVQmCSTPRtpn7mC
# Azfq2ec5qZ9Kgl7puPW5utvYfh8idtOWa5/WgYSKwOIvyZawIdZKLFpwqOtqbJe4
# sWzVahasFhLfoAKkniKOAocJDkJexh5pO/EOSKEZ3mOCU1ZSs4XWRGISRhV3qGZp
# f+Y3JlHKMeFDWKynaJBO8/GU5sqMATlDUvrByBtU2OQ2Um/L3QIDAQABo0YwRDAO
# BgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFHw5
# rOy6xlW6B45sJUsiI2A/yS0MMA0GCSqGSIb3DQEBCwUAA4IBAQAUTLH0+w8ysvmh
# YuBw4NDKcZm40MTh9Zc1M2p2hAkYsgNLJ+/rAP+I74rNfqguTYwxpCyjkwrg8yF5
# wViwggboLpF2yDu4N/dgDainR4wR8NVpS7zFZOFkpmNPepc6bw3d4yQKa/wJXKeC
# pkRjS50N77/hfVI+fFKNao7POb7en5fcXuZaN6xWoTRy+J4I4MhfHpjZuxSLSXjb
# VXtPD4RZ9HGjl9BU8162cRhjujr/Lc3/dY/6ikHQYnxuxcdxRew4nzaqAQaOeWu6
# tGp899JPKfldM5Zay5IBl3zs15gNS9+0Jrd0ARQnSVYoI0DLh3KybFnfK4POezoN
# Lp/dbX2SMYIB4zCCAd8CAQEwQjAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0
# b21hdGlvbi1EZXZlbG9wbWVudAIQdR0W2SKoK5VE8JId4ZxrRTAJBgUrDgMCGgUA
# oHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYB
# BAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0B
# CQQxFgQUTNK5XhrJT2VI3qcuohfbSxFDsnUwDQYJKoZIhvcNAQEBBQAEggEAAtTg
# qcQDA56lhbZOCGSO+Ad95Wy/BY99jV21RSI9S8Xf+qylIaYev5/o/WYl7kirS7xz
# KmlCW2kJqchvcS5TYRrdZjeqjsRr4QOsv+/v68FY2eP9/bM3xnlpt3ePLkeBqpOU
# OrQBpwmPQQJaDrZIPfAdESYd+lQRy4MEvtFx4mVxukH6UcG25Mn8sb6LW5ylhDLQ
# M+5Exi20iqoGAhLe9ElXETVBYk04nSZMoNekxDINjW4flffPTktZhjG3Yul8pTWG
# 3mEsUZPq9TYWr+o3cbW5tlnWk8vOEjnNnDprq4QQA8tt8vQHMAODNE4eEWgWPBXd
# uYxPaNU56nHpYAiatg==
# SIG # End signature block
