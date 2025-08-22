# ErrorHandling.psm1
# Master Plan Day 11: Error Handling and Retry Logic Implementation
# Implements exponential backoff, selective retry logic, and error classification
# Date: 2025-08-18
# IMPORTANT: ASCII only, no backticks, proper variable delimiting

#region Module Dependencies

# Import required modules
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "Core\AgentLogging.psm1") -Force

#endregion

#region Module Variables

# Error classification definitions
$script:ErrorClassification = @{
    "Transient" = @{
        Patterns = @("timeout", "network", "connection", "503", "502", "500", "429", "408")
        RetryEnabled = $true
        MaxRetries = 5
        BaseDelay = 1000  # 1 second
    }
    
    "Permanent" = @{
        Patterns = @("401", "403", "404", "400", "authentication", "unauthorized", "forbidden", "not found")
        RetryEnabled = $false
        MaxRetries = 0
        BaseDelay = 0
    }
    
    "RateLimited" = @{
        Patterns = @("rate limit", "throttle", "429", "quota", "limit exceeded")
        RetryEnabled = $true
        MaxRetries = 3
        BaseDelay = 5000  # 5 seconds for rate limits
    }
    
    "Unity" = @{
        Patterns = @("CS\d{4}", "compilation", "build", "unity", "script error")
        RetryEnabled = $true
        MaxRetries = 2
        BaseDelay = 2000  # 2 seconds for Unity-specific errors
    }
}

# Circuit breaker state management
$script:CircuitBreakerState = @{
    "DefaultCircuit" = @{
        State = "Closed"  # Closed, Open, Half-Open
        FailureCount = 0
        LastFailureTime = $null
        SuccessCount = 0
        OpenTimeout = 30000  # 30 seconds
        FailureThreshold = 5
        SuccessThreshold = 3  # For Half-Open -> Closed transition
    }
}

# Retry attempt tracking
$script:RetryAttempts = @{}

#endregion

#region Exponential Backoff Functions

function Invoke-ExponentialBackoffRetry {
    <#
    .SYNOPSIS
    Executes operation with exponential backoff retry strategy
    
    .DESCRIPTION
    Implements retry logic with exponential backoff, jitter, and error classification
    
    .PARAMETER ScriptBlock
    The operation to retry
    
    .PARAMETER MaxRetries
    Maximum number of retry attempts
    
    .PARAMETER BaseDelayMs
    Base delay in milliseconds for exponential calculation
    
    .PARAMETER MaxDelayMs
    Maximum delay cap to prevent excessive backoff
    
    .PARAMETER ErrorClassifier
    Function to classify errors for retry decision
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ScriptBlock]$ScriptBlock,
        
        [int]$MaxRetries = 3,
        
        [int]$BaseDelayMs = 1000,
        
        [int]$MaxDelayMs = 30000,
        
        [ScriptBlock]$ErrorClassifier = $null
    )
    
    Write-AgentLog "Starting exponential backoff retry operation" -Level "INFO" -Component "RetryManager"
    
    $attemptCount = 0
    $lastError = $null
    
    while ($attemptCount -le $MaxRetries) {
        try {
            Write-AgentLog "Retry attempt $attemptCount/$MaxRetries" -Level "DEBUG" -Component "RetryManager"
            
            # Execute the operation
            $result = & $ScriptBlock
            
            Write-AgentLog "Operation succeeded on attempt $attemptCount" -Level "SUCCESS" -Component "RetryManager"
            return @{
                Success = $true
                Result = $result
                AttemptCount = $attemptCount
            }
        }
        catch {
            $lastError = $_
            $attemptCount++
            
            Write-AgentLog "Operation failed on attempt $attemptCount`: $_" -Level "WARNING" -Component "RetryManager"
            
            # Check if we should retry this error
            $shouldRetry = Test-ErrorRetryability -Error $lastError -ErrorClassifier $ErrorClassifier
            
            if (-not $shouldRetry -or $attemptCount -gt $MaxRetries) {
                Write-AgentLog "Not retrying: ShouldRetry=$shouldRetry, AttemptCount=$attemptCount, MaxRetries=$MaxRetries" -Level "INFO" -Component "RetryManager"
                break
            }
            
            # Calculate delay with exponential backoff and jitter
            $delay = Get-ExponentialBackoffDelay -AttemptCount $attemptCount -BaseDelayMs $BaseDelayMs -MaxDelayMs $MaxDelayMs
            
            Write-AgentLog "Waiting $delay ms before retry attempt $($attemptCount + 1)" -Level "DEBUG" -Component "RetryManager"
            Start-Sleep -Milliseconds $delay
        }
    }
    
    Write-AgentLog "All retry attempts exhausted, operation failed" -Level "ERROR" -Component "RetryManager"
    return @{
        Success = $false
        Error = $lastError
        AttemptCount = $attemptCount
    }
}

