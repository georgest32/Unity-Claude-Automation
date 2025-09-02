# IntegrationManagement.psm1
# Integration and Status Management for Unity-Claude-DecisionEngine
# Part of the refactored Unity-Claude-DecisionEngine module

# Import core module for shared functions
$corePath = Join-Path $PSScriptRoot "DecisionEngineCore.psm1"
if (Test-Path $corePath) {
    Import-Module $corePath -Force -DisableNameChecking
}

# Module integration state
$script:ConnectedModules = @{
    IntelligentPromptEngine = $false
    ConversationStateManager = $false
    ResponseMonitor = $false
}

#region Module Integrations

function Connect-IntelligentPromptEngine {
    [CmdletBinding()]
    param()
    
    Write-DecisionEngineLog -Message "Attempting to connect to IntelligentPromptEngine" -Level "INFO"
    
    try {
        if (Test-RequiredModule -ModuleName "IntelligentPromptEngine") {
            $script:ConnectedModules.IntelligentPromptEngine = $true
            
            # Register callback if available
            if (Get-Command -Name "Register-DecisionCallback" -ErrorAction SilentlyContinue) {
                Register-DecisionCallback -Callback {
                    param($Analysis)
                    Invoke-AutonomousDecision -Analysis $Analysis
                }
                Write-DecisionEngineLog -Message "Registered decision callback with IntelligentPromptEngine" -Level "INFO"
            }
            
            return @{
                Success = $true
                Message = "Connected to IntelligentPromptEngine"
            }
        } else {
            return @{
                Success = $false
                Message = "IntelligentPromptEngine module not available"
            }
        }
    } catch {
        Write-DecisionEngineLog -Message "Failed to connect to IntelligentPromptEngine: $_" -Level "ERROR"
        return @{
            Success = $false
            Message = $_.Exception.Message
        }
    }
}

function Connect-ConversationManager {
    [CmdletBinding()]
    param()
    
    Write-DecisionEngineLog -Message "Attempting to connect to ConversationStateManager" -Level "INFO"
    
    try {
        if (Test-RequiredModule -ModuleName "ConversationStateManager") {
            $script:ConnectedModules.ConversationStateManager = $true
            
            # Get initial conversation state if available
            if (Get-Command -Name "Get-ConversationState" -ErrorAction SilentlyContinue) {
                $state = Get-ConversationState
                if ($state) {
                    Write-DecisionEngineLog -Message "Retrieved conversation state: $($state.CurrentState)" -Level "DEBUG"
                }
            }
            
            return @{
                Success = $true
                Message = "Connected to ConversationStateManager"
            }
        } else {
            return @{
                Success = $false
                Message = "ConversationStateManager module not available"
            }
        }
    } catch {
        Write-DecisionEngineLog -Message "Failed to connect to ConversationStateManager: $_" -Level "ERROR"
        return @{
            Success = $false
            Message = $_.Exception.Message
        }
    }
}

#endregion

#region Status and Management

function Get-DecisionEngineStatus {
    [CmdletBinding()]
    param()
    
    Write-DecisionEngineLog -Message "Getting Decision Engine status" -Level "DEBUG"
    
    $status = @{
        Timestamp = Get-Date
        Configuration = Get-DecisionEngineConfig
        DecisionHistoryCount = $script:DecisionHistory.Count
        ContextBufferCount = $script:ContextBuffer.Count
        ActiveDecisions = $script:ActiveDecisions.Count
        ConnectedModules = $script:ConnectedModules
        Health = "Unknown"
        Metrics = @{}
    }
    
    # Calculate health status
    $healthScore = 0
    
    # Check configuration
    if ($status.Configuration.EnableDebugLogging) { $healthScore++ }
    if ($status.Configuration.ConfidenceThreshold -gt 0) { $healthScore++ }
    
    # Check history
    if ($status.DecisionHistoryCount -gt 0) { $healthScore++ }
    
    # Check module connections
    $connectedCount = ($script:ConnectedModules.GetEnumerator() | Where-Object { $_.Value -eq $true }).Count
    $healthScore += $connectedCount
    
    # Determine health status
    if ($healthScore -ge 5) {
        $status.Health = "Excellent"
    } elseif ($healthScore -ge 3) {
        $status.Health = "Good"
    } elseif ($healthScore -ge 1) {
        $status.Health = "Fair"
    } else {
        $status.Health = "Poor"
    }
    
    # Calculate metrics
    if ($script:DecisionHistory.Count -gt 0) {
        $recentDecisions = $script:DecisionHistory | Where-Object {
            (Get-Date) - $_.Timestamp -lt [TimeSpan]::FromHours(1)
        }
        
        $status.Metrics = @{
            TotalDecisions = $script:DecisionHistory.Count
            RecentDecisions = $recentDecisions.Count
            AverageConfidence = ($script:DecisionHistory | Measure-Object -Property Confidence -Average).Average
            MostCommonAction = ($script:DecisionHistory | Group-Object -Property Action | Sort-Object Count -Descending | Select-Object -First 1).Name
        }
    }
    
    return $status
}

