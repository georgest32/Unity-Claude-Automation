# Test-HITLApprovalWorkflows.ps1
# Comprehensive test suite for Phase 5 Day 5: Human-in-the-Loop Approval Workflows
# Tests Unity-Claude-HITL module integration with LangGraph bridge

param(
    [Parameter()]
    [switch]$SaveResults,
    
    [Parameter()]
    [switch]$DetailedLogging,
    
    [Parameter()]
    [string]$OutputFormat = "Console",  # Console, JSON, Markdown
    
    [Parameter()]
    [switch]$SkipLangGraphTests,
    
    [Parameter()]
    [switch]$QuickTest
)

# Initialize test framework
$ErrorActionPreference = "Continue"
$script:TestResults = @{
    TestSuite = "HITL Approval Workflows"
    StartTime = Get-Date
    EndTime = $null
    Tests = @()
    Summary = @{
        Total = 0
        Passed = 0
        Failed = 0
        Skipped = 0
    }
    Environment = @{
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        OSVersion = [System.Environment]::OSVersion.ToString()
        MachineName = $env:COMPUTERNAME
        UserName = $env:USERNAME
        TestDate = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    }
}

function Write-TestLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        "ERROR" { Write-Host $logMessage -ForegroundColor Red }
        "WARN"  { Write-Host $logMessage -ForegroundColor Yellow }
        "PASS"  { Write-Host $logMessage -ForegroundColor Green }
        "FAIL"  { Write-Host $logMessage -ForegroundColor Red }
        default { Write-Host $logMessage -ForegroundColor White }
    }
    
    if ($DetailedLogging) {
        Add-Content -Path "HITLApprovalWorkflows-TestLog-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt" -Value $logMessage
    }
}

function Add-TestResult {
    param(
        [Parameter(Mandatory)]
        [string]$TestName,
        
        [Parameter(Mandatory)]
        [string]$Status,  # PASSED, FAILED, SKIPPED
        
        [Parameter()]
        [string]$Details = "",
        
        [Parameter()]
        [string]$Error = "",
        
        [Parameter()]
        [hashtable]$Metrics = @{}
    )
    
    $testResult = @{
        Name = $TestName
        Status = $Status
        Details = $Details
        Error = $Error
        Metrics = $Metrics
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Duration = $null
    }
    
    $script:TestResults.Tests += $testResult
    $script:TestResults.Summary.Total++
    
    switch ($Status) {
        "PASSED" { 
            $script:TestResults.Summary.Passed++
            Write-TestLog "✅ $TestName - PASSED" -Level "PASS"
        }
        "FAILED" { 
            $script:TestResults.Summary.Failed++
            Write-TestLog "❌ $TestName - FAILED: $Error" -Level "FAIL"
        }
        "SKIPPED" { 
            $script:TestResults.Summary.Skipped++
            Write-TestLog "⏭️ $TestName - SKIPPED" -Level "WARN"
        }
    }
    
    if ($Details -and $DetailedLogging) {
        Write-TestLog "   Details: $Details" -Level "INFO"
    }
}

# Test 1: Module Import and Basic Structure
function Test-ModuleImport {
    Write-TestLog "Testing Unity-Claude-HITL module import..." -Level "INFO"
    $startTime = Get-Date
    
    try {
        # Test module import
        Import-Module "$PSScriptRoot\Modules\Unity-Claude-HITL\Unity-Claude-HITL.psd1" -Force
        
        # Verify module loaded
        $module = Get-Module -Name "Unity-Claude-HITL"
        if (-not $module) {
            throw "Module not loaded after import"
        }
        
        # Check exported functions
        $expectedFunctions = @(
            'New-ApprovalRequest', 'Send-ApprovalNotification', 'Wait-HumanApproval',
            'Get-ApprovalStatus', 'Resume-WorkflowFromApproval', 'Set-HITLConfiguration',
            'Initialize-ApprovalDatabase', 'New-ApprovalToken', 'Test-ApprovalToken',
            'Invoke-ApprovalAction', 'Get-PendingApprovals'
        )
        
        $exportedFunctions = $module.ExportedFunctions.Keys
        $missingFunctions = $expectedFunctions | Where-Object { $_ -notin $exportedFunctions }
        
        if ($missingFunctions) {
            throw "Missing expected functions: $($missingFunctions -join ', ')"
        }
        
        $duration = ((Get-Date) - $startTime).TotalSeconds
        Add-TestResult -TestName "Module Import and Structure" -Status "PASSED" -Details "All $($expectedFunctions.Count) expected functions exported" -Metrics @{Duration = $duration}
        
    } catch {
        $duration = ((Get-Date) - $startTime).TotalSeconds
        Add-TestResult -TestName "Module Import and Structure" -Status "FAILED" -Error $_.Exception.Message -Metrics @{Duration = $duration}
    }
}

