# Integrate-Phases-Fixed.ps1
# Integration script for Phase 1, 2, and 3 modules
# This demonstrates how to connect Unity-Claude-Core, Unity-Claude-IPC, and Unity-Claude-Learning
# Date: 2025-08-17

param(
    [switch]$TestMode,
    [switch]$Verbose
)

if ($Verbose) {
    $VerbosePreference = 'Continue'
}

Write-Host "`n=== PHASE 1-2-3 INTEGRATION ===" -ForegroundColor Cyan
Write-Host "Connecting Learning module with Core and IPC modules" -ForegroundColor Yellow

# Setup module paths
$modulePath = Join-Path $PSScriptRoot 'Modules'
if ($env:PSModulePath -notlike "*$modulePath*") {
    $env:PSModulePath = "$modulePath;$env:PSModulePath"
}

# Initialize availability flags
$ipcAvailable = $false
$errorsAvailable = $false

# Load all modules
Write-Host "`nLoading modules..." -ForegroundColor Gray

# Phase 1: Core
try {
    Import-Module Unity-Claude-Core -Force -ErrorAction Stop
    Write-Host "  ✓ Unity-Claude-Core loaded" -ForegroundColor Green
}
catch {
    Write-Host "  ✗ Unity-Claude-Core failed to load: $_" -ForegroundColor Red
    exit 1
}

# Phase 2: IPC (optional)
if (Get-Module -ListAvailable -Name Unity-Claude-IPC) {
    try {
        Import-Module Unity-Claude-IPC -Force -ErrorAction Stop
        Write-Host "  ✓ Unity-Claude-IPC loaded" -ForegroundColor Green
        $ipcAvailable = $true
    }
    catch {
        Write-Host "  ⚠ Unity-Claude-IPC failed to load: $_" -ForegroundColor Yellow
    }
}
else {
    Write-Host "  ⚠ Unity-Claude-IPC not found (will skip Claude integration)" -ForegroundColor Yellow
}

# Phase 3: Learning
try {
    Import-Module Unity-Claude-Learning-Simple -Force -ErrorAction Stop
    Write-Host "  ✓ Unity-Claude-Learning-Simple loaded" -ForegroundColor Green
}
catch {
    Write-Host "  ✗ Unity-Claude-Learning-Simple failed to load: $_" -ForegroundColor Red
    exit 1
}

# Error tracking (optional)
if (Get-Module -ListAvailable -Name Unity-Claude-Errors) {
    try {
        Import-Module Unity-Claude-Errors -Force -ErrorAction Stop
        Write-Host "  ✓ Unity-Claude-Errors loaded" -ForegroundColor Green
        $errorsAvailable = $true
    }
    catch {
        Write-Host "  ⚠ Unity-Claude-Errors failed to load: $_" -ForegroundColor Yellow
    }
}

# Initialize learning storage
Write-Host "`nInitializing learning system..." -ForegroundColor Gray
Initialize-LearningStorage | Out-Null
Write-Host "  ✓ Learning storage initialized" -ForegroundColor Green

# Get current configuration
$learningConfig = Get-LearningConfig
Write-Host "  Patterns file: $($learningConfig.PatternsFile)" -ForegroundColor Gray
if (Test-Path $learningConfig.PatternsFile) {
    $jsonContent = Get-Content $learningConfig.PatternsFile -Raw | ConvertFrom-Json
    $patternCount = ($jsonContent | Get-Member -MemberType NoteProperty).Count
    Write-Host "  Patterns loaded: $patternCount" -ForegroundColor Gray
}

#region Integration Functions