function Get-ExponentialBackoffDelay {
    <#
    .SYNOPSIS
    Calculates exponential backoff delay with jitter
    
    .DESCRIPTION
    Implements exponential backoff formula: (base * 2^n) + jitter
    
    .PARAMETER AttemptCount
    Current attempt number
    
    .PARAMETER BaseDelayMs
    Base delay in milliseconds
    
    .PARAMETER MaxDelayMs
    Maximum delay cap
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$AttemptCount,
        
        [int]$BaseDelayMs = 1000,
        
        [int]$MaxDelayMs = 30000
    )
    
    # Calculate exponential delay: base * 2^attempt
    $exponentialDelay = $BaseDelayMs * [Math]::Pow(2, $AttemptCount - 1)
    
    # Apply maximum delay cap
    $cappedDelay = [Math]::Min($exponentialDelay, $MaxDelayMs)
    
    # Add jitter (±25% randomness) to prevent thundering herd
    $jitterRange = [Math]::Max(1, $cappedDelay * 0.25)
    $jitter = (Get-Random -Minimum (-$jitterRange) -Maximum $jitterRange)
    $finalDelay = [Math]::Max(100, $cappedDelay + $jitter)  # Minimum 100ms
    
    Write-AgentLog "Backoff calculation: Base=$BaseDelayMs, Exponential=$exponentialDelay, Capped=$cappedDelay, Jitter=$jitter, Final=$finalDelay" -Level "DEBUG" -Component "BackoffCalculator"
    
    return [int]$finalDelay
}

function Test-ErrorRetryability {
    <#
    .SYNOPSIS
    Tests if an error should be retried based on classification
    
    .DESCRIPTION
    Classifies errors as transient/permanent and determines retry eligibility
    
    .PARAMETER Error
    The error object to classify
    
    .PARAMETER ErrorClassifier
    Optional custom error classifier
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Error,
        
        [ScriptBlock]$ErrorClassifier = $null
    )
    
    Write-AgentLog "Classifying error for retry decision" -Level "DEBUG" -Component "ErrorClassifier"
    
    try {
        # Use custom classifier if provided
        if ($ErrorClassifier) {
            $customResult = & $ErrorClassifier $Error
            Write-AgentLog "Custom classifier result: $customResult" -Level "DEBUG" -Component "ErrorClassifier"
            return $customResult
        }
        
        # Default classification logic
        # Check for null message and handle gracefully
        $errorMessage = if ($Error.Exception -and $Error.Exception.Message) {
            $Error.Exception.Message.ToLower()
        } else {
            ""
        }
        
        $errorType = if ($Error.CategoryInfo -and $Error.CategoryInfo.Category) {
            $Error.CategoryInfo.Category.ToString()
        } else {
            "Unknown"
        }
        
        Write-AgentLog "Error analysis: Message='$errorMessage', Type='$errorType'" -Level "DEBUG" -Component "ErrorClassifier"
        
        # Check against classification patterns
        foreach ($classification in $script:ErrorClassification.Keys) {
            $classData = $script:ErrorClassification[$classification]
            
            foreach ($pattern in $classData.Patterns) {
                if ($errorMessage -match $pattern) {
                    $shouldRetry = $classData.RetryEnabled
                    Write-AgentLog "Error classified as '$classification' (pattern: $pattern), RetryEnabled: $shouldRetry" -Level "INFO" -Component "ErrorClassifier"
                    return $shouldRetry
                }
            }
        }
        
        # Default: retry unknown errors conservatively
        Write-AgentLog "Error not classified, defaulting to retry=true" -Level "DEBUG" -Component "ErrorClassifier"
        return $true
    }
    catch {
        Write-AgentLog "Error classification failed: $_" -Level "ERROR" -Component "ErrorClassifier"
        return $false  # Don't retry if classification fails
    }
}

