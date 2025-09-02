# Update-DocumentationForFile.ps1
# Updates documentation for a specific file when changes are detected
# Date: 2025-08-24

param(
    [Parameter(Mandatory)]
    [string]$FilePath,
    
    [string]$OutputPath = ".\docs\generated",
    
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# Ensure output directory exists
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

# Get file info
$file = Get-Item $FilePath
$extension = $file.Extension.ToLower()
$relativePath = $file.FullName.Replace("$PSScriptRoot\..\..\", "").Replace("\", "/")

Write-Host "[DOC-UPDATE] Processing: $relativePath" -ForegroundColor Yellow

# Determine documentation type based on file extension
$docType = switch ($extension) {
    ".ps1" { "PowerShell" }
    ".psm1" { "PowerShell" }
    ".psd1" { "PowerShell" }
    ".py" { "Python" }
    ".js" { "JavaScript" }
    ".ts" { "TypeScript" }
    ".md" { "Markdown" }
    default { "Unknown" }
}

if ($docType -eq "Unknown") {
    Write-Warning "Unsupported file type: $extension"
    return
}

# Generate documentation based on type
$outputFile = Join-Path $OutputPath ($file.BaseName + "_doc.md")

try {
    switch ($docType) {
        "PowerShell" {
            # Parse PowerShell AST
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($FilePath, [ref]$null, [ref]$null)
            
            $functions = $ast.FindAll({
                $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
            }, $true)
            
            $doc = @"
# Documentation: $relativePath

**Generated**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Type**: PowerShell Script/Module

## Overview
File: ``$($file.Name)``
Size: $([math]::Round($file.Length/1KB, 2)) KB
Last Modified: $($file.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss"))

## Functions ($($functions.Count))

"@
            
            foreach ($func in $functions) {
                $params = $func.Body.ParamBlock.Parameters | ForEach-Object { $_.Name.VariablePath.UserPath }
                $doc += @"

### $($func.Name)

**Parameters**: $($params -join ', ')

``````powershell
$($func.Extent.Text.Substring(0, [Math]::Min(500, $func.Extent.Text.Length)))
``````

"@
            }
        }
        
        "Python" {
            $content = Get-Content $FilePath -Raw
            $functions = [regex]::Matches($content, 'def\s+(\w+)\s*\([^)]*\):')
            $classes = [regex]::Matches($content, 'class\s+(\w+).*:')
            
            $doc = @"
# Documentation: $relativePath

**Generated**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Type**: Python Module

## Overview
File: ``$($file.Name)``
Size: $([math]::Round($file.Length/1KB, 2)) KB

## Classes ($($classes.Count))
$(($classes | ForEach-Object { "- $($_.Groups[1].Value)" }) -join "`n")

## Functions ($($functions.Count))
$(($functions | ForEach-Object { "- $($_.Groups[1].Value)" }) -join "`n")

"@
        }
        
        "JavaScript" {
            $content = Get-Content $FilePath -Raw
            $functions = [regex]::Matches($content, 'function\s+(\w+)|const\s+(\w+)\s*=\s*(?:async\s*)?\([^)]*\)\s*=>')
            
            $doc = @"
# Documentation: $relativePath

**Generated**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Type**: JavaScript Module

## Overview
File: ``$($file.Name)``

## Functions ($($functions.Count))
$(($functions | ForEach-Object { 
    if ($_.Groups[1].Value) { "- $($_.Groups[1].Value)" } 
    else { "- $($_.Groups[2].Value)" }
}) -join "`n")

"@
        }
        
        "TypeScript" {
            $content = Get-Content $FilePath -Raw
            $interfaces = [regex]::Matches($content, 'interface\s+(\w+)')
            $classes = [regex]::Matches($content, 'class\s+(\w+)')
            
            $doc = @"
# Documentation: $relativePath

**Generated**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Type**: TypeScript Module

## Overview
File: ``$($file.Name)``

## Interfaces ($($interfaces.Count))
$(($interfaces | ForEach-Object { "- $($_.Groups[1].Value)" }) -join "`n")

## Classes ($($classes.Count))
$(($classes | ForEach-Object { "- $($_.Groups[1].Value)" }) -join "`n")

"@
        }
    }
    
    # Add drift detection info if available
    if (Get-Command Test-DocumentationDrift -ErrorAction SilentlyContinue) {
        $drift = Test-DocumentationDrift -FilePath $FilePath
        if ($drift) {
            $doc += @"

## Documentation Drift Status
- **Has Drift**: $($drift.HasDrift)
- **Last Sync**: $($drift.LastSync)
- **Changes Since Sync**: $($drift.ChangeCount)

"@
        }
    }
    
    # Write documentation file
    $doc | Out-File -FilePath $outputFile -Encoding UTF8
    Write-Host "[DOC-UPDATE] Generated: $outputFile" -ForegroundColor Green
    
    # Update index if it exists
    $indexFile = Join-Path $OutputPath "index.md"
    if (Test-Path $indexFile) {
        $index = Get-Content $indexFile -Raw
        $linkText = "- [$relativePath]($($file.BaseName)_doc.md)"
        
        if ($index -notmatch [regex]::Escape($linkText)) {
            Add-Content -Path $indexFile -Value $linkText
            Write-Host "[DOC-UPDATE] Updated index" -ForegroundColor Green
        }
    }
    
} catch {
    Write-Error "Failed to generate documentation: $_"
}