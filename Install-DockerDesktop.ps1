# Docker Desktop Installation Script for Unity-Claude-Automation
# Date: 2025-08-23
# Purpose: Automated Docker Desktop installation with WSL2 backend

param(
    [switch]$Silent = $false,
    [switch]$VerifyOnly = $false
)

$ErrorActionPreference = "Stop"

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Docker Desktop Installation Tool" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if ($VerifyOnly) {
    Write-Host "Checking Docker installation status..." -ForegroundColor Yellow
    
    # Check if Docker is installed
    $dockerPath = Get-Command docker -ErrorAction SilentlyContinue
    if ($dockerPath) {
        Write-Host "[SUCCESS] Docker is installed" -ForegroundColor Green
        docker --version
        
        # Check Docker service
        $dockerService = Get-Service -Name "Docker Desktop Service" -ErrorAction SilentlyContinue
        if ($dockerService) {
            Write-Host "[INFO] Docker Desktop Service Status: $($dockerService.Status)" -ForegroundColor Cyan
        }
        
        # Check WSL2 integration
        Write-Host "`nChecking WSL2 integration..." -ForegroundColor Yellow
        $wslVersion = wsl --version 2>$null
        if ($wslVersion) {
            Write-Host "[SUCCESS] WSL2 is available" -ForegroundColor Green
            wsl --version
        }
    }
    else {
        Write-Host "[WARNING] Docker is not installed or not in PATH" -ForegroundColor Yellow
        Write-Host "Run this script without -VerifyOnly to install Docker Desktop" -ForegroundColor Yellow
    }
    exit 0
}

# Installation process
$installerPath = "C:\Temp\DockerDesktopInstaller.exe"

# Check if installer exists
if (-not (Test-Path $installerPath)) {
    Write-Host "Docker Desktop installer not found. Downloading..." -ForegroundColor Yellow
    
    try {
        New-Item -ItemType Directory -Path "C:\Temp" -Force | Out-Null
        $downloadUrl = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
        
        Write-Host "Downloading from: $downloadUrl" -ForegroundColor Cyan
        Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath -UseBasicParsing
        
        if (Test-Path $installerPath) {
            $fileInfo = Get-Item $installerPath
            Write-Host "[SUCCESS] Downloaded Docker Desktop installer" -ForegroundColor Green
            Write-Host "Size: $([math]::Round($fileInfo.Length/1MB,2)) MB" -ForegroundColor Cyan
        }
    }
    catch {
        Write-Host "[ERROR] Failed to download Docker Desktop installer" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        exit 1
    }
}
else {
    Write-Host "[INFO] Docker Desktop installer found at: $installerPath" -ForegroundColor Cyan
}

# Installation options
if (-not $isAdmin) {
    Write-Host "`n[WARNING] This script needs to be run as Administrator for silent installation" -ForegroundColor Yellow
    Write-Host "Options:" -ForegroundColor Yellow
    Write-Host "1. Close this window and run PowerShell as Administrator" -ForegroundColor White
    Write-Host "2. Or manually run the installer by double-clicking:" -ForegroundColor White
    Write-Host "   $installerPath" -ForegroundColor Cyan
    
    $response = Read-Host "`nDo you want to launch the installer now? (Y/N)"
    if ($response -eq 'Y' -or $response -eq 'y') {
        Start-Process -FilePath $installerPath
        Write-Host "`n[INFO] Docker Desktop installer launched" -ForegroundColor Green
        Write-Host "Please follow the installation wizard" -ForegroundColor Cyan
    }
    exit 0
}

# Admin installation
Write-Host "`n[INFO] Running as Administrator - proceeding with installation" -ForegroundColor Green

if ($Silent) {
    Write-Host "Starting silent installation with WSL2 backend..." -ForegroundColor Yellow
    
    try {
        $arguments = @(
            "install",
            "--accept-license",
            "--backend=wsl-2",
            "--quiet"
        )
        
        $process = Start-Process -FilePath $installerPath -ArgumentList $arguments -Wait -PassThru -NoNewWindow
        
        if ($process.ExitCode -eq 0) {
            Write-Host "[SUCCESS] Docker Desktop installed successfully!" -ForegroundColor Green
            Write-Host "`n[IMPORTANT] Please restart your computer to complete the installation" -ForegroundColor Yellow
            Write-Host "After restart, Docker Desktop will start automatically" -ForegroundColor Cyan
        }
        else {
            Write-Host "[ERROR] Installation failed with exit code: $($process.ExitCode)" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "[ERROR] Installation failed" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}
else {
    Write-Host "Starting interactive installation..." -ForegroundColor Yellow
    Write-Host "Installation arguments: --accept-license --backend=wsl-2" -ForegroundColor Cyan
    
    try {
        Start-Process -FilePath $installerPath -ArgumentList "install", "--accept-license", "--backend=wsl-2" -Wait -Verb RunAs
        Write-Host "`n[INFO] Installation process completed" -ForegroundColor Green
        Write-Host "[IMPORTANT] Please restart your computer if prompted" -ForegroundColor Yellow
    }
    catch {
        Write-Host "[ERROR] Failed to start installation" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "Post-Installation Steps:" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host "1. Restart your computer (required)" -ForegroundColor White
Write-Host "2. Start Docker Desktop from Start Menu" -ForegroundColor White
Write-Host "3. Sign in to Docker Hub (optional)" -ForegroundColor White
Write-Host "4. Verify installation: docker --version" -ForegroundColor White
Write-Host "5. Test WSL2 integration: docker run hello-world" -ForegroundColor White
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBh9JcjqlJn1KFz
# KkU1f7g1G50U7laO1dbuknCXHsKOj6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIMgZ6go/Buwzx5T0yuDn8Ng+
# wrMpV7WNZolwIUL7HQ6BMA0GCSqGSIb3DQEBAQUABIIBAFtAUv/O1jV2Iu3aiQ/a
# vjdN28kdzMNqaDvxHLJBOlnP4c3WsKfAd352AEKpcB5e44EKDYczP94g0qD860cd
# B4ms6wMCkLAKg9oWo5cF6aX2JDA8ahyJz63xAcmPj3IBXEI/64i6mD59VHU/Cvwy
# m5B3S18ODMjTIeJJYglselfvMZpVX4ma0jo51b4WuvmT+YzQqGLYXOjsu0ogmAbx
# on3ALEQEHUr0KeOS2tSTy4uYP7oISu6kJiUeGqZsUDpVHmdiZHAMrJaltToXtcyd
# csqEEuocKgWUY9DcyJK9RhaSmhCZ3PR6v++gKo9bsTLbV1ZKQaEUJZiR4V3Y2Vzm
# qbs=
# SIG # End signature block
