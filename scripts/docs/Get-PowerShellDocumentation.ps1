#Requires -Version 5.1
<#
.SYNOPSIS
    Extracts documentation from PowerShell scripts and modules.

.DESCRIPTION
    Parses PowerShell files to extract comment-based help, function signatures,
    and generates structured documentation in JSON and Markdown formats.

.PARAMETER Path
    Path to PowerShell file or directory to analyze

.PARAMETER OutputFormat
    Output format: JSON, Markdown, or Both (default)

.PARAMETER Recurse
    Recursively process directories

.EXAMPLE
    Get-PowerShellDocumentation -Path .\Modules -OutputFormat Both -Recurse
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    
    [ValidateSet('JSON', 'Markdown', 'Both')]
    [string]$OutputFormat = 'Both',
    
    [switch]$Recurse
)

function Extract-CommentBasedHelp {
    param([string]$Content)
    
    $helpPattern = '(?ms)<#\s*\n(.*?)\n#>'
    $matches = [regex]::Matches($Content, $helpPattern)
    
    $helpData = @{}
    
    foreach ($match in $matches) {
        $helpText = $match.Groups[1].Value
        
        # Extract sections
        if ($helpText -match '\.SYNOPSIS\s*\n\s*(.+?)(?=\n\.|$)') {
            $helpData.Synopsis = $Matches[1].Trim()
        }
        
        if ($helpText -match '\.DESCRIPTION\s*\n\s*(.+?)(?=\n\.|$)') {
            $helpData.Description = $Matches[1].Trim()
        }
        
        if ($helpText -match '\.PARAMETER\s+(\w+)\s*\n\s*(.+?)(?=\n\.|$)') {
            if (-not $helpData.Parameters) {
                $helpData.Parameters = @{}
            }
            $helpData.Parameters[$Matches[1]] = $Matches[2].Trim()
        }
        
        if ($helpText -match '\.EXAMPLE\s*\n\s*(.+?)(?=\n\.|$)') {
            if (-not $helpData.Examples) {
                $helpData.Examples = @()
            }
            $helpData.Examples += $Matches[1].Trim()
        }
    }
    
    return $helpData
}

function Extract-FunctionInfo {
    param([string]$FilePath)
    
    Write-Host "Analyzing: $FilePath"
    
    $content = Get-Content -Path $FilePath -Raw
    $functions = @()
    
    # Parse using AST
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $FilePath,
        [ref]$null,
        [ref]$null
    )
    
    # Find all function definitions
    $functionAsts = $ast.FindAll({
        $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
    }, $true)
    
    foreach ($funcAst in $functionAsts) {
        $funcInfo = @{
            Name = $funcAst.Name
            Parameters = @()
            StartLine = $funcAst.Extent.StartLineNumber
            EndLine = $funcAst.Extent.EndLineNumber
            FilePath = $FilePath
            Help = @{}
        }
        
        # Extract parameters
        if ($funcAst.Parameters) {
            foreach ($param in $funcAst.Parameters) {
                $paramInfo = @{
                    Name = $param.Name.VariablePath.UserPath
                    Type = if ($param.StaticType) { $param.StaticType.Name } else { 'object' }
                    DefaultValue = if ($param.DefaultValue) { $param.DefaultValue.ToString() } else { $null }
                }
                $funcInfo.Parameters += $paramInfo
            }
        }
        
        # Extract help for this function
        $funcContent = $funcAst.Extent.Text
        $funcInfo.Help = Extract-CommentBasedHelp -Content $funcContent
        
        $functions += $funcInfo
    }
    
    return $functions
}

function Extract-ModuleInfo {
    param([string]$ManifestPath)
    
    $moduleInfo = @{
        ManifestPath = $ManifestPath
        ModuleName = [System.IO.Path]::GetFileNameWithoutExtension($ManifestPath)
    }
    
    if (Test-Path $ManifestPath) {
        $manifest = Import-PowerShellDataFile -Path $ManifestPath
        
        $moduleInfo.Version = $manifest.ModuleVersion
        $moduleInfo.Author = $manifest.Author
        $moduleInfo.Description = $manifest.Description
        $moduleInfo.RequiredModules = $manifest.RequiredModules
        $moduleInfo.FunctionsToExport = $manifest.FunctionsToExport
        $moduleInfo.CmdletsToExport = $manifest.CmdletsToExport
        $moduleInfo.VariablesToExport = $manifest.VariablesToExport
        $moduleInfo.AliasesToExport = $manifest.AliasesToExport
    }
    
    return $moduleInfo
}

