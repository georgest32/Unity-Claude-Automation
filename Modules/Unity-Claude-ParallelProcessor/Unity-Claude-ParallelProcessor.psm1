# Unity-Claude-ParallelProcessor-Refactored.psm1
# Refactored version of Unity-Claude-ParallelProcessor with modular component architecture
# This orchestrator module imports all Core components to maintain backward compatibility

using namespace System.Management.Automation.Runspaces
using namespace System.Collections.Concurrent
using namespace System.Threading

Write-Debug "[Unity-Claude-ParallelProcessor] Loading refactored module - ORCHESTRATOR VERSION"

#region Version and Module Information

$ModuleVersion = "2.0.0-Refactored"
$ModuleName = "Unity-Claude-ParallelProcessor"
$ComponentPath = "$PSScriptRoot\Core"

Write-Debug "[Unity-Claude-ParallelProcessor] Module: $ModuleName, Version: $ModuleVersion"
Write-Debug "[Unity-Claude-ParallelProcessor] Component Path: $ComponentPath"

#endregion

#region Component Import Section

# Import all core components in dependency order and make functions globally available
try {
    # 1. Core utilities and configuration (no dependencies)
    Write-Debug "[Unity-Claude-ParallelProcessor] Importing ParallelProcessorCore component..."
    Import-Module "$ComponentPath\ParallelProcessorCore.psm1" -Force -Global
    
    # 2. Runspace pool management (depends on Core) - Import before JobScheduler
    Write-Debug "[Unity-Claude-ParallelProcessor] Importing RunspacePoolManager component..."  
    Import-Module "$ComponentPath\RunspacePoolManager.psm1" -Force -Global
    
    # 3. Statistics tracking (depends on Core)
    Write-Debug "[Unity-Claude-ParallelProcessor] Importing StatisticsTracker component..."
    Import-Module "$ComponentPath\StatisticsTracker.psm1" -Force -Global
    
    # 4. Job scheduling (depends on Core and RunspacePoolManager)
    Write-Debug "[Unity-Claude-ParallelProcessor] Importing JobScheduler component..."
    Import-Module "$ComponentPath\JobScheduler.psm1" -Force -Global
    
    # 5. Batch processing engine (depends on Core)
    Write-Debug "[Unity-Claude-ParallelProcessor] Importing BatchProcessingEngine component..."
    Import-Module "$ComponentPath\BatchProcessingEngine.psm1" -Force -Global
    
    # 6. Public API functions (depends on all components)
    Write-Debug "[Unity-Claude-ParallelProcessor] Importing ModuleFunctions component..."
    Import-Module "$ComponentPath\ModuleFunctions.psm1" -Force -Global
    
    Write-Debug "[Unity-Claude-ParallelProcessor] All components imported successfully"
} catch {
    Write-Error "[Unity-Claude-ParallelProcessor] Failed to import component: $($_.Exception.Message)"
    Write-Debug "[Unity-Claude-ParallelProcessor] Stack trace: $($_.ScriptStackTrace)"
    throw "Failed to load Unity-Claude-ParallelProcessor components: $_"
}

#endregion

#region Module Validation

try {
    # Verify all essential functions are available
    $requiredFunctions = @(
        'New-ParallelProcessor',
        'Invoke-ParallelProcessing',
        'Start-BatchProcessing',
        'Get-ParallelProcessorStatistics',
        'Get-JobStatus',
        'Stop-ParallelProcessor',
        'Test-ParallelProcessorHealth'
    )
    
    $missingFunctions = @()
    foreach ($func in $requiredFunctions) {
        if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
            $missingFunctions += $func
        }
    }
    
    if ($missingFunctions.Count -gt 0) {
        throw "Missing required functions after component import: $($missingFunctions -join ', ')"
    }
    
    Write-Debug "[Unity-Claude-ParallelProcessor] Module validation completed successfully"
    Write-Debug "[Unity-Claude-ParallelProcessor] Available functions: $($requiredFunctions.Count)"
} catch {
    Write-Error "[Unity-Claude-ParallelProcessor] Module validation failed: $_"
    throw
}

#endregion

#region Module Metadata and Help

$ModuleInfo = @{
    Name = $ModuleName
    Version = $ModuleVersion
    Description = "Refactored PowerShell parallel processing module with modular architecture"
    Author = "Unity-Claude-Automation"
    Architecture = "Modular Component-Based"
    Components = @(
        "ParallelProcessorCore - Core utilities and configuration",
        "RunspacePoolManager - Runspace pool lifecycle management", 
        "JobScheduler - Job submission, execution and tracking",
        "StatisticsTracker - Performance statistics and monitoring",
        "BatchProcessingEngine - Batch processing with producer-consumer patterns",
        "ModuleFunctions - Public API and main processor class"
    )
    Compatibility = "Backward compatible with original Unity-Claude-ParallelProcessor.psm1"
    RequiredPowerShellVersion = "5.1"
    ThreadSafety = "Full thread-safety with concurrent collections"
}

