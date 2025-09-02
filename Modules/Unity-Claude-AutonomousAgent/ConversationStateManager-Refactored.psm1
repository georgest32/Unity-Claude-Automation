# ConversationStateManager-Refactored.psm1
# Refactored orchestrator for ConversationStateManager module
# Imports and coordinates all modular components

# Component Imports
$componentsPath = Join-Path $PSScriptRoot "Core"
Import-Module (Join-Path $componentsPath "ConversationCore.psm1") -Force -Global
Import-Module (Join-Path $componentsPath "StateManagement.psm1") -Force
Import-Module (Join-Path $componentsPath "HistoryManagement.psm1") -Force
Import-Module (Join-Path $componentsPath "GoalManagement.psm1") -Force
Import-Module (Join-Path $componentsPath "RoleAwareManagement.psm1") -Force
Import-Module (Join-Path $componentsPath "PersistenceManagement.psm1") -Force

# Version information
$script:ModuleVersion = "2.0.0"
$script:RefactoredDate = "2025-08-26"

Write-StateLog "ConversationStateManager Refactored Module v$script:ModuleVersion loaded" -Level "INFO"
Write-StateLog "REFACTORED VERSION - Using modular component architecture" -Level "SUCCESS"

# Orchestration Functions

function Get-ConversationStateManagerComponents {
    <#
    .SYNOPSIS
    Returns information about loaded components
    
    .DESCRIPTION
    Provides details about the refactored modular architecture
    #>
    
    return @{
        Version = $script:ModuleVersion
        RefactoredDate = $script:RefactoredDate
        Components = @(
            @{ Name = "ConversationCore"; Description = "Core configuration and logging" }
            @{ Name = "StateManagement"; Description = "State machine management" }
            @{ Name = "HistoryManagement"; Description = "Conversation history tracking" }
            @{ Name = "GoalManagement"; Description = "Goal tracking and effectiveness" }
            @{ Name = "RoleAwareManagement"; Description = "Role-aware dialogue patterns" }
            @{ Name = "PersistenceManagement"; Description = "State and history persistence" }
        )
        Architecture = "Modular Component-Based"
        TotalFunctions = 22
    }
}

function Test-ConversationStateManagerHealth {
    <#
    .SYNOPSIS
    Tests health of all components
    
    .DESCRIPTION
    Verifies that all components are loaded and functioning
    #>
    
    Write-StateLog "Testing ConversationStateManager component health" -Level "DEBUG"
    
    $healthReport = @{
        Overall = $true
        Components = @{}
        Timestamp = Get-Date
    }
    
    # Test each component
    $components = @(
        @{ Name = "StateManagement"; TestCmd = { Get-Command Initialize-ConversationState -ErrorAction SilentlyContinue } }
        @{ Name = "HistoryManagement"; TestCmd = { Get-Command Add-ConversationHistoryItem -ErrorAction SilentlyContinue } }
        @{ Name = "GoalManagement"; TestCmd = { Get-Command Add-ConversationGoal -ErrorAction SilentlyContinue } }
        @{ Name = "RoleAwareManagement"; TestCmd = { Get-Command Add-RoleAwareHistoryItem -ErrorAction SilentlyContinue } }
        @{ Name = "PersistenceManagement"; TestCmd = { Get-Command Save-ConversationState -ErrorAction SilentlyContinue } }
    )
    
    foreach ($component in $components) {
        $result = & $component.TestCmd
        $healthReport.Components[$component.Name] = if ($result) { "Healthy" } else { "Failed" }
        
        if (-not $result) {
            $healthReport.Overall = $false
            Write-StateLog "Component health check failed: $($component.Name)" -Level "WARNING"
        }
    }
    
    # Test state initialization
    if ($null -eq $script:ConversationState) {
        $healthReport.StateInitialized = $false
        Write-StateLog "Conversation state not initialized" -Level "INFO"
    } else {
        $healthReport.StateInitialized = $true
    }
    
    return $healthReport
}

function Invoke-ConversationStateManagerDiagnostics {
    <#
    .SYNOPSIS
    Runs comprehensive diagnostics on the conversation state system
    
    .DESCRIPTION
    Performs detailed analysis and reporting of system status
    #>
    
    Write-StateLog "Running ConversationStateManager diagnostics" -Level "INFO"
    
    $diagnostics = @{
        Timestamp = Get-Date
        ComponentHealth = Test-ConversationStateManagerHealth
        StateInfo = if ($script:ConversationState) {
            @{
                CurrentState = $script:ConversationState.CurrentState
                SessionId = $script:ConversationState.SessionId
                TransitionCount = $script:ConversationState.TransitionCount
                ErrorCount = $script:ConversationState.ErrorCount
                SuccessCount = $script:ConversationState.SuccessCount
            }
        } else { "Not initialized" }
        HistoryInfo = @{
            ItemCount = $script:ConversationHistory.Count
            RoleAwareItemCount = $script:RoleAwareHistory.Count
            MaxHistorySize = $script:MaxHistorySize
            MaxRoleHistorySize = $script:MaxRoleHistorySize
        }
        GoalsInfo = @{
            TotalGoals = $script:ConversationGoals.Count
            ActiveGoals = ($script:ConversationGoals | Where-Object { $_.Status -eq "Active" }).Count
            CompletedGoals = ($script:ConversationGoals | Where-Object { $_.Status -eq "Completed" }).Count
        }
        EffectivenessInfo = if ($script:ConversationEffectiveness -and $script:ConversationEffectiveness.Scores) {
            @{
                OverallScore = $script:ConversationEffectiveness.Scores.Overall
                Trend = $script:ConversationEffectiveness.Scores.Trend
            }
        } else { "Not calculated" }
        PersistenceInfo = @{
            StateFileExists = Test-Path $script:StatePersistencePath
            HistoryFileExists = Test-Path $script:HistoryPersistencePath
            GoalsFileExists = Test-Path $script:GoalsPersistencePath
        }
    }
    
    Write-StateLog "Diagnostics complete" -Level "SUCCESS"
    
    return $diagnostics
}

