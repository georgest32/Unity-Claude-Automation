# ResultAnalysisEngine.psm1
# Command result analysis system for intelligent prompt engine
# Refactored component from IntelligentPromptEngine.psm1
# Component: Command result analysis system (350 lines)

#region Command Result Analysis System

function Invoke-CommandResultAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$CommandResult,
        
        [Parameter(Mandatory=$true)]
        [string]$CommandType,
        
        [Parameter()]
        [hashtable]$Context = @{}
    )
    
    Write-AgentLog -Message "Starting command result analysis for type: $CommandType" -Level "DEBUG" -Component "ResultAnalyzer"
    
    try {
        # Initialize analysis result structure
        $analysisResult = @{
            Classification = $null
            Severity = $null
            Priority = $null
            Confidence = 0.0
            Patterns = @()
            Metadata = @{
                Timestamp = Get-Date
                CommandType = $CommandType
                AnalysisVersion = "1.0"
                Context = $Context
            }
            NextActions = @()
            LearningData = @{}
        }
        
        Write-AgentLog -Message "Analyzing command result structure and content" -Level "DEBUG" -Component "ResultAnalyzer"
        
        # Step 1: Classify result using Operation Result Pattern (Success/Failure/Exception)
        $classification = Get-ResultClassification -CommandResult $CommandResult -CommandType $CommandType
        $analysisResult.Classification = $classification.Type
        $analysisResult.Confidence = $classification.Confidence
        
        Write-AgentLog -Message "Result classified as: $($classification.Type) with confidence: $($classification.Confidence)" -Level "INFO" -Component "ResultAnalyzer"
        
        # Step 2: Determine severity level using four-tier system
        $severity = Get-ResultSeverity -CommandResult $CommandResult -Classification $classification -CommandType $CommandType
        $analysisResult.Severity = $severity.Level
        $analysisResult.Priority = $severity.Priority
        
        Write-AgentLog -Message "Severity assessed as: $($severity.Level), Priority: $($severity.Priority)" -Level "INFO" -Component "ResultAnalyzer"
        
        # Step 3: Extract patterns and anomalies
        $patterns = Find-ResultPatterns -CommandResult $CommandResult -CommandType $CommandType -Classification $classification
        $analysisResult.Patterns = $patterns
        
        Write-AgentLog -Message "Found $($patterns.Count) patterns in result analysis" -Level "DEBUG" -Component "ResultAnalyzer"
        
        # Step 4: Generate next action recommendations
        $nextActions = Get-NextActionRecommendations -Classification $classification -Severity $severity -Patterns $patterns -CommandType $CommandType
        $analysisResult.NextActions = $nextActions
        
        Write-AgentLog -Message "Generated $($nextActions.Count) next action recommendations" -Level "DEBUG" -Component "ResultAnalyzer"
        
        # Step 5: Store result for pattern learning
        $learningData = @{
            CommandType = $CommandType
            Classification = $classification
            Severity = $severity
            Patterns = $patterns
            Timestamp = Get-Date
            Context = $Context
        }
        
        $config = Get-PromptEngineConfig
        $config.ResultHistory.Enqueue($learningData)
        $analysisResult.LearningData = $learningData
        
        Write-AgentLog -Message "Result analysis completed successfully" -Level "INFO" -Component "ResultAnalyzer"
        
        return @{
            Success = $true
            Analysis = $analysisResult
            Error = $null
        }
    }
    catch {
        Write-AgentLog -Message "Command result analysis failed: $_" -Level "ERROR" -Component "ResultAnalyzer"
        return @{
            Success = $false
            Analysis = $null
            Error = $_.ToString()
        }
    }
}

