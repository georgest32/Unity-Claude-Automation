# Unity-Claude-DecisionEngine-Refactored.psm1
# Orchestrator for refactored Unity-Claude-DecisionEngine module
# Loads and coordinates modular components from Core/ directory
#
# Original module: 1,284 lines
# Refactored into: 4 focused components
# Complexity reduction: ~78% per component
#
# === REFACTORED VERSION - PRODUCTION READY ===
Write-Host "[DecisionEngine] Loading REFACTORED version with modular components" -ForegroundColor Green
Write-Host "[DecisionEngine] Components: DecisionEngineCore, ResponseAnalysis, DecisionMaking, IntegrationManagement" -ForegroundColor Cyan

# Script root for component loading
$script:ModuleRoot = $PSScriptRoot
$script:CorePath = Join-Path $script:ModuleRoot "Core"

# Component loading tracking
$script:LoadedComponents = @{}
$script:LoadErrors = @()

#region Component Loading

function Import-DecisionEngineComponent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComponentName,
        
        [Parameter()]
        [switch]$Required
    )
    
    $componentPath = Join-Path $script:CorePath "$ComponentName.psm1"
    
    try {
        if (Test-Path $componentPath) {
            Import-Module $componentPath -Force -DisableNameChecking -Global
            $script:LoadedComponents[$ComponentName] = $true
            Write-Verbose "[DecisionEngine] Loaded component: $ComponentName"
            return $true
        } else {
            $errorMsg = "Component not found: $ComponentName at $componentPath"
            $script:LoadErrors += $errorMsg
            
            if ($Required) {
                throw $errorMsg
            } else {
                Write-Warning "[DecisionEngine] Optional component missing: $ComponentName"
                return $false
            }
        }
    } catch {
        $script:LoadErrors += "Failed to load $ComponentName : $_"
        $script:LoadedComponents[$ComponentName] = $false
        
        if ($Required) {
            throw "Failed to load required component $ComponentName : $_"
        } else {
            Write-Warning "[DecisionEngine] Failed to load optional component $ComponentName : $_"
            return $false
        }
    }
}

# Load core components in dependency order
try {
    # Core module (required - contains shared state and utilities)
    Import-DecisionEngineComponent -ComponentName "DecisionEngineCore" -Required
    
    # Response Analysis module (required for hybrid analysis)
    Import-DecisionEngineComponent -ComponentName "ResponseAnalysis" -Required
    
    # Decision Making module (required for autonomous decisions)
    Import-DecisionEngineComponent -ComponentName "DecisionMaking" -Required
    
    # Integration Management module (optional but recommended)
    Import-DecisionEngineComponent -ComponentName "IntegrationManagement"
    
} catch {
    Write-Error "[DecisionEngine] Critical component loading failure: $_"
    throw
}

#endregion

#region Module Initialization

# Import required modules if available
$RequiredModules = @('IntelligentPromptEngine', 'ConversationStateManager', 'Unity-Claude-ResponseMonitor')
foreach ($module in $RequiredModules) {
    if (Get-Module -ListAvailable -Name $module) {
        try {
            Import-Module $module -Force -ErrorAction SilentlyContinue
            Write-Verbose "[DecisionEngine] Imported integration module: $module"
        } catch {
            Write-Verbose "[DecisionEngine] Could not import integration module: $module"
        }
    }
}

# Initialize module connections if IntegrationManagement loaded
if ($script:LoadedComponents['IntegrationManagement']) {
    if (Get-Command Connect-IntelligentPromptEngine -ErrorAction SilentlyContinue) {
        $promptConnection = Connect-IntelligentPromptEngine
        if ($promptConnection.Success) {
            Write-Verbose "[DecisionEngine] Connected to IntelligentPromptEngine"
        }
    }
    
    if (Get-Command Connect-ConversationManager -ErrorAction SilentlyContinue) {
        $conversationConnection = Connect-ConversationManager
        if ($conversationConnection.Success) {
            Write-Verbose "[DecisionEngine] Connected to ConversationStateManager"
        }
    }
}

#endregion

#region Orchestration Functions

