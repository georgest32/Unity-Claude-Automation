# Generate-ModuleDocumentation.ps1
# Efficient documentation generator for Unity-Claude modules
# Date: 2025-08-24

param(
    [string]$ModulePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules",
    [string]$OutputPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\docs\generated",
    [string[]]$SpecificModules = @(),
    [switch]$QuickMode = $true,
    [switch]$GenerateIndex = $true
)

$ErrorActionPreference = "Continue"

Write-Host "=================================" -ForegroundColor Cyan
Write-Host "Module Documentation Generator" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# Ensure output directory exists
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    Write-Host "[CREATED] Output directory: $OutputPath" -ForegroundColor Green
}

# Get modules to document
$modules = if ($SpecificModules.Count -gt 0) {
    $SpecificModules | ForEach-Object {
        Get-ChildItem -Path $ModulePath -Directory -Filter $_
    }
} else {
    Get-ChildItem -Path $ModulePath -Directory | Where-Object {
        Test-Path (Join-Path $_.FullName "$($_.Name).psd1")
    }
}

Write-Host "`nFound $($modules.Count) modules to document" -ForegroundColor Yellow

# Initialize index
$indexContent = @"
# Unity-Claude-Automation Documentation

**Generated**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Modules**: $($modules.Count)

## Module Index

"@

$allFunctions = @()
$allClasses = @()
$moduleCount = 0

foreach ($module in $modules) {
    $moduleCount++
    Write-Host "`n[$moduleCount/$($modules.Count)] Processing: $($module.Name)" -ForegroundColor Cyan
    
    $manifestPath = Join-Path $module.FullName "$($module.Name).psd1"
    $modulePath = Join-Path $module.FullName "$($module.Name).psm1"
    
    # Generate module documentation
    $moduleDoc = @"
# Module: $($module.Name)

**Generated**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Path**: $($module.FullName)

## Overview

"@
    
    # Load manifest if available
    if (Test-Path $manifestPath) {
        try {
            $manifest = Import-PowerShellDataFile -Path $manifestPath
            
            $moduleDoc += @"
**Version**: $($manifest.ModuleVersion -or "1.0.0")
**Description**: $($manifest.Description -or "No description available")
**Author**: $($manifest.Author -or "Unknown")
**Company**: $($manifest.CompanyName -or "Unity-Claude-Automation")

### Exported Functions
"@
            
            if ($manifest.FunctionsToExport -and $manifest.FunctionsToExport -ne '*') {
                $exportedFunctions = $manifest.FunctionsToExport
                $moduleDoc += "`n" + ($exportedFunctions | ForEach-Object { "- $_" }) -join "`n"
            }
            
        } catch {
            Write-Warning "Could not load manifest for $($module.Name): $_"
        }
    }
    
    # Parse module file for functions
    if (Test-Path $modulePath) {
        try {
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($modulePath, [ref]$null, [ref]$null)
            
            $functions = $ast.FindAll({
                $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
            }, $true)
            
            if ($functions.Count -gt 0) {
                $moduleDoc += @"

## Functions ($($functions.Count))

"@
                
                foreach ($func in $functions) {
                    $funcName = $func.Name
                    $allFunctions += [PSCustomObject]@{
                        Module = $module.Name
                        Function = $funcName
                        File = "$($module.Name)_doc.md"
                    }
                    
                    # Get parameters
                    $params = @()
                    if ($func.Body.ParamBlock) {
                        $params = $func.Body.ParamBlock.Parameters | ForEach-Object {
                            $_.Name.VariablePath.UserPath
                        }
                    }
                    
                    # Get comment-based help if available
                    $helpText = ""
                    $comments = $ast.FindAll({
                        $args[0] -is [System.Management.Automation.Language.CommentAst]
                    }, $true)
                    
                    foreach ($comment in $comments) {
                        if ($comment.Extent.Text -match "\.SYNOPSIS|\.DESCRIPTION") {
                            $helpText = $comment.Extent.Text
                            break
                        }
                    }
                    
                    $moduleDoc += @"

### $funcName

**Parameters**: $(if ($params) { $params -join ', ' } else { 'None' })

"@
                    
                    if ($helpText) {
                        $moduleDoc += @"
**Help**:
``````
$helpText
``````

"@
                    }
                    
                    # Add first 200 chars of function for context (in QuickMode)
                    if ($QuickMode) {
                        $funcSnippet = $func.Extent.Text.Substring(0, [Math]::Min(200, $func.Extent.Text.Length))
                        $moduleDoc += @"
**Signature**:
``````powershell
$funcSnippet...
``````

"@
                    }
                }
            }
            
        } catch {
            Write-Warning "Could not parse module file for $($module.Name): $_"
        }
    }
    
    # Check for additional module files
    $additionalFiles = Get-ChildItem -Path $module.FullName -Filter "*.ps1" -Recurse | 
        Where-Object { $_.Name -ne "$($module.Name).ps1" }
    
    if ($additionalFiles.Count -gt 0) {
        $moduleDoc += @"

## Additional Files ($($additionalFiles.Count))

"@
        $additionalFiles | ForEach-Object {
            $relativePath = $_.FullName.Replace($module.FullName, "").TrimStart("\")
            $moduleDoc += "- $relativePath`n"
        }
    }
    
    # Write module documentation
    $outputFile = Join-Path $OutputPath "$($module.Name)_doc.md"
    $moduleDoc | Out-File -FilePath $outputFile -Encoding UTF8
    Write-Host "  [OK] Generated: $outputFile" -ForegroundColor Green
    
    # Add to index
    $indexContent += "- [$($module.Name)]($($module.Name)_doc.md) - $($functions.Count) functions`n"
}

# Generate cross-reference index
if ($GenerateIndex) {
    Write-Host "`nGenerating cross-reference index..." -ForegroundColor Yellow
    
    $indexContent += @"

## Function Index

| Function | Module | Documentation |
|----------|--------|---------------|
"@
    
    $allFunctions | Sort-Object Function | ForEach-Object {
        $indexContent += "| $($_.Function) | $($_.Module) | [$($_.Module)]($($_.File)) |`n"
    }
    
    # Generate quick search index
    $searchIndex = @{
        Generated = Get-Date
        Modules = $modules.Name
        Functions = $allFunctions | Select-Object -ExpandProperty Function | Sort-Object -Unique
        TotalFunctions = $allFunctions.Count
        TotalModules = $modules.Count
    }
    
    $searchIndexPath = Join-Path $OutputPath "search_index.json"
    $searchIndex | ConvertTo-Json -Depth 3 | Out-File -FilePath $searchIndexPath -Encoding UTF8
    Write-Host "  [OK] Generated search index: $searchIndexPath" -ForegroundColor Green
}

# Write main index
$indexPath = Join-Path $OutputPath "index.md"
$indexContent | Out-File -FilePath $indexPath -Encoding UTF8
Write-Host "  [OK] Generated index: $indexPath" -ForegroundColor Green

# Summary
Write-Host "`n=================================" -ForegroundColor Cyan
Write-Host "Documentation Generation Complete" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Cyan
Write-Host "Modules documented: $($modules.Count)" -ForegroundColor Yellow
Write-Host "Functions documented: $($allFunctions.Count)" -ForegroundColor Yellow
Write-Host "Output location: $OutputPath" -ForegroundColor Yellow

# Return summary
return @{
    Success = $true
    ModulesProcessed = $modules.Count
    FunctionsDocumented = $allFunctions.Count
    OutputPath = $OutputPath
    IndexFile = $indexPath
}