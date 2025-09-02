#region Module Header
<#
.SYNOPSIS
    Documentation Backup & Integration System
    
.DESCRIPTION
    Handles backup and recovery of documentation, integration with predictive analysis,
    comprehensive reporting, and rollback capabilities for documentation automation.
    
.VERSION
    2.0.0
    
.AUTHOR
    Unity-Claude-Automation
#>
#endregion

#region Backup & Recovery Functions

function New-DocumentationBackup {
    <#
    .SYNOPSIS
        Creates a backup of current documentation state
    .DESCRIPTION
        Backs up documentation files for rollback capability
    .PARAMETER Reason
        Reason for creating backup
    .EXAMPLE
        New-DocumentationBackup -Reason "Pre-automation run"
    #>
    [CmdletBinding()]
    param(
        [string]$Reason = "Manual backup",
        [string[]]$Paths = @('.\docs', '.\README.md'),
        [switch]$Compress
    )
    
    try {
        $backupId = "backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        $backupPath = Join-Path $script:DocumentationAutomationConfig.BackupLocation $backupId
        
        Write-Host "Creating documentation backup: $backupId" -ForegroundColor Cyan
        
        New-Item -Path $backupPath -ItemType Directory -Force | Out-Null
        
        $backedUpFiles = @()
        foreach ($path in $Paths) {
            if (Test-Path $path) {
                $destination = Join-Path $backupPath (Split-Path $path -Leaf)
                if (Test-Path $path -PathType Container) {
                    Copy-Item -Path $path -Destination $destination -Recurse -Force
                } else {
                    Copy-Item -Path $path -Destination $destination -Force
                }
                $backedUpFiles += $path
            }
        }
        
        # Create backup metadata
        $metadata = @{
            Id = $backupId
            Reason = $Reason
            CreatedAt = Get-Date
            Paths = $backedUpFiles
            BackupPath = $backupPath
            Compressed = $Compress.IsPresent
            Size = (Get-ChildItem $backupPath -Recurse | Measure-Object -Property Length -Sum).Sum
        }
        
        $metadataFile = Join-Path $backupPath "metadata.json"
        $metadata | ConvertTo-Json -Depth 10 | Out-File -FilePath $metadataFile -Encoding UTF8
        
        if ($Compress) {
            $zipPath = "$backupPath.zip"
            Compress-Archive -Path $backupPath -DestinationPath $zipPath -Force
            Remove-Item -Path $backupPath -Recurse -Force
            $metadata.BackupPath = $zipPath
        }
        
        Write-Host "Backup created successfully" -ForegroundColor Green
        Write-Host "  ID: $backupId" -ForegroundColor Gray
        Write-Host "  Files: $($backedUpFiles.Count)" -ForegroundColor Gray
        Write-Host "  Size: $([math]::Round($metadata.Size/1KB, 2)) KB" -ForegroundColor Gray
        
        return $metadata
        
    } catch {
        Write-Error "Failed to create documentation backup: $_"
        throw
    }
}

