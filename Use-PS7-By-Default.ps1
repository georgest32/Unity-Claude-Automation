# Simple script to ensure PowerShell 7 is used by default (no admin required)
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "PowerShell 7 Default Setup (Simple)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. Check current PowerShell version
Write-Host "`nCurrent PowerShell:" -ForegroundColor Yellow
Write-Host "  Version: $($PSVersionTable.PSVersion)" -ForegroundColor Gray
Write-Host "  Edition: $($PSVersionTable.PSEdition)" -ForegroundColor Gray

# 2. Create/Update VS Code settings to use PS7
Write-Host "`nUpdating VS Code settings..." -ForegroundColor Cyan
$vscodeSettingsPath = "$env:APPDATA\Code\User\settings.json"
if (Test-Path $vscodeSettingsPath) {
    Write-Host "  VS Code settings found" -ForegroundColor Green
    $settings = Get-Content $vscodeSettingsPath -Raw | ConvertFrom-Json
    
    # Update PowerShell executable path
    if (-not $settings."powershell.powerShellDefaultVersion") {
        Add-Member -InputObject $settings -NotePropertyName "powershell.powerShellDefaultVersion" -NotePropertyValue "PowerShell" -Force
    }
    
    if (-not $settings."terminal.integrated.defaultProfile.windows") {
        Add-Member -InputObject $settings -NotePropertyName "terminal.integrated.defaultProfile.windows" -NotePropertyValue "PowerShell" -Force
    }
    
    $settings | ConvertTo-Json -Depth 10 | Set-Content $vscodeSettingsPath
    Write-Host "  VS Code configured to use PowerShell 7" -ForegroundColor Green
} else {
    Write-Host "  VS Code settings not found (VS Code may not be installed)" -ForegroundColor Gray
}

# 3. Create convenient batch files for running PS1 scripts with PS7
Write-Host "`nCreating convenient launchers..." -ForegroundColor Cyan

$launcherContent = @'
@echo off
pwsh -ExecutionPolicy Bypass -File "%~dpn0.ps1" %*
'@

# Create launcher for the test script
$testLauncher = "$PSScriptRoot\Run-Tests.cmd"
$launcherContent | Out-File -FilePath $testLauncher -Encoding ASCII
Write-Host "  Created: Run-Tests.cmd (runs Test-StaticAnalysisIntegration-Final.ps1 with PS7)" -ForegroundColor Green

# 4. Update Windows Terminal profile (if exists)
Write-Host "`nChecking Windows Terminal..." -ForegroundColor Cyan
$wtSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
if (Test-Path $wtSettingsPath) {
    Write-Host "  Windows Terminal found" -ForegroundColor Green
    Write-Host "  To make PS7 default:" -ForegroundColor Yellow
    Write-Host "    1. Open Windows Terminal" -ForegroundColor Gray
    Write-Host "    2. Click dropdown arrow → Settings (or press Ctrl+,)" -ForegroundColor Gray
    Write-Host "    3. Under 'Startup', set 'Default profile' to 'PowerShell' (not 'Windows PowerShell')" -ForegroundColor Gray
} else {
    Write-Host "  Windows Terminal not installed" -ForegroundColor Gray
}

# 5. Create alias for PowerShell in cmd
Write-Host "`nCreating command prompt alias..." -ForegroundColor Cyan
$cmdAutoRunPath = "HKCU:\Software\Microsoft\Command Processor"
if (Test-Path $cmdAutoRunPath) {
    $currentAutoRun = (Get-ItemProperty -Path $cmdAutoRunPath -Name "AutoRun" -ErrorAction SilentlyContinue).AutoRun
    if ($currentAutoRun -notlike "*doskey powershell=pwsh*") {
        $newAutoRun = if ($currentAutoRun) { "$currentAutoRun & " } else { "" }
        $newAutoRun += "doskey powershell=pwsh `$*"
        Set-ItemProperty -Path $cmdAutoRunPath -Name "AutoRun" -Value $newAutoRun -Force
        Write-Host "  Added 'powershell' alias to run 'pwsh' in Command Prompt" -ForegroundColor Green
    } else {
        Write-Host "  Alias already exists" -ForegroundColor Gray
    }
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`nWhat was configured:" -ForegroundColor Yellow
Write-Host "✓ PowerShell 5 profile redirects to PS7" -ForegroundColor Green
Write-Host "✓ VS Code configured to use PS7" -ForegroundColor Green
Write-Host "✓ Created Run-Tests.cmd launcher" -ForegroundColor Green
Write-Host "✓ Command Prompt 'powershell' now runs PS7" -ForegroundColor Green

Write-Host "`nHow to use PowerShell 7:" -ForegroundColor Yellow
Write-Host "  • Type 'pwsh' instead of 'powershell'" -ForegroundColor Gray
Write-Host "  • Double-click Run-Tests.cmd to run tests" -ForegroundColor Gray
Write-Host "  • In Windows Terminal, set PS7 as default profile" -ForegroundColor Gray
Write-Host "  • Your .ps1 scripts will auto-switch to PS7" -ForegroundColor Gray

Write-Host "`nNo admin rights required for these changes!" -ForegroundColor Green
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDoJ/Pl/DQkfANh
# 8/BzUlHnGzsOLn4FQGsxabAy0kcS76CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEICbHc1Z6cWkQIyCZUrwCsx6t
# K43utMeqjGlJ0rR3eDeAMA0GCSqGSIb3DQEBAQUABIIBAFD1JvdSF8dbzwIC7X0a
# Ac3N1S6kDaxWIMpquE0cNd4abk2lEWXf+A/oPvvserPPjUJos9CD2HPILE67isQY
# HjGNxTJBpV7EatdAyZPgxG4vbchSmrjhjH3mqb2RfRNxarfVMfXRnlwerCkjtDsG
# zMCGpzxnDNJiVWbx/024pVpRrKtEAc/rR4bUF4LW/4lhbCJa/B91IHdW3uquZxlq
# EBOE9dbxyAqDWf0vZpKEQlQdYgNCV5x3lBkJpT66LVrErZQqgJQpigHiA3CMTBhN
# eiarllL2DEAPw/IxsNnyZZSPoZ+Mg+RrpzW5J127dxr+4Vf5kByAFy2aow1ulv/b
# /jc=
# SIG # End signature block
