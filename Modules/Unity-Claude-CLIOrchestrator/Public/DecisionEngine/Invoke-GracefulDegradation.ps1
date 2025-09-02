function Invoke-GracefulDegradation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ErrorMessage,
        
        [Parameter()]
        [hashtable]$Context = @{},
        
        [Parameter()]
        [string]$FallbackAction = "CONTINUE"
    )
    
    Write-DecisionLog "Initiating graceful degradation for error: $ErrorMessage" "WARN"
    
    $degradationResult = @{
        Timestamp = Get-Date
        OriginalError = $ErrorMessage
        DegradationStrategy = "Unknown"
        FallbackDecision = $FallbackAction
        SafetyLevel = "High"
        Confidence = 0.5
        Reason = "Graceful degradation applied"
        Actions = @()
    }
    
    try {
        # Analyze error type to determine degradation strategy
        $errorType = "Generic"
        $degradationStrategy = "DefaultFallback"
        
        # Pattern-based error classification
        if ($ErrorMessage -match "(timeout|time.*out)") {
            $errorType = "Timeout"
            $degradationStrategy = "RetryWithIncreasedTimeout"
            $degradationResult.FallbackDecision = "CONTINUE"
            $degradationResult.Actions += "Increase timeout settings"
        }
        elseif ($ErrorMessage -match "(access.*denied|permission|unauthorized)") {
            $errorType = "PermissionError"
            $degradationStrategy = "RequestElevation"
            $degradationResult.FallbackDecision = "ERROR"
            $degradationResult.Actions += "Request elevated permissions"
        }
        elseif ($ErrorMessage -match "(file.*not.*found|path.*not.*found|does not exist)") {
            $errorType = "FileNotFound"
            $degradationStrategy = "CreateAlternative"
            $degradationResult.FallbackDecision = "CONTINUE"
            $degradationResult.Actions += "Attempt to create missing resource"
        }
        elseif ($ErrorMessage -match "(network|connection|unreachable|dns)") {
            $errorType = "NetworkError"
            $degradationStrategy = "OfflineMode"
            $degradationResult.FallbackDecision = "CONTINUE"
            $degradationResult.Actions += "Switch to offline processing"
        }
        elseif ($ErrorMessage -match "(memory|out of memory|heap)") {
            $errorType = "MemoryError"
            $degradationStrategy = "ReduceScope"
            $degradationResult.FallbackDecision = "CONTINUE"
            $degradationResult.Actions += "Reduce processing scope to conserve memory"
        }
        else {
            $errorType = "UnknownError"
            $degradationStrategy = "SafeStop"
            $degradationResult.FallbackDecision = "ERROR"
            $degradationResult.Actions += "Stop processing safely"
        }
        
        $degradationResult.ErrorType = $errorType
        $degradationResult.DegradationStrategy = $degradationStrategy
        
        # Adjust confidence based on error type
        $degradationResult.Confidence = switch ($errorType) {
            "Timeout" { 0.8 }
            "FileNotFound" { 0.7 }
            "NetworkError" { 0.6 }
            "PermissionError" { 0.4 }
            "MemoryError" { 0.3 }
            default { 0.2 }
        }
        
        # Add context-specific actions
        if ($Context.ContainsKey('RetryCount') -and $Context.RetryCount -gt 2) {
            $degradationResult.Actions += "Retry limit exceeded - escalating to manual intervention"
            $degradationResult.FallbackDecision = "ERROR"
            $degradationResult.SafetyLevel = "Critical"
        }
        
        Write-DecisionLog "Degradation strategy: $degradationStrategy for $errorType (Confidence: $($degradationResult.Confidence))" "INFO"
        Write-DecisionLog "Fallback decision: $($degradationResult.FallbackDecision)" "INFO"
        
        return $degradationResult
        
    } catch {
        Write-DecisionLog "Error during graceful degradation: $($_.Exception.Message)" "ERROR"
        
        # Ultimate fallback
        return @{
            Timestamp = Get-Date
            OriginalError = $ErrorMessage
            DegradationError = $_.Exception.Message
            DegradationStrategy = "EmergencyStop"
            FallbackDecision = "ERROR"
            SafetyLevel = "Critical"
            Confidence = 0.1
            Reason = "Graceful degradation failed - emergency stop"
            Actions = @("Emergency stop - manual intervention required")
        }
    }
}