# Make module info available
$global:UnityClaudeParallelProcessorInfo = $ModuleInfo

function Get-UnityClaudeParallelProcessorInfo {
    <#
    .SYNOPSIS
        Gets information about the refactored Unity-Claude-ParallelProcessor module
    .DESCRIPTION
        Returns detailed information about the module architecture, components, and capabilities
    .EXAMPLE
        Get-UnityClaudeParallelProcessorInfo
    #>
    return $global:UnityClaudeParallelProcessorInfo
}

#endregion

#region Compatibility Layer

# Ensure backward compatibility with any legacy usage patterns
try {
    # Register module in global processor registry if not already registered
    if (Get-Command Register-ParallelProcessor -ErrorAction SilentlyContinue) {
        Register-ParallelProcessor -ModuleName $ModuleName -Version $ModuleVersion -Architecture "Refactored"
    }
    
    Write-Debug "[Unity-Claude-ParallelProcessor] Compatibility layer initialized"
} catch {
    Write-Debug "[Unity-Claude-ParallelProcessor] Compatibility layer warning: $_"
}

#endregion

#region Module Cleanup Handler

# Register cleanup handler for proper resource disposal
$OnRemoveScript = {
    Write-Debug "[Unity-Claude-ParallelProcessor] Module removal cleanup starting..."
    
    try {
        # Stop any running processors
        if (Get-Command Get-ParallelProcessorRegistry -ErrorAction SilentlyContinue) {
            $registry = Get-ParallelProcessorRegistry
            foreach ($processorId in $registry.Keys) {
                try {
                    Stop-ParallelProcessor -ProcessorId $processorId -Force
                } catch {
                    Write-Debug "[Unity-Claude-ParallelProcessor] Warning: Could not stop processor $processorId during cleanup: $_"
                }
            }
        }
        
        Write-Debug "[Unity-Claude-ParallelProcessor] Module cleanup completed"
    } catch {
        Write-Debug "[Unity-Claude-ParallelProcessor] Module cleanup error: $_"
    }
}

$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = $OnRemoveScript

#endregion

#region Export Section

# Public surface expected by the test suite and consumers
$__publicFunctions = @(
    # Helper/Core functions
    'Get-OptimalThreadCount',
    'New-RunspacePoolManager',
    'New-JobScheduler',
    'New-StatisticsTracker',
    'Test-RunspacePoolHealth',
    'Format-StatisticsReport',
    # Main public API functions
    'New-ParallelProcessor',
    'Invoke-ParallelProcessing',
    'Start-BatchProcessing',
    'Get-ParallelProcessorStatistics',
    'Get-JobStatus',
    'Stop-ParallelProcessor',
    'Test-ParallelProcessorHealth',
    'Get-UnityClaudeParallelProcessorInfo'
) | Where-Object { $_ -and (Get-Command $_ -ErrorAction SilentlyContinue) }

Write-Debug "[Unity-Claude-ParallelProcessor] Found $($__publicFunctions.Count) functions available for export"
Write-Debug "[Unity-Claude-ParallelProcessor] Functions: $($__publicFunctions -join ', ')"

if ($__publicFunctions.Count -gt 0) {
    Export-ModuleMember -Function $__publicFunctions
    Write-Debug "[Unity-Claude-ParallelProcessor] Successfully exported $($__publicFunctions.Count) functions"
} else {
    Write-Warning "[Unity-Claude-ParallelProcessor] No functions found to export!"
}

#endregion

# Final initialization message
Write-Debug "[Unity-Claude-ParallelProcessor] Refactored module loaded successfully!"
Write-Information "Unity-Claude-ParallelProcessor (Refactored v$ModuleVersion) - Modular parallel processing framework" -InformationAction Continue
# Added by Fix-ParallelProcessorExports
Export-ModuleMember -Function Get-UnityClaudeParallelProcessorInfo


# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDPqNtLROUPAwob
# Nxtksk16S8E5xyrny0mnrypPrrLEq6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIAHItOAylt+X16uFeSs8X1Qw
# IpqLetYaofYUymTH7X33MA0GCSqGSIb3DQEBAQUABIIBAAK218nZDITrdmbcpoxn
# ZxN0nUrT/cke8qziKhVvEQQYIJN+FExC9QHwzVMqDY9nUfJSXAleIIZPBLGHpcYx
# mVGyk/eUfdaxBAtq1DZw0PNWKHPYUYaLM8a0/a1easlkfvfalJD4/kjH6ne8GZ7z
# 45v2LfoT93wk/2QZ8jGNTaaeLRt+zQxx0bfK7SuJlCcF+nSfhsgfpMRf87+fvAuC
# VoGS/O0e3rxJoGjIEJbytKhM3X2IvQQ5nyNbUw/YqUONdOP01ParhpX4J9ak3+bq
# KIMv5wqmt1h4SDEIz5GknVzdOXb9zKXLsFpoEqVuiIawG4TvBz9lHfuunb2Xjb12
# 0Pg=
# SIG # End signature block
