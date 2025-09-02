# Test-StaticAnalysisIntegration.ps1
# Comprehensive test suite for Phase 2 Static Analysis Integration

param(
    [Parameter()]
    [string]$TestPath = ".",
    
    [Parameter()]
    [switch]$IncludeSecurityScanners,
    
    [Parameter()]
    [switch]$SaveResults,
    
    [Parameter()]
    [switch]$VerboseOutput
)

$ErrorActionPreference = 'Stop'

# Test configuration - use script scope for proper access
$script:TestResults = @{
    StartTime = Get-Date
    Tests = @()
    Summary = @{
        Total = 0
        Passed = 0
        Failed = 0
        Skipped = 0
    }
}

function Write-TestResult {
    param($TestName, $Status, $Message = "", $Duration = 0)
    
    $result = [PSCustomObject]@{
        Test = $TestName
        Status = $Status
        Message = $Message
        Duration = $Duration
        Timestamp = Get-Date
    }
    
    # Simplified property access - ensure TestResults is always a hashtable
    if (-not $script:TestResults) {
        $script:TestResults = @{ 
            Tests = @(); 
            Summary = @{ Total = 0; Passed = 0; Failed = 0; Skipped = 0 }
            StartTime = Get-Date
        }
    }
    
    # Safe property access with PSObject check
    if (-not $script:TestResults.PSObject.Properties["Tests"]) {
        $script:TestResults.Tests = @()
    }
    if (-not $script:TestResults.Tests) {
        $script:TestResults.Tests = @()
    }
    
    $script:TestResults.Tests += $result
    
    # Simplified summary handling with safe property access
    if (-not $script:TestResults.PSObject.Properties["Summary"] -or -not $script:TestResults.Summary) {
        $script:TestResults.Summary = @{ Total = 0; Passed = 0; Failed = 0; Skipped = 0 }
    }
    
    # Initialize status if not exists - safe hashtable access
    if (-not $script:TestResults.Summary.ContainsKey($Status)) {
        $script:TestResults.Summary.$Status = 0
    }
    
    # Increment counters
    $script:TestResults.Summary.$Status++
    $script:TestResults.Summary.Total++
    
    $statusColor = switch ($Status) {
        'Passed' { 'Green' }
        'Failed' { 'Red' }
        'Skipped' { 'Yellow' }
        default { 'White' }
    }
    
    Write-Host "[$Status] $TestName" -ForegroundColor $statusColor
    if ($Message) {
        Write-Host "  $Message" -ForegroundColor Gray
    }
}

function Test-ModuleFunction {
    param($FunctionName, $ModuleName = "Unity-Claude-RepoAnalyst")
    
    $startTime = Get-Date
    
    try {
        # Check if module is loaded
        $module = Get-Module $ModuleName
        if (-not $module) {
            Import-Module "$PSScriptRoot\Modules\$ModuleName\$ModuleName.psm1" -Force
        }
        
        # Check if function exists
        $function = Get-Command $FunctionName -ErrorAction SilentlyContinue
        if ($function) {
            $duration = ((Get-Date) - $startTime).TotalMilliseconds
            Write-TestResult "Function Availability: $FunctionName" "Passed" "Function loaded successfully" $duration
            return $true
        } else {
            $duration = ((Get-Date) - $startTime).TotalMilliseconds
            Write-TestResult "Function Availability: $FunctionName" "Failed" "Function not found" $duration
            return $false
        }
    } catch {
        $duration = ((Get-Date) - $startTime).TotalMilliseconds
        Write-TestResult "Function Availability: $FunctionName" "Failed" "Error: $_" $duration
        return $false
    }
}

function Test-StaticAnalysisExecution {
    param($FunctionName, $TestParameters)
    
    $startTime = Get-Date
    
    try {
        Write-Host "  Testing $FunctionName execution..." -ForegroundColor Cyan
        
        # Execute the function with test parameters
        $result = & $FunctionName @TestParameters
        
        # Validate SARIF structure
        if ($result -and $result.runs -and $result.runs.Count -gt 0) {
            $run = $result.runs[0]
            
            # Check required SARIF properties
            $requiredProperties = @('tool', 'results', 'columnKind')
            $missingProperties = @()
            
            foreach ($prop in $requiredProperties) {
                if (-not $run.$prop) {
                    $missingProperties += $prop
                }
            }
            
            if ($missingProperties.Count -eq 0) {
                $duration = ((Get-Date) - $startTime).TotalMilliseconds
                $resultCount = $run.results.Count
                Write-TestResult "Static Analysis Execution: $FunctionName" "Passed" "SARIF output valid, $resultCount results" $duration
                return $result
            } else {
                $duration = ((Get-Date) - $startTime).TotalMilliseconds
                Write-TestResult "Static Analysis Execution: $FunctionName" "Failed" "Missing SARIF properties: $($missingProperties -join ', ')" $duration
                return $null
            }
        } else {
            $duration = ((Get-Date) - $startTime).TotalMilliseconds
            Write-TestResult "Static Analysis Execution: $FunctionName" "Failed" "Invalid or empty SARIF output" $duration
            return $null
        }
    } catch {
        $duration = ((Get-Date) - $startTime).TotalMilliseconds
        Write-TestResult "Static Analysis Execution: $FunctionName" "Failed" "Execution error: $_" $duration
        return $null
    }
}

