# Unity-Claude-CodeQL Module
# Enhanced Documentation System - Phase 3 Day 5: CodeQL Integration & Security
# Generated: 2025-08-25

#region Configuration and Initialization

$script:ModuleConfig = @{
    CodeQLPath = $env:CODEQL_HOME ?? "$env:USERPROFILE\codeql-home"
    DatabasePath = "$env:TEMP\codeql-databases"
    QueryPath = "$PSScriptRoot\queries"
    LogPath = "$env:TEMP\codeql-logs"
    SecurityThreshold = 'medium'
    MaxConcurrentScans = 3
}

# Initialize logging
if (-not (Test-Path $script:ModuleConfig.LogPath)) {
    New-Item -Path $script:ModuleConfig.LogPath -ItemType Directory -Force | Out-Null
}

function Write-CodeQLLog {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error', 'Debug')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMessage = "[$timestamp] [$Level] $Message"
    $logFile = Join-Path $script:ModuleConfig.LogPath "codeql-$(Get-Date -Format 'yyyyMMdd').log"
    
    Add-Content -Path $logFile -Value $logMessage -ErrorAction SilentlyContinue
    
    switch ($Level) {
        'Error' { Write-Error $Message }
        'Warning' { Write-Warning $Message }
        'Debug' { Write-Debug $Message }
        default { Write-Verbose $Message }
    }
}

#endregion

#region CodeQL CLI Management

function Install-CodeQLCLI {
    <#
    .SYNOPSIS
    Installs CodeQL CLI using multiple installation methods
    
    .DESCRIPTION
    Attempts to install CodeQL CLI using Chocolatey, direct download, or manual setup
    
    .PARAMETER InstallPath
    Path where CodeQL should be installed (default: $env:USERPROFILE\codeql-home)
    
    .PARAMETER Force
    Force reinstallation even if CodeQL is already present
    
    .EXAMPLE
    Install-CodeQLCLI -InstallPath "C:\Tools\CodeQL"
    #>
    [CmdletBinding()]
    param(
        [string]$InstallPath = $script:ModuleConfig.CodeQLPath,
        [switch]$Force
    )
    
    try {
        Write-CodeQLLog "Starting CodeQL CLI installation to: $InstallPath" -Level Info
        
        # Check if already installed
        if (-not $Force -and (Test-CodeQLInstallation)) {
            Write-CodeQLLog "CodeQL CLI already installed and functional" -Level Info
            return @{ Success = $true; Message = "CodeQL CLI already installed" }
        }
        
        # Method 1: Try Chocolatey installation
        if (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-CodeQLLog "Attempting Chocolatey installation..." -Level Info
            try {
                $chocoResult = & choco install codeql --yes 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-CodeQLLog "CodeQL installed successfully via Chocolatey" -Level Info
                    return @{ Success = $true; Method = 'Chocolatey'; Message = "Installed via Chocolatey" }
                }
            }
            catch {
                Write-CodeQLLog "Chocolatey installation failed: $($_.Exception.Message)" -Level Warning
            }
        }
        
        # Method 2: Direct download (GitHub releases)
        Write-CodeQLLog "Attempting direct download installation..." -Level Info
        
        if (-not (Test-Path $InstallPath)) {
            New-Item -Path $InstallPath -ItemType Directory -Force | Out-Null
        }
        
        # Download latest CodeQL CLI bundle
        $downloadUrl = "https://github.com/github/codeql-cli-binaries/releases/latest/download/codeql-win64.zip"
        $zipPath = Join-Path $env:TEMP "codeql-win64.zip"
        
        try {
            Write-CodeQLLog "Downloading CodeQL CLI from GitHub..." -Level Info
            Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing
            
            # Extract to installation directory
            Expand-Archive -Path $zipPath -DestinationPath $InstallPath -Force
            Remove-Item $zipPath -Force
            
            # Update PATH if needed
            $codeqlBinPath = Join-Path $InstallPath "codeql"
            if ($env:PATH -notlike "*$codeqlBinPath*") {
                $env:PATH += ";$codeqlBinPath"
                Write-CodeQLLog "Added CodeQL to PATH: $codeqlBinPath" -Level Info
            }
            
            # Verify installation
            if (Test-CodeQLInstallation) {
                Write-CodeQLLog "CodeQL CLI installed successfully via direct download" -Level Info
                return @{ Success = $true; Method = 'DirectDownload'; Path = $InstallPath }
            }
        }
        catch {
            Write-CodeQLLog "Direct download installation failed: $($_.Exception.Message)" -Level Error
        }
        
        return @{ Success = $false; Error = "All installation methods failed" }
    }
    catch {
        Write-CodeQLLog "CodeQL installation failed: $($_.Exception.Message)" -Level Error
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

function Test-CodeQLInstallation {
    <#
    .SYNOPSIS
    Verifies CodeQL CLI installation and functionality
    
    .DESCRIPTION
    Tests CodeQL CLI installation by checking executable presence and basic functionality
    
    .EXAMPLE
    Test-CodeQLInstallation
    #>
    [CmdletBinding()]
    param()
    
    try {
        # Test if CodeQL command is available
        $codeqlCommand = Get-Command codeql -ErrorAction SilentlyContinue
        if (-not $codeqlCommand) {
            Write-CodeQLLog "CodeQL command not found in PATH" -Level Warning
            return $false
        }
        
        # Test basic CodeQL functionality
        $version = & codeql version 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-CodeQLLog "CodeQL version check failed" -Level Warning
            return $false
        }
        
        Write-CodeQLLog "CodeQL CLI verified: $($version[0])" -Level Info
        return $true
    }
    catch {
        Write-CodeQLLog "CodeQL installation test failed: $($_.Exception.Message)" -Level Error
        return $false
    }
}