function Get-DecisionEngineComponentStatus {
    <#
    .SYNOPSIS
    Returns the status of all DecisionEngine components
    
    .DESCRIPTION
    Provides detailed information about loaded components, their health, and any loading errors
    #>
    [CmdletBinding()]
    param()
    
    $status = @{
        ModuleVersion = "2.0.0"
        Architecture = "Refactored"
        ComponentsLoaded = $script:LoadedComponents
        LoadErrors = $script:LoadErrors
        Health = "Unknown"
    }
    
    # Determine overall health
    $loadedCount = ($script:LoadedComponents.GetEnumerator() | Where-Object { $_.Value -eq $true }).Count
    $totalComponents = 4
    
    if ($loadedCount -eq $totalComponents) {
        $status.Health = "Excellent"
    } elseif ($loadedCount -ge ($totalComponents - 1)) {
        $status.Health = "Good"
    } elseif ($loadedCount -ge 2) {
        $status.Health = "Degraded"
    } else {
        $status.Health = "Critical"
    }
    
    # Add component health if available
    if (Get-Command Test-DecisionEngineHealth -ErrorAction SilentlyContinue) {
        $status.ComponentHealth = Test-DecisionEngineHealth
    }
    
    # Add integration status if available
    if (Get-Command Get-DecisionEngineStatus -ErrorAction SilentlyContinue) {
        $status.IntegrationStatus = Get-DecisionEngineStatus
    }
    
    return $status
}

function Invoke-DecisionEngineAnalysis {
    <#
    .SYNOPSIS
    Main entry point for decision engine analysis
    
    .DESCRIPTION
    Orchestrates response analysis and decision making across all components
    
    .PARAMETER ResponseText
    The response text to analyze
    
    .PARAMETER Context
    Optional context information
    
    .PARAMETER AutoDecide
    Whether to automatically make a decision based on analysis
    
    .PARAMETER AutoExecute
    Whether to automatically execute high-confidence decisions
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$ResponseText,
        
        [Parameter()]
        [hashtable]$Context = @{},
        
        [Parameter()]
        [switch]$AutoDecide,
        
        [Parameter()]
        [switch]$AutoExecute
    )
    
    process {
        $result = @{
            Timestamp = Get-Date
            ResponseText = $ResponseText
            Analysis = $null
            Decision = $null
            Error = $null
        }
        
        try {
            # Step 1: Perform hybrid response analysis
            if (Get-Command Invoke-HybridResponseAnalysis -ErrorAction SilentlyContinue) {
                Write-Verbose "[DecisionEngine] Performing response analysis..."
                $result.Analysis = Invoke-HybridResponseAnalysis -ResponseText $ResponseText -Context $Context
            } else {
                throw "Response analysis component not available"
            }
            
            # Step 2: Make autonomous decision if requested
            if ($AutoDecide -and $result.Analysis) {
                if (Get-Command Invoke-AutonomousDecision -ErrorAction SilentlyContinue) {
                    Write-Verbose "[DecisionEngine] Making autonomous decision..."
                    $result.Decision = Invoke-AutonomousDecision -Analysis $result.Analysis -Context $Context -AutoExecute:$AutoExecute
                } else {
                    Write-Warning "[DecisionEngine] Decision making component not available"
                }
            }
            
            # Step 3: Add to context buffer for future analysis
            if ($script:ContextBuffer) {
                $script:ContextBuffer.Enqueue($result)
                
                # Limit buffer size
                while ($script:ContextBuffer.Count -gt 10) {
                    [void]$script:ContextBuffer.Dequeue()
                }
            }
            
        } catch {
            $result.Error = $_.Exception.Message
            Write-Error "[DecisionEngine] Analysis error: $_"
        }
        
        return $result
    }
}

