# Unity-Claude-Automation.ps1
# Main orchestrator script using modular architecture
# Replaces the monolithic unity_claude_automation.ps1

[CmdletBinding()]
param(
    # Operation modes
    [switch]$Loop,
    [switch]$RunOnce,
    [switch]$TestModules,
    
    # Prompt configuration
    [ValidateSet('Continue','Fix','Explain','Triage','Plan','Review','Debugging','Custom')]
    [string]$PromptType = 'Continue',
    [string]$AdditionalInstructions,
    
    # Claude settings
    [string]$Model = 'sonnet-3.5',
    [string]$ClaudeExe = 'claude',
    
    # Unity configuration
    [string]$UnityExe = 'C:\Program Files\Unity\Hub\Editor\2021.1.14f1\Editor\Unity.exe',
    [string]$ProjectPath = 'C:\UnityProjects\Sound-and-Shoal',
    
    # Boilerplate and logs
    [string]$BoilerplatePath = 'C:\UnityProjects\Sound-and-Shoal\CLAUDE_PROMPT_DIRECTIVES.txt',
    [string]$ConsoleDumpPath = 'C:\UnityProjects\Sound-and-Shoal\ConsoleLogs.txt',
    
    # Timeouts
    [int]$UnityTimeout = 300,
    [int]$ClaudeTimeout = 3600,
    
    # Advanced features
    [switch]$EnableLearning,
    [switch]$EnableDatabase,
    [switch]$GenerateReport,
    [switch]$Verbose
)

$ErrorActionPreference = 'Stop'

#region Module Loading

Write-Host "Unity-Claude Automation System v2.0 (Modular)" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# Add modules to path
$modulePath = Join-Path $PSScriptRoot 'Modules'
if ($env:PSModulePath -notlike "*$modulePath*") {
    $env:PSModulePath = "$modulePath;$env:PSModulePath"
    Write-Host "Added module path: $modulePath" -ForegroundColor Gray
}

# Test modules if requested
if ($TestModules) {
    Write-Host "`nRunning module tests..." -ForegroundColor Yellow
    & (Join-Path $PSScriptRoot 'Test-UnityClaudeModules.ps1') -GenerateReport
    return
}

# Load required modules
try {
    Write-Host "`nLoading modules..." -ForegroundColor Yellow
    
    Import-Module Unity-Claude-Core -Force
    Write-Host "  âœ" Unity-Claude-Core loaded" -ForegroundColor Green
    
    Import-Module Unity-Claude-IPC -Force
    Write-Host "  âœ" Unity-Claude-IPC loaded" -ForegroundColor Green
    
    Import-Module Unity-Claude-Errors -Force
    Write-Host "  âœ" Unity-Claude-Errors loaded" -ForegroundColor Green
    
} catch {
    Write-Host "Failed to load modules: $_" -ForegroundColor Red
    Write-Host "Run with -TestModules to diagnose issues" -ForegroundColor Yellow
    exit 1
}

#endregion

#region Initialization

Write-Host "`nInitializing automation context..." -ForegroundColor Yellow

# Initialize core context
$context = Initialize-AutomationContext -ProjectPath $ProjectPath `
                                        -UnityExe $UnityExe `
                                        -DefaultTimeout $UnityTimeout

Write-Log "=== Unity-Claude Automation Started ===" -Level 'INFO'
Write-Log "Project: $ProjectPath" -Level 'INFO'
Write-Log "Unity: $UnityExe" -Level 'INFO'
Write-Log "Mode: $(if ($Loop) { 'Loop' } elseif ($RunOnce) { 'RunOnce' } else { 'Interactive' })" -Level 'INFO'

# Initialize error database if enabled
if ($EnableDatabase) {
    Write-Host "Initializing error database..." -ForegroundColor Yellow
    $dbInitialized = Initialize-ErrorDatabase
    if ($dbInitialized) {
        Write-Host "  âœ" Error database ready" -ForegroundColor Green
    } else {
        Write-Host "  âš  Database unavailable (using memory storage)" -ForegroundColor Yellow
    }
}

