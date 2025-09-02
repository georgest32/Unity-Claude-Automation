# Generate-DetailedDocumentation.ps1
# Fixed comprehensive documentation generator with actual content

param(
    [string]$OutputPath = ".\docs\generated",
    [switch]$IncludePrivate,
    [switch]$ExportHTML
)

# Ensure output directory exists
if (-not (Test-Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "DETAILED DOCUMENTATION GENERATION" -ForegroundColor Green
Write-Host "Generating actual documentation with function details..." -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Cyan

# Step 1: Scan all PowerShell modules
Write-Host "`n[1/4] Scanning PowerShell modules..." -ForegroundColor Green
$modulePath = ".\Modules"
$modules = Get-ChildItem -Path $modulePath -Filter "*.psm1" -Recurse

$allDocumentation = @()

foreach ($module in $modules) {
    Write-Host "  Documenting $($module.BaseName)..." -ForegroundColor Gray
    
    try {
        # Import the module
        Import-Module $module.FullName -Force -ErrorAction SilentlyContinue
        
        # Get module info
        $moduleInfo = Get-Module $module.BaseName
        
        # Get all functions from the module file content
        $content = Get-Content $module.FullName -Raw
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null)
        
        # Find all function definitions
        $functions = $ast.FindAll({
            $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
        }, $true)
        
        $functionDocs = @()
        foreach ($function in $functions) {
            # Skip private functions unless requested
            if (-not $IncludePrivate -and $function.Name -match '^_') {
                continue
            }
            
            # Extract function details
            $funcDoc = @{
                Name = $function.Name
                Parameters = @()
                Body = ""
                StartLine = $function.Extent.StartLineNumber
                EndLine = $function.Extent.EndLineNumber
            }
            
            # Get parameters
            if ($function.Parameters) {
                $funcDoc.Parameters = $function.Parameters | ForEach-Object {
                    @{
                        Name = $_.Name.VariablePath.UserPath
                        Type = if ($_.StaticType) { $_.StaticType.Name } else { "Object" }
                        DefaultValue = if ($_.DefaultValue) { $_.DefaultValue.Extent.Text } else { $null }
                    }
                }
            }
            
            # Get function body (first 10 lines for summary)
            $bodyLines = $function.Body.Extent.Text -split "`n" | Select-Object -First 10
            $funcDoc.Body = ($bodyLines -join "`n").Trim()
            
            # Try to get help documentation
            try {
                $help = Get-Help $function.Name -ErrorAction SilentlyContinue
                if ($help) {
                    $funcDoc.Synopsis = $help.Synopsis
                    $funcDoc.Description = $help.Description.Text
                    $funcDoc.Examples = $help.Examples
                }
            } catch {
                # No help available
            }
            
            $functionDocs += $funcDoc
        }
        
        # Create module documentation
        $moduleDoc = @{
            ModuleName = $module.BaseName
            FilePath = $module.FullName
            Version = if ($moduleInfo.Version) { $moduleInfo.Version.ToString() } else { "1.0.0" }
            Description = if ($moduleInfo.Description) { $moduleInfo.Description } else { "" }
            FunctionCount = $functionDocs.Count
            Functions = $functionDocs
            ExportedCommands = if ($moduleInfo) { @($moduleInfo.ExportedCommands.Keys) } else { @() }
            LastModified = $module.LastWriteTime
        }
        
        $allDocumentation += $moduleDoc
        
        # Generate individual module markdown
        $markdown = @"
# Module: $($module.BaseName)

**Version:** $($moduleDoc.Version)  
**Path:** ``$($module.FullName)``  
**Last Modified:** $($module.LastWriteTime)  
**Total Functions:** $($functionDocs.Count)  

## Description
$($moduleDoc.Description)

## Exported Commands
$(if ($moduleDoc.ExportedCommands) {
    $moduleDoc.ExportedCommands | ForEach-Object { "- ``$_``" } | Out-String
} else {
    "*No exported commands*"
})

## Functions

$(foreach ($func in $functionDocs) {
    @"

### $($func.Name)
**Lines:** $($func.StartLine) - $($func.EndLine)

$(if ($func.Synopsis) { "**Synopsis:** $($func.Synopsis)`n" })
$(if ($func.Description) { "**Description:** $($func.Description)`n" })

**Parameters:**
$(if ($func.Parameters.Count -gt 0) {
    $func.Parameters | ForEach-Object {
        "- ``$($_.Name)`` ($($_.Type))$(if ($_.DefaultValue) { " = $($_.DefaultValue)" })"
    } | Out-String
} else {
    "*No parameters*"
})

**Code Preview:**
``````powershell
$($func.Body)
``````
"@
})

---
*Generated by Unity-Claude Documentation System*
"@
        
        $markdown | Out-File "$OutputPath\$($module.BaseName)_detailed.md" -Encoding UTF8
        
    } catch {
        Write-Host "    Warning: Error documenting $($module.BaseName): $_" -ForegroundColor Yellow
    }
}

# Step 2: Generate master documentation
Write-Host "`n[2/4] Creating master documentation..." -ForegroundColor Green

$masterDoc = @{
    GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    TotalModules = $allDocumentation.Count
    TotalFunctions = ($allDocumentation | ForEach-Object { $_.FunctionCount } | Measure-Object -Sum).Sum
    Modules = $allDocumentation
}

$masterDoc | ConvertTo-Json -Depth 10 | Out-File "$OutputPath\Master-Documentation.json" -Encoding UTF8

# Step 3: Generate index markdown
Write-Host "`n[3/4] Creating documentation index..." -ForegroundColor Green

$indexMarkdown = @"
# Unity-Claude Automation - Complete Documentation

**Generated:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## System Overview

The Unity-Claude Automation system consists of **$($allDocumentation.Count) modules** containing **$(($allDocumentation | ForEach-Object { $_.FunctionCount } | Measure-Object -Sum).Sum) functions**.

## Module Index

| Module | Functions | Description | Documentation |
|--------|-----------|-------------|---------------|
$(foreach ($module in $allDocumentation | Sort-Object ModuleName) {
    "| **$($module.ModuleName)** | $($module.FunctionCount) | $(if ($module.Description) { $module.Description.Substring(0, [Math]::Min(50, $module.Description.Length)) + "..." } else { "*No description*" }) | [View](./$($module.ModuleName)_detailed.md) |"
})

## Quick Statistics

- **Total Modules:** $($allDocumentation.Count)
- **Total Functions:** $(($allDocumentation | ForEach-Object { $_.FunctionCount } | Measure-Object -Sum).Sum)
- **Total Exported Commands:** $(($allDocumentation | ForEach-Object { $_.ExportedCommands.Count } | Measure-Object -Sum).Sum)

## Module Details

$(foreach ($module in $allDocumentation | Sort-Object ModuleName) {
    @"

### $($module.ModuleName)
- **Functions:** $($module.FunctionCount)
- **Exported Commands:** $($module.ExportedCommands.Count)
- **Top Functions:**
$(if ($module.Functions.Count -gt 0) {
    $module.Functions | Select-Object -First 5 | ForEach-Object {
        "  - ``$($_.Name)``$(if ($_.Parameters.Count -gt 0) { " ($($_.Parameters.Count) parameters)" })"
    } | Out-String
} else {
    "  *No functions documented*"
})
"@
})

## Documentation Files

| File | Size | Description |
|------|------|-------------|
$(Get-ChildItem $OutputPath -Filter "*.md" | ForEach-Object {
    "| [$($_.Name)](./$($_.Name)) | $('{0:N1}' -f ($_.Length / 1KB)) KB | Module documentation |"
})

---
*Generated by Unity-Claude Enhanced Documentation System*
"@

$indexMarkdown | Out-File "$OutputPath\INDEX.md" -Encoding UTF8

# Step 4: Generate HTML if requested
if ($ExportHTML) {
    Write-Host "`n[4/4] Generating HTML documentation..." -ForegroundColor Green
    
    $htmlTemplate = @"
<!DOCTYPE html>
<html>
<head>
    <title>Unity-Claude Documentation</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 40px; background: #f5f5f5; }
        h1 { color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 10px; }
        h2 { color: #34495e; margin-top: 30px; }
        h3 { color: #7f8c8d; }
        table { border-collapse: collapse; width: 100%; margin: 20px 0; background: white; }
        th, td { border: 1px solid #ddd; padding: 12px; text-align: left; }
        th { background-color: #3498db; color: white; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        code { background: #ecf0f1; padding: 2px 6px; border-radius: 3px; }
        pre { background: #2c3e50; color: #ecf0f1; padding: 15px; border-radius: 5px; overflow-x: auto; }
        .module-card { background: white; padding: 20px; margin: 20px 0; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .stat { display: inline-block; padding: 10px 20px; margin: 10px; background: #3498db; color: white; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>Unity-Claude Automation Documentation</h1>
    <div>
        <span class="stat">Modules: $($allDocumentation.Count)</span>
        <span class="stat">Functions: $(($allDocumentation | ForEach-Object { $_.FunctionCount } | Measure-Object -Sum).Sum)</span>
        <span class="stat">Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</span>
    </div>
    
    <h2>Module Overview</h2>
    <table>
        <tr><th>Module</th><th>Functions</th><th>Exported Commands</th></tr>
        $(foreach ($module in $allDocumentation | Sort-Object ModuleName) {
            "<tr><td><strong>$($module.ModuleName)</strong></td><td>$($module.FunctionCount)</td><td>$($module.ExportedCommands.Count)</td></tr>"
        })
    </table>
    
    $(foreach ($module in $allDocumentation | Sort-Object ModuleName) {
        @"
    <div class="module-card">
        <h2>$($module.ModuleName)</h2>
        <p><strong>Path:</strong> <code>$($module.FilePath)</code></p>
        <p><strong>Functions:</strong> $($module.FunctionCount)</p>
        <h3>Function List</h3>
        <ul>
        $(foreach ($func in $module.Functions | Select-Object -First 10) {
            "<li><code>$($func.Name)</code>$(if ($func.Synopsis) { " - $($func.Synopsis)" })</li>"
        })
        </ul>
    </div>
"@
    })
</body>
</html>
"@
    
    $htmlTemplate | Out-File "$OutputPath\Documentation.html" -Encoding UTF8
    Write-Host "  HTML documentation generated" -ForegroundColor Green
}

# Display summary
Write-Host "`n" + "=" * 80 -ForegroundColor Cyan
Write-Host "DOCUMENTATION GENERATION COMPLETE!" -ForegroundColor Green
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "`nStatistics:" -ForegroundColor Yellow
Write-Host "  - Modules Documented: $($allDocumentation.Count)" -ForegroundColor White
Write-Host "  - Total Functions: $(($allDocumentation | ForEach-Object { $_.FunctionCount } | Measure-Object -Sum).Sum)" -ForegroundColor White
Write-Host "  - Output Location: $OutputPath" -ForegroundColor White

Write-Host "`nGenerated Files:" -ForegroundColor Yellow
Get-ChildItem $OutputPath -Filter "*.md" | Select-Object -First 10 | ForEach-Object {
    Write-Host "  - $($_.Name) ($('{0:N1}' -f ($_.Length / 1KB)) KB)" -ForegroundColor Gray
}

Write-Host "`n✅ Documentation with actual content generated successfully!" -ForegroundColor Green
Write-Host "📄 View the index at: $OutputPath\INDEX.md" -ForegroundColor Cyan