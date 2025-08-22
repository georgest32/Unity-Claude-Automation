# Unity-Claude-ErrorHandling.psm1
# Day 5: Error Handling Framework & BeginInvoke/EndInvoke Systems for Parallel Processing
# Phase 1 Week 1 Day 5 Hours 1-8 Implementation
# Date: 2025-08-20

$ErrorActionPreference = "Stop"

#region Module Variables

# Error aggregation using thread-safe collections
$script:ErrorAggregator = $null
$script:CircuitBreakerStates = $null
$script:RetryPolicies = $null

# Performance metrics for error handling
$script:ErrorHandlingStats = @{
    TotalErrors = 0
    ClassifiedErrors = 0
    RetriedOperations = 0
    CircuitBreakerTrips = 0
    RecoveredOperations = 0
    AverageErrorHandlingTimeMs = 0
}

#endregion

#region Hour 1-2: BeginInvoke/EndInvoke Error Handling Framework

<#
.SYNOPSIS
Executes PowerShell command asynchronously with comprehensive error handling

.DESCRIPTION
Wraps PowerShell BeginInvoke/EndInvoke pattern with robust error handling,
error stream monitoring, and proper resource disposal for runspace pool scenarios.

.PARAMETER PowerShellInstance
The PowerShell instance to execute asynchronously

.PARAMETER TimeoutMs
Timeout in milliseconds for async operation

.PARAMETER ErrorAggregator
Optional ConcurrentBag for collecting errors across operations

.EXAMPLE
$result = Invoke-AsyncWithErrorHandling -PowerShellInstance $ps -TimeoutMs 30000 -ErrorAggregator $errors
#>
function Invoke-AsyncWithErrorHandling {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.PowerShell]$PowerShellInstance,
        
        [int]$TimeoutMs = 30000,
        
        [object]$ErrorAggregator = $null
    )
    
    $result = @{
        Success = $false
        Output = $null
        Errors = @()
        Duration = 0
        AsyncHandle = $null
        Exception = $null
    }
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        Write-ConcurrentLog -Message "Starting async operation with error handling (Timeout: ${TimeoutMs}ms)" -Level "DEBUG" -Component "ErrorHandling"
        
        # PowerShell.BeginInvoke() handles error and output streams automatically
        # MergeMyResults not needed for PowerShell class (only for Pipeline Commands)
        
        # Begin async execution
        $result.AsyncHandle = $PowerShellInstance.BeginInvoke()
        
        Write-ConcurrentLog -Message "Async operation started, monitoring completion..." -Level "DEBUG" -Component "ErrorHandling"
        
        # Monitor completion with timeout
        $completed = $false
        $timeoutReached = $false
        
        while (-not $completed -and -not $timeoutReached) {
            if ($result.AsyncHandle.IsCompleted) {
                $completed = $true
                Write-ConcurrentLog -Message "Async operation completed successfully" -Level "DEBUG" -Component "ErrorHandling"
            } elseif ($stopwatch.ElapsedMilliseconds -gt $TimeoutMs) {
                $timeoutReached = $true
                Write-ConcurrentLog -Message "Async operation timeout reached (${TimeoutMs}ms)" -Level "WARNING" -Component "ErrorHandling"
            } else {
                Start-Sleep -Milliseconds 100  # Check every 100ms
            }
        }
        
        if ($completed) {
            # Check for errors before calling EndInvoke
            if ($PowerShellInstance.Streams.Error.Count -gt 0) {
                Write-ConcurrentLog -Message "Error stream contains $($PowerShellInstance.Streams.Error.Count) errors" -Level "WARNING" -Component "ErrorHandling"
                
                # Collect all errors from stream
                foreach ($errorRecord in $PowerShellInstance.Streams.Error) {
                    $result.Errors += @{
                        Message = $errorRecord.Exception.Message
                        Exception = $errorRecord.Exception
                        Category = $errorRecord.CategoryInfo.Category
                        TargetObject = $errorRecord.TargetObject
                        Timestamp = Get-Date
                    }
                    
                    # Add to error aggregator if provided
                    if ($ErrorAggregator -and $ErrorAggregator.InternalBag) {
                        Add-ConcurrentBagItem -Bag $ErrorAggregator -Item $result.Errors[-1]
                    }
                }
            }
            
            # Call EndInvoke with proper exception handling
            try {
                $result.Output = $PowerShellInstance.EndInvoke($result.AsyncHandle)
                $result.Success = $true
                Write-ConcurrentLog -Message "Async operation EndInvoke completed successfully" -Level "INFO" -Component "ErrorHandling"
            } catch {
                $result.Exception = $_
                $result.Success = $false
                Write-ConcurrentLog -Message "EndInvoke failed: $($_.Exception.Message)" -Level "ERROR" -Component "ErrorHandling"
                
                # Add EndInvoke exception to aggregator
                if ($ErrorAggregator -and $ErrorAggregator.InternalBag) {
                    $endInvokeError = @{
                        Message = $_.Exception.Message
                        Exception = $_.Exception
                        Category = "EndInvokeFailure"
                        TargetObject = $PowerShellInstance
                        Timestamp = Get-Date
                    }
                    Add-ConcurrentBagItem -Bag $ErrorAggregator -Item $endInvokeError
                }
            }
        } else {
            # Timeout reached
            $result.Success = $false
            $result.Exception = [System.TimeoutException]::new("Async operation timed out after ${TimeoutMs}ms")
            Write-ConcurrentLog -Message "Async operation timed out" -Level "ERROR" -Component "ErrorHandling"
        }
        
    } catch {
        $result.Success = $false
        $result.Exception = $_
        Write-ConcurrentLog -Message "Async operation failed during setup: $($_.Exception.Message)" -Level "ERROR" -Component "ErrorHandling"
    } finally {
        $stopwatch.Stop()
        $result.Duration = $stopwatch.ElapsedMilliseconds
        
        # Always attempt proper resource disposal
        try {
            if ($PowerShellInstance) {
                $PowerShellInstance.Dispose()
                Write-ConcurrentLog -Message "PowerShell instance disposed successfully" -Level "DEBUG" -Component "ErrorHandling"
            }
        } catch {
            Write-ConcurrentLog -Message "Error disposing PowerShell instance: $($_.Exception.Message)" -Level "WARNING" -Component "ErrorHandling"
        }
        
        # Update error handling statistics
        $script:ErrorHandlingStats.TotalErrors += $result.Errors.Count
        Write-ConcurrentLog -Message "Async operation completed in $($result.Duration)ms with $($result.Errors.Count) errors" -Level "INFO" -Component "ErrorHandling"
    }
    
    return $result
}

