# Test-TriggerManager.ps1
# Comprehensive test script for Unity-Claude-TriggerManager module

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$SaveResults
)

# Test results structure
$script:TestResults = @{
    StartTime = Get-Date
    Tests = @()
    Summary = @{
        Total = 0
        Passed = 0
        Failed = 0
        Duration = 0
    }
}

function Write-TestLog {
    param([string]$Message, [string]$Level = 'Info')
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
    $logMessage = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        'Error' { Write-Host $logMessage -ForegroundColor Red }
        'Warning' { Write-Host $logMessage -ForegroundColor Yellow }
        'Success' { Write-Host $logMessage -ForegroundColor Green }
        'Debug' { Write-Verbose $logMessage }
        default { Write-Host $logMessage }
    }
}

function Test-Function {
    param(
        [string]$TestName,
        [scriptblock]$TestScript,
        [string]$Description = ''
    )
    
    Write-TestLog "Running test: $TestName" 'Info'
    
    $testResult = @{
        Name = $TestName
        Description = $Description
        Status = 'Failed'
        Error = $null
        Duration = 0
        Timestamp = Get-Date
    }
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        $result = & $TestScript
        if ($result -eq $true -or $result.Success -eq $true) {
            $testResult.Status = 'Passed'
            Write-TestLog "  [PASSED] $TestName" 'Success'
        } else {
            $testResult.Status = 'Failed'
            $testResult.Error = "Test returned false or unsuccessful result"
            Write-TestLog "  [FAILED] $TestName" 'Error'
        }
    }
    catch {
        $testResult.Status = 'Failed'
        $testResult.Error = $_.Exception.Message
        Write-TestLog "  [FAILED] $TestName - Error: $_" 'Error'
    }
    finally {
        $stopwatch.Stop()
        $testResult.Duration = $stopwatch.ElapsedMilliseconds
    }
    
    $script:TestResults.Tests += $testResult
    $script:TestResults.Summary.Total++
    
    if ($testResult.Status -eq 'Passed') {
        $script:TestResults.Summary.Passed++
    } else {
        $script:TestResults.Summary.Failed++
    }
    
    return $testResult
}

# Main test execution
Write-TestLog "=" * 60 'Info'
Write-TestLog "Unity-Claude-TriggerManager Test Suite" 'Info'
Write-TestLog "=" * 60 'Info'
Write-TestLog "Starting at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" 'Info'
Write-TestLog "" 'Info'

# Import the module
Write-TestLog "Importing Unity-Claude-TriggerManager module..." 'Info'
try {
    Import-Module "$PSScriptRoot\Modules\Unity-Claude-FileMonitor\Unity-Claude-TriggerManager.psd1" -Force
    Write-TestLog "Module imported successfully" 'Success'
}
catch {
    Write-TestLog "Failed to import module: $_" 'Error'
    exit 1
}

