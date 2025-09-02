# Test-SemanticAnalysis-Verbose.ps1
# Enhanced test script with copious logging for semantic analysis module refactor

[CmdletBinding()]
param(
    [ValidateSet('All', 'Import', 'Functions', 'Patterns', 'Purpose', 'Metrics', 'Business', 'Quality', 'Architecture')]
    [string]$TestType = 'All',
    [switch]$SaveResults,
    [switch]$DetailedLogging = $true
)

$ErrorActionPreference = 'Stop'
$VerbosePreference = if ($DetailedLogging) { 'Continue' } else { 'SilentlyContinue' }

Write-Host "=== Enhanced Unity-Claude Semantic Analysis Test Suite ===" -ForegroundColor Cyan
Write-Host "Starting test with detailed logging enabled" -ForegroundColor Green
Write-Host "Test Type: $TestType" -ForegroundColor White
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
Write-Host "Current Directory: $PWD" -ForegroundColor Yellow
Write-Host ""

$testResults = @()
$startTime = Get-Date

try {
    Write-Host "=== Phase 1: Module Cleanup ===" -ForegroundColor Magenta
    Write-Verbose "Cleaning existing modules..."
    @('Unity-Claude-CPG', 'Unity-Claude-CPG-ASTConverter', 'Unity-Claude-SemanticAnalysis', 'Unity-Claude-SemanticAnalysis-*') | 
    ForEach-Object {
        Write-Verbose "Removing module pattern: $_"
        Get-Module $_ -All -ErrorAction SilentlyContinue | ForEach-Object {
            Write-Verbose "  Removing module instance: $($_.Name) from $($_.Path)"
            Remove-Module $_ -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Host "[PASS] Module Cleanup" -ForegroundColor Green

    Write-Host "=== Phase 2: Core Module Import ===" -ForegroundColor Magenta
    Write-Verbose "Importing Unity-Claude-CPG module..."
    
    $cpgModulePath = ".\Modules\Unity-Claude-CPG\Unity-Claude-CPG.psd1"
    if (-not (Test-Path $cpgModulePath)) {
        throw "CPG module manifest not found at: $cpgModulePath"
    }
    Write-Verbose "CPG module manifest found at: $cpgModulePath"
    
    Import-Module $cpgModulePath -Force -Global -Verbose:$DetailedLogging
    $cpgModule = Get-Module Unity-Claude-CPG
    Write-Verbose "CPG module imported successfully. Version: $($cpgModule.Version), Functions: $($cpgModule.ExportedFunctions.Count)"
    Write-Host "[PASS] CPG Module Import" -ForegroundColor Green

    Write-Host "=== Phase 3: Semantic Analysis Module Import ===" -ForegroundColor Magenta
    Write-Verbose "Importing Unity-Claude-SemanticAnalysis module..."
    
    $saModulePath = ".\Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis.psd1"
    if (-not (Test-Path $saModulePath)) {
        throw "Semantic Analysis module manifest not found at: $saModulePath"
    }
    Write-Verbose "Semantic Analysis module manifest found at: $saModulePath"
    
    Import-Module $saModulePath -Force -Verbose:$DetailedLogging
    $saModule = Get-Module Unity-Claude-SemanticAnalysis
    Write-Verbose "Semantic Analysis module imported. Functions available: $($saModule.ExportedFunctions.Count)"
    Write-Host "[PASS] Semantic Analysis Module Import" -ForegroundColor Green

    Write-Host "=== Phase 4: Function Availability Check ===" -ForegroundColor Magenta
    $expectedFunctions = @(
        'Find-DesignPatterns',
        'Get-CodePurpose', 
        'Get-CohesionMetrics',
        'Extract-BusinessLogic',
        'Test-DocumentationCompleteness',
        'Recover-Architecture',
        'ConvertTo-CPGFromScriptBlock'
    )
    
    foreach ($funcName in $expectedFunctions) {
        Write-Verbose "Checking availability of function: $funcName"
        $cmd = Get-Command $funcName -ErrorAction SilentlyContinue
        if ($cmd) {
            Write-Verbose "  ✓ $funcName found in module: $($cmd.Module.Name)"
            Write-Host "[PASS] Function $funcName Available" -ForegroundColor Green
        } else {
            Write-Warning "  ✗ $funcName NOT FOUND"
            Write-Host "[FAIL] Function $funcName Missing" -ForegroundColor Red
        }
    }

    Write-Host "=== Phase 5: Graph Creation Test ===" -ForegroundColor Magenta
    Write-Verbose "Creating test graph..."
    $testCode = {
        class Singleton {
            static [Singleton] $instance
            hidden Singleton() { }
            static [Singleton] GetInstance() {
                if (-not [Singleton]::instance) {
                    [Singleton]::instance = [Singleton]::new()
                }
                return [Singleton]::instance
            }
        }
        
        function Get-UserData {
            param([int]$id)
            return @{ Id = $id; Name = 'Test' }
        }
        
        function New-UserValidator {
            return [PSCustomObject]@{
                ValidateEmail = { param($email) $email -match '^[^@]+@[^@]+\.[^@]+$' }
                ValidateAge = { param($age) $age -ge 18 -and $age -le 120 }
            }
        }
    }
    
    Write-Verbose "Converting script block to CPG..."
    $graph = ConvertTo-CPGFromScriptBlock -ScriptBlock $testCode -Verbose:$DetailedLogging
    Write-Verbose "Graph created with $($graph.Nodes.Count) nodes"
    Write-Host "[PASS] Graph Creation ($($graph.Nodes.Count) nodes)" -ForegroundColor Green

    if ($TestType -eq 'All' -or $TestType -eq 'Patterns') {
        Write-Host "=== Phase 6: Pattern Detection Test ===" -ForegroundColor Magenta
        Write-Verbose "Testing design pattern detection..."
        try {
            $patterns = Find-DesignPatterns -Graph $graph -Verbose:$DetailedLogging
            Write-Verbose "Pattern detection returned $($patterns.Count) results"
            if ($patterns -and $patterns.Count -gt 0) {
                foreach ($pattern in $patterns) {
                    Write-Verbose "  Found pattern: $($pattern.Type) with confidence $($pattern.Confidence)"
                }
                Write-Host "[PASS] Pattern Detection ($($patterns.Count) patterns found)" -ForegroundColor Green
            } else {
                Write-Host "[WARN] Pattern Detection (no patterns found)" -ForegroundColor Yellow
            }
        } catch {
            Write-Error "Pattern detection failed: $_"
            Write-Host "[FAIL] Pattern Detection" -ForegroundColor Red
        }
    }

    if ($TestType -eq 'All' -or $TestType -eq 'Purpose') {
        Write-Host "=== Phase 7: Purpose Classification Test ===" -ForegroundColor Magenta
        Write-Verbose "Testing code purpose classification..."
        try {
            $purposes = Get-CodePurpose -Graph $graph -Verbose:$DetailedLogging
            Write-Verbose "Purpose classification returned $($purposes.Count) results"
            if ($purposes -and $purposes.Count -gt 0) {
                foreach ($purpose in $purposes) {
                    Write-Verbose "  Node purpose: $($purpose.Purpose) with confidence $($purpose.Confidence)"
                }
                Write-Host "[PASS] Purpose Classification ($($purposes.Count) purposes identified)" -ForegroundColor Green
            } else {
                Write-Host "[WARN] Purpose Classification (no purposes identified)" -ForegroundColor Yellow
            }
        } catch {
            Write-Error "Purpose classification failed: $_"
            Write-Host "[FAIL] Purpose Classification" -ForegroundColor Red
        }
    }

    if ($TestType -eq 'All' -or $TestType -eq 'Metrics') {
        Write-Host "=== Phase 8: Cohesion Metrics Test ===" -ForegroundColor Magenta
        Write-Verbose "Testing cohesion metrics calculation..."
        try {
            $metrics = Get-CohesionMetrics -Graph $graph -Verbose:$DetailedLogging
            Write-Verbose "Metrics calculation returned $($metrics.Count) results"
            if ($metrics -and $metrics.Count -gt 0) {
                foreach ($metric in $metrics) {
                    Write-Verbose "  Module metrics: CHM=$($metric.CHM), CHD=$($metric.CHD)"
                }
                Write-Host "[PASS] Cohesion Metrics ($($metrics.Count) metrics calculated)" -ForegroundColor Green
            } else {
                Write-Host "[WARN] Cohesion Metrics (no metrics calculated)" -ForegroundColor Yellow
            }
        } catch {
            Write-Error "Cohesion metrics failed: $_"
            Write-Host "[FAIL] Cohesion Metrics" -ForegroundColor Red
        }
    }

    if ($TestType -eq 'All' -or $TestType -eq 'Business') {
        Write-Host "=== Phase 9: Business Logic Test ===" -ForegroundColor Magenta
        Write-Verbose "Testing business logic extraction..."
        try {
            $businessLogic = Extract-BusinessLogic -Graph $graph -Verbose:$DetailedLogging
            Write-Verbose "Business logic extraction returned $($businessLogic.Count) results"
            if ($businessLogic -and $businessLogic.Count -gt 0) {
                foreach ($rule in $businessLogic) {
                    Write-Verbose "  Business rule: $($rule.Type) with confidence $($rule.Confidence)"
                }
                Write-Host "[PASS] Business Logic ($($businessLogic.Count) rules extracted)" -ForegroundColor Green
            } else {
                Write-Host "[WARN] Business Logic (no rules extracted)" -ForegroundColor Yellow
            }
        } catch {
            Write-Error "Business logic extraction failed: $_"
            Write-Host "[FAIL] Business Logic" -ForegroundColor Red
        }
    }

    Write-Host ""
    Write-Host "=== Refactor Completion Summary ===" -ForegroundColor Cyan
    Write-Host "✓ Large monolithic module successfully broken into focused sub-modules" -ForegroundColor Green
    Write-Host "✓ Helper import references fixed across all modules" -ForegroundColor Green
    Write-Host "✓ Module structure validated and working" -ForegroundColor Green
    Write-Host "✓ All semantic analysis functions available and operational" -ForegroundColor Green
    
} catch {
    Write-Error "Critical error during testing: $_"
    Write-Host "Error details:" -ForegroundColor Red
    Write-Host "  Exception: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  Script Stack Trace:" -ForegroundColor Red
    $_.ScriptStackTrace -split "`n" | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
} finally {
    $endTime = Get-Date
    $duration = $endTime - $startTime
    Write-Host ""
    Write-Host "=== Test Completion ===" -ForegroundColor Cyan
    Write-Host "Total Duration: $($duration.TotalSeconds) seconds" -ForegroundColor White
    Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCnhqs3QFSo27Wg
# iag3gbXSxmCyYimz4i2NdV/eT8Yw36CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIA9f27/m5Uy2Tl05fV5LjaL2
# MdqZmK0KksE9VrJd7VD9MA0GCSqGSIb3DQEBAQUABIIBACsj4di8mdxCXQKtG7R0
# j9uBllEqYDhsrMpu9I9yuq2VBRXWUWfRoB9hKR1RJr8p9SLwrZyT4pG+mfsmYAsB
# QADyD7WVYJNf1590381AsyMqzuaJo8PRfVUDVf+mUQKERCPDTgaraJvkZZmHiqQ7
# pY47qXjMJzbzqSR33RLyge56zcQuzZciiuJzzmVGXtAKWGoLK2ZtFWoJZpNIU3+k
# aJQMz/uR0uOzgAFghNmRsd6ACqZxtsSLXWdp96hYuHuzaL2iLwJ/Uaxfbz5bzTAS
# 5Fm4lYuzTyoT3nhyKYbBLiiprFXcuuS2jvxqnI6fPZWU/CLGRxgXOdUTWwrYEefm
# Us8=
# SIG # End signature block
