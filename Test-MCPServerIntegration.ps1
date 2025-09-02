#Requires -Version 5.1
<#
.SYNOPSIS
Tests MCP Server integration with Cursor IDE

.DESCRIPTION
This script tests the MCP (Model Context Protocol) server setup for:
- Ripgrep search functionality
- Filesystem operations
- Git operations
- Integration with Cursor IDE
#>

param(
    [Parameter()]
    [switch]$InstallDependencies,
    
    [Parameter()]
    [switch]$SkipCursorCheck
)

# Set verbose preference based on common parameter
if ($PSBoundParameters['Verbose']) {
    $VerbosePreference = 'Continue'
}

$timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
$resultFile = ".\Test-MCPServer-Results_$timestamp.txt"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  MCP Server Integration Test Suite" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Initialize results
$testResults = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Tests = @()
    Summary = @{
        Total = 0
        Passed = 0
        Failed = 0
        Skipped = 0
    }
}

function Test-Requirement {
    param(
        [string]$Name,
        [scriptblock]$Test,
        [string]$InstallCommand = $null
    )
    
    Write-Host "Checking $Name..." -NoNewline
    try {
        $result = & $Test
        if ($result) {
            Write-Host " [PASS]" -ForegroundColor Green
            return $true
        }
        else {
            throw "Check failed"
        }
    }
    catch {
        Write-Host " [FAIL]" -ForegroundColor Red
        if ($InstallDependencies -and $InstallCommand) {
            Write-Host "  Installing $Name..." -ForegroundColor Yellow
            Invoke-Expression $InstallCommand
            # Re-test
            try {
                $result = & $Test
                if ($result) {
                    Write-Host "  Installation successful!" -ForegroundColor Green
                    return $true
                }
            }
            catch {
                Write-Host "  Installation failed!" -ForegroundColor Red
            }
        }
        else {
            Write-Host "  To install: $InstallCommand" -ForegroundColor Yellow
        }
        return $false
    }
}

Write-Host "Phase 1: Checking Prerequisites" -ForegroundColor Yellow
Write-Host "--------------------------------" -ForegroundColor DarkGray

# Check Node.js/npm
$nodeInstalled = Test-Requirement -Name "Node.js" -Test {
    $null = Get-Command node -ErrorAction Stop
    $version = node --version
    Write-Verbose "Node.js version: $version"
    $true
} -InstallCommand "choco install nodejs -y"

$testResults.Tests += @{
    Name = "Node.js Installation"
    Result = if ($nodeInstalled) { "Passed" } else { "Failed" }
}

# Check npm
$npmInstalled = Test-Requirement -Name "npm" -Test {
    $null = Get-Command npm -ErrorAction Stop
    $version = npm --version
    Write-Verbose "npm version: $version"
    $true
} -InstallCommand "npm install -g npm@latest"

$testResults.Tests += @{
    Name = "npm Installation"
    Result = if ($npmInstalled) { "Passed" } else { "Failed" }
}

# Check ripgrep
$rgInstalled = Test-Requirement -Name "ripgrep" -Test {
    $null = Get-Command rg -ErrorAction Stop
    $version = rg --version
    Write-Verbose "ripgrep version: $version"
    $true
} -InstallCommand "choco install ripgrep -y"

$testResults.Tests += @{
    Name = "ripgrep Installation"
    Result = if ($rgInstalled) { "Passed" } else { "Failed" }
}

# Check ctags
$ctagsInstalled = Test-Requirement -Name "universal-ctags" -Test {
    $null = Get-Command ctags -ErrorAction Stop
    $version = ctags --version
    Write-Verbose "ctags version: $version"
    $true
} -InstallCommand "choco install universal-ctags -y"

$testResults.Tests += @{
    Name = "universal-ctags Installation"
    Result = if ($ctagsInstalled) { "Passed" } else { "Failed" }
}

# Check Git
$gitInstalled = Test-Requirement -Name "Git" -Test {
    $null = Get-Command git -ErrorAction Stop
    $version = git --version
    Write-Verbose "Git version: $version"
    $true
}

$testResults.Tests += @{
    Name = "Git Installation"
    Result = if ($gitInstalled) { "Passed" } else { "Failed" }
}

Write-Host "`nPhase 2: Checking MCP Configuration" -ForegroundColor Yellow
Write-Host "------------------------------------" -ForegroundColor DarkGray

