# Install-RepoAnalystTools.ps1
# Installation script for Unity-Claude Repo Analyst dependencies

param(
    [switch]$SkipWSL,
    [switch]$SkipPython,
    [switch]$SkipTools
)

Write-Host "=== Unity-Claude Repo Analyst Tools Installation ===" -ForegroundColor Cyan
Write-Host ""

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Warning "Some installations may require administrator privileges. Consider running as administrator."
}

# 1. Check and install WSL2
if (-not $SkipWSL) {
    Write-Host "Checking WSL2 installation..." -ForegroundColor Yellow
    
    try {
        $wslStatus = wsl --status 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "WSL2 is already installed" -ForegroundColor Green
            
            # Check WSL version
            $wslVersion = wsl --list --verbose 2>&1
            Write-Host "Current WSL distributions:" -ForegroundColor Cyan
            Write-Host $wslVersion
        }
        else {
            throw "WSL not installed"
        }
    }
    catch {
        Write-Host "WSL2 not found. Installing..." -ForegroundColor Yellow
        
        if ($isAdmin) {
            # Enable WSL feature
            Write-Host "Enabling Windows Subsystem for Linux..." -ForegroundColor Yellow
            dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
            
            Write-Host "Enabling Virtual Machine Platform..." -ForegroundColor Yellow
            dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
            
            # Download and install WSL2 kernel update
            Write-Host "Please download and install the WSL2 kernel update from:" -ForegroundColor Yellow
            Write-Host "https://aka.ms/wsl2kernel" -ForegroundColor Cyan
            
            # Set WSL2 as default
            wsl --set-default-version 2
            
            Write-Host "WSL2 installation initiated. Please restart your computer and run this script again." -ForegroundColor Yellow
            return
        }
        else {
            Write-Error "Administrator privileges required to install WSL2"
            Write-Host "Please run this script as Administrator or install WSL2 manually" -ForegroundColor Red
            return
        }
    }
}

# 2. Install development tools
if (-not $SkipTools) {
    Write-Host ""
    Write-Host "Installing development tools..." -ForegroundColor Yellow
    
    # Check if Chocolatey is installed
    try {
        $chocoVersion = choco --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Chocolatey version $chocoVersion found" -ForegroundColor Green
        }
        else {
            throw "Chocolatey not found"
        }
    }
    catch {
        Write-Host "Installing Chocolatey..." -ForegroundColor Yellow
        
        if ($isAdmin) {
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        }
        else {
            Write-Error "Administrator privileges required to install Chocolatey"
            Write-Host "Please install Chocolatey manually from https://chocolatey.org/install" -ForegroundColor Yellow
        }
    }
    
    # Install ripgrep
    Write-Host "Checking ripgrep..." -ForegroundColor Yellow
    try {
        $rgVersion = rg --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "ripgrep is already installed: $($rgVersion[0])" -ForegroundColor Green
        }
        else {
            throw "ripgrep not found"
        }
    }
    catch {
        Write-Host "Installing ripgrep..." -ForegroundColor Yellow
        choco install ripgrep -y
    }
    
    # Install universal-ctags
    Write-Host "Checking universal-ctags..." -ForegroundColor Yellow
    try {
        $ctagsVersion = ctags --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "universal-ctags is already installed" -ForegroundColor Green
        }
        else {
            throw "ctags not found"
        }
    }
    catch {
        Write-Host "Installing universal-ctags..." -ForegroundColor Yellow
        choco install universal-ctags -y
    }
    
    # Check Git
    Write-Host "Checking Git installation..." -ForegroundColor Yellow
    try {
        $gitVersion = git --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Git is installed: $gitVersion" -ForegroundColor Green
        }
        else {
            throw "Git not found"
        }
    }
    catch {
        Write-Host "Installing Git..." -ForegroundColor Yellow
        choco install git -y
    }
}

