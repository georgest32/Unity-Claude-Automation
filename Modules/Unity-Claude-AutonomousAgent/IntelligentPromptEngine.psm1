# Phase 2 Day 8: Intelligent Prompt Generation Engine Module
# Advanced result analysis, prompt type selection, and template system
# Date: 2025-08-18

#region Module Configuration

$script:ModuleConfig = @{
    ResultAnalysisConfig = @{
        PatternLearningThreshold = 3  # Minimum occurrences for pattern establishment
        ConfidenceThreshold = 0.7     # Minimum confidence for automation decisions
        HistoryRetentionDays = 30     # Days to retain result history
        BaselineWindowSize = 10       # Number of results for baseline establishment
    }
    PromptTypeConfig = @{
        Types = @('Debugging', 'Test Results', 'Continue', 'ARP')
        DefaultType = 'Continue'
        ConfidenceThreshold = 0.8     # Minimum confidence for automatic selection
        FallbackType = 'Continue'     # Fallback when confidence is low
    }
    ConversationStateConfig = @{
        States = @('Idle', 'Processing', 'WaitingForInput', 'Error', 'Learning', 'Autonomous')
        DefaultState = 'Idle'
        TransitionTimeout = 300       # Seconds before state timeout
        ContextRetentionLimit = 50    # Maximum context items to retain
    }
    SeverityConfig = @{
        Levels = @('Critical', 'High', 'Medium', 'Low')
        CriticalThreshold = 0.9       # Confidence threshold for critical classification
        AutomationThresholds = @{     # Minimum confidence for automated handling
            Critical = 0.95
            High = 0.85
            Medium = 0.75
            Low = 0.65
        }
    }
}

# Thread-safe collections for result tracking
$script:ResultHistory = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()
$script:PatternRegistry = [System.Collections.Concurrent.ConcurrentDictionary[string,object]]::new()
$script:ConversationContext = [System.Collections.Concurrent.ConcurrentDictionary[string,object]]::new()

