# Unity-Claude-SemanticAnalysis-New.psm1
# Main Semantic Analysis Module - Refactored
# Imports and coordinates all semantic analysis sub-modules

#region Module Information
Write-Verbose "Unity-Claude-SemanticAnalysis module loading (refactored version)"
#endregion

#region Import CPG Dependencies
# Import required CPG module with classes and functions
$cpgModule = Join-Path $PSScriptRoot "Unity-Claude-CPG.psm1"
if (Test-Path $cpgModule) {
    Import-Module $cpgModule -Force -Global -Verbose:$false
    Write-Verbose "Imported Unity-Claude-CPG module successfully"
} else {
    throw "Unity-Claude-CPG module not found at: $cpgModule"
}

# Verify CPG classes are available
try {
    $testGraph = New-CPGraph -Name "TestGraph"
    Write-Verbose "CPG classes loaded successfully"
} catch {
    throw "CPG classes not available after module import: $($_.Exception.Message)"
}
#endregion

#region Import Sub-Modules
$moduleRoot = $PSScriptRoot

# Import helper functions first (required by all other modules)
$helpersModule = Join-Path $moduleRoot "Unity-Claude-SemanticAnalysis-Helpers.psm1"
if (Test-Path $helpersModule) {
    Import-Module $helpersModule -Force -Global -Verbose:$false
    Write-Verbose "Imported Helpers sub-module"
} else {
    throw "Helpers sub-module not found at: $helpersModule"
}

# Import pattern detection module
$patternsModule = Join-Path $moduleRoot "Unity-Claude-SemanticAnalysis-Patterns.psm1"
if (Test-Path $patternsModule) {
    Import-Module $patternsModule -Force -Verbose:$false
    Write-Verbose "Imported Patterns sub-module"
} else {
    Write-Warning "Patterns sub-module not found at: $patternsModule"
}

# Import purpose classification module
$purposeModule = Join-Path $moduleRoot "Unity-Claude-SemanticAnalysis-Purpose.psm1"
if (Test-Path $purposeModule) {
    Import-Module $purposeModule -Force -Verbose:$false
    Write-Verbose "Imported Purpose sub-module"
} else {
    Write-Warning "Purpose sub-module not found at: $purposeModule"
}

# Import metrics module
$metricsModule = Join-Path $moduleRoot "Unity-Claude-SemanticAnalysis-Metrics.psm1"
if (Test-Path $metricsModule) {
    Import-Module $metricsModule -Force -Verbose:$false
    Write-Verbose "Imported Metrics sub-module"
} else {
    Write-Warning "Metrics sub-module not found at: $metricsModule"
}

# Import business logic module
$businessModule = Join-Path $moduleRoot "Unity-Claude-SemanticAnalysis-Business.psm1"
if (Test-Path $businessModule) {
    Import-Module $businessModule -Force -Verbose:$false
    Write-Verbose "Imported Business sub-module"
} else {
    Write-Warning "Business sub-module not found at: $businessModule"
}

# Import quality analysis module
$qualityModule = Join-Path $moduleRoot "Unity-Claude-SemanticAnalysis-Quality.psm1"
if (Test-Path $qualityModule) {
    Import-Module $qualityModule -Force -Verbose:$false
    Write-Verbose "Imported Quality sub-module"
} else {
    Write-Warning "Quality sub-module not found at: $qualityModule"
}

# Import architecture recovery module
$archModule = Join-Path $moduleRoot "Unity-Claude-SemanticAnalysis-Architecture.psm1"
if (Test-Path $archModule) {
    Import-Module $archModule -Force -Verbose:$false
    Write-Verbose "Imported Architecture sub-module"
} else {
    Write-Warning "Architecture sub-module not found at: $archModule"
}

Write-Verbose "Unity-Claude-SemanticAnalysis module loaded successfully (refactored)"
#endregion

#region Helper Functions for Backward Compatibility

