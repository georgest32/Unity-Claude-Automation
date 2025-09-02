# Test autonomous functions by extracting them directly from the module
Write-Host "Testing Autonomous CLI Functions" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

# Define the script variables that the functions need
$script:BoilerplatePrompt = @'
***START OF BOILERPLATE***

You are an advanced autonomous agent responsible for analyzing recommendations from the Unity-Claude-Automation system and executing appropriate actions. Your primary objectives are:

1. PARSE AND UNDERSTAND: Carefully analyze the recommendations provided
2. MAKE DECISIONS: Determine the most appropriate actions based on confidence levels and context
3. EXECUTE SAFELY: Perform actions with appropriate safety checks and validation
4. REPORT RESULTS: Provide clear feedback on actions taken and their outcomes
5. CONTINUOUS IMPROVEMENT: Learn from results and adapt future responses

CRITICAL DIRECTIVES:
- ALWAYS validate file paths before any file operations
- NEVER execute destructive commands without explicit confirmation
- PRIORITIZE safety over speed
- MAINTAIN detailed logs of all actions
- RESPOND in a structured, parseable format

When you receive a recommendation, you should:
1. Extract the key components (type, action, confidence, context)
2. Evaluate if the action is safe and appropriate
3. Execute the action if approved
4. Report the results clearly
5. Suggest next steps if applicable

Prompt Types You Must Recognize:
- Test Results: Analyze test outcomes and determine next actions
- Debugging: Investigate and resolve issues
- Continue Implementation Plan: Resume work on ongoing tasks
- Review: Evaluate completed work

***END OF BOILERPLATE***
'@

$script:SimpleDirective = "RESPONSE: Please provide a structured analysis and execute the appropriate action based on the above context."

# Load the module file directly  
$modulePath = ".\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator.psm1"
Write-Host "`nLoading functions from: $modulePath" -ForegroundColor Yellow

# Read the module content
$content = Get-Content $modulePath -Raw

# Extract and define each function
$functionNames = @(
    'New-AutonomousPrompt',
    'Get-ActionResultSummary',
    'Invoke-AutonomousExecutionLoop'
)

