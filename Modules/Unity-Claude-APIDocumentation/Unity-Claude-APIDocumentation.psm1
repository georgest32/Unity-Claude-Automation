# Unity-Claude-APIDocumentation Module
# Enhanced Documentation System - Phase 3 Day 5: Final Integration & Documentation
# Generated: 2025-08-25

#region Configuration and Initialization

$script:ModuleConfig = @{
    OutputPath = ".\docs\api"
    TemplatePath = "$PSScriptRoot\templates"
    LogPath = "$env:TEMP\api-documentation-logs"
    PlatypsPSVersion = "Microsoft.PowerShell.PlatyPS"
    SupportedFormats = @('html', 'markdown', 'pdf', 'wiki', 'openapi')
}

# Initialize logging
if (-not (Test-Path $script:ModuleConfig.LogPath)) {
    New-Item -Path $script:ModuleConfig.LogPath -ItemType Directory -Force | Out-Null
}

function Write-DocLog {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error', 'Debug')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMessage = "[$timestamp] [$Level] $Message"
    $logFile = Join-Path $script:ModuleConfig.LogPath "api-docs-$(Get-Date -Format 'yyyyMMdd').log"
    
    Add-Content -Path $logFile -Value $logMessage -ErrorAction SilentlyContinue
    
    switch ($Level) {
        'Error' { Write-Error $Message }
        'Warning' { Write-Warning $Message }
        'Debug' { Write-Debug $Message }
        default { Write-Verbose $Message }
    }
}

#endregion

#region PlatyPS Integration and Setup

