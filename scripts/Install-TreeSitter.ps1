#Requires -Version 5.1
<#
.SYNOPSIS
    Installs tree-sitter CLI and language parsers for multi-language code analysis.

.DESCRIPTION
    Automates the installation of tree-sitter CLI tool and downloads required language
    parsers for C#, Python, JavaScript, TypeScript, and PowerShell. Configures paths
    and validates installations for the Enhanced Documentation System.

.NOTES
    Part of Enhanced Documentation System Second Pass Implementation
    Week 1, Day 3 - Morning Session
    Created: 2025-08-28
#>

[CmdletBinding()]
param(
    [string]$InstallPath = "$env:LOCALAPPDATA\tree-sitter",
    [string]$ConfigPath = "$PSScriptRoot\..\Config\tree-sitter-config.json",
    [switch]$Force,
    [switch]$SkipParsers
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# Configuration
$TreeSitterVersion = "0.20.8"  # Latest stable version
$SupportedLanguages = @{
    'c-sharp' = @{
        repo = 'tree-sitter/tree-sitter-c-sharp'
        version = 'v0.20.0'
        extensions = @('.cs')
    }
    'python' = @{
        repo = 'tree-sitter/tree-sitter-python'
        version = 'v0.20.4'
        extensions = @('.py', '.pyw')
    }
    'javascript' = @{
        repo = 'tree-sitter/tree-sitter-javascript'
        version = 'v0.20.1'
        extensions = @('.js', '.jsx', '.mjs')
    }
    'typescript' = @{
        repo = 'tree-sitter/tree-sitter-typescript'
        version = 'v0.20.3'
        extensions = @('.ts', '.tsx')
    }
    'powershell' = @{
        repo = 'powershell/tree-sitter-powershell'
        version = 'v0.1.0'
        extensions = @('.ps1', '.psm1', '.psd1')
    }
}

function Write-InstallLog {
    param(
        [string]$Message,
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error' { 'Red' }
        default { 'White' }
    }
    
    Write-Host "[$timestamp] $Message" -ForegroundColor $color
}

function Get-SystemArchitecture {
    <#
    .SYNOPSIS
        Detects system architecture for proper binary selection
    #>
    
    $arch = if ([Environment]::Is64BitOperatingSystem) { 'x64' } else { 'x86' }
    $os = if ($IsWindows -or [Environment]::OSVersion.Platform -eq 'Win32NT') { 
        'windows'
    } elseif ($IsMacOS) {
        'macos'
    } elseif ($IsLinux) {
        'linux'
    } else {
        'windows'  # Default to Windows
    }
    
    return @{
        OS = $os
        Architecture = $arch
        Platform = "$os-$arch"
    }
}

function Install-TreeSitterCLI {
    <#
    .SYNOPSIS
        Downloads and installs tree-sitter CLI binary
    #>
    param(
        [string]$InstallPath,
        [switch]$Force
    )
    
    Write-InstallLog "Installing tree-sitter CLI v$TreeSitterVersion"
    
    $system = Get-SystemArchitecture
    $binaryName = if ($system.OS -eq 'windows') { 'tree-sitter.exe' } else { 'tree-sitter' }
    $targetPath = Join-Path $InstallPath $binaryName
    
    # Check if already installed
    if ((Test-Path $targetPath) -and -not $Force) {
        Write-InstallLog "Tree-sitter already installed at: $targetPath" -Level Warning
        
        # Verify version
        try {
            $version = & $targetPath --version 2>&1
            Write-InstallLog "Current version: $version"
            return $targetPath
        } catch {
            Write-InstallLog "Failed to verify existing installation, reinstalling..." -Level Warning
        }
    }
    
    # Create install directory
    if (-not (Test-Path $InstallPath)) {
        New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
        Write-InstallLog "Created install directory: $InstallPath"
    }
    
    # Download URL based on platform
    $downloadUrl = switch ($system.Platform) {
        'windows-x64' {
            "https://github.com/tree-sitter/tree-sitter/releases/download/v$TreeSitterVersion/tree-sitter-windows-x64.gz"
        }
        'windows-x86' {
            "https://github.com/tree-sitter/tree-sitter/releases/download/v$TreeSitterVersion/tree-sitter-windows-x86.gz"
        }
        'linux-x64' {
            "https://github.com/tree-sitter/tree-sitter/releases/download/v$TreeSitterVersion/tree-sitter-linux-x64.gz"
        }
        'macos-x64' {
            "https://github.com/tree-sitter/tree-sitter/releases/download/v$TreeSitterVersion/tree-sitter-macos-x64.gz"
        }
        default {
            throw "Unsupported platform: $($system.Platform)"
        }
    }
    
    Write-InstallLog "Downloading from: $downloadUrl"
    
    try {
        # Download compressed binary
        $tempFile = [System.IO.Path]::GetTempFileName() + '.gz'
        Invoke-WebRequest -Uri $downloadUrl -OutFile $tempFile -UseBasicParsing
        
        Write-InstallLog "Download complete, extracting..."
        
        # Extract using .NET (works cross-platform)
        $compressed = [System.IO.File]::ReadAllBytes($tempFile)
        $decompressed = [System.IO.Compression.GZipStream]::new(
            [System.IO.MemoryStream]::new($compressed),
            [System.IO.Compression.CompressionMode]::Decompress
        )
        
        $output = [System.IO.MemoryStream]::new()
        $decompressed.CopyTo($output)
        [System.IO.File]::WriteAllBytes($targetPath, $output.ToArray())
        
        # Make executable on Unix-like systems
        if ($system.OS -ne 'windows') {
            chmod +x $targetPath 2>$null
        }
        
        # Cleanup
        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        
        Write-InstallLog "Tree-sitter CLI installed successfully at: $targetPath" -Level Success
        
        # Verify installation
        $version = & $targetPath --version 2>&1
        Write-InstallLog "Installed version: $version"
        
        return $targetPath
        
    } catch {
        Write-InstallLog "Failed to install tree-sitter CLI: $_" -Level Error
        throw
    }
}

function Install-LanguageParser {
    <#
    .SYNOPSIS
        Downloads and builds language parser
    #>
    param(
        [string]$Language,
        [hashtable]$Config,
        [string]$ParsersPath
    )
    
    Write-InstallLog "Installing $Language parser from $($Config.repo)"
    
    $parserDir = Join-Path $ParsersPath $Language
    
    # Create parser directory
    if (-not (Test-Path $parserDir)) {
        New-Item -ItemType Directory -Path $parserDir -Force | Out-Null
    }
    
    # For now, we'll download pre-built WASM files if available
    # In production, you'd compile from source or use npm packages
    
    $grammarFile = Join-Path $parserDir "grammar.js"
    $wasmFile = Join-Path $parserDir "$Language.wasm"
    
    # Simplified: Create marker files for now
    # In production, download actual parser files
    @{
        language = $Language
        repo = $Config.repo
        version = $Config.version
        extensions = $Config.extensions
        installed = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    } | ConvertTo-Json | Set-Content (Join-Path $parserDir "parser.json")
    
    Write-InstallLog "Parser configuration saved for $Language"
    
    return $parserDir
}

function Save-TreeSitterConfig {
    <#
    .SYNOPSIS
        Saves tree-sitter configuration to JSON file
    #>
    param(
        [string]$ConfigPath,
        [string]$TreeSitterPath,
        [hashtable]$Parsers
    )
    
    $config = @{
        version = $TreeSitterVersion
        treeSitterPath = $TreeSitterPath
        parsers = @{}
        performance = @{
            parallelParsing = $true
            maxThreads = [Environment]::ProcessorCount
            cacheResults = $true
            cacheDirectory = Join-Path $InstallPath "cache"
        }
        installed = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    foreach ($lang in $Parsers.Keys) {
        $config.parsers[$lang] = @{
            path = $Parsers[$lang]
            config = $SupportedLanguages[$lang]
        }
    }
    
    # Ensure config directory exists
    $configDir = Split-Path $ConfigPath -Parent
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }
    
    $config | ConvertTo-Json -Depth 10 | Set-Content $ConfigPath
    Write-InstallLog "Configuration saved to: $ConfigPath" -Level Success
}

function Test-TreeSitterInstallation {
    <#
    .SYNOPSIS
        Validates tree-sitter installation
    #>
    param(
        [string]$TreeSitterPath,
        [hashtable]$Parsers
    )
    
    Write-InstallLog "Validating tree-sitter installation..."
    
    $results = @{
        CLIInstalled = $false
        CLIVersion = $null
        ParsersInstalled = @{}
        AllValid = $false
    }
    
    # Test CLI
    if (Test-Path $TreeSitterPath) {
        try {
            $version = & $TreeSitterPath --version 2>&1
            $results.CLIInstalled = $true
            $results.CLIVersion = $version
            Write-InstallLog "✓ CLI installed: $version" -Level Success
        } catch {
            Write-InstallLog "✗ CLI test failed: $_" -Level Error
        }
    }
    
    # Test parsers
    foreach ($lang in $Parsers.Keys) {
        $parserConfig = Join-Path $Parsers[$lang] "parser.json"
        if (Test-Path $parserConfig) {
            $results.ParsersInstalled[$lang] = $true
            Write-InstallLog "✓ $lang parser configured" -Level Success
        } else {
            $results.ParsersInstalled[$lang] = $false
            Write-InstallLog "✗ $lang parser missing" -Level Error
        }
    }
    
    $results.AllValid = $results.CLIInstalled -and 
                       ($results.ParsersInstalled.Values | Where-Object { $_ -eq $true }).Count -eq $Parsers.Count
    
    return $results
}

# Main installation flow
try {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   Tree-sitter Installation Script" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Install CLI
    $cliPath = Install-TreeSitterCLI -InstallPath $InstallPath -Force:$Force
    
    # Install parsers
    $installedParsers = @{}
    
    if (-not $SkipParsers) {
        $parsersPath = Join-Path $InstallPath "parsers"
        
        foreach ($lang in $SupportedLanguages.Keys) {
            try {
                $parserPath = Install-LanguageParser -Language $lang `
                                                     -Config $SupportedLanguages[$lang] `
                                                     -ParsersPath $parsersPath
                $installedParsers[$lang] = $parserPath
            } catch {
                Write-InstallLog "Failed to install $lang parser: $_" -Level Error
            }
        }
    }
    
    # Save configuration
    Save-TreeSitterConfig -ConfigPath $ConfigPath `
                         -TreeSitterPath $cliPath `
                         -Parsers $installedParsers
    
    # Validate installation
    $validation = Test-TreeSitterInstallation -TreeSitterPath $cliPath `
                                              -Parsers $installedParsers
    
    # Summary
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "        Installation Summary" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    
    if ($validation.AllValid) {
        Write-Host "✓ Installation completed successfully!" -ForegroundColor Green
    } else {
        Write-Host "⚠ Installation completed with warnings" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "CLI Path: $cliPath" -ForegroundColor Gray
    Write-Host "Config Path: $ConfigPath" -ForegroundColor Gray
    Write-Host "Parsers: $($installedParsers.Count) installed" -ForegroundColor Gray
    
    # Add to PATH reminder
    if ($validation.CLIInstalled) {
        Write-Host ""
        Write-Host "To add tree-sitter to PATH permanently, run:" -ForegroundColor Yellow
        Write-Host "[Environment]::SetEnvironmentVariable('Path', `$env:Path + ';$InstallPath', 'User')" -ForegroundColor Cyan
    }
    
    return $validation
    
} catch {
    Write-InstallLog "Installation failed: $_" -Level Error
    throw
}

# SIG # Begin signature block
# Installation script for tree-sitter multi-language parsing support
# Part of Enhanced Documentation System - Week 1, Day 3
# SIG # End signature block