# Sign-PowerShellScripts.ps1
# Digitally signs all PowerShell scripts in Unity-Claude-Automation
# Date: 2025-08-21

param(
    [switch]$CreateCertificate,
    [switch]$UseTrustedCert,
    [string]$CertThumbprint
)

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "POWERSHELL SCRIPT SIGNING UTILITY" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Function to create self-signed certificate
function New-CodeSigningCertificate {
    Write-Host "Creating self-signed code signing certificate..." -ForegroundColor Yellow
    
    $certParams = @{
        Subject = "Unity-Claude-Automation Code Signing ($env:COMPUTERNAME)"
        Type = "CodeSigningCert"
        KeySpec = "Signature"
        KeyUsage = "DigitalSignature"
        FriendlyName = "Unity-Claude Code Signing Certificate"
        CertStoreLocation = "Cert:\CurrentUser\My"
        NotAfter = (Get-Date).AddYears(5)
    }
    
    $cert = New-SelfSignedCertificate @certParams
    
    Write-Host "  Certificate created!" -ForegroundColor Green
    Write-Host "  Thumbprint: $($cert.Thumbprint)" -ForegroundColor Yellow
    
    # Export to Trusted Root and Trusted Publishers
    Write-Host ""
    Write-Host "Installing certificate to trusted stores..." -ForegroundColor Yellow
    
    # Export certificate
    $certPath = ".\Unity-Claude-CodeSigning.cer"
    Export-Certificate -Cert $cert -FilePath $certPath | Out-Null
    
    # Import to Trusted Root
    Import-Certificate -FilePath $certPath -CertStoreLocation "Cert:\CurrentUser\Root" | Out-Null
    Write-Host "  Added to Trusted Root Certification Authorities" -ForegroundColor Green
    
    # Import to Trusted Publishers
    Import-Certificate -FilePath $certPath -CertStoreLocation "Cert:\CurrentUser\TrustedPublisher" | Out-Null
    Write-Host "  Added to Trusted Publishers" -ForegroundColor Green
    
    # Clean up export file
    Remove-Item $certPath -Force
    
    return $cert
}

# Get or create certificate
$cert = $null

if ($CreateCertificate) {
    $cert = New-CodeSigningCertificate
}
elseif ($CertThumbprint) {
    Write-Host "Using certificate with thumbprint: $CertThumbprint" -ForegroundColor Yellow
    $cert = Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert | 
            Where-Object { $_.Thumbprint -eq $CertThumbprint }
    
    if (-not $cert) {
        Write-Host "  Certificate not found!" -ForegroundColor Red
        exit 1
    }
}
else {
    Write-Host "Looking for existing code signing certificates..." -ForegroundColor Yellow
    $certs = Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert
    
    if ($certs.Count -eq 0) {
        Write-Host "  No code signing certificates found" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Creating new self-signed certificate..." -ForegroundColor Cyan
        $cert = New-CodeSigningCertificate
    }
    elseif ($certs.Count -eq 1) {
        $cert = $certs[0]
        Write-Host "  Found certificate: $($cert.Subject)" -ForegroundColor Green
        Write-Host "  Thumbprint: $($cert.Thumbprint)" -ForegroundColor Gray
    }
    else {
        Write-Host "  Found multiple certificates:" -ForegroundColor Yellow
        for ($i = 0; $i -lt $certs.Count; $i++) {
            Write-Host "    [$i] $($certs[$i].Subject)" -ForegroundColor Gray
            Write-Host "        Thumbprint: $($certs[$i].Thumbprint)" -ForegroundColor DarkGray
        }
        
        $selection = Read-Host "Select certificate [0-$($certs.Count-1)]"
        $cert = $certs[$selection]
    }
}

Write-Host ""
Write-Host "Using certificate:" -ForegroundColor Cyan
Write-Host "  Subject: $($cert.Subject)" -ForegroundColor Gray
Write-Host "  Thumbprint: $($cert.Thumbprint)" -ForegroundColor Gray
Write-Host "  Expires: $($cert.NotAfter)" -ForegroundColor Gray

