# Test-RepoAnalystEnvironment.ps1
# Environment validation script for Unity-Claude Repo Analyst

[CmdletBinding()]
param()

Write-Host "=== Unity-Claude Repo Analyst Environment Test ===" -ForegroundColor Cyan
Write-Host ""

$testResults = @{
    WSL2 = $false
    Ripgrep = $false
    Ctags = $false
    Git = $false
    Python = $false
    LangGraph = $false
    AutoGen = $false
    PowerShellModule = $false
    DirectoryStructure = $false
}

# Test directory structure
Write-Host "Testing directory structure..." -NoNewline
$requiredDirs = @(
    ".ai\mcp",
    ".ai\cache", 
    ".ai\rules",
    "agents\analyst_docs",
    "agents\research_lab",
    "agents\implementers",
    "scripts\codegraph",
    "scripts\docs",
    "Modules\Unity-Claude-RepoAnalyst"
)

$allDirsExist = $true
foreach ($dir in $requiredDirs) {
    $fullPath = Join-Path $PSScriptRoot $dir
    if (-not (Test-Path $fullPath)) {
        $allDirsExist = $false
        Write-Verbose "Missing directory: $fullPath"
    }
}

if ($allDirsExist) {
    $testResults.DirectoryStructure = $true
    Write-Host " PASS" -ForegroundColor Green
} else {
    Write-Host " FAIL (run script to create directories)" -ForegroundColor Red
}

# Test WSL2
Write-Host "Testing WSL2..." -NoNewline
try {
    $wslVersion = wsl --status 2>&1
    if ($LASTEXITCODE -eq 0) {
        $testResults.WSL2 = $true
        Write-Host " PASS" -ForegroundColor Green
    } else {
        Write-Host " FAIL" -ForegroundColor Red
    }
} catch {
    Write-Host " FAIL" -ForegroundColor Red
}

# Test ripgrep
Write-Host "Testing ripgrep..." -NoNewline
try {
    $rgVersion = rg --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        $testResults.Ripgrep = $true
        $versionString = if ($rgVersion -is [array]) { $rgVersion[0] } else { $rgVersion.ToString() }
        Write-Host " PASS ($versionString)" -ForegroundColor Green
    } else {
        Write-Host " FAIL" -ForegroundColor Red
    }
} catch {
    Write-Host " FAIL" -ForegroundColor Red
}

# Test universal-ctags
Write-Host "Testing universal-ctags..." -NoNewline
try {
    $ctagsVersion = ctags --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        $testResults.Ctags = $true
        Write-Host " PASS" -ForegroundColor Green
    } else {
        Write-Host " FAIL" -ForegroundColor Red
    }
} catch {
    Write-Host " FAIL" -ForegroundColor Red
}

# Test Git
Write-Host "Testing Git..." -NoNewline
try {
    $gitVersion = git --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        $testResults.Git = $true
        Write-Host " PASS ($gitVersion)" -ForegroundColor Green
    } else {
        Write-Host " FAIL" -ForegroundColor Red
    }
} catch {
    Write-Host " FAIL" -ForegroundColor Red
}

# Test Python in WSL
if ($testResults.WSL2) {
    Write-Host "Testing Python in WSL..." -NoNewline
    try {
        $pythonVersion = wsl -d Ubuntu -e bash -c "python3 --version" 2>&1
        if ($LASTEXITCODE -eq 0) {
            $testResults.Python = $true
            Write-Host " PASS ($pythonVersion)" -ForegroundColor Green
        } else {
            Write-Host " FAIL (Python3 not installed)" -ForegroundColor Red
        }
    } catch {
        Write-Host " FAIL" -ForegroundColor Red
    }
    
    # Test LangGraph
    if ($testResults.Python) {
        Write-Host "Testing LangGraph in WSL..." -NoNewline
        try {
            $venvPath = "/mnt/c/UnityProjects/Sound-and-Shoal/Unity-Claude-Automation"
            $langGraphTest = wsl -d Ubuntu -e bash -c "cd $venvPath && source .venv/bin/activate && python -c 'import langgraph; print(\"LangGraph available\")'" 2>&1
            if ($LASTEXITCODE -eq 0) {
                $testResults.LangGraph = $true
                Write-Host " PASS" -ForegroundColor Green
            } else {
                Write-Host " FAIL (venv may not be set up)" -ForegroundColor Red
            }
        } catch {
            Write-Host " FAIL" -ForegroundColor Red
        }
        
        # Test AutoGen
        Write-Host "Testing AutoGen in WSL..." -NoNewline
        try {
            $autoGenTest = wsl -d Ubuntu -e bash -c "cd $venvPath && source .venv/bin/activate && python -c 'import autogen_core; print(\"AutoGen available\")'" 2>&1
            if ($LASTEXITCODE -eq 0) {
                $testResults.AutoGen = $true
                Write-Host " PASS" -ForegroundColor Green
            } else {
                Write-Host " FAIL (venv may not be set up)" -ForegroundColor Red
            }
        } catch {
            Write-Host " FAIL" -ForegroundColor Red
        }
    }
}

