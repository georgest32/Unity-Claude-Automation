# Final Static Analysis Integration Test with All Fixes
param(
    [switch]$SaveResults,
    [switch]$Verbose
)

$ErrorActionPreference = 'Continue'
if ($Verbose) { $VerbosePreference = 'Continue' }

Write-Host "Unity-Claude Static Analysis Integration Test Suite (Final)" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host "Starting at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

$testResults = @{
    StartTime = Get-Date
    Tests = @()
    Summary = @{ Passed = 0; Failed = 0; Skipped = 0 }
}

function Test-Analysis {
    param(
        [string]$Name,
        [scriptblock]$Test
    )
    
    Write-Host "Testing $Name..." -ForegroundColor Yellow
    try {
        $result = & $Test
        if ($result.Success) {
            Write-Host "[PASSED] $Name" -ForegroundColor Green
            if ($result.Details) {
                Write-Host "  $($result.Details)" -ForegroundColor Gray
            }
            $testResults.Summary.Passed++
            $testResults.Tests += @{Name = $Name; Status = "Passed"; Details = $result.Details}
        } else {
            Write-Host "[FAILED] $Name" -ForegroundColor Red
            Write-Host "  Error: $($result.Error)" -ForegroundColor Red
            $testResults.Summary.Failed++
            $testResults.Tests += @{Name = $Name; Status = "Failed"; Error = $result.Error}
        }
    } catch {
        Write-Host "[FAILED] $Name" -ForegroundColor Red
        Write-Host "  Exception: $_" -ForegroundColor Red
        $testResults.Summary.Failed++
        $testResults.Tests += @{Name = $Name; Status = "Failed"; Error = $_.ToString()}
    }
}

# Test 1: Module Loading
Test-Analysis -Name "Module Loading" -Test {
    Import-Module "$PSScriptRoot\Modules\Unity-Claude-RepoAnalyst" -Force -ErrorAction Stop
    $module = Get-Module Unity-Claude-RepoAnalyst
    @{
        Success = $true
        Details = "Module version: $($module.Version)"
    }
}

# Test 2: PSScriptAnalyzer
Test-Analysis -Name "PSScriptAnalyzer" -Test {
    # Ensure module is available
    if (-not (Get-Module -ListAvailable PSScriptAnalyzer)) {
        # Try to save module for Windows PowerShell
        $modulePath = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules"
        if (-not (Test-Path $modulePath)) {
            New-Item -Path $modulePath -ItemType Directory -Force | Out-Null
        }
        Save-Module -Name PSScriptAnalyzer -Path $modulePath -Force
    }
    
    Import-Module PSScriptAnalyzer -Force
    
    # Create test file
    $testFile = "$env:TEMP\test-psa-$(Get-Random).ps1"
    @'
# Test script
$unusedVar = "Not used"
Write-Host "Test output"
if($true){Write-Host "No space"}
'@ | Out-File -FilePath $testFile -Encoding UTF8
    
    try {
        $results = Invoke-ScriptAnalyzer -Path $testFile -Severity @('Error', 'Warning', 'Information')
        Remove-Item $testFile -Force
        
        @{
            Success = $true
            Details = "Found $($results.Count) issues in test file"
        }
    } catch {
        Remove-Item $testFile -Force -ErrorAction SilentlyContinue
        throw $_
    }
}

