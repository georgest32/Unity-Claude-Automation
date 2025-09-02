#Requires -Version 5.1
<#
.SYNOPSIS
    Pre-commit hook for documentation quality checks.

.DESCRIPTION
    Runs Vale and markdownlint on staged markdown files before commit.
    Called by Git pre-commit hook.

.EXAMPLE
    This script is called automatically by Git pre-commit hook
#>

param(
    [switch]$SkipVale,
    [switch]$SkipMarkdownlint,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "=== Pre-commit Documentation Quality Check ===" -ForegroundColor Cyan
Write-Host ""

# Get staged markdown files
$stagedFiles = git diff --cached --name-only --diff-filter=ACM | Where-Object { $_ -match '\.md$' }

if ($stagedFiles.Count -eq 0) {
    Write-Host "No markdown files staged for commit" -ForegroundColor Gray
    exit 0
}

Write-Host "Checking $($stagedFiles.Count) staged markdown file(s)..." -ForegroundColor Yellow
Write-Host ""

$hasErrors = $false
$hasWarnings = $false

# Check each file with Vale
if (-not $SkipVale) {
    try {
        $valeVersion = vale --version 2>&1
        if ($valeVersion) {
            Write-Host "Running Vale prose linter..." -ForegroundColor Yellow
            
            foreach ($file in $stagedFiles) {
                if (Test-Path $file) {
                    Write-Host "  $file..." -NoNewline
                    
                    $valeOutput = vale --output JSON $file 2>&1 | Out-String
                    
                    try {
                        $valeJson = $valeOutput | ConvertFrom-Json
                        $issueCount = 0
                        $errorCount = 0
                        
                        foreach ($fileName in $valeJson.PSObject.Properties.Name) {
                            $fileIssues = $valeJson.$fileName
                            $issueCount += $fileIssues.Count
                            
                            foreach ($issue in $fileIssues) {
                                if ($issue.Severity -eq 'error') {
                                    $errorCount++
                                }
                            }
                        }
                        
                        if ($issueCount -eq 0) {
                            Write-Host " OK" -ForegroundColor Green
                        }
                        elseif ($errorCount -gt 0) {
                            Write-Host " $errorCount error(s)" -ForegroundColor Red
                            $hasErrors = $true
                            
                            # Show errors
                            foreach ($fileName in $valeJson.PSObject.Properties.Name) {
                                foreach ($issue in $valeJson.$fileName) {
                                    if ($issue.Severity -eq 'error') {
                                        Write-Host "    Line $($issue.Line): $($issue.Message)" -ForegroundColor Red
                                    }
                                }
                            }
                        }
                        else {
                            Write-Host " $issueCount warning(s)" -ForegroundColor Yellow
                            $hasWarnings = $true
                        }
                    }
                    catch {
                        Write-Host " SKIP (parse error)" -ForegroundColor Yellow
                    }
                }
            }
            
            Write-Host ""
        }
    }
    catch {
        Write-Host "[!] Vale not available - skipping prose checks" -ForegroundColor Yellow
    }
}

# Check with markdownlint
if (-not $SkipMarkdownlint) {
    try {
        $mdlVersion = npx markdownlint-cli2 --version 2>&1
        if ($mdlVersion) {
            Write-Host "Running markdownlint..." -ForegroundColor Yellow
            
            # Create temp file list
            $tempFileList = [System.IO.Path]::GetTempFileName()
            $stagedFiles | Out-File -FilePath $tempFileList -Encoding UTF8
            
            # Run markdownlint on staged files
            $mdlCommand = "markdownlint-cli2"
            if (Test-Path ".markdownlint-cli2.jsonc") {
                $mdlCommand += " --config '.markdownlint-cli2.jsonc'"
            }
            
            $mdlErrors = @()
            
            foreach ($file in $stagedFiles) {
                if (Test-Path $file) {
                    $mdlOutput = Invoke-Expression "$mdlCommand '$file'" 2>&1
                    
                    if ($LASTEXITCODE -ne 0) {
                        $mdlErrors += $mdlOutput
                    }
                }
            }
            
            # Clean up temp file
            Remove-Item $tempFileList -Force -ErrorAction SilentlyContinue
            
            if ($mdlErrors.Count -gt 0) {
                Write-Host "  Found markdownlint issues:" -ForegroundColor Red
                $mdlErrors | ForEach-Object {
                    Write-Host "    $_" -ForegroundColor Red
                }
                $hasErrors = $true
            }
            else {
                Write-Host "  All files passed markdownlint" -ForegroundColor Green
            }
            
            Write-Host ""
        }
    }
    catch {
        Write-Host "[!] markdownlint not available - skipping markdown checks" -ForegroundColor Yellow
    }
}

# Determine result
if ($hasErrors -and -not $Force) {
    Write-Host "=== COMMIT BLOCKED ===" -ForegroundColor Red
    Write-Host "Documentation quality errors found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Yellow
    Write-Host "  1. Fix the errors and stage the changes" -ForegroundColor White
    Write-Host "  2. Run with --no-verify to skip checks (not recommended)" -ForegroundColor Gray
    Write-Host "  3. Add --force flag to commit with warnings" -ForegroundColor Gray
    Write-Host ""
    exit 1
}
elseif ($hasWarnings) {
    Write-Host "=== COMMIT ALLOWED WITH WARNINGS ===" -ForegroundColor Yellow
    Write-Host "Documentation has style suggestions - consider reviewing" -ForegroundColor Yellow
    Write-Host ""
    exit 0
}
else {
    Write-Host "=== COMMIT ALLOWED ===" -ForegroundColor Green
    Write-Host "All documentation quality checks passed!" -ForegroundColor Green
    Write-Host ""
    exit 0
}