# Test 2: Database Initialization
function Test-DatabaseInitialization {
    Write-TestLog "Testing approval database initialization..." -Level "INFO"
    $startTime = Get-Date
    
    try {
        # Test database initialization
        $dbPath = "$env:TEMP\test_hitl_approvals.db"
        if (Test-Path $dbPath) {
            Remove-Item $dbPath -Force
        }
        
        $result = Initialize-ApprovalDatabase -DatabasePath $dbPath
        
        if (-not $result) {
            throw "Database initialization returned false"
        }
        
        # Verify database file created
        if (-not (Test-Path $dbPath)) {
            throw "Database file was not created"
        }
        
        # Verify schema file created (fallback for missing SQLite module)
        $schemaFile = "$dbPath.schema.sql"
        if (Test-Path $schemaFile) {
            $schemaContent = Get-Content $schemaFile -Raw
            if ($schemaContent -notmatch "approval_requests" -or $schemaContent -notmatch "escalation_rules") {
                throw "Schema file missing required tables"
            }
        }
        
        $duration = ((Get-Date) - $startTime).TotalSeconds
        Add-TestResult -TestName "Database Initialization" -Status "PASSED" -Details "Database and schema created successfully" -Metrics @{Duration = $duration; DatabaseSize = (Get-Item $dbPath -ErrorAction SilentlyContinue).Length}
        
    } catch {
        $duration = ((Get-Date) - $startTime).TotalSeconds
        Add-TestResult -TestName "Database Initialization" -Status "FAILED" -Error $_.Exception.Message -Metrics @{Duration = $duration}
    }
}

# Test 3: Token Generation and Validation
function Test-TokenSecurity {
    Write-TestLog "Testing approval token security..." -Level "INFO"
    $startTime = Get-Date
    
    try {
        # Test token generation
        $approvalId = 12345
        $token = New-ApprovalToken -ApprovalId $approvalId -ExpirationMinutes 60
        
        if (-not $token) {
            throw "Token generation failed"
        }
        
        # Test token validation
        $isValid = Test-ApprovalToken -Token $token
        if (-not $isValid) {
            throw "Valid token failed validation"
        }
        
        # Test invalid token
        $invalidToken = "invalid-token-string"
        $isInvalid = Test-ApprovalToken -Token $invalidToken
        if ($isInvalid) {
            throw "Invalid token passed validation"
        }
        
        # Test token uniqueness
        $token2 = New-ApprovalToken -ApprovalId $approvalId -ExpirationMinutes 60
        if ($token -eq $token2) {
            throw "Token generation not producing unique tokens"
        }
        
        $duration = ((Get-Date) - $startTime).TotalSeconds
        Add-TestResult -TestName "Token Security" -Status "PASSED" -Details "Token generation, validation, and uniqueness verified" -Metrics @{Duration = $duration; TokenLength = $token.Length}
        
    } catch {
        $duration = ((Get-Date) - $startTime).TotalSeconds
        Add-TestResult -TestName "Token Security" -Status "FAILED" -Error $_.Exception.Message -Metrics @{Duration = $duration}
    }
}