#endregion

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
        
        $script:ResultHistory.Enqueue($learningData)
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
        
        # Pattern 3: Resource usage patterns
        if ($CommandResult.ContainsKey('ResourceUsage')) {
            $resourceUsage = $CommandResult.ResourceUsage
            if ($resourceUsage.ContainsKey('Memory') -and $resourceUsage.Memory -gt 1GB) {
                $patterns += @{
                    Type = "HighMemoryUsage"
                    MemoryUsage = $resourceUsage.Memory
                    Severity = "Medium"
                    Confidence = 0.8
                }
            }
        }
        
        # Pattern 4: Historical pattern matching
        $historicalPatterns = Get-HistoricalPatterns -CommandType $CommandType -Classification $Classification.Type
        foreach ($historicalPattern in $historicalPatterns) {
            if ($historicalPattern.Frequency -ge $script:ModuleConfig.ResultAnalysisConfig.PatternLearningThreshold) {
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
        
        if ($script:PatternRegistry.ContainsKey($key)) {
            $registryEntry = $script:PatternRegistry[$key]
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
        
        # Add pattern-specific recommendations
        foreach ($pattern in $Patterns) {
            switch ($pattern.Type) {
                'CompilationError' {
                    $recommendations += @{
                        Action = "ARP"
                        Priority = "Medium"
                        Description = "Research and plan compilation error resolution for $($pattern.Code)"
                        Confidence = 0.8
                        PromptType = "ARP"
                        Context = @{ ErrorCode = $pattern.Code; Description = $pattern.Description }
                    }
                }
                'Performance' {
                    if ($pattern.Classification -eq "Slow") {
                        $recommendations += @{
                            Action = "ARP"
                            Priority = "Medium"
                            Description = "Research performance optimization strategies"
                            Confidence = 0.75
                            PromptType = "ARP"
                            Context = @{ PerformanceIssue = $pattern.Classification; ExecutionTime = $pattern.ExecutionTime }
                        }
                    }
                }
            }
        }
        
        # Sort recommendations by priority and confidence
        $recommendations = $recommendations | Sort-Object { 
            switch ($_.Priority) {
                'High' { 3 }
                'Medium' { 2 }
                'Low' { 1 }
                default { 0 }
            }
        }, { $_.Confidence } -Descending
        
        Write-AgentLog -Message "Generated $($recommendations.Count) action recommendations" -Level "DEBUG" -Component "ActionRecommender"
        
        return $recommendations
    }
    catch {
        Write-AgentLog -Message "Action recommendation generation failed: $_" -Level "ERROR" -Component "ActionRecommender"
        return @()
    }
}

#endregion

#region Prompt Type Selection Logic

function Invoke-PromptTypeSelection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$ResultAnalysis,
        
        [Parameter()]
        [hashtable]$ConversationContext = @{},
        
        [Parameter()]
        [hashtable]$HistoricalData = @{}
    )
    
    Write-AgentLog -Message "Starting intelligent prompt type selection" -Level "DEBUG" -Component "PromptSelector"
    
    try {
        $selection = @{
            PromptType = $script:ModuleConfig.PromptTypeConfig.DefaultType
            Confidence = 0.0
            DecisionFactors = @()
            FallbackUsed = $false
            DecisionTree = @{}
        }
        
        # Decision tree implementation with rule-based logic
        $decisionTree = New-PromptTypeDecisionTree -ResultAnalysis $ResultAnalysis -Context $ConversationContext
        $selection.DecisionTree = $decisionTree
        
        Write-AgentLog -Message "Decision tree created with $($decisionTree.Nodes.Count) decision nodes" -Level "DEBUG" -Component "PromptSelector"
        
        # Apply decision tree logic
        $decision = Invoke-DecisionTreeAnalysis -DecisionTree $decisionTree -ResultAnalysis $ResultAnalysis
        $selection.PromptType = $decision.PromptType
        $selection.Confidence = $decision.Confidence
        $selection.DecisionFactors = $decision.Factors
        
        # Validate confidence threshold
        if ($selection.Confidence -lt $script:ModuleConfig.PromptTypeConfig.ConfidenceThreshold) {
            Write-AgentLog -Message "Confidence $($selection.Confidence) below threshold, using fallback" -Level "WARNING" -Component "PromptSelector"
            $selection.PromptType = $script:ModuleConfig.PromptTypeConfig.FallbackType
            $selection.FallbackUsed = $true
            $selection.Confidence = 0.6  # Assign moderate confidence to fallback
        }
        
        Write-AgentLog -Message "Prompt type selected: $($selection.PromptType) with confidence: $($selection.Confidence)" -Level "INFO" -Component "PromptSelector"
        
        return @{
            Success = $true
            Selection = $selection
            Error = $null
        }
    }
    catch {
        Write-AgentLog -Message "Prompt type selection failed: $_" -Level "ERROR" -Component "PromptSelector"
        return @{
            Success = $false
            Selection = @{
                PromptType = $script:ModuleConfig.PromptTypeConfig.FallbackType
                Confidence = 0.5
                DecisionFactors = @("Selection Process Exception")
                FallbackUsed = $true
            }
            Error = $_.ToString()
        }
    }
}

