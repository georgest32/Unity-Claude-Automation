#Requires -Version 5.1
<#
.SYNOPSIS
    Generates unified documentation from multiple language sources.

.DESCRIPTION
    Combines documentation from PowerShell, Python, JavaScript/TypeScript
    and other sources into a unified format. Creates cross-referenced
    documentation with index and search capabilities.

.PARAMETER ProjectPath
    Root path of the project to document

.PARAMETER OutputPath
    Output directory for generated documentation

.PARAMETER IncludeLanguages
    Languages to include in documentation (default: all detected)

.PARAMETER GenerateIndex
    Generate searchable index of all documentation

.EXAMPLE
    New-UnifiedDocumentation -ProjectPath . -OutputPath .\docs\api -GenerateIndex
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,
    
    [string]$OutputPath = ".\docs\api",
    
    [string[]]$IncludeLanguages = @('PowerShell', 'Python', 'JavaScript', 'TypeScript', 'CSharp'),
    
    [switch]$GenerateIndex,
    
    [switch]$GenerateHTML
)

# Initialize documentation structure
$unifiedDocs = @{
    GeneratedAt = Get-Date
    ProjectPath = $ProjectPath
    Version = "1.0.0"
    Languages = @{}
    CrossReferences = @{}
    Index = @{
        Functions = @{}
        Classes = @{}
        Modules = @{}
        Files = @{}
    }
    Statistics = @{
        TotalFiles = 0
        TotalFunctions = 0
        TotalClasses = 0
        TotalModules = 0
        TotalLines = 0
    }
}

function Write-VerboseLog {
    param([string]$Message)
    if ($VerbosePreference -ne 'SilentlyContinue') {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Message" -ForegroundColor Cyan
    }
}

function Get-FileStatistics {
    param([string]$FilePath)
    
    if (Test-Path $FilePath) {
        $lines = (Get-Content $FilePath | Measure-Object -Line).Lines
        return @{
            Lines = $lines
            Size = (Get-Item $FilePath).Length
            LastModified = (Get-Item $FilePath).LastWriteTime
        }
    }
    return @{ Lines = 0; Size = 0; LastModified = $null }
}

function Extract-PowerShellDocs {
    param([string]$Path)
    
    Write-VerboseLog "Extracting PowerShell documentation from $Path"
    
    $psDocsScript = Join-Path $PSScriptRoot "Get-PowerShellDocumentation.ps1"
    
    if (Test-Path $psDocsScript) {
        $tempFile = [System.IO.Path]::GetTempFileName()
        & $psDocsScript -Path $Path -OutputFormat JSON -Recurse | Out-Null
        
        # Find the generated JSON file
        $jsonFiles = Get-ChildItem -Path . -Filter "PowerShellDocs_*.json" | 
                     Sort-Object LastWriteTime -Descending | 
                     Select-Object -First 1
        
        if ($jsonFiles) {
            $docs = Get-Content $jsonFiles.FullName | ConvertFrom-Json
            Remove-Item $jsonFiles.FullName -Force
            return $docs
        }
    }
    
    return $null
}

function Extract-PythonDocs {
    param([string]$Path)
    
    Write-VerboseLog "Extracting Python documentation from $Path"
    
    $pyScript = Join-Path $PSScriptRoot "extract_python_docs.py"
    
    if ((Test-Path $pyScript) -and (Get-Command python -ErrorAction SilentlyContinue)) {
        $tempDir = [System.IO.Path]::GetTempPath()
        $result = python $pyScript $Path --output-format json --recursive --output-dir $tempDir 2>&1
        
        # Find the generated JSON file
        $jsonFiles = Get-ChildItem -Path $tempDir -Filter "python_docs_*.json" | 
                     Sort-Object LastWriteTime -Descending | 
                     Select-Object -First 1
        
        if ($jsonFiles) {
            $docs = Get-Content $jsonFiles.FullName | ConvertFrom-Json
            Remove-Item $jsonFiles.FullName -Force
            return $docs
        }
    }
    
    return $null
}

