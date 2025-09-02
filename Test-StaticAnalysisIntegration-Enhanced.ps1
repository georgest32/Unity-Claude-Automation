# Enhanced Static Analysis Integration Test with Detailed Logging
param(
    [switch]$SaveResults,
    [int]$Timeout = 30  # Timeout in seconds for each test
)

$ErrorActionPreference = 'Continue'

# Test results storage
$testResults = @{
    StartTime = Get-Date
    Tests = @()
    Summary = @{
        Passed = 0
        Failed = 0
        Skipped = 0
    }
}

function Test-WithTimeout {
    param(
        [string]$TestName,
        [scriptblock]$TestScript,
        [int]$TimeoutSeconds = 30
    )
    
    Write-Host "`nTesting: $TestName" -ForegroundColor Cyan
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Starting test with ${TimeoutSeconds}s timeout..." -ForegroundColor Gray
    
    $job = Start-Job -ScriptBlock $TestScript
    $result = Wait-Job -Job $job -Timeout $TimeoutSeconds
    
    if ($null -eq $result) {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [TIMEOUT] Test exceeded ${TimeoutSeconds}s limit" -ForegroundColor Red
        Stop-Job -Job $job
        Remove-Job -Job $job -Force
        return @{
            TestName = $TestName
            Status = 'Timeout'
            Duration = $TimeoutSeconds
            Details = "Test exceeded timeout of ${TimeoutSeconds} seconds"
        }
    }
    
    $output = Receive-Job -Job $job
    Remove-Job -Job $job
    
    $duration = (Get-Date) - $job.PSBeginTime
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Completed in $($duration.TotalSeconds.ToString('F2'))s" -ForegroundColor Gray
    
    return @{
        TestName = $TestName
        Status = 'Completed'
        Duration = $duration.TotalSeconds
        Output = $output
    }
}

Write-Host "Unity-Claude Static Analysis Integration Test Suite (Enhanced)" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host "Timeout per test: ${Timeout} seconds" -ForegroundColor Yellow
Write-Host ""

# Test 1: Module Loading
Write-Host "Testing Module Loading..." -ForegroundColor Yellow
try {
    Import-Module "$PSScriptRoot\Modules\Unity-Claude-RepoAnalyst" -Force -ErrorAction Stop
    Write-Host "[PASSED] Module Loading" -ForegroundColor Green
    Write-Host "  Unity-Claude-RepoAnalyst module loaded" -ForegroundColor Gray
    $testResults.Tests += @{Name = "Module Loading"; Status = "Passed"}
    $testResults.Summary.Passed++
} catch {
    Write-Host "[FAILED] Module Loading" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Red
    $testResults.Tests += @{Name = "Module Loading"; Status = "Failed"; Error = $_.ToString()}
    $testResults.Summary.Failed++
}

# Test 2: PSScriptAnalyzer with specific file
Write-Host "`nTesting PSScriptAnalyzer (Single File)..." -ForegroundColor Yellow
$psaTestResult = Test-WithTimeout -TestName "PSScriptAnalyzer-SingleFile" -TimeoutSeconds $Timeout -TestScript {
    try {
        # Create a test file
        $testFile = "$env:TEMP\test-psa-$(Get-Random).ps1"
        @'
# Test script
$x = 1
Write-Host "Test"
'@ | Out-File -FilePath $testFile -Encoding UTF8
        
        Import-Module PSScriptAnalyzer -Force
        $results = Invoke-ScriptAnalyzer -Path $testFile -Severity @('Error', 'Warning')
        Remove-Item $testFile -Force
        
        return @{
            Success = $true
            IssueCount = $results.Count
        }
    } catch {
        return @{
            Success = $false
            Error = $_.ToString()
        }
    }
}

if ($psaTestResult.Status -eq 'Completed' -and $psaTestResult.Output.Success) {
    Write-Host "[PASSED] PSScriptAnalyzer Single File Test" -ForegroundColor Green
    Write-Host "  Found $($psaTestResult.Output.IssueCount) issues" -ForegroundColor Gray
    $testResults.Summary.Passed++
} else {
    Write-Host "[FAILED] PSScriptAnalyzer Single File Test" -ForegroundColor Red
    if ($psaTestResult.Status -eq 'Timeout') {
        Write-Host "  Test timed out" -ForegroundColor Red
    } else {
        Write-Host "  Error: $($psaTestResult.Output.Error)" -ForegroundColor Red
    }
    $testResults.Summary.Failed++
}

