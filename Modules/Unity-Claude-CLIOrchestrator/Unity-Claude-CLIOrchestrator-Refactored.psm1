#region Module Header
<#
.SYNOPSIS
    Unity-Claude CLI Orchestrator Module - Refactored
    Phase 7 Advanced Features: Intelligent CLI Orchestration System
    
.DESCRIPTION
    Provides comprehensive autonomous CLI orchestration with intelligent window management,
    secure prompt submission, autonomous operations, and sophisticated decision making.
    This is the refactored version with modular component architecture.
    
.VERSION
    2.0.0
    
.AUTHOR
    Unity-Claude-Automation
    
.DATE
    2025-08-25
    
.ARCHITECTURE
    This module follows a component-based architecture with specialized modules:
    - WindowManager: Claude CLI window detection and management
    - PromptSubmissionEngine: Secure TypeKeys prompt submission with safety measures
    - AutonomousOperations: Autonomous prompt generation and execution loops
    - OrchestrationManager: Main orchestration control and status monitoring
    - (Existing) ResponseAnalysisEngine: Advanced response analysis and processing
    - (Existing) PatternRecognitionEngine: Pattern recognition and classification
    - (Existing) DecisionEngine: Rule-based and Bayesian decision making
    - (Existing) ActionExecutionEngine: Safe action execution with queuing
    
.REFACTORING_NOTES
    Original module: 1,610 lines
    Refactored components: 4 new components + existing Core/ components
    New components average: ~402 lines each (down from 1,610 monolithic)
    Benefits: Improved maintainability, testability, and modularity
#>
#endregion

#region Private Variables
$script:CLIOrchestratorConfig = @{
    IsRunning = $false
    Version = "2.0.0"
    Architecture = "Component-Based"
    StartTime = $null
    LastActivity = $null
    ComponentStatus = @{}
    SessionStats = @{
        PromptsSent = 0
        ResponsesProcessed = 0
        DecisionsMade = 0
        ActionsExecuted = 0
        ErrorCount = 0
    }
}

# Simple directive for backward compatibility
$script:SimpleDirective = " ================================================== CRITICAL: AT THE END OF YOUR RESPONSE, YOU MUST CREATE A RESPONSE .JSON FILE AT ./ClaudeResponses/Autonomous/ AND IN IT WRITE THE END OF YOUR RESPONSE, WHICH SHOULD END WITH: [RECOMMENDATION: CONTINUE]; [RECOMMENDATION: TEST <Name>]; [RECOMMENDATION: FIX <File>]; [RECOMMENDATION: COMPILE]; [RECOMMENDATION: RESTART <Module>]; [RECOMMENDATION: COMPLETE]; [RECOMMENDATION: ERROR <Description>]=================================================="

# Full boilerplate prompt stored as a resource  
$script:BoilerplatePrompt = $null
try {
    $boilerplatePath = Join-Path $PSScriptRoot "Resources\BoilerplatePrompt.txt"
    if (Test-Path $boilerplatePath) {
        $script:BoilerplatePrompt = Get-Content -Path $boilerplatePath -Raw
    }
} catch {
    Write-Host "Warning: Could not load boilerplate prompt file: $_" -ForegroundColor Yellow
}

if (-not $script:BoilerplatePrompt) {
    # Fallback to simple directive if file not found
    $script:BoilerplatePrompt = "Please process the following recommendation and provide a detailed response."
}
#endregion

#region Component Imports
# Note: All module imports are handled by the manifest's NestedModules section
# This prevents PowerShell module nesting limit errors and ensures proper dependency management
# The manifest imports: WindowManager, PromptSubmissionEngine, AutonomousOperations, OrchestrationManager
# Additional Core components (ResponseAnalysisEngine, PatternRecognitionEngine, DecisionEngine, ActionExecutionEngine)
# are available through PowerShell's module system without explicit imports
#endregion

#region Enhanced Orchestration Functions