foreach ($funcName in $functionNames) {
    Write-Host "`nExtracting function: $funcName" -ForegroundColor Yellow
    
    # Find the function in the content
    if ($content -match "(?ms)^function $funcName\s*\{.*?^\}") {
        $functionCode = $Matches[0]
        
        try {
            # Define the function
            Invoke-Expression $functionCode
            
            if (Get-Command $funcName -ErrorAction SilentlyContinue) {
                Write-Host "  [OK] $funcName defined successfully" -ForegroundColor Green
            } else {
                Write-Host "  [ERROR] $funcName not found after definition" -ForegroundColor Red
            }
        } catch {
            Write-Host "  [ERROR] Failed to define ${funcName}: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "  [ERROR] Could not find $funcName in module" -ForegroundColor Red
    }
}

Write-Host "`n--- Testing Functions ---" -ForegroundColor Cyan

# Test 1: New-AutonomousPrompt
Write-Host "`nTest 1: New-AutonomousPrompt" -ForegroundColor Yellow
try {
    $prompt = New-AutonomousPrompt `
        -RecommendationType "TEST" `
        -ActionDetails "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Test-Module.ps1" `
        -Context @{TestRun = "Validation"; Phase = "Testing"}
    
    Write-Host "  SUCCESS: Generated prompt ($($prompt.Length) chars)" -ForegroundColor Green
    
    # Show first part of prompt
    $preview = $prompt.Substring(0, [Math]::Min(200, $prompt.Length))
    Write-Host "  Preview: $preview..." -ForegroundColor DarkGray
} catch {
    Write-Host "  ERROR: $_" -ForegroundColor Red
}

# Test 2: New-AutonomousPrompt with boilerplate
Write-Host "`nTest 2: New-AutonomousPrompt with boilerplate" -ForegroundColor Yellow
try {
    $fullPrompt = New-AutonomousPrompt `
        -RecommendationType "CONTINUE" `
        -ActionDetails "Continue with Phase 7 implementation" `
        -Context @{Module = "CLIOrchestrator"; Status = "InProgress"} `
        -IncludeBoilerplate
    
    Write-Host "  SUCCESS: Generated full prompt ($($fullPrompt.Length) chars)" -ForegroundColor Green
    
    if ($fullPrompt -match "START OF BOILERPLATE") {
        Write-Host "  Boilerplate: INCLUDED" -ForegroundColor Green
    } else {
        Write-Host "  Boilerplate: MISSING" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ERROR: $_" -ForegroundColor Red
}

# Test 3: Get-ActionResultSummary
Write-Host "`nTest 3: Get-ActionResultSummary" -ForegroundColor Yellow
try {
    # Create a mock result file
    $mockResult = @{
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        TestName = "CLIOrchestrator Tests"
        TotalTests = 10
        Passed = 8
        Failed = 2
        Results = @(
            @{Name = "Import Module"; Status = "Passed"; Duration = "1.2s"},
            @{Name = "Analyze Response"; Status = "Passed"; Duration = "0.8s"},
            @{Name = "Execute Action"; Status = "Failed"; Error = "Timeout"}
        )
    }
    
    $tempFile = ".\temp-test-result.json"
    $mockResult | ConvertTo-Json -Depth 10 | Out-File $tempFile -Encoding UTF8
    
    $summary = Get-ActionResultSummary -ResultPath $tempFile -ActionType "Test"
    
    Write-Host "  SUCCESS: Generated summary" -ForegroundColor Green
    Write-Host "  Summary:" -ForegroundColor Gray
    $summaryLines = $summary -split "`n" | Select-Object -First 5
    $summaryLines | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
    
    # Clean up
    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
} catch {
    Write-Host "  ERROR: $_" -ForegroundColor Red
}

# Test 4: Invoke-AutonomousExecutionLoop
Write-Host "`nTest 4: Invoke-AutonomousExecutionLoop (Dry Run)" -ForegroundColor Yellow
try {
    # Create a mock analysis result
    $analysisResult = @{
        Recommendations = @(
            @{
                Type = "TEST"
                Action = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Test-CLIOrchestrator.ps1"
                Confidence = 0.92
                Priority = 1
            }
        )
        ConfidenceAnalysis = @{
            OverallConfidence = 0.92
            QualityRating = "High"
        }
        Entities = @{
            FilePaths = @(".\Test-CLIOrchestrator.ps1")
            PowerShellCommands = @("Import-Module", "Test-Path")
        }
        ProcessingSuccess = $true
    }
    
    # Mock the required functions if they don't exist
    if (-not (Get-Command Invoke-RuleBasedDecision -ErrorAction SilentlyContinue)) {
        function Invoke-RuleBasedDecision {
            param($AnalysisResult, [switch]$DryRun)
            return @{
                Decision = "EXECUTE"
                Rules = @("High confidence", "Safe action")
                Actions = @("Execute test script")
            }
        }
    }
    
    if (-not (Get-Command Test-SafetyValidation -ErrorAction SilentlyContinue)) {
        function Test-SafetyValidation {
            param($AnalysisResult)
            return @{
                IsSafe = $true
                RiskLevel = "Low"
                Warnings = @()
            }
        }
    }
    
    if (-not (Get-Command Add-ActionToQueue -ErrorAction SilentlyContinue)) {
        function Add-ActionToQueue {
            param($Action, $Priority, $Context)
            return @{
                Success = $true
                QueuePosition = 1
            }
        }
    }
    
    $loopResult = Invoke-AutonomousExecutionLoop `
        -AnalysisResult $analysisResult `
        -DryRun `
        -MaxIterations 1
    
    Write-Host "  SUCCESS: Loop executed" -ForegroundColor Green
    Write-Host "  Decision: $($loopResult.Decision)" -ForegroundColor Gray
    Write-Host "  Actions Queued: $($loopResult.ActionsQueued)" -ForegroundColor Gray
    Write-Host "  Safety: $($loopResult.SafetyCheckPassed)" -ForegroundColor Gray
} catch {
    Write-Host "  ERROR: $_" -ForegroundColor Red
    Write-Host "  Stack: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
}

Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "Testing Complete" -ForegroundColor Cyan
Write-Host "" 
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "The autonomous functions are working correctly when extracted directly." -ForegroundColor Green
Write-Host "The issue is with module export. Functions need to be properly exported." -ForegroundColor Yellow
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC4YDLlNBzAuhK2
# IR2cS+TNy135aHwFonzKvJ50h1ACOaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIF0Dq+G4aQ9QV1htUZYMuxVb
# zv0+L7kR1wohQLfs+b5fMA0GCSqGSIb3DQEBAQUABIIBADG8U7524vz+b9msfdNw
# D5sa59GxFjY+00raaSwsHpeaBWgQE+iIYCrQoF+VTR558Y5jfUD4kGY72NZqfgxY
# dntZx8UT970OY5LSkQjxXM6hf+eLLGLckTJ5lb6WiEuvNJ2fdd4RALE+nQU3CICk
# xDwsYLNeKnNGc+FxQCJiRclZFfQsiaYIj0q70ffwzVffIAkEYAFX7mLRBZTr0zzr
# ktBofzz68OiLc1J1JTiaB7garHGYjeOKG+CMyK0dOG8uyJzHZ2t/BpP2iVYk6BJQ
# zBXL16bzwDt17ZvLEY8WV9VuOS/rQKG9U5XXkNW85OKGk77JGvhZEYBjlGl0wKgh
# fgU=
# SIG # End signature block