function Test-DecisionEngineIntegration {
    [CmdletBinding()]
    param()
    
    Write-DecisionEngineLog -Message "Testing Decision Engine integration" -Level "INFO"
    
    $testResults = @{
        Timestamp = Get-Date
        OverallStatus = "FAIL"
        ResponseAnalysis = $false
        DecisionMaking = $false
        ContextManagement = $false
        ModuleIntegrations = $false
        Details = @()
    }
    
    try {
        # Test response analysis
        Write-DecisionEngineLog -Message "Testing response analysis..." -Level "DEBUG"
        $testResponse = "I recommend running the test script to verify the configuration."
        $analysis = Invoke-HybridResponseAnalysis -ResponseText $testResponse
        
        if ($analysis -and $analysis.Intent -ne "UNKNOWN") {
            $testResults.ResponseAnalysis = $true
            $testResults.Details += "Response analysis: PASS"
            Write-DecisionEngineLog -Message "Response analysis test: PASS" -Level "DEBUG"
        } else {
            $testResults.Details += "Response analysis: FAIL"
        }
        
        # Test decision making
        Write-DecisionEngineLog -Message "Testing decision making..." -Level "DEBUG"
        if ($analysis) {
            $decision = Invoke-AutonomousDecision -Analysis $analysis
            
            if ($decision -and $decision.Action -ne "NONE") {
                $testResults.DecisionMaking = $true
                $testResults.Details += "Decision making: PASS"
                Write-DecisionEngineLog -Message "Decision making test: PASS" -Level "DEBUG"
            } else {
                $testResults.Details += "Decision making: FAIL"
            }
        }
        
        # Test context management
        Write-DecisionEngineLog -Message "Testing context management..." -Level "DEBUG"
        if ($script:ContextBuffer.Count -gt 0) {
            $testResults.ContextManagement = $true
            $testResults.Details += "Context management: PASS"
            Write-DecisionEngineLog -Message "Context management test: PASS" -Level "DEBUG"
        } else {
            $testResults.Details += "Context management: WARN (No context)"
        }
        
        # Test module integrations
        Write-DecisionEngineLog -Message "Testing module integrations..." -Level "DEBUG"
        $integrationCount = 0
        $requiredModules = @('IntelligentPromptEngine', 'ConversationStateManager', 'Unity-Claude-ResponseMonitor')
        
        foreach ($module in $requiredModules) {
            if (Test-RequiredModule -ModuleName $module) {
                $integrationCount++
            }
        }
        
        if ($integrationCount -ge 2) {
            $testResults.ModuleIntegrations = $true
            $testResults.Details += "Module integrations: PASS ($integrationCount/3)"
            Write-DecisionEngineLog -Message "Module integrations test: PASS ($integrationCount/3)" -Level "DEBUG"
        } else {
            $testResults.Details += "Module integrations: WARN ($integrationCount/3)"
        }
        
        # Overall status
        $passCount = ($testResults.GetEnumerator() | Where-Object { $_.Key -ne "OverallStatus" -and $_.Key -ne "Timestamp" -and $_.Key -ne "Details" -and $_.Value -eq $true }).Count
        
        if ($passCount -ge 3) {
            $testResults.OverallStatus = "PASS"
            Write-DecisionEngineLog -Message "Decision Engine integration test: PASS ($passCount/4 tests passed)" -Level "INFO"
        } else {
            Write-DecisionEngineLog -Message "Decision Engine integration test: FAIL ($passCount/4 tests passed)" -Level "WARN"
        }
        
    } catch {
        Write-DecisionEngineLog -Message "Integration test error: $_" -Level "ERROR"
        $testResults.Details += "Test error: $($_.Exception.Message)"
    }
    
    return $testResults
}