function New-PromptTypeDecisionTree {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$ResultAnalysis,
        
        [Parameter()]
        [hashtable]$Context = @{}
    )
    
    Write-AgentLog -Message "Creating prompt type decision tree" -Level "DEBUG" -Component "DecisionTreeBuilder"
    
    try {
        $decisionTree = @{
            Nodes = @()
            Rules = @()
            Metadata = @{
                CreatedAt = Get-Date
                Version = "1.0"
            }
        }
        
        # Root decision node: Classification type
        $classificationNode = @{
            NodeId = "root_classification"
            Question = "What is the result classification?"
            Type = "Classification"
            Branches = @{
                "Exception" = @{
                    PromptType = "Debugging"
                    Confidence = 0.95
                    Reason = "Exceptions require immediate debugging"
                }
                "Failure" = @{
                    NextNode = "severity_assessment"
                    Reason = "Failures need severity-based routing"
                }
                "Success" = @{
                    NextNode = "continuation_check"
                    Reason = "Success should continue workflow"
                }
            }
        }
        
        # Severity assessment node for failures
        $severityNode = @{
            NodeId = "severity_assessment"
            Question = "What is the failure severity?"
            Type = "Severity"
            Branches = @{
                "Critical" = @{
                    PromptType = "Debugging"
                    Confidence = 0.9
                    Reason = "Critical failures need immediate debugging"
                }
                "High" = @{
                    NextNode = "error_pattern_check"
                    Reason = "High severity needs pattern analysis"
                }
                "Medium" = @{
                    PromptType = "Test Results"
                    Confidence = 0.75
                    Reason = "Medium severity suitable for test results analysis"
                }
                "Low" = @{
                    PromptType = "Continue"
                    Confidence = 0.8
                    Reason = "Low severity can continue with monitoring"
                }
            }
        }
        
        # Error pattern check for high severity failures
        $errorPatternNode = @{
            NodeId = "error_pattern_check"
            Question = "Are there known error patterns?"
            Type = "ErrorPattern"
            Branches = @{
                "CompilationError" = @{
                    PromptType = "ARP"
                    Confidence = 0.85
                    Reason = "Compilation errors need research and planning"
                }
                "TestFailure" = @{
                    PromptType = "Test Results"
                    Confidence = 0.8
                    Reason = "Test failures need result analysis"
                }
                "BuildError" = @{
                    PromptType = "Debugging"
                    Confidence = 0.85
                    Reason = "Build errors need immediate debugging"
                }
                "Unknown" = @{
                    NextNode = "context_analysis"
                    Reason = "Unknown patterns need context analysis"
                }
            }
        }
        
        # Continuation check for successful operations
        $continuationNode = @{
            NodeId = "continuation_check"
            Question = "Should workflow continue automatically?"
            Type = "Continuation"
            Branches = @{
                "AutoContinue" = @{
                    PromptType = "Continue"
                    Confidence = 0.9
                    Reason = "Successful operations continue workflow"
                }
                "RequiresInput" = @{
                    PromptType = "Test Results"
                    Confidence = 0.7
                    Reason = "Success requiring input needs result review"
                }
            }
        }
        
        # Context analysis for complex scenarios
        $contextNode = @{
            NodeId = "context_analysis"
            Question = "What does conversation context suggest?"
            Type = "Context"
            Branches = @{
                "OngoingDebug" = @{
                    PromptType = "Debugging"
                    Confidence = 0.8
                    Reason = "Continue ongoing debugging session"
                }
                "TestSequence" = @{
                    PromptType = "Test Results"
                    Confidence = 0.75
                    Reason = "Continue test sequence analysis"
                }
                "PlanningPhase" = @{
                    PromptType = "ARP"
                    Confidence = 0.7
                    Reason = "Continue planning and research"
                }
                "Default" = @{
                    PromptType = "Continue"
                    Confidence = 0.6
                    Reason = "Default continuation when context unclear"
                }
            }
        }
        
        # Add nodes to decision tree
        $decisionTree.Nodes = @(
            $classificationNode,
            $severityNode,
            $errorPatternNode,
            $continuationNode,
            $contextNode
        )
        
        Write-AgentLog -Message "Decision tree created with $($decisionTree.Nodes.Count) nodes" -Level "DEBUG" -Component "DecisionTreeBuilder"
        
        return $decisionTree
    }
    catch {
        Write-AgentLog -Message "Decision tree creation failed: $_" -Level "ERROR" -Component "DecisionTreeBuilder"
        return @{
            Nodes = @()
            Rules = @()
            Metadata = @{ Error = $_.ToString() }
        }
    }
}

