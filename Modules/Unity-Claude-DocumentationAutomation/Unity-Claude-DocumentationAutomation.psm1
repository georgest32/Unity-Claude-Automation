#region Module Header

# Module self-registration for session visibility
if (-not $ExecutionContext.SessionState.Module) {
    $ModuleName = 'Unity-Claude-DocumentationAutomation'
    if (-not (Get-Module -Name $ModuleName)) {
        # Module is being imported but not yet visible in session
        Write-Verbose "[$ModuleName] Ensuring module registration in session" -Verbose:$false
    }
} else {
    # Module context is properly established
    Write-Verbose "[$($ExecutionContext.SessionState.Module.Name)] Module context established" -Verbose:$false
}
<#
.SYNOPSIS
    Unity-Claude Documentation Automation Module - Refactored
    Phase 3 Day 3-4 Hours 5-8: Automated Documentation Updates
    
.DESCRIPTION
    Provides automated documentation update system with GitHub PR automation,
    intelligent synchronization, and review workflows. This is the refactored version
    with modular component architecture.
    
.VERSION
    2.0.0
    
.AUTHOR
    Unity-Claude-Automation
    
.DATE
    2025-08-25
    
.ARCHITECTURE
    This module follows a component-based architecture with specialized modules:
    - AutomationEngine: Core automation lifecycle management
    - GitHubPRManager: Pull request creation and management  
    - TemplateSystem: Documentation template system
    - TriggerSystem: Auto-generation triggers and workflows
    - BackupIntegration: Backup/recovery and system integration
    
.REFACTORING_NOTES
    Original module: 1,633 lines
    Refactored components: 5 modules, ~350 lines each
    Benefits: Improved maintainability, testability, and modularity
#>
#endregion

#region Private Variables
$script:DocumentationAutomationConfig = @{
    IsRunning = $false
    TriggerInterval = 15 # minutes
    LastRunTime = $null
    ActiveTriggers = @()
    BackupLocation = "${env:TEMP}\DocAutomationBackups"
    ReviewQueue = @()
    PRHistory = @()
}

$script:TemplateCache = @{}
$script:TriggerJobs = @{}
#endregion

#region Component Imports

# Import core automation engine
Import-Module (Join-Path $PSScriptRoot "Core\AutomationEngine.psm1") -Force -Global

# Import GitHub PR management
Import-Module (Join-Path $PSScriptRoot "Core\GitHubPRManager.psm1") -Force -Global

# Import template system
Import-Module (Join-Path $PSScriptRoot "Core\TemplateSystem.psm1") -Force -Global

# Import trigger system
Import-Module (Join-Path $PSScriptRoot "Core\TriggerSystem.psm1") -Force -Global

# Import backup and integration
Import-Module (Join-Path $PSScriptRoot "Core\BackupIntegration.psm1") -Force -Global

#endregion

#region Enhanced Orchestration Functions

function Initialize-DocumentationAutomation {
    <#
    .SYNOPSIS
        Initializes the documentation automation system
    .DESCRIPTION
        Performs comprehensive initialization of all automation components
    .PARAMETER LoadTemplates
        Load templates from disk during initialization
    .PARAMETER RegisterDefaultTriggers
        Register default file monitoring triggers
    .EXAMPLE
        Initialize-DocumentationAutomation -LoadTemplates -RegisterDefaultTriggers
    #>
    [CmdletBinding()]
    param(
        [switch]$LoadTemplates,
        [switch]$RegisterDefaultTriggers,
        [int]$TriggerInterval = 15
    )
    
    try {
        Write-Host "Initializing Documentation Automation System v2.0..." -ForegroundColor Cyan
        
        # Initialize configuration
        $script:DocumentationAutomationConfig.TriggerInterval = $TriggerInterval
        
        # Initialize backup location
        if (-not (Test-Path $script:DocumentationAutomationConfig.BackupLocation)) {
            New-Item -Path $script:DocumentationAutomationConfig.BackupLocation -ItemType Directory -Force | Out-Null
            Write-Verbose "Created backup location: $($script:DocumentationAutomationConfig.BackupLocation)"
        }
        
        # Load templates if requested
        if ($LoadTemplates) {
            $templatesLoaded = 0
            $templatesPath = Join-Path $script:DocumentationAutomationConfig.BackupLocation "Templates"
            if (Test-Path $templatesPath) {
                Get-ChildItem -Path $templatesPath -Filter "*.json" | ForEach-Object {
                    try {
                        $template = Get-Content $_.FullName | ConvertFrom-Json
                        $script:TemplateCache[$template.Name] = $template
                        $templatesLoaded++
                    } catch {
                        Write-Warning "Could not load template: $($_.Name)"
                    }
                }
            }
            Write-Host "  Loaded templates: $templatesLoaded" -ForegroundColor Gray
        }
        
        # Register default triggers if requested
        if ($RegisterDefaultTriggers) {
            $triggersRegistered = 0
            
            # PowerShell file changes
            Register-DocumentationTrigger -Name "PowerShellFiles" -Type "FileChange" -Condition "*.psm1" -Priority 1
            $triggersRegistered++
            
            # C# script changes
            Register-DocumentationTrigger -Name "CSharpFiles" -Type "FileChange" -Condition "*.cs" -Priority 2
            $triggersRegistered++
            
            # Git commits
            Register-DocumentationTrigger -Name "GitCommits" -Type "GitCommit" -Condition "main" -Priority 3
            $triggersRegistered++
            
            Write-Host "  Registered triggers: $triggersRegistered" -ForegroundColor Gray
        }
        
        # Initialize component health check
        $componentHealth = Test-ComponentHealth
        $healthyComponents = ($componentHealth.Components | Where-Object { $_.Status -eq 'Healthy' }).Count
        
        Write-Host "Documentation Automation System initialized successfully" -ForegroundColor Green
        Write-Host "  Version: 2.0.0 (Refactored)" -ForegroundColor Gray
        Write-Host "  Components: $healthyComponents/$($componentHealth.Components.Count) healthy" -ForegroundColor Gray
        Write-Host "  Trigger interval: $TriggerInterval minutes" -ForegroundColor Gray
        
        return @{
            Version = "2.0.0"
            Initialized = $true
            ComponentHealth = $componentHealth
            TemplatesLoaded = if ($LoadTemplates) { $templatesLoaded } else { 0 }
            TriggersRegistered = if ($RegisterDefaultTriggers) { $triggersRegistered } else { 0 }
        }
        
    } catch {
        Write-Error "Failed to initialize documentation automation: $_"
        throw
    }
}

