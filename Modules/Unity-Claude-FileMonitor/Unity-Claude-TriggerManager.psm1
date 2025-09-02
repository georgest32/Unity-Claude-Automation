# Unity-Claude-TriggerManager Module
# Advanced trigger conditions and priority-based processing for file changes

# Module-level variables
$script:TriggerConditions = @{}
$script:ExclusionPatterns = @()
$script:ProcessingQueue = [System.Collections.Generic.PriorityQueue[object, int]]::new()
$script:TriggerHandlers = @{}
$script:ProcessingActive = $false

# Default trigger conditions
$script:DefaultTriggers = @{
    CodeChange = @{
        Patterns = @('*.ps1', '*.psm1', '*.cs', '*.js', '*.ts', '*.py')
        MinPriority = 2
        Actions = @('UpdateDocumentation', 'RunAnalysis')
        Cooldown = 300  # 5 minutes
        BatchSize = 10
    }
    ConfigChange = @{
        Patterns = @('*.json', '*.xml', '*.yaml', '*.yml', '*.config')
        MinPriority = 3
        Actions = @('ValidateConfig', 'UpdateDocumentation')
        Cooldown = 60   # 1 minute
        BatchSize = 5
    }
    BuildFileChange = @{
        Patterns = @('*.csproj', '*.sln', 'package.json', '*.gradle')
        MinPriority = 1
        Actions = @('FullAnalysis', 'UpdateArchitecture', 'RunTests')
        Cooldown = 600  # 10 minutes
        BatchSize = 1
    }
    DocumentationChange = @{
        Patterns = @('*.md', '*.txt', '*.rst')
        MinPriority = 4
        Actions = @('ValidateLinks', 'UpdateIndex')
        Cooldown = 30   # 30 seconds
        BatchSize = 20
    }
    TestChange = @{
        Patterns = @('*test*.ps1', '*test*.cs', '*spec*.js', '*test*.py')
        MinPriority = 5
        Actions = @('RunTests', 'UpdateCoverage')
        Cooldown = 120  # 2 minutes
        BatchSize = 15
    }
}

# Default exclusion patterns
$script:DefaultExclusions = @(
    '*.tmp', '*.temp', '*.log', '*.cache',
    'node_modules\*', '.git\*', 'bin\*', 'obj\*',
    '*.lock', '*.pid', '*~', '.DS_Store'
)

function Initialize-TriggerManager {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [hashtable]$CustomTriggers = @{},
        
        [Parameter(Mandatory = $false)]
        [string[]]$CustomExclusions = @()
    )
    
    Write-Verbose "[Initialize-TriggerManager] Starting trigger manager initialization"
    
    # Initialize triggers with defaults and custom overrides
    $script:TriggerConditions = $script:DefaultTriggers.Clone()
    
    # Merge custom triggers
    foreach ($triggerName in $CustomTriggers.Keys) {
        if ($script:TriggerConditions.ContainsKey($triggerName)) {
            # Merge with existing
            $existing = $script:TriggerConditions[$triggerName]
            $custom = $CustomTriggers[$triggerName]
            
            foreach ($property in $custom.Keys) {
                $existing[$property] = $custom[$property]
            }
        } else {
            # Add new trigger
            $script:TriggerConditions[$triggerName] = $CustomTriggers[$triggerName]
        }
    }
    
    # Initialize exclusions
    $script:ExclusionPatterns = $script:DefaultExclusions + $CustomExclusions
    
    # Initialize last triggered times
    foreach ($triggerName in $script:TriggerConditions.Keys) {
        $script:TriggerConditions[$triggerName]['LastTriggered'] = [DateTime]::MinValue
        $script:TriggerConditions[$triggerName]['PendingChanges'] = @()
    }
    
    Write-Verbose "[Initialize-TriggerManager] Initialized $($script:TriggerConditions.Count) triggers and $($script:ExclusionPatterns.Count) exclusion patterns"
}

function Test-FileExclusion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    $fileName = [System.IO.Path]::GetFileName($FilePath)
    $relativePath = $FilePath
    
    foreach ($pattern in $script:ExclusionPatterns) {
        if ($fileName -like $pattern -or $relativePath -like $pattern) {
            Write-Verbose "[Test-FileExclusion] File excluded by pattern '$pattern': $FilePath"
            return $true
        }
    }
    
    return $false
}

