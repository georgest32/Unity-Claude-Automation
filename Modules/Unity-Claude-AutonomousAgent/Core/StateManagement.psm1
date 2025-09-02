# StateManagement.psm1
# State machine core functionality for ConversationStateManager

# Import core module for shared variables
Import-Module (Join-Path $PSScriptRoot "ConversationCore.psm1") -Force

function Initialize-ConversationState {
    <#
    .SYNOPSIS
    Initializes the conversation state machine
    
    .DESCRIPTION
    Sets up the initial state, loads persisted state if available, and prepares the state machine
    
    .PARAMETER SessionId
    Optional session identifier for continuing previous sessions
    
    .PARAMETER LoadPersisted
    Whether to load previously persisted state
    #>
    param(
        [string]$SessionId = "",
        [switch]$LoadPersisted
    )
    
    Write-StateLog "Initializing conversation state machine" -Level "INFO"
    
    try {
        # Generate session ID if not provided
        if ([string]::IsNullOrEmpty($SessionId)) {
            $SessionId = [Guid]::NewGuid().ToString()
            Write-StateLog "Generated new session ID: $SessionId" -Level "INFO"
        }
        
        # Define state machine structure
        $script:ConversationState = @{
            CurrentState = "Idle"
            PreviousState = $null
            SessionId = $SessionId
            StartTime = Get-Date
            LastStateChange = Get-Date
            TransitionCount = 0
            ErrorCount = 0
            SuccessCount = 0
            Metadata = @{
                UnityVersion = "2021.1.14f1"
                PowerShellVersion = $PSVersionTable.PSVersion.ToString()
                ModuleVersion = "2.0.0"
            }
        }
        
        # Initialize session metadata
        $script:SessionMetadata = @{
            SessionId = $SessionId
            StartTime = Get-Date
            LastActivity = Get-Date
            TotalPrompts = 0
            TotalResponses = 0
            TotalCommands = 0
            SuccessfulCommands = 0
            FailedCommands = 0
            TotalErrors = 0
            TotalStateTransitions = 0
            AverageResponseTime = 0.0
            MaxResponseTime = 0.0
            MinResponseTime = [double]::MaxValue
        }
        
        # Load persisted state if requested
        if ($LoadPersisted) {
            if (Test-Path $script:StatePersistencePath) {
                try {
                    $persistedState = Get-Content $script:StatePersistencePath | ConvertFrom-Json
                    $script:ConversationState = $persistedState
                    Write-StateLog "Loaded persisted state from previous session" -Level "INFO"
                }
                catch {
                    Write-StateLog "Failed to load persisted state: $_" -Level "WARNING"
                }
            }
            
            if (Test-Path $script:HistoryPersistencePath) {
                try {
                    $persistedHistory = Get-Content $script:HistoryPersistencePath | ConvertFrom-Json
                    $script:ConversationHistory = @($persistedHistory)
                    Write-StateLog "Loaded $($script:ConversationHistory.Count) history items" -Level "INFO"
                }
                catch {
                    Write-StateLog "Failed to load persisted history: $_" -Level "WARNING"
                }
            }
        }
        
        Write-StateLog "Conversation state machine initialized" -Level "SUCCESS"
        
        return @{
            Success = $true
            SessionId = $SessionId
            LoadedPersisted = $LoadPersisted.IsPresent
        }
    }
    catch {
        Write-StateLog "Failed to initialize conversation state: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Set-ConversationState {
    <#
    .SYNOPSIS
    Updates the conversation state
    
    .DESCRIPTION
    Transitions the state machine to a new state with validation
    
    .PARAMETER NewState
    The target state to transition to
    
    .PARAMETER Force
    Force the transition even if not normally valid
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Idle", "PromptPreparing", "PromptSubmitted", "WaitingForResponse", 
                     "ResponseReceived", "ProcessingResponse", "ExecutingAction", 
                     "Error", "Completed", "Suspended")]
        [string]$NewState,
        
        [switch]$Force
    )
    
    Write-StateLog "Attempting state transition to: $NewState" -Level "DEBUG"
    
    try {
        # Validate transition
        if (-not $Force) {
            $validTransitions = Get-ValidStateTransitions
            if ($NewState -notin $validTransitions) {
                Write-StateLog "Invalid state transition from $($script:ConversationState.CurrentState) to $NewState" -Level "WARNING"
                return @{
                    Success = $false
                    Reason = "Invalid transition"
                    CurrentState = $script:ConversationState.CurrentState
                    ValidTransitions = $validTransitions
                }
            }
        }
        
        # Store current state in history
        $script:StateHistory += @{
            State = $script:ConversationState.CurrentState
            Timestamp = Get-Date
            TransitionNumber = $script:ConversationState.TransitionCount
        }
        
        # Trim history if needed
        if ($script:StateHistory.Count -gt 100) {
            $script:StateHistory = $script:StateHistory[-100..-1]
        }
        
        # Update state
        $script:ConversationState.PreviousState = $script:ConversationState.CurrentState
        $script:ConversationState.CurrentState = $NewState
        $script:ConversationState.LastStateChange = Get-Date
        $script:ConversationState.TransitionCount++
        
        # Update session metadata
        $script:SessionMetadata.TotalStateTransitions++
        $script:SessionMetadata.LastActivity = Get-Date
        
        # Handle state-specific actions
        switch ($NewState) {
            "Error" {
                $script:ConversationState.ErrorCount++
                $script:SessionMetadata.TotalErrors++
            }
            "Completed" {
                $script:ConversationState.SuccessCount++
            }
        }
        
        # Save state
        Save-ConversationState
        
        Write-StateLog "State transitioned from $($script:ConversationState.PreviousState) to $NewState" -Level "INFO"
        
        return @{
            Success = $true
            PreviousState = $script:ConversationState.PreviousState
            CurrentState = $NewState
            TransitionCount = $script:ConversationState.TransitionCount
        }
    }
    catch {
        Write-StateLog "Failed to set conversation state: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Get-ConversationState {
    <#
    .SYNOPSIS
    Gets the current conversation state
    
    .DESCRIPTION
    Returns the current state machine status and metadata
    #>
    
    Write-StateLog "Getting conversation state" -Level "DEBUG"
    
    try {
        if ($null -eq $script:ConversationState) {
            Write-StateLog "Conversation state not initialized" -Level "WARNING"
            return @{
                Success = $false
                Reason = "State not initialized"
            }
        }
        
        return @{
            Success = $true
            State = $script:ConversationState
            SessionDuration = ((Get-Date) - $script:ConversationState.StartTime)
            HistoryCount = $script:ConversationHistory.Count
            GoalCount = $script:ConversationGoals.Count
        }
    }
    catch {
        Write-StateLog "Failed to get conversation state: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Get-ValidStateTransitions {
    <#
    .SYNOPSIS
    Gets valid state transitions from current state
    
    .DESCRIPTION
    Returns list of states the machine can transition to from current state
    #>
    
    Write-StateLog "Getting valid state transitions" -Level "DEBUG"
    
    $stateTransitionMap = @{
        "Idle" = @("PromptPreparing", "Error", "Suspended")
        "PromptPreparing" = @("PromptSubmitted", "Error", "Idle")
        "PromptSubmitted" = @("WaitingForResponse", "Error", "Idle")
        "WaitingForResponse" = @("ResponseReceived", "Error", "Suspended")
        "ResponseReceived" = @("ProcessingResponse", "Error")
        "ProcessingResponse" = @("ExecutingAction", "Completed", "Error")
        "ExecutingAction" = @("Completed", "Error", "WaitingForResponse")
        "Error" = @("Idle", "PromptPreparing")
        "Completed" = @("Idle", "PromptPreparing")
        "Suspended" = @("Idle")
    }
    
    $currentState = $script:ConversationState.CurrentState
    return $stateTransitionMap[$currentState]
}

function Reset-ConversationState {
    <#
    .SYNOPSIS
    Resets the conversation state machine
    
    .DESCRIPTION
    Clears all state and history, optionally preserving files
    
    .PARAMETER PreserveFiles
    Whether to keep persisted state files
    #>
    param(
        [switch]$PreserveFiles
    )
    
    Write-StateLog "Resetting conversation state machine" -Level "WARNING"
    
    try {
        # Clear in-memory data
        $script:ConversationState = $null
        $script:StateHistory = @()
        $script:ConversationHistory = @()
        $script:SessionMetadata = @{}
        $script:ConversationGoals = @()
        $script:RoleAwareHistory = @()
        $script:DialoguePatterns = @{}
        $script:ConversationEffectiveness = @{}
        
        # Remove persisted files if requested
        if (-not $PreserveFiles) {
            $filesToRemove = @(
                $script:StatePersistencePath,
                $script:HistoryPersistencePath,
                $script:GoalsPersistencePath,
                $script:EffectivenessPersistencePath
            )
            
            foreach ($file in $filesToRemove) {
                if (Test-Path $file) {
                    Remove-Item $file -Force
                    Write-StateLog "Removed persistence file: $(Split-Path $file -Leaf)" -Level "INFO"
                }
            }
        }
        
        Write-StateLog "Conversation state machine reset complete" -Level "SUCCESS"
        
        return @{
            Success = $true
            FilesPreserved = $PreserveFiles.IsPresent
        }
    }
    catch {
        Write-StateLog "Failed to reset conversation state: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

# Private helper function for saving state
function Save-ConversationState {
    Write-StateLog "Saving conversation state" -Level "DEBUG"
    
    try {
        $stateData = $script:ConversationState | ConvertTo-Json -Depth 10
        Set-Content -Path $script:StatePersistencePath -Value $stateData -Force
        
        Write-StateLog "Conversation state saved successfully" -Level "DEBUG"
    }
    catch {
        Write-StateLog "Failed to save conversation state: $_" -Level "WARNING"
    }
}

Export-ModuleMember -Function Initialize-ConversationState, Set-ConversationState, Get-ConversationState, Get-ValidStateTransitions, Reset-ConversationState
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBBVEbXy41aklSp
# M9KbLt6o5J2jttyydax8yjMYU29aOKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIDSyRs524XfMEPAMAC2wg8Bf
# SOrnpVVpGagg54/83Ut5MA0GCSqGSIb3DQEBAQUABIIBAKgUmmTgDwKHN3Mrmc8F
# Y9tMyy66Yrx15awN/gX2Qb0nCnVpYnBoL50hLP0z0SQKOPrcMT2OtXBi1mpx3wZt
# 8j56dFyBqQ4lVIp+rfDeriqMVoSFTiOU3dMj6jAmryL9tV3GfbNcJBUZL4bbNwKl
# tagvWT+9E3cuRnQMDfaDdgp1tE62CDXMPsBJTcQvsTkAZA4GvcluEUZwZidscKmO
# xd+NCO9hSO6Trh9XHh13hiMwPK2INvS5nrIxNZoH/wdy4bkfmTufDm5lw4kuSJJY
# TIbUQ96DSWSkesAn77KkXDVYOcYsgwEB9e3+Zxq2tQsZU/KqgR2P0xSdJ26LMa2Q
# M+E=
# SIG # End signature block