# Test PowerShell Module
Write-Host "Testing Unity-Claude-RepoAnalyst module..." -NoNewline
try {
    $modulePath = Join-Path $PSScriptRoot "Modules\Unity-Claude-RepoAnalyst\Unity-Claude-RepoAnalyst.psd1"
    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force -ErrorAction Stop
        $testResults.PowerShellModule = $true
        Write-Host " PASS" -ForegroundColor Green
    } else {
        Write-Host " FAIL (module not found)" -ForegroundColor Red
    }
} catch {
    Write-Host " FAIL ($_)" -ForegroundColor Red
}

# Summary
Write-Host ""
Write-Host "=== Test Summary ===" -ForegroundColor Cyan
$passCount = ($testResults.Values | Where-Object { $_ -eq $true }).Count
$totalCount = $testResults.Count

$summaryColor = if ($passCount -eq $totalCount) { "Green" } elseif ($passCount -ge 5) { "Yellow" } else { "Red" }
Write-Host "Passed: $passCount/$totalCount" -ForegroundColor $summaryColor

if ($passCount -lt $totalCount) {
    Write-Host ""
    Write-Host "Failed components:" -ForegroundColor Yellow
    $testResults.GetEnumerator() | Where-Object { $_.Value -eq $false } | ForEach-Object {
        Write-Host "  - $($_.Key)" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "To fix missing components:" -ForegroundColor Cyan
    Write-Host "1. Run '.\Install-RepoAnalystTools.ps1' to install missing tools"
    Write-Host "2. If WSL/Python issues persist, run with administrator privileges"
    Write-Host "3. Restart PowerShell after installation"
}

# Save test results
$resultsFile = Join-Path $PSScriptRoot "RepoAnalyst_EnvironmentTest_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$testResults | ConvertTo-Json -Depth 2 | Out-File $resultsFile -Encoding UTF8
Write-Host ""
Write-Host "Test results saved to: $resultsFile" -ForegroundColor Gray

# Return results for automation
return $testResults
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBwCEyML3aChE1V
# O/dQlqedEnN7vLwVaaxhDRmQEJWz2aCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIIHN4iilcwVXtatI3NMQnXxc
# cUlvXVt+Gw+q7RDYN1+9MA0GCSqGSIb3DQEBAQUABIIBADFbtWv0t9EyvnSJUIYc
# p+2WunzvXw1kH+co+kTJxt3i8iyYfuRBhre/3Btt3jeiqNk8GzmrWAFQ1K4YGBgV
# D46a/nLzJHAv39i/SlRJ21E5r5N1nPgRkDa9VIJuhKVQnCV7XH7xgm19OLyBfsgv
# 4gUdbf/G7Fh5k2kLGzC0qN91N2RYHwg3y0INeNp5nK+Jp7jOH0S8uzgiUQhVuwN8
# oQaKNPqjSp/mcHZude5vKNh5XY2swPIcn3t+4Rqz0bNGgzU9q6QheWui/n2dwVAG
# Lgy11T0c5me6zIMIlsis+LY5WM02InNI6WlzEP67fJK7MZIRCvuNrNiqRS0L9WPb
# bsI=
# SIG # End signature block