function Find-MatchingTriggers {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$FileChange
    )
    
    $matchingTriggers = @()
    $fileName = [System.IO.Path]::GetFileName($FileChange.FullPath)
    
    foreach ($triggerName in $script:TriggerConditions.Keys) {
        $trigger = $script:TriggerConditions[$triggerName]
        
        # Check if file matches any pattern for this trigger
        $patternMatch = $false
        foreach ($pattern in $trigger.Patterns) {
            if ($fileName -like $pattern) {
                $patternMatch = $true
                break
            }
        }
        
        # Check priority threshold
        $priorityMatch = $FileChange.Priority -le $trigger.MinPriority
        
        if ($patternMatch -and $priorityMatch) {
            $matchingTriggers += $triggerName
            Write-Verbose "[Find-MatchingTriggers] File $fileName matches trigger '$triggerName'"
        }
    }
    
    return $matchingTriggers
}

function Test-TriggerCooldown {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TriggerName
    )
    
    $trigger = $script:TriggerConditions[$TriggerName]
    $cooldownSeconds = $trigger.Cooldown
    $lastTriggered = $trigger.LastTriggered
    
    $timeSinceLastTrigger = (Get-Date) - $lastTriggered
    $onCooldown = $timeSinceLastTrigger.TotalSeconds -lt $cooldownSeconds
    
    if ($onCooldown) {
        $remainingSeconds = [Math]::Ceiling($cooldownSeconds - $timeSinceLastTrigger.TotalSeconds)
        Write-Verbose "[Test-TriggerCooldown] Trigger '$TriggerName' on cooldown for $remainingSeconds more seconds"
    }
    
    return $onCooldown
}

function Add-ChangeToTrigger {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TriggerName,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$FileChange
    )
    
    $trigger = $script:TriggerConditions[$TriggerName]
    
    # Add to pending changes
    $trigger.PendingChanges += $FileChange
    
    Write-Verbose "[Add-ChangeToTrigger] Added change to trigger '$TriggerName'. Pending: $($trigger.PendingChanges.Count), Batch Size: $($trigger.BatchSize)"
    
    # Check if batch size reached or cooldown expired
    $batchReady = $trigger.PendingChanges.Count -ge $trigger.BatchSize
    $cooldownExpired = -not (Test-TriggerCooldown -TriggerName $TriggerName)
    
    if ($batchReady -or $cooldownExpired) {
        Write-Verbose "[Add-ChangeToTrigger] Trigger '$TriggerName' ready to fire: BatchReady=$batchReady, CooldownExpired=$cooldownExpired"
        Invoke-Trigger -TriggerName $TriggerName
    }
}

function Invoke-Trigger {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TriggerName
    )
    
    $trigger = $script:TriggerConditions[$TriggerName]
    $pendingChanges = $trigger.PendingChanges
    
    if ($pendingChanges.Count -eq 0) {
        Write-Verbose "[Invoke-Trigger] No pending changes for trigger '$TriggerName'"
        return
    }
    
    Write-Verbose "[Invoke-Trigger] Firing trigger '$TriggerName' with $($pendingChanges.Count) changes"
    
    # Create trigger event
    $triggerEvent = @{
        TriggerName = $TriggerName
        Actions = $trigger.Actions
        Changes = $pendingChanges
        Priority = ($pendingChanges.Priority | Measure-Object -Minimum).Minimum
        Timestamp = Get-Date
        BatchSize = $pendingChanges.Count
    }
    
    # Add to processing queue with priority
    $script:ProcessingQueue.Enqueue($triggerEvent, $triggerEvent.Priority)
    
    # Update last triggered time and clear pending changes
    $trigger.LastTriggered = Get-Date
    $trigger.PendingChanges = @()
    
    # Call registered handlers
    foreach ($handlerName in $script:TriggerHandlers.Keys) {
        try {
            $handler = $script:TriggerHandlers[$handlerName]
            & $handler -TriggerEvent $triggerEvent
        }
        catch {
            Write-Warning "[Invoke-Trigger] Handler '$handlerName' error: $_"
        }
    }
    
    # Start processing if not already active
    if (-not $script:ProcessingActive) {
        Start-TriggerProcessing
    }
}