function Restore-DocumentationBackup {
    <#
    .SYNOPSIS
        Restores documentation from backup
    .DESCRIPTION
        Restores documentation files from a previous backup
    .PARAMETER BackupId
        Backup ID to restore from
    .EXAMPLE
        Restore-DocumentationBackup -BackupId "backup-20250825-143022"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$BackupId,
        [switch]$Force
    )
    
    try {
        $backupPath = Join-Path $script:DocumentationAutomationConfig.BackupLocation $BackupId
        $zipPath = "$backupPath.zip"
        
        # Check if backup exists
        $isCompressed = Test-Path $zipPath
        if (-not (Test-Path $backupPath) -and -not $isCompressed) {
            throw "Backup '$BackupId' not found"
        }
        
        # Extract if compressed
        if ($isCompressed) {
            Expand-Archive -Path $zipPath -DestinationPath $backupPath -Force
        }
        
        # Read metadata
        $metadataFile = Join-Path $backupPath "metadata.json"
        if (-not (Test-Path $metadataFile)) {
            throw "Backup metadata not found"
        }
        
        $metadata = Get-Content $metadataFile | ConvertFrom-Json
        
        if ($PSCmdlet.ShouldProcess("Documentation", "Restore from backup $BackupId")) {
            Write-Host "Restoring documentation from backup: $BackupId" -ForegroundColor Cyan
            
            foreach ($originalPath in $metadata.Paths) {
                $backupItemPath = Join-Path $backupPath (Split-Path $originalPath -Leaf)
                
                if (Test-Path $backupItemPath) {
                    if (Test-Path $originalPath) {
                        if ($Force) {
                            Remove-Item -Path $originalPath -Recurse -Force
                        } else {
                            throw "Path '$originalPath' already exists. Use -Force to overwrite."
                        }
                    }
                    
                    $parentDir = Split-Path $originalPath -Parent
                    if ($parentDir -and -not (Test-Path $parentDir)) {
                        New-Item -Path $parentDir -ItemType Directory -Force | Out-Null
                    }
                    
                    Copy-Item -Path $backupItemPath -Destination $originalPath -Recurse -Force
                    Write-Host "Restored: $originalPath" -ForegroundColor Green
                }
            }
            
            Write-Host "Documentation restored successfully from backup: $BackupId" -ForegroundColor Green
        }
        
        # Cleanup extracted files if they were compressed
        if ($isCompressed) {
            Remove-Item -Path $backupPath -Recurse -Force
        }
        
        return $metadata
        
    } catch {
        Write-Error "Failed to restore documentation backup: $_"
        throw
    }
}

function Get-DocumentationHistory {
    <#
    .SYNOPSIS
        Gets documentation backup history
    .DESCRIPTION
        Returns list of available backups with metadata
    .PARAMETER Limit
        Maximum number of backups to return
    .EXAMPLE
        Get-DocumentationHistory -Limit 10
    #>
    [CmdletBinding()]
    param(
        [int]$Limit = 20
    )
    
    try {
        $backupLocation = $script:DocumentationAutomationConfig.BackupLocation
        if (-not (Test-Path $backupLocation)) {
            return @()
        }
        
        $backups = @()
        
        # Get backup directories
        $backupDirs = Get-ChildItem -Path $backupLocation -Directory | Where-Object { $_.Name -like 'backup-*' }
        foreach ($dir in $backupDirs) {
            $metadataFile = Join-Path $dir.FullName "metadata.json"
            if (Test-Path $metadataFile) {
                $metadata = Get-Content $metadataFile | ConvertFrom-Json
                $backups += $metadata
            }
        }
        
        # Get compressed backups
        $zipFiles = Get-ChildItem -Path $backupLocation -File -Filter "backup-*.zip"
        foreach ($zip in $zipFiles) {
            try {
                # Extract just the metadata
                $tempDir = Join-Path $env:TEMP "temp-backup-extract"
                Expand-Archive -Path $zip.FullName -DestinationPath $tempDir -Force
                
                $metadataFile = Join-Path $tempDir "metadata.json"
                if (Test-Path $metadataFile) {
                    $metadata = Get-Content $metadataFile | ConvertFrom-Json
                    $metadata.Compressed = $true
                    $backups += $metadata
                }
                
                Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            } catch {
                Write-Verbose "Could not read metadata from $($zip.Name): $_"
            }
        }
        
        return $backups | Sort-Object CreatedAt -Descending | Select-Object -First $Limit
        
    } catch {
        Write-Error "Error getting documentation history: $_"
        throw
    }
}