<#
.SYNOPSIS
Creates a new error aggregation system for parallel processing

.DESCRIPTION
Initializes thread-safe error collection using ConcurrentBag for aggregating
errors across multiple runspace operations.

.PARAMETER MaxErrors
Maximum number of errors to collect before forcing circuit breaker

.EXAMPLE
$errorSystem = New-ParallelErrorAggregator -MaxErrors 100
#>
function New-ParallelErrorAggregator {
    [CmdletBinding()]
    param(
        [int]$MaxErrors = 1000
    )
    
    try {
        Write-ConcurrentLog -Message "Creating parallel error aggregator (MaxErrors: $MaxErrors)" -Level "INFO" -Component "ErrorHandling"
        
        # Create ConcurrentBag for thread-safe error collection
        $script:ErrorAggregator = New-ConcurrentBag
        
        # Initialize error aggregation metadata
        $aggregatorWrapper = New-Object PSObject -Property @{
            ErrorBag = $script:ErrorAggregator
            MaxErrors = $MaxErrors
            Created = Get-Date
            TotalErrors = 0
            ClassificationStats = @{
                Transient = 0
                Permanent = 0
                RateLimited = 0
                Unity = 0
                Unknown = 0
            }
        }
        
        Write-ConcurrentLog -Message "Parallel error aggregator created successfully" -Level "SUCCESS" -Component "ErrorHandling"
        return $aggregatorWrapper
        
    } catch {
        Write-ConcurrentLog -Message "Failed to create error aggregator: $($_.Exception.Message)" -Level "ERROR" -Component "ErrorHandling"
        throw
    }
}

#endregion

#region Hour 3-4: Error Aggregation and Classification System

<#
.SYNOPSIS
Classifies error for appropriate retry and circuit breaker handling

.DESCRIPTION
Analyzes error patterns to determine if error is Transient, Permanent, 
RateLimited, or Unity-specific for proper retry logic application.

.PARAMETER ErrorRecord
The error record to classify

.PARAMETER ExistingClassifier
Optional existing ErrorHandling.psm1 classification logic

