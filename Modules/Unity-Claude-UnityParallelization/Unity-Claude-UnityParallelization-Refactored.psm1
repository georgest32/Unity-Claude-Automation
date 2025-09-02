#Requires -Version 5.1
<#
.SYNOPSIS
    Unity-Claude-UnityParallelization orchestrator module (Refactored Version 2.0.0).

.DESCRIPTION
    Orchestrator module that coordinates refactored Unity parallelization components
    for concurrent Unity compilation monitoring and error detection.
    
    This is the refactored version that replaces the monolithic 2,084-line module
    with a modular architecture split into focused components.

.NOTES
    Module: Unity-Claude-UnityParallelization
    Version: 2.0.0
    Refactored: 2025-08-25
    Original Size: 2,084 lines
    New Architecture: 6 focused components (~100-600 lines each)
    
    Components:
    - ParallelizationCore.psm1 (~119 lines) - Core utilities and configuration
    - ProjectConfiguration.psm1 (~342 lines) - Unity project discovery and configuration
    - ParallelMonitoring.psm1 (~508 lines) - Parallel monitoring architecture
    - CompilationIntegration.psm1 (~117 lines) - Unity compilation process integration
    - ErrorDetection.psm1 (~580 lines) - Concurrent error detection and classification
    - ErrorExport.psm1 (~337 lines) - Concurrent error export and performance testing
#>

$ErrorActionPreference = "Stop"

# Component loading with debug support
if ($env:UNITYPARALLEL_DEBUG) {
    Write-Host "[DEBUG] Loading Unity-Claude-UnityParallelization-Refactored orchestrator..." -ForegroundColor Cyan
}

#region Import Core Components

$componentPath = Join-Path $PSScriptRoot "Core"

# Load components in dependency order
$components = @(
    @{Name = "ParallelizationCore"; Description = "Core utilities and configuration"}
    @{Name = "ProjectConfiguration"; Description = "Unity project discovery and configuration"}
    @{Name = "ParallelMonitoring"; Description = "Parallel monitoring architecture"}
    @{Name = "CompilationIntegration"; Description = "Unity compilation process integration"}
    @{Name = "ErrorDetection"; Description = "Concurrent error detection and classification"}
    @{Name = "ErrorExport"; Description = "Concurrent error export and performance testing"}
)

foreach ($component in $components) {
    $modulePath = Join-Path $componentPath "$($component.Name).psm1"
    
    if (Test-Path $modulePath) {
        try {
            Import-Module $modulePath -Force -Global
            
            if ($env:UNITYPARALLEL_DEBUG) {
                Write-Host "[DEBUG] Loaded component: $($component.Name) - $($component.Description)" -ForegroundColor Green
            }
        } catch {
            Write-Warning "Failed to load component $($component.Name): $($_.Exception.Message)"
            throw "Component loading failed for $($component.Name)"
        }
    } else {
        Write-Warning "Component not found: $($component.Name) at $modulePath"
    }
}

#endregion

#region Module Initialization

# Initialize module dependencies with safety check
if (Get-Command Initialize-ModuleDependencies -ErrorAction SilentlyContinue) {
    Initialize-ModuleDependencies
} else {
    Write-Verbose "[Unity-Claude-UnityParallelization] Module dependency initialization not available - continuing without it"
}

# Module version information
$script:ModuleInfo = @{
    Name = "Unity-Claude-UnityParallelization"
    Version = "2.0.0"
    RefactoredDate = "2025-08-25"
    Architecture = "Modular Component-Based"
    ComponentCount = $components.Count
    OriginalLines = 2084
    Status = "Refactored"
}

if ($env:UNITYPARALLEL_DEBUG) {
    Write-Host "[DEBUG] Unity-Claude-UnityParallelization Refactored Module Info:" -ForegroundColor Cyan
    $script:ModuleInfo.GetEnumerator() | ForEach-Object {
        Write-Host "  $($_.Key): $($_.Value)" -ForegroundColor Gray
    }
}

#endregion

#region Convenience Functions

function Get-UnityParallelizationModuleInfo {
    <#
    .SYNOPSIS
    Gets information about the Unity parallelization module
    .DESCRIPTION
    Returns module version and architecture information
    .EXAMPLE
    Get-UnityParallelizationModuleInfo
    #>
    [CmdletBinding()]
    param()
    
    return $script:ModuleInfo
}