function Start-TriggerProcessing {
    [CmdletBinding()]
    param()
    
    if ($script:ProcessingActive) {
        Write-Verbose "[Start-TriggerProcessing] Processing already active"
        return
    }
    
    $script:ProcessingActive = $true
    Write-Verbose "[Start-TriggerProcessing] Starting trigger processing"
    
    try {
        while ($script:ProcessingQueue.Count -gt 0) {
            $triggerEvent = $script:ProcessingQueue.Dequeue()
            
            Write-Verbose "[Start-TriggerProcessing] Processing trigger '$($triggerEvent.TriggerName)' with priority $($triggerEvent.Priority)"
            
            # Process each action
            foreach ($action in $triggerEvent.Actions) {
                Write-Verbose "[Start-TriggerProcessing] Executing action: $action"
                
                try {
                    switch ($action) {
                        'UpdateDocumentation' {
                            Invoke-DocumentationUpdate -TriggerEvent $triggerEvent
                        }
                        'RunAnalysis' {
                            Invoke-CodeAnalysis -TriggerEvent $triggerEvent
                        }
                        'ValidateConfig' {
                            Invoke-ConfigValidation -TriggerEvent $triggerEvent
                        }
                        'FullAnalysis' {
                            Invoke-FullAnalysis -TriggerEvent $triggerEvent
                        }
                        'UpdateArchitecture' {
                            Invoke-ArchitectureUpdate -TriggerEvent $triggerEvent
                        }
                        'RunTests' {
                            Invoke-TestExecution -TriggerEvent $triggerEvent
                        }
                        'ValidateLinks' {
                            Invoke-LinkValidation -TriggerEvent $triggerEvent
                        }
                        'UpdateIndex' {
                            Invoke-IndexUpdate -TriggerEvent $triggerEvent
                        }
                        'UpdateCoverage' {
                            Invoke-CoverageUpdate -TriggerEvent $triggerEvent
                        }
                        default {
                            Write-Warning "[Start-TriggerProcessing] Unknown action: $action"
                        }
                    }
                }
                catch {
                    Write-Error "[Start-TriggerProcessing] Action '$action' failed: $_"
                }
            }
        }
    }
    finally {
        $script:ProcessingActive = $false
        Write-Verbose "[Start-TriggerProcessing] Trigger processing complete"
    }
}

# Action implementations (stubs for now - will be implemented in integration)
function Invoke-DocumentationUpdate {
    param([hashtable]$TriggerEvent)
    Write-Verbose "[Action] Documentation update triggered for $($TriggerEvent.Changes.Count) files"
}

function Invoke-CodeAnalysis {
    param([hashtable]$TriggerEvent)
    Write-Verbose "[Action] Code analysis triggered for $($TriggerEvent.Changes.Count) files"
}

function Invoke-ConfigValidation {
    param([hashtable]$TriggerEvent)
    Write-Verbose "[Action] Config validation triggered for $($TriggerEvent.Changes.Count) files"
}

function Invoke-FullAnalysis {
    param([hashtable]$TriggerEvent)
    Write-Verbose "[Action] Full analysis triggered for $($TriggerEvent.Changes.Count) files"
}

function Invoke-ArchitectureUpdate {
    param([hashtable]$TriggerEvent)
    Write-Verbose "[Action] Architecture update triggered for $($TriggerEvent.Changes.Count) files"
}

function Invoke-TestExecution {
    param([hashtable]$TriggerEvent)
    Write-Verbose "[Action] Test execution triggered for $($TriggerEvent.Changes.Count) files"
}

function Invoke-LinkValidation {
    param([hashtable]$TriggerEvent)
    Write-Verbose "[Action] Link validation triggered for $($TriggerEvent.Changes.Count) files"
}

function Invoke-IndexUpdate {
    param([hashtable]$TriggerEvent)
    Write-Verbose "[Action] Index update triggered for $($TriggerEvent.Changes.Count) files"
}

function Invoke-CoverageUpdate {
    param([hashtable]$TriggerEvent)
    Write-Verbose "[Action] Coverage update triggered for $($TriggerEvent.Changes.Count) files"
}

function Process-FileChange {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$FileChange
    )
    
    Write-Verbose "[Process-FileChange] Processing change: $($FileChange.FullPath) ($($FileChange.ChangeType))"
    
    # Check exclusions first
    if (Test-FileExclusion -FilePath $FileChange.FullPath) {
        Write-Verbose "[Process-FileChange] File excluded from processing"
        return
    }
    
    # Find matching triggers
    $matchingTriggers = Find-MatchingTriggers -FileChange $FileChange
    
    if ($matchingTriggers.Count -eq 0) {
        Write-Verbose "[Process-FileChange] No triggers match this file change"
        return
    }
    
    # Add to matching triggers
    foreach ($triggerName in $matchingTriggers) {
        Add-ChangeToTrigger -TriggerName $triggerName -FileChange $FileChange
    }
}

