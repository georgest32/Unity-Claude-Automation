# Sign All PowerShell Scripts in Unity-Claude-Automation
# Bulk script signing for long-term use

$ErrorActionPreference = "Stop"

Write-Host "=== PowerShell Script Signing Analysis ===" -ForegroundColor Cyan

# Check current execution policy
$currentPolicy = Get-ExecutionPolicy
Write-Host "Current Execution Policy: $currentPolicy" -ForegroundColor Yellow

# Option 1: Self-Signed Certificate (Recommended for development)
Write-Host "`n=== Option 1: Create Self-Signed Certificate (RECOMMENDED) ===" -ForegroundColor Green

function New-SelfSignedCodeCert {
    param(
        [string]$CertName = "Unity-Claude-Automation-Development"
    )
    
    try {
        # Check if certificate already exists
        $existingCert = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.Subject -like "*$CertName*" }
        
        if ($existingCert) {
            Write-Host "[INFO] Self-signed certificate already exists: $($existingCert.Subject)" -ForegroundColor Green
            return $existingCert
        }
        
        # Create new self-signed certificate for code signing
        $cert = New-SelfSignedCertificate -Subject "CN=$CertName" -Type CodeSigning -KeyUsage DigitalSignature -FriendlyName $CertName -CertStoreLocation Cert:\CurrentUser\My
        
        # Move to Trusted Root (makes it trusted for this user)
        $store = New-Object System.Security.Cryptography.X509Certificates.X509Store([System.Security.Cryptography.X509Certificates.StoreName]::Root, [System.Security.Cryptography.X509Certificates.StoreLocation]::CurrentUser)
        $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
        $store.Add($cert)
        $store.Close()
        
        Write-Host "[SUCCESS] Created and installed self-signed certificate: $($cert.Subject)" -ForegroundColor Green
        Write-Host "Certificate Thumbprint: $($cert.Thumbprint)" -ForegroundColor Gray
        
        return $cert
    } catch {
        Write-Host "[ERROR] Failed to create certificate: $_" -ForegroundColor Red
        return $null
    }
}

function Sign-AllPowerShellFiles {
    param(
        [string]$RootPath = ".",
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate
    )
    
    if (-not $Certificate) {
        Write-Host "[ERROR] No certificate provided for signing" -ForegroundColor Red
        return
    }
    
    # Find all PowerShell files
    $psFiles = Get-ChildItem -Path $RootPath -Recurse -Include "*.ps1", "*.psm1", "*.psd1" | Where-Object { $_.FullName -notlike "*\.git\*" }
    
    Write-Host "[INFO] Found $($psFiles.Count) PowerShell files to sign" -ForegroundColor Yellow
    
    $signedCount = 0
    $failedCount = 0
    
    foreach ($file in $psFiles) {
        try {
            # Check if already signed
            $signature = Get-AuthenticodeSignature -FilePath $file.FullName
            if ($signature.Status -eq "Valid") {
                Write-Host "[SKIP] Already signed: $($file.Name)" -ForegroundColor Gray
                continue
            }
            
            # Sign the file
            $result = Set-AuthenticodeSignature -FilePath $file.FullName -Certificate $Certificate
            
            if ($result.Status -eq "Valid") {
                Write-Host "[PASS] Signed: $($file.Name)" -ForegroundColor Green
                $signedCount++
            } else {
                Write-Host "[FAIL] Failed to sign: $($file.Name) - $($result.Status)" -ForegroundColor Red
                $failedCount++
            }
        } catch {
            Write-Host "[ERROR] Exception signing $($file.Name): $_" -ForegroundColor Red
            $failedCount++
        }
    }
    
    Write-Host "`n=== Signing Summary ===" -ForegroundColor Cyan
    Write-Host "Total files: $($psFiles.Count)" -ForegroundColor White
    Write-Host "Signed: $signedCount" -ForegroundColor Green
    Write-Host "Failed: $failedCount" -ForegroundColor Red
    Write-Host "Success rate: $([math]::Round(($signedCount / $psFiles.Count) * 100, 1))%" -ForegroundColor Yellow
}