function ConvertTo-CPGFromScriptBlock {
    <#
    .SYNOPSIS
    Converts a ScriptBlock to a CPG graph (compatibility wrapper)
    
    .PARAMETER ScriptBlock
    The ScriptBlock to convert
    #>
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock
    )
    
    Write-Verbose "ConvertTo-CPGFromScriptBlock: Starting CPG conversion"
    
    try {
        # Use the CPG module's conversion function
        if (Get-Command Convert-ASTtoCPG -ErrorAction SilentlyContinue) {
            # Parse ScriptBlock to AST
            $ast = [System.Management.Automation.Language.Parser]::ParseInput(
                $ScriptBlock.ToString(), 
                [ref]$null, 
                [ref]$null
            )
            
            # Convert AST to CPG
            $graph = Convert-ASTtoCPG -AST $ast -FilePath "InMemory:$(Get-Date -Format 'yyyyMMdd_HHmmss')_$([System.Guid]::NewGuid().ToString('N').Substring(0,8)).ps1"
            
            Write-Verbose "  Successfully converted ScriptBlock to CPG"
            return $graph
        } else {
            throw "Convert-ASTtoCPG function not available"
        }
    } catch {
        Write-Error "ConvertTo-CPGFromScriptBlock failed: $($_.Exception.Message)"
        throw
    }
}

#endregion

#region Module Export

# Export all functions from sub-modules
Export-ModuleMember -Function @(
    # Pattern Detection
    'Find-DesignPatterns',
    'Find-SingletonPattern',
    'Find-FactoryPattern',
    'Find-ObserverPattern',
    'Find-StrategyPattern',
    'Find-CommandPattern',
    'Find-DecoratorPattern',
    
    # Purpose Classification
    'Get-CodePurpose',
    'Classify-CallablePurpose',
    'Classify-ClassPurpose',
    
    # Metrics and Cohesion
    'Get-CohesionMetrics',
    'Calculate-ModuleCohesion',
    'Calculate-SemanticCohesion',
    'Get-CohesionRecommendations',
    'Get-ComplexityMetrics',
    
    # Business Logic
    'Extract-BusinessLogic',
    'Find-ValidationRules',
    'Find-BusinessRules',
    'Find-WorkflowPatterns',
    'Find-DomainCalculations',
    
    # Quality Analysis
    'Test-DocumentationCompleteness',
    'Test-NamingConventions',
    'Test-CommentCodeAlignment',
    'Get-TechnicalDebt',
    'New-QualityReport',
    
    # Architecture Recovery
    'Recover-Architecture',
    'Identify-SystemLayers',
    'Analyze-ModuleDependencies',
    'Find-ArchitecturalPatterns',
    'Analyze-ComponentRelationships',
    
    # Helper Functions
    'Test-IsCPGraph',
    'Ensure-GraphDuckType',
    'Ensure-Array',
    'Normalize-AnalysisRecord',
    'Get-CacheKey',
    'ConvertTo-CPGFromScriptBlock'
) -Variable @(
    'UC_SA_Cache',
    'PatternThresholds',
    'ComplexityThresholds'
)

#endregion
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD1VTE8f2FP38ia
# VgpG9ouh2aYFDfjYgdug577qwJtGIqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEICMbpLrxXSzWO4ftQpCXC6Mc
# EWldZWBHHffTQtB9aLpcMA0GCSqGSIb3DQEBAQUABIIBAF0ZnReCL/QuLxZ0VUw5
# UbR+uLzhB5g9sOc+ZYCfzHZyKDUy6YJE2RZJpI3FNC7YJ2BDvqMwYnCZlAei7gdh
# X1PzaX7zI59opRVkXeVoaBpOnzfn7Xo4fMtq19baeVockv6Q0n1ZEY72aQEjj1mp
# yUmUwS31oq2YdkoobJz9VoR/7/Rf8ssiK444n9XkuKKh72a7huGJPFEukr/LRqTO
# X4fWGejrHWzJKQs+WcXJPqrb5Tf0ubwUhNgPWk7U413rkIzpEiidQF2zVXddU0m4
# MPqYpsp48Ly7Wx3+KrViO1iK6tqOH71YbdjMcMLeV3keQrWDdBnJAQbI4wFgZAvJ
# m8I=
# SIG # End signature block
