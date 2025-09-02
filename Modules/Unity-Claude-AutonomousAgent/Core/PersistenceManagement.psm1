# PersistenceManagement.psm1  
# State and history persistence management

# Import core module for shared variables
Import-Module (Join-Path $PSScriptRoot "ConversationCore.psm1") -Force

function Save-ConversationState {
    <#
    .SYNOPSIS
    Persists conversation state to disk
    
    .DESCRIPTION
    Saves current state machine status for recovery
    
    .PARAMETER Compress
    Whether to compress the saved data
    #>
    param(
        [switch]$Compress
    )
    
    Write-StateLog "Saving conversation state" -Level "DEBUG"
    
    try {
        if ($null -eq $script:ConversationState) {
            Write-StateLog "No conversation state to save" -Level "WARNING"
            return @{
                Success = $false
                Reason = "No state initialized"
            }
        }
        
        $stateData = $script:ConversationState | ConvertTo-Json -Depth 10
        
        if ($Compress) {
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($stateData)
            $stream = [System.IO.MemoryStream]::new()
            $gzip = [System.IO.Compression.GZipStream]::new($stream, [System.IO.Compression.CompressionLevel]::Optimal)
            $gzip.Write($bytes, 0, $bytes.Length)
            $gzip.Close()
            $compressedData = [Convert]::ToBase64String($stream.ToArray())
            
            $outputPath = $script:StatePersistencePath + ".gz"
            Set-Content -Path $outputPath -Value $compressedData -Force
            Write-StateLog "Conversation state saved (compressed)" -Level "DEBUG"
        }
        else {
            Set-Content -Path $script:StatePersistencePath -Value $stateData -Force
            Write-StateLog "Conversation state saved successfully" -Level "DEBUG"
        }
        
        return @{
            Success = $true
            Path = if ($Compress) { $outputPath } else { $script:StatePersistencePath }
            SizeKB = [Math]::Round((Get-Item (if ($Compress) { $outputPath } else { $script:StatePersistencePath })).Length / 1KB, 2)
        }
    }
    catch {
        Write-StateLog "Failed to save conversation state: $_" -Level "WARNING"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Save-ConversationHistory {
    <#
    .SYNOPSIS
    Persists conversation history to disk
    
    .DESCRIPTION
    Saves conversation history for session recovery
    
    .PARAMETER Compress
    Whether to compress the saved data
    #>
    param(
        [switch]$Compress
    )
    
    Write-StateLog "Saving conversation history" -Level "DEBUG"
    
    try {
        if ($script:ConversationHistory.Count -eq 0) {
            Write-StateLog "No conversation history to save" -Level "DEBUG"
            return @{
                Success = $true
                Reason = "No history to save"
            }
        }
        
        $historyData = $script:ConversationHistory | ConvertTo-Json -Depth 10
        
        if ($Compress) {
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($historyData)
            $stream = [System.IO.MemoryStream]::new()
            $gzip = [System.IO.Compression.GZipStream]::new($stream, [System.IO.Compression.CompressionLevel]::Optimal)
            $gzip.Write($bytes, 0, $bytes.Length)
            $gzip.Close()
            $compressedData = [Convert]::ToBase64String($stream.ToArray())
            
            $outputPath = $script:HistoryPersistencePath + ".gz"
            Set-Content -Path $outputPath -Value $compressedData -Force
            Write-StateLog "Conversation history saved (compressed, $($script:ConversationHistory.Count) items)" -Level "DEBUG"
        }
        else {
            Set-Content -Path $script:HistoryPersistencePath -Value $historyData -Force
            Write-StateLog "Conversation history saved ($($script:ConversationHistory.Count) items)" -Level "DEBUG"
        }
        
        return @{
            Success = $true
            Path = if ($Compress) { $outputPath } else { $script:HistoryPersistencePath }
            ItemCount = $script:ConversationHistory.Count
            SizeKB = [Math]::Round((Get-Item (if ($Compress) { $outputPath } else { $script:HistoryPersistencePath })).Length / 1KB, 2)
        }
    }
    catch {
        Write-StateLog "Failed to save conversation history: $_" -Level "WARNING"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Save-ConversationGoals {
    <#
    .SYNOPSIS
    Persists conversation goals to disk
    
    .DESCRIPTION
    Saves conversation goals for session recovery
    #>
    
    Write-StateLog "Saving conversation goals" -Level "DEBUG"
    
    try {
        if ($script:ConversationGoals.Count -eq 0) {
            Write-StateLog "No conversation goals to save" -Level "DEBUG"
            return @{
                Success = $true
                Reason = "No goals to save"
            }
        }
        
        $goalsData = $script:ConversationGoals | ConvertTo-Json -Depth 10
        Set-Content -Path $script:GoalsPersistencePath -Value $goalsData -Force
        
        Write-StateLog "Conversation goals saved ($($script:ConversationGoals.Count) goals)" -Level "DEBUG"
        
        return @{
            Success = $true
            Path = $script:GoalsPersistencePath
            GoalCount = $script:ConversationGoals.Count
        }
    }
    catch {
        Write-StateLog "Failed to save conversation goals: $_" -Level "WARNING"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Load-ConversationState {
    <#
    .SYNOPSIS
    Loads persisted conversation state
    
    .DESCRIPTION
    Restores conversation state from disk
    
    .PARAMETER Path
    Custom path to load state from
    #>
    param(
        [string]$Path
    )
    
    Write-StateLog "Loading conversation state" -Level "DEBUG"
    
    try {
        # Determine path
        $loadPath = if ($Path) { $Path } 
        elseif (Test-Path ($script:StatePersistencePath + ".gz")) { $script:StatePersistencePath + ".gz" }
        elseif (Test-Path $script:StatePersistencePath) { $script:StatePersistencePath }
        else {
            Write-StateLog "No persisted state file found" -Level "WARNING"
            return @{
                Success = $false
                Reason = "File not found"
            }
        }
        
        # Load and decompress if needed
        if ($loadPath.EndsWith(".gz")) {
            $compressedData = Get-Content $loadPath
            $bytes = [Convert]::FromBase64String($compressedData)
            $stream = [System.IO.MemoryStream]::new($bytes)
            $gzip = [System.IO.Compression.GZipStream]::new($stream, [System.IO.Compression.CompressionMode]::Decompress)
            $reader = [System.IO.StreamReader]::new($gzip)
            $stateData = $reader.ReadToEnd()
            $reader.Close()
        }
        else {
            $stateData = Get-Content $loadPath -Raw
        }
        
        $script:ConversationState = $stateData | ConvertFrom-Json -AsHashtable
        
        Write-StateLog "Loaded conversation state from: $loadPath" -Level "SUCCESS"
        
        return @{
            Success = $true
            LoadedFrom = $loadPath
            SessionId = $script:ConversationState.SessionId
            StateAge = ((Get-Date) - $script:ConversationState.LastStateChange)
        }
    }
    catch {
        Write-StateLog "Failed to load conversation state: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Load-ConversationHistory {
    <#
    .SYNOPSIS
    Loads persisted conversation history
    
    .DESCRIPTION
    Restores conversation history from disk
    
    .PARAMETER Path
    Custom path to load history from
    #>
    param(
        [string]$Path
    )
    
    Write-StateLog "Loading conversation history" -Level "DEBUG"
    
    try {
        # Determine path
        $loadPath = if ($Path) { $Path }
        elseif (Test-Path ($script:HistoryPersistencePath + ".gz")) { $script:HistoryPersistencePath + ".gz" }
        elseif (Test-Path $script:HistoryPersistencePath) { $script:HistoryPersistencePath }
        else {
            Write-StateLog "No persisted history file found" -Level "WARNING"
            return @{
                Success = $false
                Reason = "File not found"
            }
        }
        
        # Load and decompress if needed
        if ($loadPath.EndsWith(".gz")) {
            $compressedData = Get-Content $loadPath
            $bytes = [Convert]::FromBase64String($compressedData)
            $stream = [System.IO.MemoryStream]::new($bytes)
            $gzip = [System.IO.Compression.GZipStream]::new($stream, [System.IO.Compression.CompressionMode]::Decompress)
            $reader = [System.IO.StreamReader]::new($gzip)
            $historyData = $reader.ReadToEnd()
            $reader.Close()
        }
        else {
            $historyData = Get-Content $loadPath -Raw
        }
        
        $script:ConversationHistory = @($historyData | ConvertFrom-Json)
        
        Write-StateLog "Loaded $($script:ConversationHistory.Count) history items from: $loadPath" -Level "SUCCESS"
        
        return @{
            Success = $true
            LoadedFrom = $loadPath
            ItemCount = $script:ConversationHistory.Count
            OldestItem = if ($script:ConversationHistory.Count -gt 0) { $script:ConversationHistory[0].Timestamp } else { $null }
            NewestItem = if ($script:ConversationHistory.Count -gt 0) { $script:ConversationHistory[-1].Timestamp } else { $null }
        }
    }
    catch {
        Write-StateLog "Failed to load conversation history: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Load-ConversationGoals {
    <#
    .SYNOPSIS
    Loads persisted conversation goals
    
    .DESCRIPTION
    Restores conversation goals from disk
    #>
    
    Write-StateLog "Loading conversation goals" -Level "DEBUG"
    
    try {
        if (-not (Test-Path $script:GoalsPersistencePath)) {
            Write-StateLog "No persisted goals file found" -Level "WARNING"
            return @{
                Success = $false
                Reason = "File not found"
            }
        }
        
        $goalsData = Get-Content $script:GoalsPersistencePath -Raw
        $script:ConversationGoals = @($goalsData | ConvertFrom-Json)
        
        Write-StateLog "Loaded $($script:ConversationGoals.Count) goals" -Level "SUCCESS"
        
        return @{
            Success = $true
            GoalCount = $script:ConversationGoals.Count
            ActiveGoals = ($script:ConversationGoals | Where-Object { $_.Status -eq "Active" }).Count
            CompletedGoals = ($script:ConversationGoals | Where-Object { $_.Status -eq "Completed" }).Count
        }
    }
    catch {
        Write-StateLog "Failed to load conversation goals: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Export-ConversationSession {
    <#
    .SYNOPSIS
    Exports complete conversation session
    
    .DESCRIPTION
    Creates comprehensive export of entire conversation session
    
    .PARAMETER Path
    Directory to export session to
    
    .PARAMETER Format
    Export format (JSON, XML, CSV)
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [ValidateSet("JSON", "XML", "CSV")]
        [string]$Format = "JSON"
    )
    
    Write-StateLog "Exporting conversation session to: $Path" -Level "INFO"
    
    try {
        # Create export directory
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -ItemType Directory -Force | Out-Null
        }
        
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $sessionExport = @{
            ExportTimestamp = Get-Date
            SessionId = $script:ConversationState.SessionId
            State = $script:ConversationState
            History = $script:ConversationHistory
            Goals = $script:ConversationGoals
            RoleAwareHistory = $script:RoleAwareHistory
            DialoguePatterns = $script:DialoguePatterns
            Effectiveness = $script:ConversationEffectiveness
            SessionMetadata = $script:SessionMetadata
        }
        
        switch ($Format) {
            "JSON" {
                $exportPath = Join-Path $Path "conversation_export_${timestamp}.json"
                $sessionExport | ConvertTo-Json -Depth 10 | Set-Content -Path $exportPath
            }
            "XML" {
                $exportPath = Join-Path $Path "conversation_export_${timestamp}.xml"
                $sessionExport | ConvertTo-Xml -Depth 10 -As String | Set-Content -Path $exportPath
            }
            "CSV" {
                # Export history as CSV (simplified)
                $exportPath = Join-Path $Path "conversation_history_${timestamp}.csv"
                $script:ConversationHistory | Export-Csv -Path $exportPath -NoTypeInformation
                
                # Export goals as separate CSV
                $goalsPath = Join-Path $Path "conversation_goals_${timestamp}.csv"
                $script:ConversationGoals | Export-Csv -Path $goalsPath -NoTypeInformation
            }
        }
        
        Write-StateLog "Session exported successfully" -Level "SUCCESS"
        
        return @{
            Success = $true
            ExportPath = $exportPath
            Format = $Format
            ItemsExported = @{
                History = $script:ConversationHistory.Count
                Goals = $script:ConversationGoals.Count
                RoleAwareHistory = $script:RoleAwareHistory.Count
            }
        }
    }
    catch {
        Write-StateLog "Failed to export conversation session: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Import-ConversationSession {
    <#
    .SYNOPSIS
    Imports conversation session from export
    
    .DESCRIPTION
    Restores conversation session from previous export
    
    .PARAMETER Path
    Path to import file
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    Write-StateLog "Importing conversation session from: $Path" -Level "INFO"
    
    try {
        if (-not (Test-Path $Path)) {
            throw "Import file not found: $Path"
        }
        
        $extension = [System.IO.Path]::GetExtension($Path).ToLower()
        
        switch ($extension) {
            ".json" {
                $sessionData = Get-Content $Path -Raw | ConvertFrom-Json -AsHashtable
                
                # Restore all components
                $script:ConversationState = $sessionData.State
                $script:ConversationHistory = @($sessionData.History)
                $script:ConversationGoals = @($sessionData.Goals)
                $script:RoleAwareHistory = @($sessionData.RoleAwareHistory)
                $script:DialoguePatterns = $sessionData.DialoguePatterns
                $script:ConversationEffectiveness = $sessionData.Effectiveness
                $script:SessionMetadata = $sessionData.SessionMetadata
            }
            ".xml" {
                [xml]$xmlData = Get-Content $Path
                # XML import would require custom parsing logic
                throw "XML import not yet implemented"
            }
            ".csv" {
                # CSV only contains history, not full session
                $script:ConversationHistory = @(Import-Csv -Path $Path)
            }
            default {
                throw "Unsupported import format: $extension"
            }
        }
        
        Write-StateLog "Session imported successfully" -Level "SUCCESS"
        
        return @{
            Success = $true
            SessionId = $script:ConversationState.SessionId
            ItemsImported = @{
                History = $script:ConversationHistory.Count
                Goals = $script:ConversationGoals.Count
                RoleAwareHistory = $script:RoleAwareHistory.Count
            }
        }
    }
    catch {
        Write-StateLog "Failed to import conversation session: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

Export-ModuleMember -Function Save-ConversationState, Save-ConversationHistory, Save-ConversationGoals, 
                              Load-ConversationState, Load-ConversationHistory, Load-ConversationGoals,
                              Export-ConversationSession, Import-ConversationSession
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBLjAtzZpmUXwVi
# TicWH0xSFTorLH05cC3ccfDaEPQVaaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIOWceP7oi0bOMH6Ecic3uKxo
# L5/dmdRUaAwLF0M9g3v0MA0GCSqGSIb3DQEBAQUABIIBAK3BZSgNgi7F4Mr/03BS
# U5qUNRXQlBEkpQ6uFZ5Xa2Z22oTe+PDpHMpltZvYSVOpini99OKmM/v56r0pWgVR
# JJTgyxW4JvkqjvZY/loiDPI+nOTNrWDa1dcfA96t87N4Umm4eI2VgtxJq3SjIKUS
# lWXWaDg/2yokueDvuTvKcavJRPVAJIEKSaeG4346mykJ3UT8jZ6+/ahgEKCdlAVq
# 7dnhe5RQBLnoBBRFkndF+rdxJDbahdHYObJaUawIZ9our0CwgjY2gbSQfzTKTPTe
# DfZq1GO5afU5067AqjRAlPgKhbKwOcJ3ZwPw6JHw7vPC++JUoMreeai2I5bK52y/
# DCk=
# SIG # End signature block