.EXAMPLE
$classification = Get-ParallelErrorClassification -ErrorRecord $errorInfo
#>
function Get-ParallelErrorClassification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$ErrorRecord,
        
        [object]$ExistingClassifier = $null
    )
    
    try {
        $errorMessage = $ErrorRecord.Message.ToLower()
        $classification = "Unknown"
        $retryable = $false
        $maxRetries = 0
        $baseDelayMs = 1000
        
        # Classification patterns based on research and existing ErrorHandling.psm1
        if ($errorMessage -match "timeout|network|connection|503|502|500|429|408") {
            $classification = "Transient"
            $retryable = $true
            $maxRetries = 5
            $baseDelayMs = 1000
        } elseif ($errorMessage -match "401|403|404|400|authentication|unauthorized|forbidden|not found") {
            $classification = "Permanent"
            $retryable = $false
            $maxRetries = 0
            $baseDelayMs = 0
        } elseif ($errorMessage -match "rate limit|throttle|429|quota|limit exceeded") {
            $classification = "RateLimited"
            $retryable = $true
            $maxRetries = 3
            $baseDelayMs = 5000
        } elseif ($errorMessage -match "cs\d{4}|compilation|build|unity|script error") {
            $classification = "Unity"
            $retryable = $true
            $maxRetries = 2
            $baseDelayMs = 2000
        }
        
        $result = @{
            Classification = $classification
            Retryable = $retryable
            MaxRetries = $maxRetries
            BaseDelayMs = $baseDelayMs
            ErrorRecord = $ErrorRecord
            Timestamp = Get-Date
        }
        
        Write-ConcurrentLog -Message "Error classified as '$classification' (Retryable: $retryable, MaxRetries: $maxRetries)" -Level "DEBUG" -Component "ErrorHandling"
        return $result
        
    } catch {
        Write-ConcurrentLog -Message "Error classification failed: $($_.Exception.Message)" -Level "ERROR" -Component "ErrorHandling"
        throw
    }
}

<#
.SYNOPSIS
Aggregates and reports errors from parallel operations

.DESCRIPTION
Collects errors from error aggregator, classifies them, and generates
comprehensive error reporting with statistics and recommendations.

.PARAMETER ErrorAggregator
The error aggregation system containing collected errors

.EXAMPLE
$report = Get-ParallelErrorReport -ErrorAggregator $errorSystem
#>
function Get-ParallelErrorReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$ErrorAggregator
    )
    
    try {
        Write-ConcurrentLog -Message "Generating parallel error report..." -Level "INFO" -Component "ErrorHandling"
        
        # Get all errors from aggregator
        $allErrors = Get-ConcurrentBagItems -Bag $ErrorAggregator.ErrorBag
        Write-ConcurrentLog -Message "Retrieved $($allErrors.Count) errors from aggregator" -Level "DEBUG" -Component "ErrorHandling"
        
        # Classify all errors
        $classifiedErrors = @()
        $classificationStats = @{
            Transient = 0
            Permanent = 0
            RateLimited = 0
            Unity = 0
            Unknown = 0
        }
        
        foreach ($error in $allErrors) {
            $classification = Get-ParallelErrorClassification -ErrorRecord $error
            $classifiedErrors += $classification
            $classificationStats[$classification.Classification]++
        }
        
        # Generate comprehensive report
        $report = @{
            TotalErrors = $allErrors.Count
            ClassificationStats = $classificationStats
            ClassifiedErrors = $classifiedErrors
            RetryableErrors = ($classifiedErrors | Where-Object { $_.Retryable }).Count
            PermanentErrors = ($classifiedErrors | Where-Object { -not $_.Retryable }).Count
            ReportGenerated = Get-Date
            Recommendations = @()
        }
        
        # Add recommendations based on error patterns
        if ($report.ClassificationStats.Transient -gt 5) {
            $report.Recommendations += "High transient error count ($($report.ClassificationStats.Transient)) - consider increasing timeout values"
        }
        if ($report.ClassificationStats.RateLimited -gt 2) {
            $report.Recommendations += "Rate limiting detected ($($report.ClassificationStats.RateLimited)) - implement exponential backoff"
        }
        if ($report.ClassificationStats.Unity -gt 3) {
            $report.Recommendations += "Unity errors detected ($($report.ClassificationStats.Unity)) - check Unity project stability"
        }
        
        Write-ConcurrentLog -Message "Error report generated: $($report.TotalErrors) total, $($report.RetryableErrors) retryable" -Level "INFO" -Component "ErrorHandling"
        return $report
        
    } catch {
        Write-ConcurrentLog -Message "Failed to generate error report: $($_.Exception.Message)" -Level "ERROR" -Component "ErrorHandling"
        throw
    }
}