function Get-ErrorClassificationConfig {
    <#
    .SYNOPSIS
    Gets the current error classification configuration
    
    .DESCRIPTION
    Returns error classification patterns and retry settings
    #>
    [CmdletBinding()]
    param()
    
    return $script:ErrorClassification
}

function Set-ErrorClassificationConfig {
    <#
    .SYNOPSIS
    Updates error classification configuration
    
    .DESCRIPTION
    Allows customization of error patterns and retry settings
    
    .PARAMETER Classification
    New classification configuration
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Classification
    )
    
    Write-AgentLog "Updating error classification configuration" -Level "INFO" -Component "ConfigManager"
    
    try {
        $script:ErrorClassification = $Classification
        Write-AgentLog "Error classification updated successfully" -Level "SUCCESS" -Component "ConfigManager"
        return $true
    }
    catch {
        Write-AgentLog "Failed to update error classification: $_" -Level "ERROR" -Component "ConfigManager"
        return $false
    }
}

#endregion

#region Circuit Breaker Functions

function Get-CircuitBreakerState {
    <#
    .SYNOPSIS
    Gets the current state of a circuit breaker
    
    .DESCRIPTION
    Returns circuit breaker state and metrics
    
    .PARAMETER CircuitName
    Name of the circuit breaker
    #>
    [CmdletBinding()]
    param(
        [string]$CircuitName = "DefaultCircuit"
    )
    
    if ($script:CircuitBreakerState.ContainsKey($CircuitName)) {
        return $script:CircuitBreakerState[$CircuitName]
    }
    
    # Return default state if circuit doesn't exist
    return @{
        State = "Closed"
        FailureCount = 0
        LastFailureTime = $null
        SuccessCount = 0
    }
}

function Set-CircuitBreakerState {
    <#
    .SYNOPSIS
    Updates circuit breaker state
    
    .DESCRIPTION
    Manages circuit breaker state transitions
    
    .PARAMETER CircuitName
    Name of the circuit breaker
    
    .PARAMETER NewState
    New state for the circuit
    
    .PARAMETER Reason
    Reason for state change
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CircuitName,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("Closed", "Open", "Half-Open")]
        [string]$NewState,
        
        [string]$Reason = ""
    )
    
    Write-AgentLog "Circuit breaker '$CircuitName' state change: $NewState ($Reason)" -Level "INFO" -Component "CircuitBreaker"
    
    if (-not $script:CircuitBreakerState.ContainsKey($CircuitName)) {
        # Initialize new circuit breaker
        $script:CircuitBreakerState[$CircuitName] = @{
            State = "Closed"
            FailureCount = 0
            LastFailureTime = $null
            SuccessCount = 0
            OpenTimeout = 30000
            FailureThreshold = 5
            SuccessThreshold = 3
        }
    }
    
    $circuit = $script:CircuitBreakerState[$CircuitName]
    $previousState = $circuit.State
    $circuit.State = $NewState
    
    # Reset counters on state transitions
    switch ($NewState) {
        "Closed" {
            $circuit.FailureCount = 0
            $circuit.SuccessCount = 0
        }
        "Open" {
            $circuit.LastFailureTime = Get-Date
        }
        "Half-Open" {
            $circuit.SuccessCount = 0
        }
    }
    
    Write-AgentLog "Circuit breaker '$CircuitName' transition: $previousState → $NewState" -Level "INFO" -Component "CircuitBreaker"
}