# Option 2: Simple execution policy change (Alternative)
Write-Host "`n=== Option 2: Change Execution Policy (SIMPLER) ===" -ForegroundColor Yellow

Write-Host @"
Alternative approach - just change execution policy to RemoteSigned:
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

This allows:
- Local scripts to run without signing
- Remote scripts require signing
- No certificates needed
- Simpler for development
"@ -ForegroundColor Gray

# Interactive choice
Write-Host "`n=== Choose Your Approach ===" -ForegroundColor Cyan
Write-Host "1. Create self-signed certificate and sign all scripts (more secure)" -ForegroundColor Green
Write-Host "2. Set execution policy to RemoteSigned (simpler)" -ForegroundColor Yellow
Write-Host "3. Do nothing - keep using bypass in scripts (status quo)" -ForegroundColor Gray

$choice = Read-Host "`nEnter choice (1, 2, or 3)"

switch ($choice) {
    "1" {
        Write-Host "`nCreating self-signed certificate and signing scripts..." -ForegroundColor Green
        
        $cert = New-SelfSignedCodeCert
        if ($cert) {
            Sign-AllPowerShellFiles -Certificate $cert
            
            Write-Host "`n=== Next Steps ===" -ForegroundColor Cyan
            Write-Host "1. All scripts are now signed with your self-signed certificate" -ForegroundColor Green
            Write-Host "2. You can run scripts normally without execution policy issues" -ForegroundColor Green
            Write-Host "3. Certificate is installed in your user store and trusted" -ForegroundColor Green
        }
    }
    
    "2" {
        Write-Host "`nSetting execution policy to RemoteSigned..." -ForegroundColor Yellow
        try {
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            Write-Host "[SUCCESS] Execution policy set to RemoteSigned for current user" -ForegroundColor Green
            Write-Host "Local scripts will now run without signing requirements" -ForegroundColor Green
        } catch {
            Write-Host "[ERROR] Failed to set execution policy: $_" -ForegroundColor Red
        }
    }
    
    "3" {
        Write-Host "`nKeeping current approach..." -ForegroundColor Gray
        Write-Host "You can continue using execution policy bypass in scripts" -ForegroundColor Gray
        Write-Host "Add this line to scripts that need it: Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force" -ForegroundColor Gray
    }
    
    default {
        Write-Host "Invalid choice. Exiting without changes." -ForegroundColor Red
    }
}

Write-Host "`n=== Recommendations ===" -ForegroundColor Cyan
Write-Host "For development: Option 2 (RemoteSigned) is simplest and most practical" -ForegroundColor Green
Write-Host "For production: Option 1 (signed scripts) provides better security" -ForegroundColor Yellow
Write-Host "For testing: Option 3 (bypass in scripts) works but requires code changes" -ForegroundColor Gray
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUL+n8oUb0eI+m3VfY96dpmDlg
# C46gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUwfwcLO2HZFL62DZoTYye6trNtg4wDQYJKoZIhvcNAQEBBQAEggEAGeRL
# 18lLqMRmdQDIexGui14rAiFmqIjLNGlws0N4sBNc13g2+z+YWkKZtsl2s+9K6dCZ
# 8TfHbS9FgEzTEnaLmLQ2VqKvwUi1+H+5vntlZSLhMaHv7t8ne/j3QRl7tUcdiP4s
# xI+mXDYE2vnJdhh57Erbea2QEj+by25sNtNBG+jlGztoDAEz0/qtDpdT/ZIh02Aw
# 6qIHU220iEZSL+imHBOl+vqhEBq7aHri3kuDz9YX1RAt6Rcl9wqXHmdB1IMaz2vg
# aRjzn6KmPCBlwgoqQbnIbaUdobaltNZIX0jGWkqKRZUfBBJD8DYFRXn4H2sgEsue
# 9fPF30oobEF4QFAYVA==
# SIG # End signature block