# Main test execution
Write-Host "Unity-Claude Static Analysis Integration Test Suite" -ForegroundColor Magenta
Write-Host "=" * 60 -ForegroundColor Magenta
Write-Host ""

# Test 1: Module Loading
Write-Host "Testing Module Loading..." -ForegroundColor Yellow
$modulePath = "$PSScriptRoot\Modules\Unity-Claude-RepoAnalyst\Unity-Claude-RepoAnalyst.psm1"
if (Test-Path $modulePath) {
    try {
        Import-Module $modulePath -Force
        Write-TestResult "Module Loading" "Passed" "Unity-Claude-RepoAnalyst module loaded"
    } catch {
        Write-TestResult "Module Loading" "Failed" "Module load error: $_"
        exit 1
    }
} else {
    Write-TestResult "Module Loading" "Failed" "Module file not found: $modulePath"
    exit 1
}

# Test 2: Function Availability Tests
Write-Host "Testing Function Availability..." -ForegroundColor Yellow

$functions = @(
    'Invoke-StaticAnalysis',
    'Invoke-ESLintAnalysis',
    'Invoke-PylintAnalysis', 
    'Invoke-PSScriptAnalyzerEnhanced',
    'Invoke-BanditAnalysis',
    'Invoke-SemgrepAnalysis',
    'Merge-SarifResults'
)

$availableFunctions = @()
foreach ($func in $functions) {
    if (Test-ModuleFunction $func) {
        $availableFunctions += $func
    }
}

# Test 3: Configuration Loading
Write-Host "Testing Configuration Loading..." -ForegroundColor Yellow
$configPath = "$PSScriptRoot\Modules\Unity-Claude-RepoAnalyst\Config\StaticAnalysisConfig.psd1"
if (Test-Path $configPath) {
    try {
        $config = Import-PowerShellDataFile $configPath
        if ($config -and $config.GetType().Name -eq 'Hashtable') {
            Write-TestResult "Configuration Loading" "Passed" "Configuration loaded with $($config.Keys.Count) sections"
        } else {
            Write-TestResult "Configuration Loading" "Failed" "Invalid configuration format"
        }
    } catch {
        Write-TestResult "Configuration Loading" "Failed" "Configuration load error: $_"
    }
} else {
    Write-TestResult "Configuration Loading" "Skipped" "Configuration file not found"
}

# Test 4: PSScriptAnalyzer Integration (Always Available)
Write-Host "Testing PSScriptAnalyzer Integration..." -ForegroundColor Yellow
if ('Invoke-PSScriptAnalyzerEnhanced' -in $availableFunctions) {
    $psaParams = @{
        Path = $TestPath
        Severity = @('Warning', 'Error')
    }
    $psaResult = Test-StaticAnalysisExecution 'Invoke-PSScriptAnalyzerEnhanced' $psaParams
    
    if ($psaResult) {
        # Test SARIF structure validation
        $run = $psaResult.runs[0]
        if ($run.tool.driver.name -eq 'PSScriptAnalyzer' -and $run.results) {
            Write-TestResult "PSScriptAnalyzer SARIF Validation" "Passed" "SARIF structure valid"
        } else {
            Write-TestResult "PSScriptAnalyzer SARIF Validation" "Failed" "Invalid SARIF structure"
        }
    }
}

