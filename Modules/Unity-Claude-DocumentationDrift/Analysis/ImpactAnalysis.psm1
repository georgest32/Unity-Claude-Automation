# Unity-Claude-DocumentationDrift Impact Analysis Module
# Analyzes impact of code changes on documentation
# Created: 2025-08-25 (Refactored from large monolithic module)

#Requires -Version 7.2

function Analyze-ChangeImpact {
    <#
    .SYNOPSIS
    Analyzes the impact of code changes on documentation
    
    .DESCRIPTION
    Compares current code against previous version using AST analysis to determine
    the impact on documentation. Classifies changes as semantic vs formatting and
    provides impact severity assessment.
    
    .PARAMETER FilePath
    Path to the file that has changed
    
    .PARAMETER PreviousContent
    Previous content of the file for comparison (optional - will use Git if not provided)
    
    .PARAMETER ChangeType
    Type of change: Added, Modified, Deleted, Renamed
    
    .EXAMPLE
    Analyze-ChangeImpact -FilePath ".\Modules\MyModule\MyModule.psm1" -ChangeType Modified
    Analyzes impact of changes to MyModule.psm1
    
    .EXAMPLE
    Analyze-ChangeImpact -FilePath ".\Scripts\Deploy.ps1" -PreviousContent $oldContent -ChangeType Modified
    Analyzes impact with explicit previous content comparison
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [string]$PreviousContent,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet('Added', 'Modified', 'Deleted', 'Renamed')]
        [string]$ChangeType
    )
    
    Write-Verbose "[Analyze-ChangeImpact] Analyzing impact for file: $FilePath (Change: $ChangeType)"
    
    try {
        # Initialize impact analysis result
        $impactResult = @{
            FilePath = $FilePath
            ChangeType = $ChangeType
            Timestamp = Get-Date
            ImpactLevel = 'None'
            ChangeCategory = 'Unknown'
            AffectedFunctions = @()
            AffectedClasses = @()
            DocumentationImpact = @()
            Recommendations = @()
            Details = @{
                SemanticChanges = @()
                FormattingChanges = @()
                NewElements = @()
                RemovedElements = @()
                ModifiedElements = @()
                BreakingChanges = @()
            }
        }
        
        # Handle different change types
        switch ($ChangeType) {
            'Added' {
                Write-Verbose "[Analyze-ChangeImpact] Analyzing new file addition"
                $impactResult = Analyze-NewFileImpact -FilePath $FilePath -ImpactResult $impactResult
            }
            
            'Deleted' {
                Write-Verbose "[Analyze-ChangeImpact] Analyzing file deletion"
                $impactResult = Analyze-DeletedFileImpact -FilePath $FilePath -ImpactResult $impactResult
            }
            
            'Modified' {
                Write-Verbose "[Analyze-ChangeImpact] Analyzing file modifications"
                $impactResult = Analyze-ModifiedFileImpact -FilePath $FilePath -PreviousContent $PreviousContent -ImpactResult $impactResult
            }
            
            'Renamed' {
                Write-Verbose "[Analyze-ChangeImpact] Analyzing file rename"
                $impactResult = Analyze-RenamedFileImpact -FilePath $FilePath -ImpactResult $impactResult
            }
        }
        
        # Determine overall impact level based on analysis
        $impactResult.ImpactLevel = Determine-OverallImpactLevel -ImpactResult $impactResult
        
        # Generate recommendations based on impact
        $impactResult.Recommendations = Generate-ChangeRecommendations -ImpactResult $impactResult
        
        Write-Verbose "[Analyze-ChangeImpact] Impact analysis completed. Level: $($impactResult.ImpactLevel), Affected docs: $($impactResult.DocumentationImpact.Count)"
        
        return $impactResult
        
    } catch {
        Write-Error "[Analyze-ChangeImpact] Failed to analyze change impact for $($FilePath): $_"
        throw
    }
}

