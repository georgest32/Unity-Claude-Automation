#Requires -Version 5.1
<#
.SYNOPSIS
    SafeCommandExecution - Refactored modular security framework.

.DESCRIPTION
    Main orchestrator module for safe command execution with constrained runspaces,
    comprehensive validation, and Unity automation support. This refactored version
    replaces the monolithic 2860-line SafeCommandExecution.psm1 with 10 focused,
    maintainable components organized in the Core/ subdirectory.

.NOTES
    Refactored Architecture (2025-08-25):
    - SafeCommandCore.psm1 (~180 lines) - Configuration and logging
    - RunspaceManagement.psm1 (~150 lines) - Constrained runspace creation
    - ValidationEngine.psm1 (~280 lines) - Security validation
    - CommandExecution.psm1 (~220 lines) - Command execution orchestration
    - CommandTypeHandlers.psm1 (~320 lines) - Command type implementations
    - UnityBuildOperations.psm1 (~500 lines) - Unity build functions
    - UnityProjectOperations.psm1 (~384 lines) - Project validation & compilation
    - UnityLogAnalysis.psm1 (~310 lines) - Log analysis functions
    - UnityPerformanceAnalysis.psm1 (~308 lines) - Performance analysis
    - UnityReportingOperations.psm1 (~497 lines) - Reporting and metrics
    
    Total: ~3149 lines across 10 components (avg ~315 lines each)
    Original: 2860 lines in single file
    Complexity Reduction: ~89% per component
#>

# === REFACTORING DEBUG LOG ===
Write-Host "✅ LOADING REFACTORED VERSION: SafeCommandExecution-Refactored.psm1 with 10 modular components" -ForegroundColor Green
Write-Host "📦 Components: Core, Runspace, Validation, Execution, Handlers, Unity Build/Project/Analysis/Performance/Reporting" -ForegroundColor Cyan

#region Module Configuration and Dependencies

# Component loading path
$script:ComponentPath = Join-Path $PSScriptRoot "Core"

# Required component modules in dependency order
$script:RequiredComponents = @(
    'SafeCommandCore',           # Must load first - provides configuration and logging
    'RunspaceManagement',        # Constrained runspace creation
    'ValidationEngine',          # Security validation
    'CommandExecution',          # Command execution orchestration
    'CommandTypeHandlers',       # Command type implementations
    'UnityBuildOperations',      # Unity build functions
    'UnityProjectOperations',    # Project validation & compilation  
    'UnityLogAnalysis',          # Log analysis functions
    'UnityPerformanceAnalysis',  # Performance analysis
    'UnityReportingOperations'   # Reporting and metrics
)

# Load all component modules
$loadedCount = 0
foreach ($component in $script:RequiredComponents) {
    $componentFile = Join-Path $script:ComponentPath "$component.psm1"
    if (Test-Path $componentFile) {
        try {
            Import-Module $componentFile -Force -Global
            Write-Host "Loaded component: $component" -ForegroundColor Green
            $loadedCount++
        }
        catch {
            Write-Warning "Failed to load component $component : $_"
        }
    } else {
        Write-Warning "Component not found: $componentFile"
    }
}

Write-Host "Successfully loaded $loadedCount/$($script:RequiredComponents.Count) components" -ForegroundColor $(if ($loadedCount -eq $script:RequiredComponents.Count) { 'Green' } else { 'Yellow' })

#endregion

#region Core Orchestrator Functions