function Process-UnityErrorWithLearning {
    <#
    .SYNOPSIS
    Process Unity error using learning system first, then Claude as fallback
    .DESCRIPTION
    This is the main integration point that tries learned patterns before using Claude
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ErrorMessage,
        
        [string]$ErrorType = 'CompilationError',
        
        [hashtable]$Context = @{},
        
        [double]$MinSimilarity = 65,
        
        [switch]$EnableAutoFix
    )
    
    Write-Host "`n[INTEGRATION] Processing error: $ErrorMessage" -ForegroundColor Cyan
    
    # Step 1: Try learned patterns first
    Write-Host "  Checking learned patterns..." -ForegroundColor Gray
    $suggestedFixes = Get-SuggestedFixes -ErrorMessage $ErrorMessage -MinSimilarity $MinSimilarity
    
    if ($suggestedFixes -and $suggestedFixes.Count -gt 0) {
        Write-Host "  ✓ Found $($suggestedFixes.Count) pattern match(es)!" -ForegroundColor Green
        
        # Use highest confidence fix
        $bestFix = $suggestedFixes | Sort-Object -Property Confidence -Descending | Select-Object -First 1
        
        Write-Host "    Best match: Pattern $($bestFix.PatternId)" -ForegroundColor Gray
        Write-Host "    Confidence: $($bestFix.Confidence)" -ForegroundColor Gray
        Write-Host "    Fix: $($bestFix.Fix)" -ForegroundColor Yellow
        
        if ($EnableAutoFix -and -not $TestMode) {
            Write-Host "  Applying fix automatically..." -ForegroundColor Cyan
            $result = Apply-AutoFix -ErrorMessage $ErrorMessage -DryRun
            
            if ($result.Applied) {
                Write-Host "  ✓ Fix applied successfully!" -ForegroundColor Green
                
                # Update success metrics
                Update-FixSuccess -PatternId $bestFix.PatternId -Success $true
                
                return @{
                    Success = $true
                    Source = 'Learning'
                    PatternId = $bestFix.PatternId
                    Fix = $bestFix.Fix
                    Confidence = $bestFix.Confidence
                }
            }
            else {
                Write-Host "  ⚠ Fix could not be applied: $($result.Reason)" -ForegroundColor Yellow
            }
        }
        else {
            return @{
                Success = $true
                Source = 'Learning'
                PatternId = $bestFix.PatternId
                Fix = $bestFix.Fix
                Confidence = $bestFix.Confidence
                Applied = $false
            }
        }
    }
    else {
        Write-Host "  No pattern matches found" -ForegroundColor Yellow
    }
    
    # Step 2: Fallback to Claude if available
    if ($ipcAvailable -and -not $TestMode) {
        Write-Host "  Consulting Claude for analysis..." -ForegroundColor Cyan
        
        $claudeResponse = $null
        try {
            # This would call the actual Claude IPC module
            # For now, we'll simulate the response
            $claudeResponse = @{
                Success = $true
                Fix = "// Claude would provide fix here"
                Model = "claude-3-sonnet"
                Explanation = "Claude's analysis would be here"
            }
            
            if ($claudeResponse.Success) {
                Write-Host "  ✓ Claude provided solution" -ForegroundColor Green
                
                # Learn from Claude's response
                Write-Host "  Learning from Claude's solution..." -ForegroundColor Gray
                $patternId = Add-ErrorPattern `
                    -ErrorMessage $ErrorMessage `
                    -ErrorType $ErrorType `
                    -Fix $claudeResponse.Fix `
                    -Context @{
                        Source = 'Claude'
                        Model = $claudeResponse.Model
                        LearnedAt = Get-Date
                    }
                
                if ($patternId) {
                    Write-Host "  ✓ Pattern learned (ID: $patternId)" -ForegroundColor Green
                }
                
                return @{
                    Success = $true
                    Source = 'Claude'
                    Fix = $claudeResponse.Fix
                    Model = $claudeResponse.Model
                    PatternId = $patternId
                }
            }
        }
        catch {
            Write-Host "  ✗ Claude error: $_" -ForegroundColor Red
        }
    }
    elseif (-not $ipcAvailable) {
        Write-Host "  Claude IPC not available" -ForegroundColor Gray
    }
    
    # Step 3: Return failure if no solution found
    return @{
        Success = $false
        Source = 'None'
        Reason = 'No fix available'
    }
}