function Test-ComponentHealth {
    <#
    .SYNOPSIS
        Tests health of all documentation automation components
    .DESCRIPTION
        Performs health checks on all system components
    .EXAMPLE
        Test-ComponentHealth
    #>
    [CmdletBinding()]
    param()
    
    try {
        $healthResults = @{
            Overall = 'Healthy'
            TestedAt = Get-Date
            Components = @()
        }
        
        # Test AutomationEngine component
        try {
            $status = Get-DocumentationStatus
            $healthResults.Components += @{
                Name = 'AutomationEngine'
                Status = 'Healthy'
                Details = "Running: $($status.IsRunning), Jobs: $($status.ActiveJobs.Count)"
            }
        } catch {
            $healthResults.Components += @{
                Name = 'AutomationEngine'
                Status = 'Error'
                Details = $_.Exception.Message
            }
            $healthResults.Overall = 'Degraded'
        }
        
        # Test GitHubPRManager component
        try {
            $prs = Get-DocumentationPRs -Limit 1
            $healthResults.Components += @{
                Name = 'GitHubPRManager'
                Status = 'Healthy'
                Details = "PR history accessible"
            }
        } catch {
            $healthResults.Components += @{
                Name = 'GitHubPRManager'
                Status = 'Error'
                Details = $_.Exception.Message
            }
            $healthResults.Overall = 'Degraded'
        }
        
        # Test TemplateSystem component
        try {
            $templates = Get-DocumentationTemplates
            $healthResults.Components += @{
                Name = 'TemplateSystem'
                Status = 'Healthy'
                Details = "Templates: $($templates.Count)"
            }
        } catch {
            $healthResults.Components += @{
                Name = 'TemplateSystem'
                Status = 'Error'
                Details = $_.Exception.Message
            }
            $healthResults.Overall = 'Degraded'
        }
        
        # Test TriggerSystem component
        try {
            $triggers = Get-DocumentationTriggers
            $healthResults.Components += @{
                Name = 'TriggerSystem'
                Status = 'Healthy'
                Details = "Triggers: $($triggers.Count)"
            }
        } catch {
            $healthResults.Components += @{
                Name = 'TriggerSystem'
                Status = 'Error'
                Details = $_.Exception.Message
            }
            $healthResults.Overall = 'Degraded'
        }
        
        # Test BackupIntegration component
        try {
            $history = Get-DocumentationHistory -Limit 1
            $healthResults.Components += @{
                Name = 'BackupIntegration'
                Status = 'Healthy'
                Details = "Backup system operational"
            }
        } catch {
            $healthResults.Components += @{
                Name = 'BackupIntegration'
                Status = 'Error'
                Details = $_.Exception.Message
            }
            $healthResults.Overall = 'Degraded'
        }
        
        return $healthResults
        
    } catch {
        Write-Error "Failed to test component health: $_"
        throw
    }
}

