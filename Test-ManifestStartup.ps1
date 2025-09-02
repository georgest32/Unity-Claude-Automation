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
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAazezAGrpbLZRS
# Ylewq5YZxHva7sh/nx88nwuboj3ataCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIF9xx1uihm6xnH4s/93KyPEm
# x/HJCcUNvI5quolOzXRmMA0GCSqGSIb3DQEBAQUABIIBACmcBJ4XRAzU/WMtxYdF
# 8LwnBtjbkRpC3Df787oxW4e9Ok85ep+Xa8HSm9ZVeyM9hAlSoa6eJKeLNPjYKq53
# d4rNsOk9ajR60MmT5h/jvVZdMR4whHPICd7pLGG2H+QyGlKIhbjdanNXifeY/2LO
# N2Z3yVEQTB0F2YzaY3n/rq6nTnchC3lawNi45GUQQ1R6UOwjwMSVSreJiCTXR6bZ
# oOK0z2zTK5zPLZVjZCxc40VWhOCZZi5vEznudfCYeocBRdo4mvkFlBNxHBHsmTZ+
# 42YKg+wBkGdKvKKX1co/4TVvDbQ/QatTiUZvgdTUMhDs1IKYz9y560Sk2T++cj1O
# FRA=
# SIG # End signature block
