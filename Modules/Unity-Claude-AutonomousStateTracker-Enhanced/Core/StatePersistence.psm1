# StatePersistence.psm1
# State persistence and recovery functions for autonomous state tracking
# Refactored component from Unity-Claude-AutonomousStateTracker-Enhanced.psm1
# Component: State persistence and recovery (200 lines)

#region State Persistence and Recovery

function New-StateCheckpoint {
    <#
    .SYNOPSIS
    Create a state checkpoint for recovery purposes (based on research findings)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$AgentState,
        
        [string]$Reason = "Scheduled checkpoint"
    )
    
    try {
        $stateConfig = Get-EnhancedStateConfig
        
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $checkpointId = "$($AgentState.AgentId)-$timestamp"
        $checkpointFile = Join-Path $stateConfig.CheckpointPath "$checkpointId.json"
        
        # Create checkpoint data
        $checkpoint = @{
            CheckpointId = $checkpointId
            AgentId = $AgentState.AgentId
            Timestamp = Get-Date
            Reason = $Reason
            AgentState = $AgentState
            SystemState = Get-SystemPerformanceMetrics
            PowerShellProcess = @{
                PID = $PID
                WorkingSet = (Get-Process -Id $PID).WorkingSet64
                StartTime = Get-SafeDateTime -DateTimeObject (Get-Process -Id $PID).StartTime
            }
        }
        
        # Save checkpoint
        $checkpoint | ConvertTo-Json -Depth 15 | Out-File -FilePath $checkpointFile -Encoding UTF8
        
        # Update agent state with checkpoint reference
        $checkpointEntry = @{
            CheckpointId = $checkpointId
            Timestamp = Get-Date
            Reason = $Reason
            FilePath = $checkpointFile
        }
        $AgentState.CheckpointHistory = @($AgentState.CheckpointHistory) + @($checkpointEntry)
        
        # Trim checkpoint history
        if ($AgentState.CheckpointHistory.Count -gt 50) {
            $AgentState.CheckpointHistory = $AgentState.CheckpointHistory | Select-Object -Last 50
        }
        
        Write-EnhancedStateLog -Message "State checkpoint created: $checkpointId" -Level "INFO" -AdditionalData @{ Reason = $Reason }
        
        return $checkpointId
        
    } catch {
        Write-EnhancedStateLog -Message "Failed to create state checkpoint: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Restore-AgentStateFromCheckpoint {
    <#
    .SYNOPSIS
    Restore agent state from the most recent checkpoint
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AgentId,
        
        [string]$CheckpointId
    )
    
    try {
        $stateConfig = Get-EnhancedStateConfig
        
        $checkpointFiles = Get-ChildItem -Path $stateConfig.CheckpointPath -Filter "$AgentId-*.json" | 
                          Sort-Object LastWriteTime -Descending
        
        if (-not $checkpointFiles) {
            Write-EnhancedStateLog -Message "No checkpoints found for agent: $AgentId" -Level "WARNING"
            return $null
        }
        
        $targetCheckpoint = if ($CheckpointId) {
            $checkpointFiles | Where-Object { $_.BaseName -eq $CheckpointId } | Select-Object -First 1
        } else {
            $checkpointFiles | Select-Object -First 1  # Most recent
        }
        
        if (-not $targetCheckpoint) {
            Write-EnhancedStateLog -Message "Checkpoint not found: $CheckpointId" -Level "WARNING"
            return $null
        }
        
        # Load checkpoint data
        $checkpointJson = Get-Content $targetCheckpoint.FullName -Raw
        $checkpointData = ConvertTo-HashTable -Object ($checkpointJson | ConvertFrom-Json) -Recurse
        
        # Extract agent state
        $restoredState = $checkpointData.AgentState
        
        # Update restoration metadata
        $restoredState.RestoredFromCheckpoint = $checkpointData.CheckpointId
        $restoredState.RestoredAt = Get-Date
        
        Write-EnhancedStateLog -Message "Agent state restored from checkpoint: $($checkpointData.CheckpointId)" -Level "INFO" -AdditionalData @{
            AgentId = $AgentId
            CheckpointTimestamp = $checkpointData.Timestamp
        }
        
        return $restoredState
        
    } catch {
        Write-EnhancedStateLog -Message "Failed to restore from checkpoint: $($_.Exception.Message)" -Level "ERROR"
        return $null
    }
}

function Get-CheckpointHistory {
    <#
    .SYNOPSIS
    Get checkpoint history for an agent
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AgentId,
        
        [int]$Limit = 20
    )
    
    try {
        $stateConfig = Get-EnhancedStateConfig
        
        $checkpointFiles = Get-ChildItem -Path $stateConfig.CheckpointPath -Filter "$AgentId-*.json" | 
                          Sort-Object LastWriteTime -Descending |
                          Select-Object -First $Limit
        
        $checkpoints = @()
        
        foreach ($file in $checkpointFiles) {
            try {
                $checkpointJson = Get-Content $file.FullName -Raw
                $checkpointData = $checkpointJson | ConvertFrom-Json
                
                $checkpoints += @{
                    CheckpointId = $checkpointData.CheckpointId
                    AgentId = $checkpointData.AgentId
                    Timestamp = $checkpointData.Timestamp
                    Reason = $checkpointData.Reason
                    FilePath = $file.FullName
                    FileSize = [math]::Round($file.Length / 1KB, 2)
                }
            } catch {
                Write-EnhancedStateLog -Message "Failed to read checkpoint file: $($file.Name)" -Level "WARNING"
            }
        }
        
        return $checkpoints
        
    } catch {
        Write-EnhancedStateLog -Message "Failed to get checkpoint history: $($_.Exception.Message)" -Level "ERROR"
        return @()
    }
}