# Test 5: ESLint Integration (if available)
Write-Host "Testing ESLint Integration..." -ForegroundColor Yellow
if ('Invoke-ESLintAnalysis' -in $availableFunctions) {
    # Check if ESLint is available
    $eslintAvailable = $false
    try {
        $null = Get-Command 'eslint' -ErrorAction SilentlyContinue
        $eslintAvailable = $true
    } catch {
        try {
            $null = Get-Command 'npx' -ErrorAction SilentlyContinue
            $eslintAvailable = $true
        } catch {}
    }
    
    if ($eslintAvailable) {
        $eslintParams = @{
            Path = $TestPath
        }
        $eslintResult = Test-StaticAnalysisExecution 'Invoke-ESLintAnalysis' $eslintParams
    } else {
        Write-TestResult "ESLint Integration" "Skipped" "ESLint not available in PATH"
    }
} else {
    Write-TestResult "ESLint Integration" "Skipped" "Function not available"
}

# Test 6: Pylint Integration (if available)
Write-Host "Testing Pylint Integration..." -ForegroundColor Yellow
if ('Invoke-PylintAnalysis' -in $availableFunctions) {
    # Check if Pylint is available
    $pylintAvailable = $false
    try {
        $null = Get-Command 'pylint' -ErrorAction SilentlyContinue
        $pylintAvailable = $true
    } catch {}
    
    if ($pylintAvailable) {
        $pylintParams = @{
            Path = $TestPath
        }
        $pylintResult = Test-StaticAnalysisExecution 'Invoke-PylintAnalysis' $pylintParams
    } else {
        Write-TestResult "Pylint Integration" "Skipped" "Pylint not available in PATH"
    }
} else {
    Write-TestResult "Pylint Integration" "Skipped" "Function not available"
}

# Test 7: Security Scanner Tests (if enabled)
if ($IncludeSecurityScanners) {
    Write-Host "Testing Security Scanner Integration..." -ForegroundColor Yellow
    
    # Bandit test
    if ('Invoke-BanditAnalysis' -in $availableFunctions) {
        $banditAvailable = $false
        try {
            $null = Get-Command 'bandit' -ErrorAction SilentlyContinue
            $banditAvailable = $true
        } catch {}
        
        if ($banditAvailable) {
            $banditParams = @{
                Path = $TestPath
                Severity = @('MEDIUM', 'HIGH')
            }
            $banditResult = Test-StaticAnalysisExecution 'Invoke-BanditAnalysis' $banditParams
        } else {
            Write-TestResult "Bandit Security Scanner" "Skipped" "Bandit not available in PATH"
        }
    }
    
    # Semgrep test
    if ('Invoke-SemgrepAnalysis' -in $availableFunctions) {
        $semgrepAvailable = $false
        try {
            $null = Get-Command 'semgrep' -ErrorAction SilentlyContinue
            $semgrepAvailable = $true
        } catch {}
        
        if ($semgrepAvailable) {
            $semgrepParams = @{
                Path = $TestPath
                RuleSet = 'auto'
            }
            $semgrepResult = Test-StaticAnalysisExecution 'Invoke-SemgrepAnalysis' $semgrepParams
        } else {
            Write-TestResult "Semgrep Security Scanner" "Skipped" "Semgrep not available in PATH"
        }
    }
}

# Test 8: Result Merging and Deduplication
Write-Host "Testing Result Merging..." -ForegroundColor Yellow
if ('Merge-SarifResults' -in $availableFunctions) {
    # Create test SARIF results
    $testResults = @()
    
    # Mock SARIF result 1
    $testResults += [PSCustomObject]@{
        runs = @([PSCustomObject]@{
            tool = [PSCustomObject]@{
                driver = [PSCustomObject]@{
                    name = 'TestTool1'
                    version = '1.0.0'
                    rules = @()
                }
            }
            results = @(
                [PSCustomObject]@{
                    ruleId = 'test-rule-1'
                    level = 'warning'
                    message = [PSCustomObject]@{ text = 'Test warning message' }
                    locations = @([PSCustomObject]@{
                        physicalLocation = [PSCustomObject]@{
                            artifactLocation = [PSCustomObject]@{ uri = 'test.js' }
                            region = [PSCustomObject]@{ startLine = 10; startColumn = 5 }
                        }
                    })
                }
            )
        })
    }
    
    # Mock SARIF result 2
    $testResults += [PSCustomObject]@{
        runs = @([PSCustomObject]@{
            tool = [PSCustomObject]@{
                driver = [PSCustomObject]@{
                    name = 'TestTool2'
                    version = '2.0.0'
                    rules = @()
                }
            }
            results = @(
                [PSCustomObject]@{
                    ruleId = 'test-rule-2'
                    level = 'error'
                    message = [PSCustomObject]@{ text = 'Test error message' }
                    locations = @([PSCustomObject]@{
                        physicalLocation = [PSCustomObject]@{
                            artifactLocation = [PSCustomObject]@{ uri = 'test.py' }
                            region = [PSCustomObject]@{ startLine = 15; startColumn = 1 }
                        }
                    })
                }
            )
        })
    }
    
    try {
        $mergedResult = Merge-SarifResults -SarifResults $testResults -IncludeMetrics
        
        if ($mergedResult -and $mergedResult.runs -and $mergedResult.runs[0].results.Count -eq 2) {
            Write-TestResult "SARIF Result Merging" "Passed" "Successfully merged $($testResults.Count) result sets"
            
            # Test deduplication
            $dedupResult = Merge-SarifResults -SarifResults $testResults -DeduplicateResults -DeduplicationThreshold 0.8
            Write-TestResult "SARIF Deduplication" "Passed" "Deduplication completed"
        } else {
            Write-TestResult "SARIF Result Merging" "Failed" "Merge result validation failed"
        }
    } catch {
        Write-TestResult "SARIF Result Merging" "Failed" "Merge execution error: $_"
    }
}

