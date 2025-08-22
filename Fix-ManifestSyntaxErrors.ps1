# Fix-ManifestSyntaxErrors.ps1
# Fix syntax errors created by commenting out RequiredModules
# Date: 2025-08-21

Write-Host "=== Fix Manifest Syntax Errors ===" -ForegroundColor Cyan
Write-Host "Correcting malformed RequiredModules comments" -ForegroundColor White
Write-Host ""

$moduleBasePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules"
$manifestsToFix = @(
    "$moduleBasePath\Unity-Claude-IntegratedWorkflow\Unity-Claude-IntegratedWorkflow.psd1",
    "$moduleBasePath\Unity-Claude-RunspaceManagement\Unity-Claude-RunspaceManagement.psd1",
    "$moduleBasePath\Unity-Claude-UnityParallelization\Unity-Claude-UnityParallelization.psd1",
    "$moduleBasePath\Unity-Claude-ClaudeParallelization\Unity-Claude-ClaudeParallelization.psd1"
)

foreach ($manifestPath in $manifestsToFix) {
    if (-not (Test-Path $manifestPath)) {
        Write-Host "[SKIP] Manifest not found: $manifestPath" -ForegroundColor Red
        continue
    }
    
    $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($manifestPath)
    Write-Host "[PROCESSING] $moduleName..." -ForegroundColor Cyan
    
    try {
        # Read the current content
        $content = Get-Content $manifestPath -Raw -Encoding UTF8
        
        # Fix the malformed RequiredModules comment structure
        # Replace the current broken pattern with a proper comment block
        $fixedContent = $content -replace '# RequiredModules = @\(\s*([^)]*)\s*\) # COMMENTED OUT: Causing module nesting limit issues', '# RequiredModules commented out to prevent nesting limit issues
    # RequiredModules = @(
    #     $1
    # )'
        
        # Also fix any stray quotes or syntax issues
        $fixedContent = $fixedContent -replace "'\s*\n\s*\)", "'`n    )"
        
        # Write the corrected content back
        $fixedContent | Set-Content $manifestPath -Encoding UTF8 -Force
        
        # Test if the manifest is now valid
        try {
            Test-ModuleManifest $manifestPath -ErrorAction Stop | Out-Null
            Write-Host "   [SUCCESS] Manifest syntax corrected and validated" -ForegroundColor Green
        } catch {
            Write-Host "   [WARNING] Manifest may still have issues: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "   [ERROR] Failed to fix manifest: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== Syntax Fix Complete ===" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUQI4G9YzASioQIaZLdBCWj/ly
# YM+gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUwdKfcEe23TjHR7eGe4R/E5wzXrAwDQYJKoZIhvcNAQEBBQAEggEABirU
# gDeOcmc8w0OdAMLLotxnxCdufS351L+m2NRTpwE2RejANGE3vPZeF/8mYJiiieZH
# UoPjsTAyqc43KeB+jd8p8+CxeglTTXx6D4bSKN2nR+XZhrQU9bDdNwrW7ZSg/8aL
# OisfBqIYCyWgW23izdR2sR38i9vrqfcknVyBzt8IgJXa9AoK9c9DTyqOR/FlBMxS
# ICHqZWq2Rr0UkPVCdilFioU5T1LbROLtKllvx/qI9ZT7L2YNMgxPU8b735XHSVas
# j4hI7FUT9Djqhpsn6r9QTpAkJ1Ym0s63dgjMjbBKuv1ttIBX1J9UlooVIKX54BSy
# HKP6NoVh2VRhQmpm6A==
# SIG # End signature block
