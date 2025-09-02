# Test-MultiAgentSystem.ps1
# PowerShell test script for Phase 4 Multi-Agent System

param(
    [switch]$RunPythonTests,
    [switch]$StartRESTBridge,
    [switch]$TestPowerShellIntegration,
    [switch]$RunAll
)

$ErrorActionPreference = "Continue"

Write-Host "`n" -NoNewline
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " PHASE 4 MULTI-AGENT SYSTEM TEST SUITE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray

# Test 1: Check Python Environment
function Test-PythonEnvironment {
    Write-Host "`n[TEST 1] Python Environment Check" -ForegroundColor Yellow
    Write-Host "="*40 -ForegroundColor DarkGray
    
    $pythonVersion = & python --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Python available: $pythonVersion" -ForegroundColor Green
    } else {
        Write-Host "❌ Python not found" -ForegroundColor Red
        return $false
    }
    
    # Check WSL2
    $wslVersion = wsl --version 2>&1 | Select-String "WSL version"
    if ($wslVersion) {
        Write-Host "✅ WSL2 available: $wslVersion" -ForegroundColor Green
    } else {
        Write-Host "⚠️  WSL2 not detected (optional)" -ForegroundColor Yellow
    }
    
    return $true
}

# Test 2: Check Directory Structure
function Test-DirectoryStructure {
    Write-Host "`n[TEST 2] Directory Structure Check" -ForegroundColor Yellow
    Write-Host "="*40 -ForegroundColor DarkGray
    
    $requiredDirs = @(
        ".ai\mcp",
        ".ai\cache",
        ".ai\rules",
        "agents\analyst_docs",
        "agents\research_lab",
        "agents\implementers"
    )
    
    $allExist = $true
    foreach ($dir in $requiredDirs) {
        if (Test-Path $dir) {
            Write-Host "✅ Directory exists: $dir" -ForegroundColor Green
        } else {
            Write-Host "❌ Directory missing: $dir" -ForegroundColor Red
            $allExist = $false
        }
    }
    
    return $allExist
}

# Test 3: Check Python Files
function Test-PythonFiles {
    Write-Host "`n[TEST 3] Python Module Files Check" -ForegroundColor Yellow
    Write-Host "="*40 -ForegroundColor DarkGray
    
    $requiredFiles = @(
        "test_autogen_groupchat.py",
        "powershell_python_bridge.py",
        "powershell_rest_bridge.py",
        "supervisor_coordination.py",
        "agents\analyst_docs\repo_analyst_config.py",
        "agents\research_lab\research_agents_config.py",
        "agents\implementers\implementer_agents_config.py"
    )
    
    $allExist = $true
    foreach ($file in $requiredFiles) {
        if (Test-Path $file) {
            Write-Host "✅ File exists: $file" -ForegroundColor Green
        } else {
            Write-Host "❌ File missing: $file" -ForegroundColor Red
            $allExist = $false
        }
    }
    
    return $allExist
}

# Test 4: Run Python Tests (in WSL2)
function Test-PythonMultiAgentSystem {
    Write-Host "`n[TEST 4] Running Python Multi-Agent Tests" -ForegroundColor Yellow
    Write-Host "="*40 -ForegroundColor DarkGray
    
    if (-not (Test-Path "test_multi_agent_system.py")) {
        Write-Host "❌ Test file not found: test_multi_agent_system.py" -ForegroundColor Red
        return $false
    }
    
    Write-Host "Running tests in WSL2 environment..." -ForegroundColor Cyan
    $testCommand = "cd /mnt/c/UnityProjects/Sound-and-Shoal/Unity-Claude-Automation && source langgraph-env/bin/activate && python test_multi_agent_system.py"
    
    $result = wsl -e bash -c $testCommand
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Python tests completed successfully" -ForegroundColor Green
        return $true
    } else {
        Write-Host "⚠️  Some Python tests failed (see output above)" -ForegroundColor Yellow
        return $false
    }
}

# Test 5: PowerShell Module Integration
function Test-PowerShellModules {
    Write-Host "`n[TEST 5] PowerShell Module Integration Check" -ForegroundColor Yellow
    Write-Host "="*40 -ForegroundColor DarkGray
    
    $modulePath = ".\Modules"
    if (-not (Test-Path $modulePath)) {
        Write-Host "❌ Modules directory not found" -ForegroundColor Red
        return $false
    }
    
    # Check for Unity-Claude modules
    $unityModules = Get-ChildItem -Path $modulePath -Directory -Filter "Unity-Claude-*" | Select-Object -First 5
    
    if ($unityModules) {
        Write-Host "✅ Found $($unityModules.Count) Unity-Claude modules:" -ForegroundColor Green
        foreach ($module in $unityModules) {
            Write-Host "   - $($module.Name)" -ForegroundColor Gray
        }
        return $true
    } else {
        Write-Host "❌ No Unity-Claude modules found" -ForegroundColor Red
        return $false
    }
}