# Check .cursor/mcp.json exists
Write-Host "Checking Cursor MCP configuration..." -NoNewline
$cursorConfigPath = ".\.cursor\mcp.json"
if (Test-Path $cursorConfigPath) {
    Write-Host " [PASS]" -ForegroundColor Green
    $cursorConfig = Get-Content $cursorConfigPath -Raw | ConvertFrom-Json
    Write-Verbose "Found MCP servers: $($cursorConfig.mcpServers.PSObject.Properties.Name -join ', ')"
    $testResults.Tests += @{
        Name = "Cursor MCP Configuration"
        Result = "Passed"
    }
}
else {
    Write-Host " [FAIL]" -ForegroundColor Red
    Write-Host "  Configuration file not found at: $cursorConfigPath" -ForegroundColor Yellow
    $testResults.Tests += @{
        Name = "Cursor MCP Configuration"
        Result = "Failed"
    }
}

# Check .ai/mcp directory structure
Write-Host "Checking MCP directory structure..." -NoNewline
$requiredDirs = @(
    ".\.ai\mcp\servers",
    ".\.ai\mcp\configs",
    ".\.ai\mcp\logs",
    ".\.ai\cache",
    ".\.ai\rules"
)

$allDirsExist = $true
foreach ($dir in $requiredDirs) {
    if (-not (Test-Path $dir)) {
        $allDirsExist = $false
        Write-Verbose "Missing directory: $dir"
    }
}

if ($allDirsExist) {
    Write-Host " [PASS]" -ForegroundColor Green
    $testResults.Tests += @{
        Name = "MCP Directory Structure"
        Result = "Passed"
    }
}
else {
    Write-Host " [FAIL]" -ForegroundColor Red
    Write-Host "  Some directories are missing. Creating them..." -ForegroundColor Yellow
    foreach ($dir in $requiredDirs) {
        if (-not (Test-Path $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
        }
    }
    $testResults.Tests += @{
        Name = "MCP Directory Structure"
        Result = "Failed"
    }
}

Write-Host "`nPhase 3: Testing MCP Server Module" -ForegroundColor Yellow
Write-Host "-----------------------------------" -ForegroundColor DarkGray

# Import the module
Write-Host "Importing Unity-Claude-RepoAnalyst module..." -NoNewline
try {
    Import-Module ".\Modules\Unity-Claude-RepoAnalyst\Unity-Claude-RepoAnalyst.psd1" -Force -ErrorAction Stop
    Write-Host " [PASS]" -ForegroundColor Green
    $testResults.Tests += @{
        Name = "Module Import"
        Result = "Passed"
    }
    
    # Check for MCP functions
    $mcpFunctions = @('Start-MCPServer', 'Stop-MCPServer', 'Get-MCPServerStatus', 'Invoke-MCPServerCommand')
    $allFunctionsExist = $true
    
    foreach ($func in $mcpFunctions) {
        if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
            $allFunctionsExist = $false
            Write-Verbose "Missing function: $func"
        }
    }
    
    if ($allFunctionsExist) {
        Write-Host "All MCP functions available" -ForegroundColor Green
        $testResults.Tests += @{
            Name = "MCP Functions"
            Result = "Passed"
        }
    }
    else {
        Write-Host "Some MCP functions are missing" -ForegroundColor Red
        $testResults.Tests += @{
            Name = "MCP Functions"
            Result = "Failed"
        }
    }
}
catch {
    Write-Host " [FAIL]" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Red
    $testResults.Tests += @{
        Name = "Module Import"
        Result = "Failed"
        Error = $_.ToString()
    }
}

Write-Host "`nPhase 4: Testing NPX Package Access" -ForegroundColor Yellow
Write-Host "------------------------------------" -ForegroundColor DarkGray

if ($nodeInstalled -and $npmInstalled) {
    # Test npx availability
    Write-Host "Testing npx command..." -NoNewline
    try {
        $npxVersion = npx --version
        Write-Host " [PASS]" -ForegroundColor Green
        Write-Verbose "npx version: $npxVersion"
        $testResults.Tests += @{
            Name = "npx Availability"
            Result = "Passed"
        }
    }
    catch {
        Write-Host " [FAIL]" -ForegroundColor Red
        $testResults.Tests += @{
            Name = "npx Availability"
            Result = "Failed"
        }
    }
    
    # Test MCP packages availability (without actually running them)
    $mcpPackages = @(
        'mcp-ripgrep@latest',
        '@modelcontextprotocol/server-filesystem',
        '@modelcontextprotocol/server-git'
    )
    
    Write-Host "Checking MCP npm packages availability..."
    foreach ($package in $mcpPackages) {
        Write-Host "  - $package..." -NoNewline
        try {
            # Just check if package exists in npm registry
            $packageName = $package -replace '@latest', ''
            $result = npm view $packageName version 2>$null
            if ($result) {
                Write-Host " [AVAILABLE]" -ForegroundColor Green
                Write-Verbose "    Version: $result"
                $testResults.Tests += @{
                    Name = "NPM Package: $packageName"
                    Result = "Passed"
                }
            }
            else {
                Write-Host " [NOT FOUND]" -ForegroundColor Red
                $testResults.Tests += @{
                    Name = "NPM Package: $packageName"
                    Result = "Failed"
                }
            }
        }
        catch {
            Write-Host " [ERROR]" -ForegroundColor Red
            $testResults.Tests += @{
                Name = "NPM Package: $packageName"
                Result = "Failed"
                Error = $_.ToString()
            }
        }
    }
}
else {
    Write-Host "Skipping NPX tests (Node.js/npm not available)" -ForegroundColor Yellow
    $testResults.Tests += @{
        Name = "NPX Package Tests"
        Result = "Skipped"
    }
}

