#
# Unity-Claude-DocumentationPipeline.psm1
# Integrated documentation generation pipeline combining semantic analysis with LLM enhancement
#

# Import required modules
Import-Module "$PSScriptRoot\..\Unity-Claude-CPG\Unity-Claude-CPG.psd1" -Force -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\..\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis.psd1" -Force -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\Unity-Claude-LLM.psd1" -Force

function New-EnhancedDocumentationPipeline {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$SourcePath,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        
        [ValidateSet('PowerShell', 'Python', 'CSharp', 'TypeScript')]
        [string]$Language = 'PowerShell',
        
        [ValidateSet('Function', 'Module', 'Class', 'Script', 'API', 'Architecture')]
        [string]$DocumentationType = 'Module',
        
        [switch]$IncludeSemanticAnalysis,
        [switch]$IncludeCodeAnalysis,
        [switch]$IncludeArchitectureInfo,
        [switch]$GenerateIndex
    )
    
    $pipeline = @{
        StartTime = Get-Date
        SourcePath = $SourcePath
        OutputPath = $OutputPath
        Language = $Language
        DocumentationType = $DocumentationType
        Steps = @()
        Results = @{}
        Errors = @()
        Success = $true
    }
    
    try {
        # Step 1: Verify source exists
        $pipeline.Steps += "VerifySource"
        if (-not (Test-Path $SourcePath)) {
            throw "Source path not found: $SourcePath"
        }
        
        # Step 2: Create output directory
        $pipeline.Steps += "CreateOutput"
        $outputDir = Split-Path $OutputPath -Parent
        if (-not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        # Step 3: Read source code
        $pipeline.Steps += "ReadSource"
        $sourceCode = Get-Content $SourcePath -Raw
        $pipeline.Results.SourceCode = $sourceCode
        
        # Step 4: Semantic Analysis (if requested)
        if ($IncludeSemanticAnalysis) {
            $pipeline.Steps += "SemanticAnalysis"
            $semanticResults = Invoke-SemanticAnalysisPipeline -Code $sourceCode
            $pipeline.Results.SemanticAnalysis = $semanticResults
        }
        
        # Step 5: Code Analysis (if requested)
        if ($IncludeCodeAnalysis) {
            $pipeline.Steps += "CodeAnalysis"
            $analysisResults = Invoke-CodeAnalysis -FilePath $SourcePath -AnalysisTypes @('Quality', 'Security', 'Performance')
            $pipeline.Results.CodeAnalysis = $analysisResults
        }
        
        # Step 6: Architecture Analysis (if requested)
        if ($IncludeArchitectureInfo) {
            $pipeline.Steps += "ArchitectureAnalysis"
            $archResults = Invoke-ArchitectureAnalysis -Code $sourceCode
            $pipeline.Results.ArchitectureAnalysis = $archResults
        }
        
        # Step 7: Generate enhanced documentation
        $pipeline.Steps += "GenerateDocumentation"
        $context = Build-DocumentationContext -Pipeline $pipeline
        $documentation = Invoke-DocumentationGeneration -FilePath $SourcePath -Type $DocumentationType -Context $context -OutputPath $OutputPath
        $pipeline.Results.Documentation = $documentation
        
        # Step 8: Generate index (if requested)
        if ($GenerateIndex) {
            $pipeline.Steps += "GenerateIndex"
            $indexPath = Join-Path (Split-Path $OutputPath -Parent) "index.md"
            $indexContent = New-DocumentationIndex -Pipeline $pipeline
            $indexContent | Out-File -FilePath $indexPath -Encoding UTF8
            $pipeline.Results.IndexPath = $indexPath
        }
        
        $pipeline.EndTime = Get-Date
        $pipeline.Duration = $pipeline.EndTime - $pipeline.StartTime
        
        Write-Host "Documentation pipeline completed successfully!" -ForegroundColor Green
        Write-Host "Output: $OutputPath" -ForegroundColor Gray
        Write-Host "Duration: $($pipeline.Duration.TotalSeconds) seconds" -ForegroundColor Gray
        
        return $pipeline
    }
    catch {
        $pipeline.Success = $false
        $pipeline.Errors += $_.Exception.Message
        $pipeline.EndTime = Get-Date
        Write-Error "Documentation pipeline failed: $($_.Exception.Message)"
        return $pipeline
    }
}