# Find all PowerShell files
Write-Host ""
Write-Host "Finding PowerShell files to sign..." -ForegroundColor Yellow

$scriptFiles = @()
$scriptFiles += Get-ChildItem -Path "." -Filter "*.ps1" -File
$scriptFiles += Get-ChildItem -Path ".\Modules" -Filter "*.ps1" -Recurse -File
$scriptFiles += Get-ChildItem -Path ".\Modules" -Filter "*.psm1" -Recurse -File
$scriptFiles += Get-ChildItem -Path ".\Modules" -Filter "*.psd1" -Recurse -File

Write-Host "  Found $($scriptFiles.Count) files to sign" -ForegroundColor Green

# Sign files
Write-Host ""
Write-Host "Signing files..." -ForegroundColor Cyan

$signedCount = 0
$alreadySigned = 0
$errors = 0

foreach ($file in $scriptFiles) {
    $relativePath = $file.FullName.Replace("$PWD\", ".\")
    
    # Check current signature
    $currentSig = Get-AuthenticodeSignature -FilePath $file.FullName
    
    if ($currentSig.Status -eq "Valid" -and $currentSig.SignerCertificate.Thumbprint -eq $cert.Thumbprint) {
        $alreadySigned++
        Write-Host "  [SKIP] $relativePath (already signed)" -ForegroundColor Gray
        continue
    }
    
    try {
        # Sign the file
        $result = Set-AuthenticodeSignature -FilePath $file.FullName -Certificate $cert
        
        if ($result.Status -eq "Valid") {
            $signedCount++
            Write-Host "  [OK] $relativePath" -ForegroundColor Green
        }
        else {
            $errors++
            Write-Host "  [ERROR] $relativePath - $($result.Status)" -ForegroundColor Red
        }
    }
    catch {
        $errors++
        Write-Host "  [ERROR] $relativePath - $_" -ForegroundColor Red
    }
}

# Summary
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "SIGNING COMPLETE" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Results:" -ForegroundColor Yellow
Write-Host "  Newly signed: $signedCount" -ForegroundColor Green
Write-Host "  Already signed: $alreadySigned" -ForegroundColor Gray
Write-Host "  Errors: $errors" -ForegroundColor $(if($errors -gt 0){'Red'}else{'Gray'})
Write-Host ""

# Save certificate info for future use
$certInfo = @{
    Thumbprint = $cert.Thumbprint
    Subject = $cert.Subject
    NotAfter = $cert.NotAfter.ToString()
    LastSigningDate = (Get-Date).ToString()
    FilesSignedCount = $signedCount
}

$certInfo | ConvertTo-Json | Set-Content -Path ".\code_signing_cert_info.json"
Write-Host "Certificate info saved to: .\code_signing_cert_info.json" -ForegroundColor Gray

Write-Host ""
Write-Host "To verify signatures, run:" -ForegroundColor Cyan
Write-Host "  Get-AuthenticodeSignature .\*.ps1" -ForegroundColor White
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU3eZEXjfRTyWOgmwczmnyCv6H
# e9WgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUkL0h1n3cNPCuXnfmA80c/j5xkJ0wDQYJKoZIhvcNAQEBBQAEggEAFrwk
# nH4WVFYQv5E1cRfdoVkYERDUtOsqwutvTtz2HGDV9T8IfCsMVo76F+tw+V04mmIP
# 4oO20s6P+qzAhibbropddUdQZY/6f5cZHsrWWqYmU61skutbzdU3+Zx44gZRTtlp
# tM99T3F2V3zx6UP0Kvu/dsC3eVlaDZ7jUkDLzbkuPpHiQ2MtaowCf5ezyl//fSJ2
# F3YXAq571u53V8tOEVGPj9wB+LJ8a6e7sgPbLGkBBV6lPEg+9GAsze+g4au8EMHM
# lF+KswDXSR+Uy1Q8J6gAgndfBRCkxstUFakz52T/8WeUOaRkEVttXJdVUwXszzQD
# xBTOz9ayUZDjhRu8Tw==
# SIG # End signature block