function Get-ResultClassification {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$CommandResult,
        
        [Parameter(Mandatory=$true)]
        [string]$CommandType
    )
    
    Write-AgentLog -Message "Classifying result using Operation Result Pattern" -Level "DEBUG" -Component "ResultClassifier"
    
    try {
        # Initialize classification result
        $classification = @{
            Type = "Unknown"
            Confidence = 0.0
            Indicators = @()
            Metadata = @{}
        }
        
        # Check for explicit success/failure indicators
        if ($CommandResult.ContainsKey('Success')) {
            if ($CommandResult.Success -eq $true) {
                $classification.Type = "Success"
                $classification.Confidence = 0.9
                $classification.Indicators += "Explicit Success Flag"
            }
            elseif ($CommandResult.Success -eq $false) {
                if ($CommandResult.ContainsKey('Error') -and $CommandResult.Error) {
                    $classification.Type = "Exception"
                    $classification.Confidence = 0.85
                    $classification.Indicators += "Explicit Error with Exception"
                }
                else {
                    $classification.Type = "Failure"
                    $classification.Confidence = 0.8
                    $classification.Indicators += "Explicit Failure Flag"
                }
            }
        }
        
        # Analyze exit codes for process-based commands
        if ($CommandResult.ContainsKey('ExitCode')) {
            $exitCode = $CommandResult.ExitCode
            if ($exitCode -eq 0) {
                $classification.Type = "Success"
                $classification.Confidence = [math]::Max($classification.Confidence, 0.8)
                $classification.Indicators += "Exit Code 0"
            }
            elseif ($exitCode -eq 2) {
                $classification.Type = "Failure"
                $classification.Confidence = [math]::Max($classification.Confidence, 0.75)
                $classification.Indicators += "Exit Code 2 (Test Failure)"
            }
            elseif ($exitCode -lt 0 -or $exitCode -gt 100) {
                $classification.Type = "Exception"
                $classification.Confidence = [math]::Max($classification.Confidence, 0.8)
                $classification.Indicators += "Abnormal Exit Code: $exitCode"
            }
            else {
                $classification.Type = "Failure"
                $classification.Confidence = [math]::Max($classification.Confidence, 0.7)
                $classification.Indicators += "Non-Zero Exit Code: $exitCode"
            }
        }
        
        # Analyze output content for Unity-specific patterns
        if ($CommandResult.ContainsKey('Output') -and $CommandResult.Output) {
            $output = $CommandResult.Output.ToString()
            
            # Success patterns
            if ($output -match "Compilation succeeded|Tests passed|Build succeeded|Analysis completed") {
                $classification.Type = "Success"
                $classification.Confidence = [math]::Max($classification.Confidence, 0.85)
                $classification.Indicators += "Success Pattern in Output"
            }
            
            # Failure patterns
            elseif ($output -match "Compilation failed|Tests failed|Build failed|error CS\d+") {
                $classification.Type = "Failure"
                $classification.Confidence = [math]::Max($classification.Confidence, 0.8)
                $classification.Indicators += "Failure Pattern in Output"
            }
            
            # Exception patterns
            elseif ($output -match "Exception|NullReferenceException|ArgumentException|TimeoutException") {
                $classification.Type = "Exception"
                $classification.Confidence = [math]::Max($classification.Confidence, 0.9)
                $classification.Indicators += "Exception Pattern in Output"
            }
        }
        
        # Command type specific analysis
        switch ($CommandType) {
            'TEST' {
                if ($CommandResult.ContainsKey('TestResults')) {
                    $testResults = $CommandResult.TestResults
                    if ($testResults.ContainsKey('Passed') -and $testResults.ContainsKey('Failed')) {
                        if ($testResults.Failed -eq 0) {
                            $classification.Type = "Success"
                            $classification.Confidence = 0.95
                            $classification.Indicators += "All Tests Passed"
                        }
                        else {
                            $classification.Type = "Failure"
                            $classification.Confidence = 0.9
                            $classification.Indicators += "Some Tests Failed"
                        }
                    }
                }
            }
            'BUILD' {
                if ($CommandResult.ContainsKey('BuildOutput')) {
                    $buildOutput = $CommandResult.BuildOutput.ToString()
                    if ($buildOutput -match "Build succeeded") {
                        $classification.Type = "Success"
                        $classification.Confidence = 0.95
                        $classification.Indicators += "Build Success Message"
                    }
                    elseif ($buildOutput -match "Build failed") {
                        $classification.Type = "Failure"
                        $classification.Confidence = 0.9
                        $classification.Indicators += "Build Failure Message"
                    }
                }
            }
            'ANALYZE' {
                if ($CommandResult.ContainsKey('AnalysisResult')) {
                    $analysisResult = $CommandResult.AnalysisResult
                    if ($analysisResult.ContainsKey('Summary')) {
                        $summary = $analysisResult.Summary
                        if ($summary.ContainsKey('ErrorCount') -and $summary.ErrorCount -eq 0) {
                            $classification.Type = "Success"
                            $classification.Confidence = 0.9
                            $classification.Indicators += "No Errors Found"
                        }
                        elseif ($summary.ContainsKey('ErrorCount') -and $summary.ErrorCount -gt 0) {
                            $classification.Type = "Failure"
                            $classification.Confidence = 0.85
                            $classification.Indicators += "Errors Detected in Analysis"
                        }
                    }
                }
            }
        }
        
        # Default classification if no clear indicators
        if ($classification.Type -eq "Unknown") {
            $classification.Type = "Failure"
            $classification.Confidence = 0.5
            $classification.Indicators += "No Clear Success/Failure Indicators"
        }
        
        Write-AgentLog -Message "Classification completed: $($classification.Type) with confidence $($classification.Confidence)" -Level "DEBUG" -Component "ResultClassifier"
        
        return $classification
    }
    catch {
        Write-AgentLog -Message "Result classification failed: $_" -Level "ERROR" -Component "ResultClassifier"
        return @{
            Type = "Exception"
            Confidence = 1.0
            Indicators = @("Classification Process Exception")
            Metadata = @{ Error = $_.ToString() }
        }
    }
}