# Check Claude availability
Write-Host "Checking Claude CLI..." -ForegroundColor Yellow
$claudeAvailable = Test-ClaudeAvailable -ClaudeExe $ClaudeExe
if ($claudeAvailable) {
    Write-Host "  âœ" Claude CLI available" -ForegroundColor Green
} else {
    Write-Host "  FAILED Claude CLI not found" -ForegroundColor Red
    Write-Host "    Please ensure 'claude' is in PATH or specify -ClaudeExe" -ForegroundColor Yellow
    
    if (-not $RunOnce) {
        exit 1
    }
}

# Install AutoRecompile script
Write-Host "Setting up Unity automation..." -ForegroundColor Yellow
$installed = Install-AutoRecompileScript
if ($installed) {
    Write-Host "  âœ" AutoRecompile script ready" -ForegroundColor Green
} else {
    Write-Host "  FAILED Failed to install AutoRecompile script" -ForegroundColor Red
    exit 1
}

#endregion

#region Main Automation Loop

$continueAutomation = $true
$cycleCount = 0
$maxCycles = 100
$failedStreak = 0
$errorHistory = @()

Write-Host "`nStarting automation..." -ForegroundColor Green
Write-Host "Press Ctrl+C to stop`n" -ForegroundColor Gray

while ($continueAutomation -and $cycleCount -lt $maxCycles) {
    $cycleCount++
    $cycleStart = Get-Date
    
    Write-Log "=== Cycle $cycleCount Started ===" -Level 'INFO'
    Write-Host "`n[Cycle $cycleCount] $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Cyan
    
    # Test Unity compilation
    Write-Host "  Testing Unity compilation..." -ForegroundColor White
    $compilationResult = Test-UnityCompilation -TimeoutSeconds $UnityTimeout
    
    if ($compilationResult.Success) {
        Write-Host "  âœ" Compilation successful!" -ForegroundColor Green
        Write-Log "Unity compilation succeeded" -Level 'OK'
        
        $failedStreak = 0
        
        # Record success in database
        if ($EnableDatabase -and $errorHistory.Count -gt 0) {
            $lastError = $errorHistory[-1]
            if ($lastError.PatternId) {
                $duration = ((Get-Date) - $cycleStart).TotalSeconds
                Update-ErrorSolution -PatternId $lastError.PatternId `
                                    -Solution $lastError.Solution `
                                    -Success $true `
                                    -FixDuration $duration
            }
        }
        
        if ($RunOnce) {
            Write-Host "`nâœ" Unity compilation successful - exiting" -ForegroundColor Green
            break
        }
        
        if (-not $Loop) {
            Write-Host "`nCompilation successful. Continue? (Y/N): " -NoNewline -ForegroundColor Yellow
            $response = Read-Host
            if ($response -notlike 'y*') {
                $continueAutomation = $false
            }
        }
        
    } else {
        Write-Host "  FAILED Compilation failed: $($compilationResult.Reason)" -ForegroundColor Red
        Write-Log "Unity compilation failed: $($compilationResult.Reason)" -Level 'ERROR'
        
        $failedStreak++
        
        # Export and analyze console
        Write-Host "  Exporting Unity console..." -ForegroundColor White
        $exported = Export-UnityConsole -OutputPath $ConsoleDumpPath -TimeoutSeconds 90
        
        if ($exported) {
            Write-Host "  Analyzing errors..." -ForegroundColor White
            
            # Format error context
            $errorContext = Format-ErrorContext -ConsolePath $ConsoleDumpPath `
                                               -EditorLogPath $context.EditorLogPath
            
            # Parse errors for database
            if ($EnableDatabase -and $errorContext) {
                $lines = $errorContext -split "`n"
                foreach ($line in $lines) {
                    if ($line -match 'error CS\d+|Exception') {
                        $parsed = Parse-UnityError -ErrorLine $line
                        if ($parsed.ErrorCode) {
                            Add-ErrorPattern -ErrorCode $parsed.ErrorCode `
                                           -Pattern $line `
                                           -FilePath $parsed.FilePath `
                                           -LineNumber $parsed.LineNumber `
                                           -ErrorType $parsed.Type
                            
                            # Find similar errors
                            $similar = Find-SimilarErrors -ErrorMessage $line -MaxResults 1
                            if ($similar) {
                                Write-Host "    Found similar error pattern in database" -ForegroundColor Yellow
                            }
                        }
                    }
                }
            }
            
            # Split large console logs
            if ((Get-Item $ConsoleDumpPath).Length -gt 200KB) {
                Write-Host "  Splitting large console log..." -ForegroundColor White
                $splitDir = Join-Path $ProjectPath 'Dithering\Assets\ConsoleLogs_Split'
                $splitFiles = Split-ConsoleLog -LogPath $ConsoleDumpPath -OutputDirectory $splitDir
                Write-Host "    Split into $($splitFiles.Count) files" -ForegroundColor Gray
            }
            
            # Determine prompt type based on failure streak
            $currentPromptType = Get-CurrentPromptType -FailedStreak $failedStreak
            if ($currentPromptType -ne $PromptType -and $PromptType -ne 'Custom') {
                Write-Host "    Switching to $currentPromptType mode (failed $failedStreak times)" -ForegroundColor Yellow
                $actualPromptType = $currentPromptType
            } else {
                $actualPromptType = $PromptType
            }
            
            # Invoke Claude analysis
            if ($claudeAvailable) {
                Write-Host "  Sending to Claude for analysis..." -ForegroundColor White
                Write-Host "    Model: $Model | Type: $actualPromptType" -ForegroundColor Gray
                
                $claudeResult = Invoke-ClaudeAnalysis -ErrorContext $errorContext `
                                                      -PromptType $actualPromptType `
                                                      -AdditionalInstructions $AdditionalInstructions `
                                                      -Model $Model `
                                                      -TimeoutSeconds $ClaudeTimeout
                
                if ($claudeResult.Success) {
                    Write-Host "  âœ" Claude provided solution" -ForegroundColor Green
                    
                    # Store in history for database tracking
                    if ($EnableDatabase) {
                        $errorHistory += @{
                            Errors = $errorContext
                            Solution = $claudeResult.Response
                            Timestamp = Get-Date
                        }
                    }
                    
                    # Show snippet of response
                    $snippet = $claudeResult.Response.Substring(0, [Math]::Min(200, $claudeResult.Response.Length))
                    Write-Host "    Response preview: $snippet..." -ForegroundColor Gray
                    
                } else {
                    Write-Host "  FAILED Claude analysis failed: $($claudeResult.Error)" -ForegroundColor Red
                    Write-Log "Claude analysis failed: $($claudeResult.Error)" -Level 'ERROR'
                }
            } else {
                Write-Host "  âš  Skipping Claude analysis (CLI not available)" -ForegroundColor Yellow
            }
            
        } else {
            Write-Host "  FAILED Failed to export Unity console" -ForegroundColor Red
            Write-Log "Console export failed" -Level 'ERROR'
        }
    }
    
    # Check if we should continue
    if (-not $Loop -and -not $RunOnce) {
        Write-Host "`nContinue to next cycle? (Y/N): " -NoNewline -ForegroundColor Yellow
        $response = Read-Host
        if ($response -notlike 'y*') {
            $continueAutomation = $false
        }
    }
    
    # Add delay between cycles
    if ($continueAutomation -and $Loop) {
        $delay = if ($failedStreak -gt 3) { 10 } else { 5 }
        Write-Host "  Waiting $delay seconds..." -ForegroundColor Gray
        Start-Sleep -Seconds $delay
    }
}

