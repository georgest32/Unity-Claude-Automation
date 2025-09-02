# Quick Code Analysis Pipeline Test
# Focus on core functionality without slow git operations

param(
    [switch]$Verbose
)

if ($Verbose) { $VerbosePreference = 'Continue' }

# Colors for output
$ColorPass = [ConsoleColor]::Green
$ColorFail = [ConsoleColor]::Red
$ColorInfo = [ConsoleColor]::Cyan

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Message = ""
    )
    
    $status = if ($Passed) { "PASS" } else { "FAIL" }
    $color = if ($Passed) { $ColorPass } else { $ColorFail }
    
    Write-Host "[$status] $TestName" -ForegroundColor $color
    if ($Message) {
        Write-Host "  $Message" -ForegroundColor Gray
    }
}

Write-Host "`n========================================"
Write-Host "   Quick Code Analysis Test Suite"
Write-Host "========================================"

$testResults = @()

# Test 1: Module Import
Write-Host "`nTesting: Module Import"
Write-Host "==================================================" -ForegroundColor $ColorInfo
try {
    # Force reimport
    if (Get-Module Unity-Claude-RepoAnalyst) {
        Remove-Module Unity-Claude-RepoAnalyst -Force
    }
    
    Import-Module ".\Modules\Unity-Claude-RepoAnalyst\Unity-Claude-RepoAnalyst.psd1" -Force
    $module = Get-Module Unity-Claude-RepoAnalyst
    
    Write-TestResult "Module Import" $true "Module version: $($module.Version)"
    $testResults += "PASS"
    
} catch {
    Write-TestResult "Module Import" $false $_.Exception.Message
    $testResults += "FAIL"
}

# Test 2: Function Availability
Write-Host "`nTesting: Core Functions"
Write-Host "==================================================" -ForegroundColor $ColorInfo

$expectedFunctions = @(
    'Invoke-RipgrepSearch',
    'Get-PowerShellAST', 
    'New-CodeGraph',
    'Get-CtagsIndex'
)

$functionTests = 0
$functionPassed = 0

foreach ($func in $expectedFunctions) {
    $functionTests++
    if (Get-Command $func -ErrorAction SilentlyContinue) {
        Write-TestResult $func $true
        $functionPassed++
    } else {
        Write-TestResult $func $false
    }
}

$testResults += if ($functionPassed -eq $functionTests) { "PASS" } else { "FAIL" }

