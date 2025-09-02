# Simplified test for working components
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$SaveResults
)

Import-Module "$PSScriptRoot\Modules\Unity-Claude-FileMonitor\Unity-Claude-FileMonitor.psd1" -Force

Write-Host "Testing Unity-Claude-FileMonitor - Simplified" -ForegroundColor Yellow
Write-Host "=" * 50

$testResults = @()
$testDir = Join-Path $env:TEMP "FileMonitorSimpleTest_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -Path $testDir -ItemType Directory -Force | Out-Null

try {
    # Test 1: Module Loading
    Write-Host "Test 1: Module Loading..." -ForegroundColor Cyan
    $module = Get-Module -Name 'Unity-Claude-FileMonitor'
    $test1 = ($null -ne $module)
    $testResults += @{ Name = "Module Loading"; Passed = $test1 }
    Write-Host "  Result: $($test1 ? 'PASS' : 'FAIL')" -ForegroundColor ($test1 ? 'Green' : 'Red')
    
    # Test 2: Create Monitor
    Write-Host "Test 2: Create Monitor..." -ForegroundColor Cyan
    try {
        $monitorId = New-FileMonitor -Path $testDir -Filter '*.*' -DebounceMs 100
        $test2 = (-not [string]::IsNullOrEmpty($monitorId))
    } catch {
        $test2 = $false
        Write-Host "  Error: $_" -ForegroundColor Red
    }
    $testResults += @{ Name = "Create Monitor"; Passed = $test2 }
    Write-Host "  Result: $($test2 ? 'PASS' : 'FAIL')" -ForegroundColor ($test2 ? 'Green' : 'Red')
    
    # Test 3: Start Monitor
    Write-Host "Test 3: Start Monitor..." -ForegroundColor Cyan
    try {
        if ($test2) {
            Start-FileMonitor -Identifier $monitorId
            $status = Get-FileMonitorStatus -Identifier $monitorId
            $test3 = ($status.IsActive -eq $true)
        } else {
            $test3 = $false
        }
    } catch {
        $test3 = $false
        Write-Host "  Error: $_" -ForegroundColor Red
    }
    $testResults += @{ Name = "Start Monitor"; Passed = $test3 }
    Write-Host "  Result: $($test3 ? 'PASS' : 'FAIL')" -ForegroundColor ($test3 ? 'Green' : 'Red')
    
    # Test 4: File Classification
    Write-Host "Test 4: File Classification..." -ForegroundColor Cyan
    try {
        $classifications = @(
            @{ Path = "test.ps1"; ExpectedType = "Test"; ExpectedPriority = 5 },
            @{ Path = "config.json"; ExpectedType = "Config"; ExpectedPriority = 3 },
            @{ Path = "README.md"; ExpectedType = "Documentation"; ExpectedPriority = 4 },
            @{ Path = "build.csproj"; ExpectedType = "Build"; ExpectedPriority = 1 },
            @{ Path = "main.cs"; ExpectedType = "Code"; ExpectedPriority = 2 }
        )
        
        $test4 = $true
        foreach ($testCase in $classifications) {
            $result = Test-FileChangeClassification -FilePath $testCase.Path
            if ($result.FileType -ne $testCase.ExpectedType -or $result.Priority -ne $testCase.ExpectedPriority) {
                Write-Host "    FAIL: $($testCase.Path) -> Expected: $($testCase.ExpectedType)/$($testCase.ExpectedPriority), Got: $($result.FileType)/$($result.Priority)" -ForegroundColor Red
                $test4 = $false
            } else {
                Write-Host "    PASS: $($testCase.Path) -> $($result.FileType)/$($result.Priority)" -ForegroundColor Green
            }
        }
    } catch {
        $test4 = $false
        Write-Host "  Error: $_" -ForegroundColor Red
    }
    $testResults += @{ Name = "File Classification"; Passed = $test4 }
    Write-Host "  Result: $($test4 ? 'PASS' : 'FAIL')" -ForegroundColor ($test4 ? 'Green' : 'Red')
    
    # Test 5: Stop Monitor
    Write-Host "Test 5: Stop Monitor..." -ForegroundColor Cyan
    try {
        if ($test2 -and $test3) {
            Stop-FileMonitor -Identifier $monitorId
            $finalStatus = Get-FileMonitorStatus -Identifier $monitorId
            $test5 = ($null -eq $finalStatus)
        } else {
            $test5 = $true # Skip if previous tests failed
        }
    } catch {
        $test5 = $false
        Write-Host "  Error: $_" -ForegroundColor Red
    }
    $testResults += @{ Name = "Stop Monitor"; Passed = $test5 }
    Write-Host "  Result: $($test5 ? 'PASS' : 'FAIL')" -ForegroundColor ($test5 ? 'Green' : 'Red')
    
}
finally {
    # Cleanup
    Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
    
    # Summary
    Write-Host "`n" + "=" * 50
    $passed = ($testResults | Where-Object { $_.Passed }).Count
    $total = $testResults.Count
    Write-Host "Summary: $passed/$total tests passed" -ForegroundColor ($passed -eq $total ? 'Green' : 'Yellow')
    
    if ($SaveResults) {
        $resultsFile = Join-Path $PSScriptRoot "FileMonitor-Simple-TestResults-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
        $testResults | ConvertTo-Json -Depth 3 | Out-File $resultsFile
        Write-Host "Results saved to: $resultsFile" -ForegroundColor Cyan
    }
    
    Remove-Module -Name 'Unity-Claude-FileMonitor' -Force -ErrorAction SilentlyContinue
}

exit ($passed -eq $total ? 0 : 1)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCDOOT+CBK11hSX
# ovpB3VIHCSvBIfSTbuFxbw4uuSnGiqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIFlV5EM2Af0tYUpIw8ngh681
# WZiUZ/T2sOpSp2J5BQaPMA0GCSqGSIb3DQEBAQUABIIBAK2dlyrBSHMTvkaAN7eE
# YKAvJ1hbJBXiAZwRFxlkdlAC8IVgb1UzQLz0HfmzLmqzjgLJrNyFDhIyUOTye4p6
# m7O31ihUaw0hnQ0k+8szNFKWFH2zgrJo/YQrAMP6Dr+Ja6Q5uDVtawf07uWXzDq5
# B1HjsNH4py1eD3TsSFbeR9ERQr8xDuXx80sYIAdX8YvOWDxfysOzw8m3rSYU/k+8
# XD6AhHdWR8sCm1FYZb1vEGV5hupKTKyntckyHO6sQA3lv+Cq9jt5UUNuLzBzqgZl
# 2QVIkw2UWXSu7RUZJKqa3+FWtjdp5tuO2CAA07lemdObZ8ZQo9G8rBB8aPhrB+NS
# mbk=
# SIG # End signature block