function Invoke-DecisionTreeAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$DecisionTree,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$ResultAnalysis
    )
    
    Write-AgentLog -Message "Executing decision tree analysis" -Level "DEBUG" -Component "DecisionTreeAnalyzer"
    
    try {
        $result = @{
            PromptType = $script:ModuleConfig.PromptTypeConfig.DefaultType
            Confidence = 0.5
            Factors = @()
            Path = @()
        }
        
        # Start at root node
        $currentNodeId = "root_classification"
        $maxDepth = 10  # Prevent infinite loops
        $depth = 0
        
        while ($currentNodeId -and $depth -lt $maxDepth) {
            $depth++
            $currentNode = $DecisionTree.Nodes | Where-Object { $_.NodeId -eq $currentNodeId }
            
            if (-not $currentNode) {
                Write-AgentLog -Message "Node not found: $currentNodeId" -Level "WARNING" -Component "DecisionTreeAnalyzer"
                break
            }
            
            $result.Path += $currentNodeId
            Write-AgentLog -Message "Analyzing node: $currentNodeId" -Level "DEBUG" -Component "DecisionTreeAnalyzer"
            
            # Evaluate node based on type
            $nodeResult = Invoke-NodeEvaluation -Node $currentNode -ResultAnalysis $ResultAnalysis
            
            if ($nodeResult.PromptType) {
                # Terminal node reached
                $result.PromptType = $nodeResult.PromptType
                $result.Confidence = $nodeResult.Confidence
                $result.Factors += $nodeResult.Reason
                break
            }
            elseif ($nodeResult.NextNode) {
                # Continue to next node
                $currentNodeId = $nodeResult.NextNode
                $result.Factors += $nodeResult.Reason
            }
            else {
                # No clear path, use default
                break
            }
        }
        
        Write-AgentLog -Message "Decision tree analysis completed: $($result.PromptType) (Confidence: $($result.Confidence))" -Level "DEBUG" -Component "DecisionTreeAnalyzer"
        
        return $result
    }
    catch {
        Write-AgentLog -Message "Decision tree analysis failed: $_" -Level "ERROR" -Component "DecisionTreeAnalyzer"
        return @{
            PromptType = $script:ModuleConfig.PromptTypeConfig.FallbackType
            Confidence = 0.5
            Factors = @("Decision Tree Analysis Exception")
            Path = @()
        }
    }
}

function Invoke-NodeEvaluation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Node,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$ResultAnalysis
    )
    
    try {
        switch ($Node.Type) {
            'Classification' {
                $classification = $ResultAnalysis.Classification
                if ($Node.Branches.ContainsKey($classification)) {
                    return $Node.Branches[$classification]
                }
            }
            'Severity' {
                $severity = $ResultAnalysis.Severity
                if ($Node.Branches.ContainsKey($severity)) {
                    return $Node.Branches[$severity]
                }
            }
            'ErrorPattern' {
                $patterns = $ResultAnalysis.Patterns
                foreach ($pattern in $patterns) {
                    if ($Node.Branches.ContainsKey($pattern.Type)) {
                        return $Node.Branches[$pattern.Type]
                    }
                }
                # Default to Unknown if no pattern matches
                if ($Node.Branches.ContainsKey("Unknown")) {
                    return $Node.Branches["Unknown"]
                }
            }
            'Continuation' {
                # Simple heuristic for continuation decision
                if ($ResultAnalysis.Classification -eq "Success" -and $ResultAnalysis.Severity -eq "Low") {
                    return $Node.Branches["AutoContinue"]
                }
                else {
                    return $Node.Branches["RequiresInput"]
                }
            }
            'Context' {
                # Context analysis would examine conversation history
                # For now, use default
                return $Node.Branches["Default"]
            }
        }
        
        # If no branch matches, return null to continue search
        return @{}
    }
    catch {
        Write-AgentLog -Message "Node evaluation failed: $_" -Level "WARNING" -Component "DecisionTreeAnalyzer"
        return @{}
    }
}

#endregion

#region Prompt Template System

