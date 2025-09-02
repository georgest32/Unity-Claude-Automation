# Test script for autonomous CLI orchestration
Write-Host "Testing Autonomous CLI Orchestration" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# Import the module
Write-Host "`nImporting CLIOrchestrator module..." -ForegroundColor Yellow
Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator.psd1" -Force

# Get module functions and copy them to global scope
$module = Get-Module Unity-Claude-CLIOrchestrator
foreach ($func in $module.ExportedCommands.Keys) {
    $cmd = Get-Command $func -Module Unity-Claude-CLIOrchestrator
    if ($cmd) {
        Set-Item -Path "function:global:$func" -Value $cmd.ScriptBlock
    }
}

Write-Host "Module imported. Checking for autonomous functions..." -ForegroundColor Yellow

# Test if functions exist
$functions = @(
    'New-AutonomousPrompt',
    'Get-ActionResultSummary', 
    'Invoke-AutonomousExecutionLoop'
)

$allFound = $true
foreach ($func in $functions) {
    if (Get-Command $func -ErrorAction SilentlyContinue) {
        Write-Host "  [OK] $func" -ForegroundColor Green
    } else {
        Write-Host "  [MISSING] $func" -ForegroundColor Red
        $allFound = $false
    }
}

if (-not $allFound) {
    Write-Host "`nSome functions are missing. Attempting direct definition..." -ForegroundColor Yellow
    
    # Load functions directly from module file
    . ".\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator.psm1"
    
    Write-Host "Re-checking functions..." -ForegroundColor Yellow
    foreach ($func in $functions) {
        if (Get-Command $func -ErrorAction SilentlyContinue) {
            Write-Host "  [OK] $func" -ForegroundColor Green
        } else {
            Write-Host "  [MISSING] $func" -ForegroundColor Red
        }
    }
}

Write-Host "`n--- Testing Autonomous Prompt Generation ---" -ForegroundColor Cyan

# Test 1: Generate a TEST prompt
Write-Host "`nTest 1: Generating TEST prompt" -ForegroundColor Yellow
try {
    $testPrompt = New-AutonomousPrompt `
        -RecommendationType "TEST" `
        -ActionDetails "Test-SemanticAnalysis.ps1" `
        -Context @{Environment = "Development"} `
        -IncludeBoilerplate $false
    
    Write-Host "SUCCESS: Generated prompt ($($testPrompt.Length) chars)" -ForegroundColor Green
    Write-Host "First 200 chars:" -ForegroundColor Gray
    Write-Host ($testPrompt.Substring(0, [Math]::Min(200, $testPrompt.Length))) -ForegroundColor DarkGray
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Generate a complete prompt with boilerplate
Write-Host "`nTest 2: Generating complete prompt with boilerplate" -ForegroundColor Yellow
try {
    $fullPrompt = New-AutonomousPrompt `
        -RecommendationType "CONTINUE" `
        -ActionDetails "Continue with implementation" `
        -Context @{Phase = "Testing"; Module = "CLIOrchestrator"} `
        -IncludeBoilerplate $true
    
    Write-Host "SUCCESS: Generated full prompt ($($fullPrompt.Length) chars)" -ForegroundColor Green
    
    # Check if boilerplate is included
    if ($fullPrompt -match "START OF BOILERPLATE") {
        Write-Host "  Boilerplate: INCLUDED" -ForegroundColor Green
    } else {
        Write-Host "  Boilerplate: NOT FOUND" -ForegroundColor Red
    }
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n--- Testing Action Result Summary ---" -ForegroundColor Cyan

# Test 3: Get action result summary
Write-Host "`nTest 3: Getting action result summary" -ForegroundColor Yellow
try {
    # Create a mock test result file
    $mockResult = @{
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        TestName = "Mock Test"
        Status = "Success"
        Results = @(
            @{Name = "Test1"; Status = "Passed"},
            @{Name = "Test2"; Status = "Passed"}
        )
    }
    
    $mockFile = ".\mock-test-result.json"
    $mockResult | ConvertTo-Json -Depth 10 | Out-File $mockFile -Encoding UTF8
    
    $summary = Get-ActionResultSummary -ResultPath $mockFile -ActionType "Test"
    
    Write-Host "SUCCESS: Generated summary" -ForegroundColor Green
    Write-Host "Summary:" -ForegroundColor Gray
    Write-Host $summary -ForegroundColor DarkGray
    
    # Clean up
    Remove-Item $mockFile -Force -ErrorAction SilentlyContinue
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n--- Testing Autonomous Execution Loop ---" -ForegroundColor Cyan

# Test 4: Test the autonomous loop (dry run)
Write-Host "`nTest 4: Testing autonomous execution loop (dry run)" -ForegroundColor Yellow
try {
    # Create a mock analysis result
    $mockAnalysis = @{
        Recommendations = @(
            @{
                Type = "TEST"
                Action = "Test-Module.ps1"
                Confidence = 0.95
                Priority = 1
            }
        )
        ConfidenceAnalysis = @{
            OverallConfidence = 0.95
            QualityRating = "High"
        }
        Entities = @{
            FilePaths = @(".\Test-Module.ps1")
            PowerShellCommands = @()
        }
    }
    
    Write-Host "Invoking autonomous loop with mock analysis..." -ForegroundColor Gray
    $result = Invoke-AutonomousExecutionLoop `
        -AnalysisResult $mockAnalysis `
        -DryRun `
        -MaxIterations 1
    
    if ($result.Success) {
        Write-Host "SUCCESS: Autonomous loop completed" -ForegroundColor Green
        Write-Host "  Decision: $($result.Decision)" -ForegroundColor Gray
        Write-Host "  Actions Queued: $($result.ActionsQueued)" -ForegroundColor Gray
        Write-Host "  Prompt Generated: $(if($result.PromptGenerated){'Yes'}else{'No'})" -ForegroundColor Gray
    } else {
        Write-Host "Loop failed: $($result.Error)" -ForegroundColor Red
    }
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
}

Write-Host "`n=====================================" -ForegroundColor Cyan
Write-Host "Autonomous CLI Testing Complete" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDdIjrnfLceXRPa
# BQPjCrhW5Qg/OI8XHcxaCpXI4bEqzKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIFjSPBDbmaBuJ71Zqloi9zo9
# 5O60vnURZi4TT4IC+9StMA0GCSqGSIb3DQEBAQUABIIBAI1FJnUlOFP2Py2wx9cp
# PCeJNULJKyDhqSEmJulFu1nHWAiqQLDC3uSn8pONYfGmLHBG/UQSCSJg2qPRu8Ru
# ufLHaGf06YcZ0wBRKqM/ohoyyiVcH33NGzy4u18Qym79LHN7KhCt232e6GH89gHj
# E2OI+UBN6HuPDI94vRWwl/iM53P1xTB0xPAYHjQ3Sp4X3O3op8jlXsUOpVI7+E7g
# TYrxCpM1K9dXcTjsL+vCE5kaTmnkRZ38fIC/8qywfHBFJDhF1RyGM+zLnbrP7mT0
# LSy4zTvgGHB3uLwbEQIkTprnJYNee9OEY+MNcc+q3LjNLIBP4sEYcePRX16cdz82
# SWM=
# SIG # End signature block
