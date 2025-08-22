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