# Test 6: Start REST Bridge Server (optional)
function Start-PowerShellRESTBridge {
    Write-Host "`n[TEST 6] Starting PowerShell REST Bridge Server" -ForegroundColor Yellow
    Write-Host "="*40 -ForegroundColor DarkGray
    
    if (-not (Test-Path "powershell_rest_bridge.py")) {
        Write-Host "❌ REST bridge file not found" -ForegroundColor Red
        return $false
    }
    
    Write-Host "Starting REST bridge server on port 8000..." -ForegroundColor Cyan
    Write-Host "NOTE: This requires FastAPI and uvicorn installed" -ForegroundColor Gray
    
    # Start in new window
    $pythonExe = (Get-Command python).Source
    Start-Process -FilePath $pythonExe -ArgumentList "powershell_rest_bridge.py", "server" -WindowStyle Normal
    
    Write-Host "⚠️  REST bridge started in new window (verify manually)" -ForegroundColor Yellow
    Write-Host "   Access at: http://localhost:8000" -ForegroundColor Gray
    Write-Host "   Health check: http://localhost:8000/health" -ForegroundColor Gray
    
    return $true
}

# Main test execution
function Run-AllTests {
    $results = @{}
    
    # Run basic tests
    $results["Python Environment"] = Test-PythonEnvironment
    $results["Directory Structure"] = Test-DirectoryStructure
    $results["Python Files"] = Test-PythonFiles
    $results["PowerShell Modules"] = Test-PowerShellModules
    
    # Run Python tests if requested
    if ($RunPythonTests -or $RunAll) {
        $results["Python Multi-Agent Tests"] = Test-PythonMultiAgentSystem
    }
    
    # Start REST bridge if requested
    if ($StartRESTBridge -or $RunAll) {
        $results["REST Bridge Server"] = Start-PowerShellRESTBridge
    }
    
    # Summary
    Write-Host "`n" -NoNewline
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " TEST SUMMARY" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    
    $passed = 0
    $total = $results.Count
    
    foreach ($test in $results.GetEnumerator()) {
        $status = if ($test.Value) { "✅ PASSED" } else { "❌ FAILED" }
        $color = if ($test.Value) { "Green" } else { "Red" }
        Write-Host "$($test.Key.PadRight(30, '.')) $status" -ForegroundColor $color
        if ($test.Value) { $passed++ }
    }
    
    Write-Host "`nOverall Results: $passed/$total tests passed" -ForegroundColor Cyan
    
    if ($passed -eq $total) {
        Write-Host "`n🎉 SUCCESS: All tests passed! Multi-agent system is ready." -ForegroundColor Green
    } else {
        Write-Host "`n⚠️  WARNING: $($total - $passed) test(s) failed." -ForegroundColor Yellow
        Write-Host "Review the output above for specific issues." -ForegroundColor Yellow
    }
    
    return ($passed -eq $total)
}

# Execute based on parameters
if ($RunAll) {
    $success = Run-AllTests
} elseif ($RunPythonTests) {
    Test-PythonMultiAgentSystem
} elseif ($StartRESTBridge) {
    Start-PowerShellRESTBridge
} elseif ($TestPowerShellIntegration) {
    Test-PowerShellModules
} else {
    # Run basic tests by default
    $results = @{}
    $results["Python Environment"] = Test-PythonEnvironment
    $results["Directory Structure"] = Test-DirectoryStructure
    $results["Python Files"] = Test-PythonFiles
    $results["PowerShell Modules"] = Test-PowerShellModules
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host " BASIC TEST SUMMARY" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    
    $passed = 0
    foreach ($test in $results.GetEnumerator()) {
        $status = if ($test.Value) { "✅ PASSED" } else { "❌ FAILED" }
        $color = if ($test.Value) { "Green" } else { "Red" }
        Write-Host "$($test.Key.PadRight(30, '.')) $status" -ForegroundColor $color
        if ($test.Value) { $passed++ }
    }
    
    Write-Host "`nBasic Tests: $passed/$($results.Count) passed" -ForegroundColor Cyan
    Write-Host "`nTo run full tests, use:" -ForegroundColor Gray
    Write-Host "  .\Test-MultiAgentSystem.ps1 -RunAll" -ForegroundColor White
    Write-Host "Or specific tests:" -ForegroundColor Gray
    Write-Host "  .\Test-MultiAgentSystem.ps1 -RunPythonTests" -ForegroundColor White
    Write-Host "  .\Test-MultiAgentSystem.ps1 -StartRESTBridge" -ForegroundColor White
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD6rM7TBHsdQKk/
# XazS/VuV7K6ZqaK1t8gF8boX0jQ6TqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIGobnBDtiFrGuk0V56J8LL/9
# sJOpr04mYePCGrqOkxTpMA0GCSqGSIb3DQEBAQUABIIBAH3YmOooFgpUJcMZaJ5a
# 0NPOWfI/mtwhLJ/PtyGLIP6unAyf/0LEoqxYJnrkVhBUYCI+Ro+tkU2VxJssR9XO
# gQwDRz1oSUbdI++RjYgdzRxX18sYZAR1cB/3GrmGdUg4t5MRQj/4+JQVD6tTDVVU
# jX7u27t1ljbe/jJWzCAY/cUv4aOejEMkjf5ypSaIcIzjXiq2GzgtiZYjJ4gu6cuZ
# dZhLqMhlLDrMItPt5NVi4aSmMXXpNYybqgopnbm2quM9ePGVQw+EG2i2U3QdsDch
# MXPWLIV5QZa7hEFYnJXpv514Rn2zr9JEwWPyrdMChsP4oqySni+WkJfi7gpazXHc
# +XQ=
# SIG # End signature block