#endregion

#region Hour 5-6: Circuit Breaker and Resilience Framework

<#
.SYNOPSIS
Implements circuit breaker pattern for runspace pool protection

.DESCRIPTION
Monitors error rates and implements circuit breaker state management
to protect runspace pools from cascading failures.

.PARAMETER ServiceName
Name of the service/operation to protect

.PARAMETER FailureThreshold
Number of failures before opening circuit

.PARAMETER TimeoutMs
Timeout before moving from Open to Half-Open state

.EXAMPLE
Initialize-CircuitBreaker -ServiceName "ClaudeAPI" -FailureThreshold 5 -TimeoutMs 60000
#>
function Initialize-CircuitBreaker {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ServiceName,
        
        [int]$FailureThreshold = 5,
        [int]$TimeoutMs = 60000
    )
    
    try {
        if (-not $script:CircuitBreakerStates) {
            $script:CircuitBreakerStates = New-SynchronizedHashtable
        }
        
        $circuitState = @{
            ServiceName = $ServiceName
            State = "Closed"  # Closed, Open, Half-Open
            FailureCount = 0
            FailureThreshold = $FailureThreshold
            LastFailureTime = $null
            TimeoutMs = $TimeoutMs
            TotalOperations = 0
            SuccessfulOperations = 0
        }
        
        Set-SynchronizedValue -SyncHash $script:CircuitBreakerStates -Key $ServiceName -Value $circuitState
        
        Write-ConcurrentLog -Message "Circuit breaker initialized for '$ServiceName' (Threshold: $FailureThreshold, Timeout: ${TimeoutMs}ms)" -Level "INFO" -Component "ErrorHandling"
        
    } catch {
        Write-ConcurrentLog -Message "Failed to initialize circuit breaker for '$ServiceName': $($_.Exception.Message)" -Level "ERROR" -Component "ErrorHandling"
        throw
    }
}

<#
.SYNOPSIS
Tests circuit breaker state before operation execution

.DESCRIPTION
Checks if circuit breaker allows operation to proceed based on current state
and failure history. Implements Open/Half-Open/Closed state logic.

.PARAMETER ServiceName
Name of the service to check

.EXAMPLE
$allowed = Test-CircuitBreakerState -ServiceName "ClaudeAPI"
#>
function Test-CircuitBreakerState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ServiceName
    )
    
    try {
        if (-not $script:CircuitBreakerStates) {
            Write-ConcurrentLog -Message "Circuit breaker not initialized for '$ServiceName'" -Level "WARNING" -Component "ErrorHandling"
            return $true  # Allow operation if circuit breaker not initialized
        }
        
        $circuitState = Get-SynchronizedValue -SyncHash $script:CircuitBreakerStates -Key $ServiceName
        if (-not $circuitState) {
            Write-ConcurrentLog -Message "No circuit breaker found for '$ServiceName'" -Level "WARNING" -Component "ErrorHandling"
            return $true  # Allow operation if no circuit breaker defined
        }
        
        switch ($circuitState.State) {
            "Closed" {
                # Circuit closed - allow operation
                Write-ConcurrentLog -Message "Circuit breaker '$ServiceName' is CLOSED - operation allowed" -Level "DEBUG" -Component "ErrorHandling"
                return $true
            }
            "Open" {
                # Check if timeout period has elapsed
                $timeSinceFailure = (Get-Date) - $circuitState.LastFailureTime
                if ($timeSinceFailure.TotalMilliseconds -gt $circuitState.TimeoutMs) {
                    # Move to Half-Open state
                    $circuitState.State = "Half-Open"
                    Set-SynchronizedValue -SyncHash $script:CircuitBreakerStates -Key $ServiceName -Value $circuitState
                    Write-ConcurrentLog -Message "Circuit breaker '$ServiceName' moved to HALF-OPEN - allowing test operation" -Level "INFO" -Component "ErrorHandling"
                    return $true
                } else {
                    # Circuit still open
                    Write-ConcurrentLog -Message "Circuit breaker '$ServiceName' is OPEN - operation blocked" -Level "WARNING" -Component "ErrorHandling"
                    return $false
                }
            }
            "Half-Open" {
                # Allow single test operation
                Write-ConcurrentLog -Message "Circuit breaker '$ServiceName' is HALF-OPEN - allowing test operation" -Level "DEBUG" -Component "ErrorHandling"
                return $true
            }
        }
        
    } catch {
        Write-ConcurrentLog -Message "Error checking circuit breaker state for '$ServiceName': $($_.Exception.Message)" -Level "ERROR" -Component "ErrorHandling"
        return $true  # Allow operation on error checking failure
    }
}

