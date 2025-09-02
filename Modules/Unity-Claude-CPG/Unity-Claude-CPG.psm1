#Requires -Version 5.1
<#
.SYNOPSIS
    Code Property Graph (CPG) module for relationship mapping and code analysis.
    
.DESCRIPTION  
    REFACTORED VERSION: This module has been refactored into modular components
    for better maintainability and organization.
    
    Implements a Code Property Graph structure that merges AST, CFG, and PDG
    for comprehensive code analysis, relationship mapping, and obsolescence detection.
    Based on Joern architecture with PowerShell-specific optimizations.

.NOTES
    Version: 1.1.0 (Refactored)
    Author: Unity-Claude Automation System
    Date: 2025-08-25
    
    REFACTORING MARKER: This module was refactored on 2025-08-25
    Original file size: 1013 lines
    New architecture: 6 focused components in Core/ subdirectory
    
    Component Structure:
    - CPG-DataStructures.psm1: Core classes and enums
    - CPG-BasicOperations.psm1: Node/edge/graph creation
    - CPG-QueryOperations.psm1: Search and traversal
    - CPG-AnalysisOperations.psm1: Statistics and metrics  
    - CPG-SerializationOperations.psm1: Import/export
    - Plus AST conversion from existing Unity-Claude-CPG-ASTConverter.psm1
#>

# === REFACTORING DEBUG LOG ===
Write-Host "✅ LOADING REFACTORED VERSION: Unity-Claude-CPG-Refactored.psm1 with 6 modular components" -ForegroundColor Green
Write-Host "📦 Components: DataStructures, BasicOperations, QueryOperations, AnalysisOperations, SerializationOperations + ASTConverter" -ForegroundColor Cyan

# Import all component modules
$CorePath = Join-Path $PSScriptRoot "Core"

# Import data structures first (required by other components)
$dataStructuresPath = Join-Path $CorePath "CPG-DataStructures.psm1"
if (Test-Path $dataStructuresPath) {
    Import-Module $dataStructuresPath -Force -Global
} else {
    Write-Error "Core component CPG-DataStructures.psm1 not found at: $dataStructuresPath"
}

# Import all other components
$components = @(
    "CPG-BasicOperations.psm1",
    "CPG-QueryOperations.psm1", 
    "CPG-AnalysisOperations.psm1",
    "CPG-SerializationOperations.psm1"
)

foreach ($component in $components) {
    $componentPath = Join-Path $CorePath $component
    if (Test-Path $componentPath) {
        Import-Module $componentPath -Force -Global
        Write-Verbose "Imported CPG component: $component"
    } else {
        Write-Error "Core component $component not found at: $componentPath"
    }
}

# Import AST converter (existing functionality)
$astConverterPath = Join-Path $PSScriptRoot "Unity-Claude-CPG-ASTConverter.psm1"
if (Test-Path $astConverterPath) {
    Import-Module $astConverterPath -Force -Global
    Write-Verbose "Imported AST converter component"
} else {
    Write-Warning "AST converter not found at: $astConverterPath"
}

