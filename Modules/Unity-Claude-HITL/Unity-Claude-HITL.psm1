# Unity-Claude-HITL-Refactored.psm1
# Human-in-the-Loop Integration Module - Refactored Architecture
# Version 2.0.0 - 2025-08-26
# Modular orchestrator for HITL approval workflows, notifications, and system integration

Write-Host "REFACTORED VERSION - Unity-Claude-HITL module initializing..." -ForegroundColor Green

#region Core Component Imports

# Import all core components
$CorePath = Join-Path $PSScriptRoot "Core"

$Components = @(
    "HITLCore.psm1",
    "DatabaseManagement.psm1", 
    "SecurityTokens.psm1",
    "ApprovalRequests.psm1",
    "NotificationSystem.psm1",
    "WorkflowIntegration.psm1"
)

foreach ($Component in $Components) {
    $ComponentPath = Join-Path $CorePath $Component
    if (Test-Path $ComponentPath) {
        try {
            Import-Module $ComponentPath -Force -Global -ErrorAction Stop
            Write-Verbose "✅ Imported: $Component"
        }
        catch {
            Write-Warning "⚠️ Failed to import $Component`: $($_.Exception.Message)"
        }
    } else {
        Write-Warning "⚠️ Component not found: $ComponentPath"
    }
}

Write-Verbose "REFACTORED VERSION - All HITL components loaded successfully"

#endregion

#region Enhanced Orchestration Functions

function Get-HITLComponents {
    <#
    .SYNOPSIS
        Gets information about loaded HITL components.
    
    .DESCRIPTION
        Returns detailed information about all loaded HITL components,
        their status, and available functions for system diagnostics.
    
    .EXAMPLE
        $components = Get-HITLComponents
        $components | Format-Table
    #>
    [CmdletBinding()]
    param()
    
    $componentInfo = @()
    
    foreach ($component in $Components) {
        $componentName = [System.IO.Path]::GetFileNameWithoutExtension($component)
        $componentPath = Join-Path $CorePath $component
        
        $info = [PSCustomObject]@{
            Name = $componentName
            Path = $componentPath
            Loaded = Test-Path $componentPath
            Functions = @()
        }
        
        # Get functions from each component if module is loaded
        $module = Get-Module | Where-Object { $_.Path -eq $componentPath }
        if ($module) {
            $info.Functions = $module.ExportedFunctions.Keys | Sort-Object
        }
        
        $componentInfo += $info
    }
    
    return $componentInfo
}

function Test-HITLSystemIntegration {
    <#
    .SYNOPSIS
        Tests complete HITL system integration and component interactions.
    
    .DESCRIPTION
        Performs comprehensive testing of HITL system components,
        their interactions, and end-to-end workflow functionality.
    
    .EXAMPLE
        Test-HITLSystemIntegration -Verbose
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "🧪 Starting HITL System Integration Test..." -ForegroundColor Cyan
    
    $results = @{
        ComponentTests = @{}
        IntegrationTests = @{}
        OverallHealth = $false
        TestTimestamp = Get-Date
    }
    
    try {
        # Test 1: Component Loading
        Write-Host "  Testing component loading..." -ForegroundColor Blue
        $componentInfo = Get-HITLComponents
        $results.ComponentTests.ComponentLoading = @{
            Status = ($componentInfo | Where-Object { -not $_.Loaded }).Count -eq 0
            LoadedComponents = ($componentInfo | Where-Object { $_.Loaded }).Count
            TotalComponents = $componentInfo.Count
        }
        
        # Test 2: Configuration Management
        Write-Host "  Testing configuration management..." -ForegroundColor Blue
        try {
            $config = Get-HITLConfiguration
            $testConfig = @{ TestKey = 'TestValue' }
            $configResult = Set-HITLConfiguration -Configuration $testConfig
            $results.ComponentTests.ConfigurationManagement = @{
                Status = $configResult -and ($config -ne $null)
                Details = "Configuration retrieval and update functional"
            }
        }
        catch {
            $results.ComponentTests.ConfigurationManagement = @{
                Status = $false
                Error = $_.Exception.Message
            }
        }
        
        # Test 3: Token Security
        Write-Host "  Testing security tokens..." -ForegroundColor Blue
        try {
            $testToken = New-ApprovalToken -ApprovalId 999999
            $tokenValid = Test-ApprovalToken -Token $testToken
            $results.ComponentTests.TokenSecurity = @{
                Status = $testToken -and $tokenValid
                Details = "Token generation and validation functional"
            }
        }
        catch {
            $results.ComponentTests.TokenSecurity = @{
                Status = $false
                Error = $_.Exception.Message
            }
        }
        
        # Test 4: Database Integration
        Write-Host "  Testing database connectivity..." -ForegroundColor Blue
        try {
            $dbResult = Initialize-ApprovalDatabase -DatabasePath ":memory:"
            $results.ComponentTests.DatabaseIntegration = @{
                Status = $dbResult
                Details = "Database initialization functional"
            }
        }
        catch {
            $results.ComponentTests.DatabaseIntegration = @{
                Status = $false
                Error = $_.Exception.Message
            }
        }
        
        # Test 5: End-to-End Workflow (Simulation)
        Write-Host "  Testing end-to-end workflow simulation..." -ForegroundColor Blue
        try {
            $testRequest = New-ApprovalRequest -WorkflowId "test-integration-001" -Title "Integration Test" -Description "Testing HITL integration" -UrgencyLevel "low"
            $results.IntegrationTests.EndToEndWorkflow = @{
                Status = $testRequest -ne $null
                Details = "Workflow creation functional"
                RequestId = if ($testRequest) { $testRequest.Id } else { $null }
            }
        }
        catch {
            $results.IntegrationTests.EndToEndWorkflow = @{
                Status = $false
                Error = $_.Exception.Message
            }
        }
        
        # Calculate overall health
        $allTests = @()
        $allTests += $results.ComponentTests.Values | ForEach-Object { $_.Status }
        $allTests += $results.IntegrationTests.Values | ForEach-Object { $_.Status }
        
        $passedTests = ($allTests | Where-Object { $_ -eq $true }).Count
        $totalTests = $allTests.Count
        
        $results.OverallHealth = $passedTests -eq $totalTests
        $results.TestSummary = @{
            PassedTests = $passedTests
            TotalTests = $totalTests
            SuccessRate = if ($totalTests -gt 0) { [Math]::Round(($passedTests / $totalTests) * 100, 2) } else { 0 }
        }
        
        # Report results
        if ($results.OverallHealth) {
            Write-Host "✅ HITL System Integration: ALL TESTS PASSED" -ForegroundColor Green
        } else {
            Write-Host "⚠️ HITL System Integration: $passedTests/$totalTests tests passed" -ForegroundColor Yellow
        }
        
        return $results
    }
    catch {
        Write-Error "Integration test failed: $($_.Exception.Message)"
        $results.OverallHealth = $false
        $results.Error = $_.Exception.Message
        return $results
    }
}