function Test-RollbackCapability {
    <#
    .SYNOPSIS
        Tests rollback capability of documentation system
    .DESCRIPTION
        Validates that backups can be successfully restored
    .PARAMETER BackupId
        Specific backup to test (tests latest if not specified)
    .EXAMPLE
        Test-RollbackCapability -BackupId "backup-20250825-143022"
    #>
    [CmdletBinding()]
    param(
        [string]$BackupId
    )
    
    try {
        Write-Host "Testing documentation rollback capability..." -ForegroundColor Cyan
        
        $results = @{
            TestPassed = $true
            Issues = @()
            BackupsTested = 0
            ValidBackups = 0
        }
        
        if ($BackupId) {
            $backupsToTest = @($BackupId)
        } else {
            # Test the 3 most recent backups
            $allBackups = Get-DocumentationHistory -Limit 3
            $backupsToTest = $allBackups | Select-Object -ExpandProperty Id
        }
        
        foreach ($testBackupId in $backupsToTest) {
            $results.BackupsTested++
            
            try {
                $backupPath = Join-Path $script:DocumentationAutomationConfig.BackupLocation $testBackupId
                $zipPath = "$backupPath.zip"
                
                # Check if backup exists
                if (-not (Test-Path $backupPath) -and -not (Test-Path $zipPath)) {
                    $results.Issues += "Backup '$testBackupId' not found"
                    $results.TestPassed = $false
                    continue
                }
                
                # Test metadata readability
                $isCompressed = Test-Path $zipPath
                if ($isCompressed) {
                    $tempDir = Join-Path $env:TEMP "rollback-test-$(Get-Date -Format 'HHmmss')"
                    Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force
                    $metadataFile = Join-Path $tempDir "metadata.json"
                } else {
                    $metadataFile = Join-Path $backupPath "metadata.json"
                }
                
                if (-not (Test-Path $metadataFile)) {
                    $results.Issues += "Metadata not found for backup '$testBackupId'"
                    $results.TestPassed = $false
                } else {
                    try {
                        $metadata = Get-Content $metadataFile | ConvertFrom-Json
                        
                        # Validate metadata structure
                        $requiredFields = @('Id', 'CreatedAt', 'Paths', 'BackupPath')
                        foreach ($field in $requiredFields) {
                            if (-not $metadata.$field) {
                                $results.Issues += "Missing '$field' in metadata for backup '$testBackupId'"
                                $results.TestPassed = $false
                            }
                        }
                        
                        if ($results.TestPassed) {
                            $results.ValidBackups++
                        }
                        
                    } catch {
                        $results.Issues += "Invalid metadata format in backup '$testBackupId': $_"
                        $results.TestPassed = $false
                    }
                }
                
                # Cleanup temp extraction
                if ($isCompressed -and $tempDir -and (Test-Path $tempDir)) {
                    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
                }
                
            } catch {
                $results.Issues += "Error testing backup '$testBackupId': $_"
                $results.TestPassed = $false
            }
        }
        
        if ($results.TestPassed) {
            Write-Host "Rollback capability test PASSED" -ForegroundColor Green
        } else {
            Write-Host "Rollback capability test FAILED" -ForegroundColor Red
        }
        
        Write-Host "  Backups tested: $($results.BackupsTested)" -ForegroundColor Gray
        Write-Host "  Valid backups: $($results.ValidBackups)" -ForegroundColor Gray
        Write-Host "  Issues found: $($results.Issues.Count)" -ForegroundColor Gray
        
        return $results
        
    } catch {
        Write-Error "Failed to test rollback capability: $_"
        throw
    }
}

#endregion

#region Integration Functions

function Sync-WithPredictiveAnalysis {
    <#
    .SYNOPSIS
        Syncs documentation with predictive analysis results
    .DESCRIPTION
        Uses predictive analysis to update documentation based on predictions
    .PARAMETER AnalysisResults
        Results from predictive analysis
    .EXAMPLE
        Sync-WithPredictiveAnalysis -AnalysisResults $results
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $AnalysisResults,
        [switch]$CreatePR
    )
    
    try {
        Write-Host "Syncing documentation with predictive analysis..." -ForegroundColor Cyan
        
        $changes = @()
        
        # Process roadmap recommendations
        if ($AnalysisResults.Roadmap) {
            $roadmapDoc = @"
# Improvement Roadmap

Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Priority Actions
$($AnalysisResults.Roadmap.PriorityActions | ForEach-Object { "- $_" } | Out-String)

## Predicted Maintenance Needs
$($AnalysisResults.MaintenancePredictions | ForEach-Object { "- $($_.File): $($_.Risk) risk" } | Out-String)

## Refactoring Opportunities
$($AnalysisResults.RefactoringOpportunities | ForEach-Object { "- $($_.Type) in $($_.File)" } | Out-String)
"@
            
            $changes += @{
                Type = 'Update'
                Path = '.\docs\IMPROVEMENT_ROADMAP.md'
                Content = $roadmapDoc
            }
        }
        
        if ($changes.Count -gt 0) {
            # Apply changes
            foreach ($change in $changes) {
                $dir = Split-Path $change.Path -Parent
                if ($dir -and -not (Test-Path $dir)) {
                    New-Item -Path $dir -ItemType Directory -Force | Out-Null
                }
                Set-Content -Path $change.Path -Value $change.Content
            }
            
            if ($CreatePR) {
                New-DocumentationPR -Title "docs: Sync with predictive analysis" -Changes $changes
            }
        }
        
        Write-Host "Documentation synced with predictive analysis" -ForegroundColor Green
        
        return $changes
        
    } catch {
        Write-Error "Failed to sync with predictive analysis: $_"
        throw
    }
}