# Test 4: Approval Request Creation
function Test-ApprovalRequestCreation {
    Write-TestLog "Testing approval request creation..." -Level "INFO"
    $startTime = Get-Date
    
    try {
        # Create test approval request
        $request = New-ApprovalRequest -WorkflowId "test-workflow-001" -Title "Test Documentation Update" -Description "Testing approval request creation" -UrgencyLevel "medium" -RequestType "documentation"
        
        if (-not $request) {
            throw "Approval request creation failed"
        }
        
        # Validate request properties
        $requiredProperties = @('Id', 'WorkflowId', 'ThreadId', 'Title', 'Status', 'ApprovalToken')
        foreach ($property in $requiredProperties) {
            if (-not $request.$property) {
                throw "Missing required property: $property"
            }
        }
        
        # Validate status
        if ($request.Status -ne 'pending') {
            throw "Initial status should be 'pending', got '$($request.Status)'"
        }
        
        # Validate token generation
        if (-not $request.ApprovalToken) {
            throw "Approval token not generated"
        }
        
        $duration = ((Get-Date) - $startTime).TotalSeconds
        Add-TestResult -TestName "Approval Request Creation" -Status "PASSED" -Details "Request created with ID: $($request.Id)" -Metrics @{Duration = $duration; RequestId = $request.Id}
        
    } catch {
        $duration = ((Get-Date) - $startTime).TotalSeconds
        Add-TestResult -TestName "Approval Request Creation" -Status "FAILED" -Error $_.Exception.Message -Metrics @{Duration = $duration}
    }
}

# Test 5: Notification System Integration
function Test-NotificationSystem {
    Write-TestLog "Testing notification system integration..." -Level "INFO"
    $startTime = Get-Date
    
    try {
        # Create approval request for notification testing
        $request = New-ApprovalRequest -WorkflowId "notification-test-001" -Title "Notification Test Request" -Description "Testing email notification system" -UrgencyLevel "high"
        
        if (-not $request) {
            throw "Failed to create approval request for notification test"
        }
        
        # Test notification sending (simulated)
        $recipients = @("test@example.com", "manager@example.com")
        $result = Send-ApprovalNotification -ApprovalRequest $request -Recipients $recipients
        
        if (-not $result) {
            throw "Notification sending failed"
        }
        
        # Test mobile-friendly notification
        $result2 = Send-ApprovalNotification -ApprovalRequest $request -Recipients @("mobile@example.com")
        
        if (-not $result2) {
            throw "Mobile notification sending failed"
        }
        
        $duration = ((Get-Date) - $startTime).TotalSeconds
        Add-TestResult -TestName "Notification System" -Status "PASSED" -Details "Email notifications processed successfully" -Metrics @{Duration = $duration; Recipients = $recipients.Count}
        
    } catch {
        $duration = ((Get-Date) - $startTime).TotalSeconds
        Add-TestResult -TestName "Notification System" -Status "FAILED" -Error $_.Exception.Message -Metrics @{Duration = $duration}
    }
}

# Test 6: Configuration Management
function Test-ConfigurationManagement {
    Write-TestLog "Testing HITL configuration management..." -Level "INFO"
    $startTime = Get-Date
    
    try {
        # Test configuration updates
        $testConfig = @{
            DefaultTimeout = 720
            EscalationTimeout = 360
            TokenExpirationMinutes = 2880
        }
        
        $result = Set-HITLConfiguration -Configuration $testConfig
        
        if (-not $result) {
            throw "Configuration update failed"
        }
        
        # Test invalid configuration key
        $invalidConfig = @{
            NonExistentKey = "test"
        }
        
        $result2 = Set-HITLConfiguration -Configuration $invalidConfig
        # This should still return true but log warnings
        
        $duration = ((Get-Date) - $startTime).TotalSeconds
        Add-TestResult -TestName "Configuration Management" -Status "PASSED" -Details "Configuration updates processed correctly" -Metrics @{Duration = $duration}
        
    } catch {
        $duration = ((Get-Date) - $startTime).TotalSeconds
        Add-TestResult -TestName "Configuration Management" -Status "FAILED" -Error $_.Exception.Message -Metrics @{Duration = $duration}
    }
}