function Invoke-SemanticAnalysisPipeline {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Code
    )
    
    try {
        # Create CPG from code
        $scriptBlock = [ScriptBlock]::Create($Code)
        $graph = ConvertTo-CPGFromScriptBlock -ScriptBlock $scriptBlock
        
        if (-not $graph) {
            Write-Warning "Failed to create CPG from code"
            return $null
        }
        
        # Run semantic analysis
        $results = @{
            Patterns = Find-DesignPatterns -Graph $graph
            Purpose = Get-CodePurpose -Graph $graph
            Cohesion = Get-CohesionMetrics -Graph $graph
            BusinessLogic = Extract-BusinessLogic -Graph $graph
            Complexity = Get-ComplexityMetrics -Graph $graph
            NodeCount = $graph.Nodes.Count
        }
        
        return $results
    }
    catch {
        Write-Warning "Semantic analysis failed: $($_.Exception.Message)"
        return $null
    }
}

function Invoke-ArchitectureAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Code
    )
    
    try {
        # Basic architecture analysis
        $functions = [regex]::Matches($Code, 'function\s+([a-zA-Z-]+)') | ForEach-Object { $_.Groups[1].Value }
        $classes = [regex]::Matches($Code, 'class\s+([a-zA-Z]+)') | ForEach-Object { $_.Groups[1].Value }
        $imports = [regex]::Matches($Code, 'Import-Module\s+[''"]([^''"]+)[''"]') | ForEach-Object { $_.Groups[1].Value }
        
        return @{
            Functions = $functions
            Classes = $classes
            Dependencies = $imports
            Architecture = if ($classes.Count -gt 0) { 'Object-Oriented' } elseif ($functions.Count -gt 5) { 'Functional' } else { 'Procedural' }
            Complexity = if ($functions.Count -gt 20) { 'High' } elseif ($functions.Count -gt 5) { 'Medium' } else { 'Low' }
        }
    }
    catch {
        Write-Warning "Architecture analysis failed: $($_.Exception.Message)"
        return $null
    }
}

function Build-DocumentationContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Pipeline
    )
    
    $context = @()
    
    if ($Pipeline.Results.SemanticAnalysis) {
        $semantic = $Pipeline.Results.SemanticAnalysis
        $context += "SEMANTIC ANALYSIS FINDINGS:"
        
        if ($semantic.Patterns -and $semantic.Patterns.Count -gt 0) {
            $context += "Design Patterns Detected: $($semantic.Patterns | ForEach-Object { $_.Type } | Join-String ', ')"
        }
        
        if ($semantic.Purpose -and $semantic.Purpose.Count -gt 0) {
            $purposes = $semantic.Purpose | ForEach-Object { $_.Purpose } | Select-Object -Unique
            $context += "Code Purposes: $($purposes -join ', ')"
        }
        
        if ($semantic.BusinessLogic -and $semantic.BusinessLogic.Count -gt 0) {
            $context += "Business Logic Components: $($semantic.BusinessLogic.Count) identified"
        }
        
        $context += ""
    }
    
    if ($Pipeline.Results.ArchitectureAnalysis) {
        $arch = $Pipeline.Results.ArchitectureAnalysis
        $context += "ARCHITECTURE ANALYSIS:"
        $context += "Architecture Style: $($arch.Architecture)"
        $context += "Complexity Level: $($arch.Complexity)"
        $context += "Functions Count: $($arch.Functions.Count)"
        $context += "Classes Count: $($arch.Classes.Count)"
        $context += ""
    }
    
    if ($Pipeline.Results.CodeAnalysis) {
        $context += "CODE ANALYSIS AVAILABLE: Quality, Security, and Performance analyses have been conducted."
        $context += ""
    }
    
    return $context -join "`n"
}