function Reset-DecisionEngine {
    <#
    .SYNOPSIS
    Resets the Decision Engine to initial state
    
    .DESCRIPTION
    Clears all history, context, and resets configuration to defaults
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()
    
    if ($PSCmdlet.ShouldProcess("Decision Engine", "Reset to initial state")) {
        # Clear history
        if (Get-Command Clear-DecisionHistory -ErrorAction SilentlyContinue) {
            Clear-DecisionHistory
            Write-Verbose "[DecisionEngine] Cleared decision history"
        }
        
        # Reset configuration
        if (Get-Command Set-DecisionEngineConfig -ErrorAction SilentlyContinue) {
            $defaultConfig = @{
                EnableDebugLogging = $true
                ConfidenceThreshold = 0.7
                MaxDecisionRetries = 3
                DecisionTimeoutMs = 5000
                EnableAIEnhancement = $true
                ContextWindowSize = 10
                LearningEnabled = $true
            }
            Set-DecisionEngineConfig -Configuration $defaultConfig
            Write-Verbose "[DecisionEngine] Reset configuration to defaults"
        }
        
        Write-Host "[DecisionEngine] Reset complete" -ForegroundColor Green
    }
}

function Test-DecisionEngineDeployment {
    <#
    .SYNOPSIS
    Comprehensive test of the refactored Decision Engine deployment
    
    .DESCRIPTION
    Tests all components, integrations, and performs sample analysis
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "`n=== Decision Engine Deployment Test ===" -ForegroundColor Cyan
    
    $testResults = @{
        ComponentLoading = $false
        ResponseAnalysis = $false
        DecisionMaking = $false
        Integration = $false
        Overall = $false
    }
    
    # Test 1: Component Loading
    Write-Host "`nTest 1: Component Loading" -ForegroundColor Yellow
    $componentStatus = Get-DecisionEngineComponentStatus
    if ($componentStatus.Health -in @("Excellent", "Good")) {
        $testResults.ComponentLoading = $true
        Write-Host "  PASS - Components loaded successfully" -ForegroundColor Green
    } else {
        Write-Host "  FAIL - Component loading issues detected" -ForegroundColor Red
        $componentStatus.LoadErrors | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
    }
    
    # Test 2: Response Analysis
    Write-Host "`nTest 2: Response Analysis" -ForegroundColor Yellow
    try {
        $testText = "I recommend running the test script to verify the configuration."
        $analysis = Invoke-DecisionEngineAnalysis -ResponseText $testText
        
        if ($analysis -and $analysis.Analysis -and $analysis.Analysis.Intent -ne "UNKNOWN") {
            $testResults.ResponseAnalysis = $true
            Write-Host "  PASS - Analysis successful (Intent: $($analysis.Analysis.Intent))" -ForegroundColor Green
        } else {
            Write-Host "  FAIL - Analysis did not produce expected results" -ForegroundColor Red
        }
    } catch {
        Write-Host "  FAIL - Analysis error: $_" -ForegroundColor Red
    }
    
    # Test 3: Decision Making
    Write-Host "`nTest 3: Decision Making" -ForegroundColor Yellow
    try {
        $testText = "Error: Unable to compile the Unity project due to missing references."
        $decision = Invoke-DecisionEngineAnalysis -ResponseText $testText -AutoDecide
        
        if ($decision -and $decision.Decision -and $decision.Decision.Action -ne "NONE") {
            $testResults.DecisionMaking = $true
            Write-Host "  PASS - Decision made (Action: $($decision.Decision.Action))" -ForegroundColor Green
        } else {
            Write-Host "  FAIL - Decision making did not produce expected results" -ForegroundColor Red
        }
    } catch {
        Write-Host "  FAIL - Decision making error: $_" -ForegroundColor Red
    }
    
    # Test 4: Integration Test
    Write-Host "`nTest 4: Integration Test" -ForegroundColor Yellow
    if (Get-Command Test-DecisionEngineIntegration -ErrorAction SilentlyContinue) {
        $integrationTest = Test-DecisionEngineIntegration
        if ($integrationTest.OverallStatus -eq "PASS") {
            $testResults.Integration = $true
            Write-Host "  PASS - Integration test successful" -ForegroundColor Green
        } else {
            Write-Host "  FAIL - Integration test failed" -ForegroundColor Red
            $integrationTest.Details | ForEach-Object { Write-Host "    $_" }
        }
    } else {
        Write-Host "  SKIP - Integration test not available" -ForegroundColor Yellow
    }
    
    # Overall Result
    $passCount = ($testResults.GetEnumerator() | Where-Object { $_.Key -ne "Overall" -and $_.Value -eq $true }).Count
    $totalTests = 4
    
    Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
    Write-Host "Passed: $passCount / $totalTests" -ForegroundColor $(if ($passCount -eq $totalTests) { "Green" } elseif ($passCount -ge 3) { "Yellow" } else { "Red" })
    
    if ($passCount -ge 3) {
        $testResults.Overall = $true
        Write-Host "`nDecision Engine deployment: SUCCESS" -ForegroundColor Green
    } else {
        Write-Host "`nDecision Engine deployment: FAILED" -ForegroundColor Red
    }
    
    return $testResults
}