<#
.SYNOPSIS
Updates circuit breaker state based on operation result

.DESCRIPTION
Records operation success/failure and updates circuit breaker state
accordingly, implementing state transitions and failure counting.

.PARAMETER ServiceName
Name of the service to update

.PARAMETER Success
Whether the operation was successful

.PARAMETER ErrorInfo
Optional error information for failure cases

.EXAMPLE
Update-CircuitBreakerState -ServiceName "ClaudeAPI" -Success $false -ErrorInfo $errorDetails
#>
function Update-CircuitBreakerState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ServiceName,
        
        [Parameter(Mandatory)]
        [bool]$Success,
        
        [hashtable]$ErrorInfo = $null
    )
    
    try {
        if (-not $script:CircuitBreakerStates) {
            Write-ConcurrentLog -Message "Circuit breaker not initialized for state update" -Level "WARNING" -Component "ErrorHandling"
            return
        }
        
        $circuitState = Get-SynchronizedValue -SyncHash $script:CircuitBreakerStates -Key $ServiceName
        if (-not $circuitState) {
            Write-ConcurrentLog -Message "No circuit breaker found for '$ServiceName' state update" -Level "WARNING" -Component "ErrorHandling"
            return
        }
        
        # Update operation statistics
        $circuitState.TotalOperations++
        
        if ($Success) {
            # Operation successful
            $circuitState.SuccessfulOperations++
            $circuitState.FailureCount = 0  # Reset failure count on success
            
            # Close circuit if it was Half-Open
            if ($circuitState.State -eq "Half-Open") {
                $circuitState.State = "Closed"
                Write-ConcurrentLog -Message "Circuit breaker '$ServiceName' moved to CLOSED after successful test" -Level "SUCCESS" -Component "ErrorHandling"
            }
            
        } else {
            # Operation failed
            $circuitState.FailureCount++
            $circuitState.LastFailureTime = Get-Date
            
            # Open circuit if failure threshold exceeded
            if ($circuitState.FailureCount -ge $circuitState.FailureThreshold -and $circuitState.State -ne "Open") {
                $circuitState.State = "Open"
                $script:ErrorHandlingStats.CircuitBreakerTrips++
                Write-ConcurrentLog -Message "Circuit breaker '$ServiceName' OPENED due to $($circuitState.FailureCount) failures" -Level "ERROR" -Component "ErrorHandling"
            }
        }
        
        # Update circuit breaker state
        Set-SynchronizedValue -SyncHash $script:CircuitBreakerStates -Key $ServiceName -Value $circuitState
        
        Write-ConcurrentLog -Message "Circuit breaker '$ServiceName' updated: State=$($circuitState.State), Failures=$($circuitState.FailureCount)" -Level "DEBUG" -Component "ErrorHandling"
        
    } catch {
        Write-ConcurrentLog -Message "Error updating circuit breaker state for '$ServiceName': $($_.Exception.Message)" -Level "ERROR" -Component "ErrorHandling"
    }
}

#endregion

#region Hour 7-8: Integration and Monitoring

<#
.SYNOPSIS
Initializes comprehensive error handling system for parallel processing

.DESCRIPTION
Sets up error aggregation, circuit breakers, and monitoring for the
Unity-Claude parallel processing pipeline.

.PARAMETER Services
Array of service names to protect with circuit breakers

.EXAMPLE
Initialize-ParallelErrorHandling -Services @("ClaudeAPI", "UnityCompilation", "ResponseProcessing")
#>
function Initialize-ParallelErrorHandling {
    [CmdletBinding()]
    param(
        [string[]]$Services = @("ClaudeAPI", "UnityCompilation", "ResponseProcessing")
    )
    
    try {
        Write-ConcurrentLog -Message "Initializing parallel error handling system for $($Services.Count) services" -Level "INFO" -Component "ErrorHandling"
        
        # Initialize error aggregation
        $script:ErrorAggregator = New-ParallelErrorAggregator
        
        # Initialize circuit breakers for each service
        foreach ($service in $Services) {
            Initialize-CircuitBreaker -ServiceName $service -FailureThreshold 5 -TimeoutMs 60000
        }
        
        # Initialize retry policies
        $script:RetryPolicies = New-SynchronizedHashtable
        
        Write-ConcurrentLog -Message "Parallel error handling system initialized successfully" -Level "SUCCESS" -Component "ErrorHandling"
        
    } catch {
        Write-ConcurrentLog -Message "Failed to initialize parallel error handling: $($_.Exception.Message)" -Level "ERROR" -Component "ErrorHandling"
        throw
    }
}

