# Set-PS7-Terminal-Default.ps1
# Configures PowerShell 7 as default in Windows Terminal

Write-Host "Configuring PowerShell 7 as Default" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

# Windows Terminal settings path
$wtSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

if (Test-Path $wtSettingsPath) {
    Write-Host "`nWindows Terminal detected" -ForegroundColor Green
    
    # Read current settings
    $settings = Get-Content $wtSettingsPath -Raw | ConvertFrom-Json
    
    # Find PowerShell 7 profile GUID
    $ps7Profile = $settings.profiles.list | Where-Object { $_.name -eq "PowerShell" -or $_.source -eq "Windows.Terminal.PowershellCore" }
    
    if ($ps7Profile) {
        $settings.defaultProfile = $ps7Profile.guid
        $settings | ConvertTo-Json -Depth 100 | Set-Content $wtSettingsPath
        Write-Host "✓ Windows Terminal now defaults to PowerShell 7" -ForegroundColor Green
        Write-Host "  Restart Windows Terminal for changes to take effect" -ForegroundColor Yellow
    } else {
        Write-Warning "PowerShell 7 profile not found in Windows Terminal"
    }
} else {
    Write-Host "Windows Terminal not found" -ForegroundColor Yellow
}

# Create desktop shortcuts
Write-Host "`nCreating Desktop Shortcuts..." -ForegroundColor Cyan

$WshShell = New-Object -ComObject WScript.Shell

# PowerShell 7 shortcut
$Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\PowerShell 7.lnk")
$Shortcut.TargetPath = "C:\Program Files\PowerShell\7\pwsh.exe"
$Shortcut.WorkingDirectory = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"
$Shortcut.IconLocation = "C:\Program Files\PowerShell\7\pwsh.exe,0"
$Shortcut.Description = "PowerShell 7"
$Shortcut.Save()
Write-Host "✓ Created PowerShell 7 desktop shortcut" -ForegroundColor Green

# Unity-Claude with PS7 shortcut
$Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\Unity-Claude (PS7).lnk")
$Shortcut.TargetPath = "C:\Program Files\PowerShell\7\pwsh.exe"
$Shortcut.Arguments = "-NoExit -ExecutionPolicy Bypass -File `"C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Start-UnifiedSystem-Complete.ps1`""
$Shortcut.WorkingDirectory = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"
$Shortcut.IconLocation = "C:\Program Files\PowerShell\7\pwsh.exe,0"
$Shortcut.Description = "Unity-Claude Automation with PowerShell 7"
$Shortcut.Save()
Write-Host "✓ Created Unity-Claude PS7 desktop shortcut" -ForegroundColor Green

# Check if pwsh is in PATH
Write-Host "`nChecking PATH configuration..." -ForegroundColor Cyan
$pwshInPath = $env:Path -split ';' | Where-Object { $_ -like "*PowerShell\7*" }

if ($pwshInPath) {
    Write-Host "✓ PowerShell 7 is in PATH" -ForegroundColor Green
    Write-Host "  You can use 'pwsh' command from anywhere" -ForegroundColor Gray
} else {
    Write-Host "✗ PowerShell 7 not in PATH" -ForegroundColor Yellow
    Write-Host "  Restart your terminal or run:" -ForegroundColor Yellow
    Write-Host "  `$env:Path += ';C:\Program Files\PowerShell\7'" -ForegroundColor White
}

Write-Host "`n====================================" -ForegroundColor Cyan
Write-Host "Configuration Complete!" -ForegroundColor Green
Write-Host "`nHow to use PowerShell 7:" -ForegroundColor Cyan
Write-Host "1. In Terminal: Type 'pwsh' instead of 'powershell'" -ForegroundColor White
Write-Host "2. From Desktop: Use the new shortcuts" -ForegroundColor White
Write-Host "3. Windows Terminal: Will now open PS7 by default (after restart)" -ForegroundColor White
Write-Host "4. Scripts: Will auto-upgrade when run from anywhere" -ForegroundColor White
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCTu/Ss1OO0S6S2
# fnC5ybohfnDiq5KHaubOoOqtZtK9BqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIHMht39qzjtdDXwY72DheKpS
# 3zjQt98dWKnf865RNxWYMA0GCSqGSIb3DQEBAQUABIIBAD840iYdVZMmWYubEMTI
# cBNgC18Ou2Vm1kcbBU5YGRYd1bD/rS2Z3lJH+PQvzcB/g7LF2RTbDCx0kACDqHq4
# p6H2wD0db1np9fKRzJigdJxbZpn70H+9daE1cuy6QZOheJ8cN6ShMX+tEqtt3a7T
# wF51HQ6IjApXqECIUGRcDnFlKwADmqAT12B0kgquJ+sgYTqwCnho40ieOlJHzy5P
# dn20g9QCEPq7zXhY2e10cPpx31pHq7ZQ/PECjiltyxEM5kx9b+ada6LqRoWizie4
# NHJQMDGdtA+6Pl74duyGQpyvdtE83vEP173crct5KWD//Nkn6waHGJh9OOhPAF1+
# Fk4=
# SIG # End signature block