function Get-ResultSeverity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$CommandResult,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$Classification,
        
        [Parameter(Mandatory=$true)]
        [string]$CommandType
    )
    
    Write-AgentLog -Message "Determining result severity level" -Level "DEBUG" -Component "SeverityAnalyzer"
    
    try {
        $severity = @{
            Level = "Low"
            Priority = "Low"
            Confidence = 0.0
            Factors = @()
            Escalation = $false
        }
        
        # Base severity on classification type
        switch ($Classification.Type) {
            'Exception' {
                $severity.Level = "Critical"
                $severity.Priority = "High"
                $severity.Confidence = 0.9
                $severity.Factors += "Exception Classification"
                $severity.Escalation = $true
            }
            'Failure' {
                $severity.Level = "High"
                $severity.Priority = "Medium"
                $severity.Confidence = 0.8
                $severity.Factors += "Failure Classification"
            }
            'Success' {
                $severity.Level = "Low"
                $severity.Priority = "Low"
                $severity.Confidence = 0.9
                $severity.Factors += "Success Classification"
            }
        }
        
        # Adjust severity based on command type impact
        switch ($CommandType) {
            'TEST' {
                if ($CommandResult.ContainsKey('TestResults')) {
                    $testResults = $CommandResult.TestResults
                    if ($testResults.ContainsKey('Failed') -and $testResults.Failed -gt 0) {
                        $failureRate = $testResults.Failed / ($testResults.Passed + $testResults.Failed)
                        if ($failureRate -gt 0.5) {
                            $severity.Level = "Critical"
                            $severity.Priority = "High"
                            $severity.Factors += "High Test Failure Rate"
                            $severity.Escalation = $true
                        }
                        elseif ($failureRate -gt 0.2) {
                            $severity.Level = "High"
                            $severity.Priority = "Medium"
                            $severity.Factors += "Moderate Test Failure Rate"
                        }
                    }
                }
            }
            'BUILD' {
                if ($Classification.Type -eq "Failure") {
                    $severity.Level = "Critical"
                    $severity.Priority = "High"
                    $severity.Factors += "Build Failure Blocks Development"
                    $severity.Escalation = $true
                }
            }
            'ANALYZE' {
                if ($CommandResult.ContainsKey('AnalysisResult')) {
                    $analysisResult = $CommandResult.AnalysisResult
                    if ($analysisResult.ContainsKey('Summary')) {
                        $summary = $analysisResult.Summary
                        if ($summary.ContainsKey('ErrorCount') -and $summary.ErrorCount -gt 10) {
                            $severity.Level = "High"
                            $severity.Priority = "Medium"
                            $severity.Factors += "High Error Count in Analysis"
                        }
                    }
                }
            }
        }
        
        # Check for timeout indicators
        if ($CommandResult.ContainsKey('ErrorMessage') -and $CommandResult.ErrorMessage -match "timeout|timed out") {
            $severity.Level = "High"
            $severity.Priority = "Medium"
            $severity.Factors += "Operation Timeout"
        }
        
        # Check for security-related issues
        if ($CommandResult.ContainsKey('SecurityViolation') -and $CommandResult.SecurityViolation) {
            $severity.Level = "Critical"
            $severity.Priority = "High"
            $severity.Factors += "Security Violation Detected"
            $severity.Escalation = $true
        }
        
        # Calculate final confidence based on number of factors
        $severity.Confidence = [math]::Min(0.95, 0.6 + ($severity.Factors.Count * 0.1))
        
        Write-AgentLog -Message "Severity determined: $($severity.Level) (Priority: $($severity.Priority), Confidence: $($severity.Confidence))" -Level "INFO" -Component "SeverityAnalyzer"
        
        return $severity
    }
    catch {
        Write-AgentLog -Message "Severity analysis failed: $_" -Level "ERROR" -Component "SeverityAnalyzer"
        return @{
            Level = "High"
            Priority = "High"
            Confidence = 1.0
            Factors = @("Severity Analysis Exception")
            Escalation = $true
        }
    }
}