function Extract-CSharpDocs {
    param([string]$Path)
    
    Write-VerboseLog "Extracting C# documentation from $Path"
    
    $csDocsScript = Join-Path $PSScriptRoot "Get-CSharpDocumentation.ps1"
    
    if (Test-Path $csDocsScript) {
        $tempFile = [System.IO.Path]::GetTempFileName()
        & $csDocsScript -Path $Path -OutputFormat JSON -Recurse | Out-Null
        
        # Find the generated JSON file
        $jsonFiles = Get-ChildItem -Path . -Filter "CSharpDocs_*.json" | 
                     Sort-Object LastWriteTime -Descending | 
                     Select-Object -First 1
        
        if ($jsonFiles) {
            $docs = Get-Content $jsonFiles.FullName | ConvertFrom-Json
            Remove-Item $jsonFiles.FullName -Force
            return $docs
        }
    }
    
    return $null
}

function Extract-JavaScriptDocs {
    param([string]$Path)
    
    Write-VerboseLog "Extracting JavaScript/TypeScript documentation from $Path"
    
    # Basic JavaScript/TypeScript parsing using regex
    $docs = @{
        files = @()
        functions = @()
        classes = @()
    }
    
    # Get JavaScript/TypeScript files, excluding common directories that cause issues
    $jsFiles = Get-ChildItem -Path $Path -Include '*.js', '*.ts', '*.jsx', '*.tsx' -Recurse -ErrorAction SilentlyContinue | 
               Where-Object { 
                   $_.FullName -notmatch '[\\/](\.venv|venv|node_modules|\.git|__pycache__|dist|build|out)[\\/]' -and
                   -not $_.Attributes.HasFlag([System.IO.FileAttributes]::ReparsePoint)
               }
    
    foreach ($file in $jsFiles) {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $content) { continue }
        $fileInfo = @{
            path = $file.FullName
            language = if ($file.Extension -match 'ts') { 'TypeScript' } else { 'JavaScript' }
        }
        
        # Extract functions
        $functionPattern = '(?:export\s+)?(?:async\s+)?function\s+(\w+)\s*\([^)]*\)'
        $matches = [regex]::Matches($content, $functionPattern)
        
        foreach ($match in $matches) {
            $docs.functions += @{
                name = $match.Groups[1].Value
                file = $file.FullName
                language = $fileInfo.language
            }
        }
        
        # Extract classes
        $classPattern = '(?:export\s+)?class\s+(\w+)'
        $matches = [regex]::Matches($content, $classPattern)
        
        foreach ($match in $matches) {
            $docs.classes += @{
                name = $match.Groups[1].Value
                file = $file.FullName
                language = $fileInfo.language
            }
        }
        
        $docs.files += $fileInfo
    }
    
    return $docs
}

function Generate-CrossReferences {
    param($UnifiedDocs)
    
    Write-VerboseLog "Generating cross-references"
    
    $crossRefs = @{}
    
    # Build function cross-references
    foreach ($lang in $UnifiedDocs.Languages.Keys) {
        $langDocs = $UnifiedDocs.Languages[$lang]
        
        if ($langDocs.Functions) {
            foreach ($func in $langDocs.Functions) {
                $funcName = if ($func.Name) { $func.Name } else { $func.name }
                
                if (-not $crossRefs[$funcName]) {
                    $crossRefs[$funcName] = @{
                        Type = 'Function'
                        Occurrences = @()
                    }
                }
                
                $crossRefs[$funcName].Occurrences += @{
                    Language = $lang
                    File = if ($func.FilePath) { $func.FilePath } else { $func.file_path }
                    Line = if ($func.StartLine) { $func.StartLine } else { $func.line_number }
                }
            }
        }
        
        # Handle C# classes with methods
        if ($lang -eq 'CSharp' -and $langDocs.Classes) {
            foreach ($class in $langDocs.Classes) {
                if ($class.Methods) {
                    foreach ($method in $class.Methods) {
                        $methodName = "$($class.Name).$($method.Name)"
                        
                        if (-not $crossRefs[$methodName]) {
                            $crossRefs[$methodName] = @{
                                Type = 'Method'
                                Class = $class.Name
                                Occurrences = @()
                            }
                        }
                        
                        $crossRefs[$methodName].Occurrences += @{
                            Language = $lang
                            File = $class.FilePath
                            Line = $method.LineNumber
                        }
                    }
                }
            }
        }
    }
    
    return $crossRefs
}

