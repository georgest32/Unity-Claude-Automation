# Rename-AutonomousMonitoringModule.ps1
# Script to efficiently rename Unity-Claude-AutonomousMonitoring to Unity-Claude-CLIOrchestrator
# Date: 2025-08-25

param(
    [switch]$DryRun = $false,
    [switch]$Backup = $true
)

$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'

# Configuration
$OldModuleName = "Unity-Claude-AutonomousMonitoring"
$NewModuleName = "Unity-Claude-CLIOrchestrator"
$RootPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"
$ModulesPath = Join-Path $RootPath "Modules"
$OldModulePath = Join-Path $ModulesPath $OldModuleName
$NewModulePath = Join-Path $ModulesPath $NewModuleName

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Module Renaming Tool" -ForegroundColor Cyan
Write-Host "From: $OldModuleName" -ForegroundColor Yellow
Write-Host "To:   $NewModuleName" -ForegroundColor Green
Write-Host "Dry Run: $DryRun" -ForegroundColor Magenta
Write-Host "================================================" -ForegroundColor Cyan

# Step 1: Create backup if requested
if ($Backup -and -not $DryRun) {
    $BackupPath = Join-Path $RootPath "Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Write-Host "`nCreating backup at: $BackupPath" -ForegroundColor Yellow
    
    New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
    
    # Backup the module directory
    if (Test-Path $OldModulePath) {
        Copy-Item -Path $OldModulePath -Destination $BackupPath -Recurse -Force
        Write-Host "  - Backed up module directory" -ForegroundColor Green
    }
    
    # Backup scripts that reference the module
    $FilesToBackup = Get-ChildItem -Path $RootPath -Filter "*.ps*" -Recurse -ErrorAction SilentlyContinue | 
        Where-Object { 
            $_.FullName -notlike "*\.venv\*" -and
            $_.FullName -notlike "*\venv\*" -and
            $_.FullName -notlike "*\node_modules\*" -and
            $_.FullName -notlike "*\site\*" -and
            $_.FullName -notlike "*\langgraph-env\*" -and
            $_.FullName -notlike "*\__pycache__\*" -and
            (Select-String -Path $_.FullName -Pattern $OldModuleName -Quiet -ErrorAction SilentlyContinue)
        }
    
    foreach ($File in $FilesToBackup) {
        $RelativePath = $File.FullName.Replace($RootPath, "").TrimStart("\")
        $BackupFilePath = Join-Path $BackupPath $RelativePath
        $BackupFileDir = Split-Path $BackupFilePath -Parent
        
        if (-not (Test-Path $BackupFileDir)) {
            New-Item -ItemType Directory -Path $BackupFileDir -Force | Out-Null
        }
        
        Copy-Item -Path $File.FullName -Destination $BackupFilePath -Force
    }
    
    Write-Host "  - Backed up $($FilesToBackup.Count) referencing files" -ForegroundColor Green
}

# Step 2: Rename module directory
Write-Host "`nStep 1: Renaming module directory..." -ForegroundColor Cyan
if (Test-Path $OldModulePath) {
    if ($DryRun) {
        Write-Host "  [DRY RUN] Would rename: $OldModulePath -> $NewModulePath" -ForegroundColor Gray
    } else {
        if (Test-Path $NewModulePath) {
            Write-Host "  WARNING: Target path already exists: $NewModulePath" -ForegroundColor Yellow
            $confirm = Read-Host "  Overwrite? (y/n)"
            if ($confirm -ne 'y') {
                Write-Host "  Aborted by user" -ForegroundColor Red
                exit 1
            }
            Remove-Item -Path $NewModulePath -Recurse -Force
        }
        Rename-Item -Path $OldModulePath -NewName $NewModuleName -Force
        Write-Host "  - Renamed module directory" -ForegroundColor Green
    }
} else {
    Write-Host "  - Module directory not found: $OldModulePath" -ForegroundColor Red
}

# Step 3: Rename module files
Write-Host "`nStep 2: Renaming module files..." -ForegroundColor Cyan
$ModuleFiles = @(
    @{ Old = "$OldModuleName.psd1"; New = "$NewModuleName.psd1" }
    @{ Old = "$OldModuleName.psm1"; New = "$NewModuleName.psm1" }
)

foreach ($FileMap in $ModuleFiles) {
    $OldFile = Join-Path $NewModulePath $FileMap.Old
    $NewFile = Join-Path $NewModulePath $FileMap.New
    
    if (Test-Path $OldFile) {
        if ($DryRun) {
            Write-Host "  [DRY RUN] Would rename: $($FileMap.Old) -> $($FileMap.New)" -ForegroundColor Gray
        } else {
            Rename-Item -Path $OldFile -NewName $FileMap.New -Force
            Write-Host "  - Renamed: $($FileMap.Old) -> $($FileMap.New)" -ForegroundColor Green
        }
    }
}

# Step 4: Update content within module files
Write-Host "`nStep 3: Updating module file contents..." -ForegroundColor Cyan
if (-not $DryRun) {
    # Update .psd1 file
    $PsdPath = Join-Path $NewModulePath "$NewModuleName.psd1"
    if (Test-Path $PsdPath) {
        $Content = Get-Content $PsdPath -Raw
        $Content = $Content -replace $OldModuleName, $NewModuleName
        Set-Content -Path $PsdPath -Value $Content -Force
        Write-Host "  - Updated manifest file (.psd1)" -ForegroundColor Green
    }
    
    # Update .psm1 file
    $PsmPath = Join-Path $NewModulePath "$NewModuleName.psm1"
    if (Test-Path $PsmPath) {
        $Content = Get-Content $PsmPath -Raw
        $Content = $Content -replace $OldModuleName, $NewModuleName
        Set-Content -Path $PsmPath -Value $Content -Force
        Write-Host "  - Updated module file (.psm1)" -ForegroundColor Green
    }
}

# Step 5: Find and update all references
Write-Host "`nStep 4: Finding and updating references..." -ForegroundColor Cyan
$ReferencingFiles = Get-ChildItem -Path $RootPath -Include "*.ps1","*.psm1","*.psd1","*.md" -Recurse -ErrorAction SilentlyContinue |
    Where-Object { 
        $_.FullName -notlike "*\Backup_*" -and
        $_.FullName -notlike "*\.venv\*" -and
        $_.FullName -notlike "*\venv\*" -and
        $_.FullName -notlike "*\node_modules\*" -and
        $_.FullName -notlike "*\site\*" -and
        $_.FullName -notlike "*\langgraph-env\*" -and
        $_.FullName -notlike "*\__pycache__\*" -and
        (Select-String -Path $_.FullName -Pattern $OldModuleName -Quiet -ErrorAction SilentlyContinue)
    }

Write-Host "  Found $($ReferencingFiles.Count) files with references" -ForegroundColor Yellow

$UpdatedCount = 0
foreach ($File in $ReferencingFiles) {
    if ($DryRun) {
        Write-Host "  [DRY RUN] Would update: $($File.FullName)" -ForegroundColor Gray
    } else {
        try {
            $Content = Get-Content $File.FullName -Raw
            $UpdatedContent = $Content -replace $OldModuleName, $NewModuleName
            
            if ($Content -ne $UpdatedContent) {
                Set-Content -Path $File.FullName -Value $UpdatedContent -Force
                $UpdatedCount++
                Write-Host "  - Updated: $($File.Name)" -ForegroundColor Green
            }
        } catch {
            Write-Host "  - Error updating $($File.Name): $_" -ForegroundColor Red
        }
    }
}

if (-not $DryRun) {
    Write-Host "  Updated $UpdatedCount files" -ForegroundColor Green
}

# Step 6: Update Start scripts specifically
Write-Host "`nStep 5: Updating Start scripts..." -ForegroundColor Cyan
$StartScripts = @(
    "Start-AutonomousMonitoring.ps1",
    "Start-AutonomousMonitoring-Fixed.ps1",
    "Start-AutonomousMonitoring-Enhanced.ps1"
)

foreach ($ScriptName in $StartScripts) {
    $OldScript = Join-Path $RootPath $ScriptName
    if (Test-Path $OldScript) {
        $NewScriptName = $ScriptName -replace "AutonomousMonitoring", "CLIOrchestrator"
        $NewScript = Join-Path $RootPath $NewScriptName
        
        if ($DryRun) {
            Write-Host "  [DRY RUN] Would rename script: $ScriptName -> $NewScriptName" -ForegroundColor Gray
        } else {
            # First update content
            $Content = Get-Content $OldScript -Raw
            $Content = $Content -replace $OldModuleName, $NewModuleName
            $Content = $Content -replace "AutonomousMonitoring", "CLIOrchestrator"
            $Content = $Content -replace "autonomous monitoring", "CLI orchestration"
            $Content = $Content -replace "Autonomous Monitoring", "CLI Orchestrator"
            
            # Save with new name
            Set-Content -Path $NewScript -Value $Content -Force
            
            # Remove old file
            Remove-Item -Path $OldScript -Force
            
            Write-Host "  - Renamed and updated: $ScriptName -> $NewScriptName" -ForegroundColor Green
        }
    }
}

# Step 7: Summary
Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "Renaming Summary" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "DRY RUN COMPLETE - No actual changes made" -ForegroundColor Yellow
    Write-Host "Run without -DryRun flag to apply changes" -ForegroundColor Yellow
} else {
    Write-Host "Module successfully renamed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Old Name: $OldModuleName" -ForegroundColor Yellow
    Write-Host "New Name: $NewModuleName" -ForegroundColor Green
    Write-Host ""
    Write-Host "Updated:" -ForegroundColor Cyan
    Write-Host "  - Module directory and files" -ForegroundColor White
    Write-Host "  - $UpdatedCount referencing files" -ForegroundColor White
    Write-Host "  - Start scripts renamed" -ForegroundColor White
    
    if ($Backup) {
        Write-Host ""
        Write-Host "Backup created at: $BackupPath" -ForegroundColor Cyan
    }
}

Write-Host "`nNext Steps:" -ForegroundColor Magenta
Write-Host "1. Test the renamed module: Import-Module $NewModulePath\$NewModuleName.psd1" -ForegroundColor White
Write-Host "2. Run any existing tests to verify functionality" -ForegroundColor White
Write-Host "3. Update any external documentation or references" -ForegroundColor White
Write-Host "4. Commit changes to version control" -ForegroundColor White