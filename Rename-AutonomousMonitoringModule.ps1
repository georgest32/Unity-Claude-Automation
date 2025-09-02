# Rename-AutonomousMonitoringModule.ps1
# Script to efficiently rename Unity-Claude-CLIOrchestrator to Unity-Claude-CLIOrchestrator
# Date: 2025-08-25

param(
    [switch]$DryRun = $false,
    [switch]$Backup = $true
)

$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'

# Configuration
$OldModuleName = "Unity-Claude-CLIOrchestrator"
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

# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDbV0x6241iLGCU
# vy0nLsEXXvF+P7XKSXzQpyD+h1zBJqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEINbF6V23lVqnOQ2Yw4rTd50t
# 129V6D9dRw6YFwhV06EOMA0GCSqGSIb3DQEBAQUABIIBAEoTitptNcXBUuVnvOP8
# de4DPKbxK62k+sVicPS3/9HTTJ99konzBaygFAQnehqHUMY311aMecSyQQUaN2N/
# gF4c/EITy+8/ADKbNttPyIDGlLaqf6TxcmVfC5kqweRdccGbIKVh3eTioswMw6q1
# n1ysw30kcpRItZ26c4djqBQKTAeazFjZ5DlQm9UIyN7ANVfjxaBX3+yxOo4uVftX
# Fn7hvbjU0FzQICY4WWllxwpIk2/FZV2+7QsG/FC95O+Y7Op8ljG0lrKSaeSjDrMa
# n2WoPvloEvAOEdtPhP6KjF8o1YbqccRezRFUu7QVD9Ccs8KSZuK6+9XpmNI/oNIV
# W1I=
# SIG # End signature block
