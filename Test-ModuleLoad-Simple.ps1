# Test simple module loading without dependencies
Write-Host "Testing DocumentationDrift module loading..." -ForegroundColor Cyan

# First test: Just load the manifest without dependencies
try {
    Write-Host "1. Testing manifest load..." -ForegroundColor Yellow
    $manifest = Test-ModuleManifest -Path "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-DocumentationDrift\Unity-Claude-DocumentationDrift.psd1" -ErrorAction Stop
    Write-Host "✅ Manifest loaded successfully" -ForegroundColor Green
    Write-Host "   Version: $($manifest.Version)" -ForegroundColor Gray
    Write-Host "   Functions: $($manifest.ExportedFunctions.Count)" -ForegroundColor Gray
} catch {
    Write-Host "❌ Manifest failed: $_" -ForegroundColor Red
    exit 1
}

# Second test: Check if required modules exist and are loadable
try {
    Write-Host "`n2. Testing required module availability..." -ForegroundColor Yellow
    
    $modules = @('Unity-Claude-RepoAnalyst', 'Unity-Claude-FileMonitor', 'Unity-Claude-GitHub')
    foreach ($module in $modules) {
        $path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\$module"
        if (Test-Path $path) {
            Write-Host "   ✅ $module - Path exists" -ForegroundColor Green
        } else {
            Write-Host "   ❌ $module - Path missing" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "❌ Module check failed: $_" -ForegroundColor Red
}

Write-Host "`n3. Testing individual dependency load..." -ForegroundColor Yellow
try {
    Import-Module Unity-Claude-RepoAnalyst -Force -ErrorAction Stop
    Write-Host "   ✅ Unity-Claude-RepoAnalyst loaded" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Unity-Claude-RepoAnalyst failed: $_" -ForegroundColor Red
}

Write-Host "`nTest completed." -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCTPEdR+EqIfngb
# OhuIQ8E1+LVpzVrqGQJQuQUZYoBPGKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIKcyN9trL2orQcLo7Ud/fe7A
# hfWrUwNdxpJZ8+TAov1oMA0GCSqGSIb3DQEBAQUABIIBAJ47bOL8F7oeooYSnMg9
# 0GiaOUh5Cq9/ogS/V9bXQkmzFk5rCifaVRViFiY4/9GBJAOT/bg4vr7AnovzDn9R
# euiSyJgyL/UU9hpf3g3Eq3SRmPlEIeELW6SO78ELF8c1TeqPZu4OURgFqYXe2lyA
# cEUOAWhMIj1C4P5WL36FPIuvcIFrBQovO4Op5lZdDpaj5apdkMawMnXanOQ4fKUV
# VlZrpMcMLEl/D4lASta6JbfvMII1CVXqzE40C1Rei6Tfil6oauoIDPKM/LTzGJS9
# 9RTrgY3/mLkEXAwk535fg3ke0miUwcEA7ZuW74gtLRiW28uBJXVpqPWijPateQYK
# gnM=
# SIG # End signature block
