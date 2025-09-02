# Update-UnifiedSystemNaming.ps1
# Updates all UnifiedSystem scripts to use CLIOrchestrator instead of AutonomousAgent
# Date: 2025-08-25

param(
    [switch]$DryRun = $false
)

$ErrorActionPreference = 'Stop'

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Updating UnifiedSystem Scripts to CLIOrchestrator" -ForegroundColor Cyan
Write-Host "Dry Run: $DryRun" -ForegroundColor Magenta
Write-Host "================================================" -ForegroundColor Cyan

# Define the files to update
$filesToUpdate = @(
    "Start-UnifiedSystem.ps1",
    "Start-UnifiedSystem-Complete.ps1",
    "Start-UnifiedSystem-Final.ps1",
    "Start-UnifiedSystem-Fixed.ps1",
    "Start-UnifiedSystem-Simple.ps1",
    "Start-UnifiedSystem-WithCompatibility.ps1"
)

# Define the replacements to make
$replacements = @(
    @{
        Old = '[switch]$SkipAutonomousAgent'
        New = '[switch]$SkipCLIOrchestrator'
    },
    @{
        Old = '-SkipAutonomousAgent'
        New = '-SkipCLIOrchestrator'
    },
    @{
        Old = 'SkipAutonomousAgent'
        New = 'SkipCLIOrchestrator'
    },
    @{
        Old = 'Starting AutonomousAgent...'
        New = 'Starting CLI Orchestrator...'
    },
    @{
        Old = 'Step 4: Starting AutonomousAgent...'
        New = 'Step 4: Starting CLI Orchestrator...'
    },
    @{
        Old = 'Step 3: Starting AutonomousAgent...'
        New = 'Step 3: Starting CLI Orchestrator...'
    },
    @{
        Old = 'Skipping AutonomousAgent'
        New = 'Skipping CLI Orchestrator'
    },
    @{
        Old = 'AutonomousAgent already'
        New = 'CLI Orchestrator already'
    },
    @{
        Old = 'AutonomousAgent monitoring'
        New = 'CLI Orchestrator monitoring'
    },
    @{
        Old = 'AutonomousAgent module'
        New = 'CLI Orchestrator module'
    },
    @{
        Old = 'AutonomousAgent registered'
        New = 'CLI Orchestrator registered'
    },
    @{
        Old = 'AutonomousAgent is'
        New = 'CLI Orchestrator is'
    },
    @{
        Old = 'AutonomousAgent RESTARTED'
        New = 'CLI Orchestrator RESTARTED'
    },
    @{
        Old = 'restart AutonomousAgent'
        New = 'restart CLI Orchestrator'
    },
    @{
        Old = 'AutonomousAgent: PID'
        New = 'CLI Orchestrator: PID'
    },
    @{
        Old = 'AutonomousAgent: Not'
        New = 'CLI Orchestrator: Not'
    },
    @{
        Old = 'AutonomousAgent: Visible'
        New = 'CLI Orchestrator: Visible'
    },
    @{
        Old = 'AutonomousAgent window'
        New = 'CLI Orchestrator window'
    },
    @{
        Old = 'Unity-Claude-AutonomousAgent'
        New = 'Unity-Claude-CLIOrchestrator'
    },
    @{
        Old = 'Unity-Claude-AutonomousAgent-Refactored'
        New = 'Unity-Claude-CLIOrchestrator'
    },
    @{
        Old = 'Test-AutonomousAgentStatus'
        New = 'Test-CLIOrchestratorStatus'
    },
    @{
        Old = 'Start-AutonomousAgentSafe'
        New = 'Start-CLIOrchestratorSafe'
    },
    @{
        Old = 'AutonomousAgent*.ps1'
        New = 'CLIOrchestrator*.ps1'
    },
    @{
        Old = 'Start-AutonomousMonitoring.ps1'
        New = 'Start-CLIOrchestrator.ps1'
    },
    @{
        Old = 'Start-AutonomousMonitoring-Fixed.ps1'
        New = 'Start-CLIOrchestrator-Fixed.ps1'
    },
    @{
        Old = 'Start-AutonomousMonitoring-Enhanced.ps1'
        New = 'Start-CLIOrchestrator-Enhanced.ps1'
    },
    @{
        Old = '"AutonomousAgent"'
        New = '"CLIOrchestrator"'
    },
    @{
        Old = '.subsystems.AutonomousAgent'
        New = '.subsystems.CLIOrchestrator'
    },
    @{
        Old = 'subsystems["Unity-Claude-AutonomousAgent"]'
        New = 'subsystems["Unity-Claude-CLIOrchestrator"]'
    },
    @{
        Old = 'subsystems.ContainsKey("AutonomousAgent")'
        New = 'subsystems.ContainsKey("CLIOrchestrator")'
    },
    @{
        Old = 'subsystems.Remove("AutonomousAgent")'
        New = 'subsystems.Remove("CLIOrchestrator")'
    },
    @{
        Old = 'SystemStatus|AutonomousAgent'
        New = 'SystemStatus|CLIOrchestrator'
    },
    @{
        Old = '# Unified startup for SystemStatusMonitoring and AutonomousAgent'
        New = '# Unified startup for SystemStatusMonitoring and CLI Orchestrator'
    }
)

