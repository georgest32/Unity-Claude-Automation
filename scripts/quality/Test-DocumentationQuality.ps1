#Requires -Version 5.1
<#
.SYNOPSIS
    Tests documentation quality using Vale and markdownlint.

.DESCRIPTION
    Runs Vale prose linter and markdownlint on project documentation,
    generating quality reports and optionally fixing issues.

.PARAMETER Path
    Path to test (defaults to current directory)

.PARAMETER Fix
    Attempt to auto-fix markdownlint issues

.PARAMETER OutputFormat
    Output format: Console, JSON, or Both (default)

.PARAMETER SkipVale
    Skip Vale prose linting

.PARAMETER SkipMarkdownlint
    Skip markdownlint validation

.PARAMETER SaveResults
    Save results to a file

.EXAMPLE
    Test-DocumentationQuality.ps1 -Path .\docs -Fix -SaveResults
#>

param(
    [string]$Path = ".",
    [switch]$Fix,
    [ValidateSet('Console', 'JSON', 'Both')]
    [string]$OutputFormat = 'Console',
    [switch]$SkipVale,
    [switch]$SkipMarkdownlint,
    [switch]$SaveResults,
    [int]$MaxFiles = 50
)

$ErrorActionPreference = 'Continue'

# Initialize results
$results = @{
    TestName = "Documentation Quality Test"
    StartTime = Get-Date
    Path = $Path
    ValeResults = @{
        Available = $false
        Files = @()
        Issues = @()
        Summary = @{
            Errors = 0
            Warnings = 0
            Suggestions = 0
        }
    }
    MarkdownlintResults = @{
        Available = $false
        Files = @()
        Issues = @()
        Fixed = 0
    }
    Summary = @{
        TotalFiles = 0
        PassedFiles = 0
        FailedFiles = 0
        TotalIssues = 0
    }
}

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Documentation Quality Test" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Path: $Path" -ForegroundColor Gray
Write-Host "Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Find markdown files
Write-Host "Finding markdown files..." -ForegroundColor Yellow
$allMarkdownFiles = Get-ChildItem -Path $Path -Filter "*.md" -Recurse -File -ErrorAction SilentlyContinue | 
                    Where-Object { 
                        $_.FullName -notmatch '[\\/](\.venv|venv|node_modules|\.git|build|dist|out)[\\/]'
                    }

# Limit files if specified
if ($MaxFiles -gt 0 -and $allMarkdownFiles.Count -gt $MaxFiles) {
    Write-Host "Found $($allMarkdownFiles.Count) markdown files, limiting to $MaxFiles for testing" -ForegroundColor Yellow
    $markdownFiles = $allMarkdownFiles | Select-Object -First $MaxFiles
}
else {
    $markdownFiles = $allMarkdownFiles
}

$results.Summary.TotalFiles = $markdownFiles.Count
Write-Host "Testing $($markdownFiles.Count) markdown files" -ForegroundColor Green
Write-Host ""