function ConvertTo-MarkdownDoc {
    param($Documentation)
    
    $markdown = @()
    $markdown += "# PowerShell Documentation"
    $markdown += ""
    $markdown += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $markdown += ""
    
    # Modules section
    if ($Documentation.Modules -and $Documentation.Modules.Count -gt 0) {
        $markdown += "## Modules"
        $markdown += ""
        
        foreach ($module in $Documentation.Modules) {
            $markdown += "### $($module.ModuleName)"
            $markdown += ""
            
            if ($module.Description) {
                $markdown += $module.Description
                $markdown += ""
            }
            
            if ($module.Version) {
                $markdown += "**Version:** $($module.Version)"
                $markdown += ""
            }
            
            if ($module.Author) {
                $markdown += "**Author:** $($module.Author)"
                $markdown += ""
            }
            
            if ($module.FunctionsToExport -and $module.FunctionsToExport.Count -gt 0) {
                $markdown += "**Exported Functions:**"
                foreach ($func in $module.FunctionsToExport) {
                    $markdown += "- $func"
                }
                $markdown += ""
            }
        }
    }
    
    # Functions section
    if ($Documentation.Functions -and $Documentation.Functions.Count -gt 0) {
        $markdown += "## Functions"
        $markdown += ""
        
        foreach ($func in $Documentation.Functions) {
            $markdown += "### $($func.Name)"
            $markdown += ""
            
            if ($func.Help.Synopsis) {
                $markdown += "**Synopsis:** $($func.Help.Synopsis)"
                $markdown += ""
            }
            
            if ($func.Help.Description) {
                $markdown += "**Description:**"
                $markdown += ""
                $markdown += $func.Help.Description
                $markdown += ""
            }
            
            if ($func.Parameters -and $func.Parameters.Count -gt 0) {
                $markdown += "**Parameters:**"
                $markdown += ""
                
                foreach ($param in $func.Parameters) {
                    $markdown += "- **$($param.Name)** [$($param.Type)]"
                    if ($param.DefaultValue) {
                        $markdown += "  - Default: $($param.DefaultValue)"
                    }
                    if ($func.Help.Parameters -and $func.Help.Parameters[$param.Name]) {
                        $markdown += "  - $($func.Help.Parameters[$param.Name])"
                    }
                }
                $markdown += ""
            }
            
            if ($func.Help.Examples -and $func.Help.Examples.Count -gt 0) {
                $markdown += "**Examples:**"
                $markdown += ""
                
                foreach ($example in $func.Help.Examples) {
                    $markdown += '```powershell'
                    $markdown += $example
                    $markdown += '```'
                    $markdown += ""
                }
            }
            
            $markdown += "**Source:** $($func.FilePath):$($func.StartLine)"
            $markdown += ""
            $markdown += "---"
            $markdown += ""
        }
    }
    
    return $markdown -join "`n"
}

# Main execution
Write-Host "PowerShell Documentation Extractor"
Write-Host "===================================="
Write-Host ""

$documentation = @{
    GeneratedAt = Get-Date
    Path = $Path
    Modules = @()
    Functions = @()
    Files = @()
}

# Determine files to process
$files = @()

if (Test-Path -Path $Path -PathType Container) {
    # Directory
    if ($Recurse) {
        $files = @(Get-ChildItem -Path $Path -Filter '*.ps1' -Recurse -File)
        $files += @(Get-ChildItem -Path $Path -Filter '*.psm1' -Recurse -File)
        $files += @(Get-ChildItem -Path $Path -Filter '*.psd1' -Recurse -File)
    } else {
        $files = @(Get-ChildItem -Path $Path -Filter '*.ps1' -File)
        $files += @(Get-ChildItem -Path $Path -Filter '*.psm1' -File)
        $files += @(Get-ChildItem -Path $Path -Filter '*.psd1' -File)
    }
} else {
    # Single file
    $files = @(Get-Item -Path $Path)
}

Write-Host "Found $($files.Count) files to process"
Write-Host ""

# Process files
foreach ($file in $files) {
    $documentation.Files += $file.FullName
    
    if ($file.Extension -eq '.psd1') {
        # Module manifest
        $moduleInfo = Extract-ModuleInfo -ManifestPath $file.FullName
        $documentation.Modules += $moduleInfo
    } elseif ($file.Extension -in '.ps1', '.psm1') {
        # Script or module file
        $functions = Extract-FunctionInfo -FilePath $file.FullName
        $documentation.Functions += $functions
    }
}

# Output results
$outputPath = Join-Path -Path (Get-Location) -ChildPath "PowerShellDocs_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

if ($OutputFormat -in 'JSON', 'Both') {
    $jsonPath = "$outputPath.json"
    $documentation | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonPath -Encoding UTF8
    Write-Host "JSON documentation saved to: $jsonPath"
}

if ($OutputFormat -in 'Markdown', 'Both') {
    $mdPath = "$outputPath.md"
    $markdown = ConvertTo-MarkdownDoc -Documentation $documentation
    $markdown | Out-File -FilePath $mdPath -Encoding UTF8
    Write-Host "Markdown documentation saved to: $mdPath"
}

Write-Host ""
Write-Host "Documentation extraction complete!"
Write-Host "Processed $($documentation.Modules.Count) modules and $($documentation.Functions.Count) functions"

# Return documentation object
return $documentation