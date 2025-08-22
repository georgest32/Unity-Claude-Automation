# Fix-SQLiteErrors.ps1
# Helps resolve SQLite4Unity3d reference issues
# Date: 2025-08-17

[CmdletBinding()]
param()

Write-Host "=== SQLite4Unity3d Error Fix Tool ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Verify SQLite installation
Write-Host "Step 1: Verifying SQLite4Unity3d installation..." -ForegroundColor Yellow

$sqlitePath = "C:\UnityProjects\Sound-and-Shoal\Dithering\Assets\Plugins\SQLite4Unity3d"
if (Test-Path $sqlitePath) {
    Write-Host "  [OK] SQLite4Unity3d folder found" -ForegroundColor Green
    
    # Check key files
    $requiredFiles = @(
        "SQLite.cs",
        "SQLite4Unity3d.asmdef",
        "Plugins\x64\sqlite3.dll",
        "Plugins\x86\sqlite3.dll"
    )
    
    foreach ($file in $requiredFiles) {
        $filePath = Join-Path $sqlitePath $file
        if (Test-Path $filePath) {
            Write-Host "  [OK] $file exists" -ForegroundColor Green
        }
        else {
            Write-Host "  [X] $file missing!" -ForegroundColor Red
        }
    }
}
else {
    Write-Host "  [X] SQLite4Unity3d not found at expected location!" -ForegroundColor Red
    Write-Host "      Expected: $sqlitePath" -ForegroundColor DarkGray
    exit 1
}

# Step 2: Check assembly definitions
Write-Host ""
Write-Host "Step 2: Checking assembly definitions..." -ForegroundColor Yellow

$asmdefFiles = @(
    "C:\UnityProjects\Sound-and-Shoal\Dithering\Assets\Plugins\SQLite4Unity3d\SQLite4Unity3d.asmdef",
    "C:\UnityProjects\Sound-and-Shoal\Dithering\Assets\Scripts\SymbolicMemory\SoundAndShoal.SymbolicMemory.asmdef",
    "C:\UnityProjects\Sound-and-Shoal\Dithering\Assets\Scripts\SymbolicMemory\Editor\SoundAndShoal.SymbolicMemory.Editor.asmdef"
)

foreach ($asmdef in $asmdefFiles) {
    if (Test-Path $asmdef) {
        $content = Get-Content $asmdef -Raw | ConvertFrom-Json
        $fileName = Split-Path $asmdef -Leaf
        Write-Host "  [OK] $fileName" -ForegroundColor Green
        
        # Check if it references SQLite4Unity3d
        if ($content.references -contains "SQLite4Unity3d") {
            Write-Host "      - References SQLite4Unity3d" -ForegroundColor DarkGreen
        }
        elseif ($fileName -eq "SQLite4Unity3d.asmdef") {
            Write-Host "      - Is the SQLite4Unity3d assembly" -ForegroundColor DarkGreen
        }
        else {
            Write-Host "      - Does NOT reference SQLite4Unity3d" -ForegroundColor DarkYellow
        }
    }
    else {
        Write-Host "  [X] Missing: $(Split-Path $asmdef -Leaf)" -ForegroundColor Red
    }
}

# Step 3: Instructions for Unity
Write-Host ""
Write-Host "Step 3: Unity Actions Required" -ForegroundColor Yellow
Write-Host ""
Write-Host "Please perform these actions in Unity Editor:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1. In Unity, go to menu: Tools > Fix SQLite References" -ForegroundColor White
Write-Host "  2. Then go to: Tools > Force Recompilation" -ForegroundColor White
Write-Host "  3. Wait for compilation to complete" -ForegroundColor White
Write-Host "  4. Check Console for errors" -ForegroundColor White
Write-Host ""
Write-Host "If errors persist:" -ForegroundColor Yellow
Write-Host "  1. Right-click on Assets/Plugins/SQLite4Unity3d in Project view" -ForegroundColor White
Write-Host "  2. Select 'Reimport'" -ForegroundColor White
Write-Host "  3. Wait for import to complete" -ForegroundColor White
Write-Host ""

# Step 4: Check current errors
Write-Host "Step 4: Checking current compilation errors..." -ForegroundColor Yellow

$exportScript = Join-Path $PSScriptRoot "Export-UnityCompilationErrors.ps1"
if (Test-Path $exportScript) {
    Write-Host "  Running error detection..." -ForegroundColor Gray
    
    # Run the export script and capture SQLite-related errors
    $errorOutput = & $exportScript 2>$null
    $sqliteErrors = $errorOutput | Where-Object { $_ -match "SQLite|CS0246.*SQLite" }
    
    if ($sqliteErrors) {
        Write-Host "  [!] Found SQLite-related errors:" -ForegroundColor Yellow
        $sqliteErrors | Select-Object -First 5 | ForEach-Object {
            Write-Host "      $_" -ForegroundColor DarkYellow
        }
    }
    else {
        Write-Host "  [OK] No SQLite-related errors detected" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "=== Fix Process Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Follow the Unity Editor instructions above" -ForegroundColor White
Write-Host "2. After Unity recompiles, run:" -ForegroundColor White
Write-Host "   .\Export-UnityCompilationErrors.ps1" -ForegroundColor Yellow
Write-Host "3. Check if SQLite errors are resolved" -ForegroundColor White
Write-Host ""
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUthrbF3r46n+C63UvFNOOXeG2
# KFagggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU/zZPQ0+RQWzYSTuK9x5axcmIv4UwDQYJKoZIhvcNAQEBBQAEggEAH/pB
# SKSD9PB32nQVwIXXOYhUZyfHmOhNrnGGRdSUSjPbeqkL5dgbvC8k376c9BzD5y/2
# PXMwjR4gZ+JYKr7VUzlqgisACjsvjjG9OGq6VuHHv9I2d94LzYs0um70v2RWBY+s
# O5YQC3LWK5pWU1jLFZRKIEZmluYflUrv3eVF6pX8DFm0WuoMcqL9nsrii2wiDDWs
# +/LRE8XwOlL+/Q/k1/ynSycplnDwXwtEEbaEwXpSdbWcszDtqh0oW0VfMQjp8cNw
# 295k/yrzh4yonlBg04pMpugzjbBFmsLVU/R7dmzYW2bioymFpvSMXy3dJGkvWaXi
# qFnQ94R7vTnCroH7Bw==
# SIG # End signature block