function Update-FromCodeChanges {
    <#
    .SYNOPSIS
        Updates documentation based on code changes
    .DESCRIPTION
        Analyzes code changes and updates relevant documentation
    .PARAMETER ChangedFiles
        List of changed files to process
    .EXAMPLE
        Update-FromCodeChanges -ChangedFiles $files
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$ChangedFiles,
        [switch]$AutoCommit,
        [switch]$CreatePR
    )
    
    try {
        Write-Host "Updating documentation from code changes..." -ForegroundColor Cyan
        
        $changes = @()
        
        foreach ($file in $ChangedFiles) {
            if (-not (Test-Path $file)) {
                Write-Warning "File not found: $file"
                continue
            }
            
            # Determine documentation path
            $docPath = switch -Regex ($file) {
                '\.psm?1$' { $file -replace '\.ps(m?)1$', '.md' -replace '\\Modules\\', '\docs\api\' }
                '\.cs$' { $file -replace '\.cs$', '.md' -replace '\\Scripts\\', '\docs\api\' }
                default { $null }
            }
            
            if (-not $docPath) {
                Write-Verbose "No documentation mapping for file: $file"
                continue
            }
            
            # Generate documentation content
            $fileInfo = Get-Item $file
            $content = @"
# $($fileInfo.BaseName)

**File:** $($fileInfo.Name)  
**Path:** $($fileInfo.FullName)  
**Last Modified:** $($fileInfo.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))  

## Overview

This documentation was automatically generated from code analysis.

## Details

*Auto-generated content based on source file structure and metadata.*

---
*Generated by Unity-Claude Documentation Automation*
"@
            
            $changes += @{
                Type = if (Test-Path $docPath) { 'Update' } else { 'Create' }
                Path = $docPath
                Content = $content
                SourceFile = $file
            }
        }
        
        if ($changes.Count -gt 0) {
            # Apply changes
            foreach ($change in $changes) {
                $dir = Split-Path $change.Path -Parent
                if ($dir -and -not (Test-Path $dir)) {
                    New-Item -Path $dir -ItemType Directory -Force | Out-Null
                }
                Set-Content -Path $change.Path -Value $change.Content
                Write-Host "$($change.Type): $($change.Path)" -ForegroundColor Green
            }
            
            if ($AutoCommit) {
                git add .
                git commit -m "docs: Auto-update from code changes"
                Write-Host "Changes committed automatically" -ForegroundColor Green
            }
            
            if ($CreatePR) {
                New-DocumentationPR -Title "docs: Update from code changes" -Changes $changes
            }
        }
        
        Write-Host "Documentation updated from code changes" -ForegroundColor Green
        Write-Host "  Files processed: $($ChangedFiles.Count)" -ForegroundColor Gray
        Write-Host "  Documentation updated: $($changes.Count)" -ForegroundColor Gray
        
        return $changes
        
    } catch {
        Write-Error "Failed to update documentation from code changes: $_"
        throw
    }
}