function Analyze-NewFileImpact {
    <#
    .SYNOPSIS
    Analyzes the impact of adding a new file
    
    .DESCRIPTION
    Determines what documentation needs to be created for a new file
    
    .PARAMETER FilePath
    Path to the new file
    
    .PARAMETER ImpactResult
    Base impact result to enhance
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$ImpactResult
    )
    
    Write-Verbose "[Analyze-NewFileImpact] Analyzing new file: $FilePath"
    
    $ImpactResult.ImpactLevel = 'Medium'
    $ImpactResult.ChangeCategory = 'Addition'
    
    # Analyze file type and content
    $extension = [System.IO.Path]::GetExtension($FilePath)
    
    switch ($extension.ToLower()) {
        '.ps1' {
            $ImpactResult.Recommendations += "Create documentation for new PowerShell script: $FilePath"
            $ImpactResult.ImpactLevel = 'Medium'
        }
        '.psm1' {
            $ImpactResult.Recommendations += "Create module documentation for: $FilePath"
            $ImpactResult.ImpactLevel = 'High'
        }
        '.cs' {
            $ImpactResult.Recommendations += "Create API documentation for new C# file: $FilePath"
            $ImpactResult.ImpactLevel = 'Medium'
        }
        default {
            $ImpactResult.Recommendations += "Review documentation needs for new file: $FilePath"
            $ImpactResult.ImpactLevel = 'Low'
        }
    }
    
    return $ImpactResult
}

function Analyze-DeletedFileImpact {
    <#
    .SYNOPSIS
    Analyzes the impact of deleting a file
    
    .DESCRIPTION
    Determines what documentation needs to be removed or updated when a file is deleted
    
    .PARAMETER FilePath
    Path to the deleted file
    
    .PARAMETER ImpactResult
    Base impact result to enhance
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$ImpactResult
    )
    
    Write-Verbose "[Analyze-DeletedFileImpact] Analyzing deleted file: $FilePath"
    
    $ImpactResult.ImpactLevel = 'High'
    $ImpactResult.ChangeCategory = 'Deletion'
    $ImpactResult.Recommendations += "Remove or update documentation references to deleted file: $FilePath"
    $ImpactResult.Details.BreakingChanges += @{
        Type = 'File Deletion'
        Description = "File $FilePath has been deleted"
        Impact = 'High'
    }
    
    return $ImpactResult
}

function Analyze-ModifiedFileImpact {
    <#
    .SYNOPSIS
    Analyzes the impact of modifying a file
    
    .DESCRIPTION
    Compares current and previous content to determine documentation impact
    
    .PARAMETER FilePath
    Path to the modified file
    
    .PARAMETER PreviousContent
    Previous content of the file
    
    .PARAMETER ImpactResult
    Base impact result to enhance
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [string]$PreviousContent,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$ImpactResult
    )
    
    Write-Verbose "[Analyze-ModifiedFileImpact] Analyzing modified file: $FilePath"
    
    try {
        if (-not $PreviousContent) {
            # Try to get previous content from Git
            try {
                $PreviousContent = git show HEAD:$FilePath 2>$null
            } catch {
                Write-Warning "[Analyze-ModifiedFileImpact] Could not retrieve previous content from Git"
                $PreviousContent = ""
            }
        }
        
        if (Test-Path $FilePath) {
            $currentContent = Get-Content $FilePath -Raw
            
            # Basic comparison for now - this could be enhanced with AST parsing
            $differences = Compare-Object ($PreviousContent -split "`n") ($currentContent -split "`n") -IncludeEqual
            
            $addedLines = ($differences | Where-Object SideIndicator -eq '=>').Count
            $removedLines = ($differences | Where-Object SideIndicator -eq '<=').Count
            $totalChanges = $addedLines + $removedLines
            
            if ($totalChanges -gt 50) {
                $ImpactResult.ImpactLevel = 'High'
            } elseif ($totalChanges -gt 10) {
                $ImpactResult.ImpactLevel = 'Medium'
            } else {
                $ImpactResult.ImpactLevel = 'Low'
            }
            
            $ImpactResult.ChangeCategory = 'Modification'
            $ImpactResult.Details.SemanticChanges += @{
                AddedLines = $addedLines
                RemovedLines = $removedLines
                TotalChanges = $totalChanges
            }
            
            $ImpactResult.Recommendations += "Review documentation for modified file: $FilePath ($totalChanges lines changed)"
            
        } else {
            Write-Warning "[Analyze-ModifiedFileImpact] File not found: $FilePath"
            $ImpactResult.ImpactLevel = 'High'
            $ImpactResult.Recommendations += "File $FilePath appears to be missing - check documentation impact"
        }
        
    } catch {
        Write-Error "[Analyze-ModifiedFileImpact] Error analyzing file modifications: $_"
        $ImpactResult.ImpactLevel = 'Medium'
        $ImpactResult.Recommendations += "Manual review required for file: $FilePath (analysis error)"
    }
    
    return $ImpactResult
}