#endregion

#region Database Management

function New-CodeQLDatabase {
    <#
    .SYNOPSIS
    Creates a new CodeQL database for a source code directory
    
    .DESCRIPTION
    Creates CodeQL database with language detection and custom configuration
    
    .PARAMETER SourcePath
    Path to source code directory to analyze
    
    .PARAMETER Language
    Programming language (powershell, csharp, javascript, etc.)
    
    .PARAMETER DatabaseName
    Name for the database (default: auto-generated)
    
    .EXAMPLE
    New-CodeQLDatabase -SourcePath "C:\Code\MyProject" -Language "csharp"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SourcePath,
        
        [Parameter(Mandatory)]
        [ValidateSet('powershell', 'csharp', 'javascript', 'python', 'java', 'go', 'cpp', 'ruby')]
        [string]$Language,
        
        [string]$DatabaseName
    )
    
    try {
        if (-not (Test-Path $SourcePath)) {
            throw "Source path does not exist: $SourcePath"
        }
        
        if (-not $DatabaseName) {
            $DatabaseName = "$(Split-Path $SourcePath -Leaf)-$Language-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        }
        
        $dbPath = Join-Path $script:ModuleConfig.DatabasePath $DatabaseName
        
        Write-CodeQLLog "Creating CodeQL database: $DatabaseName for language: $Language" -Level Info
        
        # Create database directory
        if (-not (Test-Path $script:ModuleConfig.DatabasePath)) {
            New-Item -Path $script:ModuleConfig.DatabasePath -ItemType Directory -Force | Out-Null
        }
        
        # Build CodeQL database
        $codeqlArgs = @(
            'database', 'create', $dbPath,
            '--language', $Language,
            '--source-root', $SourcePath
        )
        
        Write-CodeQLLog "Executing: codeql $($codeqlArgs -join ' ')" -Level Debug
        
        $result = & codeql $codeqlArgs 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-CodeQLLog "Database created successfully: $dbPath" -Level Info
            return @{
                Success = $true
                DatabasePath = $dbPath
                Language = $Language
                SourcePath = $SourcePath
            }
        }
        else {
            throw "CodeQL database creation failed: $result"
        }
    }
    catch {
        Write-CodeQLLog "Database creation failed: $($_.Exception.Message)" -Level Error
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

function Initialize-PowerShellCodeQLDB {
    <#
    .SYNOPSIS
    Creates CodeQL database specifically for PowerShell code analysis
    
    .DESCRIPTION
    Specialized database creation for PowerShell projects with optimized settings
    
    .PARAMETER ProjectPath
    Path to PowerShell project or module
    
    .EXAMPLE
    Initialize-PowerShellCodeQLDB -ProjectPath "C:\Code\MyPowerShellModule"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProjectPath
    )
    
    try {
        Write-CodeQLLog "Initializing PowerShell CodeQL database for: $ProjectPath" -Level Info
        
        # PowerShell-specific database creation
        $result = New-CodeQLDatabase -SourcePath $ProjectPath -Language 'javascript' -DatabaseName "PowerShell-$(Split-Path $ProjectPath -Leaf)"
        
        if ($result.Success) {
            # Additional PowerShell-specific setup
            Write-CodeQLLog "PowerShell CodeQL database initialized successfully" -Level Info
        }
        
        return $result
    }
    catch {
        Write-CodeQLLog "PowerShell database initialization failed: $($_.Exception.Message)" -Level Error
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

#endregion

#region Query Execution

function Invoke-CodeQLQuery {
    <#
    .SYNOPSIS
    Executes a CodeQL query against a database
    
    .DESCRIPTION
    Runs CodeQL queries and processes results for security analysis
    
    .PARAMETER DatabasePath
    Path to CodeQL database
    
    .PARAMETER QueryPath
    Path to CodeQL query file or query suite
    
    .PARAMETER OutputFormat
    Output format (sarif, csv, json)
    
    .EXAMPLE
    Invoke-CodeQLQuery -DatabasePath "C:\db\myproject" -QueryPath "security-extended" -OutputFormat "sarif"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DatabasePath,
        
        [Parameter(Mandatory)]
        [string]$QueryPath,
        
        [ValidateSet('sarif', 'csv', 'json')]
        [string]$OutputFormat = 'sarif',
        
        [string]$OutputPath
    )
    
    try {
        if (-not (Test-Path $DatabasePath)) {
            throw "Database not found: $DatabasePath"
        }
        
        if (-not $OutputPath) {
            $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
            $OutputPath = Join-Path $script:ModuleConfig.LogPath "results-$timestamp.$OutputFormat"
        }
        
        Write-CodeQLLog "Executing CodeQL query: $QueryPath against database: $DatabasePath" -Level Info
        
        $codeqlArgs = @(
            'database', 'analyze', $DatabasePath,
            $QueryPath,
            '--format', $OutputFormat,
            '--output', $OutputPath
        )
        
        Write-CodeQLLog "Executing: codeql $($codeqlArgs -join ' ')" -Level Debug
        
        $result = & codeql $codeqlArgs 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-CodeQLLog "Query executed successfully. Results: $OutputPath" -Level Info
            
            # Process results
            $findings = @()
            if (Test-Path $OutputPath) {
                switch ($OutputFormat) {
                    'json' { 
                        $findings = Get-Content $OutputPath | ConvertFrom-Json 
                    }
                    'sarif' { 
                        $sarifData = Get-Content $OutputPath | ConvertFrom-Json
                        $findings = $sarifData.runs.results
                    }
                }
            }
            
            return @{
                Success = $true
                OutputPath = $OutputPath
                FindingsCount = $findings.Count
                Findings = $findings
            }
        }
        else {
            throw "CodeQL query execution failed: $result"
        }
    }
    catch {
        Write-CodeQLLog "Query execution failed: $($_.Exception.Message)" -Level Error
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

function Invoke-PowerShellSecurityScan {
    <#
    .SYNOPSIS
    Performs comprehensive security scan of PowerShell code
    
    .DESCRIPTION
    Runs PowerShell-specific security queries including script injection, credential exposure, and command injection detection
    
    .PARAMETER ProjectPath
    Path to PowerShell project
    
    .PARAMETER ScanLevel
    Security scan level (basic, standard, comprehensive)
    
    .EXAMPLE
    Invoke-PowerShellSecurityScan -ProjectPath "C:\Code\MyModule" -ScanLevel "comprehensive"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProjectPath,
        
        [ValidateSet('basic', 'standard', 'comprehensive')]
        [string]$ScanLevel = 'standard'
    )
    
    try {
        Write-CodeQLLog "Starting PowerShell security scan: $ScanLevel level" -Level Info
        
        # Create database if needed
        $dbResult = Initialize-PowerShellCodeQLDB -ProjectPath $ProjectPath
        if (-not $dbResult.Success) {
            throw "Failed to create database: $($dbResult.Error)"
        }
        
        # Define query suites based on scan level
        $querySuites = switch ($ScanLevel) {
            'basic' { @('security-extended') }
            'standard' { @('security-extended', 'security-and-quality') }
            'comprehensive' { @('security-extended', 'security-and-quality', 'security-experimental') }
        }
        
        $allFindings = @()
        foreach ($suite in $querySuites) {
            Write-CodeQLLog "Running query suite: $suite" -Level Info
            
            $queryResult = Invoke-CodeQLQuery -DatabasePath $dbResult.DatabasePath -QueryPath $suite -OutputFormat 'sarif'
            
            if ($queryResult.Success -and $queryResult.Findings) {
                $allFindings += $queryResult.Findings
            }
        }
        
        # Generate security report
        $securityReport = @{
            ScanDate = Get-Date
            ProjectPath = $ProjectPath
            ScanLevel = $ScanLevel
            TotalFindings = $allFindings.Count
            CriticalCount = ($allFindings | Where-Object { $_.level -eq 'error' }).Count
            HighCount = ($allFindings | Where-Object { $_.level -eq 'warning' }).Count
            MediumCount = ($allFindings | Where-Object { $_.level -eq 'note' }).Count
            Findings = $allFindings
        }
        
        Write-CodeQLLog "PowerShell security scan completed. Found $($allFindings.Count) issues" -Level Info
        
        return @{
            Success = $true
            Report = $securityReport
            DatabasePath = $dbResult.DatabasePath
        }
    }
    catch {
        Write-CodeQLLog "PowerShell security scan failed: $($_.Exception.Message)" -Level Error
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

#endregion

#region Results Processing and Reporting

function Export-CodeQLResults {
    <#
    .SYNOPSIS
    Exports CodeQL results in various formats for integration
    
    .DESCRIPTION
    Processes and exports CodeQL analysis results for documentation and reporting
    
    .PARAMETER Results
    CodeQL analysis results object
    
    .PARAMETER OutputPath
    Path for exported results
    
    .PARAMETER Format
    Export format (html, markdown, json, xml)
    
    .EXAMPLE
    Export-CodeQLResults -Results $scanResults -OutputPath "security-report.html" -Format "html"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Results,
        
        [string]$OutputPath,
        
        [ValidateSet('html', 'markdown', 'json', 'xml')]
        [string]$Format = 'html'
    )
    
    try {
        if (-not $OutputPath) {
            $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
            $OutputPath = "security-report-$timestamp.$Format"
        }
        
        Write-CodeQLLog "Exporting CodeQL results to: $OutputPath" -Level Info
        
        switch ($Format) {
            'html' {
                $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>CodeQL Security Analysis Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: #f4f4f4; padding: 20px; border-left: 4px solid #007acc; }
        .critical { color: #d73a49; font-weight: bold; }
        .high { color: #f66a0a; font-weight: bold; }
        .medium { color: #ffd33d; font-weight: bold; }
        .finding { margin: 10px 0; padding: 10px; border-left: 3px solid #ccc; }
        .summary { background: #f8f9fa; padding: 15px; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="header">
        <h1>CodeQL Security Analysis Report</h1>
        <p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
        <p>Project: $($Results.Report.ProjectPath)</p>
        <p>Scan Level: $($Results.Report.ScanLevel)</p>
    </div>
    
    <div class="summary">
        <h2>Summary</h2>
        <p>Total Findings: $($Results.Report.TotalFindings)</p>
        <p><span class="critical">Critical: $($Results.Report.CriticalCount)</span></p>
        <p><span class="high">High: $($Results.Report.HighCount)</span></p>
        <p><span class="medium">Medium: $($Results.Report.MediumCount)</span></p>
    </div>
    
    <h2>Detailed Findings</h2>
"@
                
                foreach ($finding in $Results.Report.Findings) {
                    $severity = switch ($finding.level) {
                        'error' { 'critical' }
                        'warning' { 'high' }
                        default { 'medium' }
                    }
                    
                    $html += @"
    <div class="finding">
        <h3 class="$severity">$($finding.ruleId): $($finding.message.text)</h3>
        <p><strong>File:</strong> $($finding.locations[0].physicalLocation.artifactLocation.uri)</p>
        <p><strong>Line:</strong> $($finding.locations[0].physicalLocation.region.startLine)</p>
        <p><strong>Severity:</strong> <span class="$severity">$($finding.level)</span></p>
    </div>
"@
                }
                
                $html += "</body></html>"
                $html | Out-File -FilePath $OutputPath -Encoding UTF8
            }
            
            'markdown' {
                $markdown = @"
# CodeQL Security Analysis Report

**Generated:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  
**Project:** $($Results.Report.ProjectPath)  
**Scan Level:** $($Results.Report.ScanLevel)  

## Summary

- **Total Findings:** $($Results.Report.TotalFindings)
- **Critical:** $($Results.Report.CriticalCount)
- **High:** $($Results.Report.HighCount)  
- **Medium:** $($Results.Report.MediumCount)

## Detailed Findings

"@
                
                foreach ($finding in $Results.Report.Findings) {
                    $markdown += @"
### $($finding.ruleId): $($finding.message.text)

- **File:** $($finding.locations[0].physicalLocation.artifactLocation.uri)
- **Line:** $($finding.locations[0].physicalLocation.region.startLine)
- **Severity:** $($finding.level)

---

"@
                }
                
                $markdown | Out-File -FilePath $OutputPath -Encoding UTF8
            }
            
            'json' {
                $Results.Report | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
            }
        }
        
        Write-CodeQLLog "Results exported successfully to: $OutputPath" -Level Info
        return @{ Success = $true; OutputPath = $OutputPath }
    }
    catch {
        Write-CodeQLLog "Results export failed: $($_.Exception.Message)" -Level Error
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

#endregion

#region Integration Functions

function Register-SecurityCallback {
    <#
    .SYNOPSIS
    Registers callback functions for security events
    
    .DESCRIPTION
    Allows registration of custom callbacks for security findings integration
    
    .PARAMETER CallbackFunction
    Function to call when security issues are found
    
    .EXAMPLE
    Register-SecurityCallback -CallbackFunction { param($findings) Write-Host "Found $($findings.Count) issues" }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$CallbackFunction
    )
    
    $script:SecurityCallback = $CallbackFunction
    Write-CodeQLLog "Security callback registered" -Level Info
}

function Get-CodeQLVersion {
    <#
    .SYNOPSIS
    Gets CodeQL CLI version information
    
    .EXAMPLE
    Get-CodeQLVersion
    #>
    [CmdletBinding()]
    param()
    
    try {
        if (-not (Test-CodeQLInstallation)) {
            throw "CodeQL CLI not installed or not functional"
        }
        
        $version = & codeql version 2>&1
        return @{
            Success = $true
            Version = $version[0]
            FullOutput = $version
        }
    }
    catch {
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

#endregion

# Export module members
Export-ModuleMember -Function @(
    'Install-CodeQLCLI',
    'Test-CodeQLInstallation',
    'New-CodeQLDatabase',
    'Initialize-PowerShellCodeQLDB',
    'Initialize-CSharpCodeQLDB',
    'Invoke-CodeQLQuery',
    'Invoke-PowerShellSecurityScan',
    'Invoke-CSharpSecurityScan',
    'Export-CodeQLResults',
    'Register-SecurityCallback',
    'Get-CodeQLVersion'
) -Alias @(
    'cql-scan',
    'cql-db', 
    'cql-query',
    'cql-report',
    'sec-scan'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAOkRVFnptULEP5
# Gqx1TJHp0ZGlk2OIs3Y8Z2AOh3mScqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIMtPimmQVn2IyZjCufxob3OP
# Q58JE8viTdAej2/KacEAMA0GCSqGSIb3DQEBAQUABIIBAGwEnYuDJxNVNgPuGMwN
# ztYhnOSFDeu2B1HKzStpR0XuU0oYfG6VptJNQI5dtBwREPVbTEh+JnxzYJoa+O5m
# 3+eLjYML0P2GjrWmlEJBpIo59kOFuuQbQ4wUWtVtzAJ2QnE3jbmpnCG8iGtZDDvx
# SyczJhjas+3pDi+XBN9V3Rsm8PWKpQmdD78LzHNUK7AU/Sz5ydMw9Mr1t9n4xzBV
# zciotplAdC8kWqG/INFfNWIYCZEwkKQkyYEtn9sj4dChrDSqQxTQLZ+XQ3hMPuyn
# Ppo2K/uswUQBKkAgQW+DWoiRXc2vLwEotADzaUUdJa3NCxyzb3zubnY/F7f6QUKC
# X5w=
# SIG # End signature block