function Generate-ImprovementDocs {
    <#
    .SYNOPSIS
        Generates improvement documentation from analysis
    .DESCRIPTION
        Creates comprehensive improvement documentation from various analysis sources
    .PARAMETER AnalysisData
        Combined analysis data from multiple sources
    .EXAMPLE
        Generate-ImprovementDocs -AnalysisData $analysis
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $AnalysisData,
        [string]$OutputPath = '.\docs\IMPROVEMENTS.md',
        [switch]$IncludeMetrics
    )
    
    try {
        Write-Host "Generating improvement documentation..." -ForegroundColor Cyan
        
        $content = @"
# System Improvement Documentation

Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Executive Summary

This document contains improvement recommendations based on automated analysis
of the Unity-Claude-Automation system.

"@
        
        # Add technical debt analysis
        if ($AnalysisData.TechnicalDebt) {
            $content += @"

## Technical Debt Analysis

### High Priority Issues
$($AnalysisData.TechnicalDebt.HighPriority | ForEach-Object { "- $_" } | Out-String)

### Medium Priority Issues
$($AnalysisData.TechnicalDebt.MediumPriority | ForEach-Object { "- $_" } | Out-String)

### Code Complexity Metrics
- Average Cyclomatic Complexity: $($AnalysisData.TechnicalDebt.AvgComplexity)
- Files Above Threshold: $($AnalysisData.TechnicalDebt.ComplexFiles.Count)
- Total Lines of Code: $($AnalysisData.TechnicalDebt.TotalLOC)

"@
        }
        
        # Add performance analysis
        if ($AnalysisData.Performance) {
            $content += @"

## Performance Analysis

### Bottlenecks Identified
$($AnalysisData.Performance.Bottlenecks | ForEach-Object { "- $($_.Function): $($_.AverageTime)ms" } | Out-String)

### Optimization Opportunities
$($AnalysisData.Performance.Optimizations | ForEach-Object { "- $_" } | Out-String)

"@
        }
        
        # Add security analysis
        if ($AnalysisData.Security) {
            $content += @"

## Security Review

### Recommendations
$($AnalysisData.Security.Recommendations | ForEach-Object { "- $_" } | Out-String)

### Best Practices
$($AnalysisData.Security.BestPractices | ForEach-Object { "- $_" } | Out-String)

"@
        }
        
        $content += @"

## Implementation Roadmap

### Phase 1: Critical Issues (Week 1-2)
- Address high-priority technical debt
- Fix performance bottlenecks
- Implement security recommendations

### Phase 2: Optimization (Week 3-4)
- Refactor complex functions
- Optimize data structures
- Improve error handling

### Phase 3: Enhancement (Week 5-6)
- Add new features
- Improve documentation
- Expand test coverage

---
*This document is automatically generated and updated based on ongoing system analysis.*
"@
        
        # Create output directory if needed
        $outputDir = Split-Path $OutputPath -Parent
        if ($outputDir -and -not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        # Write documentation
        Set-Content -Path $OutputPath -Value $content -Encoding UTF8
        
        Write-Host "Improvement documentation generated successfully" -ForegroundColor Green
        Write-Host "  Output: $OutputPath" -ForegroundColor Gray
        Write-Host "  Size: $([math]::Round((Get-Item $OutputPath).Length/1KB, 2)) KB" -ForegroundColor Gray
        
        return @{
            OutputPath = $OutputPath
            Size = (Get-Item $OutputPath).Length
            GeneratedAt = Get-Date
        }
        
    } catch {
        Write-Error "Failed to generate improvement documentation: $_"
        throw
    }
}

