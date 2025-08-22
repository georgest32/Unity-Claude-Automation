# Test-ManifestStartup.ps1
# Quick test of manifest-based startup to diagnose issues

$ErrorActionPreference = "Continue"

# Set project root
$projectRoot = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"
Set-Location $projectRoot

Write-Host "Testing Manifest-Based Startup System" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Project Root: $projectRoot" -ForegroundColor Gray

# Import SystemStatus module
Write-Host "`n1. Loading SystemStatus module..." -ForegroundColor Yellow
try {
    $modulePath = Join-Path $projectRoot "Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psm1"
    Import-Module $modulePath -Force
    Write-Host "   Module loaded successfully" -ForegroundColor Green
} catch {
    Write-Host "   ERROR: Failed to load module - $_" -ForegroundColor Red
    exit 1
}

# Discover manifests
Write-Host "`n2. Discovering manifests..." -ForegroundColor Yellow
$manifestPath = Join-Path $projectRoot "Manifests"
$manifests = Get-SubsystemManifests -Path $manifestPath
Write-Host "   Found $($manifests.Count) manifests" -ForegroundColor Green

# Check start script paths
Write-Host "`n3. Checking start script paths..." -ForegroundColor Yellow
foreach ($manifest in $manifests) {
    Write-Host "   $($manifest.Name):" -ForegroundColor White
    # The actual manifest data is in the Data property
    if ($manifest.Data.StartScript) {
        # Check if script exists at project root
        $scriptPath = Join-Path $projectRoot $manifest.Data.StartScript
        
        if (Test-Path $scriptPath) {
            Write-Host "     [OK] Start script found: $($manifest.Data.StartScript)" -ForegroundColor Green
        } else {
            Write-Host "     [X] Start script NOT found: $scriptPath" -ForegroundColor Red
        }
    } else {
        Write-Host "     [--] No start script defined" -ForegroundColor Gray
    }
}

# Test validation with corrected paths
Write-Host "`n4. Testing manifest validation..." -ForegroundColor Yellow
$testPath = Join-Path $manifestPath "SystemMonitoring.manifest.psd1"
if (Test-Path $testPath) {
    try {
        $validation = Test-SubsystemManifest -Path $testPath
        Write-Host "   SystemMonitoring validation:" -ForegroundColor White
        Write-Host "     - IsValid: $($validation.IsValid)" -ForegroundColor $(if ($validation.IsValid) { "Green" } else { "Red" })
        
        if ($validation.Errors.Count -gt 0) {
            Write-Host "     - Errors:" -ForegroundColor Red
            foreach ($error in $validation.Errors) {
                Write-Host "       * $error" -ForegroundColor Red
            }
        }
        
        if ($validation.Warnings.Count -gt 0) {
            Write-Host "     - Warnings:" -ForegroundColor Yellow
            foreach ($warning in $validation.Warnings) {
                Write-Host "       * $warning" -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host "   ERROR: $_" -ForegroundColor Red
    }
} else {
    Write-Host "   Manifest file not found" -ForegroundColor Red
}

Write-Host "`n5. Ready to test manifest-based startup!" -ForegroundColor Cyan
Write-Host "   Run: .\Start-UnifiedSystem-WithCompatibility.ps1 -UseManifestMode" -ForegroundColor White
Write-Host "`nTest complete!" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUwUf4dtIs4OO9SOhsreSR26Y4
# Ed6gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUE8kD4TMpUqJGjikuQ64H6ni57cowDQYJKoZIhvcNAQEBBQAEggEAECCI
# NlQ50I4qpfqT3GV8oj/zQnXWEOrFryfveiompyRQiEd4USpzhEpu983pqdB38GvP
# fyJLMEqZkHujCa2v2NogCBg7y2XIAsMGcoPC36+IQrYXL0pT7OJ5NGmRNHcRtb8W
# 12ZCV8jio7b37QlgDZIVXDriAy9bEECDlmSNh2B0Ckf7fDIusdtm4EJIIw2Hgs//
# wvJ6uYi9Yr/LvfwMTe4Vytc5Z748hCGtor3m4GRAN4Bre3wXwhbNLfUkZQtH7r3g
# 45Rob6K4eNNQDwMAP3A1tY0AW0+ZtQU0Q8PWCkzmscX5JTig1EgFjYDLrRPr0u9t
# ZNQxPvtAsR19jkOZaw==
# SIG # End signature block
