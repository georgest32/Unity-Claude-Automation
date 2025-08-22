# Test-GitHubIssueManagement.ps1
# Comprehensive test suite for GitHub Issue Management System
# Phase 4, Week 8, Days 3-4

param(
    [switch]$AllTests,
    [switch]$TestCreation,
    [switch]$TestSearch,
    [switch]$TestDuplication,
    [switch]$TestUpdate,
    [switch]$TestFormat,
    [switch]$TestIntegration,
    [switch]$SaveResults,
    [switch]$Verbose,
    [string]$TestRepository = "Unity-Claude-Test",
    [string]$TestOwner = $env:GITHUB_USER
)

# Set verbose preference
if ($Verbose) {
    $VerbosePreference = "Continue"
}

# Test results storage
$testResults = @{
    StartTime = Get-Date
    Tests = @()
    Summary = @{
        Total = 0
        Passed = 0
        Failed = 0
        Skipped = 0
    }
}

# Helper function for test execution
function Invoke-TestCase {
    param(
        [string]$Name,
        [scriptblock]$Test,
        [switch]$Critical
    )
    
    Write-Host "`n[TEST] $Name" -ForegroundColor Cyan
    $testResult = @{
        Name = $Name
        StartTime = Get-Date
        Status = "Failed"
        Error = $null
        Critical = $Critical.IsPresent
    }
    
    try {
        $result = & $Test
        $testResult.Status = "Passed"
        Write-Host "  [PASS] $Name" -ForegroundColor Green
        $script:testResults.Summary.Passed++
    }
    catch {
        $testResult.Status = "Failed"
        $testResult.Error = $_.ToString()
        Write-Host "  [FAIL] $Name" -ForegroundColor Red
        Write-Host "    Error: $_" -ForegroundColor Red
        $script:testResults.Summary.Failed++
        
        if ($Critical) {
            Write-Host "  [CRITICAL] This is a critical test. Stopping execution." -ForegroundColor Red
            throw "Critical test failed: $Name"
        }
    }
    finally {
        $testResult.EndTime = Get-Date
        $testResult.Duration = ($testResult.EndTime - $testResult.StartTime).TotalSeconds
        $script:testResults.Tests += $testResult
        $script:testResults.Summary.Total++
    }
}

Write-Host "================================" -ForegroundColor Yellow
Write-Host " GitHub Issue Management Tests  " -ForegroundColor Yellow
Write-Host "================================" -ForegroundColor Yellow
Write-Host "Test Repository: $TestOwner/$TestRepository"
Write-Host "Start Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# Import the module
Write-Host "`n[SETUP] Importing Unity-Claude-GitHub module..." -ForegroundColor Yellow
try {
    $modulePath = Join-Path $PSScriptRoot "Modules\Unity-Claude-GitHub"
    Import-Module $modulePath -Force -ErrorAction Stop
    Write-Host "  Module imported successfully" -ForegroundColor Green
}
catch {
    Write-Host "  Failed to import module: $_" -ForegroundColor Red
    exit 1
}

# Test 1: Authentication Check
if ($AllTests -or $TestCreation) {
    Invoke-TestCase -Name "GitHub Authentication Available" -Critical -Test {
        $result = Test-GitHubPAT
        if (-not $result) {
            throw "GitHub PAT not configured. Run Set-GitHubPAT first."
        }
        return $true
    }
}

# Test 2: Create Mock Unity Error
$mockError = @{
    ErrorText = "Assets/Scripts/PlayerController.cs(42,10): error CS0103: The name 'playerSpeed' does not exist in the current context"
    Message = "The name 'playerSpeed' does not exist in the current context"
    Code = "CS0103"
    File = "Assets/Scripts/PlayerController.cs"
    Line = 42
    Column = 10
    Project = "Unity-Claude-Test"
    UnityVersion = "2022.3.10f1"
}

# Test 3: Error Signature Generation
if ($AllTests -or $TestFormat) {
    Invoke-TestCase -Name "Generate Unity Error Signature" -Test {
        $signature = Get-UnityErrorSignature -UnityError $mockError
        if (-not $signature) {
            throw "Failed to generate error signature"
        }
        if ($signature.Length -ne 16) {
            throw "Signature has incorrect length: $($signature.Length)"
        }
        Write-Verbose "Generated signature: $signature"
        return $true
    }
    
    Invoke-TestCase -Name "Signature Consistency" -Test {
        $sig1 = Get-UnityErrorSignature -UnityError $mockError
        $sig2 = Get-UnityErrorSignature -UnityError $mockError
        if ($sig1 -ne $sig2) {
            throw "Signatures are not consistent: $sig1 vs $sig2"
        }
        return $true
    }
}