function Export-DocumentationReport {
    <#
    .SYNOPSIS
        Exports comprehensive documentation report
    .DESCRIPTION
        Creates detailed report of documentation automation status and metrics
    .PARAMETER OutputPath
        Path for report output
    .PARAMETER Format
        Report format (JSON, HTML, Text)
    .EXAMPLE
        Export-DocumentationReport -OutputPath ".\reports\doc-report.html" -Format HTML
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$OutputPath,
        [ValidateSet('JSON', 'HTML', 'Text')]
        [string]$Format = 'HTML'
    )
    
    try {
        Write-Host "Generating documentation automation report..." -ForegroundColor Cyan
        
        # Collect data
        $status = Get-DocumentationStatus
        $triggers = Get-DocumentationTriggers
        $prs = Get-DocumentationPRs -Limit 50
        $templates = Get-DocumentationTemplates
        $history = Get-DocumentationHistory -Limit 20
        
        $report = @{
            GeneratedAt = Get-Date
            System = @{
                IsRunning = $status.IsRunning
                LastRunTime = $status.LastRunTime
                TriggerInterval = $status.TriggerInterval
                ActiveJobs = $status.ActiveJobs.Count
                ReviewQueueLength = $status.ReviewQueueLength
            }
            Triggers = @{
                Total = $triggers.Count
                Enabled = ($triggers | Where-Object Enabled).Count
                ByType = $triggers | Group-Object Type | ForEach-Object { @{ Type = $_.Name; Count = $_.Count } }
            }
            PRs = @{
                Total = $prs.Count
                Open = ($prs | Where-Object { $_.Status -eq 'Open' }).Count
                Merged = ($prs | Where-Object { $_.Status -eq 'Merged' }).Count
            }
            Templates = @{
                Total = $templates.Count
                ByType = $templates | Group-Object Type | ForEach-Object { @{ Type = $_.Name; Count = $_.Count } }
            }
            Backups = @{
                Total = $history.Count
                SizeTotal = ($history | Measure-Object Size -Sum).Sum
                OldestBackup = ($history | Sort-Object CreatedAt | Select-Object -First 1).CreatedAt
            }
        }
        
        # Generate output based on format
        switch ($Format) {
            'JSON' {
                $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
            }
            'HTML' {
                $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Documentation Automation Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: #f0f0f0; padding: 20px; border-radius: 5px; }
        .section { margin: 20px 0; }
        .metric { display: inline-block; margin: 10px; padding: 10px; background: #e9e9e9; border-radius: 3px; }
        .status-running { color: green; }
        .status-stopped { color: red; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Documentation Automation Report</h1>
        <p>Generated: $($report.GeneratedAt)</p>
        <p class="status-$($report.System.IsRunning.ToString().ToLower())">
            Status: $(if($report.System.IsRunning) { "Running" } else { "Stopped" })
        </p>
    </div>
    
    <div class="section">
        <h2>System Metrics</h2>
        <div class="metric">Active Jobs: $($report.System.ActiveJobs)</div>
        <div class="metric">Review Queue: $($report.System.ReviewQueueLength)</div>
        <div class="metric">Trigger Interval: $($report.System.TriggerInterval) min</div>
    </div>
    
    <div class="section">
        <h2>Triggers</h2>
        <div class="metric">Total: $($report.Triggers.Total)</div>
        <div class="metric">Enabled: $($report.Triggers.Enabled)</div>
    </div>
    
    <div class="section">
        <h2>Pull Requests</h2>
        <div class="metric">Total: $($report.PRs.Total)</div>
        <div class="metric">Open: $($report.PRs.Open)</div>
        <div class="metric">Merged: $($report.PRs.Merged)</div>
    </div>
    
    <div class="section">
        <h2>Templates</h2>
        <div class="metric">Total: $($report.Templates.Total)</div>
    </div>
    
    <div class="section">
        <h2>Backups</h2>
        <div class="metric">Total: $($report.Backups.Total)</div>
        <div class="metric">Size: $([math]::Round($report.Backups.SizeTotal/1MB, 2)) MB</div>
    </div>
</body>
</html>
"@
                $html | Out-File -FilePath $OutputPath -Encoding UTF8
            }
            'Text' {
                $text = @"
DOCUMENTATION AUTOMATION REPORT
===============================
Generated: $($report.GeneratedAt)

SYSTEM STATUS
- Running: $($report.System.IsRunning)
- Last Run: $($report.System.LastRunTime)
- Trigger Interval: $($report.System.TriggerInterval) minutes
- Active Jobs: $($report.System.ActiveJobs)
- Review Queue: $($report.System.ReviewQueueLength)

TRIGGERS
- Total: $($report.Triggers.Total)
- Enabled: $($report.Triggers.Enabled)

PULL REQUESTS
- Total: $($report.PRs.Total)
- Open: $($report.PRs.Open)
- Merged: $($report.PRs.Merged)

TEMPLATES
- Total: $($report.Templates.Total)

BACKUPS
- Total: $($report.Backups.Total)
- Total Size: $([math]::Round($report.Backups.SizeTotal/1MB, 2)) MB
- Oldest: $($report.Backups.OldestBackup)
"@
                $text | Out-File -FilePath $OutputPath -Encoding UTF8
            }
        }
        
        Write-Host "Documentation report exported successfully" -ForegroundColor Green
        Write-Host "  Format: $Format" -ForegroundColor Gray
        Write-Host "  Output: $OutputPath" -ForegroundColor Gray
        
        return $report
        
    } catch {
        Write-Error "Failed to export documentation report: $_"
        throw
    }
}

#endregion

Export-ModuleMember -Function @(
    'New-DocumentationBackup',
    'Restore-DocumentationBackup',
    'Get-DocumentationHistory',
    'Test-RollbackCapability',
    'Sync-WithPredictiveAnalysis',
    'Update-FromCodeChanges',
    'Generate-ImprovementDocs',
    'Export-DocumentationReport'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDaNypvLGtXPHeX
# v3U/5VBRH/lslBC0dRdOrVqrHyHKg6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCSqGSIb3DQEBCwUAMC4xLDAqBgNVBAMMI1VuaXR5LUNsYXVk
# ZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MB4XDTI1MDgyMDIxMTUxN1oXDTI2MDgy
# MDIxMzUxN1owLjEsMCoGA1UEAwwjVW5pdHktQ2xhdWRlLUF1dG9tYXRpb24tRGV2
# ZWxvcG1lbnQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCx4feqKdUQ
# 6GufY4umNzlM1Pi8aHUGR8HlfhIWFjsrRAxCxhieRlWbHe0Hw+pVBeX76X57e5Pu
# 4Kxxzu+MxMry0NJYf3yOLRTfhYskHBcLraXUCtrMwqnhPKvul6Sx6Lu8vilk605W
# ADJNifl3WFuexVCYJJM9G2mfuYIDN+rZ5zmpn0qCXum49bm629h+HyJ205Zrn9aB
# hIrA4i/JlrAh1kosWnCo62psl7ixbNVqFqwWEt+gAqSeIo4ChwkOQl7GHmk78Q5I
# oRneY4JTVlKzhdZEYhJGFXeoZml/5jcmUcox4UNYrKdokE7z8ZTmyowBOUNS+sHI
# G1TY5DZSb8vdAgMBAAGjRjBEMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggr
# BgEFBQcDAzAdBgNVHQ4EFgQUfDms7LrGVboHjmwlSyIjYD/JLQwwDQYJKoZIhvcN
# AQELBQADggEBABRMsfT7DzKy+aFi4HDg0MpxmbjQxOH1lzUzanaECRiyA0sn7+sA
# /4jvis1+qC5NjDGkLKOTCuDzIXnBWLCCBugukXbIO7g392ANqKdHjBHw1WlLvMVk
# 4WSmY096lzpvDd3jJApr/Alcp4KmRGNLnQ3vv+F9Uj58Uo1qjs85vt6fl9xe5lo3
# rFahNHL4ngjgyF8emNm7FItJeNtVe08PhFn0caOX0FTzXrZxGGO6Ov8tzf91j/qK
# QdBifG7Fx3FF7DifNqoBBo55a7q0anz30k8p+V0zllrLkgGXfOzXmA1L37Qmt3QB
# FCdJVigjQMuHcrJsWd8rg857Og0un91tfZIxggH0MIIB8AIBATBCMC4xLDAqBgNV
# BAMMI1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50AhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKA
# AKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIEPx/ohlf3hrVG2run0kWToQ
# /MHi/2DYyQq5CIdalrzTMA0GCSqGSIb3DQEBAQUABIIBABnedAmg0StA4w6ZZsIa
# zXSZgC7651Cg9GMwy6RUS8gUNhs5JdzTBGQ/NhfWsLft5zH47OkzzdN6dd3XIG23
# 5RjcsyzxTR6ScsiCRfUPTw7Oq3fSvngTciglYorEb8++mzmeQ+LP+fKsftDdJchO
# OOZxFqF3NObVWe08OtncCBn56Zw7Br2qYPEfLbYUr9VdzhmhRsq8FBKE4GLOxmNp
# hwIF+d3bemW8FVnwbY2AuZpPSIGihpaYmt8FBxLyZt67bHT8L567trKWjFbgQYnw
# EvSwp1hHp4RG6+0h/8dz6VFoAMI6bDP5Y/NkFlQDUOtqX+FgoZH7gVcpiDobnMrV
# gq0=
# SIG # End signature block