try {
    # Test 1: Module Loading and Initialization
    Test-Function -TestName "Module Loading" -Description "Verify module loads and initializes correctly" -TestScript {
        $module = Get-Module -Name 'Unity-Claude-TriggerManager'
        $status = Get-TriggerStatus
        return ($null -ne $module -and $status.Count -gt 0)
    }
    
    # Test 2: File Exclusion Testing
    Test-Function -TestName "File Exclusion" -Description "Test exclusion pattern matching" -TestScript {
        $testCases = @(
            @{ Path = 'test.tmp'; ShouldExclude = $true },
            @{ Path = 'node_modules\package.json'; ShouldExclude = $true },
            @{ Path = '.git\config'; ShouldExclude = $true },
            @{ Path = 'src\main.cs'; ShouldExclude = $false },
            @{ Path = 'docs\readme.md'; ShouldExclude = $false }
        )
        
        $allCorrect = $true
        foreach ($testCase in $testCases) {
            $excluded = Test-FileExclusion -FilePath $testCase.Path
            if ($excluded -ne $testCase.ShouldExclude) {
                Write-TestLog "    Exclusion mismatch for $($testCase.Path): Expected $($testCase.ShouldExclude), got $excluded" 'Warning'
                $allCorrect = $false
            }
        }
        return $allCorrect
    }
    
    # Test 3: Trigger Condition Matching
    Test-Function -TestName "Trigger Matching" -Description "Test trigger condition matching for different file types" -TestScript {
        # Mock file changes
        $testChanges = @(
            @{ FullPath = 'src\main.cs'; Priority = 2; FileType = 'Code' },
            @{ FullPath = 'config.json'; Priority = 3; FileType = 'Config' },
            @{ FullPath = 'project.csproj'; Priority = 1; FileType = 'Build' },
            @{ FullPath = 'readme.md'; Priority = 4; FileType = 'Documentation' },
            @{ FullPath = 'test\unit.test.cs'; Priority = 5; FileType = 'Test' }
        )
        
        $allMatched = $true
        foreach ($change in $testChanges) {
            # Use internal function to find triggers (we'd need to expose this for testing)
            $triggers = Get-TriggerStatus
            $hasMatch = $false
            
            # Simple matching logic for test
            foreach ($triggerName in $triggers.Keys) {
                $trigger = $triggers[$triggerName]
                foreach ($pattern in $trigger.Patterns) {
                    $fileName = [System.IO.Path]::GetFileName($change.FullPath)
                    if ($fileName -like $pattern -and $change.Priority -le $trigger.MinPriority) {
                        $hasMatch = $true
                        break
                    }
                }
                if ($hasMatch) { break }
            }
            
            if (-not $hasMatch) {
                Write-TestLog "    No trigger match found for $($change.FullPath)" 'Warning'
                $allMatched = $false
            }
        }
        return $allMatched
    }
    
    # Test 4: Priority Processing Queue
    Test-Function -TestName "Priority Processing" -Description "Test priority-based processing queue" -TestScript {
        $queueStatus = Get-ProcessingQueueStatus
        return ($null -ne $queueStatus -and $queueStatus.ContainsKey('QueueCount'))
    }
    
    # Test 5: Handler Registration
    Test-Function -TestName "Handler Registration" -Description "Test trigger handler registration and unregistration" -TestScript {
        # Register a test handler
        $testHandler = { param($TriggerEvent) Write-Verbose "Test handler called" }
        Register-TriggerHandler -Name 'TestHandler' -Handler $testHandler
        
        $status = Get-ProcessingQueueStatus
        $registered = 'TestHandler' -in $status.RegisteredHandlers
        
        # Unregister the handler
        Unregister-TriggerHandler -Name 'TestHandler'
        
        $statusAfter = Get-ProcessingQueueStatus
        $unregistered = 'TestHandler' -notin $statusAfter.RegisteredHandlers
        
        return ($registered -and $unregistered)
    }
    
    # Test 6: Exclusion Pattern Management
    Test-Function -TestName "Exclusion Management" -Description "Test adding and removing exclusion patterns" -TestScript {
        $initialPatterns = Get-ExclusionPatterns
        $initialCount = $initialPatterns.Count
        
        # Add a new pattern
        Add-ExclusionPattern -Pattern '*.test-temp'
        $afterAdd = Get-ExclusionPatterns
        $addedCorrectly = $afterAdd.Count -eq ($initialCount + 1) -and '*.test-temp' -in $afterAdd
        
        # Remove the pattern
        Remove-ExclusionPattern -Pattern '*.test-temp'
        $afterRemove = Get-ExclusionPatterns
        $removedCorrectly = $afterRemove.Count -eq $initialCount -and '*.test-temp' -notin $afterRemove
        
        return ($addedCorrectly -and $removedCorrectly)
    }
    
    # Test 7: File Change Processing (Simulation)
    Test-Function -TestName "File Change Processing" -Description "Test processing file changes through trigger system" -TestScript {
        # Mock a file change that shouldn't be excluded
        $mockChange = @{
            FullPath = 'src\TestFile.cs'
            ChangeType = 'Changed'
            Priority = 2
            FileType = 'Code'
            Timestamp = Get-Date
        }
        
        try {
            # This should not throw an exception
            Process-FileChange -FileChange $mockChange
            return $true
        }
        catch {
            Write-TestLog "    Error processing file change: $_" 'Error'
            return $false
        }
    }
    
    # Test 8: Trigger Status Retrieval
    Test-Function -TestName "Trigger Status" -Description "Test retrieving trigger status information" -TestScript {
        $allStatus = Get-TriggerStatus
        $specificStatus = Get-TriggerStatus -TriggerName 'CodeChange'
        
        $hasAllStatus = $null -ne $allStatus -and $allStatus.Count -gt 0
        $hasSpecificStatus = $null -ne $specificStatus -and $specificStatus.ContainsKey('Actions')
        
        return ($hasAllStatus -and $hasSpecificStatus)
    }
    
    # Test 9: Queue Management
    Test-Function -TestName "Queue Management" -Description "Test clearing trigger queue and pending changes" -TestScript {
        # Clear the queue
        $cleared = Clear-TriggerQueue
        
        # Check queue status
        $status = Get-ProcessingQueueStatus
        $queueEmpty = $status.QueueCount -eq 0
        
        return $queueEmpty
    }
    
    # Test 10: Default Triggers Validation
    Test-Function -TestName "Default Triggers" -Description "Validate default trigger configurations" -TestScript {
        $triggers = Get-TriggerStatus
        $expectedTriggers = @('CodeChange', 'ConfigChange', 'BuildFileChange', 'DocumentationChange', 'TestChange')
        
        $allPresent = $true
        foreach ($expectedTrigger in $expectedTriggers) {
            if (-not $triggers.ContainsKey($expectedTrigger)) {
                Write-TestLog "    Missing expected trigger: $expectedTrigger" 'Warning'
                $allPresent = $false
            } else {
                $trigger = $triggers[$expectedTrigger]
                $hasRequiredFields = $trigger.ContainsKey('Patterns') -and 
                                   $trigger.ContainsKey('MinPriority') -and 
                                   $trigger.ContainsKey('Actions') -and 
                                   $trigger.ContainsKey('Cooldown')
                
                if (-not $hasRequiredFields) {
                    Write-TestLog "    Trigger $expectedTrigger missing required fields" 'Warning'
                    $allPresent = $false
                }
            }
        }
        return $allPresent
    }
}
finally {
    # Calculate summary
    $script:TestResults.Summary.Duration = ((Get-Date) - $script:TestResults.StartTime).TotalSeconds
    
    # Display summary
    Write-TestLog "" 'Info'
    Write-TestLog "=" * 60 'Info'
    Write-TestLog "Test Summary" 'Info'
    Write-TestLog "=" * 60 'Info'
    Write-TestLog "Total Tests: $($script:TestResults.Summary.Total)" 'Info'
    Write-TestLog "Passed: $($script:TestResults.Summary.Passed)" 'Success'
    Write-TestLog "Failed: $($script:TestResults.Summary.Failed)" $(if ($script:TestResults.Summary.Failed -gt 0) { 'Error' } else { 'Info' })
    Write-TestLog "Duration: $([Math]::Round($script:TestResults.Summary.Duration, 2)) seconds" 'Info'
    Write-TestLog "" 'Info'
    
    # Display failed tests
    if ($script:TestResults.Summary.Failed -gt 0) {
        Write-TestLog "Failed Tests:" 'Error'
        $script:TestResults.Tests | Where-Object { $_.Status -eq 'Failed' } | ForEach-Object {
            Write-TestLog "  - $($_.Name): $($_.Error)" 'Error'
        }
        Write-TestLog "" 'Info'
    }
    
    # Save results if requested
    if ($SaveResults) {
        $resultsFile = Join-Path $PSScriptRoot "TriggerManager-TestResults-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
        $script:TestResults | ConvertTo-Json -Depth 10 | Out-File $resultsFile
        Write-TestLog "Test results saved to: $resultsFile" 'Info'
    }
    
    # Remove module
    Remove-Module -Name 'Unity-Claude-TriggerManager' -Force -ErrorAction SilentlyContinue
    
    # Exit with appropriate code
    if ($script:TestResults.Summary.Failed -gt 0) {
        exit 1
    } else {
        Write-TestLog "All tests passed successfully!" 'Success'
        exit 0
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBOX5jLtTux6oYx
# BNZhVn8HPNsA+He07Rb/GAXYeqkew6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIITE1MBDWhsfL4hNhNhuAhyi
# yS5W5tooec98ru8gQ95wMA0GCSqGSIb3DQEBAQUABIIBACJnPXg+uS+V4WmD5kHW
# +bDAtq4FUhmqwI55ElWEw7FjQwXhESRoH16K6eq1fPA5Fohd2NC99lNp46iJK3IK
# fUU/kS+8hbb3aMvG5WG9XMhujISU1FtW+eXsePr7VZ+qViIiEvo0qERyoTFQ/xeq
# 4pNEuZZPUg/KFYLtvgU7CJ1Apj7rPCmheppbJB8qg+d9nWwaXusG+5Rhv/aX22rZ
# gZelGAqEipWFU9t0RDypF0P51ZS5zNyL4a/ZFCK5bFKzYwpcJSF48lADTT7dQe/q
# SdDgE8x/8ccFwLw9H32wWUyIY051MHpDokXjcNHs9keRg9dxPaQkx6Tj25HrdpwH
# 1Mw=
# SIG # End signature block
