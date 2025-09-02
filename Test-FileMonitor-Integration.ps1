# Test-FileMonitor-Integration.ps1
# Integration test combining FileSystemWatcher and TriggerManager

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$SaveResults
)

Write-Host "Integration Test: FileMonitor + TriggerManager" -ForegroundColor Yellow
Write-Host "=" * 60

# Import both modules
Write-Host "Importing modules..." -ForegroundColor Cyan
Import-Module "$PSScriptRoot\Modules\Unity-Claude-FileMonitor\Unity-Claude-FileMonitor.psd1" -Force
Import-Module "$PSScriptRoot\Modules\Unity-Claude-FileMonitor\Unity-Claude-TriggerManager.psd1" -Force

$testResults = @()
$testDir = Join-Path $env:TEMP "FileMonitorIntegrationTest_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -Path $testDir -ItemType Directory -Force | Out-Null

try {
    # Test 1: Module Integration
    Write-Host "`nTest 1: Module Integration..." -ForegroundColor Cyan
    $fileMonitorModule = Get-Module -Name 'Unity-Claude-FileMonitor'
    $triggerModule = Get-Module -Name 'Unity-Claude-TriggerManager'
    $test1 = ($null -ne $fileMonitorModule -and $null -ne $triggerModule)
    $testResults += @{ Name = "Module Integration"; Passed = $test1 }
    Write-Host "  Result: $($test1 ? 'PASS' : 'FAIL')" -ForegroundColor ($test1 ? 'Green' : 'Red')
    
    # Test 2: Trigger System Setup
    Write-Host "`nTest 2: Trigger System Setup..." -ForegroundColor Cyan
    $triggers = Get-TriggerStatus
    $exclusions = Get-ExclusionPatterns
    $test2 = ($triggers.Count -gt 0 -and $exclusions.Count -gt 0)
    $testResults += @{ Name = "Trigger System Setup"; Passed = $test2 }
    Write-Host "  Triggers: $($triggers.Count)" -ForegroundColor Gray
    Write-Host "  Exclusions: $($exclusions.Count)" -ForegroundColor Gray
    Write-Host "  Result: $($test2 ? 'PASS' : 'FAIL')" -ForegroundColor ($test2 ? 'Green' : 'Red')
    
    # Test 3: FileMonitor Creation with Trigger Integration
    Write-Host "`nTest 3: FileMonitor with Trigger Integration..." -ForegroundColor Cyan
    
    # Register a handler to capture trigger events
    $script:capturedTriggerEvents = @()
    Register-TriggerHandler -Name 'IntegrationTestHandler' -Handler {
        param($TriggerEvent)
        $script:capturedTriggerEvents += $TriggerEvent
        Write-Host "    Trigger fired: $($TriggerEvent.TriggerName) with $($TriggerEvent.Changes.Count) changes" -ForegroundColor Green
    }
    
    # Create monitor and integrate with trigger system
    $monitorId = New-FileMonitor -Path $testDir -Filter '*.*' -DebounceMs 200
    
    # Register file change handler that feeds into trigger system
    Register-FileChangeHandler -Handler {
        param($AggregatedChanges)
        foreach ($change in $AggregatedChanges) {
            Write-Host "      FileMonitor detected: $($change.Path) ($($change.ChangeType))" -ForegroundColor Yellow
            
            # Convert to format expected by trigger system
            $triggerChange = @{
                FullPath = $change.Path
                ChangeType = $change.ChangeType
                Priority = $change.Priority
                FileType = $change.FileType
                Timestamp = Get-Date
            }
            
            Process-FileChange -FileChange $triggerChange
        }
    }
    
    Start-FileMonitor -Identifier $monitorId
    $test3 = (Get-FileMonitorStatus -Identifier $monitorId).IsActive
    $testResults += @{ Name = "FileMonitor with Triggers"; Passed = $test3 }
    Write-Host "  Result: $($test3 ? 'PASS' : 'FAIL')" -ForegroundColor ($test3 ? 'Green' : 'Red')
    
    # Test 4: File Change Trigger Integration
    Write-Host "`nTest 4: File Change Trigger Integration..." -ForegroundColor Cyan
    
    # Create different types of files to test various triggers
    $testFiles = @(
        @{ Name = "TestCode.cs"; Content = "// C# code file"; ExpectedTrigger = "CodeChange" },
        @{ Name = "config.json"; Content = '{"test": true}'; ExpectedTrigger = "ConfigChange" },
        @{ Name = "README.md"; Content = "# Documentation"; ExpectedTrigger = "DocumentationChange" },
        @{ Name = "project.csproj"; Content = "<Project></Project>"; ExpectedTrigger = "BuildFileChange" },
        @{ Name = "UnitTest.test.cs"; Content = "// Test file"; ExpectedTrigger = "TestChange" }
    )
    
    foreach ($testFile in $testFiles) {
        $filePath = Join-Path $testDir $testFile.Name
        $testFile.Content | Out-File -FilePath $filePath
        Write-Host "    Created: $($testFile.Name) (expecting $($testFile.ExpectedTrigger))" -ForegroundColor Gray
    }
    
    # Wait for file changes to be processed
    Start-Sleep -Seconds 1
    
    # Check if triggers were fired
    $test4 = $script:capturedTriggerEvents.Count -gt 0
    $testResults += @{ Name = "File Change Integration"; Passed = $test4 }
    Write-Host "  Captured trigger events: $($script:capturedTriggerEvents.Count)" -ForegroundColor Gray
    
    foreach ($event in $script:capturedTriggerEvents) {
        Write-Host "    - $($event.TriggerName): $($event.Changes.Count) changes, Priority: $($event.Priority)" -ForegroundColor Gray
    }
    
    Write-Host "  Result: $($test4 ? 'PASS' : 'FAIL')" -ForegroundColor ($test4 ? 'Green' : 'Red')
    
    # Test 5: Exclusion Pattern Integration
    Write-Host "`nTest 5: Exclusion Pattern Integration..." -ForegroundColor Cyan
    
    # Create files that should be excluded
    $excludedFiles = @("temp.tmp", "cache.cache", "test.log")
    $initialTriggerCount = $script:capturedTriggerEvents.Count
    
    foreach ($excludedFile in $excludedFiles) {
        $filePath = Join-Path $testDir $excludedFile
        "excluded content" | Out-File -FilePath $filePath
        Write-Host "    Created excluded file: $excludedFile" -ForegroundColor Gray
    }
    
    # Wait for processing
    Start-Sleep -Seconds 1
    
    # Check that no new triggers were fired for excluded files
    $finalTriggerCount = $script:capturedTriggerEvents.Count
    $test5 = $finalTriggerCount -eq $initialTriggerCount
    $testResults += @{ Name = "Exclusion Pattern Integration"; Passed = $test5 }
    Write-Host "  Trigger count before: $initialTriggerCount, after: $finalTriggerCount" -ForegroundColor Gray
    Write-Host "  Result: $($test5 ? 'PASS' : 'FAIL')" -ForegroundColor ($test5 ? 'Green' : 'Red')
    
    # Test 6: Priority-Based Processing
    Write-Host "`nTest 6: Priority-Based Processing..." -ForegroundColor Cyan
    
    # Check if events were processed in priority order
    $sortedEvents = $script:capturedTriggerEvents | Sort-Object -Property Priority
    $test6 = $true
    
    for ($i = 0; $i -lt $script:capturedTriggerEvents.Count - 1; $i++) {
        if ($script:capturedTriggerEvents[$i].Priority -gt $script:capturedTriggerEvents[$i + 1].Priority) {
            $test6 = $false
            break
        }
    }
    
    $testResults += @{ Name = "Priority-Based Processing"; Passed = $test6 }
    Write-Host "  Events processed in priority order: $test6" -ForegroundColor Gray
    Write-Host "  Result: $($test6 ? 'PASS' : 'FAIL')" -ForegroundColor ($test6 ? 'Green' : 'Red')
    
    # Test 7: Resource Cleanup
    Write-Host "`nTest 7: Resource Cleanup..." -ForegroundColor Cyan
    
    # Stop monitoring
    Stop-FileMonitor -Identifier $monitorId
    
    # Unregister handlers
    Unregister-TriggerHandler -Name 'IntegrationTestHandler'
    
    # Check cleanup
    $finalStatus = Get-FileMonitorStatus -Identifier $monitorId
    $queueStatus = Get-ProcessingQueueStatus
    $test7 = ($null -eq $finalStatus -and 'IntegrationTestHandler' -notin $queueStatus.RegisteredHandlers)
    $testResults += @{ Name = "Resource Cleanup"; Passed = $test7 }
    Write-Host "  Result: $($test7 ? 'PASS' : 'FAIL')" -ForegroundColor ($test7 ? 'Green' : 'Red')
    
}
finally {
    # Cleanup
    Write-Host "`nCleaning up..." -ForegroundColor Cyan
    
    # Remove test directory
    if (Test-Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # Summary
    Write-Host "`n" + "=" * 60
    $passed = ($testResults | Where-Object { $_.Passed }).Count
    $total = $testResults.Count
    Write-Host "Integration Test Summary: $passed/$total tests passed" -ForegroundColor ($passed -eq $total ? 'Green' : 'Yellow')
    
    if ($SaveResults) {
        $resultsFile = Join-Path $PSScriptRoot "FileMonitor-Integration-TestResults-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
        
        $fullResults = @{
            TestResults = $testResults
            TriggerEvents = $script:capturedTriggerEvents
            Summary = @{
                Total = $total
                Passed = $passed
                Failed = $total - $passed
                Timestamp = Get-Date
            }
        }
        
        $fullResults | ConvertTo-Json -Depth 5 | Out-File $resultsFile
        Write-Host "Results saved to: $resultsFile" -ForegroundColor Cyan
    }
    
    # Show detailed results
    Write-Host "`nDetailed Results:" -ForegroundColor Cyan
    foreach ($result in $testResults) {
        $status = if ($result.Passed) { "PASS" } else { "FAIL" }
        $color = if ($result.Passed) { "Green" } else { "Red" }
        Write-Host "  $($result.Name): $status" -ForegroundColor $color
    }
    
    # Remove modules
    Remove-Module -Name 'Unity-Claude-FileMonitor' -Force -ErrorAction SilentlyContinue
    Remove-Module -Name 'Unity-Claude-TriggerManager' -Force -ErrorAction SilentlyContinue
}

exit ($passed -eq $total ? 0 : 1)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBqs1hXavmb9hdD
# o1MRfNADIh5eqiqQWPHrG1l0sp+0ZqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIP6ATGH2OxBR7WlShaFrDY1q
# nb6CX9HhKjUCRMFlATs8MA0GCSqGSIb3DQEBAQUABIIBADlmgpaCPTUP+hNL0w31
# Sz9v3SU+RSKsWw7MD/Aaf3Hw3W3GsDTj9b4TVmc67o2+8trXnxJNBFK4IeQiledX
# gf5cEzZwoSFEFzgegBdAc4ZEwjWv/FxlfKTFafqmX3jEIm+cjDylmqMQUv2s8CzA
# 37JYUpa0P0V8BK7EBKevDmj9UnUwQRqjc2TklRsNLjdfk6sglYprQzg5Pe/xyi7b
# qmW+ELhzsq9SP7o7fhDUZ5UWvgXRkKJXTqb6mu5sy0+xPfQ8G8Vt7HC2txyEK8+8
# t+rfXBU2gEAUqOm70UUZtV7EdEy8xE++Zef0Ie8gu7qjz9kw8yoBvmor0elZ0KGW
# wT0=
# SIG # End signature block