function Find-ResultPatterns {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$CommandResult,
        
        [Parameter(Mandatory=$true)]
        [string]$CommandType,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$Classification
    )
    
    Write-AgentLog -Message "Finding patterns in command result" -Level "DEBUG" -Component "PatternDetector"
    
    try {
        $patterns = @()
        
        # Pattern 1: Error patterns in output
        if ($CommandResult.ContainsKey('Output') -and $CommandResult.Output) {
            $output = $CommandResult.Output.ToString()
            
            # Unity compilation error patterns
            $unityErrorPatterns = @{
                'CS0246' = 'Type or namespace not found'
                'CS0103' = 'Name does not exist in current context'
                'CS1061' = 'Member not found on type'
                'CS0029' = 'Type conversion error'
            }
            
            foreach ($errorCode in $unityErrorPatterns.Keys) {
                if ($output -match "error $errorCode") {
                    $patterns += @{
                        Type = "CompilationError"
                        Code = $errorCode
                        Description = $unityErrorPatterns[$errorCode]
                        Frequency = ($output | Select-String -Pattern "error $errorCode" -AllMatches).Matches.Count
                        Confidence = 0.95
                    }
                }
            }
        }
        
        # Pattern 2: Performance patterns
        if ($CommandResult.ContainsKey('ExecutionTime')) {
            $executionTime = $CommandResult.ExecutionTime
            $performancePattern = @{
                Type = "Performance"
                ExecutionTime = $executionTime
                Confidence = 0.8
            }
            
            # Classify performance
            if ($executionTime -gt 300000) { # > 5 minutes
                $performancePattern.Classification = "Slow"
                $performancePattern.Severity = "High"
            }
            elseif ($executionTime -gt 60000) { # > 1 minute
                $performancePattern.Classification = "Moderate"
                $performancePattern.Severity = "Medium"
            }
            else {
                $performancePattern.Classification = "Fast"
                $performancePattern.Severity = "Low"
            }
            
            $patterns += $performancePattern
        }
        
        # Pattern 3: Historical pattern matching
        $historicalPatterns = Get-HistoricalPatterns -CommandType $CommandType -Classification $Classification.Type
        foreach ($historicalPattern in $historicalPatterns) {
            $config = Get-PromptEngineConfig
            if ($historicalPattern.Frequency -ge $config.ResultAnalysisConfig.PatternLearningThreshold) {
                $patterns += @{
                    Type = "Historical"
                    Pattern = $historicalPattern
                    Confidence = [math]::Min(0.9, $historicalPattern.Frequency / 10.0)
                }
            }
        }
        
        Write-AgentLog -Message "Found $($patterns.Count) patterns in result analysis" -Level "DEBUG" -Component "PatternDetector"
        
        return $patterns
    }
    catch {
        Write-AgentLog -Message "Pattern detection failed: $_" -Level "ERROR" -Component "PatternDetector"
        return @()
    }
}