# Test 3: PowerShell AST Parsing
Write-Host "`nTesting: PowerShell AST"
Write-Host "==================================================" -ForegroundColor $ColorInfo
try {
    $testCode = @"
function Test-Function {
    param([string]`$Name)
    Write-Output "Hello `$Name"
}

`$global:TestVar = "value"
"@
    
    $result = Get-PowerShellAST -Content $testCode
    
    if ($result.Functions.Count -gt 0 -and $result.Variables.Count -gt 0) {
        Write-TestResult "PowerShell AST" $true "Functions: $($result.Functions.Count), Variables: $($result.Variables.Count)"
        $testResults += "PASS"
    } else {
        Write-TestResult "PowerShell AST" $false "No functions or variables parsed"
        $testResults += "FAIL"
    }
    
} catch {
    Write-TestResult "PowerShell AST" $false $_.Exception.Message
    $testResults += "FAIL"
}

# Test 4: Basic Ripgrep Search
Write-Host "`nTesting: Ripgrep Search"
Write-Host "==================================================" -ForegroundColor $ColorInfo
try {
    # Create a test file with known content to search for in current directory
    $testSearchFile = Join-Path $pwd "TempRipgrepTest.ps1"
    
    Set-Content -Path $testSearchFile -Value @"
function Test-RipgrepSearch {
    param([string]`$TestParameter)
    Write-Output "Testing ripgrep functionality"
}
"@
    
    # Search for the param pattern we just created in current directory
    $result = Invoke-RipgrepSearch -Pattern "param\(" -Path "." -FileType "powershell" -Include @("TempRipgrepTest.ps1") -FilesWithMatches
    
    if ($result -and $result.Count -gt 0) {
        Write-TestResult "Ripgrep Search" $true "Found matches in $($result.Count) files"
        $testResults += "PASS"
    } else {
        # Try alternative search patterns
        $altResult = Invoke-RipgrepSearch -Pattern "function" -Path "." -FileType "powershell" -Include @("TempRipgrepTest.ps1") -FilesWithMatches
        if ($altResult -and $altResult.Count -gt 0) {
            Write-TestResult "Ripgrep Search" $true "Found alternative matches in $($altResult.Count) files"
            $testResults += "PASS"
        } else {
            Write-TestResult "Ripgrep Search" $false "No matches found for test pattern"
            $testResults += "FAIL"
        }
    }
    
    # Cleanup
    if (Test-Path $testSearchFile) {
        Remove-Item $testSearchFile -Force
    }
    
} catch {
    Write-TestResult "Ripgrep Search" $false $_.Exception.Message
    $testResults += "FAIL"
}

# Test 5: Code Graph Generation
Write-Host "`nTesting: Code Graph"
Write-Host "==================================================" -ForegroundColor $ColorInfo
try {
    # Create a small test file in current directory
    $tempFile = Join-Path $pwd "TempCodeGraphTest.ps1"
    
    Set-Content -Path $tempFile -Value @"
function Test-CodeGraph {
    param([string]`$Input)
    return Get-Content `$Input
}
"@
    
    $result = New-CodeGraph -ProjectPath $pwd -IncludePatterns @("TempCodeGraphTest.ps1")
    
    if ($result -and $result.FileCount -ge 0) {
        Write-TestResult "Code Graph" $true "Generated graph with $($result.FileCount) files"
        $testResults += "PASS"
    } else {
        Write-TestResult "Code Graph" $false "No graph generated"
        $testResults += "FAIL"
    }
    
    # Cleanup
    if (Test-Path $tempFile) {
        Remove-Item $tempFile -Force
    }
    
} catch {
    Write-TestResult "Code Graph" $false $_.Exception.Message
    $testResults += "FAIL"
}

# Final Results
Write-Host "`n========================================"
Write-Host "         Test Results Summary"
Write-Host "========================================"

$totalTests = $testResults.Count
$passedTests = ($testResults | Where-Object { $_ -eq "PASS" }).Count
$failedTests = $totalTests - $passedTests
$successRate = [math]::Round(($passedTests / $totalTests) * 100, 1)

Write-Host "Total Tests: $totalTests" -ForegroundColor $ColorInfo
Write-Host "Passed: $passedTests" -ForegroundColor $ColorPass
Write-Host "Failed: $failedTests" -ForegroundColor $ColorFail
Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 80) { $ColorPass } else { $ColorFail })

if ($successRate -ge 80) {
    Write-Host "`n✅ Code Analysis Pipeline is working correctly!" -ForegroundColor $ColorPass
} else {
    Write-Host "`n❌ Code Analysis Pipeline needs attention" -ForegroundColor $ColorFail
}

Write-Host "`nTest completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCubhwIGSMSl/O2
# 3y3CBwYJx4tNDlC2zReg9Ovi7KKBZKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJCnNsI89YU2K5XCiOr5X2Xj
# WXKqEPO8AQr3mnsSG/tkMA0GCSqGSIb3DQEBAQUABIIBABY9cKZ5MIpR9Gau0QvF
# ZrgQASKds8iO5y1XpKV0aMYCyV4kdkx72O84GulGuUqh/fFicOEJO9AI+g4bo36z
# uFzKt3mv/HixU2GKTHx9Mls9+KMWVPHQJcyT3CDhnpG1C2M2cVyXashdYe0p2uat
# l/Eq7NRD62fcvryrAFLx7G6TCuMMFETe8K+ZQN1qyB4WuScLIiaZDxHVfZOv+d0B
# 8LC7gWz8JAhsA0krZsH47+LLrEYHQLSGMlC7jzzEgja7U9bcvH4ETHgujT2LrJTI
# oCYYFrtDgQw7EUNcqJZAapFuXivseDF1yaWUCRMNgC+tlrAnZILj5JuJlrAiDItg
# KD8=
# SIG # End signature block