# Test 4: Format Unity Error as Issue
if ($AllTests -or $TestFormat) {
    Invoke-TestCase -Name "Format Unity Error as GitHub Issue" -Test {
        $issue = Format-UnityErrorAsIssue -UnityError $mockError
        
        if (-not $issue.Title) {
            throw "Issue title is empty"
        }
        if (-not $issue.Body) {
            throw "Issue body is empty"
        }
        if ($issue.Labels.Count -eq 0) {
            throw "No labels generated"
        }
        
        Write-Verbose "Issue Title: $($issue.Title)"
        Write-Verbose "Labels: $($issue.Labels -join ', ')"
        
        # Store for later tests
        $script:formattedIssue = $issue
        return $true
    }
}

# Test 5: Search for Issues (read-only test)
if ($AllTests -or $TestSearch) {
    Invoke-TestCase -Name "Search GitHub Issues" -Test {
        # Search for Unity-related issues in the test repo
        $searchResults = Search-GitHubIssues -Query "Unity" -Owner $TestOwner -Repository $TestRepository -MaxResults 5
        
        Write-Verbose "Found $($searchResults.Count) issues"
        
        # This test passes even if no issues are found (valid result)
        return $true
    }
    
    Invoke-TestCase -Name "Search with Filters" -Test {
        # Search with specific filters
        $searchResults = Search-GitHubIssues -Query "error" -State "all" -Labels @("bug") -Owner $TestOwner -Repository $TestRepository -MaxResults 3
        
        Write-Verbose "Found $($searchResults.Count) issues with filters"
        return $true
    }
}

# Test 6: Duplicate Detection (requires existing issues)
if ($AllTests -or $TestDuplication) {
    Invoke-TestCase -Name "Test Duplicate Detection" -Test {
        # Check if our mock error already exists
        $duplicate = Test-GitHubIssueDuplicate -UnityError $mockError -Owner $TestOwner -Repository $TestRepository
        
        if ($duplicate) {
            Write-Verbose "Found potential duplicate: Issue #$($duplicate.number)"
        }
        else {
            Write-Verbose "No duplicate found"
        }
        
        # Store result for integration test
        $script:existingDuplicate = $duplicate
        return $true
    }
}

