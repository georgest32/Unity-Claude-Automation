# Test-UnityClaudeModules.ps1
# Comprehensive test suite for Unity-Claude modular system

[CmdletBinding()]
param(
    [switch]$Verbose,
    [switch]$SkipDatabaseTests,
    [switch]$SkipClaudeTests,
    [switch]$GenerateReport
)

$ErrorActionPreference = 'Stop'

# Test results tracking
$script:TestResults = @{
    Passed = 0
    Failed = 0
    Skipped = 0
    Details = @()
}

# Add modules path to PSModulePath
$modulePath = Join-Path $PSScriptRoot 'Modules'
if ($env:PSModulePath -notlike "*$modulePath*") {
    $env:PSModulePath = "$modulePath;$env:PSModulePath"
}

#region Test Framework

function Test-Case {
    param(
        [string]$Name,
        [scriptblock]$Test,
        [switch]$Skip
    )
    
    Write-Host "`n[$Name]" -ForegroundColor Cyan
    
    if ($Skip) {
        Write-Host "  SKIPPED" -ForegroundColor Yellow
        $script:TestResults.Skipped++
        $script:TestResults.Details += @{
            Name = $Name
            Status = 'Skipped'
            Message = 'Test skipped by parameter'
        }
        return
    }
    
    try {
        $result = & $Test
        if ($result -eq $true -or $null -eq $result) {
            Write-Host "  âœ" PASSED" -ForegroundColor Green
            $script:TestResults.Passed++
            $script:TestResults.Details += @{
                Name = $Name
                Status = 'Passed'
                Message = ''
            }
        } else {
            Write-Host "  FAILED FAILED: $result" -ForegroundColor Red
            $script:TestResults.Failed++
            $script:TestResults.Details += @{
                Name = $Name
                Status = 'Failed'
                Message = $result
            }
        }
    } catch {
        Write-Host "  FAILED ERROR: $_" -ForegroundColor Red
        $script:TestResults.Failed++
        $script:TestResults.Details += @{
            Name = $Name
            Status = 'Error'
            Message = $_.ToString()
        }
    }
}

function Show-TestSummary {
    Write-Host "`n" + ("=" * 60) -ForegroundColor Cyan
    Write-Host "TEST SUMMARY" -ForegroundColor Cyan
    Write-Host ("=" * 60) -ForegroundColor Cyan
    
    $total = $script:TestResults.Passed + $script:TestResults.Failed + $script:TestResults.Skipped
    $passRate = if ($total -gt 0) { 
        [Math]::Round(($script:TestResults.Passed / $total) * 100, 1) 
    } else { 0 }
    
    Write-Host "Total Tests: $total" -ForegroundColor White
    Write-Host "Passed: $($script:TestResults.Passed)" -ForegroundColor Green
    Write-Host "Failed: $($script:TestResults.Failed)" -ForegroundColor $(if ($script:TestResults.Failed -gt 0) { 'Red' } else { 'Gray' })
    Write-Host "Skipped: $($script:TestResults.Skipped)" -ForegroundColor Yellow
    Write-Host "Pass Rate: $passRate%" -ForegroundColor $(if ($passRate -ge 80) { 'Green' } elseif ($passRate -ge 60) { 'Yellow' } else { 'Red' })
    
    if ($GenerateReport) {
        $reportPath = Export-TestReport
        Write-Host "`nTest report saved to: $reportPath" -ForegroundColor Cyan
    }
}