<#
.SYNOPSIS
Gets comprehensive error handling statistics and status

.DESCRIPTION
Provides detailed statistics about error handling performance,
circuit breaker states, and system health across parallel operations.

.EXAMPLE
$stats = Get-ParallelErrorHandlingStats
#>
function Get-ParallelErrorHandlingStats {
    [CmdletBinding()]
    param()
    
    try {
        $stats = $script:ErrorHandlingStats.Clone()
        
        # Add circuit breaker states if available
        if ($script:CircuitBreakerStates) {
            $stats.CircuitBreakerStates = @{}
            
            foreach ($serviceName in $script:CircuitBreakerStates.Keys) {
                if ($serviceName -ne "_Metadata") {
                    $circuitState = Get-SynchronizedValue -SyncHash $script:CircuitBreakerStates -Key $serviceName
                    $stats.CircuitBreakerStates[$serviceName] = @{
                        State = $circuitState.State
                        FailureCount = $circuitState.FailureCount
                        TotalOperations = $circuitState.TotalOperations
                        SuccessfulOperations = $circuitState.SuccessfulOperations
                        SuccessRate = if ($circuitState.TotalOperations -gt 0) { 
                            [math]::Round(($circuitState.SuccessfulOperations / $circuitState.TotalOperations) * 100, 2) 
                        } else { 0 }
                    }
                }
            }
        }
        
        # Add error aggregator stats
        if ($script:ErrorAggregator) {
            $stats.ErrorAggregatorStats = @{
                TotalErrors = $script:ErrorAggregator.TotalErrors
                MaxErrors = $script:ErrorAggregator.MaxErrors
                Created = $script:ErrorAggregator.Created
                ClassificationStats = $script:ErrorAggregator.ClassificationStats
            }
        }
        
        $stats.ReportGenerated = Get-Date
        Write-ConcurrentLog -Message "Error handling statistics generated" -Level "DEBUG" -Component "ErrorHandling"
        
        return $stats
        
    } catch {
        Write-ConcurrentLog -Message "Error generating error handling stats: $($_.Exception.Message)" -Level "ERROR" -Component "ErrorHandling"
        throw
    }
}

#endregion

# Export module functions
Export-ModuleMember -Function @(
    # BeginInvoke/EndInvoke Error Handling Framework
    'Invoke-AsyncWithErrorHandling',
    'New-ParallelErrorAggregator',
    
    # Error Aggregation and Classification System
    'Get-ParallelErrorClassification',
    'Get-ParallelErrorReport',
    
    # Circuit Breaker and Resilience Framework
    'Initialize-CircuitBreaker',
    'Test-CircuitBreakerState', 
    'Update-CircuitBreakerState',
    
    # Integration and Monitoring
    'Initialize-ParallelErrorHandling',
    'Get-ParallelErrorHandlingStats'
)
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUapm3NhzairMexrGiRj4/81Qd
# Wd2gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQULU7Ejhi0eAqVEtpvAOU5IWpyNzQwDQYJKoZIhvcNAQEBBQAEggEANwTG
# yVl0UZb4zfKZ5y3RG0fqYjJCV27M9B9LCAxu0NxiJexQ09t2opWjO+m4kvOL792R
# aHNPcTW6mMyJBYwFdi05RKHsUG/B18WkKJRlbmI/C0JrwoKpRjB2SwsJXhrEtHli
# tyX+SN+v8b2Ys89Drxm7W2hjy/6kMjiTDKuicUZUKyEKxftU1ktwn0SW+mcAHsOO
# WHXeGoUHlfix8yPyziE3fUzswSgphyOAYdd7Km/ZikQS+O7y2y1DwNfbGJ6tvST7
# 8uK3Q5GVRWVH7gyFf9rqlrfNmXOUqQQFgd+k6z1L5btLqIhkYbnB2WTyL9+srPsa
# rdVcJDoaRvpWDRml3g==
# SIG # End signature block