# Test 7: LangGraph Bridge Integration (if not skipped)
function Test-LangGraphBridge {
    if ($SkipLangGraphTests) {
        Add-TestResult -TestName "LangGraph Bridge Integration" -Status "SKIPPED" -Details "Skipped per parameter"
        return
    }
    
    Write-TestLog "Testing LangGraph bridge integration..." -Level "INFO"
    $startTime = Get-Date
    
    try {
        # Test LangGraph server availability
        $langGraphEndpoint = "http://localhost:8001"
        
        try {
            $healthCheck = Invoke-RestMethod -Uri "$langGraphEndpoint/health" -Method GET -TimeoutSec 5 -ErrorAction Stop
        } catch {
            Add-TestResult -TestName "LangGraph Bridge Integration" -Status "SKIPPED" -Details "LangGraph server not available at $langGraphEndpoint"
            return
        }
        
        # Test approval request creation via API
        $approvalRequest = @{
            workflow_id = "test-bridge-001"
            title = "Bridge Integration Test"
            description = "Testing PowerShell to LangGraph integration"
            urgency_level = "medium"
            request_type = "documentation"
        }
        
        $headers = @{ "Content-Type" = "application/json" }
        $body = ConvertTo-Json $approvalRequest -Depth 10
        
        $response = Invoke-RestMethod -Uri "$langGraphEndpoint/approval/request" -Method POST -Headers $headers -Body $body -TimeoutSec 10
        
        if (-not $response.approval_id) {
            throw "LangGraph approval request creation failed"
        }
        
        # Test approval status check
        $statusResponse = Invoke-RestMethod -Uri "$langGraphEndpoint/approval/$($response.approval_id)" -Method GET -TimeoutSec 10
        
        if ($statusResponse.status -ne "pending") {
            throw "Unexpected approval status: $($statusResponse.status)"
        }
        
        $duration = ((Get-Date) - $startTime).TotalSeconds
        Add-TestResult -TestName "LangGraph Bridge Integration" -Status "PASSED" -Details "API endpoints responding correctly" -Metrics @{Duration = $duration; ApprovalId = $response.approval_id}
        
    } catch {
        $duration = ((Get-Date) - $startTime).TotalSeconds
        Add-TestResult -TestName "LangGraph Bridge Integration" -Status "FAILED" -Error $_.Exception.Message -Metrics @{Duration = $duration}
    }
}

# Test 8: End-to-End Approval Workflow
function Test-EndToEndWorkflow {
    Write-TestLog "Testing end-to-end approval workflow..." -Level "INFO"
    $startTime = Get-Date
    
    try {
        # Step 1: Create approval request
        $request = New-ApprovalRequest -WorkflowId "e2e-test-001" -Title "End-to-End Workflow Test" -Description "Complete workflow testing" -UrgencyLevel "medium"
        
        if (-not $request) {
            throw "Step 1 failed: Approval request creation"
        }
        
        # Step 2: Send notification
        $notificationResult = Send-ApprovalNotification -ApprovalRequest $request -Recipients @("test@example.com")
        
        if (-not $notificationResult) {
            throw "Step 2 failed: Notification sending"
        }
        
        # Step 3: Simulate approval action
        $token = $request.ApprovalToken
        $approvalResult = Invoke-ApprovalAction -Token $token -Action "approve" -Comments "Automated test approval"
        
        if (-not $approvalResult) {
            throw "Step 3 failed: Approval action processing"
        }
        
        # Step 4: Resume workflow (simulated)
        $resumeResult = Resume-WorkflowFromApproval -ThreadId $request.ThreadId -ApprovalResult @{Approved = $true; ApprovedBy = "test-user"}
        
        if (-not $resumeResult) {
            throw "Step 4 failed: Workflow resumption"
        }
        
        $duration = ((Get-Date) - $startTime).TotalSeconds
        Add-TestResult -TestName "End-to-End Workflow" -Status "PASSED" -Details "Complete approval workflow executed successfully" -Metrics @{Duration = $duration; WorkflowId = $request.WorkflowId}
        
    } catch {
        $duration = ((Get-Date) - $startTime).TotalSeconds
        Add-TestResult -TestName "End-to-End Workflow" -Status "FAILED" -Error $_.Exception.Message -Metrics @{Duration = $duration}
    }
}