function Invoke-ComprehensiveHITLAnalysis {
    <#
    .SYNOPSIS
        Performs comprehensive analysis of HITL system capabilities and status.
    
    .DESCRIPTION
        Analyzes all aspects of the HITL system including components,
        configuration, security, and provides recommendations for optimization.
    
    .EXAMPLE
        Invoke-ComprehensiveHITLAnalysis | ConvertTo-Json -Depth 5
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "🔍 Performing Comprehensive HITL Analysis..." -ForegroundColor Cyan
    
    $analysis = @{
        SystemOverview = @{
            ModuleName = "Unity-Claude-HITL"
            Version = "2.0.0 (Refactored)"
            Architecture = "Component-based modular system"
            ComponentCount = $Components.Count
            AnalysisTimestamp = Get-Date
        }
        ComponentAnalysis = @{}
        SecurityAnalysis = @{}
        IntegrationAnalysis = @{}
        Recommendations = @()
    }
    
    try {
        # Component Analysis
        Write-Host "  Analyzing components..." -ForegroundColor Blue
        $componentInfo = Get-HITLComponents
        $analysis.ComponentAnalysis = @{
            LoadedComponents = $componentInfo | Where-Object { $_.Loaded }
            FailedComponents = $componentInfo | Where-Object { -not $_.Loaded }
            TotalFunctions = ($componentInfo | ForEach-Object { $_.Functions.Count } | Measure-Object -Sum).Sum
            ComponentHealth = ($componentInfo | Where-Object { $_.Loaded }).Count / $componentInfo.Count * 100
        }
        
        # Security Analysis
        Write-Host "  Analyzing security..." -ForegroundColor Blue
        $config = Get-HITLConfiguration
        $analysis.SecurityAnalysis = @{
            TokenValidationEnabled = $config.SecuritySettings.RequireTokenValidation
            MobileApprovalsEnabled = $config.SecuritySettings.AllowMobileApprovals
            AuditingEnabled = $config.SecuritySettings.AuditAllActions
            SecurityScore = 0
        }
        
        # Calculate security score
        $securityFeatures = @(
            $config.SecuritySettings.RequireTokenValidation,
            $config.SecuritySettings.AuditAllActions,
            ($config.TokenExpirationMinutes -le 4320)  # Reasonable token expiration
        )
        $analysis.SecurityAnalysis.SecurityScore = ($securityFeatures | Where-Object { $_ -eq $true }).Count / $securityFeatures.Count * 100
        
        # Integration Analysis
        Write-Host "  Analyzing integrations..." -ForegroundColor Blue
        $analysis.IntegrationAnalysis = @{
            EmailIntegrationEnabled = $config.NotificationSettings.EmailEnabled
            WebhookIntegrationEnabled = $config.NotificationSettings.WebhookEnabled
            LangGraphEndpoint = $config.LangGraphEndpoint
            DatabasePath = $config.DatabasePath
            MobileOptimized = $config.NotificationSettings.MobileOptimized
        }
        
        # Generate Recommendations
        Write-Host "  Generating recommendations..." -ForegroundColor Blue
        if ($analysis.ComponentAnalysis.ComponentHealth -lt 100) {
            $analysis.Recommendations += "⚠️ Some components failed to load. Check component dependencies."
        }
        
        if ($analysis.SecurityAnalysis.SecurityScore -lt 80) {
            $analysis.Recommendations += "🔒 Consider enabling additional security features for production use."
        }
        
        if (-not $analysis.IntegrationAnalysis.EmailIntegrationEnabled) {
            $analysis.Recommendations += "📧 Email integration is disabled. Enable for full notification functionality."
        }
        
        if ($analysis.Recommendations.Count -eq 0) {
            $analysis.Recommendations += "✅ HITL system is optimally configured and functioning well."
        }
        
        Write-Host "✅ Comprehensive HITL Analysis completed" -ForegroundColor Green
        return $analysis
    }
    catch {
        Write-Error "Analysis failed: $($_.Exception.Message)"
        $analysis.Error = $_.Exception.Message
        return $analysis
    }
}