function Generate-DocumentationIndex {
    param($UnifiedDocs)
    
    Write-VerboseLog "Generating documentation index"
    
    $index = @{
        AllItems = @()
        ByType = @{
            Functions = @()
            Classes = @()
            Modules = @()
        }
        ByLanguage = @{}
        SearchIndex = @{}
    }
    
    foreach ($lang in $UnifiedDocs.Languages.Keys) {
        $index.ByLanguage[$lang] = @()
        $langDocs = $UnifiedDocs.Languages[$lang]
        
        # Index functions
        if ($langDocs.Functions) {
            foreach ($func in $langDocs.Functions) {
                $item = @{
                    Name = if ($func.Name) { $func.Name } else { $func.name }
                    Type = 'Function'
                    Language = $lang
                    File = if ($func.FilePath) { $func.FilePath } else { $func.file_path }
                    Description = if ($func.Help.Synopsis) { $func.Help.Synopsis } 
                                 elseif ($func.docstring) { ($func.docstring -split '\n')[0] }
                                 else { "" }
                }
                
                $index.AllItems += $item
                $index.ByType.Functions += $item
                $index.ByLanguage[$lang] += $item
                
                # Add to search index
                $searchKey = "$($item.Name) $($item.Type) $($item.Language)".ToLower()
                $index.SearchIndex[$searchKey] = $item
            }
        }
        
        # Index classes
        if ($langDocs.Classes -or $langDocs.classes) {
            $classes = if ($langDocs.Classes) { $langDocs.Classes } else { $langDocs.classes }
            foreach ($class in $classes) {
                $item = @{
                    Name = if ($class.Name) { $class.Name } else { $class.name }
                    Type = 'Class'
                    Language = $lang
                    File = if ($class.FilePath) { $class.FilePath } else { $class.file_path }
                    Description = if ($class.docstring) { ($class.docstring -split '\n')[0] } else { "" }
                }
                
                $index.AllItems += $item
                $index.ByType.Classes += $item
                $index.ByLanguage[$lang] += $item
                
                # Add to search index
                $searchKey = "$($item.Name) $($item.Type) $($item.Language)".ToLower()
                $index.SearchIndex[$searchKey] = $item
            }
        }
    }
    
    return $index
}

function Generate-MarkdownIndex {
    param($UnifiedDocs, $Index)
    
    Write-VerboseLog "Generating Markdown index"
    
    $markdown = @()
    $markdown += "# Project Documentation Index"
    $markdown += ""
    $markdown += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $markdown += ""
    
    # Statistics
    $markdown += "## Statistics"
    $markdown += ""
    $markdown += "| Metric | Count |"
    $markdown += "|--------|-------|"
    $markdown += "| Total Files | $($UnifiedDocs.Statistics.TotalFiles) |"
    $markdown += "| Total Functions | $($UnifiedDocs.Statistics.TotalFunctions) |"
    $markdown += "| Total Classes | $($UnifiedDocs.Statistics.TotalClasses) |"
    $markdown += "| Total Modules | $($UnifiedDocs.Statistics.TotalModules) |"
    $markdown += "| Total Lines | $($UnifiedDocs.Statistics.TotalLines) |"
    $markdown += ""
    
    # Languages
    $markdown += "## Languages"
    $markdown += ""
    
    foreach ($lang in $UnifiedDocs.Languages.Keys | Sort-Object) {
        $langDocs = $UnifiedDocs.Languages[$lang]
        $funcCount = if ($langDocs.Functions) { $langDocs.Functions.Count } else { 0 }
        $classCount = 0
        if ($langDocs.Classes) { $classCount = $langDocs.Classes.Count }
        elseif ($langDocs.classes) { $classCount = $langDocs.classes.Count }
        
        $markdown += "### $lang"
        $markdown += ""
        $markdown += "- Functions: $funcCount"
        $markdown += "- Classes: $classCount"
        $markdown += "- [View $lang Documentation](./$lang/index.md)"
        $markdown += ""
    }
    
    # Quick Reference
    $markdown += "## Quick Reference"
    $markdown += ""
    
    # Functions
    if ($Index.ByType.Functions.Count -gt 0) {
        $markdown += "### Functions"
        $markdown += ""
        $markdown += "| Name | Language | File |"
        $markdown += "|------|----------|------|"
        
        foreach ($func in $Index.ByType.Functions | Sort-Object Name | Select-Object -First 20) {
            $fileName = Split-Path $func.File -Leaf
            $markdown += "| $($func.Name) | $($func.Language) | $fileName |"
        }
        
        if ($Index.ByType.Functions.Count -gt 20) {
            $markdown += ""
            $markdown += "_Showing first 20 of $($Index.ByType.Functions.Count) functions_"
        }
        $markdown += ""
    }
    
    # Classes
    if ($Index.ByType.Classes.Count -gt 0) {
        $markdown += "### Classes"
        $markdown += ""
        $markdown += "| Name | Language | File |"
        $markdown += "|------|----------|------|"
        
        foreach ($class in $Index.ByType.Classes | Sort-Object Name | Select-Object -First 20) {
            $fileName = Split-Path $class.File -Leaf
            $markdown += "| $($class.Name) | $($class.Language) | $fileName |"
        }
        
        if ($Index.ByType.Classes.Count -gt 20) {
            $markdown += ""
            $markdown += "_Showing first 20 of $($Index.ByType.Classes.Count) classes_"
        }
        $markdown += ""
    }
    
    return $markdown -join "`n"
}