function New-PromptTemplate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$PromptType,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$Context,
        
        [Parameter()]
        [hashtable]$ResultAnalysis = @{},
        
        [Parameter()]
        [string]$TemplateVersion = "1.0"
    )
    
    Write-AgentLog -Message "Creating prompt template for type: $PromptType" -Level "DEBUG" -Component "TemplateEngine"
    
    try {
        # Get base template for prompt type
        $baseTemplate = Get-BasePromptTemplate -PromptType $PromptType
        
        # Create template context with variable substitution
        $templateContext = @{
            PromptType = $PromptType
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Version = $TemplateVersion
            Context = $Context
            ResultAnalysis = $ResultAnalysis
            Variables = @{}
        }
        
        # Add type-specific variables
        $typeSpecificVars = Get-TypeSpecificVariables -PromptType $PromptType -Context $Context -ResultAnalysis $ResultAnalysis
        $templateContext.Variables = $typeSpecificVars
        
        # Render template with variable substitution
        $renderedPrompt = Invoke-TemplateRendering -BaseTemplate $baseTemplate -Context $templateContext
        
        Write-AgentLog -Message "Prompt template created successfully (Length: $($renderedPrompt.Length) characters)" -Level "DEBUG" -Component "TemplateEngine"
        
        return @{
            Success = $true
            Prompt = $renderedPrompt
            Template = $baseTemplate
            Context = $templateContext
            Error = $null
        }
    }
    catch {
        Write-AgentLog -Message "Prompt template creation failed: $_" -Level "ERROR" -Component "TemplateEngine"
        return @{
            Success = $false
            Prompt = ""
            Template = @{}
            Context = @{}
            Error = $_.ToString()
        }
    }
}

function Get-BasePromptTemplate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$PromptType
    )
    
    $templates = @{
        'Debugging' = @{
            Header = "DEBUGGING SESSION - {{timestamp}}"
            Introduction = "I encountered an issue that requires debugging assistance. Please analyze the problem and provide a systematic debugging approach."
            Context = @{
                Required = @("ErrorDetails", "CommandType", "ResultAnalysis")
                Optional = @("StackTrace", "Environment", "RecentChanges")
            }
            Sections = @{
                "Problem Description" = "{{errorDescription}}"
                "Error Details" = "{{errorDetails}}"
                "Context Information" = "{{contextInfo}}"
                "Previous Attempts" = "{{previousAttempts}}"
                "Environment" = "{{environment}}"
            }
            Footer = "Please provide a step-by-step debugging approach and potential solutions."
            Template = @"
# DEBUGGING SESSION - {{timestamp}}

I encountered an issue that requires debugging assistance. Please analyze the problem and provide a systematic debugging approach.

## Problem Description
{{errorDescription}}

## Error Details
{{errorDetails}}

## Context Information
{{contextInfo}}

## Previous Attempts
{{previousAttempts}}

## Environment
{{environment}}

Please provide a step-by-step debugging approach and potential solutions.
"@
        }
        
        'Test Results' = @{
            Header = "TEST RESULTS ANALYSIS - {{timestamp}}"
            Introduction = "I have completed test execution and need analysis of the results to determine next steps."
            Context = @{
                Required = @("TestResults", "CommandType", "ResultAnalysis")
                Optional = @("TestConfiguration", "Environment", "ComparisonData")
            }
            Sections = @{
                "Test Summary" = "{{testSummary}}"
                "Results Analysis" = "{{resultsAnalysis}}"
                "Performance Metrics" = "{{performanceMetrics}}"
                "Failure Analysis" = "{{failureAnalysis}}"
                "Next Steps" = "{{nextSteps}}"
            }
            Footer = "Please analyze these test results and recommend next actions."
            Template = @"
# TEST RESULTS ANALYSIS - {{timestamp}}

I have completed test execution and need analysis of the results to determine next steps.

## Test Summary
{{testSummary}}

## Results Analysis
{{resultsAnalysis}}

## Performance Metrics
{{performanceMetrics}}

## Failure Analysis
{{failureAnalysis}}

## Environment
{{environment}}

Please analyze these test results and recommend next actions.
"@
        }
        
        'Continue' = @{
            Header = "WORKFLOW CONTINUATION - {{timestamp}}"
            Introduction = "Previous operation completed. Continuing with the automation workflow based on results."
            Context = @{
                Required = @("PreviousResults", "WorkflowState")
                Optional = @("NextSteps", "Configuration", "Metrics")
            }
            Sections = @{
                "Previous Operation" = "{{previousOperation}}"
                "Results Summary" = "{{resultsSummary}}"
                "Current State" = "{{currentState}}"
                "Next Actions" = "{{nextActions}}"
            }
            Footer = "Please continue with the next appropriate step in the workflow."
            Template = @"
# WORKFLOW CONTINUATION - {{timestamp}}

Previous operation completed. Continuing with the automation workflow based on results.

## Previous Operation
{{previousOperation}}

## Results Summary
{{resultsSummary}}

## Current State
{{currentState}}

## Next Actions
{{nextActions}}

Please continue with the next appropriate step in the workflow.
"@
        }
        
        'ARP' = @{
            Header = "ANALYSIS, RESEARCH, AND PLANNING - {{timestamp}}"
            Introduction = "I need comprehensive analysis, research, and planning for the following topic or issue."
            Context = @{
                Required = @("Topic", "Goals", "Context")
                Optional = @("Constraints", "Requirements", "Timeline")
            }
            Sections = @{
                "Topic Overview" = "{{topicOverview}}"
                "Goals and Objectives" = "{{goalsObjectives}}"
                "Current Context" = "{{currentContext}}"
                "Constraints" = "{{constraints}}"
                "Research Areas" = "{{researchAreas}}"
            }
            Footer = "Please provide comprehensive analysis, research, and create a detailed implementation plan."
            Template = @"
# ANALYSIS, RESEARCH, AND PLANNING - {{timestamp}}

I need comprehensive analysis, research, and planning for the following topic or issue.

## Topic Overview
{{topicOverview}}

## Goals and Objectives
{{goalsObjectives}}

## Current Context
{{currentContext}}

## Constraints
{{constraints}}

## Research Areas
{{researchAreas}}

Please provide comprehensive analysis, research, and create a detailed implementation plan.
"@
        }
    }
    
    return $templates[$PromptType]
}

