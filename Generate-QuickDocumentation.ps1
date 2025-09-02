# Generate-QuickDocumentation.ps1
# Fast documentation generator that analyzes code without importing modules

param(
    [string]$OutputPath = ".\docs\generated"
)

# Ensure output directory exists
if (-not (Test-Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "QUICK DOCUMENTATION GENERATION" -ForegroundColor Green
Write-Host "Analyzing code structure without module imports..." -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Cyan

# Get all PowerShell files
Write-Host "`n[1/3] Scanning PowerShell files..." -ForegroundColor Green
$psFiles = Get-ChildItem -Path "." -Filter "*.ps*1" -Recurse -ErrorAction SilentlyContinue | 
    Where-Object { $_.FullName -notmatch "\\(node_modules|\.git|temp|backup|test-results)\\" }

Write-Host "  Found $($psFiles.Count) PowerShell files" -ForegroundColor Gray

$allDocumentation = @()

foreach ($file in $psFiles) {
    Write-Host "  Analyzing $($file.Name)..." -ForegroundColor Gray -NoNewline
    
    try {
        $content = Get-Content $file.FullName -Raw -ErrorAction Stop
        
        # Parse the AST
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$tokens, [ref]$errors)
        
        # Find all functions
        $functions = $ast.FindAll({
            $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
        }, $true)
        
        if ($functions.Count -eq 0) {
            Write-Host " (no functions)" -ForegroundColor DarkGray
            continue
        }
        
        $functionDocs = @()
        foreach ($function in $functions) {
            $funcDoc = @{
                Name = $function.Name
                Parameters = @()
                LineCount = $function.Extent.EndLineNumber - $function.Extent.StartLineNumber
                StartLine = $function.Extent.StartLineNumber
            }
            
            # Get parameters
            if ($function.Parameters) {
                $funcDoc.Parameters = $function.Parameters | ForEach-Object {
                    $_.Name.VariablePath.UserPath
                }
            }
            
            # Look for comment-based help
            $helpPattern = '<#[\s\S]*?\.SYNOPSIS[\s\S]*?#>'
            if ($content -match $helpPattern) {
                $funcDoc.HasHelp = $true
            }
            
            $functionDocs += $funcDoc
        }
        
        # Create file documentation
        $fileDoc = @{
            FileName = $file.Name
            RelativePath = $file.FullName.Replace($PWD.Path, "").TrimStart("\")
            FileType = if ($file.Extension -eq ".psm1") { "Module" } 
                      elseif ($file.Extension -eq ".ps1") { "Script" } 
                      else { "Manifest" }
            Size = [math]::Round($file.Length / 1KB, 2)
            LastModified = $file.LastWriteTime
            FunctionCount = $functions.Count
            Functions = $functionDocs
            TotalLines = ($content -split "`n").Count
        }
        
        $allDocumentation += $fileDoc
        Write-Host " ($($functions.Count) functions)" -ForegroundColor Green
        
    } catch {
        Write-Host " (error)" -ForegroundColor Red
    }
}

# Step 2: Generate comprehensive markdown documentation
Write-Host "`n[2/3] Generating comprehensive documentation..." -ForegroundColor Green

# Group files by type
$modules = $allDocumentation | Where-Object { $_.FileType -eq "Module" }
$scripts = $allDocumentation | Where-Object { $_.FileType -eq "Script" }
$manifests = $allDocumentation | Where-Object { $_.FileType -eq "Manifest" }

# Generate master documentation
$masterMarkdown = @"
# Unity-Claude Automation - Complete Code Documentation

**Generated:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## System Overview

- **Total Files:** $($allDocumentation.Count)
- **Total Functions:** $(($allDocumentation | ForEach-Object { $_.FunctionCount } | Measure-Object -Sum).Sum)
- **Total Lines of Code:** $(($allDocumentation | ForEach-Object { $_.TotalLines } | Measure-Object -Sum).Sum)

## Quick Statistics

| Category | Count | Functions | Lines of Code |
|----------|-------|-----------|---------------|
| Modules | $($modules.Count) | $(($modules | ForEach-Object { $_.FunctionCount } | Measure-Object -Sum).Sum) | $(($modules | ForEach-Object { $_.TotalLines } | Measure-Object -Sum).Sum) |
| Scripts | $($scripts.Count) | $(($scripts | ForEach-Object { $_.FunctionCount } | Measure-Object -Sum).Sum) | $(($scripts | ForEach-Object { $_.TotalLines } | Measure-Object -Sum).Sum) |
| Manifests | $($manifests.Count) | 0 | $(($manifests | ForEach-Object { $_.TotalLines } | Measure-Object -Sum).Sum) |

## Modules ($($modules.Count))

| Module | Functions | Size (KB) | Key Functions |
|--------|-----------|-----------|---------------|
$(foreach ($module in $modules | Sort-Object FileName) {
    $topFuncs = ($module.Functions | Select-Object -First 3 | ForEach-Object { "``$($_.Name)``" }) -join ", "
    "| **$($module.FileName -replace '\.psm1$','')** | $($module.FunctionCount) | $($module.Size) | $topFuncs |"
})

## Scripts ($($scripts.Count))

| Script | Functions | Size (KB) | Purpose |
|--------|-----------|-----------|---------|
$(foreach ($script in $scripts | Sort-Object FileName | Select-Object -First 20) {
    $purpose = switch -Wildcard ($script.FileName) {
        "Test-*" { "Testing/Validation" }
        "Start-*" { "Initialization" }
        "Deploy-*" { "Deployment" }
        "Generate-*" { "Generation" }
        "Build-*" { "Build Process" }
        default { "Automation" }
    }
    "| $($script.FileName) | $($script.FunctionCount) | $($script.Size) | $purpose |"
})

## Module Details

$(foreach ($module in $modules | Sort-Object FileName) {
    @"

### $($module.FileName -replace '\.psm1$','')

- **Path:** ``$($module.RelativePath)``
- **Size:** $($module.Size) KB
- **Functions:** $($module.FunctionCount)
- **Lines:** $($module.TotalLines)
- **Last Modified:** $($module.LastModified)

**Functions:**
$(foreach ($func in $module.Functions | Sort-Object Name) {
    "- ``$($func.Name)`` (Line $($func.StartLine), $($func.LineCount) lines$(if ($func.Parameters.Count -gt 0) { ", $($func.Parameters.Count) params" }))"
})
"@
})

## Function Index

Total Functions: $(($allDocumentation | ForEach-Object { $_.FunctionCount } | Measure-Object -Sum).Sum)

### Top 50 Functions by Size

| Function | Module/Script | Lines | Parameters |
|----------|--------------|-------|------------|
$(foreach ($item in ($allDocumentation | ForEach-Object {
    $file = $_
    $_.Functions | ForEach-Object {
        [PSCustomObject]@{
            Function = $_.Name
            File = $file.FileName
            Lines = $_.LineCount
            Params = $_.Parameters.Count
        }
    }
} | Sort-Object Lines -Descending | Select-Object -First 50)) {
    "| ``$($item.Function)`` | $($item.File) | $($item.Lines) | $($item.Params) |"
})

---
*Generated by Unity-Claude Documentation System*
"@

$masterMarkdown | Out-File "$OutputPath\MASTER_DOCUMENTATION.md" -Encoding UTF8

# Step 3: Generate individual module documentation
Write-Host "`n[3/3] Generating individual module documentation..." -ForegroundColor Green

foreach ($module in $modules) {
    $moduleMarkdown = @"
# $($module.FileName -replace '\.psm1$','')

**Type:** PowerShell Module  
**Path:** ``$($module.RelativePath)``  
**Size:** $($module.Size) KB  
**Last Modified:** $($module.LastModified)  

## Statistics

- **Total Functions:** $($module.FunctionCount)
- **Total Lines:** $($module.TotalLines)
- **Average Function Size:** $([math]::Round(($module.Functions | ForEach-Object { $_.LineCount } | Measure-Object -Average).Average, 1)) lines

## Functions

$(foreach ($func in $module.Functions | Sort-Object Name) {
    @"

### $($func.Name)

- **Location:** Line $($func.StartLine)
- **Size:** $($func.LineCount) lines
$(if ($func.Parameters.Count -gt 0) {
    "- **Parameters:** $($func.Parameters -join ', ')"
})
$(if ($func.HasHelp) {
    "- ✅ **Has Help Documentation**"
})
"@
})

---
*Generated on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")*
"@
    
    $moduleMarkdown | Out-File "$OutputPath\$($module.FileName -replace '\.psm1$','')_complete.md" -Encoding UTF8
}

# Create HTML summary
$htmlSummary = @"
<!DOCTYPE html>
<html>
<head>
    <title>Unity-Claude Documentation</title>
    <style>
        body { 
            font-family: 'Segoe UI', sans-serif; 
            margin: 40px; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        .container {
            background: white;
            color: #333;
            padding: 30px;
            border-radius: 15px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
        }
        h1 { 
            color: #764ba2; 
            border-bottom: 3px solid #667eea; 
            padding-bottom: 10px; 
        }
        .stat-card {
            display: inline-block;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            margin: 10px;
            border-radius: 10px;
            min-width: 150px;
            text-align: center;
        }
        .stat-number {
            font-size: 2em;
            font-weight: bold;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        th {
            background: #667eea;
            color: white;
            padding: 10px;
            text-align: left;
        }
        td {
            padding: 8px;
            border-bottom: 1px solid #ddd;
        }
        tr:hover {
            background: #f5f5f5;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Unity-Claude Automation Documentation</h1>
        
        <div>
            <div class="stat-card">
                <div class="stat-number">$($allDocumentation.Count)</div>
                <div>Files</div>
            </div>
            <div class="stat-card">
                <div class="stat-number">$(($allDocumentation | ForEach-Object { $_.FunctionCount } | Measure-Object -Sum).Sum)</div>
                <div>Functions</div>
            </div>
            <div class="stat-card">
                <div class="stat-number">$('{0:N0}' -f (($allDocumentation | ForEach-Object { $_.TotalLines } | Measure-Object -Sum).Sum))</div>
                <div>Lines of Code</div>
            </div>
        </div>
        
        <h2>Modules</h2>
        <table>
            <tr><th>Module</th><th>Functions</th><th>Lines</th><th>Size (KB)</th></tr>
            $(foreach ($module in $modules | Sort-Object FunctionCount -Descending | Select-Object -First 20) {
                "<tr><td><strong>$($module.FileName -replace '\.psm1$','')</strong></td><td>$($module.FunctionCount)</td><td>$($module.TotalLines)</td><td>$($module.Size)</td></tr>"
            })
        </table>
        
        <p><em>Generated on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</em></p>
    </div>
</body>
</html>
"@

$htmlSummary | Out-File "$OutputPath\Documentation_Summary.html" -Encoding UTF8

# Display summary
Write-Host "`n" + "=" * 80 -ForegroundColor Cyan
Write-Host "DOCUMENTATION GENERATION COMPLETE!" -ForegroundColor Green
Write-Host "=" * 80 -ForegroundColor Cyan

Write-Host "`nStatistics:" -ForegroundColor Yellow
Write-Host "  Files Analyzed: $($allDocumentation.Count)" -ForegroundColor White
Write-Host "  Total Functions: $(($allDocumentation | ForEach-Object { $_.FunctionCount } | Measure-Object -Sum).Sum)" -ForegroundColor White
Write-Host "  Total Lines: $(($allDocumentation | ForEach-Object { $_.TotalLines } | Measure-Object -Sum).Sum)" -ForegroundColor White

Write-Host "`nGenerated Files:" -ForegroundColor Yellow
Write-Host "  - MASTER_DOCUMENTATION.md (Complete system overview)" -ForegroundColor Cyan
Write-Host "  - Documentation_Summary.html (Visual summary)" -ForegroundColor Cyan
Write-Host "  - $($modules.Count) individual module documentation files" -ForegroundColor Gray

Write-Host "`n✅ Documentation successfully generated with full content!" -ForegroundColor Green
Write-Host "📄 Main documentation: $OutputPath\MASTER_DOCUMENTATION.md" -ForegroundColor Cyan
Write-Host "🌐 HTML summary: $OutputPath\Documentation_Summary.html" -ForegroundColor Cyan