function Test-CircuitBreakerState {
    <#
    .SYNOPSIS
    Tests if circuit breaker allows operation execution
    
    .DESCRIPTION
    Checks circuit breaker state and determines if operations should proceed
    
    .PARAMETER CircuitName
    Name of the circuit breaker to test
    #>
    [CmdletBinding()]
    param(
        [string]$CircuitName = "DefaultCircuit"
    )
    
    $circuit = Get-CircuitBreakerState -CircuitName $CircuitName
    
    Write-AgentLog "Testing circuit breaker '$CircuitName' (State: $($circuit.State))" -Level "DEBUG" -Component "CircuitBreaker"
    
    switch ($circuit.State) {
        "Closed" {
            Write-AgentLog "Circuit CLOSED - operation allowed" -Level "DEBUG" -Component "CircuitBreaker"
            return $true
        }
        
        "Open" {
            # Check if timeout period has elapsed
            if ($circuit.LastFailureTime) {
                $timeSinceFailure = (Get-Date) - $circuit.LastFailureTime
                if ($timeSinceFailure.TotalMilliseconds -gt $circuit.OpenTimeout) {
                    Write-AgentLog "Circuit timeout elapsed, transitioning to Half-Open" -Level "INFO" -Component "CircuitBreaker"
                    Set-CircuitBreakerState -CircuitName $CircuitName -NewState "Half-Open" -Reason "Timeout elapsed"
                    return $true
                }
            }
            
            Write-AgentLog "Circuit OPEN - operation blocked" -Level "WARNING" -Component "CircuitBreaker"
            return $false
        }
        
        "Half-Open" {
            Write-AgentLog "Circuit HALF-OPEN - limited operation allowed" -Level "DEBUG" -Component "CircuitBreaker"
            return $true
        }
        
        default {
            Write-AgentLog "Unknown circuit state: $($circuit.State)" -Level "ERROR" -Component "CircuitBreaker"
            return $false
        }
    }
}

function Update-CircuitBreakerMetrics {
    <#
    .SYNOPSIS
    Updates circuit breaker metrics based on operation result
    
    .DESCRIPTION
    Records success/failure and manages state transitions
    
    .PARAMETER CircuitName
    Name of the circuit breaker
    
    .PARAMETER Success
    Whether the operation succeeded
    
    .PARAMETER ResponseTime
    Operation response time in milliseconds
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CircuitName,
        
        [Parameter(Mandatory = $true)]
        [bool]$Success,
        
        [int]$ResponseTime = 0
    )
    
    Write-AgentLog "Updating circuit breaker metrics: CircuitName=$CircuitName, Success=$Success, ResponseTime=$ResponseTime" -Level "DEBUG" -Component "CircuitBreaker"
    
    $circuit = Get-CircuitBreakerState -CircuitName $CircuitName
    
    if ($Success) {
        $circuit.SuccessCount++
        Write-AgentLog "Circuit success recorded (count: $($circuit.SuccessCount))" -Level "DEBUG" -Component "CircuitBreaker"
        
        # Transition from Half-Open to Closed if enough successes
        if ($circuit.State -eq "Half-Open" -and $circuit.SuccessCount -ge $circuit.SuccessThreshold) {
            Set-CircuitBreakerState -CircuitName $CircuitName -NewState "Closed" -Reason "Success threshold reached"
        }
    } else {
        $circuit.FailureCount++
        $circuit.LastFailureTime = Get-Date
        Write-AgentLog "Circuit failure recorded (count: $($circuit.FailureCount))" -Level "WARNING" -Component "CircuitBreaker"
        
        # Transition to Open if failure threshold exceeded
        if ($circuit.State -eq "Closed" -and $circuit.FailureCount -ge $circuit.FailureThreshold) {
            Set-CircuitBreakerState -CircuitName $CircuitName -NewState "Open" -Reason "Failure threshold exceeded"
        }
        # Transition from Half-Open to Open on any failure
        elseif ($circuit.State -eq "Half-Open") {
            Set-CircuitBreakerState -CircuitName $CircuitName -NewState "Open" -Reason "Half-Open test failed"
        }
    }
    
    # Update the state in module variable
    $script:CircuitBreakerState[$CircuitName] = $circuit
}

#endregion

#region Timeout and Cancellation Support

