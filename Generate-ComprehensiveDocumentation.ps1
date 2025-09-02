# Generate-ComprehensiveDocumentation.ps1
# Generates maximum detail enhanced documentation for the entire Unity-Claude Automation system

param(
    [switch]$MaximumDetail,
    [switch]$ExportAll,
    [string]$OutputPath = ".\docs\generated",
    [string]$ProjectPath = "."
)

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "COMPREHENSIVE DOCUMENTATION GENERATION" -ForegroundColor Cyan
Write-Host "Generating Enhanced Documentation with Maximum Detail" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Cyan

# Create output directory
New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null

# Import all documentation modules
$modules = @(
    "Unity-Claude-DocumentationQualityAssessment",
    "Unity-Claude-DocumentationOrchestrator",
    "Unity-Claude-DocumentationCrossReference",
    "Unity-Claude-DocumentationAnalytics",
    "Unity-Claude-DocumentationSuggestions"
)

foreach ($module in $modules) {
    $modulePath = Join-Path ".\Modules" $module "$module.psm1"
    if (Test-Path $modulePath) {
        Write-Host "Loading $module..." -ForegroundColor Gray
        Import-Module $modulePath -Force
    }
}

# Step 1: Scan and analyze all code
Write-Host "`n[1/6] Scanning codebase..." -ForegroundColor Green
$codeFiles = Get-ChildItem -Path $ProjectPath -Include *.ps1,*.psm1,*.psd1 -Recurse -ErrorAction SilentlyContinue
Write-Host "  Found $($codeFiles.Count) PowerShell files" -ForegroundColor Gray

# Step 2: Generate module documentation
Write-Host "`n[2/6] Generating module documentation..." -ForegroundColor Green
$modulesDocs = @{}
Get-ChildItem -Path ".\Modules" -Directory | ForEach-Object {
    $moduleName = $_.Name
    Write-Host "  Documenting $moduleName..." -ForegroundColor Gray
    
    try {
        Import-Module $_.FullName -Force -ErrorAction SilentlyContinue
        $commands = Get-Command -Module $moduleName
        
        $moduleDoc = @{
            Name = $moduleName
            Path = $_.FullName
            Commands = $commands | ForEach-Object {
                @{
                    Name = $_.Name
                    CommandType = $_.CommandType
                    Parameters = $_.Parameters.Keys
                    Synopsis = (Get-Help $_.Name -ErrorAction SilentlyContinue).Synopsis
                }
            }
            ExportedFunctions = (Get-Module $moduleName).ExportedFunctions.Keys
            Version = (Get-Module $moduleName).Version
        }
        
        $modulesDocs[$moduleName] = $moduleDoc
        
        # Export individual module documentation
        $moduleDoc | ConvertTo-Json -Depth 5 | Out-File "$OutputPath\$moduleName-Documentation.json"
        
    } catch {
        Write-Host "    Warning: Could not fully document $moduleName" -ForegroundColor Yellow
    }
}

# Step 3: Run quality assessment
Write-Host "`n[3/6] Running quality assessment..." -ForegroundColor Green
if (Get-Command Test-DocumentationQuality -ErrorAction SilentlyContinue) {
    $qualityResults = Test-DocumentationQuality -Path $ProjectPath -Detailed
    $qualityResults | ConvertTo-Json -Depth 5 | Out-File "$OutputPath\Quality-Assessment-Report.json"
    Write-Host "  Quality Score: $($qualityResults.OverallScore)%" -ForegroundColor Cyan
}

# Step 4: Generate cross-references
Write-Host "`n[4/6] Building cross-references..." -ForegroundColor Green
if (Get-Command New-DocumentationCrossReference -ErrorAction SilentlyContinue) {
    $crossRefs = New-DocumentationCrossReference -RootPath $ProjectPath
    $crossRefs | ConvertTo-Json -Depth 5 | Out-File "$OutputPath\Cross-References.json"
    Write-Host "  Generated $($crossRefs.Count) cross-references" -ForegroundColor Gray
}