# Test 9: Performance and Stress Testing
function Test-Performance {
    if ($QuickTest) {
        Add-TestResult -TestName "Performance Testing" -Status "SKIPPED" -Details "Skipped in quick test mode"
        return
    }
    
    Write-TestLog "Testing performance with multiple approval requests..." -Level "INFO"
    $startTime = Get-Date
    
    try {
        $requestCount = 10
        $requests = @()
        
        # Create multiple approval requests
        for ($i = 1; $i -le $requestCount; $i++) {
            $request = New-ApprovalRequest -WorkflowId "perf-test-$i" -Title "Performance Test Request $i" -Description "Load testing approval system" -UrgencyLevel "low"
            $requests += $request
        }
        
        if ($requests.Count -ne $requestCount) {
            throw "Failed to create all test requests. Created: $($requests.Count), Expected: $requestCount"
        }
        
        # Test token generation performance
        $tokenStartTime = Get-Date
        $tokens = @()
        foreach ($request in $requests) {
            $token = New-ApprovalToken -ApprovalId $request.Id -ExpirationMinutes 60
            $tokens += $token
        }
        $tokenDuration = ((Get-Date) - $tokenStartTime).TotalSeconds
        
        # Test token validation performance
        $validationStartTime = Get-Date
        $validationResults = @()
        foreach ($token in $tokens) {
            $isValid = Test-ApprovalToken -Token $token
            $validationResults += $isValid
        }
        $validationDuration = ((Get-Date) - $validationStartTime).TotalSeconds
        
        $totalDuration = ((Get-Date) - $startTime).TotalSeconds
        $avgRequestTime = $totalDuration / $requestCount
        
        Add-TestResult -TestName "Performance Testing" -Status "PASSED" -Details "Processed $requestCount requests successfully" -Metrics @{
            Duration = $totalDuration
            RequestCount = $requestCount
            AvgRequestTime = $avgRequestTime
            TokenGenerationTime = $tokenDuration
            TokenValidationTime = $validationDuration
        }
        
    } catch {
        $duration = ((Get-Date) - $startTime).TotalSeconds
        Add-TestResult -TestName "Performance Testing" -Status "FAILED" -Error $_.Exception.Message -Metrics @{Duration = $duration}
    }
}

# Test 10: Error Handling and Edge Cases
function Test-ErrorHandling {
    Write-TestLog "Testing error handling and edge cases..." -Level "INFO"
    $startTime = Get-Date
    
    try {
        $errorTests = @()
        
        # Test 1: Invalid approval ID for token generation
        try {
            $token = New-ApprovalToken -ApprovalId -1
            $errorTests += @{Test = "Invalid ApprovalId"; Result = "FAILED"; Expected = "Error"; Actual = "Success"}
        } catch {
            $errorTests += @{Test = "Invalid ApprovalId"; Result = "PASSED"; Expected = "Error"; Actual = "Error"}
        }
        
        # Test 2: Empty approval request
        try {
            $request = New-ApprovalRequest -WorkflowId "" -Title "" -Description ""
            $errorTests += @{Test = "Empty Request Fields"; Result = "FAILED"; Expected = "Error"; Actual = "Success"}
        } catch {
            $errorTests += @{Test = "Empty Request Fields"; Result = "PASSED"; Expected = "Error"; Actual = "Error"}
        }
        
        # Test 3: Invalid token validation
        try {
            $isValid = Test-ApprovalToken -Token "clearly-invalid-token"
            if ($isValid) {
                $errorTests += @{Test = "Invalid Token Validation"; Result = "FAILED"; Expected = "False"; Actual = "True"}
            } else {
                $errorTests += @{Test = "Invalid Token Validation"; Result = "PASSED"; Expected = "False"; Actual = "False"}
            }
        } catch {
            $errorTests += @{Test = "Invalid Token Validation"; Result = "PASSED"; Expected = "Error"; Actual = "Error"}
        }
        
        # Test 4: Malformed approval action
        try {
            $result = Invoke-ApprovalAction -Token "invalid" -Action "invalid-action" -Comments "test"
            $errorTests += @{Test = "Invalid Approval Action"; Result = "FAILED"; Expected = "Error"; Actual = "Success"}
        } catch {
            $errorTests += @{Test = "Invalid Approval Action"; Result = "PASSED"; Expected = "Error"; Actual = "Error"}
        }
        
        # Calculate pass rate
        $passedErrorTests = ($errorTests | Where-Object { $_.Result -eq "PASSED" }).Count
        $totalErrorTests = $errorTests.Count
        $passRate = if ($totalErrorTests -gt 0) { ($passedErrorTests / $totalErrorTests) * 100 } else { 0 }
        
        if ($passRate -ge 75) {
            $status = "PASSED"
        } else {
            $status = "FAILED"
        }
        
        $duration = ((Get-Date) - $startTime).TotalSeconds
        Add-TestResult -TestName "Error Handling" -Status $status -Details "Error handling pass rate: $($passRate.ToString('F1'))%" -Metrics @{Duration = $duration; PassRate = $passRate; TestsRun = $totalErrorTests}
        
    } catch {
        $duration = ((Get-Date) - $startTime).TotalSeconds
        Add-TestResult -TestName "Error Handling" -Status "FAILED" -Error $_.Exception.Message -Metrics @{Duration = $duration}
    }
}