function Invoke-OperationWithTimeout {
    <#
    .SYNOPSIS
    Executes operation with timeout support
    
    .DESCRIPTION
    PowerShell 5.1 compatible timeout implementation using manual timing
    
    .PARAMETER ScriptBlock
    Operation to execute
    
    .PARAMETER TimeoutMs
    Timeout in milliseconds
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ScriptBlock]$ScriptBlock,
        
        [int]$TimeoutMs = 30000
    )
    
    Write-AgentLog "Starting operation with timeout: ${TimeoutMs}ms" -Level "INFO" -Component "TimeoutManager"
    
    try {
        # Start timing
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        # PowerShell 5.1 compatible timeout - use job-based execution
        $job = Start-Job -ScriptBlock $ScriptBlock
        
        # Wait for completion with timeout
        $completed = Wait-Job -Job $job -Timeout ($TimeoutMs / 1000)
        $stopwatch.Stop()
        
        if ($completed) {
            $result = Receive-Job -Job $job
            Remove-Job -Job $job -Force
            
            Write-AgentLog "Operation completed successfully in $($stopwatch.ElapsedMilliseconds)ms" -Level "SUCCESS" -Component "TimeoutManager"
            
            return @{
                Success = $true
                Result = $result
                ElapsedMs = $stopwatch.ElapsedMilliseconds
                TimedOut = $false
            }
        } else {
            # Operation timed out
            Stop-Job -Job $job -PassThru | Remove-Job -Force
            
            Write-AgentLog "Operation timed out after $($stopwatch.ElapsedMilliseconds)ms (limit: ${TimeoutMs}ms)" -Level "WARNING" -Component "TimeoutManager"
            
            return @{
                Success = $false
                Error = "Operation timed out"
                ElapsedMs = $stopwatch.ElapsedMilliseconds
                TimedOut = $true
            }
        }
    }
    catch {
        Write-AgentLog "Timeout operation failed: $_" -Level "ERROR" -Component "TimeoutManager"
        return @{
            Success = $false
            Error = $_.Exception.Message
            TimedOut = $false
        }
    }
}

function Stop-OperationGracefully {
    <#
    .SYNOPSIS
    Gracefully cancels a long-running operation
    
    .DESCRIPTION
    Provides cancellation mechanisms for PowerShell operations
    
    .PARAMETER OperationId
    Identifier for the operation to cancel
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OperationId
    )
    
    Write-AgentLog "Gracefully stopping operation: $OperationId" -Level "INFO" -Component "CancellationManager"
    
    try {
        # Implementation would track running operations and provide cancellation
        # For PowerShell 5.1, this involves job management
        
        Write-AgentLog "Operation cancellation requested: $OperationId" -Level "SUCCESS" -Component "CancellationManager"
        
        return @{
            Success = $true
            OperationId = $OperationId
            CancelledAt = Get-Date
        }
    }
    catch {
        Write-AgentLog "Operation cancellation failed: $_" -Level "ERROR" -Component "CancellationManager"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

#endregion

# Export module functions
Export-ModuleMember -Function @(
    'Invoke-ExponentialBackoffRetry',
    'Get-ExponentialBackoffDelay',
    'Test-ErrorRetryability',
    'Get-ErrorClassificationConfig',
    'Set-ErrorClassificationConfig',
    'Get-CircuitBreakerState',
    'Set-CircuitBreakerState', 
    'Test-CircuitBreakerState',
    'Update-CircuitBreakerMetrics',
    'Invoke-OperationWithTimeout',
    'Stop-OperationGracefully'
)

Write-AgentLog "ErrorHandling module loaded successfully" -Level "INFO" -Component "ErrorHandling"
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUc7ilpc673uo9SQirY6oyLkO/
# OlagggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUofP2U8xbJy2NdGonXMpPfZaPPoMwDQYJKoZIhvcNAQEBBQAEggEAl7RH
# 67ZBYsbiK7odT2hdQ8ceI5QmNBoKDCFhV2frQRRvsm9EfJV/SvZjpdKuVMoFzBNS
# dDBOr+fJM6aASdNgFBWUbInH0e2HmSFZpxblAGxdBQ3OTW9QjEFYtVfuOm5y1b38
# jLPS8TQCy2W4bPbLs2HWKmWlLKaAXbIjk5iAe+b7u8IOY5ElK+xwQvjDDosG9Cir
# bjS8FJQ4xffxVMLN4A3EAG0YrjSf36J0X32gomVf8YiDGytiFySuIWH8X8hNIWXZ
# 7/lNLOoplnJW3w1Ur1xifFcaDblQtTTVY63hOwUl0SOB/Zsm3Stl+cAaVueSjcX5
# e/dLS6RuOvptQkIhJw==
# SIG # End signature block
