function Get-CLIOrchestratorInfo {
    <#
    .SYNOPSIS
        Gets comprehensive information about the CLI orchestrator system
    .DESCRIPTION
        Returns detailed system information including version, architecture,
        components, and runtime statistics
    .EXAMPLE
        Get-CLIOrchestratorInfo
    #>
    [CmdletBinding()]
    param()
    
    try {
        $info = @{
            Version = "2.0.0"
            Architecture = "Component-Based"
            RefactoringDetails = @{
                OriginalLines = 1610
                NewComponents = 4
                ExistingCoreComponents = 4
                TotalComponents = 8
                AverageNewComponentSize = 402
                Maintainability = "Significantly Improved"
                Testability = "Enhanced" 
            }
            Components = @{
                New = @(
                    @{ Name = "WindowManager"; Description = "Claude CLI window detection and management"; Lines = "~272" }
                    @{ Name = "PromptSubmissionEngine"; Description = "Secure TypeKeys prompt submission with safety measures"; Lines = "~310" }
                    @{ Name = "AutonomousOperations"; Description = "Autonomous prompt generation and execution loops"; Lines = "~490" }
                    @{ Name = "OrchestrationManager"; Description = "Main orchestration control and status monitoring"; Lines = "~536" }
                )
                Existing = @(
                    @{ Name = "ResponseAnalysisEngine"; Description = "Advanced response analysis and processing" }
                    @{ Name = "PatternRecognitionEngine"; Description = "Pattern recognition and classification" }
                    @{ Name = "DecisionEngine"; Description = "Rule-based and Bayesian decision making" }
                    @{ Name = "ActionExecutionEngine"; Description = "Safe action execution with queuing" }
                )
            }
            Benefits = @(
                "Separation of concerns with focused components"
                "Improved code maintainability and readability"
                "Enhanced testability with isolated components"
                "Better error isolation and debugging"
                "Easier feature development and extension"
                "Preserved existing Core component functionality"
                "Maintained full backward compatibility"
            )
            SessionStatistics = $script:CLIOrchestratorConfig.SessionStats.Clone()
            SystemState = @{
                IsRunning = $script:CLIOrchestratorConfig.IsRunning
                StartTime = $script:CLIOrchestratorConfig.StartTime
                LastActivity = $script:CLIOrchestratorConfig.LastActivity
                ComponentStatus = $script:CLIOrchestratorConfig.ComponentStatus.Clone()
            }
        }
        
        # Add runtime information
        if ($script:CLIOrchestratorConfig.IsRunning -and $script:CLIOrchestratorConfig.StartTime) {
            $runtime = (Get-Date) - $script:CLIOrchestratorConfig.StartTime
            $info.SystemState.RuntimeMinutes = [Math]::Round($runtime.TotalMinutes, 2)
        }
        
        return $info
        
    } catch {
        Write-Error "Failed to get CLI orchestrator info: $_"
        throw
    }
}