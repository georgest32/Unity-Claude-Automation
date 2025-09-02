# HistoryManagement.psm1
# Conversation history tracking and management

# Import core module for shared variables
Import-Module (Join-Path $PSScriptRoot "ConversationCore.psm1") -Force

function Add-ConversationHistoryItem {
    <#
    .SYNOPSIS
    Adds an item to conversation history
    
    .DESCRIPTION
    Records prompts, responses, commands, and errors in conversation history
    
    .PARAMETER Type
    Type of history item (Prompt, Response, Command, Error)
    
    .PARAMETER Content
    The content to record
    
    .PARAMETER Metadata
    Additional metadata for the item
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Prompt", "Response", "Command", "Error")]
        [string]$Type,
        
        [Parameter(Mandatory = $true)]
        [string]$Content,
        
        [hashtable]$Metadata = @{}
    )
    
    Write-StateLog "Adding $Type to conversation history" -Level "DEBUG"
    
    try {
        $historyItem = [PSCustomObject]@{
            Type = $Type
            Content = $Content
            Timestamp = Get-Date
            SessionId = $script:ConversationState.SessionId
            StateAtTime = $script:ConversationState.CurrentState
            Index = $script:ConversationHistory.Count
            Metadata = $Metadata
        }
        
        # Add to history
        $script:ConversationHistory += $historyItem
        
        # Update session metadata
        switch ($Type) {
            "Prompt" { $script:SessionMetadata.TotalPrompts++ }
            "Response" { $script:SessionMetadata.TotalResponses++ }
            "Command" { $script:SessionMetadata.TotalCommands++ }
            "Error" { $script:SessionMetadata.TotalErrors++ }
        }
        
        $script:SessionMetadata.LastActivity = Get-Date
        
        # Trim history if needed
        if ($script:ConversationHistory.Count -gt $script:MaxHistorySize) {
            # Keep the most recent items
            $script:ConversationHistory = $script:ConversationHistory[-$script:MaxHistorySize..-1]
            Write-StateLog "Trimmed conversation history to $script:MaxHistorySize items" -Level "DEBUG"
        }
        
        # Save history
        Save-ConversationHistory
        
        Write-StateLog "Added $Type to history (Total items: $($script:ConversationHistory.Count))" -Level "DEBUG"
        
        return @{
            Success = $true
            HistoryIndex = $historyItem.Index
            TotalItems = $script:ConversationHistory.Count
        }
    }
    catch {
        Write-StateLog "Failed to add history item: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Get-ConversationHistory {
    <#
    .SYNOPSIS
    Gets conversation history
    
    .DESCRIPTION
    Returns filtered conversation history items
    
    .PARAMETER Type
    Filter by specific type
    
    .PARAMETER Limit
    Maximum number of items to return
    
    .PARAMETER Since
    Return items since this timestamp
    #>
    param(
        [ValidateSet("Prompt", "Response", "Command", "Error", "All")]
        [string]$Type = "All",
        
        [int]$Limit = 0,
        
        [DateTime]$Since = [DateTime]::MinValue
    )
    
    Write-StateLog "Getting conversation history (Type: $Type, Limit: $Limit)" -Level "DEBUG"
    
    try {
        $filteredHistory = $script:ConversationHistory
        
        # Filter by type
        if ($Type -ne "All") {
            $filteredHistory = $filteredHistory | Where-Object { $_.Type -eq $Type }
        }
        
        # Filter by time
        if ($Since -ne [DateTime]::MinValue) {
            $filteredHistory = $filteredHistory | Where-Object { $_.Timestamp -gt $Since }
        }
        
        # Apply limit
        if ($Limit -gt 0 -and $filteredHistory.Count -gt $Limit) {
            $filteredHistory = $filteredHistory[-$Limit..-1]
        }
        
        Write-StateLog "Retrieved $($filteredHistory.Count) history items" -Level "INFO"
        
        return @{
            Success = $true
            History = $filteredHistory
            TotalCount = $filteredHistory.Count
        }
    }
    catch {
        Write-StateLog "Failed to get conversation history: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Get-ConversationContext {
    <#
    .SYNOPSIS
    Gets conversation context for decision making
    
    .DESCRIPTION
    Returns recent context including prompts, responses, and errors
    
    .PARAMETER ContextSize
    Number of recent items to include
    #>
    param(
        [int]$ContextSize = 5
    )
    
    Write-StateLog "Getting conversation context (Size: $ContextSize)" -Level "DEBUG"
    
    try {
        $context = @{
            CurrentState = $script:ConversationState.CurrentState
            PreviousState = $script:ConversationState.PreviousState
            SessionId = $script:ConversationState.SessionId
            ErrorCount = $script:ConversationState.ErrorCount
            SuccessCount = $script:ConversationState.SuccessCount
            RecentHistory = @()
            ActiveGoals = @()
            LastPrompt = $null
            LastResponse = $null
            LastError = $null
        }
        
        # Get recent history
        if ($script:ConversationHistory.Count -gt 0) {
            $startIndex = [Math]::Max(0, $script:ConversationHistory.Count - $ContextSize)
            $context.RecentHistory = $script:ConversationHistory[$startIndex..($script:ConversationHistory.Count - 1)]
            
            # Find last prompt
            $lastPrompt = $script:ConversationHistory | Where-Object { $_.Type -eq "Prompt" } | Select-Object -Last 1
            if ($lastPrompt) {
                $context.LastPrompt = @{
                    Content = $lastPrompt.Content
                    Timestamp = $lastPrompt.Timestamp
                }
            }
            
            # Find last response
            $lastResponse = $script:ConversationHistory | Where-Object { $_.Type -eq "Response" } | Select-Object -Last 1
            if ($lastResponse) {
                $context.LastResponse = @{
                    Content = $lastResponse.Content
                    Timestamp = $lastResponse.Timestamp
                }
            }
            
            # Find last error
            $lastError = $script:ConversationHistory | Where-Object { $_.Type -eq "Error" } | Select-Object -Last 1
            if ($lastError) {
                $context.LastError = @{
                    Content = $lastError.Content
                    Timestamp = $lastError.Timestamp
                }
            }
        }
        
        # Get active goals
        $context.ActiveGoals = $script:ConversationGoals | Where-Object { $_.Status -eq "Active" }
        
        Write-StateLog "Generated context with $($context.RecentHistory.Count) history items" -Level "INFO"
        
        return @{
            Success = $true
            Context = $context
        }
    }
    catch {
        Write-StateLog "Failed to get conversation context: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Clear-ConversationHistory {
    <#
    .SYNOPSIS
    Clears conversation history
    
    .DESCRIPTION
    Removes conversation history with optional persistence
    
    .PARAMETER KeepPersisted
    Whether to keep persisted history file
    #>
    param(
        [switch]$KeepPersisted
    )
    
    Write-StateLog "Clearing conversation history" -Level "WARNING"
    
    try {
        $oldCount = $script:ConversationHistory.Count
        $script:ConversationHistory = @()
        
        if (-not $KeepPersisted -and (Test-Path $script:HistoryPersistencePath)) {
            Remove-Item $script:HistoryPersistencePath -Force
            Write-StateLog "Removed persisted history file" -Level "INFO"
        }
        
        Write-StateLog "Cleared $oldCount history items" -Level "SUCCESS"
        
        return @{
            Success = $true
            ItemsCleared = $oldCount
        }
    }
    catch {
        Write-StateLog "Failed to clear conversation history: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Get-SessionMetadata {
    <#
    .SYNOPSIS
    Gets session metadata and statistics
    
    .DESCRIPTION
    Returns comprehensive session information and metrics
    #>
    
    Write-StateLog "Getting session metadata" -Level "DEBUG"
    
    try {
        # Calculate average response time
        $responseTimes = @()
        for ($i = 0; $i -lt $script:ConversationHistory.Count - 1; $i++) {
            if ($script:ConversationHistory[$i].Type -eq "Prompt" -and 
                $script:ConversationHistory[$i + 1].Type -eq "Response") {
                $responseTime = ($script:ConversationHistory[$i + 1].Timestamp - $script:ConversationHistory[$i].Timestamp).TotalSeconds
                $responseTimes += $responseTime
            }
        }
        
        if ($responseTimes.Count -gt 0) {
            $script:SessionMetadata.AverageResponseTime = [Math]::Round(($responseTimes | Measure-Object -Average).Average, 2)
            $script:SessionMetadata.MaxResponseTime = [Math]::Round(($responseTimes | Measure-Object -Maximum).Maximum, 2)
            $script:SessionMetadata.MinResponseTime = [Math]::Round(($responseTimes | Measure-Object -Minimum).Minimum, 2)
        }
        
        # Calculate success rate
        if ($script:SessionMetadata.TotalCommands -gt 0) {
            $successRate = [Math]::Round($script:SessionMetadata.SuccessfulCommands / $script:SessionMetadata.TotalCommands * 100, 1)
        } else {
            $successRate = 0
        }
        
        $result = @{
            Success = $true
            Metadata = $script:SessionMetadata
            Statistics = @{
                SuccessRate = $successRate
                AverageResponseTimeSeconds = $script:SessionMetadata.AverageResponseTime
                MaxResponseTimeSeconds = $script:SessionMetadata.MaxResponseTime
                MinResponseTimeSeconds = $script:SessionMetadata.MinResponseTime
                SessionDurationMinutes = [Math]::Round(((Get-Date) - $script:SessionMetadata.StartTime).TotalMinutes, 2)
                HistoryItemCount = $script:ConversationHistory.Count
                StateTransitionCount = $script:SessionMetadata.TotalStateTransitions
                ActiveGoalCount = ($script:ConversationGoals | Where-Object { $_.Status -eq "Active" }).Count
            }
        }
        
        Write-StateLog "Retrieved session metadata" -Level "INFO"
        return $result
    }
    catch {
        Write-StateLog "Failed to get session metadata: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

# Private helper function for saving history
function Save-ConversationHistory {
    Write-StateLog "Saving conversation history" -Level "DEBUG"
    
    try {
        if ($script:ConversationHistory.Count -gt 0) {
            $historyData = $script:ConversationHistory | ConvertTo-Json -Depth 10
            Set-Content -Path $script:HistoryPersistencePath -Value $historyData -Force
            
            Write-StateLog "Conversation history saved ($($script:ConversationHistory.Count) items)" -Level "DEBUG"
        }
    }
    catch {
        Write-StateLog "Failed to save conversation history: $_" -Level "WARNING"
    }
}

Export-ModuleMember -Function Add-ConversationHistoryItem, Get-ConversationHistory, Get-ConversationContext, Clear-ConversationHistory, Get-SessionMetadata
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCxQ5OwbR4xbx3X
# Fe/6pqodjLexXh2n3Eq1vxC1wccpGaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIAjs7hjJhYvDWlJ9R8ViLYz4
# QsecGzQwi481nTiIyzgDMA0GCSqGSIb3DQEBAQUABIIBAIXTFMeFW6/QaBArikV+
# 97C+yBTc//tOhSpE10RvloRyXN50hRcvYYF3s3chsdSLXUl1V3CiOgHRdW8wXK5I
# 5pY0bp4N/5lVziDEqCPRL8odaCCRs3akG8UMkZcJKYUWeTLM5YYXK/6lVKfqPy6G
# h8UnWKH4LW3MdD39eiW/BeVg0bM/JNjX4+y/Ur7tz7Go/NLLRBna0uoO01d63daQ
# 7It31ITtxBeB2EMSazPHs8H1mE9HUS/ufVKk1lA0zTIa64+ytC/VNwIzYShM0ZeJ
# 74vFYRtE1/ONXFkDVw1zlzKVz1hGqjtofNuAnwjUP/H09U6MvCZ8/oZUv3Znfe8T
# 1UM=
# SIG # End signature block
