#requires -Version 5.1

<#
.SYNOPSIS
Migrates AI components from root to organized Modules subfolder structure

.DESCRIPTION
This script moves Week 1 AI components (LangGraph, AutoGen, Ollama) from the root
directory to an organized structure under Modules/Unity-Claude-AI-Integration/

.NOTES
Date: 2025-08-30
Author: Unity-Claude-Automation System
Purpose: Organize AI components for Week 3 implementation
#>

param(
    [switch]$WhatIf,
    [switch]$UseGitMove
)

$ErrorActionPreference = "Stop"

function Write-MigrationLog {
    param([string]$Message, [string]$Level = "Info")
    
    $colors = @{
        "Info" = "White"
        "Success" = "Green"
        "Warning" = "Yellow"
        "Error" = "Red"
        "Header" = "Cyan"
    }
    
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Message" -ForegroundColor $colors[$Level]
}

Write-Host ""
Write-MigrationLog "========================================" -Level "Header"
Write-MigrationLog "AI Components Migration to Modules" -Level "Header"
Write-MigrationLog "========================================" -Level "Header"
Write-Host ""

if ($WhatIf) {
    Write-MigrationLog "Running in WhatIf mode - no changes will be made" -Level "Warning"
    Write-Host ""
}

# Define source and destination paths
$rootPath = $PSScriptRoot
$modulesPath = Join-Path $rootPath "Modules"
$aiIntegrationPath = Join-Path $modulesPath "Unity-Claude-AI-Integration"

# Create folder structure
Write-MigrationLog "Creating folder structure..." -Level "Header"

$folders = @(
    $aiIntegrationPath,
    (Join-Path $aiIntegrationPath "LangGraph"),
    (Join-Path $aiIntegrationPath "LangGraph\Workflows"),
    (Join-Path $aiIntegrationPath "AutoGen"),
    (Join-Path $aiIntegrationPath "Ollama")
)

foreach ($folder in $folders) {
    if (-not (Test-Path $folder)) {
        if (-not $WhatIf) {
            New-Item -ItemType Directory -Path $folder -Force | Out-Null
            Write-MigrationLog "  Created: $($folder.Replace($rootPath, '.'))" -Level "Success"
        }
        else {
            Write-MigrationLog "  Would create: $($folder.Replace($rootPath, '.'))" -Level "Info"
        }
    }
    else {
        Write-MigrationLog "  Exists: $($folder.Replace($rootPath, '.'))" -Level "Info"
    }
}

Write-Host ""

# Define files to move
$fileMappings = @(
    # LangGraph components
    @{
        Source = "Unity-Claude-LangGraphBridge.psm1"
        Destination = "Modules\Unity-Claude-AI-Integration\LangGraph\Unity-Claude-LangGraphBridge.psm1"
    },
    @{
        Source = "Unity-Claude-MultiStepOrchestrator.psm1"
        Destination = "Modules\Unity-Claude-AI-Integration\LangGraph\Unity-Claude-MultiStepOrchestrator.psm1"
    },
    @{
        Source = "PredictiveAnalysis-LangGraph-Workflows.json"
        Destination = "Modules\Unity-Claude-AI-Integration\LangGraph\Workflows\PredictiveAnalysis-LangGraph-Workflows.json"
    },
    @{
        Source = "MultiStep-Orchestrator-Workflows.json"
        Destination = "Modules\Unity-Claude-AI-Integration\LangGraph\Workflows\MultiStep-Orchestrator-Workflows.json"
    },
    
    # AutoGen components
    @{
        Source = "Unity-Claude-AutoGen.psm1"
        Destination = "Modules\Unity-Claude-AI-Integration\AutoGen\Unity-Claude-AutoGen.psm1"
    },
    @{
        Source = "Unity-Claude-AutoGenMonitoring.psm1"
        Destination = "Modules\Unity-Claude-AI-Integration\AutoGen\Unity-Claude-AutoGenMonitoring.psm1"
    },
    @{
        Source = "PowerShell-AutoGen-Terminal-Integration.ps1"
        Destination = "Modules\Unity-Claude-AI-Integration\AutoGen\PowerShell-AutoGen-Terminal-Integration.ps1"
    },
    
    # Ollama components
    @{
        Source = "Unity-Claude-Ollama.psm1"
        Destination = "Modules\Unity-Claude-AI-Integration\Ollama\Unity-Claude-Ollama.psm1"
    },
    @{
        Source = "Unity-Claude-Ollama.psd1"
        Destination = "Modules\Unity-Claude-AI-Integration\Ollama\Unity-Claude-Ollama.psd1"
    },
    @{
        Source = "Unity-Claude-Ollama-Optimized-Fixed.psm1"
        Destination = "Modules\Unity-Claude-AI-Integration\Ollama\Unity-Claude-Ollama-Optimized-Fixed.psm1"
    },
    @{
        Source = "Unity-Claude-Ollama-Enhanced.psm1"
        Destination = "Modules\Unity-Claude-AI-Integration\Ollama\Unity-Claude-Ollama-Enhanced.psm1"
    },
    @{
        Source = "Unity-Claude-Ollama-Optimized.psm1"
        Destination = "Modules\Unity-Claude-AI-Integration\Ollama\Unity-Claude-Ollama-Optimized.psm1"
    }
)

# Move files
Write-MigrationLog "Moving AI component files..." -Level "Header"

$movedCount = 0
$skippedCount = 0
$errorCount = 0

