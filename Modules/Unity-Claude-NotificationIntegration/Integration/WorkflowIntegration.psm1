# WorkflowIntegration.psm1
# Workflow integration functionality for Unity-Claude notifications
# Date: 2025-08-21

#region Workflow Integration Functions

function Invoke-NotificationHook {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Context
    )
    
    Write-Verbose "Invoking notification hook: $Name"
    
    if (-not $script:NotificationHooks.ContainsKey($Name)) {
        Write-Error "Hook '$Name' not found"
        return $false
    }
    
    $hook = $script:NotificationHooks[$Name]
    
    if (-not $hook.Enabled) {
        Write-Verbose "Hook '$Name' is disabled, skipping"
        return $false
    }
    
    # Check conditions
    $conditionsMet = $true
    foreach ($condition in $hook.Conditions.GetEnumerator()) {
        $key = $condition.Key
        $expectedValue = $condition.Value
        
        if ($Context.ContainsKey($key)) {
            if ($Context[$key] -ne $expectedValue) {
                $conditionsMet = $false
                break
            }
        }
        else {
            $conditionsMet = $false
            break
        }
    }
    
    if (-not $conditionsMet) {
        Write-Verbose "Conditions not met for hook '$Name', skipping"
        return $false
    }
    
    try {
        # Update hook statistics
        $hook.TriggerCount++
        $hook.LastTriggered = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        
        # Execute the hook action
        $result = & $hook.Action -Context $Context
        
        Write-Verbose "Hook '$Name' executed successfully"
        return $result
    }
    catch {
        Write-Error "Failed to execute hook '$Name': $_"
        return $false
    }
}

function Add-WorkflowNotificationTrigger {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Unity.CompilationError', 'Unity.CompilationSuccess', 'Claude.SubmissionFailed', 'Claude.ResponseReceived', 'System.HealthAlert', 'Workflow.StateChange', 'Human.InterventionRequired')]
        [string]$EventType,
        
        [Parameter(Mandatory = $true)]
        [string]$HookName,
        
        [Parameter()]
        [ValidateSet('Critical', 'Error', 'Warning', 'Info')]
        [string]$Severity = 'Info',
        
        [Parameter()]
        [hashtable]$CustomData = @{}
    )
    
    Write-Verbose "Adding workflow notification trigger for $EventType"
    
    $templateName = switch ($EventType) {
        'Unity.CompilationError' { 'UnityCompilationFailure' }
        'Unity.CompilationSuccess' { 'UnityCompilationSuccess' }
        'Claude.SubmissionFailed' { 'ClaudeSubmissionFailure' }
        'Claude.ResponseReceived' { 'ClaudeResponseReceived' }
        'System.HealthAlert' { 'SystemHealthAlert' }
        'Workflow.StateChange' { 'WorkflowStateChange' }
        'Human.InterventionRequired' { 'HumanInterventionRequired' }
        default { 'GenericNotification' }
    }
    
    # Create a simple action that works with the template
    $action = {
        param($Context)
        
        $data = $Context.Data.Clone()
        $data['EventType'] = $Context.EventType
        $data['Severity'] = $Context.Severity
        
        # Use generic template for now - can be enhanced later
        return Send-IntegratedNotification -TemplateName 'WorkflowNotification' -Severity $Context.Severity -Data $data -Channels $Context.Channels
    }
    
    $hook = Register-NotificationHook -Name $HookName -TriggerEvent $EventType -Action $action -Severity $Severity -Enabled
    
    Write-Verbose "Workflow notification trigger added: $HookName for $EventType"
    return $hook
}

function Remove-WorkflowNotificationTrigger {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$HookName
    )
    
    Write-Verbose "Removing workflow notification trigger: $HookName"
    return Unregister-NotificationHook -Name $HookName
}

function Enable-WorkflowNotifications {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]$HookNames = @(),
        
        [Parameter()]
        [string]$EventType
    )
    
    Write-Verbose "Enabling workflow notifications"
    
    $hooks = Get-NotificationHooks
    
    if ($HookNames.Count -gt 0) {
        $hooks = $hooks | Where-Object { $_.Name -in $HookNames }
    }
    
    if ($EventType) {
        $hooks = $hooks | Where-Object { $_.TriggerEvent -eq $EventType }
    }
    
    $enabledCount = 0
    foreach ($hook in $hooks) {
        $script:NotificationHooks[$hook.Name].Enabled = $true
        $enabledCount++
    }
    
    Write-Verbose "Enabled $enabledCount notification hooks"
    return $enabledCount
}

function Disable-WorkflowNotifications {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]$HookNames = @(),
        
        [Parameter()]
        [string]$EventType
    )
    
    Write-Verbose "Disabling workflow notifications"
    
    $hooks = Get-NotificationHooks
    
    if ($HookNames.Count -gt 0) {
        $hooks = $hooks | Where-Object { $_.Name -in $HookNames }
    }
    
    if ($EventType) {
        $hooks = $hooks | Where-Object { $_.TriggerEvent -eq $EventType }
    }
    
    $disabledCount = 0
    foreach ($hook in $hooks) {
        $script:NotificationHooks[$hook.Name].Enabled = $false
        $disabledCount++
    }
    
    Write-Verbose "Disabled $disabledCount notification hooks"
    return $disabledCount
}