function Initialize-CLIOrchestrator {
    <#
    .SYNOPSIS
        Initializes the CLI orchestrator system with all components
    .DESCRIPTION
        Performs comprehensive initialization of all orchestration components
        and validates system readiness for autonomous operations
    .PARAMETER ValidateComponents
        Validate all components during initialization
    .PARAMETER SetupDirectories
        Create required directories during initialization
    .EXAMPLE
        Initialize-CLIOrchestrator -ValidateComponents -SetupDirectories
    #>
    [CmdletBinding()]
    param(
        [switch]$ValidateComponents,
        [switch]$SetupDirectories
    )
    
    try {
        Write-Host "Initializing CLI Orchestrator System v2.0..." -ForegroundColor Cyan
        
        # Initialize configuration
        $script:CLIOrchestratorConfig.StartTime = Get-Date
        $script:CLIOrchestratorConfig.LastActivity = Get-Date
        
        # Setup directories if requested
        if ($SetupDirectories) {
            $directories = @(
                ".\ClaudeResponses\Autonomous",
                ".\logs\orchestrator",
                ".\config\orchestrator"
            )
            
            foreach ($dir in $directories) {
                if (-not (Test-Path $dir)) {
                    New-Item -Path $dir -ItemType Directory -Force | Out-Null
                    Write-Verbose "Created directory: $dir"
                }
            }
            Write-Host "  Directory structure validated" -ForegroundColor Gray
        }
        
        # Validate components if requested
        if ($ValidateComponents) {
            $componentResults = Test-CLIOrchestratorComponents
            $healthyComponents = ($componentResults.Components | Where-Object { $_.Status -eq 'Healthy' }).Count
            Write-Host "  Components: $healthyComponents/$($componentResults.Components.Count) healthy" -ForegroundColor Gray
            
            # Update component status
            foreach ($component in $componentResults.Components) {
                $script:CLIOrchestratorConfig.ComponentStatus[$component.Name] = $component.Status
            }
        }
        
        # Validate Claude window availability
        $claudeWindow = Find-ClaudeWindow
        if ($claudeWindow) {
            Write-Host "  Claude CLI window detected successfully" -ForegroundColor Green
        } else {
            Write-Host "  WARNING: Claude CLI window not found" -ForegroundColor Yellow
        }
        
        Write-Host "CLI Orchestrator System initialized successfully" -ForegroundColor Green
        Write-Host "  Version: 2.0.0 (Refactored)" -ForegroundColor Gray
        Write-Host "  Architecture: Component-Based" -ForegroundColor Gray
        
        $script:CLIOrchestratorConfig.IsRunning = $true
        
        return @{
            Version = "2.0.0"
            Initialized = $true
            ComponentHealth = if ($ValidateComponents) { $componentResults } else { @{} }
            ClaudeWindowAvailable = ($claudeWindow -ne $null)
            InitializedAt = $script:CLIOrchestratorConfig.StartTime
        }
        
    } catch {
        Write-Error "Failed to initialize CLI orchestrator: $_"
        throw
    }
}

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

function Update-CLISessionStats {
    <#
    .SYNOPSIS
        Updates CLI orchestrator session statistics
    .DESCRIPTION
        Updates various session statistics for monitoring and reporting
    .PARAMETER StatType
        Type of statistic to update
    .PARAMETER Increment
        Amount to increment the statistic by (default: 1)
    .EXAMPLE
        Update-CLISessionStats -StatType "PromptsSent"
    #>
    [CmdletBinding()]
    param(
        [ValidateSet("PromptsSent", "ResponsesProcessed", "DecisionsMade", "ActionsExecuted", "ErrorCount")]
        [string]$StatType,
        
        [int]$Increment = 1
    )
    
    try {
        if ($script:CLIOrchestratorConfig.SessionStats.ContainsKey($StatType)) {
            $script:CLIOrchestratorConfig.SessionStats[$StatType] += $Increment
            $script:CLIOrchestratorConfig.LastActivity = Get-Date
            
            Write-Verbose "Updated $StatType by $Increment (new value: $($script:CLIOrchestratorConfig.SessionStats[$StatType]))"
        } else {
            Write-Warning "Unknown statistic type: $StatType"
        }
    } catch {
        Write-Error "Failed to update session statistics: $_"
    }
}

#endregion

#region Module Initialization
# Initialize module state
if (-not $script:CLIOrchestratorConfig.StartTime) {
    $script:CLIOrchestratorConfig.StartTime = Get-Date
    $script:CLIOrchestratorConfig.LastActivity = Get-Date
}

# Auto-initialize if Claude window is available
try {
    $claudeWindow = Find-ClaudeWindow
    if ($claudeWindow) {
        Write-Verbose "CLI Orchestrator: Claude window detected, system ready for operation"
    }
} catch {
    Write-Verbose "CLI Orchestrator: Initialization check completed"
}
#endregion