if (-not $SkipCursorCheck) {
    Write-Host "`nPhase 5: Cursor IDE Integration Check" -ForegroundColor Yellow
    Write-Host "--------------------------------------" -ForegroundColor DarkGray
    
    Write-Host "Checking for Cursor IDE process..." -NoNewline
    $cursorProcess = Get-Process -Name "Cursor" -ErrorAction SilentlyContinue
    if ($cursorProcess) {
        Write-Host " [RUNNING]" -ForegroundColor Green
        Write-Host "  Cursor is running. MCP servers should be accessible." -ForegroundColor Cyan
        Write-Host "  To verify:" -ForegroundColor Yellow
        Write-Host "    1. Open Cursor Settings (Ctrl+,)" -ForegroundColor White
        Write-Host "    2. Search for 'MCP'" -ForegroundColor White
        Write-Host "    3. Check if servers show green indicators" -ForegroundColor White
        $testResults.Tests += @{
            Name = "Cursor IDE Process"
            Result = "Passed"
        }
    }
    else {
        Write-Host " [NOT RUNNING]" -ForegroundColor Yellow
        Write-Host "  Cursor is not running. Start Cursor to test MCP integration." -ForegroundColor Yellow
        $testResults.Tests += @{
            Name = "Cursor IDE Process"
            Result = "Skipped"
        }
    }
}

# Calculate summary
$testResults.Summary.Total = $testResults.Tests.Count
$testResults.Summary.Passed = ($testResults.Tests | Where-Object { $_.Result -eq "Passed" }).Count
$testResults.Summary.Failed = ($testResults.Tests | Where-Object { $_.Result -eq "Failed" }).Count
$testResults.Summary.Skipped = ($testResults.Tests | Where-Object { $_.Result -eq "Skipped" }).Count

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "           TEST SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total Tests: $($testResults.Summary.Total)" -ForegroundColor White
Write-Host "Passed: $($testResults.Summary.Passed)" -ForegroundColor Green
Write-Host "Failed: $($testResults.Summary.Failed)" -ForegroundColor $(if ($testResults.Summary.Failed -gt 0) { 'Red' } else { 'Gray' })
Write-Host "Skipped: $($testResults.Summary.Skipped)" -ForegroundColor Yellow

# Save results
$testResults | ConvertTo-Json -Depth 10 | Out-File $resultFile
Write-Host "`nResults saved to: $resultFile" -ForegroundColor Cyan

# Return overall success
$success = $testResults.Summary.Failed -eq 0
if ($success) {
    Write-Host "`nMCP Server Infrastructure is ready!" -ForegroundColor Green
    Write-Host "You can now use MCP servers in Cursor IDE." -ForegroundColor Green
}
else {
    Write-Host "`nSome tests failed. Please review the results and fix issues." -ForegroundColor Red
}

return $success
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBahes1scrVgmtn
# yoAdjg68iAPFwPlH8VgIqLJ5WdCMsKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIA2sUcalRKR9bSQcSrAoivt7
# E7WnfRHSBvPemqG3KVAHMA0GCSqGSIb3DQEBAQUABIIBAK41M0MNLo9kd0nz+uGm
# xsZcf9Kg8NqaK/UiH35glm0or1KBZNQistvJm3ycqDAEDyiIfAnbWzl/M9AGa1Vp
# 6djcqVbu6RkM2f6LyRAIIQI9Ik5tCxl8S4phrGGWcyftXm8k+O/s0fSOqaQyXQrI
# FQFTmr51DleaRmCSnGKNgaA8CsgOeWBsgZVGmANFMx3gdJMfr8Qn/pDXoQG7/PhV
# OenJQehMkGS9Q/teVnLex3Szv2WNJIw8PWAqAcYHQ3+OtoB7JyFcgYARzSwxltXb
# 3txb3UhTlJHY+yNQyabqqlQ9T+Z1CIb49CrFHj/kLJrGpnQYTQLLVPDPW1jmHLxv
# n64=
# SIG # End signature block