#endregion

#region Component Health Monitoring

function Get-DecisionEngineComponents {
    [CmdletBinding()]
    param()
    
    return @{
        Core = @{
            Name = "DecisionEngineCore"
            Path = Join-Path $PSScriptRoot "DecisionEngineCore.psm1"
            Status = if (Test-Path (Join-Path $PSScriptRoot "DecisionEngineCore.psm1")) { "Loaded" } else { "Missing" }
        }
        ResponseAnalysis = @{
            Name = "ResponseAnalysis"
            Path = Join-Path $PSScriptRoot "ResponseAnalysis.psm1"
            Status = if (Test-Path (Join-Path $PSScriptRoot "ResponseAnalysis.psm1")) { "Loaded" } else { "Missing" }
        }
        DecisionMaking = @{
            Name = "DecisionMaking"
            Path = Join-Path $PSScriptRoot "DecisionMaking.psm1"
            Status = if (Test-Path (Join-Path $PSScriptRoot "DecisionMaking.psm1")) { "Loaded" } else { "Missing" }
        }
        IntegrationManagement = @{
            Name = "IntegrationManagement"
            Path = Join-Path $PSScriptRoot "IntegrationManagement.psm1"
            Status = if (Test-Path (Join-Path $PSScriptRoot "IntegrationManagement.psm1")) { "Loaded" } else { "Missing" }
        }
    }
}

function Test-DecisionEngineHealth {
    [CmdletBinding()]
    param()
    
    $health = @{
        Status = "Healthy"
        Components = Get-DecisionEngineComponents
        Issues = @()
    }
    
    # Check each component
    foreach ($component in $health.Components.GetEnumerator()) {
        if ($component.Value.Status -ne "Loaded") {
            $health.Status = "Degraded"
            $health.Issues += "Component $($component.Key) is not loaded"
        }
    }
    
    # Check configuration
    $config = Get-DecisionEngineConfig
    if ($config.ConfidenceThreshold -le 0 -or $config.ConfidenceThreshold -gt 1) {
        $health.Status = "Warning"
        $health.Issues += "Invalid confidence threshold: $($config.ConfidenceThreshold)"
    }
    
    # Check history size
    if ($script:DecisionHistory.Count -gt 500) {
        $health.Status = "Warning"
        $health.Issues += "Decision history is large: $($script:DecisionHistory.Count) entries"
    }
    
    return $health
}

#endregion

# Export module members
Export-ModuleMember -Function @(
    'Connect-IntelligentPromptEngine',
    'Connect-ConversationManager',
    'Get-DecisionEngineStatus',
    'Test-DecisionEngineIntegration',
    'Get-DecisionEngineComponents',
    'Test-DecisionEngineHealth'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCT8Fk6Zf3118qi
# ns+dL6rX5C1nY1g3zZ6hDOdAmGVto6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEILqFxjHAImg8vwZtEumt0owe
# +j/b2xlII9Isxy9hnVYgMA0GCSqGSIb3DQEBAQUABIIBABTQohW85PQw3H3R4f5P
# U1cK+ZLFyar9B6hdlJSI0YqQjxpQ+a0iHw1FDE3/okEiuYSF9yxeAeok0tlr8LPY
# ODxQRuo100M5NR6E3etPsY4DeS+YpVe9jR6w/VHYWZ7rIUf83AiSyofcl9ngt9Pp
# Uw57J1Cc2JqDn2ehnaLYQLpbE8n6hnIvSpQBcYKLUxUzznILZXoG51PL0/d3jKUw
# P17MJ8pTT3Aj6fcWEMZ7anT90ETHRuu0YdyN6Lsdq+ukUGhymEwdHVAEUmKGMVA+
# 6x95kx4Nj9KFZzDXRtr0jorr7rRO9idd14bJu6HMChoZ+9JeJ1eybOfqkRnKlgXY
# NCI=
# SIG # End signature block