foreach ($mapping in $fileMappings) {
    $sourcePath = Join-Path $rootPath $mapping.Source
    $destPath = Join-Path $rootPath $mapping.Destination
    
    if (Test-Path $sourcePath) {
        if (-not (Test-Path $destPath)) {
            try {
                if (-not $WhatIf) {
                    if ($UseGitMove) {
                        # Use git mv to preserve history
                        $gitCommand = "git mv `"$($mapping.Source)`" `"$($mapping.Destination)`""
                        Write-MigrationLog "  Git moving: $($mapping.Source)" -Level "Info"
                        Invoke-Expression $gitCommand
                    }
                    else {
                        # Regular move
                        Move-Item -Path $sourcePath -Destination $destPath -Force
                    }
                    Write-MigrationLog "  Moved: $($mapping.Source) -> $($mapping.Destination)" -Level "Success"
                    $movedCount++
                }
                else {
                    Write-MigrationLog "  Would move: $($mapping.Source) -> $($mapping.Destination)" -Level "Info"
                }
            }
            catch {
                Write-MigrationLog "  Error moving $($mapping.Source): $_" -Level "Error"
                $errorCount++
            }
        }
        else {
            Write-MigrationLog "  Destination exists, skipping: $($mapping.Source)" -Level "Warning"
            $skippedCount++
        }
    }
    else {
        Write-MigrationLog "  Source not found: $($mapping.Source)" -Level "Info"
        $skippedCount++
    }
}

Write-Host ""

# Create module manifests if they don't exist
Write-MigrationLog "Creating module manifests..." -Level "Header"

$manifestDefinitions = @(
    @{
        Path = "Modules\Unity-Claude-AI-Integration\LangGraph\Unity-Claude-LangGraphBridge.psd1"
        ModuleName = "Unity-Claude-LangGraphBridge"
        RootModule = "Unity-Claude-LangGraphBridge.psm1"
        Description = "PowerShell to LangGraph API integration for AI workflow orchestration"
    },
    @{
        Path = "Modules\Unity-Claude-AI-Integration\AutoGen\Unity-Claude-AutoGen.psd1"
        ModuleName = "Unity-Claude-AutoGen"
        RootModule = "Unity-Claude-AutoGen.psm1"
        Description = "AutoGen multi-agent coordination for Unity-Claude automation"
    }
)

foreach ($manifest in $manifestDefinitions) {
    $manifestPath = Join-Path $rootPath $manifest.Path
    
    if (-not (Test-Path $manifestPath)) {
        if (-not $WhatIf) {
            $manifestContent = @"
@{
    ModuleVersion = '1.0.0'
    GUID = '$(New-Guid)'
    Author = 'Unity-Claude-Automation'
    Description = '$($manifest.Description)'
    RootModule = '$($manifest.RootModule)'
    FunctionsToExport = '*'
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
}
"@
            $manifestContent | Out-File -FilePath $manifestPath -Encoding UTF8
            Write-MigrationLog "  Created manifest: $($manifest.Path)" -Level "Success"
        }
        else {
            Write-MigrationLog "  Would create manifest: $($manifest.Path)" -Level "Info"
        }
    }
}

Write-Host ""

# Update references in test files (optional)
Write-MigrationLog "Checking for test file updates needed..." -Level "Header"

$testFiles = @(
    "Test-LangGraphBridge.ps1",
    "Test-LangGraphBridge-Integration.ps1",
    "Test-AutoGenBasicConversation.ps1",
    "Test-Ollama-Integration.ps1",
    "Test-PredictiveAnalysis-LangGraph-Integration.ps1"
)

foreach ($testFile in $testFiles) {
    $testPath = Join-Path $rootPath $testFile
    if (Test-Path $testPath) {
        Write-MigrationLog "  May need update: $testFile" -Level "Info"
        Write-MigrationLog "    Update Import-Module paths to: .\Modules\Unity-Claude-AI-Integration\..." -Level "Info"
    }
}

Write-Host ""

# Summary
Write-MigrationLog "========================================" -Level "Header"
Write-MigrationLog "Migration Summary" -Level "Header"
Write-MigrationLog "========================================" -Level "Header"
Write-Host ""

Write-Host "Results:" -ForegroundColor Cyan
Write-Host "  Files moved: $movedCount" -ForegroundColor Green
Write-Host "  Files skipped: $skippedCount" -ForegroundColor Yellow
Write-Host "  Errors: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Gray" })

Write-Host ""
Write-Host "New Structure:" -ForegroundColor Cyan
Write-Host "  Modules\" -ForegroundColor White
Write-Host "    └── Unity-Claude-AI-Integration\" -ForegroundColor White
Write-Host "        ├── LangGraph\" -ForegroundColor White
Write-Host "        │   ├── Unity-Claude-LangGraphBridge.psm1" -ForegroundColor Green
Write-Host "        │   └── Workflows\" -ForegroundColor White
Write-Host "        ├── AutoGen\" -ForegroundColor White
Write-Host "        │   └── Unity-Claude-AutoGen.psm1" -ForegroundColor Green
Write-Host "        └── Ollama\" -ForegroundColor White
Write-Host "            └── Unity-Claude-Ollama.psm1" -ForegroundColor Green

if (-not $WhatIf) {
    Write-Host ""
    Write-MigrationLog "Migration complete!" -Level "Success"
    
    if ($UseGitMove) {
        Write-MigrationLog "Remember to commit the changes: git commit -m 'Reorganize AI components into Modules structure'" -Level "Info"
    }
}
else {
    Write-Host ""
    Write-MigrationLog "WhatIf mode complete - no changes made" -Level "Warning"
    Write-MigrationLog "Run without -WhatIf to perform the migration" -Level "Info"
}

# Return success/failure
exit $(if ($errorCount -eq 0) { 0 } else { 1 })