function Show-UnityParallelizationFunctions {
    <#
    .SYNOPSIS
    Shows all available Unity parallelization functions
    .DESCRIPTION
    Lists all exported functions from the Unity parallelization module
    .EXAMPLE
    Show-UnityParallelizationFunctions
    #>
    [CmdletBinding()]
    param()
    
    $functions = Get-Command -Module Unity-Claude-UnityParallelization
    
    Write-Host "`nUnity-Claude-UnityParallelization Functions ($($functions.Count) total):" -ForegroundColor Cyan
    Write-Host "=" * 60 -ForegroundColor Cyan
    
    # Group by category
    $categories = @{
        "Project Management" = @("Find-UnityProjects", "Register-UnityProject", "Get-RegisteredUnityProjects", 
                                "Get-UnityProjectConfiguration", "Set-UnityProjectConfiguration", "Test-UnityProjectAvailability")
        "Monitoring" = @("New-UnityParallelMonitor", "Start-UnityParallelMonitoring", "Stop-UnityParallelMonitoring", 
                        "Get-UnityMonitoringStatus")
        "Compilation" = @("Start-UnityCompilationJob", "Find-UnityExecutablePath", "Test-UnityCompilationResult")
        "Error Detection" = @("Start-ConcurrentErrorDetection", "Classify-UnityCompilationError", "Aggregate-UnityErrors", 
                             "Deduplicate-UnityErrors", "Get-UnityErrorStatistics")
        "Error Export" = @("Export-UnityErrorsConcurrently", "Format-UnityErrorsForClaude")
        "Performance" = @("Test-UnityParallelizationPerformance")
        "Core" = @("Get-UnityParallelizationConfig", "Set-UnityParallelizationConfig", "Write-UnityParallelLog")
    }
    
    foreach ($category in $categories.Keys | Sort-Object) {
        Write-Host "`n${category}:" -ForegroundColor Yellow
        $categoryFunctions = $functions | Where-Object { $_.Name -in $categories[$category] }
        foreach ($func in $categoryFunctions | Sort-Object Name) {
            Write-Host "  - $($func.Name)" -ForegroundColor White
        }
    }
    
    Write-Host "`n" -ForegroundColor Cyan
}

#endregion

#region Export All Component Functions

# Export all functions from loaded components
# This maintains the same public API as the monolithic version

Export-ModuleMember -Function @(
    # Core utilities (from ParallelizationCore)
    'Get-UnityParallelizationConfig',
    'Set-UnityParallelizationConfig',
    'Write-UnityParallelLog',
    
    # Unity Project Discovery and Configuration (from ProjectConfiguration)
    'Find-UnityProjects',
    'Register-UnityProject',
    'Get-RegisteredUnityProjects',
    'Get-UnityProjectConfiguration',
    'Set-UnityProjectConfiguration',
    'Test-UnityProjectAvailability',
    
    # Parallel Unity Monitoring Architecture (from ParallelMonitoring)
    'New-UnityParallelMonitor',
    'Start-UnityParallelMonitoring',
    'Stop-UnityParallelMonitoring',
    'Get-UnityMonitoringStatus',
    'Submit-RunspaceJob',
    'Wait-RunspaceJobs',
    'Get-RunspaceJobResults',
    
    # Unity Compilation Process Integration (from CompilationIntegration)
    'Start-UnityCompilationJob',
    'Find-UnityExecutablePath',
    'Test-UnityCompilationResult',
    
    # Concurrent Error Detection and Classification (from ErrorDetection)
    'Start-ConcurrentErrorDetection',
    'Classify-UnityCompilationError',
    'Aggregate-UnityErrors',
    'Deduplicate-UnityErrors',
    'Get-UnityErrorStatistics',
    
    # Concurrent Error Export and Integration (from ErrorExport)
    'Export-UnityErrorsConcurrently',
    'Format-UnityErrorsForClaude',
    'Test-UnityParallelizationPerformance',
    
    # Orchestrator functions
    'Get-UnityParallelizationModuleInfo',
    'Show-UnityParallelizationFunctions'
)

#endregion

# Module loading complete notification
if (Get-Command Write-UnityParallelLog -ErrorAction SilentlyContinue) {
    Write-UnityParallelLog -Message "Unity-Claude-UnityParallelization (v2.0.0 Refactored) loaded with $($components.Count) components" -Level "INFO"
} else {
    Write-Verbose "[Unity-Claude-UnityParallelization] v2.0.0 Refactored loaded with $($components.Count) components"
}

if ($env:UNITYPARALLEL_DEBUG) {
    Write-Host "[DEBUG] Unity-Claude-UnityParallelization orchestrator loaded successfully" -ForegroundColor Green
    Write-Host "[DEBUG] Use Show-UnityParallelizationFunctions to see all available functions" -ForegroundColor Gray
}

# REFACTORING COMPLETE: Unity-Claude-UnityParallelization module
# Refactored from 2,084 lines to 6 focused components plus orchestrator
# Date: 2025-08-25

# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD79vgY9FlOLgiN
# gq9rT8mcTfZE7QefhdsYv4jsl7TOJ6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIK9yNPARBHDxJspWtD0RG/sc
# AYL/jk86NHoQhE6mixSQMA0GCSqGSIb3DQEBAQUABIIBAAv2O2KXEwX7JwPcGHYm
# 7HAJSzINjJLAR2cryBD4Es8v8qkNZcFoVuNlA9gl17wYSxhnSUs7tKigVO418ERL
# RRf9v7Qq/drk7LAIlPAHAexbk8uvryoPgOoknuYByoNajWyIMsUxr4oHsENcrqB7
# iuRiAx232xybRI6yAkbqhTs9KeygsozpzJ7BHENyQPa9Omd5O++jqwf99R4DvGwO
# WPykEItRtgKH13nqOOWi7U4WwwWYxKurD/I5P9UeqqxDbf4TkdweFnpSrOaafWzP
# kIG6WHY1NjwelBxg9RdB0XXHKOdgKXe6Z9jaUS5z3yS/jDIzdjSOWQZ1QG1+cFo4
# lDw=
# SIG # End signature block