function Register-TriggerHandler {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$Handler
    )
    
    $script:TriggerHandlers[$Name] = $Handler
    Write-Verbose "[Register-TriggerHandler] Registered trigger handler: $Name"
}

function Unregister-TriggerHandler {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    if ($script:TriggerHandlers.ContainsKey($Name)) {
        $script:TriggerHandlers.Remove($Name)
        Write-Verbose "[Unregister-TriggerHandler] Unregistered trigger handler: $Name"
    }
}

function Get-TriggerStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$TriggerName
    )
    
    if ($TriggerName) {
        if ($script:TriggerConditions.ContainsKey($TriggerName)) {
            return $script:TriggerConditions[$TriggerName]
        } else {
            Write-Warning "Trigger not found: $TriggerName"
            return $null
        }
    } else {
        return $script:TriggerConditions
    }
}

function Get-ProcessingQueueStatus {
    [CmdletBinding()]
    param()
    
    return @{
        QueueCount = $script:ProcessingQueue.Count
        ProcessingActive = $script:ProcessingActive
        RegisteredHandlers = $script:TriggerHandlers.Keys
    }
}

function Clear-TriggerQueue {
    [CmdletBinding()]
    param()
    
    $cleared = $script:ProcessingQueue.Count
    $script:ProcessingQueue.Clear()
    
    # Clear pending changes in triggers
    foreach ($triggerName in $script:TriggerConditions.Keys) {
        $pendingCount = $script:TriggerConditions[$triggerName].PendingChanges.Count
        $script:TriggerConditions[$triggerName].PendingChanges = @()
        $cleared += $pendingCount
    }
    
    Write-Verbose "[Clear-TriggerQueue] Cleared $cleared pending items"
    return $cleared
}

function Add-ExclusionPattern {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Pattern
    )
    
    if ($Pattern -notin $script:ExclusionPatterns) {
        $script:ExclusionPatterns += $Pattern
        Write-Verbose "[Add-ExclusionPattern] Added exclusion pattern: $Pattern"
    }
}

function Remove-ExclusionPattern {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Pattern
    )
    
    $script:ExclusionPatterns = $script:ExclusionPatterns | Where-Object { $_ -ne $Pattern }
    Write-Verbose "[Remove-ExclusionPattern] Removed exclusion pattern: $Pattern"
}

function Get-ExclusionPatterns {
    [CmdletBinding()]
    param()
    
    return $script:ExclusionPatterns
}

# Module cleanup
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    Write-Verbose "[Unity-Claude-TriggerManager] Module cleanup"
    
    # Clear all collections
    $script:TriggerConditions.Clear()
    $script:ExclusionPatterns = @()
    $script:ProcessingQueue.Clear()
    $script:TriggerHandlers.Clear()
    $script:ProcessingActive = $false
}

# Export module members
Export-ModuleMember -Function @(
    'Initialize-TriggerManager',
    'Process-FileChange',
    'Register-TriggerHandler',
    'Unregister-TriggerHandler',
    'Get-TriggerStatus',
    'Get-ProcessingQueueStatus',
    'Clear-TriggerQueue',
    'Add-ExclusionPattern',
    'Remove-ExclusionPattern',
    'Get-ExclusionPatterns',
    'Test-FileExclusion'
)

# Initialize with defaults
Initialize-TriggerManager

Write-Verbose "[Unity-Claude-TriggerManager] Module loaded successfully"
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCgAOfqA46NjeOu
# zP+4g5nIldsSW9XL1TC5tVOuA0TeT6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJS/XOZ76Mqj/u7uVALkkMjl
# qjBUNurH7gZ38IgPh9G8MA0GCSqGSIb3DQEBAQUABIIBABB2BlG0MK5rAVuOTIWS
# eBoX6kI6E+m1H/orSND5nThPGPsLcKWb7SwLBKPzxCqEfXAZSmo3/v+L4mzQsv9n
# vxv90bfZ+PyTNFgHmWrl2NNsp4wuISbtvkFzbo2QmZXb8M7V/IYmsloZGeAdqI2S
# a5ywhH/oEIFScMzCBfk7YtotvvAUvZ2idf/A0qyDybA8gDyBBovgpxgdQpKuJdR5
# G6WAzjMkhsDR/dPyCaxXt3pEi8gi1Lizy1xiWfcTv/8SU7V2mlCqHd6PW9GogdLk
# 5tZZJ/9q0Y01KmWpB3lrD+mh4btPRAXDg19gQuvth4YotWOAEUct94DqLOy3ZTA7
# ynI=
# SIG # End signature block