function Get-TypeSpecificVariables {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$PromptType,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$Context,
        
        [Parameter()]
        [hashtable]$ResultAnalysis = @{}
    )
    
    $variables = @{
        "timestamp" = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "promptType" = $PromptType
    }
    
    switch ($PromptType) {
        'Debugging' {
            $variables["errorDescription"] = if ($Context.ContainsKey('ErrorDescription')) { $Context.ErrorDescription } else { "Error description not provided" }
            $variables["errorDetails"] = if ($ResultAnalysis.ContainsKey('Classification')) { 
                "Classification: $($ResultAnalysis.Classification), Severity: $($ResultAnalysis.Severity)" 
            } else { 
                "Error details not available" 
            }
            $variables["contextInfo"] = if ($Context.ContainsKey('ContextInfo')) { $Context.ContextInfo } else { "Context information not provided" }
            $variables["previousAttempts"] = if ($Context.ContainsKey('PreviousAttempts')) { $Context.PreviousAttempts } else { "No previous attempts recorded" }
            $variables["environment"] = if ($Context.ContainsKey('Environment')) { $Context.Environment } else { "Unity 2021.1.14f1, PowerShell 5.1" }
        }
        'Test Results' {
            $variables["testSummary"] = if ($Context.ContainsKey('TestSummary')) { $Context.TestSummary } else { "Test summary not provided" }
            $variables["resultsAnalysis"] = if ($ResultAnalysis.ContainsKey('Classification')) { 
                "Result: $($ResultAnalysis.Classification), Confidence: $($ResultAnalysis.Confidence)" 
            } else { 
                "Results analysis not available" 
            }
            $variables["performanceMetrics"] = if ($Context.ContainsKey('PerformanceMetrics')) { $Context.PerformanceMetrics } else { "Performance metrics not provided" }
            $variables["failureAnalysis"] = if ($ResultAnalysis.ContainsKey('Patterns')) { 
                "Patterns found: $($ResultAnalysis.Patterns.Count)" 
            } else { 
                "No failure patterns detected" 
            }
            $variables["environment"] = "Unity 2021.1.14f1, PowerShell 5.1"
        }
        'Continue' {
            $variables["previousOperation"] = if ($Context.ContainsKey('PreviousOperation')) { $Context.PreviousOperation } else { "Previous operation not specified" }
            $variables["resultsSummary"] = if ($ResultAnalysis.ContainsKey('Classification')) { 
                "Result: $($ResultAnalysis.Classification), Severity: $($ResultAnalysis.Severity)" 
            } else { 
                "Results summary not available" 
            }
            $variables["currentState"] = if ($Context.ContainsKey('CurrentState')) { $Context.CurrentState } else { "Current state not specified" }
            $variables["nextActions"] = if ($ResultAnalysis.ContainsKey('NextActions')) { 
                ($ResultAnalysis.NextActions | ForEach-Object { "- $($_.Description)" }) -join "`n" 
            } else { 
                "Next actions to be determined" 
            }
        }
        'ARP' {
            $variables["topicOverview"] = if ($Context.ContainsKey('Topic')) { $Context.Topic } else { "Topic not specified" }
            $variables["goalsObjectives"] = if ($Context.ContainsKey('Goals')) { $Context.Goals } else { "Goals and objectives not specified" }
            $variables["currentContext"] = if ($Context.ContainsKey('CurrentContext')) { $Context.CurrentContext } else { "Current context not provided" }
            $variables["constraints"] = if ($Context.ContainsKey('Constraints')) { $Context.Constraints } else { "No constraints specified" }
            $variables["researchAreas"] = if ($Context.ContainsKey('ResearchAreas')) { $Context.ResearchAreas } else { "Research areas to be determined" }
        }
    }
    
    return $variables
}