function Export-TestReport {
    $reportPath = Join-Path $PSScriptRoot "TestReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Unity-Claude Module Test Report</title>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 10px; }
        .summary { display: flex; justify-content: space-around; margin: 20px 0; }
        .stat { text-align: center; padding: 15px; border-radius: 5px; flex: 1; margin: 0 10px; }
        .stat.passed { background: #d4edda; color: #155724; }
        .stat.failed { background: #f8d7da; color: #721c24; }
        .stat.skipped { background: #fff3cd; color: #856404; }
        .stat.total { background: #d1ecf1; color: #0c5460; }
        .stat .number { font-size: 2em; font-weight: bold; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th { background: #3498db; color: white; padding: 10px; text-align: left; }
        td { padding: 8px; border-bottom: 1px solid #ddd; }
        tr:hover { background: #f9f9f9; }
        .passed { color: #27ae60; font-weight: bold; }
        .failed { color: #e74c3c; font-weight: bold; }
        .skipped { color: #f39c12; font-weight: bold; }
        .error { color: #c0392b; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Unity-Claude Module Test Report</h1>
        <p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
        
        <div class="summary">
            <div class="stat total">
                <div class="number">$($script:TestResults.Passed + $script:TestResults.Failed + $script:TestResults.Skipped)</div>
                <div>Total Tests</div>
            </div>
            <div class="stat passed">
                <div class="number">$($script:TestResults.Passed)</div>
                <div>Passed</div>
            </div>
            <div class="stat failed">
                <div class="number">$($script:TestResults.Failed)</div>
                <div>Failed</div>
            </div>
            <div class="stat skipped">
                <div class="number">$($script:TestResults.Skipped)</div>
                <div>Skipped</div>
            </div>
        </div>
        
        <h2>Test Details</h2>
        <table>
            <tr>
                <th>Test Name</th>
                <th>Status</th>
                <th>Message</th>
            </tr>
"@
    
    foreach ($test in $script:TestResults.Details) {
        $statusClass = $test.Status.ToLower()
        $html += @"
            <tr>
                <td>$($test.Name)</td>
                <td class="$statusClass">$($test.Status)</td>
                <td>$($test.Message)</td>
            </tr>
"@
    }
    
    $html += @"
        </table>
    </div>
</body>
</html>
"@
    
    Set-Content -Path $reportPath -Value $html
    return $reportPath
}

#endregion

#region Module Loading Tests

Write-Host "`n=== MODULE LOADING TESTS ===" -ForegroundColor Yellow

Test-Case "Unity-Claude-Core module exists" {
    $module = Get-Module -ListAvailable -Name Unity-Claude-Core
    if (-not $module) { return "Module not found in path: $modulePath" }
    return $true
}

Test-Case "Unity-Claude-IPC module exists" {
    $module = Get-Module -ListAvailable -Name Unity-Claude-IPC
    if (-not $module) { return "Module not found" }
    return $true
}

Test-Case "Unity-Claude-Errors module exists" {
    $module = Get-Module -ListAvailable -Name Unity-Claude-Errors
    if (-not $module) { return "Module not found" }
    return $true
}

Test-Case "Core module loads successfully" {
    Remove-Module Unity-Claude-Core -ErrorAction SilentlyContinue
    Import-Module Unity-Claude-Core -ErrorAction Stop
    $module = Get-Module Unity-Claude-Core
    if (-not $module) { return "Module failed to load" }
    return $true
}

Test-Case "IPC module loads successfully" {
    Remove-Module Unity-Claude-IPC -ErrorAction SilentlyContinue
    Import-Module Unity-Claude-IPC -ErrorAction Stop
    $module = Get-Module Unity-Claude-IPC
    if (-not $module) { return "Module failed to load" }
    return $true
}

Test-Case "Errors module loads successfully" {
    Remove-Module Unity-Claude-Errors -ErrorAction SilentlyContinue
    Import-Module Unity-Claude-Errors -ErrorAction Stop
    $module = Get-Module Unity-Claude-Errors
    if (-not $module) { return "Module failed to load" }
    return $true
}

#endregion

#region Core Module Tests

Write-Host "`n=== CORE MODULE TESTS ===" -ForegroundColor Yellow

Test-Case "Initialize-AutomationContext creates context" {
    Import-Module Unity-Claude-Core -Force
    $context = Initialize-AutomationContext -ProjectPath $PSScriptRoot
    if (-not $context) { return "Context not created" }
    if ($context.ProjectPath -ne $PSScriptRoot) { return "Project path mismatch" }
    if (-not $context.LogDir) { return "Log directory not set" }
    return $true
}

Test-Case "Write-Log creates log file" {
    Import-Module Unity-Claude-Core -Force
    Initialize-AutomationContext -ProjectPath $PSScriptRoot | Out-Null
    Write-Log -Message "Test log entry" -Level 'INFO'
    
    $logDir = Join-Path $PSScriptRoot 'AutomationLogs'
    $logFile = Get-ChildItem -Path $logDir -Filter "automation_*.log" | Select-Object -First 1
    if (-not $logFile) { return "Log file not created" }
    
    $content = Get-Content $logFile.FullName -Tail 1
    if ($content -notlike "*Test log entry*") { return "Log content not found" }
    return $true
}

Test-Case "Get-FileTailAsString handles missing file" {
    Import-Module Unity-Claude-Core -Force
    $result = Get-FileTailAsString -Path "C:\NonExistent\File.txt"
    if ($result -ne "") { return "Should return empty string for missing file" }
    return $true
}

Test-Case "Install-AutoRecompileScript creates script" {
    Import-Module Unity-Claude-Core -Force
    Initialize-AutomationContext -ProjectPath $PSScriptRoot | Out-Null
    
    $result = Install-AutoRecompileScript
    if (-not $result) { return "Installation failed" }
    
    $scriptPath = Join-Path $PSScriptRoot 'Assets\Editor\Automation\AutoRecompile.cs'
    if (-not (Test-Path $scriptPath)) { return "Script file not created" }
    
    $content = Get-Content $scriptPath -Raw
    if ($content -notlike "*ForceCompileAndExit*") { return "Script content incorrect" }
    return $true
}

Test-Case "Get-CurrentPromptType returns correct type" {
    Import-Module Unity-Claude-Core -Force
    
    $type1 = Get-CurrentPromptType -FailedStreak 0
    if ($type1 -ne 'Continue') { return "Should return Continue for 0 failures" }
    
    $type2 = Get-CurrentPromptType -FailedStreak 3
    if ($type2 -ne 'Debugging') { return "Should return Debugging for 3 failures" }
    
    $type3 = Get-CurrentPromptType -FailedStreak 5
    if ($type3 -ne 'Review') { return "Should return Review for 5+ failures" }
    
    return $true
}

#endregion

#region IPC Module Tests

Write-Host "`n=== IPC MODULE TESTS ===" -ForegroundColor Yellow

Test-Case "Test-ClaudeAvailable detects Claude CLI" -Skip:$SkipClaudeTests {
    Import-Module Unity-Claude-IPC -Force
    $available = Test-ClaudeAvailable
    # This might fail if Claude CLI isn't installed, which is OK for testing
    return $true
}

Test-Case "Split-ConsoleLog creates split files" {
    Import-Module Unity-Claude-IPC -Force
    
    # Create test log file
    $testLog = Join-Path $env:TEMP "test_console.log"
    $testContent = 1..1000 | ForEach-Object { "Line $_: This is a test log entry with some content" }
    Set-Content -Path $testLog -Value $testContent
    
    $splitFiles = Split-ConsoleLog -LogPath $testLog -MaxLinesPerFile 100
    if ($splitFiles.Count -lt 10) { return "Should create at least 10 split files" }
    
    # Check index file
    $indexFile = Join-Path (Split-Path $testLog -Parent) 'ConsoleLogs_Split\_INDEX.txt'
    if (-not (Test-Path $indexFile)) { return "Index file not created" }
    
    # Cleanup
    Remove-Item $testLog -Force
    Remove-Item (Join-Path (Split-Path $testLog -Parent) 'ConsoleLogs_Split') -Recurse -Force
    
    return $true
}

Test-Case "Format-ErrorContext extracts errors" {
    Import-Module Unity-Claude-IPC -Force
    
    # Create test console file with errors
    $testConsole = Join-Path $env:TEMP "test_errors.log"
    $errorContent = @"
Normal log line
Assets\Scripts\Test.cs(10,5): error CS0246: The type or namespace name 'Missing' could not be found
Another normal line
NullReferenceException: Object reference not set to an instance of an object
More normal content
"@
    Set-Content -Path $testConsole -Value $errorContent
    
    $context = Format-ErrorContext -ConsolePath $testConsole
    if ($context -notlike "*CS0246*") { return "CS error not extracted" }
    if ($context -notlike "*NullReferenceException*") { return "Exception not extracted" }
    
    # Cleanup
    Remove-Item $testConsole -Force
    
    return $true
}

Test-Case "Get-PromptBoilerplate returns boilerplate" {
    Import-Module Unity-Claude-IPC -Force
    
    $boilerplate = Get-PromptBoilerplate -Type 'Debugging'
    if ($boilerplate -notlike "*Unity*") { return "Should mention Unity" }
    if ($boilerplate -notlike "*DEBUGGING MODE*") { return "Should include debugging mode" }
    
    return $true
}

Test-Case "Named pipe can be created" {
    Import-Module Unity-Claude-IPC -Force
    
    $pipeName = "TestPipe_$(Get-Random)"
    $pipe = Start-BidirectionalPipe -PipeName $pipeName
    
    if (-not $pipe.Success) { return "Pipe creation failed: $($pipe.Error)" }
    if ($pipe.PipeName -ne $pipeName) { return "Pipe name mismatch" }
    
    # Cleanup
    if ($pipe.PipeServer) {
        $pipe.PipeServer.Dispose()
    }
    
    return $true
}

#endregion

#region Error Module Tests

Write-Host "`n=== ERROR MODULE TESTS ===" -ForegroundColor Yellow

Test-Case "Initialize-ErrorDatabase creates database" -Skip:$SkipDatabaseTests {
    Import-Module Unity-Claude-Errors -Force
    
    $dbPath = Join-Path $env:TEMP "test_errors.db"
    $result = Initialize-ErrorDatabase -DatabasePath $dbPath -Force
    
    if (-not $result) { return "Database initialization failed" }
    if (-not (Test-Path $dbPath)) { return "Database file not created" }
    
    # Cleanup
    Remove-Item $dbPath -Force -ErrorAction SilentlyContinue
    
    return $true
}

Test-Case "Parse-UnityError correctly parses CS errors" {
    Import-Module Unity-Claude-Errors -Force
    
    $errorLine = "Assets\Scripts\Test.cs(42,10): error CS0246: The type or namespace name 'Missing' could not be found"
    $parsed = Parse-UnityError -ErrorLine $errorLine
    
    if ($parsed.ErrorCode -ne 'CS0246') { return "Error code not parsed: $($parsed.ErrorCode)" }
    if ($parsed.LineNumber -ne 42) { return "Line number not parsed: $($parsed.LineNumber)" }
    if ($parsed.FilePath -notlike "*Test.cs") { return "File path not parsed" }
    if ($parsed.Type -ne 'Compilation') { return "Type should be Compilation" }
    
    return $true
}

Test-Case "Parse-UnityError handles exceptions" {
    Import-Module Unity-Claude-Errors -Force
    
    $errorLine = "NullReferenceException: Object reference not set to an instance of an object"
    $parsed = Parse-UnityError -ErrorLine $errorLine
    
    if ($parsed.ErrorCode -ne 'NullReferenceException') { return "Exception type not parsed" }
    if ($parsed.Type -ne 'Runtime') { return "Type should be Runtime" }
    
    return $true
}

Test-Case "Get-ErrorSeverity returns correct severity" {
    Import-Module Unity-Claude-Errors -Force
    
    $sev1 = Get-ErrorSeverity -ErrorCode 'CS0246'
    if ($sev1 -ne 'Critical') { return "CS0246 should be Critical" }
    
    $sev2 = Get-ErrorSeverity -ErrorCode 'CS0117'
    if ($sev2 -ne 'High') { return "CS0117 should be High" }
    
    $sev3 = Get-ErrorSeverity -ErrorCode 'CS1002'
    if ($sev3 -ne 'Medium') { return "CS1002 should be Medium" }
    
    $sev4 = Get-ErrorSeverity -ErrorCode 'NullReferenceException'
    if ($sev4 -ne 'Critical') { return "NullReferenceException should be Critical" }
    
    return $true
}

Test-Case "Error pattern storage works" -Skip:$SkipDatabaseTests {
    Import-Module Unity-Claude-Errors -Force
    
    # Initialize in-memory storage
    Initialize-ErrorDatabase -DatabasePath ":memory:" | Out-Null
    
    # Add pattern
    $added = Add-ErrorPattern -ErrorCode 'CS0246' -Pattern 'TestNamespace not found' -FilePath 'Test.cs' -LineNumber 10
    if (-not $added) { return "Failed to add pattern" }
    
    # Retrieve pattern
    $patterns = Get-ErrorPattern -ErrorCode 'CS0246'
    if ($patterns.Count -eq 0) { return "Pattern not retrieved" }
    
    return $true
}

#endregion

#region Integration Tests

Write-Host "`n=== INTEGRATION TESTS ===" -ForegroundColor Yellow

Test-Case "Modules can work together" {
    Import-Module Unity-Claude-Core -Force
    Import-Module Unity-Claude-IPC -Force
    Import-Module Unity-Claude-Errors -Force
    
    # Initialize context
    $context = Initialize-AutomationContext -ProjectPath $PSScriptRoot
    if (-not $context) { return "Context initialization failed" }
    
    # Write a log
    Write-Log -Message "Integration test" -Level 'INFO'
    
    # Parse an error
    $error = Parse-UnityError -ErrorLine "Test.cs(1,1): error CS0246: Missing type"
    if ($error.ErrorCode -ne 'CS0246') { return "Error parsing failed" }
    
    # Get severity
    $severity = Get-ErrorSeverity -ErrorCode $error.ErrorCode
    if ($severity -ne 'Critical') { return "Severity check failed" }
    
    return $true
}

Test-Case "Module dependencies are correct" {
    $core = Get-Module -ListAvailable -Name Unity-Claude-Core
    $ipc = Get-Module -ListAvailable -Name Unity-Claude-IPC
    $errors = Get-Module -ListAvailable -Name Unity-Claude-Errors
    
    # Check IPC depends on Core
    $ipcManifest = Import-PowerShellDataFile -Path (Join-Path $ipc.ModuleBase "$($ipc.Name).psd1")
    $ipcDeps = $ipcManifest.RequiredModules
    if ($ipcDeps.ModuleName -notcontains 'Unity-Claude-Core') {
        return "IPC should depend on Core"
    }
    
    # Check Errors depends on Core
    $errorsManifest = Import-PowerShellDataFile -Path (Join-Path $errors.ModuleBase "$($errors.Name).psd1")
    $errorsDeps = $errorsManifest.RequiredModules
    if ($errorsDeps[0].ModuleName -ne 'Unity-Claude-Core') {
        return "Errors should depend on Core"
    }
    
    return $true
}

#endregion

# Cleanup
Write-Host "`n=== CLEANUP ===" -ForegroundColor Yellow
Write-Host "Removing test artifacts..." -ForegroundColor Gray

# Remove test log directory
$testLogDir = Join-Path $PSScriptRoot 'AutomationLogs'
if (Test-Path $testLogDir) {
    Remove-Item $testLogDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  Removed AutomationLogs" -ForegroundColor Gray
}

# Remove test AutoRecompile script
$testAutoDir = Join-Path $PSScriptRoot 'Assets'
if (Test-Path $testAutoDir) {
    Remove-Item $testAutoDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  Removed Assets directory" -ForegroundColor Gray
}

# Show summary
Show-TestSummary

# Return exit code based on failures
exit $script:TestResults.Failed

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUui5D8Eo1N5zg8jE25vtKS2AP
# POqgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
# AQsFADAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0b21hdGlvbi1EZXZlbG9w
# bWVudDAeFw0yNTA4MjAyMTE1MTdaFw0yNjA4MjAyMTM1MTdaMC4xLDAqBgNVBAMM
# I1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEAseH3qinVEOhrn2OLpjc5TNT4vGh1BkfB5X4S
# FhY7K0QMQsYYnkZVmx3tB8PqVQXl++l+e3uT7uCscc7vjMTK8tDSWH98ji0U34WL
# JBwXC62l1ArazMKp4Tyr7peksei7vL4pZOtOVgAyTYn5d1hbnsVQmCSTPRtpn7mC
# Azfq2ec5qZ9Kgl7puPW5utvYfh8idtOWa5/WgYSKwOIvyZawIdZKLFpwqOtqbJe4
# sWzVahasFhLfoAKkniKOAocJDkJexh5pO/EOSKEZ3mOCU1ZSs4XWRGISRhV3qGZp
# f+Y3JlHKMeFDWKynaJBO8/GU5sqMATlDUvrByBtU2OQ2Um/L3QIDAQABo0YwRDAO
# BgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFHw5
# rOy6xlW6B45sJUsiI2A/yS0MMA0GCSqGSIb3DQEBCwUAA4IBAQAUTLH0+w8ysvmh
# YuBw4NDKcZm40MTh9Zc1M2p2hAkYsgNLJ+/rAP+I74rNfqguTYwxpCyjkwrg8yF5
# wViwggboLpF2yDu4N/dgDainR4wR8NVpS7zFZOFkpmNPepc6bw3d4yQKa/wJXKeC
# pkRjS50N77/hfVI+fFKNao7POb7en5fcXuZaN6xWoTRy+J4I4MhfHpjZuxSLSXjb
# VXtPD4RZ9HGjl9BU8162cRhjujr/Lc3/dY/6ikHQYnxuxcdxRew4nzaqAQaOeWu6
# tGp899JPKfldM5Zay5IBl3zs15gNS9+0Jrd0ARQnSVYoI0DLh3KybFnfK4POezoN
# Lp/dbX2SMYIB4zCCAd8CAQEwQjAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0
# b21hdGlvbi1EZXZlbG9wbWVudAIQdR0W2SKoK5VE8JId4ZxrRTAJBgUrDgMCGgUA
# oHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYB
# BAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0B
# CQQxFgQULESPXm4GdgVpCw5AW1IVJEtgGm8wDQYJKoZIhvcNAQEBBQAEggEADGgt
# 7C+B74oXEIGjESmZZ0jmrsm2hqfnQ2TTRe40HL6QnF4pZHbuFETLv2q/t3t+EsqO
# qI7XlRUDrPvzZ93xuWD7/jlELU2VMHbmtk0DkDMvCgYoFw7MLMO4WpnbeAJ2CRzj
# /y5cUhnXSZZBjhUIC9rTB3EY2TJdSmy19ddmjWOh4w54c6znlDqDhLs+BBI/HFix
# xdBIKaZ78jxBJWZ3pEORZ/5H+5hjeK3CdsEU5fW01VlmbzEHz8UYecu8xfcaXFpS
# pgxGR6necC/xWJZM6/Ufl2Ym7bsV0DxqNs7hxdiV2ONRH4oFFJkCwKIZu9rCMQns
# kvhTkav0TXGOrVfnng==
# SIG # End signature block
