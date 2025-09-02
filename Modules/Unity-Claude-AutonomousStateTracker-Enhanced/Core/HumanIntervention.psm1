# HumanIntervention.psm1
# Human intervention system for autonomous state tracking
# Refactored component from Unity-Claude-AutonomousStateTracker-Enhanced.psm1
# Component: Human intervention system (240 lines)

#region Human Intervention System

function Request-HumanIntervention {
    <#
    .SYNOPSIS
    Request human intervention with multiple notification methods
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AgentId,
        
        [Parameter(Mandatory = $true)]
        [string]$Reason,
        
        [ValidateSet("Low", "Medium", "High", "Critical")]
        [string]$Priority = "Medium",
        
        [hashtable]$Context = @{}
    )
    
    try {
        $stateConfig = Get-EnhancedStateConfig
        
        $timestamp = Get-Date
        $interventionId = New-Guid | Select-Object -ExpandProperty Guid
        
        # Create intervention record
        $intervention = @{
            InterventionId = $interventionId
            AgentId = $AgentId
            Timestamp = $timestamp
            Reason = $Reason
            Priority = $Priority
            Context = $Context
            Status = "Requested"
            ResponseDeadline = $timestamp.AddSeconds($stateConfig.HumanApprovalTimeout)
            ResolutionTime = $null
            Response = $null
        }
        
        # Update agent state
        $agentState = Get-AgentState -AgentId $AgentId
        if ($agentState) {
            $agentState.HumanInterventionRequested = $true
            $agentState.InterventionHistory = @($agentState.InterventionHistory) + @($intervention)
            Save-AgentState -AgentState $agentState
        }
        
        # Log intervention request
        Write-EnhancedStateLog -Message "Human intervention requested: $Reason" -Level "INTERVENTION" -AdditionalData @{
            InterventionId = $interventionId
            Priority = $Priority
            AgentId = $AgentId
        }
        
        # Send notifications based on configuration
        foreach ($method in $stateConfig.NotificationMethods) {
            switch ($method) {
                "Console" {
                    $message = @"
[HUMAN INTERVENTION REQUIRED]
Agent: $AgentId
Priority: $Priority
Reason: $Reason
Intervention ID: $interventionId
Response required by: $($intervention.ResponseDeadline)

Actions available:
- Use 'Approve-AgentIntervention -InterventionId $interventionId' to approve
- Use 'Deny-AgentIntervention -InterventionId $interventionId -Reason "explanation"' to deny
- Use 'Get-PendingInterventions -AgentId $AgentId' to view all pending interventions
"@
                    Write-Host $message -ForegroundColor Yellow -BackgroundColor DarkRed
                }
                "File" {
                    $interventionFile = Join-Path $stateConfig.StateDataPath "pending_interventions.json"
                    $existingInterventions = if (Test-Path $interventionFile) {
                        $existingData = ConvertTo-HashTable -Object (Get-Content $interventionFile -Raw | ConvertFrom-Json) -Recurse
                        if ($existingData -is [Array]) { $existingData } else { @() }
                    } else {
                        @()
                    }
                    $existingInterventions = @($existingInterventions) + @($intervention)
                    $existingInterventions | ConvertTo-Json -Depth 10 | Out-File -FilePath $interventionFile -Encoding UTF8
                }
            }
        }
        
        return $interventionId
        
    } catch {
        Write-EnhancedStateLog -Message "Failed to request human intervention: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Approve-AgentIntervention {
    <#
    .SYNOPSIS
    Approve a pending human intervention request
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InterventionId,
        
        [string]$Response = "Approved",
        
        [string]$NextAction = "Continue"
    )
    
    try {
        # Find and update intervention
        $updated = Update-InterventionStatus -InterventionId $InterventionId -Status "Approved" -Response $Response
        
        if ($updated) {
            Write-EnhancedStateLog -Message "Human intervention approved: $InterventionId" -Level "INTERVENTION" -AdditionalData @{
                Response = $Response
                NextAction = $NextAction
            }
            
            # Update agent state to clear intervention flag
            $agentState = Get-AgentState -AgentId $updated.AgentId
            if ($agentState) {
                $agentState.HumanInterventionRequested = $false
                Save-AgentState -AgentState $agentState
                
                # Transition to appropriate state based on next action
                switch ($NextAction) {
                    "Continue" { 
                        if ($agentState.CurrentState -ne "Active") {
                            Set-EnhancedAutonomousState -AgentId $updated.AgentId -NewState "Active" -Reason "Human intervention approved"
                        }
                    }
                    "Pause" { Set-EnhancedAutonomousState -AgentId $updated.AgentId -NewState "Paused" -Reason "Human intervention approved - paused" }
                    "Stop" { Set-EnhancedAutonomousState -AgentId $updated.AgentId -NewState "Stopped" -Reason "Human intervention approved - stopped" }
                }
            }
            
            return $true
        }
        
        return $false
        
    } catch {
        Write-EnhancedStateLog -Message "Failed to approve intervention: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Deny-AgentIntervention {
    <#
    .SYNOPSIS
    Deny a pending human intervention request
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InterventionId,
        
        [Parameter(Mandatory = $true)]
        [string]$Reason
    )
    
    try {
        $updated = Update-InterventionStatus -InterventionId $InterventionId -Status "Denied" -Response $Reason
        
        if ($updated) {
            Write-EnhancedStateLog -Message "Human intervention denied: $InterventionId" -Level "INTERVENTION" -AdditionalData @{
                Reason = $Reason
            }
            
            # Update agent state
            $agentState = Get-AgentState -AgentId $updated.AgentId
            if ($agentState) {
                $agentState.HumanInterventionRequested = $false
                Save-AgentState -AgentState $agentState
                
                # Transition to paused state for manual resolution
                Set-EnhancedAutonomousState -AgentId $updated.AgentId -NewState "Paused" -Reason "Human intervention denied: $Reason"
            }
            
            return $true
        }
        
        return $false
        
    } catch {
        Write-EnhancedStateLog -Message "Failed to deny intervention: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Update-InterventionStatus {
    <#
    .SYNOPSIS
    Update intervention status in persistent storage
    #>
    [CmdletBinding()]
    param(
        [string]$InterventionId,
        [string]$Status,
        [string]$Response
    )
    
    try {
        $stateConfig = Get-EnhancedStateConfig
        $interventionFile = Join-Path $stateConfig.StateDataPath "pending_interventions.json"
        
        if (-not (Test-Path $interventionFile)) {
            return $null
        }
        
        $interventionsData = ConvertTo-HashTable -Object (Get-Content $interventionFile -Raw | ConvertFrom-Json) -Recurse
        $interventions = if ($interventionsData -is [Array]) { $interventionsData } else { @($interventionsData) }
        $targetIntervention = $interventions | Where-Object { $_.InterventionId -eq $InterventionId }
        
        if ($targetIntervention) {
            $targetIntervention.Status = $Status
            $targetIntervention.Response = $Response
            $targetIntervention.ResolutionTime = Get-Date
            
            # Save updated interventions
            $interventions | ConvertTo-Json -Depth 10 | Out-File -FilePath $interventionFile -Encoding UTF8
            
            return $targetIntervention
        }
        
        return $null
        
    } catch {
        Write-EnhancedStateLog -Message "Failed to update intervention status: $($_.Exception.Message)" -Level "ERROR"
        return $null
    }
}

