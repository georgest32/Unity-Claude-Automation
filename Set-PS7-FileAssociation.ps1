# Script to set PowerShell 7 as default for .ps1 files (requires admin)
param(
    [switch]$Force
)

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host "This script requires Administrator privileges to modify file associations." -ForegroundColor Yellow
    Write-Host "Restarting with elevation..." -ForegroundColor Cyan
    
    # Restart script with elevation
    $arguments = "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
    if ($Force) { $arguments += " -Force" }
    
    Start-Process pwsh -Verb RunAs -ArgumentList $arguments
    exit
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "PowerShell 7 File Association Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Running as Administrator" -ForegroundColor Green

# Check current file association
Write-Host "`nChecking current .ps1 file association..." -ForegroundColor Yellow

# Multiple possible registry paths for PS1 files
$regPaths = @(
    "HKLM:\SOFTWARE\Classes\Microsoft.PowerShellScript.1\Shell\Open\Command",
    "HKLM:\SOFTWARE\Classes\SystemFileAssociations\.ps1\Shell\Open\Command",
    "HKCR:\Microsoft.PowerShellScript.1\Shell\Open\Command"
)

$foundPath = $null
foreach ($path in $regPaths) {
    # Convert HKCR to HKLM if needed
    $testPath = $path -replace "^HKCR:", "HKLM:\SOFTWARE\Classes"
    
    if (Test-Path $testPath) {
        $foundPath = $testPath
        Write-Host "  Found registry key at: $testPath" -ForegroundColor Green
        
        try {
            $currentValue = (Get-ItemProperty -Path $testPath -ErrorAction Stop)."(Default)"
            Write-Host "  Current association: $currentValue" -ForegroundColor Gray
        } catch {
            Write-Host "  Could not read current value" -ForegroundColor Yellow
        }
        break
    }
}

if (-not $foundPath) {
    Write-Host "  No existing PowerShell file association found" -ForegroundColor Yellow
    Write-Host "  Creating new association..." -ForegroundColor Cyan
    
    # Create the registry structure
    $basePath = "HKLM:\SOFTWARE\Classes\Microsoft.PowerShellScript.1"
    
    # Create base key
    if (-not (Test-Path $basePath)) {
        New-Item -Path $basePath -Force | Out-Null
        New-ItemProperty -Path $basePath -Name "(Default)" -Value "PowerShell Script" -Force | Out-Null
    }
    
    # Create Shell\Open\Command structure
    $shellPath = "$basePath\Shell"
    if (-not (Test-Path $shellPath)) {
        New-Item -Path $shellPath -Force | Out-Null
    }
    
    $openPath = "$shellPath\Open"
    if (-not (Test-Path $openPath)) {
        New-Item -Path $openPath -Force | Out-Null
    }
    
    $commandPath = "$openPath\Command"
    if (-not (Test-Path $commandPath)) {
        New-Item -Path $commandPath -Force | Out-Null
    }
    
    $foundPath = $commandPath
}

# Set new value
$newValue = "`"C:\Program Files\PowerShell\7\pwsh.exe`" -NoExit -File `"%1`""
Write-Host "`nSetting new file association..." -ForegroundColor Cyan
Write-Host "  New value: $newValue" -ForegroundColor Gray

if (-not $Force) {
    $response = Read-Host "Do you want to update the file association? (y/n)"
    if ($response -ne 'y') {
        Write-Host "Operation cancelled" -ForegroundColor Yellow
        exit
    }
}

try {
    Set-ItemProperty -Path $foundPath -Name "(Default)" -Value $newValue -Force
    Write-Host "  File association updated successfully!" -ForegroundColor Green
} catch {
    Write-Host "  Failed to update registry: $_" -ForegroundColor Red
    exit 1
}

# Also update the .ps1 extension association
Write-Host "`nUpdating .ps1 extension handler..." -ForegroundColor Cyan
$extPath = "HKLM:\SOFTWARE\Classes\.ps1"

if (Test-Path $extPath) {
    try {
        Set-ItemProperty -Path $extPath -Name "(Default)" -Value "Microsoft.PowerShellScript.1" -Force
        Write-Host "  Extension handler updated" -ForegroundColor Green
    } catch {
        Write-Host "  Could not update extension handler: $_" -ForegroundColor Yellow
    }
} else {
    New-Item -Path $extPath -Force | Out-Null
    New-ItemProperty -Path $extPath -Name "(Default)" -Value "Microsoft.PowerShellScript.1" -Force | Out-Null
    Write-Host "  Extension handler created" -ForegroundColor Green
}

# Refresh explorer to apply changes
Write-Host "`nRefreshing Windows Explorer..." -ForegroundColor Cyan
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Process explorer

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✓ .ps1 files will now open with PowerShell 7" -ForegroundColor Green
Write-Host "✓ Double-clicking .ps1 files will use pwsh.exe" -ForegroundColor Green
Write-Host "`nNote: You may need to log out and back in for all changes to take effect" -ForegroundColor Yellow
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDByj/TeUgH9fQx
# GbtFerBfc8iWFzkntSoNIB8k44iYLaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEICUTgiawL6bkUVWzxMeyyxKq
# 0QpkVyoAS3wdgKSe86SJMA0GCSqGSIb3DQEBAQUABIIBAA3JFQ9omxUWw8FWDTWG
# yjh0b8RGuxAecWFNEzUOjO3ovto38nbjUqCokYer/f4ByJ8OM4f4UXR0Nnej81eg
# Mo3gSz5U9Fgx9T5u8AJPJWupfzQXl3Xbr7Rx/1UXrSAn2geHVgvRhsk0tqEW4/aZ
# 35SO3fmiY51awTkGnRGwgOv/CzJT5DojpaLJvPDMmzfnRd8b6Uc6jr8E5H0p9CFY
# L2qUZW4C6U2AMwlUX0qVPw/3iz22SMSbxZZAZj67n8CBOKX0p6KAMhomz4/btjbo
# syhlg/ti0KhHLBx2wA/4t3QwYUSIs2ax4hHncYIGWddybsUhdkkLpXFQIz4wI8JT
# tfg=
# SIG # End signature block