function Analyze-RenamedFileImpact {
    <#
    .SYNOPSIS
    Analyzes the impact of renaming a file
    
    .DESCRIPTION
    Determines what documentation needs to be updated when a file is renamed
    
    .PARAMETER FilePath
    New path of the renamed file
    
    .PARAMETER ImpactResult
    Base impact result to enhance
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$ImpactResult
    )
    
    Write-Verbose "[Analyze-RenamedFileImpact] Analyzing renamed file: $FilePath"
    
    $ImpactResult.ImpactLevel = 'Medium'
    $ImpactResult.ChangeCategory = 'Rename'
    $ImpactResult.Recommendations += "Update documentation references to reflect renamed file: $FilePath"
    
    return $ImpactResult
}

function Determine-OverallImpactLevel {
    <#
    .SYNOPSIS
    Determines the overall impact level based on analysis results
    
    .PARAMETER ImpactResult
    Impact analysis result
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$ImpactResult
    )
    
    # Priority order: Critical > High > Medium > Low > None
    $levels = @('Critical', 'High', 'Medium', 'Low', 'None')
    
    $highestLevel = 'None'
    
    # Check breaking changes
    if ($ImpactResult.Details.BreakingChanges.Count -gt 0) {
        $highestLevel = 'Critical'
    }
    
    # Check current impact level
    $currentIndex = $levels.IndexOf($ImpactResult.ImpactLevel)
    $highestIndex = $levels.IndexOf($highestLevel)
    
    if ($currentIndex -lt $highestIndex) {
        $highestLevel = $ImpactResult.ImpactLevel
    }
    
    return $highestLevel
}

function Generate-ChangeRecommendations {
    <#
    .SYNOPSIS
    Generates recommendations based on impact analysis
    
    .PARAMETER ImpactResult
    Impact analysis result
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$ImpactResult
    )
    
    $recommendations = @()
    
    switch ($ImpactResult.ImpactLevel) {
        'Critical' {
            $recommendations += "URGENT: Critical documentation updates required immediately"
            $recommendations += "Create detailed migration guide for breaking changes"
        }
        'High' {
            $recommendations += "High priority documentation update needed"
            $recommendations += "Update API documentation and examples"
        }
        'Medium' {
            $recommendations += "Documentation review and update recommended"
            $recommendations += "Update relevant user guides"
        }
        'Low' {
            $recommendations += "Minor documentation updates may be needed"
        }
    }
    
    return $recommendations
}

# Export module members
Export-ModuleMember -Function @(
    'Analyze-ChangeImpact',
    'Analyze-NewFileImpact',
    'Analyze-DeletedFileImpact', 
    'Analyze-ModifiedFileImpact',
    'Analyze-RenamedFileImpact',
    'Determine-OverallImpactLevel',
    'Generate-ChangeRecommendations'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBSYU3u6jD23B+x
# N4YAwV5RGbmgnW2DFfcEdj6jH97p66CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIH28eokHJXI0N60Yo967hpGT
# c0us0vN9xAmMKqnLYGOoMA0GCSqGSIb3DQEBAQUABIIBAITiCXt8eBiWLEUjLVGD
# hnt1f2IHR0sHetpyTEKEeBPIuHK82dSYV5gOfBUk5esFyjn0fos16CywcNc7CXC6
# J3GC9X3HWcYRxIhToCiPCshDW1CpzUeNfzjYVUbRhX3n54J544V4keU5mZAm0CfR
# MeN3LNl5xt/M6gF+sP3LXB9U001XArs0AHeJBEQgoC74FxiJamFQymIiM0lK9oBJ
# FGpUkkXA0B6nBk3jILE2Oe24tOnqjOqaPM585Sr2SaNZuOEVhYctPsGydUMM8wL5
# tk1+OS+v8rUYVd2uKI81axNv+BLh1YZqlhqAMM0xZSlcnM/ZRVO2Vk5pOL3uTBLj
# yMo=
# SIG # End signature block