# Re-export nested module functions to ensure they are available
# This is needed because dot-sourced module functions need explicit export
$coreModuleFunctions = @(
    'Invoke-EnhancedResponseAnalysis', 'Test-JsonTruncation', 'Repair-TruncatedJson', 'Extract-ResponseEntities', 
    'Analyze-ResponseSentiment', 'Get-ResponseContext', 'Invoke-PatternRecognitionAnalysis', 'Find-RecommendationPatterns',
    'Extract-ContextEntities', 'Classify-ResponseType', 'Calculate-OverallConfidence', 'Invoke-RuleBasedDecision',
    'Resolve-PriorityDecision', 'Test-SafetyValidation', 'Test-SafeFilePath', 'Test-SafeCommand', 'Test-ActionQueueCapacity',
    'New-ActionQueueItem', 'Get-ActionQueueStatus', 'Resolve-ConflictingRecommendations', 'Invoke-GracefulDegradation',
    'Test-CircuitBreakerState', 'Update-CircuitBreakerState', 'Invoke-SafeAction', 'Add-ActionToQueue', 
    'Get-NextQueuedAction', 'Get-ActionExecutionStatus', 'Test-ActionSafety', 'Test-PatternRecognitionPerformance',
    'Get-PatternRecognitionStatus'
)

# Export each available core function
foreach ($functionName in $coreModuleFunctions) {
    if (Get-Command $functionName -ErrorAction SilentlyContinue) {
        Export-ModuleMember -Function $functionName
    }
}

# Export all functions from new components plus orchestration functions
Export-ModuleMember -Function @(
    # New Orchestration Functions
    'Initialize-CLIOrchestrator',
    'Test-CLIOrchestratorComponents',
    'Get-CLIOrchestratorInfo',
    'Update-CLISessionStats',
    
    # WindowManager Functions
    'Update-ClaudeWindowInfo',
    'Find-ClaudeWindow',
    'Switch-ToWindow',
    
    # PromptSubmissionEngine Functions
    'Submit-ToClaudeViaTypeKeys',
    'Execute-TestScript',
    
    # AutonomousOperations Functions
    'New-AutonomousPrompt',
    'Get-ActionResultSummary',
    'Process-ResponseFile',
    'Invoke-AutonomousExecutionLoop',
    
    # OrchestrationManager Functions  
    'Start-CLIOrchestration',
    'Get-CLIOrchestrationStatus',
    'Invoke-ComprehensiveResponseAnalysis',
    'Invoke-AutonomousDecisionMaking',
    'Invoke-DecisionExecution',
    
    # Legacy Functions (maintained for backward compatibility)
    'Invoke-RuleBasedDecision',
    'Resolve-PriorityDecision', 
    'Test-SafetyValidation',
    'Test-SafeFilePath',
    'Test-SafeCommand',
    'Test-ActionQueueCapacity',
    'New-ActionQueueItem',
    'Get-ActionQueueStatus',
    'Resolve-ConflictingRecommendations',
    'Invoke-GracefulDegradation',
    
    # Circuit Breaker Functions
    'Test-CircuitBreakerState',
    'Update-CircuitBreakerState',
    
    # Pattern Recognition Functions
    'Invoke-PatternRecognitionAnalysis',
    'Find-RecommendationPatterns',
    'Extract-ContextEntities',
    'Classify-ResponseType',
    'Calculate-OverallConfidence',
    
    # Response Analysis Functions
    'Invoke-EnhancedResponseAnalysis',
    'Test-JsonTruncation',
    'Repair-TruncatedJson',
    'Extract-ResponseEntities',
    'Analyze-ResponseSentiment',
    'Get-ResponseContext',
    
    # Action Execution Functions
    'Invoke-SafeAction',
    'Add-ActionToQueue',
    'Get-NextQueuedAction',
    'Get-ActionExecutionStatus',
    'Test-ActionSafety'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDZL5rw6buqsv1R
# E4wHdiSLb1L+2ussAViMelyFrNECOaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIG0LYbXHmu+ehRbEtzMmhyEr
# 8M3af2ZM38Qx8ArIy9jaMA0GCSqGSIb3DQEBAQUABIIBACZqbD/78UtTx6/8SDwZ
# 44tN//A15yE+n0qyp3y3vBOOj4cHJqRALFMmvmzkJKulE6Wrl2bqHVc6+3bHju+8
# akuKfdDg29JYdWR4hYALEIneT5vfINVTOt6TO6dz4f4zv23TU3wimMhfCa2vKRnO
# x9/qTachJ8AntH58ZaTt4EvUjd0iHjycvjf0Z7I48iXifnlKOvuT4hyBbLKaPU+t
# b4En3ehE6zq61Wf3Prc+HgRCQNWB9QCYllZ2zM3B9x/D3nVbvfFqc6JWGGhF9n2O
# l26Fir1TQHmnyd2fgNJS+Q9zIpsOHas8KXoIluxIo2ALdvW3cOjJUi7Q6zIhdG6X
# I14=
# SIG # End signature block
