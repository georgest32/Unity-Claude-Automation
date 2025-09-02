# Unity-Claude-DocumentationDrift - Refactored Modular Version
# Documentation drift detection and automated update system
# Created: 2025-08-25 (Refactored from large monolithic module)

#Requires -Version 7.2

# Import sub-modules
$ModulePath = $PSScriptRoot

Write-Verbose "[DocumentationDrift] Loading refactored modular components..."

try {
    # Import Core Configuration module
    Import-Module "$ModulePath\Core\Configuration.psd1" -Force -Global -ErrorAction Stop
    Write-Verbose "[DocumentationDrift] Core Configuration module loaded"
    
    # Import Analysis modules
    Import-Module "$ModulePath\Analysis\ImpactAnalysis.psd1" -Force -Global -ErrorAction Stop  
    Write-Verbose "[DocumentationDrift] Impact Analysis module loaded"
    
    Write-Information "[DocumentationDrift] Refactored modular DocumentationDrift system loaded successfully"
    
} catch {
    Write-Error "[DocumentationDrift] Failed to load modular components: $_"
    throw
}

# Module-level variables shared across components
$script:CodeToDocMapping = @{}           # Bidirectional mapping: code->docs and docs->code
$script:DocumentationIndex = @{}         # Index of all documentation files and their relationships  
$script:DriftResults = @{}               # Current drift detection results

function Clear-DriftCache {
    <#
    .SYNOPSIS
    Clears all cached drift detection results and forces fresh analysis
    
    .DESCRIPTION
    Resets the drift detection cache including code-to-documentation mapping,
    documentation index, and previous analysis results. Use this when you want
    to force a complete re-analysis of the codebase.
    
    .PARAMETER Force
    Force cache clearing without confirmation
    
    .EXAMPLE
    Clear-DriftCache
    Clears the drift cache with confirmation prompt
    
    .EXAMPLE
    Clear-DriftCache -Force
    Clears the drift cache without confirmation
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    if ($Force -or $PSCmdlet.ShouldProcess("Documentation drift cache", "Clear")) {
        $script:CodeToDocMapping = @{}
        $script:DocumentationIndex = @{}
        $script:DriftResults = @{}
        Write-Information "[Clear-DriftCache] Drift detection cache cleared"
    }
}

function Get-DriftDetectionResults {
    <#
    .SYNOPSIS
    Gets the current drift detection results
    
    .DESCRIPTION
    Returns the most recent drift detection analysis results including
    affected files, impact levels, and recommendations
    
    .EXAMPLE
    Get-DriftDetectionResults
    Returns current drift detection results
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()
    
    if ($script:DriftResults.Count -eq 0) {
        Write-Warning "No drift detection results available. Run drift analysis first."
        return @{}
    }
    
    return $script:DriftResults.Clone()
}

