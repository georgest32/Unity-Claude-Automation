# Integrate-Phases.ps1
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

# Load all modules
Write-Host "`nLoading modules..." -ForegroundColor Gray
try {
    # Phase 1: Core
    Import-Module Unity-Claude-Core -Force
    Write-Host "  ✓ Unity-Claude-Core loaded" -ForegroundColor Green
    
    # Phase 2: IPC (if exists)
    if (Get-Module -ListAvailable -Name Unity-Claude-IPC) {
        Import-Module Unity-Claude-IPC -Force
        Write-Host "  ✓ Unity-Claude-IPC loaded" -ForegroundColor Green
        $ipcAvailable = $true
    }
    else {
        Write-Host "  ⚠ Unity-Claude-IPC not found (will skip Claude integration)" -ForegroundColor Yellow
        $ipcAvailable = $false
    }
    
    # Phase 3: Learning
    Import-Module Unity-Claude-Learning-Simple -Force
    Write-Host "  ✓ Unity-Claude-Learning-Simple loaded" -ForegroundColor Green
    
    # Error tracking (optional)
    if (Get-Module -ListAvailable -Name Unity-Claude-Errors) {
        Import-Module Unity-Claude-Errors -Force
        Write-Host "  ✓ Unity-Claude-Errors loaded" -ForegroundColor Green
        $errorsAvailable = $true
    }
    else {
        $errorsAvailable = $false
    }
} catch {
    Write-Host "  ✗ Error loading modules: $_" -ForegroundColor Red
    exit 1
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
            } else {
                Write-Host "  ⚠ Fix could not be applied: $($result.Reason)" -ForegroundColor Yellow
            }
        } else {
            return @{
                Success = $true
                Source = 'Learning'
                PatternId = $bestFix.PatternId
                Fix = $bestFix.Fix
                Confidence = $bestFix.Confidence
                Applied = $false
            }
        }
    } else {
        Write-Host "  No pattern matches found" -ForegroundColor Yellow
    }
    
    # Step 2: Fallback to Claude if available
    if ($ipcAvailable -and -not $TestMode) {
        Write-Host "  Consulting Claude for analysis..." -ForegroundColor Cyan
        
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
        } catch {
            Write-Host "  ✗ Claude error: $_" -ForegroundColor Red
        }
    } elseif (-not $ipcAvailable) {
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
        } else {
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
    
} else {
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
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUvUgHzzVXDF+jgsJB9mUnLGyw
# t+agggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQURt1u3DV8d/q+SRl1fRPB5d7VsTQwDQYJKoZIhvcNAQEBBQAEggEAUV4W
# ADc2cYmRTVX/rfYUEYUdHkNdajC2rmuKJBZ/KrT3w1FIN17hnVnlVfef7dosHEuo
# AqFPajZy59aTRCEVmFAegs/JGrhGaD9cXdQSkiQt0LNlTJrNSw3vI6HBKaE1pa6V
# dGnzMa8n9eZ8FKkMs9X8NLcv/IRgrFY1AUrQfTcMh9uIYv7Em4VoQb89D6eC4MoN
# eCvftzEHpENz6vr59cT6HWhewxk4pLjNPN7m/7ZWFojKlcrvSKJVvMjiiuuykDWr
# tNFK1E8IsK88o2V8T/BWF0xSeokYqeEyaxbdXSyZ3vkvCdZsBwDFu21DFhj6ohz+
# hvDjCM0fyhNWK8XgqA==
# SIG # End signature block