function Install-PlatyPS {
    <#
    .SYNOPSIS
    Installs or updates PlatyPS documentation module
    
    .DESCRIPTION
    Installs Microsoft.PowerShell.PlatyPS (new version) or falls back to legacy platyPS
    
    .PARAMETER Force
    Force reinstallation even if already present
    
    .EXAMPLE
    Install-PlatyPS -Force
    #>
    [CmdletBinding()]
    param(
        [switch]$Force
    )
    
    try {
        Write-DocLog "Checking PlatyPS installation..." -Level Info
        
        # Check if already installed
        $existing = Get-Module -ListAvailable -Name $script:ModuleConfig.PlatypsPSVersion -ErrorAction SilentlyContinue
        if ($existing -and -not $Force) {
            Write-DocLog "PlatyPS already installed: $($existing.Version)" -Level Info
            return @{ Success = $true; Version = $existing.Version; AlreadyInstalled = $true }
        }
        
        # Try to install new PlatyPS version
        try {
            Write-DocLog "Installing Microsoft.PowerShell.PlatyPS..." -Level Info
            
            if ($PSVersionTable.PSVersion.Major -ge 7) {
                # PowerShell 7+
                Install-PSResource -Name $script:ModuleConfig.PlatypsPSVersion -Prerelease -Force:$Force -Scope CurrentUser
            }
            else {
                # Windows PowerShell 5.1
                Install-Module -Name $script:ModuleConfig.PlatypsPSVersion -AllowPrerelease -Force:$Force -Scope CurrentUser
            }
            
            Write-DocLog "PlatyPS installed successfully" -Level Info
            return @{ Success = $true; Version = "Latest"; Method = "PSResource" }
        }
        catch {
            Write-DocLog "Failed to install new PlatyPS, trying legacy version..." -Level Warning
            
            # Fallback to legacy version
            Install-Module -Name "platyPS" -Force:$Force -Scope CurrentUser
            Write-DocLog "Legacy PlatyPS installed successfully" -Level Info
            return @{ Success = $true; Version = "Legacy"; Method = "Legacy" }
        }
    }
    catch {
        Write-DocLog "PlatyPS installation failed: $($_.Exception.Message)" -Level Error
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

function Initialize-DocumentationProject {
    <#
    .SYNOPSIS
    Initializes a new documentation project structure
    
    .DESCRIPTION
    Creates directory structure and configuration files for comprehensive API documentation
    
    .PARAMETER ProjectPath
    Root path for documentation project
    
    .PARAMETER ModulePaths
    Array of module paths to document
    
    .EXAMPLE
    Initialize-DocumentationProject -ProjectPath ".\docs" -ModulePaths @(".\Modules\Unity-Claude-CPG", ".\Modules\Unity-Claude-LLM")
    #>
    [CmdletBinding()]
    param(
        [string]$ProjectPath = $script:ModuleConfig.OutputPath,
        [string[]]$ModulePaths = @()
    )
    
    try {
        Write-DocLog "Initializing documentation project at: $ProjectPath" -Level Info
        
        # Create directory structure
        $directories = @(
            $ProjectPath,
            "$ProjectPath\api",
            "$ProjectPath\guides",
            "$ProjectPath\examples", 
            "$ProjectPath\architecture",
            "$ProjectPath\integration",
            "$ProjectPath\templates",
            "$ProjectPath\assets",
            "$ProjectPath\assets\images",
            "$ProjectPath\assets\diagrams"
        )
        
        foreach ($dir in $directories) {
            if (-not (Test-Path $dir)) {
                New-Item -Path $dir -ItemType Directory -Force | Out-Null
                Write-DocLog "Created directory: $dir" -Level Debug
            }
        }
        
        # Create configuration file
        $config = @{
            ProjectName = "Enhanced Documentation System API Reference"
            Version = "1.0.0"
            GeneratedDate = Get-Date
            ModulePaths = $ModulePaths
            OutputFormats = $script:ModuleConfig.SupportedFormats
            Settings = @{
                IncludePrivateFunctions = $false
                GenerateExamples = $true
                CrossReferenceLinks = $true
                ValidateLinks = $true
                GenerateTOC = $true
            }
        }
        
        $configPath = Join-Path $ProjectPath "documentation-config.json"
        $config | ConvertTo-Json -Depth 10 | Out-File -FilePath $configPath -Encoding UTF8
        
        Write-DocLog "Documentation project initialized successfully" -Level Info
        return @{ Success = $true; ProjectPath = $ProjectPath; ConfigPath = $configPath }
    }
    catch {
        Write-DocLog "Documentation project initialization failed: $($_.Exception.Message)" -Level Error
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

#endregion

#region Module Documentation Generation

function New-ModuleDocumentation {
    <#
    .SYNOPSIS
    Generates comprehensive documentation for a PowerShell module
    
    .DESCRIPTION
    Creates complete API documentation including function reference, examples, and cross-references
    
    .PARAMETER ModulePath
    Path to the PowerShell module
    
    .PARAMETER OutputPath
    Output directory for generated documentation
    
    .PARAMETER IncludePrivate
    Include private/internal functions in documentation
    
    .EXAMPLE
    New-ModuleDocumentation -ModulePath ".\Modules\Unity-Claude-CPG" -OutputPath ".\docs\api\CPG"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModulePath,
        
        [string]$OutputPath,
        
        [switch]$IncludePrivate,
        
        [switch]$Force
    )
    
    try {
        # Validate module path
        $manifestPath = Get-ChildItem -Path $ModulePath -Filter "*.psd1" | Select-Object -First 1
        if (-not $manifestPath) {
            throw "No module manifest found in: $ModulePath"
        }
        
        $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($manifestPath.Name)
        Write-DocLog "Generating documentation for module: $moduleName" -Level Info
        
        # Set output path
        if (-not $OutputPath) {
            $OutputPath = Join-Path $script:ModuleConfig.OutputPath $moduleName
        }
        
        if (-not (Test-Path $OutputPath)) {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        }
        
        # Import module
        Write-DocLog "Importing module: $manifestPath" -Level Debug
        Import-Module $manifestPath.FullName -Force -ErrorAction Stop
        
        # Get module information
        $module = Get-Module $moduleName
        if (-not $module) {
            throw "Failed to import module: $moduleName"
        }
        
        # Get functions to document
        $functions = $module.ExportedFunctions.Keys
        if ($IncludePrivate) {
            # Also include non-exported functions
            $allFunctions = Get-Command -Module $moduleName -CommandType Function
            $functions += $allFunctions.Name | Where-Object { $_ -notin $functions }
        }
        
        Write-DocLog "Found $($functions.Count) functions to document" -Level Info
        
        # Generate markdown help using PlatyPS
        try {
            # Try new PlatyPS first
            if (Get-Module -ListAvailable -Name $script:ModuleConfig.PlatypsPSVersion) {
                Import-Module $script:ModuleConfig.PlatypsPSVersion -Force
                New-MarkdownHelp -Module $moduleName -OutputFolder $OutputPath -Force:$Force
            }
            else {
                # Fallback to legacy PlatyPS
                Import-Module platyPS -Force
                New-MarkdownHelp -Module $moduleName -OutputFolder $OutputPath -Force:$Force
            }
        }
        catch {
            Write-DocLog "PlatyPS generation failed, creating manual documentation..." -Level Warning
            
            # Manual documentation generation
            foreach ($functionName in $functions) {
                $functionDoc = New-FunctionDocumentation -FunctionName $functionName -ModuleName $moduleName
                $docPath = Join-Path $OutputPath "$functionName.md"
                $functionDoc | Out-File -FilePath $docPath -Encoding UTF8
            }
        }
        
        # Create module overview
        $overview = New-ModuleOverview -Module $module -Functions $functions
        $overviewPath = Join-Path $OutputPath "$moduleName.md"
        $overview | Out-File -FilePath $overviewPath -Encoding UTF8
        
        # Generate cross-references
        $crossRef = Build-ModuleCrossReference -ModuleName $moduleName -Functions $functions
        $crossRefPath = Join-Path $OutputPath "cross-references.md"
        $crossRef | Out-File -FilePath $crossRefPath -Encoding UTF8
        
        Write-DocLog "Module documentation generated successfully: $OutputPath" -Level Info
        
        return @{
            Success = $true
            ModuleName = $moduleName
            OutputPath = $OutputPath
            FunctionCount = $functions.Count
            Files = Get-ChildItem -Path $OutputPath -Filter "*.md" | Select-Object -ExpandProperty Name
        }
    }
    catch {
        Write-DocLog "Module documentation generation failed: $($_.Exception.Message)" -Level Error
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

function New-FunctionDocumentation {
    <#
    .SYNOPSIS
    Creates documentation for a specific PowerShell function
    
    .DESCRIPTION
    Generates detailed markdown documentation for a function including syntax, parameters, examples
    
    .PARAMETER FunctionName
    Name of the function to document
    
    .PARAMETER ModuleName
    Name of the module containing the function
    
    .EXAMPLE
    New-FunctionDocumentation -FunctionName "Get-CodePurpose" -ModuleName "Unity-Claude-SemanticAnalysis"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FunctionName,
        
        [Parameter(Mandatory)]
        [string]$ModuleName
    )
    
    try {
        $command = Get-Command -Name $FunctionName -Module $ModuleName -ErrorAction Stop
        $help = Get-Help $FunctionName -Full -ErrorAction SilentlyContinue
        
        $doc = @"
# $FunctionName

## Synopsis
$($help.Synopsis ?? "Function description not available")

## Description
$($help.Description.Text ?? "Detailed description not available")

## Syntax

``````powershell
$($command.Definition)
``````

## Parameters

"@
        
        # Add parameters
        if ($command.Parameters) {
            foreach ($param in $command.Parameters.Values) {
                if ($param.Name -notin @('Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'InformationAction', 'ErrorVariable', 'WarningVariable', 'InformationVariable', 'OutVariable', 'OutBuffer', 'PipelineVariable')) {
                    $doc += @"

### -$($param.Name)
**Type:** $($param.ParameterType.Name)  
**Required:** $($param.Attributes.Mandatory -contains $true)  
**Position:** $($param.Attributes.Position ?? "Named")  

"@
                }
            }
        }
        
        # Add examples
        if ($help.Examples) {
            $doc += @"

## Examples

"@
            foreach ($example in $help.Examples.Example) {
                $doc += @"

### $($example.Title ?? "Example")

``````powershell
$($example.Code)
``````

$($example.Remarks.Text ?? "")

"@
            }
        }
        
        # Add related links
        if ($help.RelatedLinks) {
            $doc += @"

## Related Links

"@
            foreach ($link in $help.RelatedLinks.NavigationLink) {
                $doc += "- [$($link.LinkText)]($($link.Uri))`n"
            }
        }
        
        return $doc
    }
    catch {
        Write-DocLog "Function documentation generation failed for $FunctionName`: $($_.Exception.Message)" -Level Error
        return "# $FunctionName`n`nDocumentation generation failed: $($_.Exception.Message)"
    }
}

function New-ModuleOverview {
    <#
    .SYNOPSIS
    Creates module overview documentation
    
    .PARAMETER Module
    PowerShell module object
    
    .PARAMETER Functions
    Array of function names
    
    .EXAMPLE
    New-ModuleOverview -Module $myModule -Functions @("Func1", "Func2")
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Module,
        
        [string[]]$Functions = @()
    )
    
    $overview = @"
# $($Module.Name) Module

## Overview
**Version:** $($Module.Version)  
**Author:** $($Module.Author ?? "Unity-Claude-Automation")  
**Description:** $($Module.Description ?? "No description available")  

## Module Information
- **GUID:** $($Module.Guid)
- **PowerShell Version:** $($Module.PowerShellVersion)
- **Exported Functions:** $($Module.ExportedFunctions.Count)
- **Total Functions:** $($Functions.Count)

## Exported Functions

"@
    
    foreach ($functionName in $Functions) {
        $overview += "- [$functionName]($functionName.md)`n"
    }
    
    if ($Module.ExportedAliases.Count -gt 0) {
        $overview += @"

## Exported Aliases

"@
        foreach ($alias in $Module.ExportedAliases.Keys) {
            $overview += "- **$alias** → $($Module.ExportedAliases[$alias])`n"
        }
    }
    
    return $overview
}

#endregion

#region Comprehensive API Documentation

function New-ComprehensiveAPIDocs {
    <#
    .SYNOPSIS
    Generates complete API documentation for all Enhanced Documentation System modules
    
    .DESCRIPTION
    Creates comprehensive documentation covering all modules, cross-references, and integration guides
    
    .PARAMETER ProjectRoot
    Root path of the project containing modules
    
    .PARAMETER OutputPath
    Output directory for all documentation
    
    .EXAMPLE
    New-ComprehensiveAPIDocs -ProjectRoot "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProjectRoot,
        
        [string]$OutputPath = ".\docs\api-complete"
    )
    
    try {
        Write-DocLog "Starting comprehensive API documentation generation..." -Level Info
        
        # Initialize documentation project
        $initResult = Initialize-DocumentationProject -ProjectPath $OutputPath
        if (-not $initResult.Success) {
            throw "Failed to initialize documentation project: $($initResult.Error)"
        }
        
        # Find all modules
        $modulesPath = Join-Path $ProjectRoot "Modules"
        $moduleDirectories = Get-ChildItem -Path $modulesPath -Directory | Where-Object { 
            Test-Path (Join-Path $_.FullName "*.psd1")
        }
        
        Write-DocLog "Found $($moduleDirectories.Count) modules to document" -Level Info
        
        $allResults = @()
        $moduleIndex = @()
        
        # Generate documentation for each module
        foreach ($moduleDir in $moduleDirectories) {
            Write-DocLog "Processing module: $($moduleDir.Name)" -Level Info
            
            $moduleOutputPath = Join-Path $OutputPath "api" $moduleDir.Name
            $result = New-ModuleDocumentation -ModulePath $moduleDir.FullName -OutputPath $moduleOutputPath
            
            if ($result.Success) {
                $allResults += $result
                $moduleIndex += @{
                    Name = $result.ModuleName
                    Path = "api/$($moduleDir.Name)/$($result.ModuleName).md"
                    FunctionCount = $result.FunctionCount
                    Description = "Enhanced Documentation System module"
                }
            }
        }
        
        # Generate master index
        $masterIndex = New-MasterAPIIndex -Modules $moduleIndex -OutputPath $OutputPath
        
        # Generate architecture documentation
        $architectureDocs = New-ArchitectureDocumentation -ProjectRoot $ProjectRoot -OutputPath $OutputPath
        
        # Generate user guides
        $userGuides = New-ComprehensiveUserGuides -OutputPath $OutputPath -Modules $moduleIndex
        
        # Generate integration guides
        $integrationGuides = New-IntegrationDocumentation -OutputPath $OutputPath -Modules $moduleIndex
        
        Write-DocLog "Comprehensive API documentation completed successfully" -Level Info
        
        return @{
            Success = $true
            OutputPath = $OutputPath
            ModulesDocumented = $allResults.Count
            TotalFunctions = ($allResults | Measure-Object -Property FunctionCount -Sum).Sum
            Components = @{
                ModuleDocumentation = $allResults
                MasterIndex = $masterIndex
                ArchitectureDocs = $architectureDocs
                UserGuides = $userGuides
                IntegrationGuides = $integrationGuides
            }
        }
    }
    catch {
        Write-DocLog "Comprehensive API documentation failed: $($_.Exception.Message)" -Level Error
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

function New-MasterAPIIndex {
    <#
    .SYNOPSIS
    Creates master API index page
    
    .PARAMETER Modules
    Array of module information objects
    
    .PARAMETER OutputPath
    Output directory path
    
    .EXAMPLE
    New-MasterAPIIndex -Modules $moduleData -OutputPath ".\docs"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$Modules,
        
        [Parameter(Mandatory)]
        [string]$OutputPath
    )
    
    $index = @"
# Enhanced Documentation System - API Reference

**Generated:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  
**Total Modules:** $($Modules.Count)  
**Total Functions:** $(($Modules | Measure-Object -Property FunctionCount -Sum).Sum)

## Overview

The Enhanced Documentation System provides intelligent relationship mapping, obsolescence detection, and automated documentation generation for codebases. This API reference covers all modules and their exported functions.

## Architecture

The system is built around several core components:

1. **Code Property Graph (CPG)** - Foundation for relationship analysis
2. **Semantic Analysis** - Pattern recognition and code understanding  
3. **LLM Integration** - Natural language documentation enhancement
4. **Performance Optimization** - Caching and scalability features
5. **Security Analysis** - CodeQL integration for vulnerability detection

## Module Index

"@
    
    foreach ($module in $Modules) {
        $index += "- **[$($module.Name)]($($module.Path))** - $($module.Description) ($($module.FunctionCount) functions)`n"
    }
    
    $index += @"

## Quick Links

- [Installation Guide](guides/installation.md)
- [Quick Start](guides/quick-start.md)
- [Configuration](guides/configuration.md)
- [Architecture Overview](architecture/overview.md)
- [Integration Examples](integration/examples.md)

## Support

For issues and questions:
- [GitHub Issues](https://github.com/unity-claude/enhanced-documentation/issues)
- [Documentation Updates](documentation-updates.md)
"@
    
    $indexPath = Join-Path $OutputPath "README.md"
    $index | Out-File -FilePath $indexPath -Encoding UTF8
    
    return @{ Success = $true; Path = $indexPath }
}

#endregion

#region Export Functions

function Export-HTMLDocumentation {
    <#
    .SYNOPSIS
    Exports documentation to HTML format
    
    .DESCRIPTION
    Converts markdown documentation to HTML with styling and navigation
    
    .PARAMETER SourcePath
    Path to markdown documentation files
    
    .PARAMETER OutputPath
    Output path for HTML files
    
    .PARAMETER Theme
    HTML theme (default, bootstrap, material)
    
    .EXAMPLE
    Export-HTMLDocumentation -SourcePath ".\docs\api" -OutputPath ".\docs\html" -Theme "bootstrap"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SourcePath,
        
        [string]$OutputPath = ".\docs\html",
        
        [ValidateSet('default', 'bootstrap', 'material')]
        [string]$Theme = 'bootstrap'
    )
    
    try {
        Write-DocLog "Exporting HTML documentation from: $SourcePath" -Level Info
        
        if (-not (Test-Path $OutputPath)) {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        }
        
        # Get all markdown files
        $markdownFiles = Get-ChildItem -Path $SourcePath -Filter "*.md" -Recurse
        
        $htmlTemplate = Get-HTMLTemplate -Theme $Theme
        $convertedFiles = @()
        
        foreach ($mdFile in $markdownFiles) {
            Write-DocLog "Converting: $($mdFile.Name)" -Level Debug
            
            # Convert markdown to HTML
            $markdown = Get-Content -Path $mdFile.FullName -Raw
            $htmlContent = ConvertFrom-Markdown -InputObject $markdown -AsHtml
            
            # Apply template
            $fullHtml = $htmlTemplate -f $mdFile.BaseName, $htmlContent.Html
            
            # Calculate relative output path
            $relativePath = [System.IO.Path]::GetRelativePath($SourcePath, $mdFile.FullName)
            $htmlPath = Join-Path $OutputPath ([System.IO.Path]::ChangeExtension($relativePath, ".html"))
            
            # Create directory if needed
            $htmlDir = Split-Path $htmlPath -Parent
            if (-not (Test-Path $htmlDir)) {
                New-Item -Path $htmlDir -ItemType Directory -Force | Out-Null
            }
            
            # Write HTML file
            $fullHtml | Out-File -FilePath $htmlPath -Encoding UTF8
            $convertedFiles += $htmlPath
        }
        
        # Create navigation index
        New-HTMLNavigationIndex -OutputPath $OutputPath -Files $convertedFiles -Theme $Theme
        
        Write-DocLog "HTML export completed: $($convertedFiles.Count) files converted" -Level Info
        
        return @{
            Success = $true
            OutputPath = $OutputPath
            FilesConverted = $convertedFiles.Count
            Theme = $Theme
        }
    }
    catch {
        Write-DocLog "HTML export failed: $($_.Exception.Message)" -Level Error
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

function Get-HTMLTemplate {
    param([string]$Theme)
    
    switch ($Theme) {
        'bootstrap' {
            return @'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{0} - Enhanced Documentation System</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.3.1/styles/default.min.css" rel="stylesheet">
    <style>
        .sidebar {{ background-color: #f8f9fa; min-height: 100vh; }}
        .content {{ padding: 20px; }}
        pre code {{ background: #f8f9fa; padding: 10px; border-radius: 4px; }}
    </style>
</head>
<body>
    <div class="container-fluid">
        <div class="row">
            <div class="col-md-3 sidebar">
                <h5>Enhanced Documentation System</h5>
                <nav>
                    <a href="README.html" class="nav-link">Home</a>
                    <a href="guides/installation.html" class="nav-link">Installation</a>
                    <a href="guides/quick-start.html" class="nav-link">Quick Start</a>
                </nav>
            </div>
            <div class="col-md-9 content">
                {1}
            </div>
        </div>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.3.1/highlight.min.js"></script>
    <script>hljs.highlightAll();</script>
</body>
</html>
'@
        }
        default {
            return @'
<!DOCTYPE html>
<html>
<head>
    <title>{0}</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 20px; line-height: 1.6; }}
        h1, h2, h3 {{ color: #333; }}
        pre {{ background: #f4f4f4; padding: 10px; border-radius: 4px; }}
        code {{ background: #f4f4f4; padding: 2px 4px; border-radius: 3px; }}
    </style>
</head>
<body>
{1}
</body>
</html>
'@
        }
    }
}

#endregion

# Export module members
Export-ModuleMember -Function @(
    'Install-PlatyPS',
    'Initialize-DocumentationProject',
    'New-ModuleDocumentation',
    'New-ComprehensiveAPIDocs',
    'Export-HTMLDocumentation',
    'New-UserGuide',
    'Test-DocumentationCompleteness'
) -Alias @(
    'gendoc',
    'updatedoc', 
    'apidocs',
    'htmldoc',
    'userguide',
    'testdoc'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDqG0b5IFTZmzf4
# eQDD0M3nv4wPjZcibGqMiMzPE5aTkKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIHTPioxladrmY9Ime6dFiqNF
# NKchd3gQfIVfcf5vgsQVMA0GCSqGSIb3DQEBAQUABIIBAJNGQp0xraT5UrC/MVL7
# Nab73rYaDYq9MtuoN0yElBNfsidSdqJfXV07i6/DoCOTnl6MT8FTuGUw9PYNYRqj
# mxKPS3ZNWL30JUbwr4y9mXjh49ajD8fiMQRt+kIKZf8Gl6et2bwtKIAIpcmQ5em5
# 19n5B8j5e3A6kVQJj9kt6qJeshaW75HR/bkGehwlzC4+1YVfBl8Z1AdK99PTymj9
# 4p3paKpg75i0NZFna2oDeG1ACjijg+/6yED4FFNzeykdYY1KM/KazVFfQ8oIlH1P
# MruqVM4bn9q4lHnLdj7uvOlZNrCdtfpRSwTL1l63nkYbuAnkn7BCJ/YgwC//+XdL
# X/4=
# SIG # End signature block