function New-DocumentationIndex {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Pipeline
    )
    
    $content = @()
    $content += "# Documentation Index"
    $content += ""
    $content += "Generated: $($Pipeline.EndTime.ToString('yyyy-MM-dd HH:mm:ss'))"
    $content += "Duration: $($Pipeline.Duration.TotalSeconds) seconds"
    $content += ""
    
    # Source information
    $content += "## Source Information"
    $content += "- **File**: $($Pipeline.SourcePath)"
    $content += "- **Language**: $($Pipeline.Language)"
    $content += "- **Type**: $($Pipeline.DocumentationType)"
    $content += ""
    
    # Analysis results
    if ($Pipeline.Results.SemanticAnalysis) {
        $semantic = $Pipeline.Results.SemanticAnalysis
        $content += "## Semantic Analysis Summary"
        $content += "- **Nodes Analyzed**: $($semantic.NodeCount)"
        $content += "- **Design Patterns**: $($semantic.Patterns.Count) detected"
        $content += "- **Purpose Classifications**: $($semantic.Purpose.Count) identified"
        $content += "- **Business Logic Components**: $($semantic.BusinessLogic.Count) found"
        $content += ""
    }
    
    if ($Pipeline.Results.ArchitectureAnalysis) {
        $arch = $Pipeline.Results.ArchitectureAnalysis
        $content += "## Architecture Summary"
        $content += "- **Style**: $($arch.Architecture)"
        $content += "- **Complexity**: $($arch.Complexity)"
        $content += "- **Functions**: $($arch.Functions.Count)"
        $content += "- **Classes**: $($arch.Classes.Count)"
        $content += ""
    }
    
    # Documentation link
    $docFile = Split-Path $Pipeline.OutputPath -Leaf
    $content += "## Generated Documentation"
    $content += "- [Main Documentation](./$docFile)"
    $content += ""
    
    # Processing steps
    $content += "## Processing Steps"
    foreach ($step in $Pipeline.Steps) {
        $content += "- ✓ $step"
    }
    
    if ($Pipeline.Errors.Count -gt 0) {
        $content += ""
        $content += "## Errors"
        foreach ($error in $Pipeline.Errors) {
            $content += "- ⚠️ $error"
        }
    }
    
    return $content -join "`n"
}

function Get-ComplexityMetrics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        $Graph
    )
    
    try {
        $nodes = Get-CPGNode -Graph $Graph
        $functions = $nodes | Where-Object { $_.Type -eq [CPGNodeType]::Function }
        
        return @{
            TotalNodes = $nodes.Count
            FunctionCount = $functions.Count
            AverageDepth = if ($nodes.Count -gt 0) { ($nodes | ForEach-Object { $_.Depth } | Measure-Object -Average).Average } else { 0 }
            ComplexityScore = [Math]::Min([Math]::Max($nodes.Count / 10, 1), 10)
        }
    }
    catch {
        Write-Warning "Complexity metrics calculation failed: $($_.Exception.Message)"
        return @{
            TotalNodes = 0
            FunctionCount = 0
            AverageDepth = 0
            ComplexityScore = 1
        }
    }
}

# Export functions
Export-ModuleMember -Function @(
    'New-EnhancedDocumentationPipeline',
    'Invoke-SemanticAnalysisPipeline',
    'Invoke-ArchitectureAnalysis',
    'Build-DocumentationContext',
    'New-DocumentationIndex',
    'Get-ComplexityMetrics'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA2evJCwXtaTi0c
# K/ArnY9ki/AIAidJbRI9YsG4ReiCzKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIKJRka6qHHhMuUgpvWn3FG6S
# H6oES1e50vJeD5q9cv9HMA0GCSqGSIb3DQEBAQUABIIBALGSjCVJNPZ4hyoMn8Sx
# KOGbroyxm/MW78V3Df82HtAlJ7iFjNQwSJXfNmNko4SH8cZHoHym8kqztnT98urY
# 8zFtNiApdowt6S0slDINaAjXVB/hCjjqm2Ya40TKX1OmwrmyvhtzNqlGDY2yg1IL
# xduWGOopBMA4uur5XPe3KAQyn75GDd7N72PYF41DKk5IUo3sfICgRtMm0nS3raNj
# 3eBdIuOC4lSGncpl1L3mpXk5tkXF3hPUmQzPYs0kKXDhjIyfiA8TEq/dTwaZvRVv
# v460wMgaaI9POJZyXS0UNkxY0zuVdG4DTL3b78CnZmcXvTp9koTvZWODEHAj7PcB
# e2A=
# SIG # End signature block