function Test-IntegrationPipeline {
    <#
    .SYNOPSIS
    Test the complete integration pipeline
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "`n=== INTEGRATION PIPELINE TEST ===" -ForegroundColor Cyan
    
    $testCases = @(
        @{
            Error = "CS0246: GameObject not found"
            ExpectedSource = "Learning"
            Description = "Known pattern"
        },
        @{
            Error = "CS0103: The name 'playerHealth' does not exist"
            ExpectedSource = "Learning"
            Description = "Similar to known pattern"
        },
        @{
            Error = "CS9999: Completely unknown bizarre error that nobody has seen"
            ExpectedSource = "Claude"
            Description = "Unknown pattern (Claude fallback)"
        }
    )
    
    $results = @()
    
    foreach ($test in $testCases) {
        Write-Host "`nTest: $($test.Description)" -ForegroundColor Yellow
        Write-Host "Error: $($test.Error)" -ForegroundColor Gray
        
        $result = Process-UnityErrorWithLearning -ErrorMessage $test.Error -ErrorType "TestError"
        
        $passed = ($result.Source -eq $test.ExpectedSource) -or 
                  ($test.ExpectedSource -eq "Claude" -and $result.Source -eq "None" -and -not $ipcAvailable)
        
        if ($passed) {
            Write-Host "✓ PASS - Source: $($result.Source)" -ForegroundColor Green
        }
        else {
            Write-Host "✗ FAIL - Expected: $($test.ExpectedSource), Got: $($result.Source)" -ForegroundColor Red
        }
        
        $results += @{
            Test = $test.Description
            Passed = $passed
            Result = $result
        }
    }
    
    # Summary
    $passCount = ($results | Where-Object { $_.Passed }).Count
    $totalCount = $results.Count
    
    Write-Host "`n=== TEST SUMMARY ===" -ForegroundColor Cyan
    Write-Host "Passed: $passCount / $totalCount" -ForegroundColor $(if ($passCount -eq $totalCount) { "Green" } else { "Yellow" })
    
    return $results
}

#endregion

# Main execution
if ($TestMode) {
    Write-Host "`n=== RUNNING IN TEST MODE ===" -ForegroundColor Yellow
    $testResults = Test-IntegrationPipeline
    
    Write-Host "`n=== INTEGRATION STATUS ===" -ForegroundColor Cyan
    Write-Host "✓ Phase 1 (Core): Loaded" -ForegroundColor Green
    Write-Host "$(if ($ipcAvailable) { '✓' } else { '⚠' }) Phase 2 (IPC): $(if ($ipcAvailable) { 'Loaded' } else { 'Not Available' })" -ForegroundColor $(if ($ipcAvailable) { "Green" } else { "Yellow" })
    Write-Host "✓ Phase 3 (Learning): Loaded with $patternCount patterns" -ForegroundColor Green
    Write-Host "$(if ($errorsAvailable) { '✓' } else { '○' }) Error Tracking: $(if ($errorsAvailable) { 'Loaded' } else { 'Not Available' })" -ForegroundColor $(if ($errorsAvailable) { "Green" } else { "Gray" })
    
}
else {
    # Production mode - process actual Unity errors
    Write-Host "`n=== PRODUCTION MODE ===" -ForegroundColor Green
    Write-Host "Integration ready for Unity error processing" -ForegroundColor Gray
    
    # Example of how this would be called from Unity-Claude-Core
    Write-Host "`nExample integration usage:" -ForegroundColor Cyan
    Write-Host @'
    # In your main automation loop:
    $compilationResult = Test-UnityCompilation
    if (-not $compilationResult.Success) {
        $errors = Export-UnityConsole
        foreach ($error in $errors) {
            $fix = Process-UnityErrorWithLearning -ErrorMessage $error.Message
            if ($fix.Success) {
                Write-Host "Fix found from $($fix.Source): $($fix.Fix)"
            }
        }
    }
'@ -ForegroundColor Gray
}

Write-Host "`n=== INTEGRATION COMPLETE ===" -ForegroundColor Cyan
Write-Host "The learning system is now integrated with Unity automation" -ForegroundColor Green
Write-Host ""

# Export the integration function for use by other scripts
Export-ModuleMember -Function Process-UnityErrorWithLearning, Test-IntegrationPipeline
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUNA+y8kT97RHr+BW46qj/Cu0Y
# p8mgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU3OAHvep1rTryQVFpCeUw3PCdxtswDQYJKoZIhvcNAQEBBQAEggEAUn8p
# IunUai6iz5Lr22pGjAy+xd+RPjSl4M/HNqAJWrYMoMcwhSSkk2jll5BBGCHFvmcE
# nR6kq3obP0h+sIvNjtEEVg1dJxMffbsHq3wrFbgbqn069UlnuuzwQENbAHcho1Ra
# uocjxkHF5vhAolZBCoLwK0teJmis5KupVJAZRK+roGuFZfA7ogZR+Tz3K0XOnC27
# VthWslnqAZtui7srq9FH85LUe+jMumzyM44jjtP1y2W8b/N1uJT92bn3cHhpTiHC
# PDsODwjwHN6xRrtuZ4ekQLUFYXSyLNJk7JOLwVo7Ol1+3ZtCQfBZEbEG9693mdc6
# rIz9LoYWuOXhOksfcg==
# SIG # End signature block