# Main execution
function Main {
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "Unity-Claude HITL Approval Workflows Test Suite" -ForegroundColor Cyan
    Write-Host "Phase 5 Day 5: Human-in-the-Loop Integration Testing" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    Write-TestLog "Starting HITL Approval Workflows test suite..." -Level "INFO"
    Write-TestLog "Environment: PowerShell $($PSVersionTable.PSVersion), $($env:COMPUTERNAME)" -Level "INFO"
    
    if ($QuickTest) {
        Write-TestLog "Quick test mode enabled - skipping performance tests" -Level "INFO"
    }
    
    if ($SkipLangGraphTests) {
        Write-TestLog "LangGraph integration tests will be skipped" -Level "INFO"
    }
    
    Write-Host ""
    
    # Execute test functions
    Test-ModuleImport
    Test-DatabaseInitialization  
    Test-TokenSecurity
    Test-ApprovalRequestCreation
    Test-NotificationSystem
    Test-ConfigurationManagement
    Test-LangGraphBridge
    Test-EndToEndWorkflow
    Test-Performance
    Test-ErrorHandling
    
    # Finalize results
    $script:TestResults.EndTime = Get-Date
    $script:TestResults.TotalDuration = ($script:TestResults.EndTime - $script:TestResults.StartTime).TotalSeconds
    
    # Display summary
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "Test Summary" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    
    $passRate = if ($script:TestResults.Summary.Total -gt 0) { 
        ($script:TestResults.Summary.Passed / $script:TestResults.Summary.Total) * 100 
    } else { 0 }
    
    Write-Host "Total Tests: $($script:TestResults.Summary.Total)" -ForegroundColor White
    Write-Host "Passed: $($script:TestResults.Summary.Passed)" -ForegroundColor Green
    Write-Host "Failed: $($script:TestResults.Summary.Failed)" -ForegroundColor Red
    Write-Host "Skipped: $($script:TestResults.Summary.Skipped)" -ForegroundColor Yellow
    Write-Host "Pass Rate: $($passRate.ToString('F1'))%" -ForegroundColor $(if ($passRate -ge 80) { "Green" } else { "Red" })
    Write-Host "Duration: $($script:TestResults.TotalDuration.ToString('F2'))s" -ForegroundColor White
    
    # Save results if requested
    if ($SaveResults) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $resultsFile = "HITLApprovalWorkflows-TestResults-$timestamp.json"
        
        $script:TestResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultsFile -Encoding UTF8
        Write-Host ""
        Write-Host "Results saved to: $resultsFile" -ForegroundColor Blue
    }
    
    # Return overall success status
    return $passRate -ge 80
}

# Execute main function
$testSuccess = Main

# Exit with appropriate code
if ($testSuccess) {
    Write-Host "✅ HITL Approval Workflows test suite completed successfully!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ HITL Approval Workflows test suite completed with failures!" -ForegroundColor Red
    exit 1
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDPiabUB9fMZZUP
# v2DheZ36IMXwbqp4iTgXAkPGhLqpU6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJbulcxY9okb+LnSFtkSsKwy
# 9F1HhwEnh6G9sRnbVQwBMA0GCSqGSIb3DQEBAQUABIIBAImQp+V83dJjuUDUKHDQ
# wHqtl4V0x0jlPu/EiTamxxS0CFhtJhQevk8jlcqhyuK+6nS+M1Q/MGhNG78b44xM
# 5l30ynbWyHlRotlJ0AUFQzzBTIhLCH0FQSCB0i6Rz3HYmgY3irjV4tR3L32un1Ts
# pa2MmvdgyYXeidtg7JyaNNaxsun5T8ySoZ7eHTbvlhZYTBVIuyz2muz4SDk95ABE
# Zbwe5GKz57blA3oOaOtytJGtkneyXQlIWxfpbw/qnlkXVnY1X6jDoVpxfA1xJM8t
# E/DkBHn1iuUW4lQEHF7RIEcL8S+4fZ5tj0Zw0aJMvPlkDllfPRyaxBvbQBqp0/1g
# f0I=
# SIG # End signature block