# Test 7: Integration Test - Create or Update Issue
if ($AllTests -or $TestIntegration) {
    Invoke-TestCase -Name "Integration: Smart Issue Creation/Update" -Test {
        Write-Host "    Checking for existing issues..." -ForegroundColor Gray
        
        # Check for duplicate
        $duplicate = Test-GitHubIssueDuplicate -UnityError $mockError -Owner $TestOwner -Repository $TestRepository
        
        if ($duplicate) {
            Write-Host "    Found duplicate issue #$($duplicate.number)" -ForegroundColor Yellow
            
            # Add a comment about recurrence
            $comment = "This error occurred again during automated testing.`n`nError Details:````$($mockError.ErrorText)````"
            $commentResult = Add-GitHubIssueComment -Owner $TestOwner -Repository $TestRepository -IssueNumber $duplicate.number -Comment $comment
            
            if (-not $commentResult) {
                throw "Failed to add comment to issue"
            }
            
            Write-Host "    Added recurrence comment to issue #$($duplicate.number)" -ForegroundColor Green
            
            # Store for cleanup
            $script:testIssueNumber = $duplicate.number
            $script:createdNewIssue = $false
        }
        else {
            Write-Host "    No duplicate found, creating new issue..." -ForegroundColor Gray
            
            # Format the error
            $issueData = Format-UnityErrorAsIssue -UnityError $mockError
            
            # Create new issue
            $newIssue = New-GitHubIssue -Owner $TestOwner -Repository $TestRepository `
                -Title "[TEST] $($issueData.Title)" `
                -Body "$($issueData.Body)`n`n**Note**: This is an automated test issue." `
                -Labels @("test", "automated") + $issueData.Labels
            
            if (-not $newIssue) {
                throw "Failed to create new issue"
            }
            
            Write-Host "    Created new issue #$($newIssue.number)" -ForegroundColor Green
            
            # Store for cleanup
            $script:testIssueNumber = $newIssue.number
            $script:createdNewIssue = $true
        }
        
        return $true
    }
    
    # Test update functionality if we have an issue
    if ($script:testIssueNumber) {
        Invoke-TestCase -Name "Update Issue Labels" -Test {
            $updateResult = Update-GitHubIssue -Owner $TestOwner -Repository $TestRepository `
                -IssueNumber $script:testIssueNumber `
                -Labels @("test", "automated", "updated")
            
            if (-not $updateResult) {
                throw "Failed to update issue labels"
            }
            
            Write-Verbose "Updated labels for issue #$($script:testIssueNumber)"
            return $true
        }
    }
}

# Test 8: Cleanup Test Issues (optional)
if ($script:createdNewIssue -and $script:testIssueNumber) {
    Write-Host "`n[CLEANUP] Closing test issue #$($script:testIssueNumber)..." -ForegroundColor Yellow
    try {
        Update-GitHubIssue -Owner $TestOwner -Repository $TestRepository `
            -IssueNumber $script:testIssueNumber `
            -State "closed"
        
        Add-GitHubIssueComment -Owner $TestOwner -Repository $TestRepository `
            -IssueNumber $script:testIssueNumber `
            -Comment "Test completed. Closing automated test issue."
        
        Write-Host "  Test issue closed successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "  Warning: Could not close test issue: $_" -ForegroundColor Yellow
    }
}

# Generate summary
Write-Host "`n================================" -ForegroundColor Yellow
Write-Host "        TEST SUMMARY            " -ForegroundColor Yellow
Write-Host "================================" -ForegroundColor Yellow

$testResults.EndTime = Get-Date
$testResults.Duration = ($testResults.EndTime - $testResults.StartTime).TotalSeconds

Write-Host "Total Tests: $($testResults.Summary.Total)"
Write-Host "Passed: $($testResults.Summary.Passed)" -ForegroundColor Green
Write-Host "Failed: $($testResults.Summary.Failed)" -ForegroundColor $(if ($testResults.Summary.Failed -gt 0) { "Red" } else { "Gray" })
Write-Host "Skipped: $($testResults.Summary.Skipped)" -ForegroundColor Gray
Write-Host "Duration: $([Math]::Round($testResults.Duration, 2)) seconds"

# Calculate success rate
if ($testResults.Summary.Total -gt 0) {
    $successRate = ($testResults.Summary.Passed / $testResults.Summary.Total) * 100
    Write-Host "Success Rate: $([Math]::Round($successRate, 1))%" -ForegroundColor $(if ($successRate -ge 80) { "Green" } elseif ($successRate -ge 60) { "Yellow" } else { "Red" })
}

# Save results if requested
if ($SaveResults) {
    $resultsFile = Join-Path $PSScriptRoot "Test-GitHubIssueManagement-Results_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    
    $output = @()
    $output += "GitHub Issue Management Test Results"
    $output += "====================================="
    $output += "Test Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $output += "Repository: $TestOwner/$TestRepository"
    $output += ""
    $output += "Summary:"
    $output += "  Total Tests: $($testResults.Summary.Total)"
    $output += "  Passed: $($testResults.Summary.Passed)"
    $output += "  Failed: $($testResults.Summary.Failed)"
    $output += "  Duration: $([Math]::Round($testResults.Duration, 2))s"
    $output += ""
    $output += "Detailed Results:"
    
    foreach ($test in $testResults.Tests) {
        $output += ""
        $output += "Test: $($test.Name)"
        $output += "  Status: $($test.Status)"
        $output += "  Duration: $([Math]::Round($test.Duration, 3))s"
        if ($test.Error) {
            $output += "  Error: $($test.Error)"
        }
    }
    
    $output | Out-File -FilePath $resultsFile -Encoding UTF8
    Write-Host "`nResults saved to: $resultsFile" -ForegroundColor Cyan
}

# Exit with appropriate code
if ($testResults.Summary.Failed -gt 0) {
    exit 1
}
else {
    exit 0
}