# 3. Python setup in WSL
if (-not $SkipPython -and -not $SkipWSL) {
    Write-Host ""
    Write-Host "Setting up Python in WSL..." -ForegroundColor Yellow
    
    # Check if Ubuntu is installed in WSL by trying to run a command
    $ubuntuInstalled = $false
    try {
        $ubuntuTest = wsl -d Ubuntu -e echo "test" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Ubuntu is already installed in WSL" -ForegroundColor Green
            $ubuntuInstalled = $true
        }
    }
    catch {
        # Ubuntu not accessible
    }
    
    if (-not $ubuntuInstalled) {
        Write-Host "Installing Ubuntu in WSL..." -ForegroundColor Yellow
        wsl --install -d Ubuntu
        Write-Host "Ubuntu installation started. Please complete the setup and run this script again." -ForegroundColor Yellow
        return
    }
    
    # Check if Python 3 is already installed (Ubuntu Noble has 3.12 by default)
    Write-Host "Checking Python 3 in WSL Ubuntu..." -ForegroundColor Yellow
    try {
        $pythonCheck = wsl -d Ubuntu -e bash -c "python3 --version" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Python is already installed: $pythonCheck" -ForegroundColor Green
            
            # Also ensure venv and pip are installed
            Write-Host "Ensuring python3-venv and pip are installed..." -ForegroundColor Yellow
            Write-Host "You may be prompted for your Ubuntu password" -ForegroundColor Cyan
            wsl -d Ubuntu -- bash -c "sudo apt update && sudo apt install -y python3-venv python3-pip"
        }
        else {
            Write-Host "Installing Python 3 in WSL Ubuntu..." -ForegroundColor Yellow
            Write-Host "You may be prompted for your Ubuntu password" -ForegroundColor Cyan
            $pythonInstallCmd = "sudo apt update && sudo apt install -y python3 python3-pip python3-venv"
            wsl -d Ubuntu -- bash -c $pythonInstallCmd
        }
    }
    catch {
        Write-Host "Installing Python 3 in WSL Ubuntu..." -ForegroundColor Yellow
        Write-Host "You may be prompted for your Ubuntu password" -ForegroundColor Cyan
        $pythonInstallCmd = "sudo apt update && sudo apt install -y python3 python3-pip python3-venv"
        wsl -d Ubuntu -- bash -c $pythonInstallCmd
    }
    
    # Create virtual environment for the project
    Write-Host "Checking Python virtual environment..." -ForegroundColor Yellow
    $venvPath = "/mnt/c/UnityProjects/Sound-and-Shoal/Unity-Claude-Automation"
    
    # Check if venv already exists
    $venvCheck = wsl -d Ubuntu -e bash -c "test -d $venvPath/.venv && echo 'exists'" 2>&1
    if ($venvCheck -eq "exists") {
        Write-Host "Virtual environment already exists" -ForegroundColor Green
    }
    else {
        Write-Host "Creating Python virtual environment..." -ForegroundColor Yellow
        $venvCmd = "cd $venvPath && python3 -m venv .venv"
        wsl -d Ubuntu -e bash -c $venvCmd
    }
    
    # Install Python packages
    Write-Host "Installing Python packages (LangGraph, AutoGen)..." -ForegroundColor Yellow
    # Use single line command to avoid line ending issues
    $pipInstallCmd = "cd $venvPath && source .venv/bin/activate && pip install --upgrade pip && pip install langgraph langchain langchain-core pyautogen"
    wsl -d Ubuntu -e bash -c $pipInstallCmd
}

Write-Host ""
Write-Host "=== Installation Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Restart PowerShell to ensure PATH updates take effect"
Write-Host "2. Run 'Test-RepoAnalystEnvironment.ps1' to verify installation"
Write-Host "3. Import the module: Import-Module .\Modules\Unity-Claude-RepoAnalyst\Unity-Claude-RepoAnalyst.psd1"
Write-Host ""
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCwUddUikD/oN4B
# 5LifwnAV4JlA/8gCmgCebERnrGj4laCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJdlOtXfIffxbUQTmvk2W35M
# ePa+VhrV7Pg1xRAUo0t/MA0GCSqGSIb3DQEBAQUABIIBABSfEfDd+I+oDTPD17Rg
# YQLq8OLxNE8xJm8cjpozMismt+nqKpsMLGkjQGXtx89hGSZ5z0MtGS/5Z+sI2FhJ
# pz3QmSrpad3dn+8HcuxWBTuraT6cjyoMBButBCkKM9bgvoB9h7jpCiLEl+bYzYGk
# wGyJ/Hyb8/Dewu1P86n84E4DjsKUMgJDkllELiw7Yo2FfLdCQoRUxSDUY9y9BxDg
# fBpwR+bIqyK0pgJAKDOojruUtTq3DuhlFLglA/Ts0pPd2ZWWyBM0FogF9pBXJFwf
# k5A+1F4nNlQNobLQmyHZ3SH2TxFYp4s6W2gNS0G2cPmkXE1Wv3diPKNG1v/cVp8Y
# u5U=
# SIG # End signature block