function Get-WorkflowNotificationStatus {
    [CmdletBinding()]
    param()
    
    Write-Verbose "Getting workflow notification status"
    
    $workflowHooks = Get-NotificationHooks
    
    $status = @{
        TotalHooks = $workflowHooks.Count
        EnabledHooks = ($workflowHooks | Where-Object { $_.Enabled }).Count
        DisabledHooks = ($workflowHooks | Where-Object { -not $_.Enabled }).Count
        TotalTriggers = if ($workflowHooks.Count -gt 0) { ($workflowHooks | ForEach-Object { $_.TriggerCount } | Measure-Object -Sum).Sum } else { 0 }
        LastTriggered = ($workflowHooks | Sort-Object LastTriggered -Descending | Select-Object -First 1).LastTriggered
        Hooks = @{}
    }
    
    foreach ($hook in $workflowHooks) {
        $status.Hooks[$hook.Name] = @{
            TriggerEvent = $hook.TriggerEvent
            Severity = $hook.Severity
            Enabled = $hook.Enabled
            TriggerCount = $hook.TriggerCount
            LastTriggered = $hook.LastTriggered
            Channels = $hook.Channels
        }
    }
    
    return $status
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    'Invoke-NotificationHook',
    'Add-WorkflowNotificationTrigger',
    'Remove-WorkflowNotificationTrigger',
    'Enable-WorkflowNotifications',
    'Disable-WorkflowNotifications',
    'Get-WorkflowNotificationStatus'
)

Write-Verbose "WorkflowIntegration module loaded successfully"
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUzVXZdF9e2BdYBrpw4P3b0S4F
# 0FGgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
# AQsFADAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0b21hdGlvbi1EZXZlbG9w
# bWVudDAeFw0yNTA4MjAyMTE1MTdaFw0yNjA4MjAyMTM1MTdaMC4xLDAqBgNVBAMM
# I1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEAseH3qinVEOhrn2OLpjc5TNT4vGh1BkfB5X4S
# FhY7K0QMQsYYnkZVmx3tB8PqVQXl++l+e3uT7uCscc7vjMTK8tDSWH98ji0U34WL
# JBwXC62l1ArazMKp4Tyr7peksei7vL4pZOtOVgAyTYn5d1hbnsVQmCSTPRtpn7mC
# Azfq2ec5qZ9Kgl7puPW5utvYfh8idtOWa5/WgYSKwOIvyZawIdZKLFpwqOtqbJe4
# sWzVahasFhLfoAKkniKOAocJDkJexh5pO/EOSKEZ3mOCU1ZSs4XWRGISRhV3qGZp
# f+Y3JlHKMeFDWKynaJBO8/GU5sqMATlDUvrByBtU2OQ2Um/L3QIDAQABo0YwRDAO
# BgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFHw5
# rOy6xlW6B45sJUsiI2A/yS0MMA0GCSqGSIb3DQEBCwUAA4IBAQAUTLH0+w8ysvmh
# YuBw4NDKcZm40MTh9Zc1M2p2hAkYsgNLJ+/rAP+I74rNfqguTYwxpCyjkwrg8yF5
# wViwggboLpF2yDu4N/dgDainR4wR8NVpS7zFZOFkpmNPepc6bw3d4yQKa/wJXKeC
# pkRjS50N77/hfVI+fFKNao7POb7en5fcXuZaN6xWoTRy+J4I4MhfHpjZuxSLSXjb
# VXtPD4RZ9HGjl9BU8162cRhjujr/Lc3/dY/6ikHQYnxuxcdxRew4nzaqAQaOeWu6
# tGp899JPKfldM5Zay5IBl3zs15gNS9+0Jrd0ARQnSVYoI0DLh3KybFnfK4POezoN
# Lp/dbX2SMYIB4zCCAd8CAQEwQjAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0
# b21hdGlvbi1EZXZlbG9wbWVudAIQdR0W2SKoK5VE8JId4ZxrRTAJBgUrDgMCGgUA
# oHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYB
# BAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0B
# CQQxFgQUSy6nXl7S9VNZX68/qtaBlO3QqI8wDQYJKoZIhvcNAQEBBQAEggEALOOu
# nb5mLgdL4FGck3rfeId6c8qJQVHBD3Pu0yaJLMjvC4rX+To5DTHzKH5UElrIOf8Y
# VK37UuMdQw7V4zvWJokRwFrp9S6YN8FCVAaHCeuX9U8oRfERkD+6PaH5YeW3iTXp
# pf8/oUNIB9BmxbtpOddJtYxmq11HnjtPoxkqR2V27xEpKRQpM4wmw7Gs0D65thLH
# T4Nptu43lOkWyPHOBFJWPTRQsF9ISwo3QFyO0XWSJIws9r54HdFaSHvUSHE4mO9N
# Toe7GmXY/44463/haBskG5/lt3sujqYGa2NS/69Krzh5tVr71BCBdH38B8qxdPfM
# lI8U9yve+FWCs/cWgQ==
# SIG # End signature block