function Get-PendingInterventions {
    <#
    .SYNOPSIS
    Get all pending intervention requests
    #>
    [CmdletBinding()]
    param(
        [string]$AgentId
    )
    
    try {
        $stateConfig = Get-EnhancedStateConfig
        $interventionFile = Join-Path $stateConfig.StateDataPath "pending_interventions.json"
        
        if (-not (Test-Path $interventionFile)) {
            return @()
        }
        
        $interventionsData = ConvertTo-HashTable -Object (Get-Content $interventionFile -Raw | ConvertFrom-Json) -Recurse
        $interventions = if ($interventionsData -is [Array]) { $interventionsData } else { @($interventionsData) }
        
        # Filter by agent if specified
        if ($AgentId) {
            $interventions = $interventions | Where-Object { $_.AgentId -eq $AgentId }
        }
        
        # Filter to only pending (not resolved) interventions
        $pending = $interventions | Where-Object { $_.Status -eq "Requested" }
        
        return $pending
        
    } catch {
        Write-EnhancedStateLog -Message "Failed to get pending interventions: $($_.Exception.Message)" -Level "ERROR"
        return @()
    }
}

function Clear-ResolvedInterventions {
    <#
    .SYNOPSIS
    Clean up resolved intervention requests from pending file
    #>
    [CmdletBinding()]
    param(
        [int]$OlderThanDays = 7
    )
    
    try {
        $stateConfig = Get-EnhancedStateConfig
        $interventionFile = Join-Path $stateConfig.StateDataPath "pending_interventions.json"
        
        if (-not (Test-Path $interventionFile)) {
            return 0
        }
        
        $interventionsData = ConvertTo-HashTable -Object (Get-Content $interventionFile -Raw | ConvertFrom-Json) -Recurse
        $interventions = if ($interventionsData -is [Array]) { $interventionsData } else { @($interventionsData) }
        
        $cutoffDate = (Get-Date).AddDays(-$OlderThanDays)
        
        # Keep only recent or unresolved interventions
        $filteredInterventions = $interventions | Where-Object {
            $interventionDate = [DateTime]$_.Timestamp
            $_.Status -eq "Requested" -or $interventionDate -gt $cutoffDate
        }
        
        $removedCount = $interventions.Count - $filteredInterventions.Count
        
        if ($removedCount -gt 0) {
            # Save filtered interventions
            $filteredInterventions | ConvertTo-Json -Depth 10 | Out-File -FilePath $interventionFile -Encoding UTF8
            
            Write-EnhancedStateLog -Message "Cleaned up $removedCount resolved interventions older than $OlderThanDays days" -Level "INFO"
        }
        
        return $removedCount
        
    } catch {
        Write-EnhancedStateLog -Message "Failed to clear resolved interventions: $($_.Exception.Message)" -Level "ERROR"
        return 0
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Request-HumanIntervention',
    'Approve-AgentIntervention',
    'Deny-AgentIntervention',
    'Update-InterventionStatus',
    'Get-PendingInterventions',
    'Clear-ResolvedInterventions'
)

#endregion
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAkhdg4PqhsMd9H
# pag0Z+iwuMwP8p9su2oVUbawCj/4FqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIFVoBbCuLDMFS2bMnkEM7c5/
# EN3kozAQbMhmj2idClInMA0GCSqGSIb3DQEBAQUABIIBACth8f5F2Lc8tBkWaEVt
# IEDgjJ9PXeN/Gs8auW3IoVLe7WJTfdGur0rVwPG7GvP8gx/9wH/wWDb4BSsUC38K
# gO7KKupleXWopb59vb2EH8sKQbIakDimoXlBDMfXJMcDK/Xky3DQjne3FTL57ZxG
# 4Do4lsALCZSMrFNum6e5gQG2SIqMRpPoIobk7fnvpVLxQpcGi41dhsbCywH6Y0Eg
# /ED1fXjdMqmFiRDJeDTK+P+DsJ3U9Cgvb8EXNDmU8amUPjsXBG6g1lV8dsxG3sJn
# shdwwJUItdol8y4+Ib+Dw1P4RF7GMECt3YXFhhX+F6rEc421FJsBQnaG7vnwxWsO
# +nM=
# SIG # End signature block