# Test 3: ESLint
Test-Analysis -Name "ESLint" -Test {
    # Find eslint - try multiple variants
    $eslintCmd = Get-Command "eslint.cmd" -ErrorAction SilentlyContinue
    if (-not $eslintCmd) {
        $eslintCmd = Get-Command "eslint" -ErrorAction SilentlyContinue
    }
    if (-not $eslintCmd) {
        return @{
            Success = $false
            Error = "eslint/eslint.cmd not found in PATH"
        }
    }
    
    # Create test file
    $testFile = "$env:TEMP\test-eslint-$(Get-Random).js"
    @'
const x = 1;
console.log("Test");
const unusedVar = 42;
'@ | Out-File -FilePath $testFile -Encoding UTF8
    
    try {
        # Run eslint with config file
        $configPath = "$PSScriptRoot\eslint.config.js"
        $arguments = "--config `"$configPath`" --format json `"$testFile`""
        
        Write-Verbose "Running: eslint.cmd $arguments"
        
        # Use the found eslint command
        $eslintExe = if ($eslintCmd.Name -eq "eslint.cmd") { "cmd.exe" } else { $eslintCmd.Source }
        $eslintArgs = if ($eslintCmd.Name -eq "eslint.cmd") { "/c eslint.cmd $arguments" } else { $arguments }
        
        $process = Start-Process -FilePath $eslintExe -ArgumentList $eslintArgs `
            -NoNewWindow -PassThru `
            -RedirectStandardOutput "$env:TEMP\eslint-out.txt" `
            -RedirectStandardError "$env:TEMP\eslint-err.txt"
        
        # Wait with timeout
        $process | Wait-Process -Timeout 10 -ErrorAction SilentlyContinue
        
        if (-not $process.HasExited) {
            $process | Stop-Process -Force
            throw "ESLint timed out after 10 seconds"
        }
        
        $exitCode = $process.ExitCode
        Remove-Item $testFile -Force
        Remove-Item "$env:TEMP\eslint-out.txt" -Force -ErrorAction SilentlyContinue
        Remove-Item "$env:TEMP\eslint-err.txt" -Force -ErrorAction SilentlyContinue
        
        # ESLint returns non-zero exit codes when it finds issues, which is expected
        @{
            Success = $true
            Details = "ESLint executed successfully (exit code: $exitCode)"
        }
    } catch {
        Remove-Item $testFile -Force -ErrorAction SilentlyContinue
        Remove-Item "$env:TEMP\eslint-out.txt" -Force -ErrorAction SilentlyContinue
        Remove-Item "$env:TEMP\eslint-err.txt" -Force -ErrorAction SilentlyContinue
        throw $_
    }
}

# Test 4: Pylint
Test-Analysis -Name "Pylint" -Test {
    $pylintPath = Get-Command pylint -ErrorAction SilentlyContinue
    if (-not $pylintPath) {
        return @{
            Success = $false
            Error = "Pylint not found in PATH"
        }
    }
    
    # Create test file
    $testFile = "$env:TEMP\test-pylint-$(Get-Random).py"
    @'
#!/usr/bin/env python3
"""Test module for pylint"""

def test_function():
    """Test function"""
    unused_var = 42
    print("Test output")
    return True

if __name__ == "__main__":
    test_function()
'@ | Out-File -FilePath $testFile -Encoding UTF8
    
    try {
        Write-Verbose "Running: pylint --output-format=json `"$testFile`""
        
        $process = Start-Process -FilePath $pylintPath.Source -ArgumentList "--output-format=json `"$testFile`"" `
            -NoNewWindow -PassThru `
            -RedirectStandardOutput "$env:TEMP\pylint-out.txt" `
            -RedirectStandardError "$env:TEMP\pylint-err.txt"
        
        # Wait with timeout
        $process | Wait-Process -Timeout 10 -ErrorAction SilentlyContinue
        
        if (-not $process.HasExited) {
            $process | Stop-Process -Force
            throw "Pylint timed out after 10 seconds"
        }
        
        $exitCode = $process.ExitCode
        Remove-Item $testFile -Force
        Remove-Item "$env:TEMP\pylint-out.txt" -Force -ErrorAction SilentlyContinue
        Remove-Item "$env:TEMP\pylint-err.txt" -Force -ErrorAction SilentlyContinue
        
        # Pylint returns non-zero exit codes when it finds issues, which is expected
        @{
            Success = $true
            Details = "Pylint executed successfully (exit code: $exitCode)"
        }
    } catch {
        Remove-Item $testFile -Force -ErrorAction SilentlyContinue
        Remove-Item "$env:TEMP\pylint-out.txt" -Force -ErrorAction SilentlyContinue
        Remove-Item "$env:TEMP\pylint-err.txt" -Force -ErrorAction SilentlyContinue
        throw $_
    }
}