# Step 5: Generate analytics
Write-Host "`n[5/6] Generating analytics and metrics..." -ForegroundColor Green
if (Get-Command Get-DocumentationAnalytics -ErrorAction SilentlyContinue) {
    $analytics = Get-DocumentationAnalytics -Path $ProjectPath
    $analytics | ConvertTo-Json -Depth 5 | Out-File "$OutputPath\Documentation-Analytics.json"
    Write-Host "  Calculated $($analytics.Metrics.Count) metrics" -ForegroundColor Gray
}

# Step 6: Create master documentation index
Write-Host "`n[6/6] Creating master documentation index..." -ForegroundColor Green
$masterIndex = @{
    GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    ProjectPath = $ProjectPath
    OutputPath = $OutputPath
    Statistics = @{
        TotalFiles = $codeFiles.Count
        ModulesDocumented = $modulesDocs.Count
        TotalFunctions = ($modulesDocs.Values | ForEach-Object { $_.Commands.Count } | Measure-Object -Sum).Sum
    }
    Modules = $modulesDocs.Keys
    GeneratedFiles = Get-ChildItem $OutputPath -Filter *.json | Select-Object Name, Length, LastWriteTime
}

$masterIndex | ConvertTo-Json -Depth 5 | Out-File "$OutputPath\Master-Documentation-Index.json"

# Generate README
$readme = @"
# Unity-Claude Automation - Enhanced Documentation

Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Documentation Contents

### Modules Documented
$($modulesDocs.Keys | ForEach-Object { "- $_" } | Out-String)

### Statistics
- Total PowerShell Files: $($codeFiles.Count)
- Modules Documented: $($modulesDocs.Count)
- Total Functions: $(($modulesDocs.Values | ForEach-Object { $_.Commands.Count } | Measure-Object -Sum).Sum)

### Generated Documentation Files
$(Get-ChildItem $OutputPath -Filter *.json | ForEach-Object { "- $($_.Name) ($('{0:N0}' -f ($_.Length / 1KB)) KB)" } | Out-String)

## Viewing Documentation

### Web Interface
Access the documentation at: http://localhost:8080

### API Documentation
View API docs at: http://localhost:8091/docs

### Monitoring Dashboard
Monitor system at: http://localhost:3000

## Quality Metrics
$(if ($qualityResults) { "Overall Quality Score: $($qualityResults.OverallScore)%" })

---
*Generated by Unity-Claude Enhanced Documentation System*
"@

$readme | Out-File "$OutputPath\README.md" -Encoding UTF8

# Display summary
Write-Host "`n" + "=" * 80 -ForegroundColor Cyan
Write-Host "DOCUMENTATION GENERATION COMPLETE!" -ForegroundColor Green
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "`nOutput Location: $OutputPath" -ForegroundColor Yellow
Write-Host "`nGenerated Files:" -ForegroundColor White
Get-ChildItem $OutputPath | ForEach-Object {
    Write-Host "  - $($_.Name)" -ForegroundColor Gray
}

Write-Host "`nAccess Points:" -ForegroundColor White
Write-Host "  Web Interface: http://localhost:8080" -ForegroundColor Cyan
Write-Host "  API Docs: http://localhost:8091/docs" -ForegroundColor Cyan
Write-Host "  Monitoring: http://localhost:3000" -ForegroundColor Cyan

if ($ExportAll) {
    Write-Host "`nExporting to multiple formats..." -ForegroundColor Yellow
    # Convert JSON to HTML
    Get-ChildItem "$OutputPath\*.json" | ForEach-Object {
        $content = Get-Content $_.FullName | ConvertFrom-Json
        $html = $content | ConvertTo-Html -Title $_.BaseName
        $html | Out-File "$OutputPath\$($_.BaseName).html"
    }
    Write-Host "  Exported HTML versions" -ForegroundColor Green
}

Write-Host "`n✅ Documentation generation completed successfully!" -ForegroundColor Green