$totalUpdates = 0

foreach ($fileName in $filesToUpdate) {
    $filePath = Join-Path "." $fileName
    
    if (-not (Test-Path $filePath)) {
        Write-Host "  File not found: $fileName" -ForegroundColor Yellow
        continue
    }
    
    Write-Host "`nProcessing: $fileName" -ForegroundColor Cyan
    
    try {
        $content = Get-Content $filePath -Raw
        $originalContent = $content
        $fileUpdates = 0
        
        foreach ($replacement in $replacements) {
            $matches = [regex]::Matches($content, [regex]::Escape($replacement.Old))
            if ($matches.Count -gt 0) {
                if ($DryRun) {
                    Write-Host "  [DRY RUN] Would replace '$($replacement.Old)' ($($matches.Count) occurrences)" -ForegroundColor Gray
                } else {
                    $content = $content -replace [regex]::Escape($replacement.Old), $replacement.New
                    Write-Host "  Replaced: '$($replacement.Old)' -> '$($replacement.New)' ($($matches.Count) occurrences)" -ForegroundColor Green
                }
                $fileUpdates += $matches.Count
            }
        }
        
        if ($fileUpdates -gt 0) {
            if (-not $DryRun) {
                # Create backup
                $backupPath = "$filePath.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
                Copy-Item -Path $filePath -Destination $backupPath -Force
                
                # Save updated content
                Set-Content -Path $filePath -Value $content -Force
                Write-Host "  Total updates: $fileUpdates" -ForegroundColor Green
                Write-Host "  Backup created: $backupPath" -ForegroundColor Gray
            } else {
                Write-Host "  [DRY RUN] Would make $fileUpdates updates" -ForegroundColor Gray
            }
            $totalUpdates += $fileUpdates
        } else {
            Write-Host "  No changes needed" -ForegroundColor Gray
        }
        
    } catch {
        Write-Host "  Error processing $fileName : $_" -ForegroundColor Red
    }
}

Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "Update Summary" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "DRY RUN COMPLETE - No actual changes made" -ForegroundColor Yellow
    Write-Host "Would update $totalUpdates references across $($filesToUpdate.Count) files" -ForegroundColor Yellow
    Write-Host "Run without -DryRun flag to apply changes" -ForegroundColor Yellow
} else {
    Write-Host "Successfully updated $totalUpdates references!" -ForegroundColor Green
    Write-Host "Files processed: $($filesToUpdate.Count)" -ForegroundColor Green
    Write-Host "`nBackup files created with .bak_<timestamp> extension" -ForegroundColor Cyan
}

Write-Host "`nNext Steps:" -ForegroundColor Magenta
Write-Host "1. Test the unified system startup: .\Start-UnifiedSystem-Complete.ps1" -ForegroundColor White
Write-Host "2. Verify CLI Orchestrator integration works correctly" -ForegroundColor White
Write-Host "3. Remove backup files once verified: Remove-Item *.bak_* -Force" -ForegroundColor White
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDcQSVaDC1e+H7r
# EZwHmiSe4UKCN4tV7scozvpB/kGIIqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIFFurnu+nQiINkKwwyIVVm+T
# eVUj/7KuckS0XxYkokUgMA0GCSqGSIb3DQEBAQUABIIBACoOrqgiucQWcxa/1XIR
# B2YE+Fmd63WWgKX1doFaOx/r9/wv9ZDhcnXjkk1YUx7EMmz2ot3FKwW2HnDJw3Ve
# cvzpDTwd2Q4Gmr8y5JH5jN0ErONneDXLGG149iJG/7eGtPi7g0oIYGvplOBvVf1X
# HDqmls/JCvWdUBp/Ioui5UxWE+KUVmhWXk7Dl+fh35Xd5dAflL7DNMDmyY7G6HHq
# u2w/YI2/2Rf+pgFv/J/2YSSWpGijP2n4PwGdxsMIvzZNw1yvbQIUH+Ps9f/wXsTi
# Wpxqgqik+2rxh63O/LPJxF0gAQs0+uDoZJ4WtdHqRKbzzxpllRarPh6wD0FQSLbH
# CTA=
# SIG # End signature block