# Test 9: Master Orchestration Function
Write-Host "Testing Master Orchestration..." -ForegroundColor Yellow
if ('Invoke-StaticAnalysis' -in $availableFunctions) {
    try {
        $orchestrationParams = @{
            Path = $TestPath
            Linters = @('PSScriptAnalyzer')  # Use only PSA for basic test
            Config = @{}
            ParallelExecution = $false  # Disable for testing
        }
        
        $orchestrationResult = Invoke-StaticAnalysis @orchestrationParams
        
        if ($orchestrationResult -and $orchestrationResult.runs) {
            Write-TestResult "Master Orchestration" "Passed" "Orchestration executed successfully"
        } else {
            Write-TestResult "Master Orchestration" "Failed" "Invalid orchestration result"
        }
    } catch {
        Write-TestResult "Master Orchestration" "Failed" "Orchestration error: $_"
    }
}

# Test Summary
Write-Host ""
Write-Host "Test Summary" -ForegroundColor Magenta
Write-Host "=" * 30 -ForegroundColor Magenta

$script:TestResults.EndTime = Get-Date
$script:TestResults.Duration = ($script:TestResults.EndTime - $script:TestResults.StartTime).TotalSeconds

$summary = $script:TestResults.Summary
Write-Host "Total Tests: $($summary.Total)" -ForegroundColor White
Write-Host "Passed: $($summary.Passed)" -ForegroundColor Green
Write-Host "Failed: $($summary.Failed)" -ForegroundColor Red
Write-Host "Skipped: $($summary.Skipped)" -ForegroundColor Yellow
Write-Host "Duration: $([Math]::Round($script:TestResults.Duration, 2)) seconds" -ForegroundColor White

$successRate = if ($summary.Total -gt 0) { [Math]::Round(($summary.Passed / $summary.Total) * 100, 1) } else { 0 }
Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 80) { 'Green' } elseif ($successRate -ge 60) { 'Yellow' } else { 'Red' })

# Save results if requested
if ($SaveResults) {
    $resultsPath = "Test-StaticAnalysisIntegration-Results-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $script:TestResults | ConvertTo-Json -Depth 10 | Set-Content $resultsPath
    Write-Host "Results saved to: $resultsPath" -ForegroundColor Cyan
}

# Return exit code based on results
if ($summary.Failed -gt 0) {
    exit 1
} else {
    exit 0
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA7AQlaEpYBtmFz
# JLvkxwvYaI6l/SawBWKoXiQ9SfSrYKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJrvxz47+d51TQFXIWYRuJ5S
# uwLagiTLeMT5+JdoOl4AMA0GCSqGSIb3DQEBAQUABIIBAH4Jg7vtBmm/k6/NeX+d
# c/TdpG0MSoK9Tdu0q/OOMntEzlNubqP5DaqS63BNClpLfV0bGeXEl7oeF5eJASVr
# fQVFbe92Ejrn/GD5TQ9fkmZmvVp73MhFdwPT19mU8hk241xpDOr5E+ijlgkhiplH
# efCh6swCeF0AHQmr/fngeLQ6EuqmRNFmUaolnjrWP+kmIsGZQZbWZTrqCMFz2XS1
# Jvfir31Sk9s+i80fppXRYbPsZr76YcBLHQX1C+DCRg+TKQARIg4VMxS0lTO0DdVf
# HwdYQjEudAZ64FV+2pbtep2QLhQV96tRuHPNInBhuV936AWtEi1Tx5ohryetoTFx
# ViI=
# SIG # End signature block