function Remove-OldCheckpoints {
    <#
    .SYNOPSIS
    Clean up old checkpoints based on retention policy
    #>
    [CmdletBinding()]
    param(
        [string]$AgentId,
        [int]$RetentionDays
    )
    
    try {
        $stateConfig = Get-EnhancedStateConfig
        
        if (-not $RetentionDays) {
            $RetentionDays = $stateConfig.BackupRetentionDays
        }
        
        $cutoffDate = (Get-Date).AddDays(-$RetentionDays)
        
        $filter = if ($AgentId) { "$AgentId-*.json" } else { "*.json" }
        
        $oldCheckpoints = Get-ChildItem -Path $stateConfig.CheckpointPath -Filter $filter | 
                         Where-Object { $_.LastWriteTime -lt $cutoffDate }
        
        $removedCount = 0
        foreach ($checkpoint in $oldCheckpoints) {
            try {
                Remove-Item $checkpoint.FullName -Force
                $removedCount++
            } catch {
                Write-EnhancedStateLog -Message "Failed to remove old checkpoint: $($checkpoint.Name)" -Level "WARNING"
            }
        }
        
        if ($removedCount -gt 0) {
            Write-EnhancedStateLog -Message "Removed $removedCount old checkpoints (older than $RetentionDays days)" -Level "INFO"
        }
        
        return $removedCount
        
    } catch {
        Write-EnhancedStateLog -Message "Failed to clean up old checkpoints: $($_.Exception.Message)" -Level "ERROR"
        return 0
    }
}

function Test-CheckpointIntegrity {
    <#
    .SYNOPSIS
    Test the integrity of checkpoint files
    #>
    [CmdletBinding()]
    param(
        [string]$AgentId
    )
    
    try {
        $stateConfig = Get-EnhancedStateConfig
        
        $filter = if ($AgentId) { "$AgentId-*.json" } else { "*.json" }
        
        $checkpointFiles = Get-ChildItem -Path $stateConfig.CheckpointPath -Filter $filter
        
        $results = @()
        
        foreach ($file in $checkpointFiles) {
            $integrity = @{
                FileName = $file.Name
                FilePath = $file.FullName
                FileSize = $file.Length
                LastModified = $file.LastWriteTime
                IsValid = $false
                Error = $null
            }
            
            try {
                $checkpointJson = Get-Content $file.FullName -Raw
                $checkpointData = $checkpointJson | ConvertFrom-Json
                
                # Validate required fields
                if ($checkpointData.CheckpointId -and 
                    $checkpointData.AgentId -and 
                    $checkpointData.Timestamp -and 
                    $checkpointData.AgentState) {
                    $integrity.IsValid = $true
                }
            } catch {
                $integrity.Error = $_.Exception.Message
            }
            
            $results += $integrity
        }
        
        return $results
        
    } catch {
        Write-EnhancedStateLog -Message "Failed to test checkpoint integrity: $($_.Exception.Message)" -Level "ERROR"
        return @()
    }
}

# Export functions
Export-ModuleMember -Function @(
    'New-StateCheckpoint',
    'Restore-AgentStateFromCheckpoint',
    'Get-CheckpointHistory',
    'Remove-OldCheckpoints',
    'Test-CheckpointIntegrity'
)

#endregion
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB3Fa1W/eVDXoii
# g4LXtheRFZXohH0eSr4R6xpcuILq9aCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIERWve6TjYmfK9aTZ4FfOTED
# 98z1LcoLuEG6h9R//dLAMA0GCSqGSIb3DQEBAQUABIIBACIJI3XsMv9eioM/C2Dg
# Yfnh1Bva16i8AWkACvROMgd/bdJgH/zhsVtZeu2I4dSce/EcCDYnr5tDsLQhbtAO
# 880PeTEv1d4qE3YuENU3BhHjvmSmwheYMlDvxNy+h8dlYg7SV+76PPSGenrpAisP
# h0W7Mq9w7PJMFcSLopyqAI1oAmx4S6RB9ggr1DYteN5PVYLkUE3y30/9rRQq9oxh
# QTrv/IlrpKz7kOAr9mrD/G+dwpCz7NVaRKhe3S/RoXgr0aupjPbeeorWJO4Ytwhu
# Q1Q7aExtTZdt7jW952Q7SFGz5bzC2D1iRlz+vjtidKlD2GSOLL/5ncqVH7qfGeUO
# j8E=
# SIG # End signature block
