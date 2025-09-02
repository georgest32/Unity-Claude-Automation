function Test-CLIOrchestratorComponents {
    <#
    .SYNOPSIS
        Tests health of all CLI orchestrator components
    .DESCRIPTION
        Performs health checks on all system components including new refactored
        components and existing Core components
    .EXAMPLE
        Test-CLIOrchestratorComponents
    #>
    [CmdletBinding()]
    param()
    
    try {
        $healthResults = @{
            Overall = 'Healthy'
            TestedAt = Get-Date
            Components = @()
        }
        
        # Test WindowManager component
        try {
            $claudeWindow = Find-ClaudeWindow
            $healthResults.Components += @{
                Name = 'WindowManager'
                Status = 'Healthy'
                Details = if ($claudeWindow) { "Claude window detected" } else { "Claude window not found" }
            }
        } catch {
            $healthResults.Components += @{
                Name = 'WindowManager'
                Status = 'Error'
                Details = $_.Exception.Message
            }
            $healthResults.Overall = 'Degraded'
        }
        
        # Test PromptSubmissionEngine component
        try {
            # Test by checking if required assemblies are loaded
            $sendKeysAvailable = [System.Windows.Forms.SendKeys] -ne $null
            $healthResults.Components += @{
                Name = 'PromptSubmissionEngine'
                Status = 'Healthy'
                Details = "SendKeys functionality available: $sendKeysAvailable"
            }
        } catch {
            $healthResults.Components += @{
                Name = 'PromptSubmissionEngine'
                Status = 'Error'
                Details = $_.Exception.Message
            }
            $healthResults.Overall = 'Degraded'
        }
        
        # Test AutonomousOperations component
        try {
            $prompt = New-AutonomousPrompt -BasePrompt "Test prompt" -Priority "Low"
            $healthResults.Components += @{
                Name = 'AutonomousOperations'
                Status = 'Healthy'
                Details = "Prompt generation functional, test prompt length: $($prompt.Length) characters"
            }
        } catch {
            $healthResults.Components += @{
                Name = 'AutonomousOperations'
                Status = 'Error'
                Details = $_.Exception.Message
            }
            $healthResults.Overall = 'Degraded'
        }
        
        # Test OrchestrationManager component
        try {
            $status = Get-CLIOrchestrationStatus
            $healthResults.Components += @{
                Name = 'OrchestrationManager'
                Status = 'Healthy'
                Details = "Status reporting functional, overall status: $($status.OverallStatus)"
            }
        } catch {
            $healthResults.Components += @{
                Name = 'OrchestrationManager'
                Status = 'Error'
                Details = $_.Exception.Message
            }
            $healthResults.Overall = 'Degraded'
        }
        
        # Test existing Core components
        $coreComponents = @('ResponseAnalysisEngine', 'PatternRecognitionEngine', 'DecisionEngine', 'ActionExecutionEngine')
        
        foreach ($component in $coreComponents) {
            try {
                # Basic availability test - check if functions are available
                $testFunction = switch ($component) {
                    'ResponseAnalysisEngine' { 'Invoke-EnhancedResponseAnalysis' }
                    'PatternRecognitionEngine' { 'Find-RecommendationPatterns' }  
                    'DecisionEngine' { 'Invoke-RuleBasedDecision' }
                    'ActionExecutionEngine' { 'Invoke-SafeAction' }
                }
                
                if (Get-Command $testFunction -ErrorAction SilentlyContinue) {
                    $healthResults.Components += @{
                        Name = $component
                        Status = 'Healthy'
                        Details = "Core component available"
                    }
                } else {
                    $healthResults.Components += @{
                        Name = $component
                        Status = 'Warning'
                        Details = "Core component function not found: $testFunction"
                    }
                    if ($healthResults.Overall -eq 'Healthy') {
                        $healthResults.Overall = 'Degraded'
                    }
                }
            } catch {
                $healthResults.Components += @{
                    Name = $component
                    Status = 'Error'
                    Details = $_.Exception.Message
                }
                $healthResults.Overall = 'Degraded'
            }
        }
        
        return $healthResults
        
    } catch {
        Write-Error "Failed to test component health: $_"
        throw
    }
}