# Test Vale
if (-not $SkipVale) {
    Write-Host "Running Vale prose linter..." -ForegroundColor Yellow
    
    try {
        $valeVersion = vale --version 2>&1
        if ($valeVersion) {
            $results.ValeResults.Available = $true
            Write-Host "Vale version: $valeVersion" -ForegroundColor Gray
            
            # Check if Vale is configured
            if (-not (Test-Path ".vale.ini")) {
                Write-Host "[!] .vale.ini not found - using default configuration" -ForegroundColor Yellow
            }
            
            # Run Vale on each file
            foreach ($file in $markdownFiles) {
                Write-Host "  Checking: $($file.Name)..." -NoNewline
                
                $valeOutput = vale --output JSON $file.FullName 2>&1 | Out-String
                
                try {
                    $valeJson = $valeOutput | ConvertFrom-Json
                    
                    $fileResult = @{
                        File = $file.FullName
                        Issues = @()
                    }
                    
                    foreach ($fileName in $valeJson.PSObject.Properties.Name) {
                        $fileIssues = $valeJson.$fileName
                        
                        foreach ($issue in $fileIssues) {
                            $issueInfo = @{
                                Line = $issue.Line
                                Column = $issue.Column
                                Severity = $issue.Severity
                                Message = $issue.Message
                                Check = $issue.Check
                            }
                            
                            $fileResult.Issues += $issueInfo
                            $results.ValeResults.Issues += $issueInfo
                            
                            switch ($issue.Severity.ToLower()) {
                                'error' { $results.ValeResults.Summary.Errors++ }
                                'warning' { $results.ValeResults.Summary.Warnings++ }
                                'suggestion' { $results.ValeResults.Summary.Suggestions++ }
                            }
                        }
                    }
                    
                    $results.ValeResults.Files += $fileResult
                    
                    if ($fileResult.Issues.Count -eq 0) {
                        Write-Host " OK" -ForegroundColor Green
                        $results.Summary.PassedFiles++
                    }
                    else {
                        Write-Host " $($fileResult.Issues.Count) issues" -ForegroundColor Yellow
                        $results.Summary.FailedFiles++
                        $results.Summary.TotalIssues += $fileResult.Issues.Count
                    }
                }
                catch {
                    Write-Host " ERROR" -ForegroundColor Red
                    Write-Host "    Failed to parse Vale output: $_" -ForegroundColor Red
                }
            }
            
            Write-Host ""
            Write-Host "Vale Summary:" -ForegroundColor Cyan
            Write-Host "  Errors: $($results.ValeResults.Summary.Errors)" -ForegroundColor $(if ($results.ValeResults.Summary.Errors -gt 0) { 'Red' } else { 'Green' })
            Write-Host "  Warnings: $($results.ValeResults.Summary.Warnings)" -ForegroundColor $(if ($results.ValeResults.Summary.Warnings -gt 0) { 'Yellow' } else { 'Green' })
            Write-Host "  Suggestions: $($results.ValeResults.Summary.Suggestions)" -ForegroundColor Gray
        }
        else {
            Write-Host "[X] Vale is not installed" -ForegroundColor Red
            Write-Host "    Install with: choco install vale" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "[X] Vale is not available: $_" -ForegroundColor Red
    }
}
else {
    Write-Host "[i] Skipping Vale" -ForegroundColor Gray
}

Write-Host ""

# Test markdownlint
if (-not $SkipMarkdownlint) {
    Write-Host "Running markdownlint..." -ForegroundColor Yellow
    
    try {
        # Try npx first, then direct command
        $mdlVersion = $null
        try {
            $mdlVersion = npx markdownlint-cli2 --version 2>&1
        }
        catch {
            # Try direct command if npx fails
            try {
                $mdlVersion = markdownlint-cli2 --version 2>&1
            }
            catch {
                $mdlVersion = $null
            }
        }
        if ($mdlVersion) {
            $results.MarkdownlintResults.Available = $true
            Write-Host "markdownlint-cli2 version: $mdlVersion" -ForegroundColor Gray
            
            # Check if configured
            $configFile = $null
            if (Test-Path ".markdownlint-cli2.jsonc") {
                $configFile = ".markdownlint-cli2.jsonc"
            }
            elseif (Test-Path ".markdownlintrc") {
                $configFile = ".markdownlintrc"
            }
            
            if ($configFile) {
                Write-Host "Using config: $configFile" -ForegroundColor Gray
            }
            else {
                Write-Host "[!] No markdownlint configuration found - using defaults" -ForegroundColor Yellow
            }
            
            # Build command - use npx to ensure it's found
            # Process only the specific files we're testing
            $mdlCommand = "npx markdownlint-cli2"
            
            # Use --no-globs to prevent config file globs from overriding our file list
            $mdlCommand += " --no-globs"
            
            # Use the basic .markdownlintrc for rules only
            if (Test-Path ".markdownlintrc") {
                $mdlCommand += " --config '.markdownlintrc'"
            }
            
            if ($Fix) {
                $mdlCommand += " --fix"
            }
            
            # Add each file explicitly to limit scope
            foreach ($file in $markdownFiles) {
                $relativePath = $file.FullName.Replace("$PWD\", "").Replace("\", "/")
                $mdlCommand += " '$relativePath'"
            }
            
            # Run markdownlint
            Write-Host "Command: $mdlCommand" -ForegroundColor Gray
            $mdlOutput = Invoke-Expression $mdlCommand 2>&1 | Out-String
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "All files passed markdownlint!" -ForegroundColor Green
                $results.Summary.PassedFiles = $results.Summary.TotalFiles
            }
            else {
                # Parse output for issues
                $lines = $mdlOutput -split "`n"
                foreach ($line in $lines) {
                    if ($line -match '^(.+\.md):(\d+)(?::(\d+))?\s+(.+)$') {
                        $issueInfo = @{
                            File = $Matches[1]
                            Line = [int]$Matches[2]
                            Column = if ($Matches[3]) { [int]$Matches[3] } else { 0 }
                            Message = $Matches[4]
                        }
                        
                        $results.MarkdownlintResults.Issues += $issueInfo
                        $results.Summary.TotalIssues++
                    }
                }
                
                Write-Host "Found $($results.MarkdownlintResults.Issues.Count) markdownlint issues" -ForegroundColor Yellow
                
                if ($Fix) {
                    Write-Host "Attempted to fix issues (run again to see remaining)" -ForegroundColor Cyan
                }
            }
            
            # Show sample issues if any
            if ($results.MarkdownlintResults.Issues.Count -gt 0 -and $OutputFormat -ne 'JSON') {
                Write-Host ""
                Write-Host "Sample markdownlint issues:" -ForegroundColor Yellow
                $results.MarkdownlintResults.Issues | Select-Object -First 5 | ForEach-Object {
                    Write-Host "  $($_.File):$($_.Line) - $($_.Message)" -ForegroundColor Gray
                }
                
                if ($results.MarkdownlintResults.Issues.Count -gt 5) {
                    Write-Host "  ... and $($results.MarkdownlintResults.Issues.Count - 5) more" -ForegroundColor Gray
                }
            }
        }
        else {
            Write-Host "[X] markdownlint-cli2 is not installed" -ForegroundColor Red
            Write-Host "    Install with: npm install -g markdownlint-cli2" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "[X] markdownlint is not available: $_" -ForegroundColor Red
    }
}
else {
    Write-Host "[i] Skipping markdownlint" -ForegroundColor Gray
}

# Calculate final results
$results.EndTime = Get-Date
$results.Duration = ($results.EndTime - $results.StartTime).TotalSeconds

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Total Files: $($results.Summary.TotalFiles)"
Write-Host "Passed: $($results.Summary.PassedFiles)" -ForegroundColor Green
Write-Host "Failed: $($results.Summary.FailedFiles)" -ForegroundColor $(if ($results.Summary.FailedFiles -gt 0) { 'Red' } else { 'Gray' })
Write-Host "Total Issues: $($results.Summary.TotalIssues)" -ForegroundColor $(if ($results.Summary.TotalIssues -gt 0) { 'Yellow' } else { 'Green' })
Write-Host "Duration: $([math]::Round($results.Duration, 2)) seconds"
Write-Host ""

# Save results if requested
if ($SaveResults) {
    $resultsFile = ".\DocumentationQuality-Results-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $results | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultsFile -Encoding UTF8
    Write-Host "Results saved to: $resultsFile" -ForegroundColor Cyan
}

# Output JSON if requested
if ($OutputFormat -in 'JSON', 'Both') {
    Write-Host ""
    Write-Host "JSON Output:" -ForegroundColor Cyan
    $results | ConvertTo-Json -Depth 5
}

# Return exit code
if ($results.Summary.TotalIssues -gt 0) {
    if ($results.ValeResults.Summary.Errors -gt 0 -or $results.MarkdownlintResults.Issues.Count -gt 0) {
        Write-Host ""
        Write-Host "Documentation Quality Test: FAILED" -ForegroundColor Red
        exit 1
    }
    else {
        Write-Host ""
        Write-Host "Documentation Quality Test: PASSED WITH WARNINGS" -ForegroundColor Yellow
        exit 0
    }
}
else {
    Write-Host ""
    Write-Host "Documentation Quality Test: PASSED" -ForegroundColor Green
    exit 0
}