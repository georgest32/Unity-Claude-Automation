#Requires -Version 5.1
<#
.SYNOPSIS
    Installs documentation quality tools (Vale and markdownlint) for the project.

.DESCRIPTION
    Installs Vale prose linter and markdownlint-cli2, configures them with
    appropriate style guides and rules for the Unity-Claude-Automation project.

.PARAMETER SkipVale
    Skip Vale installation

.PARAMETER SkipMarkdownlint
    Skip markdownlint installation

.PARAMETER ConfigureOnly
    Only create configuration files, skip tool installation

.EXAMPLE
    .\Install-QualityTools.ps1
#>

param(
    [switch]$SkipVale,
    [switch]$SkipMarkdownlint,
    [switch]$ConfigureOnly
)

$ErrorActionPreference = 'Stop'

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Documentation Quality Tools Installation" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Check prerequisites
$prerequisites = @{
    Chocolatey = $false
    Node = $false
    PowerShell7 = $false
}

# Check Chocolatey
try {
    $chocoVersion = choco --version 2>&1
    Write-Host "[OK] Chocolatey found: $chocoVersion" -ForegroundColor Green
    $prerequisites.Chocolatey = $true
}
catch {
    Write-Host "[!] Chocolatey not found" -ForegroundColor Yellow
    Write-Host "    Vale can be installed manually from GitHub releases" -ForegroundColor Gray
    Write-Host "    Or install Chocolatey from: https://chocolatey.org/install" -ForegroundColor Cyan
}

# Check Node.js/npm
try {
    $nodeVersion = node --version
    $npmVersion = npm --version
    Write-Host "[OK] Node.js found: $nodeVersion" -ForegroundColor Green
    Write-Host "[OK] npm found: $npmVersion" -ForegroundColor Green
    $prerequisites.Node = $true
}
catch {
    Write-Host "[X] Node.js/npm not found" -ForegroundColor Red
    Write-Host "    Required for markdownlint-cli2" -ForegroundColor Yellow
    Write-Host "    Install from: https://nodejs.org/" -ForegroundColor Cyan
}

# Check PowerShell 7
try {
    $pwshVersion = & "C:\Program Files\PowerShell\7\pwsh.exe" -Command '$PSVersionTable.PSVersion.ToString()' 2>&1
    Write-Host "[OK] PowerShell 7 found: $pwshVersion" -ForegroundColor Green
    $prerequisites.PowerShell7 = $true
}
catch {
    Write-Host "[!] PowerShell 7 not found" -ForegroundColor Yellow
    Write-Host "    Recommended for pre-commit hooks" -ForegroundColor Gray
}

Write-Host ""

if (-not $ConfigureOnly) {
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "Installing Quality Tools" -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Install Vale
    if (-not $SkipVale) {
        Write-Host "Installing Vale..." -ForegroundColor Yellow
        
        $valeInstalled = $false
        try {
            $valeVersion = vale --version 2>&1
            if ($valeVersion) {
                Write-Host "[OK] Vale already installed: $valeVersion" -ForegroundColor Green
                $valeInstalled = $true
            }
        }
        catch {
            # Not installed
        }
        
        if (-not $valeInstalled) {
            if ($prerequisites.Chocolatey) {
                try {
                    Write-Host "Installing Vale via Chocolatey..." -ForegroundColor Gray
                    choco install vale -y
                    
                    # Refresh PATH
                    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + 
                               [System.Environment]::GetEnvironmentVariable("Path","User")
                    
                    Write-Host "[OK] Vale installed successfully" -ForegroundColor Green
                }
                catch {
                    Write-Host "[X] Failed to install Vale: $_" -ForegroundColor Red
                    Write-Host "    Download manually from: https://github.com/errata-ai/vale/releases" -ForegroundColor Yellow
                }
            }
            else {
                Write-Host "[!] Cannot install Vale automatically without Chocolatey" -ForegroundColor Yellow
                Write-Host "    Download from: https://github.com/errata-ai/vale/releases" -ForegroundColor Cyan
                Write-Host "    Extract and add to PATH manually" -ForegroundColor Gray
            }
        }
    }
    
    Write-Host ""
    
    # Install markdownlint-cli2
    if (-not $SkipMarkdownlint -and $prerequisites.Node) {
        Write-Host "Installing markdownlint-cli2..." -ForegroundColor Yellow
        
        $mdlInstalled = $false
        try {
            $mdlVersion = npx markdownlint-cli2 --version 2>&1
            if ($mdlVersion) {
                Write-Host "[OK] markdownlint-cli2 already installed: v$mdlVersion" -ForegroundColor Green
                $mdlInstalled = $true
            }
        }
        catch {
            # Not installed
        }
        
        if (-not $mdlInstalled) {
            try {
                Write-Host "Installing markdownlint-cli2 globally via npm..." -ForegroundColor Gray
                npm install -g markdownlint-cli2
                
                Write-Host "[OK] markdownlint-cli2 installed successfully" -ForegroundColor Green
            }
            catch {
                Write-Host "[X] Failed to install markdownlint-cli2: $_" -ForegroundColor Red
                Write-Host "    Try manual installation: npm install -g markdownlint-cli2" -ForegroundColor Yellow
            }
        }
    }
    elseif ($SkipMarkdownlint) {
        Write-Host "[i] Skipping markdownlint installation" -ForegroundColor Gray
    }
    else {
        Write-Host "[X] Cannot install markdownlint-cli2 without Node.js" -ForegroundColor Red
    }
    
    Write-Host ""
}

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Creating Configuration Files" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Create Vale configuration
Write-Host "Creating Vale configuration..." -ForegroundColor Yellow