#endregion

#region Completion

Write-Host "`n" + ("=" * 60) -ForegroundColor Cyan
Write-Host "AUTOMATION COMPLETE" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Cyan

$duration = (Get-Date) - $context.StartTime
Write-Host "Total Duration: $([Math]::Round($duration.TotalMinutes, 1)) minutes" -ForegroundColor White
Write-Host "Total Cycles: $cycleCount" -ForegroundColor White
Write-Host "Failed Streaks: $failedStreak" -ForegroundColor $(if ($failedStreak -gt 0) { 'Yellow' } else { 'Green' })

Write-Log "=== Automation Completed ===" -Level 'INFO'
Write-Log "Duration: $($duration.TotalMinutes) minutes, Cycles: $cycleCount" -Level 'INFO'

# Generate report if requested
if ($GenerateReport -and $EnableDatabase) {
    Write-Host "`nGenerating error report..." -ForegroundColor Yellow
    $reportPath = Export-ErrorReport -StartDate $context.StartTime -EndDate (Get-Date)
    Write-Host "Report saved to: $reportPath" -ForegroundColor Green
    
    # Open report in browser
    Start-Process $reportPath
}

# Show statistics
if ($EnableDatabase) {
    Write-Host "`nError Statistics:" -ForegroundColor Yellow
    $stats = Get-ErrorStatistics -StartDate $context.StartTime
    
    if ($stats.MostCommon) {
        Write-Host "  Most common errors:" -ForegroundColor White
        $stats.MostCommon | Select-Object -First 3 | ForEach-Object {
            Write-Host "    - $($_.error_code): $($_.total_occurrences) occurrences" -ForegroundColor Gray
        }
    }
    
    if ($stats.BestSolutions) {
        Write-Host "  Most effective solutions:" -ForegroundColor White
        $stats.BestSolutions | Select-Object -First 3 | ForEach-Object {
            $rate = [Math]::Round($_.success_rate, 1)
            Write-Host "    - Success rate: $rate%" -ForegroundColor Gray
        }
    }
}