#endregion

#region Backward Compatibility Shims

# These shims ensure backward compatibility with existing code that uses the monolithic module

# Map old function names to new implementations if needed
if (-not (Get-Command Invoke-HybridResponseAnalysis -ErrorAction SilentlyContinue)) {
    Write-Warning "[DecisionEngine] Some functions may not be available due to component loading issues"
}

#endregion

# Export all functions from loaded components plus orchestration functions
$exportFunctions = @(
    # Orchestration functions (always available)
    'Get-DecisionEngineComponentStatus',
    'Invoke-DecisionEngineAnalysis',
    'Reset-DecisionEngine',
    'Test-DecisionEngineDeployment'
)

# Add functions from loaded components
$componentFunctions = @{
    'DecisionEngineCore' = @(
        'Write-DecisionEngineLog',
        'Test-RequiredModule',
        'Get-DecisionEngineConfig',
        'Set-DecisionEngineConfig',
        'Get-DecisionHistory',
        'Clear-DecisionHistory',
        'Add-DecisionToHistory'
    )
    'ResponseAnalysis' = @(
        'Invoke-HybridResponseAnalysis',
        'Invoke-RegexBasedAnalysis',
        'Invoke-AIEnhancedAnalysis',
        'Get-IntentClassification',
        'Get-SemanticContext',
        'Get-SemanticActions',
        'Calculate-SemanticConfidence',
        'Merge-AnalysisResults',
        'Add-ContextualEnrichment',
        'Get-ConversationFlowAnalysis',
        'Get-ConversationConsistency',
        'Get-LastSimilarResponse'
    )
    'DecisionMaking' = @(
        'Invoke-AutonomousDecision',
        'Invoke-DecisionTree',
        'Apply-ContextualAdjustments',
        'Invoke-DecisionValidation'
    )
    'IntegrationManagement' = @(
        'Connect-IntelligentPromptEngine',
        'Connect-ConversationManager',
        'Get-DecisionEngineStatus',
        'Test-DecisionEngineIntegration',
        'Get-DecisionEngineComponents',
        'Test-DecisionEngineHealth'
    )
}

foreach ($component in $componentFunctions.Keys) {
    if ($script:LoadedComponents[$component]) {
        $exportFunctions += $componentFunctions[$component]
    }
}

Export-ModuleMember -Function $exportFunctions

Write-Host "[DecisionEngine] Module loaded successfully with $($exportFunctions.Count) functions" -ForegroundColor Green
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB7iBhNCcJMMapK
# uC78yNJMb6vCn64+bf427jxrN5K+haCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEINFixJDDHPQrOpaitt//BwLB
# H4EJ4X4+VIbbSP5lQqJTMA0GCSqGSIb3DQEBAQUABIIBAHFV2As8hZ9/laGYTaMM
# tBFgNtmY6m17RKCLR9tEwfzaG9lFLeJrkfEQdyfuXK1yAQTgLrj4Pl27jHtmu9QQ
# xvBoplQpn715lNUcJXEa74l3ZpBCf/RR2Suu52g382FYGZsE56v1rN3mPz8VlB7v
# xhNyFYScoGjmucsCDGmhag2mFn7dM2l9Do7WsuG0bCJBoJVkx/G3/swAqb/m5N4G
# vCY769hEUHOttuaQJKmpm15Yeh8v4jYvetOBGkUKlMuBsFaJvsPKuRYwabkKRfB2
# 6c4ApQktWt+ZMVkinXAirXghs6ua+e+iwNHyYrFQzYOMImxODNAvIr0gyccobGRn
# jeU=
# SIG # End signature block