function Invoke-TemplateRendering {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$BaseTemplate,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$Context
    )
    
    try {
        $template = $BaseTemplate.Template
        $variables = $Context.Variables
        
        # Perform variable substitution
        foreach ($variable in $variables.GetEnumerator()) {
            $placeholder = "{{$($variable.Key)}}"
            $value = $variable.Value
            $template = $template -replace [regex]::Escape($placeholder), $value
        }
        
        # Clean up any remaining unsubstituted placeholders
        $template = $template -replace '\{\{[^}]+\}\}', '[Variable not provided]'
        
        return $template
    }
    catch {
        Write-AgentLog -Message "Template rendering failed: $_" -Level "ERROR" -Component "TemplateEngine"
        return "Template rendering failed: $_"
    }
}

#endregion

# Export module members
Export-ModuleMember -Function @(
    # Result Analysis Framework
    'Invoke-CommandResultAnalysis',
    'Get-ResultClassification',
    'Get-ResultSeverity',
    'Find-ResultPatterns',
    'Get-HistoricalPatterns',
    'Get-NextActionRecommendations',
    
    # Prompt Type Selection Logic
    'Invoke-PromptTypeSelection',
    'New-PromptTypeDecisionTree',
    'Invoke-DecisionTreeAnalysis',
    'Invoke-NodeEvaluation',
    
    # Prompt Template System
    'New-PromptTemplate',
    'Get-BasePromptTemplate',
    'Get-TypeSpecificVariables',
    'Invoke-TemplateRendering'
)

# Module initialization logging (Write-AgentLog may not be available at module load time)
if (Get-Command Write-AgentLog -ErrorAction SilentlyContinue) {
    Write-AgentLog -Message "IntelligentPromptEngine module loaded successfully" -Level "INFO" -Component "ModuleLoader"
} else {
    Write-Verbose "IntelligentPromptEngine module loaded successfully"
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUhHX0vdIUjGnUZ16PRGWrHhsJ
# UNmgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUTJV1Ev3Ik5pAx3pG5SrItY1ZBZcwDQYJKoZIhvcNAQEBBQAEggEAn3dk
# bQMwYl03D1amLPfsrnKtzeGQyji7cWbHTZx0vS0/MJkyF4Dv7boZIxsV7yd/s70H
# ES4kCNCuwiznuHsUrdgiPScXH9BRX8kZNiM1ApPGXcbdhHXim+IIS/CkZJRGxWlr
# KcWUWAUrhFR8gmTytGvW7lT5gRwfqGjrfczlSutea724bpn5X3T05Y0HUQCLT+X+
# 6gjb/gj4eDQZv9/V1f2Z5JZjqSLCvXCWslDIGNlWPObtP9TSQju0t1lb1NWH33+z
# stonBI7BWLmA8UAskhAaKMpohPQAjusR+KXuz0YqyWLeZqdgR9whAH1Jc0N5uJYc
# zHix/DN2za1X2d8WZA==
# SIG # End signature block