function Get-HistoricalPatterns {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$CommandType,
        
        [Parameter(Mandatory=$true)]
        [string]$Classification
    )
    
    try {
        $patterns = @()
        $key = "$CommandType-$Classification"
        
        $config = Get-PromptEngineConfig  
        if ($config.PatternRegistry.ContainsKey($key)) {
            $registryEntry = $config.PatternRegistry[$key]
            $patterns = $registryEntry.Patterns
        }
        
        return $patterns
    }
    catch {
        Write-AgentLog -Message "Historical pattern retrieval failed: $_" -Level "WARNING" -Component "PatternDetector"
        return @()
    }
}

function Get-NextActionRecommendations {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Classification,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$Severity,
        
        [Parameter(Mandatory=$true)]
        [array]$Patterns,
        
        [Parameter(Mandatory=$true)]
        [string]$CommandType
    )
    
    Write-AgentLog -Message "Generating next action recommendations" -Level "DEBUG" -Component "ActionRecommender"
    
    try {
        $recommendations = @()
        
        # Base recommendations on classification and severity
        switch ($Classification.Type) {
            'Exception' {
                $recommendations += @{
                    Action = "Debugging"
                    Priority = "High"
                    Description = "Investigate exception cause and fix underlying issue"
                    Confidence = 0.9
                    PromptType = "Debugging"
                }
            }
            'Failure' {
                switch ($Severity.Level) {
                    'Critical' {
                        $recommendations += @{
                            Action = "Debugging"
                            Priority = "High"
                            Description = "Critical failure requires immediate debugging"
                            Confidence = 0.95
                            PromptType = "Debugging"
                        }
                    }
                    'High' {
                        $recommendations += @{
                            Action = "Test Results"
                            Priority = "Medium"
                            Description = "Analyze failure details and create action plan"
                            Confidence = 0.8
                            PromptType = "Test Results"
                        }
                    }
                    default {
                        $recommendations += @{
                            Action = "Continue"
                            Priority = "Low"
                            Description = "Minor failure, continue with workflow"
                            Confidence = 0.7
                            PromptType = "Continue"
                        }
                    }
                }
            }
            'Success' {
                $recommendations += @{
                    Action = "Continue"
                    Priority = "Low"
                    Description = "Operation successful, continue workflow"
                    Confidence = 0.9
                    PromptType = "Continue"
                }
            }
        }
        
        Write-AgentLog -Message "Generated $($recommendations.Count) action recommendations" -Level "DEBUG" -Component "ActionRecommender"
        
        return $recommendations
    }
    catch {
        Write-AgentLog -Message "Action recommendation generation failed: $_" -Level "ERROR" -Component "ActionRecommender"
        return @(@{
            Action = "Continue"
            Priority = "Medium"
            Description = "Default action due to recommendation failure"
            Confidence = 0.5
            PromptType = "Continue"
        })
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Invoke-CommandResultAnalysis',
    'Get-ResultClassification',
    'Get-ResultSeverity',
    'Find-ResultPatterns',
    'Get-HistoricalPatterns',
    'Get-NextActionRecommendations'
)

#endregion
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCs2JN9FxgYeXM0
# 2unI4AxQqT1wuEHzcEW9KOJDGY68YqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEINO2+ZXfTzjR0hT6jmL6/Lny
# +BBuHJEG8J8ibc0dDj9NMA0GCSqGSIb3DQEBAQUABIIBACr/RuwrxuCOqhOjMYRw
# NN/tGavDvILMk2zTsHcYieKIkNaTuOr1rfplOIIT/gOQ90yeeD5wZBVG67CnnRfJ
# 0YMTCWSkEQ4dNbj4NWz8C0poaiGBg3RIhyQJsXehYznyeUq42+3RD3bgl3lsV/0/
# hIJm96jMigqZ3c3gZ35cumqmt1eIXWIHfYQ/BR19FXDvBPFKrNzk0A0hcMtkEQPE
# ztyoX3v+jI5cYN1CACSaXqtMVYsrdCEa36X9IyxyWfgBR/t0Sq6N1ezFodOgHTpA
# Eps+YO4hJJcLUg6TzAimfW4M/bv0bsowUMjQDWkwsMdIpVJo5tARe4P6QlhYGUme
# 4F0=
# SIG # End signature block