function Generate-HTMLDocumentation {
    param($UnifiedDocs, $OutputPath)
    
    Write-VerboseLog "Generating HTML documentation"
    
    $htmlTemplate = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Project Documentation</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background: #f5f5f5;
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin: 20px 0;
        }
        .stat-card {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .stat-value {
            font-size: 2em;
            font-weight: bold;
            color: #3498db;
        }
        .stat-label {
            color: #7f8c8d;
            margin-top: 5px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            background: white;
            margin: 20px 0;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        th {
            background: #34495e;
            color: white;
            padding: 12px;
            text-align: left;
        }
        td {
            padding: 12px;
            border-bottom: 1px solid #ecf0f1;
        }
        tr:hover {
            background: #f8f9fa;
        }
        .language-badge {
            display: inline-block;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 0.85em;
            font-weight: bold;
        }
        .lang-powershell { background: #012456; color: white; }
        .lang-python { background: #3776ab; color: white; }
        .lang-javascript { background: #f7df1e; color: black; }
        .lang-typescript { background: #3178c6; color: white; }
        .lang-csharp { background: #239120; color: white; }
        .search-box {
            width: 100%;
            padding: 12px;
            font-size: 16px;
            border: 2px solid #ddd;
            border-radius: 8px;
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <h1>Project Documentation</h1>
    <p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    
    <input type="text" class="search-box" placeholder="Search documentation..." id="searchBox">
    
    <div class="stats">
        <div class="stat-card">
            <div class="stat-value">$($UnifiedDocs.Statistics.TotalFiles)</div>
            <div class="stat-label">Total Files</div>
        </div>
        <div class="stat-card">
            <div class="stat-value">$($UnifiedDocs.Statistics.TotalFunctions)</div>
            <div class="stat-label">Functions</div>
        </div>
        <div class="stat-card">
            <div class="stat-value">$($UnifiedDocs.Statistics.TotalClasses)</div>
            <div class="stat-label">Classes</div>
        </div>
        <div class="stat-card">
            <div class="stat-value">$($UnifiedDocs.Statistics.TotalModules)</div>
            <div class="stat-label">Modules</div>
        </div>
    </div>
    
    <h2>Documentation by Language</h2>
    <table>
        <thead>
            <tr>
                <th>Language</th>
                <th>Functions</th>
                <th>Classes</th>
                <th>Files</th>
            </tr>
        </thead>
        <tbody>
"@
    
    foreach ($lang in $UnifiedDocs.Languages.Keys | Sort-Object) {
        $langDocs = $UnifiedDocs.Languages[$lang]
        $funcCount = if ($langDocs.Functions) { $langDocs.Functions.Count } else { 0 }
        $classCount = 0
        if ($langDocs.Classes) { $classCount = $langDocs.Classes.Count }
        elseif ($langDocs.classes) { $classCount = $langDocs.classes.Count }
        $fileCount = if ($langDocs.Files) { $langDocs.Files.Count } else { 0 }
        
        $langClass = "lang-$($lang.ToLower())"
        
        $htmlTemplate += @"
            <tr>
                <td><span class="language-badge $langClass">$lang</span></td>
                <td>$funcCount</td>
                <td>$classCount</td>
                <td>$fileCount</td>
            </tr>
"@
    }
    
    $htmlTemplate += @"
        </tbody>
    </table>
    
    <script>
        document.getElementById('searchBox').addEventListener('input', function(e) {
            const searchTerm = e.target.value.toLowerCase();
            // Implement search functionality
            console.log('Searching for:', searchTerm);
        });
    </script>
</body>
</html>
"@
    
    return $htmlTemplate
}

# Main execution
Write-Host "Unified Documentation Generator" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host ""

# Ensure output directory exists
if (-not (Test-Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Process each language
foreach ($lang in $IncludeLanguages) {
    Write-Host "Processing $lang files..." -ForegroundColor Yellow
    
    switch ($lang) {
        'PowerShell' {
            $docs = Extract-PowerShellDocs -Path $ProjectPath
            if ($docs) {
                $unifiedDocs.Languages.PowerShell = $docs
                $unifiedDocs.Statistics.TotalFunctions += $docs.Functions.Count
                $unifiedDocs.Statistics.TotalModules += $docs.Modules.Count
                $unifiedDocs.Statistics.TotalFiles += $docs.Files.Count
            }
        }
        
        'Python' {
            $docs = Extract-PythonDocs -Path $ProjectPath
            if ($docs) {
                $unifiedDocs.Languages.Python = $docs
                if ($docs.functions) {
                    $unifiedDocs.Statistics.TotalFunctions += $docs.functions.Count
                }
                if ($docs.classes) {
                    $unifiedDocs.Statistics.TotalClasses += $docs.classes.Count
                }
                if ($docs.modules) {
                    $unifiedDocs.Statistics.TotalModules += $docs.modules.Count
                }
            }
        }
        
        'CSharp' {
            $docs = Extract-CSharpDocs -Path $ProjectPath
            if ($docs) {
                $unifiedDocs.Languages.CSharp = $docs
                if ($docs.Classes) {
                    $unifiedDocs.Statistics.TotalClasses += $docs.Classes.Count
                    
                    # Count methods from all classes
                    foreach ($class in $docs.Classes) {
                        if ($class.Methods) {
                            $unifiedDocs.Statistics.TotalFunctions += $class.Methods.Count
                        }
                    }
                }
                if ($docs.Files) {
                    $unifiedDocs.Statistics.TotalFiles += $docs.Files.Count
                }
            }
        }
        
        { $_ -in 'JavaScript', 'TypeScript' } {
            $docs = Extract-JavaScriptDocs -Path $ProjectPath
            if ($docs) {
                $unifiedDocs.Languages[$_] = $docs
                $unifiedDocs.Statistics.TotalFunctions += $docs.functions.Count
                $unifiedDocs.Statistics.TotalClasses += $docs.classes.Count
                $unifiedDocs.Statistics.TotalFiles += $docs.files.Count
            }
        }
    }
}

# Generate cross-references
$unifiedDocs.CrossReferences = Generate-CrossReferences -UnifiedDocs $unifiedDocs

# Generate index if requested
if ($GenerateIndex) {
    Write-Host "Generating documentation index..." -ForegroundColor Yellow
    $index = Generate-DocumentationIndex -UnifiedDocs $unifiedDocs
    $unifiedDocs.Index = $index
    
    # Save index as markdown
    $indexMarkdown = Generate-MarkdownIndex -UnifiedDocs $unifiedDocs -Index $index
    $indexPath = Join-Path $OutputPath "index.md"
    $indexMarkdown | Out-File -FilePath $indexPath -Encoding UTF8
    Write-Host "Index saved to: $indexPath" -ForegroundColor Green
}

# Generate HTML if requested
if ($GenerateHTML) {
    Write-Host "Generating HTML documentation..." -ForegroundColor Yellow
    $html = Generate-HTMLDocumentation -UnifiedDocs $unifiedDocs -OutputPath $OutputPath
    $htmlPath = Join-Path $OutputPath "index.html"
    $html | Out-File -FilePath $htmlPath -Encoding UTF8
    Write-Host "HTML documentation saved to: $htmlPath" -ForegroundColor Green
}

# Save unified documentation as JSON
$jsonPath = Join-Path $OutputPath "unified_documentation.json"
$unifiedDocs | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonPath -Encoding UTF8
Write-Host "Unified documentation saved to: $jsonPath" -ForegroundColor Green

# Save summary
Write-Host ""
Write-Host "Documentation Generation Complete!" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Green
Write-Host "Total Files Processed: $($unifiedDocs.Statistics.TotalFiles)"
Write-Host "Total Functions: $($unifiedDocs.Statistics.TotalFunctions)"
Write-Host "Total Classes: $($unifiedDocs.Statistics.TotalClasses)"
Write-Host "Total Modules: $($unifiedDocs.Statistics.TotalModules)"
Write-Host "Languages Processed: $($unifiedDocs.Languages.Keys -join ', ')"

# Return documentation object
return $unifiedDocs