# Test 3: ESLint with timeout
Write-Host "`nTesting ESLint (With Timeout)..." -ForegroundColor Yellow
$eslintTestResult = Test-WithTimeout -TestName "ESLint" -TimeoutSeconds 10 -TestScript {
    try {
        # Create a simple JS file
        $testFile = "$env:TEMP\test-eslint-$(Get-Random).js"
        @'
const x = 1;
console.log("Test");
'@ | Out-File -FilePath $testFile -Encoding UTF8
        
        # Try to run eslint with a simple command
        $eslintPath = Get-Command eslint -ErrorAction SilentlyContinue
        if ($eslintPath) {
            # Run with timeout using Start-Process
            $process = Start-Process -FilePath "eslint" -ArgumentList "--format json `"$testFile`"" -NoNewWindow -PassThru -RedirectStandardOutput "$env:TEMP\eslint-out.txt" -RedirectStandardError "$env:TEMP\eslint-err.txt"
            
            # Wait max 5 seconds
            $process | Wait-Process -Timeout 5 -ErrorAction SilentlyContinue
            
            if (-not $process.HasExited) {
                $process | Stop-Process -Force
                throw "ESLint process timeout"
            }
            
            Remove-Item $testFile -Force -ErrorAction SilentlyContinue
            return @{
                Success = $true
                ExitCode = $process.ExitCode
            }
        } else {
            return @{
                Success = $false
                Error = "ESLint not found"
            }
        }
    } catch {
        return @{
            Success = $false
            Error = $_.ToString()
        }
    }
}

if ($eslintTestResult.Status -eq 'Completed' -and $eslintTestResult.Output.Success) {
    Write-Host "[PASSED] ESLint Test" -ForegroundColor Green
    Write-Host "  ESLint executed successfully" -ForegroundColor Gray
    $testResults.Summary.Passed++
} elseif ($eslintTestResult.Status -eq 'Timeout') {
    Write-Host "[TIMEOUT] ESLint Test" -ForegroundColor Yellow
    Write-Host "  ESLint execution timed out (may be hanging)" -ForegroundColor Yellow
    $testResults.Summary.Failed++
} else {
    Write-Host "[FAILED] ESLint Test" -ForegroundColor Red
    Write-Host "  Error: $($eslintTestResult.Output.Error)" -ForegroundColor Red
    $testResults.Summary.Failed++
}

# Test 4: Pylint with timeout
Write-Host "`nTesting Pylint (With Timeout)..." -ForegroundColor Yellow
$pylintTestResult = Test-WithTimeout -TestName "Pylint" -TimeoutSeconds 10 -TestScript {
    try {
        # Create a simple Python file
        $testFile = "$env:TEMP\test-pylint-$(Get-Random).py"
        @'
def test():
    x = 1
    print("Test")
'@ | Out-File -FilePath $testFile -Encoding UTF8
        
        $pylintPath = Get-Command pylint -ErrorAction SilentlyContinue
        if ($pylintPath) {
            $process = Start-Process -FilePath "pylint" -ArgumentList "--output-format=json `"$testFile`"" -NoNewWindow -PassThru -RedirectStandardOutput "$env:TEMP\pylint-out.txt" -RedirectStandardError "$env:TEMP\pylint-err.txt"
            
            # Wait max 5 seconds
            $process | Wait-Process -Timeout 5 -ErrorAction SilentlyContinue
            
            if (-not $process.HasExited) {
                $process | Stop-Process -Force
                throw "Pylint process timeout"
            }
            
            Remove-Item $testFile -Force -ErrorAction SilentlyContinue
            return @{
                Success = $true
                ExitCode = $process.ExitCode
            }
        } else {
            return @{
                Success = $false
                Error = "Pylint not found"
            }
        }
    } catch {
        return @{
            Success = $false
            Error = $_.ToString()
        }
    }
}

if ($pylintTestResult.Status -eq 'Completed' -and $pylintTestResult.Output.Success) {
    Write-Host "[PASSED] Pylint Test" -ForegroundColor Green
    Write-Host "  Pylint executed successfully" -ForegroundColor Gray
    $testResults.Summary.Passed++
} elseif ($pylintTestResult.Status -eq 'Timeout') {
    Write-Host "[TIMEOUT] Pylint Test" -ForegroundColor Yellow
    Write-Host "  Pylint execution timed out" -ForegroundColor Yellow
    $testResults.Summary.Failed++
} else {
    Write-Host "[FAILED] Pylint Test" -ForegroundColor Red
    Write-Host "  Error: $($pylintTestResult.Output.Error)" -ForegroundColor Red
    $testResults.Summary.Failed++
}

# Summary
Write-Host "`n" ("=" * 60) -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host "Total Tests: $($testResults.Summary.Passed + $testResults.Summary.Failed + $testResults.Summary.Skipped)" -ForegroundColor White
Write-Host "Passed: $($testResults.Summary.Passed)" -ForegroundColor Green
Write-Host "Failed: $($testResults.Summary.Failed)" -ForegroundColor Red
Write-Host "Skipped: $($testResults.Summary.Skipped)" -ForegroundColor Yellow

$testResults.EndTime = Get-Date
$testResults.Duration = ($testResults.EndTime - $testResults.StartTime).TotalSeconds

# Save results if requested
if ($SaveResults) {
    $resultsFile = "$PSScriptRoot\Test-StaticAnalysisIntegration-Results-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $testResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultsFile -Encoding UTF8
    Write-Host "`nResults saved to: $resultsFile" -ForegroundColor Green
}

# Exit code
$exitCode = if ($testResults.Summary.Failed -eq 0) { 0 } else { 1 }
Write-Host "`nTest completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
exit $exitCode
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAnCiaBPVJAI4If
# q1HGfek59euIBpBJNBU+y2KUL+m+VKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIEaYbgfkWgIvhvTwJgtzm+ZH
# aAVVeaKkIKPu7sqhBfnPMA0GCSqGSIb3DQEBAQUABIIBABiRHUVbwSRc+5fClnua
# /nfFN4qROGdxjiwN6ORW35O/GPx6ksB8DpbStGfWtbs9y6L+Z+Xb9I0pB4yZKtsF
# DfpB8E+jNLx8JcPsmm/SUHdQXLkx0HscdA5Jhl9fsz5ciXPT6o95QnPoPMagJCwW
# aQ+7Ctt2lfUyxep7p1Mjtsm1j/f7TTs9LsGSOb1+rpxG3fi8+L0DLn5YS8ckxCF+
# wKOIDES/QotUT0EotOwg3Rhe1RX7AURIShFf+5wcOtrxVp/VF4nKigF0GuhGALqB
# qCAjg6WPNq4I1FLC/L+zNAdpWvt57A4ZjG5i+b2syOp8ANMoSJDQ796Yt0XdEP1X
# 8+s=
# SIG # End signature block
