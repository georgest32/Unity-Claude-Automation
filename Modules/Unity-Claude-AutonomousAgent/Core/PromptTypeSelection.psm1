# PromptTypeSelection.psm1
# Prompt type selection logic with decision tree analysis
# Refactored component from IntelligentPromptEngine.psm1
# Component: Prompt type selection logic (400 lines)

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
        $config = Get-PromptEngineConfig
        $selection = @{
            PromptType = $config.PromptTypeConfig.DefaultType
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
        if ($selection.Confidence -lt $config.PromptTypeConfig.ConfidenceThreshold) {
            Write-AgentLog -Message "Confidence $($selection.Confidence) below threshold, using fallback" -Level "WARNING" -Component "PromptSelector"
            $selection.PromptType = $config.PromptTypeConfig.FallbackType
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
                PromptType = $config.PromptTypeConfig.FallbackType
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
        $config = Get-PromptEngineConfig
        $result = @{
            PromptType = $config.PromptTypeConfig.DefaultType
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
            
            $result.Path += $currentNode.NodeId
            Write-AgentLog -Message "Processing node: $($currentNode.NodeId)" -Level "DEBUG" -Component "DecisionTreeAnalyzer"
            
            # Evaluate current node
            $nodeResult = Invoke-NodeEvaluation -Node $currentNode -ResultAnalysis $ResultAnalysis
            
            if ($nodeResult.FinalDecision) {
                # Node returned a final decision
                $result.PromptType = $nodeResult.PromptType
                $result.Confidence = $nodeResult.Confidence
                $result.Factors += $nodeResult.Reason
                break
            }
            else {
                # Continue to next node
                $currentNodeId = $nodeResult.NextNode
                $result.Factors += $nodeResult.Reason
            }
        }
        
        if ($depth -eq $maxDepth) {
            Write-AgentLog -Message "Decision tree depth limit reached, using default" -Level "WARNING" -Component "DecisionTreeAnalyzer"
            $result.PromptType = $config.PromptTypeConfig.DefaultType
            $result.Confidence = 0.5
        }
        
        Write-AgentLog -Message "Decision tree analysis completed: $($result.PromptType) with confidence $($result.Confidence)" -Level "DEBUG" -Component "DecisionTreeAnalyzer"
        
        return $result
    }
    catch {
        Write-AgentLog -Message "Decision tree analysis failed: $_" -Level "ERROR" -Component "DecisionTreeAnalyzer"
        return @{
            PromptType = $config.PromptTypeConfig.DefaultType
            Confidence = 0.3
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
        Write-AgentLog -Message "Evaluating node: $($Node.NodeId) of type: $($Node.Type)" -Level "DEBUG" -Component "NodeEvaluator"
        
        $evaluation = @{
            FinalDecision = $false
            PromptType = $null
            Confidence = 0.0
            Reason = $null
            NextNode = $null
        }
        
        # Evaluate based on node type
        switch ($Node.Type) {
            'Classification' {
                $classification = $ResultAnalysis.Analysis.Classification
                if ($Node.Branches.ContainsKey($classification)) {
                    $branch = $Node.Branches[$classification]
                    if ($branch.ContainsKey('PromptType')) {
                        $evaluation.FinalDecision = $true
                        $evaluation.PromptType = $branch.PromptType
                        $evaluation.Confidence = $branch.Confidence
                        $evaluation.Reason = $branch.Reason
                    }
                    else {
                        $evaluation.NextNode = $branch.NextNode
                        $evaluation.Reason = $branch.Reason
                    }
                }
            }
            
            'Severity' {
                $severity = $ResultAnalysis.Analysis.Severity
                if ($Node.Branches.ContainsKey($severity)) {
                    $branch = $Node.Branches[$severity]
                    if ($branch.ContainsKey('PromptType')) {
                        $evaluation.FinalDecision = $true
                        $evaluation.PromptType = $branch.PromptType
                        $evaluation.Confidence = $branch.Confidence
                        $evaluation.Reason = $branch.Reason
                    }
                    else {
                        $evaluation.NextNode = $branch.NextNode
                        $evaluation.Reason = $branch.Reason
                    }
                }
            }
            
            'ErrorPattern' {
                $patterns = $ResultAnalysis.Analysis.Patterns
                $errorPattern = $patterns | Where-Object { $_.Type -eq "CompilationError" } | Select-Object -First 1
                
                $patternType = if ($errorPattern) { "CompilationError" } 
                              elseif ($patterns | Where-Object { $_.Type -eq "Performance" }) { "Performance" }
                              else { "Unknown" }
                
                if ($Node.Branches.ContainsKey($patternType)) {
                    $branch = $Node.Branches[$patternType]
                    if ($branch.ContainsKey('PromptType')) {
                        $evaluation.FinalDecision = $true
                        $evaluation.PromptType = $branch.PromptType
                        $evaluation.Confidence = $branch.Confidence
                        $evaluation.Reason = $branch.Reason
                    }
                    else {
                        $evaluation.NextNode = $branch.NextNode
                        $evaluation.Reason = $branch.Reason
                    }
                }
            }
            
            'Continuation' {
                # Simple heuristic: successful operations should continue
                $continuationType = if ($ResultAnalysis.Analysis.Classification -eq "Success") { "AutoContinue" } else { "RequiresInput" }
                
                if ($Node.Branches.ContainsKey($continuationType)) {
                    $branch = $Node.Branches[$continuationType]
                    $evaluation.FinalDecision = $true
                    $evaluation.PromptType = $branch.PromptType
                    $evaluation.Confidence = $branch.Confidence
                    $evaluation.Reason = $branch.Reason
                }
            }
            
            'Context' {
                # Default to continue for now - more sophisticated context analysis could be added
                $contextType = "Default"
                
                if ($Node.Branches.ContainsKey($contextType)) {
                    $branch = $Node.Branches[$contextType]
                    $evaluation.FinalDecision = $true
                    $evaluation.PromptType = $branch.PromptType
                    $evaluation.Confidence = $branch.Confidence
                    $evaluation.Reason = $branch.Reason
                }
            }
            
            default {
                Write-AgentLog -Message "Unknown node type: $($Node.Type)" -Level "WARNING" -Component "NodeEvaluator"
                $evaluation.FinalDecision = $true
                $config = Get-PromptEngineConfig
                $evaluation.PromptType = $config.PromptTypeConfig.DefaultType
                $evaluation.Confidence = 0.5
                $evaluation.Reason = "Unknown node type, using default"
            }
        }
        
        Write-AgentLog -Message "Node evaluation completed: Final=$($evaluation.FinalDecision), Type=$($evaluation.PromptType)" -Level "DEBUG" -Component "NodeEvaluator"
        
        return $evaluation
    }
    catch {
        Write-AgentLog -Message "Node evaluation failed: $_" -Level "ERROR" -Component "NodeEvaluator"
        $config = Get-PromptEngineConfig
        return @{
            FinalDecision = $true
            PromptType = $config.PromptTypeConfig.DefaultType
            Confidence = 0.3
            Reason = "Node evaluation exception"
            NextNode = $null
        }
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Invoke-PromptTypeSelection',
    'New-PromptTypeDecisionTree',
    'Invoke-DecisionTreeAnalysis',
    'Invoke-NodeEvaluation'
)

#endregion
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBciUR5lWBR1zkt
# 1E3O+uImSzav0ZsqKxL+p6zvN7pQYqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIA/PSFFZcI5Bn0Nc6Ily+Fgh
# q9YvXgMKo62RUzvzFLb2MA0GCSqGSIb3DQEBAQUABIIBAJJolmSZnRHWMgKubD5n
# sBYcifhPXgqrnGgKw7ZonIY3ALH9DB0ZVjgD5nkf0U/P19iqa3eO6ud8hHhlgbH7
# Demqubkz2VUpBghMz9TYxIW/Vv1MM5HKIpDqrvUfyIWl3Ubd0MQpKZ6NuWjHd34U
# cESm0DVAfiqkUTCqxCJmE2P8VmKVXrPoGaF2Yor0BQwRgSgXONtXGOLeA1Q47k2y
# Gx3W9NhdecuC037don37omP0BIonE9CO56YyINrcG9CUqeH62PuzdyFK+yR6uI+F
# wabbdZYZ8zL1iaufzp/5UaXd6deFIiCb7D0cb4cb8TFso7zosdH4sd5jhtyOKF3U
# ufo=
# SIG # End signature block
