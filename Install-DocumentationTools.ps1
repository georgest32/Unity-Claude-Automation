#Requires -Version 5.1
<#
.SYNOPSIS
    Installs documentation generation tools for the Unity-Claude-Automation project.

.DESCRIPTION
    Installs DocFX, TypeDoc, Sphinx, and other required documentation tools.
    Checks for prerequisites and provides installation instructions.

.PARAMETER SkipDocFX
    Skip DocFX installation

.PARAMETER SkipTypeDoc  
    Skip TypeDoc installation

.PARAMETER SkipSphinx
    Skip Sphinx installation

.EXAMPLE
    .\Install-DocumentationTools.ps1
#>

param(
    [switch]$SkipDocFX,
    [switch]$SkipTypeDoc,
    [switch]$SkipSphinx
)

$ErrorActionPreference = 'Stop'

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Documentation Tools Installation" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Check for prerequisites
$results = @{
    DotNet = $false
    Node = $false
    Python = $false
    Chocolatey = $false
}

# Check .NET SDK
Write-Host "Checking prerequisites..." -ForegroundColor Yellow
Write-Host ""

try {
    $dotnetVersion = dotnet --version
    Write-Host "[✓] .NET SDK found: $dotnetVersion" -ForegroundColor Green
    $results.DotNet = $true
}
catch {
    Write-Host "[✗] .NET SDK not found" -ForegroundColor Red
    Write-Host "    Please install .NET SDK 6.0 or later from:" -ForegroundColor Yellow
    Write-Host "    https://dotnet.microsoft.com/download" -ForegroundColor Cyan
}

# Check Node.js/npm
try {
    $nodeVersion = node --version
    $npmVersion = npm --version
    Write-Host "[✓] Node.js found: $nodeVersion" -ForegroundColor Green
    Write-Host "[✓] npm found: $npmVersion" -ForegroundColor Green
    $results.Node = $true
}
catch {
    Write-Host "[✗] Node.js/npm not found" -ForegroundColor Red
    Write-Host "    Please install Node.js from:" -ForegroundColor Yellow
    Write-Host "    https://nodejs.org/" -ForegroundColor Cyan
}

# Check Python
try {
    $pythonVersion = python --version 2>&1
    Write-Host "[✓] Python found: $pythonVersion" -ForegroundColor Green
    $results.Python = $true
}
catch {
    Write-Host "[✗] Python not found" -ForegroundColor Red
    Write-Host "    Please install Python 3.8+ from:" -ForegroundColor Yellow
    Write-Host "    https://www.python.org/downloads/" -ForegroundColor Cyan
}