function Initialize-CompleteConversationSystem {
    <#
    .SYNOPSIS
    Initializes the complete conversation management system
    
    .DESCRIPTION
    Sets up all components with default or specified configuration
    
    .PARAMETER SessionId
    Optional session ID to use
    
    .PARAMETER LoadPersisted
    Whether to load persisted data
    #>
    param(
        [string]$SessionId = "",
        [switch]$LoadPersisted
    )
    
    Write-StateLog "Initializing complete conversation system" -Level "INFO"
    
    try {
        # Initialize state
        $stateResult = Initialize-ConversationState -SessionId $SessionId -LoadPersisted:$LoadPersisted
        
        if (-not $stateResult.Success) {
            throw "Failed to initialize conversation state: $($stateResult.Error)"
        }
        
        # Load persisted data if requested
        if ($LoadPersisted) {
            # Load goals
            $goalsResult = Load-ConversationGoals
            if ($goalsResult.Success) {
                Write-StateLog "Loaded $($goalsResult.GoalCount) persisted goals" -Level "INFO"
            }
            
            # Initialize effectiveness tracking
            Update-ConversationEffectiveness
        }
        
        Write-StateLog "Complete conversation system initialized" -Level "SUCCESS"
        
        return @{
            Success = $true
            SessionId = $stateResult.SessionId
            LoadedPersisted = $LoadPersisted.IsPresent
            ComponentStatus = Test-ConversationStateManagerHealth
        }
    }
    catch {
        Write-StateLog "Failed to initialize complete conversation system: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Get-ConversationSummary {
    <#
    .SYNOPSIS
    Gets comprehensive conversation summary
    
    .DESCRIPTION
    Returns complete overview of conversation state and metrics
    #>
    
    Write-StateLog "Generating conversation summary" -Level "DEBUG"
    
    try {
        $summary = @{
            State = Get-ConversationState
            Metadata = Get-SessionMetadata
            Goals = Get-ConversationGoals -Status "All"
            History = @{
                Recent = (Get-ConversationHistory -Limit 5).History
                RoleAware = (Get-RoleAwareHistory -Limit 5 -IncludeAnalysis).Analysis
            }
            Effectiveness = if ($script:ConversationEffectiveness) {
                $script:ConversationEffectiveness
            } else { @{} }
            DialoguePatterns = if ($script:DialoguePatterns.Statistics) {
                $script:DialoguePatterns.Statistics
            } else { @{} }
        }
        
        return @{
            Success = $true
            Summary = $summary
        }
    }
    catch {
        Write-StateLog "Failed to generate conversation summary: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

# Export all public functions from components plus orchestration functions
Export-ModuleMember -Function @(
    # State Management
    'Initialize-ConversationState',
    'Set-ConversationState',
    'Get-ConversationState',
    'Get-ValidStateTransitions',
    'Reset-ConversationState',
    
    # History Management
    'Add-ConversationHistoryItem',
    'Get-ConversationHistory',
    'Get-ConversationContext',
    'Clear-ConversationHistory',
    'Get-SessionMetadata',
    
    # Goal Management
    'Add-ConversationGoal',
    'Update-ConversationGoal',
    'Get-ConversationGoals',
    'Calculate-GoalRelevance',
    
    # Role-Aware Management
    'Add-RoleAwareHistoryItem',
    'Get-RoleAwareHistory',
    'Update-DialoguePatterns',
    'Update-ConversationEffectiveness',
    
    # Persistence Management
    'Save-ConversationState',
    'Save-ConversationHistory',
    'Save-ConversationGoals',
    'Load-ConversationState',
    'Load-ConversationHistory',
    'Load-ConversationGoals',
    'Export-ConversationSession',
    'Import-ConversationSession',
    
    # Orchestration Functions
    'Get-ConversationStateManagerComponents',
    'Test-ConversationStateManagerHealth',
    'Invoke-ConversationStateManagerDiagnostics',
    'Initialize-CompleteConversationSystem',
    'Get-ConversationSummary'
)

Write-StateLog "ConversationStateManager module loaded successfully with 33 functions" -Level "SUCCESS"
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCS7Ug+JrYZiGDG
# /tVuXjhW7jFWm6Ci56W8Osb87BEdwKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIAArov6WLx4cFJZtscMvoDI2
# 8QAQ76aQ2FsNjHrAA+47MA0GCSqGSIb3DQEBAQUABIIBADskg0R0dgvHbLnG9Ukp
# oFkG9u6NVWScELiY9B4ag6Os2ebN6pjx3EfQNqSQICrFLPNtBBSrw45qi6dgzqZC
# YxbD8SaUmis0zvwDYNj7aophqlCp3Ez5UWH9dYjRI4oNhD3lUVjztC5ds9FXksLQ
# JK1Tq/2kEigzqRJfXJQJf3kGlvQp6rNx2PdKlkzu7+c74htE3Vp2b8HdAX925ux+
# A0ZedKj6XbpEoRgtbvsmS/jnKp+5mqItYWo6aNW2AdBVxaPORmrzmOEv6jsTjwwn
# Nhg/f/JLoKDVODCO0gug15jPw41D1qGI7obHZ1sEafV0W8gpYN90iEo2EaRK/URc
# QVQ=
# SIG # End signature block