function Get-DocumentationAutomationInfo {
    <#
    .SYNOPSIS
        Gets comprehensive information about the documentation automation system
    .DESCRIPTION
        Returns detailed system information including version, components, and metrics
    .EXAMPLE
        Get-DocumentationAutomationInfo
    #>
    [CmdletBinding()]
    param()
    
    try {
        $info = @{
            Version = "2.0.0"
            Architecture = "Component-Based"
            Components = @(
                @{ Name = "AutomationEngine"; Description = "Core automation lifecycle management"; LinesSaved = "~250" }
                @{ Name = "GitHubPRManager"; Description = "Pull request creation and management"; LinesSaved = "~270" }
                @{ Name = "TemplateSystem"; Description = "Documentation template system"; LinesSaved = "~320" }
                @{ Name = "TriggerSystem"; Description = "Auto-generation triggers and workflows"; LinesSaved = "~490" }
                @{ Name = "BackupIntegration"; Description = "Backup/recovery and system integration"; LinesSaved = "~300" }
            )
            Metrics = @{
                OriginalLines = 1633
                RefactoredComponents = 5
                AverageComponentSize = 326
                Maintainability = "Improved"
                Testability = "Enhanced"
            }
            Benefits = @(
                "Separation of concerns with focused components"
                "Improved code maintainability and readability"  
                "Enhanced testability with isolated components"
                "Better error isolation and debugging"
                "Easier feature development and extension"
            )
        }
        
        # Add runtime information
        $status = Get-DocumentationStatus
        $info.Runtime = @{
            IsRunning = $status.IsRunning
            LastRunTime = $status.LastRunTime
            ActiveJobs = $status.ActiveJobs.Count
            ActiveTriggers = $status.ActiveTriggers
            ReviewQueueLength = $status.ReviewQueueLength
        }
        
        return $info
        
    } catch {
        Write-Error "Failed to get documentation automation info: $_"
        throw
    }
}

#endregion

#region Module Initialization
# Initialize module state
if (-not $script:DocumentationAutomationConfig.BackupLocation) {
    $script:DocumentationAutomationConfig.BackupLocation = "${env:TEMP}\DocAutomationBackups"
}

# Load templates from disk if they exist
$templatesPath = Join-Path $script:DocumentationAutomationConfig.BackupLocation "Templates"
if (Test-Path $templatesPath) {
    Get-ChildItem -Path $templatesPath -Filter "*.json" | ForEach-Object {
        try {
            $template = Get-Content $_.FullName | ConvertFrom-Json
            $script:TemplateCache[$template.Name] = $template
        } catch {
            Write-Verbose "Could not load template: $($_.Name)"
        }
    }
}
#endregion

# Export all functions from components plus orchestration functions
Export-ModuleMember -Function @(
    # Orchestration functions
    'Initialize-DocumentationAutomation',
    'Test-ComponentHealth',
    'Get-DocumentationAutomationInfo',
    
    # AutomationEngine functions
    'Start-DocumentationAutomation',
    'Stop-DocumentationAutomation', 
    'Test-DocumentationSync',
    'Get-DocumentationStatus',
    
    # GitHubPRManager functions
    'New-DocumentationPR',
    'Update-DocumentationPR',
    'Get-DocumentationPRs',
    'Merge-DocumentationPR',
    'Test-PRDocumentationChanges',
    
    # TemplateSystem functions
    'New-DocumentationTemplate',
    'Get-DocumentationTemplates',
    'Update-DocumentationTemplate',
    'Export-DocumentationTemplates',
    'Import-DocumentationTemplates',
    'Invoke-TemplateRendering',
    
    # TriggerSystem functions
    'Register-DocumentationTrigger',
    'Unregister-DocumentationTrigger',
    'Get-DocumentationTriggers',
    'Test-TriggerConditions',
    'Invoke-DocumentationUpdate',
    'Start-DocumentationReview',
    'Get-ReviewStatus',
    'Approve-DocumentationChanges',
    'Reject-DocumentationChanges',
    'Get-ReviewMetrics',
    
    # BackupIntegration functions
    'New-DocumentationBackup',
    'Restore-DocumentationBackup',
    'Get-DocumentationHistory',
    'Test-RollbackCapability',
    'Sync-WithPredictiveAnalysis',
    'Update-FromCodeChanges',
    'Generate-ImprovementDocs',
    'Export-DocumentationReport'
    
) -Alias @('sda', 'ndr', 'idt', 'gds', 'ndb', 'ida')

# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAKvL+PvGIGP62e
# INqYSmPSGKRdySg5SNenEpxHhjSprKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIMsxVoouFv4t+kMXn9JfTJw5
# ypcHVExpOFGnNMN3O8ZwMA0GCSqGSIb3DQEBAQUABIIBAGoeqUxFWuoSRUNDAOQs
# I6ZX3DPJI6Nfj2nF0mhC1csgp9DXcvIbqNs0m1LNiKmMWGXPj7RJ97J/dYF8gRBY
# 1lZoorW5QfNKahjcF7d5gpw37vasgDDtiepQKGYBC30oHUbkPG77VQmhRaAsftwU
# TK3XsZWVy18CFrCAPuR6WMa+qeG5+W26tnWMxnDBl2nVja16hvTr7DsApkxlwlSh
# OCGtK8jOMXRK+AgRvk8PELF1GQIm5jyvvGXTRlvSVUkR6bCHB/jFnCfIFUbER/ym
# ysCl4ZEs1GAwAyHlhoiIjZ8i9+6lEuDOiEc1JwUtdOyavgBPixmFD6unIBjMRdH6
# rfM=
# SIG # End signature block