# Check Chocolatey (optional)
try {
    $chocoVersion = choco --version 2>&1
    Write-Host "[✓] Chocolatey found: $chocoVersion" -ForegroundColor Green
    $results.Chocolatey = $true
}
catch {
    Write-Host "[i] Chocolatey not found (optional)" -ForegroundColor Yellow
    Write-Host "    Chocolatey can simplify tool installation:" -ForegroundColor Gray
    Write-Host "    https://chocolatey.org/install" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Installing Documentation Tools" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Install DocFX
if (-not $SkipDocFX -and $results.DotNet) {
    Write-Host "Installing DocFX..." -ForegroundColor Yellow
    
    try {
        # Check if already installed
        $docfxInstalled = $false
        try {
            $docfxVersion = docfx --version 2>&1
            if ($docfxVersion) {
                Write-Host "[✓] DocFX already installed: $docfxVersion" -ForegroundColor Green
                $docfxInstalled = $true
            }
        }
        catch {
            # Not installed
        }
        
        if (-not $docfxInstalled) {
            Write-Host "Installing DocFX globally via dotnet tool..." -ForegroundColor Gray
            dotnet tool install -g docfx
            
            # Refresh PATH
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + 
                       [System.Environment]::GetEnvironmentVariable("Path","User")
            
            Write-Host "[✓] DocFX installed successfully" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "[✗] Failed to install DocFX: $_" -ForegroundColor Red
        Write-Host "    Try manual installation:" -ForegroundColor Yellow
        Write-Host "    dotnet tool install -g docfx" -ForegroundColor Cyan
    }
}
elseif ($SkipDocFX) {
    Write-Host "[i] Skipping DocFX installation" -ForegroundColor Gray
}
else {
    Write-Host "[✗] Cannot install DocFX without .NET SDK" -ForegroundColor Red
}

Write-Host ""

# Install TypeDoc
if (-not $SkipTypeDoc -and $results.Node) {
    Write-Host "Installing TypeDoc..." -ForegroundColor Yellow
    
    try {
        # Check if already installed
        $typedocInstalled = $false
        try {
            $typedocVersion = npx typedoc --version 2>&1
            if ($typedocVersion) {
                Write-Host "[✓] TypeDoc already installed: v$typedocVersion" -ForegroundColor Green
                $typedocInstalled = $true
            }
        }
        catch {
            # Not installed
        }
        
        if (-not $typedocInstalled) {
            Write-Host "Installing TypeDoc locally via npm..." -ForegroundColor Gray
            npm install --save-dev typedoc
            
            # Install useful plugins
            Write-Host "Installing TypeDoc plugins..." -ForegroundColor Gray
            npm install --save-dev typedoc-plugin-markdown typedoc-plugin-missing-exports
            
            Write-Host "[✓] TypeDoc installed successfully" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "[✗] Failed to install TypeDoc: $_" -ForegroundColor Red
        Write-Host "    Try manual installation:" -ForegroundColor Yellow
        Write-Host "    npm install --save-dev typedoc" -ForegroundColor Cyan
    }
}
elseif ($SkipTypeDoc) {
    Write-Host "[i] Skipping TypeDoc installation" -ForegroundColor Gray
}
else {
    Write-Host "[✗] Cannot install TypeDoc without Node.js" -ForegroundColor Red
}

Write-Host ""

# Install Sphinx
if (-not $SkipSphinx -and $results.Python) {
    Write-Host "Installing Sphinx..." -ForegroundColor Yellow
    
    try {
        # Check if already installed
        $sphinxInstalled = $false
        try {
            $sphinxVersion = python -m sphinx --version 2>&1
            if ($sphinxVersion) {
                Write-Host "[✓] Sphinx already installed: $sphinxVersion" -ForegroundColor Green
                $sphinxInstalled = $true
            }
        }
        catch {
            # Not installed
        }
        
        if (-not $sphinxInstalled) {
            Write-Host "Installing Sphinx and extensions via pip..." -ForegroundColor Gray
            python -m pip install --upgrade pip
            python -m pip install sphinx sphinx-rtd-theme sphinx-autobuild
            
            Write-Host "[✓] Sphinx installed successfully" -ForegroundColor Green
        }
        
        # Install additional extensions
        Write-Host "Checking Sphinx extensions..." -ForegroundColor Gray
        python -m pip install sphinx-autodoc-typehints sphinxcontrib-napoleon
    }
    catch {
        Write-Host "[✗] Failed to install Sphinx: $_" -ForegroundColor Red
        Write-Host "    Try manual installation:" -ForegroundColor Yellow
        Write-Host "    pip install sphinx sphinx-rtd-theme sphinx-autobuild" -ForegroundColor Cyan
    }
}
elseif ($SkipSphinx) {
    Write-Host "[i] Skipping Sphinx installation" -ForegroundColor Gray
}
else {
    Write-Host "[✗] Cannot install Sphinx without Python" -ForegroundColor Red
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Installation Summary" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Check final status
$toolStatus = @{
    DocFX = $false
    TypeDoc = $false
    Sphinx = $false
}

try {
    $null = docfx --version 2>&1
    $toolStatus.DocFX = $true
    Write-Host "[✓] DocFX: Ready" -ForegroundColor Green
}
catch {
    Write-Host "[✗] DocFX: Not available" -ForegroundColor Red
}

try {
    $null = npx typedoc --version 2>&1
    $toolStatus.TypeDoc = $true
    Write-Host "[✓] TypeDoc: Ready" -ForegroundColor Green
}
catch {
    Write-Host "[✗] TypeDoc: Not available" -ForegroundColor Red
}

try {
    $null = python -m sphinx --version 2>&1
    $toolStatus.Sphinx = $true
    Write-Host "[✓] Sphinx: Ready" -ForegroundColor Green
}
catch {
    Write-Host "[✗] Sphinx: Not available" -ForegroundColor Red
}

Write-Host ""

# Provide next steps
if ($toolStatus.DocFX -and $toolStatus.TypeDoc -and $toolStatus.Sphinx) {
    Write-Host "✅ All documentation tools are installed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Run Test-DocumentationPipeline.ps1 to verify installation" -ForegroundColor White
    Write-Host "2. Use New-UnifiedDocumentation.ps1 to generate docs" -ForegroundColor White
    Write-Host ""
    Write-Host "Example usage:" -ForegroundColor Gray
    Write-Host '  .\scripts\docs\New-UnifiedDocumentation.ps1 -ProjectPath . -GenerateIndex -GenerateHTML' -ForegroundColor Cyan
}
else {
    Write-Host "⚠️  Some tools are not installed" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please install missing prerequisites and run this script again." -ForegroundColor White
    Write-Host "You can also install tools manually using the commands shown above." -ForegroundColor Gray
}

Write-Host ""
Write-Host "Documentation tool installation complete!" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCHTGg9s7vu2Gow
# qEyZqJtK/bqsil73qsUjAr363i8FNqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIC+xL5RB7/TVZe2xGSbrusXJ
# QFeQTDj+tg4eCGdo+yJrMA0GCSqGSIb3DQEBAQUABIIBAIYbG/HpqUhFVGVaueyL
# 2WZnnuovEdEm2fCmkLX7Bwev6QnBWAXqOLXggyj+dLxZsIOniDVPg7483YIptp5R
# P8Sm1DpmJ6o+YrX7lKVto21lhuULvL+DeJTX6meIakOeRbwtlPFzjHPxFm3//PDR
# IfJOTuIxvScNVP2c4uwJraEV6pKG9eSY1Hx4Ud4B06oYmew995zZDjI+uREaKaMS
# iSFvqnuLpv98V8rN8o+ElVFRSfHM3jtQGKKBMec6nawYrsR5wNp33ZvlwGvNLfPj
# le0CSA0A03wxSGQekc2aG88MorhtfGHcQ6Zk8Ni5YmxTxBQPrw7dBE8BtJbV/ZER
# R9o=
# SIG # End signature block