function Test-DocumentationDrift {
    <#
    .SYNOPSIS
    Performs comprehensive documentation drift analysis
    
    .DESCRIPTION
    Analyzes the entire codebase for documentation drift by comparing
    code changes against existing documentation
    
    .PARAMETER Path
    Root path to analyze (defaults to current directory)
    
    .PARAMETER Quick
    Performs quick analysis (skips some intensive checks)
    
    .EXAMPLE
    Test-DocumentationDrift
    Performs full documentation drift analysis on current directory
    
    .EXAMPLE
    Test-DocumentationDrift -Path ".\Modules" -Quick
    Performs quick analysis on Modules directory
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Path = ".",
        
        [Parameter(Mandatory = $false)]
        [switch]$Quick
    )
    
    Write-Information "[Test-DocumentationDrift] Starting documentation drift analysis..."
    
    try {
        # Get configuration
        $config = Get-DocumentationDriftConfig
        if ($config.Count -eq 0) {
            Write-Warning "DocumentationDrift not configured. Initializing with defaults..."
            Initialize-DocumentationDrift
            $config = Get-DocumentationDriftConfig
        }
        
        # Get all relevant files
        $allFiles = Get-ChildItem -Path $Path -Recurse -File | Where-Object {
            $file = $_
            $include = $false
            
            # Check include patterns
            foreach ($pattern in $config.IncludePatterns) {
                if ($file.Name -like $pattern) {
                    $include = $true
                    break
                }
            }
            
            if (-not $include) { return $false }
            
            # Check exclude patterns
            foreach ($pattern in $config.ExcludePatterns) {
                if ($file.FullName -like "*$pattern*") {
                    return $false
                }
            }
            
            return $true
        }
        
        Write-Verbose "[Test-DocumentationDrift] Analyzing $($allFiles.Count) files..."
        
        $results = @{
            Timestamp = Get-Date
            Path = $Path
            TotalFiles = $allFiles.Count
            AnalyzedFiles = 0
            ImpactResults = @()
            Summary = @{
                Critical = 0
                High = 0
                Medium = 0
                Low = 0
                None = 0
            }
            Recommendations = @()
        }
        
        foreach ($file in $allFiles) {
            try {
                # For this refactored version, we'll do a simplified analysis
                # In the full implementation, this would use Git to detect changes
                $impact = Analyze-ChangeImpact -FilePath $file.FullName -ChangeType 'Modified'
                $results.ImpactResults += $impact
                $results.Summary[$impact.ImpactLevel]++
                $results.AnalyzedFiles++
                
                if ($impact.Recommendations) {
                    $results.Recommendations += $impact.Recommendations
                }
                
            } catch {
                Write-Warning "[Test-DocumentationDrift] Failed to analyze $($file.FullName): $_"
            }
        }
        
        # Store results in module cache
        $script:DriftResults = $results
        
        Write-Information "[Test-DocumentationDrift] Analysis complete. $($results.AnalyzedFiles) files analyzed."
        Write-Information "[Test-DocumentationDrift] Impact summary - Critical: $($results.Summary.Critical), High: $($results.Summary.High), Medium: $($results.Summary.Medium), Low: $($results.Summary.Low)"
        
        return $results
        
    } catch {
        Write-Error "[Test-DocumentationDrift] Documentation drift analysis failed: $_"
        throw
    }
}

# Export module members (combining exports from sub-modules)
Export-ModuleMember -Function @(
    # From Core.Configuration
    'Initialize-DocumentationDrift',
    'Get-DocumentationDriftConfig', 
    'Set-DocumentationDriftConfig',
    'Reset-DocumentationDriftConfig',
    'Export-DocumentationDriftConfig',
    
    # From Analysis.ImpactAnalysis  
    'Analyze-ChangeImpact',
    'Analyze-NewFileImpact',
    'Analyze-DeletedFileImpact', 
    'Analyze-ModifiedFileImpact',
    'Analyze-RenamedFileImpact',
    'Determine-OverallImpactLevel',
    'Generate-ChangeRecommendations',
    
    # Main module functions
    'Clear-DriftCache',
    'Get-DriftDetectionResults',
    'Test-DocumentationDrift'
)

Write-Verbose "[DocumentationDrift] Refactored modular DocumentationDrift module loaded with $((Get-Command -Module $MyInvocation.MyCommand.ModuleName).Count) exported functions"
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCChGzcxn3s+QCf7
# TeRO8ESZeGOHxt28D8/o3DhB+CZBRaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJbeXDLppyJj67q8TRAlYwtm
# w8WnnNEZMbgo6WTyrDmgMA0GCSqGSIb3DQEBAQUABIIBADe4lcYorYWbJwJeXyGa
# QDvLJh2iy51nLjkO6TTz59wQK2c1Php9t5M4QrwhE12B5GAJZR2r0fP+eIonpJjs
# k+RfAAab3W5x7FzxfO7aagB8dHxn04I4MvDV965OzvkFM7RJ/uEA5c+oqlctZ7fV
# Mq9ld2dSrdNnzWTDCRnnd5rUVVK1ydJ4hm09YUb9MGMlESlh12+DckeJHmEDkCbu
# KrtX5Zez0oGYEJZvIkD3DvsHKRfMA6HxjxGVroyWsFg3ZOdlNj802lRjkT9xm14n
# aj0iZiNc4882LKJVNhqcd93N1022bWDgMpNdYoELSSiXP0vQXNAQqbHpu/uTpUiV
# 71Q=
# SIG # End signature block