$valeConfig = @'
# Vale configuration for Unity-Claude-Automation
# Documentation: https://vale.sh/docs/topics/config/

StylesPath = .vale/styles
MinAlertLevel = suggestion

# Download Microsoft style with: vale sync
Packages = Microsoft

# Global settings
[*]
BasedOnStyles = Vale, Microsoft

# Markdown-specific settings
[*.{md,markdown}]
BasedOnStyles = Vale, Microsoft
vale.Spelling = YES

# PowerShell comments
[*.{ps1,psm1,psd1}]
BasedOnStyles = Vale, Microsoft
BlockIgnores = (?s) *(<#.*?#>)
TokenIgnores = \$\w+

# Python docstrings
[*.py]
BasedOnStyles = Vale, Microsoft
BlockIgnores = (?s) *(""".*?"""|'''.*?''')

# C# XML comments
[*.cs]
BasedOnStyles = Vale, Microsoft
BlockIgnores = (?s) *(///.*?$|/\*.*?\*/)

# Ignore certain directories
[{.git,node_modules,.venv,venv,build,dist,out}/**]
BasedOnStyles = 
'@

$valeConfig | Out-File -FilePath ".vale.ini" -Encoding UTF8
Write-Host "[OK] Created .vale.ini" -ForegroundColor Green

# Create .vale directory structure
if (-not (Test-Path ".vale")) {
    New-Item -Path ".vale" -ItemType Directory -Force | Out-Null
}
if (-not (Test-Path ".vale\styles")) {
    New-Item -Path ".vale\styles" -ItemType Directory -Force | Out-Null
}
Write-Host "[OK] Created .vale directory structure" -ForegroundColor Green

# Create custom Vale vocabulary
$acceptTerms = @'
# Accepted terms for Unity-Claude-Automation project
Unity
Claude
PowerShell
pwsh
cmdlet
cmdlets
runspace
runspaces
ScriptableObject
MonoBehaviour
GameObject
prefab
prefabs
async
webhook
webhooks
JSON
YAML
API
APIs
SDK
CI/CD
GitHub
GitLab
npm
Vale
markdownlint
TypeDoc
DocFX
Sphinx
AST
LangGraph
AutoGen
MCP
ripgrep
ctags
VSCode
IntelliSense
UTF-8
BOM
SARIF
'@

# Create vocabulary directory first
if (-not (Test-Path ".vale\styles\Vocab")) {
    New-Item -Path ".vale\styles\Vocab" -ItemType Directory -Force | Out-Null
}
$acceptTerms | Out-File -FilePath ".vale\styles\Vocab\accept.txt" -Encoding UTF8
Write-Host "[OK] Created Vale vocabulary" -ForegroundColor Green

Write-Host ""

# Create markdownlint configuration
Write-Host "Creating markdownlint configuration..." -ForegroundColor Yellow

$markdownlintConfig = @'
{
  "config": {
    "default": true,
    "MD003": { "style": "atx" },
    "MD004": { "style": "dash" },
    "MD007": { "indent": 2 },
    "MD013": { 
      "line_length": 120,
      "heading_line_length": 100,
      "code_block_line_length": 150,
      "code_blocks": false,
      "tables": false
    },
    "MD024": { "allow_different_nesting": true },
    "MD025": false,
    "MD026": { "punctuation": ".,;:!" },
    "MD029": { "style": "ordered" },
    "MD033": { 
      "allowed_elements": ["br", "hr", "a", "img", "details", "summary"]
    },
    "MD034": false,
    "MD036": false,
    "MD040": false,
    "MD041": false,
    "MD046": { "style": "fenced" },
    "MD048": { "style": "backtick" },
    "MD049": { "style": "underscore" },
    "MD050": { "style": "asterisk" },
    "no-hard-tabs": false
  },
  "globs": [
    "**/*.md",
    "!node_modules/**",
    "!.venv/**",
    "!venv/**",
    "!build/**",
    "!dist/**",
    "!out/**"
  ],
  "ignores": [
    "node_modules/**",
    ".venv/**",
    "venv/**",
    "build/**",
    "dist/**",
    "out/**"
  ],
  "customRules": [],
  "fix": false,
  "outputFormatters": [
    ["markdownlint-cli2-formatter-default"]
  ]
}
'@

$markdownlintConfig | Out-File -FilePath ".markdownlint-cli2.jsonc" -Encoding UTF8
Write-Host "[OK] Created .markdownlint-cli2.jsonc" -ForegroundColor Green

# Also create a basic .markdownlintrc for compatibility
$markdownlintBasic = @'
{
  "default": true,
  "MD013": { "line_length": 120 },
  "MD033": { "allowed_elements": ["br", "hr", "a", "img"] },
  "MD041": false,
  "no-hard-tabs": false
}
'@

$markdownlintBasic | Out-File -FilePath ".markdownlintrc" -Encoding UTF8
Write-Host "[OK] Created .markdownlintrc" -ForegroundColor Green

Write-Host ""

# Sync Vale packages if Vale is installed
try {
    $valeCheck = vale --version 2>&1
    if ($valeCheck) {
        Write-Host "Syncing Vale packages..." -ForegroundColor Yellow
        vale sync
        Write-Host "[OK] Vale packages synced" -ForegroundColor Green
    }
}
catch {
    Write-Host "[!] Vale not available - run 'vale sync' after installation" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Configuration Summary" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Check final status
$toolStatus = @{
    Vale = $false
    Markdownlint = $false
}

try {
    $null = vale --version 2>&1
    $toolStatus.Vale = $true
    Write-Host "[OK] Vale: Ready" -ForegroundColor Green
    Write-Host "     Run 'vale sync' to download Microsoft style guide" -ForegroundColor Gray
}
catch {
    Write-Host "[X] Vale: Not available" -ForegroundColor Red
}

try {
    $null = npx markdownlint-cli2 --version 2>&1
    $toolStatus.Markdownlint = $true
    Write-Host "[OK] markdownlint-cli2: Ready" -ForegroundColor Green
}
catch {
    Write-Host "[X] markdownlint-cli2: Not available" -ForegroundColor Red
}

Write-Host ""
Write-Host "Configuration files created:" -ForegroundColor Yellow
Write-Host "  - .vale.ini (Vale configuration)" -ForegroundColor White
Write-Host "  - .vale/styles/Vocab/accept.txt (Custom vocabulary)" -ForegroundColor White
Write-Host "  - .markdownlint-cli2.jsonc (markdownlint configuration)" -ForegroundColor White
Write-Host "  - .markdownlintrc (Basic markdownlint config)" -ForegroundColor White

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow

if ($toolStatus.Vale) {
    Write-Host "1. Run 'vale sync' to download style packages" -ForegroundColor White
    Write-Host "2. Test Vale: vale README.md" -ForegroundColor White
}
else {
    Write-Host "1. Install Vale manually from GitHub releases" -ForegroundColor White
}

if ($toolStatus.Markdownlint) {
    Write-Host "3. Test markdownlint: markdownlint-cli2 '**/*.md'" -ForegroundColor White
}
else {
    Write-Host "3. Install markdownlint-cli2: npm install -g markdownlint-cli2" -ForegroundColor White
}

Write-Host "4. Run Test-DocumentationQuality.ps1 to validate setup" -ForegroundColor White
Write-Host ""
Write-Host "Quality tools setup complete!" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBcE1Sjy/9ZH9W9
# 1QfrMYsby5kJ5Q/HGiuvohEYBNlqVKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIGt/0DCGyxM1scJoEGuf51rH
# gPS/rnHoV6bRxbF6sJb7MA0GCSqGSIb3DQEBAQUABIIBALGZPcedzsFtXLIl6xdk
# aIRv8aqyap6d8x8bnZ1osZOpkz1sgxmnUfAqoLIWoFoZmCqLLKMCgj+lFTukCJrC
# /rNqHkhTu4i3tFAYRZFePTz9RrgFEYWBYuhQjXcaBiTzj3P9a/XOD/m11cPm35ic
# T0Gp/bjCPwNoHlwkELinQUFStm3yOHVj1XppSNwc9UwG1nYGAumaJzMGdz+qYjh+
# 5gSKf6tsmOOrHyNzxYv7i/xdsyE5rAae+LjiWb1hkB5ExfNAgb3fiWq20byO89Y5
# fNkkKX2Wqaa0O68rrylHiXUSyCPgBCwFEhLJySf1mw5cSihnzkr9yNaAmmAD1KiV
# VTI=
# SIG # End signature block