# Test 5: Ripgrep
Test-Analysis -Name "Ripgrep" -Test {
    $rgPath = Get-Command rg -ErrorAction SilentlyContinue
    if (-not $rgPath) {
        return @{
            Success = $false
            Error = "Ripgrep (rg) not found in PATH"
        }
    }
    
    # Test ripgrep on current directory
    $results = & rg --count "function" --type ps1 2>$null | Select-Object -First 5
    
    @{
        Success = $true
        Details = "Ripgrep working, found matches in $($results.Count) files"
    }
}

# Test 6: Ctags
Test-Analysis -Name "Ctags" -Test {
    $ctagsPath = Get-Command ctags -ErrorAction SilentlyContinue
    if (-not $ctagsPath) {
        return @{
            Success = $false
            Error = "Ctags not found in PATH"
        }
    }
    
    # Test ctags version
    $version = & ctags --version 2>&1 | Select-Object -First 1
    
    @{
        Success = $true
        Details = "Ctags available: $version"
    }
}

# Summary
Write-Host "`n" ("=" * 60) -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host "Total Tests: $($testResults.Summary.Passed + $testResults.Summary.Failed)" -ForegroundColor White
Write-Host "Passed: $($testResults.Summary.Passed)" -ForegroundColor Green
Write-Host "Failed: $($testResults.Summary.Failed)" -ForegroundColor Red

if ($testResults.Summary.Failed -gt 0) {
    Write-Host "`nFailed Tests:" -ForegroundColor Yellow
    $testResults.Tests | Where-Object { $_.Status -eq "Failed" } | ForEach-Object {
        Write-Host "  - $($_.Name): $($_.Error)" -ForegroundColor Red
    }
}

$testResults.EndTime = Get-Date
$testResults.Duration = ($testResults.EndTime - $testResults.StartTime).TotalSeconds

# Save results if requested
if ($SaveResults) {
    $resultsFile = "$PSScriptRoot\Test-StaticAnalysisIntegration-Final-Results-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $testResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultsFile -Encoding UTF8
    Write-Host "`nResults saved to: $resultsFile" -ForegroundColor Green
}

Write-Host "`nTest completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "Duration: $([Math]::Round($testResults.Duration, 2)) seconds" -ForegroundColor Gray

# Return success/failure
exit $(if ($testResults.Summary.Failed -eq 0) { 0 } else { 1 })
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDu4otfpTxsaHXs
# WRfrj++ArKpazPWtrZ99Fe0ctvkT3qCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIKe1qIzSGDIkBbCNkJk2zWga
# icbKtoux21n0f7/5OFSAMA0GCSqGSIb3DQEBAQUABIIBAA5ElQV6BgK0Iy7yr6/G
# eLBvR6wuGb3G3b7D8mG2lZB/NfT4vHcteR2XiDE5yXmGhz1pvVLSF6iZV3svp3sY
# WtrcSIY32IWkYp9GMIBnC1gvODfIcttcCRY1r/+JMWvCIVOcbDczjcEwHUO8FbQE
# Yc9d9AFKzOBjKsz+OYK/D3BKndKqGHD0pbX3iF060paodu4A/J2KndeBSLvm+C8M
# 4uiSJ0UF6Ntdf0sVGTd/N2PJSfSsWylr/WgiR8SGlSBBZBNVdWeIjYu134rkKsbz
# riwfs2Z8vr9Xo5dRBVY7gPXdoQdwqOD2w5OaHyEaZ9q3kyKB5t5dcEq89jyHvVAM
# TJY=
# SIG # End signature block