Write-Host "`nAutomation complete!" -ForegroundColor Green

#endregion

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUUVGnvPuovFX/9JpjI92VN2E6
# Cy+gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
# AQsFADAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0b21hdGlvbi1EZXZlbG9w
# bWVudDAeFw0yNTA4MjAyMTE1MTdaFw0yNjA4MjAyMTM1MTdaMC4xLDAqBgNVBAMM
# I1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEAseH3qinVEOhrn2OLpjc5TNT4vGh1BkfB5X4S
# FhY7K0QMQsYYnkZVmx3tB8PqVQXl++l+e3uT7uCscc7vjMTK8tDSWH98ji0U34WL
# JBwXC62l1ArazMKp4Tyr7peksei7vL4pZOtOVgAyTYn5d1hbnsVQmCSTPRtpn7mC
# Azfq2ec5qZ9Kgl7puPW5utvYfh8idtOWa5/WgYSKwOIvyZawIdZKLFpwqOtqbJe4
# sWzVahasFhLfoAKkniKOAocJDkJexh5pO/EOSKEZ3mOCU1ZSs4XWRGISRhV3qGZp
# f+Y3JlHKMeFDWKynaJBO8/GU5sqMATlDUvrByBtU2OQ2Um/L3QIDAQABo0YwRDAO
# BgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFHw5
# rOy6xlW6B45sJUsiI2A/yS0MMA0GCSqGSIb3DQEBCwUAA4IBAQAUTLH0+w8ysvmh
# YuBw4NDKcZm40MTh9Zc1M2p2hAkYsgNLJ+/rAP+I74rNfqguTYwxpCyjkwrg8yF5
# wViwggboLpF2yDu4N/dgDainR4wR8NVpS7zFZOFkpmNPepc6bw3d4yQKa/wJXKeC
# pkRjS50N77/hfVI+fFKNao7POb7en5fcXuZaN6xWoTRy+J4I4MhfHpjZuxSLSXjb
# VXtPD4RZ9HGjl9BU8162cRhjujr/Lc3/dY/6ikHQYnxuxcdxRew4nzaqAQaOeWu6
# tGp899JPKfldM5Zay5IBl3zs15gNS9+0Jrd0ARQnSVYoI0DLh3KybFnfK4POezoN
# Lp/dbX2SMYIB4zCCAd8CAQEwQjAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0
# b21hdGlvbi1EZXZlbG9wbWVudAIQdR0W2SKoK5VE8JId4ZxrRTAJBgUrDgMCGgUA
# oHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYB
# BAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0B
# CQQxFgQUXrOGzp14wIEHXViu6GFm8tU61r4wDQYJKoZIhvcNAQEBBQAEggEAjSub
# qrqDF2VIPQKF7oYv7O5F6xxMdBs0hOqeWHjZ/j+MoGzoSaT+xzVH5sk2yCiGm2v1
# ljn61lYQ56a6HIij+m6AJWHQTTdRZM1GqNk8NFpiH4FEhEF8ER79tgNP8dN7RgJ3
# yJ9rbZct8OhfcgGAvWJOs4Q/UgcIXRQpYX982aVBMJLdcCTs/LBAbMot57bW6VKy
# Cv3Fe/eLxxUUkSs32GcWZ1pDtlPlcRqFQz0HWmEt1+G5w9W3bB0/+PbbKjOt6nWC
# SczP16iP24yD3ZfyX1KPLp5mP0svPDmw1affgAN+KH6PF3zPeEvVjdDEK96M5q6u
# IaEc7XHt493RJiilRw==
# SIG # End signature block