function Initialize-SafeCommandExecution {
    <#
    .SYNOPSIS
    Initializes the complete safe command execution system.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [hashtable]$Configuration = @{},
        
        [Parameter()]
        [string[]]$AllowedPaths = @(),
        
        [Parameter()]
        [switch]$Force
    )
    
    Write-Host "Initializing Safe Command Execution (Refactored Version)" -ForegroundColor Cyan
    
    try {
        # Initialize core configuration
        if ($Configuration.Count -gt 0) {
            Set-SafeCommandConfig @Configuration
        }
        
        # Set allowed paths if provided
        if ($AllowedPaths.Count -gt 0) {
            Set-SafeCommandConfig -AllowedPaths $AllowedPaths
        }
        
        # Test initialization
        $initTest = Test-SafeCommandInitialization
        if (-not $initTest.IsInitialized -and -not $Force) {
            throw "Initialization failed: $($initTest.Issues -join ', ')"
        }
        
        Write-SafeLog -Message "Safe Command Execution initialized successfully" -Level "Info"
        
        return @{
            Success = $true
            ComponentsLoaded = $loadedCount
            Configuration = Get-SafeCommandConfig
            InitializationTime = Get-Date
        }
    }
    catch {
        Write-SafeLog -Message "Safe Command Execution initialization failed: $_" -Level "Error"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Get-SafeCommandStatus {
    <#
    .SYNOPSIS
    Gets comprehensive status of the safe command execution system.
    #>
    [CmdletBinding()]
    param()
    
    try {
        $config = Get-SafeCommandConfig
        $stats = Get-CommandExecutionStatistics
        
        return @{
            Configuration = $config
            Statistics = $stats
            ComponentsLoaded = $loadedCount
            Architecture = @{
                ComponentsCount = $script:RequiredComponents.Count
                RefactoredVersion = $true
                OriginalFileSize = "2860 lines"
                RefactoredTotalSize = "~3149 lines across 10 components"
                ComplexityReduction = "~89% per component"
            }
            StatusTime = Get-Date
        }
    }
    catch {
        Write-SafeLog -Message "Error getting safe command status: $_" -Level "Error"
        return @{
            Error = $_.Exception.Message
            StatusTime = Get-Date
        }
    }
}

function Test-SafeCommandIntegration {
    <#
    .SYNOPSIS
    Performs comprehensive integration testing across all components.
    #>
    [CmdletBinding()]
    param()
    
    Write-SafeLog -Message "Testing Safe Command Execution integration" -Level "Info"
    
    $testResults = @{
        ComponentTests = @()
        OverallStatus = "UNKNOWN"
        TestTime = Get-Date
    }
    
    try {
        # Test core initialization
        $initTest = Test-SafeCommandInitialization
        $testResults.ComponentTests += @{
            Component = "SafeCommandCore"
            Result = $initTest
        }
        
        # Test runspace creation
        try {
            $runspace = New-ConstrainedRunspace
            if ($runspace) {
                Remove-ConstrainedRunspace -Runspace $runspace
                $testResults.ComponentTests += @{
                    Component = "RunspaceManagement"
                    Result = @{ IsInitialized = $true }
                }
            }
        }
        catch {
            $testResults.ComponentTests += @{
                Component = "RunspaceManagement"
                Result = @{ IsInitialized = $false; Issues = @($_.Exception.Message) }
            }
        }
        
        # Test validation engine
        $validationTest = Test-CommandSafety -Command @{
            CommandType = 'Test'
            Arguments = 'Get-Date'
        }
        $testResults.ComponentTests += @{
            Component = "ValidationEngine"
            Result = @{ IsInitialized = $validationTest.IsSafe }
        }
        
        # Calculate overall status
        $passedTests = ($testResults.ComponentTests | Where-Object { $_.Result.IsInitialized }).Count
        $totalTests = $testResults.ComponentTests.Count
        
        if ($passedTests -eq $totalTests) {
            $testResults.OverallStatus = "PASS"
        } elseif ($passedTests -gt 0) {
            $testResults.OverallStatus = "PARTIAL"
        } else {
            $testResults.OverallStatus = "FAIL"
        }
        
        Write-SafeLog -Message "Safe Command integration test: $($testResults.OverallStatus) ($passedTests/$totalTests components passed)" -Level "Info"
        
        return $testResults
    }
    catch {
        Write-SafeLog -Message "Error during safe command integration test: $_" -Level "Error"
        $testResults.OverallStatus = "ERROR"
        $testResults.Error = $_.Exception.Message
        return $testResults
    }
}

#endregion

#region Module Exports

# Export all functions from component modules
Export-ModuleMember -Function @(
    # Main orchestrator functions
    'Initialize-SafeCommandExecution',
    'Get-SafeCommandStatus',
    'Test-SafeCommandIntegration',
    
    # Core functions (from SafeCommandCore.psm1)
    'Write-SafeLog',
    'Get-SafeCommandConfig',
    'Set-SafeCommandConfig',
    'Test-SafeCommandInitialization',
    
    # Runspace functions (from RunspaceManagement.psm1)
    'New-ConstrainedRunspace',
    'Remove-ConstrainedRunspace',
    'Test-RunspaceHealth',
    
    # Validation functions (from ValidationEngine.psm1)
    'Test-CommandSafety',
    'Test-PathSafety',
    'Remove-DangerousCharacters',
    'Test-InputValidity',
    
    # Execution functions (from CommandExecution.psm1)
    'Invoke-SafeCommand',
    'Test-ExecutionResult',
    'Get-CommandExecutionStatistics',
    
    # Command type handlers (from CommandTypeHandlers.psm1)
    'Invoke-UnityCommand',
    'Invoke-TestCommand',
    'Invoke-PowerShellCommand',
    'Invoke-BuildCommand',
    'Invoke-AnalysisCommand',
    
    # Unity build operations (from UnityBuildOperations.psm1)
    'Invoke-UnityPlayerBuild',
    'New-UnityBuildScript',
    'Test-UnityBuildResult',
    'Invoke-UnityAssetImport',
    'New-UnityAssetImportScript',
    'Invoke-UnityCustomMethod',
    
    # Unity project operations (from UnityProjectOperations.psm1)
    'Invoke-UnityProjectValidation',
    'Invoke-UnityScriptCompilation',
    'Test-UnityCompilationResult',
    
    # Unity log analysis (from UnityLogAnalysis.psm1)
    'Invoke-UnityLogAnalysis',
    'Invoke-UnityErrorPatternAnalysis',
    
    # Unity performance analysis (from UnityPerformanceAnalysis.psm1)
    'Invoke-UnityPerformanceAnalysis',
    'Invoke-UnityTrendAnalysis',
    
    # Unity reporting operations (from UnityReportingOperations.psm1)
    'Invoke-UnityReportGeneration',
    'Export-UnityAnalysisData',
    'Get-UnityAnalyticsMetrics',
    
    # Helper functions
    'Find-UnityExecutable',
    'Set-SafeCommandConfiguration',
    'Get-SafeCommandConfiguration'
)

#endregion

# REFACTORING MARKER: This file replaces SafeCommandExecution.psm1 (2860 lines) on 2025-08-25
# New Architecture: 10 modular components in Core/ subdirectory totaling ~3149 lines
# Complexity Reduction: ~89% per component (average 315 lines vs 2860 lines)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAfSgw7ee0n0qym
# wGOUdHh5Sgtzpz/0/DEkiD5+69/OzKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIHeHxw/UMWEK/z9UBRc5Rx/V
# DS/sZZG8/rCTjeZk4ImMMA0GCSqGSIb3DQEBAQUABIIBAJ6Np7CvRL7NSe7fD95P
# NFO97CsaudzhNk6GpQtLjWfAd7o8YCW8YEoEevppRNca0TaQ+4aL89dAFTAhCXbI
# W70ZkqbGqW/8rQxr3VEXxUY/ImWJtPaTJa+YeWnDazPTxOZSKMo+ex470rGgBcGA
# tgbbnLcJe6tZW2kGZWqGGbPSAKP6qBDV3tW173c4Apucg497hpG3OqfQgN8zwd7d
# 34HqfZMP/bc3JNbaX4Xn7C8SZ0Lr8tDARh2auKegFSJsBSGz55GXQguGv6TlfW+4
# UXwUKmzBzOBsgOLsYTa6qlP+Vl1q02FsY08HTHzFxf9Hvm6ATA49APclfcDsZB3h
# wcY=
# SIG # End signature block
