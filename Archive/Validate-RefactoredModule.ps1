# Validate-RefactoredModule.ps1
# Validate syntax of refactored module

$scriptPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-AutonomousAgent\Unity-Claude-AutonomousAgent-Refactored.psm1"

Write-Host "Validating refactored module syntax: $(Split-Path $scriptPath -Leaf)" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan

if (-not (Test-Path $scriptPath)) {
    Write-Host "Error: Module file not found" -ForegroundColor Red
    exit 1
}

$scriptContent = Get-Content $scriptPath -Raw

Write-Host "Module length: $($scriptContent.Length) characters" -ForegroundColor Gray
Write-Host "Validating syntax..." -ForegroundColor Yellow

$errors = @()
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
        }
        Write-Host ""
        Write-Host "VALIDATION FAILED: Refactored module has syntax errors" -ForegroundColor Red
    } else {
        Write-Host ""
        Write-Host "VALIDATION PASSED: No syntax errors found in refactored module" -ForegroundColor Green
    }
    
} catch {
    Write-Host "Parser error: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "Validation complete" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUZAxzl+MIpn7whYcLywR96nlc
# SiCgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUqqiJHUewAIkV2+IXOMpwWWh5xicwDQYJKoZIhvcNAQEBBQAEggEAMgr+
# lvG5NBsM849S9fiqD3f5uu88XkoBnitDnXudUr++lLlBu+uhH+Utl0ubsCDmNGBp
# yux18oTbudiMNKuQIL9yxqDs4ekWvvFxNZKUQGVXANcRT7JcV0F1AAlIykrQ29Ks
# 3XMdGVkncR18m7bKEL2yviqGUyjdtmQb2LcXZqCIETWlJOrtlF/lY9hiFhkGaA5Y
# +X3MqMxsu4FbGdgvomyGtLqzEscnvNr+80/V82StWJrGlWMqOY07q8G+9i75OTJ0
# ARJSa82I9dRAg4+251bKonRw0ihlH2nqf30kg9hvdersuMiMlJmG635ZI0X5tiDD
# aR16Cizeq1MlnUl5OQ==
# SIG # End signature block