# Add the ConvertTo-CPGFromScriptBlock function (preserved from original)
function ConvertTo-CPGFromScriptBlock {
    <#
    .SYNOPSIS
    Converts a PowerShell ScriptBlock to CPG format for analysis.
    
    .DESCRIPTION
    Parses a PowerShell ScriptBlock into an AST and converts it to CPG format for analysis.
    Provides a synthetic file path for in-memory code snippets.
    
    .PARAMETER ScriptBlock
    The PowerShell ScriptBlock to convert
    
    .PARAMETER GraphName
    Name for the generated graph (optional)
    
    .PARAMETER IncludeDataFlow
    Include data flow edges in the graph
    
    .PARAMETER IncludeControlFlow
    Include control flow edges in the graph
    
    .PARAMETER PseudoPath
    Optional friendly pseudo path for the root file node
    
    .EXAMPLE
    $graph = ConvertTo-CPGFromScriptBlock -ScriptBlock { function Test { Write-Host "Hello" } }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock] $ScriptBlock,

        [string] $GraphName,
        [switch] $IncludeDataFlow,
        [switch] $IncludeControlFlow,

        # Optional friendly pseudo path for the root file node
        [string] $PseudoPath
    )

    # Parse the ScriptBlock to an AST
    $tokens = $null            # ✅ declare a real variable for tokens
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput(
        $ScriptBlock.ToString(),
        [ref]$tokens,           # ✅ pass a ref to a variable
        [ref]$parseErrors
    )

    if ($parseErrors -and $parseErrors.Count -gt 0) {
        throw ("ScriptBlock parse failed:`n" + ($parseErrors | ForEach-Object { $_.Message } | Out-String))
    }
    if (-not $ast) { throw "Parser returned null AST." }

    if (-not $PseudoPath) {
        $timestamp = (Get-Date).ToString('yyyyMMdd_HHmmss_ffff')
        $PseudoPath = "InMemory:$timestamp.ps1"
    }

    Write-Verbose "[CPG] Parsed scriptblock to AST; PseudoPath='$PseudoPath'"

    # Invoke the converter function directly (now available through nested module)
    $graph = Convert-ASTtoCPG `
        -AST $ast `
        -FilePath $PseudoPath `
        -GraphName $GraphName `
        -IncludeDataFlow:$IncludeDataFlow `
        -IncludeControlFlow:$IncludeControlFlow
    
    if (-not $graph) { throw "Convert-ASTtoCPG returned null graph." }
    return $graph
}

# Export all public functions from components
Export-ModuleMember -Function @(
    # Core graph API (from BasicOperations)
    'New-CPGraph','New-CPGNode','Add-CPGNode','New-CPGEdge','Add-CPGEdge',
    
    # Query operations
    'Get-CPGNode','Get-CPGEdge','Get-CPGNeighbors','Find-CPGPath',
    
    # Analysis operations  
    'Get-CPGStatistics','Test-CPGStronglyConnected','Get-CPGComplexityMetrics','Find-CPGCycles',
    
    # Serialization operations
    'Export-CPGraph','Import-CPGraph',

    # AST conversion operations
    'Convert-ASTtoCPG','ConvertTo-CPGFromFile','ConvertTo-CPGFromScriptBlock'
)

Write-Verbose "Unity-Claude-CPG refactored module loaded successfully"
Write-Verbose "Components: DataStructures, BasicOperations, QueryOperations, AnalysisOperations, SerializationOperations, ASTConverter"

# REFACTORING MARKER: This module was refactored from Unity-Claude-CPG.psm1 on 2025-08-25
# Original monolithic file: 1013 lines
# New modular architecture: 6 focused components + main orchestrator
# Maintainability improvement: ~85% reduction in file complexity per component
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDJVEHAJ9mVjTFm
# C7VV/ngr0pfDiznifkseVuv1VOB/9KCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIEhtukY6mwaiXbF/qlocDNOB
# 3gKuPhjv7MX5odQyF6X5MA0GCSqGSIb3DQEBAQUABIIBAFhoTjVLuESOoORQgk8g
# EADDK/wvAXEQfFaedEpj8o5PJ2n6qa817rKHpUhphcfi8fLpnJ3AJiN+3SwGMuDd
# OvrekS+xQzCDdbSVmD8XEoBCoPFenvoiPw1KzJzzcFa7kV+kMqAghbaWPUMgdR87
# /vztYzCzX9ksKjVKXOfl1c+ggE8I4YCnd9gt/2XwLpPQRwgtVzokc70Z8v1kajID
# 5mEcT2G1/TjcVkq3JyDfSS6egAN0zOVEz+3rdGQZiY7VjzeeEP+TtTvSsN9UJ0he
# S9n8JY+h/cizoPivQ39H4x5upntyozuiY6Yo6c36r1n4m/GOgiSTdEjt4J7mEpOc
# 3NA=
# SIG # End signature block