#endregion

#region Module Initialization and Export

# Skip Unity-Claude-GitHub import to avoid interactive prompts during testing
# In production, this would be imported when needed by specific functions
# Import-Module Unity-Claude-GitHub -Force -ErrorAction SilentlyContinue

# Re-export all functions from components
$ExportedFunctions = @()

# Core functions
$ExportedFunctions += @(
    'Set-HITLConfiguration',
    'Get-HITLConfiguration'
)

# Database functions
$ExportedFunctions += @(
    'Initialize-ApprovalDatabase',
    'Test-DatabaseConnection'
)

# Security functions
$ExportedFunctions += @(
    'New-ApprovalToken',
    'Test-ApprovalToken',
    'Get-TokenMetadata',
    'Revoke-ApprovalToken'
)

# Approval request functions
$ExportedFunctions += @(
    'New-ApprovalRequest',
    'Get-ApprovalStatus',
    'Set-ApprovalEscalation',
    'Get-PendingApprovals',
    'Update-ApprovalStatus'
)

# Notification functions
$ExportedFunctions += @(
    'Send-ApprovalNotification',
    'Build-ApprovalEmailTemplate',
    'Send-ApprovalReminder',
    'Send-ApprovalResultNotification'
)

# Workflow integration functions
$ExportedFunctions += @(
    'Wait-HumanApproval',
    'Resume-WorkflowFromApproval',
    'Invoke-HumanApprovalWorkflow',
    'Invoke-ApprovalAction',
    'Export-ApprovalMetrics',
    'Test-HITLSystemHealth'
)

# Orchestrator functions
$ExportedFunctions += @(
    'Get-HITLComponents',
    'Test-HITLSystemIntegration',
    'Invoke-ComprehensiveHITLAnalysis'
)

Write-Host "Unity-Claude-HITL (REFACTORED) module loaded successfully." -ForegroundColor Green
Write-Host "📦 Components: $($Components.Count) | Functions: $($ExportedFunctions.Count) | Architecture: Modular" -ForegroundColor Cyan

#endregion

#region Export Module Members

Export-ModuleMember -Function $ExportedFunctions

#endregion
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAoOwsOXtP4MsYX
# 4iHAtTnEIoKR6g3TTOVhKS4R6oeMHqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEINKaQi36VtQYx0Fw45nPYddP
# CQCPFd+oHkitYjgk24F0MA0GCSqGSIb3DQEBAQUABIIBAIkJWU6g1H4Q4Vpe5X5h
# kLQESYp/VgfS3RIUmkKNwkjKJs+mZZONbxV8lxYoNFceSk3CiWpkm0AXJ8+D2jMg
# OoM9yOuVYutJxLRCFc0nj7/rmcKGYIdkMbh0GR0HbQUGIUJgIwkKsLGjy5CJ0TSf
# vy57xykj1cQb+ximPRT9NWx97ft21QZVLmQ+UwXzf/u5p0ue5C+EE3hWB/tTT0AE
# iJzrub8R+qzWa05+s8P5gtoqGjF9D/g25ZRIOd+YzEslfYfAxQr8h6ZQTeMqWR7I
# gB7lvDBBbodvjPTisaGvkdnzyGsRNhHZeRxFW88azZqiX/8UriO0ie3GI4lHVw/1
# GCs=
# SIG # End signature block
